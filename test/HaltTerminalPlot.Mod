MODULE HaltTerminalPlot; (* a character plotted off the screen (Fl.IndexOutOfRange) *)

IMPORT Fl, FlTerminal;

VAR
  win: Fl.Window;
  t: FlTerminal.Terminal;

BEGIN
  NEW(win); Fl.OpenWindow(win, 200, 100, "halt");
  NEW(t); FlTerminal.OpenTerminal(t, 0, 0, 200, 100, "");
  win.End;
  t.PlotChar("x", 0, 100000)
END HaltTerminalPlot.
