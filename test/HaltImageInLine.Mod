MODULE HaltImageInLine; (* An image drawn in a Line halts with Fl.OutOfOrder, 77 *)
IMPORT Fl, FlDraw, Probe;
TYPE
  Canvas = POINTER TO CanvasDesc;
  CanvasDesc = RECORD (Fl.BoxDesc) END;
  Source = POINTER TO SourceDesc;
  SourceDesc = RECORD (FlDraw.ImageSourceDesc) END;
VAR
  win: Fl.Window; canvas: Canvas; source: Source;
  ok: BOOLEAN;

PROCEDURE (s: Source) Line*(x, y, w: INTEGER; VAR buf: ARRAY OF CHAR);
BEGIN FlDraw.DrawImageMonoLines(s, 0, 0, 1, 1, 1)
END Line;

PROCEDURE (c: Canvas) Draw*;
BEGIN FlDraw.DrawImageLines(source, 0, 0, 2, 2, 3)
END Draw;

BEGIN
  NEW(win); Fl.OpenWindow(win, 20, 20, "HaltImageInLine");
  NEW(canvas); Fl.OpenBox(canvas, 0, 0, 20, 20, "");
  win.End;
  NEW(source);
  ok := Probe.Capture(canvas)
END HaltImageInLine.
