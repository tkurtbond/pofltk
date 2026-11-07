MODULE ResizeExample5c; (* FLTK's test/resize-example5c.cxx in Oberon-2 *)

(* As resize-example5b, but the groups have no box or label, and the
   small box between them is a thin yellow line. *)

IMPORT Fl, ResizeArrows;

CONST
  TLx = 35; TRx = 320; TLw = 260; Ww = 620;
  TLy = 35; LGy = 100; TLh = 65; LGh = 70; LAh = 35; Wh = 175;

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
VAR s, g, l: Fl.Group; b: Fl.Box;
BEGIN
  s := Group(x, y, w, h, label, Fl.UpBox);
  g := Group(x + 10, y + 10, 240, 45, "", Fl.UpBox);
  l := Group(x + 10, y + 15, 145, 35, "", Fl.NoBox);
  b := UpBox(x + 20, y + 20, 80, 25, "A");
  l.SetResizable(b);
  b := UpBox(x + 110, y + 20, 40, 25, "B");
  l.End;
  l := Group(x + 155, y + 15, 95, 35, "", Fl.NoBox);
  b := UpBox(x + 160, y + 20, 80, 25, "C");
  l.SetResizable(b);
  l.End;
  b := UpBox(x + 155 - 20, y + 40, 2 * 20, 5, "");
  b.SetBoxType(Fl.FlatBox);
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
  tr := Simplex(x + TRx, y + TLy, TLw, TLh, "Horizontally Resized", trk);

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
  NEW(window); Fl.OpenDoubleWindow(window, Ww, Wh, "resize-example5c");
  window.SetColor(Fl.White);
  resizables := Resizables(0, 0, Ww, Wh);
  window.End;
  window.SetResizable(resizables);
  window.SizeRange(Ww, Wh, 0, 0);
  window.ShowArgs;
  window.Size(Ww + 90, Wh);
  Fl.Run
END ResizeExample5c.
