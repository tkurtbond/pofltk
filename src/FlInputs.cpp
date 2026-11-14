// The C++ part of FlInputs: the text input and output classes. See
// pofltk.h for the conventions.

#include "pofltk.h"

#include <FL/Fl_File_Input.H>
#include <FL/Fl_Float_Input.H>
#include <FL/Fl_Input.H>
#include <FL/Fl_Input_Choice.H>
#include <FL/Fl_Int_Input.H>
#include <FL/Fl_Multiline_Input.H>
#include <FL/Fl_Multiline_Output.H>
#include <FL/Fl_Output.H>
#include <FL/Fl_Secret_Input.H>
#include <string.h>

#include <string>

namespace {

template <class T>
intptr_t make(int32_t x, int32_t y, int32_t w, int32_t h, const char *label,
              intptr_t self) {
  ofl::W<T> *i = new ofl::W<T>(x, y, w, h);
  i->copy_label(ofl::label_text(label));
  return ofl::open(i, self);
}

Fl_Input_ *input(intptr_t i) { return ofl::as<Fl_Input_>(i); }
Fl_Input_Choice *chooser(intptr_t i) { return ofl::as<Fl_Input_Choice>(i); }

}  // namespace

extern "C" {

// The texts of the menu an input or a text widget pops up on the right
// button. FLTK keeps the pointers, and sets its menu's labels from them as
// each menu opens, so the copies here outlast every menu.
void ofl_input_set_menu_texts(const char *cut, const char *copy,
                              const char *paste) {
  static std::string texts[3];
  texts[0] = cut;
  texts[1] = copy;
  texts[2] = paste;
  Fl_Input::cut_menu_text = texts[0].c_str();
  Fl_Input::copy_menu_text = texts[1].c_str();
  Fl_Input::paste_menu_text = texts[2].c_str();
}

// Text which (0 cut, 1 copy, 2 paste), cut to n - 1 bytes.
void ofl_input_menu_text(int32_t which, char *buf, int32_t n) {
  const char *t = which == 0 ? Fl_Input::cut_menu_text
                : which == 1 ? Fl_Input::copy_menu_text
                : Fl_Input::paste_menu_text;
  ofl::copy_out(t ? t : "", buf, n);
}

// kind is 0 Fl_Input, 1 Fl_Int_Input, and so on, as FlInputs numbers them.
intptr_t ofl_input_new(int32_t kind, int32_t x, int32_t y, int32_t w,
                       int32_t h, const char *label, intptr_t self) {
  switch (kind) {
    case 1: return make<Fl_Int_Input>(x, y, w, h, label, self);
    case 2: return make<Fl_Float_Input>(x, y, w, h, label, self);
    case 3: return make<Fl_Multiline_Input>(x, y, w, h, label, self);
    case 4: return make<Fl_Secret_Input>(x, y, w, h, label, self);
    case 5: return make<Fl_Output>(x, y, w, h, label, self);
    case 6: return make<Fl_Multiline_Output>(x, y, w, h, label, self);
    case 7: return make<Fl_File_Input>(x, y, w, h, label, self);
    case 8: return make<Fl_Input_Choice>(x, y, w, h, label, self);
    default: return make<Fl_Input>(x, y, w, h, label, self);
  }
}

// The text, into buf of n characters, truncated (ofl::copy_out).
void ofl_input_value(intptr_t i, char *buf, int32_t n) {
  ofl::copy_out(input(i)->value(), buf, n);
}

// Copied by FLTK (Fl_Input_::value calls put_in_buffer).
void ofl_input_set_value(intptr_t i, const char *s) { input(i)->value(s); }

// Fl_File_Input::value hides Fl_Input_'s, and alone redraws the bar of
// the path's parts, so the class is called as itself.
void ofl_file_input_set_value(intptr_t i, const char *s) {
  ofl::as<Fl_File_Input>(i)->value(s);
}

int32_t ofl_file_input_down_box(intptr_t i) {
  return ofl::as<Fl_File_Input>(i)->down_box();
}

void ofl_file_input_set_down_box(intptr_t i, int32_t b) {
  ofl::as<Fl_File_Input>(i)->down_box(static_cast<Fl_Boxtype>(b));
}

int32_t ofl_input_ivalue(intptr_t i) { return input(i)->ivalue(); }
double ofl_input_dvalue(intptr_t i) { return input(i)->dvalue(); }
void ofl_input_set_ivalue(intptr_t i, int32_t v) { input(i)->value(static_cast<int>(v)); }
void ofl_input_set_dvalue(intptr_t i, double v) { input(i)->value(v); }

// The text's length in bytes.
int32_t ofl_input_size(intptr_t i) { return input(i)->size(); }

int32_t ofl_input_maximum_size(intptr_t i) { return input(i)->maximum_size(); }

void ofl_input_set_maximum_size(intptr_t i, int32_t m) {
  input(i)->maximum_size(m);
}

int32_t ofl_input_insert_position(intptr_t i) {
  return input(i)->insert_position();
}

int32_t ofl_input_mark(intptr_t i) { return input(i)->mark(); }

// FLTK doesn't check the index (it reads outside the text): -1 if it is
// outside, for FlInputs to halt.
int32_t ofl_input_index(intptr_t i, int32_t pos) {
  if (pos < 0 || pos > input(i)->size()) return -1;
  return static_cast<int32_t>(input(i)->index(pos));
}

void ofl_input_set_position(intptr_t i, int32_t p, int32_t m) {
  input(i)->insert_position(p, m);
}

// The edits return 0 if nothing changed, or a maximum_size stopped them.
int32_t ofl_input_replace(intptr_t i, int32_t b, int32_t e, const char *s) {
  return input(i)->replace(b, e, s);
}

int32_t ofl_input_cut(intptr_t i) { return input(i)->cut(); }

int32_t ofl_input_cut_range(intptr_t i, int32_t a, int32_t b) {
  return input(i)->cut(a, b);
}

int32_t ofl_input_insert(intptr_t i, const char *s) {
  return input(i)->insert(s);
}

int32_t ofl_input_undo(intptr_t i) { return input(i)->undo(); }
int32_t ofl_input_redo(intptr_t i) { return input(i)->redo(); }

int32_t ofl_input_readonly(intptr_t i) { return input(i)->readonly(); }

void ofl_input_set_readonly(intptr_t i, int32_t r) {
  input(i)->readonly(r);
}

int32_t ofl_input_wrap(intptr_t i) { return input(i)->wrap(); }
void ofl_input_set_wrap(intptr_t i, int32_t w) { input(i)->wrap(w); }

int32_t ofl_input_tab_nav(intptr_t i) { return input(i)->tab_nav(); }
void ofl_input_set_tab_nav(intptr_t i, int32_t t) { input(i)->tab_nav(t); }

int32_t ofl_input_shortcut(intptr_t i) { return input(i)->shortcut(); }
void ofl_input_set_shortcut(intptr_t i, int32_t s) { input(i)->shortcut(s); }

int32_t ofl_input_textfont(intptr_t i) { return input(i)->textfont(); }
void ofl_input_set_textfont(intptr_t i, int32_t f) { input(i)->textfont(f); }
int32_t ofl_input_textsize(intptr_t i) { return input(i)->textsize(); }
void ofl_input_set_textsize(intptr_t i, int32_t s) { input(i)->textsize(s); }

int32_t ofl_input_textcolor(intptr_t i) {
  return static_cast<int32_t>(input(i)->textcolor());
}

void ofl_input_set_textcolor(intptr_t i, int32_t c) {
  input(i)->textcolor(static_cast<Fl_Color>(c));
}

int32_t ofl_input_cursor_color(intptr_t i) {
  return static_cast<int32_t>(input(i)->cursor_color());
}

void ofl_input_set_cursor_color(intptr_t i, int32_t c) {
  input(i)->cursor_color(static_cast<Fl_Color>(c));
}

// Fl_Input_Choice is a group, but its children are FLTK's own, with no
// Oberon objects, and deleting one leaves it holding a dead pointer, so
// FlInputs gives it none of Fl.Group's methods.
//
// Fl_Menu_::add(const char *), done here: it cuts a part between |s at
// 1022 bytes into several items, dropping the byte after each cut
// (doc/fltk-issues.md, 161), and reads a shortcut from the tab before it,
// which strtol skips, so "^a" gives none (173). Each part is an item, its
// label up to a tab, cut as FlMenus cuts them (172), and its shortcut what
// follows the last tab, read by fl_old_shortcut.
void ofl_input_choice_add(intptr_t i, const char *s) {
  Fl_Menu_Button *m = chooser(i)->menubutton();
  while (*s) {
    size_t n = strcspn(s, "|");
    std::string part(s, n);
    size_t tab = part.find('\t');
    int sc = 0;
    if (tab != std::string::npos) {
      sc = static_cast<int>(fl_old_shortcut(part.c_str() + part.rfind('\t') + 1));
      part.resize(tab);
    }
    m->add(ofl::menu_path(part.c_str()).c_str(), sc, 0, 0, 0);
    s += n;
    if (*s) s++;
  }
}
void ofl_input_choice_clear(intptr_t i) { chooser(i)->clear(); }

// As ofl_menu_is_item: an index FLTK wouldn't check.
int32_t ofl_input_choice_is_item(intptr_t i, int32_t n) {
  Fl_Menu_Button *m = chooser(i)->menubutton();
  return n >= 0 && n < m->size() - 1 && m->text(n) != 0;
}

int32_t ofl_input_choice_length(intptr_t i) {
  return chooser(i)->menubutton()->size();
}

void ofl_input_choice_item(intptr_t i, int32_t n, char *buf, int32_t size) {
  ofl::copy_out(chooser(i)->menubutton()->text(n), buf, size);
}

int32_t ofl_input_choice_selected(intptr_t i) {
  return chooser(i)->menubutton()->value();
}

void ofl_input_choice_value(intptr_t i, char *buf, int32_t n) {
  ofl::copy_out(chooser(i)->value(), buf, n);
}

// The length of the text, in bytes, to its first 0X, as
// ofl_input_choice_value copies it.
int32_t ofl_input_choice_text_length(intptr_t i) {
  const char *s = chooser(i)->value();
  return s ? static_cast<int32_t>(strlen(s)) : 0;
}

void ofl_input_choice_set_value(intptr_t i, const char *s) {
  chooser(i)->value(s);
}

void ofl_input_choice_set_index(intptr_t i, int32_t n) {
  chooser(i)->value(static_cast<int>(n));
}

int32_t ofl_input_choice_update_menu(intptr_t i) {
  return chooser(i)->update_menubutton();
}

// These hide Fl_Widget's, and read and set the input's too.
int32_t ofl_input_choice_changed(intptr_t i) { return chooser(i)->changed() != 0; }
void ofl_input_choice_set_changed(intptr_t i) { chooser(i)->set_changed(); }
void ofl_input_choice_clear_changed(intptr_t i) { chooser(i)->clear_changed(); }

int32_t ofl_input_choice_down_box(intptr_t i) { return chooser(i)->down_box(); }

void ofl_input_choice_set_down_box(intptr_t i, int32_t b) {
  chooser(i)->down_box(static_cast<Fl_Boxtype>(b));
}

int32_t ofl_input_choice_textfont(intptr_t i) { return chooser(i)->textfont(); }
void ofl_input_choice_set_textfont(intptr_t i, int32_t f) { chooser(i)->textfont(f); }
int32_t ofl_input_choice_textsize(intptr_t i) { return chooser(i)->textsize(); }
void ofl_input_choice_set_textsize(intptr_t i, int32_t s) { chooser(i)->textsize(s); }

int32_t ofl_input_choice_textcolor(intptr_t i) {
  return static_cast<int32_t>(chooser(i)->textcolor());
}

void ofl_input_choice_set_textcolor(intptr_t i, int32_t c) {
  chooser(i)->textcolor(static_cast<Fl_Color>(c));
}

}  // extern "C"
