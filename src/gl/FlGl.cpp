// The C++ part of FlGl: Fl_Gl_Window, FL/gl.h, and the part of GL that
// FLTK's programs use. See pofltk.h for the conventions. A library of its
// own (pofltk-gl), so a program using only widgets isn't linked with
// libfltk_gl and libGL.

#include "../pofltk.h"

#include <FL/Fl_Gl_Window.H>
#include <FL/fl_draw.H>
#include <FL/gl.h>
#include <FL/platform.H>

// How many draw()s of GL windows are running. FlGlut.cpp's window counts
// too. Fl_Gl_Window::mode() must not be called inside one.
int ofl_gl_drawing = 0;

namespace {

bool wayland() {
  fl_open_display();
#if defined(FLTK_USE_WAYLAND)
  return fl_wl_display() != 0;
#else
  return false;
#endif
}

class Gl : public ofl::Overlaid<Fl_Gl_Window> {
public:
  Gl(int w, int h) : ofl::Overlaid<Fl_Gl_Window>(w, h) {}
  Gl(int x, int y, int w, int h) : ofl::Overlaid<Fl_Gl_Window>(x, y, w, h) {}
  void draw() FL_OVERRIDE {
    ofl_gl_drawing++;
    ofl::Overlaid<Fl_Gl_Window>::draw();
    ofl_gl_drawing--;
  }
};

// Whether c is a window now shown. Fl_Window::current() stays set after
// hide(), and dangles after delete, so it is compared, never followed,
// until this says it is safe (doc/fltk-issues.md, 111).
bool is_shown(Fl_Window *c) {
  if (!c) return false;
  for (Fl_Window *w = Fl::first_window(); w; w = Fl::next_window(w)) {
    if (w == c) return true;
  }
  return false;
}

// Whether gl_start() has run with no gl_finish() yet.
bool started = false;

// Whether FL/gl.h's text calls have a context. They crash with none
// (doc/fltk-issues.md, 111).
bool ready() {
  if (started) return true;
  Fl_Window *c = Fl_Window::current();
  return is_shown(c) && c->as_gl_window();
}

float f(double d) { return static_cast<float>(d); }

// gl_draw makes a texture as wide as its text, and text with no width, as a
// line feed or a zero-width space, crashes in making it
// (doc/fltk-issues.md, 134).
void draw_some(const char *s, int n) {
  if (gl_width(s, n) > 0) gl_draw(s, n);
}

// gl_draw_invert in gl_draw.cxx, which gl_draw gives fl_draw for each line.
void draw_line(const char *s, int n, int x, int y) {
  glRasterPos2i(x, -y);
  draw_some(s, n);
}

}  // namespace

