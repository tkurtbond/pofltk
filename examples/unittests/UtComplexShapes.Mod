MODULE UtComplexShapes; (* FLTK's test/unittest_complex_shapes.cxx in Oberon-2 *)

IMPORT Fl, FlDraw, FlValuators, Ut, UtGl;

CONST Label* = "Complex Shapes";

TYPE
  Page = POINTER TO RECORD (Fl.GroupDesc) END;
  Native = POINTER TO RECORD (Fl.WindowDesc) END;
  (* the controls, which redraw the tests *)
  Scale = POINTER TO RECORD (FlValuators.ValueSliderDesc) END;
  Dial = POINTER TO RECORD (FlValuators.DialDesc) END;
  Positioner = POINTER TO RECORD (FlValuators.PositionerDesc) END;

VAR
  scale: Scale; rotate: Dial; position: Positioner;
  native, gl: Fl.Widget;

PROCEDURE Update;
BEGIN native.Redraw; IF gl # NIL THEN gl.Redraw END
END Update;

PROCEDURE (s: Scale) Callback*; BEGIN Update END Callback;
PROCEDURE (d: Dial) Callback*; BEGIN Update END Callback;
PROCEDURE (p: Positioner) Callback*; BEGIN Update END Callback;

PROCEDURE Transform;
BEGIN
  FlDraw.Translate(position.XValue(), position.YValue());
  FlDraw.Rotate(-rotate.Value());
  FlDraw.Scale(scale.Value(), scale.Value())
END Transform;

PROCEDURE V(x, y: INTEGER);
BEGIN FlDraw.Vertex(x, y)
END V;

PROCEDURE Convex(w, h: INTEGER);
BEGIN
  V(-(w DIV 2), -h); V(w DIV 2, -h); V(w, 0); V(w, h); V(0, h);
  V(-w, h DIV 2); V(-w, -(h DIV 2))
END Convex;

PROCEDURE Complex(w, h: INTEGER);
BEGIN
  V(-(w DIV 2), -h); V(0, -(h DIV 2)); V(w DIV 2, -h); V(w, 0); V(w, h);
  V(0, h); V(-w, h DIV 2); V(-(w DIV 2), 0); V(-w, -(h DIV 2))
END Complex;

PROCEDURE TwoComplex(w, h: INTEGER);
BEGIN
  V(-(w DIV 2), -h); V(w DIV 2, -h); V(w, 0); V(w, h - 3);
  FlDraw.Gap;
  V(w - 3, h); V(0, h); V(-w, h DIV 2); V(-w, -(h DIV 2))
END TwoComplex;

PROCEDURE WithHole(w, h: INTEGER);
  VAR w2, h2: INTEGER;
BEGIN
  w2 := w DIV 3; h2 := h DIV 3;
  (* clockwise *)
  Convex(w, h);
  FlDraw.Gap;
  (* counterclockwise *)
  V(-w2, -h2); V(-w2, h2); V(w2, h2); V(w2, -h2)
END WithHole;

PROCEDURE Shapes(win: Fl.Widget);
  VAR a, b, dx, dy, w, h, w2, h2: INTEGER;
BEGIN
  a := 0; b := 0; dx := 20; dy := 20; w := 10; h := 10;
  w2 := w DIV 3; h2 := h DIV 3;
  (* 1: draw a random shape *)
  FlDraw.SetColor(Fl.Black);
  FlDraw.PushMatrix;
  FlDraw.Translate(a + dx, b + dy);
  Transform;
  FlDraw.BeginPoints;
  Convex(w, h);
  FlDraw.EndPoints;
  FlDraw.PopMatrix;
  FlDraw.PushMatrix;
  FlDraw.Translate(a + dx + 50, b + dy);
  Transform;
  FlDraw.BeginLine;
  Convex(w, h);
  FlDraw.EndLine;
  FlDraw.PopMatrix;
  FlDraw.PushMatrix;
  FlDraw.Translate(a + dx + 100, b + dy);
  Transform;
  FlDraw.BeginLoop;
  Convex(w, h);
  FlDraw.EndLoop;
  FlDraw.PopMatrix;
  FlDraw.PushMatrix;
  FlDraw.Translate(a + dx + 150, b + dy);
  Transform;
  FlDraw.BeginPolygon;
  Convex(w, h);
  FlDraw.EndPolygon;
  FlDraw.PopMatrix;
  (* 2: draw a complex shape *)
  INC(b, 44);
  FlDraw.PushMatrix;
  FlDraw.Translate(a + dx, b + dy);
  Transform;
  FlDraw.SetColor(Fl.Dark2);
  FlDraw.BeginComplexPolygon;
  Convex(w, h);
  FlDraw.EndComplexPolygon;
  FlDraw.SetColor(Fl.Blue);
  FlDraw.BeginLoop;
  Convex(w, h);
  FlDraw.EndLoop;
  FlDraw.PopMatrix;
  FlDraw.PushMatrix;
  FlDraw.Translate(a + dx + 50, b + dy);
  Transform;
  FlDraw.SetColor(Fl.Dark2);
  FlDraw.BeginComplexPolygon;
  Complex(w, h);
  FlDraw.EndComplexPolygon;
  FlDraw.SetColor(Fl.Blue);
  FlDraw.BeginLoop;
  Complex(w, h);
  FlDraw.EndLoop;
  FlDraw.PopMatrix;
  FlDraw.PushMatrix;
  FlDraw.Translate(a + dx + 100, b + dy);
  Transform;
  FlDraw.SetColor(Fl.Dark2);
  FlDraw.BeginComplexPolygon;
  TwoComplex(w, h);
  FlDraw.EndComplexPolygon;
  FlDraw.SetColor(Fl.Blue);
  FlDraw.BeginLoop;
  V(-(w DIV 2), -h);
  V((w DIV 2), -h);
  V(w, 0);
  V(w, h - 3);
  FlDraw.EndLoop;
  FlDraw.BeginLoop;
  V(w - 3, h);
  V(0, h);
  V(-w, (h DIV 2));
  V(-w, -(h DIV 2));
  FlDraw.EndLoop;
  FlDraw.PopMatrix;
  FlDraw.PushMatrix;
  FlDraw.Translate(a + dx + 150, b + dy);
  Transform;
  FlDraw.SetColor(Fl.Dark2);
  FlDraw.BeginComplexPolygon;
  WithHole(w, h);
  FlDraw.EndComplexPolygon;
  FlDraw.SetColor(Fl.Blue);
  FlDraw.BeginLoop;
  V(-(w DIV 2), -h);
  V((w DIV 2), -h);
  V(w, 0);
  V(w, h);
  V(0, h);
  V(-w, (h DIV 2));
  V(-w, -(h DIV 2));
  FlDraw.EndLoop;
  FlDraw.BeginLoop;
  V(-w2, -h2);
  V(-w2, h2);
  V(w2, h2);
  V(w2, -h2);
  FlDraw.EndLoop;
  FlDraw.PopMatrix;
  (* 3: draw polygons with arcs *)
  INC(b, 44);
  FlDraw.PushMatrix;
  FlDraw.Translate(a + dx, b + dy);
  Transform;
  FlDraw.SetColor(Fl.Dark2);
  FlDraw.BeginComplexPolygon;
  V(-w, 0); FlDraw.ArcPath(0, 0, w - 3, 180.0D0, 0.0D0); V(w, 0);
  V(w, h); V(-w, h);
  FlDraw.EndComplexPolygon;
  FlDraw.SetColor(Fl.Blue);
  FlDraw.BeginLoop;
  V(-w, 0); FlDraw.ArcPath(0, 0, w - 3, 180.0D0, 0.0D0); V(w, 0);
  V(w, h); V(-w, h);
  FlDraw.EndLoop;
  FlDraw.PopMatrix;
  FlDraw.PushMatrix;
  FlDraw.Translate(a + dx + 50, b + dy);
  Transform;
  FlDraw.SetColor(Fl.Dark2);
  FlDraw.BeginComplexPolygon;
  V(-w, 0); FlDraw.ArcPath(0, 0, w - 3, 180.0D0, 360.0D0); V(w, 0);
  V(w, h); V(-w, h);
  FlDraw.EndComplexPolygon;
  FlDraw.SetColor(Fl.Blue);
  FlDraw.BeginLoop;
  V(-w, 0); FlDraw.ArcPath(0, 0, w - 3, 180.0D0, 360.0D0); V(w, 0);
  V(w, h); V(-w, h);
  FlDraw.EndLoop;
  FlDraw.PopMatrix;
  FlDraw.PushMatrix;
  FlDraw.Translate(a + dx + 100, b + dy);
  Transform;
  FlDraw.SetColor(Fl.Dark2);
  FlDraw.BeginComplexPolygon;
  V(-w, 0);
  FlDraw.Curve(-w + 3, 0, 0, -h, 0, h, w - 3, 0);
  V(w, 0);
  V(w, h); V(-w, h);
  FlDraw.EndComplexPolygon;
  FlDraw.SetColor(Fl.Blue);
  FlDraw.BeginLoop;
  V(-w, 0);
  FlDraw.Curve(-w + 3, 0, 0, -h, 0, h, w - 3, 0);
  V(w, 0);
  V(w, h); V(-w, h);
  FlDraw.EndLoop;
  FlDraw.PopMatrix
END Shapes;

PROCEDURE (w: Native) Draw*;
BEGIN w.Draw^; Shapes(w)
END Draw;

PROCEDURE Create*(): Fl.Widget;
  VAR p: Page; a, b: INTEGER; win: Native; t: Fl.Box;
BEGIN
  NEW(p); Ut.OpenPage(p, "Testing complex shape drawing.");
  a := Ut.X + 16; b := Ut.Y + 34;
  Ut.Heading(a, b - 24, "native");
  NEW(win); Fl.OpenWindowAt(win, a + 23, b - 1, 200, 200, "");
  win.SetBoxType(Fl.FlatBox); win.End; native := win;
  Ut.Mark(a, b, 18, "1", "Testing complex drawing with transformations.||Draw a point pattern, an open line, a closed line, and a covenx polygon.||Use the controls at the bottom right to scale, rotate, and move the patterns.");
  INC(b, 44);
  Ut.Mark(a, b, 18, "2", "Testing complex polygons.||Draw polygons at different leves of complexity. All polygons should be within the blue boundaries||1: a convex polygon|2: a non-convex polygon|3: two polygons in a single operation|4: a polygon with a square hole in it");
  INC(b, 44);
  Ut.Mark(a, b, 18, "3", "Testing complex polygons with arcs.||Draw polygons with an arc section. All polygons should be within the blue boundaries||1: a polygon with a camel hump|2: a polygon with a camel dip");
  IF UtGl.Have THEN
    a := Ut.X + 16 + 250; b := Ut.Y + 34;
    Ut.Heading(a, b - 24, "OpenGL");
    gl := UtGl.Open(a + 31, b - 1, 200, 200, Shapes, TRUE);
    Ut.Mark(a, b, 26, "1a", "Testing complex drawing with transformations.||Draw a point pattern, an open line, a closed line, and a convex polygon.||Use the controls at the bottom right to scale, rotate, and move the patterns.");
    INC(b, 44);
    Ut.Mark(a, b, 28, "2a", "Testing complex polygons.||Draw polygons at different leves of complexity. All polygons should be within the blue boundaries||1: a convex polygon|2: a non-convex polygon|3: two polygons in a single operation|4: a polygon with a square hole in it");
    INC(b, 44);
    Ut.Mark(a, b, 28, "3a", "Testing complex polygons with arcs.||Draw polygons with an arc section. All polygons should be within the blue boundaries||1: a polygon with a camel hump|2: a polygon with a camel dip")
  END;
  a := Ut.X + Ut.W - 250; b := Ut.Y + Ut.H - 50;
  NEW(scale); FlValuators.OpenHorValueSlider(scale, a, b + 10, 120, 20, "Scale:");
  scale.SetAlign(Fl.AlignTopLeft);
  scale.SetBounds(0.8D0, 1.2D0); scale.SetValue(1.0D0);
  NEW(rotate); FlValuators.OpenDial(rotate, a + 140, b, 40, 40, "Rotate:");
  rotate.SetAlign(Fl.AlignTopLeft);
  rotate.SetAngles(0, 360);
  rotate.SetBounds(-180.0D0, 180.0D0); rotate.SetValue(0.0D0);
  NEW(position); FlValuators.OpenPositioner(position, a + 200, b, 40, 40, "Offset:");
  position.SetAlign(Fl.AlignTopLeft);
  position.SetXBounds(-10, 10); position.SetYBounds(-10, 10);
  position.SetValue(0.0D0, 0.0D0);
  NEW(t); Fl.OpenBox(t, a - 1, b - 1, 1, 1, "");
  p.SetResizable(t);
  p.End;
  RETURN p
END Create;

END UtComplexShapes.
