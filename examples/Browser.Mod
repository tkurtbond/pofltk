MODULE Browser; (* FLTK's test/browser.cxx in Oberon-2 *)

(* A browser showing a file, by default FLTK's browser.cxx, whose
   comment tries the browser's formatting characters; the buttons move
   the line typed to the top, bottom or middle, or into view, swap two
   selected lines or sort them; the choices change the browser's kind
   and when it calls back, and the terminal shows each callback. *)

IMPORT Args, Err, Fl, FlBrowsers, FlButtons, FlDialogs, FlInputs, FlMenus, FlTerminal;

CONST
  Esc = 1BX;

TYPE
  Action = PROCEDURE (w: Fl.Widget);

VAR
  window: Fl.DoubleWindow;
  browser: FlBrowsers.SelectBrowser;
  top, bottom, middle, visible, swap, sort: FlButtons.Button;
  btype, wtype: FlMenus.Choice;
  field: FlInputs.IntInput;
  tty: FlTerminal.Terminal;
  whens: ARRAY 9 OF SET;
  fname: ARRAY 1024 OF CHAR;
  help: ARRAY 4096 OF CHAR;
  i: INTEGER;

(* s with each "|" a line feed *)
PROCEDURE Lines(VAR s: ARRAY OF CHAR);
VAR i: INTEGER;
BEGIN
  i := 0; WHILE s[i] # 0X DO IF s[i] = "|" THEN s[i] := 0AX END; INC(i) END
END Lines;

(* Appends s to t. *)
PROCEDURE Cat(s-: ARRAY OF CHAR; VAR t: ARRAY OF CHAR);
VAR i, j: INTEGER;
BEGIN
  i := 0; WHILE t[i] # 0X DO INC(i) END;
  j := 0; WHILE s[j] # 0X DO t[i] := s[j]; INC(i); INC(j) END;
  t[i] := 0X
END Cat;

(* Appends n to s. *)
PROCEDURE Num(n: INTEGER; VAR s: ARRAY OF CHAR);
VAR i: INTEGER;
BEGIN
  IF n < 0 THEN Cat("-", s); n := -n END;
  IF n >= 10 THEN Num(n DIV 10, s) END;
  i := 0; WHILE s[i] # 0X DO INC(i) END;
  s[i] := CHR(ORD("0") + n MOD 10); s[i + 1] := 0X
END Num;

(* Escape sequence ESC[<code>m. *)
PROCEDURE Sgr(code-: ARRAY OF CHAR; VAR s: ARRAY OF CHAR);
VAR e: ARRAY 2 OF CHAR;
BEGIN
  e[0] := Esc; e[1] := 0X; Cat(e, s); Cat("[", s); Cat(code, s); Cat("m", s)
END Sgr;

PROCEDURE BrowserCallback(o: Fl.Widget);
VAR s: ARRAY 128 OF CHAR;
BEGIN
  s := "callback, selection = "; Sgr("31", s); Num(o(FlBrowsers.Browser).Value(), s); Sgr("0", s);
  Cat(", event_clicks = ", s); Sgr("32", s); Num(Fl.EventClicks(), s); Sgr("0", s);
  Cat(0AX, s);
  tty.Append(s)
END BrowserCallback;

PROCEDURE ShowCallback(o: Fl.Widget);
VAR line: INTEGER; s: ARRAY 128 OF CHAR;
BEGIN
  line := field.IntValue();
  IF line = 0 THEN
    s := "Please enter a number in the text field|before clicking on the buttons."; Lines(s);
    FlDialogs.Alert(s)
  ELSIF o = top THEN browser.SetTopLine(line)
  ELSIF o = bottom THEN browser.SetBottomLine(line)
  ELSIF o = middle THEN browser.SetMiddleLine(line)
  ELSE browser.MakeVisible(line)
  END
END ShowCallback;

(* Swaps the first two lines selected; FLTK's program never looks at the
   last line. *)
PROCEDURE SwapCallback(o: Fl.Widget);
VAR a, b, t: INTEGER;
BEGIN
  a := -1; b := -1; t := 1;
  WHILE (b < 0) & (t < browser.Count()) DO
    IF browser.Selected(t) THEN
      IF a < 0 THEN a := t ELSE b := t END
    END;
    INC(t)
  END;
  IF b > 0 THEN browser.Swap(a, b) END
END SwapCallback;

PROCEDURE SortCallback(o: Fl.Widget);
BEGIN browser.Sort(FlBrowsers.SortAscending)
END SortCallback;

PROCEDURE KindCallback(o: Fl.Widget);
VAR t: INTEGER; ok: BOOLEAN;
BEGIN
  FOR t := 1 TO browser.Count() DO ok := browser.Select(t, FALSE) END;
  ok := browser.Select(1, FALSE); (* leave the focus box on the first line *)
  (* the choice's items are the kinds, in order *)
  IF btype.Value() >= 0 THEN browser.SetKind(btype.Value()) END;
  browser.Redraw
END KindCallback;

PROCEDURE WhenCallback(o: Fl.Widget);
BEGIN
  IF wtype.Value() >= 0 THEN browser.SetWhen(whens[wtype.Value()]) END
END WhenCallback;

PROCEDURE Button(VAR b: FlButtons.Button; x: INTEGER; label-: ARRAY OF CHAR; action: Action);
BEGIN
  NEW(b); FlButtons.OpenButton(b, x, 375, 80, 25, label); b.action := action
END Button;

PROCEDURE When(name-: ARRAY OF CHAR; i: INTEGER; w: SET);
BEGIN
  i := wtype.Add(name, 0, {}, NIL, {}); whens[i] := w
END When;

BEGIN
  IF ~Fl.ParseArgs(NIL, i) THEN
    Fl.ArgsHelp(help); Err.String(help); Err.Ln; HALT(1)
  END;
  IF i < Args.argc THEN Args.Get(i, fname) ELSE fname := "browser.cxx" END;
  NEW(window); Fl.OpenDoubleWindow(window, 720, 520, fname);
  NEW(browser); FlBrowsers.OpenSelectBrowser(browser, 0, 0, window.W(), 350, "");
  browser.SetKind(FlBrowsers.MultiKind);
  browser.action := BrowserCallback;
  IF ~browser.Load(fname) THEN
    help := "Can't load '"; Cat(fname, help); Cat("'", help);
    FlDialogs.Message(help);
    browser.Add("This is a test of how the browser draws lines.");
    browser.Add("This is a second line.");
    browser.Add("This is a third.");
    browser.Add("@bBold text");
    browser.Add("@iItalic text")
  END;
  browser.SetVPosition(0);

  NEW(field); FlInputs.OpenIntInput(field, 55, 350, window.W() - 55, 25, "Line #:");
  field.action := ShowCallback;

  Button(top, 0, "Top", ShowCallback);
  Button(bottom, 80, "Bottom", ShowCallback);
  Button(middle, 160, "Middle", ShowCallback);
  Button(visible, 240, "Make Vis.", ShowCallback);
  Button(swap, 320, "Swap", SwapCallback);
  help := "Swaps two selected lines|(Use CTRL-click to select two lines)"; Lines(help);
  swap.SetTooltip(help);
  Button(sort, 400, "Sort", SortCallback);

  NEW(btype); FlMenus.OpenChoice(btype, 480, 375, 80, 25, "");
  i := btype.Add("Normal", 0, {}, NIL, {});
  i := btype.Add("Select", 0, {}, NIL, {});
  i := btype.Add("Hold", 0, {}, NIL, {});
  i := btype.Add("Multi", 0, {}, NIL, {});
  btype.action := KindCallback;
  IF btype.SetValue(3) THEN END;
  btype.SetTooltip("Changes the browser type()");

  NEW(wtype); FlMenus.OpenChoice(wtype, 560, 375, 160, 25, "");
  wtype.SetTextSize(8);
  When("FL_WHEN_NEVER", 0, Fl.WhenNever);
  When("FL_WHEN_CHANGED", 0, Fl.WhenChanged);
  When("FL_WHEN_NOT_CHANGED", 0, Fl.WhenNotChanged);
  When("FL_WHEN_RELEASE", 0, Fl.WhenRelease);
  When("FL_WHEN_RELEASE_ALWAYS", 0, Fl.WhenReleaseAlways);
  When("FL_WHEN_ENTER_KEY", 0, Fl.WhenEnterKey);
  When("FL_WHEN_ENTER_KEY_ALWAYS", 0, Fl.WhenEnterKeyAlways);
  When("FL_WHEN_ENTER_KEY_CHANGED", 0, Fl.WhenEnterKeyChanged);
  (* FLTK's program adds the numbers, 11 + 6, which is 17, {0, 4} *)
  When("FL_WHEN_ENTER_KEY + FL_WHEN_RELEASE_ALWAYS", 0, {0, 4});
  wtype.action := WhenCallback;
  IF wtype.SetValue(4) THEN END; (* WhenReleaseAlways is a browser's default *)

  (* a small terminal for the callbacks' messages *)
  NEW(tty); FlTerminal.OpenTerminal(tty, 0, 400, 720, 120, "");
  tty.SetHistoryRows(50);
  tty.SetAnsi(TRUE);

  window.End;
  window.SetResizable(browser);
  window.ShowArgs;
  Fl.Run
END Browser.
