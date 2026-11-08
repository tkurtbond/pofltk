// The C++ part of Fl, pofltk's core module: widgets, groups, windows,
// boxes, timeouts and the event loop. See pofltk.h for the conventions.

#include "pofltk.h"

#include <FL/Fl_Box.H>
#include <FL/Fl_Double_Window.H>
#include <FL/Fl_Flex.H>
#include <FL/Fl_Group.H>
#include <FL/Fl_Menu_Window.H>
#include <FL/Fl_Overlay_Window.H>
#include <FL/Fl_Pack.H>
#include <FL/Fl_Scheme.H>
#include <FL/Fl_Single_Window.H>
#include <FL/Fl_Table.H>
#include <FL/Fl_Tooltip.H>
#include <FL/Fl_Window.H>
#include <FL/fl_draw.H>
#include <FL/filename.H>
#include <FL/names.h>
#include <FL/platform.H>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>

#include <map>
#include <memory>
#include <vector>

namespace ofl {

SelfFn on_callback, on_draw, on_deleted, on_draw_overlay;
HandleFn on_handle;
ResizeFn on_resize;
int depth;
int pending;

void callback_trampoline(Fl_Widget *, void *data) {
  Dispatch d;
  on_callback(static_cast<Ref *>(data)->self);
}

}  // namespace ofl

namespace {

ofl::SelfFn on_timeout;

// A timeout's data is its Oberon Timer's address, which Fl keeps
// reachable while the timeout is pending.
void timeout_trampoline(void *self) {
  ofl::Dispatch d;
  on_timeout(reinterpret_cast<intptr_t>(self));
}

// Idle callbacks and watched file descriptors: the data is the Oberon
// Idle's or FdWatch's address, which Fl keeps reachable while FLTK has it.
ofl::SelfFn on_idle, on_fd;

void idle_trampoline(void *self) {
  ofl::Dispatch d;
  on_idle(reinterpret_cast<intptr_t>(self));
}

void fd_trampoline(FL_SOCKET, void *self) {
  ofl::Dispatch d;
  on_fd(reinterpret_cast<intptr_t>(self));
}

// The event dispatch: Fl's, given each event and its window's Oberon
// object (0 for a window FLTK made, or none), with the window kept for
// ofl_handle_default. A dispatch, so a widget deleted in it is deleted
// later, not under Fl::handle_.
int32_t (*on_dispatch)(int32_t, intptr_t);
Fl_Window *dispatch_window;

int dispatch_trampoline(int event, Fl_Window *w) {
  ofl::Dispatch d;
  Fl_Window *outer = dispatch_window;
  dispatch_window = w;
  int r = on_dispatch(event, ofl::object_of(w));
  dispatch_window = outer;
  return r;
}

// The event handlers: Fl's, which calls those added, newest first, with
// an event no widget used. Called as a dispatch, as the event dispatch
// is.
int32_t (*on_handler)(int32_t);

int handler_trampoline(int event) {
  ofl::Dispatch d;
  return on_handler(event);
}

// The text an event is given (ofl_set_event_text): FLTK keeps the
// pointer until the next event.
std::vector<char> event_text;


// Checks and the clipboard's notices: Fl's, as idles and handlers are.
ofl::SelfFn on_check;
void (*on_clipboard)(int32_t);

void check_trampoline(void *self) {
  ofl::Dispatch d;
  on_check(reinterpret_cast<intptr_t>(self));
}

void clipboard_trampoline(int source, void *) {
  ofl::Dispatch d;
  on_clipboard(source);
}

// Closing a window: FLTK's windows are FLTK's to hide, and Oberon sees
// only its own.
ofl::SelfFn on_atclose;

void atclose_trampoline(Fl_Window *w, void *data) {
  intptr_t self = ofl::object_of(w);
  if (self) {
    ofl::Dispatch d;
    on_atclose(self);
  } else {
    Fl::default_atclose(w, data);
  }
}

// A fatal error: FLTK's handler takes a printf format, and must not
// return (Fl.H), so if Oberon's does the program ends as FLTK's own
// handler ends it.
void (*on_abort)(intptr_t);
Fl_Abort_Handler fltk_abort;

void abort_trampoline(const char *format, ...) {
  char text[1024];
  va_list args;
  va_start(args, format);
  vsnprintf(text, sizeof text, format, args);
  va_end(args);
  on_abort(reinterpret_cast<intptr_t>(text));
  exit(1);
}

// FLTK's font table grows with Fl::set_font, knows its size only there,
// checks no number, and keeps the name's pointer: so the table's end
// and the names' copies are kept here (doc/fltk-issues.md, 130).
int font_end = FL_FREE_FONT;
std::map<int, std::unique_ptr<char[]>> font_names;

// Sets font f to name, cut to fit the 127 bytes of Fl_Fontdesc's
// fontname, whose last is the font's attributes, at a character's start.
void set_font(int f, const char *name) {
  size_t n = strlen(name);
  if (n > 126) {
    n = 126;
    while (n > 0 && (name[n] & 0xC0) == 0x80) n--;
  }
  std::unique_ptr<char[]> copy(new char[n + 1]);
  memcpy(copy.get(), name, n);
  copy[n] = 0;
  Fl::set_font(static_cast<Fl_Font>(f), copy.get());
  std::swap(font_names[f], copy);
  if (f >= font_end) font_end = f + 1;
}

// True if the display, which this opens, is Wayland's. An FLTK built
// without Wayland (OpenBSD's) has no fl_wl_display.
bool wayland() {
  fl_open_display();
#if defined(FLTK_USE_WAYLAND)
  return fl_wl_display() != 0;
#else
  return false;
#endif
}
}  // namespace

