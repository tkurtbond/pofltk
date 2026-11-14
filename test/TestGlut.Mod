MODULE TestGlut; (* FlGlut: FLTK's GLUT emulation *)

IMPORT SYSTEM, Fl, FlGl, FlGlut, Check, Probe;

CONST
  Limit = 500;  (* of waits, so that valgrind has time *)
  FontW = 200;  (* the area FontDisplay draws in *)
  FontH = 100;
  ColorClearValue = 0C22H;  (* GL's, for glGetFloatv *)
  GlVersion = 1F02H;        (* GL's, for glGetString *)

TYPE
  (* GL functions, called through GetProcAddress *)
  ClearColorProc = PROCEDURE (r, g, b, a: REAL);
  GetFloatvProc = PROCEDURE (pname: SYSTEM.INT32; v: SYSTEM.ADDRESS);
  GetStringProc = PROCEDURE (name: SYSTEM.INT32): SYSTEM.ADDRESS;

VAR
  win: FlGlut.Window;       (* a window with an object, for Probe *)
  outer: Fl.Window;
  n, n2, sub, m, m2: INTEGER;
  title: ARRAY 16 OF CHAR;
  ok: BOOLEAN;
  (* what the callbacks heard *)
  draws, red, reshapes, width, height, key, keyx, special, button, state,
  motions, passive, entries, entered, visible, invisible, idles, timer,
  picked, menuState, menuStatus, picks, hiding, rethinking, dying: INTEGER;
  answerPick: BOOLEAN;
  fontDraws, overlays, procDraws: INTEGER;
  pixels: ARRAY 3 * FontW * FontH OF CHAR;

PROCEDURE Display;
  VAR p: ARRAY 4 OF CHAR;
BEGIN
  INC(draws);
  FlGl.ClearColor(1.0, 0.0, 0.0, 1.0);
  FlGl.Clear(FlGl.ColorBufferBit);
  FlGl.Flush;
  FlGl.ReadPixels(1, 1, 1, 1, p);
  red := ORD(p[0]);
  FlGlut.SwapBuffers
END Display;

PROCEDURE OverlayDisplay;
BEGIN INC(overlays)
END OverlayDisplay;

(* Hides the current window, as it draws. *)
PROCEDURE Hiding;
BEGIN INC(hiding); FlGlut.HideWindow
END Hiding;

(* Hides the current window and thinks again, as it draws. *)
PROCEDURE Rethinking;
BEGIN
  INC(rethinking);
  FlGlut.HideWindow;
  FlGlut.FullScreen;     (* under Wayland, a wait for an expose, if not refused *)
  FlGlut.ShowWindow
END Rethinking;

(* Destroys the current window, as it draws. *)
PROCEDURE Dying;
BEGIN
  INC(dying);
  FlGlut.DestroyWindow(FlGlut.GetWindow())
END Dying;

PROCEDURE Reshape(w, h: INTEGER);
BEGIN INC(reshapes); width := w; height := h; FlGl.Viewport(0, 0, w, h)
END Reshape;

PROCEDURE Keyboard(c: CHAR; x, y: INTEGER);
BEGIN key := ORD(c); keyx := x
END Keyboard;

PROCEDURE Special(k, x, y: INTEGER);
BEGIN special := k
END Special;

PROCEDURE Mouse(b, s, x, y: INTEGER);
BEGIN button := b; state := s
END Mouse;

PROCEDURE Motion(x, y: INTEGER);
BEGIN INC(motions)
END Motion;

PROCEDURE Passive(x, y: INTEGER);
BEGIN INC(passive)
END Passive;

PROCEDURE Entry(s: INTEGER);
BEGIN INC(entries); entered := s
END Entry;

PROCEDURE Visibility(s: INTEGER);
BEGIN
  IF s = FlGlut.Visible THEN INC(visible) ELSE INC(invisible) END
END Visibility;

PROCEDURE Idle;
BEGIN INC(idles)
END Idle;

PROCEDURE Timed(v: INTEGER);
BEGIN timer := v
END Timed;

PROCEDURE Picked(v: INTEGER);
BEGIN picked := v; INC(picks)
END Picked;

PROCEDURE MenuState(s: INTEGER);
BEGIN menuState := s
END MenuState;

PROCEDURE MenuStatus(s, x, y: INTEGER);
BEGIN menuStatus := s
END MenuStatus;

(* Answers a pop-up menu: its first item, or none. *)
PROCEDURE Answer(v: INTEGER);
  VAR ok: BOOLEAN;
BEGIN
  IF answerPick THEN
    ok := Probe.HandleKey(win, Fl.EvKeyDown, Fl.KeyDown, {}, "");
    ok := Probe.HandleKey(win, Fl.EvKeyDown, Fl.KeyEnter, {}, 0DX)
  ELSE
    ok := Probe.HandleKey(win, Fl.EvKeyDown, Fl.KeyEscape, {}, 1BX)
  END
END Answer;

(* How many pixels of the area FontDisplay draws in are lit. *)
PROCEDURE Lit(): INTEGER;
  VAR i, c: INTEGER;
BEGIN
  FlGl.Flush;
  FlGl.ReadPixels(0, 0, FontW, FontH, pixels);
  c := 0;
  FOR i := 0 TO FontW * FontH - 1 DO
    IF ORD(pixels[3 * i]) > 100 THEN INC(c) END
  END;
  RETURN c
END Lit;

PROCEDURE Blank;
BEGIN
  FlGl.ClearColor(0.0, 0.0, 0.0, 1.0);
  FlGl.Clear(FlGl.ColorBufferBit);
  FlGl.Color3f(1.0, 1.0, 1.0);
  FlGl.LoadIdentity;
  FlGl.Ortho(0.0D0, FontW, 0.0D0, FontH, -1.0D0, 1.0D0);
  FlGl.DrawTextAt("", 40.0, 50.0);   (* sets the raster position *)
  FlGl.Translatef(40.0, 50.0, 0.0);
  FlGl.Scalef(0.25, 0.25, 1.0)
END Blank;

(* Its checks need a context, so they are made here, once. *)
PROCEDURE FontDisplay;
  VAR f, one: INTEGER; s: ARRAY 8 OF CHAR;
BEGIN
  IF fontDraws > 0 THEN RETURN END;
  INC(fontDraws);
  FlGl.Viewport(0, 0, FontW, FontH);
  FOR f := FlGlut.Bitmap9By15 TO FlGlut.BitmapHelvetica18 DO
    Blank;
    Check.Check(FlGlut.BitmapHeight(f) > 0, "a bitmap font's height");
    Check.Check(FlGlut.BitmapWidth(f, "A") > 0, "a character's width");
    Check.Check(FlGlut.BitmapLength(f, "AB") > FlGlut.BitmapWidth(f, "A"), "a string's length");
    Check.Check(FlGlut.BitmapLength(f, "") = 0, "an empty string's");
    FlGlut.BitmapString(f, "AB");
    Check.Check(Lit() > 0, "BitmapString draws")
  END;
  f := FlGlut.BitmapTimesRoman24;
  Check.Check(FlGlut.BitmapHeight(f) > FlGlut.BitmapHeight(FlGlut.BitmapTimesRoman10), "its sizes differ");
  Blank;
  FlGlut.BitmapCharacter(f, "A");
  one := Lit();
  Check.Check(one > 0, "BitmapCharacter draws");
  FlGlut.BitmapCharacter(f, "A");
  Check.Check(Lit() > one, "and moves on");

  (* a character past 7FX is the Unicode one BitmapWidth measures: FLTK
     would draw 80X to 9FX alone as CP1252's (doc/fltk-issues.md, 135) *)
  s[0] := 0C2X; s[1] := 80X; s[2] := 0X;
  Blank; FlGlut.BitmapString(f, s); one := Lit();
  Blank; FlGlut.BitmapCharacter(f, 80X);
  Check.Check((one > 0) & (Lit() = one), "BitmapCharacter(80X) draws U+0080");
  s[0] := 0C3X; s[1] := 0A9X;
  Blank; FlGlut.BitmapString(f, s); one := Lit();
  Blank; FlGlut.BitmapCharacter(f, 0E9X);
  Check.Check((one > 0) & (Lit() = one), "and 0E9X U+00E9");

  (* text with no width, which FLTK can't draw *)
  Blank;
  FlGlut.BitmapCharacter(f, 0X);
  FlGlut.BitmapCharacter(f, 0AX);
  s[0] := 0AX; s[1] := 0X;
  FlGlut.BitmapString(f, s);
  s[0] := 0E2X; s[1] := 80X; s[2] := 8BX; s[3] := 0X;   (* a zero-width space *)
  FlGlut.BitmapString(f, s);
  FlGlut.BitmapString(f, "");
  FlGl.Font(Fl.Helvetica, 14);
  FlGl.DrawText(s);
  FlGl.DrawTextAt(s, 40.0, 50.0);
  FlGl.DrawTextIn(s, 0, 0, FontW, FontH, {});
  Check.Check(TRUE, "text with no width doesn't crash");
  s[3] := 0AX; s[4] := "B"; s[5] := 0X;
  Blank;
  FlGl.DrawTextIn(s, 0, 0, FontW, FontH, {});
  Check.Check(Lit() > 0, "and DrawTextIn draws the line after it");

  Blank;
  FlGlut.StrokeString(FlGlut.StrokeRoman, "AB");
  Check.Check(Lit() > 0, "StrokeString draws");
  Blank;
  FlGlut.StrokeCharacter(FlGlut.StrokeMonoRoman, "A");
  one := Lit();
  Check.Check(one > 0, "StrokeCharacter draws");
  FlGlut.StrokeCharacter(FlGlut.StrokeMonoRoman, "A");
  Check.Check(Lit() > one, "and moves on");
  Blank;
  FlGlut.StrokeCharacter(FlGlut.StrokeRoman, 0C8X);
  FlGlut.StrokeString(FlGlut.StrokeRoman, "");
  Check.Check(Lit() = 0, "a character no stroke font has draws nothing");
  Check.Check(FlGl.GetError() = 0, "and GL has no complaint")
END FontDisplay;

PROCEDURE Waits;
BEGIN Fl.Wait(0.02D0)
END Waits;

PROCEDURE Draws;
  VAR d, i: INTEGER;
BEGIN
  d := draws; i := 0;
  WHILE (draws = d) & (i < Limit) DO Waits; INC(i) END
END Draws;

PROCEDURE Windows;
  VAR w: FlGlut.Window; i, c: INTEGER; ok: BOOLEAN; b: Fl.Box;
BEGIN
  FlGlut.InitDisplayMode(FlGlut.Rgb + FlGlut.Double + FlGlut.Depth);
  FlGlut.InitWindowSize(100, 80);
  Check.Check(FlGlut.Get(FlGlut.GetInitWindowWidth) = 100, "Get: the size for a new window");
  Check.Check(FlGlut.Get(FlGlut.GetInitDisplayMode) = FlGlut.Rgb + FlGlut.Double + FlGlut.Depth, "Get: its mode");
  Check.Check(FlGlut.Get(FlGlut.GetDisplayModePossible) # 0, "that mode can be had");
  Check.Check(FlGlut.Get(FlGlut.GetVersion) > 0, "Get: FLTK's GLUT version");
  Check.Check(FlGlut.DeviceGet(FlGlut.HasKeyboard) # 0, "a keyboard");
  Check.Check(FlGlut.DeviceGet(FlGlut.NumMouseButtons) = 3, "a mouse");
  title := "first";
  n := FlGlut.CreateWindow(title);
  title := "xxxxx";
  Check.Check(n >= 1, "CreateWindow gives a number");
  Check.Check(FlGlut.GetWindow() = n, "and it is current");
  Check.Check(FlGlut.WindowExists(n), "it exists");
  NEW(b); Fl.OpenBox(b, 0, 0, 10, 10, "");
  Check.Check(b.Parent() = NIL, "CreateWindow leaves no group current");
  b.Delete;

  FlGlut.DisplayFunc(Display);
  FlGlut.ReshapeFunc(Reshape);
  FlGlut.VisibilityFunc(Visibility);
  draws := 0;
  FlGlut.PostRedisplay;
  Draws;
  Check.Check(draws > 0, "the display procedure is called");
  Check.Check(red = 255, "and draws with GL");
  Check.Check(reshapes > 0, "reshape is called");
  Check.Check(FlGlut.Get(FlGlut.GetWindowWidth) = 100, "Get: its width");
  Check.Check(FlGlut.Get(FlGlut.GetWindowHeight) = 80, "Get: its height");
  Check.Check(FlGlut.Get(FlGlut.GetWindowParent) = 0, "Get: no parent");
  Check.Check(FlGlut.Get(FlGlut.GetWindowDoublebuffer) = 1, "Get: GL's answer");
  Check.Check(FlGlut.Get(FlGlut.GetWindowBufferSize) > 0, "Get: its bits");
  Check.Check(FlGlut.LayerGet(FlGlut.OverlayPossible) = 0, "LayerGet");

  FlGlut.ReshapeWindow(120, 90);
  FlGlut.PostRedisplay;
  Draws;
  (* a tiling compositor gives it the size it likes *)
  i := 0;
  WHILE (width # FlGlut.Get(FlGlut.GetWindowWidth)) & (i < Limit) DO Waits; INC(i) END;
  Check.Check(width = FlGlut.Get(FlGlut.GetWindowWidth), "reshape hears the size");
  Check.Check(Fl.Has(Fl.Wayland) OR (width = 120), "the size asked for");
  FlGlut.SetWindowTitle("second");
  FlGlut.SetIconTitle("icon");
  FlGlut.SetIconTitle("icon2");
  FlGlut.SetCursor(FlGlut.CursorInfo);
  FlGlut.PopWindow;
  Waits;

  n2 := FlGlut.CreateSubWindow(n, 5, 5, 30, 30);
  Check.Check((n2 # n) & FlGlut.WindowExists(n2), "a subwindow");
  Check.Check(FlGlut.Get(FlGlut.GetWindowParent) = n, "its parent");
  FlGlut.DisplayFunc(Display);
  FlGlut.SetWindow(n);
  Check.Check(FlGlut.GetWindow() = n, "SetWindow");
  FlGlut.PostWindowRedisplay(n2);
  Waits;

  FlGlut.SetWindow(n);   (* any event makes its window current *)
  FlGlut.HideWindow;
  i := 0;
  WHILE (invisible = 0) & (i < Limit) DO Waits; INC(i) END;
  Check.Check(invisible > 0, "visibility hears it hidden");
  (* the overlay is glDrawBuffer on the current context, so a hidden window
     takes it as a shown one does *)
  FlGlut.SetWindow(n);
  overlays := 0;
  FlGlut.OverlayDisplayFunc(OverlayDisplay);
  FlGlut.EstablishOverlay;
  FlGlut.UseLayer(FlGlut.Overlay);
  FlGlut.UseLayer(FlGlut.Normal);
  FlGlut.PostOverlayRedisplay;
  Check.Check(overlays = 0, "nor drawn while hidden");
  FlGlut.ShowWindow;
  i := 0;
  WHILE (overlays = 0) & (i < Limit) DO Waits; INC(i) END;
  Check.Check(overlays > 0, "an overlay established while hidden is drawn when shown");
  (* FLTK calls these unchecked; NIL draws nothing. Wayland redraws the
     subwindow with its parent. *)
  FlGlut.SetWindow(n2);
  FlGlut.DisplayFunc(NIL);
  FlGlut.SetWindow(n);
  FlGlut.OverlayDisplayFunc(NIL);
  FlGlut.DisplayFunc(NIL);
  draws := 0;
  FlGlut.PostRedisplay;
  FlGlut.PostOverlayRedisplay;
  Waits; Waits;
  Check.Check(draws = 0, "NIL display procedures draw nothing");
  FlGlut.SetWindow(n);
  FlGlut.RemoveOverlay;

  FlGlut.SetWindow(n);
  FlGlut.DestroyWindow(n);
  Check.Check(FlGlut.GetWindow() = 0, "no window is current after the current one goes");
  Check.Check(~FlGlut.WindowExists(n), "it is gone at once");
  Check.Check(~FlGlut.WindowExists(n2), "with its subwindow");
  ok := Fl.Check();

  (* with no current window, these do nothing *)
  FlGlut.PostRedisplay;
  FlGlut.SetWindowTitle("none");
  FlGlut.SetIconTitle("none");
  FlGlut.ReshapeWindow(1, 1);
  FlGlut.DisplayFunc(NIL);
  FlGlut.SwapBuffers;
  FlGlut.EstablishOverlay;
  FlGlut.UseLayer(FlGlut.Overlay);
  Check.Check(FlGlut.Get(FlGlut.GetWindowParent) = 0, "no current window");
  Check.Check(FlGlut.Get(FlGlut.GetWindowDoublebuffer) >= 0, "nor a GL query's junk");

  (* hidden as it draws *)
  n := FlGlut.CreateWindow("hiding");
  FlGlut.DisplayFunc(Hiding);
  FlGlut.VisibilityFunc(Visibility);
  invisible := 0;
  i := 0;
  WHILE (invisible = 0) & (i < Limit) DO Waits; INC(i) END;
  Check.Check((hiding > 0) & (invisible > 0), "a window can hide itself as it draws");
  Check.Check(FlGlut.WindowExists(n), "and stays");

  FlGlut.SetWindow(n);
  FlGlut.DisplayFunc(Rethinking);
  FlGlut.ShowWindow;
  invisible := 0;
  i := 0;
  WHILE (rethinking = 0) & (i < Limit) DO Waits; INC(i) END;
  Waits;
  Check.Check((rethinking > 0) & (invisible = 0), "or think again before the hiding is done");

  (* destroyed as it draws *)
  FlGlut.SetWindow(n);
  FlGlut.DisplayFunc(Dying);
  FlGlut.PostRedisplay;
  i := 0;
  WHILE (dying = 0) & (i < Limit) DO Waits; INC(i) END;
  Check.Check(dying = 1, "a window can destroy itself as it draws");
  Check.Check(~FlGlut.WindowExists(n), "and goes");
  Waits;
  Waits;

  (* every window FLTK has, as objects *)
  c := 0; ok := TRUE;
  NEW(outer); Fl.OpenWindow(outer, 100, 100, "");
  WHILE c < 31 DO
    NEW(w); FlGlut.OpenWindowAt(w, 0, 0, 10, 10, "");
    w.End;
    ok := ok & (w.Number() = c + 1);
    INC(c)
  END;
  outer.End;
  Check.Check(ok, "31 windows, numbered from 1");
  outer.Delete;
  Check.Check(~FlGlut.WindowExists(1), "which go with their parent")
END Windows;

PROCEDURE Events;
  VAR ok: BOOLEAN;
BEGIN
  NEW(win);
  FlGlut.OpenWindow(win, 100, 80, "");
  win.End;
  win.MakeCurrent;
  Check.Check(FlGlut.GetWindow() = win.Number(), "MakeCurrent before it is shown");
  FlGlut.DisplayFunc(Display);
  FlGlut.KeyboardFunc(Keyboard);
  FlGlut.SpecialFunc(Special);
  FlGlut.MouseFunc(Mouse);
  FlGlut.MotionFunc(Motion);
  FlGlut.PassiveMotionFunc(Passive);
  FlGlut.EntryFunc(Entry);
  win.Show;
  win.WaitForExpose;
  draws := 0;
  win.Redraw;
  Draws;
  Check.Check(draws > 0, "a Window's display procedure");
  win.MakeCurrent;
  FlGlut.HideWindow;
  FlGlut.ShowWindow;
  Waits;
  Check.Check(win.Shown(), "hidden and shown again");

  ok := Probe.Mouse(win, Fl.EvPush, 10, 11, 3, {}, 1);
  Check.Check(ok & (button = FlGlut.RightButton) & (state = FlGlut.Down), "mouse: a push");
  ok := Probe.Mouse(win, Fl.EvDrag, 12, 11, 3, {}, 1);
  Check.Check(motions = 1, "motion");
  ok := Probe.Mouse(win, Fl.EvRelease, 12, 11, 3, {}, 1);
  Check.Check(state = FlGlut.Up, "mouse: a release");
  ok := Probe.Mouse(win, Fl.EvMove, 13, 11, 0, {}, 0);
  Check.Check(passive = 1, "passive motion");
  ok := Probe.Wheel(win, 13, 11, 0, 1);
  Check.Check(button = 4, "the wheel is a fifth button");

  Fl.SetFocus(win);
  ok := Probe.Key(Fl.EvKeyDown, ORD("q"), {}, "q");
  Check.Check(ok & (key = ORD("q")), "keyboard");
  ok := Probe.Key(Fl.EvKeyDown, 233, {}, 0E9X);
  Check.Check(ok & (key = 233), "keyboard: a key above 127");
  ok := Probe.Key(Fl.EvKeyDown, Fl.KeyF + 2, {}, "");
  Check.Check(ok & (special = FlGlut.KeyF2), "special: F2");
  ok := Probe.Key(Fl.EvKeyDown, Fl.KeyLeft, {}, "");
  Check.Check(ok & (special = FlGlut.KeyLeft), "special: left");

  FlGlut.KeyboardFunc(NIL);
  FlGlut.SpecialFunc(NIL);
  FlGlut.MouseFunc(NIL);
  FlGlut.MotionFunc(NIL);
  FlGlut.PassiveMotionFunc(NIL);
  FlGlut.EntryFunc(NIL)
END Events;

PROCEDURE Menus;
  VAR i: INTEGER;
BEGIN
  Check.Check(FlGlut.GetMenu() = 0, "no menu to start with");
  Check.Check(FlGlut.Get(FlGlut.GetMenuNumItems) = 0, "and no items");
  sub := FlGlut.CreateMenu(Picked);
  title := "one";
  FlGlut.AddMenuEntry(title, 1);
  title := "xxx";
  FlGlut.AddMenuEntry("two", 2);
  m := FlGlut.CreateMenu(Picked);
  Check.Check(FlGlut.GetMenu() = m, "a menu made is current");
  FlGlut.AddMenuEntry("top", 3);
  FlGlut.AddSubMenu("more", sub);
  Check.Check(FlGlut.Get(FlGlut.GetMenuNumItems) = 2, "it has what was added");
  FlGlut.ChangeToMenuEntry(1, "changed", 4);
  FlGlut.ChangeToSubMenu(2, "again", sub);

  (* removing with the array just full reads past it (issue 112) *)
  m2 := FlGlut.CreateMenu(Picked);
  FOR i := 1 TO 9 DO FlGlut.AddMenuEntry("item", i) END;
  FlGlut.RemoveMenuItem(1);
  Check.Check(FlGlut.Get(FlGlut.GetMenuNumItems) = 8, "RemoveMenuItem");
  FlGlut.AddMenuEntry("item", 10);
  FlGlut.RemoveMenuItem(9);
  Check.Check(FlGlut.Get(FlGlut.GetMenuNumItems) = 8, "the last item too");
  FlGlut.DestroyMenu(m2);
  Check.Check(FlGlut.GetMenu() = 0, "a menu destroyed isn't current");
  FlGlut.SetMenu(m);
  FlGlut.MenuStateFunc(MenuState);
  win.MakeCurrent;
  FlGlut.AttachMenu(FlGlut.LeftButton);

  (* as in TestMenus, X11 alone: doc/fltk-issues.md, 29 *)
  IF ~Fl.Has(Fl.Wayland) THEN
    answerPick := TRUE;
    FlGlut.TimerFunc(200, Answer, 0);
    ok := Probe.Mouse(win, Fl.EvPush, 10, 10, 1, {}, 1);
    Check.Check((picks = 1) & (picked = 4), "a menu pops up, and calls back");
    Check.Check(menuState = FlGlut.MenuNotInUse, "the menu state is heard");
    ok := Probe.Mouse(win, Fl.EvRelease, 10, 10, 1, {}, 1);
    answerPick := FALSE;
    FlGlut.TimerFunc(200, Answer, 0);
    ok := Probe.Mouse(win, Fl.EvPush, 10, 10, 1, {}, 1);
    Check.Check(picks = 1, "or doesn't, closed");
    ok := Probe.Mouse(win, Fl.EvRelease, 10, 10, 1, {}, 1)
  ELSE
    Check.Skip("GLUT's pop-up menus: under Wayland the compositor closes them")
  END;

  FlGlut.DestroyMenu(m);
  FlGlut.DestroyMenu(sub);
  button := -1;
  FlGlut.MouseFunc(Mouse);
  ok := Probe.Mouse(win, Fl.EvPush, 10, 10, 1, {}, 1);
  Check.Check(button = FlGlut.LeftButton, "a window's button after its menu goes");
  ok := Probe.Mouse(win, Fl.EvRelease, 10, 10, 1, {}, 1)
END Menus;

PROCEDURE Fonts;
  VAR w, i: INTEGER; s: ARRAY 8 OF CHAR;
BEGIN
  (* the stroke fonts are data, and need no window *)
  Check.Check(FlGlut.StrokeWidth(FlGlut.StrokeRoman, "A") = 80, "a stroke character's width");
  Check.Check(FlGlut.StrokeWidth(FlGlut.StrokeMonoRoman, "A") = 105, "a monospaced one's");
  Check.Check(FlGlut.StrokeWidth(FlGlut.StrokeRoman, 0C8X) = 0, "one it hasn't");
  Check.Check(FlGlut.StrokeLength(FlGlut.StrokeRoman, "AB") = 164, "a string's length");
  Check.Check(FlGlut.StrokeLength(FlGlut.StrokeMonoRoman, "AB") = 210, "a monospaced one's");
  Check.Check(FlGlut.StrokeLength(FlGlut.StrokeRoman, "") = 0, "an empty one's");
  s[0] := "A"; s[1] := "B"; s[2] := 0AX; s[3] := "A"; s[4] := 0X;
  Check.Check(FlGlut.StrokeLength(FlGlut.StrokeRoman, s) = 164, "its longest line");
  Check.Check(ENTIER(FlGlut.StrokeHeight(FlGlut.StrokeRoman)) = 152, "a stroke font's height");
  Check.Check(ENTIER(FlGlut.StrokeHeight(FlGlut.StrokeMonoRoman)) = 152, "the other's");

  FlGlut.InitDisplayMode(FlGlut.Rgb + FlGlut.Double);
  FlGlut.InitWindowSize(FontW, FontH);
  w := FlGlut.CreateWindow("fonts");
  FlGlut.DisplayFunc(FontDisplay);
  fontDraws := 0;
  FlGlut.PostRedisplay;
  i := 0;
  WHILE (fontDraws = 0) & (i < Limit) DO Waits; INC(i) END;
  Check.Check(fontDraws > 0, "the fonts were drawn");
  FlGlut.DestroyWindow(w);
  Waits
END Fonts;

(* GL called through GetProcAddress: floats, a pointer passed and a pointer
   returned. Its checks need a context, so they are made here, once. *)
PROCEDURE ProcDisplay;
  VAR
    clearColor: ClearColorProc; getFloatv: GetFloatvProc;
    getString: GetStringProc;
    v: ARRAY 4 OF REAL; p: ARRAY 4 OF CHAR;
    version, mine: ARRAY 256 OF CHAR;
    a: SYSTEM.ADDRESS; i: INTEGER; c: CHAR;
BEGIN
  IF procDraws > 0 THEN RETURN END;
  INC(procDraws);
  clearColor := SYSTEM.VAL(ClearColorProc, FlGlut.GetProcAddress("glClearColor"));
  getFloatv := SYSTEM.VAL(GetFloatvProc, FlGlut.GetProcAddress("glGetFloatv"));
  getString := SYSTEM.VAL(GetStringProc, FlGlut.GetProcAddress("glGetString"));
  clearColor(0.25, 0.5, 0.75, 1.0);
  getFloatv(ColorClearValue, SYSTEM.ADR(v));
  Check.Check((v[0] = 0.25) & (v[1] = 0.5) & (v[2] = 0.75) & (v[3] = 1.0),
    "glClearColor and glGetFloatv, called by their addresses");
  FlGl.Clear(FlGl.ColorBufferBit);
  FlGl.Flush;
  FlGl.ReadPixels(1, 1, 1, 1, p);
  Check.Check((ABS(ORD(p[0]) - 64) <= 1) & (ABS(ORD(p[1]) - 128) <= 1)
    & (ABS(ORD(p[2]) - 191) <= 1), "and the colour they set");
  a := getString(GlVersion);
  i := 0;
  IF a # 0 THEN
    REPEAT SYSTEM.GET(a + i, c); mine[i] := c; INC(i)
    UNTIL (c = 0X) OR (i = LEN(mine))
  END;
  mine[LEN(mine) - 1] := 0X;
  FlGl.Version(version);
  Check.Check((version # "") & (mine = version), "glGetString, by its address")
END ProcDisplay;

PROCEDURE Procs;
  VAR w, i: INTEGER;
BEGIN
  Check.Check(FlGlut.GetProcAddress("glClearColor") # 0,
    "a GL function's address, with no context");
  FlGlut.InitDisplayMode(FlGlut.Rgb + FlGlut.Single);
  FlGlut.InitWindowSize(FontW, FontH);
  w := FlGlut.CreateWindow("procs");
  FlGlut.DisplayFunc(ProcDisplay);
  procDraws := 0;
  FlGlut.PostRedisplay;
  i := 0;
  WHILE (procDraws = 0) & (i < Limit) DO Waits; INC(i) END;
  Check.Check(procDraws > 0, "GL was called by address");
  FlGlut.DestroyWindow(w);
  Waits
END Procs;

PROCEDURE Timers;
  VAR i: INTEGER;
BEGIN
  FlGlut.TimerFunc(1, Timed, 42);
  i := 0;
  WHILE (timer = 0) & (i < Limit) DO Waits; INC(i) END;
  Check.Check(timer = 42, "a timer, with its value");
  FlGlut.IdleFunc(Idle);
  i := 0;
  WHILE (idles = 0) & (i < Limit) DO Waits; INC(i) END;
  FlGlut.IdleFunc(NIL);
  Check.Check(idles > 0, "idle");
  Check.Check(FlGlut.Get(FlGlut.GetElapsedTime) > 0, "elapsed time")
END Timers;

BEGIN
  FlGlut.Init;
  Windows;
  Events;
  Menus;
  Timers;
  Fonts;
  Procs;
  win.Delete;
  Fl.Wait(0.0D0);
  Check.Summary
END TestGlut.
