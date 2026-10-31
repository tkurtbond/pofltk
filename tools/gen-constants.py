#!/usr/bin/env python3
"""gen-constants.py: FLTK's constants for pofltk's modules, and the test of them.

Writes, from the SPEC below:
  - in each module's src/<Module>.Mod, the block between
    "(* BEGIN generated constants" and "(* END generated constants *)",
    each value taken from FLTK's headers by compiling and running a C++
    program, so it is right when written;
  - test/CConstants.cpp, a table of the same C expressions, and
    test/TestConstants.Mod, which checks each Oberon constant against it,
    so a later FLTK whose headers differ fails `make test`.

Run from the repository root after changing SPEC or upgrading FLTK:
  python3 tools/gen-constants.py
It needs clang++ and fltk-config. The Oberon names are PLAN.md's: events
take the prefix Ev, so FL_FOCUS can't clash with a procedure Focus, and
keys the prefix Key, so FL_End can't be the keyword END.
"""

import os, re, subprocess, sys, tempfile

# (Oberon name, C++ expression, kind, module): kind "int" is an INTEGER
# constant, "set" a SET constant (a bit-flag type, every bit below 32).
SPEC = []
MODULES = []  # in the order SPEC first names them
# The modules of the optional libraries (PLAN.md, Phase 20): the source of
# each, and the test that checks its constants, which pofltk's own mustn't
# import, since it would link the library. Each test has its own headers.
OPTIONAL = {"FlForms": ("src/forms/FlForms.Mod", "Forms", "#include <FL/forms.H>\n"),
            "FlGl": ("src/gl/FlGl.Mod", "Gl",
                     "#include <FL/gl.h>\n#include <FL/Fl_Gl_Window.H>\n"),
            "FlGlut": ("src/gl/FlGlut.Mod", "Glut",
                       "#pragma clang diagnostic push\n"
                       "#pragma clang diagnostic ignored \"-Wunknown-warning-option\"\n"
                       "#pragma clang diagnostic ignored \"-Wcast-function-type-mismatch\"\n"
                       "#include <FL/glut.H>\n"
                       "#pragma clang diagnostic pop\n")}
current = None

def module(name):
    global current
    current = name
    if name not in MODULES:
        MODULES.append(name)

def add(kind, pairs):
    for name, expr in pairs:
        SPEC.append((name, expr, kind, current))

def section(title):
    SPEC.append((title, None, "comment", current))

module("Fl")

section("events (Fl_Event), the argument of Handle")
add("int", [
    ("EvNone", "FL_NO_EVENT"), ("EvPush", "FL_PUSH"), ("EvRelease", "FL_RELEASE"),
    ("EvEnter", "FL_ENTER"), ("EvLeave", "FL_LEAVE"), ("EvDrag", "FL_DRAG"),
    ("EvFocus", "FL_FOCUS"), ("EvUnfocus", "FL_UNFOCUS"), ("EvKeyDown", "FL_KEYDOWN"),
    ("EvKeyUp", "FL_KEYUP"), ("EvClose", "FL_CLOSE"), ("EvMove", "FL_MOVE"),
    ("EvShortcut", "FL_SHORTCUT"), ("EvDeactivate", "FL_DEACTIVATE"),
    ("EvActivate", "FL_ACTIVATE"), ("EvHide", "FL_HIDE"), ("EvShow", "FL_SHOW"),
    ("EvPaste", "FL_PASTE"), ("EvSelectionClear", "FL_SELECTIONCLEAR"),
    ("EvMouseWheel", "FL_MOUSEWHEEL"), ("EvDndEnter", "FL_DND_ENTER"),
    ("EvDndDrag", "FL_DND_DRAG"), ("EvDndLeave", "FL_DND_LEAVE"),
    ("EvDndRelease", "FL_DND_RELEASE"),
    ("EvScreenConfigurationChanged", "FL_SCREEN_CONFIGURATION_CHANGED"),
    ("EvFullscreen", "FL_FULLSCREEN"), ("EvZoomGesture", "FL_ZOOM_GESTURE"),
    ("EvZoomEvent", "FL_ZOOM_EVENT"),
])

section("when a widget calls its Callback (Fl_When)")
add("set", [
    ("WhenNever", "FL_WHEN_NEVER"), ("WhenChanged", "FL_WHEN_CHANGED"),
    ("WhenNotChanged", "FL_WHEN_NOT_CHANGED"), ("WhenRelease", "FL_WHEN_RELEASE"),
    ("WhenReleaseAlways", "FL_WHEN_RELEASE_ALWAYS"), ("WhenEnterKey", "FL_WHEN_ENTER_KEY"),
    ("WhenEnterKeyAlways", "FL_WHEN_ENTER_KEY_ALWAYS"),
    ("WhenEnterKeyChanged", "FL_WHEN_ENTER_KEY_CHANGED"), ("WhenClosed", "FL_WHEN_CLOSED"),
])

