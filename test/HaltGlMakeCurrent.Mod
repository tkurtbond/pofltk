MODULE HaltGlMakeCurrent; (* A GL window not shown can't be made current: Fl.OutOfOrder, 77 *)
IMPORT FlGl;
VAR w: FlGl.GlWindow;
BEGIN
  NEW(w); FlGl.OpenGlWindow(w, 10, 10, "");
  w.End;
  w.MakeCurrent
END HaltGlMakeCurrent.
