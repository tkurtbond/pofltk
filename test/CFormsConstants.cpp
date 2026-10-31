// Written by tools/gen-constants.py: FLTK's values of the constants
// TestFormsConstants checks them against. Edit the script, not this file.

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
#include <FL/Fl_File_Browser.H>
#include <FL/Fl_Tree.H>
#include <FL/Fl_Table_Row.H>
#include <FL/Fl_Anim_GIF_Image.H>
#include <FL/Fl_File_Icon.H>
#include <FL/Fl_Terminal.H>
#include <FL/Fl_Paged_Device.H>
#include <stdint.h>
#include <stdio.h>
#include <FL/forms.H>
#include <string.h>

namespace {

struct Entry {
  const char *name;
  int32_t value;
};

const Entry entries[] = {
  {"FL_NORMAL_TIMER", (int32_t)(FL_NORMAL_TIMER)},
  {"FL_VALUE_TIMER", (int32_t)(FL_VALUE_TIMER)},
  {"FL_HIDDEN_TIMER", (int32_t)(FL_HIDDEN_TIMER)},
  {"FL_NORMAL_FREE", (int32_t)(FL_NORMAL_FREE)},
  {"FL_SLEEPING_FREE", (int32_t)(FL_SLEEPING_FREE)},
  {"FL_INPUT_FREE", (int32_t)(FL_INPUT_FREE)},
  {"FL_CONTINUOUS_FREE", (int32_t)(FL_CONTINUOUS_FREE)},
  {"FL_ALL_FREE", (int32_t)(FL_ALL_FREE)},
  {"FL_DRAW", (int32_t)(FL_DRAW)},
  {"FL_STEP", (int32_t)(FL_STEP)}
};

}  // namespace

extern "C" {

// The value of the C expression name, in *value; 0 if the table hasn't it.
int32_t ofltest_formsconstant(const char *name, int32_t *value) {
  for (const Entry &e : entries) {
    if (strcmp(e.name, name) == 0) {
      *value = e.value;
      return 1;
    }
  }
  return 0;
}

}  // extern "C"
