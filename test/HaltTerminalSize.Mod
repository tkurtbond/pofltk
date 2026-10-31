MODULE HaltTerminalSize; (* rows of no use (Fl.Unsupported) *)

IMPORT Fl, FlTerminal;

VAR
  win: Fl.Window;
  t: FlTerminal.Terminal;

BEGIN
  NEW(win); Fl.OpenWindow(win, 200, 100, "halt");
  NEW(t); FlTerminal.OpenTerminal(t, 0, 0, 200, 100, "");
  win.End;
  t.SetDisplayRows(0)
END HaltTerminalSize.
