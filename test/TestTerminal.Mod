MODULE TestTerminal; (* FlTerminal: output, escape sequences, the history, resizing and selecting *)

IMPORT Strings, Fl, FlTerminal, Check, Probe;

CONST
  Esc = 1BX;
  LF = 0AX;

TYPE
  (* A terminal that counts what is sent to it. *)
  Term = POINTER TO RECORD (FlTerminal.TerminalDesc)
    draws, pushes, resizes: INTEGER
  END;

VAR
  win: Fl.Window;
  t: FlTerminal.Terminal;
  s: ARRAY 65536 OF CHAR;
  ok: BOOLEAN;

PROCEDURE (t: Term) Draw*;
BEGIN INC(t.draws); t.Draw^
END Draw;

PROCEDURE (t: Term) Handle*(event: INTEGER): BOOLEAN;
BEGIN
  IF event = Fl.EvPush THEN INC(t.pushes) END;
  RETURN t.Handle^(event)
END Handle;

PROCEDURE (t: Term) Resize*(x, y, w, h: INTEGER);
BEGIN INC(t.resizes); t.Resize^(x, y, w, h)
END Resize;

(* The escape sequence ESC [ seq, for Append. *)
PROCEDURE Csi(t: FlTerminal.Terminal; seq-: ARRAY OF CHAR);
  VAR e: ARRAY 64 OF CHAR;
BEGIN
  e[0] := Esc; e[1] := "["; e[2] := 0X;
  Strings.Append(seq, e);
  t.Append(e)
END Csi;

(* Line n, from 0, of the terminal's text is line. *)
PROCEDURE Line(t: FlTerminal.Terminal; n: INTEGER; line-: ARRAY OF CHAR): BOOLEAN;
  VAR i, j: INTEGER;
BEGIN
  t.Text(s, TRUE);
  i := 0;
  WHILE n > 0 DO
    WHILE (s[i] # LF) & (s[i] # 0X) DO INC(i) END;
    IF s[i] = 0X THEN RETURN FALSE END;
    INC(i); DEC(n)
  END;
  j := 0;
  WHILE (line[j] # 0X) & (s[i + j] = line[j]) DO INC(j) END;
  RETURN (line[j] = 0X) & ((s[i + j] = LF) OR (s[i + j] = 0X))
END Line;

PROCEDURE Open(wide, high: INTEGER);
BEGIN
  NEW(win); Fl.OpenWindow(win, wide, high, "terminal");
  NEW(t); FlTerminal.OpenTerminal(t, 0, 0, wide, high, "");
  win.End
END Open;

PROCEDURE Close;
BEGIN
  win.Delete;
  Check.Check(Fl.OpenWidgets() = 0, "every widget is gone")
END Close;

PROCEDURE TestSettings;
  VAR e: ARRAY 8 OF CHAR; r: LONGREAL;
BEGIN
  Open(400, 300);
  Check.Check(t.Ansi() & ~t.ShowUnknown(), "ansi on, unknown characters not shown");
  Check.Check(t.RedrawStyle() = FlTerminal.RateLimited, "rate limited");
  Check.Check(t.HistoryRows() = 100, "100 rows of history");
  Check.Check(t.HistoryUse() = 0, "none used");
  Check.Check(t.BoxType() = Fl.DownFrame, "a down frame");
  Check.Check(t.OutputTranslate() = FlTerminal.OutLfToCrLf, "a line feed is both");
  Check.Check(t.HScrollbarStyle() = FlTerminal.ScrollbarAuto, "scrollbar as needed");
  t.SetHScrollbarStyle(FlTerminal.ScrollbarOn);
  Check.Check(t.HScrollbarStyle() = FlTerminal.ScrollbarOn, "scrollbar on");
  t.SetHScrollbarStyle(FlTerminal.ScrollbarOff);
  t.SetScrollbarSize(30);
  Check.Check((t.ScrollbarSize() = 30) & (t.ScrollbarActualSize() = 30), "scrollbar size");
  t.SetScrollbarSize(0);
  Check.Check((t.ScrollbarSize() = 0) & (t.ScrollbarActualSize() = Fl.ScrollbarSize()),
              "0 is FLTK's scrollbar size");
  t.SetMarginLeft(5); t.SetMarginRight(6); t.SetMarginTop(7); t.SetMarginBottom(8);
  Check.Check((t.MarginLeft() = 5) & (t.MarginRight() = 6)
              & (t.MarginTop() = 7) & (t.MarginBottom() = 8), "margins");
  t.SetTextFont(Fl.Courier);
  Check.Check(t.TextFont() = Fl.Courier, "font");
  t.SetTextSize(20);
  Check.Check(t.TextSize() = 20, "size");
  t.SetBoxType(Fl.FlatBox);
  Check.Check(t.BoxType() = Fl.FlatBox, "box");
  t.SetTextFgColor(Fl.Red); t.SetTextBgColor(Fl.Blue);
  Check.Check((t.TextFgColor() = Fl.Red) & (t.TextBgColor() = Fl.Blue), "text colors");
  t.SetTextFgColorDefault(Fl.Green); t.SetTextBgColorDefault(Fl.Yellow);
  Check.Check((t.TextFgColorDefault() = Fl.Green) & (t.TextBgColorDefault() = Fl.Yellow),
              "default colors");
  t.SetTextColor(Fl.Cyan);
  Check.Check((t.TextFgColor() = Fl.Cyan) & (t.TextFgColorDefault() = Fl.Cyan),
              "SetTextColor sets both");
  t.SetSelectionFgColor(Fl.Red); t.SetSelectionBgColor(Fl.Blue);
  Check.Check((t.SelectionFgColor() = Fl.Red) & (t.SelectionBgColor() = Fl.Blue),
              "selection colors");
  t.SetCursorFgColor(Fl.Green); t.SetCursorBgColor(Fl.Yellow);
  Check.Check((t.CursorFgColor() = Fl.Green) & (t.CursorBgColor() = Fl.Yellow),
              "cursor colors");
  t.SetTextFgColorXterm(1);
  Check.Check(t.TextFgColor() # Fl.Cyan, "an xterm foreground color");
  t.SetTextBgColorXterm(4);
  Check.Check(t.TextBgColor() # Fl.Blue, "an xterm background color");
  t.SetTextAttrib(FlTerminal.Bold + FlTerminal.Inverse);
  Check.Check(t.TextAttrib() = FlTerminal.Bold + FlTerminal.Inverse, "attributes");
  t.SetTextAttrib(FlTerminal.Normal);
  Check.Check(t.TextAttrib() = {}, "none");
  t.SetRedrawStyle(FlTerminal.PerWrite);
  Check.Check(t.RedrawStyle() = FlTerminal.PerWrite, "redraw style");
  t.SetRedrawRate(0.25D0);
  r := t.RedrawRate();
  Check.Check(r = 0.25D0, "redraw rate");
  t.SetAnsi(FALSE);
  Check.Check(~t.Ansi(), "ansi off");
  t.SetShowUnknown(TRUE);
  Check.Check(t.ShowUnknown(), "unknown characters shown");
  t.ErrorChar(e);
  Check.Check(e # "", "an error character to start with");
  Close
END TestSettings;

(* A widget opened after a terminal goes in its window: Fl_Terminal
   ends its own group. *)
PROCEDURE TestGroup;
  VAR b: Fl.Box;
BEGIN
  NEW(win); Fl.OpenWindow(win, 200, 200, "group");
  NEW(t); FlTerminal.OpenTerminal(t, 0, 0, 200, 100, "log");
  NEW(b); Fl.OpenBox(b, 0, 100, 200, 100, "");
  win.End;
  Check.Check(b.Parent() = win, "the next widget is the window's");
  Check.Check(t.Parent() = win, "and the terminal is");
  Close
END TestGroup;

PROCEDURE TestOutput;
BEGIN
  Open(400, 300);
  Check.Check(t.TextLength(FALSE) = 1, "an empty terminal is one empty line");
  t.Append("hello"); t.Append(LF); t.Append("world");
  Check.Check(t.TextLength(FALSE) = 12, "the length up to the cursor");
  Check.Check(Line(t, 0, "hello") & Line(t, 1, "world"), "two lines");
  Check.Check((t.CursorRow() = 1) & (t.CursorCol() = 5), "the cursor after them");
  Check.Check(t.TextLength(TRUE) = 10 + t.DisplayRows(), "below, every row of the screen");
  t.Clear;
  t.AppendUtf8("a"); t.AppendAscii("b"); t.PrintChar("c");
  Check.Check(t.HistoryUse() > 0, "Clear moves the screen to the history");
  t.ClearHistory;
  Check.Check(t.HistoryUse() = 0, "cleared");
  Check.Check(Line(t, 0, "abc"), "each of the ways to write");
  t.ClearScreen(FALSE);
  Check.Check(t.HistoryUse() = 0, "not to the history");
  Check.Check((t.CursorRow() = 0) & (t.CursorCol() = 3), "and the cursor stays");
  t.Append("z");
  t.ClearScreenHome(TRUE);
  Check.Check(t.HistoryUse() > 0, "to the history");
  Check.Check((t.CursorRow() = 0) & (t.CursorCol() = 0), "and the cursor is home");
  t.ResetTerminal;
  Check.Check(t.HistoryUse() = 0, "reset clears the history");
  t.ClearWith(Fl.Red);
  Check.Check(t.TextBgColor() # Fl.Red, "ClearWith leaves the text's color");
  t.ResetTerminal;
  t.SetOutputTranslate(FlTerminal.OutOff);
  Check.Check(t.OutputTranslate() = {}, "no translation");
  t.Append("a"); t.Append(LF); t.Append("b");
  Check.Check(Line(t, 1, " b"), "a line feed only goes down");
  t.ResetTerminal;
  t.SetOutputTranslate(FlTerminal.OutCrToLf);
  t.Append("c"); t.Append(0DX); t.Append("d");
  Check.Check(Line(t, 1, " d"), "a carriage return goes down");
  t.ResetTerminal;
  t.SetOutputTranslate(FlTerminal.OutLfToCrLf);
  t.PlotChar("x", 2, 3);
  Check.Check(Line(t, 2, "   x"), "plotted");
  Check.Check((t.CursorRow() = 0) & (t.CursorCol() = 0), "the cursor stays");
  t.PlotChar("", 2, 4);
  Check.Check(Line(t, 2, "   x"), "nothing to plot");
  t.PrintChar("");
  Check.Check(t.CursorCol() = 0, "nothing to print");
  Close
END TestOutput;

PROCEDURE TestUtf8;
  VAR e: ARRAY 8 OF CHAR; euro: ARRAY 4 OF CHAR;
BEGIN
  euro[0] := 0E2X; euro[1] := 82X; euro[2] := 0ACX; euro[3] := 0X;
  Open(400, 300);
  t.Append(euro);
  Check.Check(Line(t, 0, euro), "a character of three bytes");
  Check.Check(t.CursorCol() = 1, "in one cell");
  t.ResetTerminal;
  e[0] := 0E2X; e[1] := 82X; e[2] := 0X;
  t.Append(e);
  Check.Check(t.CursorCol() = 0, "a cut character waits");
  e[0] := 0ACX; e[1] := "!"; e[2] := 0X;
  t.Append(e);
  COPY(euro, e); Strings.Append("!", e);
  Check.Check(Line(t, 0, e), "for the rest of it");
  t.ResetTerminal;
  t.SetShowUnknown(TRUE);
  t.SetErrorChar("#");
  t.ErrorChar(e);
  Check.Check(e = "#", "the error character");
  (* 0FFX would wait for its rest, as the start of a long character. *)
  e[0] := 80X; e[1] := 0X;
  t.Append("a"); t.Append(e); t.Append("b");
  Check.Check(Line(t, 0, "a#b"), "shows for a bad byte");
  t.ResetTerminal;
  t.SetShowUnknown(TRUE);
  (* FLTK keeps the pointer: this one is gone when SetErrorChar returns. *)
  e := euro; t.SetErrorChar(e); e[0] := "?";
  t.ErrorChar(e);
  Check.Check(e = euro, "a character of three bytes");
  e[0] := 02X; e[1] := 0X;
  t.Append(e);
  Check.Check(Line(t, 0, euro), "shows for a control character");
  t.ResetTerminal;
  e[0] := 0F0X; e[1] := 0X;
  t.PrintChar(e);
  Check.Check(Line(t, 0, euro), "and for a cut one");
  t.PlotChar(e, 1, 0);
  Check.Check(Line(t, 1, euro), "plotted too");
  Close
END TestUtf8;

PROCEDURE TestEscapes;
  VAR fg, bg: INTEGER;
BEGIN
  Open(400, 300);
  fg := t.TextFgColor(); bg := t.TextBgColor();
  Csi(t, "31;42m");
  t.Append("red");
  Check.Check(Line(t, 0, "red"), "the sequence is not in the text");
  Check.Check((t.TextFgColor() # fg) & (t.TextBgColor() # bg), "colors");
  Csi(t, "0m");
  Check.Check((t.TextFgColor() = fg) & (t.TextBgColor() = bg), "and back");
  Csi(t, "1m");
  Check.Check(FlTerminal.Bold * t.TextAttrib() # {}, "bold");
  Csi(t, "0m");
  Csi(t, "3;5H");
  Check.Check((t.CursorRow() = 2) & (t.CursorCol() = 4), "the cursor moved");
  Csi(t, "2J");
  Check.Check(Line(t, t.HistoryUse(), ""), "the screen cleared");
  t.SetAnsi(FALSE);
  Csi(t, "1;1H");
  Check.Check((t.CursorRow() = 2) & (t.CursorCol() # 0), "not read with ansi off");
  Close
END TestEscapes;

PROCEDURE TestCursor;
BEGIN
  Open(400, 300);
  t.SetCursorRow(3); t.SetCursorCol(10);
  Check.Check((t.CursorRow() = 3) & (t.CursorCol() = 10), "set");
  t.SetCursorRow(100000); t.SetCursorCol(100000);
  Check.Check((t.CursorRow() = t.DisplayRows() - 1) & (t.CursorCol() = t.DisplayColumns() - 1),
              "kept on the screen");
  t.SetCursorRow(3); t.SetCursorCol(10);
  t.CursorUp(1, FALSE); t.CursorLeft(2);
  Check.Check((t.CursorRow() = 2) & (t.CursorCol() = 8), "up, left");
  t.CursorDown(2, FALSE); t.CursorRight(3, FALSE);
  Check.Check((t.CursorRow() = 4) & (t.CursorCol() = 11), "down, right");
  t.CursorUp(0, FALSE); t.CursorDown(0, FALSE); t.CursorLeft(0); t.CursorRight(0, FALSE);
  Check.Check((t.CursorRow() = 4) & (t.CursorCol() = 11), "no count, no move");
  t.CursorEol;
  Check.Check(t.CursorCol() = t.DisplayColumns() - 1, "end of the line");
  t.CursorSol;
  Check.Check(t.CursorCol() = 0, "start of the line");
  t.SetCursorCol(4); t.CursorCr;
  Check.Check(t.CursorCol() = 0, "carriage return");
  t.SetCursorCol(4); t.CursorCrLf(2);
  Check.Check((t.CursorRow() = 6) & (t.CursorCol() = 0), "two lines down");
  t.CursorTabRight(1);
  Check.Check(t.CursorCol() = 8, "a tab stop");
  t.CursorTabLeft(1);
  Check.Check(t.CursorCol() = 0, "and back");
  t.CursorTabRight(2);
  Check.Check(t.CursorCol() = 16, "two tab stops");
  t.SetCursorCol(24); t.CursorTabLeft(2);
  Check.Check(t.CursorCol() = 8, "and two back");
  t.CursorTabRight(10000);
  Check.Check(t.CursorCol() = t.DisplayColumns() - 1, "no further than the end of the line");
  t.CursorTabLeft(10000);
  Check.Check(t.CursorCol() = 0, "nor the start");
  t.CursorHome;
  Check.Check((t.CursorRow() = 0) & (t.CursorCol() = 0), "home");
  t.CursorUp(1, FALSE);
  Check.Check(t.CursorRow() = 0, "stops at the top");
  (* doc/fltk-issues.md, 97: FLTK's own wouldn't go back to column 1. *)
  t.SetCursorRow(2); t.SetCursorCol(1);
  t.SaveCursor;
  t.CursorHome;
  t.RestoreCursor;
  Check.Check((t.CursorRow() = 2) & (t.CursorCol() = 1), "restored to column 1");
  Close
END TestCursor;

PROCEDURE Decimal(i: INTEGER; VAR s: ARRAY OF CHAR);
  VAR k: INTEGER; d: ARRAY 2 OF CHAR;
BEGIN
  s[0] := 0X; k := i;
  REPEAT
    d[0] := CHR(ORD("0") + k MOD 10); d[1] := 0X;
    Strings.Insert(d, 0, s);
    k := k DIV 10
  UNTIL k = 0
END Decimal;

PROCEDURE TestHistory;
  VAR i: INTEGER; n: ARRAY 16 OF CHAR;
BEGIN
  Open(400, 300);
  t.SetHistoryRows(50);
  Check.Check(t.HistoryRows() = 50, "history size");
  i := 0;
  WHILE i < 200 DO
    Decimal(i, n); t.Append(n); t.Append(LF);
    INC(i)
  END;
  Check.Check(t.HistoryUse() = 50, "the history fills");
  Decimal(200 - 50 - t.DisplayRows() + 1, n);
  Check.Check(Line(t, 0, n), "with the last lines");
  t.SetHistoryRows(0);
  Check.Check((t.HistoryRows() = 0) & (t.HistoryUse() = 0), "no history");
  Close
END TestHistory;

(* doc/fltk-issues.md, 96: writing after each of these went outside the
   row, which valgrind sees, or would. *)
PROCEDURE TestShrink;
  VAR rows: INTEGER;
BEGIN
  Open(400, 300);
  rows := t.DisplayRows();
  t.SetCursorRow(rows - 1); t.SetCursorCol(40);
  t.SetDisplayRows(3);
  Check.Check(t.CursorRow() < t.DisplayRows(), "fewer rows, on the screen");
  t.Append("a");
  t.Resize(0, 0, 400, 300);
  t.SetCursorCol(t.DisplayColumns() - 1);
  t.SetDisplayColumns(20);
  Check.Check(t.CursorCol() < t.DisplayColumns(), "fewer columns, on the screen");
  t.Append("b");
  t.Resize(0, 0, 400, 300);
  t.SetDisplayColumns(50);
  t.SetCursorRow(t.DisplayRows() - 1); t.SetCursorCol(49);
  Csi(t, "s");
  t.SetDisplayColumns(15); t.Resize(0, 0, 400, 40);
  Csi(t, "u");
  Check.Check((t.CursorRow() < t.DisplayRows()) & (t.CursorCol() < t.DisplayColumns()),
              "a saved cursor comes back on the screen");
  t.Append("c");
  t.Resize(0, 0, 400, 300);
  t.SetCursorRow(t.DisplayRows() - 1);
  t.SetTextSize(40);
  Check.Check(t.CursorRow() < t.DisplayRows(), "a larger font, on the screen");
  t.Append("d");
  t.SetTextSize(14);
  t.SetCursorRow(t.DisplayRows() - 1);
  t.SetMarginBottom(200);
  Check.Check(t.CursorRow() < t.DisplayRows(), "a larger margin, on the screen");
  t.Append("e");
  t.SetMarginBottom(0);
  t.SetCursorRow(t.DisplayRows() - 1);
  t.Resize(0, 0, 400, 60);
  Check.Check(t.CursorRow() < t.DisplayRows(), "a smaller widget, on the screen");
  t.Append("f");
  Close
END TestShrink;

PROCEDURE TestSizes;
  VAR rows, cols: INTEGER;
BEGIN
  Open(400, 300);
  t.SetTextFont(Fl.Courier);
  ok := Probe.Capture(t);
  Probe.Release;
  rows := t.DisplayRows(); cols := t.DisplayColumns();
  Check.Check((rows > 2) & (cols > 10), "rows and columns fit its size");
  t.SetDisplayColumns(cols + 50);
  Check.Check(t.DisplayColumns() = cols + 50, "more columns stay");
  t.SetDisplayRows(5);
  Check.Check(t.DisplayRows() > 0, "the rows are something");
  t.Resize(0, 0, 400, 200);
  Check.Check(t.DisplayRows() < rows, "a shorter widget has fewer");
  Check.Check(t.DisplayColumns() = cols + 50, "and keeps its columns");
  t.SetTextSize(t.TextSize() * 2);
  t.SetHistoryRows(0);
  rows := t.DisplayRows();
  t.Resize(0, 0, 400, 400);
  Check.Check(t.DisplayRows() > rows, "a taller widget has more");
  Close
END TestSizes;

PROCEDURE TestDrawing;
  VAR before, x, y: INTEGER; differs: BOOLEAN;
BEGIN
  Open(200, 100);
  t.SetTextFont(Fl.Courier);
  ok := Probe.Capture(t);
  Check.Check(ok, "drawn");
  before := Probe.Pixel(10, 10);
  Probe.Release;
  Csi(t, "41m");
  t.Append("        ");
  ok := Probe.Capture(t);
  Check.Check(Probe.Pixel(10, 10) # before, "a background color shows");
  Probe.Release;
  t.ResetTerminal;
  t.Append("xxxxxxxxxx");
  ok := Probe.Capture(t);
  differs := FALSE;
  y := 4;
  WHILE y < 20 DO
    x := 4;
    WHILE x < 60 DO
      differs := differs OR (Probe.Pixel(x, y) # before);
      INC(x)
    END;
    INC(y)
  END;
  Probe.Release;
  Check.Check(differs, "text shows");
  Close
END TestDrawing;

PROCEDURE TestSelection;
BEGIN
  Open(400, 300);
  t.SetTextFont(Fl.Courier);
  t.Append("selected");
  ok := Probe.Capture(t);
  Probe.Release;
  t.SelectionText(s);
  Check.Check((s = "") & (t.SelectionTextLength() = 0), "nothing selected");
  ok := Probe.Mouse(win, Fl.EvPush, 8, 12, 1, Fl.Button1, 1);
  ok := Probe.Mouse(win, Fl.EvDrag, 390, 12, 1, Fl.Button1, 1);
  ok := Probe.Mouse(win, Fl.EvRelease, 390, 12, 1, {}, 1);
  t.SelectionText(s);
  Check.Check(Strings.Pos("lec", s, 0) >= 0, "the mouse selects text");
  Check.Check(t.SelectionTextLength() > 0, "of some length");
  Close
END TestSelection;

PROCEDURE TestSubclass;
  VAR n: Term;
BEGIN
  NEW(win); Fl.OpenWindow(win, 200, 100, "subclass");
  NEW(n); FlTerminal.OpenTerminal(n, 0, 0, 200, 100, "");
  win.End;
  ok := Probe.Capture(n);
  Probe.Release;
  Check.Check(n.draws = 1, "Draw is the program's");
  ok := Probe.Mouse(win, Fl.EvPush, 50, 50, 1, Fl.Button1, 1);
  ok := Probe.Mouse(win, Fl.EvRelease, 50, 50, 1, {}, 1);
  Check.Check(n.pushes = 1, "and Handle");
  n.Resize(0, 0, 150, 80);
  Check.Check(n.resizes = 1, "and Resize");
  Close
END TestSubclass;

(* A redraw on FLTK's timer is pending when the terminal goes. *)
(* Each style redraws whenever text is written, not just the first time. *)
PROCEDURE TestRedraw;
  VAR i: INTEGER;
BEGIN
  Open(200, 100);
  t.SetRedrawStyle(FlTerminal.PerWrite);
  t.ClearDamage; t.Append("a");
  Check.Check(t.Damage() # {}, "PerWrite: a write redraws");
  ok := Probe.Capture(t); Probe.Release;
  t.ClearDamage; t.Append("b");
  Check.Check(t.Damage() # {}, "and so does the next, once drawn");
  ok := Probe.Capture(t); Probe.Release;
  t.ClearDamage; t.SetRedrawStyle(FlTerminal.RateLimited); t.Append("c");
  i := 0;
  WHILE (i < 500) & (t.Damage() = {}) DO Fl.Wait(0.01D0); INC(i) END;
  Check.Check(t.Damage() # {}, "RateLimited, after PerWrite");
  ok := Probe.Capture(t); Probe.Release;
  t.ClearDamage; t.Append("d"); t.SetRedrawStyle(FlTerminal.PerWrite);
  Check.Check(t.Damage() # {}, "a write waiting for RateLimited's timer is drawn when the style changes");
  ok := Probe.Capture(t); Probe.Release;
  t.ClearDamage; t.Append("e");
  Check.Check(t.Damage() # {}, "and PerWrite redraws after it");
  Close
END TestRedraw;

PROCEDURE TestPending;
  VAR i: INTEGER;
BEGIN
  Open(200, 100);
  win.Show;
  t.Append("pending");
  t.SetRedrawRate(0.01D0);
  t.Delete;
  i := 0;
  WHILE i < 5 DO ok := Fl.Check(); INC(i) END;
  Check.Check(~t.IsOpen(), "deleted with a redraw waiting");
  Close
END TestPending;

BEGIN
  TestSettings;
  TestGroup;
  TestOutput;
  TestUtf8;
  TestEscapes;
  TestCursor;
  TestHistory;
  TestShrink;
  TestSizes;
  TestDrawing;
  TestSelection;
  TestSubclass;
  TestRedraw;
  TestPending;
  Check.Summary
END TestTerminal.
