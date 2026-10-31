// The C++ part of FlCairo: a double window drawn with cairo, and the part
// of cairo FlCairo binds. See pofltk.h for the conventions.
//
// This isn't Fl_Cairo_Window, which only an FLTK built for it has. X11's
// way of making a context needs nothing of FLTK but the window, and
// Wayland's needs only fl_wl_gc(), so a window of ours draws on every
// FLTK, and with a context of its own (doc/fltk-issues.md, 114).

#include "../pofltk.h"

#include <FL/Fl_Double_Window.H>
#include <FL/Fl_Device.H>
#include <FL/platform.H>

#include <cairo.h>
#if defined(FLTK_USE_X11)
#include <cairo-xlib.h>
#endif

namespace {

typedef void (*DrawCairoFn)(intptr_t self, intptr_t context);

// The Oberon dispatcher, which FlCairo's body registers.
DrawCairoFn on_draw_cairo;

// A context on the surface FLTK is drawing this window on: the offscreen
// buffer, whatever the back end. A cairo error stays in its context, so
// one made for each draw keeps a program's errors, and any Save it leaves,
// out of the next draw and out of FLTK's own drawing.
cairo_t *make_context(Fl_Window *w) {
#if defined(FLTK_USE_WAYLAND)
  if (fl_wl_display()) {
    cairo_t *fltk = fl_wl_gc();
    cairo_t *c = cairo_create(cairo_get_target(fltk));
    cairo_matrix_t m;
    cairo_get_matrix(fltk, &m);  // the display's scale
    cairo_set_matrix(c, &m);
    return c;
  }
#endif
#if defined(FLTK_USE_X11)
  float scale = Fl::screen_scale(w->screen_num());
  cairo_surface_t *s = cairo_xlib_surface_create(
      fl_display, fl_window, fl_visual->visual, static_cast<int>(w->w() * scale),
      static_cast<int>(w->h() * scale));
  cairo_t *c = cairo_create(s);
  cairo_surface_destroy(s);  // c holds it
  cairo_scale(c, scale, scale);
  return c;
#else
  (void)w;
  return 0;
#endif
}

// Cairo's part comes after the widgets', in the place Fl_Cairo_Window's
// is, so that W<Cw> sends it through a program's Draw and its call of
// the base's.
class Cw : public Fl_Double_Window {
public:
  using Fl_Double_Window::Fl_Double_Window;
  void draw() override {
    Fl_Double_Window::draw();
    // On another surface fl_window and fl_wl_gc() aren't that surface's
    // (doc/fltk-issues.md, 114).
    if (!user_data() ||
        Fl_Surface_Device::surface() != Fl_Display_Device::display_device())
      return;
    cairo_t *c = make_context(this);
    if (!c) return;
    {
      ofl::Dispatch d;
      on_draw_cairo(ofl::self_of(this), reinterpret_cast<intptr_t>(c));
    }
    cairo_surface_flush(cairo_get_target(c));
    cairo_destroy(c);
  }
};

typedef ofl::W<Cw> Win;

cairo_t *cr(intptr_t c) { return reinterpret_cast<cairo_t *>(c); }
cairo_pattern_t *pat(intptr_t p) {
  return reinterpret_cast<cairo_pattern_t *>(p);
}

}  // namespace

