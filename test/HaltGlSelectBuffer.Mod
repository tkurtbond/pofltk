MODULE HaltGlSelectBuffer; (* SelectBuffer in select mode halts with Fl.OutOfOrder, 77 *)
IMPORT Fl, FlGl;
  VAR w: FlGl.GlWindow; n: INTEGER;
BEGIN
  NEW(w);
  FlGl.OpenGlWindow(w, 40, 40, "");
  w.End;
  w.Show;
  w.MakeCurrent;
  FlGl.SelectBuffer(4);
  n := FlGl.RenderMode(FlGl.Select);
  FlGl.SelectBuffer(4)
END HaltGlSelectBuffer.
