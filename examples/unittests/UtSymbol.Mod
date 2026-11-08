MODULE UtSymbol; (* FLTK's test/unittest_symbol.cxx in Oberon-2 *)

IMPORT Fl, FlDraw, Ut;

CONST Label* = "Symbol Text";

TYPE Page = POINTER TO RECORD (Fl.BoxDesc) END;

(* txt at x, y with its symbols, in fl_measure's box (red). Lines end at
   "|". fl_text_extents can't measure more than a line, so FLTK's test
   leaves its box out. *)
PROCEDURE TextAndBox(txt: ARRAY OF CHAR; x, y: INTEGER);
  VAR wo, ho: INTEGER;
BEGIN
  Ut.Lines(txt);
  wo := 0; FlDraw.Measure(txt, wo, ho);
  FlDraw.SetColor(Fl.Red); FlDraw.Rect(x, y, wo, ho);
  FlDraw.SetColor(Fl.Black);
  FlDraw.TextAligned(txt, x, y, 10, 10, Fl.AlignInside + Fl.AlignTop + Fl.AlignLeft)
END TextAndBox;

PROCEDURE (p: Page) Draw*;
  CONST fsize = 25;
  VAR x0, y0, w0, h0, xx, yy: INTEGER;
BEGIN
  x0 := p.X(); y0 := p.Y(); w0 := p.W(); h0 := p.H();
  FlDraw.PushClip(x0, y0, w0, h0);
  FlDraw.SetColor(Fl.GrayRamp(Fl.NumGray - 3)); FlDraw.RectF(x0, y0, w0, h0);
  FlDraw.SetFont(Fl.Helvetica, fsize);
  xx := x0 + 10; yy := y0 + 10;
  TextAndBox("Text", xx, yy); INC(yy, fsize + 10);  (* no symbols *)
  TextAndBox("@->", xx, yy); INC(yy, fsize + 10);  (* a symbol alone *)
  TextAndBox("@-> ", xx, yy); INC(yy, fsize + 10);  (* with a space after *)
  TextAndBox("@-> Rt Arrow", xx, yy); INC(yy, fsize + 10);  (* at the left *)
  TextAndBox("Lt Arrow @<-", xx, yy); INC(yy, fsize + 10);  (* at the right *)
  TextAndBox("@-> Rt/Lt @<-", xx, yy); INC(yy, fsize + 10);  (* at both *)
  TextAndBox("@@ At/Lt @<-", xx, yy); INC(yy, fsize + 10);  (* @@ left, symbol right *)
  TextAndBox("@-> Lt/At @@", xx, yy); INC(yy, fsize + 10);  (* symbol left, @@ right *)
  TextAndBox("@@ At/At @@", xx, yy); INC(yy, fsize + 10);  (* @@ at both *)
  xx := x0 + 200; yy := y0 + 10;
  TextAndBox("Line1|Line2", xx, yy); INC(yy, (fsize + 10) * 2);
  TextAndBox("@-> Line1|Line2 @<-", xx, yy); INC(yy, (fsize + 10) * 2);
  TextAndBox("@-> Line1|Line2|Line3 @<-", xx, yy); INC(yy, (fsize + 10) * 3);
  TextAndBox("@@@@", xx, yy); INC(yy, fsize + 10);  (* @@s abutting *)
  TextAndBox("@@ @@", xx, yy); INC(yy, fsize + 10);  (* and apart *)
  FlDraw.SetFont(Fl.Helvetica, 14);
  FlDraw.SetColor(Fl.Red);
  FlDraw.Text("fl_measure bounding box in RED", x0 + 10, y0 + h0 - 20);
  FlDraw.PopClip
END Draw;

PROCEDURE Create*(): Fl.Widget;
  VAR p: Page;
BEGIN
  NEW(p); Fl.OpenBox(p, Ut.X, Ut.Y, Ut.W, Ut.H, "");
  RETURN p
END Create;

END UtSymbol.
