MODULE ResizeArrows; (* FLTK's test/resize-arrows.cxx in Oberon-2 *)

(* The arrows the resize-example programs draw beside their groups, to
   show a width or height before and after resizing: a box with a
   black arrow across its middle, on white, with no border. A
   horizontal arrow's label is below it, a vertical one's to its
   right. *)

IMPORT Fl, FlDraw;

TYPE
  Harrow* = POINTER TO HarrowDesc;
  HarrowDesc* = RECORD (Fl.BoxDesc) END;
  Varrow* = POINTER TO VarrowDesc;
  VarrowDesc* = RECORD (Fl.BoxDesc) END;

(* Opens b with label, in which each "|" is a line feed. *)
PROCEDURE Open(b: Fl.Box; x, y, w, h: INTEGER; label: ARRAY OF CHAR; align: SET);
VAR i: INTEGER;
BEGIN
  i := 0; WHILE label[i] # 0X DO IF label[i] = "|" THEN label[i] := 0AX END; INC(i) END;
  Fl.OpenBox(b, x, y, w, h, label);
  b.SetAlign(align);
  b.SetBoxType(Fl.NoBox);
  b.SetColor(Fl.White)
END Open;

PROCEDURE OpenHarrow*(a: Harrow; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(a, x, y, w, h, label, Fl.AlignBottom)
END OpenHarrow;

PROCEDURE OpenVarrow*(a: Varrow; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(a, x, y, w, h, label, Fl.AlignRight)
END OpenVarrow;

PROCEDURE (a: Harrow) Draw*;
CONST dx = 5; dy = 4;
VAR old, x, y, w, h, my: INTEGER;
BEGIN
  old := FlDraw.Color();
  x := a.X(); y := a.Y(); w := a.W(); h := a.H();
  my := y + h DIV 2;
  FlDraw.SetColor(Fl.White); FlDraw.RectF(x, y, w, h);
  FlDraw.SetColor(Fl.Black);
  FlDraw.Polygon3(x, my, x + dx, my - dy, x + dx, my + dy);
  FlDraw.Line(x + dx, my, x + w - dx, my);
  FlDraw.Polygon3(x + w, my, x + w - dx, my + dy, x + w - dx, my - dy);
  FlDraw.SetColor(old)
END Draw;

PROCEDURE (a: Varrow) Draw*;
CONST dx = 4; dy = 5;
VAR old, x, y, w, h, mx: INTEGER;
BEGIN
  old := FlDraw.Color();
  x := a.X(); y := a.Y(); w := a.W(); h := a.H();
  mx := x + w DIV 2;
  FlDraw.SetColor(Fl.White); FlDraw.RectF(x, y, w, h);
  FlDraw.SetColor(Fl.Black);
  FlDraw.Polygon3(mx - dx, y + dy, mx, y, mx + dx, y + dy);
  FlDraw.Line(mx, y + dy, mx, y + h - dy);
  FlDraw.Polygon3(mx - dx, y + h - dy, mx + dx, y + h - dy, mx, y + h);
  FlDraw.SetColor(old)
END Draw;

END ResizeArrows.
