MODULE TestRect; (* Fl.Rect: the arithmetic of Fl_Rect, and a widget's and box's rectangles *)

IMPORT Fl, Check;

VAR
  r, q: Fl.Rect;
  b: Fl.Box;
  win: Fl.Window;

BEGIN
  r.Set(10, 20, 30, 40);
  Check.Check((r.x = 10) & (r.y = 20) & (r.w = 30) & (r.h = 40), "Set");
  Check.Check((r.Right() = 40) & (r.Bottom() = 60), "Right and Bottom are just past it");

  r.SetRight(50); r.SetBottom(70);
  Check.Check((r.x = 10) & (r.y = 20) & (r.w = 40) & (r.h = 50), "SetRight and SetBottom move one edge");

  r.Inset(5);
  Check.Check((r.x = 15) & (r.y = 25) & (r.w = 30) & (r.h = 40), "Inset shrinks every side");
  r.Inset(-5);
  Check.Check((r.x = 10) & (r.y = 20) & (r.w = 40) & (r.h = 50), "and a negative amount enlarges");
  r.InsetSides(1, 2, 3, 4);
  Check.Check((r.x = 11) & (r.y = 22) & (r.w = 36) & (r.h = 44), "InsetSides");

  q := r;
  Check.Check(r.Equal(q), "Equal");
  q.w := 0;
  Check.Check(~r.Equal(q), "and not");

  r.Set(0, 0, 100, 100);
  r.InsetBox(Fl.DownBox);
  Check.Check((r.x = Fl.BoxDX(Fl.DownBox)) & (r.y = Fl.BoxDY(Fl.DownBox))
    & (r.w = 100 - Fl.BoxDW(Fl.DownBox)) & (r.h = 100 - Fl.BoxDH(Fl.DownBox)),
    "InsetBox leaves what the box has inside");
  Check.Check(r.w < 100, "and the down box has a frame");

  NEW(win); Fl.OpenWindow(win, 200, 200, "TestRect");
  NEW(b); Fl.OpenBox(b, 1, 2, 3, 4, "");
  win.End;
  r.SetFrom(b);
  Check.Check((r.x = 1) & (r.y = 2) & (r.w = 3) & (r.h = 4), "SetFrom a widget");
  win.Delete;
  Check.Check(Fl.OpenWidgets() = 0, "every widget deleted");
  Check.Summary
END TestRect.
