MODULE Fullscreen; (* FLTK's test/fullscreen.cxx in Oberon-2 *)

(* A window's border, full screen and maximized states, and the screens'
   sizes. -2 puts the GL shape in a window of its own; -f starts full
   screen. *)

IMPORT SYSTEM, Args, Err, Fl, FlGl, FlButtons, FlInputs, FlValuators,
  FlBrowsers, MathL, RealDigits, OutStr;

CONST numb = 9;  (* the rows of controls *)

TYPE
  ShapeWindow = POINTER TO RECORD (FlGl.GlWindowDesc) sides: INTEGER END;
  FullscreenWindow = POINTER TO RECORD (Fl.SingleWindowDesc)
    borderButton, maximizeButton, fullscreenButton,
    allscreensButton: FlButtons.LightButton
  END;
  AfterResize = POINTER TO RECORD (Fl.TimerDesc) win: FullscreenWindow END;
  Sides = POINTER TO RECORD (FlValuators.SliderDesc) END;
  Double = POINTER TO RECORD (FlButtons.LightButtonDesc) END;
  Border = POINTER TO RECORD (FlButtons.LightButtonDesc) END;
  Full = POINTER TO RECORD (FlButtons.LightButtonDesc) END;
  Max = POINTER TO RECORD (FlButtons.LightButtonDesc) END;
  AllScreens = POINTER TO RECORD (FlButtons.LightButtonDesc) END;

VAR
  window: FullscreenWindow;
  after: AfterResize;
  sw: ShapeWindow;
  w: Fl.Window;  (* the window the buttons act on *)
  browser: FlBrowsers.Browser;
  slider: Sides;
  b1: Double;
  border: Border;
  full: Full;
  max: Max;
  all: AllScreens;
  i1: FlInputs.Input;
  eb, update: FlButtons.Button;
  twowindow, initfull, ok: BOOLEAN;
  i, y: INTEGER;
  help: ARRAY 1024 OF CHAR;

PROCEDURE (s: ShapeWindow) Draw*;
  VAR j: INTEGER; ang: LONGREAL;
BEGIN
  IF ~s.Valid() THEN
    s.SetValid(TRUE);
    FlGl.LoadIdentity;
    FlGl.Viewport(0, 0, s.PixelW(), s.PixelH())
  END;
  FlGl.Clear(FlGl.ColorBufferBit);
  FlGl.Color3f(0.5, 0.6, 0.7);
  FlGl.Begin(FlGl.Polygon);
  FOR j := 0 TO s.sides - 1 DO
    ang := j * 2 * MathL.pi / s.sides;
    FlGl.Vertex3f(SHORT(MathL.cos(ang)), SHORT(MathL.sin(ang)), 0.0)
  END;
  FlGl.End
END Draw;

(* The buttons follow the window's state once it has settled. *)
PROCEDURE (t: AfterResize) Fire*;
BEGIN
  t.win.maximizeButton.SetValue(t.win.MaximizeActive());
  t.win.maximizeButton.Redraw;
  t.win.fullscreenButton.SetValue(t.win.FullscreenActive());
  t.win.fullscreenButton.Redraw
END Fire;

PROCEDURE (f: FullscreenWindow) Resize*(x, y, w, h: INTEGER);
BEGIN
  f.Resize^(x, y, w, h);
  Fl.AddTimeout(after, 0.0D0)
END Resize;

PROCEDURE (s: Sides) Callback*;
BEGIN sw.sides := SHORT(ENTIER(s.Value())); sw.Redraw
END Callback;

PROCEDURE (b: Double) Callback*;
BEGIN
  IF b.Value() THEN ok := sw.SetMode(FlGl.Double + FlGl.Rgb)
  ELSE ok := sw.SetMode(FlGl.Rgb)
  END
END Callback;

PROCEDURE (b: Border) Callback*;
  VAR d: BOOLEAN;
BEGIN
  d := b.Value(); w.SetBorder(d);
  IF w.Border() # d THEN b.SetValue(w.Border()) END
END Callback;

PROCEDURE (b: Max) Callback*;
BEGIN
  IF w.FullscreenActive() THEN b.SetValue(~b.Value())
  ELSIF w.MaximizeActive() THEN w.UnMaximize
  ELSE w.Maximize
  END
END Callback;

PROCEDURE (b: Full) Callback*;
BEGIN
  IF w.MaximizeActive() THEN b.SetValue(~b.Value())
  ELSIF b.Value() THEN w.Fullscreen
  ELSE w.FullscreenOff
  END
END Callback;

(* Full screen over the screens at the top, bottom, left and right. *)
PROCEDURE (b: AllScreens) Callback*;
  VAR top, bottom, left, right, topY, bottomY, leftX, rightX,
    sx, sy, sw, sh, i: INTEGER;
BEGIN
  IF b.Value() THEN
    top := 0; bottom := 0; left := 0; right := 0;
    Fl.ScreenXYWH(0, sx, sy, sw, sh);
    topY := sy; bottomY := sy + sh; leftX := sx; rightX := sx + sw;
    FOR i := 1 TO Fl.ScreenCount() - 1 DO
      Fl.ScreenXYWH(i, sx, sy, sw, sh);
      IF sy < topY THEN top := i; topY := sy END;
      IF sy + sh > bottomY THEN bottom := i; bottomY := sy + sh END;
      IF sx < leftX THEN left := i; leftX := sx END;
      IF sx + sw > rightX THEN right := i; rightX := sx + sw END
    END;
    w.FullscreenScreens(top, bottom, left, right)
  ELSE w.FullscreenScreens(-1, -1, -1, -1)
  END
END Callback;

(* v as "%.nf" writes it, n from 0 up. *)
PROCEDURE Fixed(v: LONGREAL; n: INTEGER; VAR s: ARRAY OF CHAR);
  VAR d: ARRAY 40 OF CHAR; count, e, p: INTEGER;

  PROCEDURE Digit(p: INTEGER);   (* the digit of 10^p *)
  BEGIN
    IF (e - p >= 0) & (e - p < count) THEN OutStr.Char(d[e - p], s) ELSE OutStr.Char("0", s) END
  END Digit;

BEGIN
  IF SYSTEM.VAL(HUGEINT, v) < 0 THEN OutStr.Char("-", s); v := -v END;  (* -0 too *)
  IF v = 0.0D0 THEN count := 0; e := 0 ELSE RealDigits.Fixed(v, n, 30, d, count, e) END;
  p := e; IF p < 0 THEN p := 0 END;
  WHILE p >= 0 DO Digit(p); DEC(p) END;
  IF n > 0 THEN
    OutStr.Char(".", s);
    FOR p := -1 TO -n BY -1 DO Digit(p) END
  END
END Fixed;

PROCEDURE Area(x, y, w, h: INTEGER; VAR s: ARRAY OF CHAR);
BEGIN
  OutStr.Int(w, 0, s); OutStr.Char("x", s); OutStr.Int(h, 0, s);
  OutStr.Char("@", s); OutStr.Int(x, 0, s); OutStr.Char(",", s); OutStr.Int(y, 0, s)
END Area;

PROCEDURE UpdateScreenInfo(b: Fl.Widget);
  VAR x, y, w, h, mx, my, n: INTEGER; dpih, dpiv: LONGREAL;
    line: ARRAY 128 OF CHAR;
BEGIN
  browser.Clear;
  line := "Main screen work area: ";
  Area(Fl.ScreenX(), Fl.ScreenY(), Fl.ScreenW(), Fl.ScreenH(), line);
  browser.Add(line);
  (* FLTK's screen_work_area(x, y, w, h): the mouse's screen *)
  Fl.GetMouse(mx, my); Fl.ScreenWorkArea(Fl.ScreenAt(mx, my), x, y, w, h);
  line := "Mouse screen work area: "; Area(x, y, w, h, line);
  browser.Add(line);
  FOR n := 0 TO Fl.ScreenCount() - 1 DO
    Fl.ScreenXYWH(n, x, y, w, h);
    Fl.ScreenDPI(n, dpih, dpiv);
    line := "Screen "; OutStr.Int(n, 0, line); OutStr.String(": ", line);
    Area(x, y, w, h, line);
    OutStr.String(" DPI:", line); Fixed(dpih, 1, line);
    OutStr.Char("x", line); Fixed(dpiv, 1, line);
    OutStr.String(" scale:", line); Fixed(Fl.ScreenScale(n), 2, line);
    browser.Add(line);
    Fl.ScreenWorkArea(n, x, y, w, h);
    line := "Work area "; OutStr.Int(n, 0, line); OutStr.String(": ", line);
    Area(x, y, w, h, line);
    browser.Add(line)
  END
END UpdateScreenInfo;

PROCEDURE Exit(b: Fl.Widget);
BEGIN HALT(0)
END Exit;

PROCEDURE Arg(i: INTEGER): INTEGER;
  VAR s: ARRAY 4 OF CHAR;
BEGIN
  Args.Get(i, s);
  IF s[1] = "2" THEN twowindow := TRUE; RETURN 1 END;
  IF s[1] = "f" THEN initfull := TRUE; RETURN 1 END;
  RETURN 0
END Arg;

PROCEDURE LightButton(b: FlButtons.LightButton; label: ARRAY OF CHAR);
BEGIN
  FlButtons.OpenLightButton(b, 50, y, window.W() - 60, 30, label); INC(y, 30)
END LightButton;

BEGIN
  FlGl.UseHighRes(TRUE);
  IF ~Fl.ParseArgs(Arg, i) OR (i < Args.argc) THEN
    Fl.ArgsHelp(help);
    Err.String("Options are:"); Err.Ln;
    Err.String(" -2 = 2 windows"); Err.Ln;
    Err.String(" -f = startup fullscreen"); Err.Ln;
    Err.String(help); Err.Ln; HALT(1)
  END;

  NEW(window); Fl.OpenSingleWindow(window, 460, 400 + 30 * numb, ""); window.End;
  NEW(after); after.win := window;

  NEW(sw); FlGl.OpenGlWindowAt(sw, 10, 10, window.W() - 20, window.H() - 30 * numb - 120, "");
  sw.sides := 3;
  sw.SetVisible(TRUE);  (* necessary because sw is not a child of window *)
  ok := sw.SetMode(FlGl.Rgb);

  IF twowindow THEN  (* make its own window *)
    sw.SetResizable(sw);
    w := sw;
    window.SetModal;  (* makes controls stay on top when fullscreen pushed *)
    sw.Show
  ELSE  (* otherwise make a subwindow *)
    window.Add(sw);
    window.SetResizable(sw);
    w := window
  END;

  window.Begin;

  y := window.H() - 30 * numb - 105;
  NEW(slider); FlValuators.OpenHorSlider(slider, 50, y, window.W() - 60, 30, "Sides:");
  slider.SetAlign(Fl.AlignLeft);
  slider.SetValue(sw.sides);
  slider.SetStep(1.0D0);
  slider.SetBounds(3.0D0, 40.0D0);
  INC(y, 30);

  NEW(b1); LightButton(b1, "Double Buffered");

  NEW(i1); FlInputs.OpenInput(i1, 50, y, window.W() - 60, 30, "Input");
  INC(y, 30);

  NEW(border); LightButton(border, "Border"); window.borderButton := border;
  border.SetValue(TRUE);

  NEW(full); LightButton(full, "FullScreen"); window.fullscreenButton := full;

  NEW(max); LightButton(max, "Maximize"); window.maximizeButton := max;

  NEW(all); LightButton(all, "All Screens"); window.allscreensButton := all;

  NEW(eb); FlButtons.OpenButton(eb, 50, y, window.W() - 60, 30, "Exit");
  eb.action := Exit;
  INC(y, 30);

  NEW(browser); FlBrowsers.OpenBrowser(browser, 50, y, window.W() - 60, 100, "");
  UpdateScreenInfo(NIL);
  INC(y, 100);

  NEW(update); FlButtons.OpenButton(update, 50, y, window.W() - 60, 30, "Update");
  update.action := UpdateScreenInfo;
  INC(y, 30);

  IF initfull THEN full.SetValue(TRUE); full.DoCallback END;

  window.End;
  window.ShowArgs;
  Fl.Run
END Fullscreen.
