MODULE TestGlut; (* FlGlut: FLTK's GLUT emulation *)

IMPORT Fl, FlGl, FlGlut, Check, Probe;

CONST Limit = 500; (* of waits, so that valgrind has time *)

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
  FlGlut.ShowWindow;
  Waits;
  FlGlut.SetWindow(n);
  FlGlut.EstablishOverlay;
  FlGlut.UseLayer(FlGlut.Normal);
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
  win.Delete;
  Fl.Wait(0.0D0);
  Check.Summary
END TestGlut.
