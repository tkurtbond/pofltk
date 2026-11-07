MODULE HaltLineNumberFormat; (* a line number format FLTK would read a string for *)

IMPORT Fl, FlText;

VAR d: FlText.TextDisplay;

BEGIN
  NEW(d); FlText.OpenTextDisplay(d, 0, 0, 100, 100, "");
  d.SetLineNumberFormat("%d %s")
END HaltLineNumberFormat.
