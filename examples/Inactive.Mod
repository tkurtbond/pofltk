MODULE Inactive; (* FLTK's test/inactive.cxx in Oberon-2 *)

(* A group of many kinds of widget, which the buttons below it activate
   and deactivate, to show how each draws when inactive. *)

IMPORT Fl, FlButtons, FlInputs, FlMenus, FlValuators;

VAR
  window: Fl.DoubleWindow;
  theGroup, g: Fl.Group;
  b: FlButtons.Button;
  lb: FlButtons.LightButton;
  cb: FlButtons.CheckButton;
  rb: FlButtons.RoundButton;
  slider: FlValuators.Slider;
  input: FlInputs.Input;
  menu: FlMenus.MenuButton;
  out: FlValuators.ValueOutput;
  box: Fl.Box;
  bar: FlValuators.Scrollbar;
  roller: FlValuators.Roller;
  dial: FlValuators.Dial;
  clock: FlValuators.Clock;
  i, n: INTEGER;
  name: ARRAY 8 OF CHAR; (* FLUID's colors 1, 2 and 4 are the colormap's first red, green and blue *)

PROCEDURE ActiveCallback(w: Fl.Widget);
BEGIN theGroup.Activate
END ActiveCallback;

PROCEDURE InactiveCallback(w: Fl.Widget);
BEGIN theGroup.Deactivate
END InactiveCallback;

(* A radio check button in a color. *)
PROCEDURE Colored(y: INTEGER; label-: ARRAY OF CHAR; c: INTEGER);
VAR b: FlButtons.CheckButton;
BEGIN
  NEW(b); FlButtons.OpenCheckButton(b, 54, y, 97, 20, label);
  b.SetKind(FlButtons.Radio);
  b.SetDownBox(Fl.DiamondDownBox);
  b.SetSelectionColor(c);
  b.SetLabelColor(c)
END Colored;

BEGIN
  NEW(window); Fl.OpenDoubleWindow(window, 420, 369, "");
  NEW(theGroup); Fl.OpenGroup(theGroup, 25, 25, 375, 295, "activate()/deactivate() called on this Fl_Group");
  theGroup.SetBoxType(Fl.EngravedFrame);
  theGroup.SetAlign(Fl.AlignTop + Fl.AlignInside);
  NEW(b); FlButtons.OpenButton(b, 50, 50, 105, 20, "button");
  NEW(lb); FlButtons.OpenLightButton(lb, 50, 75, 105, 20, "light button");
  lb.SetValue(TRUE);
  lb.SetAlign(Fl.AlignCenter + Fl.AlignInside);

  NEW(g); Fl.OpenGroup(g, 50, 100, 105, 20, "");
  NEW(b); FlButtons.OpenButton(b, 50, 100, 52, 20, "On");
  b.SetKind(FlButtons.Radio); b.SetValue(TRUE); b.SetCompact(TRUE);
  NEW(b); FlButtons.OpenButton(b, 102, 100, 53, 20, "Off");
  b.SetKind(FlButtons.Radio); b.SetCompact(TRUE);
  g.End;

  NEW(g); Fl.OpenGroup(g, 50, 150, 105, 105, "Child group");
  g.SetBoxType(Fl.DownFrame);
  Colored(192, "red", 1);
  Colored(212, "green", 2);
  Colored(232, "blue", 4);
  NEW(cb); FlButtons.OpenCheckButton(cb, 54, 152, 97, 20, "check");
  cb.SetDownBox(Fl.DownBox);
  NEW(rb); FlButtons.OpenRoundButton(rb, 54, 172, 97, 20, "round");
  rb.SetDownBox(Fl.RoundDownBox);
  g.End;

  NEW(slider); FlValuators.OpenSlider(slider, 165, 50, 24, 205, "Fl_Slider");
  slider.SetValue(0.5D0);
  (* static_value isn't bound; the value, copied, looks the same *)
  NEW(input); FlInputs.OpenInput(input, 195, 50, 195, 30, "");
  input.SetValue("Fl_Input");
  NEW(menu); FlMenus.OpenMenuButton(menu, 245, 90, 130, 30, "menu");
  (* FLTK's program gives a menu of five items named "item"; Add would
     make one of them, replacing the item with the same label, so each
     is added by a name of its own, then labelled "item" *)
  FOR n := 1 TO 5 DO
    name := "item0"; name[4] := CHR(ORD("0") + n);
    i := menu.Add(name, 0, {}, NIL, {}); menu.SetItemLabel(i, "item")
  END;
  NEW(out); FlValuators.OpenValueOutput(out, 245, 130, 130, 30, "value:");
  out.SetBounds(out.Minimum(), 10000);
  out.SetStep(1);
  out.SetTextFont(5);
  out.SetTextSize(24);
  out.SetTextColor(4);
  NEW(box); Fl.OpenBox(box, 245, 170, 140, 50, "Fl_Box");
  box.SetBoxType(Fl.EmbossedFrame);
  box.SetLabelType(Fl.ShadowLabel);
  box.SetLabelFont(3);
  box.SetLabelSize(38);
  NEW(bar); FlValuators.OpenScrollbar(bar, 40, 274, 180, 20, "scrollbar");
  bar.SetKind(FlValuators.Horizontal);
  NEW(roller); FlValuators.OpenRoller(roller, 235, 230, 25, 65, "roller");
  NEW(dial); FlValuators.OpenDial(dial, 275, 235, 50, 50, "dial");
  NEW(clock); FlValuators.OpenClock(clock, 335, 235, 50, 50, "clock");
  theGroup.End;
  window.SetResizable(theGroup);

  NEW(b); FlButtons.OpenButton(b, 25, 330, 185, 25, "active");
  b.SetKind(FlButtons.Radio); b.SetValue(TRUE);
  b.action := ActiveCallback;
  NEW(b); FlButtons.OpenButton(b, 220, 330, 180, 25, "inactive");
  b.SetKind(FlButtons.Radio);
  b.action := InactiveCallback;
  window.End;
  window.ShowArgs;
  Fl.Run
END Inactive.
