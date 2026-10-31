MODULE TestCairo; (* FlCairo: windows drawn with cairo, their contexts, and gradients *)

IMPORT Fl, FlCairo, Check, Probe;

CONST Limit = 500; (* of waits, so that valgrind has time *)

TYPE
  (* Red on its left half and blue on its right. *)
  Halves = POINTER TO RECORD (FlCairo.CairoWindowDesc)
    draws: INTEGER
  END;

  (* What a draw leaves, for the next to find. *)
  Sticky = POINTER TO RECORD (FlCairo.CairoWindowDesc)
    draws: INTEGER;
    broke: BOOLEAN;   (* the context went wrong at the first draw *)
    fresh: BOOLEAN    (* and was right at a later one *)
  END;

  (* A Draw of a program's own. *)
  Own = POINTER TO RECORD (FlCairo.CairoWindowDesc)
    base: BOOLEAN;
    draws, cairoDraws: INTEGER
  END;

  Graded = POINTER TO RECORD (FlCairo.CairoWindowDesc)
    draws: INTEGER;
    closed: BOOLEAN;   (* its pattern is closed before it is used *)
    bad: BOOLEAN;      (* it draws with a scale cairo refuses *)
    ok: BOOLEAN
  END;

  Texted = POINTER TO RECORD (FlCairo.CairoWindowDesc)
    draws: INTEGER;
    e: FlCairo.TextExtents;
    ok: BOOLEAN
  END;

  Shapes = POINTER TO RECORD (FlCairo.CairoWindowDesc)
    draws: INTEGER
  END;

VAR
  halves, second, inner: Halves;
  sticky: Sticky;
  own: Own;
  graded: Graded;
  texted: Texted;
  shapes: Shapes;
  outer: Fl.Window;
  kid: Fl.Box;
  red, blue, white, green: INTEGER;

PROCEDURE (w: Halves) DrawCairo*(c: FlCairo.Context);
BEGIN
  INC(w.draws);
  c.SetSourceRGB(1, 0, 0);
  c.Rectangle(0, 0, w.W() DIV 2, w.H());
  c.Fill;
  c.SetSourceRGB(0, 0, 1);
  c.Rectangle(w.W() DIV 2, 0, w.W() - w.W() DIV 2, w.H());
  c.Fill
END DrawCairo;

PROCEDURE (w: Sticky) DrawCairo*(c: FlCairo.Context);
BEGIN
  INC(w.draws);
  IF w.draws = 1 THEN
    (* A scale and a Save, then more Restores than Saves. *)
    c.Scale(0.5D0, 0.5D0);
    c.Save;
    c.Restore;
    Check.Check(c.Ok(), "a Restore with its Save is fine");
    c.Restore;
    w.broke := ~c.Ok();
    c.SetSourceRGB(1, 0, 0);
    c.Paint
  ELSE
    w.fresh := c.Ok();
    c.SetSourceRGB(0, 0, 1);
    c.Rectangle(0, 0, w.W(), w.H());
    c.Fill
  END
END DrawCairo;

PROCEDURE (w: Own) Draw*;
BEGIN
  INC(w.draws);
  IF w.base THEN w.Draw^ END
END Draw;

PROCEDURE (w: Own) DrawCairo*(c: FlCairo.Context);
BEGIN
  INC(w.cairoDraws);
  c.SetSourceRGB(1, 0, 0);
  c.Paint
END DrawCairo;

PROCEDURE (w: Graded) DrawCairo*(c: FlCairo.Context);
  VAR p: FlCairo.Pattern;
BEGIN
  INC(w.draws);
  IF w.bad THEN c.Scale(0, 0) END;
  p := FlCairo.LinearPattern(0, 0, w.W(), 0);
  p.AddColorStopRGB(0, 1, 0, 0);
  p.AddColorStopRGBA(1, 0, 0, 1, 1);
  p.SetExtend(FlCairo.ExtendPad);
  c.SetSource(p);
  IF w.closed THEN p.Close; p.Close END;
  c.Paint;
  w.ok := c.Ok();
  p.Close
END DrawCairo;

PROCEDURE (w: Texted) DrawCairo*(c: FlCairo.Context);
BEGIN
  INC(w.draws);
  c.SelectFontFace("Sans", FlCairo.SlantOblique, FlCairo.WeightBold);
  c.SetFontSize(40);
  c.GetTextExtents("Oberon", w.e);
  c.SetSourceRGB(0, 0, 0);
  c.MoveTo(10, 50);
  c.ShowText("Oberon");
  c.MoveTo(10, 100);
  c.TextPath("Oberon");
  c.SetSourceRGB(0, 0, 1);
  c.FillPreserve;
  c.SetLineWidth(1);
  c.StrokePreserve;
  c.NewPath;
  w.ok := c.Ok()
END DrawCairo;

(* A square in each corner, each by another of cairo's ways. *)
PROCEDURE (w: Shapes) DrawCairo*(c: FlCairo.Context);
BEGIN
  INC(w.draws);
  c.SetAntialias(FlCairo.AntialiasNone);
  c.SetSourceRGB(1, 0, 0);
  c.Save;
    c.Translate(100, 0);
    c.Scale(2, 2);
    c.Rectangle(0, 0, 10, 10);
    c.Fill;
  c.Restore;
  c.Save;
    c.Rectangle(0, 0, 10, 10);
    c.Clip;
    c.Paint;
  c.Restore;
  c.SetSourceRGB(0, 0, 1);
  c.MoveTo(0, 100); c.LineTo(10, 100); c.LineTo(10, 110); c.LineTo(0, 110);
  c.ClosePath;
  c.Fill;
  c.SetLineWidth(4);
  c.Arc(105, 105, 8, 0, 6.2831853071795862D0);
  c.Stroke;
  c.Save;
    c.Translate(60, 60);
    c.Rotate(3.1415926535897931D0);
    c.Rectangle(-5, -5, 10, 10);
    c.CurveTo(0, 0, 1, 1, 2, 2);
    c.Fill;
  c.Restore
END DrawCairo;

(* Whether color is within 12 of r, g, b, in each. *)
PROCEDURE Near(color, r, g, b: INTEGER): BOOLEAN;
  VAR n: INTEGER;
BEGIN
  n := color DIV 100H;
  RETURN (ABS(n DIV 10000H MOD 100H - r) <= 12) & (ABS(n DIV 100H MOD 100H - g) <= 12)
    & (ABS(n MOD 100H - b) <= 12)
END Near;

PROCEDURE Wait(VAR draws: INTEGER; before: INTEGER);
  VAR i: INTEGER; b: BOOLEAN;
BEGIN
  i := 0;
  WHILE (draws = before) & (i < Limit) DO Fl.Wait(0.01D0); INC(i) END;
  (* All of the flush that drew it. *)
  b := Fl.Check()
END Wait;

PROCEDURE TestHalves;
  VAR before: INTEGER;
BEGIN
  NEW(halves);
  FlCairo.OpenCairoWindow(halves, 100, 60, "cairo");
  NEW(kid);
  Fl.OpenBox(kid, 0, 0, 100, 60, "");
  kid.SetBoxType(Fl.FlatBox); kid.SetColor(Fl.Green);
  halves.End;
  Check.Check(halves.draws = 0, "nothing drawn before it is shown");
  halves.Show;
  Wait(halves.draws, 0);
  Check.Check(halves.draws > 0, "DrawCairo is called");
  Check.Check((Probe.ShownPixel(halves, 10, 10) = red) & (Probe.ShownPixel(halves, 90, 50) = blue),
    "it draws in the window's coordinates, over the widgets");
  before := halves.draws;
  halves.Redraw;
  Wait(halves.draws, before);
  Check.Check(halves.draws > before, "again at each redraw");
  Check.Check(Probe.ShownPixel(halves, 90, 50) = blue, "the same again");

  before := halves.draws;
  kid.Resize(0, 0, 200, 60);
  halves.Resize(halves.X(), halves.Y(), 200, 60);
  halves.Redraw;
  Wait(halves.draws, before);
  Check.Check(Probe.ShownPixel(halves, 90, 50) = red, "resized, its left half is wider");
  Check.Check(Probe.ShownPixel(halves, 190, 50) = blue, "and it draws on the new part");

  NEW(second);
  FlCairo.OpenCairoWindow(second, 80, 40, "");
  second.End;
  second.Show;
  Wait(second.draws, 0);
  Check.Check(Probe.ShownPixel(second, 70, 30) = blue, "a second window");
  Check.Check(Probe.ShownPixel(halves, 190, 50) = blue, "leaves the first");

  (* A surface isn't the display: the widgets are shown, without cairo. *)
  before := halves.draws;
  Check.Check(Probe.Capture(halves), "captured");
  Check.Check((Probe.Pixel(10, 10) = green) & (halves.draws = before),
    "on another surface, DrawCairo isn't called");
  Probe.Release;
  Check.Check(Probe.ShownPixel(halves, 10, 10) = red, "and the window is as it was");
  second.Delete;
  halves.Delete;
  Check.Check(~kid.IsOpen(), "its children go with it")
END TestHalves;

PROCEDURE TestSticky;
BEGIN
  NEW(sticky);
  FlCairo.OpenCairoWindow(sticky, 100, 60, "");
  sticky.End;
  sticky.Show;
  Wait(sticky.draws, 0);
  Check.Check(sticky.broke, "a Restore too many: Ok is FALSE");
  sticky.Redraw;
  Wait(sticky.draws, 1);
  Check.Check(sticky.fresh, "the next draw has a good context");
  Check.Check(Probe.ShownPixel(sticky, 90, 50) = blue, "with no scale left from the last");
  sticky.Delete
END TestSticky;

PROCEDURE TestOwn;
BEGIN
  NEW(own);
  FlCairo.OpenCairoWindow(own, 100, 60, "");
  own.End;
  own.base := TRUE;
  own.Show;
  Wait(own.cairoDraws, 0);
  Check.Check((own.draws > 0) & (own.cairoDraws > 0), "Draw^ draws with cairo");
  own.base := FALSE; own.cairoDraws := 0; own.draws := 0;
  own.Redraw;
  Wait(own.draws, 0);
  Check.Check((own.draws > 0) & (own.cairoDraws = 0), "and without it DrawCairo isn't called");
  own.Delete
END TestOwn;

PROCEDURE TestPatterns;
  VAR left, right, before: INTEGER;
BEGIN
  NEW(graded);
  FlCairo.OpenCairoWindow(graded, 100, 60, "");
  graded.End;
  graded.Show;
  Wait(graded.draws, 0);
  Check.Check(graded.ok, "a gradient");
  left := Probe.ShownPixel(graded, 1, 30); right := Probe.ShownPixel(graded, 98, 30);
  Check.Check(Near(left, 250, 0, 0) & Near(right, 0, 0, 250),
    "from red to blue");
  before := graded.draws;
  graded.closed := TRUE;
  graded.Redraw;
  Wait(graded.draws, before);
  Check.Check(graded.ok & (Probe.ShownPixel(graded, 98, 30) = right), "cairo keeps a closed one it was set");
  before := graded.draws;
  graded.bad := TRUE;
  graded.Redraw;
  Wait(graded.draws, before);
  Check.Check(~graded.ok, "a scale cairo refuses: Ok is FALSE");
  before := graded.draws;
  graded.bad := FALSE;
  graded.Redraw;
  Wait(graded.draws, before);
  Check.Check(graded.ok, "which lasts that draw");
  graded.Delete
END TestPatterns;

PROCEDURE TestText;
  VAR x, y, dark: INTEGER;
BEGIN
  NEW(texted);
  FlCairo.OpenCairoWindow(texted, 200, 120, "");
  texted.SetColor(Fl.White);
  texted.End;
  texted.Show;
  Wait(texted.draws, 0);
  Check.Check(texted.ok, "text");
  Check.Check((texted.e.width > 0) & (texted.e.height > 0) & (texted.e.xAdvance > 0)
    & (texted.e.yBearing < 0), "GetTextExtents");
  dark := 0;
  FOR y := 0 TO 119 DO
    FOR x := 0 TO 199 DO
      IF Probe.ShownPixel(texted, x, y) # white THEN INC(dark) END
    END
  END;
  Check.Check(dark > 100, "ShowText, TextPath and their fill draw");
  texted.Delete
END TestText;

PROCEDURE TestShapes;
BEGIN
  NEW(shapes);
  FlCairo.OpenCairoWindow(shapes, 120, 120, "");
  shapes.SetColor(Fl.White);
  shapes.End;
  shapes.Show;
  Wait(shapes.draws, 0);
  Check.Check(Probe.ShownPixel(shapes, 5, 5) = red, "Clip and Paint");
  Check.Check(Probe.ShownPixel(shapes, 11, 11) = white, "Restore ends the clip");
  Check.Check((Probe.ShownPixel(shapes, 115, 15) = red) & (Probe.ShownPixel(shapes, 99, 5) = white),
    "Translate and Scale");
  Check.Check(Probe.ShownPixel(shapes, 5, 105) = blue, "a path of lines");
  Check.Check((Probe.ShownPixel(shapes, 113, 105) = blue) & (Probe.ShownPixel(shapes, 105, 105) = white),
    "an arc stroked");
  Check.Check(Probe.ShownPixel(shapes, 60, 60) = blue, "Rotate");
  shapes.Delete
END TestShapes;

PROCEDURE TestInner;
BEGIN
  NEW(outer);
  Fl.OpenWindow(outer, 200, 100, "");
  NEW(inner);
  FlCairo.OpenCairoWindowAt(inner, 40, 20, 100, 60, "");
  inner.End;
  outer.End;
  outer.Show;
  Wait(inner.draws, 0);
  Check.Check((Probe.ShownPixel(inner, 10, 10) = red) & (Probe.ShownPixel(inner, 90, 50) = blue),
    "a window in a window");
  outer.Delete;
  Check.Check(~inner.IsOpen(), "goes with it")
END TestInner;

BEGIN
  red := Fl.RGB(255, 0, 0); blue := Fl.RGB(0, 0, 255);
  white := Fl.RGB(255, 255, 255); green := Fl.RGB(0, 255, 0);
  TestHalves;
  TestSticky;
  TestOwn;
  TestPatterns;
  TestText;
  TestShapes;
  TestInner;
  Check.Summary
END TestCairo.
