MODULE Rects; (* Fl.Rect: laying out a Draw by arithmetic on rectangles *)

IMPORT Fl, FlDraw;

TYPE
  Nest = POINTER TO RECORD (Fl.BoxDesc) END;

VAR
  window: Fl.DoubleWindow;
  nest: Nest;

(* Each box inside the last, gaining from the frame of the box type. *)
PROCEDURE (n: Nest) Draw*;
  VAR r: Fl.Rect; i: INTEGER;
BEGIN
  r.SetFrom(n);
  FOR i := 0 TO 7 DO
    FlDraw.DrawBox(Fl.UpBox, r.x, r.y, r.w, r.h, Fl.GrayRamp(i * 3));
    r.InsetBox(Fl.UpBox);
    r.Inset(8);
    r.InsetSides(4, 0, 0, 4)
  END
END Draw;

BEGIN
  NEW(window); Fl.OpenDoubleWindow(window, 300, 300, "Rects");
  NEW(nest); Fl.OpenBox(nest, 10, 10, 280, 280, "");
  window.SetResizable(nest);
  window.End;
  window.Show;
  Fl.Run
END Rects.
