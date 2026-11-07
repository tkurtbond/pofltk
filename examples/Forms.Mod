MODULE Forms; (* FLTK's test/forms.cxx: every kind of widget the Forms library has, and a choice of box types *)

(* FLTK's program makes this window with fl_add_box and the rest of
   FL/forms.H, the C calls of old programs. Each only makes the FLTK
   widget, so this makes them itself, and the Forms library's own classes,
   FormsText, FormsBitmap and Timer, come from FlForms. FLTK's Forms menu
   of type FL_PUSH_MENU is a pop-up, so it shows nothing until clicked.
   FLTK's window opens under the mouse; hotspots aren't bound. *)

IMPORT Fl, FlBrowsers, FlButtons, FlForms, FlImages, FlInputs, FlMenus, FlValuators;

CONST
  width = 75; height = 75;
  slateBlue = 195;
  tests = 18;  (* the widgets whose box can be chosen *)

VAR
  form: Fl.Window;
  tobj: ARRAY tests OF Fl.Widget;
  btypes: ARRAY 21 OF INTEGER;
  btypeob: FlMenus.Choice;
  lastbt: INTEGER;
  bits: ARRAY 750 OF CHAR;
  n: INTEGER;

PROCEDURE Row(s: ARRAY OF CHAR);
  VAR i: INTEGER;

  PROCEDURE Digit(c: CHAR): INTEGER;
  BEGIN
    IF c >= "a" THEN RETURN ORD(c) - ORD("a") + 10 END;
    RETURN ORD(c) - ORD("0")
  END Digit;

BEGIN
  i := 0;
  WHILE s[i] # 0X DO
    bits[n] := CHR(Digit(s[i]) * 16 + Digit(s[i + 1])); INC(n); INC(i, 2)
  END
END Row;

PROCEDURE Bits;
BEGIN
  Row("fc7e4020900007802300");
  Row("00c6c14198b801076600");
  Row("159f03478cc6dc7bcc00");
  Row("b0710e4d0666738e8f01");
  Row("18c4394b02230c041e03");
  Row("0c08c7ef083006071c02");
  Row("063018aec8983f782006");
  Row("022060a0c41dc0ff4104");
  Row("fa6380a1a43d0084bf04");
  Row("0f06fca1346b011cc905");
  Row("06c706be111e43309105");
  Row("c36102301b30cc201100");
  Row("c13c03200a00e8602100");
  Row("611bc16308f0c6c72103");
  Row("f808e1cf0afc4d994307");
  Row("3c0cf19f0bfc5b814702");
  Row("1604311c0b1f17894d06");
  Row("1a043138020756894904");
  Row("0b04b17282a1549a4904");
  Row("1d6650e7c2f0549a5804");
  Row("0d62c11f44fc51909004");
  Row("8663e07404ef311a9100");
  Row("02e2c1fd84f9300a9100");
  Row("82a9c0b984f931168100");
  Row("42a9db7f0cff1c161100");
  Row("02280b0708601c029100");
  Row("46290e00000010161102");
  Row("06290400000010169106");
  Row("a62a0400000018249104");
  Row("862a0400000018279304");
  Row("964a0400000004029104");
  Row("864a0c0000001e239304");
  Row("56880800000090219304");
  Row("520a09800100d0219504");
  Row("570a0f802700d8209d04");
  Row("5d081c806700e4018504");
  Row("798a3f000000f4118506");
  Row("39087d000018b7108103");
  Row("2912cb007e3028008503");
  Row("2910be81ff270c108503");
  Row("2932fac1ff2794118503");
  Row("28206ce1ff070c018501");
  Row("28625ce38f034e918005");
  Row("3940f4c2ff009f918405");
  Row("31c6e8077f80cd00c404");
  Row("3106c90e00c04888e004");
  Row("7904db1200300cc8e404");
  Row("6d06b62300181cc08404");
  Row("250cffc2004e06b08004");
  Row("3f8ab383ffc303918404");
  Row("2ed80f3f00005f838404");
  Row("2a70fd7f0000c8c08404");
  Row("4be22f01000858608004");
  Row("5b82ff010008d0a08404");
  Row("7280e5000008d2204404");
  Row("ca02ff000008dea04404");
  Row("82026d000008f6b04002");
  Row("82073f00000844584402");
  Row("933f1f000030884f4403");
  Row("83233e0000001860e007");
  Row("e30ffe0000007070e407");
  Row("c71bfe010000e03ce407");
  Row("c7e3fe1f0000ff1ffc07");
  Row("c703f83300c0f007ff07");
  Row("8702fc430060f0ffff07");
  Row("8f06be870030f8ffff07");
  Row("8f149c8f0000fcffff07");
  Row("9f8d8a0f0000feffff07");
  Row("bf0b801f0000ffffff07");
  Row("7f3a803f0080ffffff07");
  Row("ff20c03f0080ffffff07");
  Row("ff01e07f00c0ffffff07");
  Row("ff0ff8ff40e0ffffff07");
  Row("ffffffff40f0ffffff07");
  Row("ffffffff41f0ffffff07")
END Bits;

PROCEDURE BoxtypeCb(w: Fl.Widget);
  VAR i, req: INTEGER;
BEGIN
  req := btypeob.Value();
  IF lastbt # req THEN
    FOR i := 0 TO tests - 1 DO tobj[i].SetBoxType(btypes[req]) END;
    lastbt := req;
    form.Redraw
  END
END BoxtypeCb;

PROCEDURE ExitCb(w: Fl.Widget);
BEGIN form.Hide
END ExitCb;

PROCEDURE Plain(x, y, w, h: INTEGER; label: ARRAY OF CHAR; type, color: INTEGER);
  VAR b: Fl.Box;
BEGIN
  NEW(b); Fl.OpenBox(b, x, y, w, h, label);
  b.SetBoxType(type); b.SetColor(color); b.SetSelectionColor(Fl.Gray)
END Plain;

PROCEDURE AddItems(m: FlMenus.Menu);
  VAR i, item: INTEGER; name: ARRAY 8 OF CHAR;
BEGIN
  name := "item 0";
  FOR i := 1 TO 5 DO
    name[5] := CHR(ORD("0") + i);
    item := m.Add(name, 0, {}, NIL, {})
  END
END AddItems;

PROCEDURE AddBox(VAR i: INTEGER; type: INTEGER; name: ARRAY OF CHAR);
BEGIN
  btypes[i] := type;
  i := btypeob.Add(name, 0, {}, NIL, {}) + 1
END AddBox;

PROCEDURE AddBoxes;
  VAR i: INTEGER;
BEGIN
  i := 0;
  AddBox(i, Fl.NoBox, "no box");
  AddBox(i, Fl.UpBox, "up box");
  AddBox(i, Fl.DownBox, "down box");
  AddBox(i, Fl.BorderBox, "border box");
  AddBox(i, Fl.ShadowBox, "shadow box");
  AddBox(i, Fl.FlatBox, "flat box");
  AddBox(i, Fl.EngravedBox, "frame box");
  AddBox(i, Fl.EmbossedBox, "embossed box");
  AddBox(i, Fl.RoundedBox, "rounded box");
  AddBox(i, Fl.RFlatBox, "rflat box");
  AddBox(i, Fl.RShadowBox, "rshadow box");
  AddBox(i, Fl.OvalBox, "oval box");
  AddBox(i, Fl.RoundUpBox, "rounded3d upbox");
  AddBox(i, Fl.RoundDownBox, "rounded3d downbox");
  AddBox(i, Fl.RoundUpBox, "oval3d upbox");
  AddBox(i, Fl.RoundDownBox, "oval3d downbox");
  AddBox(i, Fl.PlasticUpBox, "plastic upbox");
  AddBox(i, Fl.PlasticDownBox, "plastic downbox");
  AddBox(i, Fl.GtkUpBox, "GTK up box");
  AddBox(i, Fl.GtkRoundUpBox, "GTK round up box");
  AddBox(i, Fl.GleamUpBox, "Gleam up box")
END AddBoxes;

PROCEDURE AddLines(b: FlBrowsers.Browser);
BEGIN
  b.Add(" "); b.Add("@C1@c@l@bObjects Demo"); b.Add(" ");
  b.Add("This demo shows you all"); b.Add("objects that currently");
  b.Add("exist in the Forms Library."); b.Add(" ");
  b.Add("You can change the boxtype"); b.Add("of the different objects");
  b.Add("using the buttons at the top"); b.Add("of the form. Note that some");
  b.Add("combinations might not"); b.Add("look too good. Also realize");
  b.Add("that for all object classes"); b.Add("many different types are");
  b.Add("available with different"); b.Add("behaviour."); b.Add(" ");
  b.Add("With this demo you can also"); b.Add("see the effect of the drawing");
  b.Add("mode on the appearance of"); b.Add("the objects.")
END AddLines;

PROCEDURE CreateForm;
  VAR
    box: Fl.Box;
    text: FlForms.FormsText;
    bitmap: FlForms.FormsBitmap;
    image: FlImages.Image;
    chart: FlValuators.Chart;
    clock: FlValuators.Clock;
    button, exitob: FlButtons.Button;
    light: FlButtons.LightButton;
    round: FlButtons.RoundButton;
    slider: FlValuators.Slider;
    valslider: FlValuators.ValueSlider;
    dial: FlValuators.Dial;
    positioner: FlValuators.Positioner;
    counter: FlValuators.Counter;
    input: FlInputs.Input;
    menu: FlMenus.MenuButton;
    choice, modeob: FlMenus.Choice;
    timer: FlForms.Timer;
    browser: FlBrowsers.Browser;
BEGIN
  NEW(form); Fl.OpenWindow(form, 720, 520, "Box types");
  form.SetBoxType(Fl.NoBox);
  Plain(0, 0, 720, 520, "", Fl.UpBox, Fl.Blue);
  Plain(10, 90, 700, 420, "", Fl.DownBox, Fl.Gray);
  Plain(10, 10, 700, 70, "", Fl.DownBox, slateBlue);
  NEW(box); Fl.OpenBox(box, 30, 110, 110, 110, "Box");
  box.SetBoxType(Fl.UpBox); tobj[0] := box;
  NEW(text); FlForms.OpenFormsText(text, 30, 240, 110, 30, "Text"); tobj[1] := text;
  NEW(bitmap); FlForms.OpenFormsBitmap(bitmap, 40, 280, 90, 80, "Bitmap");
  bitmap.SetLabelColor(Fl.Blue);
  n := 0; Bits;
  NEW(image); FlImages.OpenBitmap(image, bits, width, height);
  bitmap.SetBitmap(image); tobj[2] := bitmap;
  NEW(chart); FlValuators.OpenChart(chart, 160, 110, 160, 110, "Chart"); tobj[3] := chart;
  chart.SetKind(FlValuators.BarChart);
  chart.Add(15.0D0, "item 1", Fl.Black);
  chart.Add(5.0D0, "item 2", Fl.Black + 1);
  chart.Add(-10.0D0, "item 3", Fl.Black + 2);
  chart.Add(25.0D0, "item 4", Fl.Black + 3);
  NEW(clock); FlValuators.OpenClock(clock, 40, 390, 90, 90, "Clock"); tobj[4] := clock;
  NEW(button); FlButtons.OpenButton(button, 340, 110, 120, 30, "Button"); tobj[5] := button;
  NEW(light); FlButtons.OpenLightButton(light, 340, 150, 120, 30, "Lightbutton");
  light.SetKind(FlButtons.Toggle); tobj[6] := light;
  NEW(round); FlButtons.OpenRoundButton(round, 340, 190, 120, 30, "Roundbutton");
  round.SetKind(FlButtons.Toggle); tobj[7] := round;
  NEW(slider); FlValuators.OpenSlider(slider, 160, 250, 40, 230, "Slider"); tobj[8] := slider;
  NEW(valslider); FlValuators.OpenValueSlider(valslider, 220, 250, 40, 230, "Valslider");
  valslider.SetKind(FlValuators.VertSlider); tobj[9] := valslider;
  NEW(dial); FlValuators.OpenLineDial(dial, 280, 250, 100, 100, "Dial"); tobj[10] := dial;
  NEW(positioner); FlValuators.OpenPositioner(positioner, 280, 380, 150, 100, "Positioner");
  tobj[11] := positioner;
  NEW(counter); FlValuators.OpenCounter(counter, 480, 110, 210, 30, "Counter"); tobj[12] := counter;
  NEW(input); FlInputs.OpenInput(input, 520, 170, 170, 30, "Input"); tobj[13] := input;
  NEW(menu); FlMenus.OpenMenuButton(menu, 400, 240, 100, 30, "Menu");
  menu.SetKind(FlMenus.Popup1); AddItems(menu); tobj[14] := menu;
  NEW(choice); FlMenus.OpenChoice(choice, 580, 250, 110, 30, "Choice");
  AddItems(choice); tobj[15] := choice;
  NEW(timer); FlForms.OpenTimer(timer, FlForms.ValueTimer, 580, 210, 110, 30, "Timer");
  timer.SetValue(1000.0D0); tobj[16] := timer;
  NEW(browser); FlBrowsers.OpenBrowser(browser, 450, 300, 240, 180, "Browser");
  AddLines(browser); tobj[17] := browser;
  NEW(exitob); FlButtons.OpenButton(exitob, 590, 30, 100, 30, "Exit");
  exitob.action := ExitCb;
  NEW(btypeob); FlMenus.OpenChoice(btypeob, 110, 30, 130, 30, "Boxtype");
  btypeob.action := BoxtypeCb;
  AddBoxes;
  NEW(modeob); FlMenus.OpenChoice(modeob, 370, 30, 130, 30, "Graphics mode");
  form.End
END CreateForm;

BEGIN
  lastbt := -1;
  CreateForm;
  form.ShowArgs;
  Fl.Run
END Forms.
