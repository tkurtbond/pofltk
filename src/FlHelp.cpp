// The C++ part of FlHelp: Fl_Help_View, whose links and images are asked
// of the Oberon object's Link, and Fl_Help_Dialog. See pofltk.h for the
// conventions.
//
// A view's link function answers two questions FLTK doesn't tell apart:
// what to load, as a page loads, and where an image is, as a page is
// laid out, drawn or freed. FLTK asks the second again for each of these,
// and releases what the answer names (doc/fltk-issues.md, 90), so each
// image's answer is remembered, and given again with no Oberon called,
// in a drawing or a destructor.

#include "pofltk.h"

#include <FL/Fl_Help_Dialog.H>
#include <FL/Fl_Help_View.H>
#include <FL/platform.H>

#include <map>
#include <string>

namespace {

typedef int32_t (*LinkFn)(intptr_t self, const char *uri);

// The Oberon dispatcher, which FlHelp's body registers.
LinkFn on_link;

// What a view keeps beside FLTK's object.
struct ViewState {
  std::map<std::string, std::string> images;  // the answers about images
  std::string answer;                         // the last Link's
  bool loading;      // the next question is what to load
  bool in_image;     // in Link, about an image
  bool in_load;      // in Link, about what to load
  bool set_in_link;  // the text was set there
  unsigned changes;  // of the layout, whose links a pushed link is one of
  unsigned at_push;  // changes when the mouse was pushed
  ViewState()
      : loading(false), in_image(false), in_load(false), set_in_link(false),
        changes(0), at_push(0) {}
};

const char *help_link(Fl_Widget *w, const char *uri);

class View : public ViewState, public ofl::W<Fl_Help_View> {
public:
  View(int x, int y, int w, int h) : ofl::W<Fl_Help_View>(x, y, w, h) {
    link(help_link);
  }
  // The destructor of Fl_Help_View would ask about its images once this
  // class is gone.
  ~View() { value(0); }

  // After the view's own Handle. A link pushed holds on to the layout
  // till the release, which follows it (doc/fltk-issues.md, 89), so a
  // layout changed since must not be followed.
  int base_handle(int event) override {
    if (event == FL_PUSH) {
      at_push = changes;
    } else if (event == FL_RELEASE) {
      if (changes != at_push) Fl::event_is_click(0);
      loading = true;
    }
    int r = ofl::W<Fl_Help_View>::base_handle(event);
    loading = false;
    return r;
  }
  void base_resize(int x, int y, int w, int h) override {
    ++changes;
    ofl::W<Fl_Help_View>::base_resize(x, y, w, h);
  }
};

View *view(intptr_t h) { return dynamic_cast<View *>(ofl::widget(h)); }

const char *ask(View *v, const char *uri) {
  ofl::Dispatch d;
  return on_link(ofl::self_of(v), uri) ? v->answer.c_str() : 0;
}

const char *help_link(Fl_Widget *w, const char *uri) {
  View *v = dynamic_cast<View *>(w);
  if (!v) return uri;
  if (v->loading) {
    v->loading = false;
    v->in_load = true;
    const char *r = ask(v, uri);
    v->in_load = false;
    return r;
  }
  std::map<std::string, std::string>::iterator i = v->images.find(uri);
  if (i != v->images.end()) return i->second.c_str();
  const char *r = 0;
  if (v->user_data()) {
    bool was = v->in_image;
    v->in_image = true;
    r = ask(v, uri);
    v->in_image = was;
  }
  // "" names nothing, so a broken image, where NULL would crash FLTK.
  return (v->images[uri] = r ? r : "").c_str();
}

Fl_Help_Dialog *dialog(intptr_t d) {
  return reinterpret_cast<Fl_Help_Dialog *>(d);
}

}  // namespace

