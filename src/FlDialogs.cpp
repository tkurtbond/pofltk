// The C++ part of FlDialogs: FLTK's common dialogs. See pofltk.h for the
// conventions.
//
// fl_message and the rest take a printf format, so the text is always an
// argument of "%s", never the format: an Oberon string may hold a "%".

#include "pofltk.h"

#include <FL/Fl_Color_Chooser.H>
#include <FL/Fl_File_Chooser.H>
#include <FL/Fl_Native_File_Chooser.H>
#include <FL/fl_ask.H>
#include <FL/fl_show_colormap.H>
#include <FL/filename.H>
#include <stdlib.h>
#include <string.h>

#include <deque>
#include <new>
#include <string>

namespace {

// "" is no button.
const char *button(const char *s) { return s && *s ? s : 0; }

// fl_file_chooser and fl_dir_chooser keep one chooser window for the
// program, and set its title with Fl_File_Chooser::label, which keeps the
// pointer (doc/fltk-issues.md, 30). So the title is copied here, where it
// outlives the call; a longer one is cut short.
char chooser_title[1024];

const char *keep_title(const char *s) {
  strncpy(chooser_title, s, sizeof chooser_title - 1);
  chooser_title[sizeof chooser_title - 1] = 0;
  return chooser_title;
}


// Fl_Native_File_Chooser. FLTK's own driver, used when zenity, kdialog
// and GTK are off or missing, keeps the title pointer (it is
// Fl_File_Chooser::label, doc/fltk-issues.md, 30), so the title is copied
// here, beside the chooser; the other drivers copy it themselves, as
// every driver copies the filter, directory and preset file.
struct Chooser {
  Fl_Native_File_Chooser chooser;
  char *title;
  explicit Chooser(int kind) : chooser(kind), title(0) {}
  ~Chooser() { free(title); }
};

Chooser *chooser(intptr_t c) { return reinterpret_cast<Chooser *>(c); }

// A directory's names, as fl_filename_list gives them, until freed.
struct Listing {
  dirent **list;
  int n;
};

Listing *listing(intptr_t l) { return reinterpret_cast<Listing *>(l); }

// What is private in Fl_File_Chooser, reached as FlBrowsers.cpp reaches
// Fl_Tree's: an explicit instantiation may name it.
template <class Tag, typename Tag::type M> struct Reach {
  friend typename Tag::type member(Tag) { return M; }
};
struct ExtGroup {
  typedef Fl_Widget *Fl_File_Chooser::*type;
  friend type member(ExtGroup);
};
template struct Reach<ExtGroup, &Fl_File_Chooser::ext_group>;
struct ShowChoice {
  typedef Fl_Choice *Fl_File_Chooser::*type;
  friend type member(ShowChoice);
};
template struct Reach<ShowChoice, &Fl_File_Chooser::showChoice>;

typedef void (*FileChooserFn)(intptr_t self);

// The Oberon dispatcher, which FlDialogs' body registers.
FileChooserFn on_file_chooser;

// Fl_File_Chooser, with the strings FLTK keeps pointers to beside it, and
// listed first, as its constructor is given the title. A chooser can be
// closed in its callback, where FLTK goes on using it
// (doc/fltk-issues.md, 91), or in the callback of its extra widget,
// inside its window's event: it then goes when no callback is left
// (close_later).
struct FileCh {
  std::string title, ok;
  Fl_File_Chooser chooser;
  intptr_t self;
  int calling;
  bool closing;
  int extra_h;  // the extra widget's height, as FLTK added it to the window
  FileCh(const char *dir, const char *pattern, int type, const char *t,
         intptr_t s)
      : title(t), chooser(dir, pattern, type, title.c_str()), self(s),
        calling(0), closing(false), extra_h(0) {}
};

FileCh *file_ch(intptr_t c) { return reinterpret_cast<FileCh *>(c); }

void file_ch_callback(Fl_File_Chooser *, void *p) {
  FileCh *c = static_cast<FileCh *>(p);
  ++c->calling;
  if (!c->closing) {
    ofl::Dispatch d;
    on_file_chooser(c->self);
  }
  --c->calling;
}

void close_later(void *p) {
  FileCh *c = static_cast<FileCh *>(p);
  if (c->calling > 0) {  // a dialog shown in the callback
    Fl::add_timeout(0.05, close_later, p);
  } else {
    delete c;
  }
}

// FLTK's chooser's labels, which it keeps. Each copy lasts as long as the
// program: a chooser may be showing the last one.
std::deque<std::string> chooser_labels;

}  // namespace

