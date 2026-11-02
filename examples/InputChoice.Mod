MODULE InputChoice; (* FLTK's test/input_choice.cxx: an input choice beside a choice, in a group *)

(* What FLTK's test writes to its terminal goes to standard error, not
   to an FlTerminal; the window keeps the room for one. *)

IMPORT Err, Fl, FlButtons, FlInputs, FlMenus;

CONST terminalHeight = 150;

VAR
  win: Fl.DoubleWindow;
  activeGroup: Fl.Group;
  in: FlInputs.InputChoice;
  choice: FlMenus.Choice;
  sch: FlMenus.SchemeChoice;
  active: FlButtons.CheckButton;
  n: INTEGER;
  ok: BOOLEAN;

PROCEDURE ActiveCB(w: Fl.Widget);
BEGIN
  IF active.Value() THEN
    activeGroup.Activate; Err.String("activate group")
  ELSE
    activeGroup.Deactivate; Err.String("deactivate group")
  END;
  Err.Ln;
  activeGroup.Redraw;
  IF active.Changed() THEN
    Err.String("Callback: changed() is set"); Err.Ln;
    active.SetChanged(FALSE)
  END
END ActiveCB;

PROCEDURE InputChoiceCB(w: Fl.Widget);
  VAR s: ARRAY 256 OF CHAR;
BEGIN
  in.Value(s);
  Err.String("Fl_Input_Choice value='"); Err.String(s); Err.String("'"); Err.Ln
END InputChoiceCB;

PROCEDURE ChoiceCB(w: Fl.Widget);
BEGIN
  Err.String("Fl_Choice       value='"); Err.Int(choice.Value(), 0); Err.String("'"); Err.Ln
END ChoiceCB;

BEGIN
  NEW(win); Fl.OpenDoubleWindow(win, 300, 200 + terminalHeight, "input_choice");

  (* this group can be activated and deactivated: *)
  NEW(activeGroup); Fl.OpenGroup(activeGroup, 0, 0, 300, 120, "");

  (* all the choices are aligned, for easier visual comparison: *)
  NEW(in); FlInputs.OpenInputChoice(in, 180, 40, 100, 25, "Fl_Input_Choice:");
  in.action := InputChoiceCB;
  in.Add("one"); in.Add("two"); in.Add("three");
  in.SetValueIndex(0);

  NEW(choice); FlMenus.OpenChoice(choice, 180, 70, 100, 25, "Fl_Choice:");
  choice.action := ChoiceCB;
  n := choice.Add("aaa", 0, {}, NIL, {});
  n := choice.Add("bbb", 0, {}, NIL, {});
  n := choice.Add("ccc", 0, {}, NIL, {});
  ok := choice.SetValue(1);

  activeGroup.End;

  (* interactive control of the scheme *)
  NEW(sch); FlMenus.OpenSchemeChoice(sch, 180, 120, 100, 25, "Choose scheme:");
  sch.SetVisibleFocus(FALSE);

  NEW(active); FlButtons.OpenCheckButton(active, 50, 160, 160, 30, "Activate/deactivate");
  active.action := ActiveCB;
  active.SetValue(TRUE);

  win.End;
  win.SetResizable(win);
  win.SizeRange(200, 160, 0, 0);
  win.ShowArgs;
  Fl.Run
END InputChoice.
