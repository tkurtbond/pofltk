MODULE TestDrawMore; (* FlDraw beyond TestDraw, and what FlImages adds to it *)

(* As in TestDraw, a box's Draw is captured and its pixels checked, except
   for what needs a window shown: Scroll, the overlay and CaptureWindow. *)

IMPORT Fl, FlDraw, FlImages, FlTest, Check;

CONST Size = 60;

TYPE
  Job = PROCEDURE (c: Fl.Box);
  Canvas = POINTER TO RECORD (Fl.BoxDesc) END;
  Shown = POINTER TO RECORD (Fl.WindowDesc) END;
  (* fills what it is asked to in its color, and counts its calls *)
  Part = POINTER TO RECORD (FlDraw.AreaDesc) color, calls, w, h: INTEGER END;
  (* rows of 3 bytes a pixel, 2 wide: x red, y green; or of 1, gray x *)
  Rows = POINTER TO RECORD (FlDraw.ImageSourceDesc)
    calls: INTEGER
  END;
  Gray = POINTER TO RECORD (FlDraw.ImageSourceDesc) END;

VAR
  win: Fl.Window; canvas: Canvas; job: Job;
  red, green, blue, white, black, gray: INTEGER;
  rgb: ARRAY 12 OF CHAR;
  rgba: ARRAY 16 OF CHAR;
  grays: ARRAY 4 OF CHAR;
  pixmap: ARRAY 4 OF ARRAY 16 OF CHAR;
  scale, x0, y0, dx0, dy0, x1, y1, x2, y2, x3: LONGREAL;
  ok: BOOLEAN;
  smooth, canSmooth: BOOLEAN;
  part: Part; rows: Rows; grayRows: Gray;
  off: FlDraw.Offscreen;
  shown: Shown;

PROCEDURE (c: Canvas) Draw*;
BEGIN
  FlDraw.SetColor(Fl.White); FlDraw.RectF(0, 0, Size, Size);
  job(c)
END Draw;

(* a symbol: all of its box, black *)
PROCEDURE Square(color: INTEGER);
BEGIN
  FlDraw.SetColor(Fl.Black);
  FlDraw.BeginPolygon;
  FlDraw.Vertex(-1.0D0, -1.0D0); FlDraw.Vertex(1.0D0, -1.0D0);
  FlDraw.Vertex(1.0D0, 1.0D0); FlDraw.Vertex(-1.0D0, 1.0D0);
  FlDraw.EndPolygon
END Square;

PROCEDURE (p: Part) Draw*(x, y, w, h: INTEGER);
BEGIN
  INC(p.calls); p.w := w; p.h := h;
  FlDraw.SetColor(p.color); FlDraw.RectF(x, y, w, h)
END Draw;

PROCEDURE (s: Rows) Line*(x, y, w: INTEGER; VAR buf: ARRAY OF CHAR);
  VAR i: INTEGER;
BEGIN
  INC(s.calls);
  FOR i := 0 TO w - 1 DO
    buf[i * 3] := CHR((x + i) * 255); buf[i * 3 + 1] := CHR(y * 255); buf[i * 3 + 2] := 0X
  END
END Line;

PROCEDURE (s: Gray) Line*(x, y, w: INTEGER; VAR buf: ARRAY OF CHAR);
  VAR i: INTEGER;
BEGIN
  FOR i := 0 TO w - 1 DO buf[i] := CHR((x + i) * 255) END
END Line;

