MODULE TestGlutConstants; (* pofltk's constants are FLTK's *)

(* Written by tools/gen-constants.py: one check per constant, against the
   value the installed FLTK's headers give (CGlutConstants). A failure means
   FLTK's headers changed: run the script again, and see what moved. *)

IMPORT SYSTEM, Out, FlGlut, Check, CGlutConstants;

VAR checked, wrong: INTEGER;

PROCEDURE Same(oberon: INTEGER; c-: ARRAY OF CHAR);
  VAR v: INTEGER;
BEGIN
  INC(checked);
  IF ~CGlutConstants.Value(c, v) OR (v # oberon) THEN
    INC(wrong); Out.String("  differs from C: "); Out.String(c); Out.Ln
  END
END Same;

BEGIN
  checked := 0; wrong := 0;
  Same(FlGlut.Rgb, "GLUT_RGB");
  Same(FlGlut.Rgba, "GLUT_RGBA");
  Same(FlGlut.Index, "GLUT_INDEX");
  Same(FlGlut.Single, "GLUT_SINGLE");
  Same(FlGlut.Double, "GLUT_DOUBLE");
  Same(FlGlut.Accum, "GLUT_ACCUM");
  Same(FlGlut.Alpha, "GLUT_ALPHA");
  Same(FlGlut.Depth, "GLUT_DEPTH");
  Same(FlGlut.Stencil, "GLUT_STENCIL");
  Same(FlGlut.Multisample, "GLUT_MULTISAMPLE");
  Same(FlGlut.Stereo, "GLUT_STEREO");
  Same(FlGlut.LeftButton, "GLUT_LEFT_BUTTON");
  Same(FlGlut.MiddleButton, "GLUT_MIDDLE_BUTTON");
  Same(FlGlut.RightButton, "GLUT_RIGHT_BUTTON");
  Same(FlGlut.Down, "GLUT_DOWN");
  Same(FlGlut.Up, "GLUT_UP");
  Same(FlGlut.Left, "GLUT_LEFT");
  Same(FlGlut.Entered, "GLUT_ENTERED");
  Same(FlGlut.NotVisible, "GLUT_NOT_VISIBLE");
  Same(FlGlut.Visible, "GLUT_VISIBLE");
  Same(FlGlut.MenuNotInUse, "GLUT_MENU_NOT_IN_USE");
  Same(FlGlut.MenuInUse, "GLUT_MENU_IN_USE");
  Same(FlGlut.Normal, "GLUT_NORMAL");
  Same(FlGlut.Overlay, "GLUT_OVERLAY");
  Same(FlGlut.KeyF1, "GLUT_KEY_F1");
  Same(FlGlut.KeyF2, "GLUT_KEY_F2");
  Same(FlGlut.KeyF3, "GLUT_KEY_F3");
  Same(FlGlut.KeyF4, "GLUT_KEY_F4");
  Same(FlGlut.KeyF5, "GLUT_KEY_F5");
  Same(FlGlut.KeyF6, "GLUT_KEY_F6");
  Same(FlGlut.KeyF7, "GLUT_KEY_F7");
  Same(FlGlut.KeyF8, "GLUT_KEY_F8");
  Same(FlGlut.KeyF9, "GLUT_KEY_F9");
  Same(FlGlut.KeyF10, "GLUT_KEY_F10");
  Same(FlGlut.KeyF11, "GLUT_KEY_F11");
  Same(FlGlut.KeyF12, "GLUT_KEY_F12");
  Same(FlGlut.KeyLeft, "GLUT_KEY_LEFT");
  Same(FlGlut.KeyUp, "GLUT_KEY_UP");
  Same(FlGlut.KeyRight, "GLUT_KEY_RIGHT");
  Same(FlGlut.KeyDown, "GLUT_KEY_DOWN");
  Same(FlGlut.KeyHome, "GLUT_KEY_HOME");
  Same(FlGlut.KeyEnd, "GLUT_KEY_END");
  Same(FlGlut.KeyInsert, "GLUT_KEY_INSERT");
  Same(FlGlut.KeyPageUp, "GLUT_KEY_PAGE_UP");
  Same(FlGlut.KeyPageDown, "GLUT_KEY_PAGE_DOWN");
  Same(FlGlut.CursorRightArrow, "GLUT_CURSOR_RIGHT_ARROW");
  Same(FlGlut.CursorLeftArrow, "GLUT_CURSOR_LEFT_ARROW");
  Same(FlGlut.CursorInfo, "GLUT_CURSOR_INFO");
  Same(FlGlut.CursorDestroy, "GLUT_CURSOR_DESTROY");
  Same(FlGlut.CursorHelp, "GLUT_CURSOR_HELP");
  Same(FlGlut.CursorCycle, "GLUT_CURSOR_CYCLE");
  Same(FlGlut.CursorSpray, "GLUT_CURSOR_SPRAY");
  Same(FlGlut.CursorWait, "GLUT_CURSOR_WAIT");
  Same(FlGlut.CursorText, "GLUT_CURSOR_TEXT");
  Same(FlGlut.CursorCrosshair, "GLUT_CURSOR_CROSSHAIR");
  Same(FlGlut.CursorUpDown, "GLUT_CURSOR_UP_DOWN");
  Same(FlGlut.CursorLeftRight, "GLUT_CURSOR_LEFT_RIGHT");
  Same(FlGlut.CursorTopSide, "GLUT_CURSOR_TOP_SIDE");
  Same(FlGlut.CursorBottomSide, "GLUT_CURSOR_BOTTOM_SIDE");
  Same(FlGlut.CursorLeftSide, "GLUT_CURSOR_LEFT_SIDE");
  Same(FlGlut.CursorRightSide, "GLUT_CURSOR_RIGHT_SIDE");
  Same(FlGlut.CursorTopLeftCorner, "GLUT_CURSOR_TOP_LEFT_CORNER");
  Same(FlGlut.CursorTopRightCorner, "GLUT_CURSOR_TOP_RIGHT_CORNER");
  Same(FlGlut.CursorBottomRightCorner, "GLUT_CURSOR_BOTTOM_RIGHT_CORNER");
  Same(FlGlut.CursorBottomLeftCorner, "GLUT_CURSOR_BOTTOM_LEFT_CORNER");
  Same(FlGlut.CursorInherit, "GLUT_CURSOR_INHERIT");
  Same(FlGlut.CursorNone, "GLUT_CURSOR_NONE");
  Same(FlGlut.CursorFullCrosshair, "GLUT_CURSOR_FULL_CROSSHAIR");
  Same(FlGlut.GetWindowX, "GLUT_WINDOW_X");
  Same(FlGlut.GetWindowY, "GLUT_WINDOW_Y");
  Same(FlGlut.GetWindowWidth, "GLUT_WINDOW_WIDTH");
  Same(FlGlut.GetWindowHeight, "GLUT_WINDOW_HEIGHT");
  Same(FlGlut.GetWindowParent, "GLUT_WINDOW_PARENT");
  Same(FlGlut.GetScreenWidth, "GLUT_SCREEN_WIDTH");
  Same(FlGlut.GetScreenHeight, "GLUT_SCREEN_HEIGHT");
  Same(FlGlut.GetMenuNumItems, "GLUT_MENU_NUM_ITEMS");
  Same(FlGlut.GetDisplayModePossible, "GLUT_DISPLAY_MODE_POSSIBLE");
  Same(FlGlut.GetInitWindowX, "GLUT_INIT_WINDOW_X");
  Same(FlGlut.GetInitWindowY, "GLUT_INIT_WINDOW_Y");
  Same(FlGlut.GetInitWindowWidth, "GLUT_INIT_WINDOW_WIDTH");
  Same(FlGlut.GetInitWindowHeight, "GLUT_INIT_WINDOW_HEIGHT");
  Same(FlGlut.GetInitDisplayMode, "GLUT_INIT_DISPLAY_MODE");
  Same(FlGlut.GetWindowBufferSize, "GLUT_WINDOW_BUFFER_SIZE");
  Same(FlGlut.GetVersion, "GLUT_VERSION");
  Same(FlGlut.GetElapsedTime, "GLUT_ELAPSED_TIME");
  Same(FlGlut.GetWindowStencilSize, "GLUT_WINDOW_STENCIL_SIZE");
  Same(FlGlut.GetWindowDepthSize, "GLUT_WINDOW_DEPTH_SIZE");
  Same(FlGlut.GetWindowRedSize, "GLUT_WINDOW_RED_SIZE");
  Same(FlGlut.GetWindowGreenSize, "GLUT_WINDOW_GREEN_SIZE");
  Same(FlGlut.GetWindowBlueSize, "GLUT_WINDOW_BLUE_SIZE");
  Same(FlGlut.GetWindowAlphaSize, "GLUT_WINDOW_ALPHA_SIZE");
  Same(FlGlut.GetWindowDoublebuffer, "GLUT_WINDOW_DOUBLEBUFFER");
  Same(FlGlut.HasKeyboard, "GLUT_HAS_KEYBOARD");
  Same(FlGlut.HasMouse, "GLUT_HAS_MOUSE");
  Same(FlGlut.NumMouseButtons, "GLUT_NUM_MOUSE_BUTTONS");
  Same(FlGlut.OverlayPossible, "GLUT_OVERLAY_POSSIBLE");
  Same(FlGlut.NormalDamaged, "GLUT_NORMAL_DAMAGED");
  Same(FlGlut.OverlayDamaged, "GLUT_OVERLAY_DAMAGED");
  Same(FlGlut.ActiveShift, "GLUT_ACTIVE_SHIFT");
  Same(FlGlut.ActiveCtrl, "GLUT_ACTIVE_CTRL");
  Same(FlGlut.ActiveAlt, "GLUT_ACTIVE_ALT");
  Check.Check((wrong = 0) & (checked = 101), "each of 101 constants and values is FLTK's");
  Check.Summary
END TestGlutConstants.
