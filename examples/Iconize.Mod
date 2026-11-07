MODULE Iconize; (* FLTK's test/iconize.cxx in Oberon-2 *)

(* An empty main window, and a control window whose buttons hide,
   iconize and show it, or show the control window itself; closing the
   control window ends the program. Iconizing needs a window manager on
   X11. *)

IMPORT Fl, FlButtons;

VAR
  mainw, control: Fl.Window;
  hide, iconize, show, showThis: FlButtons.Button;

PROCEDURE HideCb(w: Fl.Widget);
BEGIN mainw.Hide
END HideCb;

PROCEDURE IconizeCb(w: Fl.Widget);
BEGIN mainw.Iconize
END IconizeCb;

PROCEDURE ShowCb(w: Fl.Widget);
BEGIN
  IF w = showThis THEN control.Show ELSE mainw.Show END
END ShowCb;

PROCEDURE WindowCb(w: Fl.Widget);
BEGIN HALT(0)
END WindowCb;

BEGIN
  NEW(mainw); Fl.OpenWindow(mainw, 200, 200, "");
  mainw.End;
  mainw.ShowArgs;

  NEW(control); Fl.OpenWindow(control, 120, 120, "");

  NEW(hide); FlButtons.OpenButton(hide, 0, 0, 120, 30, "hide()");
  hide.action := HideCb;

  NEW(iconize); FlButtons.OpenButton(iconize, 0, 30, 120, 30, "iconize()");
  iconize.action := IconizeCb;

  NEW(show); FlButtons.OpenButton(show, 0, 60, 120, 30, "show()");
  show.action := ShowCb;

  NEW(showThis); FlButtons.OpenButton(showThis, 0, 90, 120, 30, "show this");
  showThis.action := ShowCb;

  control.End;
  control.Show;
  control.action := WindowCb;
  Fl.Run
END Iconize.