section("box types (Fl_Boxtype); Fl.cpp defines every one at start-up")
BOXES = """NO_BOX FLAT_BOX UP_BOX DOWN_BOX UP_FRAME DOWN_FRAME THIN_UP_BOX
THIN_DOWN_BOX THIN_UP_FRAME THIN_DOWN_FRAME ENGRAVED_BOX EMBOSSED_BOX
ENGRAVED_FRAME EMBOSSED_FRAME BORDER_BOX SHADOW_BOX BORDER_FRAME SHADOW_FRAME
ROUNDED_BOX RSHADOW_BOX ROUNDED_FRAME RFLAT_BOX ROUND_UP_BOX ROUND_DOWN_BOX
DIAMOND_UP_BOX DIAMOND_DOWN_BOX OVAL_BOX OSHADOW_BOX OVAL_FRAME OFLAT_BOX
PLASTIC_UP_BOX PLASTIC_DOWN_BOX PLASTIC_UP_FRAME PLASTIC_DOWN_FRAME
PLASTIC_THIN_UP_BOX PLASTIC_THIN_DOWN_BOX PLASTIC_ROUND_UP_BOX
PLASTIC_ROUND_DOWN_BOX GTK_UP_BOX GTK_DOWN_BOX GTK_UP_FRAME GTK_DOWN_FRAME
GTK_THIN_UP_BOX GTK_THIN_DOWN_BOX GTK_THIN_UP_FRAME GTK_THIN_DOWN_FRAME
GTK_ROUND_UP_BOX GTK_ROUND_DOWN_BOX GLEAM_UP_BOX GLEAM_DOWN_BOX GLEAM_UP_FRAME
GLEAM_DOWN_FRAME GLEAM_THIN_UP_BOX GLEAM_THIN_DOWN_BOX GLEAM_ROUND_UP_BOX
GLEAM_ROUND_DOWN_BOX OXY_UP_BOX OXY_DOWN_BOX OXY_UP_FRAME OXY_DOWN_FRAME
OXY_THIN_UP_BOX OXY_THIN_DOWN_BOX OXY_THIN_UP_FRAME OXY_THIN_DOWN_FRAME
OXY_ROUND_UP_BOX OXY_ROUND_DOWN_BOX OXY_BUTTON_UP_BOX OXY_BUTTON_DOWN_BOX
FREE_BOXTYPE""".split()
WORDS = {"RSHADOW": "RShadow", "RFLAT": "RFlat", "OSHADOW": "OShadow",
         "OFLAT": "OFlat", "BOXTYPE": "Boxtype"}

def camel(c_name):
    return "".join(WORDS.get(w, w.capitalize()) for w in c_name.split("_"))

add("int", [(camel(b), "FL_" + b) for b in BOXES])

section("label types (Fl_Labeltype); multi, icon and image labels come with images")
add("int", [
    ("NormalLabel", "FL_NORMAL_LABEL"), ("NoLabel", "FL_NO_LABEL"),
    ("ShadowLabel", "FL_SHADOW_LABEL"), ("EngravedLabel", "FL_ENGRAVED_LABEL"),
    ("EmbossedLabel", "FL_EMBOSSED_LABEL"),
])

section("label alignment (Fl_Align)")
ALIGNS = """CENTER TOP BOTTOM LEFT RIGHT INSIDE TEXT_OVER_IMAGE IMAGE_OVER_TEXT
CLIP WRAP IMAGE_NEXT_TO_TEXT TEXT_NEXT_TO_IMAGE IMAGE_BACKDROP TOP_LEFT
TOP_RIGHT BOTTOM_LEFT BOTTOM_RIGHT LEFT_TOP RIGHT_TOP LEFT_BOTTOM
RIGHT_BOTTOM NOWRAP POSITION_MASK IMAGE_MASK""".split()
WORDS["NOWRAP"] = "NoWrap"
add("set", [("Align" + camel(a), "FL_ALIGN_" + a) for a in ALIGNS])

section("fonts (Fl_Font); add Bold, Italic or BoldItalic to Helvetica, Courier or Times")
FONTS = """HELVETICA HELVETICA_BOLD HELVETICA_ITALIC HELVETICA_BOLD_ITALIC COURIER
COURIER_BOLD COURIER_ITALIC COURIER_BOLD_ITALIC TIMES TIMES_BOLD TIMES_ITALIC
TIMES_BOLD_ITALIC SYMBOL SCREEN SCREEN_BOLD ZAPF_DINGBATS FREE_FONT BOLD ITALIC
BOLD_ITALIC""".split()
add("int", [(camel(f), "FL_" + f) for f in FONTS])

section("colors (Fl_Color): an index into FLTK's colormap, or RGB(r, g, b)")
COLORS = """FOREGROUND_COLOR BACKGROUND2_COLOR INACTIVE_COLOR SELECTION_COLOR
GRAY0 DARK3 DARK2 DARK1 BACKGROUND_COLOR LIGHT1 LIGHT2 LIGHT3 GRAY BLACK RED
GREEN YELLOW BLUE MAGENTA CYAN DARK_RED DARK_GREEN DARK_YELLOW DARK_BLUE
DARK_MAGENTA DARK_CYAN WHITE FREE_COLOR NUM_FREE_COLOR NUM_GRAY NUM_RED
NUM_GREEN NUM_BLUE""".split()
add("int", [(camel(c), "FL_" + c) for c in COLORS])

section("keys (Fl::event_key): a character's code for most; KeyF + n is F<n>, KeyKP + c keypad c")
KEYS = """Button BackSpace Tab Iso_Key Enter Pause Scroll_Lock Escape Kana Eisu Yen
JIS_Underscore Home Left Up Right Down Page_Up Page_Down End Print Insert Menu
Help Num_Lock KP KP_Enter KP_Last F F_Last Shift_L Shift_R Control_L Control_R
Caps_Lock Meta_L Meta_R Alt_L Alt_R Delete Alt_Gr Volume_Down Volume_Mute
Volume_Up Media_Play Media_Stop Media_Prev Media_Next Home_Page Mail Search
Back Forward Stop Refresh Sleep Favorites""".split()
WORDS.update({"KP": "KP", "JIS": "JIS", "BACKSPACE": "BackSpace"})
add("int", [("Key" + camel(k.upper()), "FL_" + k) for k in KEYS])

