MODULE HaltGrabHidden; (* a grab of a window not shown *)

IMPORT Fl;

VAR w: Fl.Window;

BEGIN
  NEW(w); Fl.OpenWindow(w, 20, 20, ""); w.End;
  Fl.SetGrab(w)
END HaltGrabHidden.