extern "C" {

intptr_t ofl_gl_window_new(int32_t placed, int32_t x, int32_t y, int32_t w,
                           int32_t h, const char *label, intptr_t self) {
  // The window's driver is chosen by the display (doc/fltk-issues.md, 110).
  fl_open_display();
  Gl *g = placed ? new Gl(x, y, w, h) : new Gl(w, h);
  g->copy_label(ofl::label_text(label));
  return ofl::open(g, self);
}

int32_t ofl_gl_mode(intptr_t w) {
  return ofl::as<Fl_Gl_Window>(w)->mode();
}

int32_t ofl_gl_drawing_now(void) { return ofl_gl_drawing != 0; }

// 0 if this display has no such mode; the window keeps its old one.
int32_t ofl_gl_set_mode(intptr_t w, int32_t mode) {
  return ofl::as<Fl_Gl_Window>(w)->mode(mode) != 0;
}

int32_t ofl_gl_can_do(intptr_t w) {
  return ofl::as<Fl_Gl_Window>(w)->can_do();
}

int32_t ofl_gl_can_do_mode(int32_t mode) {
  fl_open_display();
  return Fl_Gl_Window::can_do(mode);
}

int32_t ofl_gl_visual(int32_t mode) {
  fl_open_display();
  return Fl::gl_visual(mode);
}

void ofl_gl_use_high_res(int32_t on) { Fl::use_high_res_GL(on); }

int32_t ofl_gl_valid(intptr_t w) {
  return ofl::as<Fl_Gl_Window>(w)->valid() != 0;
}

void ofl_gl_set_valid(intptr_t w, int32_t v) {
  ofl::as<Fl_Gl_Window>(w)->valid(static_cast<char>(v));
}

int32_t ofl_gl_context_valid(intptr_t w) {
  return ofl::as<Fl_Gl_Window>(w)->context_valid() != 0;
}

void ofl_gl_set_context_valid(intptr_t w, int32_t v) {
  ofl::as<Fl_Gl_Window>(w)->context_valid(static_cast<char>(v));
}

void ofl_gl_invalidate(intptr_t w) { ofl::as<Fl_Gl_Window>(w)->invalidate(); }

int32_t ofl_gl_make_current(intptr_t w) {
  Fl_Gl_Window *g = ofl::as<Fl_Gl_Window>(w);
  if (!g->shown()) return 0;
  g->make_current();
  return 1;
}

void ofl_gl_swap_buffers(intptr_t w) {
  ofl::as<Fl_Gl_Window>(w)->swap_buffers();
}

int32_t ofl_gl_swap_interval(intptr_t w) {
  return ofl::as<Fl_Gl_Window>(w)->swap_interval();
}

void ofl_gl_set_swap_interval(intptr_t w, int32_t i) {
  ofl::as<Fl_Gl_Window>(w)->swap_interval(i);
}

void ofl_gl_ortho(intptr_t w) { ofl::as<Fl_Gl_Window>(w)->ortho(); }

int32_t ofl_gl_pixel_w(intptr_t w) {
  return ofl::as<Fl_Gl_Window>(w)->pixel_w();
}

int32_t ofl_gl_pixel_h(intptr_t w) {
  return ofl::as<Fl_Gl_Window>(w)->pixel_h();
}

double ofl_gl_pixels_per_unit(intptr_t w) {
  return ofl::as<Fl_Gl_Window>(w)->pixels_per_unit();
}

int32_t ofl_gl_can_do_overlay(intptr_t w) {
  return ofl::as<Fl_Gl_Window>(w)->can_do_overlay();
}

void ofl_gl_redraw_overlay(intptr_t w) {
  ofl::as<Fl_Gl_Window>(w)->redraw_overlay();
}

void ofl_gl_hide_overlay(intptr_t w) {
  ofl::as<Fl_Gl_Window>(w)->hide_overlay();
}

int32_t ofl_gl_make_overlay_current(intptr_t w) {
  Fl_Gl_Window *g = ofl::as<Fl_Gl_Window>(w);
  if (!g->shown()) return 0;
  g->make_overlay_current();
  return 1;
}

// gl_start() crashes under Wayland, always (doc/fltk-issues.md, 109).
int32_t ofl_gl_can_start(void) { return !wayland(); }

int32_t ofl_gl_start(void) {
  if (started || !is_shown(Fl_Window::current())) return 0;
  gl_start();
  started = true;
  return 1;
}

int32_t ofl_gl_finish(void) {
  if (!started) return 0;
  gl_finish();
  started = false;
  return 1;
}

int32_t ofl_gl_ready(void) { return ready(); }

void ofl_gl_color(int32_t c) { gl_color(static_cast<Fl_Color>(c)); }

void ofl_gl_rect(int32_t x, int32_t y, int32_t w, int32_t h) {
  gl_rect(x, y, w, h);
}

void ofl_gl_rectf(int32_t x, int32_t y, int32_t w, int32_t h) {
  gl_rectf(x, y, w, h);
}

void ofl_gl_font(int32_t font, int32_t size) { gl_font(font, size); }

int32_t ofl_gl_height(void) { return gl_height(); }

int32_t ofl_gl_descent(void) { return gl_descent(); }

double ofl_gl_width(const char *s) { return gl_width(s); }

void ofl_gl_measure(const char *s, int32_t *w, int32_t *h) {
  int cw = *w, ch = *h;
  gl_measure(s, cw, ch);
  *w = cw;
  *h = ch;
}

void ofl_gl_draw(const char *s) { draw_some(s, strlen(s)); }

// For FlGlut.cpp: whether gl_draw can take these n bytes in the current font.
int32_t ofl_gl_has_width(const char *s, int32_t n) {
  return gl_width(s, n) > 0;
}

void ofl_gl_draw_at(const char *s, double x, double y) {
  glRasterPos2f(f(x), f(y));
  draw_some(s, strlen(s));
}

void ofl_gl_draw_in(const char *s, int32_t x, int32_t y, int32_t w, int32_t h,
                    int32_t align) {
  fl_draw(s, x, -y - h, w, h, static_cast<Fl_Align>(align), draw_line, NULL, 0);
}

void ofl_gl_draw_image(const char *data, int32_t x, int32_t y, int32_t w,
                       int32_t h, int32_t d) {
  gl_draw_image(reinterpret_cast<const uchar *>(data), x, y, w, h, d);
}

void ofl_gl_texture_reset(void) { gl_texture_reset(); }
int32_t ofl_gl_texture_pile_height(void) { return gl_texture_pile_height(); }
void ofl_gl_set_texture_pile_height(int32_t max) { gl_texture_pile_height(max); }

// GL itself. GL's float crosses as a double.

void ofl_gl_begin(int32_t mode) { glBegin(mode); }
void ofl_gl_end(void) { glEnd(); }
void ofl_gl_clear(int32_t mask) { glClear(mask); }

void ofl_gl_clear_color(double r, double g, double b, double a) {
  glClearColor(f(r), f(g), f(b), f(a));
}

void ofl_gl_color3f(double r, double g, double b) {
  glColor3f(f(r), f(g), f(b));
}

void ofl_gl_color4f(double r, double g, double b, double a) {
  glColor4f(f(r), f(g), f(b), f(a));
}

void ofl_gl_color3ub(int32_t r, int32_t g, int32_t b) {
  glColor3ub(static_cast<GLubyte>(r), static_cast<GLubyte>(g),
             static_cast<GLubyte>(b));
}

void ofl_gl_enable(int32_t cap) { glEnable(cap); }
void ofl_gl_disable(int32_t cap) { glDisable(cap); }

void ofl_gl_frustum(double l, double r, double b, double t, double n,
                    double fr) {
  glFrustum(l, r, b, t, n, fr);
}

void ofl_gl_load_identity(void) { glLoadIdentity(); }

void ofl_gl_gl_ortho(double l, double r, double b, double t, double n,
                     double fr) {
  glOrtho(l, r, b, t, n, fr);
}

void ofl_gl_push_matrix(void) { glPushMatrix(); }
void ofl_gl_pop_matrix(void) { glPopMatrix(); }

void ofl_gl_rotatef(double a, double x, double y, double z) {
  glRotatef(f(a), f(x), f(y), f(z));
}

void ofl_gl_scalef(double x, double y, double z) {
  glScalef(f(x), f(y), f(z));
}

void ofl_gl_shade_model(int32_t mode) { glShadeModel(mode); }

void ofl_gl_translatef(double x, double y, double z) {
  glTranslatef(f(x), f(y), f(z));
}

void ofl_gl_vertex3f(double x, double y, double z) {
  glVertex3f(f(x), f(y), f(z));
}

void ofl_gl_viewport(int32_t x, int32_t y, int32_t w, int32_t h) {
  glViewport(x, y, w, h);
}

void ofl_gl_blend_func(int32_t s, int32_t d) { glBlendFunc(s, d); }
void ofl_gl_flush(void) { glFlush(); }
int32_t ofl_gl_get_error(void) { return glGetError(); }

// RGB bytes, with no padding between rows.
void ofl_gl_read_pixels(int32_t x, int32_t y, int32_t w, int32_t h,
                        char *data) {
  GLint old;
  glGetIntegerv(GL_PACK_ALIGNMENT, &old);
  glPixelStorei(GL_PACK_ALIGNMENT, 1);
  glReadPixels(x, y, w, h, GL_RGB, GL_UNSIGNED_BYTE, data);
  glPixelStorei(GL_PACK_ALIGNMENT, old);
}

void ofl_gl_version(char *buf, int32_t n) {
  ofl::copy_out(reinterpret_cast<const char *>(glGetString(GL_VERSION)), buf,
                n);
}

}  // extern "C"
