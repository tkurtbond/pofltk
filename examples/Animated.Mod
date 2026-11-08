MODULE Animated; (* FLTK's test/animated.cxx in Oberon-2 *)

(* Alpha blending: 48 frames of a 256 by 256 RGBA image, a sphere fading
   in and out and a half-transparent blob moving across, drawn over the
   window's red at 24 frames a second. Each frame is drawn from 5, 5 of
   the image, clipped 5 pixels in, so both edges show 5 pixels of red
   and the image's black box at its top left doesn't show. *)

IMPORT Fl, FlDraw, FlImages;

CONST
  dim = 256;     (* the images' width and height *)
  frames = 48;   (* the animation's length *)

TYPE
  Window = POINTER TO RECORD (Fl.DoubleWindowDesc) END;
  Animation = POINTER TO RECORD (Fl.TimerDesc) END;

VAR
  img: ARRAY frames OF FlImages.Image;
  data: ARRAY dim * dim * 4 OF CHAR;
  curframe: INTEGER;
  win: Window;
  animation: Animation;

(* C's conversion of a float to an int: toward zero. *)
PROCEDURE Trunc(r: REAL): INTEGER;
BEGIN
  IF r < 0 THEN RETURN -SHORT(ENTIER(-r)) ELSE RETURN SHORT(ENTIER(r)) END
END Trunc;

(* Each pixel's channel c, set to v. *)
PROCEDURE Set(x, y, c, v: INTEGER);
BEGIN data[(y * dim + x) * 4 + c] := CHR(v)
END Set;

(* The frames, computed in single precision as FLTK's program does. *)
PROCEDURE MakeImages;
  CONST spherew = 60; spherex = (dim - spherew) DIV 2;
    maxdist = (spherew DIV 2) * (spherew DIV 2);
  VAR i, j, x, y, alpha, myalpha, grey, xoffset, yoffset, w: INTEGER;
    distx, disty, dist, fill, pos: REAL;
BEGIN
  FOR i := 0 TO frames - 1 DO
    FOR j := 0 TO LEN(data) - 1 DO data[j] := 0X END;

    (* first a black box, 10x10 pixels in the top-left corner *)
    FOR x := 0 TO 9 DO
      FOR y := 0 TO 9 DO Set(x, y, 3, 255) END
    END;

    (* a fading sphere *)
    IF i < frames DIV 2 THEN alpha := Trunc(255 * (i / (frames / 2)))
    ELSE alpha := Trunc(255 * ((frames DIV 2 - (i - frames DIV 2)) / (frames / 2)))
    END;
    FOR x := spherex TO spherex + spherew - 1 DO
      FOR y := 20 TO 20 + spherew - 1 DO
        distx := x - (spherex + spherew / 2);
        disty := y - (20 + spherew / 2);
        dist := distx * distx + disty * disty;
        IF dist <= maxdist THEN
          fill := dist / maxdist;
          grey := Trunc(fill * 255);
          myalpha := alpha;
          (* C compares the float with the double 0.9, and the product
             wraps in a byte *)
          IF LONG(fill) > 0.9D0 THEN
            myalpha := myalpha * Trunc((1.0 - fill) * 10) MOD 256
          END;
          Set(x, y, 0, grey); Set(x, y, 1, grey); Set(x, y, 2, grey);
          Set(x, y, 3, myalpha)
        END
      END
    END;

    (* a moving blob *)
    pos := (i / frames) * 2 - 0.5;
    xoffset := Trunc(pos * dim);
    yoffset := 2 * dim DIV 3;
    w := dim DIV 4;
    FOR x := -w TO w - 1 DO
      IF (x + xoffset >= 0) & (x + xoffset < dim) THEN
        FOR y := yoffset - w TO yoffset + w - 1 DO
          Set(x + xoffset, y, 2, ABS(y - yoffset));
          Set(x + xoffset, y, 3, 127)
        END
      END
    END;

    NEW(img[i]); FlImages.OpenRGB(img[i], data, dim, dim, 4, 0)
  END
END MakeImages;

PROCEDURE (w: Window) Draw*;
BEGIN
  w.Draw^;
  (* test both cx/cy offset and clipping *)
  FlDraw.PushClip(5, 5, w.W() - 5, w.H() - 5);
  img[curframe].DrawPart(0, 0, dim, dim, 5, 5);
  FlDraw.PopClip
END Draw;

PROCEDURE (t: Animation) Fire*;
BEGIN
  win.Redraw;
  Fl.RepeatTimeout(t, 1.0D0 / 24);
  curframe := (curframe + 1) MOD frames
END Fire;

BEGIN
  NEW(win); Fl.OpenDoubleWindow(win, 256, 256, "Alpha rendering benchmark, watch CPU use");
  win.SetColor(Fl.RGB(142, 0, 0));
  MakeImages;
  win.End;
  win.ShowArgs;
  NEW(animation); Fl.AddTimeout(animation, 1.0D0 / 24);
  Fl.Run
END Animated.