extern "C" {

void ofl_dialog_message(int32_t alert, const char *text) {
  if (alert) {
    fl_alert("%s", text);
  } else {
    fl_message("%s", text);
  }
}

// The button pushed, 0 to 2; -1 if Escape closed the dialog, -2 its
// window's close button.
int32_t ofl_dialog_choice(const char *text, const char *b0, const char *b1,
                          const char *b2) {
  return fl_choice_n("%s", button(b0), button(b1), button(b2), text);
}

// 1 and the text typed in buf, which also holds the text to start with; 0
// if the dialog was cancelled. FLTK returns its own copy, and copies buf
// before the dialog starts.
int32_t ofl_dialog_input(int32_t password, const char *label, char *buf,
                         int32_t n) {
  const char *r = password ? fl_password("%s", buf, label)
                           : fl_input("%s", buf, label);
  if (r == 0) return 0;
  ofl::copy_out(r, buf, n);
  return 1;
}

// fl_message_title copies; the title is for the next dialog only, or with
// dflt for every dialog given none.
void ofl_dialog_title(int32_t dflt, const char *title) {
  if (dflt) {
    fl_message_title_default(title);
  } else {
    fl_message_title(title);
  }
}

int32_t ofl_dialog_hotspot(void) { return fl_message_hotspot(); }
void ofl_dialog_set_hotspot(int32_t on) { fl_message_hotspot(on); }

void ofl_dialog_font(int32_t *font, int32_t *size) {
  *font = fl_message_font_;
  *size = fl_message_size_;
}

void ofl_dialog_set_font(int32_t font, int32_t size) {
  fl_message_font(font, size);
}

void ofl_beep(int32_t kind) { fl_beep(kind); }

// 1, and the color chosen in r, g, b (0 to 255), if the user chose one.
int32_t ofl_color_chooser(const char *title, int32_t *r, int32_t *g,
                          int32_t *b, int32_t mode) {
  uchar R = static_cast<uchar>(*r), G = static_cast<uchar>(*g),
        B = static_cast<uchar>(*b);
  if (!fl_color_chooser(title, R, G, B, mode)) return 0;
  *r = R;
  *g = G;
  *b = B;
  return 1;
}

// Color choosers. FLTK's class holds its children as members, so FlDialogs
// gives it none of Fl.Group's methods: clearing it would delete them.

intptr_t ofl_color_chooser_new(int32_t x, int32_t y, int32_t w, int32_t h,
                               const char *label, intptr_t self) {
  ofl::W<Fl_Color_Chooser> *c = new ofl::W<Fl_Color_Chooser>(x, y, w, h);
  c->copy_label(ofl::label_text(label));
  return ofl::open(c, self);
}

// what: 0 hue, 1 saturation, 2 value, 3 red, 4 green, 5 blue.
double ofl_color_chooser_get(intptr_t c, int32_t what) {
  Fl_Color_Chooser *cc = ofl::as<Fl_Color_Chooser>(c);
  switch (what) {
    case 1: return cc->saturation();
    case 2: return cc->value();
    case 3: return cc->r();
    case 4: return cc->g();
    case 5: return cc->b();
    default: return cc->hue();
  }
}

int32_t ofl_color_chooser_set_hsv(intptr_t c, double h, double s, double v) {
  return ofl::as<Fl_Color_Chooser>(c)->hsv(h, s, v);
}

int32_t ofl_color_chooser_set_rgb(intptr_t c, double r, double g, double b) {
  return ofl::as<Fl_Color_Chooser>(c)->rgb(r, g, b);
}

int32_t ofl_color_chooser_mode(intptr_t c) {
  return ofl::as<Fl_Color_Chooser>(c)->mode();
}

void ofl_color_chooser_set_mode(intptr_t c, int32_t m) {
  ofl::as<Fl_Color_Chooser>(c)->mode(m);
}

void ofl_hsv_to_rgb(double h, double s, double v, double *r, double *g,
                    double *b) {
  Fl_Color_Chooser::hsv2rgb(h, s, v, *r, *g, *b);
}

void ofl_rgb_to_hsv(double r, double g, double b, double *h, double *s,
                    double *v) {
  Fl_Color_Chooser::rgb2hsv(r, g, b, *h, *s, *v);
}

int32_t ofl_show_colormap(int32_t old) {
  return static_cast<int32_t>(fl_show_colormap(static_cast<Fl_Color>(old)));
}

// 1 and the path chosen in buf, which also holds the one to start with; 0
// if cancelled. FLTK returns its own copy.
int32_t ofl_file_chooser(int32_t dir, const char *title, const char *pattern,
                         char *buf, int32_t n, int32_t relative) {
  Fl_File_Chooser::sort = ofl::numericsort;  // doc/fltk-issues.md, 63
  const char *r = dir ? fl_dir_chooser(keep_title(title), buf, relative)
                      : fl_file_chooser(keep_title(title), pattern, buf,
                                        relative);
  if (r == 0) return 0;
  ofl::copy_out(r, buf, n);
  return 1;
}

// A native file chooser of kind (Fl_Native_File_Chooser::Type); 0 if out
// of memory. It opens the display, and looks for zenity and kdialog.
intptr_t ofl_fnfc_new(int32_t kind) {
  return reinterpret_cast<intptr_t>(new (std::nothrow) Chooser(kind));
}

void ofl_fnfc_close(intptr_t c) { delete chooser(c); }

// what: 0 the title, 1 the filter, 2 the directory, 3 the preset file.
// 0 if out of memory.
int32_t ofl_fnfc_set_text(intptr_t c, int32_t what, const char *s) {
  Fl_Native_File_Chooser &f = chooser(c)->chooser;
  switch (what) {
    case 0: {
      char *t = strdup(s);
      if (!t) return 0;
      f.title(t);
      free(chooser(c)->title);
      chooser(c)->title = t;
      break;
    }
    case 1: f.filter(s); break;
    case 2: f.directory(s); break;
    default: f.preset_file(s);
  }
  return 1;
}

// what: 0 the kind, 1 the options, 2 the filter chosen.
void ofl_fnfc_set_int(intptr_t c, int32_t what, int32_t v) {
  Fl_Native_File_Chooser &f = chooser(c)->chooser;
  switch (what) {
    case 0: f.type(v); break;
    case 1: f.options(v); break;
    default: f.filter_value(v);
  }
}

// what: 0 the kind, 1 the options, 2 the filter chosen, 3 the number of
// filters, 4 the number of files chosen.
int32_t ofl_fnfc_get_int(intptr_t c, int32_t what) {
  Fl_Native_File_Chooser &f = chooser(c)->chooser;
  switch (what) {
    case 0: return f.type();
    case 1: return f.options();
    case 2: return f.filter_value();
    case 3: return f.filters();
    default: return f.count();
  }
}

// 0 a file chosen, 1 cancelled, -1 an error (ofl_fnfc_errmsg).
// FLTK's own chooser lists a directory sorted by Fl_File_Chooser::sort,
// which is fl_numericsort until it is set (doc/fltk-issues.md, 63).
int32_t ofl_fnfc_show(intptr_t c) {
  Fl_File_Chooser::sort = ofl::numericsort;
  return chooser(c)->chooser.show();
}

// File i chosen, of ofl_fnfc_get_int(c, 4).
intptr_t ofl_fnfc_filename(intptr_t c, int32_t i) {
  return reinterpret_cast<intptr_t>(chooser(c)->chooser.filename(i));
}

intptr_t ofl_fnfc_errmsg(intptr_t c) {
  return reinterpret_cast<intptr_t>(chooser(c)->chooser.errmsg());
}

// File choosers

void ofl_fc_register(FileChooserFn f) { on_file_chooser = f; }

// FLTK's window stays open until ofl_fc_close, its sort corrected
// (doc/fltk-issues.md, 63).
intptr_t ofl_fc_new(const char *dir, const char *pattern, int32_t type,
                    const char *title, intptr_t self) {
  Fl_File_Chooser::sort = ofl::numericsort;
  FileCh *c = new FileCh(dir, pattern, type, title, self);
  c->chooser.callback(file_ch_callback, c);
  return reinterpret_cast<intptr_t>(c);
}

// hide() lets go of the preview's image, which the destructor doesn't.
void ofl_fc_close(intptr_t h) {
  FileCh *c = file_ch(h);
  c->chooser.hide();
  if (c->calling > 0 || ofl::depth > 0) {
    c->closing = true;
    Fl::add_timeout(0, close_later, c);
  } else {
    delete c;
  }
}

void ofl_fc_show(intptr_t c) { file_ch(c)->chooser.show(); }
void ofl_fc_hide(intptr_t c) { file_ch(c)->chooser.hide(); }

// The chooser's numbers, by what: 0 shown, 1 visible, 2 count, 3 filter
// value, 4 filters, 5 preview, 6 hidden files shown, 7 type, 8 color, 9
// icon size, 10 text color, 11 text font, 12 text size, 13 x, 14 y, 15
// w, 16 h.
int32_t ofl_fc_get(intptr_t h, int32_t what) {
  Fl_File_Chooser &f = file_ch(h)->chooser;
  switch (what) {
    case 0: return f.shown();
    case 1: return f.visible();
    case 2: return f.count();
    case 3: return f.filter_value();
    case 4: return (f.*member(ShowChoice()))->size() - 1;
    case 5: return f.preview();
    case 6: return f.showHiddenButton->value();
    case 7: return f.type();
    case 8: return static_cast<int32_t>(f.color());
    case 9: return f.iconsize();
    case 10: return static_cast<int32_t>(f.textcolor());
    case 11: return f.textfont();
    case 12: return f.textsize();
    case 13: return f.x();
    case 14: return f.y();
    case 15: return f.w();
    default: return f.h();
  }
}

// By what, as ofl_fc_get. A filter's and hidden files' effect shows in
// the list at once.
void ofl_fc_set(intptr_t h, int32_t what, int32_t v) {
  Fl_File_Chooser &f = file_ch(h)->chooser;
  switch (what) {
    case 3: f.filter_value(v); break;
    case 5: f.preview(v); break;
    case 6:
      f.showHiddenButton->value(v);
      f.rescan_keep_filename();
      break;
    case 7: f.type(v); break;
    case 8: f.color(static_cast<Fl_Color>(v)); break;
    case 9: f.iconsize(static_cast<uchar>(v)); break;
    case 10: f.textcolor(static_cast<Fl_Color>(v)); break;
    case 11: f.textfont(v); break;
    default: f.textsize(v); break;
  }
}

// The text, by what: 0 directory, 1 filter, 2 label, 3 OK button's
// label, or i from 1 the chosen file (NULL for none, which is not one
// file a chooser has).
intptr_t ofl_fc_text(intptr_t h, int32_t what, int32_t i) {
  Fl_File_Chooser &f = file_ch(h)->chooser;
  const char *s;
  switch (what) {
    case 0: s = f.directory(); break;
    case 1: s = f.filter(); break;
    case 2: s = f.label(); break;
    case 3: s = f.ok_label(); break;
    default: s = f.value(i); break;
  }
  return reinterpret_cast<intptr_t>(s);
}

// By what: 0 directory, 1 filter, 2 label, 3 OK button's label, 4 the
// chosen file. FLTK keeps the two labels, so they are kept here.
void ofl_fc_set_text(intptr_t h, int32_t what, const char *s) {
  FileCh *c = file_ch(h);
  switch (what) {
    case 0: c->chooser.directory(s); break;
    case 1: c->chooser.filter(s); break;
    case 2:
      c->title = s;
      c->chooser.label(c->title.c_str());
      break;
    case 3:
      c->ok = s;
      c->chooser.ok_label(c->ok.c_str());
      break;
    default: c->chooser.value(s); break;
  }
}

void ofl_fc_rescan(intptr_t c) { file_ch(c)->chooser.rescan_keep_filename(); }

void ofl_fc_position(intptr_t c, int32_t x, int32_t y) {
  file_ch(c)->chooser.position(x, y);
}

void ofl_fc_resize(intptr_t c, int32_t x, int32_t y, int32_t w, int32_t h) {
  file_ch(c)->chooser.resize(x, y, w, h);
}

// Sets extra (0 for none) under the chooser's own widgets. With gone, the
// last one was deleted, which FLTK can't see: add_extra would read it
// (doc/fltk-issues.md, 92), so it is forgotten here, and the window takes
// back the room it was given.
void ofl_fc_set_extra(intptr_t h, intptr_t extra, int32_t gone) {
  FileCh *c = file_ch(h);
  Fl_File_Chooser &f = c->chooser;
  if (gone) {
    f.*member(ExtGroup()) = 0;
    f.size(f.w(), f.h() - c->extra_h);
    c->extra_h = 0;
  }
  Fl_Widget *w = extra ? ofl::widget(extra) : 0;
  f.add_extra(w);
  c->extra_h = w ? w->h() + 4 : 0;
}

// which is the Oberon constant: FLTK's static labels, in its header's
// order.
void ofl_fc_set_label(int32_t which, const char *s) {
  chooser_labels.push_back(s);
  const char *t = chooser_labels.back().c_str();
  switch (which) {
    case 0: Fl_File_Chooser::add_favorites_label = t; break;
    case 1: Fl_File_Chooser::all_files_label = t; break;
    case 2: Fl_File_Chooser::custom_filter_label = t; break;
    case 3: Fl_File_Chooser::existing_file_label = t; break;
    case 4: Fl_File_Chooser::favorites_label = t; break;
    case 5: Fl_File_Chooser::filename_label = t; break;
    case 6: Fl_File_Chooser::filesystems_label = t; break;
    case 7: Fl_File_Chooser::hidden_label = t; break;
    case 8: Fl_File_Chooser::manage_favorites_label = t; break;
    case 9: Fl_File_Chooser::new_directory_label = t; break;
    case 10: Fl_File_Chooser::new_directory_tooltip = t; break;
    case 11: Fl_File_Chooser::preview_label = t; break;
    case 12: Fl_File_Chooser::save_label = t; break;
    default: Fl_File_Chooser::show_label = t; break;
  }
}

// Directories

// Directory dir's names, sorted by sort (0 fl_alphasort, 1
// fl_casealphasort, 2 fl_numericsort, 3 fl_casenumericsort, the last two
// corrected: doc/fltk-issues.md, 63), their number in *n; 0 if it can't
// be read.
intptr_t ofl_filename_list(const char *dir, int32_t sort, int32_t *n) {
  Fl_File_Sort_F *f = sort == 1   ? fl_casealphasort
                      : sort == 2 ? ofl::numericsort
                      : sort == 3 ? ofl::casenumericsort
                                  : fl_alphasort;
  dirent **list = 0;
  int k = fl_filename_list(dir, &list, f);
  if (k < 0) return 0;
  *n = k;
  return reinterpret_cast<intptr_t>(new Listing{list, k});
}

int32_t ofl_filename_length(intptr_t l, int32_t i) {
  return static_cast<int32_t>(strlen(listing(l)->list[i]->d_name));
}

void ofl_filename_get(intptr_t l, int32_t i, char *buf, int32_t n) {
  ofl::copy_out(listing(l)->list[i]->d_name, buf, n);
}

void ofl_filename_free(intptr_t l) {
  fl_filename_free_list(&listing(l)->list, listing(l)->n);
  delete listing(l);
}

}  // extern "C"
