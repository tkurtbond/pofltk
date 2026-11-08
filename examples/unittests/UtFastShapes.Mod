MODULE UtFastShapes; (* FLTK's test/unittest_fast_shapes.cxx in Oberon-2 *)

IMPORT Fl, FlDraw, Ut, UtGl;

CONST Label* = "Fast Shapes";

TYPE
  Page = POINTER TO RECORD (Fl.GroupDesc) END;
  Native = POINTER TO RECORD (Fl.WindowDesc) END;

(* The shapes, in w's own coordinates, as FLTK's draw_fast_shapes: green
   pixels that must show, red ones that must be covered, and the shape in
   black. *)
PROCEDURE Shapes(w: Fl.Widget);
  VAR a, b, i: INTEGER;
BEGIN
  a := 0; b := 0;
  FlDraw.SetColor(Fl.Green);
  FOR i := 0 TO 40 DO FlDraw.Point(a + i, b); FlDraw.Point(a + i, b + 20) END;
  FOR i := 0 TO 20 DO FlDraw.Point(a, b + i); FlDraw.Point(a + 40, b + i) END;
  FlDraw.SetColor(Fl.Red);
  FOR i := 1 TO 39 DO FlDraw.Point(a + i, b + 1); FlDraw.Point(a + i, b + 19) END;
  FOR i := 1 TO 19 DO FlDraw.Point(a + 1, b + i); FlDraw.Point(a + 39, b + i) END;
  FlDraw.SetColor(Fl.Black);
  FlDraw.RectF(a + 1, b + 1, 39, 19);
  INC(b, 24);
  FlDraw.SetColor(Fl.Green);
  FOR i := 0 TO 40 DO FlDraw.Point(a + i, b); FlDraw.Point(a + i, b + 20) END;
  FOR i := 0 TO 20 DO FlDraw.Point(a, b + i); FlDraw.Point(a + 40, b + i) END;
  FlDraw.SetColor(Fl.Green);
  FOR i := 2 TO 38 DO FlDraw.Point(a + i, b + 2); FlDraw.Point(a + i, b + 18) END;
  FOR i := 2 TO 18 DO FlDraw.Point(a + 2, b + i); FlDraw.Point(a + 38, b + i) END;
  FlDraw.SetColor(Fl.Red);
  FOR i := 1 TO 39 DO FlDraw.Point(a + i, b + 1); FlDraw.Point(a + i, b + 19) END;
  FOR i := 1 TO 19 DO FlDraw.Point(a + 1, b + i); FlDraw.Point(a + 39, b + i) END;
  FlDraw.SetColor(Fl.Black);
  FlDraw.Rect(a + 1, b + 1, 39, 19);
  INC(b, 24);
  FlDraw.SetColor(Fl.Green);
  FlDraw.Rect(a, b, 41, 21);
  FlDraw.Rect(a + 4, b + 4, 33, 13);
  FlDraw.SetColor(Fl.Red);
  FlDraw.Rect(a + 1, b + 1, 39, 19);
  FlDraw.Rect(a + 3, b + 3, 35, 15);
  FlDraw.SetColor(Fl.Black);
  FlDraw.LineStyle(FlDraw.Solid, 3);
  FlDraw.Rect(a + 2, b + 2, 37, 17);
  FlDraw.LineStyle(FlDraw.Solid, 1);
  INC(b, 24);
  FlDraw.SetColor(Fl.Green);
  FlDraw.Rect(a, b + 8, 41, 3);
  FlDraw.Rect(a + 45, b, 41, 3);
  FlDraw.Rect(a + 83, b, 3, 21);
  FlDraw.Rect(a + 90, b, 21, 3);
  FlDraw.Rect(a + 109, b, 3, 21);
  FlDraw.Rect(a + 109, b + 18, 21, 3);
  FlDraw.SetColor(Fl.Red);
  FlDraw.RectF(a + 1, b + 9, 39, 1);
  FlDraw.RectF(a + 46, b + 1, 39, 1);
  FlDraw.RectF(a + 84, b + 1, 1, 19);
  FlDraw.RectF(a + 91, b + 1, 20, 1);
  FlDraw.RectF(a + 110, b + 1, 1, 19);
  FlDraw.RectF(a + 110, b + 19, 19, 1);
  FlDraw.SetColor(Fl.Black);
  FlDraw.XYLine(a + 1, b + 9, a + 39);
  FlDraw.XYLine2(a + 46, b + 1, a + 84, b + 19);
  FlDraw.XYLine3(a + 91, b + 1, a + 110, b + 19, a + 128);
  INC(b, 24);
  FlDraw.SetColor(Fl.Green);
  FlDraw.Rect(a, b + 7, 41, 5);
  FlDraw.Rect(a + 45, b, 41, 5);
  FlDraw.Rect(a + 81, b, 5, 21);
  FlDraw.Rect(a + 90, b, 22, 5);
  FlDraw.Rect(a + 108, b, 5, 21);
  FlDraw.Rect(a + 108, b + 16, 22, 5);
  FlDraw.SetColor(Fl.Red);
  FlDraw.RectF(a + 1, b + 8, 39, 3);
  FlDraw.RectF(a + 46, b + 1, 39, 3);
  FlDraw.RectF(a + 82, b + 1, 3, 19);
  FlDraw.RectF(a + 91, b + 1, 20, 3);
  FlDraw.RectF(a + 109, b + 1, 3, 19);
  FlDraw.RectF(a + 109, b + 17, 20, 3);
  FlDraw.SetColor(Fl.Black);
  FlDraw.LineStyle(FlDraw.Solid, 3);
  FlDraw.XYLine(a + 1, b + 9, a + 39);
  FlDraw.XYLine2(a + 46, b + 2, a + 83, b + 19);
  FlDraw.XYLine3(a + 91, b + 2, a + 110, b + 18, a + 128);
  FlDraw.LineStyle(FlDraw.Solid, 1);
  INC(b, 24);
  FlDraw.SetColor(Fl.Green);
  FlDraw.Rect(a + 9, b, 3, 21);
  FlDraw.Rect(a + 45, b, 3, 21);
  FlDraw.Rect(a + 45, b + 18, 41, 3);
  FlDraw.Rect(a + 90, b, 3, 11);
  FlDraw.Rect(a + 90, b + 9, 40, 3);
  FlDraw.Rect(a + 127, b + 9, 3, 12);
  FlDraw.SetColor(Fl.Red);
  FlDraw.RectF(a + 10, b + 1, 1, 19);
  FlDraw.RectF(a + 46, b + 1, 1, 19);
  FlDraw.RectF(a + 46, b + 19, 39, 1);
  FlDraw.RectF(a + 91, b + 1, 1, 10);
  FlDraw.RectF(a + 91, b + 10, 38, 1);
  FlDraw.RectF(a + 128, b + 10, 1, 10);
  FlDraw.SetColor(Fl.Black);
  FlDraw.YXLine(a + 10, b + 1, b + 19);
  FlDraw.YXLine2(a + 46, b + 1, b + 19, a + 84);
  FlDraw.YXLine3(a + 91, b + 1, b + 10, a + 128, b + 19);
  INC(b, 24);
  FlDraw.SetColor(Fl.Green);
  FlDraw.Rect(a + 8, b, 5, 21);
  FlDraw.Rect(a + 45, b, 5, 21);
  FlDraw.Rect(a + 45, b + 16, 41, 5);
  FlDraw.Rect(a + 90, b, 5, 11);
  FlDraw.Rect(a + 90, b + 8, 40, 5);
  FlDraw.Rect(a + 125, b + 8, 5, 13);
  FlDraw.SetColor(Fl.Red);
  FlDraw.RectF(a + 9, b + 1, 3, 19);
  FlDraw.RectF(a + 46, b + 1, 3, 19);
  FlDraw.RectF(a + 46, b + 17, 39, 3);
  FlDraw.RectF(a + 91, b + 1, 3, 10);
  FlDraw.RectF(a + 91, b + 9, 38, 3);
  FlDraw.RectF(a + 126, b + 9, 3, 11);
  FlDraw.SetColor(Fl.Black);
  FlDraw.LineStyle(FlDraw.Solid, 3);
  FlDraw.YXLine(a + 10, b + 1, b + 19);
  FlDraw.YXLine2(a + 47, b + 1, b + 18, a + 84);
  FlDraw.YXLine3(a + 92, b + 1, b + 10, a + 127, b + 19);
  FlDraw.LineStyle(FlDraw.Solid, 1);
  INC(b, 24);
  FlDraw.SetColor(Fl.Green);
  FlDraw.Point(a, b); FlDraw.Point(a + 1, b); FlDraw.Point(a, b + 1);
  FlDraw.Point(a + 20, b + 20); FlDraw.Point(a + 19, b + 20); FlDraw.Point(a + 20, b + 19);
  FlDraw.SetColor(Fl.Red);
  FlDraw.Point(a + 1, b + 1); FlDraw.Point(a + 19, b + 19);
  FlDraw.SetColor(Fl.Black);
  FlDraw.Line(a + 1, b + 1, a + 19, b + 19);
  FlDraw.SetColor(Fl.Green);
  FlDraw.Point(a + 25 + 1, b); FlDraw.Point(a + 25, b + 1); FlDraw.Point(a + 25 + 4, b); FlDraw.Point(a + 25, b + 4);
  FlDraw.Point(a + 25 + 20, b + 19); FlDraw.Point(a + 25 + 19, b + 20); FlDraw.Point(a + 25 + 16, b + 20); FlDraw.Point(a + 25 + 20, b + 16);
  FlDraw.SetColor(Fl.Red);
  FlDraw.Point(a + 25 + 2, b + 2); FlDraw.Point(a + 25 + 18, b + 18);
  FlDraw.SetColor(Fl.Black);
  FlDraw.LineStyle(FlDraw.Solid, 5);
  FlDraw.Line(a + 25 + 1, b + 1, a + 25 + 19, b + 19);
  FlDraw.Line3(a + 50 + 1, b + 1, a + 50 + 20, b + 20, a + 50 + 39, b + 1);
  FlDraw.LineStyle(FlDraw.Solid, 1)
END Shapes;

PROCEDURE (w: Native) Draw*;
BEGIN w.Draw^; Shapes(w)
END Draw;

PROCEDURE Marks(a, b, w: INTEGER; gl: BOOLEAN);
  VAR n: ARRAY 3 OF CHAR;
  PROCEDURE Name(c: CHAR);
  BEGIN n[0] := c; IF gl THEN n[1] := "a" ELSE n[1] := 0X END; n[2] := 0X
  END Name;
BEGIN
  Name("1"); Ut.Mark(a, b, w, n, "Testing filled rectangle alignment.||This draws a black rectangle, surrounded by a green frame.||If green pixels are missing, filled rectangles draw too big (see fl_rectf).||If red pixels are showing, filled rectangles are drawn too small.");
  INC(b, 24);
  Name("2"); Ut.Mark(a, b, w, n, "Testing rectangle frame alignment.||This draws a black frame, surrounded on the inside and outside by a green frame.||If green pixels are missing or red pixels are showing, rectangular frame drawing schould be adjusted (see fl_rect).||If red pixels show in the corners of the frame in hidpi mode, line endings should be adjusted.");
  INC(b, 24);
  Name("3"); Ut.Mark(a, b, w, n, "Testing scaled frame alignment.||This draws a 3 units wide black frame, surrounded on the inside and outside by a green frame.||If green pixels are missing or red pixels are showing, line width schould be adjusted (see fl_line_style).||If red pixels show in the corners of the frame in hidpi mode, line endings should be adjusted.");
  INC(b, 24);
  Name("4"); Ut.Mark(a, b, w, n, "Testing fl_xyline.||This draws 3 versions of fl_xyline surronded with a green outline.||If green pixels are missing or red pixels are showing, fl_xyline must be adjusted.");
  INC(b, 48);
  Name("5"); Ut.Mark(a, b, w, n, "Testing fl_yxline.||This draws 3 versions of fl_yxline surronded with a green outline.||If green pixels are missing or red pixels are showing, fl_yxline must be adjusted.");
  INC(b, 48);
  Name("6"); Ut.Mark(a, b, w, n, 'Testing fl_line(int...).||This draws 2 lines at differnet widths, and one connected line.||Green and red pixels mark the beginning and end of single lines.The line caps should be flat, the joints should be of type "miter".')
END Marks;

PROCEDURE Create*(): Fl.Widget;
  VAR p: Page; a, b: INTEGER; win: Native; gl: Fl.Widget;
BEGIN
  NEW(p);
  Ut.OpenPage(p, "Testing FLTK fast shape calls.|These calls draw horizontal and vertical lines, frames, and rectangles.||No red pixels should be visible. If you see bright red lines, or if parts of the green frames are hidden, drawing alignment is off.");
  a := Ut.X + 16; b := Ut.Y + 34;
  Ut.Heading(a, b - 24, "native");
  NEW(win); Fl.OpenWindowAt(win, a + 23, b - 1, 200, 200, "");
  win.SetBoxType(Fl.FlatBox); win.End;
  Marks(a, b, 18, FALSE);
  IF UtGl.Have THEN
    a := Ut.X + 16 + 250; b := Ut.Y + 34;
    Ut.Heading(a, b - 24, "OpenGL");
    gl := UtGl.Open(a + 31, b - 1, 200, 200, Shapes, FALSE);
    Marks(a, b, 26, TRUE)
  END;
  Ut.Corner(p);
  p.End;
  RETURN p
END Create;

END UtFastShapes.
