MODULE HaltFontFrom; (* SetFontFrom of a number with no font *)

IMPORT Fl;

BEGIN
  Fl.SetFont(Fl.FreeFont + 1, "x");
  Fl.SetFontFrom(Fl.FreeFont + 2, Fl.FreeFont)
END HaltFontFrom.
