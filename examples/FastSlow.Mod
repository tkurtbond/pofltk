MODULE FastSlow; (* FLTK's test/fast_slow.cxx in Oberon-2 *)

(* Three sliders: moving the left one moves the middle one at every step
   of a drag, and the right one only when the mouse is released. The
   two right sliders are output only, so take no events. *)

IMPORT Fl, FlValuators;

VAR
  window: Fl.DoubleWindow;
  control: FlValuators.Slider;
  fast, slow: FlValuators.Slider;
  box: Fl.Box;
  s: ARRAY 512 OF CHAR;
  lf: ARRAY 2 OF CHAR;

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

PROCEDURE ControlCallback(o: Fl.Widget);
BEGIN
  fast.SetValue(control.Value());
  IF Fl.Pushed() = NIL THEN slow.SetValue(control.Value()) END
END ControlCallback;

BEGIN
  lf[0] := 0AX; lf[1] := 0X;
  NEW(window); Fl.OpenDoubleWindow(window, 318, 443, "");
  s := "move|this"; Lines(s);
  NEW(control); FlValuators.OpenSlider(control, 90, 200, 30, 200, s);
  control.action := ControlCallback;
  control.SetWhen(Fl.WhenChanged + Fl.WhenRelease + Fl.WhenNotChanged);
  s := "fast|redraw"; Lines(s);
  NEW(fast); FlValuators.OpenSlider(fast, 140, 200, 30, 200, s);
  fast.SetOutput(TRUE);
  s := "slow|redraw"; Lines(s);
  NEW(slow); FlValuators.OpenSlider(slow, 190, 200, 30, 200, s);
  slow.SetOutput(TRUE);
  (* the text has its own "|"s, so its line feeds are put in by hand *)
  s := "The left slider has changed( FL_WHEN_CHANGED | FL_WHEN_RELEASE | FL_WHEN_NOT_CHANGED) so it produces a callback on both drag and release mouse events.";
  Cat(lf, s); Cat("The middle slider (representing a widget with low overhead) is changed on every mouse movement.", s);
  Cat(lf, s); Cat("The right slider (representing a widget with high overhead) is only updated when the mouse is released, by checking if Fl::pushed() is zero.", s);
  NEW(box); Fl.OpenBox(box, 10, 10, 300, 180, s);
  box.SetBoxType(Fl.DownBox);
  box.SetColor(53);
  box.SetSelectionColor(Fl.Dark1);
  box.SetLabelFont(4);
  box.SetLabelSize(12);
  box.SetAlign({2, 7} + Fl.AlignInside); (* 132, FL_ALIGN_LEFT | FL_ALIGN_WRAP *)
  window.SetResizable(window);
  window.End;
  window.ShowArgs;
  Fl.Run
END FastSlow.