section("mouse buttons (Fl::event_button)")
add("int", [(camel(b), "FL_" + b) for b in
            "LEFT_MOUSE MIDDLE_MOUSE RIGHT_MOUSE BACK_MOUSE FORWARD_MOUSE".split()])

section("the shift keys and mouse buttons held (Fl::event_state); Command is Ctrl, but Meta on macOS")
add("set", [(camel(b), "FL_" + b) for b in
            """SHIFT CAPS_LOCK CTRL ALT NUM_LOCK META SCROLL_LOCK BUTTON1 BUTTON2
            BUTTON3 BUTTON4 BUTTON5 BUTTONS COMMAND CONTROL""".split()])

section("what needs redrawing (Fl_Damage), Widget.Damage")
add("set", [("Damage" + camel(d), "FL_DAMAGE_" + d) for d in
            "CHILD EXPOSE SCROLL OVERLAY USER1 USER2 ALL".split()])

section("mouse cursors (Fl_Cursor), Window.SetCursor")
add("int", [("Cursor" + camel(c), "FL_CURSOR_" + c) for c in
            """DEFAULT ARROW CROSS WAIT INSERT HAND HELP MOVE NS WE NWSE NESW N NE
            E SE S SW W NW NONE""".split()])

section("FLTK's options (Fl::Fl_Option), Option and SetOption")
add("int", [("Option" + camel(o), "Fl::OPTION_" + o) for o in
            """ARROW_FOCUS VISIBLE_FOCUS DND_TEXT SHOW_TOOLTIPS FNFC_USES_GTK
            FNFC_USES_ZENITY FNFC_USES_KDIALOG PRINTER_USES_GTK SHOW_SCALING
            SIMPLE_ZOOM_SHORTCUT""".split()])

section("what a watched file descriptor waits for (FdWatch, WatchFd)")
add("set", [("FdRead", "FL_READ"), ("FdWrite", "FL_WRITE"), ("FdExcept", "FL_EXCEPT")])

module("FlDraw")
WORDS.update({"DASHDOT": "DashDot", "DASHDOTDOT": "DashDotDot"})
section("line styles (LineStyle): a dash pattern, plus a cap and a join")
add("int", [(camel(c), "FL_" + c) for c in
            """SOLID DASH DOT DASHDOT DASHDOTDOT CAP_FLAT CAP_ROUND CAP_SQUARE
            JOIN_MITER JOIN_ROUND JOIN_BEVEL""".split()])

module("FlButtons")
section("kinds of button (Button.SetKind); not ToggleButton and RadioButton, the types")
add("int", [("Normal", "FL_NORMAL_BUTTON"), ("Toggle", "FL_TOGGLE_BUTTON"),
            ("Radio", "FL_RADIO_BUTTON"), ("Hidden", "FL_HIDDEN_BUTTON")])

module("FlValuators")
section("kinds of valuator (Valuator.SetKind): of a roller, scrollbar or other valuator")
add("int", [("Vertical", "FL_VERTICAL"), ("Horizontal", "FL_HORIZONTAL")])
section("of a slider or value slider")
add("int", [(camel(k), "FL_" + k) for k in
            """VERT_SLIDER HOR_SLIDER VERT_FILL_SLIDER HOR_FILL_SLIDER
            VERT_NICE_SLIDER HOR_NICE_SLIDER""".split()])
section("of a clock (ClockOutput.SetKind)")
add("int", [("SquareClock", "FL_SQUARE_CLOCK"), ("RoundClock", "FL_ROUND_CLOCK")])
section("of a dial")
add("int", [(camel(k), "FL_" + k) for k in "NORMAL_DIAL LINE_DIAL FILL_DIAL".split()])
section("of a counter")
add("int", [(camel(k), "FL_" + k) for k in "NORMAL_COUNTER SIMPLE_COUNTER".split()])
section("of a spinner (Spinner.SetKind): whole numbers, or real ones")
add("int", [("IntSpinner", "FL_INT_INPUT"), ("FloatSpinner", "FL_FLOAT_INPUT")])
section("kinds of chart (Chart.SetKind); a special pie draws its first slice apart")
add("int", [("BarChart", "FL_BAR_CHART"), ("HorBarChart", "FL_HORBAR_CHART"),
            ("LineChart", "FL_LINE_CHART"), ("FillChart", "FL_FILL_CHART"),
            ("SpikeChart", "FL_SPIKE_CHART"), ("PieChart", "FL_PIE_CHART"),
            ("SpecialPieChart", "FL_SPECIALPIE_CHART")])

module("FlLayout")
section("kinds of flex (Flex.SetKind): one column, or one row")
add("int", [("Column", "Fl_Flex::COLUMN"), ("Row", "Fl_Flex::ROW")])
section("kinds of pack (Pack.SetKind)")
add("int", [("PackVertical", "Fl_Pack::VERTICAL"), ("PackHorizontal", "Fl_Pack::HORIZONTAL")])
section("kinds of scroll (Scroll.SetKind): which scrollbars, shown when needed or Always")
add("int", [("Scroll" + camel(k), "Fl_Scroll::" + k) for k in
            """HORIZONTAL VERTICAL BOTH ALWAYS_ON HORIZONTAL_ALWAYS VERTICAL_ALWAYS
            BOTH_ALWAYS""".split()])
