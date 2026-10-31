MODULE HaltContrastMode; (* a contrast mode FLTK doesn't have *)

IMPORT Fl;

BEGIN Fl.SetContrastMode(Fl.ContrastCustom + 1)
END HaltContrastMode.
