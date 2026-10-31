MODULE HaltScroll; (* Scrolling with no window current halts with Fl.OutOfOrder, 77 *)
IMPORT FlDraw;
VAR a: FlDraw.Area;
BEGIN
  NEW(a); FlDraw.Scroll(0, 0, 10, 10, 1, 1, a)
END HaltScroll.
