MODULE Image; (* FLTK's test/image.cxx in Oberon-2 *)

(* An RGB image with alpha on a button, placed by its label's alignment,
   and an inactive copy of it, shown when the button is inactive. FLTK's
   -v option, an X visual by number, isn't here: pofltk has no X visuals. *)

IMPORT Fl, FlButtons, FlImages, MathL;

CONST
  width = 100; height = 100;

VAR
  w: Fl.DoubleWindow;
  b: FlButtons.Button;
  leftb, rightb, topb, bottomb, insideb, overb, inactb: FlButtons.ToggleButton;
  rgb, dergb: FlImages.Image;
  image: ARRAY 4 * width * height OF CHAR;
  done: BOOLEAN;

(* Red in the upper left, green in the lower left, blue in the lower
   right, more transparent towards the middle. *)
PROCEDURE MakeImage;
  VAR x, y, p, alpha: INTEGER; X, Y: LONGREAL;
BEGIN
  p := 0;
  FOR y := 0 TO height - 1 DO
    Y := y; Y := Y / (height - 1);  (* in LONGREAL, as C divides *)
    FOR x := 0 TO width - 1 DO
      X := x; X := X / (width - 1);
      image[p] := CHR(ENTIER(255 * ((1 - X) * (1 - Y))));
      image[p + 1] := CHR(ENTIER(255 * ((1 - X) * Y)));
      image[p + 2] := CHR(ENTIER(255 * (X * Y)));
      X := X - 0.5D0; Y := Y - 0.5D0;
      alpha := SHORT(ENTIER(255 * MathL.sqrt(X * X + Y * Y)));
      IF alpha < 255 THEN image[p + 3] := CHR(alpha) ELSE image[p + 3] := 0FFX END;
      Y := Y + 0.5D0;
      INC(p, 4)
    END
  END
END MakeImage;

PROCEDURE ButtonCB(o: Fl.Widget);
  VAR a: SET;
BEGIN
  a := {};
  IF leftb.Value() THEN a := a + Fl.AlignLeft END;
  IF rightb.Value() THEN a := a + Fl.AlignRight END;
  IF topb.Value() THEN a := a + Fl.AlignTop END;
  IF bottomb.Value() THEN a := a + Fl.AlignBottom END;
  IF insideb.Value() THEN a := a + Fl.AlignInside END;
  IF overb.Value() THEN a := a + Fl.AlignTextOverImage END;
  b.SetAlign(a);
  IF inactb.Value() THEN b.Deactivate ELSE b.Activate END;
  w.Redraw
END ButtonCB;

PROCEDURE Toggle(VAR t: FlButtons.ToggleButton; x, y, width: INTEGER; label: ARRAY OF CHAR);
BEGIN
  NEW(t); FlButtons.OpenToggleButton(t, x, y, width, 25, label); t.action := ButtonCB
END Toggle;

BEGIN
  done := Fl.Visual(Fl.VisualRgb);
  NEW(w); Fl.OpenDoubleWindow(w, 400, 400, "");
  w.SetColor(Fl.White);
  NEW(b); FlButtons.OpenButton(b, 140, 160, 120, 120, "Image w/Alpha");
  MakeImage;
  NEW(rgb); FlImages.OpenRGB(rgb, image, width, height, 4, 0);
  NEW(dergb); rgb.Copy(dergb, width, height);
  dergb.Inactive;
  FlImages.SetImage(b, rgb);
  FlImages.SetInactiveImage(b, dergb);
  Toggle(leftb, 25, 50, 50, "left");
  Toggle(rightb, 75, 50, 50, "right");
  Toggle(topb, 125, 50, 50, "top");
  Toggle(bottomb, 175, 50, 50, "bottom");
  Toggle(insideb, 225, 50, 50, "inside");
  Toggle(overb, 25, 75, 100, "text over");
  Toggle(inactb, 125, 75, 100, "inactive");
  w.SetResizable(w);
  w.End;
  w.ShowArgs;
  Fl.Run
END Image.
