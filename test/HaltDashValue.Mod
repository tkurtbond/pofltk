MODULE HaltDashValue; (* A dash length past 127 halts with Fl.IndexOutOfRange, 74 *)
IMPORT FlDraw;
VAR d: ARRAY 2 OF INTEGER;
BEGIN
  d[0] := 3; d[1] := 128;
  FlDraw.LineStyleDashes(FlDraw.Solid, 1, d)
END HaltDashValue.
