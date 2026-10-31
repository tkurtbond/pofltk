// The C++ part of FlPrint: Fl_Printer, Fl_PostScript_File_Device,
// Fl_PDF_File_Surface, Fl_EPS_File_Surface and Fl_SVG_File_Surface. See
// pofltk.h for the conventions.
//
// A handle is a Job: the surface, and what the shim keeps beside it. No
// widget is involved, so there is no ofl::W here.
//
// FLTK's end_job for PostScript closes the file on any error from Cairo,
// and then writes to it (doc/fltk-issues.md, 101). So PostScript goes
// through a stream of the shim's, a Sink, that tells Cairo every write
// worked, and remembers when one didn't.

#include "pofltk.h"

#include <FL/Fl_PDF_File_Surface.H>
#include <FL/Fl_PostScript.H>
#include <FL/Fl_Printer.H>
#include <FL/Fl_SVG_File_Surface.H>
#include <FL/fl_draw.H>
#include <FL/fl_utf8.h>
#include <FL/platform.H>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <string>

// FLTK built with --disable-print has stubs for these classes, with null
// drivers, and doesn't have these four, and says so only in config.h,
// which a program can't see. So they are weak, and the first says if this
// FLTK prints (doc/fltk-issues.md, 104).
extern const char *ofl_pdf_title
    __asm__("_ZN19Fl_PDF_File_Surface19format_dialog_titleE")
    __attribute__((weak));
extern const char *ofl_pdf_page_size
    __asm__("_ZN19Fl_PDF_File_Surface23format_dialog_page_sizeE")
    __attribute__((weak));
extern const char *ofl_pdf_orientation
    __asm__("_ZN19Fl_PDF_File_Surface25format_dialog_orientationE")
    __attribute__((weak));
extern const char *ofl_pdf_default
    __asm__("_ZN19Fl_PDF_File_Surface21format_dialog_defaultE")
    __attribute__((weak));

namespace {

enum { printer, postscript, pdf, eps, svg };

// The file a PostScript job goes to.
struct Sink {
  FILE *out;
  bool failed;  // a write to out failed
  bool closed;  // FLTK closed the stream: Cairo had an error
};

size_t sink_put(Sink *s, const char *p, size_t n) {
  if (fwrite(p, 1, n, s->out) != n) s->failed = true;
  return n;
}

#if defined(__linux__)

ssize_t sink_write(void *c, const char *p, size_t n) {
  return static_cast<ssize_t>(sink_put(static_cast<Sink *>(c), p, n));
}

int sink_close(void *c) {
  static_cast<Sink *>(c)->closed = true;
  return 0;
}

FILE *sink_open(Sink *s) {
  cookie_io_functions_t f = {0, sink_write, 0, sink_close};
  return fopencookie(s, "w", f);
}

#else

int sink_write(void *c, const char *p, int n) {
  return static_cast<int>(sink_put(static_cast<Sink *>(c), p,
                                   static_cast<size_t>(n)));
}

int sink_close(void *c) {
  static_cast<Sink *>(c)->closed = true;
  return 0;
}

FILE *sink_open(Sink *s) { return funopen(s, 0, sink_write, 0, sink_close); }

#endif

struct Job {
  int kind;
  Fl_Widget_Surface *s;     // the surface, as any kind
  Fl_Paged_Device *paged;   // the surface, or 0 for EPS and SVG
  bool ended;               // its file is written and closed
  FILE *stream;             // PostScript's: through sink
  Sink sink;

