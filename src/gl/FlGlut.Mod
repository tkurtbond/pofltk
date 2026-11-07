MODULE FlGlut; (* FLTK's GLUT emulation: windows, menus and callbacks in GLUT's style, FL/glut.H *)

(* GLUT's way of writing a GL program: calls that act on a current window
   and a current menu, each known by a number, and a procedure for each
   event, set for the current window. FLTK emulates it, and adds Window,
   so that a GLUT window can be a child of FLTK's own widgets.

   FLTK's GLUT takes numbers and strings on trust: a window or menu that
   isn't there crashes it, and it keeps every string. So here every string
   is copied, and a number that isn't a window's or a menu's halts, with
   Fl.IndexOutOfRange. DestroyWindow takes the window's number away at
   once and does its work when the program next waits, as in GLUT, and
   so does HideWindow in a display procedure, so a window's own can call
   them.

   As in GLUT, the procedures set by DisplayFunc and the rest belong to
   the current window. Any event a window hears makes it current, and
   leaves it so, even with none of its procedures set: call SetWindow
   after waiting, before anything of a particular window.

   FLTK has 31 windows and 31 menus, and CreateWindow and CreateMenu halt
   with Fl.Unsupported past them.

   A menu that is another's submenu is held by a pointer to its items, so
   it can't change size or go, and those halt with Fl.OutOfOrder: fill a
   submenu before adding it.

   MainLoop returns when the last window closes, unlike GLUT's, since it
   is FLTK's Run.

   GLUT's fonts are numbers here, not addresses. A bitmap font is one of
   FLTK's, drawn at GL's raster position, which FlGl.DrawTextAt with "" sets;
   a stroke font is lines, drawn at the origin, a capital 100 units tall,
   so scale it. Only the stroke fonts' measures work outside a drawing.

   GLUT's shapes (glutSolidCube and the rest) and glutGetProcAddress aren't
   bound, as FlGl binds only a part of GL: draw with FlGl, or from a C++ part.

   The C++ part is FlGlut.cpp. *)

IMPORT SYSTEM, Args, Fl, FlGl;

