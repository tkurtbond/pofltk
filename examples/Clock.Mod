MODULE Clock; (* FLTK's test/clock.cxx in Oberon-2 *)

IMPORT Fl, FlValuators;

VAR
  window, window2: Fl.DoubleWindow;
  c1, c2: FlValuators.Clock;

(* Closing either window closes both. *)
PROCEDURE CloseBoth(w: Fl.Widget);
BEGIN window.Hide; window2.Hide
END CloseBoth;

BEGIN
  NEW(window); Fl.OpenDoubleWindow(window, 220, 220, "Fl_Clock");
  window.action := CloseBoth;
  NEW(c1); FlValuators.OpenClock(c1, 0, 0, 220, 220, "");
  window.SetResizable(c1);
  window.End;
  NEW(window2); Fl.OpenDoubleWindow(window2, 220, 220, "Fl_Round_Clock");
  window2.action := CloseBoth;
  NEW(c2); FlValuators.OpenRoundClock(c2, 0, 0, 220, 220, "");
  window2.SetResizable(c2);
  window2.End;
  (* FLTK's says a clock Xresource of another program's got in its way *)
  window.SetXClass("Fl_Clock");
  window2.SetXClass("Fl_Clock");
  window.ShowArgs;
  window2.Show;
  Fl.Run
END Clock.