section("a widget's place in its grid cell (Grid.Place)")
add("set", [("Grid" + camel(k), "FL_GRID_" + k) for k in
            """CENTER TOP BOTTOM LEFT RIGHT HORIZONTAL VERTICAL FILL PROPORTIONAL
            TOP_LEFT TOP_RIGHT BOTTOM_LEFT BOTTOM_RIGHT""".split()])
section("what tabs do when there are too many to fit (Tabs.HandleOverflow)")
add("int", [("Overflow" + camel(k), "Fl_Tabs::OVERFLOW_" + k) for k in
            "COMPRESS CLIP PULLDOWN DRAG".split()])

module("FlMenus")
section("a menu item's flags (Menu.Add, Menu.ItemFlags); not FL_SUBMENU_POINTER")
add("set", [("MenuInactive", "FL_MENU_INACTIVE"), ("MenuToggle", "FL_MENU_TOGGLE"),
            ("MenuValue", "FL_MENU_VALUE"), ("MenuRadio", "FL_MENU_RADIO"),
            ("MenuInvisible", "FL_MENU_INVISIBLE"), ("Submenu", "FL_SUBMENU"),
            ("MenuDivider", "FL_MENU_DIVIDER")])
section("macOS's Window menu (SetWindowMenuStyle)")
add("int", [("NoWindowMenu", "Fl_Sys_Menu_Bar::no_window_menu"),
            ("TabbingModeNone", "Fl_Sys_Menu_Bar::tabbing_mode_none"),
            ("TabbingModeAutomatic", "Fl_Sys_Menu_Bar::tabbing_mode_automatic"),
            ("TabbingModePreferred", "Fl_Sys_Menu_Bar::tabbing_mode_preferred")])
section("kinds of menu button (MenuButton.SetKind): the mouse buttons that pop it up")
add("int", [("Popup" + k, "Fl_Menu_Button::POPUP" + k) for k in
            "1 2 12 3 13 23 123".split()])

module("FlDialogs")
section("kinds of beep (Beep)")
add("int", [("Beep" + camel(k), "FL_BEEP_" + k) for k in
            "DEFAULT MESSAGE ERROR QUESTION PASSWORD NOTIFICATION".split()])
section("what a native file chooser asks for (OpenNativeFileChooser)")
add("int", [("Browse" + camel(k), "Fl_Native_File_Chooser::BROWSE_" + k) for k in
            """FILE DIRECTORY MULTI_FILE MULTI_DIRECTORY SAVE_FILE
            SAVE_DIRECTORY""".split()])
section("a native file chooser's options (NativeFileChooser.SetOptions)")
WORDS.update({"SAVEAS": "SaveAs"})
add("set", [(camel(k), "Fl_Native_File_Chooser::" + k) for k in
            "SAVEAS_CONFIRM NEW_FOLDER PREVIEW USE_FILTER_EXT".split()])
section("what a file chooser asks for (OpenFileChooser)")
add("set", [("Chooser" + camel(k), "Fl_File_Chooser::" + k) for k in
            "SINGLE MULTI CREATE DIRECTORY".split()])

module("FlText")
section("how a display wraps lines (TextDisplay.SetWrapMode)")
add("int", [("Wrap" + camel(k), "Fl_Text_Display::WRAP_" + k) for k in
            "NONE AT_COLUMN AT_PIXEL AT_BOUNDS".split()])
section("the cursor's look (TextDisplay.SetCursorStyle)")
add("int", [(camel(k) + "Cursor", "Fl_Text_Display::" + k + "_CURSOR") for k in
            "NORMAL CARET DIM BLOCK HEAVY SIMPLE".split()])
section("a style's attributes (TextDisplay.AddStyle): a line kind, plus a background")
add("int", [("Attr" + camel(k), "Fl_Text_Display::ATTR_" + k) for k in
            "BGCOLOR BGCOLOR_EXT UNDERLINE GRAMMAR SPELLING STRIKE_THROUGH".split()])
module("FlBrowsers")
section("which scrollbars a browser shows (BrowserBase.SetScrollbars)")
add("int", [("Scrollbar" + camel(k), "Fl_Browser_::" + k) for k in
            "HORIZONTAL VERTICAL BOTH ALWAYS_ON HORIZONTAL_ALWAYS VERTICAL_ALWAYS BOTH_ALWAYS".split()])
section("how BrowserBase.Sort sorts")
add("int", [("SortAscending", "FL_SORT_ASCENDING"), ("SortDescending", "FL_SORT_DESCENDING"),
            ("SortCaseInsensitive", "FL_SORT_CASEINSENSITIVE")])
section("what a file browser lists (FileBrowser.SetFileType)")
add("int", [("Files", "Fl_File_Browser::FILES"), ("Directories", "Fl_File_Browser::DIRECTORIES")])
section("how a tree's items are selected (Tree.SetSelectMode)")
add("int", [("TreeSelect" + camel(k), "FL_TREE_SELECT_" + k) for k in
            "NONE SINGLE MULTI SINGLE_DRAGGABLE".split()])
section("where a tree adds an item among its siblings (Tree.SetSortOrder)")
add("int", [("TreeSort" + camel(k), "FL_TREE_SORT_" + k) for k in
            "NONE ASCENDING DESCENDING".split()])
section("the lines between a tree's items (Tree.SetConnectorStyle)")
add("int", [("Connector" + camel(k), "FL_TREE_CONNECTOR_" + k) for k in
            "NONE DOTTED SOLID".split()])
section("whether clicking a selected item calls back (Tree.SetReselectMode)")
add("int", [("SelectableOnce", "FL_TREE_SELECTABLE_ONCE"),
            ("SelectableAlways", "FL_TREE_SELECTABLE_ALWAYS")])
