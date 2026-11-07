MODULE Button; (* FLTK's test/button.cxx in Oberon-2 *)

(* Three buttons: one beeps, one does nothing, and one exits. *)

IMPORT Fl, FlButtons, FlDialogs;

VAR
  window: Fl.Window;
  b1, b2, b3: FlButtons.Button;

PROCEDURE Beep(w: Fl.Widget);
BEGIN FlDialogs.Beep(FlDialogs.BeepDefault)
END Beep;

PROCEDURE Exit(w: Fl.Widget);
BEGIN HALT(0)
END Exit;

BEGIN
  NEW(window); Fl.OpenWindow(window, 320, 65, "");
  NEW(b1); FlButtons.OpenButton(b1, 20, 20, 80, 25, "&Beep");
  b1.action := Beep;
  NEW(b2); FlButtons.OpenButton(b2, 120, 20, 80, 25, "&no op");
  NEW(b3); FlButtons.OpenButton(b3, 220, 20, 80, 25, "E&xit");
  b3.action := Exit;
  window.End;
  window.ShowArgs;
  Fl.Run
END Button.
