// The C++ part of FlDraw: fl_draw.H's drawing, for a widget's Draw. See
// pofltk.h for the conventions.

#include "pofltk.h"

#include <FL/Fl.H>
#include <FL/Fl_Device.H>
#include <FL/Fl_Graphics_Driver.H>
#include <FL/Fl_Image_Surface.H>
#include <FL/Fl_Rect.H>
#include <FL/Fl_Window.H>
#include <FL/fl_draw.H>

#include <string.h>

#include <new>
#include <set>
#include <string>
#include <vector>

namespace {

// Text drawn or measured before any fl_font crashes under Wayland/Cairo
// (doc/design.md, "Problems found"), so each text call sets FLTK's
// normal font first if none is set. An SVG surface has no descriptor,
// so a size says that a font is set there.
void ensure_font() {
  if (fl_graphics_driver->font_descriptor() == 0 && fl_size() <= 0) {
    fl_font(FL_HELVETICA, FL_NORMAL_SIZE);
  }
}

// Whether a window is current and still shown. Fl_Window::current() stays
// after a hide and dangles after a delete, so it is only compared.
bool on_window() {
  Fl_Window *c = Fl_Window::current();
  if (!c) return false;
  for (Fl_Window *w = Fl::first_window(); w; w = Fl::next_window(w)) {
    if (w == c) return true;
  }
  return false;
}

bool on_surface() {
  return Fl_Surface_Device::surface() != Fl_Display_Device::display_device();
}

// fl_symbols.cxx hashes a name's bytes as chars, and a byte from 0x80 on
// makes the index into its table negative where char is signed
// (doc/fltk-issues.md, 123). Refused, here and in AddSymbol.
bool ascii(const char *s) {
  for (; *s; s++) {
    if (static_cast<unsigned char>(*s) >= 0x80) return false;
  }
  return true;
}

// fl_add_symbol keeps its name's pointer, for good.
std::set<std::string> symbol_names;

// The Oberon dispatchers, which FlDraw's body registers.
typedef void (*AreaFn)(int32_t, int32_t, int32_t, int32_t);
typedef void (*LineFn)(int32_t, int32_t, int32_t, unsigned char *);
AreaFn on_area = 0;
LineFn on_line = 0;

void area_cb(void *, int x, int y, int w, int h) { on_area(x, y, w, h); }

void line_cb(void *, int x, int y, int w, unsigned char *buf) {
  on_line(x, y, w, buf);
}

}  // namespace

