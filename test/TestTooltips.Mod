MODULE TestTooltips; (* Fl_Tooltip's settings, and the current tooltip *)

IMPORT Fl, Check;

VAR
  win: Fl.Window;
  a, b: Fl.Box;
  d: LONGREAL;
  shown: BOOLEAN;

BEGIN
  NEW(win); Fl.OpenWindow(win, 200, 200, "TestTooltips");
  NEW(a); Fl.OpenBox(a, 0, 0, 50, 50, "");
  NEW(b); Fl.OpenBox(b, 60, 0, 50, 50, "");
  win.End;

  Fl.SetTooltipDelay(0.25D0); d := Fl.TooltipDelay();
  Check.Check(d = 0.25D0, "the delay");
  Fl.SetTooltipHideDelay(2.5D0); d := Fl.TooltipHideDelay();
  Check.Check(d = 2.5D0, "the hide delay");
  Fl.SetTooltipHoverDelay(0.5D0); d := Fl.TooltipHoverDelay();
  Check.Check(d = 0.5D0, "the hover delay");
  Fl.SetTooltipFont(Fl.Courier);
  Check.Check(Fl.TooltipFont() = Fl.Courier, "the font");
  Fl.SetTooltipSize(20);
  Check.Check(Fl.TooltipSize() = 20, "the size");
  Fl.SetTooltipColor(Fl.Red);
  Check.Check(Fl.TooltipColor() = Fl.Red, "the color");
  Fl.SetTooltipTextColor(Fl.Blue);
  Check.Check(Fl.TooltipTextColor() = Fl.Blue, "the text color");
  Fl.SetTooltipMarginWidth(7);
  Check.Check(Fl.TooltipMarginWidth() = 7, "the margin's width");
  Fl.SetTooltipMarginHeight(8);
  Check.Check(Fl.TooltipMarginHeight() = 8, "and height");
  Fl.SetTooltipWrapWidth(300);
  Check.Check(Fl.TooltipWrapWidth() = 300, "the wrap width");

  Check.Check(Fl.TooltipsEnabled(), "tooltips start on");
  Fl.EnableTooltips(FALSE);
  Check.Check(~Fl.TooltipsEnabled(), "and go off");
  Fl.EnableTooltips(TRUE);
  Check.Check(Fl.TooltipsEnabled(), "and on");

  (* the current widget *)
  Check.Check(Fl.TooltipCurrent() = NIL, "no widget's tooltip is current");
  Fl.SetTooltipCurrent(a);
  Check.Check(Fl.TooltipCurrent() = NIL, "a widget with no tooltip doesn't become it");
  a.SetTooltip("a");
  Fl.SetTooltipCurrent(a);
  Check.Check(Fl.TooltipCurrent() = a, "SetTooltipCurrent");
  Fl.SetTooltipCurrent(NIL);
  Check.Check(Fl.TooltipCurrent() = NIL, "and NIL clears it");

  (* an area of a widget, with a timer that must not outlive it, and text
     FLTK keeps, which the shim keeps a copy of *)
  Fl.SetTooltipDelay(0.0D0);
  Fl.EnterArea(a, 0, 0, 25, 25, "first");
  Check.Check(Fl.TooltipCurrent() = a, "an area makes its widget current");
  Fl.EnterArea(b, 60, 0, 25, 25, "second");
  Check.Check(Fl.TooltipCurrent() = b, "and the next takes over");
  shown := Fl.Check();

  (* a deleted widget stops being current *)
  b.Delete;
  Check.Check(Fl.TooltipCurrent() = NIL, "a deleted widget's tooltip stops");
  Fl.EnterArea(a, 0, 0, 25, 25, "");

  win.Delete;
  Check.Check(Fl.OpenWidgets() = 0, "every widget deleted");
  Check.Summary
END TestTooltips.
