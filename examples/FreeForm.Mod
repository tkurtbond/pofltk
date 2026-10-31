MODULE FreeForm; (* A Forms free object tracing the mouse with a line, which shortens by itself *)

(* FlForms.Free hears everything through one method, HandleFree: the mouse,
   drawing (FreeDraw), and, since this one is a ContinuousFree, a FreeStep
   100 times a second. *)

IMPORT Fl, FlDraw, FlForms;

CONST
  points = 200;
  stepsPerPoint = 5;  (* FreeSteps before the oldest point goes *)

TYPE
  Point = RECORD x, y: INTEGER END;

  Tracer = POINTER TO RECORD (FlForms.FreeDesc)
    trail: ARRAY points OF Point;
    first, count: INTEGER;  (* the trail, oldest first, wrapping *)
    steps: INTEGER
  END;

VAR
  win: Fl.DoubleWindow;
  tracer: Tracer;

PROCEDURE (t: Tracer) AddPoint(x, y: INTEGER);
  VAR i: INTEGER;
BEGIN
  i := (t.first + t.count) MOD points;
  t.trail[i].x := x; t.trail[i].y := y;
  IF t.count < points THEN INC(t.count) ELSE t.first := (t.first + 1) MOD points END;
  t.Redraw
END AddPoint;

PROCEDURE (t: Tracer) Shorten;
BEGIN
  INC(t.steps);
  IF (t.steps >= stepsPerPoint) & (t.count > 0) THEN
    t.steps := 0;
    t.first := (t.first + 1) MOD points; DEC(t.count);
    t.Redraw
  END
END Shorten;

PROCEDURE (t: Tracer) DrawTrail;
  VAR i, a, b, shade: INTEGER;
BEGIN
  FlDraw.SetColor(Fl.White); FlDraw.RectF(t.X(), t.Y(), t.W(), t.H());
  FOR i := 1 TO t.count - 1 DO
    a := (t.first + i - 1) MOD points; b := (t.first + i) MOD points;
    shade := 255 - 255 * i DIV t.count;  (* the oldest palest *)
    FlDraw.SetRGB(shade, shade, 255);
    FlDraw.Line(t.trail[a].x, t.trail[a].y, t.trail[b].x, t.trail[b].y)
  END
END DrawTrail;

PROCEDURE (t: Tracer) HandleFree*(event, x, y, key: INTEGER): BOOLEAN;
BEGIN
  IF event = FlForms.FreeDraw THEN t.DrawTrail
  ELSIF event = FlForms.FreeStep THEN t.Shorten
  ELSIF (event = Fl.EvMove) OR (event = Fl.EvDrag) THEN t.AddPoint(x, y)
  END;
  RETURN FALSE
END HandleFree;

BEGIN
  NEW(win); Fl.OpenDoubleWindow(win, 400, 300, "Free form");
  NEW(tracer);
  FlForms.OpenFree(tracer, FlForms.ContinuousFree, 10, 10, 380, 280, "");
  tracer.first := 0; tracer.count := 0; tracer.steps := 0;
  win.SetResizable(tracer);
  win.End;
  win.ShowArgs;
  Fl.Run
END FreeForm.
