MODULE OpenGL3Test; (* FLTK's examples/OpenGL3test.cxx: a quad drawn by OpenGL 3 shaders, under FLTK's buttons *)

(* The shaders are in GlThree, in C++, which also has GLEW. A click on the
   quad reshapes it; the text says what happened; the light button remakes
   the window, and so its context, with one buffer or two. *)

IMPORT Fl, FlButtons, FlGl, FlText, GlThree, OutStr, SYSTEM;

TYPE
  Gl3Window = POINTER TO RECORD (FlGl.GlWindowDesc)
    major: INTEGER
  END;

  Double = POINTER TO RECORD (FlButtons.LightButtonDesc) END;

  Named = POINTER TO RECORD (FlButtons.ButtonDesc)
    name: ARRAY 16 OF CHAR
  END;

VAR
  win: Gl3Window;
  output: FlText.TextDisplay;
  buffer: FlText.TextBuffer;
  first: BOOLEAN;

PROCEDURE AddOutput(s-: ARRAY OF CHAR);
BEGIN
  buffer.Append(s);
  output.Scroll(10000, 0);
  output.Redraw
END AddOutput;

PROCEDURE AddLine(name-, text-: ARRAY OF CHAR);
  VAR s: ARRAY 256 OF CHAR;
BEGIN
  s := "";
  OutStr.String(name, s); OutStr.String(text, s); OutStr.Ln(s);
  AddOutput(s)
END AddLine;

PROCEDURE (w: Gl3Window) Draw*;
  VAR log: ARRAY 4000 OF CHAR;
BEGIN
  IF (w.major >= 3) & ~GlThree.HasQuad() THEN
    GlThree.MakeQuad(log); AddOutput(log)
  ELSIF ~w.Valid() THEN
    FlGl.Viewport(0, 0, w.PixelW(), w.PixelH())
  END;
  FlGl.ClearColor(0.08, 0.8, 0.8, 1.0);
  FlGl.Clear(FlGl.ColorBufferBit);
  GlThree.DrawQuad;
  (* FLTK's widgets over the scene *)
  w.Draw^
END Draw;

(* What happens once, with the window's first context. *)
PROCEDURE Start(w: Gl3Window);
  VAR s: ARRAY 128 OF CHAR; ok: BOOLEAN;
BEGIN
  w.MakeCurrent;
  IF GlThree.InitGlew() THEN
    GlThree.GlewVersion(s); AddLine("Using GLEW ", s)
  END;
  FlGl.Version(s);
  AddLine("GL_VERSION=", s);
  w.major := GlThree.GlMajor();
  IF w.major < 3 THEN
    s := "";
    OutStr.Ln(s); OutStr.String("This platform does not support OpenGL V3 :", s); OutStr.Ln(s);
    AddOutput(s);
    AddLine("FLTK widgets will appear but the programmed rendering pipeline will not run.", "");
    ok := w.SetMode(w.Mode() - FlGl.OpenGL3)
  END;
  w.Redraw
END Start;

PROCEDURE (w: Gl3Window) Handle*(event: INTEGER): BOOLEAN;
  VAR used: BOOLEAN; s: ARRAY 64 OF CHAR; tenths: INTEGER;
BEGIN
  IF first & (event = Fl.EvShow) & w.Shown() THEN
    first := FALSE; Start(w)
  END;
  used := w.Handle^(event);
  IF ~used & (event = Fl.EvPush) & (w.major >= 3) THEN
    w.MakeCurrent;
    GlThree.PushQuad;
    w.Redraw;
    tenths := SHORT(ENTIER(10 * w.PixelsPerUnit() + 0.5));
    s := "";
    OutStr.Int(tenths DIV 10, 0, s); OutStr.Char(".", s); OutStr.Int(tenths MOD 10, 0, s);
    AddLine("push  Fl_Gl_Window::pixels_per_unit()=", s);
    used := TRUE
  END;
  RETURN used
END Handle;

PROCEDURE (b: Double) Callback*;
  VAR flags: INTEGER; ok: BOOLEAN;
BEGIN
  flags := win.Mode();
  IF b.Value() THEN flags := SYSTEM.VAL(INTEGER, SYSTEM.VAL(SET, flags) + SYSTEM.VAL(SET, FlGl.Double))
  ELSE flags := SYSTEM.VAL(INTEGER, SYSTEM.VAL(SET, flags) - SYSTEM.VAL(SET, FlGl.Double))
  END;
  GlThree.ResetQuad;
  FlGl.TextureReset;
  win.Hide;
  ok := win.SetMode(flags);
  win.Show
END Callback;

PROCEDURE (b: Named) Callback*;
  VAR s: ARRAY 64 OF CHAR;
BEGIN
  s := "run ";
  OutStr.String(b.name, s); OutStr.String(" callback", s); OutStr.Ln(s);
  AddOutput(s)
END Callback;

PROCEDURE AddButton(y, box: INTEGER; name-: ARRAY OF CHAR);
  VAR b: Named;
BEGIN
  NEW(b); FlButtons.OpenButton(b, 0, y, 60, 30, name);
  COPY(name, b.name);
  b.SetColor(Fl.FreeColor);
  b.SetBoxType(box)
END AddButton;

PROCEDURE OutputWin;
  VAR lb: Double;
BEGIN
  NEW(output); FlText.OpenTextDisplay(output, 300, 0, 500, 280, "");
  NEW(lb); FlButtons.OpenLightButton(lb, 300, 280, 500, 20, "Double-Buffered");
  lb.SetValue(TRUE);
  NEW(buffer); FlText.OpenBuffer(buffer);
  output.SetBuffer(buffer)
END OutputWin;

PROCEDURE AddWidgets;
BEGIN
  Fl.SetIndexColor(Fl.FreeColor, Fl.RGB(255, 255, 255) + 255 - 140);  (* partly transparent *)
  win.Begin;
  AddButton(0, Fl.DownBox, "button");
  AddButton(170, Fl.BorderBox, "button2");
  win.End
END AddWidgets;

PROCEDURE Main;
  VAR topwin: Fl.Window; ok: BOOLEAN;
BEGIN
  FlGl.UseHighRes(TRUE);
  NEW(topwin); Fl.OpenWindow(topwin, 800, 300, "Click GL panel to reshape");
  NEW(win); FlGl.OpenGlWindowAt(win, 0, 0, 300, 300, "");
  ok := win.SetMode(FlGl.Rgb8 + FlGl.Double + FlGl.OpenGL3);
  OutputWin;
  AddWidgets;
  topwin.End;
  topwin.SetResizable(win);
  topwin.ShowArgs;
  Fl.Run
END Main;

BEGIN
  first := TRUE;
  Main
END OpenGL3Test.
