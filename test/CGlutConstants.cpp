// Written by tools/gen-constants.py: FLTK's values of the constants
// TestGlutConstants checks them against. Edit the script, not this file.

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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunknown-warning-option"
#pragma clang diagnostic ignored "-Wcast-function-type-mismatch"
#include <FL/glut.H>
#pragma clang diagnostic pop
#include <string.h>

namespace {

struct Entry {
  const char *name;
  int32_t value;
};

const Entry entries[] = {
  {"GLUT_RGB", (int32_t)(GLUT_RGB)},
  {"GLUT_RGBA", (int32_t)(GLUT_RGBA)},
  {"GLUT_INDEX", (int32_t)(GLUT_INDEX)},
  {"GLUT_SINGLE", (int32_t)(GLUT_SINGLE)},
  {"GLUT_DOUBLE", (int32_t)(GLUT_DOUBLE)},
  {"GLUT_ACCUM", (int32_t)(GLUT_ACCUM)},
  {"GLUT_ALPHA", (int32_t)(GLUT_ALPHA)},
  {"GLUT_DEPTH", (int32_t)(GLUT_DEPTH)},
  {"GLUT_STENCIL", (int32_t)(GLUT_STENCIL)},
  {"GLUT_MULTISAMPLE", (int32_t)(GLUT_MULTISAMPLE)},
  {"GLUT_STEREO", (int32_t)(GLUT_STEREO)},
  {"GLUT_LEFT_BUTTON", (int32_t)(GLUT_LEFT_BUTTON)},
  {"GLUT_MIDDLE_BUTTON", (int32_t)(GLUT_MIDDLE_BUTTON)},
  {"GLUT_RIGHT_BUTTON", (int32_t)(GLUT_RIGHT_BUTTON)},
  {"GLUT_DOWN", (int32_t)(GLUT_DOWN)},
  {"GLUT_UP", (int32_t)(GLUT_UP)},
  {"GLUT_LEFT", (int32_t)(GLUT_LEFT)},
  {"GLUT_ENTERED", (int32_t)(GLUT_ENTERED)},
  {"GLUT_NOT_VISIBLE", (int32_t)(GLUT_NOT_VISIBLE)},
  {"GLUT_VISIBLE", (int32_t)(GLUT_VISIBLE)},
  {"GLUT_MENU_NOT_IN_USE", (int32_t)(GLUT_MENU_NOT_IN_USE)},
  {"GLUT_MENU_IN_USE", (int32_t)(GLUT_MENU_IN_USE)},
  {"GLUT_NORMAL", (int32_t)(GLUT_NORMAL)},
  {"GLUT_OVERLAY", (int32_t)(GLUT_OVERLAY)},
  {"GLUT_KEY_F1", (int32_t)(GLUT_KEY_F1)},
  {"GLUT_KEY_F2", (int32_t)(GLUT_KEY_F2)},
  {"GLUT_KEY_F3", (int32_t)(GLUT_KEY_F3)},
  {"GLUT_KEY_F4", (int32_t)(GLUT_KEY_F4)},
  {"GLUT_KEY_F5", (int32_t)(GLUT_KEY_F5)},
  {"GLUT_KEY_F6", (int32_t)(GLUT_KEY_F6)},
  {"GLUT_KEY_F7", (int32_t)(GLUT_KEY_F7)},
  {"GLUT_KEY_F8", (int32_t)(GLUT_KEY_F8)},
  {"GLUT_KEY_F9", (int32_t)(GLUT_KEY_F9)},
  {"GLUT_KEY_F10", (int32_t)(GLUT_KEY_F10)},
  {"GLUT_KEY_F11", (int32_t)(GLUT_KEY_F11)},
  {"GLUT_KEY_F12", (int32_t)(GLUT_KEY_F12)},
  {"GLUT_KEY_LEFT", (int32_t)(GLUT_KEY_LEFT)},
  {"GLUT_KEY_UP", (int32_t)(GLUT_KEY_UP)},
  {"GLUT_KEY_RIGHT", (int32_t)(GLUT_KEY_RIGHT)},
  {"GLUT_KEY_DOWN", (int32_t)(GLUT_KEY_DOWN)},
  {"GLUT_KEY_HOME", (int32_t)(GLUT_KEY_HOME)},
  {"GLUT_KEY_END", (int32_t)(GLUT_KEY_END)},
  {"GLUT_KEY_INSERT", (int32_t)(GLUT_KEY_INSERT)},
  {"GLUT_KEY_PAGE_UP", (int32_t)(GLUT_KEY_PAGE_UP)},
  {"GLUT_KEY_PAGE_DOWN", (int32_t)(GLUT_KEY_PAGE_DOWN)},
  {"GLUT_CURSOR_RIGHT_ARROW", (int32_t)(GLUT_CURSOR_RIGHT_ARROW)},
  {"GLUT_CURSOR_LEFT_ARROW", (int32_t)(GLUT_CURSOR_LEFT_ARROW)},
  {"GLUT_CURSOR_INFO", (int32_t)(GLUT_CURSOR_INFO)},
  {"GLUT_CURSOR_DESTROY", (int32_t)(GLUT_CURSOR_DESTROY)},
  {"GLUT_CURSOR_HELP", (int32_t)(GLUT_CURSOR_HELP)},
  {"GLUT_CURSOR_CYCLE", (int32_t)(GLUT_CURSOR_CYCLE)},
  {"GLUT_CURSOR_SPRAY", (int32_t)(GLUT_CURSOR_SPRAY)},
  {"GLUT_CURSOR_WAIT", (int32_t)(GLUT_CURSOR_WAIT)},
  {"GLUT_CURSOR_TEXT", (int32_t)(GLUT_CURSOR_TEXT)},
  {"GLUT_CURSOR_CROSSHAIR", (int32_t)(GLUT_CURSOR_CROSSHAIR)},
  {"GLUT_CURSOR_UP_DOWN", (int32_t)(GLUT_CURSOR_UP_DOWN)},
  {"GLUT_CURSOR_LEFT_RIGHT", (int32_t)(GLUT_CURSOR_LEFT_RIGHT)},
  {"GLUT_CURSOR_TOP_SIDE", (int32_t)(GLUT_CURSOR_TOP_SIDE)},
  {"GLUT_CURSOR_BOTTOM_SIDE", (int32_t)(GLUT_CURSOR_BOTTOM_SIDE)},
  {"GLUT_CURSOR_LEFT_SIDE", (int32_t)(GLUT_CURSOR_LEFT_SIDE)},
  {"GLUT_CURSOR_RIGHT_SIDE", (int32_t)(GLUT_CURSOR_RIGHT_SIDE)},
  {"GLUT_CURSOR_TOP_LEFT_CORNER", (int32_t)(GLUT_CURSOR_TOP_LEFT_CORNER)},
  {"GLUT_CURSOR_TOP_RIGHT_CORNER", (int32_t)(GLUT_CURSOR_TOP_RIGHT_CORNER)},
  {"GLUT_CURSOR_BOTTOM_RIGHT_CORNER", (int32_t)(GLUT_CURSOR_BOTTOM_RIGHT_CORNER)},
  {"GLUT_CURSOR_BOTTOM_LEFT_CORNER", (int32_t)(GLUT_CURSOR_BOTTOM_LEFT_CORNER)},
  {"GLUT_CURSOR_INHERIT", (int32_t)(GLUT_CURSOR_INHERIT)},
  {"GLUT_CURSOR_NONE", (int32_t)(GLUT_CURSOR_NONE)},
  {"GLUT_CURSOR_FULL_CROSSHAIR", (int32_t)(GLUT_CURSOR_FULL_CROSSHAIR)},
  {"GLUT_WINDOW_X", (int32_t)(GLUT_WINDOW_X)},
  {"GLUT_WINDOW_Y", (int32_t)(GLUT_WINDOW_Y)},
  {"GLUT_WINDOW_WIDTH", (int32_t)(GLUT_WINDOW_WIDTH)},
  {"GLUT_WINDOW_HEIGHT", (int32_t)(GLUT_WINDOW_HEIGHT)},
  {"GLUT_WINDOW_PARENT", (int32_t)(GLUT_WINDOW_PARENT)},
  {"GLUT_SCREEN_WIDTH", (int32_t)(GLUT_SCREEN_WIDTH)},
  {"GLUT_SCREEN_HEIGHT", (int32_t)(GLUT_SCREEN_HEIGHT)},
  {"GLUT_MENU_NUM_ITEMS", (int32_t)(GLUT_MENU_NUM_ITEMS)},
  {"GLUT_DISPLAY_MODE_POSSIBLE", (int32_t)(GLUT_DISPLAY_MODE_POSSIBLE)},
  {"GLUT_INIT_WINDOW_X", (int32_t)(GLUT_INIT_WINDOW_X)},
  {"GLUT_INIT_WINDOW_Y", (int32_t)(GLUT_INIT_WINDOW_Y)},
  {"GLUT_INIT_WINDOW_WIDTH", (int32_t)(GLUT_INIT_WINDOW_WIDTH)},
  {"GLUT_INIT_WINDOW_HEIGHT", (int32_t)(GLUT_INIT_WINDOW_HEIGHT)},
  {"GLUT_INIT_DISPLAY_MODE", (int32_t)(GLUT_INIT_DISPLAY_MODE)},
  {"GLUT_WINDOW_BUFFER_SIZE", (int32_t)(GLUT_WINDOW_BUFFER_SIZE)},
  {"GLUT_VERSION", (int32_t)(GLUT_VERSION)},
  {"GLUT_ELAPSED_TIME", (int32_t)(GLUT_ELAPSED_TIME)},
  {"GLUT_WINDOW_STENCIL_SIZE", (int32_t)(GLUT_WINDOW_STENCIL_SIZE)},
  {"GLUT_WINDOW_DEPTH_SIZE", (int32_t)(GLUT_WINDOW_DEPTH_SIZE)},
  {"GLUT_WINDOW_RED_SIZE", (int32_t)(GLUT_WINDOW_RED_SIZE)},
  {"GLUT_WINDOW_GREEN_SIZE", (int32_t)(GLUT_WINDOW_GREEN_SIZE)},
  {"GLUT_WINDOW_BLUE_SIZE", (int32_t)(GLUT_WINDOW_BLUE_SIZE)},
  {"GLUT_WINDOW_ALPHA_SIZE", (int32_t)(GLUT_WINDOW_ALPHA_SIZE)},
  {"GLUT_WINDOW_DOUBLEBUFFER", (int32_t)(GLUT_WINDOW_DOUBLEBUFFER)},
  {"GLUT_HAS_KEYBOARD", (int32_t)(GLUT_HAS_KEYBOARD)},
  {"GLUT_HAS_MOUSE", (int32_t)(GLUT_HAS_MOUSE)},
  {"GLUT_NUM_MOUSE_BUTTONS", (int32_t)(GLUT_NUM_MOUSE_BUTTONS)},
  {"GLUT_OVERLAY_POSSIBLE", (int32_t)(GLUT_OVERLAY_POSSIBLE)},
  {"GLUT_NORMAL_DAMAGED", (int32_t)(GLUT_NORMAL_DAMAGED)},
  {"GLUT_OVERLAY_DAMAGED", (int32_t)(GLUT_OVERLAY_DAMAGED)},
  {"GLUT_ACTIVE_SHIFT", (int32_t)(GLUT_ACTIVE_SHIFT)},
  {"GLUT_ACTIVE_CTRL", (int32_t)(GLUT_ACTIVE_CTRL)},
  {"GLUT_ACTIVE_ALT", (int32_t)(GLUT_ACTIVE_ALT)}
};

}  // namespace

extern "C" {

// The value of the C expression name, in *value; 0 if the table hasn't it.
int32_t ofltest_glutconstant(const char *name, int32_t *value) {
  for (const Entry &e : entries) {
    if (strcmp(e.name, name) == 0) {
      *value = e.value;
      return 1;
    }
  }
  return 0;
}

}  // extern "C"
