MODULE Keyboard; (* FLTK's test/keyboard.cxx, keyboard.h and keyboard_ui.fl in Oberon-2 *)

(* A keyboard of buttons, each down while its key is held, as
   Fl.EventKeyDown says, and a row of buttons for the shift keys and mouse
   buttons, as Fl.EventState says; above them the last event's key, named,
   and its text. The window takes no events but the wheel, which turns the
   two dials, so the buttons are never pushed: an event loop sets them after
   every event.

   keyboard_ui.fl's layout is here as FLUID wrote it (keyboard_ui.cxx),
   one line a button. FLTK's loop finds a key button among the window's
   children by its callback, key_cb or shift_cb, and its key or shift state
   in its argument (0 for the label's first character); here each button is
   a type of its own, holding its key or state, kept in a list. *)

IMPORT Fl, FlButtons, FlInputs, FlValuators, FlUtf8;

TYPE
  MyWindow = POINTER TO RECORD (Fl.WindowDesc) END;

  (* keyboard.cxx's key_cb and shift_cb buttons, whose callbacks do
     nothing *)
  KeyButton = POINTER TO RECORD (FlButtons.ButtonDesc)
    key: INTEGER;   (* Fl.EventKeyDown's key *)
    next: KeyButton
  END;
  ShiftButton = POINTER TO RECORD (FlButtons.ButtonDesc)
    state: SET;     (* in Fl.EventState *)
    next: ShiftButton
  END;
  (* wheel_cb's dials *)
  Wheel = POINTER TO RECORD (FlValuators.DialDesc) END;

  Name = RECORD n: INTEGER; text: ARRAY 16 OF CHAR END;

VAR
  myWindow: MyWindow;
  keyOutput, textOutput: FlInputs.Output;
  rollerX, rollerY: Wheel;
  box: Fl.Box;
  b: FlButtons.Button;    (* the button made last, for its attributes *)
  keys: KeyButton;
  shifts: ShiftButton;
  keyTable: ARRAY 32 OF Name;
  nKeys: INTEGER;

PROCEDURE (b: KeyButton) Callback*;
END Callback;

PROCEDURE (b: ShiftButton) Callback*;
END Callback;

PROCEDURE (d: Wheel) Callback*;
END Callback;

(* The window's own handling replaced: the wheel turns the dials, and
   nothing else is used, or passed to the buttons. *)
PROCEDURE (w: MyWindow) Handle*(event: INTEGER): BOOLEAN;
BEGIN
  IF event = Fl.EvMouseWheel THEN
    rollerX.SetValue(rollerX.Value() + Fl.EventDx() * rollerX.Step());
    rollerY.SetValue(rollerY.Value() + Fl.EventDy() * rollerY.Step());
    RETURN TRUE
  END;
  RETURN FALSE
END Handle;

(* Escape, offered as a shortcut no widget took, would close the window:
   the handler takes it. *)
PROCEDURE EatEscape(e: INTEGER): BOOLEAN;
BEGIN RETURN (e = Fl.EvShortcut) & (Fl.EventKey() = Fl.KeyEscape)
END EatEscape;

(* A key_cb button, for key, or for its label's first character if key
   is 0. *)
PROCEDURE Key(x, y, w, h: INTEGER; label: ARRAY OF CHAR; key: INTEGER);
  VAR k: KeyButton;
BEGIN
  NEW(k); FlButtons.OpenButton(k, x, y, w, h, label);
  IF key = 0 THEN key := ORD(label[0]) END;
  k.key := key; k.next := keys; keys := k; b := k
END Key;

(* A shift_cb button, for the shift state state. *)
PROCEDURE Shift(x, y, w, h: INTEGER; label: ARRAY OF CHAR; state: SET);
  VAR s: ShiftButton;
BEGIN
  NEW(s); FlButtons.OpenButton(s, x, y, w, h, label);
  s.state := state; s.next := shifts; shifts := s; b := s
END Shift;

PROCEDURE Roller(d: Wheel);
BEGIN
  d.SetBoxType(Fl.RoundUpBox); d.SetSelectionColor(Fl.BackgroundColor);
  d.SetLabelSize(9); d.SetStep(0.1D0); d.SetAlign(Fl.AlignTopLeft)
END Roller;

PROCEDURE MakeWindow;
BEGIN
  NEW(myWindow); Fl.OpenWindow(myWindow, 495, 215, "");
  myWindow.SetBoxType(Fl.FlatBox); myWindow.SetColor(Fl.BackgroundColor);
  myWindow.SetSelectionColor(Fl.BackgroundColor); myWindow.SetLabelType(Fl.NoLabel);
  myWindow.SetLabelFont(0); myWindow.SetLabelSize(14);
  myWindow.SetLabelColor(Fl.ForegroundColor); myWindow.SetAlign(Fl.AlignTop);
  myWindow.SetWhen(Fl.WhenRelease);
  NEW(keyOutput); FlInputs.OpenOutput(keyOutput, 15, 20, 170, 30, "Fl::event_key():");
  keyOutput.SetLabelSize(9); keyOutput.SetAlign(Fl.AlignTopLeft);
  NEW(textOutput); FlInputs.OpenOutput(textOutput, 195, 20, 190, 30, "Fl::event_text():");
  textOutput.SetLabelSize(9); textOutput.SetAlign(Fl.AlignTopLeft);
  Key(15, 70, 20, 20, "Esc ", Fl.KeyEscape); b.SetLabelSize(8);
  Key(50, 70, 20, 20, "F1", Fl.KeyF + 1); b.SetLabelSize(10);
  Key(70, 70, 20, 20, "F2", Fl.KeyF + 2); b.SetLabelSize(10);
  Key(90, 70, 20, 20, "F3", Fl.KeyF + 3); b.SetLabelSize(10);
  Key(110, 70, 20, 20, "F4", Fl.KeyF + 4); b.SetLabelSize(10);
  Key(140, 70, 20, 20, "F5", Fl.KeyF + 5); b.SetLabelSize(10);
  Key(160, 70, 20, 20, "F6", Fl.KeyF + 6); b.SetLabelSize(10);
  Key(180, 70, 20, 20, "F7", Fl.KeyF + 7); b.SetLabelSize(10);
  Key(200, 70, 20, 20, "F8", Fl.KeyF + 8); b.SetLabelSize(10);
  Key(230, 70, 20, 20, "F9", Fl.KeyF + 9); b.SetLabelSize(10);
  Key(250, 70, 20, 20, "F10", Fl.KeyF + 10); b.SetLabelSize(10);
  Key(270, 70, 20, 20, "F11", Fl.KeyF + 11); b.SetLabelSize(10);
  Key(290, 70, 20, 20, "F12", Fl.KeyF + 12); b.SetLabelSize(10);
  Key(325, 70, 20, 20, "Print ", Fl.KeyPrint); b.SetLabelSize(8);
  Key(345, 70, 20, 20, "Sclk ", Fl.KeyScrollLock); b.SetLabelSize(8);
  Key(365, 70, 20, 20, "Paus ", Fl.KeyPause); b.SetLabelSize(8);
  Key(400, 70, 20, 20, "Help", Fl.KeyHelp); b.SetLabelSize(8);
  Key(420, 70, 20, 20, "=", Fl.KeyKP + ORD("=")); b.SetLabelSize(10);
  NEW(rollerX); FlValuators.OpenDial(rollerX, 440, 70, 20, 20, "x:"); Roller(rollerX);
  NEW(rollerY); FlValuators.OpenDial(rollerY, 460, 70, 20, 20, "y:"); Roller(rollerY);
  Key(15, 100, 20, 20, "`", 0); b.SetLabelSize(10);
  Key(35, 100, 20, 20, "1", 0); b.SetLabelSize(10);
  Key(55, 100, 20, 20, "2", 0); b.SetLabelSize(10);
  Key(75, 100, 20, 20, "3", 0); b.SetLabelSize(10);
  Key(95, 100, 20, 20, "4", 0); b.SetLabelSize(10);
  Key(115, 100, 20, 20, "5", 0); b.SetLabelSize(10);
  Key(135, 100, 20, 20, "6", 0); b.SetLabelSize(10);
  Key(155, 100, 20, 20, "7", 0); b.SetLabelSize(10);
  Key(175, 100, 20, 20, "8", 0); b.SetLabelSize(10);
  Key(195, 100, 20, 20, "9", 0); b.SetLabelSize(10);
  Key(215, 100, 20, 20, "0", 0); b.SetLabelSize(10);
  Key(235, 100, 20, 20, "-", 0); b.SetLabelSize(10);
  Key(255, 100, 20, 20, "=", 0); b.SetLabelSize(10);
  Key(275, 100, 35, 20, "Bksp", Fl.KeyBackSpace); b.SetLabelType(Fl.ShadowLabel); b.SetLabelSize(8); b.SetAlign(Fl.AlignLeft + Fl.AlignInside);
  Key(325, 100, 20, 20, "Ins ", Fl.KeyInsert); b.SetLabelSize(8);
  Key(345, 100, 20, 20, "Home", Fl.KeyHome); b.SetLabelSize(8);
  Key(365, 100, 20, 20, "pgup ", Fl.KeyPageUp); b.SetLabelSize(8);
  Key(400, 100, 20, 20, "Num", Fl.KeyNumLock); b.SetLabelSize(8);
  Key(420, 100, 20, 20, "/", Fl.KeyKP + ORD("/")); b.SetLabelSize(10);
  Key(440, 100, 20, 20, "*", Fl.KeyKP + ORD("*")); b.SetLabelSize(10);
  Key(460, 100, 20, 20, "-", Fl.KeyKP + ORD("-")); b.SetLabelSize(10);
  Key(15, 120, 27, 20, "Tab", Fl.KeyTab); b.SetLabelSize(8); b.SetAlign(Fl.AlignLeft + Fl.AlignInside);
  Key(42, 120, 20, 20, "Q", 0); b.SetLabelSize(10);
  Key(62, 120, 20, 20, "W", 0); b.SetLabelSize(10);
  Key(82, 120, 20, 20, "E", 0); b.SetLabelSize(10);
  Key(102, 120, 20, 20, "R", 0); b.SetLabelSize(10);
  Key(122, 120, 20, 20, "T", 0); b.SetLabelSize(10);
  Key(142, 120, 20, 20, "Y", 0); b.SetLabelSize(10);
  Key(162, 120, 20, 20, "U", 0); b.SetLabelSize(10);
  Key(182, 120, 20, 20, "I", 0); b.SetLabelSize(10);
  Key(202, 120, 20, 20, "O", 0); b.SetLabelSize(10);
  Key(222, 120, 20, 20, "P", 0); b.SetLabelSize(10);
  Key(242, 120, 20, 20, "[", 0); b.SetLabelSize(10);
  Key(262, 120, 20, 20, "]", 0); b.SetLabelSize(10);
  Key(282, 120, 28, 20, "\", 0); b.SetLabelSize(10); b.SetAlign(Fl.AlignLeft + Fl.AlignInside);
  Key(325, 120, 20, 20, "Del ", Fl.KeyDelete); b.SetLabelSize(8);
  Key(345, 120, 20, 20, "End ", Fl.KeyEnd); b.SetLabelSize(8);
  Key(365, 120, 20, 20, "pgdn ", Fl.KeyPageDown); b.SetLabelSize(8);
  Key(400, 120, 20, 20, "7", Fl.KeyKP + ORD("7")); b.SetLabelSize(10);
  Key(420, 120, 20, 20, "8", Fl.KeyKP + ORD("8")); b.SetLabelSize(10);
  Key(440, 120, 20, 20, "9", Fl.KeyKP + ORD("9")); b.SetLabelSize(10);
  Key(460, 120, 20, 40, "+", Fl.KeyKP + ORD("+")); b.SetLabelSize(10); b.SetAlign(Fl.AlignTop + Fl.AlignInside);
  Key(15, 140, 36, 20, "Lock", Fl.KeyCapsLock); b.SetLabelSize(8); b.SetAlign(Fl.AlignLeft + Fl.AlignInside);
  Key(51, 140, 20, 20, "A", 0); b.SetLabelSize(10);
  Key(71, 140, 20, 20, "S", 0); b.SetLabelSize(10);
  Key(91, 140, 20, 20, "D", 0); b.SetLabelSize(10);
  Key(111, 140, 20, 20, "F", 0); b.SetLabelSize(10);
  Key(131, 140, 20, 20, "G", 0); b.SetLabelSize(10);
  Key(151, 140, 20, 20, "H", 0); b.SetLabelSize(10);
  Key(171, 140, 20, 20, "J", 0); b.SetLabelSize(10);
  Key(191, 140, 20, 20, "K", 0); b.SetLabelSize(10);
  Key(211, 140, 20, 20, "L", 0); b.SetLabelSize(10);
  Key(231, 140, 20, 20, ";", 0); b.SetLabelSize(10);
  Key(251, 140, 20, 20, "'", 0); b.SetLabelSize(10);
  Key(271, 140, 39, 20, "Enter", Fl.KeyEnter); b.SetLabelSize(8); b.SetAlign(Fl.AlignLeft + Fl.AlignInside);
  Key(400, 140, 20, 20, "4", Fl.KeyKP + ORD("4")); b.SetLabelSize(10);
  Key(420, 140, 20, 20, "5", Fl.KeyKP + ORD("5")); b.SetLabelSize(10);
  Key(440, 140, 20, 20, "6", Fl.KeyKP + ORD("6")); b.SetLabelSize(10);
  Key(15, 160, 45, 20, "Shift", Fl.KeyShiftL); b.SetLabelSize(8); b.SetAlign(Fl.AlignLeft + Fl.AlignInside);
  Key(60, 160, 20, 20, "Z", 0); b.SetLabelSize(10);
  Key(80, 160, 20, 20, "X", 0); b.SetLabelSize(10);
  Key(100, 160, 20, 20, "C", 0); b.SetLabelSize(10);
  Key(120, 160, 20, 20, "V", 0); b.SetLabelSize(10);
  Key(140, 160, 20, 20, "B", 0); b.SetLabelSize(10);
  Key(160, 160, 20, 20, "N", 0); b.SetLabelSize(10);
  Key(180, 160, 20, 20, "M", 0); b.SetLabelSize(10);
  Key(200, 160, 20, 20, ",", 0); b.SetLabelSize(10);
  Key(220, 160, 20, 20, ".", 0); b.SetLabelSize(10);
  Key(240, 160, 20, 20, "/", 0); b.SetLabelSize(10);
  Key(260, 160, 50, 20, "Shift", Fl.KeyShiftR); b.SetLabelSize(8); b.SetAlign(Fl.AlignLeft + Fl.AlignInside);
  Key(345, 160, 20, 20, "@8->", Fl.KeyUp); b.SetLabelType(Fl.ShadowLabel); b.SetLabelSize(10); b.SetLabelColor(Fl.Dark1);
  Key(400, 160, 20, 20, "1", Fl.KeyKP + ORD("1")); b.SetLabelSize(10);
  Key(420, 160, 20, 20, "2", Fl.KeyKP + ORD("2")); b.SetLabelSize(10);
  Key(440, 160, 20, 20, "3", Fl.KeyKP + ORD("3")); b.SetLabelSize(10);
  Key(460, 160, 20, 40, "", Fl.KeyKPEnter);
  Key(15, 180, 30, 20, "Ctrl", Fl.KeyControlL); b.SetLabelSize(8); b.SetAlign(Fl.AlignLeft + Fl.AlignInside);
  Key(45, 180, 30, 20, "Meta ", Fl.KeyMetaL); b.SetLabelSize(8);
  Key(75, 180, 30, 20, "Alt ", Fl.KeyAltL); b.SetLabelSize(8);
  Key(105, 180, 85, 20, "", ORD(" ")); b.SetLabelSize(10);
  Key(190, 180, 30, 20, "Alt ", Fl.KeyAltR); b.SetLabelSize(8);
  Key(220, 180, 30, 20, "Meta ", Fl.KeyMetaR); b.SetLabelSize(8);
  Key(250, 180, 30, 20, "Menu ", Fl.KeyMenu); b.SetLabelSize(8);
  Key(280, 180, 30, 20, "Ctrl", Fl.KeyControlR); b.SetLabelSize(8); b.SetAlign(Fl.AlignLeft + Fl.AlignInside);
  Key(325, 180, 20, 20, "@4->", Fl.KeyLeft); b.SetLabelType(Fl.ShadowLabel); b.SetLabelSize(10); b.SetLabelColor(Fl.Dark1);
  Key(345, 180, 20, 20, "@2->", Fl.KeyDown); b.SetLabelType(Fl.ShadowLabel); b.SetLabelSize(10); b.SetLabelColor(Fl.Dark1);
  Key(365, 180, 20, 20, "@6->", Fl.KeyRight); b.SetLabelType(Fl.ShadowLabel); b.SetLabelSize(10); b.SetLabelColor(Fl.Dark1);
  Key(400, 180, 40, 20, "0", Fl.KeyKP + ORD("0")); b.SetLabelSize(10); b.SetAlign(Fl.AlignLeft + Fl.AlignInside);
  Key(440, 180, 20, 20, ".", Fl.KeyKP + ORD(".")); b.SetLabelSize(10);
  NEW(box); Fl.OpenBox(box, 400, 15, 80, 0, "Fl::event_state():");
  box.SetLabelSize(9); box.SetAlign(Fl.AlignTopLeft);
  Shift(400, 15, 20, 10, "shift ", Fl.Shift); b.SetBoxType(Fl.ThinUpBox); b.SetSelectionColor(3); b.SetLabelSize(8);
  Shift(420, 15, 20, 10, "lock ", Fl.CapsLock); b.SetBoxType(Fl.ThinUpBox); b.SetSelectionColor(3); b.SetLabelSize(8);
  Shift(440, 15, 20, 10, "ctrl", Fl.Ctrl); b.SetBoxType(Fl.ThinUpBox); b.SetSelectionColor(3); b.SetLabelSize(8);
  Shift(460, 15, 20, 10, "alt", Fl.Alt); b.SetBoxType(Fl.ThinUpBox); b.SetSelectionColor(3); b.SetLabelSize(8);
  Shift(400, 25, 20, 10, "num", Fl.NumLock); b.SetBoxType(Fl.ThinUpBox); b.SetSelectionColor(3); b.SetLabelSize(8);
  Shift(420, 25, 20, 10, "?", {5}); b.SetBoxType(Fl.ThinUpBox); b.SetSelectionColor(3); b.SetLabelSize(8);
  Shift(440, 25, 20, 10, "meta ", Fl.Meta); b.SetBoxType(Fl.ThinUpBox); b.SetSelectionColor(3); b.SetLabelSize(8);
  Shift(460, 25, 20, 10, "sclk", Fl.ScrollLock); b.SetBoxType(Fl.ThinUpBox); b.SetSelectionColor(3); b.SetLabelSize(8);
  Shift(400, 35, 20, 10, "b1", Fl.Button1); b.SetBoxType(Fl.ThinUpBox); b.SetSelectionColor(3); b.SetLabelSize(8);
  Shift(420, 35, 20, 10, "b2", Fl.Button2); b.SetBoxType(Fl.ThinUpBox); b.SetSelectionColor(3); b.SetLabelSize(8);
  Shift(440, 35, 20, 10, "b3", Fl.Button3); b.SetBoxType(Fl.ThinUpBox); b.SetSelectionColor(3); b.SetLabelSize(8);
  Shift(460, 35, 20, 10, "bck", Fl.Button4); b.SetBoxType(Fl.ThinUpBox); b.SetSelectionColor(3); b.SetLabelSize(8);
  Shift(400, 45, 20, 10, "fwd", Fl.Button5); b.SetBoxType(Fl.ThinUpBox); b.SetSelectionColor(3); b.SetLabelSize(8);
  Shift(420, 45, 20, 10, "?", {13}); b.SetBoxType(Fl.ThinUpBox); b.SetSelectionColor(3); b.SetLabelSize(8);
  Shift(440, 45, 20, 10, "?", {14}); b.SetBoxType(Fl.ThinUpBox); b.SetSelectionColor(3); b.SetLabelSize(8);
  Shift(460, 45, 20, 10, "?", {15}); b.SetBoxType(Fl.ThinUpBox); b.SetSelectionColor(3); b.SetLabelSize(8);
  myWindow.End
END MakeWindow;

PROCEDURE Add(n: INTEGER; text: ARRAY OF CHAR);
BEGIN keyTable[nKeys].n := n; COPY(text, keyTable[nKeys].text); INC(nKeys)
END Add;

PROCEDURE MakeKeyTable;
BEGIN
  nKeys := 0;
  Add(Fl.KeyEscape, "FL_Escape"); Add(Fl.KeyBackSpace, "FL_BackSpace");
  Add(Fl.KeyTab, "FL_Tab"); Add(Fl.KeyIsoKey, "FL_Iso_Key");
  Add(Fl.KeyEnter, "FL_Enter"); Add(Fl.KeyPrint, "FL_Print");
  Add(Fl.KeyScrollLock, "FL_Scroll_Lock"); Add(Fl.KeyPause, "FL_Pause");
  Add(Fl.KeyInsert, "FL_Insert"); Add(Fl.KeyHome, "FL_Home");
  Add(Fl.KeyPageUp, "FL_Page_Up"); Add(Fl.KeyDelete, "FL_Delete");
  Add(Fl.KeyEnd, "FL_End"); Add(Fl.KeyPageDown, "FL_Page_Down");
  Add(Fl.KeyLeft, "FL_Left"); Add(Fl.KeyUp, "FL_Up");
  Add(Fl.KeyRight, "FL_Right"); Add(Fl.KeyDown, "FL_Down");
  Add(Fl.KeyShiftL, "FL_Shift_L"); Add(Fl.KeyShiftR, "FL_Shift_R");
  Add(Fl.KeyControlL, "FL_Control_L"); Add(Fl.KeyControlR, "FL_Control_R");
  Add(Fl.KeyCapsLock, "FL_Caps_Lock"); Add(Fl.KeyAltL, "FL_Alt_L");
  Add(Fl.KeyAltR, "FL_Alt_R"); Add(Fl.KeyMetaL, "FL_Meta_L");
  Add(Fl.KeyMetaR, "FL_Meta_R"); Add(Fl.KeyMenu, "FL_Menu");
  Add(Fl.KeyHelp, "FL_Help"); Add(Fl.KeyNumLock, "FL_Num_Lock");
  Add(Fl.KeyKPEnter, "FL_KP_Enter"); Add(Fl.KeyAltGr, "FL_Alt_Gr")
END MakeKeyTable;

(* Appends t to s. *)
PROCEDURE Cat(t-: ARRAY OF CHAR; VAR s: ARRAY OF CHAR);
  VAR i, j: INTEGER;
BEGIN
  i := 0; WHILE s[i] # 0X DO INC(i) END;
  j := 0; WHILE t[j] # 0X DO s[i] := t[j]; INC(i); INC(j) END;
  s[i] := 0X
END Cat;

(* Appends n, at least digits digits, in base (10, or 16 in lower case). *)
PROCEDURE CatNum(n, base, digits: INTEGER; VAR s: ARRAY OF CHAR);
  VAR d: ARRAY 24 OF CHAR; i, j, c: INTEGER;
BEGIN
  i := 0;
  REPEAT
    c := n MOD base; IF c < 10 THEN d[i] := CHR(ORD("0") + c) ELSE d[i] := CHR(ORD("a") + c - 10) END;
    n := n DIV base; INC(i)
  UNTIL (n = 0) & (i >= digits);
  j := 0; WHILE s[j] # 0X DO INC(j) END;
  WHILE i > 0 DO DEC(i); s[j] := d[i]; INC(j) END;
  s[j] := 0X
END CatNum;

(* keyboard.cxx's name for key k *)
PROCEDURE KeyName(k: INTEGER; VAR name: ARRAY OF CHAR);
  VAR key: ARRAY 8 OF CHAR; i, kl: INTEGER;
BEGIN
  COPY("", name);
  IF k = 0 THEN COPY("0", name)
  ELSIF k < 128 THEN   (* ASCII *)
    COPY("'", name); key[0] := CHR(k); key[1] := 0X; Cat(key, name); Cat("'", name)
  ELSIF (k >= 0A0H) & (k <= 0FFH) THEN   (* ISO-8859-1 (international keyboards) *)
    kl := FlUtf8.Encode(k, key); key[kl] := 0X;
    COPY("'", name); Cat(key, name); Cat("'", name)
  ELSIF (k > Fl.KeyF) & (k <= Fl.KeyFLast) THEN
    COPY("FL_F+", name); CatNum(k - Fl.KeyF, 10, 1, name)
  ELSIF (k >= Fl.KeyKP) & (k <= Fl.KeyKPLast) THEN
    COPY("FL_KP+'", name); key[0] := CHR(k - Fl.KeyKP); key[1] := 0X; Cat(key, name); Cat("'", name)
  ELSIF (k >= Fl.KeyButton) & (k <= Fl.KeyButton + 7) THEN
    COPY("FL_Button+", name); CatNum(k - Fl.KeyButton, 10, 1, name)
  ELSE
    COPY("0x", name); CatNum(k, 16, 4, name);
    i := 0;
    WHILE i < nKeys DO
      IF keyTable[i].n = k THEN COPY(keyTable[i].text, name); i := nKeys ELSE INC(i) END
    END
  END
END KeyName;

(* Sets the buttons, and the outputs, for the event just handled. *)
PROCEDURE Update;
  VAR k: KeyButton; s: ShiftButton; down: BOOLEAN;
    keyname, value: ARRAY 100 OF CHAR; str: ARRAY 256 OF CHAR;
BEGIN
  (* update all the buttons with the current key and shift state: *)
  k := keys;
  WHILE k # NIL DO
    down := Fl.EventKeyDown(k.key);
    IF k.Value() # down THEN k.SetValue(down) END;
    k := k.next
  END;
  s := shifts;
  WHILE s # NIL DO
    down := Fl.EventState() * s.state # {};
    IF s.Value() # down THEN s.SetValue(down) END;
    s := s.next
  END;
  (* figure out the keyname: *)
  KeyName(Fl.EventKey(), keyname);
  keyOutput.Value(value);
  IF value # keyname THEN keyOutput.SetValue(keyname) END;
  Fl.EventText(str);
  textOutput.Value(value);
  IF value # str THEN textOutput.SetValue(str) END
END Update;

BEGIN
  Fl.AddHandler(EatEscape);
  MakeKeyTable;
  MakeWindow;
  myWindow.ShowArgs;
  (* Fl::wait() is 0 once no window is shown *)
  WHILE Fl.WindowShown() DO
    Fl.Wait(1.0D20);
    IF Fl.WindowShown() THEN Update END
  END
END Keyboard.
