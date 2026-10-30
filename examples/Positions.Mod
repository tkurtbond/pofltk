MODULE Positions; (* A positioner, and a clock its two values set *)

(* Drag the cross: across sets the hours, down the minutes. *)

IMPORT Fl, FlValuators;

VAR
  window: Fl.Window;
  place: FlValuators.Positioner;
  clock: FlValuators.ClockOutput;

PROCEDURE Moved(w: Fl.Widget);
BEGIN clock.SetHMS(SHORT(ENTIER(place.XValue())), SHORT(ENTIER(place.YValue())), 0)
END Moved;

BEGIN
  NEW(window); Fl.OpenWindow(window, 420, 220, "Positions");
  NEW(place); FlValuators.OpenPositioner(place, 10, 10, 200, 200, "");
  place.SetXBounds(0.0D0, 23.0D0); place.SetYBounds(0.0D0, 59.0D0);
  place.SetXStep(1.0D0); place.SetYStep(1.0D0);
  place.SetValue(10.0D0, 10.0D0);
  place.action := Moved;
  NEW(clock); FlValuators.OpenClockOutput(clock, 220, 10, 190, 200, "");
  clock.SetKind(FlValuators.RoundClock);
  clock.SetHMS(10, 10, 0);
  window.End;
  window.Show;
  Fl.Run
END Positions.
