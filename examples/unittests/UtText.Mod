MODULE UtText; (* FLTK's test/unittest_text.cxx in Oberon-2 *)

IMPORT Fl, FlDraw, FlButtons, Ut;

CONST Label* = "Rendering Text";

TYPE
  Page = POINTER TO RECORD (Fl.GroupDesc)
    base: FlButtons.CheckButton  (* "Show Baseline" *)
  END;
  Base = POINTER TO RECORD (FlButtons.CheckButtonDesc)
    page: Page
  END;

PROCEDURE (b: Base) Callback*;
BEGIN b.page.Redraw
END Callback;

(* txt at x, y on its baseline, in fl_measure's box (red) and
   fl_text_extents' (green) *)
PROCEDURE TextAndBoxes(p: Page; txt: ARRAY OF CHAR; x, y: INTEGER);
  VAR wm, hm, dx, dy, wt, ht, desc: INTEGER;
BEGIN
  wm := 0; FlDraw.Measure(txt, wm, hm);
  FlDraw.TextExtents(txt, dx, dy, wt, ht);
  IF p.base.Value() THEN
    FlDraw.SetColor(Fl.Blue); FlDraw.Line(x - 20, y, x + wt + 20, y)
  END;
  desc := FlDraw.Descent();
  FlDraw.SetColor(Fl.Red); FlDraw.Rect(x, y - hm + desc, wm, hm);
  FlDraw.SetColor(Fl.Green); FlDraw.Rect(x + dx, y + dy, wt, ht);
  FlDraw.SetColor(Fl.Black); FlDraw.Text(txt, x, y)
END TextAndBoxes;

PROCEDURE (p: Page) Draw*;
  VAR x0, y0, w0, h0, xx, yy: INTEGER;
BEGIN
  x0 := p.X(); y0 := p.Y(); w0 := p.W(); h0 := p.H();
  FlDraw.PushClip(x0, y0, w0, h0);
  (* slightly off-white, to show the green boxes better *)
  FlDraw.SetColor(Fl.GrayRamp(Fl.NumGray - 3)); FlDraw.RectF(x0, y0, w0, h0);
  p.Draw^;
  FlDraw.SetFont(Fl.Helvetica, 30);
  xx := x0 + 55; yy := y0 + 40;
  TextAndBoxes(p, '!abcdeABCDE"#A', xx, yy); INC(yy, 50);
  TextAndBoxes(p, "oacs", xx, yy); INC(xx, 100);
  TextAndBoxes(p, "qjgIPT", xx, yy); INC(yy, 50); DEC(xx, 100);
  TextAndBoxes(p, "````````", xx, yy); INC(yy, 50);
  TextAndBoxes(p, "--------", xx, yy); INC(yy, 50);
  TextAndBoxes(p, "________", xx, yy); INC(yy, 50);
  FlDraw.SetFont(Fl.Helvetica, 14);
  FlDraw.SetColor(Fl.Red); FlDraw.Text("fl_measure bounding box in RED", xx, yy);
  INC(yy, 20);
  FlDraw.SetColor(Fl.Green);
  FlDraw.Text("fl_text_extents bounding box in GREEN", xx, yy);
  FlDraw.SetColor(Fl.Black);
  xx := x0 + 10; INC(yy, 30);
  FlDraw.Text("NOTE: On systems with text anti-aliasing (e.g. macOS Quartz)", xx, yy);
  w0 := 0; FlDraw.Measure("NOTE: ", w0, h0);
  INC(xx, w0); INC(yy, h0);
  FlDraw.Text("text may leak slightly outside the fl_text_extents()", xx, yy);
  FlDraw.PopClip
END Draw;

PROCEDURE Create*(): Fl.Widget;
  VAR p: Page; b: Base; dummy: Fl.Box;
BEGIN
  NEW(p); Fl.OpenGroup(p, Ut.X, Ut.Y, Ut.W, Ut.H, "");
  NEW(b); FlButtons.OpenCheckButton(b, Ut.X + Ut.W - 150, 50, 130, 20, "Show Baseline");
  b.page := p; p.base := b;
  b.SetBoxType(Fl.FlatBox); b.SetDownBox(Fl.DownBox);
  NEW(dummy); Fl.OpenBox(dummy, Ut.X + Ut.W - 4, Ut.Y + Ut.H - 4, 2, 2, "");
  p.SetResizable(dummy);
  p.End;
  RETURN p
END Create;

END UtText.
