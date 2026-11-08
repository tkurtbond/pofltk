MODULE UtSchemes; (* FLTK's test/unittest_schemes.cxx in Oberon-2 *)

(* Widgets of many kinds in a subwindow, to see each scheme draw them:
   Edmanuel Torres's layout, from his gleam test. *)

IMPORT Fl, FlButtons, FlInputs, FlLayout, FlMenus, FlText, FlValuators, Ut;

CONST Label* = "Schemes Test";

VAR subwin: Fl.Window;

PROCEDURE ActivateSubwin(w: Fl.Widget);
  VAR b: FlButtons.Button;
BEGIN
  b := w(FlButtons.Button);
  IF b.Value() THEN b.SetLabel("active"); subwin.Activate
  ELSE b.SetLabel("inactive"); subwin.Deactivate
  END
END ActivateSubwin;

PROCEDURE Button(x, y, color, sel, font, lcolor: INTEGER; tip: ARRAY OF CHAR);
  (* sel, font and lcolor are -1 for FLTK's own *)
  VAR b: FlButtons.Button;
BEGIN
  NEW(b); FlButtons.OpenButton(b, x, y, 90, 25, "button");
  b.SetBoxType(Fl.UpBox); b.SetColor(color);
  IF sel >= 0 THEN b.SetSelectionColor(sel) END;
  b.SetTooltip(tip);
  IF font >= 0 THEN b.SetLabelFont(font) END;
  IF lcolor >= 0 THEN b.SetLabelColor(lcolor) END
END Button;

PROCEDURE Box(x, y, w, h: INTEGER; label: ARRAY OF CHAR; box, color, lcolor: INTEGER);
  VAR b: Fl.Box;
BEGIN
  NEW(b); Fl.OpenBox(b, x, y, w, h, ""); Ut.SetLabel(b, label);
  b.SetBoxType(box); b.SetColor(color);
  IF lcolor >= 0 THEN b.SetLabelColor(lcolor) END;
  b.SetLabelSize(10)
END Box;

PROCEDURE Editor(VAR e: FlText.TextEditor; x, y, w, h, box, color: INTEGER; text, tip: ARRAY OF CHAR);
  VAR buf: FlText.TextBuffer;
BEGIN
  NEW(e); FlText.OpenTextEditor(e, x, y, w, h, "");
  e.SetBoxType(box); e.SetColor(color); e.SetTooltip(tip);
  NEW(buf); FlText.OpenBuffer(buf); buf.SetText(text);
  e.SetBuffer(buf); buf.Close
END Editor;

PROCEDURE Display(x, y, color: INTEGER; text, tip: ARRAY OF CHAR);
  VAR d: FlText.TextDisplay; buf: FlText.TextBuffer;
BEGIN
  NEW(d); FlText.OpenTextDisplay(d, x, y, 125, 55, "");
  d.SetBoxType(Fl.DownFrame); d.SetColor(color); d.SetTooltip(tip);
  d.SetTextSize(8);
  NEW(buf); FlText.OpenBuffer(buf); buf.SetText(text);
  d.SetBuffer(buf); buf.Close
END Display;

PROCEDURE Tab(x, y: INTEGER; label: ARRAY OF CHAR; hide: BOOLEAN): Fl.Group;
  VAR g: Fl.Group;
BEGIN
  NEW(g); Fl.OpenGroup(g, x, y, 310, 190, label);
  g.SetColor(Fl.Dark1);
  IF hide THEN g.Hide END;
  RETURN g
END Tab;

PROCEDURE Tab1;
  VAR g: Fl.Group; c: FlValuators.Clock; p: FlValuators.Progress;
BEGIN
  g := Tab(14, 141, "tab1", TRUE);
  g.SetSelectionColor(23);
  NEW(c); FlValuators.OpenClock(c, 24, 166, 130, 130, "");
  c.SetBoxType(Fl.ThinUpBox); c.SetColor(12);
  c.SetSelectionColor(Fl.Background2Color); c.SetLabelColor(Fl.Background2Color);
  c.SetTooltip("Fl_Clock with thin up box");
  NEW(p); FlValuators.OpenProgress(p, 22, 306, 290, 20, "");
  NEW(c); FlValuators.OpenClock(c, 179, 166, 130, 130, "");
  c.SetBoxType(Fl.ThinDownBox); c.SetColor(26);
  c.SetTooltip("Fl_Clock with thin down box");
  g.End
END Tab1;

PROCEDURE Tab2;
  VAR
    g: Fl.Group; s: FlValuators.Slider; sb: FlValuators.Scrollbar;
    vs: FlValuators.ValueSlider; vo: FlValuators.ValueOutput;
    a: FlValuators.Adjuster; c: FlValuators.Counter; r: FlValuators.Roller;
    vi: FlValuators.ValueInput;
BEGIN
  g := Tab(15, 140, "tab2", FALSE);
  NEW(s); FlValuators.OpenSlider(s, 20, 161, 25, 155, "");
  s.SetBoxType(Fl.DownBox); s.SetTooltip("Fl_Slider with down box");
  NEW(sb); FlValuators.OpenScrollbar(sb, 50, 161, 25, 155, "");
  sb.ScrollValue(0, 50, 1, 100);
  sb.SetBoxType(Fl.DownBox); sb.SetTooltip("Fl_Scrollbar with down box");
  NEW(vs); FlValuators.OpenValueSlider(vs, 115, 161, 25, 155, "");
  vs.SetBoxType(Fl.DownBox);
  NEW(vo); FlValuators.OpenValueOutput(vo, 240, 265, 75, 25, "");
  vo.SetBoxType(Fl.DownBox); vo.SetTooltip("Fl_Value_Output with down box");
  NEW(a); FlValuators.OpenAdjuster(a, 185, 210, 100, 25, "");
  a.SetTooltip("Fl_Adjuster");
  NEW(c); FlValuators.OpenCounter(c, 185, 180, 100, 25, "");
  c.SetBoxType(Fl.DownBox); c.SetTooltip("Fl_Counter with down box");
  NEW(r); FlValuators.OpenRoller(r, 85, 161, 25, 155, "");
  r.SetBoxType(Fl.UpBox); r.SetTooltip("Fl_Roller with up box");
  NEW(vi); FlValuators.OpenValueInput(vi, 155, 265, 75, 25, "");
  vi.SetBoxType(Fl.DownBox); vi.SetTooltip("Fl_Value_Input with down box");
  g.End
END Tab2;

PROCEDURE Tab3;
  VAR
    g: Fl.Group; i: FlInputs.Input; o: FlInputs.Output; e: FlText.TextEditor;
    f: FlInputs.FileInput;
BEGIN
  g := Tab(15, 140, "tab3", TRUE);
  NEW(i); FlInputs.OpenInput(i, 40, 230, 120, 25, "");
  i.SetBoxType(Fl.DownBox); i.SetTooltip("Fl_Input with down box");
  NEW(o); FlInputs.OpenOutput(o, 40, 260, 120, 25, "");
  o.SetBoxType(Fl.DownBox); o.SetTooltip("Fl_Output with down box");
  Editor(e, 180, 160, 125, 55, Fl.DownFrame, 80, "Text editor", "Fl_Text_Editor with down frame");
  e.SetTextSize(8);
  Display(180, 230, 12, "Text display", "Fl_Text_Display with down frame");
  NEW(f); FlInputs.OpenFileInput(f, 40, 290, 265, 30, "");
  f.SetBoxType(Fl.DownBox); f.SetTooltip("Fl_File_Input with down box");
  g.End
END Tab3;

PROCEDURE Round(y: INTEGER; label: ARRAY OF CHAR; sel: INTEGER; tip: ARRAY OF CHAR): FlButtons.RadioRoundButton;
  VAR b: FlButtons.RadioRoundButton;
BEGIN
  NEW(b); FlButtons.OpenRadioRoundButton(b, 40, y, 120, 25, label);
  b.SetTooltip(tip);
  IF sel >= 0 THEN b.SetSelectionColor(sel) END;
  RETURN b
END Round;

PROCEDURE Tab4;
  VAR g: Fl.Group; b: FlButtons.RadioRoundButton;
BEGIN
  g := Tab(15, 140, "tab4", TRUE);
  b := Round(160, "Choice 1", -1, "Fl_Radio_Round_Button (default)");
  b.SetValue(TRUE);
  b := Round(190, "Choice 2", Fl.Red, "Fl_Radio_Round_Button (red)");
  b := Round(220, "Choice 3", Fl.Darker(Fl.Green), "Fl_Radio_Round_Button (green)");
  b := Round(250, "Choice 4", Fl.Blue, "Fl_Radio_Round_Button (blue)");
  g.End
END Tab4;

PROCEDURE Create*(): Fl.Widget;
  VAR
    g: Fl.Group; sc: FlMenus.SchemeChoice; active, lb: FlButtons.LightButton;
    tabs: FlLayout.Tabs; ck: FlButtons.CheckButton; in: FlInputs.Input;
    a: FlValuators.Adjuster; e: FlText.TextEditor;
BEGIN
  NEW(g); Fl.OpenGroup(g, Ut.X, Ut.Y, Ut.W, Ut.H, "");
  NEW(sc); FlMenus.OpenSchemeChoice(sc, Ut.X + 125, Ut.Y, 140, 25, "FLTK Scheme");
  sc.SetLabelFont(Fl.HelveticaBold);
  NEW(active); FlButtons.OpenLightButton(active, Ut.X + 300, Ut.Y, 100, 25, "active");
  active.SetValue(TRUE);
  active.SetSelectionColor(Fl.Red);
  active.SetAlign(Fl.AlignCenter);
  NEW(subwin); Fl.OpenWindowAt(subwin, Ut.X, Ut.Y + 30, Ut.W, Ut.H - 30, "");
  active.action := ActivateSubwin;
  Button(10, 9, 101, -1, 5, -1, "selection_color() = default");
  Button(10, 36, 179, 179, 4, Fl.Background2Color, "selection_color() = color()");
  Button(10, 63, 91, Fl.Lighter(91), -1, -1, "selection_color() = fl_lighter(color())");
  Button(10, 90, Fl.InactiveColor, Fl.Darker(Fl.InactiveColor), -1, Fl.Background2Color,
    "selection_color() = fl_darker(color())");
  NEW(tabs); FlLayout.OpenTabs(tabs, 10, 120, 320, 215, "");
  tabs.SetColor(Fl.Dark1); tabs.SetSelectionColor(Fl.Dark1);
  Tab1; Tab2; Tab3; Tab4;
  tabs.End;
  Box(341, 10, 80, 50, "thin box|down1", Fl.ThinDownBox, 20, -1);
  Box(430, 10, 80, 50, "thin box|up1", Fl.ThinUpBox, Fl.SelectionColor, 6);
  Box(341, 71, 80, 44, "thin box|down2", Fl.ThinDownBox, 190, -1);
  Box(430, 71, 80, 44, "thin box|up2", Fl.ThinUpBox, 96, Fl.Background2Color);
  Box(341, 127, 80, 50, "box down3", Fl.DownBox, 3, -1);
  Box(430, 127, 80, 50, "box up3", Fl.UpBox, 104, 3);
  Box(341, 189, 80, 50, "box down4", Fl.DownBox, 42, Fl.DarkRed);
  Box(430, 189, 80, 50, "box up4", Fl.UpBox, 30, 26);
  Box(341, 251, 80, 82, "box down5", Fl.DownBox, 19, 4);
  Box(430, 251, 80, 82, "box up5", Fl.UpBox, Fl.ForegroundColor, Fl.Background2Color);
  NEW(lb); FlButtons.OpenLightButton(lb, 110, 10, 105, 25, "Light");
  lb.SetBoxType(Fl.DownBox); lb.SetColor(Fl.Background2Color);
  lb.SetSelectionColor(Fl.Red);
  lb.SetTooltip("Fl_Light_Button with down box");
  NEW(ck); FlButtons.OpenCheckButton(ck, 110, 37, 105, 25, "Check");
  ck.SetBoxType(Fl.DownFrame); ck.SetDownBox(Fl.DownBox);
  ck.SetColor(Fl.Dark1); ck.SetSelectionColor(Fl.Darker(Fl.Green));
  ck.SetTooltip("Fl_Check_Button with down frame");
  NEW(in); FlInputs.OpenInput(in, 220, 10, 100, 25, "");
  in.SetBoxType(Fl.DownBox); in.SetColor(23); in.SetTooltip("Fl_Input with down box");
  NEW(a); FlValuators.OpenAdjuster(a, 110, 65, 80, 43, "");
  a.SetBoxType(Fl.UpBox); a.SetColor(Fl.InactiveColor);
  a.SetSelectionColor(Fl.Background2Color); a.SetLabelColor(55);
  a.SetTooltip("Fl_Adjuster with up box");
  Editor(e, 220, 40, 100, 25, Fl.DownFrame, 19, "", "Fl_Text_Editor with down frame");
  e.SetSelectionColor(Fl.Dark1);
  Editor(e, 220, 70, 100, 25, Fl.UpFrame, 19, "", "Fl_Text_Editor with up frame");
  e.SetSelectionColor(Fl.Dark1);
  subwin.End;
  subwin.SetResizable(subwin);
  subwin.Show;
  g.End;
  RETURN g
END Create;

END UtSchemes.