extern "C" {

void ofl_register_loop(ofl::SelfFn idle, ofl::SelfFn fd,
                       int32_t (*dispatch)(int32_t, intptr_t),
                       int32_t (*handler)(int32_t)) {
  on_idle = idle;
  on_fd = fd;
  on_dispatch = dispatch;
  on_handler = handler;
}

// Fl's handlers are FLTK's while there are any (on 1), none of FLTK's
// otherwise.
void ofl_event_handlers(int32_t on) {
  if (on) {
    Fl::add_handler(handler_trampoline);
  } else {
    Fl::remove_handler(handler_trampoline);
  }
}

void ofl_register_statics(ofl::SelfFn check, ofl::SelfFn atclose,
                          void (*abort)(intptr_t),
                          void (*clipboard)(int32_t)) {
  on_check = check;
  on_atclose = atclose;
  on_abort = abort;
  on_clipboard = clipboard;
}

void ofl_redraw_all() { Fl::redraw(); }

int32_t ofl_window_shown_any() { return Fl::first_window() != 0; }

void ofl_add_idle(intptr_t self) {
  Fl::add_idle(idle_trampoline, reinterpret_cast<void *>(self));
}

void ofl_remove_idle(intptr_t self) {
  Fl::remove_idle(idle_trampoline, reinterpret_cast<void *>(self));
}

void ofl_add_fd(int32_t fd, int32_t when, intptr_t self) {
  Fl::add_fd(fd, when, fd_trampoline, reinterpret_cast<void *>(self));
}

void ofl_remove_fd(int32_t fd, int32_t when) { Fl::remove_fd(fd, when); }

void ofl_event_dispatch(int32_t on) {
  Fl::event_dispatch(on ? dispatch_trampoline : 0);
}

// FLTK's own handling of the dispatch's event, for its window.
int32_t ofl_handle_default(int32_t event) {
  return Fl::handle_(event, dispatch_window);
}

void ofl_set_event_key(int32_t key) { Fl::e_keysym = key; }

void ofl_set_event_text(const char *s) {
  size_t n = strlen(s);
  event_text.assign(s, s + n + 1);
  Fl::e_text = event_text.data();
  Fl::e_length = static_cast<int>(n);
}

void ofl_register(ofl::SelfFn callback, ofl::SelfFn draw,
                  ofl::HandleFn handle, ofl::ResizeFn resize,
                  ofl::SelfFn deleted, ofl::SelfFn timeout) {
  ofl::on_callback = callback;
  ofl::on_draw = draw;
  ofl::on_handle = handle;
  ofl::on_resize = resize;
  ofl::on_deleted = deleted;
  on_timeout = timeout;
  // The box and label types FLTK's headers name by macros that define
  // them on first use (FL_ROUND_UP_BOX is fl_define_FL_ROUND_UP_BOX()).
  // Fl's constants are their plain values, so every one is defined here.
  fl_define_FL_ROUND_UP_BOX();
  fl_define_FL_SHADOW_BOX();
  fl_define_FL_ROUNDED_BOX();
  fl_define_FL_RFLAT_BOX();
  fl_define_FL_RSHADOW_BOX();
  fl_define_FL_DIAMOND_BOX();
  fl_define_FL_OVAL_BOX();
  fl_define_FL_PLASTIC_UP_BOX();
  fl_define_FL_GTK_UP_BOX();
  fl_define_FL_GLEAM_UP_BOX();
  fl_define_FL_OXY_UP_BOX();
  fl_define_FL_SHADOW_LABEL();
  fl_define_FL_ENGRAVED_LABEL();
  fl_define_FL_EMBOSSED_LABEL();
}

// Widgets

intptr_t ofl_group_new(int32_t x, int32_t y, int32_t w, int32_t h,
                       intptr_t self) {
  return ofl::open(new ofl::W<Fl_Group>(x, y, w, h), self);
}

// A window placed by the window manager unless placed is 1.
intptr_t ofl_window_new(int32_t placed, int32_t x, int32_t y, int32_t w,
                        int32_t h, intptr_t self) {
  if (placed) return ofl::open(new ofl::W<Fl_Window>(x, y, w, h), self);
  return ofl::open(new ofl::W<Fl_Window>(w, h), self);
}

intptr_t ofl_double_window_new(int32_t placed, int32_t x, int32_t y,
                               int32_t w, int32_t h, intptr_t self) {
  if (placed) return ofl::open(new ofl::W<Fl_Double_Window>(x, y, w, h), self);
  return ofl::open(new ofl::W<Fl_Double_Window>(w, h), self);
}

intptr_t ofl_overlay_window_new(int32_t placed, int32_t x, int32_t y,
                                int32_t w, int32_t h, intptr_t self) {
  typedef ofl::Overlaid<Fl_Overlay_Window> Overlay;
  if (placed) return ofl::open(new Overlay(x, y, w, h), self);
  return ofl::open(new Overlay(w, h), self);
}

void ofl_register_overlay(ofl::SelfFn draw_overlay) {
  ofl::on_draw_overlay = draw_overlay;
}

int32_t ofl_overlay_can_do(intptr_t w) {
  return ofl::as<Fl_Overlay_Window>(w)->can_do_overlay();
}

void ofl_overlay_redraw(intptr_t w) {
  ofl::as<Fl_Overlay_Window>(w)->redraw_overlay();
}

// An Fl_Single_Window, or an Fl_Menu_Window if menu is 1.
intptr_t ofl_single_window_new(int32_t menu, int32_t placed, int32_t x,
                               int32_t y, int32_t w, int32_t h,
                               intptr_t self) {
  if (menu) {
    if (placed) return ofl::open(new ofl::W<Fl_Menu_Window>(x, y, w, h), self);
    return ofl::open(new ofl::W<Fl_Menu_Window>(w, h), self);
  }
  if (placed) return ofl::open(new ofl::W<Fl_Single_Window>(x, y, w, h), self);
  return ofl::open(new ofl::W<Fl_Single_Window>(w, h), self);
}

intptr_t ofl_box_new(int32_t x, int32_t y, int32_t w, int32_t h,
                     intptr_t self) {
  return ofl::open(new ofl::W<Fl_Box>(x, y, w, h), self);
}

// Deleted now, unless an Oberon dispatch is running (pofltk.h): even a
// widget already queued, which then goes with the queue.
void ofl_widget_delete(intptr_t w) {
  Fl_Widget *x = ofl::widget(w);
  if (ofl::depth == 0 && ofl::going(x)) {
    ofl::flush();
  } else {
    ofl::delete_widget(x);
  }
}

void ofl_widget_show(intptr_t w) { ofl::widget(w)->show(); }
void ofl_widget_hide(intptr_t w) { ofl::widget(w)->hide(); }
void ofl_widget_redraw(intptr_t w) { ofl::widget(w)->redraw(); }
void ofl_widget_redraw_label(intptr_t w) { ofl::widget(w)->redraw_label(); }

// wrap is the width to wrap at, 0 for none: measure_label takes it in w.
void ofl_widget_measure_label(intptr_t w, int32_t wrap, int32_t *ww, int32_t *hh) {
  int W = wrap, H = 0;
  ofl::widget(w)->measure_label(W, H);
  *ww = W; *hh = H;
}
void ofl_widget_do_callback(intptr_t w) { ofl::widget(w)->do_callback(); }

int32_t ofl_widget_visible(intptr_t w) {
  return ofl::widget(w)->visible() ? 1 : 0;
}

// What FLTK does with no callback of the program's: queue the widget
// for Fl::readqueue, or for a window, Fl::atclose, which hides it.
void ofl_widget_default_callback(intptr_t w) {
  Fl_Widget::default_callback(ofl::widget(w), 0);
}

void ofl_window_default_callback(intptr_t w) {
  Fl_Window::default_callback(ofl::as<Fl_Window>(w), 0);
}

void ofl_widget_base_draw(intptr_t w) {
  dynamic_cast<ofl::Hooks *>(ofl::widget(w))->base_draw();
}

int32_t ofl_widget_base_handle(intptr_t w, int32_t event) {
  return dynamic_cast<ofl::Hooks *>(ofl::widget(w))->base_handle(event);
}

// Fl_Window::copy_label also sets a shown window's title, but it hides
// Fl_Widget's rather than overriding it, so a window must be called as one.
// Text replaces a multi-label (FlImages), which the widget then lets go;
// copy_label keeps the label type, so it is set back to text first
// (doc/fltk-issues.md, 55).
void ofl_widget_copy_label(intptr_t w, const char *label) {
  Fl_Widget *wd = ofl::widget(w);
  bool was_multi = wd->labeltype() == _FL_MULTI_LABEL;
  // a file icon's label holds the icon, not text, as a multi-label does
  if (was_multi || wd->labeltype() == _FL_ICON_LABEL) {
    wd->label(FL_NORMAL_LABEL, 0);
  }
  Fl_Window *win = wd->as_window();
  if (win) {
    win->copy_label(ofl::label_text(label));
  } else {
    wd->copy_label(ofl::label_text(label));
  }
  if (was_multi) ofl::ref_of(wd)->hold(ofl::Ref::label, 0);
}

// The label, a const char *, or 0 for none: a multi-label, an image or an
// icon label isn't text.
intptr_t ofl_widget_label(intptr_t w) {
  Fl_Widget *wd = ofl::widget(w);
  if (wd->labeltype() >= _FL_MULTI_LABEL && wd->labeltype() <= _FL_IMAGE_LABEL) {
    return 0;
  }
  return reinterpret_cast<intptr_t>(wd->label());
}

int32_t ofl_widget_x(intptr_t w) { return ofl::widget(w)->x(); }
int32_t ofl_widget_y(intptr_t w) { return ofl::widget(w)->y(); }
int32_t ofl_widget_w(intptr_t w) { return ofl::widget(w)->w(); }
int32_t ofl_widget_h(intptr_t w) { return ofl::widget(w)->h(); }

// FLTK's own resize(), not the virtual one, which reaches Oberon's
// Resize: this is that method's default.
void ofl_widget_base_resize(intptr_t w, int32_t x, int32_t y, int32_t width,
                            int32_t height) {
  dynamic_cast<ofl::Hooks *>(ofl::widget(w))->base_resize(x, y, width, height);
}

void ofl_widget_draw_box(intptr_t w) {
  dynamic_cast<ofl::Hooks *>(ofl::widget(w))->hook_draw_box();
}

void ofl_widget_draw_label(intptr_t w) {
  dynamic_cast<ofl::Hooks *>(ofl::widget(w))->hook_draw_label();
}

void ofl_widget_draw_focus(intptr_t w) {
  dynamic_cast<ofl::Hooks *>(ofl::widget(w))->hook_draw_focus();
}

int32_t ofl_widget_changed(intptr_t w) {
  return ofl::widget(w)->changed() ? 1 : 0;
}

void ofl_widget_set_changed(intptr_t w, int32_t c) {
  if (c) {
    ofl::widget(w)->set_changed();
  } else {
    ofl::widget(w)->clear_changed();
  }
}

int32_t ofl_widget_damage(intptr_t w) { return ofl::widget(w)->damage(); }

void ofl_widget_set_damage(intptr_t w, int32_t d) {
  ofl::widget(w)->damage(static_cast<uchar>(d));
}

void ofl_widget_clear_damage(intptr_t w) { ofl::widget(w)->clear_damage(); }

// The display is opened first: under Wayland, FLTK 1.4.5 crashes when a
// text input takes the focus before it is open (doc/fltk-issues.md).
// fl_open_display does nothing if it is open already.
int32_t ofl_widget_take_focus(intptr_t w) {
  fl_open_display();
  return ofl::widget(w)->take_focus();
}

int32_t ofl_widget_visible_focus(intptr_t w) {
  return ofl::widget(w)->visible_focus() ? 1 : 0;
}

void ofl_widget_set_visible_focus(intptr_t w, int32_t v) {
  ofl::widget(w)->visible_focus(v);
}

// 1 if the event's position is inside w.
int32_t ofl_widget_event_inside(intptr_t w) {
  return Fl::event_inside(ofl::widget(w));
}

void ofl_widget_position(intptr_t w, int32_t x, int32_t y) {
  ofl::widget(w)->position(x, y);
}

void ofl_widget_size(intptr_t w, int32_t width, int32_t height) {
  ofl::widget(w)->size(width, height);
}

// The parent's Oberon object, or 0 (ofl::object_of).
intptr_t ofl_widget_parent(intptr_t w) {
  return ofl::object_of(ofl::widget(w)->parent());
}

int32_t ofl_widget_visible_r(intptr_t w) {
  return ofl::widget(w)->visible_r() ? 1 : 0;
}

void ofl_widget_activate(intptr_t w) { ofl::widget(w)->activate(); }
void ofl_widget_deactivate(intptr_t w) { ofl::widget(w)->deactivate(); }

intptr_t ofl_widget_window(intptr_t w) {
  return ofl::object_of(ofl::widget(w)->window());
}

int32_t ofl_widget_output(intptr_t w) {
  return ofl::widget(w)->output() ? 1 : 0;
}

void ofl_widget_set_output(intptr_t w, int32_t on) {
  if (on) ofl::widget(w)->set_output(); else ofl::widget(w)->clear_output();
}

int32_t ofl_widget_active(intptr_t w) {
  return ofl::widget(w)->active() ? 1 : 0;
}

int32_t ofl_widget_active_r(intptr_t w) {
  return ofl::widget(w)->active_r() ? 1 : 0;
}

// An Fl_Color is unsigned; it crosses as its bits, an int32_t.
int32_t ofl_widget_color(intptr_t w) {
  return static_cast<int32_t>(ofl::widget(w)->color());
}

void ofl_widget_set_color(intptr_t w, int32_t c) {
  ofl::widget(w)->color(static_cast<Fl_Color>(c));
}

int32_t ofl_widget_selection_color(intptr_t w) {
  return static_cast<int32_t>(ofl::widget(w)->selection_color());
}

void ofl_widget_set_selection_color(intptr_t w, int32_t c) {
  ofl::widget(w)->selection_color(static_cast<Fl_Color>(c));
}

int32_t ofl_widget_box(intptr_t w) { return ofl::widget(w)->box(); }

void ofl_widget_set_box(intptr_t w, int32_t b) {
  ofl::widget(w)->box(static_cast<Fl_Boxtype>(b));
}

int32_t ofl_widget_labelfont(intptr_t w) {
  return ofl::widget(w)->labelfont();
}

void ofl_widget_set_labelfont(intptr_t w, int32_t f) {
  ofl::widget(w)->labelfont(f);
}

int32_t ofl_widget_labelsize(intptr_t w) {
  return ofl::widget(w)->labelsize();
}

void ofl_widget_set_labelsize(intptr_t w, int32_t s) {
  ofl::widget(w)->labelsize(s);
}

// which: 0 horizontal margin, 1 vertical margin, 2 image spacing.
int32_t ofl_widget_label_margin(intptr_t w, int32_t which) {
  Fl_Widget *o = ofl::widget(w);
  switch (which) {
  case 0: return o->horizontal_label_margin();
  case 1: return o->vertical_label_margin();
  default: return o->label_image_spacing();
  }
}

void ofl_widget_set_label_margin(intptr_t w, int32_t which, int32_t px) {
  Fl_Widget *o = ofl::widget(w);
  switch (which) {
  case 0: o->horizontal_label_margin(px); break;
  case 1: o->vertical_label_margin(px); break;
  default: o->label_image_spacing(px); break;
  }
}

int32_t ofl_widget_labelcolor(intptr_t w) {
  return static_cast<int32_t>(ofl::widget(w)->labelcolor());
}

void ofl_widget_set_labelcolor(intptr_t w, int32_t c) {
  ofl::widget(w)->labelcolor(static_cast<Fl_Color>(c));
}

int32_t ofl_widget_labeltype(intptr_t w) {
  return ofl::widget(w)->labeltype();
}

// A multi-label's parts have their own types, so a widget showing one
// keeps it, and a file icon has a label that is no text. FlImages sets the
// types that make the label something else.
void ofl_widget_set_labeltype(intptr_t w, int32_t t) {
  Fl_Labeltype old = ofl::widget(w)->labeltype();
  if (old == _FL_MULTI_LABEL || old == _FL_ICON_LABEL) return;
  ofl::widget(w)->labeltype(static_cast<Fl_Labeltype>(t));
}

int32_t ofl_widget_align(intptr_t w) {
  return static_cast<int32_t>(ofl::widget(w)->align());
}

void ofl_widget_set_align(intptr_t w, int32_t a) {
  ofl::widget(w)->align(static_cast<Fl_Align>(a));
}

int32_t ofl_widget_when(intptr_t w) { return ofl::widget(w)->when(); }

void ofl_widget_set_when(intptr_t w, int32_t when) {
  ofl::widget(w)->when(static_cast<uchar>(when));
}

void ofl_widget_copy_tooltip(intptr_t w, const char *text) {
  ofl::widget(w)->copy_tooltip(text);
}

// The tooltip, a const char *, or 0 for none.
intptr_t ofl_widget_tooltip(intptr_t w) {
  return reinterpret_cast<intptr_t>(ofl::widget(w)->tooltip());
}

// Windows

int32_t ofl_window_shown(intptr_t w) {
  return ofl::as<Fl_Window>(w)->shown() ? 1 : 0;
}

// FLTK copies the name.
void ofl_window_set_xclass(intptr_t w, const char *name) {
  ofl::as<Fl_Window>(w)->xclass(name);
}

intptr_t ofl_window_xclass(intptr_t w) {
  return reinterpret_cast<intptr_t>(ofl::as<Fl_Window>(w)->xclass());
}

void ofl_window_wait_for_expose(intptr_t w) {
  ofl::as<Fl_Window>(w)->wait_for_expose();
}

void ofl_window_size_range(intptr_t w, int32_t minw, int32_t minh,
                           int32_t maxw, int32_t maxh) {
  ofl::as<Fl_Window>(w)->size_range(minw, minh, maxw, maxh);
}

void ofl_window_set_modal(intptr_t w) { ofl::as<Fl_Window>(w)->set_modal(); }

void ofl_window_set_non_modal(intptr_t w) {
  ofl::as<Fl_Window>(w)->set_non_modal();
}

int32_t ofl_window_modal(intptr_t w) {
  return ofl::as<Fl_Window>(w)->modal() ? 1 : 0;
}

void ofl_window_fullscreen(intptr_t w) { ofl::as<Fl_Window>(w)->fullscreen(); }

void ofl_window_fullscreen_off(intptr_t w) {
  ofl::as<Fl_Window>(w)->fullscreen_off();
}

// FLTK checks no screen number; any negative one is the window's own
// screen. Wayland ignores them (Fl_Wayland_Window_Driver::fullscreen_on).
void ofl_window_fullscreen_screens(intptr_t w, int32_t top, int32_t bottom,
                                   int32_t left, int32_t right) {
  ofl::as<Fl_Window>(w)->fullscreen_screens(top, bottom, left, right);
}

void ofl_window_iconize(intptr_t w) { ofl::as<Fl_Window>(w)->iconize(); }

void ofl_window_free_position(intptr_t w) {
  ofl::as<Fl_Window>(w)->free_position();
}

int32_t ofl_window_fullscreen_active(intptr_t w) {
  return ofl::as<Fl_Window>(w)->fullscreen_active() ? 1 : 0;
}

int32_t ofl_window_decorated_w(intptr_t w) {
  return ofl::as<Fl_Window>(w)->decorated_w();
}

int32_t ofl_window_decorated_h(intptr_t w) {
  return ofl::as<Fl_Window>(w)->decorated_h();
}

// Under Wayland, make_current of a window not shown is a fatal error
// (doc/fltk-issues.md, 77).
int32_t ofl_window_make_current(intptr_t w) {
  Fl_Window *win = ofl::as<Fl_Window>(w);
  if (!win->shown()) return 0;
  win->make_current();
  return 1;
}

void ofl_window_cursor(intptr_t w, int32_t c) {
  ofl::as<Fl_Window>(w)->cursor(static_cast<Fl_Cursor>(c));
}

// Colors, fonts and schemes

void ofl_set_color(int32_t i, int32_t c) {
  Fl::set_color(static_cast<Fl_Color>(i), static_cast<Fl_Color>(c));
}

void ofl_get_rgb(int32_t c, int32_t *r, int32_t *g, int32_t *b) {
  uchar cr, cg, cb;
  Fl::get_color(static_cast<Fl_Color>(c), cr, cg, cb);
  *r = cr;
  *g = cg;
  *b = cb;
}

int32_t ofl_menu_linespacing() { return Fl::menu_linespacing(); }

void ofl_set_menu_linespacing(int32_t n) { Fl::menu_linespacing(n); }

void ofl_shortcut_label(int32_t s, char *buf, int32_t n) {
  ofl::copy_out(fl_shortcut_label(static_cast<unsigned int>(s)), buf, n);
}

void ofl_background(int32_t r, int32_t g, int32_t b) {
  Fl::background(static_cast<uchar>(r), static_cast<uchar>(g), static_cast<uchar>(b));
}

void ofl_background2(int32_t r, int32_t g, int32_t b) {
  Fl::background2(static_cast<uchar>(r), static_cast<uchar>(g), static_cast<uchar>(b));
}

void ofl_foreground(int32_t r, int32_t g, int32_t b) {
  Fl::foreground(static_cast<uchar>(r), static_cast<uchar>(g), static_cast<uchar>(b));
}

int32_t ofl_color_average(int32_t c1, int32_t c2, double weight) {
  return static_cast<int32_t>(fl_color_average(
      static_cast<Fl_Color>(c1), static_cast<Fl_Color>(c2), static_cast<float>(weight)));
}

int32_t ofl_contrast(int32_t fg, int32_t bg) {
  return static_cast<int32_t>(
      fl_contrast(static_cast<Fl_Color>(fg), static_cast<Fl_Color>(bg)));
}

int32_t ofl_inactive(int32_t c) {
  return static_cast<int32_t>(fl_inactive(static_cast<Fl_Color>(c)));
}

int32_t ofl_normal_size(void) { return FL_NORMAL_SIZE; }
void ofl_set_normal_size(int32_t s) { FL_NORMAL_SIZE = s; }

// The box type b's border: what 0 dx, 1 dy, 2 dw, 3 dh. b is checked by
// the caller, since FLTK indexes its table of box types with it.
int32_t ofl_box_d(int32_t b, int32_t what) {
  Fl_Boxtype t = static_cast<Fl_Boxtype>(b);
  switch (what) {
    case 0: return Fl::box_dx(t);
    case 1: return Fl::box_dy(t);
    case 2: return Fl::box_dw(t);
    default: return Fl::box_dh(t);
  }
}

// name is "none", "base", "plastic", "gtk+", "gleam" or "oxy"; 1 if FLTK
// knows it.
// Screens. what: 0 x, 1 y, 2 w, 3 h of the main screen's work area.
int32_t ofl_screen(int32_t what) {
  switch (what) {
    case 1: return Fl::y();
    case 2: return Fl::w();
    case 3: return Fl::h();
    default: return Fl::x();
  }
}

int32_t ofl_screen_count() { return Fl::screen_count(); }

int32_t ofl_scrollbar_size() { return Fl::scrollbar_size(); }

void ofl_set_scrollbar_size(int32_t n) { Fl::scrollbar_size(n); }

// Screen n's place and size, or its work area if work is 1.
void ofl_screen_xywh(int32_t n, int32_t work, int32_t *x, int32_t *y,
                     int32_t *w, int32_t *h) {
  int X, Y, W, H;
  if (work) {
    Fl::screen_work_area(X, Y, W, H, n);
  } else {
    Fl::screen_xywh(X, Y, W, H, n);
  }
  *x = X;
  *y = Y;
  *w = W;
  *h = H;
}

int32_t ofl_screen_num(int32_t x, int32_t y) { return Fl::screen_num(x, y); }

// Command-line options. FLTK keeps pointers into argv (the title, the
// geometry, the class name) until a window is shown with them, and C's
// own argv, which poc's Args.argv is, lasts the program's life.

namespace {
int32_t (*arg_handler)(int32_t);

// FLTK's Fl_Args_Handler, giving the program's handler the argument's
// number; the handler's result, checked by Fl.Mod, is the words it used.
int handle_arg(int, char **, int &i) {
  int n = arg_handler(i);
  i += n;
  return n;
}

char **argv_of(intptr_t argv) { return reinterpret_cast<char **>(argv); }
}  // namespace

// Fl::args with handler (0 for none), *i the first argument not parsed:
// 1 unless that is an option no one knows, or lacks its value. Fl::args
// says so by returning 0, but only until it has once stopped at a word
// that isn't an option (doc/fltk-issues.md, 57), so this decides it from
// the word, as Fl::arg does.
int32_t ofl_args(int32_t argc, intptr_t argv, int32_t *i,
                 int32_t (*handler)(int32_t)) {
  arg_handler = handler;
  int n = 1;
  Fl::args(argc, argv_of(argv), n, handler ? handle_arg : 0);
  *i = n;
  const char *s = n < argc ? argv_of(argv)[n] : 0;
  return !(s && s[0] == '-' && s[1] != 0 && s[1] != '-');
}

int32_t ofl_arg(int32_t argc, intptr_t argv, int32_t i) {
  int n = i;
  return Fl::arg(argc, argv_of(argv), n);
}

intptr_t ofl_args_help() { return reinterpret_cast<intptr_t>(Fl::help); }

void ofl_window_show_args(intptr_t w, int32_t argc, intptr_t argv) {
  ofl::as<Fl_Window>(w)->show(argc, argv_of(argv));
}

// 1 if a program was started to open uri; msg, n bytes, gets its command,
// or why not.
int32_t ofl_open_uri(const char *uri, char *msg, int32_t n) {
  if (n > 0) msg[0] = 0;
  return fl_open_uri(uri, msg, n) != 0;
}

// What this FLTK has, as Fl numbers it (Has). FLTK_USE_SVG is tested
// with defined(), as FLTK's source does: CMake's FLTK_OPTION_SVG=OFF
// defines it as 0 and leaves the class in, and only configure's
// --disable-svg takes it out (doc/fltk-issues.md, 73).
int32_t ofl_has(int32_t feature) {
  switch (feature) {
#if defined(FLTK_USE_SVG)
    case 0: return 1;
#endif
    case 1: return wayland();
    case 2: return !wayland();
    default: return 0;
  }
}

int32_t ofl_set_scheme(const char *name) { return Fl::scheme(name); }

// NULL is the system's scheme (Fl_Screen_Driver::get_system_scheme).
int32_t ofl_set_system_scheme(void) { return Fl::scheme(NULL); }

// The scheme's name, a const char *, or 0 for none.
intptr_t ofl_scheme(void) { return reinterpret_cast<intptr_t>(Fl::scheme()); }

int32_t ofl_scheme_count(void) { return Fl_Scheme::num_schemes(); }

// Scheme i's name, a const char *, which FLTK keeps.
intptr_t ofl_scheme_name(int32_t i) {
  return reinterpret_cast<intptr_t>(Fl_Scheme::names()[i]);
}

// FLTK copies name.
int32_t ofl_add_scheme_name(const char *name) {
  return Fl_Scheme::add_scheme_name(name);
}

// A table's children are its cells' widgets, in an inner Fl_Scroll;
// Fl_Table's begin(), end(), children() and the rest reach them, but
// hide Fl_Group's rather than overriding them, so a table must be called
// as one (doc/fltk-issues.md, 52). Fl_Group's own would reach the
// table's scrollbars and the inner group.
static Fl_Table *table(intptr_t g) {
  return dynamic_cast<Fl_Table *>(ofl::widget(g));
}

void ofl_group_begin(intptr_t g) {
  if (Fl_Table *t = table(g)) {
    t->begin();
  } else {
    ofl::as<Fl_Group>(g)->begin();
  }
}

// Fl_Flex::end also asks for a layout, and Fl_Table::end shows the inner
// group if it has children, but each hides Fl_Group's rather than
// overriding it, so each must be called as itself.
void ofl_group_end(intptr_t g) {
  Fl_Flex *flex = dynamic_cast<Fl_Flex *>(ofl::widget(g));
  if (flex) {
    flex->end();
  } else if (Fl_Table *t = table(g)) {
    t->end();
  } else {
    ofl::as<Fl_Group>(g)->end();
  }
}

int32_t ofl_group_children(intptr_t g) {
  if (Fl_Table *t = table(g)) return t->children();
  return ofl::as<Fl_Group>(g)->children();
}

static Fl_Widget *child(intptr_t g, int i) {
  if (Fl_Table *t = table(g)) return t->child(i);
  return ofl::as<Fl_Group>(g)->child(i);
}

// The Oberon object of child i, or 0 (ofl::object_of).
intptr_t ofl_group_child(intptr_t g, int32_t i) {
  return ofl::object_of(child(g, i));
}

// Fl_Group::draw_child is protected, but a class derived from Fl_Group
// may name it, and the pointer to member that gives works on any group.
struct Draws_child : Fl_Group {
  using Fl_Group::draw_child;
};

void ofl_group_draw_child(intptr_t g, intptr_t w) {
  void (Fl_Group::*draw)(Fl_Widget &) const = &Draws_child::draw_child;
  (ofl::as<Fl_Group>(g)->*draw)(*ofl::widget(w));
}

void ofl_group_add(intptr_t g, intptr_t w) {
  if (Fl_Table *t = table(g)) {
    t->add(ofl::widget(w));
  } else {
    ofl::as<Fl_Group>(g)->add(ofl::widget(w));
  }
}

void ofl_group_insert(intptr_t g, intptr_t w, int32_t i) {
  if (Fl_Table *t = table(g)) {
    t->insert(*ofl::widget(w), i);
  } else {
    ofl::as<Fl_Group>(g)->insert(*ofl::widget(w), i);
  }
}

void ofl_group_remove(intptr_t g, intptr_t w) {
  if (Fl_Table *t = table(g)) {
    t->remove(*ofl::widget(w));
  } else {
    ofl::as<Fl_Group>(g)->remove(ofl::widget(w));
  }
}

// The index of w among g's children, or children() if it isn't one.
int32_t ofl_group_find(intptr_t g, intptr_t w) {
  if (Fl_Table *t = table(g)) return t->find(ofl::widget(w));
  return ofl::as<Fl_Group>(g)->find(ofl::widget(w));
}

// Deletes every child pofltk opened, later inside a dispatch, as
// ofl_widget_delete does. Outside one, a group already queued goes now,
// with its children, as FLTK runs the queue. Not Fl_Group::clear: some groups' children
// are FLTK's own members, not on the heap (a scroll's scrollbars, a
// spinner's field and buttons), which it would delete. Fl_Scroll::clear
// and Fl_Pack::clear allow for that, but hide Fl_Group's rather than
// overriding it. A pack's resizable goes back to none, as
// Fl_Pack::clear leaves it. A table keeps its rows and columns.
void ofl_group_clear(intptr_t g) {
  if (ofl::depth == 0) {
    bool gone = ofl::going(ofl::widget(g));
    ofl::flush();
    if (gone) return;
  }
  for (int i = ofl_group_children(g); i-- > 0;) {
    Fl_Widget *c = child(g, i);
    if (ofl::object_of(c) == 0) continue;
    ofl::delete_widget(c);
  }
  Fl_Group *group = ofl::as<Fl_Group>(g);
  if (dynamic_cast<Fl_Pack *>(group)) group->resizable(0);
}

// Forgets the sizes g saved of itself and its children, so that the next
// resize starts from where they are now. Fl_Table::init_sizes reaches
// its inner group, but hides Fl_Group's.
void ofl_group_init_sizes(intptr_t g) {
  if (Fl_Table *t = table(g)) {
    t->init_sizes();
  } else {
    ofl::as<Fl_Group>(g)->init_sizes();
  }
}

// w is 0 for none.
void ofl_group_set_resizable(intptr_t g, intptr_t w) {
  ofl::as<Fl_Group>(g)->resizable(ofl::widget(w));
}

intptr_t ofl_group_resizable(intptr_t g) {
  return ofl::object_of(ofl::as<Fl_Group>(g)->resizable());
}

// Events: the one being handled (Fl::event_x and friends), and the
// widgets that have the focus, the mouse, and the button held.

int32_t ofl_event(void) { return Fl::event(); }
int32_t ofl_event_x(void) { return Fl::event_x(); }
int32_t ofl_event_y(void) { return Fl::event_y(); }
int32_t ofl_event_x_root(void) { return Fl::event_x_root(); }
int32_t ofl_event_y_root(void) { return Fl::event_y_root(); }
int32_t ofl_event_dx(void) { return Fl::event_dx(); }
int32_t ofl_event_dy(void) { return Fl::event_dy(); }
int32_t ofl_event_button(void) { return Fl::event_button(); }
int32_t ofl_event_clicks(void) { return Fl::event_clicks(); }
void ofl_set_event_clicks(int32_t n) { Fl::event_clicks(n); }
int32_t ofl_event_is_click(void) { return Fl::event_is_click(); }
void ofl_event_is_click_off(void) { Fl::event_is_click(0); }
int32_t ofl_event_key(void) { return Fl::event_key(); }
int32_t ofl_event_original_key(void) { return Fl::event_original_key(); }
int32_t ofl_event_key_down(int32_t k) { return Fl::event_key(k); }
int32_t ofl_get_key(int32_t k) { return Fl::get_key(k); }
int32_t ofl_event_state(void) { return Fl::event_state(); }

// The text of a key or paste event, a const char * (never 0), of
// ofl_event_length() bytes.
intptr_t ofl_event_text(void) {
  return reinterpret_cast<intptr_t>(Fl::event_text());
}

int32_t ofl_event_length(void) { return Fl::event_length(); }

// The clipboard and drag and drop. destination and source: 0 the
// selection buffer, 1 the clipboard, 2 (copy) both.

// Each opens the display first: FLTK 1.4.5's X11 driver uses it without
// opening it, and crashes when no window has yet been shown
// (doc/fltk-issues.md, 49).

// Fl::copy copies the n bytes at text.
void ofl_copy(const char *text, int32_t n, int32_t destination) {
  fl_open_display();
  Fl::copy(text, n, destination, Fl::clipboard_plain_text);
}

// FLTK's own record of the sources the program owns, in both drivers.
// It is in no header, but exported.
extern char fl_i_own_selection[2];

// image: 0 text, 1 an image. Under X11, another program's data is asked
// for through Fl::first_window. With no window shown, FLTK asks with
// window 0 anyway, and the X server's BadWindow error is printed, so
// pofltk doesn't ask: the paste does nothing, as it would have.
void ofl_paste(intptr_t receiver, int32_t source, int32_t image) {
  if (!wayland() && !Fl::first_window() &&
      !fl_i_own_selection[source ? 1 : 0])
    return;
  Fl::paste(*ofl::widget(receiver), source,
            image ? Fl::clipboard_image : Fl::clipboard_plain_text);
}

int32_t ofl_clipboard_contains(int32_t image) {
  fl_open_display();
  return Fl::clipboard_contains(image ? Fl::clipboard_image
                                      : Fl::clipboard_plain_text);
}

// 1 if the EvPaste being handled carries an image (Fl::event_clipboard).
int32_t ofl_event_is_image(void) {
  return Fl::event_clipboard_type() == Fl::clipboard_image &&
         Fl::event_clipboard() != 0;
}

int32_t ofl_dnd(void) { return Fl::dnd(); }

// what: 0 get, 1 set off, 2 set on.
int32_t ofl_dnd_text_ops(int32_t what) {
  if (what) Fl::dnd_text_ops(what == 2);
  return Fl::dnd_text_ops();
}

// Fl::option: what 0 get, 1 set off, 2 set on. FLTK reads the saved
// options first, so one set here stays set.
int32_t ofl_option(int32_t o, int32_t what) {
  Fl::Fl_Option opt = static_cast<Fl::Fl_Option>(o);
  if (what) Fl::option(opt, what == 2);
  return Fl::option(opt);
}

int32_t ofl_event_inside(int32_t x, int32_t y, int32_t w, int32_t h) {
  return Fl::event_inside(x, y, w, h);
}

// Tooltips: FLTK's settings for all of them.

// what: 0 delay, 1 hide delay, 2 hover delay.
double ofl_tooltip_delay(int32_t what) {
  switch (what) {
    case 0: return Fl_Tooltip::delay();
    case 1: return Fl_Tooltip::hidedelay();
    default: return Fl_Tooltip::hoverdelay();
  }
}

void ofl_tooltip_set_delay(int32_t what, double v) {
  float f = static_cast<float>(v);
  switch (what) {
    case 0: Fl_Tooltip::delay(f); break;
    case 1: Fl_Tooltip::hidedelay(f); break;
    default: Fl_Tooltip::hoverdelay(f); break;
  }
}

// what: 0 font, 1 size, 2 color, 3 text color, 4 margin width, 5 margin
// height, 6 wrap width, 7 enabled.
int32_t ofl_tooltip_setting(int32_t what) {
  switch (what) {
    case 0: return Fl_Tooltip::font();
    case 1: return Fl_Tooltip::size();
    case 2: return static_cast<int32_t>(Fl_Tooltip::color());
    case 3: return static_cast<int32_t>(Fl_Tooltip::textcolor());
    case 4: return Fl_Tooltip::margin_width();
    case 5: return Fl_Tooltip::margin_height();
    case 6: return Fl_Tooltip::wrap_width();
    default: return Fl_Tooltip::enabled();
  }
}

void ofl_tooltip_set_setting(int32_t what, int32_t v) {
  switch (what) {
    case 0: Fl_Tooltip::font(v); break;
    case 1: Fl_Tooltip::size(v); break;
    case 2: Fl_Tooltip::color(static_cast<Fl_Color>(v)); break;
    case 3: Fl_Tooltip::textcolor(static_cast<Fl_Color>(v)); break;
    case 4: Fl_Tooltip::margin_width(v); break;
    case 5: Fl_Tooltip::margin_height(v); break;
    case 6: Fl_Tooltip::wrap_width(v); break;
    default: Fl_Tooltip::enable(v); break;
  }
}

// The Oberon object of the tooltip's widget, or 0 (ofl::object_of).
// FLTK forgets a widget as it dies (fl_throw_focus), so this is never
// stale.
intptr_t ofl_tooltip_current(void) {
  return ofl::object_of(Fl_Tooltip::current());
}

void ofl_tooltip_set_current(intptr_t w) {
  Fl_Tooltip::current(w ? ofl::widget(w) : 0);
}

// Fl_Tooltip::enter_area keeps the text, so this keeps a copy
// (doc/fltk-issues.md, 75). The same text must stay the same pointer, by
// which FLTK knows the tip it is showing already. FLTK still holds the
// last text after "", and after a text given while tooltips are off, in
// its tip and its tooltip window's label: the copy goes only when FLTK
// has taken another, and the last at exit.
namespace {
struct KeptTip {
  char *text;
  ~KeptTip() { free(text); }
};
KeptTip kept_tip = {0};
}

void ofl_tooltip_enter_area(intptr_t w, int32_t x, int32_t y, int32_t width,
                            int32_t height, const char *text) {
  char *&kept = kept_tip.text;
  Fl_Widget *wid = ofl::widget(w);
  if (!*text) {
    Fl_Tooltip::enter_area(wid, x, y, width, height, 0);
  } else if (kept && !strcmp(kept, text)) {
    Fl_Tooltip::enter_area(wid, x, y, width, height, kept);
  } else {
    char *copy = strdup(text);
    if (!copy) return;
    Fl_Tooltip::enter_area(wid, x, y, width, height, copy);
    // FLTK took it if tooltips are on (but not inside its own timer, as it
    // shows a tip, which no Oberon code runs in). wid needn't be current
    // after: hiding the last tip's window can clear that.
    if (Fl_Tooltip::enabled()) {
      free(kept);
      kept = copy;
    } else {
      free(copy);
    }
  }
}

// Each the Oberon object, or 0 (ofl::object_of).
intptr_t ofl_focus(void) { return ofl::object_of(Fl::focus()); }
intptr_t ofl_belowmouse(void) { return ofl::object_of(Fl::belowmouse()); }
intptr_t ofl_pushed(void) { return ofl::object_of(Fl::pushed()); }

// w is 0 for none. The display is opened first, as for take_focus.
void ofl_set_focus(intptr_t w) {
  fl_open_display();
  Fl::focus(ofl::widget(w));
}

// The event loop

int32_t ofl_run(void) { return Fl::run(); }
int32_t ofl_check(void) { return Fl::check(); }
void ofl_wait(double seconds) { Fl::wait(seconds); }

void ofl_add_timeout(double seconds, intptr_t self) {
  Fl::add_timeout(seconds, timeout_trampoline, reinterpret_cast<void *>(self));
}

void ofl_repeat_timeout(double seconds, intptr_t self) {
  Fl::repeat_timeout(seconds, timeout_trampoline,
                     reinterpret_cast<void *>(self));
}

void ofl_remove_timeout(intptr_t self) {
  Fl::remove_timeout(timeout_trampoline, reinterpret_cast<void *>(self));
}

void ofl_flush(void) {
  fl_open_display();
  Fl::flush();
}

// Under X11 with no display open FLTK reads through a null pointer
// (doc/fltk-issues.md, 131).
int32_t ofl_ready(void) {
  fl_open_display();
  return Fl::ready();
}

void ofl_add_check(intptr_t self) {
  Fl::add_check(check_trampoline, reinterpret_cast<void *>(self));
}

void ofl_remove_check(intptr_t self) {
  Fl::remove_check(check_trampoline, reinterpret_cast<void *>(self));
}

void ofl_run_checks(void) { Fl::run_checks(); }
void ofl_run_idle(void) { Fl::run_idle(); }
int32_t ofl_program_should_quit(void) { return Fl::program_should_quit(); }
void ofl_set_program_should_quit(int32_t q) { Fl::program_should_quit(q); }
void ofl_hide_all_windows(void) { Fl::hide_all_windows(); }
int32_t ofl_damage_any(void) { return Fl::damage(); }

// The first window shown from w on with an Oberon object, or 0.
static intptr_t oberon_window(Fl_Window *w) {
  while (w && !ofl::object_of(w)) w = Fl::next_window(w);
  return ofl::object_of(w);
}

intptr_t ofl_first_window(void) { return oberon_window(Fl::first_window()); }

// Fl::next_window of a window not shown is an Fl::error.
intptr_t ofl_next_window(intptr_t w) {
  Fl_Window *win = ofl::as<Fl_Window>(w);
  return win->shown() ? oberon_window(Fl::next_window(win)) : 0;
}

void ofl_set_first_window(intptr_t w) {
  Fl::first_window(ofl::as<Fl_Window>(w));
}

void ofl_set_atclose(int32_t on) {
  Fl::set_atclose(on ? atclose_trampoline : Fl::default_atclose);
}

void ofl_default_atclose(intptr_t w) {
  Fl_Window *win = ofl::as<Fl_Window>(w);
  Fl::default_atclose(win, win->user_data());
}

void ofl_set_abort(int32_t on) {
  if (!fltk_abort) fltk_abort = Fl::fatal;
  Fl::set_abort(on ? abort_trampoline : fltk_abort);
}

// Time

void ofl_now(double offset, double *sec, int32_t *usec) {
  Fl_Timestamp t = Fl::now(offset);
  *sec = static_cast<double>(t.sec);
  *usec = t.usec;
}

static Fl_Timestamp stamp(double sec, int32_t usec) {
  Fl_Timestamp t;
  t.sec = static_cast<time_t>(sec);
  t.usec = usec;
  return t;
}

double ofl_seconds_since(double sec, int32_t usec) {
  Fl_Timestamp t = stamp(sec, usec);
  return Fl::seconds_since(t);
}

double ofl_seconds_between(double s1, int32_t u1, double s2, int32_t u2) {
  Fl_Timestamp t1 = stamp(s1, u1), t2 = stamp(s2, u2);
  return Fl::seconds_between(t1, t2);
}

intptr_t ofl_ticks_since(double sec, int32_t usec) {
  Fl_Timestamp t = stamp(sec, usec);
  return Fl::ticks_since(t);
}

intptr_t ofl_ticks_between(double s1, int32_t u1, double s2, int32_t u2) {
  Fl_Timestamp t1 = stamp(s1, u1), t2 = stamp(s2, u2);
  return Fl::ticks_between(t1, t2);
}

// Fonts (doc/fltk-issues.md, 130)

int32_t ofl_font_end(void) { return font_end; }

intptr_t ofl_get_font(int32_t f) {
  return reinterpret_cast<intptr_t>(Fl::get_font(static_cast<Fl_Font>(f)));
}

// A number with no font has no name; Cairo's driver copies it unchecked.
intptr_t ofl_get_font_name(int32_t f, int32_t *attributes) {
  int a = 0;
  *attributes = 0;
  if (!Fl::get_font(static_cast<Fl_Font>(f))) return 0;
  const char *name = Fl::get_font_name(static_cast<Fl_Font>(f), &a);
  *attributes = a;
  return reinterpret_cast<intptr_t>(name);
}

int32_t ofl_get_font_sizes(int32_t f, int32_t *sizes, int32_t n) {
  int *found;
  int count = Fl::get_font_sizes(static_cast<Fl_Font>(f), found);
  if (count > n) count = n;
  for (int i = 0; i < count; i++) sizes[i] = found[i];
  return count;
}

void ofl_set_font(int32_t f, const char *name) { set_font(f, name); }

// Fl::set_font(to, from) shares from's name, which set_font frees when
// from is set again, so to has a copy. 0 if from has no font.
int32_t ofl_set_font_from(int32_t to, int32_t from) {
  const char *name = Fl::get_font(static_cast<Fl_Font>(from));
  if (!name) return 0;
  if (to != from) set_font(to, name);
  return 1;
}

int32_t ofl_set_fonts(void) {
  int n = Fl::set_fonts(0);
  if (n > font_end) font_end = n;
  return n;
}

// Colors and boxes

int32_t ofl_contrast_mode(void) { return fl_contrast_mode(); }
void ofl_set_contrast_mode(int32_t mode) { fl_contrast_mode(mode); }
int32_t ofl_contrast_level(void) { return fl_contrast_level(); }
void ofl_set_contrast_level(int32_t level) { fl_contrast_level(level); }

void ofl_set_contrast_function(Fl_Contrast_Function *f) {
  fl_contrast_function(f);
}

int32_t ofl_contrast_sized(int32_t fg, int32_t bg, int32_t context,
                           int32_t size) {
  return static_cast<int32_t>(fl_contrast(static_cast<Fl_Color>(fg),
                                          static_cast<Fl_Color>(bg), context,
                                          size));
}

double ofl_lightness(int32_t c) {
  return fl_lightness(static_cast<Fl_Color>(c));
}

double ofl_luminance(int32_t c) {
  return fl_luminance(static_cast<Fl_Color>(c));
}

// fl_box, fl_down and fl_frame, by what (0, 1, 2).
int32_t ofl_box_kind(int32_t b, int32_t what) {
  Fl_Boxtype t = static_cast<Fl_Boxtype>(b);
  return what == 0 ? fl_box(t) : what == 1 ? fl_down(t) : fl_frame(t);
}

int32_t ofl_parse_color(const char *name, int32_t *r, int32_t *g, int32_t *b) {
  uchar cr = 0, cg = 0, cb = 0;
  fl_open_display();
  if (!fl_parse_color(name, cr, cg, cb)) return 0;
  *r = cr;
  *g = cg;
  *b = cb;
  return 1;
}

int32_t ofl_modifier(int32_t control) {
  return control ? fl_control_modifier() : fl_command_modifier();
}

void ofl_set_boxtype(int32_t b, Fl_Box_Draw_F *draw, int32_t dx, int32_t dy,
                     int32_t dw, int32_t dh) {
  Fl::set_boxtype(static_cast<Fl_Boxtype>(b), draw, static_cast<uchar>(dx),
                  static_cast<uchar>(dy), static_cast<uchar>(dw),
                  static_cast<uchar>(dh));
}

void ofl_set_boxtype_from(int32_t to, int32_t from) {
  Fl::set_boxtype(static_cast<Fl_Boxtype>(to), static_cast<Fl_Boxtype>(from));
}

Fl_Box_Draw_F *ofl_get_boxtype(int32_t b) {
  return Fl::get_boxtype(static_cast<Fl_Boxtype>(b));
}

int32_t ofl_box_color(int32_t c) {
  return static_cast<int32_t>(Fl::box_color(static_cast<Fl_Color>(c)));
}

// There is no driver until the display is open (doc/fltk-issues.md, 131).
void ofl_set_box_color(int32_t c) {
  fl_open_display();
  Fl::set_box_color(static_cast<Fl_Color>(c));
}

int32_t ofl_draw_box_active(void) { return Fl::draw_box_active(); }
int32_t ofl_box_border_radius_max(void) { return Fl::box_border_radius_max(); }
void ofl_set_box_border_radius_max(int32_t r) { Fl::box_border_radius_max(r); }
int32_t ofl_box_shadow_width(void) { return Fl::box_shadow_width(); }
void ofl_set_box_shadow_width(int32_t w) { Fl::box_shadow_width(w); }

void ofl_free_color(int32_t c, int32_t overlay) {
  Fl::free_color(static_cast<Fl_Color>(c), overlay);
}

void ofl_get_system_colors(void) { Fl::get_system_colors(); }
void ofl_own_colormap(void) { Fl::own_colormap(); }
int32_t ofl_visual(int32_t mode) { return Fl::visual(mode); }
int32_t ofl_is_scheme(const char *name) { return Fl::is_scheme(name); }
int32_t ofl_reload_scheme(void) { return Fl::reload_scheme(); }

// Events

int32_t ofl_callback_reason(void) { return Fl::callback_reason(); }

// names.h's tables, which it defines in each file including it. A number
// outside a table, or one of the reasons' gaps (NULL), has no name.
extern "C++" {
template <size_t N>
static intptr_t name_in(const char * const (&table)[N], int32_t i) {
  return i >= 0 && size_t(i) < N ? (intptr_t)table[i] : 0;
}
}
intptr_t ofl_event_name(int32_t e) { return name_in(fl_eventnames, e); }
intptr_t ofl_font_const_name(int32_t f) { return name_in(fl_fontnames, f); }
intptr_t ofl_reason_name(int32_t r) { return name_in(fl_callback_reason_names, r); }

int32_t ofl_compose(int32_t *del) {
  int d = 0;
  int r = Fl::compose(d);
  *del = d;
  return r;
}

void ofl_compose_reset(void) { Fl::compose_reset(); }
int32_t ofl_test_shortcut(int32_t s) { return Fl::test_shortcut(s); }

void ofl_get_mouse(int32_t *x, int32_t *y) {
  int cx = 0, cy = 0;
  Fl::get_mouse(cx, cy);
  *x = cx;
  *y = cy;
}

intptr_t ofl_grab(void) { return ofl::object_of(Fl::grab()); }

// w is 0 to release. Under X11 FLTK grabs for its first window shown,
// reading through a null pointer if there is none, so Fl has checked w.
void ofl_set_grab(intptr_t w) {
  fl_open_display();
  Fl::grab(w ? ofl::as<Fl_Window>(w) : 0);
}

// A dispatch, so that a widget deleted by the event goes later, not
// under Fl::handle.
int32_t ofl_handle_event(int32_t event, intptr_t w) {
  ofl::Dispatch d;
  return Fl::handle(event, ofl::as<Fl_Window>(w));
}

// The selection

void ofl_selection(intptr_t owner, const char *text, int32_t n) {
  fl_open_display();  // as ofl_copy
  Fl::selection(*ofl::widget(owner), text, n);
}

intptr_t ofl_selection_owner(void) {
  return ofl::object_of(Fl::selection_owner());
}

void ofl_set_selection_owner(intptr_t w) {
  Fl::selection_owner(w ? ofl::widget(w) : 0);
}

int32_t ofl_selection_to_clipboard(void) {
  return Fl::selection_to_clipboard();
}

void ofl_set_selection_to_clipboard(int32_t on) {
  Fl::selection_to_clipboard(on);
}

void ofl_clipboard_notify(int32_t on) {
  fl_open_display();
  if (on) {
    Fl::add_clipboard_notify(clipboard_trampoline);
  } else {
    Fl::remove_clipboard_notify(clipboard_trampoline);
  }
}

// Screens and input

void ofl_screen_dpi(int32_t n, double *h, double *v) {
  float ch = 0, cv = 0;
  Fl::screen_dpi(ch, cv, n);
  *h = ch;
  *v = cv;
}

double ofl_screen_scale(int32_t n) { return Fl::screen_scale(n); }

void ofl_set_screen_scale(int32_t n, double factor) {
  fl_open_display();
  Fl::screen_scale(n, static_cast<float>(factor));
}

int32_t ofl_screen_scaling_supported(void) {
  return Fl::screen_scaling_supported();
}

void ofl_keyboard_screen_scaling(int32_t on) {
  Fl::keyboard_screen_scaling(on);
}

// Wayland's driver reads through a null pointer with no display open
// (doc/fltk-issues.md, 131).
void ofl_enable_im(int32_t on) {
  fl_open_display();
  if (on) {
    Fl::enable_im();
  } else {
    Fl::disable_im();
  }
}

// The version

double ofl_version(void) { return Fl::version(); }
int32_t ofl_api_version(void) { return Fl::api_version(); }
int32_t ofl_abi_version(void) { return Fl::abi_version(); }
int32_t ofl_abi_check(void) { return Fl::abi_check(FL_ABI_VERSION); }
// The headers' versions, which pofltk's C++ parts were compiled with.
double ofl_built_version(void) { return FL_VERSION; }
int32_t ofl_built_api_version(void) { return FL_API_VERSION; }
int32_t ofl_built_abi_version(void) { return FL_ABI_VERSION; }

}  // extern "C"
