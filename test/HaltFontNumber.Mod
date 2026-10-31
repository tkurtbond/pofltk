MODULE HaltFontNumber; (* a font number past the table's end *)

IMPORT Fl;

VAR name: ARRAY 64 OF CHAR;

BEGIN Fl.GetFont(Fl.FontEnd(), name)
END HaltFontNumber.
