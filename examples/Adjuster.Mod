MODULE Adjuster; (* FLTK's test/adjuster.cxx in Oberon-2 *)

IMPORT Fl, FlValuators;

TYPE
  (* an adjuster that shows its value in a box *)
  Adj = POINTER TO AdjDesc;
  AdjDesc = RECORD (FlValuators.AdjusterDesc) box: Fl.Box END;

VAR
  window: Fl.DoubleWindow;
  b1, b2: Fl.Box;
  a1, a2: Adj;

PROCEDURE Show(w: Fl.Widget);
VAR s: ARRAY 100 OF CHAR;
BEGIN
  w(Adj).Format(s); w(Adj).box.SetLabel(s)
END Show;

PROCEDURE Pair(VAR b: Fl.Box; VAR a: Adj; bx, ax, ay, aw, ah: INTEGER);
BEGIN
  NEW(b); Fl.OpenBox(b, bx, 30, 80, 25, "");
  b.SetBoxType(Fl.DownBox); b.SetColor(Fl.White);
  NEW(a); FlValuators.OpenAdjuster(a, ax, ay, aw, ah, "");
  a.box := b; a.action := Show; Show(a)
END Pair;

BEGIN
  NEW(window); Fl.OpenDoubleWindow(window, 320, 100, "adjuster");
  Pair(b1, a1, 20, 20 + 80, 30, 3 * 25, 25);
  Pair(b2, a2, 20 + 80 + 4 * 25, 20 + 80 + 4 * 25 + 80, 10, 25, 3 * 25);
  window.SetResizable(window);
  window.End;
  window.ShowArgs;
  Fl.Run
END Adjuster.
