MODULE HaltFontGap; (* SetFont past MaxFont *)

IMPORT Fl;

BEGIN Fl.SetFont(Fl.MaxFont + 1, "x")
END HaltFontGap.
