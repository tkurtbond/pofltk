MODULE GlutCube; (* The cube of FLTK's test/cube.cxx through GLUT: a GLUT window beside FLTK's widgets *)

(* FlGlut.Window is a widget, so it sits in a window with others, and GLUT's
   callbacks drive it: a timer turns the cube, the left button drags it, the
   right button is a GLUT menu, and "w" and "q" are keys. The slider and the
   check button are FLTK's, and work on the same state. *)

IMPORT Fl, FlButtons, FlGl, FlGlut, FlValuators;

CONST
  period = 40;      (* of the timer, in milliseconds *)
  menuWire = 1;
  menuFlat = 2;
  menuQuit = 3;

TYPE
  Speed = POINTER TO RECORD (FlValuators.SliderDesc) END;
  Wire = POINTER TO RECORD (FlButtons.CheckButtonDesc) END;

VAR
  form: Fl.Window;
  cube: FlGlut.Window;
  wire: Wire;
  turn, tilt, speed: REAL;
  lastX, lastY: INTEGER;
  dragging: BOOLEAN;
  vx, vy, vz: ARRAY 8 OF REAL;

PROCEDURE Face(r, g, b, v0, v1, v2, v3: INTEGER; lines: BOOLEAN);

  PROCEDURE V(i: INTEGER);
  BEGIN FlGl.Vertex3f(vx[i], vy[i], vz[i])
  END V;

BEGIN
  IF lines THEN FlGl.Begin(FlGl.LineLoop) ELSE FlGl.Begin(FlGl.Polygon) END;
  FlGl.Color3ub(r, g, b);
  V(v0); V(v1); V(v2); V(v3);
  FlGl.End
END Face;

PROCEDURE Display;
  VAR lines: BOOLEAN;
BEGIN
  lines := wire.Value();
  FlGl.Clear(FlGl.ColorBufferBit + FlGl.DepthBufferBit);
  FlGl.PushMatrix;
  FlGl.Rotatef(tilt, 1, 0, 0);
  FlGl.Rotatef(turn, 0, 1, 0);
  FlGl.Translatef(-0.5, -0.5, -0.5);
  Face(0, 0, 255, 0, 1, 2, 3, lines);
  Face(0, 255, 255, 4, 5, 6, 7, lines);
  Face(255, 0, 255, 0, 1, 5, 4, lines);
  Face(255, 255, 0, 2, 3, 7, 6, lines);
  Face(0, 255, 0, 0, 4, 7, 3, lines);
  Face(255, 0, 0, 1, 2, 6, 5, lines);
  FlGl.PopMatrix;
  FlGlut.SwapBuffers
END Display;

PROCEDURE Reshape(w, h: INTEGER);
BEGIN
  FlGl.Viewport(0, 0, w, h);
  FlGl.LoadIdentity;
  FlGl.Frustum(-1, 1, -1, 1, 2, 100);
  FlGl.Translatef(0, 0, -4);
  FlGl.ClearColor(0.4, 0.4, 0.4, 0);
  FlGl.Enable(FlGl.DepthTest)
END Reshape;

PROCEDURE Tick(value: INTEGER);
BEGIN
  IF ~dragging THEN
    turn := turn + speed;
    FlGlut.PostWindowRedisplay(cube.Number())
  END;
  FlGlut.TimerFunc(period, Tick, value)
END Tick;

PROCEDURE Mouse(button, state, x, y: INTEGER);
BEGIN
  IF button = FlGlut.LeftButton THEN
    dragging := state = FlGlut.Down;
    lastX := x; lastY := y
  END
END Mouse;

PROCEDURE Motion(x, y: INTEGER);
BEGIN
  IF dragging THEN
    turn := turn + (x - lastX); tilt := tilt + (y - lastY);
    lastX := x; lastY := y;
    FlGlut.PostRedisplay
  END
END Motion;

PROCEDURE SetWire(on: BOOLEAN);
BEGIN wire.SetValue(on); FlGlut.PostWindowRedisplay(cube.Number())
END SetWire;

PROCEDURE Keyboard(key: CHAR; x, y: INTEGER);
BEGIN
  IF key = "w" THEN SetWire(~wire.Value())
  ELSIF key = "q" THEN form.Hide
  END
END Keyboard;

PROCEDURE Menu(value: INTEGER);
BEGIN
  IF value = menuWire THEN SetWire(TRUE)
  ELSIF value = menuFlat THEN SetWire(FALSE)
  ELSIF value = menuQuit THEN form.Hide
  END
END Menu;

PROCEDURE (s: Speed) Callback*;
BEGIN speed := SHORT(s.Value())
END Callback;

PROCEDURE (b: Wire) Callback*;
BEGIN FlGlut.PostWindowRedisplay(cube.Number())
END Callback;

PROCEDURE SetCorner(i: INTEGER; x, y, z: REAL);
BEGIN vx[i] := x; vy[i] := y; vz[i] := z
END SetCorner;

PROCEDURE MakeForm;
  VAR slider: Speed; i: INTEGER;
BEGIN
  NEW(form); Fl.OpenWindow(form, 320, 390, "GLUT beside FLTK");

  FlGlut.InitDisplayMode(FlGlut.Double + FlGlut.Rgb + FlGlut.Depth);
  NEW(cube); FlGlut.OpenWindowAt(cube, 10, 10, 300, 300, "");
  cube.MakeCurrent;
  FlGlut.DisplayFunc(Display);
  FlGlut.ReshapeFunc(Reshape);
  FlGlut.MouseFunc(Mouse);
  FlGlut.MotionFunc(Motion);
  FlGlut.KeyboardFunc(Keyboard);

  i := FlGlut.CreateMenu(Menu);
  FlGlut.AddMenuEntry("Wire", menuWire);
  FlGlut.AddMenuEntry("Flat", menuFlat);
  FlGlut.AddMenuEntry("Quit", menuQuit);
  FlGlut.AttachMenu(FlGlut.RightButton);

  NEW(slider); FlValuators.OpenHorSlider(slider, 10, 320, 200, 25, "Speed");
  slider.SetBounds(0, 10);
  slider.SetValue(speed);
  NEW(wire); FlButtons.OpenCheckButton(wire, 220, 320, 90, 25, "Wire");

  form.End;
  form.SetResizable(cube)
END MakeForm;

BEGIN
  SetCorner(0, 0, 0, 0); SetCorner(1, 1, 0, 0); SetCorner(2, 1, 1, 0); SetCorner(3, 0, 1, 0);
  SetCorner(4, 0, 0, 1); SetCorner(5, 1, 0, 1); SetCorner(6, 1, 1, 1); SetCorner(7, 0, 1, 1);
  speed := 2; tilt := 30;
  FlGlut.Init;
  MakeForm;
  form.ShowArgs;
  FlGlut.TimerFunc(period, Tick, 0);
  FlGlut.MainLoop
END GlutCube.
