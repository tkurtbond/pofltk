MODULE UtUnicode; (* FLTK's test/unittest_unicode.cxx in Oberon-2 *)

IMPORT Fl, FlText, FlInputs, FlMenus, FlValuators, Ut;

CONST
  Label* = "Unicode Boxes";
  Box = "╳╳ ██ ▏▏┏━━┓ ╔══╗ ╔═╦═╗ ██████|╳╳ ██ ▏▏┃  ┃ ║  ║ ╠═╬═╣ ██  ██|╳╳ ██ ▏▏┗━━┛ ╚══╝ ╚═╩═╝ ██████||underbar: ______| overbar: ‾‾‾‾‾‾||underbar/overbar alternate:||___‾‾‾___‾‾‾___‾‾‾___‾‾‾___|‾‾‾___‾‾‾___‾‾‾___‾‾‾___‾‾‾|";
  Help = "In this test, ideally the box's lines should all be touching without white space between. Underbar and overbars should both be visible and not touching. All the above should be unaffected by different font sizes and font settings.";

VAR
  (* the page's widgets: there is one page *)
  page: Fl.Group;
  display: FlText.TextDisplay;
  input: FlInputs.MultilineInput;
  face: FlMenus.Choice;
  size: FlValuators.ValueSlider;

(* Redraws the window, as FLTK's redraws the page's parent. *)
PROCEDURE Redraw;
  VAR g: Fl.Group;
BEGIN g := page.Parent(); IF g # NIL THEN g.Redraw END
END Redraw;

PROCEDURE FaceChosen(w: Fl.Widget);
BEGIN
  CASE face.Value() OF
    0: display.SetTextFont(Fl.Courier)
  | 1: display.SetTextFont(Fl.Screen)
  ELSE
  END;
  Redraw
END FaceChosen;

PROCEDURE SizeChosen(w: Fl.Widget);
  VAR n: INTEGER;
BEGIN
  n := SHORT(ENTIER(size.Value()));
  display.SetTextSize(n);
  input.SetTextSize(n);
  input.Select(0, 0);  (* keeps it scrolled to the top *)
  Redraw
END SizeChosen;

PROCEDURE Create*(): Fl.Widget;
  VAR buffer: FlText.TextBuffer; text: ARRAY 1024 OF CHAR;
BEGIN
  NEW(page); Fl.OpenGroup(page, Ut.X, Ut.Y, Ut.W, Ut.H, "");
  text := Box; Ut.Lines(text);
  NEW(buffer); FlText.OpenBuffer(buffer); buffer.SetText(text);
  NEW(display);
  FlText.OpenTextDisplay(display, Ut.X + 5, Ut.Y + 20, 250, 250, "Fl_Text_Display");
  display.SetTextFont(Fl.Courier);
  display.SetBuffer(buffer); buffer.Close;
  display.SetTooltip(Help);
  NEW(input);
  FlInputs.OpenMultilineInput(input, Ut.X + 250 + 15, Ut.Y + 20, 250, 250, "Fl_Multiline_Input");
  input.SetAlign(Fl.AlignCenter + Fl.AlignTop);
  input.SetTextFont(Fl.Courier);
  input.SetValue(text);
  input.SetTooltip(Help);
  (* the fonts must be monospaced to line up *)
  NEW(face); FlMenus.OpenChoice(face, Ut.X + 150, Ut.Y + Ut.H - 80, 200, 25, "Font face");
  IF face.Add("FL_COURIER", 0, {}, NIL, {}) = 0 THEN END;
  IF face.Add("FL_SCREEN", 0, {}, NIL, {}) = 0 THEN END;
  IF face.SetValue(0) THEN END;
  face.action := FaceChosen;
  NEW(size);
  FlValuators.OpenHorValueSlider(size, Ut.X + 150, Ut.Y + Ut.H - 50, 200, 25, "Font size");
  size.SetAlign(Fl.AlignLeft);
  size.SetBounds(1, 50); size.SetStep(1); size.SetValue(14);
  size.action := SizeChosen;
  page.End;
  RETURN page
END Create;

END UtUnicode.
