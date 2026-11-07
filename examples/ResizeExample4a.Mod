MODULE ResizeExample4a; (* FLTK's test/resize-example4a.cxx in Oberon-2 *)

(* Two rows of boxes, "buttons" and "inputs", in a group in a group,
   shown at its first width and resized horizontally, with arrows
   showing the widths before and after. The last input is the inner
   group's resizable, so only it grows. FLTK's program spells
   "Horizonally". *)

IMPORT Fl, ResizeArrows;

CONST
  TLx = 35; TRx = 320; TLw = 260; Ww = 620;
  TLy = 35; LGy = 100; TLh = 65; LGh = 70; LAh = 35; Wh = 200;

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

(* The Simplex, and in key the widget the arrows measure. *)
PROCEDURE Simplex(x, y, w, h: INTEGER; label-: ARRAY OF CHAR; VAR key: Fl.Widget): Fl.Group;
VAR s, g: Fl.Group; b: Fl.Box;
BEGIN
  s := Group(x, y, w, h, label, Fl.UpBox);
  g := Group(x + 10, y + 10, 240, 45, "", Fl.NoBox);
  b := UpBox(x + 20, y + 20, 40, 25, "btn");
  b := UpBox(x + 70, y + 20, 50, 25, "input");
  b := UpBox(x + 140, y + 20, 40, 25, "btn");
  b := UpBox(x + 190, y + 20, 50, 25, "input");
  b.SetColor(Fl.Yellow);
  g.SetResizable(b);
  g.End;
  key := b;
  s.SetResizable(g);
  s.End;
  s.SetAlign(Fl.AlignTop + Fl.AlignLeft);
  RETURN s
END Simplex;

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
VAR r, tr, g: Fl.Group; tlk, trk: Fl.Widget;
BEGIN
  NEW(r); Fl.OpenGroup(r, x, y, w, h, "");
  g := Simplex(x + TLx, y + TLy, TLw, TLh, "Original", tlk);
  tr := Simplex(x + TRx, y + TLy, TLw, TLh, "Horizonally Resized", trk);

  g := ArrowGroup(x + TLx, y + LGy, TLw, LGh);
  g.SetResizable(Harrow(tlk.X(), g.Y(), tlk.W(), LAh, "Initial|width"));
  g.End;
  g := ArrowGroup(x + TRx, y + LGy, TLw, LGh);
  g.SetResizable(Harrow(trk.X(), g.Y(), trk.W(), LAh, "Resized|width"));
  g.End;

  r.SetResizable(tr);
  r.End;
  RETURN r
END Resizables;

BEGIN
  NEW(window); Fl.OpenDoubleWindow(window, Ww, Wh, "resize-example4a");
  window.SetColor(Fl.White);
  resizables := Resizables(0, 0, Ww, Wh);
  window.End;
  window.SetResizable(resizables);
  window.SizeRange(Ww, Wh, 0, 0);
  window.ShowArgs;
  window.Size(Ww + 90, Wh);
  Fl.Run
END ResizeExample4a.
