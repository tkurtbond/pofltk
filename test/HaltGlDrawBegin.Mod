MODULE HaltGlDrawBegin; (* DrawBegin outside the window's Draw: Fl.OutOfOrder, 77 *)
IMPORT FlGl;
VAR w: FlGl.GlWindow;
BEGIN
  NEW(w); FlGl.OpenGlWindow(w, 10, 10, "");
  w.End;
  w.DrawBegin
END HaltGlDrawBegin.
