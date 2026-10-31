MODULE HaltGlFont; (* GL text with no context halts with Fl.OutOfOrder, 77 *)
IMPORT Fl, FlGl;
BEGIN
  FlGl.Font(Fl.Helvetica, 12)
END HaltGlFont.
