MODULE HaltGlSetMode; (* SetMode in Draw halts with Fl.OutOfOrder, 77 *)
IMPORT Fl, FlGl;
TYPE
  Window = POINTER TO WindowDesc;
  WindowDesc = RECORD (FlGl.GlWindowDesc) END;
VAR w: Window; i: INTEGER;

PROCEDURE (w: Window) Draw*;
BEGIN w.SetMode(FlGl.Rgb + FlGl.Double)
END Draw;

BEGIN
  NEW(w); FlGl.OpenGlWindow(w, 10, 10, "");
  w.End;
  w.Show;
  FOR i := 1 TO 500 DO Fl.Wait(0.02D0) END
END HaltGlSetMode.
