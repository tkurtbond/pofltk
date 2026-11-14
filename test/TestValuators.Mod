MODULE TestValuators; (* FlValuators: values, bounds, steps, kinds, dragging *)

(* Mouse events are sent as from the window system (FlTest), to a window
   never shown. *)

IMPORT Fl, FlValuators, FlTest, Check;

VAR
  win: Fl.Window;
  slider: FlValuators.Slider;
  vslider: FlValuators.ValueSlider;
  scroll: FlValuators.Scrollbar;
  counter: FlValuators.Counter;
  dial: FlValuators.Dial;
  roller: FlValuators.Roller;
  adjuster: FlValuators.Adjuster;
  vin: FlValuators.ValueInput;
  vout: FlValuators.ValueOutput;
  spinner: FlValuators.Spinner;
  progress: FlValuators.Progress;
  s: ARRAY 32 OF CHAR;
  step: LONGREAL;
  calls: INTEGER;
  used: BOOLEAN;
  i: INTEGER;

PROCEDURE Count(w: Fl.Widget);
BEGIN INC(calls)
END Count;

PROCEDURE Mouse(event, x, y: INTEGER);
  VAR state: SET;
BEGIN
  IF event = Fl.EvRelease THEN state := {} ELSE state := Fl.Button1 END;
  used := FlTest.Mouse(win, event, x, y, Fl.LeftMouse, state, 0)
END Mouse;

PROCEDURE Type(keys: ARRAY OF CHAR);
  VAR i: INTEGER; t: ARRAY 2 OF CHAR;
BEGIN
  i := 0; t[1] := 0X;
  WHILE keys[i] # 0X DO
    t[0] := keys[i]; used := FlTest.Key(Fl.EvKeyDown, ORD(keys[i]), {}, t); INC(i)
  END
END Type;

(* The classes that are another's kind and box, each as FLTK's. *)
PROCEDURE CheckPresets;
  VAR s: FlValuators.Slider; vs: FlValuators.ValueSlider; d: FlValuators.Dial; c: FlValuators.Counter;
BEGIN
  NEW(win); Fl.OpenWindow(win, 500, 400, "presets");
  NEW(s); FlValuators.OpenFillSlider(s, 0, 0, 20, 100, "");
  Check.Check(s.Kind() = FlValuators.VertFillSlider, "OpenFillSlider");
  NEW(s); FlValuators.OpenHorSlider(s, 0, 0, 100, 20, "");
  Check.Check(s.Kind() = FlValuators.HorSlider, "OpenHorSlider");
  NEW(s); FlValuators.OpenHorFillSlider(s, 0, 0, 100, 20, "");
  Check.Check(s.Kind() = FlValuators.HorFillSlider, "OpenHorFillSlider");
  NEW(s); FlValuators.OpenNiceSlider(s, 0, 0, 20, 100, "");
  Check.Check((s.Kind() = FlValuators.VertNiceSlider) & (s.BoxType() = Fl.FlatBox),
    "OpenNiceSlider: FLTK's kind, and its flat box");
  NEW(s); FlValuators.OpenHorNiceSlider(s, 0, 0, 100, 20, "");
  Check.Check((s.Kind() = FlValuators.HorNiceSlider) & (s.BoxType() = Fl.FlatBox),
    "OpenHorNiceSlider: FLTK's kind, and its flat box");
  NEW(vs); FlValuators.OpenHorValueSlider(vs, 0, 0, 100, 20, "");
  Check.Check(vs.Kind() = FlValuators.HorSlider, "OpenHorValueSlider");
  NEW(d); FlValuators.OpenFillDial(d, 0, 0, 50, 50, "");
  Check.Check(d.Kind() = FlValuators.FillDial, "OpenFillDial");
  NEW(d); FlValuators.OpenLineDial(d, 0, 0, 50, 50, "");
  Check.Check(d.Kind() = FlValuators.LineDial, "OpenLineDial");
  NEW(c); FlValuators.OpenSimpleCounter(c, 0, 0, 100, 25, "");
  Check.Check(c.Kind() = FlValuators.SimpleCounter, "OpenSimpleCounter");
  win.End;
  win.Delete
END CheckPresets;

PROCEDURE CheckPositioner;
  VAR p: FlValuators.Positioner;
