MODULE Cube; (* FLTK's test/cube.cxx: two spinning cubes in GL windows, a wire one and a flat one *)

(* A timer redraws both cubes; the sliders set how fast they spin, and how
   big they are. "Stats / Exit" shows the frame rate, and offers to go on
   or reset the count. The left window has a button in it, drawn by its
   Draw's call of the window's own.

   FLTK's program takes the time with Fl::now, which pofltk has yet to
   bind; this one takes it from Platform. *)

IMPORT Fl, FlButtons, FlDialogs, FlGl, FlLayout, FlMenus, FlPrint, FlValuators, OutStr, Out, Platform;

CONST
  fps = 25.0D0;     (* the frame rate wanted, whatever the speed slider says *)
  delay = 1.0D0 / fps;
  menubarH = 25;
  margin = 20;      (* around the widgets *)
  gap = 20;         (* between them *)

TYPE
  CubeBox = POINTER TO RECORD (FlGl.GlWindowDesc)
    lasttime, size, speed: LONGREAL;
    wire: BOOLEAN
  END;

  Info = POINTER TO RECORD (FlButtons.ButtonDesc) END;
  Exit = POINTER TO RECORD (FlButtons.ButtonDesc) END;
  Form = POINTER TO RECORD (Fl.WindowDesc) END;
  Speed = POINTER TO RECORD (FlValuators.SliderDesc) END;
  Size = POINTER TO RECORD (FlValuators.SliderDesc) END;
  Wire = POINTER TO RECORD (FlButtons.RadioLightButtonDesc) END;
  Flat = POINTER TO RECORD (FlButtons.RadioLightButtonDesc) END;

VAR
  count: INTEGER;   (* frames, from -2 so that the first two aren't timed *)
  start: LONGREAL;
  form: Form;
  speed: Speed;
  size: Size;
  wire: Wire;
  flat: Flat;
  ltCube, rtCube: CubeBox;
  timer: Fl.Timer;
  vx, vy, vz: ARRAY 8 OF REAL;   (* the corners of the cube *)

(* Seconds, from some time past. *)
PROCEDURE Now(): LONGREAL;
  VAR sec, usec: LONGINT;
BEGIN Platform.GetTimeOfDay(sec, usec); RETURN sec + usec / 1000000.0D0
END Now;

(* v, not negative, as "%width.placesf" writes it. *)
PROCEDURE Fixed(v: LONGREAL; width, places: INTEGER; VAR s: ARRAY OF CHAR);
  VAR i: INTEGER; scale, part: LONGINT;
BEGIN
  scale := 1;
  FOR i := 1 TO places DO scale := scale * 10 END;
  part := ENTIER(v * scale + 0.5D0);
  OutStr.Int(part DIV scale, width - places - 1, s); OutStr.Char(".", s);
  FOR i := 1 TO places DO
    scale := scale DIV 10;
    OutStr.Char(CHR(ORD("0") + part DIV scale MOD 10), s)
  END
END Fixed;

(* A face of the cube: its color and four corners, numbered as FLTK's. *)
PROCEDURE Face(r, g, b, v0, v1, v2, v3: INTEGER; wire: BOOLEAN);

  PROCEDURE V(i: INTEGER);
  BEGIN FlGl.Vertex3f(vx[i], vy[i], vz[i])
  END V;

BEGIN
  IF wire THEN FlGl.Begin(FlGl.LineLoop) ELSE FlGl.Begin(FlGl.Polygon) END;
  FlGl.Color3ub(r, g, b);
  V(v0); V(v1); V(v2); V(v3);
  FlGl.End
END Face;

PROCEDURE DrawCube(wire: BOOLEAN);
BEGIN
  Face(0, 0, 255, 0, 1, 2, 3, wire);
  Face(0, 255, 255, 4, 5, 6, 7, wire);
  Face(255, 0, 255, 0, 1, 5, 4, wire);
  Face(255, 255, 0, 2, 3, 7, 6, wire);
  Face(0, 255, 0, 0, 4, 7, 3, wire);
  Face(255, 0, 0, 1, 2, 6, 5, wire)
END DrawCube;

PROCEDURE (c: CubeBox) Draw*;
  VAR t, s: REAL;
BEGIN
  c.lasttime := c.lasttime + c.speed;
  IF ~c.Valid() THEN
    FlGl.LoadIdentity;
    FlGl.Viewport(0, 0, c.PixelW(), c.PixelH());
    FlGl.Enable(FlGl.DepthTest);
    FlGl.Frustum(-1, 1, -1, 1, 2, 10000);
    FlGl.Translatef(0, 0, -10);
    FlGl.ClearColor(0.4, 0.4, 0.4, 0)
  END;
  FlGl.Clear(FlGl.ColorBufferBit + FlGl.DepthBufferBit);
  FlGl.PushMatrix;
  t := SHORT(c.lasttime); s := SHORT(c.size);
  FlGl.Rotatef(t * 1.6, 0, 0, 1);
  FlGl.Rotatef(t * 4.2, 1, 0, 0);
  FlGl.Rotatef(t * 2.3, 0, 1, 0);
  FlGl.Translatef(-1.0, 1.2, -1.5);
  FlGl.Scalef(s, s, s);
  DrawCube(c.wire);
  FlGl.PopMatrix;
  FlGl.Color(Fl.Gray);
  FlGl.Disable(FlGl.DepthTest);
  FlGl.Font(Fl.HelveticaBold, 16);
  IF c.wire THEN FlGl.DrawTextAt("Cube: wire", -4.5, -4.5)
  ELSE FlGl.DrawTextAt("Cube: flat", -4.5, -4.5)
  END;
  FlGl.Enable(FlGl.DepthTest);
  (* FLTK's widgets over the scene *)
  c.Draw^
END Draw;

PROCEDURE (c: CubeBox) Handle*(event: INTEGER): BOOLEAN;
BEGIN
  IF event = Fl.EvEnter THEN c.SetCursor(Fl.CursorCross)
  ELSIF event = Fl.EvLeave THEN c.SetCursor(Fl.CursorDefault)
  END;
  RETURN c.Handle^(event)
END Handle;

PROCEDURE (b: Info) Callback*;
  VAR s: ARRAY 200 OF CHAR;
BEGIN
  s := "This is an example of using FLTK widgets inside OpenGL windows.";
  OutStr.Ln(s);
  OutStr.String("Multiple widgets can be added to Fl_Gl_Windows. They will be", s);
  OutStr.Ln(s);
  OutStr.String("rendered as overlays over the scene.", s);
  FlDialogs.Message(s)
END Callback;

PROCEDURE Stats;
  VAR runtime: LONGREAL; buffer: ARRAY 120 OF CHAR;
BEGIN
  runtime := Now() - start;
  buffer := "Count =";
  OutStr.Int(count, 5, buffer);
  OutStr.String(", time = ", buffer); Fixed(runtime, 7, 3, buffer);
  OutStr.String(" sec, fps = ", buffer); Fixed(count / runtime, 5, 2, buffer);
  OutStr.String(", requested: ", buffer); Fixed(fps, 5, 2, buffer);
  Out.String(buffer); Out.Ln;
  CASE FlDialogs.Choice(buffer, "E&xit", "&Continue", "&Reset") OF
  | 0: form.Hide
  | 2: count := -2; Out.String("*** RESET ***"); Out.Ln
  ELSE
  END
END Stats;

PROCEDURE (b: Exit) Callback*;
BEGIN Stats
END Callback;

PROCEDURE (w: Form) Callback*;
BEGIN Stats
END Callback;

PROCEDURE Quit(w: Fl.Widget);
BEGIN Stats
END Quit;

PROCEDURE Tick(t: Fl.Timer);
BEGIN
  INC(count);
  IF count = 0 THEN start := Now() END;
  ltCube.Redraw;
  rtCube.Redraw;
  Fl.RepeatTimeout(t, delay)
END Tick;

PROCEDURE (s: Speed) Callback*;
BEGIN ltCube.speed := s.Value(); rtCube.speed := s.Value()
END Callback;

PROCEDURE (s: Size) Callback*;
BEGIN ltCube.size := s.Value(); rtCube.size := s.Value()
END Callback;

PROCEDURE (b: Flat) Callback*;
BEGIN ltCube.wire := ~b.Value(); rtCube.wire := b.Value()
END Callback;

PROCEDURE (b: Wire) Callback*;
BEGIN ltCube.wire := b.Value(); rtCube.wire := ~b.Value()
END Callback;

PROCEDURE SetCorner(i: INTEGER; x, y, z: REAL);
BEGIN vx[i] := x; vy[i] := y; vz[i] := z
END SetCorner;

PROCEDURE Print(w: Fl.Widget);
  VAR printer: FlPrint.Printer;
BEGIN
  NEW(printer); FlPrint.OpenPrinter(printer);
  IF printer.BeginJob(1) = 0 THEN
    printer.BeginPage;
    printer.Scale(0.5D0, 0.5D0);
    printer.DrawWidget(form, 0, 0);
    printer.EndPage;
    IF printer.EndJob() THEN END
  END;
  printer.Close
END Print;

(* A button on a GL window, which the window's Draw draws over the scene *)
PROCEDURE OverlayButton;
  VAR b: Info;
BEGIN
  NEW(b); FlButtons.OpenButton(b, 10, 10, 120, 30, "FLTK over GL");
  b.SetColor(Fl.FreeColor);
  b.SetBoxType(Fl.BorderBox)
END OverlayButton;

PROCEDURE NewCube(button: BOOLEAN): CubeBox;
  VAR c: CubeBox;
BEGIN
  NEW(c); FlGl.OpenGlWindowAt(c, 0, 0, 350, 350, "");
  c.SetBoxType(Fl.DownFrame);
  (* FLTK's GL window takes no children until told to *)
  IF button THEN c.Begin; OverlayButton; c.End END;
  RETURN c
END NewCube;

(* A form that gives resizing to the GL windows, the middle staying its
   size. *)
PROCEDURE MakeForm;
  VAR
    formW, formH, i: INTEGER;
    menubar: FlMenus.SysMenuBar;
    grid: FlLayout.Grid;
    exit: Exit;
BEGIN
  formW := 800 + 2 * margin + 2 * gap;
  formH := 350 + menubarH + 2 * margin;
  NEW(form); Fl.OpenWindow(form, formW, formH, "Cube Demo");

  NEW(menubar); FlMenus.OpenSysMenuBar(menubar, 0, 0, formW, menubarH, "");
  i := menubar.Add("File/Print window", ORD("p"), Fl.Command, Print, {});
  i := menubar.Add("File/Quit", ORD("q"), Fl.Command, Quit, {});

  NEW(grid); FlLayout.OpenGrid(grid, 0, menubarH, formW, 350 + 2 * margin, "");
  grid.SetLayout(4, 4);
  grid.SetMargins(margin, margin, margin, margin); grid.SetGap(gap, gap);
  grid.SetBoxType(Fl.FlatBox);
  grid.SetColWeight(0, 50); grid.SetColWeight(1, 0); grid.SetColWeight(2, 0); grid.SetColWeight(3, 50);
  grid.SetRowWeight(0, 0); grid.SetRowWeight(1, 0); grid.SetRowWeight(2, 50); grid.SetRowWeight(3, 0);
  grid.SetRowGap(0, 0);    (* none below the wire button *)
  grid.SetRowGap(2, 50);   (* room below the sliders for their labels *)

  ltCube := NewCube(TRUE);
  NEW(wire); FlButtons.OpenRadioLightButton(wire, 0, 0, 100, 25, "Wire");
  NEW(flat); FlButtons.OpenRadioLightButton(flat, 0, 0, 100, 25, "Flat");
  NEW(speed); FlValuators.OpenSlider(speed, 0, 0, 40, 90, "Speed");
  speed.SetKind(FlValuators.VertSlider);
  NEW(size); FlValuators.OpenSlider(size, 0, 0, 40, 90, "Size");
  size.SetKind(FlValuators.VertSlider);
  NEW(exit); FlButtons.OpenButton(exit, 0, 0, 100, 25, "Stats / E&xit");
  exit.SetTooltip("Display statistics (fps) and choose to exit or continue");
  rtCube := NewCube(FALSE);

  grid.PlaceSpan(ltCube, 0, 0, 4, 1, FlLayout.GridFill);
  grid.PlaceSpan(wire, 0, 1, 1, 2, FlLayout.GridFill);
  grid.PlaceSpan(flat, 1, 1, 1, 2, FlLayout.GridFill);
  grid.PlaceSpan(speed, 2, 1, 1, 1, FlLayout.GridVertical);
  grid.PlaceSpan(size, 2, 2, 1, 1, FlLayout.GridVertical);
  grid.PlaceSpan(exit, 3, 1, 1, 2, FlLayout.GridFill);
  grid.PlaceSpan(rtCube, 0, 3, 4, 1, FlLayout.GridFill);
  grid.End;

  form.End;
  form.SetResizable(grid);
  form.SizeRange(formW, formH, 0, 0)
END MakeForm;

BEGIN
  SetCorner(0, 0, 0, 0); SetCorner(1, 1, 0, 0); SetCorner(2, 1, 1, 0); SetCorner(3, 0, 1, 0);
  SetCorner(4, 0, 0, 1); SetCorner(5, 1, 0, 1); SetCorner(6, 1, 1, 1); SetCorner(7, 0, 1, 1);
  count := -2;
  FlGl.UseHighRes(TRUE);
  Fl.SetIndexColor(Fl.FreeColor, Fl.RGB(255, 255, 0) + 255 - 75);
  MakeForm;

  speed.SetBounds(6, 0);
  speed.SetValue(2); ltCube.speed := 2; rtCube.speed := 2;
  size.SetBounds(4, 0.2D0);
  size.SetValue(2); ltCube.size := 2; rtCube.size := 2;
  flat.SetValue(TRUE);
  wire.SetValue(FALSE);

  form.ShowArgs;
  ltCube.Show;
  rtCube.Show;
  ltCube.wire := FALSE;
  rtCube.wire := TRUE;
  ltCube.Redraw;
  rtCube.Redraw;

  form.WaitForExpose;
  NEW(timer); timer.action := Tick;
  Fl.AddTimeout(timer, 0.1D0);
  Fl.Run
END Cube.
