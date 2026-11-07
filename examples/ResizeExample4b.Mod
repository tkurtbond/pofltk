MODULE ResizeExample4b; (* FLTK's test/resize-example4b.cxx in Oberon-2 *)

(* As resize-example4a, but each button and input pair has a group of
   its own, side by side, whose resizable is its input: each group
   grows, and each input with it. The right arrow is in the right half
   of a group of two. FLTK's program spells "Horizonally". *)

IMPORT Fl, ResizeArrows;

CONST
  TLx = 35; TRx = 320; TLw = 260; Ww = 620;
  TLy = 35; LGy = 100; TLh = 65; LGh = 80; LAh = 35; Wh = 200;

VAR
  window: Fl.DoubleWindow;
  resizables: Fl.Group;

PROCEDURE UpBox(x, y, w, h: INTEGER; label-: ARRAY OF CHAR): Fl.Box;
VAR b: Fl.Box;
BEGIN
  NEW(b); Fl.OpenBox(b, x, y, w, h, label);
  b.SetBoxType(Fl.UpBox);
  RETURN b
END UpBox;

PROCEDURE Group(x, y, w, h: INTEGER; label-: ARRAY OF CHAR; box: INTEGER): Fl.Group;
VAR g: Fl.Group;
BEGIN
  NEW(g); Fl.OpenGroup(g, x, y, w, h, label);
  g.SetBoxType(box);
  RETURN g
END Group;

(* The Complex, and in key the widget the arrows measure. *)
PROCEDURE Complex(x, y, w, h: INTEGER; label-: ARRAY OF CHAR; VAR key: Fl.Widget): Fl.Group;
VAR s, g: Fl.Group; b: Fl.Box;
BEGIN
  s := Group(x, y, w, h, label, Fl.UpBox);
  g := Group(x + 10, y + 10, 120, 45, "", Fl.UpBox);
  b := UpBox(x + 20, y + 20, 40, 25, "btn");
  b := UpBox(x + 70, y + 20, 50, 25, "input");
  b.SetColor(Fl.Yellow);
  g.SetResizable(b);
  g.End;
  g := Group(x + 130, y + 10, 120, 45, "", Fl.UpBox);
  b := UpBox(x + 140, y + 20, 40, 25, "btn");
  b := UpBox(x + 190, y + 20, 50, 25, "input");
  b.SetColor(Fl.Yellow);
  g.SetResizable(b);
  g.End;
  key := b;
  s.End;
  s.SetAlign(Fl.AlignTop + Fl.AlignLeft);
  RETURN s
END Complex;

(* A group of no box, on white. *)
PROCEDURE ArrowGroup(x, y, w, h: INTEGER): Fl.Group;
VAR g: Fl.Group;
BEGIN
  g := Group(x, y, w, h, "", Fl.NoBox);
  g.SetColor(Fl.White);
  RETURN g
END ArrowGroup;

PROCEDURE Harrow(x, y, w, h: INTEGER; label-: ARRAY OF CHAR): ResizeArrows.Harrow;
VAR a: ResizeArrows.Harrow;
BEGIN NEW(a); ResizeArrows.OpenHarrow(a, x, y, w, h, label); RETURN a
END Harrow;

PROCEDURE Resizables(x, y, w, h: INTEGER): Fl.Group;
VAR r, tr, g, rg: Fl.Group; tlk, trk: Fl.Widget;
BEGIN
  NEW(r); Fl.OpenGroup(r, x, y, w, h, "");
  g := Complex(x + TLx, y + TLy, TLw, TLh, "Original", tlk);
  tr := Complex(x + TRx, y + TLy, TLw, TLh, "Horizonally Resized", trk);

  g := ArrowGroup(x + TLx, y + LGy, TLw, LGh);
  g.SetResizable(Harrow(tlk.X(), g.Y(), tlk.W(), LAh, "Initial|width"));
  g.End;
  rg := ArrowGroup(x + TRx, y + LGy, TLw, LGh);
  (* its left half empty, and its right half holding the arrow *)
  g := ArrowGroup(x + TRx, y + LGy, TLw DIV 2, LGh);
  g.End;
  g := ArrowGroup(x + TRx + TLw DIV 2, y + LGy, TLw DIV 2, LGh);
  g.SetResizable(Harrow(trk.X(), g.Y(), trk.W(), LAh, "Resized|width"));
  g.End;
  rg.End;

  r.SetResizable(tr);
  r.End;
  RETURN r
END Resizables;

BEGIN
  NEW(window); Fl.OpenDoubleWindow(window, Ww, Wh, "resize-example4b");
  window.SetColor(Fl.White);
  resizables := Resizables(0, 0, Ww, Wh);
  window.End;
  window.SetResizable(resizables);
  window.SizeRange(Ww, Wh, 0, 0);
  window.ShowArgs;
  window.Size(Ww + 90, Wh);
  Fl.Run
END ResizeExample4b.
