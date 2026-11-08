MODULE TestGl; (* FlGl: OpenGL windows, FLTK's GL drawing, and GL's calls *)

IMPORT Fl, FlGl, FlGlut, FlDraw, Check, Probe;

CONST Limit = 500; (* of waits, so that valgrind has time *)

TYPE
  Red = POINTER TO RECORD (FlGl.GlWindowDesc)
    draws, invalid, overlays: INTEGER;
    pw, ph: INTEGER;     (* its size in pixels, at a draw when not valid *)
    r, g, b: INTEGER;    (* a pixel read back as it drew *)
    height, descent: INTEGER;
    width: REAL;
    tw, th: INTEGER
  END;

  (* A window whose first draw checks GL's lists, lights, matrices,
     queries and selection, and GLUT's shapes. *)
  More = POINTER TO RECORD (FlGl.GlWindowDesc)
    draws: INTEGER
  END;

  (* A window drawing with FlDraw over its scene, between DrawBegin and
     DrawEnd, and its widgets with DrawWindow. With unended, it leaves
     DrawEnd to pofltk. *)
  Mixed = POINTER TO RECORD (FlGl.GlWindowDesc)
    draws: INTEGER;
    unended: BOOLEAN;
    rect, kid, scene: ARRAY 4 OF CHAR;  (* pixels read back *)
    error: INTEGER
  END;

  (* A plain window, drawing with GL through Start. *)
  Plain = POINTER TO RECORD (Fl.WindowDesc)
    draws: INTEGER;
    height: INTEGER
  END;

VAR
  win, win2: Red;
  more: More;
  plain: Plain;
  mixed: Mixed;
  green: Fl.Box;
  kid: Fl.Box;
  group: Fl.Window;
  inner: Red;
  version: ARRAY 128 OF CHAR;
  pix: ARRAY 4 OF CHAR;
  before: INTEGER;

PROCEDURE (w: Red) Draw*;
  VAR p: ARRAY 4 OF CHAR;
BEGIN
  INC(w.draws);
  IF ~w.Valid() THEN
    INC(w.invalid);
    w.pw := w.PixelW(); w.ph := w.PixelH();
    FlGl.Viewport(0, 0, w.pw, w.ph);
    w.Ortho
  END;
  FlGl.ClearColor(1.0, 0.0, 0.0, 1.0);
  FlGl.Clear(FlGl.ColorBufferBit);
  FlGl.Flush;
  FlGl.ReadPixels(1, 1, 1, 1, p);
  w.r := ORD(p[0]); w.g := ORD(p[1]); w.b := ORD(p[2]);
  FlGl.Font(Fl.Helvetica, 14);
  w.height := FlGl.Height();
  w.descent := FlGl.Descent();
  w.width := FlGl.Width("wide");
  w.tw := 0; w.th := 0;
  FlGl.Measure("wide", w.tw, w.th);
  FlGl.Color(Fl.White);
  FlGl.DrawTextAt("hi", 10.0, 10.0);
  FlGl.Rect(2, 2, 10, 10);
  FlGl.Rectf(4, 4, 2, 2);
  w.Draw^
END Draw;

PROCEDURE (w: Red) DrawOverlay*;
BEGIN INC(w.overlays)
END DrawOverlay;

(* The pixel at the window's centre, as red, green and blue. *)
PROCEDURE Centre(w: More; VAR r, g, b: INTEGER);
  VAR p: ARRAY 4 OF CHAR;
BEGIN
  FlGl.Flush;
  FlGl.ReadPixels(w.PixelW() DIV 2, w.PixelH() DIV 2, 1, 1, p);
  r := ORD(p[0]); g := ORD(p[1]); b := ORD(p[2])
END Centre;

PROCEDURE Is(w: More; r, g, b: INTEGER): BOOLEAN;
  VAR pr, pg, pb: INTEGER;
BEGIN
  Centre(w, pr, pg, pb);
  RETURN (pr = r) & (pg = g) & (pb = b)
END Is;

(* Clears to black, colour and depth. *)
PROCEDURE Black;
BEGIN
  FlGl.ClearColor(0.0, 0.0, 0.0, 1.0);
  FlGl.ClearDepth(1.0D0);
  FlGl.Clear(FlGl.ColorBufferBit + FlGl.DepthBufferBit)
END Black;

(* A square over all the view, at depth z, its front facing the viewer. *)
PROCEDURE Square(z: REAL);
BEGIN
  FlGl.Begin(FlGl.Quads);
  FlGl.Normal3f(0.0, 0.0, 1.0);
  FlGl.Vertex3f(-1.0, -1.0, z); FlGl.Vertex3f(1.0, -1.0, z);
  FlGl.Vertex3f(1.0, 1.0, z); FlGl.Vertex3f(-1.0, 1.0, z);
  FlGl.End
END Square;

PROCEDURE Set(VAR a: ARRAY OF REAL; x, y, z, t: REAL);
BEGIN a[0] := x; a[1] := y; a[2] := z; a[3] := t
END Set;

PROCEDURE Lists(w: More);
  VAR n: INTEGER;
BEGIN
  n := FlGl.GenLists(1);
  Check.Check(n > 0, "a display list's number");
  FlGl.NewList(n, FlGl.Compile);
  FlGl.Color3f(0.0, 1.0, 0.0);
  Square(0.0);
  FlGl.EndList;
  Check.Check(Is(w, 0, 0, 0), "Compile doesn't draw");
  FlGl.Color3f(1.0, 0.0, 0.0);
  FlGl.CallList(n);
  Check.Check(Is(w, 0, 255, 0), "a list drawn");
  FlGl.DeleteLists(n, 1);
  Check.Check(FlGl.GetError() = FlGl.NoError, "lists without an error")
END Lists;

PROCEDURE Matrices(w: More);
  VAR m: ARRAY 16 OF REAL; v: ARRAY 4 OF INTEGER; i: INTEGER;
BEGIN
  FlGl.MatrixMode(FlGl.Projection);
  FlGl.LoadIdentity;
  FlGl.Ortho(0.0D0, 2.0D0, 0.0D0, 2.0D0, -1.0D0, 1.0D0);
  Check.Check(FlGl.GetFloat(FlGl.ProjectionMatrix, m), "the projection matrix can be read");
  Check.Check((m[0] = 1.0) & (m[5] = 1.0) & (m[12] = -1.0) & (m[13] = -1.0), "it is the one Ortho made");
  Check.Check(FlGl.GetInteger(FlGl.MatrixModeNow, v) & (v[0] = FlGl.Projection), "the matrix mode");
  FlGl.LoadIdentity;
  FlGl.MatrixMode(FlGl.Modelview);
  FlGl.LoadIdentity;
  FOR i := 0 TO 15 DO m[i] := 0.0 END;
  m[0] := 2.0; m[5] := 3.0; m[10] := 1.0; m[15] := 1.0; m[12] := 0.5;
  FlGl.MultMatrixf(m);
  FOR i := 0 TO 15 DO m[i] := 9.0 END;
  Check.Check(FlGl.GetFloat(FlGl.ModelviewMatrix, m) & (m[0] = 2.0) & (m[5] = 3.0) & (m[12] = 0.5) & (m[1] = 0.0),
    "MultMatrixf");
  FlGl.LoadIdentity;
  Check.Check(FlGl.GetInteger(FlGl.ViewportArea, v) & (v[0] = 0) & (v[1] = 0)
    & (v[2] = w.PixelW()) & (v[3] = w.PixelH()), "the viewport, as integers");
  Check.Check(~FlGl.GetFloat(1, m), "GetFloat of a pname GL doesn't know");
  Check.Check(~FlGl.GetInteger(86A3H, v), "GetInteger of a list of formats");
  Check.Check(FlGl.GetError() = FlGl.NoError, "and no error left behind")
END Matrices;

PROCEDURE Attribs(w: More);
  VAR v: ARRAY 1 OF INTEGER;
BEGIN
  FlGl.PushAttrib(FlGl.EnableBit);
  FlGl.Enable(FlGl.DepthTest);
  Check.Check(FlGl.GetInteger(FlGl.DepthTest, v) & (v[0] = 1), "a cap, as a query");
  FlGl.PopAttrib;
  Check.Check(FlGl.GetInteger(FlGl.DepthTest, v) & (v[0] = 0), "PopAttrib puts it back");

  Black;
  FlGl.Enable(FlGl.DepthTest);
  FlGl.DepthFunc(FlGl.Never);
  FlGl.Color3f(1.0, 1.0, 1.0);
  Square(0.0);
  Check.Check(Is(w, 0, 0, 0), "DepthFunc(Never) draws nothing");
  FlGl.DepthFunc(FlGl.Less);
  Square(0.5);
  FlGl.Color3f(1.0, 0.0, 0.0);
  Square(0.6);
  Check.Check(Is(w, 255, 255, 255), "DepthFunc(Less) keeps the nearer");
  FlGl.ClearDepth(0.0D0);
  FlGl.Clear(FlGl.DepthBufferBit);
  Square(0.0);
  Check.Check(Is(w, 255, 255, 255), "ClearDepth(0) leaves nothing nearer");
  FlGl.Disable(FlGl.DepthTest);

  Black;
  FlGl.Enable(FlGl.CullFace);
  FlGl.SetCullFace(FlGl.Front);
  Square(0.0);
  Check.Check(Is(w, 0, 0, 0), "the front culled");
  FlGl.SetCullFace(FlGl.Back);
  Square(0.0);
  Check.Check(Is(w, 255, 0, 0), "the back culled");
  FlGl.Disable(FlGl.CullFace);
  FlGl.GlFinish;
  Check.Check(FlGl.GetError() = FlGl.NoError, "no error")
END Attribs;

PROCEDURE Lights(w: More);
  VAR a: ARRAY 4 OF REAL; d: ARRAY 3 OF REAL; r, g, b: INTEGER;
BEGIN
  Black;
  Set(a, 0.0, 0.0, 0.0, 1.0);
  FlGl.LightModel(FlGl.LightModelAmbient, a);
  FlGl.Enable(FlGl.Lighting);
  FlGl.Enable(FlGl.Light0);
  d[0] := 0.0; d[1] := 0.0; d[2] := 1.0;
  FlGl.Light(FlGl.Light0, FlGl.Position, d);  (* w 0: from far off *)
  Set(a, 1.0, 1.0, 1.0, 1.0);
  FlGl.Light(FlGl.Light0, FlGl.Diffuse, a);
  Set(a, 0.0, 0.0, 1.0, 1.0);
  FlGl.Material(FlGl.Front, FlGl.Diffuse, a);
  Set(a, 0.0, 0.0, 0.0, 1.0);
  FlGl.Material(FlGl.Front, FlGl.Ambient, a);
  FlGl.Color3f(1.0, 0.0, 0.0);
  Square(0.0);
  Centre(w, r, g, b);
  Check.Check((r = 0) & (g = 0) & (b >= 250), "a lit square of the material's colour");
  FlGl.SetColorMaterial(FlGl.Front, FlGl.Diffuse);
  FlGl.Enable(FlGl.ColorMaterial);
  FlGl.Color3f(0.0, 1.0, 0.0);
  Square(0.0);
  Centre(w, r, g, b);
  Check.Check((r = 0) & (g >= 250) & (b = 0), "ColorMaterial: the colour's");
  FlGl.Disable(FlGl.ColorMaterial);
  FlGl.Disable(FlGl.Lighting);
  FlGl.Disable(FlGl.Light0);
  Check.Check(FlGl.GetError() = FlGl.NoError, "no error")
END Lights;

PROCEDURE Selection(w: More);
  VAR v: ARRAY 1 OF INTEGER; hits: INTEGER;
BEGIN
  Check.Check(FlGl.SelectSize() = 0, "no selection buffer to start with");
  FlGl.SelectBuffer(64);
  Check.Check(FlGl.SelectSize() = 64, "a selection buffer");
  Check.Check(FlGl.RenderMode(FlGl.Select) = 0, "select mode");
  Check.Check(FlGl.GetInteger(FlGl.RenderModeNow, v) & (v[0] = FlGl.Select), "in select mode");
  FlGl.InitNames;
  FlGl.PushName(0);
  FlGl.LoadName(7);
  Square(0.0);
  FlGl.LoadName(8);
  FlGl.PushMatrix; FlGl.Translatef(5.0, 0.0, 0.0); Square(0.0); FlGl.PopMatrix;
  FlGl.PushName(-1);
  Check.Check(FlGl.GetInteger(FlGl.NameStackDepth, v) & (v[0] = 2), "the name stack's depth");
  Square(0.0);
  FlGl.PopName;
  hits := FlGl.RenderMode(FlGl.Render);
  Check.Check(hits = 2, "two hit records");
  Check.Check((FlGl.SelectValue(0) = 1) & (FlGl.SelectValue(3) = 7), "the first, of name 7");
  Check.Check((FlGl.SelectValue(4) = 2) & (FlGl.SelectValue(7) = 8) & (FlGl.SelectValue(8) = -1),
    "the second, of two names, the last unsigned");
  Check.Check(FlGl.GetError() = FlGl.NoError, "no error");
  FlGl.SelectBuffer(1);
  Check.Check(FlGl.SelectSize() = 1, "another buffer");
  Check.Check(FlGl.RenderMode(FlGl.Select) = 0, "select mode again");
  FlGl.InitNames; FlGl.PushName(1);
  Square(0.0);
  Check.Check(FlGl.RenderMode(FlGl.Render) = -1, "an overflow")
END Selection;

PROCEDURE Shapes(w: More);
BEGIN
  Black;
  FlGl.Color3f(1.0, 1.0, 1.0);
  FlGlut.Cube(TRUE, 1.0D0);
  Check.Check(Is(w, 255, 255, 255), "a solid cube");
  Black;
  FlGlut.Cube(FALSE, 1.0D0);
  Check.Check(Is(w, 0, 0, 0), "a wire cube is only edges");
  FlGlut.Sphere(TRUE, 0.5D0, 8, 8);
  Check.Check(Is(w, 255, 255, 255), "a sphere");
  Black;
  FlGlut.Torus(TRUE, 0.1D0, 0.5D0, 8, 8);
  Check.Check(Is(w, 0, 0, 0), "a torus has a hole");
  FlGlut.Cone(TRUE, 0.5D0, 0.5D0, 8, 1); FlGlut.Cone(FALSE, 0.5D0, 0.5D0, 1, 1);
  FlGlut.Sphere(FALSE, 0.5D0, 1, 1); FlGlut.Torus(FALSE, 0.1D0, 0.5D0, 1, 1);
  FlGlut.Teapot(TRUE, 0.5D0); FlGlut.Teapot(FALSE, 0.5D0);
  FlGlut.Tetrahedron(TRUE); FlGlut.Tetrahedron(FALSE);
  FlGlut.Octahedron(TRUE); FlGlut.Octahedron(FALSE);
  FlGlut.Dodecahedron(TRUE); FlGlut.Dodecahedron(FALSE);
  FlGlut.Icosahedron(TRUE); FlGlut.Icosahedron(FALSE);
  Check.Check(FlGl.GetError() = FlGl.NoError, "GLUT's shapes, without an error")
END Shapes;

PROCEDURE (w: More) Draw*;
BEGIN
  INC(w.draws);
  IF w.draws = 1 THEN
    FlGl.Viewport(0, 0, w.PixelW(), w.PixelH());
    FlGl.MatrixMode(FlGl.Projection); FlGl.LoadIdentity;
    FlGl.MatrixMode(FlGl.Modelview); FlGl.LoadIdentity;
    Black;
    Lists(w);
    Matrices(w);
    Attribs(w);
    Lights(w);
    Selection(w);
    Shapes(w)
  END
END Draw;

(* The pixel at x, y in w's units, from the top. *)
PROCEDURE ReadAt(w: Mixed; x, y: INTEGER; VAR p: ARRAY OF CHAR);
BEGIN
  FlGl.ReadPixels(x * w.PixelW() DIV w.W(), w.PixelH() - 1 - y * w.PixelH() DIV w.H(), 1, 1, p)
END ReadAt;

PROCEDURE (w: Mixed) Draw*;
BEGIN
  INC(w.draws);
  FlGl.Viewport(0, 0, w.PixelW(), w.PixelH());
  FlGl.ClearColor(0.0, 0.0, 1.0, 1.0);
  FlGl.Clear(FlGl.ColorBufferBit);
  w.DrawBegin;
  w.DrawWindow;
  FlDraw.SetColor(Fl.Red);
  FlDraw.RectF(0, 0, 10, 10);
  IF ~w.unended THEN
    w.DrawEnd;
    FlGl.Flush;
    ReadAt(w, 5, 5, w.rect); ReadAt(w, 50, 5, w.kid); ReadAt(w, 30, 30, w.scene);
    w.error := FlGl.GetError()
  END
END Draw;

PROCEDURE Red3(p: ARRAY OF CHAR; r, g, b: INTEGER): BOOLEAN;
BEGIN RETURN (ORD(p[0]) = r) & (ORD(p[1]) = g) & (ORD(p[2]) = b)
END Red3;

PROCEDURE Mix;
  VAR i, n: INTEGER;
BEGIN
  NEW(mixed);
  FlGl.OpenGlWindow(mixed, 60, 40, "");
  mixed.Begin;
  NEW(green); Fl.OpenBox(green, 40, 0, 20, 20, "");
  green.SetBoxType(Fl.FlatBox); green.SetColor(Fl.Green);
  mixed.End;
  mixed.error := -1;
  mixed.Show;
  i := 0;
  WHILE (mixed.draws = 0) & (i < Limit) DO Fl.Wait(0.02D0); INC(i) END;
  Check.Check(Red3(mixed.rect, 255, 0, 0), "FlDraw draws in a GL window, y down");
  Check.Check(Red3(mixed.kid, 0, 255, 0), "DrawWindow draws its widgets");
  Check.Check(Red3(mixed.scene, 0, 0, 255), "over the GL scene");
  Check.Check(mixed.error = FlGl.NoError, "with no GL error");

  mixed.unended := TRUE;
  n := mixed.draws; mixed.Redraw; i := 0;
  WHILE (mixed.draws = n) & (i < Limit) DO Fl.Wait(0.02D0); INC(i) END;
  mixed.unended := FALSE;
  mixed.error := -1;
  n := mixed.draws; mixed.Redraw; i := 0;
  WHILE (mixed.draws = n) & (i < Limit) DO Fl.Wait(0.02D0); INC(i) END;
  Check.Check(Red3(mixed.rect, 255, 0, 0) & (mixed.error = FlGl.NoError), "a Draw left begun is ended for it");
  mixed.Delete
END Mix;

PROCEDURE (w: Plain) Draw*;
BEGIN
  FlDraw.SetColor(Fl.Blue);
  FlDraw.RectF(0, 0, w.W(), w.H());
  INC(w.draws);
  FlGl.Start;
  FlGl.Font(Fl.Helvetica, 14);
  w.height := FlGl.Height();
  FlGl.Color(Fl.Green);
  FlGl.Rectf(0, 0, 10, 10);
  FlGl.Finish
END Draw;

PROCEDURE Open(w, h: INTEGER): Red;
  VAR r: Red;
BEGIN
  NEW(r);
  FlGl.OpenGlWindow(r, w, h, "");
  r.End;
  RETURN r
END Open;

(* Runs FLTK until r draws again. *)
PROCEDURE Draws(r: Red);
  VAR n, i: INTEGER;
BEGIN
  n := r.draws; i := 0;
  WHILE (r.draws = n) & (i < Limit) DO Fl.Wait(0.02D0); INC(i) END
END Draws;

PROCEDURE Mode;
  VAR r: Red;
BEGIN
  r := Open(60, 40);
  Check.Check(r.Mode() = FlGl.Rgb + FlGl.Double + FlGl.Depth, "a window's mode to start with");
  Check.Check(r.CanDo(), "its mode can be had");
  Check.Check(FlGl.CanDoMode(FlGl.Rgb + FlGl.Double), "a mode can be asked about");
  Check.Check(r.SetMode(FlGl.Rgb + FlGl.Double), "a mode not shown can be set");
  Check.Check(r.Mode() = FlGl.Rgb + FlGl.Double, "the mode it was given");
  r.Delete
END Mode;

BEGIN
  Mode;

  win := Open(100, 80);
  Check.Check(~win.Valid(), "not valid before it is shown");
  win.Show;
  Draws(win);
  Check.Check(win.draws > 0, "a GL window draws");
  Check.Check(win.invalid > 0, "not valid at its first draw");
  Check.Check((win.pw > 0) & (win.ph > 0), "it has a size in pixels");
  Check.Check((win.r = 255) & (win.g = 0) & (win.b = 0), "GL drew red, and read it back");
  Check.Check(win.height > 0, "text has a height");
  Check.Check(win.descent > 0, "text has a descent");
  Check.Check(win.width > 0.0, "text has a width");
  Check.Check((win.tw > 0) & (win.th > 0), "text can be measured");
  Check.Check(win.PixelsPerUnit() > 0.0, "pixels per unit");

  before := win.invalid;
  win.Redraw;
  Draws(win);
  Check.Check(win.invalid = before, "valid at a later draw");
  Check.Check(win.Valid(), "valid after a draw");

  win.Resize(0, 0, 120, 90);
  Draws(win);
  Check.Check(win.invalid > before, "a resize makes it not valid");
  Check.Check(win.pw = win.PixelW(), "drawn at its new size");

  Check.Check(FlGl.TexturePileHeight() = 100, "text's texture pile to start with");
  FlGl.SetTexturePileHeight(1);
  Check.Check(FlGl.TexturePileHeight() = 1, "a pile of one texture");
  before := win.draws;
  win.Redraw; Draws(win); win.Redraw; Draws(win);
  Check.Check(win.draws >= before + 2, "text drawn with a pile of one");
  FlGl.TextureReset;
  Check.Check(FlGl.TexturePileHeight() = 1, "a reset keeps the pile's height");
  win.Redraw; Draws(win);
  FlGl.SetTexturePileHeight(100);
  Check.Check(FlGl.TexturePileHeight() = 100, "the pile set back");

  win.MakeCurrent;
  pix[0] := 0X; pix[1] := 1X;
  FlGl.ReadPixels(1, 1, 1, 1, pix);
  Check.Check((ORD(pix[0]) = 255) OR (ORD(pix[0]) = 0), "GL can be read outside a Draw");
  FlGl.Version(version);
  Check.Check(version[0] # 0X, "GL's version");
  Check.Check(FlGl.GetError() = FlGl.NoError, "no GL error");

  win.SetSwapInterval(0);
  win.Invalidate;
  Check.Check(~win.Valid(), "Invalidate");
  win.Redraw;
  Draws(win);

  Check.Check(win.SetMode(FlGl.Rgb + FlGl.Single + FlGl.Depth), "a shown window's mode can change");
  win.Redraw;
  Draws(win);
  Check.Check((win.r = 255) & (win.g = 0), "it draws in its new mode");

  win.RedrawOverlay;
  Fl.Wait(0.05D0);
  Check.Check(win.overlays > 0, "an overlay is drawn");
  win.HideOverlay;

  win.MakeCurrent;
  win.Hide;
  win.Show;
  FlGl.Font(Fl.Helvetica, 14);
  Check.Check(FlGl.Height() > 0, "text before a draw, shown again");
  Draws(win);
  Check.Check(win.Shown(), "shown again");
  Check.Check((win.r = 255) & (win.g = 0), "it draws after being hidden");

  win.Delete;
  Check.Check(~win.IsOpen(), "a window with a context can be deleted");

  (* a child widget, and GL window in a plain one *)
  NEW(group);
  Fl.OpenWindow(group, 200, 200, "");
  inner := NIL;
  NEW(inner);
  FlGl.OpenGlWindowAt(inner, 10, 10, 100, 100, "");
  NEW(kid);
  Fl.OpenBox(kid, 5, 5, 20, 20, "");
  inner.End;
  group.End;
  group.Show;
  Draws(inner);
  Check.Check(inner.draws > 0, "a GL window in a window draws");
  group.Delete;
  Check.Check(~kid.IsOpen(), "a GL window's child goes with it");

  (* another, after one is deleted *)
  win2 := Open(50, 50);
  win2.Show;
  Draws(win2);
  Check.Check(win2.r = 255, "a window after a deleted one draws");
  win2.Delete;

  NEW(more);
  FlGl.OpenGlWindow(more, 40, 40, "");
  more.End;
  more.Show;
  before := 0;
  WHILE (more.draws = 0) & (before < Limit) DO Fl.Wait(0.02D0); INC(before) END;
  Check.Check(more.draws > 0, "the window of GL's calls draws");
  more.Delete;

  Mix;

  IF FlGl.CanStart() THEN
    NEW(plain);
    Fl.OpenWindow(plain, 40, 40, "");
    plain.End;
    plain.Show;
    before := 0;
    WHILE (plain.draws = 0) & (before < Limit) DO Fl.Wait(0.02D0); INC(before) END;
    Check.Check(plain.draws > 0, "Start in a plain window");
    Check.Check(plain.height > 0, "and text through it");
    plain.Delete
  ELSE
    Check.Skip("Start: FLTK crashes on it under Wayland")
  END;
  Check.Summary
END TestGl.
