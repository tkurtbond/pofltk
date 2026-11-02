MODULE HaltDashLong; (* A dash pattern past MaxDashes lengths halts with Fl.IndexOutOfRange, 74 *)
IMPORT FlDraw;
VAR d: ARRAY FlDraw.MaxDashes + 1 OF INTEGER; i: INTEGER;
BEGIN
  FOR i := 0 TO FlDraw.MaxDashes DO d[i] := 1 END;
  FlDraw.LineStyleDashes(FlDraw.Solid, 1, d)
END HaltDashLong.
