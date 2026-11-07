// The C++ part of FlText: text buffers, displays and editors. See pofltk.h
// for the conventions.
//
// A buffer belongs to Oberon until its TextBuffer is closed, and to the
// displays showing it, as their text or their styles; it is deleted when
// none of them holds it. FLTK's ~Fl_Text_Display still uses its buffer, and
// ~Fl_Text_Buffer doesn't detach its displays (doc/fltk-issues.md, 34), so
// a display's hold is released only after the display is destroyed: by
// Holds, a base class destroyed after Fl_Text_Display.

#include "pofltk.h"

#include <FL/Fl_Text_Buffer.H>
#include <FL/Fl_Text_Display.H>
#include <FL/Fl_Text_Editor.H>
#include <FL/fl_utf8.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <new>
#include <string>

namespace {

typedef void (*ModifiedFn)(intptr_t self, int32_t pos, int32_t inserted,
                           int32_t deleted, int32_t restyled);
ModifiedFn on_modified;

class Buffer : public Fl_Text_Buffer {
public:
  explicit Buffer(intptr_t self) : self_(self), users_(0) {
    add_modify_callback(modified, this);
  }
  // Oberon closes it: deleted now, or by the last display to let it go.
  void close() {
    self_ = 0;
    if (users_ == 0) delete this;
  }
  void hold() { ++users_; }
  void release() {
    if (--users_ == 0 && self_ == 0) delete this;
  }
  intptr_t self() const { return self_; }

private:
  // Every change, to the Oberon TextBuffer's Modified, while it is open.
  static void modified(int pos, int inserted, int deleted, int restyled,
                       const char *, void *arg) {
    Buffer *b = static_cast<Buffer *>(arg);
    if (b->self_ != 0 && on_modified != 0) {
      ofl::Dispatch d;
      on_modified(b->self_, pos, inserted, deleted, restyled);
    }
  }
  intptr_t self_;  // the Oberon TextBuffer, 0 once closed
  int users_;      // displays holding it
};

Buffer *buffer(intptr_t b) { return reinterpret_cast<Buffer *>(b); }

void release(Buffer *b) {
  if (b) b->release();
}

// What a display holds: its buffer, its style buffer, and its style table,
// which Fl_Text_Display::highlight_data keeps the pointer to.
class Holds {
public:
  Holds() : text(0), style(0), styles(0), nstyles(0), capacity(0) {}
  virtual ~Holds() {
    release(text);
    release(style);
    free(styles);
  }
  Buffer *text, *style;
  Fl_Text_Display::Style_Table_Entry *styles;
  int nstyles, capacity;
};

// Holds first, so it is destroyed after the display.
template <class B> class D : public Holds, public ofl::W<B> {
public:
  using ofl::W<B>::W;
};

template <class T>
intptr_t make(int32_t x, int32_t y, int32_t w, int32_t h, const char *label,
              intptr_t self) {
  D<T> *d = new D<T>(x, y, w, h);
  d->copy_label(ofl::label_text(label));
  return ofl::open(d, self);
}

Fl_Text_Display *display(intptr_t d) { return ofl::as<Fl_Text_Display>(d); }
Holds *holds(intptr_t d) { return dynamic_cast<Holds *>(ofl::widget(d)); }

// The style table to FLTK, if there is a style buffer and a style: with
// none, FLTK would read the entry before the table (doc/fltk-issues.md,
// 35).
void set_highlight(intptr_t d) {
  Holds *h = holds(d);
  if (h->style && h->nstyles > 0) {
    display(d)->highlight_data(h->style, h->styles, h->nstyles, 'A', 0, 0);
  } else {
    display(d)->highlight_data(0, 0, 0, 'A', 0, 0);
  }
  display(d)->redraw();
}

// FLTK's malloc'd text into buf, an Oberon ARRAY OF CHAR of n, and freed.
void give(char *s, char *buf, int32_t n) {
  ofl::copy_out(s, buf, n);
  free(s);
}

// Fl_Text_Buffer::insertfile, reading file into b at pos: 0, 1 if it can't
// be opened, 2 on a read error. FLTK's utf8_input_filter stops at a
// sequence cut short by the end of the file, and insertfile takes that
// for the end, so a Latin-1 é in the last three bytes loses it and
// all after it, with no warning (doc/fltk-issues.md, 141). Here each
// byte is decoded as FLTK's filter decodes it, up to the end of the
// file, where what is left decodes as fl_utf8decode decodes a bad byte.
int insert_file(Fl_Text_Buffer *b, const char *file, int pos) {
  FILE *fp = fl_fopen(file, "rb");
  if (!fp) return 1;
  std::string in, out;
  char chunk[65536];
  size_t r;
  int e = 0;
  try {
    while ((r = fread(chunk, 1, sizeof chunk, fp)) > 0) in.append(chunk, r);
  } catch (const std::bad_alloc &) {
    e = 2;
  }
  if (ferror(fp)) e = 2;
  fclose(fp);
  b->input_file_was_transcoded = false;
  if (e) return e;
  const char *p = in.data(), *end = p + in.size();
  char bytes[5];
  try {
    while (p < end) {
      int l = fl_utf8len1(*p);
      if (end - p < l) l = static_cast<int>(end - p);
      while (l > 0) {
        int lp;
        unsigned u = fl_utf8decode(p, p + l, &lp);
        int lq = fl_utf8encode(u, bytes);
        if (lp != l || lq != l) b->input_file_was_transcoded = true;
        out.append(bytes, lq);
        p += lp;
        l -= lp;
      }
    }
  } catch (const std::bad_alloc &) {
    return 2;
  }
  // As FLTK's insertfile does, a 0 byte ends the text inserted.
  b->insert(pos, out.c_str());
  if (b->input_file_was_transcoded && b->transcoding_warning_action)
    b->transcoding_warning_action(b);
  return 0;
}


// Key bindings (doc/fltk-issues.md, 147, 148). A Key_Func has no user
// data, so every binding of the program's is one of three trampolines,
// which call the Oberon dispatcher FlText's body registers with the
// editor, the key, the state as handle_key masks it, and which list the
// binding is in: 0 the editor's, 1 the global one, 2 the default key
// function. Each list's Oberon procedures are in an Oberon list in FLTK's
// order, and matched as FLTK matches, so the first match there is the
// binding FLTK chose.
typedef int32_t (*KeyFn)(intptr_t self, int32_t key, int32_t state,
                         int32_t which);
KeyFn on_key;

typedef Fl_Text_Editor::Key_Func Key_Func;
typedef Fl_Text_Editor::Key_Binding Key_Binding;

int run_key(int key, Fl_Text_Editor *e, int32_t which) {
  intptr_t self = ofl::object_of(e);
  if (self == 0 || on_key == 0) return 0;
  int state = Fl::event_state() & (FL_SHIFT | FL_CTRL | FL_ALT | FL_META);
  ofl::Dispatch d;
  return on_key(self, key, state, which);
}
int mine_key(int key, Fl_Text_Editor *e) { return run_key(key, e, 0); }
int global_key(int key, Fl_Text_Editor *e) { return run_key(key, e, 1); }
int default_key(int c, Fl_Text_Editor *e) { return run_key(c, e, 2); }

// FLTK's own functions, in pofltk's numbers (FlText's Kf constants).
const Key_Func builtins[] = {
    Fl_Text_Editor::kf_default,    Fl_Text_Editor::kf_ignore,
    Fl_Text_Editor::kf_backspace,  Fl_Text_Editor::kf_enter,
    Fl_Text_Editor::kf_move,       Fl_Text_Editor::kf_shift_move,
    Fl_Text_Editor::kf_ctrl_move,  Fl_Text_Editor::kf_c_s_move,
    Fl_Text_Editor::kf_meta_move,  Fl_Text_Editor::kf_m_s_move,
    Fl_Text_Editor::kf_home,       Fl_Text_Editor::kf_end,
    Fl_Text_Editor::kf_left,       Fl_Text_Editor::kf_up,
    Fl_Text_Editor::kf_right,      Fl_Text_Editor::kf_down,
    Fl_Text_Editor::kf_page_up,    Fl_Text_Editor::kf_page_down,
    Fl_Text_Editor::kf_insert,     Fl_Text_Editor::kf_delete,
    Fl_Text_Editor::kf_copy,       Fl_Text_Editor::kf_cut,
    Fl_Text_Editor::kf_paste,      Fl_Text_Editor::kf_select_all,
    Fl_Text_Editor::kf_undo,       Fl_Text_Editor::kf_redo};
const int32_t nbuiltins = sizeof builtins / sizeof builtins[0];

// What f is: a builtin's number, -1 none, -2 the program's, -3 another
// (C++ code's, or a platform's extra binding).
int32_t kind(Key_Func f) {
  if (f == 0) return -1;
  if (f == mine_key || f == global_key || f == default_key) return -2;
  for (int32_t i = 0; i < nbuiltins; i++) {
    if (f == builtins[i]) return i;
  }
  return -3;
}

// The editor's protected lists and default function, reached through a
// class derived from Fl_Text_Editor, which is never made.
struct Reach : Fl_Text_Editor {
  static Key_Binding *Fl_Text_Editor::*mine() { return &Reach::key_bindings; }
  static Key_Binding **global() { return &Reach::global_key_bindings; }
  static Key_Func Fl_Text_Editor::*dflt() {
    return &Reach::default_key_function_;
  }
};

Fl_Text_Editor *editor(intptr_t e) { return ofl::as<Fl_Text_Editor>(e); }

// The list of e's editor, or the global list if global.
Key_Binding **list(intptr_t e, int32_t global) {
  if (global) return Reach::global();
  return &(editor(e)->*Reach::mine());
}

// FLTK's own add_key_binding, remove_key_binding and remove_all, for
// either list: they are members, and the global list has no editor.
void add(Key_Binding **l, int key, int state, Key_Func f) {
  Key_Binding *kb = new Key_Binding;
  kb->key = key;
  kb->state = state;
  kb->function = f;
  kb->next = *l;
  *l = kb;
}

void clear(Key_Binding **l) {
  while (*l) {
    Key_Binding *next = (*l)->next;
    delete *l;
    *l = next;
  }
}

// FLTK never frees the global list, which pofltk's add made.
struct GlobalList {
  ~GlobalList() { clear(Reach::global()); }
} global_list;
// Whether f is a printf format for one int, or none, as FLTK passes
// linenumber_format() each line's number (snprintf): %% and at most one
// conversion of d, i, o, u, x or X, with flags, a width and a precision
// but no length or *. Anything else reads arguments that aren't there.
bool number_format_ok(const char *f) {
  int conversions = 0;
  for (; *f; f++) {
    if (*f != '%') continue;
    f++;
    if (*f == '%') continue;
    while (*f && strchr("-+ #0", *f)) f++;
    while (*f >= '0' && *f <= '9') f++;
    if (*f == '.') {
      f++;
      while (*f >= '0' && *f <= '9') f++;
    }
    if (*f == 0 || !strchr("diouxX", *f)) return false;
    conversions++;
  }
  return conversions <= 1;
}

// mNVisibleLines, the rows mLineStarts has (protected).
struct Rows : Fl_Text_Display {
  using Fl_Text_Display::mNVisibleLines;
};

}  // namespace

