MODULE TestStatics; (* Fl's statics: colors, box types, fonts, time, windows, the selection and the rest *)

IMPORT SYSTEM, Fl, FlDraw, Strings, Check, Probe;

TYPE
  Shown = POINTER TO RECORD (Fl.WindowDesc) closes: INTEGER END;
  Owner = POINTER TO RECORD (Fl.BoxDesc) cleared: INTEGER END;
  Ticker = POINTER TO RECORD (Fl.CheckerDesc) runs: INTEGER END;

VAR
  told, closing, custom, drawn, first, second: INTEGER;
  overBox, activeInBox: BOOLEAN;
  name: ARRAY 256 OF CHAR;
  long: ARRAY 400 OF CHAR;

PROCEDURE Equal(a-, b-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN a = b
END Equal;

PROCEDURE (c: Ticker) Run*;
BEGIN INC(c.runs)
END Run;

PROCEDURE CountAction(c: Fl.Checker);
BEGIN INC(told); Fl.RemoveCheck(c)
END CountAction;

PROCEDURE TestLoop;
  VAR c: Ticker; a: Fl.Checker; r: BOOLEAN;
BEGIN
  NEW(c);
  Check.Check(~c.Added(), "a checker starts out not added");
  Fl.AddCheck(c); Fl.AddCheck(c);
  Check.Check(c.Added(), "AddCheck adds");
  Fl.RunChecks;
  Check.Check(c.runs = 1, "RunChecks runs it, added twice, once");
  Fl.Wait(0.0D0);
  Check.Check(c.runs >= 2, "the loop runs it");
  Fl.RemoveCheck(c); Fl.RemoveCheck(c);
  r := Fl.Ready(); Fl.RunChecks;
  Check.Check(~c.Added() & (c.runs >= 2), "RemoveCheck removes");
  told := 0;
  NEW(a); a.action := CountAction; Fl.AddCheck(a); a := NIL;
  Fl.RunChecks; Fl.RunChecks;
  Check.Check(told = 1, "a checker can remove itself, and its action runs");
  Fl.RunIdle;
  Fl.Flush;
  Check.Check(~Fl.ProgramShouldQuit(), "nothing asked to quit");
  Fl.SetProgramShouldQuit(TRUE);
  Check.Check(Fl.ProgramShouldQuit(), "SetProgramShouldQuit");
  Fl.SetProgramShouldQuit(FALSE)
END TestLoop;

PROCEDURE TestTime;
  VAR a, b: Fl.Timestamp; d: LONGREAL; t: HUGEINT;
BEGIN
  Fl.Now(a, 0.0D0); Fl.Now(b, 1.5D0);
  d := Fl.SecondsBetween(b, a);
  Check.Check((d >= 1.5D0) & (d < 5.0D0), "SecondsBetween a moment and one 1.5s on");
  d := Fl.SecondsBetween(a, b);
  Check.Check((d <= -1.5D0) & (d > -5.0D0), "the difference has a sign");
  t := Fl.TicksBetween(b, a);
  Check.Check((t >= 90) & (t < 300), "TicksBetween, in 60ths");
  d := Fl.SecondsSince(a);
  Check.Check((d >= 0.0D0) & (d < 60.0D0), "SecondsSince");
  t := Fl.TicksSince(a);
  Check.Check((t >= 0) & (t < 3600), "TicksSince");
  Check.Check((a.usec >= 0) & (a.usec < 1000000), "microseconds")
END TestTime;

PROCEDURE Doubled(fg, bg, context, size: INTEGER): INTEGER;
BEGIN
  INC(custom);
  IF (bg = Fl.White) & (context = 3) & (size = 4) THEN RETURN fg + 1 ELSE RETURN Fl.Black END
END Doubled;

PROCEDURE TestContrast;
  VAR mode, level, c, r, g, b: INTEGER; x: LONGREAL;
BEGIN
  mode := Fl.ContrastMode();
  Check.Check(mode = Fl.ContrastCielab, "CIELAB is the default contrast");
  level := Fl.ContrastLevel();
  Fl.SetContrastLevel(77);
  Check.Check(Fl.ContrastLevel() = 77, "SetContrastLevel");
  Fl.SetContrastLevel(level);
  Fl.SetContrastMode(Fl.ContrastNone);
  Check.Check(Fl.ContrastMode() = Fl.ContrastNone, "SetContrastMode");
  Check.Check(Fl.Contrast(Fl.White, Fl.White) = Fl.White, "ContrastNone leaves the color");
  Fl.SetContrastMode(Fl.ContrastCustom);
  Fl.SetContrastFunction(Doubled);
  c := Fl.ContrastSized(5, Fl.White, 3, 4);
  Check.Check((custom = 1) & (c = 6), "a contrast function has fg, bg, context and size");
  Fl.SetContrastFunction(NIL);
  Fl.SetContrastMode(mode);
  c := Fl.Contrast(Fl.White, Fl.White);
  Check.Check(c = Fl.Black, "CIELAB gives black on white");
  x := Fl.Lightness(Fl.White);
  Check.Check((x > 99.9D0) & (x < 100.1D0), "Lightness of white");
  x := Fl.Lightness(Fl.Black);
  Check.Check((x > -0.01D0) & (x < 0.01D0), "Lightness of black");
  x := Fl.Luminance(Fl.White);
  Check.Check((x > 0.99D0) & (x < 1.01D0), "Luminance of white");
  Check.Check(Fl.ParseColor("#ff8000", r, g, b) & (r = 255) & (g = 128) & (b = 0), "ParseColor of a number");
  r := 1; g := 2; b := 3;
  Check.Check(~Fl.ParseColor("#ffgg00", r, g, b) & (r = 1) & (g = 2) & (b = 3), "ParseColor refuses bad digits");
  Check.Check(~Fl.ParseColor("", r, g, b), "ParseColor of nothing");
  Check.Check(~Fl.ParseColor("#f", r, g, b), "ParseColor of too little")
END TestContrast;

(* Draws green with a one pixel red top, by another box type and color. *)
PROCEDURE GreenBox(x, y, w, h, c: INTEGER);
  VAR flat: Fl.BoxDraw;
BEGIN
  INC(drawn);
  activeInBox := Fl.DrawBoxActive();
  flat := Fl.GetBoxtype(Fl.FlatBox);
  flat(x, y, w, h, Fl.Green);
  FlDraw.SetColor(Fl.Red);
  FlDraw.RectF(x, y, w, 1)
END GreenBox;

PROCEDURE TestBoxes;
  VAR win: Fl.Window; box: Fl.Box; c, d: INTEGER; ok: BOOLEAN;
BEGIN
  Check.Check(Fl.BoxFilled(Fl.UpFrame) = Fl.UpBox, "BoxFilled of a frame");
  Check.Check(Fl.BoxDown(Fl.UpBox) = Fl.DownBox, "BoxDown");
  Check.Check(Fl.BoxFrame(Fl.UpBox) = Fl.UpFrame, "BoxFrame");
  Fl.SetBoxtype(Fl.FreeBoxtype, GreenBox, 1, 2, 3, 4);
  Check.Check((Fl.BoxDX(Fl.FreeBoxtype) = 1) & (Fl.BoxDY(Fl.FreeBoxtype) = 2)
    & (Fl.BoxDW(Fl.FreeBoxtype) = 3) & (Fl.BoxDH(Fl.FreeBoxtype) = 4), "SetBoxtype's edges");
  Fl.SetBoxtypeFrom(Fl.FreeBoxtype + 1, Fl.FreeBoxtype);
  Check.Check(Fl.BoxDW(Fl.FreeBoxtype + 1) = 3, "SetBoxtypeFrom");
  NEW(win); Fl.OpenWindow(win, 40, 40, "");
  NEW(box); Fl.OpenBox(box, 0, 0, 40, 40, "");
  box.SetBoxType(Fl.FreeBoxtype + 1);
  win.End;
  Check.Check(Probe.Capture(box), "capture");
  Check.Check(drawn >= 1, "a box type of the program's draws");
  Check.Check(activeInBox, "DrawBoxActive");
  Check.Check(Probe.Pixel(20, 20) = Fl.RGB(0, 255, 0), "the box draws by GetBoxtype's");
  Check.Check(Probe.Pixel(20, 0) = Fl.RGB(255, 0, 0), "and draws what it likes");
  Probe.Release;
  win.Delete;
  c := Fl.BoxColor(Fl.Red);
  Check.Check(c = Fl.Red, "BoxColor of a color");
  d := Fl.BoxBorderRadiusMax();
  Fl.SetBoxBorderRadiusMax(1);
  Check.Check(Fl.BoxBorderRadiusMax() = 5, "a radius has a minimum");
  Fl.SetBoxBorderRadiusMax(d);
  d := Fl.BoxShadowWidth();
  Fl.SetBoxShadowWidth(0);
  Check.Check(Fl.BoxShadowWidth() = 1, "a shadow has a minimum");
  Fl.SetBoxShadowWidth(d);
  Fl.SetBoxColor(Fl.Blue);
  Fl.ReleaseColor(100, FALSE);
  Fl.GetSystemColors;
  Fl.OwnColormap;
  Check.Check(Fl.Visual(Fl.VisualRgb), "there is an RGB visual");
  ok := Fl.SetScheme("gtk+");
  Check.Check(Fl.IsScheme("gtk+"), "IsScheme");
  Check.Check(~Fl.IsScheme("plastic"), "IsScheme of another");
  Check.Check(Fl.ReloadScheme(), "ReloadScheme");
  ok := Fl.SetScheme("base")
END TestBoxes;

PROCEDURE TestFonts;
  VAR a, n, f: INTEGER; sizes: ARRAY 64 OF INTEGER; one: ARRAY 1 OF INTEGER;
      short: ARRAY 4 OF CHAR; i: INTEGER;
BEGIN
  Check.Check(Fl.FontEnd() = Fl.FreeFont, "the font table's built in fonts");
  Fl.GetFont(Fl.Helvetica, name);
  Check.Check(name[0] # 0X, "GetFont");
  Fl.GetFont(Fl.Helvetica, short);
  Check.Check(short[3] = 0X, "GetFont cut short");
  Fl.GetFontName(Fl.HelveticaBold, name, a);
  Check.Check((name[0] # 0X) & (a = Fl.Bold), "GetFontName of a bold font");
  Fl.GetFontName(Fl.Courier, name, a);
  Check.Check(a = 0, "GetFontName of a plain font");
  n := Fl.GetFontSizes(Fl.Helvetica, sizes);
  Check.Check(n >= 1, "GetFontSizes");
  n := Fl.GetFontSizes(Fl.Helvetica, one);
  Check.Check(n = 1, "GetFontSizes cut short");
  f := Fl.FreeFont + 1;
  Fl.SetFont(f, "pofltk test font");
  Check.Check(Fl.FontEnd() = f + 1, "SetFont makes room");
  Fl.GetFont(f, name);
  Check.Check(Equal(name, "pofltk test font"), "GetFont of SetFont's");
  Fl.GetFont(Fl.FreeFont, name);
  Check.Check(name[0] = 0X, "a number passed over has no name");
  Fl.GetFontName(Fl.FreeFont, name, a);
  Check.Check((name[0] = 0X) & (a = 0), "nor one to show");
  Fl.SetFont(f, "pofltk test font");
  Fl.SetFont(f, "another");
  Fl.GetFont(f, name);
  Check.Check(Equal(name, "another"), "a font set again");
  Fl.SetFontFrom(f + 1, f);
  Fl.SetFont(f, "a third");
  Fl.GetFont(f + 1, name);
  Check.Check(Equal(name, "another"), "SetFontFrom copies the name");
  Fl.SetFontFrom(f, f);
  Fl.GetFont(f, name);
  Check.Check(Equal(name, "a third"), "SetFontFrom itself changes nothing");
  FOR i := 0 TO 299 DO long[i] := "x" END; long[300] := 0X;
  Fl.SetFont(f, long);
  Fl.GetFont(f, name);
  Check.Check(Strings.Length(name) = 126, "a long name is cut to fit");
  long[0] := "x"; i := 1;
  WHILE i < 298 DO long[i] := 0C3X; long[i + 1] := 0A9X; INC(i, 2) END;
  long[i] := 0X;
  Fl.SetFont(f, long);
  Fl.GetFont(f, name);
  Check.Check(Strings.Length(name) = 125, "and not in the middle of a character");
  Fl.SetFont(Fl.Courier + 0, "");
  Fl.GetFont(Fl.Courier, name);
  Check.Check(name[0] = 0X, "a built in font can be set");
  n := Fl.SetFonts();
  Check.Check((n > Fl.FreeFont) & (Fl.FontEnd() >= n), "SetFonts")
END TestFonts;

PROCEDURE CloseTold(w: Fl.Window);
BEGIN INC(closing)
END CloseTold;

PROCEDURE ShowIt(w: Fl.Window);
  VAR i: INTEGER;
BEGIN
  w.Show;
  i := 0;
  WHILE ~w.Shown() & (i < 100) DO Fl.Wait(0.05D0); INC(i) END
END ShowIt;

PROCEDURE TestWindows;
  VAR a, b, c: Shown;
BEGIN
  Check.Check(Fl.FirstWindow() = NIL, "no window shown");
  NEW(a); Fl.OpenWindow(a, 50, 50, "first"); a.End;
  NEW(b); Fl.OpenWindow(b, 50, 50, "second"); b.End;
  NEW(c); Fl.OpenWindow(c, 50, 50, "not shown"); c.End;
  ShowIt(a); ShowIt(b);
  Check.Check(Fl.FirstWindow() = b, "FirstWindow is the last shown");
  Check.Check(Fl.NextWindow(b) = a, "NextWindow");
  Check.Check(Fl.NextWindow(a) = NIL, "the end of the list");
  Check.Check(Fl.NextWindow(c) = NIL, "NextWindow of one not shown");
  Fl.SetFirstWindow(a);
  Check.Check(Fl.FirstWindow() = a, "SetFirstWindow");
  Fl.SetAtclose(CloseTold);
  a.DoCallback;
  Check.Check((closing = 1) & a.Shown(), "SetAtclose's procedure is told, and the window stays");
  Fl.SetAtclose(NIL);
  a.DoCallback;
  Check.Check((closing = 1) & ~a.Shown(), "FLTK's own again hides it");
  ShowIt(a);
  Fl.DefaultAtclose(a);
  Check.Check(~a.Shown(), "DefaultAtclose hides it");
  ShowIt(a);
  Fl.HideAllWindows;
  Check.Check(~a.Shown() & ~b.Shown(), "HideAllWindows");
  Check.Check(Fl.FirstWindow() = NIL, "and none is left");
  a.Delete; b.Delete; c.Delete
END TestWindows;

PROCEDURE TestGrab;
  VAR a, b: Shown; ok: BOOLEAN; i: INTEGER;
BEGIN
  Check.Check((Fl.Grab() = NIL) & ~Fl.HasGrab(), "no grab");
  Fl.SetGrab(NIL);
  NEW(a); Fl.OpenWindow(a, 50, 50, "grabbed"); a.End;
  NEW(b); Fl.OpenWindow(b, 50, 50, "other"); b.End;
  ShowIt(a); ShowIt(b);
  Fl.SetGrab(a);
  Check.Check((Fl.Grab() = a) & Fl.HasGrab(), "SetGrab");
  Fl.SetGrab(NIL);
  Check.Check(Fl.Grab() = NIL, "SetGrab of NIL");
  Fl.SetGrab(a);
  a.Delete;
  Check.Check(Fl.Grab() = NIL, "a window deleted lets go");
  ok := Fl.HandleEvent(Fl.EvEnter, b);
  ok := Fl.HandleEvent(Fl.EvMove, b);
  FOR i := 1 TO 5 DO Fl.Wait(0.01D0) END;
  b.Delete
END TestGrab;

PROCEDURE (o: Owner) Handle*(event: INTEGER): BOOLEAN;
BEGIN
  IF event = Fl.EvSelectionClear THEN INC(o.cleared); RETURN TRUE END;
  RETURN o.Handle^(event)
END Handle;

PROCEDURE Notice1(source: INTEGER);
BEGIN INC(first); told := source
END Notice1;

PROCEDURE Notice2(source: INTEGER);
BEGIN INC(second); Fl.RemoveClipboardNotify(Notice2)
END Notice2;

PROCEDURE TestSelection;
  VAR win: Fl.Window; a, b: Owner; was: BOOLEAN;
BEGIN
  NEW(win); Fl.OpenWindow(win, 40, 40, "");
  NEW(a); Fl.OpenBox(a, 0, 0, 20, 20, "");
  NEW(b); Fl.OpenBox(b, 20, 0, 20, 20, "");
  win.End;
  Check.Check(Fl.SelectionOwner() = NIL, "no owner");
  Fl.SetSelection(a, "text");
  Check.Check(Fl.SelectionOwner() = a, "SetSelection");
  Fl.SetSelection(b, "more");
  Check.Check((Fl.SelectionOwner() = b) & (a.cleared = 0), "the old owner isn't told");
  Fl.SetSelectionOwner(a);
  Check.Check(Fl.SelectionOwner() = a, "SetSelectionOwner");
  Fl.SetSelectionOwner(NIL);
  Check.Check(Fl.SelectionOwner() = NIL, "SetSelectionOwner of NIL");
  Fl.SetSelection(b, "more");
  b.Delete;
  Check.Check(Fl.SelectionOwner() = NIL, "an owner deleted lets go");
  Fl.SetSelection(a, "text");
  Check.Check(b.cleared = 0, "and hears no more");
  win.Delete;
  was := Fl.SelectionToClipboard();
  Fl.SetSelectionToClipboard(TRUE);
  Check.Check(Fl.SelectionToClipboard(), "SetSelectionToClipboard");
  Fl.SetSelectionToClipboard(was);
  Fl.AddClipboardNotify(Notice1);
  Fl.AddClipboardNotify(Notice2);
  Probe.ClipboardNotice(Fl.Clipboard);
  Check.Check((first = 1) & (second = 1) & (told = Fl.Clipboard), "notices");
  Probe.ClipboardNotice(Fl.Selection);
  Check.Check((first = 2) & (second = 1) & (told = Fl.Selection), "one may remove itself");
  Fl.RemoveClipboardNotify(Notice2);
  Fl.RemoveClipboardNotify(Notice1);
  Probe.ClipboardNotice(Fl.Clipboard);
  Check.Check(first = 2, "removed")
END TestSelection;

PROCEDURE TestEvents;
  VAR win: Fl.Window; box: Fl.Box; x, y, del: INTEGER; ok: BOOLEAN;
BEGIN
  NEW(win); Fl.OpenWindow(win, 40, 40, "");
  NEW(box); Fl.OpenBox(box, 0, 0, 40, 40, "");
  win.End;
  ok := Probe.Mouse(win, Fl.EvMove, 5, 5, 0, Fl.Ctrl + Fl.Alt, 0);
  Check.Check(Fl.EventCtrl() & Fl.EventAlt() & ~Fl.EventShift(), "EventCtrl, EventAlt, EventShift");
  Check.Check(Fl.EventCommand(), "EventCommand");
  Probe.SetKey(ORD("a"), "a");
  Check.Check(Fl.TestShortcut(ORD("a"), Fl.Ctrl + Fl.Alt), "TestShortcut");
  Check.Check(~Fl.TestShortcut(ORD("a"), Fl.Ctrl), "TestShortcut of other keys");
  ok := Probe.Mouse(win, Fl.EvPush, 5, 5, Fl.LeftMouse, Fl.Button1, 0);
  Check.Check(Fl.EventButtons() = Fl.Button1, "EventButtons");
  Probe.Release;
  Check.Check(Fl.CommandModifier() = Fl.Ctrl, "CommandModifier");
  Check.Check(Fl.ControlModifier() = Fl.Meta, "ControlModifier");
  Check.Check(Fl.CallbackReason() = Fl.ReasonUnknown, "no reason");
  ok := Fl.Compose(del);
  Fl.ComposeReset;
  Fl.GetMouse(x, y);
  win.Delete
END TestEvents;

PROCEDURE TestScreens;
  VAR h, v, s, bv: LONGREAL;
BEGIN
  Fl.ScreenDPI(0, h, v);
  Check.Check((h >= 0.0D0) & (v >= 0.0D0), "ScreenDPI");
  s := Fl.ScreenScale(0);
  Check.Check(s > 0.0D0, "ScreenScale");
  Check.Check((Fl.ScreenScalingSupported() >= 0) & (Fl.ScreenScalingSupported() <= 2), "ScreenScalingSupported");
  Fl.SetScreenScale(0, s);
  Check.Check(Fl.ScreenScale(0) = s, "SetScreenScale");
  Fl.KeyboardScreenScaling(TRUE);
  Fl.DisableIM;
  Fl.EnableIM;
  Check.Check(Fl.Version() >= 1.04D0, "Version");
  Check.Check(Fl.ApiVersion() >= 10400, "ApiVersion");
  Check.Check(Fl.AbiVersion() >= 10400, "AbiVersion");
  v := Fl.Version(); bv := Fl.BuiltVersion();
  Check.Check(v = bv, "BuiltVersion");
  Check.Check(Fl.BuiltApiVersion() = Fl.ApiVersion(), "BuiltApiVersion");
  Check.Check(Fl.BuiltAbiVersion() = Fl.AbiVersion(), "BuiltAbiVersion");
  Check.Check(Fl.AbiCheck(), "AbiCheck")
END TestScreens;

BEGIN
  TestLoop;
  TestTime;
  TestContrast;
  TestBoxes;
  TestWindows;
  TestGrab;
  TestSelection;
  TestEvents;
  TestScreens;
  TestFonts;
  Check.Summary
END TestStatics.
