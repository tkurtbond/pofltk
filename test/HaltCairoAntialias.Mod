MODULE HaltCairoAntialias; (* an antialias mode cairo hasn't halts with Fl.IndexOutOfRange, 74 *)

IMPORT Fl, FlCairo;

TYPE Bad = POINTER TO RECORD (FlCairo.CairoWindowDesc) END;

VAR w: Bad; i: INTEGER;

PROCEDURE (w: Bad) DrawCairo*(c: FlCairo.Context);
BEGIN c.SetAntialias(FlCairo.AntialiasBest + 1)
END DrawCairo;

BEGIN
  NEW(w);
  FlCairo.OpenCairoWindow(w, 100, 60, "");
  w.End;
  w.Show;
  i := 0;
  WHILE i < 500 DO Fl.Wait(0.01D0); INC(i) END;
  HALT(1)
END HaltCairoAntialias.
