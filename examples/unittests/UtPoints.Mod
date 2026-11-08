MODULE UtPoints; (* FLTK's test/unittest_points.cxx in Oberon-2 *)

IMPORT Fl, FlDraw, Ut, UtGl;

CONST Label* = "Drawing Points";

TYPE
  Page = POINTER TO RECORD (Fl.GroupDesc) END;
  (* the native window of test 3, drawn in its own coordinates *)
  Native = POINTER TO RECORD (Fl.WindowDesc) END;

VAR lut: ARRAY 3 OF INTEGER;  (* test 2's colors *)

PROCEDURE (w: Native) Draw*;
  VAR i: INTEGER;
BEGIN
  FlDraw.SetColor(Fl.White); FlDraw.RectF(0, 0, 10, 10);
  FlDraw.SetColor(Fl.Black);
  FOR i := 0 TO 9 DO FlDraw.Point(i, 0); FlDraw.Point(i, 9) END;
  FOR i := 0 TO 9 DO FlDraw.Point(0, i); FlDraw.Point(9, i) END
END Draw;

(* Tests 1 and 2: a checker board, and the three colors *)
PROCEDURE Checks(a, b: INTEGER);
  VAR i, j, n, yy: INTEGER;
BEGIN
  FlDraw.SetColor(Fl.White); FlDraw.RectF(a + 24, b + 9 - 5, 10, 10);
  FlDraw.SetColor(Fl.Black);
  FOR i := 0 TO 7 DO
    FOR j := 0 TO 7 DO
      IF ODD(i + j) THEN FlDraw.Point(a + i + 24 + 1, b + j + 9 - 5 + 1) END
    END
  END;
  FOR n := 0 TO 2 DO
    yy := b + 9 - 5 + 24 + 16 * n;
    FlDraw.SetColor(Fl.White); FlDraw.RectF(a + 24, yy, 10, 10);
    FlDraw.SetColor(lut[n]);
    FOR i := 0 TO 7 DO
      FOR j := 0 TO 7 DO FlDraw.Point(a + i + 24 + 1, yy + j + 1) END
    END
  END
END Checks;

(* A 10 by 10 black frame at xx, yy around white, from lo to hi in from
   the frame's edge. *)
PROCEDURE Frame(xx, yy, lo, hi: INTEGER);
  VAR i, j: INTEGER;
BEGIN
  FlDraw.SetColor(Fl.Black);
  FOR i := lo TO 9 - lo DO
    FlDraw.Point(xx + i, yy + lo); FlDraw.Point(xx + i, yy + 9 - lo)
  END;
  FOR i := lo TO 9 - lo DO
    FlDraw.Point(xx + lo, yy + i); FlDraw.Point(xx + 9 - lo, yy + i)
  END;
  FlDraw.SetColor(Fl.White);
  FOR i := 0 TO hi DO
    FOR j := 0 TO hi DO FlDraw.Point(xx + i + 1 + lo, yy + j + 1 + lo) END
  END
END Frame;

PROCEDURE GlPaint(w: Fl.Widget);
  VAR a, b, i, xx, yy: INTEGER;
BEGIN
  a := -24; b := 5 - 9;
  Checks(a, b);
  (* Test 3a: pixel alignment inside windows *)
  xx := a + 24; yy := b + 2 * 24 + 2 * 16 + 9 - 5;
  FlDraw.SetColor(Fl.Red);
  FOR i := 0 TO 9 DO FlDraw.Point(xx - 1, yy + i); FlDraw.Point(xx + 10, yy + i) END;
  Frame(xx, yy, 0, 7);
  (* Test 4a: pixel clipping *)
  xx := a + 24; yy := b + 3 * 24 + 2 * 16 + 9 - 5;
  FlDraw.PushClip(xx + 1, yy + 1, 9, 9);
  FlDraw.SetColor(Fl.Red);
  FOR i := 0 TO 9 DO FlDraw.Point(xx + i, yy); FlDraw.Point(xx + i, yy + 9) END;
  FOR i := 0 TO 9 DO FlDraw.Point(xx, yy + i); FlDraw.Point(xx + 9, yy + i) END;
  Frame(xx, yy, 1, 5);
  FlDraw.PopClip
END GlPaint;

PROCEDURE (p: Page) Draw*;
  VAR a, b, i, xx, yy: INTEGER;
BEGIN
  p.Draw^;
  a := p.X() + 16; b := p.Y() + 34;
  Checks(a, b);
  (* Test 3 is the native window's. Test 4: pixel clipping *)
  xx := a + 24; yy := b + 3 * 24 + 2 * 16 + 9 - 5;
  FlDraw.PushClip(xx, yy, 10, 10);
  FlDraw.SetColor(Fl.Red);
  FOR i := -1 TO 10 DO FlDraw.Point(xx + i, yy - 1); FlDraw.Point(xx + i, yy + 10) END;
  FOR i := -1 TO 10 DO FlDraw.Point(xx - 1, yy + i); FlDraw.Point(xx + 10, yy + i) END;
  Frame(xx, yy, 0, 7);
  FlDraw.PopClip;
  (* Test 3a: pixel alignment inside the OpenGL window *)
  IF UtGl.Have THEN
    xx := a + 24 + 108; yy := b + 2 * 24 + 2 * 16 + 9 - 5;
    FlDraw.SetColor(Fl.Black);
    FOR i := -4 TO 13 DO FlDraw.Point(xx + i, yy); FlDraw.Point(xx + i, yy + 9) END
  END
END Draw;

PROCEDURE Create*(): Fl.Widget;
  VAR p: Page; a, b: INTEGER; win: Native; gl: Fl.Widget;
BEGIN
  NEW(p); Ut.OpenPage(p, "Testing the fl_point call.");
  a := Ut.X + 16; b := Ut.Y + 34;
  Ut.Heading(a, b - 24, "native");
  Ut.Mark(a, b, 18, "1", "Testing pixel size and antialiasing.||This draws a checker board of black points on a white background.||Black and white points should be the same size of one unit (1 pixel in regular mode, 2x2 pixels in hidpi mode).If black points are smaller than white in hidpi mode, point size must be increased.||Points should not be blurry. Antialiasing should be switched of and the point coordinates should be centered on the pixel(s).||If parts of the white border are missing, the size of fl_rect should be adjusted.");
  Ut.Mark(a, b + 24, 18, "2", "Testing pixels color.||This draws three squares in red, green, and blue.||If the order of colors is different, the byte order when writing into the pixel buffer should be fixed.");
  Ut.Mark(a, b + 2 * 24 + 2 * 16, 18, "3", "Testing pixels alignment in windows.||This draws a black frame around a white square.||If parts of the black frame are clipped by the window and not visible, pixel offsets must be adjusted.");
  NEW(win); Fl.OpenWindowAt(win, a + 24, b + 2 * 24 + 2 * 16 + 9 - 5, 10, 10, "");
  win.End;
  Ut.Mark(a, b + 3 * 24 + 2 * 16, 18, "4", "Testing pixels clipping.||This draws a black frame around a white square.||If red pixels are visible or black pixels are missing, graphics clipping is misaligned.");
  INC(a, 100);
  IF UtGl.Have THEN
    Ut.Heading(a, b - 24, "OpenGL");
    Ut.Mark(a, b, 26, "1a", "Testing pixel size and antialiasing.||This draws a checker board of black points on a white background.||Black and white points should be the same size of one unit (1 pixel in regular mode, 2x2 pixels in hidpi mode).If black points are smaller than white in hidpi mode, point size must be increased.||Points should not be blurry. Antialiasing should be switched of and the point coordinates should be centered on the pixel(s).||If parts of the white border are missing, the size of fl_rect should be adjusted.");
    Ut.Mark(a, b + 24, 26, "2a", "Testing pixels color.||This draws three squares in red, green, and blue.||If the order of colors is different, the color component order when writing into the pixel buffer should be fixed.");
    Ut.Mark(a, b + 2 * 24 + 2 * 16, 26, "3a", "Testing pixels alignment in windows.||This draws a black frame around a white square, extending to both sides.||If parts of the black frame are clipped by the window and not visible, pixel offsets must be adjusted horizontally.||If the horizontal lines are misaligned, vertical pixel offset should be adjusted.");
    Ut.Mark(a, b + 3 * 24 + 2 * 16, 26, "4a", "Testing pixels clipping.||This draws a black frame around a white square. The square is slightly smaller.||If red pixels are visible or black pixels are missing, graphics clipping is misaligned.");
    gl := UtGl.Open(a + 24 + 8, b + 9 - 5, 10, 4 * 24 + 2 * 16, GlPaint, TRUE)
  END;
  Ut.Corner(p);
  p.End;
  RETURN p
END Create;

BEGIN
  lut[0] := Fl.Red; lut[1] := Fl.Green; lut[2] := Fl.Blue
END UtPoints.
