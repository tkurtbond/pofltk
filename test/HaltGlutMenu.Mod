MODULE HaltGlutMenu; (* SetMenu of no menu halts with Fl.IndexOutOfRange, 74 *)
IMPORT FlGlut;
BEGIN
  FlGlut.SetMenu(5)
END HaltGlutMenu.