section("why a tree called back (Tree.CallbackReason)")
add("int", [("Reason" + camel(k), "FL_TREE_REASON_" + k) for k in
            "NONE SELECTED DESELECTED RESELECTED OPENED CLOSED DRAGGED".split()])
section("how an item with a widget is drawn (Tree.SetItemDrawMode); {} draws the widget alone")
add("set", [("ItemDrawLabelAndWidget", "FL_TREE_ITEM_DRAW_LABEL_AND_WIDGET"),
            ("ItemHeightFromWidget", "FL_TREE_ITEM_HEIGHT_FROM_WIDGET")])

module("FlImages")
section("how an animation starts (OpenAnimGIF, AnimGIF.SetCanvas): DontStart, not playing; the canvas\n"
        "     not sized to it, or not showing it; OptimizeMemory, frames kept at their own sizes;\n"
        "     AnimLog and AnimDebug, FLTK's reports of the decoding, on standard output")
add("set", [("DontStart", "Fl_Anim_GIF_Image::DONT_START"),
            ("DontResizeCanvas", "Fl_Anim_GIF_Image::DONT_RESIZE_CANVAS"),
            ("DontSetAsImage", "Fl_Anim_GIF_Image::DONT_SET_AS_IMAGE"),
            ("OptimizeMemory", "Fl_Anim_GIF_Image::OPTIMIZE_MEMORY"),
            ("AnimLog", "Fl_Anim_GIF_Image::LOG_FLAG"),
            ("AnimDebug", "Fl_Anim_GIF_Image::DEBUG_FLAG")])
section("how RGB images are scaled as they are drawn (SetScalingAlgorithm)")
add("int", [("ScalingNearest", "FL_RGB_SCALING_NEAREST"), ("ScalingBilinear", "FL_RGB_SCALING_BILINEAR")])
section("what a file icon is for (OpenFileIcon, FindFileIcon); IconAny, anything")
add("int", [("Icon" + n, "Fl_File_Icon::" + k) for n, k in
            [("Any", "ANY"), ("Plain", "PLAIN"), ("Fifo", "FIFO"), ("Device", "DEVICE"),
             ("Link", "LINK"), ("Directory", "DIRECTORY")]])
section("what is drawn in a file icon (FileIcon.Add): a Line, ClosedLine or Polygon\n"
        "     is its vertices, then IconEnd; IconColor, as a color, is the color the\n"
        "     icon is drawn with")
add("int", [("IconEnd", "Fl_File_Icon::END"), ("IconLine", "Fl_File_Icon::LINE"),
            ("IconClosedLine", "Fl_File_Icon::CLOSEDLINE"),
            ("IconPolygon", "Fl_File_Icon::POLYGON"), ("IconColor", "(int)FL_ICON_COLOR")])

module("FlTable")
WORDS.update({"STARTPAGE": "StartPage", "ENDPAGE": "EndPage", "RC": "RC"})
section("what DrawCell draws, and where a Callback's event was (Table.CallbackContext)")
add("int", [("Context" + camel(k), "Fl_Table::CONTEXT_" + k) for k in
            "NONE STARTPAGE ENDPAGE ROW_HEADER COL_HEADER CELL TABLE RC_RESIZE".split()])
section("how a table row's rows are selected (TableRow.SetSelectMode)")
add("int", [("Select" + camel(k), "Fl_Table_Row::SELECT_" + k) for k in
            "NONE SINGLE MULTI".split()])

# Not constants of Fl, but values the test also checks against C: what Fl's
# procedures compute in Oberon.
CHECKS = [
    ("Fl.GrayRamp(0)", "fl_gray_ramp(0)"), ("Fl.GrayRamp(23)", "fl_gray_ramp(23)"),
    ("Fl.ColorCube(0, 0, 0)", "fl_color_cube(0, 0, 0)"),
    ("Fl.ColorCube(4, 7, 4)", "fl_color_cube(4, 7, 4)"),
    ("Fl.ColorCube(1, 2, 3)", "fl_color_cube(1, 2, 3)"),
    ("Fl.RGB(255, 0, 0)", "fl_rgb_color(255, 0, 0)"),
    ("Fl.RGB(1, 2, 3)", "fl_rgb_color(1, 2, 3)"),
    ("Fl.RGB(0, 0, 255)", "fl_rgb_color(0, 0, 255)"),
]

module("FlTerminal")
WORDS.update({"LF": "Lf", "CR": "Cr", "CRLF": "CrLf"})
section("what the text looks like (Terminal.SetTextAttrib)")
add("set", [(camel(k), "Fl_Terminal::" + k) for k in
            "NORMAL BOLD DIM ITALIC UNDERLINE INVERSE STRIKEOUT".split()])
section("what a carriage return and a line feed do (Terminal.SetOutputTranslate)")
add("set", [("Out" + camel(k), "Fl_Terminal::" + k) for k in
            "OFF CR_TO_LF LF_TO_CR LF_TO_CRLF".split()])
section("when text is drawn (Terminal.SetRedrawStyle)")
add("int", [("NoRedraw", "Fl_Terminal::NO_REDRAW"), ("RateLimited", "Fl_Terminal::RATE_LIMITED"),
            ("PerWrite", "Fl_Terminal::PER_WRITE")])
section("the horizontal scrollbar (Terminal.SetHScrollbarStyle)")
add("int", [("Scrollbar" + camel(k), "Fl_Terminal::SCROLLBAR_" + k) for k in
            "OFF AUTO ON".split()])

