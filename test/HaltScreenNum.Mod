MODULE HaltScreenNum; (* a window put on a screen there isn't *)

IMPORT Fl;

VAR w: Fl.Window;

BEGIN
  NEW(w); Fl.OpenWindow(w, 100, 80, "w"); w.End;
  w.SetScreenNum(Fl.ScreenCount())
END HaltScreenNum.
