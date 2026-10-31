MODULE HaltGetBoxtype; (* a box type past 255 *)

IMPORT Fl;

VAR b: Fl.BoxDraw;

BEGIN b := Fl.GetBoxtype(256)
END HaltGetBoxtype.
