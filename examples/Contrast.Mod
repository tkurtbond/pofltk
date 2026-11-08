MODULE Contrast; (* FLTK's test/contrast.cxx in Oberon-2 *)

(* fl_contrast's algorithms, on the 256 colors of FLTK's colormap: each
   field is drawn in its color, with its number in the label color the
   sliders choose, as Fl.ContrastSized makes it show, and a strip of that
   color unchanged. Radio buttons choose the algorithm, sliders its level
   and the label size, a color chooser the last field's color, and a
   click on a field writes its lightness and contrast to the terminal. *)

IMPORT Fl, FlDraw, FlButtons, FlValuators, FlInputs, FlDialogs, FlTerminal;

CONST
  version = "0.9.1";

TYPE
  Button = POINTER TO RECORD (FlButtons.ButtonDesc)
    lbuf: ARRAY 20 OF CHAR; (* the label *)
    ocol: INTEGER;          (* the label color before Contrast *)
    idx: INTEGER            (* the button's number, 0 to 255 *)
  END;

VAR
  term: FlTerminal.Terminal;
  gLfg, gLbg, gLcref: LONGREAL; (* lightness of fg and bg, and their difference *)
  gSelected: INTEGER;           (* the field last clicked, -1 for none *)
  gFs: INTEGER;                 (* the label size *)
  gLevel: INTEGER;              (* the contrast level *)
  gAlgo: INTEGER;               (* the contrast mode *)
  alch: ARRAY 8 OF CHAR;        (* the mode's name *)
  lcolor: INTEGER;              (* the label color the sliders set *)
  buttons: ARRAY 256 OF Button;
  sliders: ARRAY 6 OF FlValuators.ValueSlider; (* gray, red, green, blue, level, size *)
  colorOut: FlInputs.Output;
  window: Fl.DoubleWindow;
  acie: FlButtons.RadioRoundButton;
  first: BOOLEAN;               (* the RC button not yet pressed *)
  seed: INTEGER;                (* the random colors' *)

(* Appends t to s. *)
PROCEDURE Cat(t-: ARRAY OF CHAR; VAR s: ARRAY OF CHAR);
  VAR i, j: INTEGER;
BEGIN
  i := 0; WHILE s[i] # 0X DO INC(i) END;
  j := 0; WHILE t[j] # 0X DO s[i] := t[j]; INC(i); INC(j) END;
  s[i] := 0X
END Cat;

(* Appends n to s, right aligned in width, as printf's "%<width>d", or
   with zeros as "%0<width>d". *)
PROCEDURE Int(n, width: INTEGER; pad: CHAR; VAR s: ARRAY OF CHAR);
  VAR d: ARRAY 16 OF CHAR; k, i: INTEGER; neg: BOOLEAN;
BEGIN
  neg := n < 0; IF neg THEN n := -n END;
  k := 0; REPEAT d[k] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(k) UNTIL n = 0;
  IF neg THEN d[k] := "-"; INC(k) END;
  i := 0; WHILE s[i] # 0X DO INC(i) END;
  WHILE width > k DO s[i] := pad; INC(i); DEC(width) END;
  WHILE k > 0 DO DEC(k); s[i] := d[k]; INC(i) END;
  s[i] := 0X
END Int;

(* Appends n, 0 or more, to s in width hexadecimal digits, as printf's
   "%0<width>x", or "%0<width>X" when upper. *)
PROCEDURE Hex(n, width: INTEGER; upper: BOOLEAN; VAR s: ARRAY OF CHAR);
  VAR d: ARRAY 2 OF CHAR; k, v: INTEGER;
BEGIN
  d[1] := 0X;
  FOR k := width - 1 TO 0 BY -1 DO
    v := n; IF k > 0 THEN v := SHORT(ASH(n, -4 * k)) END;
    v := v MOD 16;
    IF v < 10 THEN d[0] := CHR(ORD("0") + v)
    ELSIF upper THEN d[0] := CHR(ORD("A") + v - 10)
    ELSE d[0] := CHR(ORD("a") + v - 10)
    END;
    Cat(d, s)
  END
END Hex;

(* Appends x to s as printf's "%<width>.2f". *)
PROCEDURE Fixed(x: LONGREAL; width: INTEGER; VAR s: ARRAY OF CHAR);
  VAR t: ARRAY 32 OF CHAR; n: INTEGER; neg: BOOLEAN;
BEGIN
  neg := x < 0.0D0; IF neg THEN x := -x END;
  n := SHORT(ENTIER(x * 100.0D0 + 0.5D0));
  IF neg & (n # 0) THEN t := "-" ELSE t := "" END;
  Int(n DIV 100, 1, " ", t); Cat(".", t); Int(n MOD 100, 2, "0", t);
  n := 0; WHILE t[n] # 0X DO INC(n) END;
  WHILE width > n DO Cat(" ", s); DEC(width) END;
  Cat(t, s)
END Fixed;

(* The custom contrast algorithm: a dummy, which returns fg. A program
   could define a better one here. *)
PROCEDURE CustomContrast(fg, bg, context, size: INTEGER): INTEGER;
BEGIN RETURN fg
END CustomContrast;

(* Contrast, which also sets the lightnesses and their difference shown
   in the terminal. *)
PROCEDURE CalcContrast(fg, bg, fs: INTEGER): INTEGER;
BEGIN
  gLfg := Fl.Lightness(fg);
  gLbg := Fl.Lightness(bg);
  gLcref := gLfg - gLbg; (* perceived contrast: light on dark is positive *)
  IF (gAlgo >= Fl.ContrastNone) & (gAlgo <= Fl.ContrastCustom) THEN
    RETURN Fl.ContrastSized(fg, bg, 0, fs)
  END;
  RETURN fg
END CalcContrast;

PROCEDURE (b: Button) SetLabelcolor(col: INTEGER);
BEGIN
  b.ocol := col;
  b.SetLabelColor(CalcContrast(col, b.Color(), b.LabelSize()))
END SetLabelcolor;

PROCEDURE (b: Button) Draw*;
  VAR lw, lh: INTEGER;
BEGIN
  b.DrawBox;
  (* a small filled rectangle in the color before Contrast *)
  FlDraw.SetColor(b.ocol);
  FlDraw.RectF(b.X() + 5, b.Y() + 5, 10, b.H() - 10);
  (* the label, measured and drawn *)
  lw := 0; lh := 0;
  FlDraw.SetFont(b.LabelFont(), b.LabelSize());
  FlDraw.Measure(b.lbuf, lw, lh);
  FlDraw.SetColor(b.LabelColor());
  FlDraw.Text(b.lbuf, b.X() + 15 + (b.W() - lw - 15) DIV 2,
    b.Y() + b.H() - (b.H() - lh) DIV 2 - lh DIV 4);
  FlDraw.SetColor(Fl.Black)
END Draw;

(* The RGB color c, as Fl::get_color gives it. *)
PROCEDURE GetColor(c: INTEGER): INTEGER;
  VAR r, g, b: INTEGER;
BEGIN Fl.GetRGB(c, r, g, b); RETURN Fl.RGB(r, g, b)
END GetColor;

(* Sets every field's label color and size. *)
PROCEDURE UpdateLabels;
  VAR i: INTEGER;
BEGIN
  FOR i := 0 TO 255 DO
    buttons[i].SetLabelcolor(lcolor);
    buttons[i].SetLabelSize(gFs)
  END
END UpdateLabels;

PROCEDURE ButtonCallback(w: Fl.Widget);
  VAR b: Button; ocol, fg, bg, dummy, i: INTEGER; color: ARRAY 8 OF CHAR;
    s: ARRAY 256 OF CHAR;
BEGIN
  b := w(Button);
  gSelected := b.idx;
  ocol := GetColor(b.ocol);      (* the label color before Contrast *)
  fg := GetColor(b.LabelColor()); (* the label color *)
  bg := GetColor(b.Color());      (* the background *)
  dummy := CalcContrast(ocol, bg, gFs); (* sets the values shown *)
  IF fg = ocol THEN color := "fg"
  ELSIF fg = Fl.RGB(255, 255, 255) THEN color := "WHITE"
  ELSIF fg = 0 THEN color := "BLACK"
  ELSE color := ""
  END;
  s := "["; Cat(b.lbuf, s); Cat("] fg: ", s);
  Hex(SHORT(ASH(ocol, -8) MOD 1000000H), 6, FALSE, s); Cat(", bg: ", s);
  Hex(SHORT(ASH(bg, -8) MOD 1000000H), 6, FALSE, s); Cat(", lfg: ", s);
  Fixed(gLfg, 6, s); Cat(", lbg: ", s); Fixed(gLbg, 6, s);
  Cat(", lc: ", s); Fixed(gLcref, 7, s); Cat(", ", s); Cat(alch, s);
  Cat(" => ", s); Cat(color, s);
  i := 0; WHILE color[i] # 0X DO INC(i) END;
  WHILE i < 5 DO Cat(" ", s); INC(i) END; (* "%-5s" *)
  IF (gAlgo = Fl.ContrastLegacy) OR (gAlgo = Fl.ContrastCielab) THEN
    Cat(" (level = ", s); Int(gLevel, 3, " ", s); Cat(")", s)
  END;
  Cat(0AX, s);
  term.Append(s)
END ButtonCallback;

PROCEDURE LfCallback(w: Fl.Widget);
VAR s: ARRAY 2 OF CHAR;
BEGIN s[0] := 0AX; s[1] := 0X; term.Append(s)
END LfCallback;

(* Shows r, g, b in the output. *)
PROCEDURE ShowColor(r, g, b: INTEGER);
  VAR s: ARRAY 10 OF CHAR;
BEGIN
  s := ""; Hex(r, 2, TRUE, s); Cat(" ", s); Hex(g, 2, TRUE, s); Cat(" ", s);
  Hex(b, 2, TRUE, s);
  colorOut.SetValue(s)
END ShowColor;

(* The gray slider's: sets the red, green and blue sliders too. *)
PROCEDURE GraySliderCallback(w: Fl.Widget);
  VAR val: INTEGER;
BEGIN
  val := SHORT(ENTIER(sliders[0].Value()));
  lcolor := Fl.RGB(val, val, val);
  sliders[1].SetValue(val); sliders[2].SetValue(val); sliders[3].SetValue(val);
  UpdateLabels;
  ShowColor(val, val, val);
  window.Redraw
END GraySliderCallback;

(* The red, green and blue sliders'. *)
PROCEDURE ColorSliderCallback(w: Fl.Widget);
  VAR r, g, b: INTEGER;
BEGIN
  r := SHORT(ENTIER(sliders[1].Value()));
  g := SHORT(ENTIER(sliders[2].Value()));
  b := SHORT(ENTIER(sliders[3].Value()));
  lcolor := Fl.RGB(r, g, b);
  UpdateLabels;
  ShowColor(r, g, b);
  window.Redraw
END ColorSliderCallback;

(* The level and label size sliders'. *)
PROCEDURE SliderCallback(w: Fl.Widget);
BEGIN
  IF w = sliders[4] THEN
    gLevel := SHORT(ENTIER(sliders[4].Value()));
    Fl.SetContrastLevel(gLevel)
  ELSE
    gFs := SHORT(ENTIER(sliders[5].Value()))
  END;
  UpdateLabels;
  window.Redraw
END SliderCallback;

(* A pseudo-random number, 0 to 255. *)
PROCEDURE Random(): INTEGER;
BEGIN
  seed := (seed * 25173 + 13849) MOD 65536;
  RETURN seed DIV 256
END Random;

(* The RC button's: a random label color, black the first time. *)
PROCEDURE RcCallback(w: Fl.Widget);
  VAR r, g, b: INTEGER;
BEGIN
  IF first THEN
    first := FALSE;
    r := 0; g := 0; b := 0
  ELSE
    r := Random(); g := Random(); b := Random()
  END;
  sliders[1].SetValue(r); sliders[2].SetValue(g); sliders[3].SetValue(b);
  lcolor := Fl.RGB(r, g, b);
  UpdateLabels;
  ShowColor(r, g, b);
  window.Redraw
END RcCallback;

(* Sets algorithm val, the radio button's. *)
PROCEDURE SetAlgo(val: INTEGER);
BEGIN
  gAlgo := val;
  IF val = Fl.ContrastLegacy THEN alch := "LEGACY"; Fl.SetContrastMode(val)
  ELSIF val = Fl.ContrastCielab THEN alch := "CIELAB"; Fl.SetContrastMode(val)
  ELSIF val = Fl.ContrastCustom THEN alch := "CUSTOM"; Fl.SetContrastMode(val)
  ELSE alch := "none  "; Fl.SetContrastMode(Fl.ContrastNone)
  END;
  gLevel := Fl.ContrastLevel();
  sliders[4].SetValue(gLevel);
  UpdateLabels;
  IF gSelected >= 0 THEN ButtonCallback(buttons[gSelected]) END;
  window.Redraw
END SetAlgo;

PROCEDURE NoneCallback(w: Fl.Widget);
BEGIN SetAlgo(Fl.ContrastNone)
END NoneCallback;

PROCEDURE LegacyCallback(w: Fl.Widget);
BEGIN SetAlgo(Fl.ContrastLegacy)
END LegacyCallback;

PROCEDURE CielabCallback(w: Fl.Widget);
BEGIN SetAlgo(Fl.ContrastCielab)
END CielabCallback;

PROCEDURE CustomCallback(w: Fl.Widget);
BEGIN SetAlgo(Fl.ContrastCustom)
END CustomCallback;

(* The color chooser's: the last field's color. *)
PROCEDURE ColorCallback(w: Fl.Widget);
  VAR cc: FlDialogs.ColorChooser; bt: Button;
BEGIN
  cc := w(FlDialogs.ColorChooser);
  bt := buttons[255];
  bt.SetColor(Fl.RGB(SHORT(ENTIER(cc.R() * 255)), SHORT(ENTIER(cc.G() * 255)),
    SHORT(ENTIER(cc.B() * 255))));
  bt.SetLabelcolor(lcolor);
  bt.Redraw
END ColorCallback;

(* A slider of the label color, or the level or label size. *)
PROCEDURE NewSlider(VAR s: FlValuators.ValueSlider; x, y, w, h: INTEGER;
  label: ARRAY OF CHAR; color, textcolor: INTEGER; max: INTEGER;
  action: PROCEDURE (w: Fl.Widget));
BEGIN
  NEW(s); FlValuators.OpenHorValueSlider(s, x, y, w, h, label);
  s.SetColor(color);
  IF textcolor >= 0 THEN s.SetTextColor(textcolor) END;
  s.SetTextSize(13);
  s.SetAlign(Fl.AlignLeft);
  s.SetValue(0);
  s.SetBounds(0, max);
  s.SetStep(1);
  s.action := action
END NewSlider;

PROCEDURE Build;
  CONST bw = 58; bh = 30;
  VAR cw, ch, ww, wh, n, x, y, sx, sw, sh, sy, cgx, cgy, cgw, cgh, abh,
      ccx, ccy, ccw, cch, tty: INTEGER;
    b: Button; cg: Fl.Group; anon, aleg, aapc: FlButtons.RadioRoundButton;
    lf, rc: FlButtons.Button; chooser: FlDialogs.ColorChooser;
    s: ARRAY 256 OF CHAR;
BEGIN
  cw := 16 * bw + 10; ch := 16 * bh + 10;
  ww := cw + 10;
  wh := 16 * bh + 135 + 10 + 170 (* the terminal *) + 10;
  NEW(window); Fl.OpenDoubleWindow(window, ww, wh, "fl_contrast test");

  n := 0;
  FOR y := 0 TO 15 DO
    FOR x := 0 TO 15 DO
      NEW(b); FlButtons.OpenButton(b, x * bw + 10, y * bh + 10, bw, bh, "");
      b.idx := n;
      b.SetBoxType(Fl.ThinDownBox);
      b.action := ButtonCallback;
      b.SetColor(n);
      b.lbuf := ""; Int(n, 3, "0", b.lbuf);
      b.SetLabel(b.lbuf);
      b.SetLabelcolor(n);
      b.SetLabelSize(15);
      b.SetLabelFont(Fl.Helvetica);
      b.SetLabelcolor(n);
      buttons[n] := b;
      INC(n)
    END
  END;

  (* sliders of the label color: gray, red, green, blue *)
  sx := 10 + bw; sw := 5 * bw; sh := 25; sy := ch + 10;
  NewSlider(sliders[0], sx, sy, sw, sh, "gray", Fl.RGB(0DDH, 0DDH, 0DDH), -1, 255,
    GraySliderCallback);
  INC(sy, sh + 10);
  NewSlider(sliders[1], sx, sy, sw, sh, "red", Fl.Red, Fl.White, 255, ColorSliderCallback);
  INC(sy, sh + 5);
  NewSlider(sliders[2], sx, sy, sw, sh, "green", Fl.Green, -1, 255, ColorSliderCallback);
  INC(sy, sh + 5);
  NewSlider(sliders[3], sx, sy, sw, sh, "blue", Fl.Blue, Fl.White, 255, ColorSliderCallback);

  (* the contrast algorithm *)
  cgx := 10 + 6 * bw + 10; cgy := ch + 30; cgw := 90; cgh := 100; abh := 25;
  NEW(cg); Fl.OpenGroup(cg, cgx, cgy, cgw, cgh, "fl_contrast:");
  cg.SetAlign(Fl.AlignTop);
  cg.SetBoxType(Fl.EngravedFrame);
  NEW(anon); FlButtons.OpenRadioRoundButton(anon, cgx, cgy, cgw, abh, "none");
  NEW(aleg); FlButtons.OpenRadioRoundButton(aleg, cgx, cgy + 25, cgw, abh, "LEGACY");
  NEW(acie); FlButtons.OpenRadioRoundButton(acie, cgx, cgy + 50, cgw, abh, "CIELAB");
  NEW(aapc); FlButtons.OpenRadioRoundButton(aapc, cgx, cgy + 75, cgw, abh, "CUSTOM");
  acie.SetValue(TRUE);
  anon.action := NoneCallback;
  aleg.action := LegacyCallback;
  acie.action := CielabCallback;
  aapc.action := CustomCallback;
  cg.End;

  NEW(colorOut); FlInputs.OpenOutput(colorOut, 10 + 10 * bw, ch + 10, 100, 30, "label color:");
  colorOut.SetAlign(Fl.AlignLeft);
  colorOut.SetTextFont(Fl.Courier);
  colorOut.SetTextSize(16);
  colorOut.SetValue("00 00 00");

  (* the light blue level slider *)
  NewSlider(sliders[4], 10 + 9 * bw, sliders[1].Y(), 3 * bw - 15, sh, "level", 231, 224,
    100, SliderCallback);
  sliders[4].SetValue(gLevel);
  sliders[4].SetTooltip("set contrast sensitivity level (0-100), default: 50");

  (* the label size slider *)
  NewSlider(sliders[5], 10 + 9 * bw, sliders[2].Y(), 3 * bw - 15, sh, "labelsize", 231, 224,
    24, SliderCallback);
  sliders[5].SetBounds(8, 24);
  sliders[5].SetValue(15);
  sliders[5].SetTooltip("set label/text fontsize");

  (* the line feed button *)
  NEW(lf); FlButtons.OpenButton(lf, 10 + 8 * bw, sliders[3].Y(), bw, sh, "LF");
  lf.SetTooltip("Click to output a linefeed to the log.");
  lf.action := LfCallback;

  (* the random color button *)
  NEW(rc); FlButtons.OpenButton(rc, 10 + 8 * bw + lf.W() + 2, sliders[3].Y(), bw * 3 DIV 4, sh, "&RC");
  rc.SetTooltip("Click to select a random text color.");
  rc.action := RcCallback;

  (* the color chooser of field 255 *)
  ccx := 10 + 12 * bw; ccy := ch + 10; ccw := 4 * bw; cch := 120;
  NEW(chooser); FlDialogs.OpenColorChooser(chooser, ccx, ccy, ccw, cch, "");
  chooser.action := ColorCallback;
  chooser.SetLabel("bg color [255] @->");
  IF chooser.SetRGB(1, 1, 1) THEN END;
  chooser.SetMode(1); (* bytes *)
  chooser.SetAlign(Fl.AlignLeftBottom);

  (* the contrast mode and level, and the label colors *)
  Fl.SetContrastMode(gAlgo);
  Fl.SetContrastFunction(CustomContrast); (* the dummy *)
  SetAlgo(Fl.ContrastCielab);

  (* the terminal *)
  tty := chooser.Y() + cch + 10;
  NEW(term); FlTerminal.OpenTerminal(term, 10, tty, window.W() - 20, window.H() - tty - 10, "");
  term.SetColor(Fl.White);
  term.SetTextFgColor(Fl.Black);
  term.SetTextSize(13);

  s := "FLTK "; Int(Fl.BuiltApiVersion() DIV 10000, 1, " ", s); Cat(".", s);
  Int(Fl.BuiltApiVersion() DIV 100 MOD 100, 1, " ", s); Cat(".", s);
  Int(Fl.BuiltApiVersion() MOD 100, 1, " ", s);
  Cat(" fl_contrast() test program with different contrast algorithms, version ", s);
  Cat(version, s); Cat(0AX, s); term.Append(s);
  term.Append(" - Select a foreground (text) color with the gray or red/green/blue sliders (displayed inside each field).");
  LfCallback(NIL);
  term.Append(" - Select an arbitrary background color for field #255 with the color chooser.");
  LfCallback(NIL);
  term.Append(" - Select a colored field (by clicking on it) to display its attributes.");
  LfCallback(NIL);
  term.Append(" - Select the contrast algorithm by clicking on the radio buttons.");
  LfCallback(NIL);
  s := ' - Tune the contrast algorithm with the light blue "level" slider (default: ';
  Int(Fl.ContrastLevel(), 1, " ", s); Cat(").", s); Cat(0AX, s); term.Append(s);
  term.Append(" - Select a random foreground (text) color by clicking the RC button");
  LfCallback(NIL);

  window.SetResizable(term);
  window.End;
  window.ShowArgs;
  RcCallback(rc) (* the labels' colors, after the window is shown *)
END Build;

BEGIN
  gSelected := -1; gFs := 15; gLevel := 0; gAlgo := Fl.ContrastCielab;
  alch := ""; lcolor := Fl.Black; first := TRUE; seed := 1;
  Build;
  Fl.Run
END Contrast.