BEGIN
  NEW(win); Fl.OpenWindow(win, 500, 400, "positioner");
  NEW(p); FlValuators.OpenPositioner(p, 100, 100, 209, 109, "");
  win.End;
  Check.Check((p.XValue() = 0.5D0) & (p.YValue() = 0.5D0) & (p.XMinimum() = 0.0D0)
    & (p.XMaximum() = 1.0D0) & (p.YMinimum() = 0.0D0) & (p.YMaximum() = 1.0D0),
    "a positioner starts in the middle of 0 to 1");
  Check.Check(p.BoxType() = Fl.DownBox, "with a down box, not the no box FLTK's header says");
  p.SetValue(0.25D0, 0.75D0);
  Check.Check((p.XValue() = 0.25D0) & (p.YValue() = 0.75D0), "SetValue");
  p.SetXValue(0.125D0); p.SetYValue(0.625D0);
  Check.Check((p.XValue() = 0.125D0) & (p.YValue() = 0.625D0), "SetXValue and SetYValue");
  p.SetXBounds(0.0D0, 200.0D0); p.SetYBounds(100.0D0, 200.0D0);
  Check.Check((p.XMaximum() = 200.0D0) & (p.YMinimum() = 100.0D0) & (p.YMaximum() = 200.0D0),
    "the bounds read back");
  p.SetValue(0.0D0, 100.0D0);
  p.action := Count; calls := 0;
  (* FLTK maps x + 4 .. x + w - 5 to the bounds, and calls back as it changes *)
  Mouse(Fl.EvPush, 204, 154);
  Mouse(Fl.EvRelease, 204, 154);
  Check.Check((p.XValue() = 100.0D0) & (p.YValue() = 150.0D0) & (calls > 0),
    "a click sets both values, and calls back");
  p.SetXStep(30.0D0); p.SetYStep(25.0D0);
  Mouse(Fl.EvPush, 164, 124); (* 60 is on a step; 120 rounds up to 125 *)
  Mouse(Fl.EvRelease, 164, 124);
  Check.Check((p.XValue() = 60.0D0) & (p.YValue() = 125.0D0), "the values go to the steps");
  win.Delete
END CheckPositioner;

PROCEDURE CheckClocks;
  VAR out: FlValuators.ClockOutput; c, r: FlValuators.Clock; shown: BOOLEAN; square: INTEGER;
