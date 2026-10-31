MODULE HaltCursorHot; (* A cursor's hot spot outside its image halts with Fl.IndexOutOfRange, 74 *)
IMPORT Fl, FlImages;
VAR win: Fl.Window; i: FlImages.Image; bits: ARRAY 3 OF CHAR;
BEGIN
  NEW(win); Fl.OpenWindow(win, 10, 10, ""); win.End;
  NEW(i); FlImages.OpenRGB(i, bits, 1, 1, 3, 0);
  FlImages.SetCursor(win, i, 1, 0)
END HaltCursorHot.
