MODULE HaltSchemeName; (* A scheme past the last halts with Fl.IndexOutOfRange, 74 *)
IMPORT Fl;
VAR s: ARRAY 16 OF CHAR;
BEGIN Fl.SchemeName(Fl.SchemeCount(), s)
END HaltSchemeName.
