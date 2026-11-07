MODULE Valuators; (* FLTK's test/valuators.cxx in Oberon-2 *)

(* Every valuator class in each of its kinds, with the terminal showing
   each callback's name and value. FLTK's program is FLUID's
   (valuators.fl); it keeps each widget's name in its user data, which
   this port keeps in a table instead. The value output's name, like
   FLTK's, is "???": FLTK's program gives it to the output's group. *)

IMPORT SYSTEM, Fl, FlValuators, FlTerminal, RealDigits, OutStr;

CONST
  Esc = 1BX;
  Max = 32;

VAR
  window: Fl.DoubleWindow;
  tty: FlTerminal.Terminal;
  named: ARRAY Max OF Fl.Widget;
  names: ARRAY Max OF ARRAY 40 OF CHAR;
  count: INTEGER;
  g: Fl.Group;
  box: Fl.Box;
  slider: FlValuators.Slider;
  vslider: FlValuators.ValueSlider;
  vinput: FlValuators.ValueInput;
  voutput: FlValuators.ValueOutput;
  scroll: FlValuators.Scrollbar;
  adjuster: FlValuators.Adjuster;
  counter: FlValuators.Counter;
  spinner: FlValuators.Spinner;
  dial: FlValuators.Dial;
  roller: FlValuators.Roller;
  s: ARRAY 128 OF CHAR;

(* "-" if v is negative, -0 too, as printf writes it. *)
PROCEDURE Sign(VAR v: LONGREAL; VAR s: ARRAY OF CHAR);
BEGIN
  IF SYSTEM.VAL(HUGEINT, v) < 0 THEN OutStr.Char("-", s); v := -v END
END Sign;

(* Appends v as "%g" writes it: six significant digits, trailing zeros
   dropped, in exponential form for an exponent below -4 or above 5. *)
PROCEDURE General(v: LONGREAL; VAR s: ARRAY OF CHAR);
  VAR d: ARRAY 8 OF CHAR; e, n, i: INTEGER;
BEGIN
  Sign(v, s);
  IF v = 0.0D0 THEN OutStr.Char("0", s); RETURN END;
  RealDigits.Digits(v, 6, d, e);
  n := 6; WHILE (n > 1) & (d[n - 1] = "0") DO DEC(n) END;   (* significant digits *)
  IF (e < -4) OR (e >= 6) THEN
    OutStr.Char(d[0], s);
    IF n > 1 THEN OutStr.Char(".", s); FOR i := 1 TO n - 1 DO OutStr.Char(d[i], s) END END;
    OutStr.Char("e", s);
    IF e < 0 THEN OutStr.Char("-", s); e := -e ELSE OutStr.Char("+", s) END;
    IF e < 10 THEN OutStr.Char("0", s) END;
    OutStr.Int(e, 0, s)
  ELSIF e < 0 THEN
    OutStr.String("0.", s);
    FOR i := 1 TO -e - 1 DO OutStr.Char("0", s) END;
    FOR i := 0 TO n - 1 DO OutStr.Char(d[i], s) END
  ELSE
    FOR i := 0 TO e DO
      IF i < n THEN OutStr.Char(d[i], s) ELSE OutStr.Char("0", s) END
    END;
    IF n > e + 1 THEN
      OutStr.Char(".", s);
      FOR i := e + 1 TO n - 1 DO OutStr.Char(d[i], s) END
    END
  END
END General;

(* The line FLTK's callbacks print, for the widget o showing v. *)
PROCEDURE Report(o: Fl.Widget; v: LONGREAL);
VAR s: ARRAY 128 OF CHAR; i: INTEGER;
BEGIN
  s := "callback(): ";
  i := 0; WHILE (i < count) & (named[i] # o) DO INC(i) END;
  IF i < count THEN OutStr.String(names[i], s) ELSE OutStr.String("???", s) END;
  OutStr.String(" value() = ", s);
  OutStr.Char(Esc, s); OutStr.String("[1m", s);
  General(v, s);
  OutStr.Char(Esc, s); OutStr.String("[0m", s); OutStr.Char(0AX, s);
  tty.Append(s)
END Report;

PROCEDURE Callback(o: Fl.Widget);
BEGIN Report(o, o(FlValuators.Valuator).Value())
END Callback;

(* A spinner isn't a valuator. *)
PROCEDURE CallbackSpinner(o: Fl.Widget);
BEGIN Report(o, o(FlValuators.Spinner).Value())
END CallbackSpinner;

(* Gives w its name, its callback, and the label size all these have. *)
PROCEDURE Name(w: Fl.Widget; name-: ARRAY OF CHAR);
BEGIN
  named[count] := w; COPY(name, names[count]); INC(count);
  w.action := Callback;
  w.SetLabelSize(8)
END Name;

PROCEDURE Group(x, y, w, h: INTEGER; label-: ARRAY OF CHAR; align: SET);
BEGIN
  NEW(g); Fl.OpenGroup(g, x, y, w, h, label);
  g.SetBoxType(Fl.EngravedBox);
  g.SetLabelFont(1);
  g.SetAlign(align + Fl.AlignInside)
END Group;

PROCEDURE EndGroup;
BEGIN g.End
END EndGroup;

(* A slider of kind k, named name; a nice one has a flat green box. *)
PROCEDURE Slider(x, y, w, h: INTEGER; label-: ARRAY OF CHAR; k: INTEGER; name-: ARRAY OF CHAR);
BEGIN
  NEW(slider); FlValuators.OpenSlider(slider, x, y, w, h, label);
  slider.SetKind(k);
  IF k >= FlValuators.VertNiceSlider THEN slider.SetBoxType(Fl.FlatBox); slider.SetColor(10) END;
  slider.SetSelectionColor(1);
  Name(slider, name)
END Slider;

PROCEDURE ValueSlider(x, y, w, h: INTEGER; label-: ARRAY OF CHAR; k: INTEGER; name-: ARRAY OF CHAR);
BEGIN
  NEW(vslider); FlValuators.OpenValueSlider(vslider, x, y, w, h, label);
  vslider.SetKind(k);
  IF k >= FlValuators.VertNiceSlider THEN vslider.SetBoxType(Fl.FlatBox); vslider.SetColor(10) END;
  vslider.SetSelectionColor(1);
  Name(vslider, name)
END ValueSlider;

PROCEDURE Scrollbar(x, y, w, h: INTEGER; label-: ARRAY OF CHAR; k: INTEGER; tip-, name-: ARRAY OF CHAR);
BEGIN
  NEW(scroll); FlValuators.OpenScrollbar(scroll, x, y, w, h, label);
  scroll.SetTooltip(tip);
  scroll.SetKind(k);
  Name(scroll, name);
  scroll.SetBounds(0.0D0, 100.0D0);
  scroll.SetValue(20.0D0)
END Scrollbar;

PROCEDURE Adjuster(x, y, w, h: INTEGER; label-: ARRAY OF CHAR; tip-, name-: ARRAY OF CHAR);
BEGIN
  NEW(adjuster); FlValuators.OpenAdjuster(adjuster, x, y, w, h, label);
  adjuster.SetTooltip(tip);
  Name(adjuster, name)
END Adjuster;

PROCEDURE Counter(y: INTEGER; label-: ARRAY OF CHAR; k: INTEGER; tip-, name-: ARRAY OF CHAR);
BEGIN
  NEW(counter); FlValuators.OpenCounter(counter, 310, y, 110, 25, label);
  counter.SetTooltip(tip);
  counter.SetKind(k);
  Name(counter, name)
END Counter;

PROCEDURE Spinner(y: INTEGER; label-: ARRAY OF CHAR; k: INTEGER; min, max, step, v: LONGREAL; name-: ARRAY OF CHAR);
BEGIN
  NEW(spinner); FlValuators.OpenSpinner(spinner, 465, y, 80, 24, label);
  spinner.SetKind(k);
  Name(spinner, name);
  spinner.action := CallbackSpinner;
  spinner.SetBounds(min, max);
  spinner.SetStep(step);
  spinner.SetValue(v);
  spinner.SetAlign(Fl.AlignBottom)
END Spinner;

PROCEDURE Dial(x: INTEGER; label-: ARRAY OF CHAR; k: INTEGER; v: LONGREAL; tip-, name-: ARRAY OF CHAR);
BEGIN
  NEW(dial); FlValuators.OpenDial(dial, x, 295, 65, 65, label);
  dial.SetTooltip(tip);
  dial.SetKind(k);
  dial.SetColor(10);
  dial.SetSelectionColor(1);
  Name(dial, name);
  dial.SetValue(v)
END Dial;

PROCEDURE Roller(x, y, w, h: INTEGER; label-: ARRAY OF CHAR; k: INTEGER; tip-, name-: ARRAY OF CHAR);
BEGIN
  NEW(roller); FlValuators.OpenRoller(roller, x, y, w, h, label);
  roller.SetTooltip(tip);
  roller.SetKind(k);
  Name(roller, name)
END Roller;

BEGIN
  count := 0;
  NEW(window); Fl.OpenDoubleWindow(window, 580, 640, "Valuator classes, showing values for type()");
  window.SetColor(43);
  window.SetSelectionColor(43);

  Group(10, 10, 280, 210, "Fl_Slider", Fl.AlignTop);
    Slider(30, 45, 20, 145, "0", FlValuators.VertSlider, "Fl_Slider FL_VERT_SLIDER");
    slider.SetTooltip("Vertical Slider");
    slider.SetAlign(Fl.AlignTop);
    Slider(70, 55, 20, 145, "FL_VERT_FILL_SLIDER", FlValuators.VertFillSlider, "Fl_Slider FL_VERT_FILL_SLIDER");
    Slider(105, 45, 20, 145, "FL_VERT_NICE_SLIDER", FlValuators.VertNiceSlider, "Fl_Slider FL_VERT_NICE_SLIDER");
    slider.SetAlign(Fl.AlignTop);
    Slider(140, 80, 130, 20, "FL_HORIZONTAL", FlValuators.HorSlider, "Fl_Slider FL_HORIZONTAL");
    Slider(140, 120, 130, 20, "FL_HOR_FILL_SLIDER", FlValuators.HorFillSlider, "Fl_Slider FL_HOR_FILL_SLIDER");
    Slider(140, 160, 130, 20, "FL_HOR_NICE_SLIDER", FlValuators.HorNiceSlider, "Fl_Slider FL_HOR_NICE_SLIDER");
  EndGroup;

  Group(10, 230, 280, 210, "Fl_Value_Slider", Fl.AlignTop);
    ValueSlider(30, 260, 30, 145, "0", FlValuators.VertSlider, "FL_VERT_SLIDER");
    vslider.SetTooltip("Value Slider");
    vslider.SetAlign(Fl.AlignTop);
    ValueSlider(70, 275, 30, 140, "FL_VERT_FILL_SLIDER", FlValuators.VertFillSlider, "Fl_Value_Slider FL_VERT_FILL_SLIDER");
    ValueSlider(110, 260, 20, 145, "FL_VERT_NICE_SLIDER", FlValuators.VertNiceSlider, "Fl_Value_Slider FL_VERT_NICE_SLIDER");
    vslider.SetAlign(Fl.AlignTop);
    ValueSlider(140, 290, 130, 20, "FL_HOR_SLIDER", FlValuators.HorSlider, "Fl_Value_Slider FL_HOR_SLIDER");
    ValueSlider(140, 330, 130, 20, "FL_HOR_FILL_SLIDER", FlValuators.HorFillSlider, "Fl_Value_Slider FL_HOR_FILL_SLIDER");
    ValueSlider(140, 370, 130, 20, "FL_HOR_NICE_SLIDER", FlValuators.HorNiceSlider, "Fl_Value_Slider FL_HOR_NICE_SLIDER");
  EndGroup;

  Group(10, 450, 135, 50, "Fl_Value_Input", Fl.AlignTop);
    NEW(vinput); FlValuators.OpenValueInput(vinput, 30, 470, 105, 25, "0");
    vinput.SetTooltip("Value Input");
    Name(vinput, "Fl_Value_Input");
    vinput.SetBounds(0.0D0, 100.0D0);
    vinput.SetStep(0.1D0);
  EndGroup;

  Group(155, 450, 135, 50, "Fl_Value_Output", Fl.AlignTop);
    NEW(voutput); FlValuators.OpenValueOutput(voutput, 170, 470, 105, 25, "0");
    voutput.SetTooltip("Value Output");
    voutput.SetLabelSize(8);
    voutput.SetBounds(0.0D0, 100.0D0);
    voutput.SetStep(0.1D0);
    voutput.action := Callback;   (* unnamed: "???" *)
  EndGroup;

  Group(300, 10, 130, 120, "   Fl_Scrollbar", Fl.AlignTopLeft);
    Scrollbar(305, 55, 95, 20, "FL_HORIZONTAL", FlValuators.Horizontal, "Horizontal Scrollbar", "Fl_Scrollbar FL_HORIZONTAL");
    Scrollbar(405, 30, 20, 90, "FL_VERTICAL (0) ->", FlValuators.Vertical, "Vertical Scrollbar", "Fl_Scrollbar FL_VERTICAL");
    scroll.SetAlign(Fl.AlignLeftBottom);
  EndGroup;

  Group(440, 10, 130, 120, "Fl_Adjuster", Fl.AlignTop);
    Adjuster(450, 60, 75, 25, "w()>h()", "Horizontal Adjuster", "Fl_Adjuster w()>h()");
    Adjuster(530, 35, 25, 75, "w()<h()", "Vertical Adjuster", "Fl_Adjuster w()<h()");
  EndGroup;

  Group(300, 140, 130, 120, "Fl_Counter", Fl.AlignTop);
    Counter(175, "0", FlValuators.NormalCounter, "Standard Counter", "Fl_Counter");
    Counter(215, "FL_SIMPLE_COUNTER", FlValuators.SimpleCounter, "Simple Counter", "Fl_Counter FL_SIMPLE_COUNTER");
  EndGroup;

  Group(440, 140, 130, 120, "Fl_Spinner", Fl.AlignTop);
    Spinner(176, "FL_INT_INPUT", FlValuators.IntSpinner, -30.0D0, 30.0D0, 2.0D0, 5.0D0, "Fl_Spinner FL_INT_INPUT");
    Spinner(216, "FL_FLOAT_INPUT", FlValuators.FloatSpinner, 0.0D0, 1.0D0, 0.01D0, 0.05D0, "Fl_Spinner FL_FLOAT_INPUT");
    spinner.SetWrap(FALSE);
  EndGroup;

  Group(300, 270, 270, 105, "Fl_Dial", Fl.AlignTop);
    Dial(320, "0", FlValuators.NormalDial, 0.5D0, "Standard Dial", "Fl_Dial");
    dial.SetAngles(0, 315);
    Dial(400, "FL_LINE_DIAL", FlValuators.LineDial, 0.5D0, "Line Dial", "Fl_Dial FL_LINE_DIAL");
    Dial(480, "FL_FILL_DIAL", FlValuators.FillDial, 1.0D0, "Fill Dial", "Fl_Dial FL_FILL_DIAL");
    dial.SetAngles(0, 360);
  EndGroup;

  Group(300, 385, 150, 115, "Fl_Roller", Fl.AlignTop);
    Roller(315, 390, 20, 95, "0", FlValuators.Vertical, "Vertical Roller", "Fl_Roller FL_VERTICAL");
    Roller(345, 430, 90, 20, "FL_HORIZONTAL", FlValuators.Horizontal, "Horizontal Roller", "Fl_Roller FL_HORIZONTAL");
  EndGroup;

  s := "Some widgets have color(FL_GREEN) and color2(FL_RED) to show the areas these effect.";
  NEW(box); Fl.OpenBox(box, 460, 385, 110, 115, s);
  box.SetBoxType(Fl.BorderFrame);
  box.SetColor(Fl.ForegroundColor);
  box.SetSelectionColor(Fl.ForegroundColor);
  box.SetLabelSize(11);
  box.SetAlign(Fl.AlignWrap);

  NEW(tty); FlTerminal.OpenTerminal(tty, 10, 513, 560, 117, "");
  tty.SetAnsi(TRUE);

  window.End;
  window.ShowArgs;
  Fl.Run
END Valuators.
