MODULE UtImages; (* FLTK's test/unittest_images.cxx in Oberon-2 *)

(* Four 128 by 128 gradients, drawn as RGB images or by fl_draw_image,
   with the controls FLTK's test has for its developers: CB, IMG, FLIPH
   and LX. FLTK's DX, extra bytes at each row's end, has no control and is
   0, so this port leaves it out. *)

IMPORT Fl, FlDraw, FlButtons, FlImages, Ut;

CONST
  Label* = "Drawing Images";
  N = 128;  (* the images' width and height *)

TYPE
  Page = POINTER TO RECORD (Fl.GroupDesc) END;

VAR
  cb: BOOLEAN;  (* shows a checker board behind the images with alpha *)
  img: BOOLEAN;  (* draws images, not fl_draw_image *)
  lx: INTEGER;  (* the line size: 0 the default, 1 N * d, -1 flipped *)
  flipH: BOOLEAN;  (* flips fl_draw_image's horizontally *)
  (* the pixels, by depth: gray, gray and alpha, RGB and RGBA *)
  pixels: ARRAY 5, N * N * 4 OF CHAR;
  images: ARRAY 5 OF FlImages.Image;
  ckCB, ckIMG, ckFLIPH: FlButtons.CheckButton;
  rbLXp1, rbLX0, rbLXm1: FlButtons.RadioButton;

PROCEDURE BuildPixels;
  VAR x, y, i: INTEGER;
BEGIN
  FOR y := 0 TO N - 1 DO
    FOR x := 0 TO N - 1 DO
      i := y * N + x;
      pixels[1, i] := CHR(y * 2);
      pixels[2, i * 2] := CHR(y * 2); pixels[2, i * 2 + 1] := CHR(x + y);
      pixels[3, i * 3] := CHR(y * 2); pixels[3, i * 3 + 1] := CHR(x * 2);
      pixels[3, i * 3 + 2] := CHR((127 - x) * 2);
      pixels[4, i * 4] := CHR(y * 2); pixels[4, i * 4 + 1] := CHR(x * 2);
      pixels[4, i * 4 + 2] := CHR((127 - x) * 2);
      pixels[4, i * 4 + 3] := CHR(x + y)
    END
  END
END BuildPixels;

(* The images, for the line size lx. FLTK's image of a negative line size
   starts at the last row; FlImages.OpenRGB takes rows first to last, so
   it is given them reversed, which draws the same. *)
PROCEDURE BuildImages;
  VAR d, row, y, i: INTEGER; flipped: ARRAY N * N * 4 OF CHAR;
BEGIN
  FOR d := 1 TO 4 DO
    IF images[d] # NIL THEN images[d].Close END;
    NEW(images[d]);
    row := N * d;
    IF lx < 0 THEN
      FOR y := 0 TO N - 1 DO
        FOR i := 0 TO row - 1 DO flipped[y * row + i] := pixels[d, (N - 1 - y) * row + i] END
      END;
      FlImages.OpenRGB(images[d], flipped, N, N, d, row)
    ELSE
      FlImages.OpenRGB(images[d], pixels[d], N, N, d, lx * row)
    END
  END
END BuildImages;

(* Image d at x, y, as the controls say. *)
PROCEDURE DrawOne(d, x, y: INTEGER);
  VAR first, dd: INTEGER;
BEGIN
  IF img THEN images[d].Draw(x, y)
  ELSE
    first := 0; dd := d;
    IF lx < 0 THEN first := (N - 1) * N * d END;
    IF flipH THEN INC(first, (N - 1) * d); dd := -d END;
    FlDraw.DrawImage(pixels[d], first, x, y, N, N, dd, lx * N * d)
  END
END DrawOne;

(* A frame, with a white background and, if cb, a checker board *)
PROCEDURE Back(xx, yy: INTEGER);
BEGIN
  FlDraw.SetColor(Fl.Black); FlDraw.Rect(xx, yy, 130, 130);
  FlDraw.SetColor(Fl.White); FlDraw.RectF(xx + 1, yy + 1, 128, 128);
  IF cb THEN
    FlDraw.SetColor(Fl.Black); FlDraw.RectF(xx + 65, yy + 1, 64, 64);
    FlDraw.SetColor(Fl.Black); FlDraw.RectF(xx + 1, yy + 65, 64, 64)
  END
END Back;

PROCEDURE (p: Page) Draw*;
  VAR xx, yy: INTEGER;
BEGIN
  p.Draw^;
  (* top left: RGB *)
  xx := p.X() + 10; yy := p.Y() + 10;
  FlDraw.SetColor(Fl.Black); FlDraw.Rect(xx, yy, 130, 130);
  DrawOne(3, xx + 1, yy + 1);
  FlDraw.Text("RGB", xx + 134, yy + 64);
  (* bottom left: RGBA *)
  xx := p.X() + 10; yy := p.Y() + 10 + 134;
  Back(xx, yy);
  DrawOne(4, xx + 1, yy + 1);
  FlDraw.SetColor(Fl.Black); FlDraw.Text("RGBA", xx + 134, yy + 64);
  (* top right: Gray *)
  xx := p.X() + 10 + 200; yy := p.Y() + 10;
  FlDraw.SetColor(Fl.Black); FlDraw.Rect(xx, yy, 130, 130);
  DrawOne(1, xx + 1, yy + 1);
  FlDraw.Text("Gray", xx + 134, yy + 64);
  (* bottom right: Gray+Alpha *)
  xx := p.X() + 10 + 200; yy := p.Y() + 10 + 134;
  Back(xx, yy);
  DrawOne(2, xx + 1, yy + 1);
  FlDraw.SetColor(Fl.Black); FlDraw.Text("Gray+Alpha", xx + 134, yy + 64)
END Draw;

PROCEDURE Refresh(w: Fl.Widget);
  VAR g: Fl.Group;
BEGIN
  cb := ckCB.Value(); img := ckIMG.Value(); flipH := ckFLIPH.Value();
  IF rbLXp1.Value() THEN lx := 1
  ELSIF rbLXm1.Value() THEN lx := -1
  ELSE lx := 0
  END;
  BuildImages;
  g := ckCB.Parent(); g := g.Parent(); g.Redraw
END Refresh;

PROCEDURE Check(VAR b: FlButtons.CheckButton; x, y, w, h: INTEGER; label: ARRAY OF CHAR; v: BOOLEAN; tip: ARRAY OF CHAR);
BEGIN
  NEW(b); FlButtons.OpenCheckButton(b, x, y, w, h, label);
  b.action := Refresh; b.SetValue(v); Ut.SetTip(b, tip)
END Check;

PROCEDURE Radio(VAR b: FlButtons.RadioButton; x, y, w, h: INTEGER; label: ARRAY OF CHAR);
BEGIN
  NEW(b); FlButtons.OpenRadioButton(b, x, y, w, h, label); b.action := Refresh
END Radio;

PROCEDURE Create*(): Fl.Widget;
  CONST cw = 90; ch = 200;
  VAR p: Page; ctr, rd: Fl.Group; cx, cy: INTEGER;
BEGIN
  BuildImages;
  NEW(p);
  Ut.OpenPage(p, "Testing Image Drawing||This test renders four images, two of them with a checker board|visible through the graphics. Color and gray gradients should be|visible. This does not test any image formats such as JPEG.");
  cx := Ut.X + Ut.W - cw - 5; cy := Ut.Y + 10;
  NEW(ctr); Fl.OpenGroup(ctr, cx, cy, cw, ch, "");
  Check(ckCB, cx + 10, cy + 10, cw - 20, 30, "CB", cb, "1 to show the checker board background for alpha images,|0 otherwise");
  Check(ckIMG, cx + 10, cy + 40, cw - 20, 30, "IMG", img, "1 to use Fl_RGB_Image for drawing images with transparency,|0 to use fl_draw_image() instead.");
  Check(ckFLIPH, cx + 10, cy + 70, cw - 20, 30, "FLIPH", flipH, "1 = Flip image horizontally (only if IMG == 0)|0 = Draw image normal, w/o horizontal flipping");
  NEW(rd); Fl.OpenGroup(rd, cx + 10, cy + 100, cw - 20, 90, "LX");
  Radio(rbLXp1, cx + 15, cy + 105, cw - 30, 20, "+1");
  Radio(rbLX0, cx + 15, cy + 125, cw - 30, 20, "0");
  Ut.SetTip(rbLX0, "0 for default: ld() = 0, i.e. ld() defaults (internally) to w()*d()|+1: ld() = (w() + DX) * d()|-1 to flip image vertically: ld() = - ((w() + DX) * d())");
  Radio(rbLXm1, cx + 15, cy + 145, cw - 30, 20, "-1");
  rbLX0.SetValue(TRUE);
  rd.SetBoxType(Fl.BorderBox);
  rd.SetAlign(Fl.AlignInside + Fl.AlignBottom + Fl.AlignCenter);
  rd.End;
  ctr.SetBoxType(Fl.BorderBox);
  ctr.End;
  p.End;
  RETURN p
END Create;

BEGIN
  cb := TRUE; img := TRUE; lx := 0; flipH := FALSE;
  BuildPixels
END UtImages.