PROCEDURE Matrices(c: Fl.Box);
BEGIN
  FlDraw.PushMatrix;
  FlDraw.LoadIdentity; FlDraw.Translate(10.0D0, 20.0D0);
  x0 := FlDraw.TransformX(1.0D0, 2.0D0); y0 := FlDraw.TransformY(1.0D0, 2.0D0);
  dx0 := FlDraw.TransformDX(1.0D0, 2.0D0); dy0 := FlDraw.TransformDY(1.0D0, 2.0D0);
  FlDraw.MultMatrix(2.0D0, 0.0D0, 0.0D0, 3.0D0, 0.0D0, 0.0D0);
  x1 := FlDraw.TransformX(1.0D0, 2.0D0); y1 := FlDraw.TransformY(1.0D0, 2.0D0);
  FlDraw.LoadMatrix(1.0D0, 0.0D0, 0.0D0, 1.0D0, 5.0D0, 6.0D0);
  x2 := FlDraw.TransformX(0.0D0, 0.0D0); y2 := FlDraw.TransformY(0.0D0, 0.0D0);
  (* a transformed vertex doesn't go through the matrix *)
  FlDraw.SetColor(Fl.Black);
  FlDraw.BeginPolygon;
  FlDraw.TransformedVertex(10.0D0, 10.0D0); FlDraw.TransformedVertex(20.0D0, 10.0D0);
  FlDraw.TransformedVertex(20.0D0, 20.0D0); FlDraw.TransformedVertex(10.0D0, 20.0D0);
  FlDraw.EndPolygon;
  FlDraw.PopMatrix;
  x3 := FlDraw.TransformX(0.0D0, 0.0D0)
END Matrices;

PROCEDURE Scales(c: Fl.Box);
BEGIN
  scale := FlDraw.OverrideScale();
  FlDraw.SetColor(Fl.Black); FlDraw.RectF(5, 5, 5, 5);
  FlDraw.RestoreScale(scale)
END Scales;

PROCEDURE Shapes(c: Fl.Box);
BEGIN
  FlDraw.SetColor(Fl.Black);
  FlDraw.RoundedRectF(5, 5, 20, 20, 5);
  FlDraw.RoundedRect(30, 5, 20, 20, 5);
  FlDraw.DrawCircle(5, 30, 12, Fl.Black);
  FlDraw.DrawRadio(30, 30, 12, Fl.Black)
END Shapes;

(* Sizes no one should use: nothing to check but that they do no harm. *)
PROCEDURE OddShapes(c: Fl.Box);
BEGIN
  FlDraw.SetColor(Fl.Black);
  FlDraw.RoundedRect(0, 0, 0, 0, 3); FlDraw.RoundedRectF(0, 0, 3, 3, -2);
  FlDraw.RoundedRectF(0, 0, -3, 3, 50);
  FlDraw.DrawCircle(0, 0, 0, Fl.Black); FlDraw.DrawCircle(0, 0, -3, Fl.Black);
  FlDraw.DrawRadio(0, 0, 0, Fl.Black); FlDraw.DrawRadio(0, 0, -3, Fl.Black)
END OddShapes;

PROCEDURE Arrows(c: Fl.Box);
  VAR kind, orient, x: INTEGER;
BEGIN
  x := 0;
  FOR kind := FlDraw.ArrowSingle TO FlDraw.ArrowReturn DO
    FOR orient := FlDraw.OrientRight TO FlDraw.OrientSE DO
      FlDraw.DrawArrow(x, kind * 2, 3, 3, kind, orient, Fl.Black)
    END;
    x := x + 3
  END;
  FlDraw.DrawArrow(10, 10, 40, 40, FlDraw.ArrowSingle, FlDraw.OrientRight, Fl.Black)
END Arrows;

PROCEDURE Checked(c: Fl.Box);
BEGIN FlDraw.DrawCheck(10, 10, 30, 30, Fl.Black)
END Checked;

PROCEDURE Focused(c: Fl.Box);
BEGIN FlDraw.DrawBoxFocus(Fl.FlatBox, 5, 5, 40, 40, Fl.Black, Fl.Red)
END Focused;

PROCEDURE Frames(c: Fl.Box);
BEGIN
  FlDraw.Frame("AAAAXXXX", 5, 5, 20, 20);
  FlDraw.Frame2("AAXX", 30, 5, 20, 20);
  FlDraw.Frame("", 0, 0, 5, 5)
END Frames;

PROCEDURE Symbols(c: Fl.Box);
BEGIN
  ok := FlDraw.DrawSymbol("@tdmSquare", 10, 10, 20, 20, Fl.Red)
END Symbols;

PROCEDURE Texts(c: Fl.Box);
BEGIN
  FlDraw.SetFont(Fl.Courier, 14); FlDraw.SetColor(Fl.Black);
  FlDraw.TextRotated(90, "MMM", 20, 50)
END Texts;

PROCEDURE RightToLeft(c: Fl.Box);
BEGIN
  FlDraw.SetFont(Fl.Courier, 14); FlDraw.SetColor(Fl.Black);
  FlDraw.RightToLeft("MMM", 40, 30)
END RightToLeft;

(* the rest of the Draws below draw an image at 5, 5 by each way of laying
   it out *)

PROCEDURE Plain(c: Fl.Box);
BEGIN FlDraw.DrawImage(rgb, 0, 5, 5, 2, 2, 3, 0)
END Plain;

PROCEDURE Mirrored(c: Fl.Box);
BEGIN FlDraw.DrawImage(rgb, 3, 5, 5, 2, 2, -3, 6)
END Mirrored;

PROCEDURE BottomUp(c: Fl.Box);
BEGIN FlDraw.DrawImage(rgb, 6, 5, 5, 2, 2, 3, -6)
END BottomUp;

PROCEDURE FourBytes(c: Fl.Box);
BEGIN FlDraw.DrawImage(rgba, 0, 5, 5, 2, 2, 4, 0)
END FourBytes;

PROCEDURE Grays(c: Fl.Box);
BEGIN FlDraw.DrawImageMono(grays, 0, 5, 5, 2, 2, 1, 0)
END Grays;

PROCEDURE Skipping(c: Fl.Box);
BEGIN
  FlDraw.DrawImageMono(rgb, 0, 5, 5, 2, 2, 3, 0);
  FlDraw.DrawImage(rgb, 0, 0, 0, 0, 2, 3, 0);
  FlDraw.DrawImage(rgb, 0, 0, 0, 2, -1, 3, 0)
END Skipping;

PROCEDURE Lines(c: Fl.Box);
BEGIN FlDraw.DrawImageLines(rows, 5, 5, 2, 2, 3)
END Lines;

PROCEDURE MonoLines(c: Fl.Box);
BEGIN FlDraw.DrawImageMonoLines(grayRows, 5, 5, 2, 2, 1)
END MonoLines;

PROCEDURE Pixmaps(c: Fl.Box);
BEGIN
  ok := FlImages.DrawPixmap(pixmap, 4, 5, 5, Fl.White)
END Pixmaps;

PROCEDURE Copied(c: Fl.Box);
BEGIN off.Copy(5, 5, 10, 10, 10, 0)
END Copied;

PROCEDURE Scrolled(c: Fl.Box);
BEGIN FlDraw.Scroll(5, 5, 10, 10, 2, 0, part)
END Scrolled;

PROCEDURE Unscrolled(c: Fl.Box);
BEGIN FlDraw.Scroll(5, 5, 10, 10, 0, 0, part)
END Unscrolled;

PROCEDURE Smoothing(c: Fl.Box);
BEGIN
  smooth := FlDraw.Antialias();
  FlDraw.SetAntialias(FALSE); canSmooth := FlDraw.Antialias();
  FlDraw.SetAntialias(TRUE)
END Smoothing;

PROCEDURE Bare(c: Fl.Box);
BEGIN
END Bare;

PROCEDURE Run(j: Job): BOOLEAN;
BEGIN job := j; RETURN FlTest.Capture(canvas)
END Run;

(* The pixels not white in the capture. *)
PROCEDURE Ink(): INTEGER;
  VAR x, y, n: INTEGER;
BEGIN
  n := 0;
  FOR y := 0 TO Size - 1 DO
    FOR x := 0 TO Size - 1 DO
      IF FlTest.Pixel(x, y) # white THEN INC(n) END
    END
  END;
  RETURN n
END Ink;

(* How many separate runs of ink row y has in the capture. *)
PROCEDURE Runs(y: INTEGER): INTEGER;
  VAR x, n: INTEGER; before: BOOLEAN;
BEGIN
  n := 0; before := FALSE;
  FOR x := 0 TO Size - 1 DO
    IF FlTest.Pixel(x, y) # white THEN
      IF ~before THEN INC(n) END;
      before := TRUE
    ELSE before := FALSE
    END
  END;
  RETURN n
END Runs;

(* Lines 50 long, from y 10 down: dashes 5 long and 5 apart, a pattern
   its 0 ends, no pattern, the first pattern at width 3, and back to no
   pattern with one of MaxDashes lengths drawn between. *)
PROCEDURE Dashes(c: Fl.Box);
  VAR d: ARRAY 3 OF INTEGER; none: ARRAY 1 OF INTEGER; all: ARRAY 300 OF INTEGER; i: INTEGER;
BEGIN
  FlDraw.SetColor(Fl.White); FlDraw.RectF(0, 0, Size, Size);
  FlDraw.SetColor(Fl.Black);
  d[0] := 5; d[1] := 5; d[2] := 5;
  FlDraw.LineStyleDashes(FlDraw.Solid, 1, d);
  FlDraw.XYLine(5, 10, 54);
  d[0] := 10; d[1] := 20; d[2] := 0;
  FlDraw.LineStyleDashes(FlDraw.Solid, 1, d);
  FlDraw.XYLine(5, 20, 54);
  none[0] := 0;
  FlDraw.LineStyleDashes(FlDraw.Solid, 1, none);
  FlDraw.XYLine(5, 30, 54);
  d[0] := 5; d[1] := 5; d[2] := 0;
  FlDraw.LineStyleDashes(FlDraw.Solid, 3, d);
  FlDraw.XYLine(5, 40, 54);
  FOR i := 0 TO LEN(all) - 1 DO all[i] := 0 END;
  FOR i := 0 TO FlDraw.MaxDashes - 1 DO all[i] := 1 + i MOD 127 END;
  FlDraw.LineStyleDashes(FlDraw.Solid, 1, all);
  FlDraw.LineStyle(FlDraw.Solid, 0);
  FlDraw.XYLine(5, 50, 54)
END Dashes;

PROCEDURE Four(a, b, c, d: INTEGER): BOOLEAN;
BEGIN
  RETURN (FlTest.Pixel(5, 5) = a) & (FlTest.Pixel(6, 5) = b)
    & (FlTest.Pixel(5, 6) = c) & (FlTest.Pixel(6, 6) = d)
END Four;

(* Four bytes into s, which Oberon has no way to write as a literal. *)
PROCEDURE Set(VAR s: ARRAY OF CHAR; a, b, c, d: CHAR);
BEGIN s[0] := a; s[1] := b; s[2] := c; s[3] := d; s[4] := 0X
END Set;

PROCEDURE TestShapes;
BEGIN
  Check.Check(Run(Matrices), "capture matrices");
  Check.Check((x0 = 11.0D0) & (y0 = 22.0D0), "TransformX and TransformY after a translation");
  Check.Check((dx0 = 1.0D0) & (dy0 = 2.0D0), "TransformDX and TransformDY leave it out");
  Check.Check((x1 = 12.0D0) & (y1 = 26.0D0), "MultMatrix goes before what was there");
  Check.Check((x2 = 5.0D0) & (y2 = 6.0D0), "LoadMatrix replaces it");
  Check.Check(x3 = 0.0D0, "PopMatrix takes back LoadIdentity");
  Check.Check((FlTest.Pixel(15, 15) = black) & (FlTest.Pixel(25, 25) = white),
    "TransformedVertex goes round the matrix");
  FlTest.Release;

  Check.Check(Run(Scales), "capture an override of the scale");
  Check.Check(scale > 0.0D0, "OverrideScale gives the scale");
  Check.Check(FlTest.Pixel(7, 7) = black, "and a rectangle is drawn under it");
  FlTest.Release;

  Check.Check(Run(Shapes), "capture rounded rectangles and circles");
  Check.Check((FlTest.Pixel(15, 15) = black) & (FlTest.Pixel(5, 5) # black),
    "RoundedRectF fills all but its corners");
  Check.Check((FlTest.Pixel(40, 5) = black) & (FlTest.Pixel(40, 15) = white),
    "RoundedRect is only its line");
  Check.Check((FlTest.Pixel(11, 36) = black) & (FlTest.Pixel(5, 30) # black), "DrawCircle");
  Check.Check((FlTest.Pixel(36, 36) = black) & (FlTest.Pixel(30, 30) # black), "DrawRadio");
  FlTest.Release;
  Check.Check(Run(OddShapes), "capture shapes of no size or less");
  FlTest.Release;
  Check.Check(Run(Dashes), "capture dashed lines");
  Check.Check(Runs(10) = 5, "LineStyleDashes: its pattern");
  Check.Check(Runs(20) = 2, "a 0 ends it");
  Check.Check(Runs(30) = 1, "no lengths is a solid line");
  Check.Check(Runs(40) = 5, "dashes don't grow with the width");
  Check.Check(Runs(50) = 1, "the longest pattern, then LineStyle");
  FlTest.Release;

  Check.Check(Run(Arrows), "capture arrows of every kind and direction");
  Check.Check(Ink() > 10, "they draw");
  FlTest.Release;
  Check.Check(Run(Checked), "capture a check mark");
  Check.Check(Ink() > 10, "it draws");
  FlTest.Release;
  Check.Check(Run(Focused), "capture a box with a focus box");
  Check.Check(Ink() > 10, "DrawBoxFocus draws its focus box");
  Check.Check(FlTest.Pixel(20, 20) = white, "and no box");
  FlTest.Release;
  Check.Check(Run(Frames), "capture frames");
  Check.Check((FlTest.Pixel(5, 10) = black) & (FlTest.Pixel(6, 10) = white), "Frame's lines, out to in");
  Check.Check(FlTest.Pixel(30, 10) = white, "Frame2's first line is the bottom, in order");
  Check.Check(FlTest.Pixel(40, 24) = black, "Frame2's bottom");
  FlTest.Release
END TestShapes;

PROCEDURE TestSymbols;
  VAR s: ARRAY 8 OF CHAR; i: INTEGER;
BEGIN
  Check.Check(FlDraw.AddSymbol("tdmSquare", Square, TRUE), "AddSymbol");
  Check.Check(Run(Symbols) & ok, "capture it");
  Check.Check(FlTest.Pixel(20, 20) = black, "its draw runs, in the box given");
  Check.Check(FlTest.Pixel(5, 5) = white, "and no further");
  FlTest.Release;
  Check.Check(~FlDraw.AddSymbol("", Square, TRUE), "no empty name: that is the default symbol");
  Check.Check(~FlDraw.AddSymbol("#a", Square, TRUE), "nor # first");
  Check.Check(~FlDraw.AddSymbol("$a", Square, TRUE), "nor $ first");
  Check.Check(~FlDraw.AddSymbol("%a", Square, TRUE), "nor % first");
  Check.Check(~FlDraw.AddSymbol("3a", Square, TRUE), "nor a digit first");
  Check.Check(~FlDraw.AddSymbol("-3a", Square, TRUE), "nor - and a digit");
  Check.Check(~FlDraw.AddSymbol("+3a", Square, TRUE), "nor + and a digit");
  Check.Check(FlDraw.AddSymbol("-a", Square, TRUE), "but - alone is a name");
  Set(s, "a", 0C3X, 0A9X, 0X);
  Check.Check(~FlDraw.AddSymbol(s, Square, TRUE), "nor a byte past ASCII");
  Set(s, "@", 0C3X, 0A9X, 0X);
  Check.Check(~FlDraw.DrawSymbol(s, 0, 0, 5, 5, Fl.Black), "and that isn't drawn");
  (* last, as the table stays full *)
  i := 0; s := "tdmAA";
  WHILE (i < 200) & FlDraw.AddSymbol(s, Square, TRUE) DO
    INC(i);
    s[3] := CHR(ORD("A") + i DIV 26); s[4] := CHR(ORD("A") + i MOD 26)
  END;
  Check.Check((i >= 55) & (i < 70), "the table holds some 60 more, then says so")
END TestSymbols;

PROCEDURE TestText;
  VAR dx, dy, w, h, n, next: INTEGER; width: LONGREAL;
    to: ARRAY 40 OF CHAR; short: ARRAY 3 OF CHAR; text: ARRAY 40 OF CHAR;
BEGIN
  FlDraw.SetFont(Fl.Courier, 14);
  FlDraw.TextExtents("MMM", dx, dy, w, h);
  Check.Check((w > 0) & (h > 0) & (dy < 0), "TextExtents: the ink rises from the baseline");
  Check.Check(Run(Texts), "capture rotated text");
  Check.Check(Ink() > 10, "TextRotated draws");
  FlTest.Release;
  Check.Check(Run(RightToLeft), "capture text right to left");
  Check.Check(Ink() > 10, "RightToLeft draws");
  FlTest.Release;

  width := FlDraw.Width("ab");
  text := "ab_cd"; text[2] := 0AX;
  next := FlDraw.ExpandText(text, 0, to, 0.0D0, n, width, FALSE, FALSE);
  Check.Check((to = "ab") & (n = 2) & (next = 3) & (width > 0.0D0), "ExpandText stops at a newline");
  next := FlDraw.ExpandText(text, 3, to, 0.0D0, n, width, FALSE, FALSE);
  Check.Check((to = "cd") & (n = 2) & (next = 5), "from where it says");
  Set(text, 9X, "a", 1X, 0X);
  next := FlDraw.ExpandText(text, 0, to, 0.0D0, n, width, FALSE, FALSE);
  Check.Check((to = "        a^A") & (n = 11), "a tab, and a control character");
  next := FlDraw.ExpandText("abcdef", 0, short, 0.0D0, n, width, FALSE, FALSE);
  Check.Check((short = "ab") & (n = 6) & (next = 6), "cut to fit, and n says what it was");
  next := FlDraw.ExpandText("MMM MMM MMM", 0, to, FlDraw.Width("MMM MMM") + 1.0D0, n, width, TRUE, FALSE);
  Check.Check((to = "MMM MMM ") OR (to = "MMM MMM"), "wrap stops at a word that fits");
  Check.Check(next = 8, "and the next line starts at the next word");
  next := FlDraw.ExpandText("a@@b", 0, to, 0.0D0, n, width, FALSE, TRUE);
  Check.Check((to = "a@b") & (next = 4), "symbols: @@ is one");
  next := FlDraw.ExpandText("a@b", 0, to, 0.0D0, n, width, FALSE, TRUE);
  Check.Check((to = "a") & (next = 1), "and it stops at any other @");
  next := FlDraw.ExpandText("@b", 0, to, 0.0D0, n, width, FALSE, TRUE);
  Check.Check((to = "") & (next = 0), "which at the start stays there");

  Set(text, "a", 0E9X, 0X, 0X);
  FlDraw.Latin1ToLocal(text, to);
  Check.Check((to[0] = "a") & (to[1] = 0E9X) & (to[2] = 0X), "Latin1ToLocal is Latin-1");
  FlDraw.LocalToLatin1(text, to);
  Check.Check((to[0] = "a") & (to[1] = 0E9X) & (to[2] = 0X), "and LocalToLatin1");
  text[0] := 80X; text[1] := 81X; text[2] := "z"; text[3] := 0X;
  FlDraw.MacRomanToLocal(text, to);
  Check.Check((to[0] = 0C4X) & (to[1] = 0C5X) & (to[2] = "z") & (to[3] = 0X), "MacRomanToLocal");
  FlDraw.LocalToMacRoman(to, text);
  Check.Check((text[0] = 80X) & (text[1] = 81X) & (text[2] = "z") & (text[3] = 0X), "LocalToMacRoman");
  FlDraw.LocalToMacRoman("abcdef", short);
  Check.Check(short = "ab", "cut to fit");
  FlDraw.MacRomanToLocal("abcdef", short);
  Check.Check(short = "ab", "both ways");
  FlDraw.Latin1ToLocal("abcdef", short); Check.Check(short = "ab", "and Latin-1");
  FlDraw.LocalToLatin1("abcdef", short); Check.Check(short = "ab", "both ways")
END TestText;

PROCEDURE TestImages;
  VAR w, h: INTEGER; bad: ARRAY 2 OF ARRAY 16 OF CHAR;
BEGIN
  Check.Check(Run(Plain) & Four(red, green, blue, white), "DrawImage");
  FlTest.Release;
  Check.Check(Run(Mirrored) & Four(green, red, white, blue), "a negative d runs right to left");
  FlTest.Release;
  Check.Check(Run(BottomUp) & Four(blue, white, red, green), "a negative l runs bottom to top");
  FlTest.Release;
  Check.Check(Run(FourBytes) & Four(red, green, blue, white), "4 bytes, with its fourth ignored");
  FlTest.Release;
  Check.Check(Run(Grays) & Four(black, white, gray, Fl.RGB(64, 64, 64)), "DrawImageMono");
  FlTest.Release;
  Check.Check(Run(Skipping) & Four(white, black, black, white) & (Ink() = 2),
    "of a byte of each pixel, and no size draws nothing");
  FlTest.Release;
  rows.calls := 0;
  Check.Check(Run(Lines) & (rows.calls = 2), "DrawImageLines asks for each row");
  Check.Check(Four(Fl.RGB(0, 0, 0), red, Fl.RGB(0, 255, 0), Fl.RGB(255, 255, 0)), "and draws them");
  FlTest.Release;
  Check.Check(Run(MonoLines) & Four(black, white, black, white), "DrawImageMonoLines");
  FlTest.Release;

  ok := FALSE;
  Check.Check(Run(Pixmaps) & ok, "DrawPixmap");
  Check.Check((FlTest.Pixel(5, 5) = red) & (FlTest.Pixel(6, 5) = blue), "draws");
  FlTest.Release;
  Check.Check(FlImages.MeasurePixmap(pixmap, 4, w, h) & (w = 2) & (h = 1), "MeasurePixmap");
  w := -1;
  Check.Check(~FlImages.MeasurePixmap(pixmap, 3, w, h) & (w = -1), "too few lines");
  bad[0] := "2 1 1 1"; bad[1] := "";
  Check.Check(~FlImages.MeasurePixmap(bad, 2, w, h), "lines that don't match");
  Check.Check(~FlImages.DrawPixmap(bad, 2, 0, 0, Fl.White), "aren't drawn")
END TestImages;

PROCEDURE TestOffscreen;
  VAR o: FlDraw.Offscreen; i: FlImages.Image; r, g, b: INTEGER;
BEGIN
  NEW(off);
  Check.Check(~off.IsOpen(), "an offscreen starts closed");
  FlDraw.OpenOffscreen(off, 20, 10);
  Check.Check(off.IsOpen() & (FlDraw.openOffscreens = 1), "OpenOffscreen");
  off.Begin;
  FlDraw.SetColor(Fl.Red); FlDraw.RectF(0, 0, 10, 10);
  FlDraw.SetColor(Fl.Blue); FlDraw.RectF(10, 0, 10, 10);
  NEW(i);
  Check.Check(FlImages.ReadImage(i, 15, 5, 50, 50, FALSE), "ReadImage partly off a surface");
  Check.Check((i.W() = 5) & (i.H() = 5), "gives what is on it");
  i.Close;
  Check.Check(~FlImages.ReadImage(i, 20, 0, 5, 5, FALSE), "and none of it, nothing");
  off.End;
  Check.Check(Run(Copied), "capture a copy of an offscreen");
  Fl.GetRGB(Fl.Blue, r, g, b);
  Check.Check(FlTest.Pixel(10, 10) = Fl.RGB(r, g, b), "Copy, from sx, sy");
  Check.Check(FlTest.Pixel(16, 10) = white, "and no more than w, h");
  FlTest.Release;
  off.Rescale;
  Check.Check(Run(Copied) & (FlTest.Pixel(10, 10) # white), "Rescale keeps the picture");
  FlTest.Release;

  NEW(o); FlDraw.OpenOffscreen(o, 5, 5);
  off.Begin; o.Begin;
  FlDraw.SetColor(Fl.Red); FlDraw.RectF(0, 0, 5, 5);
  o.End;
  FlDraw.SetColor(Fl.Green); FlDraw.RectF(0, 0, 5, 5);
  off.End;
  Check.Check(FlDraw.openOffscreens = 2, "two offscreens, begun one inside the other");
  o.Close; o.Close;
  Check.Check(~o.IsOpen() & (FlDraw.openOffscreens = 1), "Close is idempotent");
  off.Begin; off.Close;
  Check.Check(~off.IsOpen() & (FlDraw.openOffscreens = 0), "and ends one begun");
  FlDraw.OpenOffscreen(off, 20, 10); off.Close
END TestOffscreen;

PROCEDURE TestSurfaceScroll;
BEGIN
  NEW(part); part.color := Fl.Black; part.calls := 0;
  Check.Check(Run(Scrolled), "capture a scroll");
  Check.Check((part.calls = 1) & (part.w = 10) & (part.h = 10), "on a surface all of it is drawn");
  Check.Check(FlTest.Pixel(10, 10) = black, "by the Area");
  FlTest.Release;
  part.calls := 0;
  Check.Check(Run(Unscrolled) & (part.calls = 0), "no move, no call");
  FlTest.Release;
  Check.Check(Run(Smoothing), "capture the antialias setting");
  Check.Check(smooth OR ~canSmooth, "SetAntialias(FALSE) is kept, or there is none");
  Check.Check(Run(Bare) & (Ink() = 0), "and SetAntialias(TRUE) puts it back: nothing was drawn");
  FlTest.Release
END TestSurfaceScroll;

PROCEDURE (w: Shown) Draw*;
BEGIN
  FlDraw.SetColor(Fl.Red); FlDraw.RectF(0, 0, w.W() DIV 2, w.H());
  FlDraw.SetColor(Fl.Green); FlDraw.RectF(w.W() DIV 2, 0, w.W() - w.W() DIV 2, w.H())
END Draw;

PROCEDURE TestShown;
  VAR i: FlImages.Image; r, g, b: INTEGER;
BEGIN
  NEW(shown); Fl.OpenWindow(shown, 100, 100, "TestDrawMore"); shown.End;
  shown.Show; shown.WaitForExpose;

  FlDraw.Cursor(Fl.CursorWait); FlDraw.Cursor(Fl.CursorDefault);
  ok := FlDraw.CanDoAlphaBlending();

  shown.MakeCurrent;
  FlDraw.OverlayRect(10, 10, 30, 30);
  FlDraw.OverlayRect(20, 20, 30, 30);
  FlDraw.OverlayClear;
  Check.Check(TRUE, "OverlayRect and OverlayClear, on a window made current");

  part.color := Fl.Blue; part.calls := 0;
  FlDraw.Scroll(0, 0, 100, 100, 10, 0, part);
  Check.Check((part.calls >= 1) & (part.w <= 100), "Scroll calls for what it uncovers");
  part.calls := 0;
  FlDraw.Scroll(0, 0, 100, 100, 200, 0, part);
  Check.Check((part.calls = 1) & (part.w = 100), "and for all of it past its size");
  shown.Redraw;
  ok := Fl.Check();

  FlDraw.SetSpot(Fl.Helvetica, 14, 10, 10, 50, 20);
  FlDraw.SetStatus(0, 0, 10, 10);
  FlDraw.ResetSpot;
  Check.Check(TRUE, "SetSpot, SetStatus and ResetSpot");

  NEW(i);
  Check.Check(FlImages.CaptureWindow(i, shown, 0, 0, 100, 100), "CaptureWindow");
  Check.Check((i.W() = 100) & (i.H() = 100), "of the size asked for");
  Fl.GetRGB(i.Pixel(10, 10), r, g, b);
  Check.Check((r = 255) & (g = 0), "of what it shows");
  Fl.GetRGB(i.Pixel(90, 90), r, g, b);
  Check.Check((r = 0) & (g = 255), "all over");
  i.Close;
  Check.Check(FlImages.CaptureWindow(i, shown, 90, 90, 50, 50), "a rectangle partly outside it");
  Check.Check((i.W() = 10) & (i.H() = 10), "gives what is on it");
  i.Close;
  Check.Check(FlImages.CaptureWindow(i, shown, -5, -6, 20, 20), "from above and left too");
  Check.Check((i.W() = 15) & (i.H() = 14), "and the same there");
  i.Close;
  Check.Check(~FlImages.CaptureWindow(i, shown, 100, 0, 5, 5), "right of it");
  Check.Check(~FlImages.CaptureWindow(i, shown, 0, -5, 5, 5), "above it");
  Check.Check(FlImages.CaptureWindow(i, shown, 90, 90, MAX(INTEGER), MAX(INTEGER)) & (i.W() = 10), "a size that overflows is cut");
  i.Close;
  shown.MakeCurrent;
  Check.Check(FlImages.ReadImage(i, 90, 90, 50, 50, FALSE), "ReadImage partly off a window");
  Check.Check((i.W() = 10) & (i.H() = 10), "gives what is on it");
  i.Close;
  Check.Check(FlImages.ReadImage(i, -5, -6, 20, 20, TRUE), "above and left too");
  Check.Check((i.W() = 15) & (i.H() = 14), "and the same there");
  i.Close;
  Check.Check(~FlImages.CaptureWindow(i, shown, 0, 0, 0, 10), "no width");
  Check.Check(~FlImages.CaptureWindow(i, shown, 0, 0, -3, 10), "a negative width");
  Check.Check(~FlImages.CaptureWindow(i, shown, 0, 0, 10, 0), "no height");
  shown.Hide; ok := Fl.Check();
  Check.Check(~FlImages.CaptureWindow(i, shown, 0, 0, 10, 10), "a window hidden");
  shown.Delete
END TestShown;

BEGIN
  red := Fl.RGB(255, 0, 0); green := Fl.RGB(0, 255, 0); blue := Fl.RGB(0, 0, 255);
  white := Fl.RGB(255, 255, 255); black := Fl.RGB(0, 0, 0); gray := Fl.RGB(128, 128, 128);
  rgb[0] := 0FFX; rgb[1] := 0X; rgb[2] := 0X;
  rgb[3] := 0X; rgb[4] := 0FFX; rgb[5] := 0X;
  rgb[6] := 0X; rgb[7] := 0X; rgb[8] := 0FFX;
  rgb[9] := 0FFX; rgb[10] := 0FFX; rgb[11] := 0FFX;
  rgba[0] := 0FFX; rgba[1] := 0X; rgba[2] := 0X; rgba[3] := 80X;
  rgba[4] := 0X; rgba[5] := 0FFX; rgba[6] := 0X; rgba[7] := 80X;
  rgba[8] := 0X; rgba[9] := 0X; rgba[10] := 0FFX; rgba[11] := 80X;
  rgba[12] := 0FFX; rgba[13] := 0FFX; rgba[14] := 0FFX; rgba[15] := 80X;
  grays[0] := 0X; grays[1] := 0FFX; grays[2] := 80X; grays[3] := 40X;
  pixmap[0] := "2 1 2 1"; pixmap[1] := "r c #FF0000"; pixmap[2] := "b c #0000FF"; pixmap[3] := "rb";
  NEW(rows); NEW(grayRows);

  NEW(win); Fl.OpenWindow(win, Size, Size, "TestDrawMore");
  NEW(canvas); Fl.OpenBox(canvas, 0, 0, Size, Size, "");
  win.End;

  TestShapes;
  TestSymbols;
  TestText;
  TestImages;
  TestOffscreen;
  TestSurfaceScroll;
  TestShown;

  win.Delete;
  Check.Summary
END TestDrawMore.