BEGIN
  NEW(win); Fl.OpenWindow(win, 500, 400, "clocks");
  NEW(out); FlValuators.OpenClockOutput(out, 10, 10, 100, 100, "");
  NEW(c); FlValuators.OpenClock(c, 120, 10, 100, 100, "");
  NEW(r); FlValuators.OpenRoundClock(r, 230, 10, 100, 100, "");
  win.End;
  Check.Check(r.BoxType() = Fl.NoBox, "a round clock has no box, unlike a square one");
  out.SetHMS(13, 14, 15);
  Check.Check((out.Hour() = 13) & (out.Minute() = 14) & (out.Second() = 15), "SetHMS");
  Check.Check(out.Time() = 13 * 3600 + 14 * 60 + 15, "SetHMS sets the time to seconds past midnight");
  out.SetTime(4294967295);
  Check.Check(out.Time() = 4294967295, "SetTime keeps the last time FLTK can hold");
  Check.Check(out.Second() = 15, "and works it out (ULONG_MAX on 32 bits, 06:28:15 UTC)");
  out.SetTime(0);
  Check.Check(out.Time() = 0, "and the first");
  Check.Check(out.Shadow(), "a clock starts with a shadow");
  out.SetShadow(FALSE);
  Check.Check(~out.Shadow(), "SetShadow");
  (* a square face reaches the corners, a round one doesn't *)
  out.SetColor(Fl.White);
  shown := FlTest.Capture(out); square := FlTest.Pixel(6, 6); FlTest.Release;
  out.SetKind(FlValuators.RoundClock);
  shown := FlTest.Capture(out);
  Check.Check(FlTest.Pixel(6, 6) # square, "SetKind changes the face");
  FlTest.Release;

  (* a shown clock's timer ticks; it must go with the clock, and valgrind
     would see it run on one deleted *)
  win.Show; shown := Fl.Check();
  win.Delete;
  shown := Fl.Check()
END CheckClocks;

BEGIN
  NEW(win); Fl.OpenWindow(win, 500, 400, "TestValuators");
  NEW(slider); FlValuators.OpenSlider(slider, 10, 10, 200, 20, "");
  NEW(vslider); FlValuators.OpenValueSlider(vslider, 10, 40, 200, 20, "");
  NEW(scroll); FlValuators.OpenScrollbar(scroll, 10, 70, 200, 20, "");
  NEW(counter); FlValuators.OpenCounter(counter, 10, 100, 200, 25, "");
  NEW(dial); FlValuators.OpenDial(dial, 250, 10, 60, 60, "");
  NEW(roller); FlValuators.OpenRoller(roller, 320, 10, 20, 100, "");
  NEW(adjuster); FlValuators.OpenAdjuster(adjuster, 350, 10, 75, 25, "");
  NEW(vin); FlValuators.OpenValueInput(vin, 10, 140, 100, 25, "");
  NEW(vout); FlValuators.OpenValueOutput(vout, 120, 140, 100, 25, "");
  NEW(spinner); FlValuators.OpenSpinner(spinner, 10, 180, 100, 25, "");
  NEW(progress); FlValuators.OpenProgress(progress, 10, 220, 200, 20, "");
  win.End;

  (* a valuator's numbers *)
  Check.Check((slider.Value() = 0.0D0) & (slider.Minimum() = 0.0D0) & (slider.Maximum() = 1.0D0)
    & (slider.Step() = 0.0D0) & (slider.When() = Fl.WhenChanged),
    "a valuator starts at 0, from 0 to 1, with no step, calling back on change");
  slider.SetBounds(0.0D0, 100.0D0); slider.SetValue(25.0D0);
  Check.Check((slider.Value() = 25.0D0) & (slider.Maximum() = 100.0D0), "SetBounds and SetValue");
  slider.SetValue(250.0D0);
  Check.Check(slider.Value() = 250.0D0, "SetValue doesn't clamp");
  slider.SetStep(5.0D0);
  Check.Check((slider.Round(12.0D0) = 10.0D0) & (slider.Clamp(250.0D0) = 100.0D0)
    & (slider.Increment(11.0D0, 3) = 25.0D0) & (slider.Increment(95.0D0, 3) = 110.0D0),
    "Round, Clamp, and Increment, which rounds but doesn't clamp");
  slider.SetPrecision(2); slider.SetValue(1.5D0);
  slider.Format(s);
  (* Stored before it is compared: on 32-bit x86, Fl_Valuator::step()
     computes A/B and returns it in an x87 register, at extended
     precision, where it is not 0.01D0 until rounded to a double. *)
  step := slider.Step();
  Check.Check((step = 0.01D0) & (s = "1.50"), "SetPrecision sets the step, and Format shows its digits");

  (* kinds *)
  Check.Check((slider.Kind() = FlValuators.VertSlider) & (dial.Kind() = FlValuators.NormalDial)
    & (counter.Kind() = FlValuators.NormalCounter) & (roller.Kind() = FlValuators.Vertical),
    "each starts with its kind");
  slider.SetKind(FlValuators.HorSlider);
  Check.Check(slider.Kind() = FlValuators.HorSlider, "SetKind");

  (* dragging a horizontal slider *)
  slider.SetBounds(0.0D0, 100.0D0); slider.SetStep(0.0D0); slider.SetValue(50.0D0);
  slider.action := Count; calls := 0;
  Mouse(Fl.EvPush, 110, 20);
  Mouse(Fl.EvDrag, 209, 20);
  Mouse(Fl.EvRelease, 209, 20);
  Check.Check(used & (slider.Value() = 100.0D0) & (calls > 0),
    "dragging the knob to the right end gives the maximum, with Callbacks");
  Mouse(Fl.EvPush, 110, 20); Mouse(Fl.EvDrag, 10, 20); Mouse(Fl.EvRelease, 10, 20);
  Check.Check(slider.Value() = 0.0D0, "and to the left end the minimum");

  (* a slider's own bounds, which redraws it *)
  slider.ClearDamage;
  slider.SetBounds(0.0D0, 10.0D0);
  Check.Check(slider.Damage() # {}, "SetBounds of a slider asks for a redraw (Fl_Slider::bounds)");
  slider.SetSliderSize(0.25D0); slider.SetSliderBox(Fl.UpBox);
  Check.Check((ABS(slider.SliderSize() - 0.25D0) < 1.0D-6) & (slider.SliderBox() = Fl.UpBox),
    "the knob's size and box read back");

  (* a scrollbar *)
  Check.Check(scroll.Linesize() = 16, "a scrollbar's line size starts at 16");
  scroll.ScrollValue(10, 20, 0, 100);
  Check.Check((scroll.Value() = 10.0D0) & (scroll.Minimum() = 0.0D0) & (scroll.Maximum() = 80.0D0)
    & (ABS(scroll.SliderSize() - 0.2D0) < 1.0D-6),
    "ScrollValue: 20 of 100 lines shown from 10");

  (* a counter's arrows: << < value > >> *)
  counter.SetStep(1.0D0); counter.SetLargeStep(10.0D0); counter.SetValue(0.0D0);
  Mouse(Fl.EvPush, counter.X() + counter.W() - 3, counter.Y() + 10);
  Mouse(Fl.EvRelease, counter.X() + counter.W() - 3, counter.Y() + 10);
  Check.Check(counter.Value() = 10.0D0, "a counter's outer right arrow adds the large step");
  Mouse(Fl.EvPush, counter.X() + 3, counter.Y() + 10);
  Mouse(Fl.EvRelease, counter.X() + 3, counter.Y() + 10);
  Check.Check(counter.Value() = 0.0D0, "and its outer left arrow subtracts it");

  (* the others' settings *)
  Check.Check((dial.Angle1() = 45) & (dial.Angle2() = 315), "a dial's angles start at 45 and 315");
  dial.SetAngles(0, 360);
  Check.Check((dial.Angle1() = 0) & (dial.Angle2() = 360), "SetAngles");
  Check.Check(adjuster.Soft() & ~vin.Soft() & ~vout.Soft(),
    "an adjuster starts soft, a value input or output not");
  vout.SetSoft(TRUE);
  Check.Check(vout.Soft(), "SetSoft");
  vin.SetTextSize(20); vslider.SetTextColor(Fl.Red); counter.SetTextFont(Fl.Courier);
  Check.Check((vin.TextSize() = 20) & (vslider.TextColor() = Fl.Red) & (counter.TextFont() = Fl.Courier),
    "the text settings of a value input, value slider and counter");

  (* typing into a value input: its field is a widget FLTK made *)
  vin.SetBounds(0.0D0, 100.0D0); vin.action := Count; calls := 0;
  Check.Check(vin.TakeFocus() & (Fl.Focus() = NIL), "a value input passes the focus to its field");
  Check.Check(Fl.HasFocus(), "HasFocus: a widget FLTK made has it");
  Type("42");
  Check.Check((vin.Value() = 42.0D0) & (calls > 0), "typing into it sets its value, with Callbacks");

  (* a spinner *)
  Check.Check((spinner.Value() = 1.0D0) & (spinner.Minimum() = 1.0D0) & (spinner.Maximum() = 100.0D0)
    & (spinner.Step() = 1.0D0) & spinner.Wrap() & (spinner.Kind() = FlValuators.IntSpinner),
    "a spinner starts at 1, from 1 to 100 in steps of 1, wrapping, whole");
  spinner.SetKind(FlValuators.FloatSpinner); spinner.SetBounds(0.0D0, 1.0D0);
  spinner.SetStep(0.1D0); spinner.SetValue(0.5D0); spinner.SetWrap(FALSE);
  Check.Check((spinner.Kind() = FlValuators.FloatSpinner) & (spinner.Value() = 0.5D0)
    & (spinner.Maximum() = 1.0D0) & (spinner.Step() = 0.1D0) & ~spinner.Wrap(),
    "its settings read back");
  spinner.SetColor(Fl.Yellow); spinner.SetSelectionColor(Fl.Green); spinner.SetTextSize(18);
  Check.Check((spinner.Color() = Fl.Yellow) & (spinner.SelectionColor() = Fl.Green)
    & (spinner.TextSize() = 18), "its colors and text size, its field's");
  Check.Check(spinner.Children() = 3, "it is a group of three widgets FLTK made");
  FOR i := 0 TO 2 DO
    Check.Check(spinner.Child(i) = NIL, "which have no Oberon object")
  END;

  (* a progress bar *)
  Check.Check((progress.Value() = 0.0D0) & (progress.Minimum() = 0.0D0) & (progress.Maximum() = 100.0D0),
    "a progress bar starts at 0, from 0 to 100");
  progress.SetBounds(0.0D0, 10.0D0); progress.SetValue(2.5D0);
  Check.Check((progress.Value() = 2.5D0) & (progress.Maximum() = 10.0D0), "its value and bounds");

  win.Delete;
  CheckPresets;
  CheckPositioner;
  CheckClocks;
  Check.Check((Fl.OpenWidgets() = 0) & (Fl.PendingTimers() = 0), "every widget deleted, no timer pending");
  Check.Summary
END TestValuators.
