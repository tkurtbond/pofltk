MODULE TestTooltips; (* Fl_Tooltip's settings, and the current tooltip *)

IMPORT Fl, Check;

VAR
  win: Fl.Window;
  a, b: Fl.Box;
  d: LONGREAL;
  shown: BOOLEAN;
  i: INTEGER;

PROCEDURE Pump;
VAR i: INTEGER;
BEGIN FOR i := 1 TO 5 DO Fl.Wait(0.01D0) END
END Pump;

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

  (* FLTK keeps the last text after an empty one, and after one given
     while tooltips are off. A text given while a tip is up is shown by the
     hover delay's timer, and hiding the tip that was up leaves no widget
     current, so the empty text after it can't stop the timer, which then
     reads the text (doc/fltk-issues.md, 75): valgrind checks the shim kept
     it *)
  (* FLTK shows no tip in a window not shown, and under Wayland a tip over
     a window not yet exposed is fatal, as a menu is
     (doc/fltk-issues.md, 28) *)
  win.Show; i := 0;
  WHILE ~win.Shown() & (i < 500) DO Fl.Wait(0.01D0); INC(i) END;
  win.WaitForExpose;
  Fl.SetTooltipHoverDelay(0.0D0);
  Fl.EnterArea(a, 0, 0, 25, 25, "tip"); Pump;
  Fl.EnterArea(a, 0, 0, 25, 25, "other tip");
  Fl.EnterArea(a, 0, 0, 25, 25, ""); Pump;
  Fl.EnterArea(a, 0, 0, 25, 25, "tip"); Pump;
  Fl.EnableTooltips(FALSE);
  Fl.EnterArea(a, 0, 0, 25, 25, "disabled tip");
  Fl.EnableTooltips(TRUE); Pump;
  Fl.EnterArea(b, 60, 0, 25, 25, "second"); Pump;

  (* a deleted widget stops being current *)
  b.Delete;
  Check.Check(Fl.TooltipCurrent() = NIL, "a deleted widget's tooltip stops");
  Fl.EnterArea(a, 0, 0, 25, 25, "");

  win.Delete;
  Check.Check(Fl.OpenWidgets() = 0, "every widget deleted");
  Check.Summary
END TestTooltips.
