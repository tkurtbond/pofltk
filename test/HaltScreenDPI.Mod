MODULE HaltScreenDPI; (* a screen there isn't *)

IMPORT Fl;

VAR h, v: LONGREAL;

BEGIN Fl.ScreenDPI(-1, h, v)
END HaltScreenDPI.
