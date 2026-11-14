// The C++ part of Probe: what pofltk's own tests need of FLTK that
// neither pofltk nor FlTest gives programs (PLAN.md, "Build and test",
// and "FlTest: testing a program", for what moved to FlTest).

#include "../src/pofltk.h"

#include <FL/Fl.H>
#include <FL/platform.H>
#include <FL/Fl_Image_Surface.H>
#include <FL/Fl_RGB_Image.H>
#include <FL/Fl_Shared_Image.H>
#include <FL/Fl_Widget.H>
#include <FL/Fl_Window.H>
#include <FL/fl_draw.H>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <dlfcn.h>
#if defined(FLTK_USE_X11)
#include <FL/x11.H>
#endif

namespace {

char text[64];  // the text SetKey gives the event

Fl_Widget *widget(intptr_t h) { return reinterpret_cast<Fl_Widget *>(h); }

// Fl_Window's protected force_position(), through a pointer to member
// named in a class derived from it.
struct Placed : Fl_Window {
  static int forced(Fl_Window *w) {
    int (Fl_Window::*get)() const = &Placed::force_position;
    return (w->*get)();
  }
};

}  // namespace

// Not in a header: what the window system's code calls.
extern void fl_trigger_clipboard_notify(int source);

extern "C" {

// 1 if window w is to be shown where the program put it, 0 if where the
// window manager chooses.
int32_t ofltest_forced_position(intptr_t w) {
  return Placed::forced(widget(w)->as_window());
}

// How many resources w keeps beside its label images (ofl::Ref::keep).
int32_t ofltest_kept(intptr_t w) {
  return static_cast<int32_t>(ofl::ref_of(widget(w))->kept_count());
}

// The number of 32-bit words in shown window w's _NET_WM_ICON property, the
// icons FLTK gave the window manager: for each, its width, its height and
// its pixels. -1 if FLTK isn't on X11. Xlib is found with dlsym, as
// libfltk loaded it, so the tests needn't link it.
int32_t ofltest_icon_words(intptr_t w) {
#if defined(FLTK_USE_X11)
  Display *d = fl_x11_display();
  if (d == 0) return -1;
  typedef Atom (*Intern)(Display *, const char *, Bool);
  typedef int (*Get)(Display *, Window, Atom, long, long, Bool, Atom, Atom *,
                     int *, unsigned long *, unsigned long *, unsigned char **);
  typedef int (*Free)(void *);
  Intern intern = reinterpret_cast<Intern>(dlsym(RTLD_DEFAULT, "XInternAtom"));
  Get get = reinterpret_cast<Get>(dlsym(RTLD_DEFAULT, "XGetWindowProperty"));
  Free xfree = reinterpret_cast<Free>(dlsym(RTLD_DEFAULT, "XFree"));
  if (intern == 0 || get == 0 || xfree == 0) return -1;
  Atom type;
  int format;
  unsigned long n, after;
  unsigned char *data = 0;
  Window x = fl_x11_xid(widget(w)->as_window());
  if (get(d, x, intern(d, "_NET_WM_ICON", False), 0, 1 << 20, False,
          AnyPropertyType, &type, &format, &n, &after, &data) != Success) {
    return -1;
  }
  if (data) xfree(data);
  return static_cast<int32_t>(n);
#else
  (void)w;
  return -1;
#endif
}

// The screen rectangle of the window FLTK grabs events to (an open menu)
// in r; 0 if there is none.
int32_t ofltest_grab(int32_t *r) {
  Fl_Window *g = Fl::grab();
  if (g == 0) return 0;
  r[0] = g->x();
  r[1] = g->y();
  r[2] = g->w();
  r[3] = g->h();
  return 1;
}

// 1 if fl_config.h gives feature, numbered as Fl.Has's.
int32_t ofltest_configured(int32_t feature) {
  switch (feature) {
#if defined(FLTK_USE_SVG)
    case 0: return 1;
#endif
#if defined(FLTK_USE_WAYLAND)
    case 1: return 1;
#endif
#if defined(FLTK_USE_X11)
    case 2: return 1;
#endif
    default: return 0;
  }
}

// A pipe, for FdWatch: its read and write ends in fds[0] and fds[1]; 1
// if it was made.
int32_t ofltest_pipe(int32_t *fds) {
  int p[2];
  if (pipe(p) != 0) return 0;
  fds[0] = p[0];
  fds[1] = p[1];
  return 1;
}

// Writes s to fd; the bytes written, or -1.
int32_t ofltest_write(int32_t fd, const char *s) {
  return static_cast<int32_t>(write(fd, s, strlen(s)));
}

// Reads up to n - 1 bytes from fd into buf, ended with 0X; the bytes
// read, or -1.
int32_t ofltest_read(int32_t fd, char *buf, int32_t n) {
  ssize_t r = read(fd, buf, n - 1);
  buf[r > 0 ? r : 0] = 0;
  return static_cast<int32_t>(r);
}

void ofltest_close(int32_t fd) { close(fd); }

// The key of the event, with no event sent, keeping its state.
void ofltest_set_key(int32_t key, const char *s) {
  strncpy(text, s, sizeof text - 1);
  Fl::e_keysym = Fl::e_original_keysym = key;
  Fl::e_text = text;
  Fl::e_length = static_cast<int>(strlen(text));
}

void ofltest_fatal(const char *text) { Fl::fatal("%s %d", text, 7); }
void ofltest_clipboard_notice(int32_t source) {
  fl_trigger_clipboard_notify(source);
}

void ofltest_setenv(const char *name, const char *value) {
  setenv(name, value, 1);
}

// The width of the image FLTK's own Fl_Shared_Image::get makes of file
// name, or 0.
int32_t ofltest_shared_width(const char *name) {
  Fl_Shared_Image *s = Fl_Shared_Image::get(name);
  if (s == 0) return 0;
  int32_t w = s->w();
  s->release();
  return w;
}

}  // extern "C"
