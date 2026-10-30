MODULE ColorChooser; (* FLTK's test/color_chooser.cxx: the two ways to ask for a color, and drawing with colors *)

(* FLTK's test can also take a visual to use on X11, as an argument. *)

IMPORT Err, Args, Fl, FlButtons, FlDialogs, FlDraw, FlImages;

CONST
  width = 100; height = 100;
  fullcolorCell = Fl.FreeColor;

TYPE
  Pens = POINTER TO RECORD (Fl.BoxDesc) END;   (* uses every color in the gray ramp *)

VAR
  win: Fl.Window;
  box, hint, imageBox, b: Fl.Box;
  b1, b2: FlButtons.Button;
  p: Pens;
  image: FlImages.Image;
  bits: ARRAY 3 * width * height OF CHAR;
  c, i: INTEGER;

PROCEDURE MakeImage;
  VAR x, y, n: INTEGER; X, Y: LONGREAL;
BEGIN
  n := 0;
  FOR y := 0 TO height - 1 DO
    Y := y / (height - 1.0D0);
    FOR x := 0 TO width - 1 DO
      X := x / (width - 1.0D0);
      bits[n] := CHR(SHORT(ENTIER(255 * ((1 - X) * (1 - Y)))));       (* red in upper-left *)
      bits[n + 1] := CHR(SHORT(ENTIER(255 * ((1 - X) * Y))));         (* green in lower-left *)
      bits[n + 2] := CHR(SHORT(ENTIER(255 * (X * Y))));               (* blue in lower-right *)
      INC(n, 3)
    END
  END
END MakeImage;

PROCEDURE (p: Pens) Draw*;
  VAR i: INTEGER;
BEGIN
  FOR i := 0 TO 3 * 8 - 1 DO
    FlDraw.SetColor(Fl.GrayRamp(i));
    FlDraw.Line(p.X() + i, p.Y(), p.X() + i, p.Y() + p.H())
  END
END Draw;

PROCEDURE Colormap(w: Fl.Widget);
  VAR parent: Fl.Group;
BEGIN
  c := FlDialogs.ChooseFromColormap(c);
  box.SetColor(c);
  hint.SetLabelColor(Fl.Contrast(Fl.Black, c));
  parent := box.Parent(); parent.Redraw
END Colormap;

PROCEDURE Chooser(w: Fl.Widget);
  VAR r, g, bl: INTEGER; parent: Fl.Group;
BEGIN
  Fl.GetRGB(c, r, g, bl);
  IF FlDialogs.ChooseColor("New color:", r, g, bl, FlDialogs.ColorHSV) THEN
    c := fullcolorCell;
    Fl.SetIndexColor(fullcolorCell, Fl.RGB(r, g, bl));
    box.SetColor(fullcolorCell);
    hint.SetLabelColor(Fl.Contrast(Fl.Black, fullcolorCell));
    parent := box.Parent(); parent.Redraw
  END
END Chooser;

BEGIN
  Fl.SetIndexColor(fullcolorCell, Fl.RGB(145, 159, 170));
  NEW(win); Fl.OpenWindow(win, 400, 400, "color_chooser");
  NEW(box); Fl.OpenBox(box, 30, 30, 340, 340, "");
  box.SetBoxType(Fl.ThinDownBox);
  c := fullcolorCell;
  box.SetColor(c);
  NEW(hint); Fl.OpenBox(hint, 40, 40, 320, 30, "Pick background color with buttons:");
  hint.SetAlign(Fl.AlignInside);
  NEW(b1); FlButtons.OpenButton(b1, 120, 80, 180, 30, "fl_show_colormap()");
  b1.action := Colormap;
  NEW(b2); FlButtons.OpenButton(b2, 120, 120, 180, 30, "fl_color_chooser()");
  b2.action := Chooser;
  NEW(imageBox); Fl.OpenBox(imageBox, 160, 190, width, height, "");
  MakeImage;
  NEW(image); FlImages.OpenRGB(image, bits, width, height, 3, 0);
  FlImages.SetImage(imageBox, image);
  NEW(b); Fl.OpenBox(b, 160, 310, 120, 30, "Example of fl_draw_image()");
  NEW(p); Fl.OpenBox(p, 60, 180, 3 * 8, 120, "lines");
  p.SetAlign(Fl.AlignTop);
  win.End;
  IF ~Fl.ParseArgs(NIL, i) OR (i < Args.argc) THEN
    Err.String("usage: ColorChooser <switches>"); Err.Ln; HALT(1)
  END;
  win.ShowArgs;
  Fl.Run
END ColorChooser.
