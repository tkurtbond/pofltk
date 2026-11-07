MODULE TwoWin; (* FLTK's test/twowin.cxx in Oberon-2 *)

(* Two windows, each with a button and an input: a window's button gives
   the focus to the other window's input. *)

IMPORT Fl, FlButtons, FlInputs;

VAR
  win1, win2: Fl.DoubleWindow;
  bb1, bb2: FlButtons.Button;
  b1, b2: FlInputs.Input;

PROCEDURE Focus1(w: Fl.Widget);
BEGIN IF b2.TakeFocus() THEN END
END Focus1;

PROCEDURE Focus2(w: Fl.Widget);
BEGIN IF b1.TakeFocus() THEN END
END Focus2;

BEGIN
  NEW(win1); Fl.OpenDoubleWindow(win1, 200, 200, "win1");
  NEW(bb1); FlButtons.OpenButton(bb1, 10, 10, 100, 100, "b1");
  bb1.action := Focus1;
  NEW(b1); FlInputs.OpenInput(b1, 10, 150, 100, 25, "");
  win1.End;

  NEW(win2); Fl.OpenDoubleWindow(win2, 200, 200, "win2");
  NEW(bb2); FlButtons.OpenButton(bb2, 10, 10, 100, 100, "b2");
  bb2.action := Focus2;
  NEW(b2); FlInputs.OpenInput(b2, 10, 150, 100, 25, "");
  win2.End;

  win1.Position(200, 200);
  win2.Position(400, 200);

  win1.ShowArgs;
  win2.Show;
  Fl.Run
END TwoWin.
