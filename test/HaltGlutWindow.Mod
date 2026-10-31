MODULE HaltGlutWindow; (* SetWindow of no window halts with Fl.IndexOutOfRange, 74 *)
IMPORT FlGlut;
BEGIN
  FlGlut.SetWindow(7)
END HaltGlutWindow.
