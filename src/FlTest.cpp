// The C++ part of FlTest: a widget's drawing captured as pixels, and
// events sent as from the window system, for a program's tests. Moved from
// test/Probe.cpp (PLAN.md, "FlTest: testing a program").

#include "pofltk.h"

#include <FL/Fl.H>
#include <FL/Fl_Button.H>
#include <FL/Fl_Image_Surface.H>
#include <FL/Fl_RGB_Image.H>
#include <FL/Fl_Widget.H>
#include <FL/Fl_Window.H>
#include <FL/fl_draw.H>
#include <stdint.h>
#include <string.h>

namespace {

Fl_RGB_Image *shot;  // the last capture, or 0
char text[64];       // the text of the last key event sent

Fl_Widget *widget(intptr_t h) { return reinterpret_cast<Fl_Widget *>(h); }

// FLTK's handling of event, sent to win, as from the window system.
int32_t send(intptr_t win, int32_t event) {
  return Fl::handle(event, widget(win)->as_window());
}

// Makes key, typing s, the event's, returning what it replaced, which
// put_back restores: a widget may keep Fl::e_text, so it points at text
// only while the event is handled.
struct Typed {
  char *old_text;
  int old_length;
  Typed(int32_t key, int32_t state, const char *s)
      : old_text(Fl::e_text), old_length(Fl::e_length) {
    strncpy(text, s, sizeof text - 1);
    text[sizeof text - 1] = 0;
    Fl::e_keysym = Fl::e_original_keysym = key;
    Fl::e_state = state;
    Fl::e_text = text;
    Fl::e_length = static_cast<int>(strlen(text));
  }
  ~Typed() {
    Fl::e_text = old_text;
    Fl::e_length = old_length;
  }
};

}  // namespace

