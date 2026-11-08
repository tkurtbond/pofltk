MODULE HaltLabelMargin; (* a label margin past a signed byte halts with Fl.IndexOutOfRange, 74 *)
IMPORT Fl;
VAR b: Fl.Box;
BEGIN
  NEW(b); Fl.OpenBox(b, 0, 0, 100, 20, "b");
  b.SetHorizontalLabelMargin(128)
END HaltLabelMargin.
