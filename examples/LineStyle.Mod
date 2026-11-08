MODULE LineStyle; (* FLTK's test/line_style.cxx in Oberon-2 *)

(* LineStyle and LineStyleDashes: a rectangle and a line through four
   points, drawn in the color, style, cap, join, width and dash pattern
   the controls choose, and with "Line" a one-pixel black line over
   them. *)

IMPORT Fl, FlDraw, FlValuators, FlMenus, FlButtons;

TYPE
  TestBox = POINTER TO RECORD (Fl.DoubleWindowDesc) END;
  ValueSlider = POINTER TO RECORD (FlValuators.ValueSliderDesc) END;
  Slider = POINTER TO RECORD (FlValuators.SliderDesc) END;
  Choice = POINTER TO RECORD (FlMenus.ChoiceDesc) END;
  CheckButton = POINTER TO RECORD (FlButtons.CheckButtonDesc) END;

VAR
  form: Fl.DoubleWindow;
  sliders: ARRAY 5 OF ValueSlider;  (* R, G, B, width and move *)
  dashSliders: ARRAY 4 OF Slider;
  choice: ARRAY 3 OF Choice;
  drawLine: CheckButton;
  test: TestBox;
  styles, caps, joins: ARRAY 5 OF INTEGER;  (* each choice's items' arguments *)

PROCEDURE (w: TestBox) Draw*;
  VAR dashes: ARRAY 5 OF INTEGER; i, n, move: INTEGER;
BEGIN
  w.Draw^;
  FlDraw.SetRGB(SHORT(ENTIER(sliders[0].Value())), SHORT(ENTIER(sliders[1].Value())),
    SHORT(ENTIER(sliders[2].Value())));
  FOR i := 0 TO 3 DO dashes[i] := SHORT(ENTIER(dashSliders[i].Value())) END;
  dashes[4] := 0;
  FlDraw.LineStyleDashes(styles[choice[0].Value()] + caps[choice[1].Value()]
    + joins[choice[2].Value()], SHORT(ENTIER(sliders[3].Value())), dashes);

  (* the rectangle and line, then the one-pixel line if enabled *)
  IF drawLine.Value() THEN n := 2 ELSE n := 1 END;
  FOR i := 1 TO n DO
    move := SHORT(ENTIER(sliders[4].Value()));
    FlDraw.Rect(move, move, w.W() - 20, w.H() - 20);
    FlDraw.BeginLine;
    FlDraw.Vertex(move + 25, move + 25);
    FlDraw.Vertex(w.W() - 45 + move, w.H() - 45 + move);
    FlDraw.Vertex(w.W() - 50 + move, move + 25);
    FlDraw.Vertex(move + 25, w.H() DIV 2 - 10 + move);
    FlDraw.EndLine;
    (* the line style must be reset when done *)
    FlDraw.LineStyle(FlDraw.Solid, 0);
    FlDraw.SetColor(Fl.Black)
  END
END Draw;

PROCEDURE (s: ValueSlider) Callback*;
BEGIN test.Redraw
END Callback;

PROCEDURE (s: Slider) Callback*;
BEGIN test.Redraw
END Callback;

PROCEDURE (c: Choice) Callback*;
BEGIN test.Redraw
END Callback;

PROCEDURE (b: CheckButton) Callback*;
BEGIN test.Redraw
END Callback;

PROCEDURE OpenValueSlider(i, y: INTEGER; label-: ARRAY OF CHAR);
BEGIN
  NEW(sliders[i]); FlValuators.OpenValueSlider(sliders[i], 280, y, 180, 20, label)
END OpenValueSlider;

PROCEDURE OpenChoice(i, y: INTEGER; label-: ARRAY OF CHAR);
BEGIN
  NEW(choice[i]); FlMenus.OpenChoice(choice[i], 280, y, 180, 20, label)
END OpenChoice;

PROCEDURE Item(c: Choice; label-: ARRAY OF CHAR; VAR args: ARRAY OF INTEGER; arg: INTEGER);
  VAR i: INTEGER;
BEGIN
  i := c.Add(label, 0, {}, NIL, {}); args[i] := arg
END Item;

PROCEDURE MakeForm;
  VAR i: INTEGER; box: Fl.Box; ok: BOOLEAN;
BEGIN
  NEW(form); Fl.OpenDoubleWindow(form, 500, 250, "fl_line_style() test");
  OpenValueSlider(0, 10, "R"); sliders[0].SetBounds(0, 255);
  OpenValueSlider(1, 30, "G"); sliders[1].SetBounds(0, 255);
  OpenValueSlider(2, 50, "B"); sliders[2].SetBounds(0, 255);
  OpenChoice(0, 70, "Style");
  Item(choice[0], "FL_SOLID", styles, FlDraw.Solid);
  Item(choice[0], "FL_DASH", styles, FlDraw.Dash);
  Item(choice[0], "FL_DOT", styles, FlDraw.Dot);
  Item(choice[0], "FL_DASHDOT", styles, FlDraw.DashDot);
  Item(choice[0], "FL_DASHDOTDOT", styles, FlDraw.DashDotDot);
  OpenChoice(1, 90, "Cap");
  Item(choice[1], "default", caps, 0);
  Item(choice[1], "FL_CAP_FLAT", caps, FlDraw.CapFlat);
  Item(choice[1], "FL_CAP_ROUND", caps, FlDraw.CapRound);
  Item(choice[1], "FL_CAP_SQUARE", caps, FlDraw.CapSquare);
  OpenChoice(2, 110, "Join");
  Item(choice[2], "default", joins, 0);
  Item(choice[2], "FL_JOIN_MITER", joins, FlDraw.JoinMiter);
  Item(choice[2], "FL_JOIN_ROUND", joins, FlDraw.JoinRound);
  Item(choice[2], "FL_JOIN_BEVEL", joins, FlDraw.JoinBevel);
  OpenValueSlider(3, 130, "Width"); sliders[3].SetBounds(0, 20);
  OpenValueSlider(4, 150, "Move"); sliders[4].SetBounds(-10, 20);
  NEW(drawLine); FlButtons.OpenCheckButton(drawLine, 280, 170, 20, 20, "&Line");
  drawLine.SetAlign(Fl.AlignLeft);
  NEW(box); Fl.OpenBox(box, 305, 170, 160, 20, "add a 1-pixel black line");
  NEW(dashSliders[0]); FlValuators.OpenSlider(dashSliders[0], 200, 210, 70, 20, "Dash");
  dashSliders[0].SetAlign(Fl.AlignTopLeft);
  NEW(dashSliders[1]); FlValuators.OpenSlider(dashSliders[1], 270, 210, 70, 20, "");
  NEW(dashSliders[2]); FlValuators.OpenSlider(dashSliders[2], 340, 210, 70, 20, "");
  NEW(dashSliders[3]); FlValuators.OpenSlider(dashSliders[3], 410, 210, 70, 20, "");
  FOR i := 0 TO 4 DO
    sliders[i].SetKind(FlValuators.HorSlider); sliders[i].SetAlign(Fl.AlignLeft);
    sliders[i].SetStep(1)
  END;
  FOR i := 0 TO 3 DO
    dashSliders[i].SetBounds(0, 40);
    dashSliders[i].SetKind(FlValuators.HorSlider); dashSliders[i].SetStep(1)
  END;
  sliders[0].SetValue(255);  (* R *)
  sliders[1].SetValue(100);  (* G *)
  sliders[2].SetValue(100);  (* B *)
  sliders[4].SetValue(10);   (* move the line's coordinates *)
  FOR i := 0 TO 2 DO ok := choice[i].SetValue(0) END;
  NEW(test); Fl.OpenDoubleWindowAt(test, 0, 0, 200, 200, "");
  test.End;
  form.SetResizable(test);
  form.End
END MakeForm;

BEGIN
  MakeForm;
  form.ShowArgs;
  Fl.Run
END LineStyle.
