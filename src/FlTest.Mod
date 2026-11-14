MODULE FlTest; (* For a program's tests: its widgets used as by a user, and their drawing read back *)

(* A test drives the program as a user would, without a person or an
   input tool: events are sent to FLTK as the window system sends them,
   to windows shown or not, and what a widget draws is read back as
   pixels. pofltk's own tests use it so.

   - Capture draws a widget into an image, and Pixel reads it.
   - Mouse, Wheel, Key, Shortcut and HandleKey send one event each.
     FLTK routes a mouse event to the widget under the mouse, and a key
     to the focus widget.
   - Click, Type and Press are a user's commonest acts, built on them.
   - Fill, Choose, SelectLine, Turn and Change set a widget's value and
     run its callback, where an event can't simply be sent: a menu that
     isn't shown, a browser line not yet drawn.
   - Answer answers the next dialog (a modal window) by keys, from a
     timer, so a program's dialogs need not be replaced in its tests.

   Mind what FLTK does with events (AGENTS.md, "Tests and the display"):
   - a push no widget uses shows its window, as FLTK raises a window
     clicked in;
   - on X11 with no window manager (Xvfb), giving a widget the focus
     shows its window, and so may a Click, which a button takes the
     focus from, and Type (doc/fltk-issues.md, 176);
   - a key no widget uses, sent by HandleKey to a window never shown
     with the mouse over a widget, crashes FLTK 1.4.5;
   - a key must carry the text the window system gives it, as Press
     gives it: under Wayland FLTK takes a key with no text as composed
     text;
   - a browser takes no click until it is drawn (Capture).
   A test must delete the windows it opens, as any program should, or
   valgrind sees them as leaks.

   Its C++ part is FlTest.cpp. *)

IMPORT SYSTEM, Fl, FlButtons, FlInputs, FlValuators, FlMenus, FlBrowsers;

CONST
  tries = 400;  (* of 0.05 s, that Answer waits for a dialog: generous, for valgrind *)

TYPE
  (* Waits for a modal window, notes its title, types text into it and
     sends key. Then it fires once more: FLTK runs timers and then waits
     for an event, so a dialog's loop would end only when the next event
     came, and under Xvfb none comes (doc/fltk-issues.md, 32). *)
  Answerer = POINTER TO AnswererDesc;
  AnswererDesc = RECORD (Fl.TimerDesc)
    text: Fl.String;
    title: ARRAY 256 OF CHAR;
    key, tries, seen: INTEGER;
    sent: BOOLEAN
  END;

VAR
  last: Answerer;  (* the last Answer, kept from the collector as it waits *)

PROCEDURE ["C", "ofl_fltest_capture"] CCapture(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_fltest_pixel"] CPixel(x, y: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_fltest_release"] CRelease;
PROCEDURE ["C", "ofl_fltest_shown_pixel"] CShownPixel(w: SYSTEM.ADDRESS; x, y: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_fltest_mouse"] CMouse(win: SYSTEM.ADDRESS; event, x, y, button, state, clicks: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_fltest_wheel"] CWheel(win: SYSTEM.ADDRESS; x, y, dx, dy: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_fltest_key"] CKey(event, key, state: SYSTEM.INT32; s: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_fltest_shortcut"] CShortcut(win: SYSTEM.ADDRESS; key, state: SYSTEM.INT32; s: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_fltest_handle_key"] CHandleKey(win: SYSTEM.ADDRESS; event, key, state: SYSTEM.INT32; s: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_fltest_modal_key"] CModalKey(key, state: SYSTEM.INT32; s: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_fltest_modal"] CModal(VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_fltest_radio"] CRadio(w: SYSTEM.ADDRESS): SYSTEM.INT32;

(* As 0xRRGGBB from the C++ part, as Fl.RGB gives a colour. *)
PROCEDURE Color(p: INTEGER): INTEGER;
BEGIN RETURN Fl.RGB(p DIV 10000H, p DIV 100H MOD 100H, p MOD 100H)
END Color;

(* Drawing *)

(* Draws w, as FLTK would in its window, on white, for Pixel; TRUE if
   the image is w's size. w's window need not be shown. *)
PROCEDURE Capture*(w: Fl.Widget): BOOLEAN;
BEGIN RETURN CCapture(Fl.Live(w)) # 0
END Capture;

(* Pixel x, y of the capture, from w's top left, as Fl.RGB gives it; -1
   outside it, or with no capture. *)
PROCEDURE Pixel*(x, y: INTEGER): INTEGER;
  VAR p: INTEGER;
BEGIN
  p := CPixel(x, y);
  IF p < 0 THEN RETURN -1 END;
  RETURN Color(p)
END Pixel;

(* Frees the capture. *)
PROCEDURE Release*;
BEGIN CRelease
END Release;

(* Pixel x, y of what shown window w shows, as Fl.RGB gives it: what the
   window system has, where Capture draws the widget anew. *)
PROCEDURE ShownPixel*(w: Fl.Window; x, y: INTEGER): INTEGER;
BEGIN RETURN Color(CShownPixel(Fl.Live(w), x, y))
END ShownPixel;

(* Events *)

(* A mouse event, EvPush, EvRelease, EvDrag, EvMove and the rest, sent to
   win as from the window system; TRUE if a widget used it. x, y are in
   win's coordinates; button is Fl.LeftMouse and so on, state the
   buttons and keys held (Fl.Button1, Fl.Ctrl, ...), clicks the clicks
   before this one, as Fl.EventClicks gives them. *)
PROCEDURE Mouse*(win: Fl.Window; event, x, y, button: INTEGER; state: SET; clicks: INTEGER): BOOLEAN;
BEGIN RETURN CMouse(Fl.Live(win), event, x, y, button, ORD(state), clicks) # 0
END Mouse;

(* The mouse wheel turned dx across and dy down, the mouse at x, y. *)
PROCEDURE Wheel*(win: Fl.Window; x, y, dx, dy: INTEGER): BOOLEAN;
BEGIN RETURN CWheel(Fl.Live(win), x, y, dx, dy) # 0
END Wheel;

(* A key event, EvKeyDown or EvKeyUp, of key typing text, sent to the
   focus widget alone, which FLTK offers it first; FALSE if there is no
   focus or it didn't use the key. *)
PROCEDURE Key*(event, key: INTEGER; state: SET; text-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CKey(event, key, ORD(state), text) # 0
END Key;

(* A key offered to win's widgets as a shortcut, as FLTK offers one the
   focus doesn't use; TRUE if one used it. *)
PROCEDURE Shortcut*(win: Fl.Window; key: INTEGER; state: SET; text-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CShortcut(Fl.Live(win), key, ORD(state), text) # 0
END Shortcut;

(* A key event, EvKeyDown or EvShortcut, sent by FLTK's route, as
   from the window system: to a pop-up menu if one is up, else a shortcut
   goes to win's widgets and then to a global menu. Not a key no widget
   uses after mouse events, in a window never shown, which crashes FLTK. *)
PROCEDURE HandleKey*(win: Fl.Window; event, key: INTEGER; state: SET; text-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CHandleKey(Fl.Live(win), event, key, ORD(state), text) # 0
END HandleKey;

(* TRUE if a modal window, a dialog, is shown, with its title in title. *)
PROCEDURE Modal*(VAR title: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CModal(title, SHORT(LEN(title))) # 0
END Modal;

(* A key sent to the modal window, a dialog, as from the window system;
   FALSE if no modal window is shown, or nothing in it used the key. *)
PROCEDURE ModalKey*(key: INTEGER; state: SET; text-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CModalKey(key, ORD(state), text) # 0
END ModalKey;

(* A user's acts *)

(* The text the window system gives key, with state held, in text: the
   control character of BackSpace, Tab, Enter, Escape and Delete, the
   character of a printable ASCII key without Ctrl, Alt or Meta, and
   none for the rest. *)
PROCEDURE KeyText*(key: INTEGER; state: SET; VAR text: ARRAY OF CHAR);
  VAR c: CHAR;
BEGIN
  c := 0X;
  IF key = Fl.KeyBackSpace THEN c := 08X
  ELSIF key = Fl.KeyTab THEN c := 09X
  ELSIF (key = Fl.KeyEnter) OR (key = Fl.KeyKPEnter) THEN c := 0DX
  ELSIF key = Fl.KeyEscape THEN c := 1BX
  ELSIF key = Fl.KeyDelete THEN c := 7FX
  ELSIF (key >= 20H) & (key < 7FH) & (state * (Fl.Ctrl + Fl.Alt + Fl.Meta) = {}) THEN
    c := CHR(key)
  END;
  IF LEN(text) > 1 THEN text[0] := c; text[1] := 0X ELSE text[0] := 0X END
END KeyText;

(* A left click in the middle of w, a push and a release sent to its
   window; TRUE if the push was used. A push no widget uses (w inactive,
   or under another widget) shows the window, as FLTK raises a window
   clicked in. Halts Fl.Unsupported if w is in no window. *)
PROCEDURE Click*(w: Fl.Widget): BOOLEAN;
  VAR win: Fl.Window; x, y: INTEGER; used, ok: BOOLEAN;
BEGIN
  win := w.Window();
  IF win # NIL THEN
    x := w.X() + w.W() DIV 2; y := w.Y() + w.H() DIV 2
  ELSE
    ASSERT(w IS Fl.Window, Fl.Unsupported);
    win := w(Fl.Window); x := w.W() DIV 2; y := w.H() DIV 2
  END;
  used := Mouse(win, Fl.EvPush, x, y, Fl.LeftMouse, Fl.Button1, 0);
  (* The push's callback may have deleted the window. *)
  IF win.IsOpen() THEN ok := Mouse(win, Fl.EvRelease, x, y, Fl.LeftMouse, {}, 0) END;
  RETURN used
END Click;

(* key pressed, with state held, carrying the text KeyText gives it, sent
   to the focus widget as Key sends it; TRUE if it was used. *)
PROCEDURE Press*(key: INTEGER; state: SET): BOOLEAN;
  VAR t: ARRAY 2 OF CHAR;
BEGIN
  KeyText(key, state, t);
  RETURN Key(Fl.EvKeyDown, key, state, t)
END Press;

(* The character at text[i], a UTF-8 sequence, copied into c, with its
   code point in code, as the window system gives a character's key; i
   moved past it. A byte that leads no whole sequence is one character,
   as FLTK reads it as CP1252 or Latin-1. *)
PROCEDURE NextChar(text-: ARRAY OF CHAR; VAR i: INTEGER; VAR c: ARRAY OF CHAR; VAR code: INTEGER);
  VAR j, n: INTEGER; b: CHAR;
BEGIN
  b := text[i];
  IF (b >= 0C2X) & (b <= 0DFX) THEN n := 2; code := ORD(b) MOD 20H
  ELSIF (b >= 0E0X) & (b <= 0EFX) THEN n := 3; code := ORD(b) MOD 10H
  ELSIF (b >= 0F0X) & (b <= 0F4X) THEN n := 4; code := ORD(b) MOD 8
  ELSE n := 1; code := ORD(b)
  END;
  c[0] := b; j := 1;
  WHILE (j < n) & (i + j < LEN(text)) & (text[i + j] >= 80X) & (text[i + j] < 0C0X) DO
    c[j] := text[i + j]; code := code * 40H + ORD(c[j]) MOD 40H; INC(j)
  END;
  IF j < n THEN j := 1; code := ORD(b) END;
  c[j] := 0X; INC(i, j)
END NextChar;

(* w given the focus, then text typed into it, a key down per character
   (per UTF-8 sequence), each carrying its character as its text; TRUE if
   w took the focus and each key was used. An input's callback runs as
   its When says: by default only when it loses the focus, or at Enter
   (Press(Fl.KeyEnter, {})) if its When has WhenEnterKey. *)
PROCEDURE Type*(w: Fl.Widget; text-: ARRAY OF CHAR): BOOLEAN;
  VAR i, code: INTEGER; c: ARRAY 5 OF CHAR; ok: BOOLEAN;
BEGIN
  Fl.SetFocus(w);
  ok := Fl.Focus() = w;
  i := 0;
  WHILE ok & (i < LEN(text)) & (text[i] # 0X) DO
    NextChar(text, i, c, code);
    ok := Key(Fl.EvKeyDown, code, {}, c)
  END;
  RETURN ok
END Type;

(* i's text set to text and its callback run, as a user's edit followed
   by leaving the field. *)
PROCEDURE Fill*(i: FlInputs.Input; text-: ARRAY OF CHAR);
BEGIN i.SetValue(text); i.DoCallback
END Fill;

(* Whether label, as FLTK holds it (s), is text: the same, or the same
   with each "&&" and "@@" read as one, as AddText doubles them. *)
PROCEDURE SameLabel(s-, text-: ARRAY OF CHAR): BOOLEAN;
  VAR i, j: INTEGER;
BEGIN
  IF s = text THEN RETURN TRUE END;
  i := 0; j := 0;
  LOOP
    IF ((s[i] = "&") OR (s[i] = "@")) & (s[i + 1] = s[i]) THEN INC(i) END;
    IF s[i] # text[j] THEN RETURN FALSE END;
    IF s[i] = 0X THEN RETURN TRUE END;
    INC(i); INC(j)
  END
END SameLabel;

(* The first item of m labelled label picked, as Menu.Pick picks it: its
   value set, and the item's action or the menu's run. label is the
   item's own, without its path, as given to Add or AddText, or as
   ItemLabel gives it. FALSE, and nothing picked, if no item has it. *)
PROCEDURE Choose*(m: FlMenus.Menu; label-: ARRAY OF CHAR): BOOLEAN;
  VAR i, n: INTEGER; s: Fl.String;
BEGIN
  (* An item AddText added holds label with its "&" and "@" doubled; one
     longer than that can't be it. *)
  NEW(s, 2 * LEN(label) + 2);
  n := m.Length(); i := 0;
  WHILE i < n DO
    IF m.IsItem(i) THEN
      m.ItemLabel(i, s^);
      IF SameLabel(s^, label) THEN m.Pick(i); RETURN TRUE END
    END;
    INC(i)
  END;
  RETURN FALSE
END Choose;

(* Whether s holds text. *)
PROCEDURE Contains(s-, text-: ARRAY OF CHAR): BOOLEAN;
  VAR i, j: INTEGER;
BEGIN
  i := 0;
  REPEAT
    j := 0;
    WHILE (text[j] # 0X) & (s[i + j] = text[j]) DO INC(j) END;
    IF text[j] = 0X THEN RETURN TRUE END;
    INC(i)
  UNTIL s[i - 1] = 0X;
  RETURN FALSE
END Contains;

(* The first line of b whose text holds text, format characters and all,
   searching each line's first 4095 bytes; 0 if none does. *)
PROCEDURE LineWith*(b: FlBrowsers.Browser; text-: ARRAY OF CHAR): INTEGER;
  VAR i, n: INTEGER; s: ARRAY 4096 OF CHAR;
BEGIN
  n := b.Count();
  FOR i := 1 TO n DO
    b.GetText(i, s);
    IF Contains(s, text) THEN RETURN i END
  END;
  RETURN 0
END LineWith;

(* Line line of b selected, the others deselected, and b's callback run,
   as a click on the line does. Halts Fl.IndexOutOfRange outside 1 to
   b.Count(). *)
PROCEDURE SelectLine*(b: FlBrowsers.Browser; line: INTEGER);
  VAR i, n: INTEGER;
BEGIN
  b.SetSelected(line, TRUE);
  n := b.Count();
  FOR i := 1 TO n DO IF i # line THEN b.SetSelected(i, FALSE) END END;
  b.DoCallback
END SelectLine;

(* b set on or off, and its callback run, if that changes it: a radio
   button is turned on as a click turns it on, turning its group's others
   off. *)
PROCEDURE Turn*(b: FlButtons.Button; on: BOOLEAN);
BEGIN
  IF b.Value() # on THEN
    IF on & (CRadio(Fl.Live(b)) # 0) THEN b.SetOnly ELSE b.SetValue(on) END;
    b.DoCallback
  END
END Turn;

(* w, a valuator or a spinner, set to x, and its callback run, if that
   changes it. Halts Fl.Unsupported for another widget. *)
PROCEDURE Change*(w: Fl.Widget; x: LONGREAL);
  VAR old, new: LONGREAL;
BEGIN
  IF w IS FlValuators.Valuator THEN
    old := w(FlValuators.Valuator).Value(); w(FlValuators.Valuator).SetValue(x);
    new := w(FlValuators.Valuator).Value()
  ELSE
    ASSERT(w IS FlValuators.Spinner, Fl.Unsupported);
    old := w(FlValuators.Spinner).Value(); w(FlValuators.Spinner).SetValue(x);
    new := w(FlValuators.Spinner).Value()
  END;
  IF new # old THEN w.DoCallback END
END Change;

(* The loop *)

(* FLTK's loop run a few times, for what a test's events started:
   redraws, timers, a window's layout. *)
PROCEDURE Settle*;
  VAR i: INTEGER;
BEGIN FOR i := 1 TO 5 DO Fl.Wait(0.01D0) END
END Settle;

(* w shown, and the loop run until the window system has shown it and
   FLTK has handled what that brought. *)
PROCEDURE Expose*(w: Fl.Window);
BEGIN w.Show; w.WaitForExpose; Fl.HandlePending
END Expose;

(* Dialogs *)

PROCEDURE (a: Answerer) Fire*;
  VAR i, code: INTEGER; c: ARRAY 5 OF CHAR; k: ARRAY 2 OF CHAR; ok: BOOLEAN;
BEGIN
  IF a.sent THEN (* only to wake the loop *)
  ELSIF ~Modal(a.title) THEN
    INC(a.tries); IF a.tries < tries THEN Fl.RepeatTimeout(a, 0.05D0) END
  ELSIF a.seen < 2 THEN  (* let it settle *)
    INC(a.seen); Fl.RepeatTimeout(a, 0.05D0)
  ELSE
    i := 0;
    WHILE a.text[i] # 0X DO NextChar(a.text^, i, c, code); ok := ModalKey(code, {}, c) END;
    KeyText(a.key, {}, k);
    ok := ModalKey(a.key, {}, k);
    a.sent := TRUE; Fl.RepeatTimeout(a, 0.01D0)
  END
END Fire;

(* Answers the next dialog: a timer waits up to 20 seconds for a modal
   window, then types text into it, a key per character, and sends key,
   with the text KeyText gives it. Call it just before the call that
   shows the dialog, which returns once it is answered. The text goes to
   the dialog's focus widget: its input, if it has one. *)
PROCEDURE Answer*(text-: ARRAY OF CHAR; key: INTEGER);
  VAR n: INTEGER;
BEGIN
  NEW(last);
  n := 0; WHILE (n < LEN(text)) & (text[n] # 0X) DO INC(n) END;
  NEW(last.text, n + 1); last.text[n] := 0X;
  WHILE n > 0 DO DEC(n); last.text[n] := text[n] END;
  last.key := key;
  Fl.AddTimeout(last, 0.05D0)
END Answer;

(* Answers the next dialog with Enter: its default button. *)
PROCEDURE Enter*;
BEGIN Answer("", Fl.KeyEnter)
END Enter;

(* Answers the next dialog with Escape: cancelled. *)
PROCEDURE Escape*;
BEGIN Answer("", Fl.KeyEscape)
END Escape;

(* TRUE if the last Answer found its dialog and sent its keys, with the
   dialog's title in title; FALSE, and title "", if it is waiting, gave
   up, or there was none. *)
PROCEDURE Answered*(VAR title: ARRAY OF CHAR): BOOLEAN;
BEGIN
  IF (last # NIL) & last.sent THEN COPY(last.title, title); RETURN TRUE END;
  title[0] := 0X; RETURN FALSE
END Answered;

END FlTest.
