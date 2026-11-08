MODULE RotatedText; (* FLTK's test/rotated_text.cxx in Oberon-2 *)

(* Text drawn at an angle, in a box drawn by the program: the sliders
   set the angle, font and size, the input the text, the toggles align
   it left or right of the box's centre, or clip it, and the choice
   draws it plain, shadowed, engraved or embossed. *)

IMPORT MathL, Fl, FlButtons, FlDraw, FlInputs, FlMenus, FlValuators;

TYPE
  (* FLTK's Rotated_Label_Box: its drawing is fl_engraved_label.cxx's. *)
  RotatedBox = POINTER TO RotatedBoxDesc;
  RotatedBoxDesc = RECORD (Fl.BoxDesc)
    angle: INTEGER;
    text: ARRAY 1024 OF CHAR;
    align: SET
  END;

VAR
  leftb, rightb, clipb: FlButtons.ToggleButton;
  input: FlInputs.Input;
  fonts, sizes, angles: FlValuators.ValueSlider;
  window: Fl.DoubleWindow;
  text: RotatedBox;
  g: Fl.Group;
  c: FlMenus.Choice;
  n: INTEGER;

(* C's conversion of a double to an int, toward 0. *)
PROCEDURE Trunc(r: LONGREAL): INTEGER;
BEGIN
  IF r < 0 THEN RETURN -SHORT(ENTIER(-r)) ELSE RETURN SHORT(ENTIER(r)) END
END Trunc;

(* C's division of ints, toward 0. *)
PROCEDURE Half(n: INTEGER): INTEGER;
BEGIN
  IF n < 0 THEN RETURN -((-n) DIV 2) ELSE RETURN n DIV 2 END
END Half;

PROCEDURE Rad(degrees: INTEGER): LONGREAL;
BEGIN RETURN MathL.pi * degrees / 180.0D0
END Rad;

(* The text at X, Y, once for each offset and colour, the last in the
   label's colour. *)
PROCEDURE (b: RotatedBox) Innards(X, Y: INTEGER; data: ARRAY OF INTEGER);
  VAR i, k: INTEGER;
BEGIN
  k := SHORT(LEN(data)) DIV 3;
  FOR i := 0 TO k - 1 DO
    IF i < k - 1 THEN FlDraw.SetColor(data[i * 3 + 2]) ELSE FlDraw.SetColor(b.LabelColor()) END;
    FlDraw.TextRotated(b.angle, b.text, X + data[i * 3], Y + data[i * 3 + 1])
  END
END Innards;

PROCEDURE (b: RotatedBox) ShadowLabel(X, Y: INTEGER);
  VAR data: ARRAY 6 OF INTEGER;
BEGIN
  data[0] := 2; data[1] := 2; data[2] := Fl.Dark3;
  data[3] := 0; data[4] := 0; data[5] := 0;
  b.Innards(X, Y, data)
END ShadowLabel;

(* Seven offsets: three in light, three in dark, s giving their signs,
   then the text itself. *)
PROCEDURE (b: RotatedBox) Relief(X, Y, s: INTEGER);
  VAR data: ARRAY 21 OF INTEGER;

  PROCEDURE Set(i, dx, dy, c: INTEGER);
  BEGIN data[i * 3] := dx; data[i * 3 + 1] := dy; data[i * 3 + 2] := c
  END Set;

BEGIN
  Set(0, s, 0, Fl.Light3); Set(1, s, s, Fl.Light3); Set(2, 0, s, Fl.Light3);
  Set(3, -s, 0, Fl.Dark3); Set(4, -s, -s, Fl.Dark3); Set(5, 0, -s, Fl.Dark3);
  Set(6, 0, 0, 0);
  b.Innards(X, Y, data)
END Relief;

PROCEDURE (b: RotatedBox) Draw*;
  VAR dx, dy, X, Y: INTEGER;
BEGIN
  b.DrawBox;
  FlDraw.SetFont(b.LabelFont(), b.LabelSize());
  FlDraw.SetColor(b.LabelColor());
  dx := 0; dy := 0;
  IF b.align * Fl.AlignClip # {} THEN FlDraw.PushClip(b.X(), b.Y(), b.W(), b.H())
  ELSE FlDraw.PushNoClip
  END;
  FlDraw.Measure(b.text, dx, dy);
  IF b.align * Fl.AlignLeft # {} THEN
    dx := 0; dy := 0
  ELSIF b.align * Fl.AlignRight # {} THEN
    dy := Trunc(-MathL.sin(Rad(b.angle + 180)) * dx);
    dx := Trunc(MathL.cos(Rad(b.angle + 180)) * dx)
  ELSE
    dy := Trunc(MathL.sin(Rad(b.angle)) * dx);
    dx := Trunc(-MathL.cos(Rad(b.angle)) * dx);
    dx := Half(dx); dy := Half(dy)
  END;
  X := b.X() + b.W() DIV 2 + dx; Y := b.Y() + b.H() DIV 2 + dy;
  IF b.LabelType() = Fl.ShadowLabel THEN b.ShadowLabel(X, Y)
  ELSIF b.LabelType() = Fl.EngravedLabel THEN b.Relief(X, Y, 1)
  ELSIF b.LabelType() = Fl.EmbossedLabel THEN b.Relief(X, Y, -1)
  ELSE FlDraw.TextRotated(b.angle, b.text, X, Y)
  END;
  FlDraw.PopClip;
  b.DrawLabel
END Draw;

PROCEDURE ButtonCB(w: Fl.Widget);
  VAR a: SET;
BEGIN
  a := {};
  IF leftb.Value() THEN a := a + Fl.AlignLeft END;
  IF rightb.Value() THEN a := a + Fl.AlignRight END;
  IF clipb.Value() THEN a := a + Fl.AlignClip END;
  text.align := a;
  window.Redraw
END ButtonCB;

PROCEDURE FontCB(w: Fl.Widget);
BEGIN text.SetLabelFont(SHORT(ENTIER(fonts.Value()))); window.Redraw
END FontCB;

PROCEDURE SizeCB(w: Fl.Widget);
BEGIN text.SetLabelSize(SHORT(ENTIER(sizes.Value()))); window.Redraw
END SizeCB;

PROCEDURE AngleCB(w: Fl.Widget);
BEGIN text.angle := Trunc(angles.Value()); window.Redraw
END AngleCB;

PROCEDURE InputCB(w: Fl.Widget);
BEGIN input.Value(text.text); window.Redraw
END InputCB;

PROCEDURE NormalCB(w: Fl.Widget);
BEGIN text.SetLabelType(Fl.NormalLabel); window.Redraw
END NormalCB;

PROCEDURE ShadowCB(w: Fl.Widget);
BEGIN text.SetLabelType(Fl.ShadowLabel); window.Redraw
END ShadowCB;

PROCEDURE EmbossedCB(w: Fl.Widget);
BEGIN text.SetLabelType(Fl.EmbossedLabel); window.Redraw
END EmbossedCB;

PROCEDURE EngravedCB(w: Fl.Widget);
BEGIN text.SetLabelType(Fl.EngravedLabel); window.Redraw
END EngravedCB;

PROCEDURE Slider(VAR s: FlValuators.ValueSlider; y: INTEGER; label: ARRAY OF CHAR;
  min, max, v: LONGREAL; cb: PROCEDURE (w: Fl.Widget));
BEGIN
  NEW(s); FlValuators.OpenHorValueSlider(s, 50, y, 350, 25, label);
  s.SetAlign(Fl.AlignLeft);
  s.SetBounds(min, max);
  s.SetStep(1);
  s.SetValue(v);
  s.action := cb
END Slider;

PROCEDURE Toggle(VAR t: FlButtons.ToggleButton; x: INTEGER; label: ARRAY OF CHAR);
BEGIN
  NEW(t); FlButtons.OpenToggleButton(t, x, 300, 50, 25, label);
  t.action := ButtonCB
END Toggle;

BEGIN
  NEW(window); Fl.OpenDoubleWindow(window, 400, 425, "");

  Slider(angles, 400, "Angle:", -360, 360, 0, AngleCB);

  NEW(input); FlInputs.OpenInput(input, 50, 375, 350, 25, "");
  input.SetValue("Rotate Me!!!");
  input.SetWhen(Fl.WhenChanged);
  input.action := InputCB;

  Slider(sizes, 350, "Size:", 1, 64, 14, SizeCB);
  Slider(fonts, 325, "Font:", 0, 15, 0, FontCB);

  NEW(g); Fl.OpenGroup(g, 50, 300, 350, 25, "");
  Toggle(leftb, 50, "left");
  Toggle(rightb, 100, "right");
  Toggle(clipb, 350, "clip");
  g.SetResizable(rightb);
  g.End;

  NEW(c); FlMenus.OpenChoice(c, 50, 275, 200, 25, "");
  n := c.Add("FL_NORMAL_LABEL", 0, {}, NormalCB, {});
  n := c.Add("FL_SHADOW_LABEL", 0, {}, ShadowCB, {});
  n := c.Add("FL_ENGRAVED_LABEL", 0, {}, EngravedCB, {});
  n := c.Add("FL_EMBOSSED_LABEL", 0, {}, EmbossedCB, {});
  IF c.SetValue(0) THEN END;  (* FLTK's menu() sets the first item *)

  NEW(text); Fl.OpenBox(text, 100, 75, 200, 100, "Widget with rotated text");
  input.Value(text.text);
  text.SetBoxType(Fl.EngravedBox);  (* FLTK's FL_FRAME_BOX *)
  text.SetAlign(Fl.AlignBottom);
  window.SetResizable(text);
  window.End;
  window.ShowArgs;
  Fl.Run
END RotatedText.