CONST
(* BEGIN generated constants: tools/gen-constants.py writes this block,
   from FLTK's headers; edit the script, not the block. *)

  (* display modes (InitDisplayMode), added together *)
  Rgb* = 0;
  Rgba* = 0;
  Index* = 1;
  Single* = 0;
  Double* = 2;
  Accum* = 4;
  Alpha* = 8;
  Depth* = 16;
  Stencil* = 32;
  Multisample* = 128;
  Stereo* = 256;

  (* mouse buttons, attached menus (AttachMenu) and MouseProc's button *)
  LeftButton* = 0;
  MiddleButton* = 1;
  RightButton* = 2;

  (* MouseProc's state *)
  Down* = 0;
  Up* = 1;

  (* EntryProc's state *)
  Left* = 0;
  Entered* = 1;

  (* VisibilityProc's state *)
  NotVisible* = 0;
  Visible* = 1;

  (* MenuStateProc's state *)
  MenuNotInUse* = 0;
  MenuInUse* = 1;

  (* layers (UseLayer) *)
  Normal* = 0;
  Overlay* = 1;

  (* SpecialProc's keys *)
  KeyF1* = 1;
  KeyF2* = 2;
  KeyF3* = 3;
  KeyF4* = 4;
  KeyF5* = 5;
  KeyF6* = 6;
  KeyF7* = 7;
  KeyF8* = 8;
  KeyF9* = 9;
  KeyF10* = 10;
  KeyF11* = 11;
  KeyF12* = 12;
  KeyLeft* = 65361;
  KeyUp* = 65362;
  KeyRight* = 65363;
  KeyDown* = 65364;
  KeyHome* = 65360;
  KeyEnd* = 65367;
  KeyInsert* = 65379;
  KeyPageUp* = 65365;
  KeyPageDown* = 65366;

  (* cursors (SetCursor) *)
  CursorRightArrow* = 2;
  CursorLeftArrow* = 67;
  CursorInfo* = 31;
  CursorDestroy* = 45;
  CursorHelp* = 47;
  CursorCycle* = 26;
  CursorSpray* = 63;
  CursorWait* = 76;
  CursorText* = 77;
  CursorCrosshair* = 66;
  CursorUpDown* = 78;
  CursorLeftRight* = 79;
  CursorTopSide* = 70;
  CursorBottomSide* = 9;
  CursorLeftSide* = 36;
  CursorRightSide* = 49;
  CursorTopLeftCorner* = 68;
  CursorTopRightCorner* = 69;
  CursorBottomRightCorner* = 8;
  CursorBottomLeftCorner* = 7;
  CursorInherit* = 0;
  CursorNone* = 255;
  CursorFullCrosshair* = 66;

  (* what Get gives *)
  GetWindowX* = 1;
  GetWindowY* = 2;
  GetWindowWidth* = 3;
  GetWindowHeight* = 4;
  GetWindowParent* = 5;
  GetScreenWidth* = 6;
  GetScreenHeight* = 7;
  GetMenuNumItems* = 8;
  GetDisplayModePossible* = 9;
  GetInitWindowX* = 10;
  GetInitWindowY* = 11;
  GetInitWindowWidth* = 12;
  GetInitWindowHeight* = 13;
  GetInitDisplayMode* = 14;
  GetWindowBufferSize* = 15;
  GetVersion* = 16;
  GetElapsedTime* = 17;
  GetWindowStencilSize* = 3415;
  GetWindowDepthSize* = 3414;
  GetWindowRedSize* = 3410;
  GetWindowGreenSize* = 3411;
  GetWindowBlueSize* = 3412;
  GetWindowAlphaSize* = 3413;
  GetWindowDoublebuffer* = 3122;

  (* what DeviceGet gives *)
  HasKeyboard* = 600;
  HasMouse* = 601;
  NumMouseButtons* = 605;

  (* what LayerGet gives *)
  OverlayPossible* = 800;
  NormalDamaged* = 804;
  OverlayDamaged* = 805;

  (* what GetModifiers gives, added together *)
  ActiveShift* = 65536;
  ActiveCtrl* = 262144;
  ActiveAlt* = 524288;
(* END generated constants *)

  (* GLUT's fonts, by pofltk's numbers for them *)
  Bitmap9By15* = 0;
  Bitmap8By13* = 1;
  BitmapTimesRoman10* = 2;
  BitmapTimesRoman24* = 3;
  BitmapHelvetica10* = 4;
  BitmapHelvetica12* = 5;
  BitmapHelvetica18* = 6;
  StrokeRoman* = 7;
  StrokeMonoRoman* = 8;

TYPE
  (* A GLUT window as a widget: Open it, with its parent group current, and
     it is GLUT's current window to set callbacks on after MakeCurrent. *)
  Window* = POINTER TO WindowDesc;
  WindowDesc* = RECORD (FlGl.GlWindowDesc) END;

  DisplayProc* = PROCEDURE;
  ReshapeProc* = PROCEDURE (w, h: INTEGER);
  KeyboardProc* = PROCEDURE (key: CHAR; x, y: INTEGER);
  MouseProc* = PROCEDURE (button, state, x, y: INTEGER);
  MotionProc* = PROCEDURE (x, y: INTEGER);
  StateProc* = PROCEDURE (state: INTEGER);
  TimerProc* = PROCEDURE (value: INTEGER);
  MenuProc* = PROCEDURE (value: INTEGER);
  MenuStatusProc* = PROCEDURE (status, x, y: INTEGER);
  SpecialProc* = PROCEDURE (key, x, y: INTEGER);

PROCEDURE ["C", "ofl_glut_window_new"] CNew(placed, x, y, w, h: SYSTEM.INT32; title: ARRAY OF CHAR; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_glut_number"] CNumber(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_glut_make_current"] CMakeCurrent(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_glut_has_room"] CHasRoom(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_glut_init"] CInit(argc: SYSTEM.INT32; argv: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_glut_init_display_mode"] CInitDisplayMode(mode: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glut_init_window_position"] CInitWindowPosition(x, y: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glut_init_window_size"] CInitWindowSize(w, h: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glut_main_loop"] CMainLoop;
PROCEDURE ["C", "ofl_glut_create_window"] CCreateWindow(title: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_glut_create_subwindow"] CCreateSubWindow(win, x, y, w, h: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl_ready"] CReady(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_glut_bitmap_character"] CBitmapCharacter(font, c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glut_bitmap_height"] CBitmapHeight(font: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_glut_bitmap_length"] CBitmapLength(font: SYSTEM.INT32; s: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_glut_bitmap_string"] CBitmapString(font: SYSTEM.INT32; s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_glut_bitmap_width"] CBitmapWidth(font, c: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_glut_stroke_character"] CStrokeCharacter(font, c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glut_stroke_height"] CStrokeHeight(font: SYSTEM.INT32): LONGREAL;
PROCEDURE ["C", "ofl_glut_stroke_length"] CStrokeLength(font: SYSTEM.INT32; s: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_glut_stroke_string"] CStrokeString(font: SYSTEM.INT32; s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_glut_stroke_width"] CStrokeWidth(font, c: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_glut_alive"] CAlive(win: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_glut_destroy_window"] CDestroyWindow(win: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glut_post_redisplay"] CPostRedisplay;
PROCEDURE ["C", "ofl_glut_post_window_redisplay"] CPostWindowRedisplay(win: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glut_swap_buffers"] CSwapBuffers;
PROCEDURE ["C", "ofl_glut_get_window"] CGetWindow(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_glut_set_window"] CSetWindow(win: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glut_set_window_title"] CSetWindowTitle(t: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_glut_set_icon_title"] CSetIconTitle(t: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_glut_position_window"] CPositionWindow(x, y: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glut_reshape_window"] CReshapeWindow(w, h: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glut_pop_window"] CPopWindow;
PROCEDURE ["C", "ofl_glut_iconify_window"] CIconifyWindow;
PROCEDURE ["C", "ofl_glut_show_window"] CShowWindow;
PROCEDURE ["C", "ofl_glut_hide_window"] CHideWindow;
PROCEDURE ["C", "ofl_glut_full_screen"] CFullScreen;
PROCEDURE ["C", "ofl_glut_set_cursor"] CSetCursor(c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glut_establish_overlay"] CEstablishOverlay;
PROCEDURE ["C", "ofl_glut_remove_overlay"] CRemoveOverlay;
PROCEDURE ["C", "ofl_glut_use_layer"] CUseLayer(layer: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glut_post_overlay_redisplay"] CPostOverlayRedisplay;
PROCEDURE ["C", "ofl_glut_show_overlay"] CShowOverlay;
PROCEDURE ["C", "ofl_glut_hide_overlay"] CHideOverlay;
PROCEDURE ["C", "ofl_glut_get"] CGet(type: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_glut_device_get"] CDeviceGet(type: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_glut_layer_get"] CLayerGet(type: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_glut_get_modifiers"] CGetModifiers(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_glut_extension_supported"] CExtensionSupported(name: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_glut_menu_room"] CMenuRoom(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_glut_create_menu"] CCreateMenu(cb: MenuProc): SYSTEM.INT32;
PROCEDURE ["C", "ofl_glut_menu_exists"] CMenuExists(m: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_glut_menu_items"] CMenuItems(m: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_glut_menu_used"] CMenuUsed(m: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_glut_destroy_menu"] CDestroyMenu(m: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glut_get_menu"] CGetMenu(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_glut_set_menu"] CSetMenu(m: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glut_add_menu_entry"] CAddMenuEntry(label: ARRAY OF CHAR; value: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glut_add_sub_menu"] CAddSubMenu(label: ARRAY OF CHAR; submenu: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glut_change_to_menu_entry"] CChangeToMenuEntry(item: SYSTEM.INT32; label: ARRAY OF CHAR; value: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glut_change_to_sub_menu"] CChangeToSubMenu(item: SYSTEM.INT32; label: ARRAY OF CHAR; submenu: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glut_remove_menu_item"] CRemoveMenuItem(item: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glut_attach_menu"] CAttachMenu(b: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glut_detach_menu"] CDetachMenu(b: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glut_display_func"] CDisplayFunc(f: DisplayProc);
PROCEDURE ["C", "ofl_glut_reshape_func"] CReshapeFunc(f: ReshapeProc);
PROCEDURE ["C", "ofl_glut_keyboard_func"] CKeyboardFunc(f: KeyboardProc);
PROCEDURE ["C", "ofl_glut_mouse_func"] CMouseFunc(f: MouseProc);
PROCEDURE ["C", "ofl_glut_motion_func"] CMotionFunc(f: MotionProc);
PROCEDURE ["C", "ofl_glut_passive_motion_func"] CPassiveMotionFunc(f: MotionProc);
PROCEDURE ["C", "ofl_glut_entry_func"] CEntryFunc(f: StateProc);
PROCEDURE ["C", "ofl_glut_visibility_func"] CVisibilityFunc(f: StateProc);
PROCEDURE ["C", "ofl_glut_idle_func"] CIdleFunc(f: DisplayProc);
PROCEDURE ["C", "ofl_glut_timer_func"] CTimerFunc(msec: SYSTEM.INT32; f: TimerProc; value: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glut_menu_state_func"] CMenuStateFunc(f: StateProc);
PROCEDURE ["C", "ofl_glut_menu_status_func"] CMenuStatusFunc(f: MenuStatusProc);
PROCEDURE ["C", "ofl_glut_special_func"] CSpecialFunc(f: SpecialProc);
PROCEDURE ["C", "ofl_glut_overlay_display_func"] COverlayDisplayFunc(f: DisplayProc);

(* A window as a widget *)

PROCEDURE OpenWindow*(win: Window; w, h: INTEGER; title-: ARRAY OF CHAR);
BEGIN
  ASSERT(CHasRoom() # 0, Fl.Unsupported);
  Fl.EndOpen(win, CNew(0, 0, 0, w, h, title, Fl.BeginOpen(win)))
END OpenWindow;

PROCEDURE OpenWindowAt*(win: Window; x, y, w, h: INTEGER; title-: ARRAY OF CHAR);
BEGIN
  ASSERT(CHasRoom() # 0, Fl.Unsupported);
  Fl.EndOpen(win, CNew(1, x, y, w, h, title, Fl.BeginOpen(win)))
END OpenWindowAt;

(* The window's GLUT number. *)
PROCEDURE (w: Window) Number*(): INTEGER;
BEGIN RETURN CNumber(Fl.Live(w))
END Number;

(* Makes it GLUT's current window, and its context current if it is shown:
   so, unlike a GlWindow's, this works before Show, to set its callbacks. *)
PROCEDURE (w: Window) MakeCurrent*;
BEGIN CMakeCurrent(Fl.Live(w))
END MakeCurrent;

(* Starting up *)

(* Takes the program's command line, for the first window's Show. Args is
   left as it was. *)
PROCEDURE Init*;
BEGIN CInit(Args.argc, Args.argv)
END Init;

(* The mode of windows made after this: a sum of the mode constants. *)
PROCEDURE InitDisplayMode*(mode: INTEGER);
BEGIN CInitDisplayMode(mode)
END InitDisplayMode;

PROCEDURE InitWindowPosition*(x, y: INTEGER);
BEGIN CInitWindowPosition(x, y)
END InitWindowPosition;

PROCEDURE InitWindowSize*(w, h: INTEGER);
BEGIN CInitWindowSize(w, h)
END InitWindowSize;

PROCEDURE MainLoop*;
BEGIN CMainLoop
END MainLoop;

(* Windows *)

PROCEDURE Check(win: INTEGER);
BEGIN ASSERT(CAlive(win) # 0, Fl.IndexOutOfRange)
END Check;

(* Makes a window, shown and current, and gives its number. *)
PROCEDURE CreateWindow*(title-: ARRAY OF CHAR): INTEGER;
BEGIN
  ASSERT(CHasRoom() # 0, Fl.Unsupported);
  RETURN CCreateWindow(title)
END CreateWindow;

PROCEDURE CreateSubWindow*(win, x, y, w, h: INTEGER): INTEGER;
BEGIN
  Check(win);
  ASSERT(CHasRoom() # 0, Fl.Unsupported);
  RETURN CCreateSubWindow(win, x, y, w, h)
END CreateSubWindow;

(* Whether a number is that of a window. *)
PROCEDURE WindowExists*(win: INTEGER): BOOLEAN;
BEGIN RETURN CAlive(win) # 0
END WindowExists;

PROCEDURE DestroyWindow*(win: INTEGER);
BEGIN Check(win); CDestroyWindow(win)
END DestroyWindow;

PROCEDURE PostRedisplay*;
BEGIN CPostRedisplay
END PostRedisplay;

PROCEDURE PostWindowRedisplay*(win: INTEGER);
BEGIN Check(win); CPostWindowRedisplay(win)
END PostWindowRedisplay;

(* Swaps the current window's buffers, unless it is drawing: FLTK then
   swaps them itself, after its display procedure. *)
PROCEDURE SwapBuffers*;
BEGIN CSwapBuffers
END SwapBuffers;

(* The current window's number, or 0. *)
PROCEDURE GetWindow*(): INTEGER;
BEGIN RETURN CGetWindow()
END GetWindow;

PROCEDURE SetWindow*(win: INTEGER);
BEGIN Check(win); CSetWindow(win)
END SetWindow;

(* These act on the current window, and do nothing without one. *)

PROCEDURE SetWindowTitle*(title-: ARRAY OF CHAR);
BEGIN CSetWindowTitle(title)
END SetWindowTitle;

PROCEDURE SetIconTitle*(title-: ARRAY OF CHAR);
BEGIN CSetIconTitle(title)
END SetIconTitle;

PROCEDURE PositionWindow*(x, y: INTEGER);
BEGIN CPositionWindow(x, y)
END PositionWindow;

PROCEDURE ReshapeWindow*(w, h: INTEGER);
BEGIN CReshapeWindow(w, h)
END ReshapeWindow;

PROCEDURE PopWindow*;
BEGIN CPopWindow
END PopWindow;

PROCEDURE IconifyWindow*;
BEGIN CIconifyWindow
END IconifyWindow;

PROCEDURE ShowWindow*;
BEGIN CShowWindow
END ShowWindow;

PROCEDURE HideWindow*;
BEGIN CHideWindow
END HideWindow;

PROCEDURE FullScreen*;
BEGIN CFullScreen
END FullScreen;

(* A Cursor constant. *)
PROCEDURE SetCursor*(c: INTEGER);
BEGIN CSetCursor(c)
END SetCursor;

(* The overlay, of the current window, shown or not: FLTK's is the front
   buffer of the current context, drawn after the window's display
   procedure, from the first EstablishOverlay or PostOverlayRedisplay on. *)

PROCEDURE EstablishOverlay*;
BEGIN CEstablishOverlay
END EstablishOverlay;

PROCEDURE RemoveOverlay*;
BEGIN CRemoveOverlay
END RemoveOverlay;

(* Normal or Overlay. *)
PROCEDURE UseLayer*(layer: INTEGER);
BEGIN CUseLayer(layer)
END UseLayer;

PROCEDURE PostOverlayRedisplay*;
BEGIN CPostOverlayRedisplay
END PostOverlayRedisplay;

PROCEDURE ShowOverlay*;
BEGIN CShowOverlay
END ShowOverlay;

PROCEDURE HideOverlay*;
BEGIN CHideOverlay
END HideOverlay;

(* What the program can ask *)

(* A Get constant's value. 0 for a GL query with no context, or one GL
   doesn't know. *)
PROCEDURE Get*(type: INTEGER): INTEGER;
BEGIN RETURN CGet(type)
END Get;

PROCEDURE DeviceGet*(type: INTEGER): INTEGER;
BEGIN RETURN CDeviceGet(type)
END DeviceGet;

PROCEDURE LayerGet*(type: INTEGER): INTEGER;
BEGIN RETURN CLayerGet(type)
END LayerGet;

(* The Active constants held down, a sum. *)
PROCEDURE GetModifiers*(): INTEGER;
BEGIN RETURN CGetModifiers()
END GetModifiers;

(* Whether the current context has an extension. *)
PROCEDURE ExtensionSupported*(name-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CExtensionSupported(name) # 0
END ExtensionSupported;

(* Menus *)

PROCEDURE HasMenu;
BEGIN ASSERT(CMenuExists(CGetMenu()) # 0, Fl.OutOfOrder)
END HasMenu;

(* Makes a menu, current, and gives its number. Its items will call cb with
   their values. *)
PROCEDURE CreateMenu*(cb: MenuProc): INTEGER;
BEGIN
  ASSERT(cb # NIL, Fl.NilArgument);
  ASSERT(CMenuRoom() # 0, Fl.Unsupported);
  RETURN CCreateMenu(cb)
END CreateMenu;

PROCEDURE DestroyMenu*(m: INTEGER);
BEGIN
  ASSERT(CMenuExists(m) # 0, Fl.IndexOutOfRange);
  ASSERT(CMenuUsed(m) = 0, Fl.OutOfOrder);
  CDestroyMenu(m)
END DestroyMenu;

(* The current menu's number, or 0. *)
PROCEDURE GetMenu*(): INTEGER;
BEGIN RETURN CGetMenu()
END GetMenu;

PROCEDURE SetMenu*(m: INTEGER);
BEGIN
  ASSERT(CMenuExists(m) # 0, Fl.IndexOutOfRange);
  CSetMenu(m)
END SetMenu;

PROCEDURE CanGrow;
BEGIN HasMenu; ASSERT(CMenuUsed(CGetMenu()) = 0, Fl.OutOfOrder)
END CanGrow;

PROCEDURE AddMenuEntry*(label-: ARRAY OF CHAR; value: INTEGER);
BEGIN CanGrow; CAddMenuEntry(label, value)
END AddMenuEntry;

(* A submenu must exist and have its items: see the module comment. *)
PROCEDURE GoodSubMenu(submenu: INTEGER);
BEGIN
  ASSERT(CMenuExists(submenu) # 0, Fl.IndexOutOfRange);
  ASSERT(CMenuItems(submenu) > 0, Fl.OutOfOrder);
  ASSERT(submenu # CGetMenu(), Fl.OutOfOrder)
END GoodSubMenu;

PROCEDURE AddSubMenu*(label-: ARRAY OF CHAR; submenu: INTEGER);
BEGIN CanGrow; GoodSubMenu(submenu); CAddSubMenu(label, submenu)
END AddSubMenu;

PROCEDURE GoodItem(item: INTEGER);
BEGIN
  HasMenu;
  ASSERT((item >= 1) & (item <= CMenuItems(CGetMenu())), Fl.IndexOutOfRange)
END GoodItem;

(* Items count from 1, as in GLUT. *)
PROCEDURE ChangeToMenuEntry*(item: INTEGER; label-: ARRAY OF CHAR; value: INTEGER);
BEGIN GoodItem(item); CChangeToMenuEntry(item, label, value)
END ChangeToMenuEntry;

PROCEDURE ChangeToSubMenu*(item: INTEGER; label-: ARRAY OF CHAR; submenu: INTEGER);
BEGIN GoodItem(item); GoodSubMenu(submenu); CChangeToSubMenu(item, label, submenu)
END ChangeToSubMenu;

PROCEDURE RemoveMenuItem*(item: INTEGER);
BEGIN
  GoodItem(item);
  ASSERT(CMenuUsed(CGetMenu()) = 0, Fl.OutOfOrder);
  CRemoveMenuItem(item)
END RemoveMenuItem;

(* Pops up the current menu when the current window's mouse button is
   pushed: LeftButton, MiddleButton or RightButton. FLTK crashes popping up
   a menu with no items, so it must have some. *)
PROCEDURE AttachMenu*(button: INTEGER);
BEGIN
  ASSERT((button >= LeftButton) & (button <= RightButton), Fl.IndexOutOfRange);
  ASSERT(CMenuItems(CGetMenu()) > 0, Fl.OutOfOrder);
  CAttachMenu(button)
END AttachMenu;

PROCEDURE DetachMenu*(button: INTEGER);
BEGIN
  ASSERT((button >= LeftButton) & (button <= RightButton), Fl.IndexOutOfRange);
  CDetachMenu(button)
END DetachMenu;

(* Callbacks of the current window, NIL for none, with no effect if there
   is none current. A NIL display procedure draws nothing, where FLTK's own
   would call through NIL. *)

PROCEDURE DisplayFunc*(f: DisplayProc);
BEGIN CDisplayFunc(f)
END DisplayFunc;

PROCEDURE ReshapeFunc*(f: ReshapeProc);
BEGIN CReshapeFunc(f)
END ReshapeFunc;

PROCEDURE KeyboardFunc*(f: KeyboardProc);
BEGIN CKeyboardFunc(f)
END KeyboardFunc;

PROCEDURE MouseFunc*(f: MouseProc);
BEGIN CMouseFunc(f)
END MouseFunc;

PROCEDURE MotionFunc*(f: MotionProc);
BEGIN CMotionFunc(f)
END MotionFunc;

PROCEDURE PassiveMotionFunc*(f: MotionProc);
BEGIN CPassiveMotionFunc(f)
END PassiveMotionFunc;

PROCEDURE EntryFunc*(f: StateProc);
BEGIN CEntryFunc(f)
END EntryFunc;

PROCEDURE VisibilityFunc*(f: StateProc);
BEGIN CVisibilityFunc(f)
END VisibilityFunc;

PROCEDURE SpecialFunc*(f: SpecialProc);
BEGIN CSpecialFunc(f)
END SpecialFunc;

PROCEDURE OverlayDisplayFunc*(f: DisplayProc);
BEGIN COverlayDisplayFunc(f)
END OverlayDisplayFunc;

(* Global callbacks, as GLUT's. *)

PROCEDURE IdleFunc*(f: DisplayProc);
BEGIN CIdleFunc(f)
END IdleFunc;

(* Calls f once, with value, after msec milliseconds. *)
PROCEDURE TimerFunc*(msec: INTEGER; f: TimerProc; value: INTEGER);
BEGIN
  ASSERT(f # NIL, Fl.NilArgument);
  CTimerFunc(msec, f, value)
END TimerFunc;

PROCEDURE MenuStateFunc*(f: StateProc);
BEGIN CMenuStateFunc(f)
END MenuStateFunc;

PROCEDURE MenuStatusFunc*(f: MenuStatusProc);
BEGIN CMenuStatusFunc(f)
END MenuStatusFunc;

(* Fonts *)

(* Each bitmap call sets FLTK's font, so needs a GL context, as FlGl's text
   does. *)
PROCEDURE CheckBitmap(font: INTEGER);
BEGIN
  ASSERT((font >= Bitmap9By15) & (font <= BitmapHelvetica18), Fl.IndexOutOfRange);
  ASSERT(CReady() # 0, Fl.OutOfOrder)
END CheckBitmap;

PROCEDURE CheckStroke(font: INTEGER);
BEGIN ASSERT((font >= StrokeRoman) & (font <= StrokeMonoRoman), Fl.IndexOutOfRange)
END CheckStroke;

(* c at the raster position, which moves past it, by a multiple of 4 pixels,
   so characters drawn one by one sit further apart than BitmapString's
   (doc/fltk-issues.md, 135). c is the character numbered ORD(c) in
   Unicode, as BitmapWidth measures it. *)
PROCEDURE BitmapCharacter*(font: INTEGER; c: CHAR);
BEGIN CheckBitmap(font); CBitmapCharacter(font, ORD(c))
END BitmapCharacter;

PROCEDURE BitmapHeight*(font: INTEGER): INTEGER;
BEGIN CheckBitmap(font); RETURN CBitmapHeight(font)
END BitmapHeight;

PROCEDURE BitmapLength*(font: INTEGER; s-: ARRAY OF CHAR): INTEGER;
BEGIN CheckBitmap(font); RETURN CBitmapLength(font, s)
END BitmapLength;

(* s, in UTF-8, at the raster position. *)
PROCEDURE BitmapString*(font: INTEGER; s-: ARRAY OF CHAR);
BEGIN CheckBitmap(font); CBitmapString(font, s)
END BitmapString;

(* The width of the character numbered ORD(c) in Unicode. *)
PROCEDURE BitmapWidth*(font: INTEGER; c: CHAR): INTEGER;
BEGIN CheckBitmap(font); RETURN CBitmapWidth(font, ORD(c))
END BitmapWidth;

(* c at the origin, translating the matrix past it. A stroke font's
   characters end at 7FX; any other draws nothing. *)
PROCEDURE StrokeCharacter*(font: INTEGER; c: CHAR);
BEGIN
  CheckStroke(font);
  ASSERT(CReady() # 0, Fl.OutOfOrder);
  CStrokeCharacter(font, ORD(c))
END StrokeCharacter;

PROCEDURE StrokeHeight*(font: INTEGER): REAL;
BEGIN CheckStroke(font); RETURN SHORT(CStrokeHeight(font))
END StrokeHeight;

(* The width of the longest line of s. *)
PROCEDURE StrokeLength*(font: INTEGER; s-: ARRAY OF CHAR): INTEGER;
BEGIN CheckStroke(font); RETURN CStrokeLength(font, s)
END StrokeLength;

(* s at the origin, translating the matrix past it; a 0AX goes back to the
   line's start and down a line. *)
PROCEDURE StrokeString*(font: INTEGER; s-: ARRAY OF CHAR);
BEGIN
  CheckStroke(font);
  ASSERT(CReady() # 0, Fl.OutOfOrder);
  CStrokeString(font, s)
END StrokeString;

PROCEDURE StrokeWidth*(font: INTEGER; c: CHAR): INTEGER;
BEGIN CheckStroke(font); RETURN CStrokeWidth(font, ORD(c))
END StrokeWidth;

END FlGlut.
