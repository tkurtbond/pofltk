MODULE Shape; (* FLTK's test/shape.cxx in Oberon-2 *)

(* A polygon drawn with GL, in a GL window that is a child of a plain
   one; the slider sets its number of sides. *)

IMPORT Fl, FlGl, FlValuators, MathL;

TYPE
  ShapeWindow = POINTER TO RECORD (FlGl.GlWindowDesc) sides: INTEGER END;
  Sides = POINTER TO RECORD (FlValuators.SliderDesc) END;

VAR
  window: Fl.Window;
  sw: ShapeWindow;
  slider: Sides;

PROCEDURE (w: ShapeWindow) Draw*;
  VAR j: INTEGER; ang: LONGREAL;
BEGIN
  (* Valid may be used to avoid setting up GL's transformation at each
     draw *)
  IF ~w.Valid() THEN
    w.SetValid(TRUE);
    FlGl.LoadIdentity;
    FlGl.Viewport(0, 0, w.PixelW(), w.PixelH())
  END;
  (* draw an amazing graphic *)
  FlGl.Clear(FlGl.ColorBufferBit);
  FlGl.Color3f(0.5, 0.6, 0.7);
  FlGl.Begin(FlGl.Polygon);
  FOR j := 0 TO w.sides - 1 DO
    ang := j * 2 * MathL.pi / w.sides;
    FlGl.Vertex3f(SHORT(MathL.cos(ang)), SHORT(MathL.sin(ang)), 0.0)
  END;
  FlGl.End
END Draw;

(* when you change the data, as here, you must call Redraw *)
PROCEDURE (s: Sides) Callback*;
BEGIN
  sw.sides := SHORT(ENTIER(s.Value()));
  sw.Redraw
END Callback;

BEGIN
  FlGl.UseHighRes(TRUE);
  NEW(window); Fl.OpenWindow(window, 300, 330, "");
  (* the shape window could be its own window, but here it is a child *)
  NEW(sw); FlGl.OpenGlWindowAt(sw, 10, 10, 280, 280, "");
  sw.sides := 3;
  (* make it resize *)
  window.SetResizable(sw);
  (* add a knob to control it *)
  NEW(slider); FlValuators.OpenHorSlider(slider, 50, 295, window.W() - 60, 30, "Sides:");
  slider.SetAlign(Fl.AlignLeft);
  slider.SetValue(sw.sides);
  slider.SetStep(1.0D0);
  slider.SetBounds(3.0D0, 40.0D0);
  window.End;
  window.ShowArgs;
  Fl.Run
END Shape.
