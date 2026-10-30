MODULE HaltColorMode; (* A color chooser's mode that isn't one: halts with Fl.IndexOutOfRange *)

IMPORT Fl, FlDialogs;

VAR
  win: Fl.Window;
  c: FlDialogs.ColorChooser;

BEGIN
  NEW(win); Fl.OpenWindow(win, 200, 100, "HaltColorMode");
  NEW(c); FlDialogs.OpenColorChooser(c, 0, 0, 200, 95, "");
  win.End;
  c.SetMode(FlDialogs.ColorDefault)
END HaltColorMode.