extern "C" {

void ofl_cairo_register(DrawCairoFn draw) { on_draw_cairo = draw; }

intptr_t ofl_cairo_window_new(int32_t placed, int32_t x, int32_t y, int32_t w,
                              int32_t h, const char *label, intptr_t self) {
  Win *win = placed ? new Win(x, y, w, h) : new Win(w, h);
  win->copy_label(ofl::label_text(label));
  return ofl::open(win, self);
}

int32_t ofl_cairo_status(intptr_t c) { return cairo_status(cr(c)); }

void ofl_cairo_save(intptr_t c) { cairo_save(cr(c)); }
void ofl_cairo_restore(intptr_t c) { cairo_restore(cr(c)); }

void ofl_cairo_translate(intptr_t c, double x, double y) {
  cairo_translate(cr(c), x, y);
}
void ofl_cairo_scale(intptr_t c, double x, double y) {
  cairo_scale(cr(c), x, y);
}
void ofl_cairo_rotate(intptr_t c, double angle) { cairo_rotate(cr(c), angle); }

void ofl_cairo_set_line_width(intptr_t c, double width) {
  cairo_set_line_width(cr(c), width);
}
void ofl_cairo_set_antialias(intptr_t c, int32_t mode) {
  cairo_set_antialias(cr(c), static_cast<cairo_antialias_t>(mode));
}
void ofl_cairo_set_source_rgba(intptr_t c, double r, double g, double b,
                               double a) {
  cairo_set_source_rgba(cr(c), r, g, b, a);
}
void ofl_cairo_set_source(intptr_t c, intptr_t p) {
  cairo_set_source(cr(c), pat(p));
}

void ofl_cairo_new_path(intptr_t c) { cairo_new_path(cr(c)); }
void ofl_cairo_close_path(intptr_t c) { cairo_close_path(cr(c)); }
void ofl_cairo_move_to(intptr_t c, double x, double y) {
  cairo_move_to(cr(c), x, y);
}
void ofl_cairo_line_to(intptr_t c, double x, double y) {
  cairo_line_to(cr(c), x, y);
}
void ofl_cairo_curve_to(intptr_t c, double x1, double y1, double x2, double y2,
                        double x3, double y3) {
  cairo_curve_to(cr(c), x1, y1, x2, y2, x3, y3);
}
void ofl_cairo_rectangle(intptr_t c, double x, double y, double w, double h) {
  cairo_rectangle(cr(c), x, y, w, h);
}
void ofl_cairo_arc(intptr_t c, double x, double y, double radius, double from,
                   double to) {
  cairo_arc(cr(c), x, y, radius, from, to);
}

void ofl_cairo_stroke(intptr_t c, int32_t preserve) {
  if (preserve) {
    cairo_stroke_preserve(cr(c));
  } else {
    cairo_stroke(cr(c));
  }
}
void ofl_cairo_fill(intptr_t c, int32_t preserve) {
  if (preserve) {
    cairo_fill_preserve(cr(c));
  } else {
    cairo_fill(cr(c));
  }
}
void ofl_cairo_paint(intptr_t c) { cairo_paint(cr(c)); }
void ofl_cairo_clip(intptr_t c) { cairo_clip(cr(c)); }

void ofl_cairo_select_font_face(intptr_t c, const char *family, int32_t slant,
                                int32_t weight) {
  cairo_select_font_face(cr(c), family, static_cast<cairo_font_slant_t>(slant),
                         static_cast<cairo_font_weight_t>(weight));
}
void ofl_cairo_set_font_size(intptr_t c, double size) {
  cairo_set_font_size(cr(c), size);
}
void ofl_cairo_show_text(intptr_t c, const char *text) {
  cairo_show_text(cr(c), text);
}
void ofl_cairo_text_path(intptr_t c, const char *text) {
  cairo_text_path(cr(c), text);
}
void ofl_cairo_text_extents(intptr_t c, const char *text, double *x_bearing,
                            double *y_bearing, double *width, double *height,
                            double *x_advance, double *y_advance) {
  cairo_text_extents_t e;
  cairo_text_extents(cr(c), text, &e);
  *x_bearing = e.x_bearing;
  *y_bearing = e.y_bearing;
  *width = e.width;
  *height = e.height;
  *x_advance = e.x_advance;
  *y_advance = e.y_advance;
}

intptr_t ofl_cairo_linear(double x0, double y0, double x1, double y1) {
  return reinterpret_cast<intptr_t>(cairo_pattern_create_linear(x0, y0, x1, y1));
}
intptr_t ofl_cairo_radial(double x0, double y0, double r0, double x1, double y1,
                          double r1) {
  return reinterpret_cast<intptr_t>(
      cairo_pattern_create_radial(x0, y0, r0, x1, y1, r1));
}
void ofl_cairo_add_color_stop(intptr_t p, double offset, double r, double g,
                              double b, double a) {
  cairo_pattern_add_color_stop_rgba(pat(p), offset, r, g, b, a);
}
void ofl_cairo_set_extend(intptr_t p, int32_t extend) {
  cairo_pattern_set_extend(pat(p), static_cast<cairo_extend_t>(extend));
}
void ofl_cairo_pattern_destroy(intptr_t p) { cairo_pattern_destroy(pat(p)); }

}  // extern "C"
