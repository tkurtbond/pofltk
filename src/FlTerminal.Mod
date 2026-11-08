MODULE FlTerminal; (* Fl_Terminal: a screen of text for a program's output, with a history and ANSI colors *)

(* A Terminal shows what a program writes to it (Append, AppendUtf8,
   AppendAscii): rows of cells, each one UTF-8 character with its colors
   and attributes. Rows that scroll off the top go into a history of
   HistoryRows rows, which its scrollbar shows. The user can select text
   with the mouse, and copy it; nothing typed reaches the program, so a
   program that wants input takes it from a widget of its own. There is
   no printf: format the text in Oberon, and Append it.

   With Ansi on, as it is at first, text may hold xterm's escape
   sequences, for colors, moving the cursor, clearing and so on.
   FLTK's documentation of Fl_Terminal lists them.

   The screen holds as many rows as its height allows, whatever
   SetDisplayRows says at the next change of size, and at least as many
   columns as its width allows. Output that fills it scrolls.

   Writing goes to the screen at the next redraw, by RedrawStyle. Clear,
   ClearWith and ClearScreenHome push the screen into the history; so
   does ClearScreen(TRUE).

   A character cut by the end of an Append waits for the rest of it in
   the next, ahead of anything else: Append of 0C3X, then "x", then 0A9X
   shows "x" and then the character.

   The sizes are limited: rows on the screen and in the history together,
   by columns, come to at most MaxCells. The C++ part is FlTerminal.cpp. *)

IMPORT SYSTEM, Fl;

CONST
(* BEGIN generated constants: tools/gen-constants.py writes this block,
   from FLTK's headers; edit the script, not the block. *)

  (* what the text looks like (Terminal.SetTextAttrib) *)
  Normal* = {};
  Bold* = {0};
  Dim* = {1};
  Italic* = {2};
  Underline* = {3};
  Inverse* = {5};
  Strikeout* = {7};

  (* what a carriage return and a line feed do (Terminal.SetOutputTranslate) *)
  OutOff* = {};
  OutCrToLf* = {0};
  OutLfToCr* = {1};
  OutLfToCrLf* = {2};

  (* when text is drawn (Terminal.SetRedrawStyle) *)
  NoRedraw* = 0;
  RateLimited* = 1;
  PerWrite* = 2;

  (* the horizontal scrollbar (Terminal.SetHScrollbarStyle) *)
  ScrollbarOff* = 0;
  ScrollbarAuto* = 1;
  ScrollbarOn* = 2;
(* END generated constants *)

  MaxCells* = 16777216;  (* rows on the screen and in the history, by columns *)

  (* The properties of ofl_terminal_get and ofl_terminal_set. *)
  displayRows = 0; displayColumns = 1; historyRows = 2; historyUse = 3;
  scrollbarSize = 4; scrollbarActualSize = 5; hScrollbarStyle = 6;
  marginLeft = 7; marginRight = 8; marginTop = 9; marginBottom = 10;
  textFont = 11; textSize = 12; textAttrib = 13; redrawStyle = 14;
  showUnknown = 15; ansi = 16; outputTranslate = 17;
  cursorRow = 18; cursorCol = 19;

  (* The colors of ofl_terminal_color and ofl_terminal_set_color. *)
  fg = 0; bg = 1; fgDefault = 2; bgDefault = 3; selFg = 4; selBg = 5;
  cursorFg = 6; cursorBg = 7; fgAndDefault = 8;

  (* The movements of ofl_terminal_cursor. *)
  up = 0; down = 1; left = 2; right = 3; home = 4; eol = 5; sol = 6;
  cr = 7; crlf = 8; tabRight = 9; tabLeft = 10; save = 11; restore = 12;

  (* The numbers of ofl_terminal_ring. *)
  ringRows = 0; ringCols = 1; ringOffset = 2; histStart = 3; histEnd = 4;
  dispStart = 5; dispEnd = 6; styleFlags = 7;

TYPE
  (* FLTK's is a group, but its scrollbars are its own, so this is a
     widget. *)
  Terminal* = POINTER TO TerminalDesc;
  TerminalDesc* = RECORD (Fl.WidgetDesc) END;

PROCEDURE ["C", "ofl_terminal_new"] CNew(x, y, w, h: SYSTEM.INT32; label: ARRAY OF CHAR; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_terminal_fits"] CFits(rows, history, columns: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_terminal_get"] CGet(t: SYSTEM.ADDRESS; what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_terminal_set"] CSet(t: SYSTEM.ADDRESS; what, v: SYSTEM.INT32);
PROCEDURE ["C", "ofl_terminal_color"] CColor(t: SYSTEM.ADDRESS; what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_terminal_set_color"] CSetColor(t: SYSTEM.ADDRESS; what, c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_terminal_set_xterm"] CSetXterm(t: SYSTEM.ADDRESS; background, c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_terminal_box"] CBox(t: SYSTEM.ADDRESS; b: SYSTEM.INT32);
PROCEDURE ["C", "ofl_terminal_redraw_rate"] CRedrawRate(t: SYSTEM.ADDRESS): LONGREAL;
PROCEDURE ["C", "ofl_terminal_set_redraw_rate"] CSetRedrawRate(t: SYSTEM.ADDRESS; rate: LONGREAL);
PROCEDURE ["C", "ofl_terminal_set_error_char"] CSetErrorChar(t: SYSTEM.ADDRESS; s: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_terminal_error_char"] CErrorChar(t: SYSTEM.ADDRESS; VAR s: ARRAY OF CHAR; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_terminal_append"] CAppend(t: SYSTEM.ADDRESS; s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_terminal_append_ascii"] CAppendAscii(t: SYSTEM.ADDRESS; s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_terminal_append_utf8"] CAppendUtf8(t: SYSTEM.ADDRESS; s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_terminal_print_char"] CPrintChar(t: SYSTEM.ADDRESS; s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_terminal_plot_char"] CPlotChar(t: SYSTEM.ADDRESS; s: ARRAY OF CHAR; row, col: SYSTEM.INT32);
PROCEDURE ["C", "ofl_terminal_clear"] CClear(t: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_terminal_clear_color"] CClearColor(t: SYSTEM.ADDRESS; c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_terminal_clear_screen"] CClearScreen(t: SYSTEM.ADDRESS; toHistory, home: SYSTEM.INT32);
PROCEDURE ["C", "ofl_terminal_clear_history"] CClearHistory(t: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_terminal_reset"] CReset(t: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_terminal_cursor"] CCursor(t: SYSTEM.ADDRESS; what, count, scroll: SYSTEM.INT32);
PROCEDURE ["C", "ofl_terminal_text"] CText(t: SYSTEM.ADDRESS; below: SYSTEM.INT32; VAR s: ARRAY OF CHAR; n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_terminal_selection"] CSelection(t: SYSTEM.ADDRESS; VAR s: ARRAY OF CHAR; n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_terminal_get_selection"] CGetSelection(t: SYSTEM.ADDRESS; VAR srow, scol, erow, ecol: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_terminal_ring"] CRing(t: SYSTEM.ADDRESS; what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_terminal_cell"] CCell(t: SYSTEM.ADDRESS; row, col: SYSTEM.INT32; VAR s: ARRAY OF CHAR; n: SYSTEM.INT32; VAR attrib, fg, bg: SYSTEM.INT32);

PROCEDURE OpenTerminal*(t: Terminal; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Fl.EndOpen(t, CNew(x, y, w, h, label, Fl.BeginOpen(t)))
END OpenTerminal;

PROCEDURE Flag(b: BOOLEAN): SYSTEM.INT32;
BEGIN IF b THEN RETURN 1 ELSE RETURN 0 END
END Flag;

PROCEDURE Get(t: Terminal; what: INTEGER): INTEGER;
BEGIN RETURN CGet(Fl.Live(t), what)
END Get;

PROCEDURE Set(t: Terminal; what, v: INTEGER);
BEGIN CSet(Fl.Live(t), what, v)
END Set;

(* The sizes given must fit, and be sizes. *)
PROCEDURE CheckSize(rows, history, columns: INTEGER);
BEGIN
  ASSERT((rows >= 1) & (history >= 0) & (columns >= 1)
    & (CFits(rows, history, columns) # 0), Fl.Unsupported)
END CheckSize;

(* size *)

PROCEDURE (t: Terminal) DisplayRows*(): INTEGER;
BEGIN RETURN Get(t, displayRows)
END DisplayRows;

(* The screen goes back to what fits its height at the next change of
   its size or font. *)
PROCEDURE (t: Terminal) SetDisplayRows*(n: INTEGER);
BEGIN
  CheckSize(n, Get(t, historyRows), Get(t, displayColumns));
  Set(t, displayRows, n)
END SetDisplayRows;

PROCEDURE (t: Terminal) DisplayColumns*(): INTEGER;
BEGIN RETURN Get(t, displayColumns)
END DisplayColumns;

(* More columns than fit show a horizontal scrollbar, by its style; a
   change of size only ever adds columns. *)
PROCEDURE (t: Terminal) SetDisplayColumns*(n: INTEGER);
BEGIN
  CheckSize(Get(t, displayRows), Get(t, historyRows), n);
  Set(t, displayColumns, n)
END SetDisplayColumns;

PROCEDURE (t: Terminal) HistoryRows*(): INTEGER;
BEGIN RETURN Get(t, historyRows)
END HistoryRows;

PROCEDURE (t: Terminal) SetHistoryRows*(n: INTEGER);
BEGIN
  CheckSize(Get(t, displayRows), n, Get(t, displayColumns));
  Set(t, historyRows, n)
END SetHistoryRows;

(* The rows of the history holding text. *)
PROCEDURE (t: Terminal) HistoryUse*(): INTEGER;
BEGIN RETURN Get(t, historyUse)
END HistoryUse;

(* 0 is Fl.ScrollbarSize's. *)
PROCEDURE (t: Terminal) ScrollbarSize*(): INTEGER;
BEGIN RETURN Get(t, scrollbarSize)
END ScrollbarSize;

PROCEDURE (t: Terminal) SetScrollbarSize*(n: INTEGER);
BEGIN Set(t, scrollbarSize, n)
END SetScrollbarSize;

PROCEDURE (t: Terminal) ScrollbarActualSize*(): INTEGER;
BEGIN RETURN Get(t, scrollbarActualSize)
END ScrollbarActualSize;

PROCEDURE (t: Terminal) HScrollbarStyle*(): INTEGER;
BEGIN RETURN Get(t, hScrollbarStyle)
END HScrollbarStyle;

(* style is ScrollbarOff, ScrollbarAuto or ScrollbarOn. *)
PROCEDURE (t: Terminal) SetHScrollbarStyle*(style: INTEGER);
BEGIN
  ASSERT((style >= ScrollbarOff) & (style <= ScrollbarOn), Fl.IndexOutOfRange);
  Set(t, hScrollbarStyle, style)
END SetHScrollbarStyle;

PROCEDURE (t: Terminal) MarginLeft*(): INTEGER;
BEGIN RETURN Get(t, marginLeft)
END MarginLeft;

PROCEDURE (t: Terminal) SetMarginLeft*(n: INTEGER);
BEGIN Set(t, marginLeft, n)
END SetMarginLeft;

PROCEDURE (t: Terminal) MarginRight*(): INTEGER;
BEGIN RETURN Get(t, marginRight)
END MarginRight;

PROCEDURE (t: Terminal) SetMarginRight*(n: INTEGER);
BEGIN Set(t, marginRight, n)
END SetMarginRight;

PROCEDURE (t: Terminal) MarginTop*(): INTEGER;
BEGIN RETURN Get(t, marginTop)
END MarginTop;

PROCEDURE (t: Terminal) SetMarginTop*(n: INTEGER);
BEGIN Set(t, marginTop, n)
END SetMarginTop;

PROCEDURE (t: Terminal) MarginBottom*(): INTEGER;
BEGIN RETURN Get(t, marginBottom)
END MarginBottom;

PROCEDURE (t: Terminal) SetMarginBottom*(n: INTEGER);
BEGIN Set(t, marginBottom, n)
END SetMarginBottom;

(* FLTK lays the screen out again for a new box, as Fl_Widget's doesn't. *)
PROCEDURE (t: Terminal) SetBoxType*(b: INTEGER);
BEGIN
  t.SetBoxType^(b);
  CBox(Fl.Live(t), b)
END SetBoxType;

(* text *)

PROCEDURE (t: Terminal) TextFont*(): INTEGER;
BEGIN RETURN Get(t, textFont)
END TextFont;

PROCEDURE (t: Terminal) SetTextFont*(font: INTEGER);
BEGIN Set(t, textFont, font)
END SetTextFont;

PROCEDURE (t: Terminal) TextSize*(): INTEGER;
BEGIN RETURN Get(t, textSize)
END TextSize;

(* FLTK divides by a size below 1. *)
PROCEDURE (t: Terminal) SetTextSize*(size: INTEGER);
BEGIN
  ASSERT(size >= 1, Fl.Unsupported);
  Set(t, textSize, size)
END SetTextSize;

PROCEDURE (t: Terminal) TextFgColor*(): INTEGER;
BEGIN RETURN CColor(Fl.Live(t), fg)
END TextFgColor;

PROCEDURE (t: Terminal) SetTextFgColor*(c: INTEGER);
BEGIN CSetColor(Fl.Live(t), fg, c)
END SetTextFgColor;

PROCEDURE (t: Terminal) TextBgColor*(): INTEGER;
BEGIN RETURN CColor(Fl.Live(t), bg)
END TextBgColor;

(* 0FFFFFFFFH, -1, is no color of its own: the widget's shows. *)
PROCEDURE (t: Terminal) SetTextBgColor*(c: INTEGER);
BEGIN CSetColor(Fl.Live(t), bg, c)
END SetTextBgColor;

(* What an escape sequence's reset goes back to. *)
PROCEDURE (t: Terminal) TextFgColorDefault*(): INTEGER;
BEGIN RETURN CColor(Fl.Live(t), fgDefault)
END TextFgColorDefault;

PROCEDURE (t: Terminal) SetTextFgColorDefault*(c: INTEGER);
BEGIN CSetColor(Fl.Live(t), fgDefault, c)
END SetTextFgColorDefault;

PROCEDURE (t: Terminal) TextBgColorDefault*(): INTEGER;
BEGIN RETURN CColor(Fl.Live(t), bgDefault)
END TextBgColorDefault;

PROCEDURE (t: Terminal) SetTextBgColorDefault*(c: INTEGER);
BEGIN CSetColor(Fl.Live(t), bgDefault, c)
END SetTextBgColorDefault;

(* The text's color now and its default. *)
PROCEDURE (t: Terminal) SetTextColor*(c: INTEGER);
BEGIN CSetColor(Fl.Live(t), fgAndDefault, c)
END SetTextColor;

(* The text's color by an xterm color number: 0 to 7, the eight colors,
   39, the default foreground color, or 49, the default background color.
   FLTK takes any other number below 256 modulo 8. *)
PROCEDURE (t: Terminal) SetTextFgColorXterm*(n: INTEGER);
BEGIN
  ASSERT((n >= 0) & (n <= 255), Fl.IndexOutOfRange);
  CSetXterm(Fl.Live(t), 0, n)
END SetTextFgColorXterm;

PROCEDURE (t: Terminal) SetTextBgColorXterm*(n: INTEGER);
BEGIN
  ASSERT((n >= 0) & (n <= 255), Fl.IndexOutOfRange);
  CSetXterm(Fl.Live(t), 1, n)
END SetTextBgColorXterm;

PROCEDURE (t: Terminal) SelectionFgColor*(): INTEGER;
BEGIN RETURN CColor(Fl.Live(t), selFg)
END SelectionFgColor;

PROCEDURE (t: Terminal) SetSelectionFgColor*(c: INTEGER);
BEGIN CSetColor(Fl.Live(t), selFg, c)
END SetSelectionFgColor;

PROCEDURE (t: Terminal) SelectionBgColor*(): INTEGER;
BEGIN RETURN CColor(Fl.Live(t), selBg)
END SelectionBgColor;

PROCEDURE (t: Terminal) SetSelectionBgColor*(c: INTEGER);
BEGIN CSetColor(Fl.Live(t), selBg, c)
END SetSelectionBgColor;

PROCEDURE (t: Terminal) CursorFgColor*(): INTEGER;
BEGIN RETURN CColor(Fl.Live(t), cursorFg)
END CursorFgColor;

PROCEDURE (t: Terminal) SetCursorFgColor*(c: INTEGER);
BEGIN CSetColor(Fl.Live(t), cursorFg, c)
END SetCursorFgColor;

PROCEDURE (t: Terminal) CursorBgColor*(): INTEGER;
BEGIN RETURN CColor(Fl.Live(t), cursorBg)
END CursorBgColor;

PROCEDURE (t: Terminal) SetCursorBgColor*(c: INTEGER);
BEGIN CSetColor(Fl.Live(t), cursorBg, c)
END SetCursorBgColor;

(* The attributes of the text to come. *)
PROCEDURE (t: Terminal) TextAttrib*(): SET;
BEGIN RETURN SYSTEM.VAL(SET, Get(t, textAttrib))
END TextAttrib;

(* attrib holds Bold, Dim, Italic, Underline, Inverse and Strikeout. *)
PROCEDURE (t: Terminal) SetTextAttrib*(attrib: SET);
BEGIN
  ASSERT(attrib - {0 .. 7} = {}, Fl.IndexOutOfRange);
  Set(t, textAttrib, ORD(attrib))
END SetTextAttrib;

(* behaviour *)

PROCEDURE (t: Terminal) RedrawStyle*(): INTEGER;
BEGIN RETURN Get(t, redrawStyle)
END RedrawStyle;

(* style is NoRedraw, the program calling Redraw itself; RateLimited,
   as it is at first, every RedrawRate seconds while text comes; or
   PerWrite. *)
PROCEDURE (t: Terminal) SetRedrawStyle*(style: INTEGER);
BEGIN
  ASSERT((style >= NoRedraw) & (style <= PerWrite), Fl.IndexOutOfRange);
  Set(t, redrawStyle, style)
END SetRedrawStyle;

PROCEDURE (t: Terminal) RedrawRate*(): LONGREAL;
BEGIN RETURN CRedrawRate(Fl.Live(t))
END RedrawRate;

PROCEDURE (t: Terminal) SetRedrawRate*(seconds: LONGREAL);
BEGIN CSetRedrawRate(Fl.Live(t), seconds)
END SetRedrawRate;

(* Whether bad UTF-8, and control characters and escape sequences not
   known, show the error character, not nothing. *)
PROCEDURE (t: Terminal) ShowUnknown*(): BOOLEAN;
BEGIN RETURN Get(t, showUnknown) # 0
END ShowUnknown;

PROCEDURE (t: Terminal) SetShowUnknown*(b: BOOLEAN);
BEGIN Set(t, showUnknown, Flag(b))
END SetShowUnknown;

PROCEDURE (t: Terminal) ErrorChar*(VAR s: ARRAY OF CHAR);
BEGIN CErrorChar(Fl.Live(t), s, SHORT(LEN(s)))
END ErrorChar;

(* s must be one printable UTF-8 character. *)
PROCEDURE (t: Terminal) SetErrorChar*(s-: ARRAY OF CHAR);
BEGIN
  ASSERT(CSetErrorChar(Fl.Live(t), s) # 0, Fl.Unsupported)
END SetErrorChar;

PROCEDURE (t: Terminal) Ansi*(): BOOLEAN;
BEGIN RETURN Get(t, ansi) # 0
END Ansi;

PROCEDURE (t: Terminal) SetAnsi*(b: BOOLEAN);
BEGIN Set(t, ansi, Flag(b))
END SetAnsi;

(* What a carriage return and a line feed in the text do. *)
PROCEDURE (t: Terminal) OutputTranslate*(): SET;
BEGIN RETURN SYSTEM.VAL(SET, Get(t, outputTranslate))
END OutputTranslate;

(* flags holds OutCrToLf, OutLfToCr and OutLfToCrLf; {}, neither is
   changed. OutLfToCrLf is the one at first. *)
PROCEDURE (t: Terminal) SetOutputTranslate*(flags: SET);
BEGIN
  ASSERT(flags - (OutCrToLf + OutLfToCr + OutLfToCrLf) = {}, Fl.IndexOutOfRange);
  Set(t, outputTranslate, ORD(flags))
END SetOutputTranslate;

(* output *)

(* Writes s, UTF-8 text, at the cursor. *)
PROCEDURE (t: Terminal) Append*(s-: ARRAY OF CHAR);
BEGIN CAppend(Fl.Live(t), s)
END Append;

PROCEDURE (t: Terminal) AppendUtf8*(s-: ARRAY OF CHAR);
BEGIN CAppendUtf8(Fl.Live(t), s)
END AppendUtf8;

(* s is ASCII; any other byte is unknown. *)
PROCEDURE (t: Terminal) AppendAscii*(s-: ARRAY OF CHAR);
BEGIN CAppendAscii(Fl.Live(t), s)
END AppendAscii;

(* Writes s, one UTF-8 character, at the cursor, which moves on. A
   control character does what it does in Append. Anything else in s is
   unknown. *)
PROCEDURE (t: Terminal) PrintChar*(s-: ARRAY OF CHAR);
BEGIN CPrintChar(Fl.Live(t), s)
END PrintChar;

(* Writes s, one UTF-8 character, in a cell of the screen. The cursor
   stays. *)
PROCEDURE (t: Terminal) PlotChar*(s-: ARRAY OF CHAR; row, col: INTEGER);
BEGIN
  ASSERT((row >= 0) & (row < t.DisplayRows())
    & (col >= 0) & (col < t.DisplayColumns()), Fl.IndexOutOfRange);
  CPlotChar(Fl.Live(t), s, row, col)
END PlotChar;

(* Moves the screen into the history, and homes the cursor. *)
PROCEDURE (t: Terminal) Clear*;
BEGIN CClear(Fl.Live(t))
END Clear;

(* The same, the cells cleared to color c. *)
PROCEDURE (t: Terminal) ClearWith*(c: INTEGER);
BEGIN CClearColor(Fl.Live(t), c)
END ClearWith;

(* The cursor stays. toHistory moves the screen to the history. *)
PROCEDURE (t: Terminal) ClearScreen*(toHistory: BOOLEAN);
BEGIN CClearScreen(Fl.Live(t), Flag(toHistory), 0)
END ClearScreen;

PROCEDURE (t: Terminal) ClearScreenHome*(toHistory: BOOLEAN);
BEGIN CClearScreen(Fl.Live(t), Flag(toHistory), 1)
END ClearScreenHome;

PROCEDURE (t: Terminal) ClearHistory*;
BEGIN CClearHistory(Fl.Live(t))
END ClearHistory;

(* Clears everything, and sets colors, attributes, and tab stops back. *)
PROCEDURE (t: Terminal) ResetTerminal*;
BEGIN CReset(Fl.Live(t))
END ResetTerminal;

(* the cursor *)

PROCEDURE (t: Terminal) CursorRow*(): INTEGER;
BEGIN RETURN Get(t, cursorRow)
END CursorRow;

(* row is moved onto the screen. *)
PROCEDURE (t: Terminal) SetCursorRow*(row: INTEGER);
BEGIN Set(t, cursorRow, row)
END SetCursorRow;

PROCEDURE (t: Terminal) CursorCol*(): INTEGER;
BEGIN RETURN Get(t, cursorCol)
END CursorCol;

PROCEDURE (t: Terminal) SetCursorCol*(col: INTEGER);
BEGIN Set(t, cursorCol, col)
END SetCursorCol;

(* What moves count times does nothing for a count below 1. *)
PROCEDURE Move(t: Terminal; what, count: INTEGER; scroll: BOOLEAN);
BEGIN
  IF count > 0 THEN CCursor(Fl.Live(t), what, count, Flag(scroll)) END
END Move;

(* With scroll, the cursor at the top scrolls the screen down, not
   stopping. *)
PROCEDURE (t: Terminal) CursorUp*(count: INTEGER; scroll: BOOLEAN);
BEGIN Move(t, up, count, scroll)
END CursorUp;

PROCEDURE (t: Terminal) CursorDown*(count: INTEGER; scroll: BOOLEAN);
BEGIN Move(t, down, count, scroll)
END CursorDown;

PROCEDURE (t: Terminal) CursorLeft*(count: INTEGER);
BEGIN Move(t, left, count, FALSE)
END CursorLeft;

(* With scroll, past the end of the row is the next row's start. *)
PROCEDURE (t: Terminal) CursorRight*(count: INTEGER; scroll: BOOLEAN);
BEGIN Move(t, right, count, scroll)
END CursorRight;

PROCEDURE (t: Terminal) CursorHome*;
BEGIN Move(t, home, 1, FALSE)
END CursorHome;

PROCEDURE (t: Terminal) CursorEol*;
BEGIN Move(t, eol, 1, FALSE)
END CursorEol;

PROCEDURE (t: Terminal) CursorSol*;
BEGIN Move(t, sol, 1, FALSE)
END CursorSol;

PROCEDURE (t: Terminal) CursorCr*;
BEGIN Move(t, cr, 1, FALSE)
END CursorCr;

PROCEDURE (t: Terminal) CursorCrLf*(count: INTEGER);
BEGIN Move(t, crlf, count, FALSE)
END CursorCrLf;

PROCEDURE (t: Terminal) CursorTabRight*(count: INTEGER);
BEGIN Move(t, tabRight, count, FALSE)
END CursorTabRight;

PROCEDURE (t: Terminal) CursorTabLeft*(count: INTEGER);
BEGIN Move(t, tabLeft, count, FALSE)
END CursorTabLeft;

(* The place RestoreCursor goes back to, as ESC [ s does. *)
PROCEDURE (t: Terminal) SaveCursor*;
BEGIN Move(t, save, 1, FALSE)
END SaveCursor;

(* Does nothing if no place was saved. *)
PROCEDURE (t: Terminal) RestoreCursor*;
BEGIN Move(t, restore, 1, FALSE)
END RestoreCursor;

(* reading it back *)

(* The text from the top of the history to the cursor's row, or the
   screen's last row with below: a line feed ends each row, whose
   trailing spaces are gone, and escape sequences aren't there. It is cut
   to fit s. *)
PROCEDURE (t: Terminal) Text*(VAR s: ARRAY OF CHAR; below: BOOLEAN);
  VAR n: SYSTEM.INT32;
BEGIN n := CText(Fl.Live(t), Flag(below), s, SHORT(LEN(s)))
END Text;

(* Its length in bytes, for choosing s. *)
PROCEDURE (t: Terminal) TextLength*(below: BOOLEAN): INTEGER;
  VAR s: ARRAY 1 OF CHAR;
BEGIN RETURN CText(Fl.Live(t), Flag(below), s, 0)
END TextLength;

(* What the user has selected, "" if nothing, cut to fit s. *)
PROCEDURE (t: Terminal) SelectionText*(VAR s: ARRAY OF CHAR);
  VAR n: SYSTEM.INT32;
BEGIN n := CSelection(Fl.Live(t), s, SHORT(LEN(s)))
END SelectionText;

PROCEDURE (t: Terminal) SelectionTextLength*(): INTEGER;
  VAR s: ARRAY 1 OF CHAR;
BEGIN RETURN CSelection(Fl.Live(t), s, 0)
END SelectionTextLength;

(* Where the selection is, start first, in columns and in rows of the
   ring (below): the screen's top row is DisplayStart, and a row of the
   history scrolled back to is counted back from it, so that it may be
   below 0; take it MOD RingRows() for a Cell. FALSE if nothing is
   selected, and then the corners are the last selection's, or all 0. *)
PROCEDURE (t: Terminal) GetSelection*(VAR srow, scol, erow, ecol: INTEGER): BOOLEAN;
  VAR a, b, c, d: SYSTEM.INT32; r: BOOLEAN;
BEGIN
  r := CGetSelection(Fl.Live(t), a, b, c, d) # 0;
  srow := a; scol := b; erow := c; ecol := d;
  RETURN r
END GetSelection;

(* FLTK's ring, for a program that shows how the terminal works, as
   FLTK's test/terminal does. The history and the screen are rows of one
   ring of RingRows rows of RingCols cells: the history's rows from
   HistoryStart to HistoryEnd, the screen's from DisplayStart to
   DisplayEnd, each going on past the ring's last row at its row 0. The
   ring turns as the screen scrolls: RingOffset is the history's first
   row. *)

PROCEDURE (t: Terminal) RingRows*(): INTEGER;
BEGIN RETURN CRing(Fl.Live(t), ringRows)
END RingRows;

PROCEDURE (t: Terminal) RingCols*(): INTEGER;
BEGIN RETURN CRing(Fl.Live(t), ringCols)
END RingCols;

PROCEDURE (t: Terminal) RingOffset*(): INTEGER;
BEGIN RETURN CRing(Fl.Live(t), ringOffset)
END RingOffset;

PROCEDURE (t: Terminal) HistoryStart*(): INTEGER;
BEGIN RETURN CRing(Fl.Live(t), histStart)
END HistoryStart;

PROCEDURE (t: Terminal) HistoryEnd*(): INTEGER;
BEGIN RETURN CRing(Fl.Live(t), histEnd)
END HistoryEnd;

PROCEDURE (t: Terminal) DisplayStart*(): INTEGER;
BEGIN RETURN CRing(Fl.Live(t), dispStart)
END DisplayStart;

PROCEDURE (t: Terminal) DisplayEnd*(): INTEGER;
BEGIN RETURN CRing(Fl.Live(t), dispEnd)
END DisplayEnd;

(* FLTK's flags of the text written next: which of its colors are xterm
   colors, which Bold and Dim change (1, the foreground; 2, the
   background). *)
PROCEDURE (t: Terminal) StyleFlags*(): SET;
BEGIN RETURN SYSTEM.VAL(SET, CRing(Fl.Live(t), styleFlags))
END StyleFlags;

(* A cell of the ring, row 0 to RingRows() - 1 and col 0 to RingCols() - 1:
   its character, cut to fit s, its attributes and its colors. *)
PROCEDURE (t: Terminal) Cell*(row, col: INTEGER; VAR s: ARRAY OF CHAR; VAR attrib: SET; VAR fg, bg: INTEGER);
  VAR h: SYSTEM.ADDRESS; a, f, b: SYSTEM.INT32;
BEGIN
  h := Fl.Live(t);
  ASSERT((row >= 0) & (row < CRing(h, ringRows)) & (col >= 0) & (col < CRing(h, ringCols)),
    Fl.IndexOutOfRange);
  CCell(h, row, col, s, SHORT(LEN(s)), a, f, b);
  attrib := SYSTEM.VAL(SET, a); fg := f; bg := b
END Cell;

END FlTerminal.
