// The C++ part of FlTerminal: Fl_Terminal. See pofltk.h for the
// conventions.
//
// Most of FLTK's setters leave the cursor, and the place an escape
// sequence saved, where they were, on a screen that may now be smaller,
// and the next character is written outside the row (doc/fltk-issues.md,
// 96). So each goes through Term::fit, as does a resize.

#include "pofltk.h"

#include <FL/Fl_Terminal.H>

#include <string>

namespace {

// A private member, reached as FlBrowsers.cpp reaches Fl_Tree's.
template <class Tag, typename Tag::type M> struct Reach {
  friend typename Tag::type member(Tag) { return M; }
};

// More than this many cells is refused: FLTK's sizes are ints, and a
// failed allocation would throw through Oberon.
const int64_t max_cells = 1 << 24;

// What a terminal keeps beside FLTK's object.
struct State {
  std::string error_text;  // FLTK keeps the pointer it is given
};

class Term : public State, public ofl::W<Fl_Terminal> {
public:
  struct Seq {
    typedef EscapeSeq Fl_Terminal::*type;
    friend type member(Seq);
  };
  struct Modified {
    typedef bool Fl_Terminal::*type;
    friend type member(Modified);
  };

  Term(int x, int y, int w, int h) : ofl::W<Fl_Terminal>(x, y, w, h) {}

  using Fl_Terminal::cursor_col;
  using Fl_Terminal::cursor_cr;
  using Fl_Terminal::cursor_crlf;
  using Fl_Terminal::cursor_down;
  using Fl_Terminal::cursor_eol;
  using Fl_Terminal::cursor_left;
  using Fl_Terminal::cursor_right;
  using Fl_Terminal::cursor_row;
  using Fl_Terminal::cursor_sol;
  using Fl_Terminal::cursor_tab_left;
  using Fl_Terminal::cursor_tab_right;
  using Fl_Terminal::cursor_up;
  using Fl_Terminal::save_cursor;

  void fit();
  void restore();

  // Fl_Terminal::display_modified is private, and the printing and
  // cursor methods don't call it; this is the public way there, so
  // redraw_style is obeyed.
  void modified() { append_ascii(""); }

  // FLTK's flag that a change waits to be drawn: PER_WRITE redraws only
  // while it is false, and only RATE_LIMITED's timer clears it, so a
  // terminal redraws once under PER_WRITE, and then never again; and one
  // that changed under RATE_LIMITED, as opening it does, never
  // (doc/fltk-issues.md, 142). Under PER_WRITE it is cleared after each
  // draw; under RATE_LIMITED its timer's work is left alone, since a
  // draw clipped to part of the terminal would then cancel the timer's
  // redraw (FLTKAda-BUGS.md, 87).
  bool &waiting() { return this->*member(Modified()); }

  void draw() override {
    ofl::W<Fl_Terminal>::draw();
    if (redraw_style() == PER_WRITE) waiting() = false;
  }

  // A change waiting for RATE_LIMITED's timer, which FLTK removes, is
  // drawn now, unless nothing is to be.
  void set_redraw_style(RedrawStyle style) {
    bool was = waiting();
    redraw_style(style);
    waiting() = false;
    if (was && style != NO_REDRAW) redraw();
  }

  void base_resize(int x, int y, int w, int h) override {
    ofl::W<Fl_Terminal>::base_resize(x, y, w, h);
    fit();
  }
};

template struct Reach<Term::Seq, &Fl_Terminal::escseq>;
template struct Reach<Term::Modified, &Fl_Terminal::redraw_modified_>;

// The cursor and the saved cursor, moved back onto the screen. The
// setters clamp.
void Term::fit() {
  cursor_row(cursor_row());
  cursor_col(cursor_col());
  EscapeSeq &seq = this->*member(Seq());
  int row, col;
  seq.restore_cursor(row, col);
  if (row >= 0 || col >= 0) {
    if (row >= display_rows()) row = display_rows() - 1;
    if (col >= display_columns()) col = display_columns() - 1;
    seq.save_cursor(row, col);
  }
}

// restore_cursor tests its column against 1, not -1, so a place in
// column 1 isn't restored (doc/fltk-issues.md, 97).
void Term::restore() {
  EscapeSeq &seq = this->*member(Seq());
  int row, col;
  seq.restore_cursor(row, col);
  if (row >= 0 && col >= 0) {
    cursor_row(row);
    cursor_col(col);
  }
}

Term *term(intptr_t h) { return dynamic_cast<Term *>(ofl::widget(h)); }

// Copies what FLTK returned, and frees it; its length.
int32_t take(const char *s, char *buf, int32_t n) {
  int32_t len = static_cast<int32_t>(strlen(s));
  if (n > 0) ofl::copy_out(s, buf, n);
  free(const_cast<char *>(s));
  return len;
}

// One printable UTF-8 character of at most FLTK's 4 bytes: it writes an
// error character with no check, and calls for one when it prints a
// control character (doc/fltk-issues.md, 98).
bool one_character(const char *s) {
  size_t len = strlen(s);
  if (len < 1 || len > 4) return false;
  if (static_cast<unsigned char>(s[0]) < 0x20) return false;
  if (fl_utf8len(s[0]) != static_cast<int>(len)) return false;
  for (size_t i = 1; i < len; i++) {
    if ((s[i] & 0xC0) != 0x80) return false;
  }
  return true;
}

}  // namespace

