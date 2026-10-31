MODULE TestGl; (* FlGl: OpenGL windows, FLTK's GL drawing, and GL's calls *)

IMPORT Fl, FlGl, FlDraw, Check, Probe;

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

  (* A plain window, drawing with GL through Start. *)
  Plain = POINTER TO RECORD (Fl.WindowDesc)
    draws: INTEGER;
    height: INTEGER
  END;

VAR
  win, win2: Red;
  plain: Plain;
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
