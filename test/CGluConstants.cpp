// Written by tools/gen-constants.py: FLTK's values of the constants
// TestGluConstants checks them against. Edit the script, not this file.

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
#include <FL/glu.h>
#include <string.h>

namespace {

struct Entry {
  const char *name;
  int32_t value;
};

const Entry entries[] = {
  {"GLU_FILL", (int32_t)(GLU_FILL)},
  {"GLU_LINE", (int32_t)(GLU_LINE)},
  {"GLU_SILHOUETTE", (int32_t)(GLU_SILHOUETTE)},
  {"GLU_POINT", (int32_t)(GLU_POINT)},
  {"GLU_NONE", (int32_t)(GLU_NONE)},
  {"GLU_FLAT", (int32_t)(GLU_FLAT)},
  {"GLU_SMOOTH", (int32_t)(GLU_SMOOTH)},
  {"GLU_OUTSIDE", (int32_t)(GLU_OUTSIDE)},
  {"GLU_INSIDE", (int32_t)(GLU_INSIDE)}
};

}  // namespace

extern "C" {

// The value of the C expression name, in *value; 0 if the table hasn't it.
int32_t ofltest_gluconstant(const char *name, int32_t *value) {
  for (const Entry &e : entries) {
    if (strcmp(e.name, name) == 0) {
      *value = e.value;
      return 1;
    }
  }
  return 0;
}

}  // extern "C"