module("FlForms")
section("a Timer's kinds (OpenTimer)")
add("int", [("NormalTimer", "FL_NORMAL_TIMER"), ("ValueTimer", "FL_VALUE_TIMER"),
            ("HiddenTimer", "FL_HIDDEN_TIMER")])
section("a Free's kinds (OpenFree)")
add("int", [(camel(k) + "Free", "FL_%s_FREE" % k) for k in
            "NORMAL SLEEPING INPUT CONTINUOUS ALL".split()])
section("the events a Free gets beside FLTK's own (Free.HandleFree)")
add("int", [("FreeDraw", "FL_DRAW"), ("FreeStep", "FL_STEP")])

module("FlGl")
section("a GlWindow's modes (SetMode), added together")
add("int", [("Rgb", "FL_RGB"), ("Index", "FL_INDEX"), ("Single", "FL_SINGLE"),
            ("Double", "FL_DOUBLE"), ("Accum", "FL_ACCUM"), ("Alpha", "FL_ALPHA"),
            ("Depth", "FL_DEPTH"), ("Stencil", "FL_STENCIL"), ("Rgb8", "FL_RGB8"),
            ("Multisample", "FL_MULTISAMPLE"), ("Stereo", "FL_STEREO"),
            ("FakeSingle", "FL_FAKE_SINGLE"), ("OpenGL3", "FL_OPENGL3")])
section("what Clear clears, added together")
add("int", [("ColorBufferBit", "GL_COLOR_BUFFER_BIT"),
            ("DepthBufferBit", "GL_DEPTH_BUFFER_BIT"),
            ("StencilBufferBit", "GL_STENCIL_BUFFER_BIT")])
section("what Begin draws")
add("int", [("Points", "GL_POINTS"), ("Lines", "GL_LINES"), ("LineLoop", "GL_LINE_LOOP"),
            ("LineStrip", "GL_LINE_STRIP"), ("Triangles", "GL_TRIANGLES"),
            ("TriangleStrip", "GL_TRIANGLE_STRIP"), ("TriangleFan", "GL_TRIANGLE_FAN"),
            ("Quads", "GL_QUADS"), ("QuadStrip", "GL_QUAD_STRIP"), ("Polygon", "GL_POLYGON")])
section("what Enable and Disable take")
add("int", [("DepthTest", "GL_DEPTH_TEST"), ("Blend", "GL_BLEND"), ("CullFace", "GL_CULL_FACE"),
            ("ScissorTest", "GL_SCISSOR_TEST"), ("Lighting", "GL_LIGHTING")])
section("ShadeModel's modes")
add("int", [("Flat", "GL_FLAT"), ("Smooth", "GL_SMOOTH")])
section("BlendFunc's factors")
add("int", [("Zero", "GL_ZERO"), ("One", "GL_ONE"), ("SrcAlpha", "GL_SRC_ALPHA"),
            ("OneMinusSrcAlpha", "GL_ONE_MINUS_SRC_ALPHA")])
section("GetError's result when there is none")
add("int", [("NoError", "GL_NO_ERROR")])

module("FlGlut")
section("display modes (InitDisplayMode), added together")
add("int", [(camel(k), "GLUT_%s" % k) for k in
            "RGB RGBA INDEX SINGLE DOUBLE ACCUM ALPHA DEPTH STENCIL MULTISAMPLE STEREO".split()])
section("mouse buttons, attached menus (AttachMenu) and MouseProc's button")
add("int", [("LeftButton", "GLUT_LEFT_BUTTON"), ("MiddleButton", "GLUT_MIDDLE_BUTTON"),
            ("RightButton", "GLUT_RIGHT_BUTTON")])
section("MouseProc's state")
add("int", [("Down", "GLUT_DOWN"), ("Up", "GLUT_UP")])
section("EntryProc's state")
add("int", [("Left", "GLUT_LEFT"), ("Entered", "GLUT_ENTERED")])
section("VisibilityProc's state")
add("int", [("NotVisible", "GLUT_NOT_VISIBLE"), ("Visible", "GLUT_VISIBLE")])
section("MenuStateProc's state")
add("int", [("MenuNotInUse", "GLUT_MENU_NOT_IN_USE"), ("MenuInUse", "GLUT_MENU_IN_USE")])
section("layers (UseLayer)")
add("int", [("Normal", "GLUT_NORMAL"), ("Overlay", "GLUT_OVERLAY")])
section("SpecialProc's keys")
add("int", [("Key" + k, "GLUT_KEY_F%s" % k[1:]) for k in
            "F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11 F12".split()])
add("int", [("Key" + camel(k), "GLUT_KEY_%s" % k) for k in
            "LEFT UP RIGHT DOWN HOME END INSERT".split()])
add("int", [("KeyPageUp", "GLUT_KEY_PAGE_UP"), ("KeyPageDown", "GLUT_KEY_PAGE_DOWN")])
section("cursors (SetCursor)")
add("int", [("Cursor" + camel(k), "GLUT_CURSOR_%s" % k) for k in
            ("RIGHT_ARROW LEFT_ARROW INFO DESTROY HELP CYCLE SPRAY WAIT TEXT CROSSHAIR "
             "UP_DOWN LEFT_RIGHT TOP_SIDE BOTTOM_SIDE LEFT_SIDE RIGHT_SIDE TOP_LEFT_CORNER "
             "TOP_RIGHT_CORNER BOTTOM_RIGHT_CORNER BOTTOM_LEFT_CORNER INHERIT NONE "
             "FULL_CROSSHAIR").split()])