extern "C" {

// Draws w as FLTK would in its window, on white, into an image of w's
// size, for ofl_fltest_pixel; 1 if the image is that size. The window need
// not be shown.
int32_t ofl_fltest_capture(intptr_t w) {
  Fl_Widget *wd = widget(w);
  delete shot;
  Fl_Image_Surface surface(wd->w(), wd->h());
  Fl_Surface_Device::push_current(&surface);
  fl_color(FL_WHITE);
  fl_rectf(0, 0, wd->w(), wd->h());
  surface.draw(wd, 0, 0);
  shot = surface.image();
  Fl_Surface_Device::pop_current();
  return shot != 0 && shot->w() == wd->w() && shot->h() == wd->h();
}

// The pixel x, y of the capture, relative to the widget's top left, as
// 0xRRGGBB; -1 outside it.
int32_t ofl_fltest_pixel(int32_t x, int32_t y) {
  if (shot == 0 || x < 0 || y < 0 || x >= shot->w() || y >= shot->h()) {
    return -1;
  }
  int ld = shot->ld() ? shot->ld() : shot->w() * shot->d();
  const uchar *p =
      reinterpret_cast<const uchar *>(shot->data()[0]) + y * ld + x * shot->d();
  if (shot->d() < 3) return p[0] << 16 | p[0] << 8 | p[0];
  return p[0] << 16 | p[1] << 8 | p[2];
}

void ofl_fltest_release(void) {
  delete shot;
  shot = 0;
}

// The pixel x, y of what a shown window shows, as 0xRRGGBB. Works on X11
// and Wayland, where a capture would draw the window anew.
int32_t ofl_fltest_shown_pixel(intptr_t w, int32_t x, int32_t y) {
  Fl_Window *win = widget(w)->as_window();
  uchar p[3] = {0, 0, 0};
  win->make_current();
  fl_read_image(p, x, y, 1, 1);
  return p[0] << 16 | p[1] << 8 | p[2];
}

// A mouse event at x, y in win's coordinates: button is 1 to 3 for
// FL_PUSH and FL_RELEASE, state FLTK's event state bits.
int32_t ofl_fltest_mouse(intptr_t win, int32_t event, int32_t x, int32_t y,
                       int32_t button, int32_t state, int32_t clicks) {
  Fl_Widget *w = widget(win);
  Fl::e_x = x;
  Fl::e_y = y;
  Fl::e_x_root = w->x() + x;
  Fl::e_y_root = w->y() + y;
  Fl::e_keysym = FL_Button + button;
  Fl::e_state = state;
  Fl::e_clicks = clicks;
  Fl::e_is_click = 1;
  return send(win, event);
}

// A mouse wheel turned dx across and dy down, the mouse at x, y.
int32_t ofl_fltest_wheel(intptr_t win, int32_t x, int32_t y, int32_t dx,
                       int32_t dy) {
  Fl_Widget *w = widget(win);
  Fl::e_x = x;
  Fl::e_y = y;
  Fl::e_x_root = w->x() + x;
  Fl::e_y_root = w->y() + y;
  Fl::e_dx = dx;
  Fl::e_dy = dy;
  return send(win, FL_MOUSEWHEEL);
}

// A key event (FL_KEYDOWN or FL_KEYUP) of key, typing s, sent to the
// focus widget, as FLTK sends it first. Not by Fl::handle: FLTK 1.4.5
// then offers a key the focus doesn't use as a shortcut, which crashes in
// a window never shown (doc/fltk-issues.md, 3).
int32_t ofl_fltest_key(int32_t event, int32_t key, int32_t state,
                     const char *s) {
  Fl_Widget *focus = Fl::focus();
  if (focus == 0) return 0;
  Typed t(key, state, s);
  Fl::e_number = event;
  return focus->handle(event);
}

// A key, typing s, offered to win and its widgets as a shortcut (as
// FLTK offers a key the focus doesn't use): FL_SHORTCUT sent to win's
// handle(), which an Fl_Group passes to each child.
int32_t ofl_fltest_shortcut(intptr_t win, int32_t key, int32_t state,
                          const char *s) {
  Typed t(key, state, s);
  Fl::e_number = FL_SHORTCUT;
  return widget(win)->handle(FL_SHORTCUT);
}

// A key event (FL_KEYDOWN or FL_SHORTCUT) of key, typing s, sent by
// Fl::handle to win, as from the window system: to the grab (a pop-up
// menu) if there is one, else for a shortcut to win's widgets and then
// the event handlers (a global menu). Never send a key no widget uses
// while the mouse is over a widget of a window never shown
// (doc/fltk-issues.md, 3).
int32_t ofl_fltest_handle_key(intptr_t win, int32_t event, int32_t key,
                            int32_t state, const char *s) {
  Typed t(key, state, s);
  return send(win, event);
}

// A key, typing s, sent by Fl::handle to the modal window (a dialog) as
// from the window system, so to its focus widget first; 0 if no modal
// window is shown.
int32_t ofl_fltest_modal_key(int32_t key, int32_t state, const char *s) {
  Fl_Window *modal = Fl::modal();
  if (modal == 0) return 0;
  return ofl_fltest_handle_key(reinterpret_cast<intptr_t>(modal), FL_KEYDOWN,
                             key, state, s);
}

// 1 if a modal window (a dialog) is shown, with its title in buf; 0 if
// none is.
int32_t ofl_fltest_modal(char *buf, int32_t n) {
  Fl_Window *modal = Fl::modal();
  buf[0] = 0;
  if (modal == 0 || !modal->shown()) return 0;
  ofl::copy_out(modal->label() ? modal->label() : "", buf, n);
  return 1;
}

// 1 if w is a radio button, by its type, which FLTK's click turns on with
// setonly().
int32_t ofl_fltest_radio(intptr_t w) {
  Fl_Button *b = dynamic_cast<Fl_Button *>(widget(w));
  return b != 0 && b->type() == FL_RADIO_BUTTON;
}

}  // extern "C"
