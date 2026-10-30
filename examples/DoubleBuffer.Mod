MODULE DoubleBuffer; (* FLTK's test/doublebuffer.cxx in Oberon-2 *)

(* The same star, drawn slowly enough to see, in a window that draws on
   the screen and one that draws off it. Move a slider to see the
   difference. *)

IMPORT Fl, FlDraw, FlValuators, MathL;

TYPE
  SingleBlink = POINTER TO RECORD (Fl.SingleWindowDesc) sides: INTEGER END;
  DoubleBlink = POINTER TO RECORD (Fl.DoubleWindowDesc) sides: INTEGER END;
  Sides = POINTER TO RECORD (FlValuators.SliderDesc) END;

VAR
  w01, w02: Fl.Window;
  w1: SingleBlink;
  w2: DoubleBlink;
  slider0, slider1: Sides;

PROCEDURE Point(i, n: INTEGER);
  VAR a: LONGREAL;
BEGIN
  a := 2.0D0 * MathL.pi * i / n + 0.1D0;
  FlDraw.Vertex(MathL.cos(a), MathL.sin(a))
END Point;

PROCEDURE Star(w, h, n: INTEGER);
  VAR i, j: INTEGER;
BEGIN
  FlDraw.PushMatrix;
  FlDraw.Translate(w DIV 2, h DIV 2);
  FlDraw.Scale(w DIV 2, h DIV 2);
  FOR i := 0 TO n - 1 DO
    FOR j := i + 1 TO n - 1 DO
      FlDraw.BeginLine; Point(i, n); Point(j, n); FlDraw.EndLine
    END
  END;
  FlDraw.PopMatrix
END Star;

PROCEDURE BadDraw(w, h, sides: INTEGER);
BEGIN
  FlDraw.SetColor(Fl.Black); FlDraw.RectF(0, 0, w, h);
  FlDraw.SetColor(Fl.White); Star(w, h, sides)
END BadDraw;

PROCEDURE (win: SingleBlink) Draw*;
BEGIN BadDraw(win.W(), win.H(), win.sides); win.DrawChild(win.Child(0))
END Draw;

PROCEDURE (win: DoubleBlink) Draw*;
BEGIN BadDraw(win.W(), win.H(), win.sides); win.DrawChild(win.Child(0))
END Draw;

PROCEDURE (s: Sides) Callback*;
BEGIN
  IF s = slider0 THEN w1.sides := SHORT(ENTIER(s.Value())); w1.Redraw
  ELSE w2.sides := SHORT(ENTIER(s.Value())); w2.Redraw
  END
END Callback;

PROCEDURE OpenSlider(s: Sides);
BEGIN
  FlValuators.OpenHorSlider(s, 20, 370, 360, 25, "");
  s.SetBounds(2.0D0, 30.0D0);
  s.SetStep(1.0D0);
  s.SetValue(20.0D0)
END OpenSlider;

BEGIN
  NEW(w01); Fl.OpenWindow(w01, 420, 420, "Fl_Single_Window"); w01.SetBoxType(Fl.FlatBox);
  NEW(w1); Fl.OpenSingleWindowAt(w1, 10, 10, 400, 400, "Fl_Single_Window");
  w1.sides := 20;
  w1.SetResizable(w1);
  w1.SetBoxType(Fl.FlatBox); w1.SetColor(Fl.Black);
  NEW(slider0); OpenSlider(slider0);
  w1.End;
  w01.End;
  NEW(w02); Fl.OpenWindow(w02, 420, 420, "Fl_Double_Window"); w02.SetBoxType(Fl.FlatBox);
  NEW(w2); Fl.OpenDoubleWindowAt(w2, 10, 10, 400, 400, "Fl_Double_Window");
  w2.sides := 20;
  w2.SetResizable(w2);
  w2.SetBoxType(Fl.FlatBox); w2.SetColor(Fl.Black);
  NEW(slider1); OpenSlider(slider1);
  w2.End;
  w02.End;
  w01.Show;
  w1.Show;
  w02.Show;
  w2.Show;
  Fl.Run
END DoubleBuffer.
