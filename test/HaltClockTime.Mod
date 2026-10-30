MODULE HaltClockTime; (* A negative time halts with Fl.Unsupported, 78: FLTK's localtime gives NULL for some *)
IMPORT Fl, FlValuators;
VAR c: FlValuators.ClockOutput;
BEGIN
  NEW(c); FlValuators.OpenClockOutput(c, 0, 0, 100, 100, "");
  c.SetTime(-1)
END HaltClockTime.