extern "C" {

void ofl_text_register(ModifiedFn modified) { on_modified = modified; }

void ofl_editor_register(KeyFn key) { on_key = key; }

// Buffers

intptr_t ofl_buffer_new(intptr_t self) {
  return reinterpret_cast<intptr_t>(new Buffer(self));
}

void ofl_buffer_close(intptr_t b) { buffer(b)->close(); }

int32_t ofl_buffer_length(intptr_t b) { return buffer(b)->length(); }

void ofl_buffer_set_text(intptr_t b, const char *s) { buffer(b)->text(s); }

void ofl_buffer_text(intptr_t b, char *buf, int32_t n) {
  give(buffer(b)->text(), buf, n);
}

void ofl_buffer_text_range(intptr_t b, int32_t start, int32_t end, char *buf,
                           int32_t n) {
  give(buffer(b)->text_range(start, end), buf, n);
}

int32_t ofl_buffer_char_at(intptr_t b, int32_t pos) {
  return static_cast<int32_t>(buffer(b)->char_at(pos));
}

int32_t ofl_buffer_byte_at(intptr_t b, int32_t pos) {
  return static_cast<unsigned char>(buffer(b)->byte_at(pos));
}

void ofl_buffer_insert(intptr_t b, int32_t pos, const char *s) {
  buffer(b)->insert(pos, s);
}

void ofl_buffer_remove(intptr_t b, int32_t start, int32_t end) {
  buffer(b)->remove(start, end);
}

void ofl_buffer_replace(intptr_t b, int32_t start, int32_t end,
                        const char *s) {
  buffer(b)->replace(start, end, s);
}

// 1 and the cursor position the change leaves in *pos, if there was one.
int32_t ofl_buffer_undo(intptr_t b, int32_t redo, int32_t *pos) {
  int p = 0;
  int r = redo ? buffer(b)->redo(&p) : buffer(b)->undo(&p);
  *pos = p;
  return r != 0;
}

int32_t ofl_buffer_can_undo(intptr_t b, int32_t redo) {
  return redo ? buffer(b)->can_redo() : buffer(b)->can_undo();
}

void ofl_buffer_set_can_undo(intptr_t b, int32_t on) {
  buffer(b)->canUndo(static_cast<char>(on));
}

// 0 or an errno. what: 0 load, 1 append, 2 insert at pos, 3 save, 4 save
// start to end.
int32_t ofl_buffer_file(intptr_t b, int32_t what, const char *name,
                        int32_t pos, int32_t end) {
  switch (what) {
    case 1: return insert_file(buffer(b), name, buffer(b)->length());
    case 2: return insert_file(buffer(b), name, pos);
    case 3: return buffer(b)->savefile(name);
    case 4: return buffer(b)->outputfile(name, pos, end);
    default: {
      Fl_Text_Buffer *t = buffer(b);
      t->select(0, t->length());
      t->remove_selection();
      return insert_file(t, name, 0);
    }
  }
}

int32_t ofl_buffer_tab_distance(intptr_t b) {
  return buffer(b)->tab_distance();
}

void ofl_buffer_set_tab_distance(intptr_t b, int32_t n) {
  buffer(b)->tab_distance(n);
}

void ofl_buffer_select(intptr_t b, int32_t start, int32_t end) {
  buffer(b)->select(start, end);
}

void ofl_buffer_unselect(intptr_t b) { buffer(b)->unselect(); }

int32_t ofl_buffer_selection(intptr_t b, int32_t *start, int32_t *end) {
  int s = 0, e = 0;
  int r = buffer(b)->selection_position(&s, &e);
  *start = s;
  *end = e;
  return r != 0;
}

void ofl_buffer_selection_text(intptr_t b, char *buf, int32_t n) {
  give(buffer(b)->selection_text(), buf, n);
}

void ofl_buffer_remove_selection(intptr_t b) {
  buffer(b)->remove_selection();
}

void ofl_buffer_replace_selection(intptr_t b, const char *s) {
  buffer(b)->replace_selection(s);
}

// The buffer's secondary selection, which, 1, and its highlight, which, 2.
void ofl_buffer_mark(intptr_t b, int32_t which, int32_t start, int32_t end) {
  if (which == 1) {
    buffer(b)->secondary_select(start, end);
  } else {
    buffer(b)->highlight(start, end);
  }
}

void ofl_buffer_unmark(intptr_t b, int32_t which) {
  if (which == 1) {
    buffer(b)->secondary_unselect();
  } else {
    buffer(b)->unhighlight();
  }
}

void ofl_buffer_marked_text(intptr_t b, int32_t which, char *buf, int32_t n) {
  give(which == 1 ? buffer(b)->secondary_selection_text()
                  : buffer(b)->highlight_text(), buf, n);
}

void ofl_buffer_remove_secondary(intptr_t b) {
  buffer(b)->remove_secondary_selection();
}

void ofl_buffer_replace_secondary(intptr_t b, const char *s) {
  buffer(b)->replace_secondary_selection(s);
}

// A selection of the buffer, which 0 primary, 1 secondary, 2 highlight.
// what: 0 selected, 1 start, 2 end, 3 length.
int32_t ofl_selection_get(intptr_t b, int32_t which, int32_t what) {
  const Fl_Text_Buffer *buf = buffer(b);
  const Fl_Text_Selection *s = which == 0   ? buf->primary_selection()
                               : which == 1 ? buf->secondary_selection()
                                            : buf->highlight_selection();
  switch (what) {
    case 0: return s->selected() ? 1 : 0;
    case 1: return s->start();
    case 2: return s->end();
    default: return s->length();
  }
}

int32_t ofl_selection_includes(intptr_t b, int32_t which, int32_t pos) {
  const Fl_Text_Buffer *buf = buffer(b);
  const Fl_Text_Selection *s = which == 0   ? buf->primary_selection()
                               : which == 1 ? buf->secondary_selection()
                                            : buf->highlight_selection();
  return s->includes(pos);
}

// what: 0 line_start, 1 line_end, 2 word_start, 3 word_end, 4 next_char,
// 5 prev_char, 6 utf8_align.
int32_t ofl_buffer_pos(intptr_t b, int32_t what, int32_t pos) {
  Buffer *buf = buffer(b);
  switch (what) {
    case 1: return buf->line_end(pos);
    case 2: return buf->word_start(pos);
    case 3: return buf->word_end(pos);
    case 4: return buf->next_char(pos);
    case 5: return buf->prev_char(pos);
    case 6: return buf->utf8_align(pos);
    default: return buf->line_start(pos);
  }
}

void ofl_buffer_line_text(intptr_t b, int32_t pos, char *buf, int32_t n) {
  give(buffer(b)->line_text(pos), buf, n);
}

int32_t ofl_buffer_count_lines(intptr_t b, int32_t start, int32_t end) {
  return buffer(b)->count_lines(start, end);
}

int32_t ofl_buffer_skip_lines(intptr_t b, int32_t start, int32_t n) {
  return buffer(b)->skip_lines(start, n);
}

int32_t ofl_buffer_rewind_lines(intptr_t b, int32_t start, int32_t n) {
  return buffer(b)->rewind_lines(start, n);
}

// Characters, not bytes, from start to target, or n of them from start,
// stopping at a newline. FLTK doesn't clamp either position.
int32_t ofl_buffer_displayed(intptr_t b, int32_t skip, int32_t start,
                             int32_t n) {
  Fl_Text_Buffer *t = buffer(b);
  int len = t->length();
  start = t->utf8_align(start < 0 ? 0 : start > len ? len : start);
  if (skip) return t->skip_displayed_characters(start, n);
  return t->count_displayed_characters(start, n < start ? start : n > len ? len : n);
}

// 1 and the position in *found if the character c is found from start,
// forward or back.
int32_t ofl_buffer_findchar(intptr_t b, int32_t back, int32_t start,
                            int32_t c, int32_t *found) {
  Fl_Text_Buffer *t = buffer(b);
  int len = t->length();
  start = t->utf8_align(start < 0 ? 0 : start > len ? len : start);
  int f = 0;
  unsigned u = static_cast<unsigned>(c);
  int r = back ? t->findchar_backward(start, u, &f) : t->findchar_forward(start, u, &f);
  *found = f;
  return r != 0;
}

// 1 and the position in *found if s is found from start. FLTK's search
// matching case reads past the end of the text (doc/fltk-issues.md, 36),
// so that one is done here, a byte at a time with byte_at, which checks
// its position. A UTF-8 string matches only at the start of a character,
// so this finds what FLTK's would. Without matching case FLTK reads
// through char_at, which checks too.
int32_t ofl_buffer_search(intptr_t b, int32_t backward, int32_t start,
                          const char *s, int32_t *found, int32_t match_case) {
  Buffer *buf = buffer(b);
  if (!match_case) {
    // From past the end, search_backward's prev_char never moves, and it
    // never returns (doc/fltk-issues.md, 139).
    if (start > buf->length()) start = buf->length();
    int f = 0;
    int r = backward ? buf->search_backward(start, s, &f, 0)
                     : buf->search_forward(start, s, &f, 0);
    *found = f;
    return r != 0;
  }
  int n = static_cast<int>(strlen(s)), len = buf->length();
  int last = len - n;  // the last position s fits at
  int p = start < 0 ? 0 : start;
  if (backward && p > last) p = last;
  for (; p >= 0 && p <= last; p += backward ? -1 : 1) {
    int i = 0;
    while (i < n && buf->byte_at(p + i) == s[i]) ++i;
    if (i == n) {
      *found = p;
      return 1;
    }
  }
  return 0;
}

// Displays and editors

// kind is 0 Fl_Text_Display, 1 Fl_Text_Editor.
intptr_t ofl_text_new(int32_t kind, int32_t x, int32_t y, int32_t w,
                      int32_t h, const char *label, intptr_t self) {
  if (kind == 1) return make<Fl_Text_Editor>(x, y, w, h, label, self);
  return make<Fl_Text_Display>(x, y, w, h, label, self);
}

// b may be 0, for none.
void ofl_text_set_buffer(intptr_t d, intptr_t b) {
  Holds *h = holds(d);
  Buffer *old = h->text;
  if (buffer(b) == old) return;
  if (b) buffer(b)->hold();
  display(d)->buffer(buffer(b));
  h->text = buffer(b);
  release(old);
}

void ofl_text_set_style_buffer(intptr_t d, intptr_t b) {
  Holds *h = holds(d);
  Buffer *old = h->style;
  if (buffer(b) == old) return;
  if (b) buffer(b)->hold();
  h->style = buffer(b);
  set_highlight(d);
  release(old);
}

// Adds a style, 'A' + its index in the table, and returns the index.
int32_t ofl_text_add_style(intptr_t d, int32_t color, int32_t font,
                           int32_t size, int32_t attr, int32_t bgcolor) {
  Holds *h = holds(d);
  if (h->nstyles == h->capacity) {
    int capacity = h->capacity ? 2 * h->capacity : 8;
    void *p = realloc(h->styles, capacity * sizeof *h->styles);
    if (p == 0) return -1;
    h->styles = static_cast<Fl_Text_Display::Style_Table_Entry *>(p);
    h->capacity = capacity;
  }
  Fl_Text_Display::Style_Table_Entry &e = h->styles[h->nstyles];
  e.color = static_cast<Fl_Color>(color);
  e.font = font;
  e.size = size;
  e.attr = static_cast<unsigned>(attr);
  e.bgcolor = static_cast<Fl_Color>(bgcolor);
  ++h->nstyles;
  set_highlight(d);
  return h->nstyles - 1;
}

void ofl_text_clear_styles(intptr_t d) {
  holds(d)->nstyles = 0;
  set_highlight(d);
}

int32_t ofl_text_insert_position(intptr_t d) {
  return display(d)->insert_position();
}

void ofl_text_set_insert_position(intptr_t d, int32_t pos) {
  display(d)->insert_position(pos);
}

void ofl_text_show_insert_position(intptr_t d) {
  display(d)->show_insert_position();
}

// Typed at the cursor, as the user would: over the selection if any.
void ofl_text_insert(intptr_t d, const char *s, int32_t overstrike) {
  if (overstrike) {
    display(d)->overstrike(s);
  } else {
    display(d)->insert(s);
  }
}

// what: 0 right, 1 left, 2 up, 3 down, 4 next word, 5 previous word. 1
// if the cursor moved (always, for the words).
int32_t ofl_text_move(intptr_t d, int32_t what) {
  Fl_Text_Display *t = display(d);
  switch (what) {
    case 1: return t->move_left();
    case 2: return t->move_up();
    case 3: return t->move_down();
    case 4: t->next_word(); return 1;
    case 5: t->previous_word(); return 1;
    default: return t->move_right();
  }
}

void ofl_text_scroll(intptr_t d, int32_t line, int32_t offset) {
  display(d)->scroll(line, offset);
}

// 1 and the position's x, y if it is shown.
int32_t ofl_text_position_to_xy(intptr_t d, int32_t pos, int32_t *x,
                                int32_t *y) {
  int X = 0, Y = 0;
  int r = display(d)->position_to_xy(pos, &X, &Y);
  *x = X;
  *y = Y;
  return r != 0;
}

int32_t ofl_text_in_selection(intptr_t d, int32_t x, int32_t y) {
  return display(d)->in_selection(x, y) != 0;
}

// Lines as shown, wrapped. what: 0 line_start, 1 line_end (from a line's
// start if wrapped), 2 count_lines to end, 3 skip_lines n, 4 rewind_lines
// n.
int32_t ofl_text_line(intptr_t d, int32_t what, int32_t pos, int32_t n) {
  Fl_Text_Display *t = display(d);
  switch (what) {
    case 1: return t->line_end(pos, n != 0);
    case 2: return t->count_lines(pos, n, false);
    case 3: return t->skip_lines(pos, n, false);
    case 4: return t->rewind_lines(pos, n);
    default: return t->line_start(pos);
  }
}

void ofl_text_wrap_mode(intptr_t d, int32_t mode, int32_t margin) {
  display(d)->wrap_mode(mode, margin);
}

// The buffer's row or column of row on the screen, wrapped. FLTK reads one
// past its rows for row = mNVisibleLines (doc/fltk-issues.md, 151), so
// that is checked here, and returns what FLTK does for rows outside.
int32_t ofl_text_wrapped(intptr_t d, int32_t row, int32_t column, int32_t col) {
  Fl_Text_Display *t = display(d);
  if (row < 0 || row >= t->*(&Rows::mNVisibleLines)) return col ? column : row;
  return col ? t->wrapped_column(row, column) : t->wrapped_row(row);
}

void ofl_text_redisplay_range(intptr_t d, int32_t start, int32_t end) {
  display(d)->redisplay_range(start, end);
}

// Line numbers' alignment and printf format: 0 if f isn't one FLTK can
// use (number_format_ok). FLTK copies the format.
void ofl_text_set_linenumber_align(intptr_t d, int32_t a) {
  display(d)->linenumber_align(static_cast<Fl_Align>(a));
  display(d)->redraw();
}

int32_t ofl_text_linenumber_align(intptr_t d) {
  return static_cast<int32_t>(display(d)->linenumber_align());
}

int32_t ofl_text_set_linenumber_format(intptr_t d, const char *f) {
  if (!number_format_ok(f)) return 0;
  display(d)->linenumber_format(f);
  display(d)->redraw();
  return 1;
}

void ofl_text_linenumber_format(intptr_t d, char *buf, int32_t n) {
  const char *f = display(d)->linenumber_format();
  ofl::copy_out(f ? f : "", buf, n);
}

void ofl_text_show_cursor(intptr_t d, int32_t on) {
  display(d)->show_cursor(on);
}

// what: 0 text font, 1 text size, 2 text color, 3 cursor style, 4 cursor
// color, 5 line number width, 6 line number font, 7 line number size, 8
// line number fg color, 9 line number bg color, 10 scrollbar size, 11
// shortcut, 12 insert mode (editors), 13 tab navigation (editors).
int32_t ofl_text_get(intptr_t d, int32_t what) {
  Fl_Text_Display *t = display(d);
  Fl_Text_Editor *e = dynamic_cast<Fl_Text_Editor *>(t);
  switch (what) {
    case 1: return t->textsize();
    case 2: return static_cast<int32_t>(t->textcolor());
    case 3: return t->cursor_style();
    case 4: return static_cast<int32_t>(t->cursor_color());
    case 5: return t->linenumber_width();
    case 6: return t->linenumber_font();
    case 7: return t->linenumber_size();
    case 8: return static_cast<int32_t>(t->linenumber_fgcolor());
    case 9: return static_cast<int32_t>(t->linenumber_bgcolor());
    case 10: return t->scrollbar_size();
    case 11: return t->shortcut();
    case 12: return e ? e->insert_mode() : 0;
    case 13: return e ? e->tab_nav() : 0;
    default: return t->textfont();
  }
}

void ofl_text_set(intptr_t d, int32_t what, int32_t v) {
  Fl_Text_Display *t = display(d);
  Fl_Text_Editor *e = dynamic_cast<Fl_Text_Editor *>(t);
  switch (what) {
    case 1: t->textsize(v); break;
    case 2: t->textcolor(static_cast<Fl_Color>(v)); break;
    case 3: t->cursor_style(v); break;
    case 4: t->cursor_color(static_cast<Fl_Color>(v)); break;
    case 5: t->linenumber_width(v); break;
    case 6: t->linenumber_font(v); break;
    case 7: t->linenumber_size(v); break;
    case 8: t->linenumber_fgcolor(static_cast<Fl_Color>(v)); break;
    case 9: t->linenumber_bgcolor(static_cast<Fl_Color>(v)); break;
    case 10: t->scrollbar_size(v); break;
    case 11: t->shortcut(v); break;
    case 12: if (e) e->insert_mode(v); break;
    default: t->textfont(v);
  }
  t->redraw();
}

// Key bindings. global: 1 the global list, 0 e's (e is then unused for
// the global list). kf: a builtin's number, or -2 the program's.
void ofl_editor_bind(intptr_t e, int32_t global, int32_t key, int32_t state,
                     int32_t kf) {
  Key_Func f = global ? global_key : mine_key;
  if (kf >= 0 && kf < nbuiltins) f = builtins[kf];
  add(list(e, global), key, state, f);
}

// Removes the first binding of key and state exactly, as FLTK's
// remove_key_binding does, and says what it was (kind).
int32_t ofl_editor_unbind(intptr_t e, int32_t global, int32_t key,
                          int32_t state) {
  Key_Binding **l = list(e, global);
  for (; *l; l = &(*l)->next) {
    if ((*l)->key == key && (*l)->state == state) {
      Key_Binding *cur = *l;
      int32_t k = kind(cur->function);
      *l = cur->next;
      delete cur;
      return k;
    }
  }
  return -1;
}

void ofl_editor_unbind_all(intptr_t e, int32_t global) {
  clear(list(e, global));
}

void ofl_editor_add_defaults(intptr_t e) {
  Fl_Text_Editor *t = editor(e);
  t->add_default_key_bindings(&(t->*Reach::mine()));
}

// What key and state are bound to, as FLTK's bound_key_function finds it.
int32_t ofl_editor_bound(intptr_t e, int32_t global, int32_t key,
                         int32_t state) {
  Fl_Text_Editor *t = editor(e);
  return kind(t->bound_key_function(key, state, *list(e, global)));
}

// The default key function: kf a builtin, -1 none, -2 the program's.
void ofl_editor_set_default(intptr_t e, int32_t kf) {
  Key_Func f = 0;
  if (kf >= 0 && kf < nbuiltins) f = builtins[kf];
  else if (kf == -2) f = default_key;
  editor(e)->default_key_function(f);
}

int32_t ofl_editor_default(intptr_t e) {
  return kind(editor(e)->*Reach::dflt());
}

// FLTK's own function kf, called with key: a callback it does, which can
// delete the editor, is a dispatch, so the deletion waits.
int32_t ofl_editor_builtin(intptr_t e, int32_t kf, int32_t key) {
  if (kf < 0 || kf >= nbuiltins) return 0;
  ofl::Dispatch d;
  return builtins[kf](key, editor(e));
}

}  // extern "C"
