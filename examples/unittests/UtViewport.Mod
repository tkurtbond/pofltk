MODULE UtViewport; (* FLTK's test/unittest_viewport.cxx in Oberon-2 *)

IMPORT Fl, Ut;

CONST Label* = "Viewport Test";

TYPE
  (* shows the main window's alignment marks while it is shown *)
  Page = POINTER TO RECORD (Fl.BoxDesc) END;

PROCEDURE (p: Page) Show*;
BEGIN p.Show^; Ut.testAlignment(TRUE)
END Show;

PROCEDURE (p: Page) Hide*;
BEGIN p.Hide^; Ut.testAlignment(FALSE)
END Hide;

PROCEDURE Create*(): Fl.Widget;
  VAR p: Page;
BEGIN
  NEW(p); Fl.OpenBox(p, Ut.X, Ut.Y, Ut.W, Ut.H, "");
  Ut.SetLabel(p, "Testing Viewport Alignment||Only green lines should be visible.|If red lines are visible in the corners of this window,|your viewport alignment and clipping is off.|If there is a space between the green lines and the window border,|the viewport is off, but some clipping may be working.|Also, your window size may be off to begin with.");
  p.SetAlign(Fl.AlignInside + Fl.AlignCenter + Fl.AlignWrap);
  p.SetBoxType(Fl.BorderBox);
  RETURN p
END Create;

END UtViewport.
