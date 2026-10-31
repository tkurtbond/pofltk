MODULE HaltTerminalStyle; (* no such redraw style (Fl.IndexOutOfRange) *)

IMPORT Fl, FlTerminal;

VAR
  win: Fl.Window;
  t: FlTerminal.Terminal;

BEGIN
  NEW(win); Fl.OpenWindow(win, 200, 100, "halt");
  NEW(t); FlTerminal.OpenTerminal(t, 0, 0, 200, 100, "");
  win.End;
  t.SetRedrawStyle(3)
END HaltTerminalStyle.
