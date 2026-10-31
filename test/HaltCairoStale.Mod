MODULE HaltCairoStale; (* a context used after its draw halts with Fl.OutOfOrder, 77 *)

IMPORT Fl, FlCairo;

TYPE Keeper = POINTER TO RECORD (FlCairo.CairoWindowDesc)
    kept: FlCairo.Context
  END;

VAR w: Keeper; i: INTEGER;

PROCEDURE (w: Keeper) DrawCairo*(c: FlCairo.Context);
BEGIN w.kept := c
END DrawCairo;

BEGIN
  NEW(w);
  FlCairo.OpenCairoWindow(w, 100, 60, "");
  w.End;
  w.Show;
  i := 0;
  WHILE (w.kept = NIL) & (i < 500) DO Fl.Wait(0.01D0); INC(i) END;
  w.kept.SetSourceRGB(1, 0, 0)
END HaltCairoStale.
