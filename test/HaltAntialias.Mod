MODULE HaltAntialias; (* Antialias with nothing to draw on halts with Fl.OutOfOrder, 77 *)
IMPORT FlDraw;
VAR on: BOOLEAN;
BEGIN
  on := FlDraw.Antialias()
END HaltAntialias.
