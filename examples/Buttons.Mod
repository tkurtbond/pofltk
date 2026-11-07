MODULE Buttons; (* FLTK's test/buttons.cxx in Oberon-2 *)

(* Each kind of button, with its name as its tooltip; a keypad of
   compact buttons; and a choice of FLTK's schemes. *)

IMPORT Fl, FlButtons, FlMenus;

VAR
  window: Fl.Window;
  b1: FlButtons.Button;
  b2: FlButtons.ReturnButton;
  b3: FlButtons.RepeatButton;
  b4: FlButtons.RoundButton;
  b5: FlButtons.LightButton;
  b6: FlButtons.CheckButton;
  keypad: Fl.Group;
  kp: ARRAY 11 OF FlButtons.Button;
  schemeChoice: FlMenus.SchemeChoice;
  i: INTEGER;

PROCEDURE Key(i, x, y, w: INTEGER; label-: ARRAY OF CHAR);
BEGIN
  NEW(kp[i]); FlButtons.OpenButton(kp[i], x, y, w, 30, label)
END Key;

BEGIN
  NEW(window); Fl.OpenWindow(window, 420, 170, "");
  NEW(b1); FlButtons.OpenButton(b1, 10, 10, 130, 30, "Fl_Button");
  b1.SetTooltip("Fl_Button");
  NEW(b2); FlButtons.OpenReturnButton(b2, 150, 10, 160, 30, "Fl_Return_Button");
  b2.SetTooltip("Fl_Return_Button");
  NEW(b3); FlButtons.OpenRepeatButton(b3, 10, 50, 130, 30, "Fl_Repeat_Button");
  b3.SetTooltip("Fl_Repeat_Button");
  NEW(b4); FlButtons.OpenRoundButton(b4, 150, 50, 160, 30, "Fl_Round_Button");
  b4.SetTooltip("Fl_Round_Button");
  NEW(b5); FlButtons.OpenLightButton(b5, 10, 90, 130, 30, "Fl_Light_Button");
  b5.SetTooltip("Fl_Light_Button");
  NEW(b6); FlButtons.OpenCheckButton(b6, 150, 90, 160, 30, "Fl_Check_Button");
  b6.SetTooltip("Fl_Check_Button");

  NEW(keypad); Fl.OpenGroup(keypad, 320, 10, 90, 120, "");
  Key(7, 320, 10, 30, "7"); Key(8, 350, 10, 30, "8"); Key(9, 380, 10, 30, "9");
  Key(4, 320, 40, 30, "4"); Key(5, 350, 40, 30, "5"); Key(6, 380, 40, 30, "6");
  Key(1, 320, 70, 30, "1"); Key(2, 350, 70, 30, "2"); Key(3, 380, 70, 30, "3");
  Key(0, 320, 100, 60, "0"); Key(10, 380, 100, 30, ".");
  FOR i := 0 TO 10 DO
    kp[i].SetCompact(TRUE);
    kp[i].SetSelectionColor(Fl.SelectionColor)
  END;
  keypad.End;

  (* at the window's right, so that its menu doesn't cover the buttons *)
  NEW(schemeChoice); FlMenus.OpenSchemeChoice(schemeChoice, 180, 130, 130, 30, "Active FLTK Scheme:");
  schemeChoice.SetTooltip("Fl_Scheme_Choice");

  window.End;
  window.SetResizable(window);
  window.SizeRange(320, 130, 0, 0);
  window.ShowArgs;
  Fl.Run
END Buttons.
