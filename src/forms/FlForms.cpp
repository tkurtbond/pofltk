// The C++ part of FlForms: the classes of FLTK's Forms compatibility
// library, libfltk_forms. See pofltk.h for the conventions. A library of
// its own (pofltk-forms), so a program using only widgets isn't linked
// with it.

#include "../pofltk.h"

#include <FL/forms.H>

extern "C" {
// From FlImages.cpp: an image's FLTK object, and what holds it.
Fl_Image *ofl_image_fltk(intptr_t i);
ofl::Shared *ofl_image_shared(intptr_t i);
}

namespace {

typedef int32_t (*EventFn)(intptr_t self, int32_t event, int32_t x, int32_t y,
                           int32_t key);
EventFn on_event;

// FLTK's handler of every Free. It gets the key as a char, and for a
// mouse event 4 less the button, so Oberon is given FLTK's own values. The
// event FL_FREEMEM comes from ~Fl_Free, with the widget half gone, and
// has no use here. (doc/fltk-issues.md, 105)
int free_event(Fl_Widget *w, int event, float x, float y, char) {
  if (event == FL_FREEMEM || !w->user_data()) return 0;
  int key = Fl::event_key();
  if (event == FL_PUSH || event == FL_DRAG || event == FL_RELEASE) {
    key = Fl::event_button();
  } else if (event == FL_DRAW || event == FL_STEP) {
    key = 0;
  }
  ofl::Dispatch d;
  return on_event(ofl::self_of(w), event, static_cast<int32_t>(x),
                  static_cast<int32_t>(y), key);
}

class Free : public ofl::W<Fl_Free> {
public:
  Free(uchar type, int x, int y, int w, int h)
      : ofl::W<Fl_Free>(type, x, y, w, h, 0, free_event) {}
  // Fl_Free's timer sends event 0, for FL_STEP (doc/fltk-issues.md, 105).
  int handle(int event) FL_OVERRIDE {
    return ofl::W<Fl_Free>::handle(event ? event : FL_STEP);
  }
};

typedef ofl::W<Fl_Timer> Timer;
typedef ofl::W<Fl_FormsBitmap> Bitmap;
typedef ofl::W<Fl_FormsPixmap> Pixmap;
typedef ofl::W<Fl_FormsText> Text;

}  // namespace

extern "C" {

void ofl_forms_register(EventFn event) { on_event = event; }

// class: 0 Timer, 1 Free, 2 FormsBitmap, 3 FormsPixmap, 4 FormsText.
// type is a Timer's or a Free's. The others start with no box.
intptr_t ofl_forms_new(int32_t cls, int32_t type, int32_t x, int32_t y,
                       int32_t w, int32_t h, const char *label,
                       intptr_t self) {
  Fl_Widget *o;
  switch (cls) {
    case 0: o = new Timer(static_cast<uchar>(type), x, y, w, h, 0); break;
    case 1: o = new Free(static_cast<uchar>(type), x, y, w, h); break;
    case 2: o = new Bitmap(FL_NO_BOX, x, y, w, h); break;
    case 3: o = new Pixmap(FL_NO_BOX, x, y, w, h); break;
    default: o = new Text(FL_NO_BOX, x, y, w, h); break;
  }
  o->copy_label(ofl::label_text(label));
  return ofl::open(o, self);
}

double ofl_timer_value(intptr_t t) { return ofl::as<Fl_Timer>(t)->value(); }
void ofl_timer_set_value(intptr_t t, double v) {
  ofl::as<Fl_Timer>(t)->value(v);
}
// Direction 0 shows the time left, against FLTK's header
// (doc/fltk-issues.md, 107).
int32_t ofl_timer_up(intptr_t t) {
  return ofl::as<Fl_Timer>(t)->direction() != 0;
}
void ofl_timer_set_up(intptr_t t, int32_t on) {
  ofl::as<Fl_Timer>(t)->direction(on != 0);
}
int32_t ofl_timer_suspended(intptr_t t) {
  return ofl::as<Fl_Timer>(t)->suspended() != 0;
}
void ofl_timer_set_suspended(intptr_t t, int32_t on) {
  ofl::as<Fl_Timer>(t)->suspended(on != 0);
}

// Shows image i on a FormsBitmap (w a bitmap) or FormsPixmap, 0 none; 0
// if i isn't an image of that class. Not through set(), which keeps its
// data's pointer, and deletes what it replaces, a program's or not, and
// the widget has no destructor to delete what it made
// (doc/fltk-issues.md, 106): the widget's Ref holds the image.
int32_t ofl_forms_show(intptr_t wd, intptr_t i) {
  Fl_Widget *w = ofl::widget(wd);
  Fl_Image *m = i ? ofl_image_fltk(i) : 0;
  if (Fl_FormsBitmap *b = dynamic_cast<Fl_FormsBitmap *>(w)) {
    Fl_Bitmap *image = dynamic_cast<Fl_Bitmap *>(m);
    if (m && !image) return 0;
    b->bitmap(image);
  } else {
    Fl_Pixmap *image = dynamic_cast<Fl_Pixmap *>(m);
    if (m && !image) return 0;
    static_cast<Fl_FormsPixmap *>(w)->Pixmap(image);
  }
  ofl::ref_of(w)->hold(ofl::Ref::content, i ? ofl_image_shared(i) : 0);
  w->redraw();
  return 1;
}

}  // extern "C"
