MODULE CubeView; (* FLTK's test/CubeView.cxx, CubeViewUI.fl and CubeMain.cxx in Oberon-2 *)

(* A cube turned, moved and zoomed by rollers and sliders: FLUID's
   tutorial program. The window is built as FLUID's CubeViewUI.cxx
   builds it. *)

IMPORT Fl, FlGl, FlValuators;

CONST alpha = 0.5;

TYPE
  Vertex = ARRAY 3 OF REAL;
  View = POINTER TO RECORD (FlGl.GlWindowDesc)
    size, vAng, hAng, xshift, yshift: LONGREAL;
    boxv: ARRAY 8 OF Vertex  (* a unit cube centred on the origin *)
  END;
  VRot = POINTER TO RECORD (FlValuators.RollerDesc) END;
  HRot = POINTER TO RECORD (FlValuators.RollerDesc) END;
  YPan = POINTER TO RECORD (FlValuators.SliderDesc) END;
  XPan = POINTER TO RECORD (FlValuators.SliderDesc) END;
  Zoom = POINTER TO RECORD (FlValuators.ValueSliderDesc) END;

VAR
  mainWindow: Fl.DoubleWindow;
  o, vChange, hChange, mainView: Fl.Group;
  vrot: VRot;
  hrot: HRot;
  ypan: YPan;
  xpan: XPan;
  zoom: Zoom;
  cube: View;
  ok: BOOLEAN;

PROCEDURE OpenView(v: View; x, y, w, h: INTEGER; label: ARRAY OF CHAR);

  PROCEDURE Set(VAR p: Vertex; x, y, z: REAL);
  BEGIN p[0] := x; p[1] := y; p[2] := z
  END Set;

BEGIN
  FlGl.OpenGlWindowAt(v, x, y, w, h, label);
  FlGl.UseHighRes(TRUE);
  v.vAng := 0.0D0; v.hAng := 0.0D0; v.size := 10.0D0;
  v.xshift := 0.0D0; v.yshift := 0.0D0;
  Set(v.boxv[0], -0.5, -0.5, -0.5); Set(v.boxv[1], 0.5, -0.5, -0.5);
  Set(v.boxv[2], 0.5, 0.5, -0.5); Set(v.boxv[3], -0.5, 0.5, -0.5);
  Set(v.boxv[4], -0.5, -0.5, 0.5); Set(v.boxv[5], 0.5, -0.5, 0.5);
  Set(v.boxv[6], 0.5, 0.5, 0.5); Set(v.boxv[7], -0.5, 0.5, 0.5)
END OpenView;

(* Draws a colored cube *)
PROCEDURE (v: View) DrawCube;

  PROCEDURE V(i: INTEGER);
  BEGIN FlGl.Vertex3f(v.boxv[i, 0], v.boxv[i, 1], v.boxv[i, 2])
  END V;

  PROCEDURE Face(r, g, b: REAL; i, j, k, l: INTEGER);
  BEGIN FlGl.Color4f(r, g, b, alpha); V(i); V(j); V(k); V(l)
  END Face;

  PROCEDURE Line(i, j: INTEGER);
  BEGIN V(i); V(j)
  END Line;

BEGIN
  FlGl.ShadeModel(FlGl.Flat);
  FlGl.Begin(FlGl.Quads);
    Face(0.0, 0.0, 1.0, 0, 1, 2, 3);
    Face(1.0, 1.0, 0.0, 0, 4, 5, 1);
    Face(0.0, 1.0, 1.0, 2, 6, 7, 3);
    Face(1.0, 0.0, 0.0, 4, 5, 6, 7);
    Face(1.0, 0.0, 1.0, 0, 3, 7, 4);
    Face(0.0, 1.0, 0.0, 1, 5, 6, 2);
  FlGl.End;
  FlGl.Color3f(1.0, 1.0, 1.0);
  FlGl.Begin(FlGl.Lines);
    Line(0, 1); Line(1, 2); Line(2, 3); Line(3, 0);
    Line(4, 5); Line(5, 6); Line(6, 7); Line(7, 4);
    Line(0, 4); Line(1, 5); Line(2, 6); Line(3, 7);
  FlGl.End
END DrawCube;

PROCEDURE (v: View) Draw*;
BEGIN
  IF ~v.Valid() THEN
    FlGl.LoadIdentity;
    FlGl.Viewport(0, 0, v.PixelW(), v.PixelH());
    FlGl.Ortho(-10.0D0, 10.0D0, -10.0D0, 10.0D0, -20050.0D0, 10000.0D0);
    FlGl.Enable(FlGl.Blend);
    FlGl.BlendFunc(FlGl.SrcAlpha, FlGl.OneMinusSrcAlpha)
  END;
  FlGl.Clear(FlGl.ColorBufferBit + FlGl.DepthBufferBit);
  FlGl.PushMatrix;
  FlGl.Translatef(SHORT(v.xshift), SHORT(v.yshift), 0.0);
  FlGl.Rotatef(SHORT(v.hAng), 0.0, 1.0, 0.0);
  FlGl.Rotatef(SHORT(v.vAng), 1.0, 0.0, 0.0);
  FlGl.Scalef(SHORT(v.size), SHORT(v.size), SHORT(v.size));
  v.DrawCube;
  FlGl.PopMatrix
END Draw;

PROCEDURE (r: VRot) Callback*;
BEGIN cube.vAng := r.Value(); cube.Redraw
END Callback;

PROCEDURE (s: YPan) Callback*;
BEGIN cube.yshift := s.Value(); cube.Redraw
END Callback;

PROCEDURE (s: XPan) Callback*;
BEGIN cube.xshift := s.Value(); cube.Redraw
END Callback;

PROCEDURE (r: HRot) Callback*;
BEGIN cube.hAng := r.Value(); cube.Redraw
END Callback;

PROCEDURE (s: Zoom) Callback*;
BEGIN cube.size := s.Value(); cube.Redraw
END Callback;

BEGIN
  NEW(mainWindow); Fl.OpenDoubleWindow(mainWindow, 415, 405, "CubeView");
  mainWindow.SetBoxType(Fl.UpBox);
  mainWindow.SetLabelSize(12);
  NEW(o); Fl.OpenGroup(o, 5, 3, 374, 399, "");
    NEW(vChange); Fl.OpenGroup(vChange, 5, 100, 37, 192, "");
      NEW(vrot); FlValuators.OpenRoller(vrot, 5, 100, 17, 186, "V Rot");
      vrot.SetLabelType(Fl.NoLabel);
      vrot.SetLabelSize(12);
      vrot.SetBounds(-180.0D0, 180.0D0);
      vrot.SetStep(1.0D0);
      vrot.SetAlign(Fl.AlignWrap);
      NEW(ypan); FlValuators.OpenSlider(ypan, 25, 100, 17, 186, "V Pan");
      ypan.SetKind(FlValuators.VertNiceSlider);
      ypan.SetSelectionColor(Fl.DarkBlue);
      ypan.SetLabelType(Fl.NoLabel);
      ypan.SetLabelSize(12);
      ypan.SetBounds(-25.0D0, 25.0D0);
      ypan.SetStep(0.1D0);
      ypan.SetAlign(Fl.AlignCenter);
    vChange.End;
    NEW(hChange); Fl.OpenGroup(hChange, 120, 362, 190, 40, "");
      NEW(xpan); FlValuators.OpenSlider(xpan, 122, 364, 186, 17, "H Pan");
      xpan.SetKind(FlValuators.HorNiceSlider);
      xpan.SetSelectionColor(Fl.DarkBlue);
      xpan.SetLabelType(Fl.NoLabel);
      xpan.SetLabelSize(12);
      xpan.SetBounds(25.0D0, -25.0D0);
      xpan.SetStep(0.1D0);
      xpan.SetAlign(Fl.AlignCenter + Fl.AlignInside);
      NEW(hrot); FlValuators.OpenRoller(hrot, 122, 383, 186, 17, "H Rotation");
      hrot.SetKind(FlValuators.Horizontal);
      hrot.SetLabelType(Fl.NoLabel);
      hrot.SetLabelSize(12);
      hrot.SetBounds(-180.0D0, 180.0D0);
      hrot.SetStep(1.0D0);
      hrot.SetAlign(Fl.AlignRight);
    hChange.End;
    NEW(mainView); Fl.OpenGroup(mainView, 46, 27, 333, 333, "");
    mainView.SetBoxType(Fl.DownBox);
      NEW(cube); OpenView(cube, 48, 29, 329, 329, "This is the cube_view");
      cube.SetBoxType(Fl.NoBox);
      cube.SetColor(Fl.BackgroundColor);
      cube.SetSelectionColor(Fl.BackgroundColor);
      cube.SetLabelType(Fl.NormalLabel);
      cube.SetLabelFont(0);
      cube.SetLabelSize(14);
      cube.SetLabelColor(Fl.ForegroundColor);
      cube.SetAlign(Fl.AlignCenter + Fl.AlignInside);
      cube.SetWhen(Fl.WhenRelease);
      mainView.SetResizable(cube);
    mainView.End;
    o.SetResizable(mainView);
    NEW(zoom); FlValuators.OpenValueSlider(zoom, 106, 3, 227, 19, "Zoom");
    zoom.SetKind(FlValuators.HorNiceSlider);
    zoom.SetSelectionColor(Fl.DarkBlue);
    zoom.SetLabelFont(1);
    zoom.SetLabelSize(12);
    zoom.SetBounds(1.0D0, 50.0D0);
    zoom.SetStep(0.1D0);
    zoom.SetValue(10.0D0);
    zoom.SetTextFont(1);
    zoom.SetAlign(Fl.AlignLeft);
  o.End;
  mainWindow.SetResizable(mainWindow);
  mainWindow.End;
  ok := Fl.Visual(Fl.VisualDouble + Fl.VisualIndex);
  mainWindow.ShowArgs;
  Fl.Run
END CubeView.