extern "C" {

void ofl_help_register(LinkFn f) { on_link = f; }

intptr_t ofl_help_new(int32_t x, int32_t y, int32_t w, int32_t h,
                      const char *label, intptr_t self) {
  View *v = new View(x, y, w, h);
  v->copy_label(ofl::label_text(label));
  return ofl::open(v, self);
}

// What Link answers, copied for FLTK to read when it returns.
void ofl_help_answer(intptr_t h, const char *s) { view(h)->answer = s; }

// 1 if the view is in Link about an image.
int32_t ofl_help_in_image(intptr_t h) { return view(h)->in_image; }

// 1 if f was loaded, or Link set the view's text; FLTK sets its own
// message in the view for a file it can't read. A URI of a scheme FLTK
// gives the system's browser is loaded as far as FLTK knows.
int32_t ofl_help_load(intptr_t h, const char *f) {
  View *v = view(h);
  ++v->changes;
  v->set_in_link = false;
  v->loading = true;
  int r = v->load(f);
  v->loading = false;
  return r == 0 || v->set_in_link;
}

// The text, which FLTK copies; NULL gives none.
void ofl_help_set_value(intptr_t h, const char *s) {
  View *v = view(h);
  ++v->changes;
  if (v->in_load) v->set_in_link = true;
  v->value(s);
}

intptr_t ofl_help_value(intptr_t h) {
  return reinterpret_cast<intptr_t>(view(h)->value());
}

// The text, by what: 0 directory, 1 file name, 2 title.
intptr_t ofl_help_text(intptr_t h, int32_t what) {
  View *v = view(h);
  const char *s;
  switch (what) {
    case 0: s = v->directory(); break;
    case 1: s = v->filename(); break;
    default: s = v->title(); break;
  }
  return reinterpret_cast<intptr_t>(s);
}

int32_t ofl_help_find(intptr_t h, const char *s, int32_t from) {
  return view(h)->find(s, from);
}

// The view's numbers, by what: 0 top line, 1 left line, 2 the document's
// height, 3 text color, 4 text font, 5 text size, 6 scrollbar size, 7
// whether text is selected.
int32_t ofl_help_get(intptr_t h, int32_t what) {
  View *v = view(h);
  switch (what) {
    case 0: return v->topline();
    case 1: return v->leftline();
    case 2: return v->size();
    case 3: return static_cast<int32_t>(v->textcolor());
    case 4: return v->textfont();
    case 5: return v->textsize();
    case 6: return v->scrollbar_size();
    default: return v->text_selected();
  }
}

// By what, as ofl_help_get. Font and size lay out the page again.
void ofl_help_set(intptr_t h, int32_t what, int32_t n) {
  View *v = view(h);
  switch (what) {
    case 0: v->topline(n); break;
    case 1: v->leftline(n); break;
    case 3: v->textcolor(static_cast<Fl_Color>(n)); break;
    case 4:
      ++v->changes;
      v->textfont(n);
      break;
    case 5:
      ++v->changes;
      v->textsize(n);
      break;
    default: v->scrollbar_size(n); break;
  }
}

void ofl_help_top_name(intptr_t h, const char *name) { view(h)->topline(name); }
void ofl_help_clear_selection(intptr_t h) { view(h)->clear_selection(); }
void ofl_help_select_all(intptr_t h) { view(h)->select_all(); }

void ofl_help_copy(intptr_t h, int32_t clipboard) {
  fl_open_display();  // as Fl.cpp's ofl_copy (doc/fltk-issues.md, 49)
  view(h)->copy(clipboard);
}

// Help dialogs

// FLTK's constructor leaves no current group: it must leave the program's.
intptr_t ofl_help_dialog_new(void) {
  Fl_Group *current = Fl_Group::current();
  Fl_Help_Dialog *d = new Fl_Help_Dialog;
  Fl_Group::current(current);
  return reinterpret_cast<intptr_t>(d);
}

void ofl_help_dialog_delete(intptr_t d) {
  dialog(d)->hide();
  delete dialog(d);
}

void ofl_help_dialog_show(intptr_t d) { dialog(d)->show(); }
void ofl_help_dialog_hide(intptr_t d) { dialog(d)->hide(); }

// 1 if f was read.
int32_t ofl_help_dialog_load(intptr_t d, const char *f) {
  return dialog(d)->load(f) == 0;
}

void ofl_help_dialog_set_value(intptr_t d, const char *s) {
  dialog(d)->value(s);
}

intptr_t ofl_help_dialog_value(intptr_t d) {
  return reinterpret_cast<intptr_t>(dialog(d)->value());
}

// The dialog's numbers, by what: 0 visible, 1 text size, 2 x, 3 y, 4 w,
// 5 h.
int32_t ofl_help_dialog_get(intptr_t h, int32_t what) {
  Fl_Help_Dialog *d = dialog(h);
  switch (what) {
    case 0: return d->visible();
    case 1: return d->textsize();
    case 2: return d->x();
    case 3: return d->y();
    case 4: return d->w();
    default: return d->h();
  }
}

void ofl_help_dialog_set_size(intptr_t d, int32_t s) {
  dialog(d)->textsize(static_cast<Fl_Fontsize>(s));
}

void ofl_help_dialog_top(intptr_t d, int32_t n) { dialog(d)->topline(n); }

void ofl_help_dialog_top_name(intptr_t d, const char *name) {
  dialog(d)->topline(name);
}

void ofl_help_dialog_position(intptr_t d, int32_t x, int32_t y) {
  dialog(d)->position(x, y);
}

void ofl_help_dialog_resize(intptr_t d, int32_t x, int32_t y, int32_t w,
                            int32_t h) {
  dialog(d)->resize(x, y, w, h);
}

}  // extern "C"
