MODULE HaltTerminalCells; (* more cells than a terminal may have (Fl.Unsupported) *)

IMPORT Fl, FlTerminal;

VAR
  win: Fl.Window;
  t: FlTerminal.Terminal;

BEGIN
  NEW(win); Fl.OpenWindow(win, 200, 100, "halt");
  NEW(t); FlTerminal.OpenTerminal(t, 0, 0, 200, 100, "");
  win.End;
  t.SetHistoryRows(FlTerminal.MaxCells)
END HaltTerminalCells.
