MODULE Output; (* FLTK's test/output.cxx in Oberon-2 *)

(* An output and a multiline output showing the text of the input below
   them, as it changes, in the font and size the two sliders choose. *)

IMPORT Fl, FlInputs, FlValuators;

VAR
  window: Fl.DoubleWindow;
  input: FlInputs.Input;
  sizes, fonts: FlValuators.ValueSlider;
  text: FlInputs.Output;
  text2: FlInputs.MultilineOutput;
  s: ARRAY 256 OF CHAR;

(* s with each "|" a line feed *)
PROCEDURE Lines(VAR s: ARRAY OF CHAR);
VAR i: INTEGER;
BEGIN
  i := 0; WHILE s[i] # 0X DO IF s[i] = "|" THEN s[i] := 0AX END; INC(i) END
END Lines;

PROCEDURE FontCallback(w: Fl.Widget);
BEGIN
  text.SetTextFont(SHORT(ENTIER(fonts.Value()))); text.Redraw;
  text2.SetTextFont(SHORT(ENTIER(fonts.Value()))); text2.Redraw
END FontCallback;

PROCEDURE SizeCallback(w: Fl.Widget);
BEGIN
  text.SetTextSize(SHORT(ENTIER(sizes.Value()))); text.Redraw;
  text2.SetTextSize(SHORT(ENTIER(sizes.Value()))); text2.Redraw
END SizeCallback;

PROCEDURE InputCallback(w: Fl.Widget);
VAR s: ARRAY 1024 OF CHAR;
BEGIN
  input.Value(s); text.SetValue(s); text2.SetValue(s)
END InputCallback;

BEGIN
  NEW(window); Fl.OpenDoubleWindow(window, 400, 400, "");

  NEW(input); FlInputs.OpenInput(input, 50, 375, 350, 25, "");
  (* FLTK's static_value, which keeps its pointer; a copy looks the same *)
  s := "The quick brown fox|jumped over|the lazy dog."; Lines(s);
  input.SetValue(s);
  input.SetWhen(Fl.WhenChanged);
  input.action := InputCallback;

  NEW(sizes); FlValuators.OpenHorValueSlider(sizes, 50, 350, 350, 25, "Size");
  sizes.SetAlign(Fl.AlignLeft);
  sizes.SetBounds(1, 64);
  sizes.SetStep(1);
  sizes.SetValue(14);
  sizes.action := SizeCallback;

  NEW(fonts); FlValuators.OpenHorValueSlider(fonts, 50, 325, 350, 25, "Font");
  fonts.SetAlign(Fl.AlignLeft);
  fonts.SetBounds(0, 15);
  fonts.SetStep(1);
  fonts.SetValue(0);
  fonts.action := FontCallback;

  NEW(text2); FlInputs.OpenMultilineOutput(text2, 100, 150, 200, 100, "Fl_Multiline_Output");
  text2.SetValue(s);
  text2.SetAlign(Fl.AlignBottom);
  text2.SetTooltip("This is an Fl_Multiline_Output widget.");
  window.SetResizable(text2);

  NEW(text); FlInputs.OpenOutput(text, 100, 90, 200, 30, "Fl_Output");
  text.SetValue(s);
  text.SetAlign(Fl.AlignBottom);
  text.SetTooltip("This is an Fl_Output widget.");

  window.End;
  window.ShowArgs;
  Fl.Run
END Output.