  Job(int k, Fl_Widget_Surface *w, Fl_Paged_Device *p)
      : kind(k), s(w), paged(p), ended(false), stream(0) {
    sink.out = 0;
    sink.failed = sink.closed = false;
  }
};

Job *job(intptr_t h) { return reinterpret_cast<Job *>(h); }
intptr_t handle(Job *j) { return reinterpret_cast<intptr_t>(j); }

std::string last_error;  // why the last thing that failed did
const char *const no_print = "This FLTK can't print";

bool can_print() {
  if (&ofl_pdf_title != 0) return true;
  last_error = no_print;
  return false;
}

// FLTK's message, kept, and freed as it was allocated: new[] by the
// Pango PDF surface and GTK's printer, strdup by the PDF surface without
// Pango. Printing without support gives none.
void take_message(char *m) {
  last_error = m ? m : no_print;
  if (m == 0) return;
  if (strstr(m, "requires PANGO")) {
    free(m);
  } else {
    delete[] m;
  }
}

FILE *open_file(const char *path) {
  FILE *f = fl_fopen(path, "w");
  if (f == 0) last_error = strerror(errno);
  return f;
}

// Closes a PostScript job's stream and file, once; whether all was
// written.
bool close_stream(Job *j) {
  bool ok = !j->sink.closed && !j->sink.failed;
  if (j->stream != 0 && !j->sink.closed && fclose(j->stream) != 0) ok = false;
  j->stream = 0;
  if (j->sink.failed) ok = false;  // the flush above
  if (j->sink.out != 0 && fclose(j->sink.out) != 0) ok = false;
  j->sink.out = 0;
  return ok;
}

// FLTK reports an error writing a PDF or printing with fl_alert, and
// tells the program nothing, so a timer watches for the alert, says so,
// and closes it (doc/fltk-issues.md, 102).
bool alerted;

void watch(void *before) {
  Fl_Window *m = Fl::modal();
  if (m != 0 && m != before) {
    alerted = true;
    m->hide();
  }
  Fl::repeat_timeout(0.01, watch, before);
}

bool end_watched(Fl_Paged_Device *d) {
  alerted = false;
  Fl::add_timeout(0, watch, Fl::modal());
  d->end_job();
  Fl::remove_timeout(watch);
  return !alerted;
}

// FLTK's surfaces have no font to begin with, and text then crashes all
// but SVG's (doc/fltk-issues.md, 100).
void set_font() { fl_font(FL_HELVETICA, FL_NORMAL_SIZE); }

bool finite(float f) { return f - f == 0; }

Fl_Paged_Device::Page_Format format_of(int32_t f) {
  return static_cast<Fl_Paged_Device::Page_Format>(f);
}

Fl_Paged_Device::Page_Layout layout_of(int32_t l) {
  return static_cast<Fl_Paged_Device::Page_Layout>(l);
}

// FLTK keeps these pointers, and uses them when it builds a panel.
const char **const texts[] = {
    &Fl_Printer::dialog_title,         &Fl_Printer::dialog_printer,
    &Fl_Printer::dialog_range,         &Fl_Printer::dialog_copies,
    &Fl_Printer::dialog_all,           &Fl_Printer::dialog_pages,
    &Fl_Printer::dialog_from,          &Fl_Printer::dialog_to,
    &Fl_Printer::dialog_properties,    &Fl_Printer::dialog_copyNo,
    &Fl_Printer::dialog_print_button,  &Fl_Printer::dialog_cancel_button,
    &Fl_Printer::dialog_print_to_file, &Fl_Printer::property_title,
    &Fl_Printer::property_pagesize,    &Fl_Printer::property_mode,
    &Fl_Printer::property_use,         &Fl_Printer::property_save,
    &Fl_Printer::property_cancel,
    &ofl_pdf_title,                    &ofl_pdf_page_size,
    &ofl_pdf_orientation,              &ofl_pdf_default,
};
const int32_t text_count = sizeof texts / sizeof texts[0];
std::string text_kept[sizeof texts / sizeof texts[0]];

}  // namespace