extern "C" {

intptr_t ofl_terminal_new(int32_t x, int32_t y, int32_t w, int32_t h,
                          const char *label, intptr_t self) {
  Term *t = new Term(x, y, w, h);
  t->copy_label(ofl::label_text(label));
  return ofl::open(t, self);
}

// Whether rows and columns on the screen and rows of history fit.
int32_t ofl_terminal_fits(int32_t rows, int32_t history, int32_t columns) {
  return (static_cast<int64_t>(rows) + history) * columns <= max_cells;
}

// The integer properties, by what: Oberon's constants name them.
int32_t ofl_terminal_get(intptr_t h, int32_t what) {
  Term *t = term(h);
  switch (what) {
    case 0: return t->display_rows();
    case 1: return t->display_columns();
    case 2: return t->history_rows();
    case 3: return t->history_use();
    case 4: return t->scrollbar_size();
    case 5: return t->scrollbar_actual_size();
    case 6: return t->hscrollbar_style();
    case 7: return t->margin_left();
    case 8: return t->margin_right();
    case 9: return t->margin_top();
    case 10: return t->margin_bottom();
    case 11: return t->textfont();
    case 12: return t->textsize();
    case 13: return t->textattrib();
    case 14: return t->redraw_style();
    case 15: return t->show_unknown();
    case 16: return t->ansi();
    case 17: return t->output_translate();
    case 18: return t->cursor_row();
    case 19: return t->cursor_col();
    default: return 0;
  }
}

void ofl_terminal_set(intptr_t h, int32_t what, int32_t v) {
  Term *t = term(h);
  switch (what) {
    case 0: t->display_rows(v); break;
    case 1: t->display_columns(v); break;
    case 2: t->history_rows(v); break;
    case 4: t->scrollbar_size(v); break;
    case 6:
      t->hscrollbar_style(static_cast<Fl_Terminal::ScrollbarStyle>(v));
      break;
    case 7: t->margin_left(v); break;
    case 8: t->margin_right(v); break;
    case 9: t->margin_top(v); break;
    case 10: t->margin_bottom(v); break;
    case 11: t->textfont(v); break;
    case 12: t->textsize(v); break;
    case 13: t->textattrib(static_cast<uchar>(v)); break;
    case 14:
      t->set_redraw_style(static_cast<Fl_Terminal::RedrawStyle>(v));
      break;
    case 15: t->show_unknown(v != 0); break;
    case 16: t->ansi(v != 0); break;
    case 17:
      t->output_translate(static_cast<Fl_Terminal::OutFlags>(v));
      break;
    case 18: t->cursor_row(v); t->modified(); break;
    case 19: t->cursor_col(v); t->modified(); break;
    default: break;
  }
  t->fit();
}

// The colors, by what, as with the properties above.
uint32_t ofl_terminal_color(intptr_t h, int32_t what) {
  Term *t = term(h);
  switch (what) {
    case 0: return t->textfgcolor();
    case 1: return t->textbgcolor();
    case 2: return t->textfgcolor_default();
    case 3: return t->textbgcolor_default();
    case 4: return t->selectionfgcolor();
    case 5: return t->selectionbgcolor();
    case 6: return t->cursorfgcolor();
    case 7: return t->cursorbgcolor();
    default: return 0;
  }
}

void ofl_terminal_set_color(intptr_t h, int32_t what, uint32_t c) {
  Term *t = term(h);
  switch (what) {
    case 0: t->textfgcolor(c); break;
    case 1: t->textbgcolor(c); break;
    case 2: t->textfgcolor_default(c); break;
    case 3: t->textbgcolor_default(c); break;
    case 4: t->selectionfgcolor(c); break;
    case 5: t->selectionbgcolor(c); break;
    case 6: t->cursorfgcolor(c); break;
    case 7: t->cursorbgcolor(c); break;
    case 8: t->textcolor(c); break;
    default: break;
  }
}

void ofl_terminal_set_xterm(intptr_t h, int32_t background, int32_t c) {
  if (background) {
    term(h)->textbgcolor_xterm(static_cast<uchar>(c));
  } else {
    term(h)->textfgcolor_xterm(static_cast<uchar>(c));
  }
}

// Fl_Terminal::box hides Fl_Widget's, and lays the screen out again.
void ofl_terminal_box(intptr_t h, int32_t b) {
  Term *t = term(h);
  t->box(static_cast<Fl_Boxtype>(b));
  t->fit();
}

double ofl_terminal_redraw_rate(intptr_t h) { return term(h)->redraw_rate(); }

void ofl_terminal_set_redraw_rate(intptr_t h, double rate) {
  term(h)->redraw_rate(static_cast<float>(rate));
}

int32_t ofl_terminal_set_error_char(intptr_t h, const char *s) {
  if (!one_character(s)) return 0;
  Term *t = term(h);
  t->error_text = s;
  t->error_char(t->error_text.c_str());
  return 1;
}

void ofl_terminal_error_char(intptr_t h, char *buf, int32_t n) {
  ofl::copy_out(term(h)->error_char(), buf, n);
}

void ofl_terminal_append(intptr_t h, const char *s) { term(h)->append(s); }

void ofl_terminal_append_ascii(intptr_t h, const char *s) {
  term(h)->append_ascii(s);
}

void ofl_terminal_append_utf8(intptr_t h, const char *s) {
  term(h)->append_utf8(s);
}

// print_char and plot_char are told the length, since with none they
// trust the first byte, and read past a cut character.
void ofl_terminal_print_char(intptr_t h, const char *s) {
  if (!*s) return;
  Term *t = term(h);
  t->print_char(s, static_cast<int>(strlen(s)));
  t->modified();
}

void ofl_terminal_plot_char(intptr_t h, const char *s, int32_t row,
                            int32_t col) {
  if (!*s) return;
  Term *t = term(h);
  int len = static_cast<int>(strlen(s));
  if (len == 1) {
    t->plot_char(*s, row, col);
  } else {
    t->plot_char(s, len, row, col);
  }
  t->modified();
}

void ofl_terminal_clear(intptr_t h) {
  Term *t = term(h);
  t->clear();
  t->modified();
}

void ofl_terminal_clear_color(intptr_t h, uint32_t c) {
  Term *t = term(h);
  t->clear(c);
  t->modified();
}

void ofl_terminal_clear_screen(intptr_t h, int32_t to_history, int32_t home) {
  Term *t = term(h);
  if (home) {
    t->clear_screen_home(to_history != 0);
  } else {
    t->clear_screen(to_history != 0);
  }
  t->modified();
}

void ofl_terminal_clear_history(intptr_t h) {
  Term *t = term(h);
  t->clear_history();
  t->modified();
}

void ofl_terminal_reset(intptr_t h) {
  Term *t = term(h);
  t->reset_terminal();
  t->modified();
}

// The cursor's movements, by what. FLTK takes a count of 0 as 1, so
// Oberon doesn't call with one.
void ofl_terminal_cursor(intptr_t h, int32_t what, int32_t count,
                         int32_t scroll) {
  Term *t = term(h);
  switch (what) {
    case 0: t->cursor_up(count, scroll != 0); break;
    case 1: t->cursor_down(count, scroll != 0); break;
    case 2: t->cursor_left(count); break;
    case 3: t->cursor_right(count, scroll != 0); break;
    case 4: t->cursor_home(); break;
    case 5: t->cursor_eol(); break;
    case 6: t->cursor_sol(); break;
    case 7: t->cursor_cr(); break;
    case 8: t->cursor_crlf(count); break;
    case 9:
    case 10:
      // FLTK's tabs stop at the first tab stop whatever the count
      // (doc/fltk-issues.md, 140), so one at a time, and no more than a
      // line holds.
      for (int i = 0; i < count && i < t->display_columns(); ++i) {
        int col = t->cursor_col();
        if (what == 9) t->cursor_tab_right(1); else t->cursor_tab_left(1);
        if (t->cursor_col() == col) break;
      }
      break;
    case 11: t->save_cursor(); break;
    case 12: t->restore(); break;
    default: break;
  }
  t->modified();
}

int32_t ofl_terminal_text(intptr_t h, int32_t below, char *buf, int32_t n) {
  return take(term(h)->text(below != 0), buf, n);
}

int32_t ofl_terminal_selection(intptr_t h, char *buf, int32_t n) {
  return take(term(h)->selection_text(), buf, n);
}

}  // extern "C"
