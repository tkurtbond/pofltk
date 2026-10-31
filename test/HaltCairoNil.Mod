MODULE HaltCairoNil; (* a NIL pattern halts with Fl.NilArgument, 72 *)

IMPORT Fl, FlCairo;

TYPE Bad = POINTER TO RECORD (FlCairo.CairoWindowDesc) END;

VAR w: Bad; i: INTEGER;

PROCEDURE (w: Bad) DrawCairo*(c: FlCairo.Context);
  VAR p: FlCairo.Pattern;
BEGIN p := NIL; c.SetSource(p)
END DrawCairo;

BEGIN
  NEW(w);
  FlCairo.OpenCairoWindow(w, 100, 60, "");
  w.End;
  w.Show;
  i := 0;
  WHILE i < 500 DO Fl.Wait(0.01D0); INC(i) END;
  HALT(1)
END HaltCairoNil.