extern "C" {

// Making them. Each opens the display, which FLTK's drivers read.

intptr_t ofl_print_printer() {
  fl_open_display();
  Fl_Printer *p = new Fl_Printer;
  return handle(new Job(printer, p, p));
}

// 0, with Error's message, if path can't be written.
intptr_t ofl_print_postscript(const char *path, int32_t format,
                              int32_t layout) {
  if (!can_print()) return 0;
  fl_open_display();
  FILE *out = open_file(path);
  if (out == 0) return 0;
  Fl_PostScript_File_Device *d = new Fl_PostScript_File_Device;
  Job *j = new Job(postscript, d, d);
  j->sink.out = out;
  j->stream = sink_open(&j->sink);
  if (j->stream == 0) {
    last_error = strerror(errno);
  } else if (d->begin_job(j->stream, 0, format_of(format),
                          layout_of(layout)) != 0) {
    last_error = "FLTK can't write PostScript here";
  } else {
    return handle(j);
  }
  delete d;
  close_stream(j);
  delete j;
  return 0;
}

// 0, 1 if the user cancelled, or 2 with Error's message; on 0, a job in
// *result. With chooser, the user picks the file, format and layout.
int32_t ofl_print_pdf(const char *path, int32_t chooser, int32_t format,
                      int32_t layout, intptr_t *result) {
  if (!can_print()) return 2;
  fl_open_display();
  Fl_PDF_File_Surface *d = new Fl_PDF_File_Surface;
  char *message = 0;
  int r = chooser ? d->begin_job(path[0] ? path : 0, &message)
                  : d->begin_document(path, format_of(format),
                                      layout_of(layout), &message);
  if (r == 0) {
    *result = handle(new Job(pdf, d, d));
    return 0;
  }
  if (r != 1) take_message(message);
  delete d;
  return r == 1 ? 1 : 2;
}

intptr_t ofl_print_eps(const char *path, int32_t w, int32_t h,
                       uint32_t background) {
  if (!can_print()) return 0;
  fl_open_display();
  FILE *f = open_file(path);
  if (f == 0) return 0;
  Fl_EPS_File_Surface *d = new Fl_EPS_File_Surface(w, h, f, background);
  return handle(new Job(eps, d, 0));
}

// Without SVG, before the file is touched.
intptr_t ofl_print_svg(const char *path, int32_t w, int32_t h) {
#if defined(FLTK_USE_SVG)
  fl_open_display();
  FILE *f = open_file(path);
  if (f == 0) return 0;
  Fl_SVG_File_Surface *d = new Fl_SVG_File_Surface(w, h, f);
  return handle(new Job(svg, d, 0));
#else
  (void)path;
  (void)w;
  (void)h;
  last_error = "This FLTK can't write SVG";
  return 0;
#endif
}

// The print dialog: 0, 1 if the user cancelled, or 2 with Error's
// message. from and to are the pages chosen.
int32_t ofl_print_job(intptr_t h, int32_t pages, int32_t *from, int32_t *to) {
  char *message = 0;
  int f = 0, t = 0;
  int r = job(h)->paged->begin_job(pages, &f, &t, &message);
  *from = f;
  *to = t;
  if (r == 0 || r == 1) return r;
  take_message(message);
  return 2;
}

// Ending. Whether the file was written, as far as FLTK or the system
// said; for a printer, whether FLTK reported no error.
int32_t ofl_print_finish(intptr_t h) {
  Job *j = job(h);
  bool ok = true;
  j->ended = true;
  switch (j->kind) {
    case postscript:
      j->paged->end_job();
      ok = close_stream(j);
      break;
    case eps:
      ok = static_cast<Fl_EPS_File_Surface *>(j->s)->close() == 0;
      break;
    case svg:
      ok = static_cast<Fl_SVG_File_Surface *>(j->s)->close() == 0;
      break;
    default:
      ok = end_watched(j->paged);
      j->ended = false;  // a printer can begin another job
  }
  return ok ? 1 : 0;
}

// Frees it. A job not ended is left unfinished: end_job runs an event
// loop, and this runs in a finalizer.
void ofl_print_close(intptr_t h) {
  Job *j = job(h);
  if (j->s->is_current()) Fl_Surface_Device::pop_current();
  if (!j->ended) {
    if (j->kind == eps) static_cast<Fl_EPS_File_Surface *>(j->s)->close();
    if (j->kind == svg) static_cast<Fl_SVG_File_Surface *>(j->s)->close();
  }
  delete j->s;
  close_stream(j);
  delete j;
}

// Drawing goes to it from here to ofl_print_end: a page, or a whole EPS
// or SVG surface.
void ofl_print_begin(intptr_t h) {
  Job *j = job(h);
  if (j->paged != 0) {
    j->paged->begin_page();
  } else {
    Fl_Surface_Device::push_current(j->s);
  }
  set_font();
}

void ofl_print_end(intptr_t h) {
  Job *j = job(h);
  if (j->paged != 0) {
    j->paged->end_page();
  } else {
    Fl_Surface_Device::pop_current();
  }
}

// Whether drawing goes to it now, so it can end.
int32_t ofl_print_current(intptr_t h) {
  return job(h)->s->is_current() ? 1 : 0;
}

void ofl_print_translate(intptr_t h, int32_t x, int32_t y) {
  job(h)->s->translate(x, y);
}

void ofl_print_untranslate(intptr_t h) { job(h)->s->untranslate(); }

void ofl_print_draw(intptr_t h, intptr_t w, int32_t x, int32_t y) {
  job(h)->s->draw(ofl::widget(w), x, y);
}

void ofl_print_decorated(intptr_t h, intptr_t w, int32_t x, int32_t y) {
  job(h)->s->draw_decorated_window(ofl::as<Fl_Window>(w), x, y);
}

void ofl_print_part(intptr_t h, intptr_t w, int32_t x, int32_t y, int32_t pw,
                    int32_t ph, int32_t dx, int32_t dy) {
  job(h)->s->print_window_part(ofl::as<Fl_Window>(w), x, y, pw, ph, dx, dy);
}

void ofl_print_rect(intptr_t h, int32_t *w, int32_t *ht) {
  int a = 0, b = 0;
  job(h)->s->printable_rect(&a, &b);
  *w = a;
  *ht = b;
}

void ofl_print_get_origin(intptr_t h, int32_t *x, int32_t *y) {
  int a = 0, b = 0;
  job(h)->s->origin(&a, &b);
  *x = a;
  *y = b;
}

void ofl_print_set_origin(intptr_t h, int32_t x, int32_t y) {
  job(h)->s->origin(x, y);
}

void ofl_print_margins(intptr_t h, int32_t *l, int32_t *t, int32_t *r,
                       int32_t *b) {
  int a = 0, c = 0, d = 0, e = 0;
  job(h)->paged->margins(&a, &c, &d, &e);
  *l = a;
  *t = c;
  *r = d;
  *b = e;
}

// 0 for a factor Cairo can't use, which would break the job (FLTK takes
// a y of 0 as "the same as x"): nothing is done.
int32_t ofl_print_scale(intptr_t h, double x, double y) {
  float a = static_cast<float>(x), b = static_cast<float>(y);
  if (a == 0 || b == 0 || !finite(a) || !finite(b)) return 0;
  job(h)->paged->scale(a, b);
  return 1;
}

int32_t ofl_print_rotate(intptr_t h, double angle) {
  float a = static_cast<float>(angle);
  if (!finite(a)) return 0;
  job(h)->paged->rotate(a);
  return 1;
}

// The last failure's message.
void ofl_print_error(char *buf, int32_t n) {
  ofl::copy_out(last_error.c_str(), buf, n);
}

// Sets one of FLTK's texts; 0 if there is no such text.
int32_t ofl_print_available() { return can_print(); }

int32_t ofl_print_text(int32_t which, const char *text) {
  if (which < 0 || which >= text_count) return 0;
  if (texts[which] == 0) return 1;
  text_kept[which] = text;
  *texts[which] = text_kept[which].c_str();
  return 1;
}

}  // extern "C"
