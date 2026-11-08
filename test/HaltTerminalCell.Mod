MODULE HaltTerminalCell; (* a cell past the ring's last row (Fl.IndexOutOfRange) *)

IMPORT Fl, FlTerminal;

VAR
  win: Fl.Window;
  t: FlTerminal.Terminal;
  s: ARRAY 8 OF CHAR;
  a: SET;
  fg, bg: INTEGER;

BEGIN
  NEW(win); Fl.OpenWindow(win, 200, 100, "halt");
  NEW(t); FlTerminal.OpenTerminal(t, 0, 0, 200, 100, "");
  win.End;
  t.Cell(t.RingRows(), 0, s, a, fg, bg)
END HaltTerminalCell.
