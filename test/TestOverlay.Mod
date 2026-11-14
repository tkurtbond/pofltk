MODULE TestOverlay; (* Fl.OverlayWindow: DrawOverlay, sent to Oberon, and redrawing *)

IMPORT Fl, FlDraw, FlTest, Check;

TYPE
  Overlay = POINTER TO RECORD (Fl.OverlayWindowDesc) draws: INTEGER END;

VAR
  o: Overlay;
  box: Fl.Box;
  n, i: INTEGER;

PROCEDURE (o: Overlay) DrawOverlay*;
BEGIN
  INC(o.draws);
  FlDraw.SetColor(Fl.Red); FlDraw.RectF(10, 10, 20, 20)
END DrawOverlay;

(* Waits for the overlay to be drawn, allowing for valgrind. *)
PROCEDURE Drawn(): BOOLEAN;
BEGIN
  i := 0;
  WHILE (o.draws = n) & (i < 500) DO Fl.Wait(0.01D0); INC(i) END;
  RETURN o.draws > n
END Drawn;

BEGIN
  NEW(o); Fl.OpenOverlayWindow(o, 100, 100, "TestOverlay");
  NEW(box); Fl.OpenBox(box, 0, 0, 100, 100, "");
  box.SetBoxType(Fl.FlatBox); box.SetColor(Fl.White);
  o.End;
  Check.Check(~o.CanDoOverlay(), "X11 and Wayland have no real overlay");

  o.RedrawOverlay;  (* in a window not shown, nothing to draw on *)
  Check.Check(o.draws = 0, "a window not shown draws no overlay");
  o.Show; o.WaitForExpose;

  (* FLTK draws a window's overlay with the window on a surface *)
  n := o.draws;
  Check.Check(FlTest.Capture(o), "a capture");
  Check.Check((o.draws = n + 1) & (FlTest.Pixel(15, 15) = Fl.RGB(255, 0, 0))
    & (FlTest.Pixel(50, 50) = Fl.RGB(255, 255, 255)), "draws the widgets, and over them the overlay");
  FlTest.Release;

  n := o.draws; o.RedrawOverlay;
  Check.Check(Drawn(), "RedrawOverlay draws it");
  n := o.draws; o.RedrawOverlay;
  Check.Check(Drawn(), "and again");

  o.Delete;
  Check.Check(Fl.OpenWidgets() = 0, "every widget deleted");
  Check.Summary
END TestOverlay.
