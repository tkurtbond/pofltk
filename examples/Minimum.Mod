MODULE Minimum; (* FLTK's test/minimum.cxx in Oberon-2 *)

(* A test of FLTK's minimal updates: the slider's label is too big for
   it, and moving the slider leaves copies of it, which only hiding and
   showing that part of the window, or the button under them changing,
   should erase. *)

IMPORT Args, Fl, FlButtons, FlValuators;

VAR
  window: Fl.DoubleWindow;
  box: Fl.Box;
  s: FlValuators.Slider;
  b: FlButtons.Button;
  r: FlButtons.ReturnButton;
  text: ARRAY 512 OF CHAR;

(* s with each "|" a line feed *)
PROCEDURE Lines(VAR s: ARRAY OF CHAR);
VAR i: INTEGER;
BEGIN
  i := 0; WHILE s[i] # 0X DO IF s[i] = "|" THEN s[i] := 0AX END; INC(i) END
END Lines;

BEGIN
  Args.Get(0, text);
  NEW(window); Fl.OpenDoubleWindow(window, 400, 320, text);
  text := "MINIMUM UPDATE TEST||The slider on the right purposely|draws outside its boundaries.|Moving it should leave old copies|of the label.  These copies should|*not* be erased by any actions|other than hiding and showing|of that portion of the window|or changing the button that|intersects them.";
  Lines(text);
  NEW(box); Fl.OpenBox(box, 10, 10, 300, 300, text); box.SetBoxType(Fl.EngravedFrame);
  window.SetResizable(box);

  NEW(s); FlValuators.OpenSlider(s, 320, 10, 20, 300, "Too_Big_Label");
  s.SetAlign({});

  NEW(b); FlButtons.OpenButton(b, 20, 270, 100, 30, "Button");
  NEW(r); FlButtons.OpenReturnButton(r, 200, 270, 100, 30, "Button");

  window.End;
  window.ShowArgs;
  Fl.Run
END Minimum.
