MODULE Arc; (* FLTK's test/arc.cxx in Oberon-2 *)

(* An arc drawn with ArcPath, filled in white with a hole in it, and
   outlined in red. Sliders set its centre, radius, start and end
   angles, and a rotation of the whole drawing. *)

IMPORT Fl, FlDraw, FlValuators;

TYPE
  Drawing = POINTER TO RECORD (Fl.BoxDesc) END;
  Arg = POINTER TO RECORD (FlValuators.ValueSliderDesc) n: INTEGER END;

VAR
  args: ARRAY 6 OF LONGREAL;
  window: Fl.DoubleWindow;
  d: Drawing;
  s: Arg;
  n, y: INTEGER;

PROCEDURE (w: Drawing) Draw*;
BEGIN
  FlDraw.PushClip(w.X(), w.Y(), w.W(), w.H());
  FlDraw.SetColor(Fl.Dark3);
  FlDraw.RectF(w.X(), w.Y(), w.W(), w.H());
  FlDraw.PushMatrix;
  IF args[5] # 0 THEN
    FlDraw.Translate(w.X() + w.W() / 2.0D0, w.Y() + w.H() / 2.0D0);
    FlDraw.Rotate(args[5]);
    FlDraw.Translate(-(w.X() + w.W() / 2.0D0), -(w.Y() + w.H() / 2.0D0))
  END;
  FlDraw.SetColor(Fl.White);
  FlDraw.Translate(w.X(), w.Y());
  FlDraw.BeginComplexPolygon;
  FlDraw.ArcPath(args[0], args[1], args[2], args[3], args[4]);
  FlDraw.Gap;
  FlDraw.ArcPath(140, 140, 20, 0, -360);
  FlDraw.EndComplexPolygon;
  FlDraw.SetColor(Fl.Red);
  FlDraw.BeginLine;
  FlDraw.ArcPath(args[0], args[1], args[2], args[3], args[4]);
  FlDraw.EndLine;
  FlDraw.PopMatrix;
  FlDraw.PopClip
END Draw;

PROCEDURE (a: Arg) Callback*;
BEGIN args[a.n] := a.Value(); d.Redraw
END Callback;

BEGIN
  args[0] := 140; args[1] := 140; args[2] := 50;
  args[3] := 0; args[4] := 360; args[5] := 0;
  NEW(window); Fl.OpenDoubleWindow(window, 300, 500, "Arc");
  NEW(d); Fl.OpenBox(d, 10, 10, 280, 280, "");
  y := 300;
  FOR n := 0 TO 5 DO
    NEW(s); s.n := n;
    CASE n OF
      0: FlValuators.OpenHorValueSlider(s, 50, y, 240, 25, "X")
    | 1: FlValuators.OpenHorValueSlider(s, 50, y, 240, 25, "Y")
    | 2: FlValuators.OpenHorValueSlider(s, 50, y, 240, 25, "R")
    | 3: FlValuators.OpenHorValueSlider(s, 50, y, 240, 25, "start")
    | 4: FlValuators.OpenHorValueSlider(s, 50, y, 240, 25, "end")
    | 5: FlValuators.OpenHorValueSlider(s, 50, y, 240, 25, "rotate")
    END;
    INC(y, 25);
    IF n < 3 THEN s.SetBounds(0, 300)
    ELSIF n = 5 THEN s.SetBounds(0, 360)
    ELSE s.SetBounds(-360, 360)
    END;
    s.SetStep(1);
    s.SetValue(args[n]);
    s.SetAlign(Fl.AlignLeft)
  END;
  window.End;
  window.ShowArgs;
  Fl.Run
END Arc.
