MODULE UtCircles; (* FLTK's test/unittest_circles.cxx in Oberon-2 *)

IMPORT Fl, FlDraw, MathL, Ut, UtGl;

CONST Label* = "Circles and Arcs";

TYPE
  Page = POINTER TO RECORD (Fl.GroupDesc) END;
  Native = POINTER TO RECORD (Fl.WindowDesc) END;

(* x, which is never negative here, cut to an integer, as C's int() *)
PROCEDURE Int(x: LONGREAL): INTEGER;
BEGIN RETURN SHORT(ENTIER(x))
END Int;

(* An arc of points, as FLTK's arc: where fl_arc should draw. *)
PROCEDURE Arc(xi, yi, w, h: INTEGER; a1, a2: LONGREAL);
  VAR rx, ry, x, y, circ, step: LONGREAL; i, segs: INTEGER;
BEGIN
  IF a2 > a1 THEN
    rx := w / 2.0D0; ry := h / 2.0D0;
    x := xi + rx + 0.5D0; y := yi + ry + 0.5D0;
    circ := MathL.pi * 0.5D0 * (rx + ry);
    segs := Int(circ * (a2 - a1) / 100);
    IF segs < 3 THEN segs := 3 END;
    a1 := a1 / 180 * MathL.pi; a2 := a2 / 180 * MathL.pi;
    step := (a2 - a1) / segs;
    FlDraw.Point(Int(x + MathL.cos(a1) * rx), Int(y - MathL.sin(a1) * ry));
    FOR i := segs TO 1 BY -1 DO
      a1 := a1 + step;
      FlDraw.Point(Int(x + MathL.cos(a1) * rx), Int(y - MathL.sin(a1) * ry))
    END
  END
END Arc;

PROCEDURE Circles(win: Fl.Widget);
  VAR a, b, w, h: INTEGER;
BEGIN
  a := 0; b := 0; w := 40; h := 40;
  (* 1: a circle and a filled circle *)
  FlDraw.SetColor(Fl.Red);
  Arc(a + 1, b + 1, w - 2, h - 2, 0.0D0, 360.0D0);
  FlDraw.SetColor(Fl.Green);
  Arc(a, b, w, h, 0.0D0, 360.0D0);
  Arc(a + 2, b + 2, w - 4, h - 4, 0.0D0, 360.0D0);
  FlDraw.SetColor(Fl.Black);
  FlDraw.Arc(a + 1, b + 1, w - 1, h - 1, 0.0D0, 360.0D0);
  FlDraw.SetColor(Fl.Red);
  Arc(a + 1 + 50, b + 1, w - 2, h - 2, 0.0D0, 360.0D0);
  FlDraw.SetColor(Fl.Green);
  Arc(a + 50, b, w, h, 0.0D0, 360.0D0);
  FlDraw.SetColor(Fl.Black);
  FlDraw.Pie(a + 1 + 50, b + 1, w - 1, h - 1, 0.0D0, 360.0D0);
  INC(b, 44);
  (* 2: arcs and pies *)
  FlDraw.SetColor(Fl.Red);
  Arc(a + 1, b + 1, w - 2, h - 2, 45.0D0, 315.0D0);
  FlDraw.SetColor(Fl.Green);
  Arc(a, b, w, h, 45.0D0, 315.0D0);
  Arc(a + 2, b + 2, w - 4, h - 4, 45.0D0, 315.0D0);
  FlDraw.SetColor(Fl.Black);
  FlDraw.Arc(a + 1, b + 1, w - 1, h - 1, 45.0D0, 315.0D0);
  FlDraw.SetColor(Fl.Red);
  Arc(a + 1 + 50, b + 1, w - 2, h - 2, 45.0D0, 315.0D0);
  FlDraw.Line(a + 50 + 20, b + 20, a + 50 + 20 + 14, b + 20 - 14);
  FlDraw.Line(a + 50 + 20, b + 20, a + 50 + 20 + 14, b + 20 + 14);
  FlDraw.SetColor(Fl.Green);
  Arc(a + 50, b, w, h, 45.0D0, 315.0D0);
  FlDraw.Line(a + 50 + 21, b + 20, a + 50 + 21 + 14, b + 20 - 14);
  FlDraw.Line(a + 50 + 21, b + 20, a + 50 + 21 + 14, b + 20 + 14);
  FlDraw.SetColor(Fl.Black);
  FlDraw.Pie(a + 1 + 50, b + 1, w - 1, h - 1, 45.0D0, 315.0D0)
END Circles;

PROCEDURE (w: Native) Draw*;
BEGIN w.Draw^; Circles(w)
END Draw;

PROCEDURE Create*(): Fl.Widget;
  VAR p: Page; a, b: INTEGER; win: Native; gl: Fl.Widget;
BEGIN
  NEW(p);
  Ut.OpenPage(p, "Testing fast circle, arc, and pie drawing||No red lines should be visible. The green outlines should not be overwritten by circle drawings.");
  a := Ut.X + 16; b := Ut.Y + 34;
  Ut.Heading(a, b - 24, "native");
  NEW(win); Fl.OpenWindowAt(win, a + 23, b - 1, 200, 200, "");
  win.SetBoxType(Fl.FlatBox); win.End;
  Ut.Mark(a, b, 18, "1", "Testing circle alignment.||This draws a black circle and a black disc, surrounded by a green frame.||If green pixels are missing, circle drawing must be adjusted (see fl_arc, fl_pie).||If red pixels are showing, line width or aligment may be off.");
  INC(b, 44);
  Ut.Mark(a, b, 18, "2", "Testing arc and pie drawing.||This draws a black frame, surrounded on the inside and outside by a green frame.||If green pixels are missing or red pixels are showing, rectangular frame drawing schould be adjusted (see fl_rect).||If red pixels show in the corners of the frame in hidpi mode, line endings should be adjusted.");
  IF UtGl.Have THEN
    a := Ut.X + 16 + 250; b := Ut.Y + 34;
    Ut.Heading(a, b - 24, "OpenGL");
    gl := UtGl.Open(a + 31, b - 1, 200, 200, Circles, TRUE);
    Ut.Mark(a, b, 26, "1a", "Testing circle alignment.||This draws a black circle and a black disc, surrounded by a green frame.||If green pixels are missing, circle drawing must be adjusted (see fl_arc, fl_pie).||If red pixels are showing, line width or aligment may be off.");
    INC(b, 44);
    Ut.Mark(a, b, 26, "2a", "Testing arc and pie drawing.||This draws a black frame, surrounded on the inside and outside by a green frame.||If green pixels are missing or red pixels are showing, rectangular frame drawing schould be adjusted (see fl_rect).||If red pixels show in the corners of the frame in hidpi mode, line endings should be adjusted.")
  END;
  Ut.Corner(p);
  p.End;
  RETURN p
END Create;

END UtCircles.
