MODULE Radio; (* FLTK's test/radio.fl in Oberon-2 *)

(* The kinds of button: push, return, light, check and round buttons,
   and two groups of radio buttons. Each callback shows the button's
   label, value and whether it changed, and prints them. *)

IMPORT Out, Fl, FlButtons, FlInputs;

CONST
  Tip = "Radio button, only one button is set at a time, in the corresponding group.";
  CustomTip = "Custom look button, only one button is set at a time, in the corresponding group.";

VAR
  w: Fl.DoubleWindow;
  g: Fl.Group;
  cbInfo: FlInputs.MultilineOutput;
  i: INTEGER;

(* Appends s to t. *)
PROCEDURE Cat(s-: ARRAY OF CHAR; VAR t: ARRAY OF CHAR);
VAR i, j: INTEGER;
BEGIN
  i := 0; WHILE t[i] # 0X DO INC(i) END;
  j := 0; WHILE s[j] # 0X DO t[i] := s[j]; INC(i); INC(j) END;
  t[i] := 0X
END Cat;

(* Appends 0 or 1 to s. *)
PROCEDURE Bool(b: BOOLEAN; VAR s: ARRAY OF CHAR);
BEGIN IF b THEN Cat("1", s) ELSE Cat("0", s) END
END Bool;

PROCEDURE ButtonCallback(o: Fl.Widget);
VAR msg, label: ARRAY 256 OF CHAR; nl: ARRAY 2 OF CHAR;
BEGIN
  nl[0] := 0AX; nl[1] := 0X;
  o.GetLabel(label);
  msg := "Label: '"; Cat(label, msg); Cat("'", msg); Cat(nl, msg);
  Cat("Value: ", msg); Bool(o(FlButtons.Button).Value(), msg); Cat(nl, msg);
  (* FLTK's program prints changed()'s flag bit, 128 *)
  Cat("Changed: ", msg); IF o.Changed() THEN Cat("128", msg) ELSE Cat("0", msg) END;
  cbInfo.SetValue(msg);
  cbInfo.Redraw;
  Out.String(msg); Out.Ln
END ButtonCallback;

PROCEDURE Push(y: INTEGER; label-, tip: ARRAY OF CHAR; when: BOOLEAN);
VAR b: FlButtons.Button;
BEGIN
  NEW(b); FlButtons.OpenButton(b, 20, y, 160, 30, label);
  b.SetTooltip(tip); b.SetLabelSize(13);
  IF when THEN b.SetWhen(Fl.WhenChanged) END;
  b.action := ButtonCallback
END Push;

PROCEDURE RadioRound(y: INTEGER; label-: ARRAY OF CHAR);
VAR b: FlButtons.RoundButton;
BEGIN
  NEW(b); FlButtons.OpenRoundButton(b, 190, y, 70, 30, label);
  b.SetTooltip(Tip);
  b.SetKind(FlButtons.Radio);
  b.SetDownBox(Fl.RoundDownBox);
  b.action := ButtonCallback
END RadioRound;

PROCEDURE Custom(y: INTEGER);
VAR b: FlButtons.Button;
BEGIN
  NEW(b); FlButtons.OpenButton(b, 280, y, 20, 20, "radio");
  b.SetTooltip(CustomTip);
  b.SetKind(FlButtons.Radio);
  b.SetSelectionColor(1);
  b.SetAlign(Fl.AlignRight)
END Custom;

PROCEDURE Buttons;
VAR r: FlButtons.ReturnButton; l: FlButtons.LightButton;
  c: FlButtons.CheckButton; o: FlButtons.RoundButton;
BEGIN
  Push(10, "&Fl_Button A1", "Normal button (callback called only when released)", FALSE);
  Push(44, "Fl_Button &A2", "Normal button with callback called when changed (push and released)", TRUE);
  NEW(r); FlButtons.OpenReturnButton(r, 20, 78, 160, 30, "Fl_Return_Button &B");
  r.SetTooltip("Button with Return key as default shortcut");
  r.SetLabelSize(13); r.action := ButtonCallback;
  NEW(l); FlButtons.OpenLightButton(l, 20, 113, 160, 30, "Fl_Light_Button &C");
  l.SetTooltip("Button with toggle state and a visual indicator of the current state");
  l.SetLabelSize(13); l.action := ButtonCallback;
  NEW(c); FlButtons.OpenCheckButton(c, 20, 148, 160, 30, "Fl_Check_Button &D");
  c.SetTooltip("Check button with toggle state");
  c.SetDownBox(Fl.DownBox);
  c.SetLabelSize(13); c.action := ButtonCallback;
  NEW(o); FlButtons.OpenRoundButton(o, 20, 178, 160, 30, "Fl_Round_Button &E");
  o.SetTooltip("Round Button with toggle state");
  o.SetDownBox(Fl.RoundDownBox);
  o.SetLabelSize(13); o.action := ButtonCallback
END Buttons;

BEGIN
  NEW(w); Fl.OpenDoubleWindow(w, 369, 214, "");
  Buttons;
  NEW(g); Fl.OpenGroup(g, 190, 10, 70, 120, "");
  g.SetBoxType(Fl.ThinUpFrame);
  RadioRound(10, "radio &1"); RadioRound(40, "radio &2");
  RadioRound(70, "radio &3"); RadioRound(100, "radio &4");
  g.End;
  NEW(g); Fl.OpenGroup(g, 270, 10, 90, 120, "");
  g.SetBoxType(Fl.ThinUpBox);
  FOR i := 0 TO 3 DO Custom(20 + 25 * i) END;
  g.End;
  NEW(cbInfo); FlInputs.OpenMultilineOutput(cbInfo, 190, 148, 170, 62, "callback:");
  cbInfo.SetTextSize(12);
  cbInfo.SetAlign(Fl.AlignTop + Fl.AlignLeft + Fl.AlignWrap);
  w.End;
  w.ShowArgs;
  Fl.Run
END Radio.
