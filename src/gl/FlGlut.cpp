// The C++ part of FlGlut: FLTK's GLUT emulation, FL/glut.H, in pofltk-gl.
// See pofltk.h for the conventions.
//
// FLTK's GLUT follows a number or a pointer it is given without a look,
// and keeps every string; so this holds what it needs to check them,
// which glut_compatibility.cxx keeps to itself (doc/fltk-issues.md, 112).

#include "../pofltk.h"

// glut.H casts a timer procedure to Fl_Timeout_Handler's type, which newer
// clangs reject unless the header is a system one (doc/fltk-issues.md, 112).
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunknown-warning-option"
#pragma clang diagnostic ignored "-Wcast-function-type-mismatch"
#include <FL/glut.H>
#pragma clang diagnostic pop
#include <FL/platform.H>
#include <FL/fl_utf8.h>
#include <FL/gl.h>

#include <deque>
#include <map>
#include <string>
#include <vector>

extern int ofl_gl_drawing;  // FlGl.cpp
extern "C" int32_t ofl_gl_has_width(const char *s, int32_t n);  // FlGl.cpp

namespace {

// By FlGlut's numbers for them, bitmap fonts first.
void *const fonts[] = {
    GLUT_BITMAP_9_BY_15,        GLUT_BITMAP_8_BY_13,
    GLUT_BITMAP_TIMES_ROMAN_10, GLUT_BITMAP_TIMES_ROMAN_24,
    GLUT_BITMAP_HELVETICA_10,   GLUT_BITMAP_HELVETICA_12,
    GLUT_BITMAP_HELVETICA_18,   GLUT_STROKE_ROMAN,
    GLUT_STROKE_MONO_ROMAN};

const unsigned char *bytes(const char *s) {
  return reinterpret_cast<const unsigned char *>(s);
}

// Whether glutBitmapCharacter or glutBitmapString can draw these bytes
// (doc/fltk-issues.md, 134). The font must be set to measure them.
bool drawable(int32_t font, const char *s, int n) {
  Fl_Glut_Bitmap_Font *f = static_cast<Fl_Glut_Bitmap_Font *>(fonts[font]);
  gl_font(f->font, f->size);
  return ofl_gl_has_width(s, n);
}

// MAXWINDOWS and MAXMENUS in glut_compatibility.cxx, whose number 32 is what
// any window or menu past the 31st shares: so the 31 before it are all.
const int kMaxWindows = 32;
const int kMaxMenus = 32;

// Every GLUT window, by number; which of them are going, or hiding, each
// one's icon title, which FLTK only points at, and its display procedures.
Fl_Glut_Window *live[kMaxWindows + 1];
bool destroyed[kMaxWindows + 1];
bool hiding[kMaxWindows + 1];
std::string icon_title[kMaxWindows + 1];
void (*display_of[kMaxWindows + 1])();
void (*overlay_of[kMaxWindows + 1])();

// How many display procedures are running.
int displaying = 0;

// What FLTK calls, with the window drawn current, in place of the procedures
// the program gave it, so that FlGlut knows it is inside Fl::flush. A window
// going can be drawn before it has gone, and has no number by then. FLTK
// calls its display and overlay procedures unchecked, so they are always
// these, and a NIL one draws nothing here (glut_compatibility.cxx, draw and
// draw_overlay; doc/fltk-issues.md, 145).
void run(void (*const *of)()) {
  int n = glut_window->number;
  if (destroyed[n] || !of[n]) return;
  displaying++;
  of[n]();
  displaying--;
}

void run_display() { run(display_of); }
void run_overlay() { run(overlay_of); }

void forget(int n) {
  live[n] = 0;
  destroyed[n] = false;
  hiding[n] = false;
  icon_title[n].clear();
  display_of[n] = 0;
  overlay_of[n] = 0;
}

// The user data of a window made by glutCreateWindow, which a plain
// Fl_Glut_Window has no other use for, so that its end is heard, however
// it comes.
class Tracker : public Fl_Callback_User_Data {
public:
  explicit Tracker(int n) : number(n) {}
  ~Tracker() { forget(number); }
  int number;
};

void track(int n) {
  live[n] = glut_window;
  glut_window->user_data(new Tracker(n), true);
}

// A window the program made as an object, FlGlut.Window. Its overlay
// stays GLUT's, so it is W, not Overlaid.
class Win : public ofl::W<Fl_Glut_Window> {
public:
  Win(int w, int h) : ofl::W<Fl_Glut_Window>(w, h) { live[number] = this; }
  Win(int x, int y, int w, int h) : ofl::W<Fl_Glut_Window>(x, y, w, h) {
    live[number] = this;
  }
  ~Win() { forget(number); }
  void draw() FL_OVERRIDE {
    ofl_gl_drawing++;
    ofl::W<Fl_Glut_Window>::draw();
    ofl_gl_drawing--;
  }
};

bool alive(int n) {
  return n >= 1 && n <= kMaxWindows && live[n] && !destroyed[n];
}

// Hides or deletes window n, as GLUT does, when the program next waits:
// hiding a window in its display procedure frees what Fl::flush is walking
// (doc/fltk-issues.md, 112), and a window can go while GLUT's calls are on
// the stack. Each window hearing it makes itself current.
void settle(void *data) {
  int n = static_cast<int>(reinterpret_cast<intptr_t>(data));
  Fl_Glut_Window *w = live[n];
  if (!w) return;
  Fl_Glut_Window *was = glut_window;
  if (destroyed[n]) {
    for (int i = 1; i <= kMaxWindows; i++)
      if (live[i] && w->contains(live[i])) live[i]->visibility = 0;
    Fl::delete_widget(w);
    if (was && w->contains(was)) was = 0;
  } else if (hiding[n]) {
    hiding[n] = false;
    w->hide();
  }
  glut_window = was;
  if (was) glutSetWindow(was->number);
}

void* settle_data(int n) {
  return reinterpret_cast<void *>(static_cast<intptr_t>(n));
}

void settle_later(int n) {
  Fl::remove_timeout(settle, settle_data(n));
  Fl::add_timeout(0.0, settle, settle_data(n));
}

// What FLTK's menu n has that it won't tell: the labels it points at, each
// item's submenu or 0, and its array's size, mirroring additem.
struct Menu {
  Menu() : alloc(0) {}
  std::deque<std::string> labels;
  std::vector<int> subs;
  int alloc;
};

std::map<int, Menu> menus;

// FLTK leaves all but the text of its menu's terminator unset, and a pop-up
// reads its flags: glutChangeToMenuEntry takes its item unchecked, so can
// set them (doc/fltk-issues.md, 112).
void seal(Menu *m) {
  glutChangeToMenuEntry(static_cast<int>(m->subs.size()) + 1, 0, 0);
}

Menu *current_menu() {
  std::map<int, Menu>::iterator i = menus.find(glut_menu);
  return i == menus.end() ? 0 : &i->second;
}

char *keep(Menu *m, const char *label) {
  m->labels.push_back(label);
  return &m->labels.back()[0];
}

void will_add(Menu *m) {
  int size = static_cast<int>(m->subs.size());
  if (size + 1 >= m->alloc) m->alloc = size * 2 + 10;
}

int gl_int(GLenum type) {
  GLint p = 0;
  glGetIntegerv(type, &p);
  return p;
}

}  // namespace

