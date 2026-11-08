MODULE Ut; (* FLTK's test/unittests.h in Oberon-2 *)

(* What the pages of Unittests share: the window's layout, the test area
   each page fills, and the widgets most pages have: a group with a long
   label, boxes naming the native and OpenGL drawings, and yellow boxes
   numbering the tests, each with a tooltip saying what to look for.
   Texts are written with "|" for each line's end, since poc has no
   escapes. *)

IMPORT Fl;

CONST
  MainW* = 700; MainH* = 600;
  BrowserX* = 10; BrowserY* = 25; BrowserW* = 150; BrowserH* = MainH - 35;
  X* = BrowserX + BrowserW + 10; Y* = BrowserY;
  W* = MainW - BrowserW - 30; H* = BrowserH;

VAR
  (* Shows the main window's alignment marks, or not: the viewport
     page's. Unittests sets it. *)
  testAlignment*: PROCEDURE (on: BOOLEAN);

(* s with each "|" a line feed *)
PROCEDURE Lines*(VAR s: ARRAY OF CHAR);
  VAR i: INTEGER;
BEGIN
  i := 0; WHILE s[i] # 0X DO IF s[i] = "|" THEN s[i] := 0AX END; INC(i) END
END Lines;

PROCEDURE SetLabel*(w: Fl.Widget; text: ARRAY OF CHAR);
BEGIN Lines(text); w.SetLabel(text)
END SetLabel;

PROCEDURE SetTip*(w: Fl.Widget; text: ARRAY OF CHAR);
BEGIN Lines(text); w.SetTooltip(text)
END SetTip;

(* A page that is a group filling the test area, its label at its foot,
   left. It is left current. *)
PROCEDURE OpenPage*(g: Fl.Group; label: ARRAY OF CHAR);
BEGIN
  Fl.OpenGroup(g, X, Y, W, H, "");
  SetLabel(g, label);
  g.SetAlign(Fl.AlignInside + Fl.AlignBottom + Fl.AlignLeft + Fl.AlignWrap);
  g.SetBoxType(Fl.BorderBox)
END OpenPage;

(* The name of a column of tests: "native" or "OpenGL". *)
PROCEDURE Heading*(x, y: INTEGER; text: ARRAY OF CHAR);
  VAR b: Fl.Box;
BEGIN
  NEW(b); Fl.OpenBox(b, x, y, 80, 18, text);
  b.SetAlign(Fl.AlignLeft + Fl.AlignInside)
END Heading;

(* A test's number, w wide, with what it tests as its tooltip. *)
PROCEDURE Mark*(x, y, w: INTEGER; label, tip: ARRAY OF CHAR);
  VAR b: Fl.Box;
BEGIN
  NEW(b); Fl.OpenBox(b, x, y, w, 18, label);
  b.SetBoxType(Fl.RoundedBox); b.SetColor(Fl.Yellow);
  SetTip(b, tip)
END Mark;

(* Makes a 1-pixel box at g's bottom right its resizable widget, so its
   tests stay where they are as it grows. *)
PROCEDURE Corner*(g: Fl.Group);
  VAR b: Fl.Box;
BEGIN
  NEW(b); Fl.OpenBox(b, g.X() + g.W() - 1, g.Y() + g.H() - 1, 1, 1, "");
  g.SetResizable(b)
END Corner;

END Ut.
