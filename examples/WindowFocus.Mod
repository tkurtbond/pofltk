MODULE WindowFocus; (* FLTK's test/windowfocus.cxx in Oberon-2 *)

(* Typing in the input shows a second window beside the first; the focus
   stays on the input. *)

IMPORT Fl, FlInputs;

VAR
  win1, win2: Fl.DoubleWindow;
  b: Fl.Box;
  input1: FlInputs.Input;

PROCEDURE Popup(w: Fl.Widget);
BEGIN
  win2.Position(win1.X() + win1.W(), win1.Y());
  win2.Show;
  win2.WaitForExpose;
  IF input1.TakeFocus() THEN END
END Popup;

BEGIN
  NEW(win1); Fl.OpenDoubleWindow(win1, 300, 200, "show() focus test");

  NEW(b); Fl.OpenBox(b, 10, 10, 280, 130,
    "Type something to pop the subwindow up. The focus should stay on the input, and you should be able to continue typing.");
  b.SetAlign(Fl.AlignWrap + Fl.AlignLeft + Fl.AlignInside);

  NEW(input1); FlInputs.OpenInput(input1, 10, 150, 150, 25, "");
  input1.SetWhen(Fl.WhenChanged);
  input1.action := Popup;

  win1.End;

  NEW(win2); Fl.OpenDoubleWindow(win2, 300, 200, "window2");
  win2.End;

  win1.ShowArgs;
  Fl.Run
END WindowFocus.