extern "C" {

void ofl_draw_register(AreaFn area, LineFn line) {
  on_area = area;
  on_line = line;
}

// Colors and lines

void ofl_draw_color(int32_t c) { fl_color(static_cast<Fl_Color>(c)); }

void ofl_draw_rgb(int32_t r, int32_t g, int32_t b) {
  fl_color(static_cast<uchar>(r), static_cast<uchar>(g), static_cast<uchar>(b));
}

int32_t ofl_draw_get_color(void) { return static_cast<int32_t>(fl_color()); }

void ofl_draw_line_style(int32_t style, int32_t width) {
  fl_line_style(style, width);
}

// FLTK copies the pattern, into 256 bytes, unchecked
// (doc/fltk-issues.md, 136): LineStyleDashes checks its length.
void ofl_draw_line_style_dashes(int32_t style, int32_t width,
                                const char *dashes) {
  fl_line_style(style, width, const_cast<char *>(dashes));
}

// Shapes, in integer coordinates, untransformed

void ofl_draw_point(int32_t x, int32_t y) { fl_point(x, y); }

void ofl_draw_line(int32_t x, int32_t y, int32_t x1, int32_t y1) {
  fl_line(x, y, x1, y1);
}

void ofl_draw_line3(int32_t x, int32_t y, int32_t x1, int32_t y1,
                    int32_t x2, int32_t y2) {
  fl_line(x, y, x1, y1, x2, y2);
}

void ofl_draw_rect(int32_t x, int32_t y, int32_t w, int32_t h) {
  fl_rect(x, y, w, h);
}

void ofl_draw_rectf(int32_t x, int32_t y, int32_t w, int32_t h) {
  fl_rectf(x, y, w, h);
}

void ofl_draw_loop3(int32_t x0, int32_t y0, int32_t x1, int32_t y1,
                    int32_t x2, int32_t y2) {
  fl_loop(x0, y0, x1, y1, x2, y2);
}

void ofl_draw_loop4(int32_t x0, int32_t y0, int32_t x1, int32_t y1,
                    int32_t x2, int32_t y2, int32_t x3, int32_t y3) {
  fl_loop(x0, y0, x1, y1, x2, y2, x3, y3);
}

void ofl_draw_polygon3(int32_t x0, int32_t y0, int32_t x1, int32_t y1,
                       int32_t x2, int32_t y2) {
  fl_polygon(x0, y0, x1, y1, x2, y2);
}

void ofl_draw_polygon4(int32_t x0, int32_t y0, int32_t x1, int32_t y1,
                       int32_t x2, int32_t y2, int32_t x3, int32_t y3) {
  fl_polygon(x0, y0, x1, y1, x2, y2, x3, y3);
}

void ofl_draw_xyline(int32_t x, int32_t y, int32_t x1) { fl_xyline(x, y, x1); }
void ofl_draw_yxline(int32_t x, int32_t y, int32_t y1) { fl_yxline(x, y, y1); }

void ofl_draw_arc(int32_t x, int32_t y, int32_t w, int32_t h, double a1,
                  double a2) {
  fl_arc(x, y, w, h, a1, a2);
}

void ofl_draw_pie(int32_t x, int32_t y, int32_t w, int32_t h, double a1,
                  double a2) {
  fl_pie(x, y, w, h, a1, a2);
}

// Paths, in transformed coordinates

void ofl_draw_push_matrix(void) { fl_push_matrix(); }
void ofl_draw_pop_matrix(void) { fl_pop_matrix(); }
void ofl_draw_scale(double x, double y) { fl_scale(x, y); }
void ofl_draw_translate(double x, double y) { fl_translate(x, y); }
void ofl_draw_rotate(double d) { fl_rotate(d); }
void ofl_draw_begin_points(void) { fl_begin_points(); }
void ofl_draw_begin_line(void) { fl_begin_line(); }
void ofl_draw_begin_loop(void) { fl_begin_loop(); }
void ofl_draw_begin_polygon(void) { fl_begin_polygon(); }
void ofl_draw_begin_complex_polygon(void) { fl_begin_complex_polygon(); }
void ofl_draw_gap(void) { fl_gap(); }
void ofl_draw_end_points(void) { fl_end_points(); }
void ofl_draw_end_line(void) { fl_end_line(); }
void ofl_draw_end_loop(void) { fl_end_loop(); }
void ofl_draw_end_polygon(void) { fl_end_polygon(); }
void ofl_draw_end_complex_polygon(void) { fl_end_complex_polygon(); }
void ofl_draw_vertex(double x, double y) { fl_vertex(x, y); }

void ofl_draw_curve(double x0, double y0, double x1, double y1, double x2,
                    double y2, double x3, double y3) {
  fl_curve(x0, y0, x1, y1, x2, y2, x3, y3);
}

void ofl_draw_arc_path(double x, double y, double r, double start,
                       double end) {
  fl_arc(x, y, r, start, end);
}

void ofl_draw_circle(double x, double y, double r) { fl_circle(x, y, r); }

// Text

void ofl_draw_font(int32_t face, int32_t size) { fl_font(face, size); }

int32_t ofl_draw_get_font(void) {
  ensure_font();
  return fl_font();
}

int32_t ofl_draw_size(void) {
  ensure_font();
  return fl_size();
}

int32_t ofl_draw_height(void) {
  ensure_font();
  return fl_height();
}

int32_t ofl_draw_descent(void) {
  ensure_font();
  return fl_descent();
}

double ofl_draw_width(const char *s) {
  ensure_font();
  return fl_width(s);
}

void ofl_draw_text(const char *s, int32_t x, int32_t y) {
  ensure_font();
  fl_draw(s, x, y);
}

void ofl_draw_text_aligned(const char *s, int32_t x, int32_t y, int32_t w,
                           int32_t h, int32_t align) {
  ensure_font();
  fl_draw(s, x, y, w, h, static_cast<Fl_Align>(align));
}

// *w is the width to wrap at on entry, 0 for none.
void ofl_draw_measure(const char *s, int32_t *w, int32_t *h) {
  int mw = *w, mh = 0;
  ensure_font();
  fl_measure(s, mw, mh);
  *w = mw;
  *h = mh;
}

// Clipping

void ofl_draw_push_clip(int32_t x, int32_t y, int32_t w, int32_t h) {
  fl_push_clip(x, y, w, h);
}

void ofl_draw_push_no_clip(void) { fl_push_no_clip(); }
void ofl_draw_pop_clip(void) { fl_pop_clip(); }

int32_t ofl_draw_not_clipped(int32_t x, int32_t y, int32_t w, int32_t h) {
  return fl_not_clipped(x, y, w, h);
}

// fl_clip_box's result is dropped: FLTK 1.4.5 returns 0 when the box was
// clipped and 1 when it wasn't, against its documentation. For a box
// wholly clipped it sets W to 0 and may leave the rest unset, hence the
// zeros.
void ofl_draw_clip_box(int32_t x, int32_t y, int32_t w, int32_t h,
                       int32_t *cx, int32_t *cy, int32_t *cw, int32_t *ch) {
  int X = 0, Y = 0, W = 0, H = 0;
  fl_clip_box(x, y, w, h, X, Y, W, H);
  *cx = X;
  *cy = Y;
  *cw = W;
  *ch = H;
}

// Boxes and symbols

void ofl_draw_box(int32_t type, int32_t x, int32_t y, int32_t w, int32_t h,
                  int32_t c) {
  fl_draw_box(static_cast<Fl_Boxtype>(type), x, y, w, h,
              static_cast<Fl_Color>(c));
}

void ofl_draw_focus_rect(int32_t x, int32_t y, int32_t w, int32_t h) {
  fl_focus_rect(x, y, w, h);
}

int32_t ofl_draw_symbol(const char *name, int32_t x, int32_t y, int32_t w,
                        int32_t h, int32_t c) {
  if (!ascii(name)) return 0;
  return fl_draw_symbol(name, x, y, w, h, static_cast<Fl_Color>(c));
}

// 0 if FLTK couldn't find the symbol again: fl_draw_symbol takes such a
// start of a name as its modifiers. An empty name would replace the
// default symbol, and its table holds what it is given for good.
int32_t ofl_draw_add_symbol(const char *name, void (*draw)(Fl_Color),
                            int32_t scalable) {
  if (!name[0] || !ascii(name)) return 0;
  char a = name[0], b = name[1];
  if (a == '#' || a == '$' || a == '%' || (a >= '0' && a <= '9')) return 0;
  if ((a == '-' || a == '+') && b >= '1' && b <= '9') return 0;
  try {
    return fl_add_symbol(symbol_names.insert(name).first->c_str(), draw,
                         scalable);
  } catch (const std::bad_alloc &) {
    return 0;
  }
}

void ofl_draw_box_focus(int32_t type, int32_t x, int32_t y, int32_t w,
                        int32_t h, int32_t fg, int32_t bg) {
  fl_draw_box_focus(static_cast<Fl_Boxtype>(type), x, y, w, h,
                    static_cast<Fl_Color>(fg), static_cast<Fl_Color>(bg));
}

void ofl_draw_frame(const char *s, int32_t x, int32_t y, int32_t w, int32_t h) {
  fl_frame(s, x, y, w, h);
}

void ofl_draw_frame2(const char *s, int32_t x, int32_t y, int32_t w,
                     int32_t h) {
  fl_frame2(s, x, y, w, h);
}

void ofl_draw_rounded_rect(int32_t x, int32_t y, int32_t w, int32_t h,
                           int32_t r) {
  fl_rounded_rect(x, y, w, h, r);
}

void ofl_draw_rounded_rectf(int32_t x, int32_t y, int32_t w, int32_t h,
                            int32_t r) {
  fl_rounded_rectf(x, y, w, h, r);
}

void ofl_draw_disc(int32_t x, int32_t y, int32_t d, int32_t c) {
  fl_draw_circle(x, y, d, static_cast<Fl_Color>(c));
}

void ofl_draw_radio(int32_t x, int32_t y, int32_t d, int32_t c) {
  fl_draw_radio(x, y, d, static_cast<Fl_Color>(c));
}

void ofl_draw_arrow(int32_t x, int32_t y, int32_t w, int32_t h, int32_t type,
                    int32_t orient, int32_t c) {
  fl_draw_arrow(Fl_Rect(x, y, w, h), static_cast<Fl_Arrow_Type>(type),
                static_cast<Fl_Orientation>(orient), static_cast<Fl_Color>(c));
}

void ofl_draw_check(int32_t x, int32_t y, int32_t w, int32_t h, int32_t c) {
  fl_draw_check(Fl_Rect(x, y, w, h), static_cast<Fl_Color>(c));
}

// Marks over what a window shows, between draws: with no window current
// each crashes (doc/fltk-issues.md, 124), so each says if it had one.
int32_t ofl_draw_overlay_rect(int32_t x, int32_t y, int32_t w, int32_t h) {
  if (!on_window() || on_surface()) return 0;
  fl_overlay_rect(x, y, w, h);
  return 1;
}

int32_t ofl_draw_overlay_clear() {
  if (!on_window() || on_surface()) return 0;
  fl_overlay_clear();
  return 1;
}

// fl_scroll moves pixels of the current window, and a surface has none of
// them, so there the whole rectangle is drawn again.
int32_t ofl_draw_scroll(int32_t x, int32_t y, int32_t w, int32_t h, int32_t dx,
                        int32_t dy) {
  if (!dx && !dy) return on_surface() || on_window() ? 1 : 0;
  if (on_surface()) {
    area_cb(0, x, y, w, h);
    return 1;
  }
  if (!on_window()) return 0;
  fl_scroll(x, y, w, h, dx, dy, area_cb, 0);
  return 1;
}

// As for overlays: Cairo has no context until something is current.
int32_t ofl_draw_can_draw() { return on_window() || on_surface() ? 1 : 0; }

int32_t ofl_draw_antialias() { return fl_antialias(); }

void ofl_draw_set_antialias(int32_t on) { fl_antialias(on); }

void ofl_draw_cursor(int32_t c) { fl_cursor(static_cast<Fl_Cursor>(c)); }

// Transformations

void ofl_draw_load_identity() { fl_load_identity(); }

void ofl_draw_load_matrix(double a, double b, double c, double d, double x,
                          double y) {
  fl_load_matrix(a, b, c, d, x, y);
}

void ofl_draw_mult_matrix(double a, double b, double c, double d, double x,
                          double y) {
  fl_mult_matrix(a, b, c, d, x, y);
}

double ofl_draw_transform_x(double x, double y) { return fl_transform_x(x, y); }

double ofl_draw_transform_y(double x, double y) { return fl_transform_y(x, y); }

double ofl_draw_transform_dx(double x, double y) {
  return fl_transform_dx(x, y);
}

double ofl_draw_transform_dy(double x, double y) {
  return fl_transform_dy(x, y);
}

void ofl_draw_transformed_vertex(double x, double y) {
  fl_transformed_vertex(x, y);
}

double ofl_draw_override_scale() { return fl_override_scale(); }

void ofl_draw_restore_scale(double s) {
  fl_restore_scale(static_cast<float>(s));
}

// More text

void ofl_draw_text_extents(const char *s, int32_t *dx, int32_t *dy, int32_t *w,
                           int32_t *h) {
  ensure_font();
  int a = 0, b = 0, c = 0, d = 0;
  fl_text_extents(s, a, b, c, d);
  *dx = a;
  *dy = b;
  *w = c;
  *h = d;
}

void ofl_draw_text_angle(int32_t angle, const char *s, int32_t x, int32_t y) {
  ensure_font();
  fl_draw(angle, s, x, y);
}

void ofl_draw_rtl(const char *s, int32_t x, int32_t y) {
  ensure_font();
  fl_rtl_draw(s, static_cast<int>(strlen(s)), x, y);
}

// One line of from as FLTK would draw it, cut to fit to; how far it went
// in from. fl_expand_text writes up to 8 bytes for a tab, and stops at
// 4 bytes from its buffer's end, so a buffer of what the text can come to
// holds any line (doc/fltk-issues.md, 125).
int32_t ofl_draw_expand(const char *from, char *to, int32_t size, double maxw,
                        int32_t *n, double *width, int32_t wrap,
                        int32_t symbols) {
  ensure_font();
  int count = 0;
  double wide = 0;
  std::vector<char> buf;
  try {
    buf.resize(8 * strlen(from) + 16);
  } catch (const std::bad_alloc &) {
    *n = 0;
    *width = 0;
    to[0] = 0;
    return 0;
  }
  const char *end =
      fl_expand_text(from, buf.data(), static_cast<int>(buf.size()), maxw,
                     count, wide, wrap, symbols);
  ofl::copy_out(buf.data(), to, size);
  *n = count;
  *width = wide;
  return static_cast<int32_t>(end - from);
}

void ofl_draw_set_spot(int32_t font, int32_t size, int32_t x, int32_t y,
                       int32_t w, int32_t h) {
  fl_set_spot(font, size, x, y, w, h);
}

void ofl_draw_reset_spot() { fl_reset_spot(); }

void ofl_draw_set_status(int32_t x, int32_t y, int32_t w, int32_t h) {
  fl_set_status(x, y, w, h);
}

// FLTK's four recoders leave their text in a buffer of theirs, unended.
// The two for Mac Roman need a first call to make it, and the one to it
// writes only its first byte (doc/fltk-issues.md, 126), so all go a byte
// at a time.
void ofl_draw_recode(int32_t kind, const char *from, char *to, int32_t n) {
  typedef const char *(*Recode)(const char *, int);
  static const Recode recode[] = {fl_latin1_to_local, fl_local_to_latin1,
                                  fl_mac_roman_to_local, fl_local_to_mac_roman};
  Recode f = recode[kind];
  f(from, 0);
  int32_t i = 0;
  for (; i < n - 1 && from[i]; i++) to[i] = f(from + i, 1)[0];
  to[i] = 0;
}

// Images

void ofl_draw_image(const unsigned char *buf, int32_t x, int32_t y, int32_t w,
                    int32_t h, int32_t d, int32_t l) {
  fl_draw_image(buf, x, y, w, h, d, l);
}

void ofl_draw_image_mono(const unsigned char *buf, int32_t x, int32_t y,
                         int32_t w, int32_t h, int32_t d, int32_t l) {
  fl_draw_image_mono(buf, x, y, w, h, d, l);
}

void ofl_draw_image_lines(int32_t x, int32_t y, int32_t w, int32_t h,
                          int32_t d) {
  fl_draw_image(line_cb, 0, x, y, w, h, d);
}

void ofl_draw_image_mono_lines(int32_t x, int32_t y, int32_t w, int32_t h,
                               int32_t d) {
  fl_draw_image_mono(line_cb, 0, x, y, w, h, d);
}

int32_t ofl_draw_can_blend() { return fl_can_do_alpha_blending(); }

// Offscreens, as fl_create_offscreen makes them, whose table of them
// tells nothing of which is current; Fl_Image_Surface does.

intptr_t ofl_offscreen_new(int32_t w, int32_t h) {
  return reinterpret_cast<intptr_t>(new Fl_Image_Surface(w, h, 1));
}

void ofl_offscreen_close(intptr_t s) {
  delete reinterpret_cast<Fl_Image_Surface *>(s);
}

void ofl_offscreen_begin(intptr_t s) {
  Fl_Surface_Device::push_current(reinterpret_cast<Fl_Image_Surface *>(s));
}

void ofl_offscreen_end() { Fl_Surface_Device::pop_current(); }

int32_t ofl_offscreen_current(intptr_t s) {
  return reinterpret_cast<Fl_Image_Surface *>(s)->is_current() ? 1 : 0;
}

void ofl_offscreen_copy(intptr_t s, int32_t x, int32_t y, int32_t w, int32_t h,
                        int32_t sx, int32_t sy) {
  fl_copy_offscreen(x, y, w, h,
                    reinterpret_cast<Fl_Image_Surface *>(s)->offscreen(), sx,
                    sy);
}

void ofl_offscreen_rescale(intptr_t s) {
  reinterpret_cast<Fl_Image_Surface *>(s)->rescale();
}

}  // extern "C"