section("what Get gives")
add("int", [("Get" + camel(k), "GLUT_%s" % k) for k in
            ("WINDOW_X WINDOW_Y WINDOW_WIDTH WINDOW_HEIGHT WINDOW_PARENT SCREEN_WIDTH "
             "SCREEN_HEIGHT MENU_NUM_ITEMS DISPLAY_MODE_POSSIBLE INIT_WINDOW_X INIT_WINDOW_Y "
             "INIT_WINDOW_WIDTH INIT_WINDOW_HEIGHT INIT_DISPLAY_MODE WINDOW_BUFFER_SIZE "
             "VERSION ELAPSED_TIME WINDOW_STENCIL_SIZE WINDOW_DEPTH_SIZE WINDOW_RED_SIZE "
             "WINDOW_GREEN_SIZE WINDOW_BLUE_SIZE WINDOW_ALPHA_SIZE WINDOW_DOUBLEBUFFER").split()])
section("what DeviceGet gives")
add("int", [(camel(k), "GLUT_%s" % k) for k in
            "HAS_KEYBOARD HAS_MOUSE NUM_MOUSE_BUTTONS".split()])
section("what LayerGet gives")
add("int", [(camel(k), "GLUT_%s" % k) for k in
            "OVERLAY_POSSIBLE NORMAL_DAMAGED OVERLAY_DAMAGED".split()])
section("what GetModifiers gives, added together")
add("int", [("ActiveShift", "GLUT_ACTIVE_SHIFT"), ("ActiveCtrl", "GLUT_ACTIVE_CTRL"),
            ("ActiveAlt", "GLUT_ACTIVE_ALT")])

module("FlPrint")
section("the page: its format (Fl_Paged_Device::Page_Format)")
add("int", [(k, "Fl_Paged_Device::" + k) for k in
            "A0 A1 A2 A3 A4 A5 A6 A7 A8 A9 B0 B1 B2 B3 B4 B5 B6 B7 B8 B9 B10".split()])
add("int", [("C5E", "Fl_Paged_Device::C5E"), ("DLE", "Fl_Paged_Device::DLE")])
add("int", [(camel(k), "Fl_Paged_Device::" + k) for k in
            "EXECUTIVE FOLIO LEDGER LEGAL LETTER TABLOID ENVELOPE".split()])
add("int", [("PageFormats", "NO_PAGE_FORMATS")])
section("and its layout (Fl_Paged_Device::Page_Layout)")
add("int", [("Portrait", "Fl_Paged_Device::PORTRAIT"), ("Landscape", "Fl_Paged_Device::LANDSCAPE"),
            ("Reversed", "Fl_Paged_Device::REVERSED")])

HEADERS = ("#include <FL/Fl.H>\n#include <FL/Enumerations.H>\n#include <FL/fl_draw.H>\n"
           "#include <FL/Fl_Button.H>\n#include <FL/Fl_Chart.H>\n#include <FL/Fl_Clock.H>\n#include <FL/Fl_Counter.H>\n#include <FL/Fl_Dial.H>\n"
           "#include <FL/Fl_Input_.H>\n#include <FL/Fl_Slider.H>\n#include <FL/Fl_Valuator.H>\n"
           "#include <FL/Fl_Flex.H>\n#include <FL/Fl_Grid.H>\n#include <FL/Fl_Pack.H>\n"
           "#include <FL/Fl_Scroll.H>\n#include <FL/Fl_Tabs.H>\n"
           "#include <FL/Fl_Menu_Item.H>\n#include <FL/Fl_Menu_Button.H>\n#include <FL/Fl_Sys_Menu_Bar.H>\n#include <FL/fl_ask.H>\n"
           "#include <FL/Fl_Native_File_Chooser.H>\n#include <FL/Fl_File_Chooser.H>\n"
           "#include <FL/Fl_Text_Display.H>\n#include <FL/Fl_File_Browser.H>\n#include <FL/Fl_Tree.H>\n"
           "#include <FL/Fl_Table_Row.H>\n#include <FL/Fl_Anim_GIF_Image.H>\n#include <FL/Fl_File_Icon.H>\n#include <FL/Fl_Terminal.H>\n#include <FL/Fl_Paged_Device.H>\n"
           "#include <stdint.h>\n#include <stdio.h>\n")

def oberon_set(v):
    bits = [str(i) for i in range(32) if v >> i & 1]
    assert v >> 32 == 0, v
    return "{" + ", ".join(bits) + "}"

def values():
    """Each SPEC expression's value, from a C++ program compiled against
    the installed FLTK."""
    exprs = [e for _, e, k, _ in SPEC if k != "comment"]
    prog = HEADERS + "".join(o[2] for o in OPTIONAL.values()) + "int main() {\n" + "".join(
        '  printf("%%lld\\n", (long long)(int32_t)(%s));\n' % e for e in exprs) + "}\n"
    flags = subprocess.check_output(["fltk-config", "--cxxflags"], text=True).split()
    flags = [f for f in flags if f.startswith(("-I", "-D")) and f != "-I/usr/include"]
    libs = subprocess.check_output(["fltk-config", "--ldflags"], text=True).split()
    with tempfile.TemporaryDirectory() as d:
        src, exe = os.path.join(d, "v.cpp"), os.path.join(d, "v")
        open(src, "w").write(prog)
        subprocess.check_call(["clang++", "-std=c++11", *flags, src, "-o", exe, *libs])
        out = subprocess.check_output([exe], text=True).split()
    return dict(zip(exprs, (int(v) for v in out)))

