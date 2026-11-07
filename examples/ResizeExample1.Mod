MODULE ResizeExample1; (* FLTK's test/resize-example1.cxx in Oberon-2 *)

(* A group of fifteen boxes, itself its resizable, shown at its first
   size and resized horizontally, vertically and both ways, with arrows
   showing the widths and heights before and after: every box grows.
   The window starts larger than it was made, so the copies are
   already resized. *)

IMPORT Fl, ResizeArrows;

CONST
  Ax = 0; Bx = 35; Cx = 70; Dx = 105; Nx = 140; Aw = 35; Rw = 70; Mw = 140;
  Ay = 0; Ey = 35; Gy = 70; Iy = 105; My = 140; Ah = 35; Rh = 70; Nh = 175;
  TLx = 35; TRx = 245; TGx = 420; TLw = 175; TGw = 140; TAw = 35;
  TLy = 35; BLy = 245; LGy = 420; TLh = 175; LGh = 105; LAh = 35;
  Ww = 560; Wh = 525;

VAR
  window: Fl.DoubleWindow;
  resizables: Fl.Group;

PROCEDURE Box(x, y, w, h: INTEGER; label-: ARRAY OF CHAR; color: INTEGER);
VAR b: Fl.Box;
BEGIN
  NEW(b); Fl.OpenBox(b, x, y, w, h, label);
  b.SetBoxType(Fl.EngravedBox); (* FL_FRAME_BOX *)
  b.SetColor(color)
END Box;

PROCEDURE Resizebox(x, y, w, h: INTEGER; label-: ARRAY OF CHAR): Fl.Group;
VAR g: Fl.Group;
BEGIN
  NEW(g); Fl.OpenGroup(g, x, y, w, h, label);
  g.SetAlign(Fl.AlignTop + Fl.AlignLeft);
  g.SetBoxType(Fl.UpBox);
  Box(x + Ax, y + Ay, Aw, Ah, "A", 14);
  Box(x + Bx, y + Ay, Aw, Ah, "B", 9);
  Box(x + Cx, y + Ay, Aw, Ah, "C", 10);
  Box(x + Dx, y + Ay, Aw, Ah, "D", 11);
  Box(x + Ax, y + Ey, Aw, Ah, "E", 9);
  Box(x + Bx, y + Ey, Rw, Rh, " ", 8);
  Box(x + Dx, y + Ey, Aw, Ah, "F", 12);
  Box(x + Ax, y + Gy, Aw, Ah, "G", 10);
  Box(x + Dx, y + Gy, Aw, Ah, "H", 13);
  Box(x + Ax, y + Iy, Aw, Ah, "I", 11);
  Box(x + Bx, y + Iy, Aw, Ah, "J", 12);
  Box(x + Cx, y + Iy, Aw, Ah, "K", 13);
  Box(x + Dx, y + Iy, Aw, Ah, "L", 14);
  Box(x + Ax, y + My, Mw, Ah, "M", 12);
  Box(x + Nx, y + Ay, Aw, Nh, "N", 13);
  g.End;
  g.SetResizable(g);
  RETURN g
END Resizebox;

(* A group of no box for an arrow. *)
PROCEDURE ArrowGroup(x, y, w, h: INTEGER): Fl.Group;
VAR g: Fl.Group;
BEGIN
  NEW(g); Fl.OpenGroup(g, x, y, w, h, "");
  g.SetBoxType(Fl.NoBox);
  g.SetColor(Fl.White);
  RETURN g
END ArrowGroup;

PROCEDURE Harrow(x, y, w, h: INTEGER; label-: ARRAY OF CHAR): ResizeArrows.Harrow;
VAR a: ResizeArrows.Harrow;
BEGIN NEW(a); ResizeArrows.OpenHarrow(a, x, y, w, h, label); RETURN a
END Harrow;

PROCEDURE Varrow(x, y, w, h: INTEGER; label-: ARRAY OF CHAR): ResizeArrows.Varrow;
VAR a: ResizeArrows.Varrow;
BEGIN NEW(a); ResizeArrows.OpenVarrow(a, x, y, w, h, label); RETURN a
END Varrow;

PROCEDURE Resizables(x, y, w, h: INTEGER): Fl.Group;
VAR r, tl, br, g: Fl.Group;
BEGIN
  NEW(r); Fl.OpenGroup(r, x, y, w, h, "");
  r.SetBoxType(Fl.UpBox);
  r.SetColor(Fl.White);
  tl := Resizebox(x + TLx, y + TLy, TLw, TLh, "Original Size");
  tl.SetResizable(NIL);
  g := Resizebox(x + TRx, y + TLy, TLw, TLh, "Horizontally Resized");
  g := Resizebox(x + TLx, y + BLy, TLw, TLh, "Vertically Resized");
  br := Resizebox(x + TRx, y + BLy, TLw, TLh, "Horizontally and Vertically Resized");

  g := ArrowGroup(x + TLx, y + LGy, TLw, LGh);
  g.SetResizable(Harrow(g.X(), g.Y(), g.W(), LAh, "Initial|width"));
  g.End;
  g := ArrowGroup(x + TRx, y + LGy, TLw, LGh);
  g.SetResizable(Harrow(g.X(), g.Y(), g.W(), LAh, "Resized|width"));
  g.End;
  g := ArrowGroup(x + TGx, y + TLy, TGw, TLh);
  g.SetResizable(Varrow(x + TGx, y + TLy, TAw, TLh, "Initial|height"));
  g.End;
  g := ArrowGroup(x + TGx, y + BLy, TGw, TLh);
  g.SetResizable(Varrow(x + TGx, y + BLy, TAw, TLh, "Resized|height"));
  g.End;

  r.SetResizable(br);
  r.End;
  RETURN r
END Resizables;

BEGIN
  NEW(window); Fl.OpenDoubleWindow(window, Ww, Wh, "resize-example1");
  window.SetColor(Fl.White);
  resizables := Resizables(0, 0, Ww, Wh);
  window.End;
  window.SetResizable(resizables);
  window.SizeRange(Ww, Wh, 0, 0);
  window.ShowArgs;
  window.Size(Ww + 140, Wh + 35);
  Fl.Run
END ResizeExample1.
