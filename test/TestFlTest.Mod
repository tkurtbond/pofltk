MODULE TestFlTest; (* FlTest: a program's widgets used as by a user, in a window never shown *)

(* The events Mouse, Key and the rest send are checked by each module's
   test; this checks what FlTest builds on them. *)

IMPORT Fl, FlButtons, FlInputs, FlValuators, FlMenus, FlBrowsers, FlDialogs, FlTest, Check;

TYPE
  Button = POINTER TO RECORD (FlButtons.ButtonDesc) calls: INTEGER END;
  CheckButton = POINTER TO RECORD (FlButtons.CheckButtonDesc) calls: INTEGER END;
  Input = POINTER TO RECORD (FlInputs.InputDesc) calls: INTEGER END;
  Browser = POINTER TO RECORD (FlBrowsers.HoldBrowserDesc) calls: INTEGER END;
  Slider = POINTER TO RECORD (FlValuators.SliderDesc) calls: INTEGER END;
  Spinner = POINTER TO RECORD (FlValuators.SpinnerDesc) calls: INTEGER END;

VAR
  win: Fl.Window;
  button: Button;
  check: CheckButton;
  r1, r2: FlButtons.RadioButton;
  radios: Fl.Group;
  input: Input;
  choice: FlMenus.Choice;
  browser: Browser;
  slider: Slider;
  spinner: Spinner;
  box: Fl.Box;
  s, hello, hell, xe: ARRAY 64 OF CHAR; (* hello is "h", U+00E9, "llo" *)
  t: ARRAY 2 OF CHAR;
  picked: INTEGER;
  ok: BOOLEAN;

PROCEDURE (b: Button) Callback*;
BEGIN INC(b.calls)
END Callback;

PROCEDURE (b: CheckButton) Callback*;
BEGIN INC(b.calls)
END Callback;

PROCEDURE (i: Input) Callback*;
BEGIN INC(i.calls)
END Callback;

PROCEDURE (b: Browser) Callback*;
BEGIN INC(b.calls)
END Callback;

PROCEDURE (v: Slider) Callback*;
BEGIN INC(v.calls)
END Callback;

PROCEDURE (v: Spinner) Callback*;
BEGIN INC(v.calls)
END Callback;

PROCEDURE Picked(w: Fl.Widget);
BEGIN INC(picked)
END Picked;

PROCEDURE Clicks;
BEGIN
  (* A button takes the focus as it is pushed, and on X11 with no window
     manager taking the focus shows the window (doc/fltk-issues.md, 176),
     so this one doesn't. *)
  button.SetVisibleFocus(FALSE);
  Check.Check(FlTest.Click(button), "Click is used by a button");
  Check.Check(button.calls = 1, "and runs its callback once");
  Check.Check(~win.Shown(), "a used click leaves a window unshown");
  Check.Check(FlTest.Click(r2) & (r2.Value()), "Click turns a radio button on");
  Check.Check(~r1.Value(), "and its group's others off")
END Clicks;

PROCEDURE Keys;
BEGIN
  FlTest.KeyText(Fl.KeyEnter, {}, t); Check.Check(t = 0DX, "Enter's text");
  FlTest.KeyText(Fl.KeyBackSpace, {}, t); Check.Check(t = 08X, "BackSpace's");
  FlTest.KeyText(ORD("a"), {}, t); Check.Check(t = "a", "a letter's is itself");
  FlTest.KeyText(ORD("a"), Fl.Ctrl, t); Check.Check(t = "", "but none with Ctrl");
  FlTest.KeyText(Fl.KeyLeft, {}, t); Check.Check(t = "", "an arrow's is none");

  Check.Check(FlTest.Type(input, hello), "Type is used by an input");
  input.Value(s);
  Check.Check(s = hello, "and types its text, a UTF-8 character as one key");
  Check.Check(Fl.Focus() = input, "giving it the focus");
  Check.Check(FlTest.Press(Fl.KeyBackSpace, {}), "Press is used");
  input.Value(s); Check.Check(s = hell, "BackSpace deletes");
  Check.Check(input.calls = 0, "an input calls back only as its When says");
  input.SetWhen(Fl.WhenEnterKey);
  ok := FlTest.Press(Fl.KeyEnter, {});
  Check.Check(input.calls = 1, "Enter calls back with WhenEnterKey");
  Check.Check(~FlTest.Type(box, "x"), "a box takes no keys");

  FlTest.Fill(input, "filled");
  input.Value(s);
  Check.Check((s = "filled") & (input.calls = 2), "Fill sets the text and calls back")
END Keys;

PROCEDURE Menus;
  VAR n: INTEGER;
BEGIN
  picked := 0;
  Check.Check(FlTest.Choose(choice, "Two"), "Choose finds an item");
  Check.Check((choice.Value() = 1) & (picked = 1), "picks it and runs its action");
  Check.Check(FlTest.Choose(choice, "Salt & pepper"), "Choose finds an item AddText added");
  Check.Check(choice.Value() = 2, "the one with its & doubled");
  Check.Check(FlTest.Choose(choice, "@home"), "and its @");
  Check.Check(choice.Value() = 3, "the one with its @ doubled");
  Check.Check(~FlTest.Choose(choice, "Four"), "Choose finds no item of another label");
  Check.Check((choice.Value() = 3) & (picked = 3), "and picks nothing");

  Check.Check(FlTest.LineWith(browser, "amm") = 3, "LineWith finds a line holding the text");
  Check.Check(FlTest.LineWith(browser, "") = 1, "the first, for none");
  Check.Check(FlTest.LineWith(browser, "delta") = 0, "and 0 for text no line has");
  n := FlTest.LineWith(browser, "beta");
  FlTest.SelectLine(browser, n);
  Check.Check((browser.Value() = 2) & (browser.calls = 1), "SelectLine selects the line and calls back");
  FlTest.SelectLine(browser, 3);
  Check.Check((browser.Value() = 3) & ~browser.Selected(2), "and deselects the others")
END Menus;

PROCEDURE Values;
BEGIN
  FlTest.Turn(check, TRUE);
  Check.Check(check.Value() & (check.calls = 1), "Turn sets a button and calls back");
  FlTest.Turn(check, TRUE);
  Check.Check(check.calls = 1, "but not when it is set");
  FlTest.Turn(r1, TRUE);
  Check.Check(r1.Value() & ~r2.Value(), "Turn turns a radio button's group off");

  FlTest.Change(slider, 0.25D0);
  Check.Check((slider.Value() = 0.25D0) & (slider.calls = 1), "Change sets a valuator and calls back");
  FlTest.Change(slider, 0.25D0);
  Check.Check(slider.calls = 1, "but not when it has the value");
  FlTest.Change(spinner, 5.0D0);
  Check.Check((spinner.Value() = 5.0D0) & (spinner.calls = 1), "Change sets a spinner")
END Values;

PROCEDURE Drawing;
BEGIN
  Check.Check(FlTest.Capture(box), "Capture draws a box");
  Check.Check(FlTest.Pixel(5, 5) = Fl.RGB(255, 0, 0), "Pixel reads its colour");
  Check.Check(FlTest.Pixel(-1, 0) = -1, "and -1 outside it");
  FlTest.Release;
  Check.Check(FlTest.Pixel(5, 5) = -1, "and with no capture")
END Drawing;

PROCEDURE Dialogs;
BEGIN
  FlTest.Enter; FlDialogs.Message("Done");
  Check.Check(FlTest.Answered(s), "Answer answers a dialog");
  FlDialogs.SetTitle("Asked");
  FlTest.Answer(xe, Fl.KeyEnter); s := "";
  ok := FlDialogs.Input("Name:", s);
  Check.Check(ok & (s = xe), "Answer types its text into a dialog's input");
  Check.Check(FlTest.Answered(s) & (s = "Asked"), "and Answered gives its title");
  FlTest.Escape; ok := FlDialogs.Input("Name:", s);
  Check.Check(~ok, "Escape cancels")
END Dialogs;

PROCEDURE Shown;
BEGIN
  FlTest.Expose(win);
  Check.Check(win.Shown(), "Expose shows a window");
  FlTest.Settle;
  Check.Check(FlTest.ShownPixel(win, box.X() + 5, box.Y() + 5) = Fl.RGB(255, 0, 0),
    "and ShownPixel reads what it shows")
END Shown;

BEGIN
  hello := "h__llo"; hello[1] := 0C3X; hello[2] := 0A9X;
  hell := hello; hell[5] := 0X;
  xe := "x__"; xe[1] := 0C3X; xe[2] := 0A9X;
  NEW(win); Fl.OpenWindow(win, 300, 400, "FlTest");
  NEW(button); FlButtons.OpenButton(button, 10, 10, 80, 25, "Go");
  NEW(radios); Fl.OpenGroup(radios, 100, 10, 190, 25, "");
  NEW(r1); FlButtons.OpenRadioButton(r1, 100, 10, 90, 25, "One");
  NEW(r2); FlButtons.OpenRadioButton(r2, 200, 10, 90, 25, "Two");
  radios.End;
  r1.SetValue(TRUE);
  NEW(check); FlButtons.OpenCheckButton(check, 10, 40, 80, 25, "Check");
  NEW(input); FlInputs.OpenInput(input, 100, 40, 190, 25, "");
  NEW(choice); FlMenus.OpenChoice(choice, 100, 70, 190, 25, "");
  IF choice.Add("One", 0, {}, Picked, {}) = 0 THEN END;
  IF choice.Add("Two", 0, {}, Picked, {}) = 1 THEN END;
  choice.AddText("Salt & pepper", Picked, {});
  choice.AddText("@home", Picked, {});
  NEW(browser); FlBrowsers.OpenHoldBrowser(browser, 10, 100, 280, 80, "");
  browser.Add("alpha"); browser.Add("beta"); browser.Add("gamma");
  NEW(slider); FlValuators.OpenSlider(slider, 10, 190, 280, 25, "");
  NEW(spinner); FlValuators.OpenSpinner(spinner, 100, 220, 100, 25, "");
  NEW(box); Fl.OpenBox(box, 10, 260, 50, 50, "");
  box.SetBoxType(Fl.FlatBox); box.SetColor(Fl.Red);
  win.End;

  Clicks; Keys; Menus; Values; Drawing; Dialogs; Shown;
  win.Delete;
  Check.Summary
END TestFlTest.