def oberon_block(vals, mod):
    lines = ["(* BEGIN generated constants: tools/gen-constants.py writes this block,",
             "   from FLTK's headers; edit the script, not the block. *)"]
    for name, expr, kind, m in SPEC:
        if m != mod:
            continue
        if kind == "comment":
            lines += ["", "  (* %s *)" % name]
            continue
        v = vals[expr]
        text = oberon_set(v & 0xFFFFFFFF) if kind == "set" else str(v)
        lines.append("  %s* = %s;" % (name, text))
    lines.append("(* END generated constants *)")
    return "\n".join(lines)

def write_modules(vals):
    pat = re.compile(r"\(\* BEGIN generated constants.*?\(\* END generated constants \*\)", re.S)
    for mod in MODULES:
        path = OPTIONAL[mod][0] if mod in OPTIONAL else "src/%s.Mod" % mod
        s = open(path).read()
        if not pat.search(s):
            sys.exit("gen-constants.py: no generated-constants block in " + path)
        s = pat.sub(lambda m: oberon_block(vals, mod), s)
        open(path, "w").write(s)

def write_test(mods, tag, headers, checked):
    """TestConstants and CConstants for mods, with tag in their names.
    A library's symbol has the tag too, though no program has both."""
    entries = [(n, e, k, m) for n, e, k, m in SPEC if k != "comment" and m in mods]
    table = ",\n".join('  {"%s", (int32_t)(%s)}' % (c, c)
                       for c in [e for _, e, _, _ in entries] + [c for _, c in checked])
    test, cmod, symbol = "Test%sConstants" % tag, "C%sConstants" % tag, "ofltest_%sconstant" % tag.lower()
    open("test/%s.cpp" % cmod, "w").write(
        "// Written by tools/gen-constants.py: FLTK's values of the constants\n"
        "// %s checks them against. Edit the script, not this file.\n\n" % test
        + headers + "#include <string.h>\n\nnamespace {\n\nstruct Entry {\n"
        "  const char *name;\n  int32_t value;\n};\n\nconst Entry entries[] = {\n"
        + table + "\n};\n\n}  // namespace\n\nextern \"C\" {\n\n"
        "// The value of the C expression name, in *value; 0 if the table hasn't it.\n"
        "int32_t %s(const char *name, int32_t *value) {\n" % symbol +
        "  for (const Entry &e : entries) {\n"
        "    if (strcmp(e.name, name) == 0) {\n"
        "      *value = e.value;\n      return 1;\n    }\n  }\n  return 0;\n}\n\n"
        "}  // extern \"C\"\n")
    open("test/%s.Mod" % cmod, "w").write(
        "MODULE %s; (* FLTK's values of C expressions, for %s *)\n\n" % (cmod, test) +
        "(* Written by tools/gen-constants.py; its C++ part is %s.cpp. *)\n\n" % cmod +
        "IMPORT SYSTEM;\n\n"
        'PROCEDURE ["C", "%s"] CConstant(name: ARRAY OF CHAR; VAR value: SYSTEM.INT32): SYSTEM.INT32;\n\n' % symbol +
        "(* The value of the C expression name, in value; FALSE if there is none. *)\n"
        "PROCEDURE Value*(name-: ARRAY OF CHAR; VAR value: INTEGER): BOOLEAN;\n"
        "  VAR v: SYSTEM.INT32;\n"
        "BEGIN\n  v := 0;\n  IF CConstant(name, v) # 0 THEN value := v; RETURN TRUE END;\n"
        "  RETURN FALSE\nEND Value;\n\nEND %s.\n" % cmod)
    checks = []
    for name, expr, kind, mod in entries:
        # A SET's bits by ORD, which needs poc 0.4.1 under -OC.
        q = "%s.%s" % (mod, name)
        o = "ORD(%s)" % q if kind == "set" else q
        checks.append('  Same(%s, "%s");' % (o, expr))
    for o, c in checked:
        checks.append('  Same(%s, "%s");' % (o, c))
    open("test/%s.Mod" % test, "w").write(
        "MODULE %s; (* pofltk's constants are FLTK's *)\n\n" % test +
        "(* Written by tools/gen-constants.py: one check per constant, against the\n"
        "   value the installed FLTK's headers give (%s). A failure means\n" % cmod +
        "   FLTK's headers changed: run the script again, and see what moved. *)\n\n"
        "IMPORT SYSTEM, Out, " + ", ".join(mods) + ", Check, %s;\n\n" % cmod +
        "VAR checked, wrong: INTEGER;\n\n"
        "PROCEDURE Same(oberon: INTEGER; c-: ARRAY OF CHAR);\n"
        "  VAR v: INTEGER;\nBEGIN\n  INC(checked);\n"
        "  IF ~%s.Value(c, v) OR (v # oberon) THEN\n" % cmod +
        '    INC(wrong); Out.String("  differs from C: "); Out.String(c); Out.Ln\n'
        "  END\nEND Same;\n\nBEGIN\n  checked := 0; wrong := 0;\n"
        + "\n".join(checks) + "\n"
        '  Check.Check((wrong = 0) & (checked = %d), "each of %d constants and values is FLTK\'s");\n'
        % (len(checks), len(checks))
        + "  Check.Summary\nEND %s.\n" % test)

def main():
    vals = values()
    write_modules(vals)
    write_test([m for m in MODULES if m not in OPTIONAL], "", HEADERS, CHECKS)
    for mod, (_, tag, headers) in OPTIONAL.items():
        write_test([mod], tag, HEADERS + headers, [])
    print("gen-constants.py: %d constants, %d other values" %
          (sum(1 for s in SPEC if s[2] != "comment"), len(CHECKS)))

main()
