MODULE GlOverlay; (* FLTK's test/gl_overlay.cxx: a polygon, with another drawn over it in the overlay *)

IMPORT Fl, FlGl, FlValuators, Math, Out;

TYPE
  ShapeWindow = POINTER TO RECORD (FlGl.GlWindowDesc)
    sides, overlaySides: INTEGER
  END;

  Slider = POINTER TO RECORD (FlValuators.SliderDesc) END;
  OverlaySlider = POINTER TO RECORD (FlValuators.SliderDesc) END;

VAR
  window: Fl.Window;
  sw: ShapeWindow;
  slider: Slider;
  oslider: OverlaySlider;

(* The valid property avoids setting GL's transformation at each redraw. *)
PROCEDURE Setup(w: ShapeWindow);
BEGIN
  IF ~w.Valid() THEN
    w.SetValid(TRUE);
    FlGl.LoadIdentity;
    FlGl.Viewport(0, 0, w.PixelW(), w.PixelH())
  END
END Setup;

PROCEDURE Vertex(j, sides: INTEGER);
  VAR ang: REAL;
BEGIN
  ang := j * 2 * Math.pi / sides;
  FlGl.Vertex3f(Math.cos(ang), Math.sin(ang), 0)
END Vertex;

PROCEDURE (w: ShapeWindow) Draw*;
  VAR j: INTEGER; shade: REAL;
BEGIN
  Setup(w);
  FlGl.Clear(FlGl.ColorBufferBit);
  FlGl.Begin(FlGl.Polygon);
  FOR j := 0 TO w.sides - 1 DO
    shade := j / w.sides;
    FlGl.Color3f(shade, shade, shade);
    Vertex(j, w.sides)
  END;
  FlGl.End
END Draw;

PROCEDURE (w: ShapeWindow) DrawOverlay*;
  VAR j: INTEGER;
BEGIN
  Setup(w);
  FlGl.Color(Fl.Red);
  FlGl.Begin(FlGl.LineLoop);
  FOR j := 0 TO w.overlaySides - 1 DO Vertex(j, w.overlaySides) END;
  FlGl.End
END DrawOverlay;

(* When the data changes, as here, the window must be redrawn. *)
PROCEDURE (s: Slider) Callback*;
BEGIN sw.sides := SHORT(ENTIER(s.Value())); sw.Redraw
END Callback;

PROCEDURE (s: OverlaySlider) Callback*;
BEGIN sw.overlaySides := SHORT(ENTIER(s.Value())); sw.RedrawOverlay
END Callback;

BEGIN
  FlGl.UseHighRes(TRUE);
  NEW(window); Fl.OpenWindow(window, 300, 370, "");

  NEW(sw); FlGl.OpenGlWindowAt(sw, 10, 75, 280, 280, "");
  sw.sides := 3; sw.overlaySides := 3;
  window.SetResizable(sw);

  NEW(slider); FlValuators.OpenSlider(slider, 60, 5, 230, 30, "Sides:");
  slider.SetKind(FlValuators.HorSlider);
  slider.SetAlign(Fl.AlignLeft);
  slider.SetValue(sw.sides);
  slider.SetStep(1);
  slider.SetBounds(3, 40);

  NEW(oslider); FlValuators.OpenSlider(oslider, 60, 40, 230, 30, "Overlay:");
  oslider.SetKind(FlValuators.HorSlider);
  oslider.SetAlign(Fl.AlignLeft);
  oslider.SetValue(sw.overlaySides);
  oslider.SetStep(1);
  oslider.SetBounds(3, 40);

  window.End;
  window.ShowArgs;
  Out.String("Can do overlay = ");
  IF sw.CanDoOverlay() THEN Out.Int(1, 0) ELSE Out.Int(0, 0) END;
  Out.Ln;
  sw.Show;
  sw.RedrawOverlay;
  Fl.Run
END GlOverlay.