// glut.H says char *, which FLTK does not define (doc/fltk-issues.md, 112).
int glutExtensionSupported(const char *);

extern "C" {

// A window

int32_t ofl_glut_has_room(void) {
  int used = 0;
  for (int n = 1; n <= kMaxWindows; n++) used += live[n] != 0;
  return used < kMaxWindows - 1;
}

intptr_t ofl_glut_window_new(int32_t placed, int32_t x, int32_t y, int32_t w,
                             int32_t h, const char *label, intptr_t self) {
  fl_open_display();  // doc/fltk-issues.md, 110
  Win *g = placed ? new Win(x, y, w, h) : new Win(w, h);
  g->copy_label(ofl::label_text(label));
  return ofl::open(g, self);
}

int32_t ofl_glut_number(intptr_t w) {
  return ofl::as<Fl_Glut_Window>(w)->number;
}

void ofl_glut_make_current(intptr_t w) {
  ofl::as<Fl_Glut_Window>(w)->make_current();
}

// GLUT's calls

void ofl_glut_init(int32_t argc, intptr_t argv) {
  // It takes FLTK's options out of its argv, and Args' is the program's.
  char **from = reinterpret_cast<char **>(argv);
  std::vector<char *> copy(from, from + argc);
  copy.push_back(0);
  int n = argc;
  glutInit(&n, &copy[0]);
}

void ofl_glut_init_display_mode(int32_t mode) { glutInitDisplayMode(mode); }

void ofl_glut_init_window_position(int32_t x, int32_t y) {
  glutInitWindowPosition(x, y);
}

void ofl_glut_init_window_size(int32_t w, int32_t h) {
  glutInitWindowSize(w, h);
}

void ofl_glut_main_loop(void) { glutMainLoop(); }

int32_t ofl_glut_create_window(const char *title) {
  fl_open_display();
  int n = glutCreateWindow(title);
  glut_window->copy_label(ofl::label_text(title));
  track(n);
  return n;
}

int32_t ofl_glut_create_subwindow(int32_t win, int32_t x, int32_t y,
                                  int32_t w, int32_t h) {
  int n = glutCreateSubWindow(win, x, y, w, h);
  track(n);
  return n;
}

int32_t ofl_glut_alive(int32_t win) { return alive(win); }

// Later, not at once as glutDestroyWindow does: a window can go in its own
// display function, or in GLUT's calls on the stack (doc/fltk-issues.md,
// 112).
void ofl_glut_destroy_window(int32_t win) {
  Fl_Glut_Window *w = live[win];
  for (int n = 1; n <= kMaxWindows; n++)
    if (live[n] && w->contains(live[n])) {
      destroyed[n] = true;
      Fl::remove_timeout(settle, settle_data(n));
    }
  if (glut_window && w->contains(glut_window)) glut_window = 0;
  settle_later(win);
}

void ofl_glut_post_redisplay(void) { glutPostRedisplay(); }
void ofl_glut_post_window_redisplay(int32_t win) {
  glutPostWindowRedisplay(win);
}
void ofl_glut_swap_buffers(void) { glutSwapBuffers(); }
int32_t ofl_glut_get_window(void) { return glutGetWindow(); }
void ofl_glut_set_window(int32_t win) { glutSetWindow(win); }

// FLTK's glutSetWindowTitle keeps the pointer.
void ofl_glut_set_window_title(const char *t) {
  if (glut_window) glut_window->copy_label(ofl::label_text(t));
}

void ofl_glut_set_icon_title(const char *t) {
  if (glut_window) {
    icon_title[glut_window->number] = t;
    glut_window->iconlabel(icon_title[glut_window->number].c_str());
  }
}

void ofl_glut_position_window(int32_t x, int32_t y) {
  glutPositionWindow(x, y);
}

void ofl_glut_reshape_window(int32_t w, int32_t h) { glutReshapeWindow(w, h); }
void ofl_glut_pop_window(void) { glutPopWindow(); }
void ofl_glut_iconify_window(void) { glutIconifyWindow(); }
void ofl_glut_show_window(void) {
  if (glut_window) hiding[glut_window->number] = false;
  glutShowWindow();
}

// Later only as it draws: a window hiding later is shown meanwhile, and under
// Wayland glutFullScreen on it would wait for an expose that the hiding, run
// by that wait, ends (doc/fltk-issues.md, 112).
void ofl_glut_hide_window(void) {
  if (!glut_window) return;
  if (displaying || ofl_gl_drawing) {
    hiding[glut_window->number] = true;
    settle_later(glut_window->number);
  } else {
    glutHideWindow();
  }
}

void ofl_glut_full_screen(void) {
  if (glut_window && !hiding[glut_window->number]) glutFullScreen();
}

void ofl_glut_set_cursor(int32_t c) {
  glutSetCursor(static_cast<Fl_Cursor>(c));
}

// The overlay. FLTK's is glDrawBuffer(GL_FRONT) on whatever context is
// current (Fl_Gl_Overlay.cxx, and each driver's make_overlay_current), so
// a window hidden or never shown takes it as a shown one does.

void ofl_glut_establish_overlay(void) { glutEstablishOverlay(); }

void ofl_glut_remove_overlay(void) { glutRemoveOverlay(); }

void ofl_glut_use_layer(int32_t layer) {
  glutUseLayer(layer);
}

void ofl_glut_post_overlay_redisplay(void) { glutPostOverlayRedisplay(); }
void ofl_glut_show_overlay(void) { glutShowOverlay(); }
void ofl_glut_hide_overlay(void) { glutHideOverlay(); }

// Queries

int32_t ofl_glut_get(int32_t type) {
  switch (type) {
  case GLUT_WINDOW_PARENT: {
    // FLTK casts the parent, whatever it is, and reads its number.
    Fl_Group *p = glut_window ? glut_window->parent() : 0;
    Fl_Glut_Window *g = dynamic_cast<Fl_Glut_Window *>(p);
    return g ? g->number : 0;
  }
  case GLUT_DISPLAY_MODE_POSSIBLE:
    fl_open_display();
    return glutGet(type);
  case GLUT_WINDOW_BUFFER_SIZE:
    return gl_int(GL_RED_BITS) + gl_int(GL_GREEN_BITS) + gl_int(GL_BLUE_BITS) +
           gl_int(GL_ALPHA_BITS);
  default:
    // FLTK's p is unset if GL takes no such query, or a core context.
    return type >= 100 ? gl_int(type) : glutGet(type);
  }
}

int32_t ofl_glut_device_get(int32_t type) { return glutDeviceGet(type); }
int32_t ofl_glut_layer_get(int32_t type) { return glutLayerGet(type); }
int32_t ofl_glut_get_modifiers(void) { return glutGetModifiers(); }

int32_t ofl_glut_extension_supported(const char *name) {
  return glutExtensionSupported(name);
}

// glXGetProcAddressARB's answer (Fl_Gl_Window.cxx), which GLVND's libGL
// gives for any name, a GL function or not (doc/fltk-issues.md, 175).
intptr_t ofl_glut_get_proc_address(const char *name) {
  return reinterpret_cast<intptr_t>(glutGetProcAddress(name));
}

// Menus

int32_t ofl_glut_menu_room(void) {
  return static_cast<int>(menus.size()) < kMaxMenus - 1;
}

int32_t ofl_glut_create_menu(void (*cb)(int)) {
  int n = glutCreateMenu(cb);
  menus[n];
  return n;
}

int32_t ofl_glut_menu_exists(int32_t m) { return menus.count(m) != 0; }

int32_t ofl_glut_menu_items(int32_t m) {
  std::map<int, Menu>::iterator i = menus.find(m);
  return i == menus.end() ? 0 : static_cast<int>(i->second.subs.size());
}

// Whether m is another menu's submenu, which holds a pointer to its items
// that adding to m or destroying it would leave dangling.
int32_t ofl_glut_menu_used(int32_t m) {
  for (std::map<int, Menu>::iterator i = menus.begin(); i != menus.end(); ++i) {
    std::vector<int> &s = i->second.subs;
    for (size_t k = 0; k < s.size(); k++) {
      if (s[k] == m) return 1;
    }
  }
  return 0;
}

void ofl_glut_destroy_menu(int32_t m) {
  // A window's button on a destroyed menu would pop up a null pointer.
  for (int n = 1; n <= kMaxWindows; n++) {
    if (live[n]) {
      for (int b = 0; b < 3; b++) {
        if (live[n]->menu[b] == m) live[n]->menu[b] = 0;
      }
    }
  }
  glutDestroyMenu(m);
  menus.erase(m);
  if (glut_menu == m) glut_menu = 0;
}

int32_t ofl_glut_get_menu(void) { return glutGetMenu(); }
void ofl_glut_set_menu(int32_t m) { glutSetMenu(m); }

void ofl_glut_add_menu_entry(const char *label, int32_t value) {
  Menu *m = current_menu();
  will_add(m);
  m->subs.push_back(0);
  glutAddMenuEntry(keep(m, label), value);
  seal(m);
}

void ofl_glut_add_sub_menu(const char *label, int32_t submenu) {
  Menu *m = current_menu();
  will_add(m);
  m->subs.push_back(submenu);
  glutAddSubMenu(keep(m, label), submenu);
  seal(m);
}

void ofl_glut_change_to_menu_entry(int32_t item, const char *label,
                                   int32_t value) {
  Menu *m = current_menu();
  m->subs[item - 1] = 0;
  glutChangeToMenuEntry(item, keep(m, label), value);
}

void ofl_glut_change_to_sub_menu(int32_t item, const char *label,
                                 int32_t submenu) {
  Menu *m = current_menu();
  m->subs[item - 1] = submenu;
  glutChangeToSubMenu(item, keep(m, label), submenu);
}

void ofl_glut_remove_menu_item(int32_t item) {
  Menu *m = current_menu();
  // FLTK copies down the item past the terminator, which is past the
  // array when that is full: an item more makes it larger first
  // (doc/fltk-issues.md, 112).
  bool full = static_cast<int>(m->subs.size()) + 1 == m->alloc;
  if (full) {
    will_add(m);
    glutAddMenuEntry(const_cast<char *>(""), 0);
  }
  glutRemoveMenuItem(item);
  m->subs.erase(m->subs.begin() + (item - 1));
  if (full) glutRemoveMenuItem(static_cast<int>(m->subs.size()) + 1);
  seal(m);
}

void ofl_glut_attach_menu(int32_t b) { glutAttachMenu(b); }
void ofl_glut_detach_menu(int32_t b) { glutDetachMenu(b); }

// Callbacks, which GLUT calls as they are

void ofl_glut_display_func(void (*f)()) {
  if (!glut_window) return;
  display_of[glut_window->number] = f;
  glutDisplayFunc(run_display);
}
void ofl_glut_reshape_func(void (*f)(int, int)) { glutReshapeFunc(f); }

void ofl_glut_keyboard_func(void (*f)(uchar, int, int)) {
  glutKeyboardFunc(f);
}

void ofl_glut_mouse_func(void (*f)(int, int, int, int)) { glutMouseFunc(f); }
void ofl_glut_motion_func(void (*f)(int, int)) { glutMotionFunc(f); }
void ofl_glut_passive_motion_func(void (*f)(int, int)) {
  glutPassiveMotionFunc(f);
}
void ofl_glut_entry_func(void (*f)(int)) { glutEntryFunc(f); }
void ofl_glut_visibility_func(void (*f)(int)) { glutVisibilityFunc(f); }
void ofl_glut_idle_func(void (*f)()) { glutIdleFunc(f); }

void ofl_glut_timer_func(int32_t msec, void (*f)(int), int32_t value) {
  glutTimerFunc(msec, f, value);
}

void ofl_glut_menu_state_func(void (*f)(int)) { glutMenuStateFunc(f); }
void ofl_glut_menu_status_func(void (*f)(int, int, int)) {
  glutMenuStatusFunc(f);
}
void ofl_glut_special_func(void (*f)(int, int, int)) { glutSpecialFunc(f); }
void ofl_glut_overlay_display_func(void (*f)()) {
  if (!glut_window) return;
  overlay_of[glut_window->number] = f;
  glutOverlayDisplayFunc(run_overlay);
}

// Fonts

// c is a character's number, which glutBitmapCharacter would draw as one
// byte: so 80 to 9F would be CP1252's, not the character glutBitmapWidth
// measures (doc/fltk-issues.md, 135). This draws it in UTF-8, as
// glutBitmapCharacter does but for that (glut_font.cxx).
void ofl_glut_bitmap_character(int32_t font, int32_t c) {
  char a[4];
  int n = fl_utf8encode(static_cast<unsigned>(c & 0xFF), a);
  if (drawable(font, a, n)) gl_draw(a, n);
}

int32_t ofl_glut_bitmap_height(int32_t font) {
  return glutBitmapHeight(fonts[font]);
}

int32_t ofl_glut_bitmap_length(int32_t font, const char *s) {
  return glutBitmapLength(fonts[font], bytes(s));
}

void ofl_glut_bitmap_string(int32_t font, const char *s) {
  if (drawable(font, s, strlen(s))) glutBitmapString(fonts[font], bytes(s));
}

int32_t ofl_glut_bitmap_width(int32_t font, int32_t c) {
  return glutBitmapWidth(fonts[font], c);
}

void ofl_glut_stroke_character(int32_t font, int32_t c) {
  glutStrokeCharacter(fonts[font], c);
}

double ofl_glut_stroke_height(int32_t font) {
  return glutStrokeHeight(fonts[font]);
}

int32_t ofl_glut_stroke_length(int32_t font, const char *s) {
  return glutStrokeLength(fonts[font], bytes(s));
}

void ofl_glut_stroke_string(int32_t font, const char *s) {
  glutStrokeString(fonts[font], bytes(s));
}

int32_t ofl_glut_stroke_width(int32_t font, int32_t c) {
  return glutStrokeWidth(fonts[font], c);
}

// GLUT's shapes, drawn about the origin.
void ofl_glut_sphere(int32_t solid, double r, int32_t slices, int32_t stacks) {
  if (solid) glutSolidSphere(r, slices, stacks);
  else glutWireSphere(r, slices, stacks);
}

void ofl_glut_cone(int32_t solid, double base, double height, int32_t slices,
                   int32_t stacks) {
  if (solid) glutSolidCone(base, height, slices, stacks);
  else glutWireCone(base, height, slices, stacks);
}

void ofl_glut_torus(int32_t solid, double inner, double outer, int32_t sides,
                    int32_t rings) {
  if (solid) glutSolidTorus(inner, outer, sides, rings);
  else glutWireTorus(inner, outer, sides, rings);
}

void ofl_glut_sized(int32_t solid, int32_t shape, double size) {
  switch (shape) {
    case 0: if (solid) glutSolidCube(size); else glutWireCube(size); break;
    default: if (solid) glutSolidTeapot(size); else glutWireTeapot(size);
  }
}

void ofl_glut_solid(int32_t solid, int32_t shape) {
  switch (shape) {
    case 0: if (solid) glutSolidTetrahedron(); else glutWireTetrahedron(); break;
    case 1: if (solid) glutSolidOctahedron(); else glutWireOctahedron(); break;
    case 2: if (solid) glutSolidDodecahedron(); else glutWireDodecahedron(); break;
    default: if (solid) glutSolidIcosahedron(); else glutWireIcosahedron();
  }
}

}  // extern "C"
