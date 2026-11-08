MODULE Curve; (* FLTK's test/curve.cxx in Oberon-2 *)

(* A Bezier curve: its four control points, joined by a black line, and
   the curve, filled in white and outlined in red, or drawn as points.
   Sliders move the points and rotate the drawing. *)

IMPORT Fl, FlDraw, FlValuators, FlButtons;

TYPE
  Drawing = POINTER TO RECORD (Fl.BoxDesc) END;
  Arg = POINTER TO RECORD (FlValuators.ValueSliderDesc) n: INTEGER END;
  Points = POINTER TO RECORD (FlButtons.ToggleButtonDesc) END;

VAR
  args: ARRAY 9 OF LONGREAL;
  points: BOOLEAN;
  window: Fl.DoubleWindow;
  d: Drawing;
  s: Arg;
  but: Points;
  n, y: INTEGER;
  label: ARRAY 8 OF CHAR;

PROCEDURE (w: Drawing) Draw*;
BEGIN
  FlDraw.PushClip(w.X(), w.Y(), w.W(), w.H());
  FlDraw.SetColor(Fl.Dark3);
  FlDraw.RectF(w.X(), w.Y(), w.W(), w.H());
  FlDraw.PushMatrix;
  IF args[8] # 0 THEN
    FlDraw.Translate(w.X() + w.W() / 2.0D0, w.Y() + w.H() / 2.0D0);
    FlDraw.Rotate(args[8]);
    FlDraw.Translate(-(w.X() + w.W() / 2.0D0), -(w.Y() + w.H() / 2.0D0))
  END;
  FlDraw.Translate(w.X(), w.Y());
  IF ~points THEN
    FlDraw.SetColor(Fl.White);
    FlDraw.BeginComplexPolygon;
    FlDraw.Curve(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7]);
    FlDraw.EndComplexPolygon
  END;
  FlDraw.SetColor(Fl.Black);
  FlDraw.BeginLine;
  FlDraw.Vertex(args[0], args[1]);
  FlDraw.Vertex(args[2], args[3]);
  FlDraw.Vertex(args[4], args[5]);
  FlDraw.Vertex(args[6], args[7]);
  FlDraw.EndLine;
  IF points THEN FlDraw.SetColor(Fl.White); FlDraw.BeginPoints
  ELSE FlDraw.SetColor(Fl.Red); FlDraw.BeginLine
  END;
  FlDraw.Curve(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7]);
  IF points THEN FlDraw.EndPoints ELSE FlDraw.EndLine END;
  FlDraw.PopMatrix;
  FlDraw.PopClip
END Draw;

PROCEDURE (b: Points) Callback*;
BEGIN points := b.Value(); d.Redraw
END Callback;

PROCEDURE (a: Arg) Callback*;
BEGIN args[a.n] := a.Value(); d.Redraw
END Callback;

PROCEDURE Name(n: INTEGER; VAR s: ARRAY OF CHAR);
BEGIN
  IF n = 8 THEN COPY("rotate", s)
  ELSE
    IF ODD(n) THEN COPY("Y0", s) ELSE COPY("X0", s) END;
    s[1] := CHR(ORD("0") + n DIV 2)
  END
END Name;

BEGIN
  args[0] := 20; args[1] := 20; args[2] := 50; args[3] := 200;
  args[4] := 100; args[5] := 20; args[6] := 200; args[7] := 200; args[8] := 0;
  NEW(window); Fl.OpenDoubleWindow(window, 300, 555, "Curve");
  NEW(d); Fl.OpenBox(d, 10, 10, 280, 280, "");
  y := 300;
  FOR n := 0 TO 8 DO
    NEW(s); s.n := n;
    Name(n, label);
    FlValuators.OpenHorValueSlider(s, 50, y, 240, 25, label); INC(y, 25);
    IF n = 8 THEN s.SetBounds(0, 360) ELSE s.SetBounds(0, 280) END;
    s.SetStep(1);
    s.SetValue(args[n]);
    s.SetAlign(Fl.AlignLeft)
  END;
  NEW(but); FlButtons.OpenToggleButton(but, 50, y, 50, 25, "points");
  window.End;
  window.ShowArgs;
  Fl.Run
END Curve.
