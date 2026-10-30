MODULE Presets; (* Each slider, dial and counter class, moving together *)

IMPORT Fl, FlValuators;

VAR
  window: Fl.Window;
  fill, hor, horFill, nice, horNice: FlValuators.Slider;
  horValue: FlValuators.ValueSlider;
  fillDial, lineDial: FlValuators.Dial;
  counter: FlValuators.Counter;

PROCEDURE Moved(w: Fl.Widget);
  VAR x: LONGREAL;
BEGIN
  x := w(FlValuators.Valuator).Value();
  fill.SetValue(x); hor.SetValue(x); horFill.SetValue(x); nice.SetValue(x); horNice.SetValue(x);
  horValue.SetValue(x); fillDial.SetValue(x); lineDial.SetValue(x); counter.SetValue(x)
END Moved;

PROCEDURE Set(v: FlValuators.Valuator; x: LONGREAL);
BEGIN v.SetBounds(0.0D0, 100.0D0); v.SetValue(x); v.action := Moved
END Set;

BEGIN
  NEW(window); Fl.OpenWindow(window, 340, 330, "Presets");
  NEW(fill); FlValuators.OpenFillSlider(fill, 20, 20, 25, 180, "fill");
  NEW(nice); FlValuators.OpenNiceSlider(nice, 70, 20, 25, 180, "nice");
  NEW(hor); FlValuators.OpenHorSlider(hor, 120, 20, 200, 25, "hor");
  NEW(horFill); FlValuators.OpenHorFillSlider(horFill, 120, 70, 200, 25, "hor fill");
  NEW(horNice); FlValuators.OpenHorNiceSlider(horNice, 120, 120, 200, 25, "hor nice");
  NEW(horValue); FlValuators.OpenHorValueSlider(horValue, 120, 170, 200, 25, "hor value");
  NEW(fillDial); FlValuators.OpenFillDial(fillDial, 20, 230, 60, 60, "fill dial");
  NEW(lineDial); FlValuators.OpenLineDial(lineDial, 100, 230, 60, 60, "line dial");
  NEW(counter); FlValuators.OpenSimpleCounter(counter, 180, 245, 140, 25, "simple counter");
  Set(fill, 40.0D0); Set(nice, 40.0D0); Set(hor, 40.0D0); Set(horFill, 40.0D0);
  Set(horNice, 40.0D0); Set(horValue, 40.0D0); Set(fillDial, 40.0D0); Set(lineDial, 40.0D0);
  Set(counter, 40.0D0);
  window.End;
  window.Show;
  Fl.Run
END Presets.
