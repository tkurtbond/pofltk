MODULE Tooltips; (* Tooltip settings, and a tooltip for each part of a widget *)

(* The left and right halves of the box have tooltips of their own. *)

IMPORT Fl, FlButtons;

TYPE
  Halves = POINTER TO RECORD (Fl.BoxDesc) inRight: BOOLEAN END;

VAR
  window: Fl.Window;
  halves: Halves;
  check: FlButtons.CheckButton;

PROCEDURE (h: Halves) EnterHalf(right: BOOLEAN);
BEGIN
  h.inRight := right;
  IF right THEN
    Fl.EnterArea(h, h.X() + h.W() DIV 2, h.Y(), h.W() DIV 2, h.H(), "the right half")
  ELSE
    Fl.EnterArea(h, h.X(), h.Y(), h.W() DIV 2, h.H(), "the left half")
  END
END EnterHalf;

PROCEDURE (h: Halves) Handle*(event: INTEGER): BOOLEAN;
BEGIN
  IF event = Fl.EvEnter THEN
    h.EnterHalf(Fl.EventX() >= h.X() + h.W() DIV 2); RETURN TRUE
  ELSIF event = Fl.EvMove THEN
    IF (Fl.EventX() >= h.X() + h.W() DIV 2) # h.inRight THEN h.EnterHalf(~h.inRight) END;
    RETURN TRUE
  ELSIF event = Fl.EvLeave THEN
    Fl.EnterArea(h, 0, 0, 0, 0, ""); RETURN TRUE
  END;
  RETURN h.Handle^(event)
END Handle;

PROCEDURE Enable(w: Fl.Widget);
BEGIN Fl.EnableTooltips(check.Value())
END Enable;

BEGIN
  Fl.SetTooltipDelay(0.2D0);
  Fl.SetTooltipColor(Fl.Yellow);
  Fl.SetTooltipFont(Fl.Courier);
  Fl.SetTooltipSize(16);
  NEW(window); Fl.OpenWindow(window, 300, 130, "Tooltips");
  NEW(halves); Fl.OpenBox(halves, 20, 20, 260, 50, "two halves");
  halves.SetBoxType(Fl.UpBox);
  NEW(check); FlButtons.OpenCheckButton(check, 20, 85, 200, 25, "show tooltips");
  check.SetValue(TRUE);
  check.SetTooltip("this one is the widget's own");
  check.action := Enable;
  window.End;
  window.Show;
  Fl.Run
END Tooltips.
