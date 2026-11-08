MODULE Label; (* FLTK's test/label.cxx in Oberon-2 *)

(* A label's alignments, fonts, sizes and types, with and without an
   image, and its margins and the gap between image and text: each
   control changes the frame's label at once. *)

IMPORT Fl, FlButtons, FlImages, FlInputs, FlMenus, FlValuators;

VAR
  imageb, imageovertextb, imagenexttotextb, imagebackdropb: FlButtons.ToggleButton;
  leftb, rightb, topb, bottomb, insideb, clipb, wrapb: FlButtons.ToggleButton;
  text: Fl.Box;
  input: FlInputs.Input;
  fonts, sizes, hMargin, vMargin, imgSpacing: FlValuators.ValueSlider;
  window: Fl.DoubleWindow;
  img: FlImages.Image;
  margin: Fl.Box;
  g: Fl.Group;
  c: FlMenus.Choice;
  n: INTEGER;
  value: ARRAY 1024 OF CHAR;

(* FLTK's test/pixmaps/blast.xpm. *)
PROCEDURE Blast(i: FlImages.Image);
  VAR x: ARRAY 65, 33 OF CHAR;
BEGIN
  x[0] := "32 32 32 1";
  x[1] := "  c #905518";
  x[2] := ". c #9F580E";
  x[3] := "+ c #A36526";
  x[4] := "@ c #AF6519";
  x[5] := "# c #BF7429";
  x[6] := "$ c #C77622";
  x[7] := "% c #B67B3C";
  x[8] := "& c #D07518";
  x[9] := "* c #D88836";
  x[10] := "= c #E48628";
  x[11] := "- c #F28514";
  x[12] := "; c #FF951C";
  x[13] := "> c #FA9835";
  x[14] := ", c #FF982A";
  x[15] := "' c #F49F48";
  x[16] := ") c #FFA82D";
  x[17] := "! c #FFA93F";
  x[18] := "~ c #FFBA1C";
  x[19] := "{ c #FFB936";
  x[20] := "] c #FFBA4C";
  x[21] := "^ c #FFCA42";
  x[22] := "/ c #FFD329";
  x[23] := "( c #FFCF5E";
  x[24] := "_ c #FFD94C";
  x[25] := ": c #FFE946";
  x[26] := "< c #FFFB3E";
  x[27] := "[ c #FFFB55";
  x[28] := "} c #FEFC69";
  x[29] := "| c #FFFE82";
  x[30] := "1 c #FFFFA3";
  x[31] := "2 c #FEFFCB";
  x[32] := "3 c #FEFFFC";
  x[33] := "     % .  ....@@@#@@.+.+++%     ";
  x[34] := "  %%++++.....@######@@@@.++ %   ";
  x[35] := " %%% %++@@.@@@#$$#######@++++%% ";
  x[36] := " %%+%+####@@$&&=*=&&$$####@++%%+";
  x[37] := "+%+%#####&&&&&==='===*$$###%%%%+";
  x[38] := "%+%%%%**=*&&&&>,>,>-=>==*$*##%%%";
  x[39] := "  %#****'=>---,))!),>>>==***#%#+";
  x[40] := "  @%*'''>>>>;;,{{{))))>>>''**#%+";
  x[41] := " ..@#*'!]]]{)){^__^^{]!!!'''###+";
  x[42] := " ..@$=']]((^^~~:::/__^{((!>**##@";
  x[43] := "....&&=>(_|[::/<}[<[::_((!>==###";
  x[44] := "....&&--!_}|}[<[}[}}}||_]!>>**##";
  x[45] := "@@$$&&--;{:|1|[<|}|}||}_^]>>=*##";
  x[46] := "##$$=-,;)~~<121<2|121}}:^])>=*$#";
  x[47] := "#*'''!]{^_<<<1313332|}}}^{!>>*##";
  x[48] := "%*'']((|}}||||<333321|[[_^]>==*#";
  x[49] := "*''''((||112333333321|}[_^]!>=*#";
  x[50] := "%%*''!]^_[[[}<13332}<[<:_])>>*$#";
  x[51] := "##*==,,)~_:<[|212311}[</{),,=*$#";
  x[52] := "#@$$==,;)~/<|1<2|<1}|[:^{)-=&&$@";
  x[53] := ".@@$&&-;)~:|}<<1}[|}[[:^{,-=&$@@";
  x[54] := "..@@&&-;)(}[/<[|[<<}<:_^{),=&$@.";
  x[55] := "...@&&=,{_(~~:[[<</[[^~]!>>=&$@@";
  x[56] := " .@@$&'!({;;{/}::/~/_^)),>=*$#@+";
  x[57] := " ..@$=''>,-;)^__~^{)^]),,==*$#@@";
  x[58] := ". @##*'==&--){({));;,{>>==$$#@++";
  x[59] := "%++#%**$&&--,!));;;-->>=&$$##@+%";
  x[60] := " +%%##@@@@&=>>>>>>=-==='$$#@@+++";
  x[61] := " %%+@@..&.$&='==-&&&&&$*$#@@.+% ";
  x[62] := " %%+ ....@$$*==&$&&&@$$##@@+ %  ";
  x[63] := "   %  ....@#*#$$$#@@@@@##+@++   ";
  x[64] := "        ..@####@@@@@..+@++%     ";
  ASSERT(FlImages.OpenXPM(i, x, 65))
END Blast;

PROCEDURE ButtonCB(w: Fl.Widget);
  VAR a: SET;
BEGIN
  a := {};
  IF leftb.Value() THEN a := a + Fl.AlignLeft END;
  IF rightb.Value() THEN a := a + Fl.AlignRight END;
  IF topb.Value() THEN a := a + Fl.AlignTop END;
  IF bottomb.Value() THEN a := a + Fl.AlignBottom END;
  IF insideb.Value() THEN a := a + Fl.AlignInside END;
  IF clipb.Value() THEN a := a + Fl.AlignClip END;
  IF wrapb.Value() THEN a := a + Fl.AlignWrap END;
  IF imageovertextb.Value() THEN a := a + Fl.AlignTextOverImage END;
  IF imagenexttotextb.Value() THEN a := a + Fl.AlignImageNextToText END;
  IF imagebackdropb.Value() THEN a := a + Fl.AlignImageBackdrop END;
  text.SetAlign(a);
  window.Redraw
END ButtonCB;

PROCEDURE ImageCB(w: Fl.Widget);
BEGIN
  IF imageb.Value() THEN FlImages.SetImage(text, img) ELSE FlImages.SetImage(text, NIL) END;
  window.Redraw
END ImageCB;

PROCEDURE FontCB(w: Fl.Widget);
BEGIN text.SetLabelFont(SHORT(ENTIER(fonts.Value()))); window.Redraw
END FontCB;

PROCEDURE HMarginCB(w: Fl.Widget);
BEGIN text.SetHorizontalLabelMargin(SHORT(ENTIER(hMargin.Value()))); window.Redraw
END HMarginCB;

PROCEDURE VMarginCB(w: Fl.Widget);
BEGIN text.SetVerticalLabelMargin(SHORT(ENTIER(vMargin.Value()))); window.Redraw
END VMarginCB;

PROCEDURE SpacingCB(w: Fl.Widget);
BEGIN text.SetLabelImageSpacing(SHORT(ENTIER(imgSpacing.Value()))); window.Redraw
END SpacingCB;

PROCEDURE SizeCB(w: Fl.Widget);
BEGIN text.SetLabelSize(SHORT(ENTIER(sizes.Value()))); window.Redraw
END SizeCB;

PROCEDURE InputCB(w: Fl.Widget);
BEGIN input.Value(value); text.SetLabel(value); window.Redraw
END InputCB;

PROCEDURE NormalCB(w: Fl.Widget);
BEGIN text.SetLabelType(Fl.NormalLabel); window.Redraw
END NormalCB;

(* FLTK's FL_SYMBOL_LABEL is FL_NORMAL_LABEL: a label starting with @ is
   a symbol. *)
PROCEDURE SymbolCB(w: Fl.Widget);
BEGIN
  text.SetLabelType(Fl.NormalLabel);
  input.Value(value);
  IF value[0] # "@" THEN
    input.SetValue("@->");
    text.SetLabel("@->")
  END;
  window.Redraw
END SymbolCB;

PROCEDURE ShadowCB(w: Fl.Widget);
BEGIN text.SetLabelType(Fl.ShadowLabel); window.Redraw
END ShadowCB;

PROCEDURE EmbossedCB(w: Fl.Widget);
BEGIN text.SetLabelType(Fl.EmbossedLabel); window.Redraw
END EmbossedCB;

PROCEDURE EngravedCB(w: Fl.Widget);
BEGIN text.SetLabelType(Fl.EngravedLabel); window.Redraw
END EngravedCB;

PROCEDURE Slider(VAR s: FlValuators.ValueSlider; x, y, w: INTEGER; label: ARRAY OF CHAR;
  min, max, v: LONGREAL; cb: PROCEDURE (w: Fl.Widget));
BEGIN
  NEW(s); FlValuators.OpenHorValueSlider(s, x, y, w, 25, label);
  s.SetAlign(Fl.AlignLeft);
  s.SetBounds(min, max);
  s.SetStep(1);
  s.SetValue(v);
  s.action := cb
END Slider;

PROCEDURE Toggle(VAR t: FlButtons.ToggleButton; x, y: INTEGER; label, tip: ARRAY OF CHAR; cb: PROCEDURE (w: Fl.Widget));
BEGIN
  NEW(t); FlButtons.OpenToggleButton(t, x, y, 50, 25, label);
  t.action := cb;
  t.SetTooltip(tip)
END Toggle;

BEGIN
  NEW(img); Blast(img);

  NEW(window); Fl.OpenDoubleWindow(window, 440, 495, "");

  NEW(input); FlInputs.OpenInput(input, 70, 435, 350, 25, "Label:");
  input.SetValue("The quick brown fox jumped over the lazy dog.");
  input.SetWhen(Fl.WhenChanged);
  input.action := InputCB;
  input.SetTooltip("label text");

  Slider(sizes, 70, 350, 350, "Size:", 1, 64, 14, SizeCB);
  Slider(fonts, 70, 325, 350, "Font:", 0, 15, 0, FontCB);

  NEW(margin); Fl.OpenBox(margin, 0, 380, 70, 25, "Margins");
  margin.SetBoxType(Fl.FlatBox);
  margin.SetAlign(Fl.AlignRight + Fl.AlignInside);

  Slider(hMargin, 70 + 50, 380, 125, "Hor:", -25, 25, 0, HMarginCB);
  Slider(vMargin, 70 + 175 + 50, 380, 125, "Vert:", -25, 25, 0, VMarginCB);
  Slider(imgSpacing, 70 + 50, 405, 125, "Image:", 0, 50, 0, SpacingCB);

  NEW(g); Fl.OpenGroup(g, 70, 275, 350, 50, "");
  Toggle(imageb, 70, 275, "image", "show image", ImageCB);
  Toggle(imageovertextb, 120, 275, "T o I", "FL_ALIGN_TEXT_OVER_IMAGE", ButtonCB);
  Toggle(imagenexttotextb, 170, 275, "I | T", "FL_ALIGN_IMAGE_NEXT_TO_TEXT", ButtonCB);
  Toggle(imagebackdropb, 220, 275, "back", "FL_ALIGN_IMAGE_BACKDROP", ButtonCB);
  Toggle(leftb, 70, 300, "left", "FL_ALIGN_LEFT", ButtonCB);
  Toggle(rightb, 120, 300, "right", "FL_ALIGN_RIGHT", ButtonCB);
  Toggle(topb, 170, 300, "top", "FL_ALIGN_TOP", ButtonCB);
  Toggle(bottomb, 220, 300, "bottom", "FL_ALIGN_BOTTOM", ButtonCB);
  Toggle(insideb, 270, 300, "inside", "FL_ALIGN_INSIDE", ButtonCB);
  Toggle(wrapb, 320, 300, "wrap", "FL_ALIGN_WRAP", ButtonCB);
  Toggle(clipb, 370, 300, "clip", "FL_ALIGN_CLIP", ButtonCB);
  g.SetResizable(insideb);
  g.End;

  NEW(c); FlMenus.OpenChoice(c, 70, 250, 200, 25, "");
  n := c.Add("FL_NORMAL_LABEL", 0, {}, NormalCB, {});
  n := c.Add("FL_SYMBOL_LABEL", 0, {}, SymbolCB, {});
  n := c.Add("FL_SHADOW_LABEL", 0, {}, ShadowCB, {});
  n := c.Add("FL_ENGRAVED_LABEL", 0, {}, EngravedCB, {});
  n := c.Add("FL_EMBOSSED_LABEL", 0, {}, EmbossedCB, {});
  IF c.SetValue(0) THEN END;  (* FLTK's menu() sets the first item *)

  input.Value(value);
  NEW(text); Fl.OpenBox(text, 120, 75, 200, 100, value);
  text.SetBoxType(Fl.EngravedBox);  (* FLTK's FL_FRAME_BOX *)
  text.SetAlign(Fl.AlignCenter);

  window.SetResizable(text);
  window.End;
  window.ShowArgs;
  Fl.Run
END Label.
