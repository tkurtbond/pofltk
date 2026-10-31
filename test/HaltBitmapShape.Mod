MODULE HaltBitmapShape; (* a bitmap can't shape a window (Fl.Unsupported) *)

IMPORT Fl, FlImages;

VAR
  win: Fl.Window;
  i: FlImages.Image;
  bits: ARRAY 2 OF CHAR;

BEGIN
  NEW(win); Fl.OpenWindow(win, 40, 40, "HaltBitmapShape"); win.End;
  NEW(i); FlImages.OpenBitmap(i, bits, 4, 2);
  FlImages.SetShape(win, i)
END HaltBitmapShape.
