// Written by tools/gen-constants.py: FLTK's values of the constants
// TestCairoConstants checks them against. Edit the script, not this file.

#include <FL/Fl.H>
#include <FL/Enumerations.H>
#include <FL/fl_draw.H>
#include <FL/Fl_Button.H>
#include <FL/Fl_Chart.H>
#include <FL/Fl_Clock.H>
#include <FL/Fl_Counter.H>
#include <FL/Fl_Dial.H>
#include <FL/Fl_Input_.H>
#include <FL/Fl_Slider.H>
#include <FL/Fl_Valuator.H>
#include <FL/Fl_Flex.H>
#include <FL/Fl_Grid.H>
#include <FL/Fl_Pack.H>
#include <FL/Fl_Scroll.H>
#include <FL/Fl_Tabs.H>
#include <FL/Fl_Menu_Item.H>
#include <FL/Fl_Menu_Button.H>
#include <FL/Fl_Sys_Menu_Bar.H>
#include <FL/fl_ask.H>
#include <FL/Fl_Native_File_Chooser.H>
#include <FL/Fl_File_Chooser.H>
#include <FL/Fl_Text_Display.H>
#include <FL/Fl_Text_Editor.H>
#include <FL/Fl_File_Browser.H>
#include <FL/Fl_Tree.H>
#include <FL/Fl_Table_Row.H>
#include <FL/Fl_Anim_GIF_Image.H>
#include <FL/Fl_File_Icon.H>
#include <FL/Fl_Terminal.H>
#include <FL/Fl_Paged_Device.H>
#include <stdint.h>
#include <stdio.h>
#include <cairo.h>
#include <string.h>

namespace {

struct Entry {
  const char *name;
  int32_t value;
};

const Entry entries[] = {
  {"CAIRO_FONT_SLANT_NORMAL", (int32_t)(CAIRO_FONT_SLANT_NORMAL)},
  {"CAIRO_FONT_SLANT_ITALIC", (int32_t)(CAIRO_FONT_SLANT_ITALIC)},
  {"CAIRO_FONT_SLANT_OBLIQUE", (int32_t)(CAIRO_FONT_SLANT_OBLIQUE)},
  {"CAIRO_FONT_WEIGHT_NORMAL", (int32_t)(CAIRO_FONT_WEIGHT_NORMAL)},
  {"CAIRO_FONT_WEIGHT_BOLD", (int32_t)(CAIRO_FONT_WEIGHT_BOLD)},
  {"CAIRO_ANTIALIAS_DEFAULT", (int32_t)(CAIRO_ANTIALIAS_DEFAULT)},
  {"CAIRO_ANTIALIAS_NONE", (int32_t)(CAIRO_ANTIALIAS_NONE)},
  {"CAIRO_ANTIALIAS_GRAY", (int32_t)(CAIRO_ANTIALIAS_GRAY)},
  {"CAIRO_ANTIALIAS_SUBPIXEL", (int32_t)(CAIRO_ANTIALIAS_SUBPIXEL)},
  {"CAIRO_ANTIALIAS_FAST", (int32_t)(CAIRO_ANTIALIAS_FAST)},
  {"CAIRO_ANTIALIAS_GOOD", (int32_t)(CAIRO_ANTIALIAS_GOOD)},
  {"CAIRO_ANTIALIAS_BEST", (int32_t)(CAIRO_ANTIALIAS_BEST)},
  {"CAIRO_EXTEND_NONE", (int32_t)(CAIRO_EXTEND_NONE)},
  {"CAIRO_EXTEND_REPEAT", (int32_t)(CAIRO_EXTEND_REPEAT)},
  {"CAIRO_EXTEND_REFLECT", (int32_t)(CAIRO_EXTEND_REFLECT)},
  {"CAIRO_EXTEND_PAD", (int32_t)(CAIRO_EXTEND_PAD)}
};

}  // namespace

extern "C" {

// The value of the C expression name, in *value; 0 if the table hasn't it.
int32_t ofltest_cairoconstant(const char *name, int32_t *value) {
  for (const Entry &e : entries) {
    if (strcmp(e.name, name) == 0) {
      *value = e.value;
      return 1;
    }
  }
  return 0;
}

}  // extern "C"
