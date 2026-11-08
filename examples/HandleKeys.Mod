MODULE HandleKeys; (* FLTK's test/handle_keys.cxx in Oberon-2 *)

(* The keyboard events a window gets, one line each in a terminal: the
   event, its key's number and name, the shift keys held, and its text,
   as a character and in UTF-8. Check buttons choose which events are
   shown (key down, key up, shortcut) and whether FLTK's keys for GUI
   scaling work; Clear empties the terminal, and Copy puts its text, or
   what is selected, on the clipboard.

   FLTK's program formats with the terminal's printf; this one builds
   each piece in a string and appends it. *)

IMPORT Fl, FlButtons, FlLayout, FlTerminal, FlUtf8;

CONST
  WW = 700; WH = 400;
  lkn = 14;  (* the key name field's length *)
  LF = 0AX;
  (* Text in the headline, and after clearing the terminal. *)
  headlineText = "[nnn] Event           Key     Name,  Flags: C A S M N L  Text  Unicode   UTF-8/hex";

TYPE
  (* A terminal that takes no keys, so that they reach the window. *)
  Terminal = POINTER TO RECORD (FlTerminal.TerminalDesc) END;

  App = POINTER TO RECORD (Fl.DoubleWindowDesc)
    eventnum: INTEGER;  (* the events shown, up to 999, then 0 again *)
    tty: Terminal;
    headline: Fl.Box
  END;

  Text = POINTER TO ARRAY OF CHAR;

VAR
  win: App;
  keydown, keyup, shortcut, scaling: FlButtons.CheckButton;
  grid: FlLayout.Grid;
  clear, copy, quit: FlButtons.Button;
  tt: ARRAY 80 OF CHAR;  (* the headline's and the terminal's tooltip *)

(* Appends t to s. *)
PROCEDURE Cat(t-: ARRAY OF CHAR; VAR s: ARRAY OF CHAR);
  VAR i, j: INTEGER;
BEGIN
  i := 0; WHILE s[i] # 0X DO INC(i) END;
  j := 0; WHILE (j < LEN(t)) & (t[j] # 0X) DO s[i] := t[j]; INC(i); INC(j) END;
  s[i] := 0X
END Cat;

PROCEDURE Length(s-: ARRAY OF CHAR): INTEGER;
  VAR i: INTEGER;
BEGIN i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) DO INC(i) END; RETURN i
END Length;

(* Appends c to s. *)
PROCEDURE Char(c: CHAR; VAR s: ARRAY OF CHAR);
  VAR i: INTEGER;
BEGIN i := Length(s); s[i] := c; s[i + 1] := 0X
END Char;

(* Appends t to s in width, right aligned (printf's "%<width>s"), or
   left aligned for a negative width ("%-<width>s"). *)
PROCEDURE Pad(t-: ARRAY OF CHAR; width: INTEGER; VAR s: ARRAY OF CHAR);
  VAR n: INTEGER;
BEGIN
  n := Length(t);
  IF width > 0 THEN WHILE width > n DO Char(" ", s); DEC(width) END END;
  Cat(t, s);
  IF width < 0 THEN WHILE -width > n DO Char(" ", s); INC(width) END END
END Pad;

(* Appends n to s in decimal, right aligned in width ("%<width>d"). *)
PROCEDURE Int(n, width: INTEGER; VAR s: ARRAY OF CHAR);
  VAR d: ARRAY 16 OF CHAR; r: ARRAY 16 OF CHAR; k, i: INTEGER; neg: BOOLEAN;
BEGIN
  neg := n < 0; IF neg THEN n := -n END;
  k := 0; REPEAT d[k] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(k) UNTIL n = 0;
  IF neg THEN d[k] := "-"; INC(k) END;
  i := 0; WHILE k > 0 DO DEC(k); r[i] := d[k]; INC(i) END; r[i] := 0X;
  Pad(r, width, s)
END Int;

(* Appends n to s in lower-case hexadecimal, with at least digits
   digits ("%0<digits>x"). *)
PROCEDURE Hex(n, digits: INTEGER; VAR s: ARRAY OF CHAR);
  VAR d: ARRAY 16 OF CHAR; k: INTEGER;
BEGIN
  k := 0;
  REPEAT
    IF n MOD 16 < 10 THEN d[k] := CHR(ORD("0") + n MOD 16) ELSE d[k] := CHR(ORD("a") - 10 + n MOD 16) END;
    n := n DIV 16; INC(k)
  UNTIL n = 0;
  WHILE k < digits DO d[k] := "0"; INC(k) END;
  WHILE k > 0 DO DEC(k); Char(d[k], s) END
END Hex;

(* The name of key k, as FLTK's get_keyname gives it. Its padding goes
   by its bytes, as FLTK's does (snprintf's count). *)
PROCEDURE KeyName(k: INTEGER; VAR s: ARRAY OF CHAR);
  VAR u: ARRAY 8 OF CHAR; n: INTEGER;
BEGIN
  COPY("", s);
  IF k = 0 THEN COPY("0", s)
  ELSIF k < 32 THEN Char("^", s); Char(CHR(k + 64), s)  (* a control character *)
  ELSIF k < 128 THEN Char("'", s); Char(CHR(k), s); Char("'", s)
  ELSIF (k >= 0A0H) & (k <= 0FFH) THEN  (* ISO-8859-1, on international keyboards *)
    n := FlUtf8.Encode(k, u);
    Char("'", s); Cat(u, s); Char("'", s)
  ELSIF (k > Fl.KeyF) & (k <= Fl.KeyFLast) THEN COPY("FL_F+", s); Int(k - Fl.KeyF, 0, s)
  ELSIF (k >= Fl.KeyKP) & (k <= Fl.KeyKPLast) THEN
    IF k = Fl.KeyKPEnter THEN COPY("FL_KP_Enter", s)
    ELSE COPY("FL_KP+'", s); Char(CHR(k - Fl.KeyKP), s); Char("'", s)
    END
  ELSIF (k >= Fl.KeyButton) & (k <= Fl.KeyButton + 7) THEN
    COPY("FL_Button+", s); Int(k - Fl.KeyButton, 0, s)
  ELSE
    CASE k OF
      Fl.KeyEscape: COPY("FL_Escape", s)
    | Fl.KeyBackSpace: COPY("FL_BackSpace", s)
    | Fl.KeyTab: COPY("FL_Tab", s)
    | Fl.KeyIsoKey: COPY("FL_Iso_Key", s)
    | Fl.KeyEnter: COPY("FL_Enter", s)
    | Fl.KeyPrint: COPY("FL_Print", s)
    | Fl.KeyScrollLock: COPY("FL_Scroll_Lock", s)
    | Fl.KeyPause: COPY("FL_Pause", s)
    | Fl.KeyInsert: COPY("FL_Insert", s)
    | Fl.KeyHome: COPY("FL_Home", s)
    | Fl.KeyPageUp: COPY("FL_Page_Up", s)
    | Fl.KeyDelete: COPY("FL_Delete", s)
    | Fl.KeyEnd: COPY("FL_End", s)
    | Fl.KeyPageDown: COPY("FL_Page_Down", s)
    | Fl.KeyLeft: COPY("FL_Left", s)
    | Fl.KeyUp: COPY("FL_Up", s)
    | Fl.KeyRight: COPY("FL_Right", s)
    | Fl.KeyDown: COPY("FL_Down", s)
    | Fl.KeyShiftL: COPY("FL_Shift_L", s)
    | Fl.KeyShiftR: COPY("FL_Shift_R", s)
    | Fl.KeyControlL: COPY("FL_Control_L", s)
    | Fl.KeyControlR: COPY("FL_Control_R", s)
    | Fl.KeyCapsLock: COPY("FL_Caps_Lock", s)
    | Fl.KeyAltL: COPY("FL_Alt_L", s)
    | Fl.KeyAltR: COPY("FL_Alt_R", s)
    | Fl.KeyMetaL: COPY("FL_Meta_L", s)
    | Fl.KeyMetaR: COPY("FL_Meta_R", s)
    | Fl.KeyMenu: COPY("FL_Menu", s)
    | Fl.KeyHelp: COPY("FL_Help", s)
    | Fl.KeyNumLock: COPY("FL_Num_Lock", s)
    | Fl.KeyAltGr: COPY("FL_Alt_Gr", s)
    ELSE COPY("0x", s); Hex(k, 4, s)
    END
  END
END KeyName;

PROCEDURE (t: Terminal) Handle*(event: INTEGER): BOOLEAN;
BEGIN
  IF (event = Fl.EvKeyDown) OR (event = Fl.EvKeyUp) OR (event = Fl.EvShortcut) THEN
    RETURN FALSE
  END;
  RETURN t.Handle^(event)
END Handle;

(* Counts and shows the event, if it is one the buttons ask for:
   FALSE if not. *)
PROCEDURE (a: App) PrintEvent(event: INTEGER): BOOLEAN;
  VAR s, name: ARRAY 64 OF CHAR;
BEGIN
  IF event = Fl.EvKeyDown THEN
    IF ~keydown.Value() THEN RETURN FALSE END;
    a.tty.SetTextFgColor(Fl.Black)
  ELSIF event = Fl.EvKeyUp THEN
    IF ~keyup.Value() THEN RETURN FALSE END;
    a.tty.SetTextFgColor(Fl.Blue)
  ELSIF event = Fl.EvShortcut THEN
    IF ~shortcut.Value() THEN RETURN FALSE END;
    a.tty.SetTextFgColor(Fl.RGB(0, 0AAH, 0))  (* dark green *)
  ELSE RETURN FALSE
  END;
  a.eventnum := (a.eventnum + 1) MOD 1000;
  Fl.EventName(event, name);
  s := "["; Int(a.eventnum, 3, s); Cat("] ", s); Pad(name, -12, s);
  a.tty.Append(s);
  RETURN TRUE
END PrintEvent;

PROCEDURE (a: App) Handle*(event: INTEGER): BOOLEAN;
  VAR
    res: BOOLEAN; state: SET;
    etxt: ARRAY 64 OF CHAR; s, name, num: ARRAY 160 OF CHAR;
    ekey, elen, i, ucs, size: INTEGER;

  PROCEDURE Flag(f: SET; c: CHAR);
  BEGIN
    IF f * state # {} THEN Char(c, s) ELSE Char(".", s) END;
    Char(" ", s)
  END Flag;

BEGIN
  res := a.Handle^(event);
  (* keyboard events only *)
  IF ~a.PrintEvent(event) THEN RETURN res END;

  FOR i := 0 TO LEN(etxt) - 1 DO etxt[i] := 0X END;
  Fl.EventText(etxt);
  ekey := Fl.EventKey();
  elen := Fl.EventLength();
  state := Fl.EventState();

  num := "0x"; Hex(ekey, 4, num);
  s := ""; Pad(num, 10, s); Cat("  ", s);  (* the event's key number *)
  KeyName(ekey, name); Cat(name, s);
  IF Length(name) < lkn THEN Pad("", Length(name) - lkn, s) END;
  Flag(Fl.Ctrl, "C"); Flag(Fl.Alt, "A"); Flag(Fl.Shift, "S");
  Flag(Fl.Meta, "M"); Flag(Fl.NumLock, "N"); Flag(Fl.CapsLock, "L");
  Cat(" ", s);

  IF elen # 0 THEN
    IF (elen = 1) & (etxt[0] < " ") THEN  (* a control character *)
      Cat("'^", s); Char(CHR(ORD(etxt[0]) + 64), s); Cat("' ", s)
    ELSE Char("'", s); Cat(etxt, s); Cat("'  ", s)
    END;
    (* FlUtf8.Decode takes no text that starts with 0X, as Ctrl+@'s *)
    IF etxt[0] = 0X THEN ucs := 0 ELSE ucs := FlUtf8.Decode(etxt, 0, size) END;
    Cat(" U+", s); Hex(ucs, 4, s); Cat("   ", s);
    FOR i := 0 TO elen - 1 DO Char(" ", s); Hex(ORD(etxt[i]), 2, s) END
  ELSE Cat("'' ", s)
  END;
  a.tty.Append(s);
  a.tty.SetTextFgColor(Fl.Black);
  a.tty.Append(LF);
  RETURN res
END Handle;

PROCEDURE OpenApp(a: App; x, y, w, h: INTEGER);
BEGIN
  Fl.OpenDoubleWindowAt(a, x, y, w, h, "");
  a.eventnum := 0;
  NEW(a.headline); Fl.OpenBox(a.headline, 2, 0, w - 4, 25, "");
  a.headline.SetColor(Fl.Light2);
  a.headline.SetBoxType(Fl.FlatBox);
  a.headline.SetAlign(Fl.AlignLeft + Fl.AlignInside);
  a.headline.SetLabelFont(Fl.Courier);
  a.headline.SetLabelSize(12);
  a.headline.SetLabel(headlineText);
  a.headline.SetTooltip(tt);
  NEW(a.tty); FlTerminal.OpenTerminal(a.tty, 0, 25, w, h - 100, "");
  a.tty.SetColor(Fl.White);
  a.tty.SetTextFgColor(Fl.Darker(Fl.Blue));
  a.tty.SetSelectionBgColor(Fl.Blue);
  a.tty.SetSelectionFgColor(Fl.White);
  a.tty.SetTextFont(Fl.Courier);
  a.tty.SetTextSize(12);
  a.tty.SetTooltip(tt)
END OpenApp;

PROCEDURE QuitCb(w: Fl.Widget);
  VAR win: Fl.Window;
BEGIN win := w.Window(); win.Hide
END QuitCb;

(* Clears the terminal. *)
PROCEDURE ClearCb(w: Fl.Widget);
  VAR ignored: BOOLEAN;
BEGIN
  win.tty.ClearScreenHome(FALSE);
  win.tty.ClearHistory;
  win.tty.Append(headlineText); win.tty.Append(LF);  (* helpful if copied to the clipboard *)
  win.tty.Redraw;
  ignored := win.tty.TakeFocus()
END ClearCb;

(* Copies the selected text to the clipboard, or all of it. *)
PROCEDURE CopyCb(w: Fl.Widget);
  VAR text: Text; s: ARRAY 80 OF CHAR; ignored: BOOLEAN;
BEGIN
  IF win.tty.SelectionTextLength() > 0 THEN
    NEW(text, win.tty.SelectionTextLength() + 1);
    win.tty.SelectionText(text^);
    s := "[Selected"
  ELSE
    NEW(text, win.tty.TextLength(FALSE) + 1);
    win.tty.Text(text^, FALSE);
    s := "[Full"
  END;
  Fl.Copy(text^, Fl.Clipboard);
  Cat(" text copied to clipboard, length = ", s); Int(Length(text^), 0, s); Cat("]", s);
  win.tty.Append(s); win.tty.Append(LF);
  ignored := win.tty.TakeFocus()
END CopyCb;

(* the check buttons' callback *)
PROCEDURE ToggleCb(w: Fl.Widget);
  VAR ignored: BOOLEAN;
BEGIN ignored := win.tty.TakeFocus()
END ToggleCb;

(* Turns the GUI scaling shortcuts on or off. *)
PROCEDURE ToggleScaling(w: Fl.Widget);
  VAR s: ARRAY 80 OF CHAR;
BEGIN
  Fl.KeyboardScreenScaling(scaling.Value());
  IF scaling.Value() THEN
    s := "GUI-Scaling = ON, OPTION_SIMPLE_ZOOM_SHORTCUT = ";
    IF Fl.Option(Fl.OptionSimpleZoomShortcut) THEN Cat("ON", s) ELSE Cat("OFF", s) END;
    win.tty.Append(s); win.tty.Append(LF)
  END;
  ToggleCb(w)  (* gives the focus to the terminal *)
END ToggleScaling;

(* The window's callback: Esc doesn't close it. *)
PROCEDURE CloseCb(w: Fl.Widget);
BEGIN
  IF Fl.Event() # Fl.EvShortcut THEN w.Hide END
END CloseCb;

PROCEDURE Check(VAR b: FlButtons.CheckButton; label-, tip-: ARRAY OF CHAR;
                col: INTEGER; on: BOOLEAN);
BEGIN
  NEW(b); FlButtons.OpenCheckButton(b, 0, 0, 80, 30, label);
  grid.Place(b, 0, col, FlLayout.GridFill);
  b.SetValue(on);
  b.action := ToggleCb;
  b.SetTooltip(tip)
END Check;

BEGIN
  tt := "Flags:"; Char(LF, tt); Cat("C=Ctrl, A=Alt, S=Shift, M=Meta", tt); Char(LF, tt);
  Cat("N=NumLock, L=CapsLock", tt);
  NEW(win); OpenApp(win, 0, 0, WW, WH);
  win.tty.SetBoxType(Fl.DownBox);
  win.tty.SetShowUnknown(TRUE);
  win.tty.SetTextFgColor(Fl.Black);
  win.tty.Append("Please press any key ..."); win.tty.Append(LF);

  NEW(grid); FlLayout.OpenGrid(grid, 0, WH - 75, WW, 75, "");
  grid.SetLayout(2, 5); grid.SetMargins(5, 5, 5, 5); grid.SetGap(5, 5);

  Check(keydown, "Keydown", "Show FL_KEYDOWN aka FL_KEYBOARD events", 0, TRUE);
  Check(keyup, "Keyup", "Show FL_KEYUP events", 1, FALSE);
  Check(shortcut, "Shortcut", "Show FL_SHORTCUT events", 2, FALSE);
  Check(scaling, "GUI scaling", "Use GUI scaling shortcuts", 3, FALSE);
  scaling.action := ToggleScaling;
  ToggleScaling(scaling);

  NEW(clear); FlButtons.OpenButton(clear, 0, 0, 80, 30, "Clear");
  grid.Place(clear, 1, 0, FlLayout.GridFill);
  clear.action := ClearCb;
  clear.SetTooltip("Clear the display");

  NEW(copy); FlButtons.OpenButton(copy, 0, 0, 80, 30, "Copy");
  grid.Place(copy, 1, 1, FlLayout.GridFill);
  copy.action := CopyCb;
  copy.SetTooltip("Copy terminal contents to clipboard");

  NEW(quit); FlButtons.OpenButton(quit, WW - 70, WH - 50, 80, 30, "Quit");
  grid.Place(quit, 1, 4, FlLayout.GridFill);
  quit.SetBoxType(Fl.ThinUpBox);
  quit.action := QuitCb;
  quit.SetTooltip("Exit the program");

  grid.End;
  win.End;
  win.action := CloseCb;
  win.SetResizable(win.tty);
  win.SizeRange(660, 300, 0, 0);
  win.ShowArgs;
  Fl.Run;
  win.Delete
END HandleKeys.
