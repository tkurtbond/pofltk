MODULE HaltArrow; (* An arrow of no kind halts with Fl.IndexOutOfRange, 74 *)
IMPORT FlDraw;
BEGIN
  FlDraw.DrawArrow(0, 0, 10, 10, 0, FlDraw.OrientUp, 0)
END HaltArrow.
