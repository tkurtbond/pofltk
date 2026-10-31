// Written by tools/gen-constants.py: FLTK's values of the constants
// TestGlConstants checks them against. Edit the script, not this file.

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
#include <FL/gl.h>
#include <FL/Fl_Gl_Window.H>
#include <string.h>

namespace {

struct Entry {
  const char *name;
  int32_t value;
};

const Entry entries[] = {
  {"FL_RGB", (int32_t)(FL_RGB)},
  {"FL_INDEX", (int32_t)(FL_INDEX)},
  {"FL_SINGLE", (int32_t)(FL_SINGLE)},
  {"FL_DOUBLE", (int32_t)(FL_DOUBLE)},
  {"FL_ACCUM", (int32_t)(FL_ACCUM)},
  {"FL_ALPHA", (int32_t)(FL_ALPHA)},
  {"FL_DEPTH", (int32_t)(FL_DEPTH)},
  {"FL_STENCIL", (int32_t)(FL_STENCIL)},
  {"FL_RGB8", (int32_t)(FL_RGB8)},
  {"FL_MULTISAMPLE", (int32_t)(FL_MULTISAMPLE)},
  {"FL_STEREO", (int32_t)(FL_STEREO)},
  {"FL_FAKE_SINGLE", (int32_t)(FL_FAKE_SINGLE)},
  {"FL_OPENGL3", (int32_t)(FL_OPENGL3)},
  {"GL_COLOR_BUFFER_BIT", (int32_t)(GL_COLOR_BUFFER_BIT)},
  {"GL_DEPTH_BUFFER_BIT", (int32_t)(GL_DEPTH_BUFFER_BIT)},
  {"GL_STENCIL_BUFFER_BIT", (int32_t)(GL_STENCIL_BUFFER_BIT)},
  {"GL_POINTS", (int32_t)(GL_POINTS)},
  {"GL_LINES", (int32_t)(GL_LINES)},
  {"GL_LINE_LOOP", (int32_t)(GL_LINE_LOOP)},
  {"GL_LINE_STRIP", (int32_t)(GL_LINE_STRIP)},
  {"GL_TRIANGLES", (int32_t)(GL_TRIANGLES)},
  {"GL_TRIANGLE_STRIP", (int32_t)(GL_TRIANGLE_STRIP)},
  {"GL_TRIANGLE_FAN", (int32_t)(GL_TRIANGLE_FAN)},
  {"GL_QUADS", (int32_t)(GL_QUADS)},
  {"GL_QUAD_STRIP", (int32_t)(GL_QUAD_STRIP)},
  {"GL_POLYGON", (int32_t)(GL_POLYGON)},
  {"GL_DEPTH_TEST", (int32_t)(GL_DEPTH_TEST)},
  {"GL_BLEND", (int32_t)(GL_BLEND)},
  {"GL_CULL_FACE", (int32_t)(GL_CULL_FACE)},
  {"GL_SCISSOR_TEST", (int32_t)(GL_SCISSOR_TEST)},
  {"GL_LIGHTING", (int32_t)(GL_LIGHTING)},
  {"GL_FLAT", (int32_t)(GL_FLAT)},
  {"GL_SMOOTH", (int32_t)(GL_SMOOTH)},
  {"GL_ZERO", (int32_t)(GL_ZERO)},
  {"GL_ONE", (int32_t)(GL_ONE)},
  {"GL_SRC_ALPHA", (int32_t)(GL_SRC_ALPHA)},
  {"GL_ONE_MINUS_SRC_ALPHA", (int32_t)(GL_ONE_MINUS_SRC_ALPHA)},
  {"GL_NO_ERROR", (int32_t)(GL_NO_ERROR)}
};

}  // namespace

extern "C" {

// The value of the C expression name, in *value; 0 if the table hasn't it.
int32_t ofltest_glconstant(const char *name, int32_t *value) {
  for (const Entry &e : entries) {
    if (strcmp(e.name, name) == 0) {
      *value = e.value;
      return 1;
    }
  }
  return 0;
}

}  // extern "C"
