MODULE Input; (* FLTK's test/input.cxx in Oberon-2 *)

(* Five kinds of input field, and toggle buttons setting when they call
   back; the terminal shows each callback, and "print changed()" the
   fields changed since it was last pushed, with the character at each
   one's cursor. The buttons on the right change the inputs' colors, and
   the light buttons the navigation by Tab in the multiline field and by
   the arrow keys. *)

IMPORT Err, Fl, FlButtons, FlDialogs, FlInputs, FlTerminal, FlUtf8;

CONST
  TerminalHeight = 120;

TYPE
  Action = PROCEDURE (w: Fl.Widget);

VAR
  window: Fl.Window;
  tty: FlTerminal.Terminal;
  input: ARRAY 5 OF FlInputs.Input;
  normal: FlInputs.Input;
  float: FlInputs.FloatInput;
  int: FlInputs.IntInput;
  secret: FlInputs.SecretInput;
  multi: FlInputs.MultilineInput;
  toggles: ARRAY 4 OF FlButtons.ToggleButton;
  whens: ARRAY 4 OF SET;
  colorButton, selectionButton, textButton: FlButtons.Button;
  b: FlButtons.Button;
  lb: FlButtons.LightButton;
  when: SET;
  i, y, y1: INTEGER;
  help: ARRAY 4096 OF CHAR;

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
  j := 0; WHILE (s[j] # 0X) & (i < LEN(t) - 1) DO t[i] := s[j]; INC(i); INC(j) END;
  t[i] := 0X
END Cat;

(* "<label> '<value>'" of input w *)
PROCEDURE Describe(w: FlInputs.Input; VAR s: ARRAY OF CHAR);
VAR v: ARRAY 4096 OF CHAR;
BEGIN
  w.GetLabel(v); Cat(v, s); Cat(" '", s);
  w.Value(v); Cat(v, s); Cat("'", s)
END Describe;

PROCEDURE Callback(o: Fl.Widget);
VAR s: ARRAY 8192 OF CHAR;
BEGIN
  s := "Callback for "; Describe(o(FlInputs.Input), s); Cat(0AX, s);
  tty.Append(s)
END Callback;

PROCEDURE ToggleCallback(o: Fl.Widget);
VAR i: INTEGER;
BEGIN
  FOR i := 0 TO 3 DO
    IF o = toggles[i] THEN
      IF toggles[i].Value() THEN when := when + whens[i] ELSE when := when - whens[i] END
    END
  END;
  FOR i := 0 TO 4 DO input[i].SetWhen(when) END
END ToggleCallback;

(* Shows i if it has changed, and the character at its cursor, 0X at
   the end. *)
PROCEDURE Test(i: FlInputs.Input);
VAR s: ARRAY 8192 OF CHAR; u: ARRAY 10 OF CHAR;
BEGIN
  IF i.Changed() THEN
    i.SetChanged(FALSE);
    s := ""; Describe(i, s); Cat(0AX, s); tty.Append(s);
    u[FlUtf8.Encode(i.Index(i.InsertPosition()), u)] := 0X;
    s := "Symbol at cursor position: "; Cat(u, s); Cat(0AX, s); tty.Append(s)
  END
END Test;

PROCEDURE ButtonCallback(o: Fl.Widget);
VAR i: INTEGER;
BEGIN
  FOR i := 0 TO 4 DO Test(input[i]) END
END ButtonCallback;

PROCEDURE ColorCallback(button: Fl.Widget);
VAR c, r, g, b: INTEGER;
BEGIN
  IF button = colorButton THEN c := Fl.Background2Color
  ELSIF button = selectionButton THEN c := Fl.SelectionColor
  ELSE c := Fl.ForegroundColor
  END;
  Fl.GetRGB(c, r, g, b);
  IF FlDialogs.ChooseColor("", r, g, b, FlDialogs.ColorDefault) THEN
    Fl.SetIndexColor(c, Fl.RGB(r, g, b)); Fl.Redraw;
    button.SetLabelColor(Fl.Contrast(Fl.Black, c));
    button.Redraw
  END
END ColorCallback;

PROCEDURE TabNavCallback(w: Fl.Widget);
BEGIN multi.SetTabNav(w(FlButtons.LightButton).Value())
END TabNavCallback;

PROCEDURE ArrowNavCallback(w: Fl.Widget);
BEGIN Fl.SetOption(Fl.OptionArrowFocus, w(FlButtons.LightButton).Value())
END ArrowNavCallback;

PROCEDURE Toggle(i: INTEGER; label-: ARRAY OF CHAR; w: SET; tip-: ARRAY OF CHAR);
BEGIN
  NEW(toggles[i]); FlButtons.OpenToggleButton(toggles[i], 10, y, 200, 25, label);
  whens[i] := w; toggles[i].action := ToggleCallback; INC(y, 25);
  toggles[i].SetTooltip(tip)
END Toggle;

PROCEDURE ColorButton(VAR b: FlButtons.Button; label-: ARRAY OF CHAR; color: INTEGER; tip-: ARRAY OF CHAR);
BEGIN
  NEW(b); FlButtons.OpenButton(b, 220, y1, 120, 25, label); INC(y1, 25);
  b.SetColor(color); b.action := ColorCallback;
  b.SetTooltip(tip)
END ColorButton;

BEGIN
  (* the following two lines set the correct color scheme, so that
     Contrast below will return good results *)
  IF ~Fl.ParseArgs(NIL, i) THEN
    Fl.ArgsHelp(help); Err.String(help); Err.Ln; HALT(1)
  END;
  Fl.GetSystemColors;
  NEW(window); Fl.OpenWindow(window, 400, 420 + TerminalHeight, "");
  NEW(tty); FlTerminal.OpenTerminal(tty, 0, 420, window.W(), TerminalHeight, "");

  y := 10;
  NEW(normal); FlInputs.OpenInput(normal, 70, y, 300, 30, "Normal:"); INC(y, 35);
  normal.SetTooltip("Normal input field");
  NEW(float); FlInputs.OpenFloatInput(float, 70, y, 300, 30, "Float:"); INC(y, 35);
  float.SetTooltip("Input field for floating-point number (F1)");
  float.SetShortcut(Fl.KeyF + 1, {});
  NEW(int); FlInputs.OpenIntInput(int, 70, y, 300, 30, "Int:"); INC(y, 35);
  int.SetTooltip("Input field for integer number (F2)");
  int.SetShortcut(Fl.KeyF + 2, {});
  NEW(secret); FlInputs.OpenSecretInput(secret, 70, y, 300, 30, "&Secret:"); INC(y, 35);
  secret.SetTooltip("Input field for password (Alt-S)");
  NEW(multi); FlInputs.OpenMultilineInput(multi, 70, y, 300, 100, "&Multiline:"); INC(y, 105);
  multi.SetTooltip("Input field for short text with newlines (Alt-M)");
  multi.SetWrap(TRUE);
  input[0] := normal; input[1] := float; input[2] := int; input[3] := secret; input[4] := multi;

  FOR i := 0 TO 3 DO
    input[i].SetWhen(Fl.WhenNever); input[i].action := Callback
  END;
  y1 := y;

  Toggle(0, "FL_WHEN_CHANGED", Fl.WhenChanged, "Do callback each time the text changes");
  Toggle(1, "FL_WHEN_RELEASE", Fl.WhenRelease, "Do callback when widget loses focus");
  Toggle(2, "FL_WHEN_ENTER_KEY", Fl.WhenEnterKey, "Do callback when user hits Enter key");
  Toggle(3, "FL_WHEN_NOT_CHANGED", Fl.WhenNotChanged, "Do callback even if the text is not changed");
  INC(y, 5);
  NEW(b); FlButtons.OpenButton(b, 10, y, 200, 25, "&print changed()"); INC(y, 25);
  b.action := ButtonCallback;
  b.SetTooltip("Print widgets that have changed() flag set");

  NEW(lb); FlButtons.OpenLightButton(lb, 10, y, 100, 25, " Tab Nav");
  lb.SetTooltip("Control tab navigation for the multiline input field");
  lb.action := TabNavCallback;
  lb.SetValue(multi.TabNav());
  NEW(lb); FlButtons.OpenLightButton(lb, 110, y, 100, 25, " Arrow Nav"); INC(y, 25);
  help := "Control horizontal arrow key focus navigation behavior.|e.g. Fl::OPTION_ARROW_FOCUS"; Lines(help);
  lb.SetTooltip(help);
  lb.action := ArrowNavCallback;
  lb.SetValue(Fl.Option(Fl.OptionArrowFocus));

  ColorButton(colorButton, "color", normal.Color(), "Color behind the text");
  ColorButton(selectionButton, "selection_color", normal.SelectionColor(), "Color behind selected text");
  selectionButton.SetLabelColor(Fl.Contrast(Fl.Black, selectionButton.Color()));
  ColorButton(textButton, "textcolor", normal.TextColor(), "Color of the text");
  textButton.SetLabelColor(Fl.Contrast(Fl.Black, textButton.Color()));

  window.End;
  window.SetResizable(tty);
  window.ShowArgs;
  Fl.Run
END Input.
