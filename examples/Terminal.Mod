MODULE Terminal; (* FLTK's test/terminal.cxx in Oberon-2 *)

(* A terminal and a panel of its settings, its operations and its tests:
   FLTK's program, mostly terminal.fl's panel, with the same widgets,
   texts and callbacks. Its escape sequence tests, which FLTK's source
   holds as arrays of strings, are read from terminal-tests.txt, which
   tools/terminal-tests.py writes from that source; the file is looked
   for in the current directory, as make test runs the examples in
   examples/. A command's output and a file are read with the examples'
   Pipe. The ring debug window shows FLTK's ring buffer through
   FlTerminal's Ring and Cell. *)

IMPORT SYSTEM, Out, Platform, Fl, FlButtons, FlInputs, FlValuators, FlMenus,
  FlDialogs, FlTerminal, Pipe;

CONST
  testsFile = "terminal-tests.txt";
  NTests = 11;      (* FLTK's tests[] *)
  MaxElems = 1000;  (* the elements of all the tests *)

TYPE
  Text = POINTER TO ARRAY OF CHAR;

  MyTerminal = POINTER TO RECORD (FlTerminal.TerminalDesc)
    interactive: BOOLEAN  (* the arrow keys move the cursor *)
  END;

  RingTimer = POINTER TO RECORD (Fl.TimerDesc) END;

  Action = PROCEDURE (w: Fl.Widget);

VAR
  win: Fl.DoubleWindow;
  tty: MyTerminal;
  lines: INTEGER;  (* the next line +50 Lines adds *)

  (* the ring debug window *)
  ringWin: Fl.DoubleWindow;
  debugTty: FlTerminal.Terminal;
  ringTimer: RingTimer;

  scrollhistory, fontsize, scrollbarsize, redrawRate: FlValuators.Spinner;
  boxChoice, colorChoice: FlMenus.Choice;
  margins, showfile, command, clearColor: FlInputs.Input;
  textcolorIn, textfgIn, textfgDefaultIn, cursorfgIn, selectionfgIn,
  colorIn, textbgIn, textbgDefaultIn, cursorbgIn, selectionbgIn: FlInputs.Input;
  lfToCrLf, lfToCr, crToLf, showunknown, interactivecursor, ansi,
  stdoutRadio: FlButtons.CheckButton;

  boxes: ARRAY 14 OF INTEGER;  (* box() choice's box types, by item *)

  (* the escape sequence tests: test k is elements testStart[k] to
     testStart[k] + testCount[k] - 1, and shows from testIndex[k] *)
  elems: ARRAY MaxElems OF Text;
  nElems, nTests: INTEGER;
  testStart, testCount, testIndex: ARRAY NTests OF INTEGER;
  testnum, testret: INTEGER;
  testsError: ARRAY 256 OF CHAR;  (* why terminal-tests.txt wasn't read *)

  (* text built for the terminals, or an input *)
  buf: ARRAY 16384 OF CHAR;
  blen: INTEGER;
  t: ARRAY 512 OF CHAR;  (* a label or tooltip (Tx) *)

PROCEDURE ["C", "rand"] Rand(): SYSTEM.INT32;

(* Text building, for printf and sprintf. *)

PROCEDURE Ch(c: CHAR);
BEGIN
  IF blen < LEN(buf) - 1 THEN buf[blen] := c; INC(blen); buf[blen] := 0X END
END Ch;

(* Adds s, with each "~" an escape and each "|" a line feed. *)
PROCEDURE S(s: ARRAY OF CHAR);
  VAR i: INTEGER;
BEGIN
  i := 0;
  WHILE (i < LEN(s)) & (s[i] # 0X) DO
    IF s[i] = "~" THEN Ch(1BX) ELSIF s[i] = "|" THEN Ch(0AX) ELSE Ch(s[i]) END;
    INC(i)
  END
END S;

(* Adds s as it is. *)
PROCEDURE R(VAR s: ARRAY OF CHAR);
  VAR i: INTEGER;
BEGIN
  i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) DO Ch(s[i]); INC(i) END
END R;

(* Adds n in decimal, as %<width>d, or %-<width>d for a negative width,
   or %0<width>d with zero. *)
PROCEDURE Int(n, width: INTEGER; zero: BOOLEAN);
  VAR v: LONGINT; d: ARRAY 24 OF CHAR; i, k: INTEGER; neg: BOOLEAN;
BEGIN
  v := n; neg := v < 0; IF neg THEN v := -v END;
  i := 0; REPEAT d[i] := CHR(ORD("0") + SHORT(v MOD 10)); v := v DIV 10; INC(i) UNTIL v = 0;
  IF neg THEN
    IF zero THEN WHILE i + 1 < width DO d[i] := "0"; INC(i) END END;
    d[i] := "-"; INC(i)
  ELSIF zero THEN WHILE i < width DO d[i] := "0"; INC(i) END
  END;
  FOR k := i + 1 TO width DO Ch(" ") END;
  WHILE i > 0 DO DEC(i); Ch(d[i]) END;
  IF width < 0 THEN
    k := 0; v := n; IF v < 0 THEN INC(k); v := -v END;
    REPEAT INC(k); v := v DIV 10 UNTIL v = 0;
    WHILE k < -width DO Ch(" "); INC(k) END
  END
END Int;

PROCEDURE D(n: INTEGER);
BEGIN Int(n, 0, FALSE)
END D;

(* Adds n, unsigned, in hex, as %0<digits>x. *)
PROCEDURE X(n, digits: INTEGER);
  VAR v: LONGINT; d: ARRAY 16 OF CHAR; i: INTEGER;
BEGIN
  v := n; IF v < 0 THEN INC(v, 100000000H) END;
  i := 0;
  REPEAT
    IF v MOD 16 < 10 THEN d[i] := CHR(ORD("0") + SHORT(v MOD 16))
    ELSE d[i] := CHR(ORD("a") - 10 + SHORT(v MOD 16))
    END;
    v := v DIV 16; INC(i)
  UNTIL v = 0;
  WHILE i < digits DO d[i] := "0"; INC(i) END;
  WHILE i > 0 DO DEC(i); Ch(d[i]) END
END X;

PROCEDURE Clear;
BEGIN blen := 0; buf[0] := 0X
END Clear;

(* Appends what was built to tty, and starts again. *)
PROCEDURE Send(tty: FlTerminal.Terminal);
BEGIN tty.Append(buf); Clear
END Send;

(* What was built, into s, and starts again. *)
PROCEDURE Take(VAR s: ARRAY OF CHAR);
BEGIN COPY(buf, s); Clear
END Take;

(* s into t, each "|" a line feed: for a label or a tooltip. *)
PROCEDURE Tx(s: ARRAY OF CHAR);
  VAR i: INTEGER;
BEGIN
  i := 0;
  WHILE (i < LEN(s)) & (s[i] # 0X) & (i < LEN(t) - 1) DO
    IF s[i] = "|" THEN t[i] := 0AX ELSE t[i] := s[i] END; INC(i)
  END;
  t[i] := 0X
END Tx;

PROCEDURE Nl(tty: FlTerminal.Terminal);
BEGIN S("|"); Send(tty)
END Nl;

(* The terminal, and stdout too if "Echo tests to stdout" is on. *)
PROCEDURE AppendTty(VAR s: ARRAY OF CHAR);
BEGIN
  tty.Append(s);
  IF stdoutRadio.Value() THEN Out.String(s) END
END AppendTty;

(* The escape sequence tests. *)

(* line, with its C escapes (\033, \n, \t and \b) decoded. *)
PROCEDURE Decode(VAR line: ARRAY OF CHAR): Text;
  VAR s: ARRAY 8192 OF CHAR; i, j: INTEGER; e: Text;
BEGIN
  i := 0; j := 0;
  WHILE line[i] # 0X DO
    IF line[i] = "\" THEN
      IF (line[i + 1] = "0") & (line[i + 2] = "3") & (line[i + 3] = "3") THEN
        s[j] := 1BX; INC(i, 4)
      ELSIF line[i + 1] = "n" THEN s[j] := 0AX; INC(i, 2)
      ELSIF line[i + 1] = "t" THEN s[j] := 09X; INC(i, 2)
      ELSIF line[i + 1] = "b" THEN s[j] := 08X; INC(i, 2)
      ELSE s[j] := "\"; INC(i)
      END
    ELSE s[j] := line[i]; INC(i)
    END;
    INC(j)
  END;
  s[j] := 0X;
  NEW(e, j + 1); COPY(s, e^);
  RETURN e
END Decode;

(* Reads terminal-tests.txt: each test is a line "=== name", then a line
   for each element. *)
PROCEDURE LoadTests;
  VAR p: Pipe.Pipe; line: ARRAY 8192 OF CHAR; n: INTEGER;
BEGIN
  nElems := 0; nTests := 0; testsError := "";
  NEW(p);
  IF ~Pipe.OpenFile(p, testsFile) THEN Pipe.Error(testsError); RETURN END;
  WHILE p.ReadLine(line) DO
    n := 0; WHILE line[n] # 0X DO INC(n) END;
    IF (n > 0) & (line[n - 1] = 0AX) THEN line[n - 1] := 0X END;
    IF (line[0] = "=") & (line[1] = "=") & (line[2] = "=") & (line[3] = " ") THEN
      IF nTests < NTests THEN
        testStart[nTests] := nElems; testCount[nTests] := 0; testIndex[nTests] := 0;
        INC(nTests)
      END
    ELSIF (nTests > 0) & (nElems < MaxElems) THEN
      elems[nElems] := Decode(line); INC(nElems); INC(testCount[nTests - 1])
    END
  END;
  IF p.Close() # 0 THEN END
END LoadTests;

(* FLTK's show_test: shows test k from where it was left, up to an element
   starting "--->", a page's end; 1 when the test is done, 0 if it has
   another page. *)
PROCEDURE ShowTest(k: INTEGER): INTEGER;
  VAR e: Text;
BEGIN
  IF k >= nTests THEN
    S("~[1;31m"); S(testsFile); S(": "); R(testsError);
    S(" (the escape sequence tests)~[0m|"); Send(tty);
    RETURN 1
  END;
  WHILE testIndex[k] < testCount[k] DO
    e := elems[testStart[k] + testIndex[k]]; INC(testIndex[k]);
    AppendTty(e^);
    IF (e[0] = "-") & (e[1] = "-") & (e[2] = "-") & (e[3] = ">") THEN
      IF testIndex[k] = testCount[k] THEN testIndex[k] := 0; RETURN 1
      ELSE RETURN 0
      END
    END
  END;
  testIndex[k] := 0;
  RETURN 1
END ShowTest;

PROCEDURE TestFirstPage;
BEGIN IF ShowTest(0) = 0 THEN END
END TestFirstPage;

(* Runs the next test, or the next page of this one (dir 1), or the one
   before (-1). *)
PROCEDURE NextEscapeTest(dir: INTEGER);
BEGIN
  INC(testnum, dir * testret);
  IF testnum >= NTests THEN testnum := 0 END;
  IF testnum < 0 THEN testnum := NTests - 1 END;
  testret := ShowTest(testnum);
  tty.Redraw
END NextEscapeTest;

(* The terminal's own handling, with the arrow keys moving the cursor
   when Interactive Cursor is on. *)
PROCEDURE (t: MyTerminal) Handle*(event: INTEGER): BOOLEAN;
  VAR k: INTEGER;
BEGIN
  IF (event = Fl.EvKeyDown) & t.interactive THEN
    k := Fl.EventKey();
    IF k = Fl.KeyUp THEN t.CursorUp(1, TRUE); t.Redraw; RETURN TRUE
    ELSIF k = Fl.KeyDown THEN t.CursorDown(1, TRUE); t.Redraw; RETURN TRUE
    ELSIF k = Fl.KeyLeft THEN t.CursorLeft(1); t.Redraw; RETURN TRUE
    ELSIF k = Fl.KeyRight THEN t.CursorRight(1, FALSE); t.Redraw; RETURN TRUE
    END
  END;
  RETURN t.Handle^(event)
END Handle;

(* The ring debug window. *)

PROCEDURE HorizBracket(w: INTEGER);
  VAR i: INTEGER;
BEGIN
  debugTty.Append("┏");
  FOR i := 1 TO w - 2 DO debugTty.PrintChar("━") END;
  debugTty.Append("┓")
END HorizBracket;

(* n cells of the ring's row, each in its own style. *)
PROCEDURE Cells(row, n: INTEGER);
  VAR col, fg, bg: INTEGER; s: ARRAY 16 OF CHAR; a: SET;
BEGIN
  FOR col := 0 TO n - 1 DO
    tty.Cell(row, col, s, a, fg, bg);
    debugTty.SetTextAttrib(a);
    debugTty.SetTextFgColor(fg);
    debugTty.SetTextBgColor(bg);
    debugTty.PrintChar(s)
  END;
  S("~[0m"); Send(debugTty)
END Cells;

PROCEDURE UpdateRing;
  VAR m1, m2, m3, m4, x, row, rr, rc, hr, dr, dc, hs, ds, col: INTEGER;
BEGIN
  IF tty.GetSelection(m1, m2, m3, m4) THEN END;
  rr := tty.RingRows(); rc := tty.RingCols();
  hr := tty.HistoryRows(); hs := tty.HistoryStart();
  dr := tty.DisplayRows(); dc := tty.DisplayColumns(); ds := tty.DisplayStart();
  x := 5;
  S("~c");   (* reset terminal (clear screen, history, home) *)
  S("~[s");  (* save cursor *)
  S("~["); D(x); S("C ~[7m   Ring Index   ~[0m|");
  S("~["); D(x); S("C   ring_rows(): "); Int(rr, -3, FALSE);
  S("  Mouse Selection (srow,scol,erow,ecol)|");
  S("~["); D(x); S("C   ring_cols(): "); Int(rc, -3, FALSE);
  S("            ~[7m("); D(m1); S(","); D(m2); S(","); D(m3); S(","); D(m4); S(")~[0m|");
  S("~["); D(x); S("C      offset(): "); Int(tty.RingOffset(), -3, FALSE);
  S("  currentstyle->charflags="); X(ORD(tty.StyleFlags()), 2); S("|");
  S("~["); D(x); S("C "); Send(debugTty);
  HorizBracket(dc);
  S("~[u"); Send(debugTty);  (* recall cursor *)

  INC(x, dc + 11);
  S("~["); D(x); S("C ~[7m   History Index   ~[0m|");
  S("~["); D(x); S("C   hist_rows(): "); D(hr); S(" hist_srow()="); D(hs); S("|");
  S("~["); D(x); S("C   hist_cols(): "); D(rc); S(" hist_erow()="); D(tty.HistoryEnd()); S("|");
  S("~["); D(x); S("C    hist_use(): "); D(tty.HistoryUse()); S("|");
  S("~["); D(x); S("C "); Send(debugTty);
  HorizBracket(dc);
  S("~[u"); Send(debugTty);

  INC(x, dc + 11);
  S("~["); D(x); S("C ~[7m   Display Index   ~[0m|");
  S("~["); D(x); S("C   disp_rows(): "); D(dr); S(" disp_srow()="); D(ds); S("|");
  S("~["); D(x); S("C   disp_cols(): "); D(dc); S(" disp_erow()="); D(tty.DisplayEnd()); S("|");
  S("|");
  S("~["); D(x); S("C "); Send(debugTty);
  HorizBracket(dc);
  Nl(debugTty);

  FOR row := 0 TO rr - 1 DO
    (* the ring *)
    Int(row, 3, FALSE); S(" R["); Send(debugTty);
    Cells(row, rc);
    S("]    "); Send(debugTty);
    (* the history *)
    IF row < hr THEN
      Int(row, 3, FALSE); S(" H["); Send(debugTty);
      Cells((hs + row) MOD rr, rc);
      S("]    ")
    ELSE
      S("     "); FOR col := 1 TO rc DO S(" ") END; S("     ")
    END;
    Send(debugTty);
    (* the screen *)
    IF row < dr THEN
      Int(row, 3, FALSE); S(" D["); Send(debugTty);
      Cells((ds + row) MOD rr, dc);
      S("]~[K|")
    ELSE
      S("~[K|")
    END;
    Send(debugTty)
  END;
  S("--- END~[0J|"); Send(debugTty)  (* clear to the end of the screen *)
END UpdateRing;

PROCEDURE (t: RingTimer) Fire*;
BEGIN
  UpdateRing;
  ringWin.Redraw;  (* after all the changes *)
  Fl.RepeatTimeout(t, 0.10D0)
END Fire;

PROCEDURE RingQuit(w: Fl.Widget);
BEGIN ringWin.Hide; Fl.RemoveTimeout(ringTimer)
END RingQuit;

PROCEDURE ShowRingDebugWindow;
BEGIN
  IF ringWin = NIL THEN
    NEW(ringWin); Fl.OpenDoubleWindow(ringWin, 1250, 800, "Fl_Terminal Ring Buffer");
    ringWin.SetResizable(ringWin);
    ringWin.action := RingQuit;
    NEW(debugTty); FlTerminal.OpenTerminal(debugTty, 0, 0, ringWin.W(), ringWin.H(), "");
    debugTty.SetTextSize(7);
    debugTty.SetRedrawStyle(FlTerminal.NoRedraw);
    debugTty.SetDisplayColumns(400);
    ringWin.End;
    NEW(ringTimer)
  END;
  ringWin.Show;
  Fl.AddTimeout(ringTimer, 0.5D0)
END ShowRingDebugWindow;

(* The operations and tests. *)

(* A file shown in the terminal, line by line. *)
PROCEDURE ShowFile(VAR name: ARRAY OF CHAR);
  VAR p: Pipe.Pipe; s: ARRAY 1023 OF CHAR; err: ARRAY 256 OF CHAR;
BEGIN
  IF tty.CursorCol() # 0 THEN Nl(tty) END;  (* a line feed after floating text *)
  NEW(p);
  IF ~Pipe.OpenFile(p, name) THEN
    Pipe.Error(err);
    S("~[1;31m"); R(name); S(": "); R(err); S("~[0m|");
    IF blen > 1023 THEN buf[1023] := 0X END;  (* FLTK's snprintf *)
    tty.AppendUtf8(buf); Clear;
    RETURN
  END;
  WHILE p.ReadLine(s) DO tty.Append(s) END;
  IF p.Close() # 0 THEN END
END ShowFile;

(* A full screen of random characters in random colors, 50 times. *)
PROCEDURE SpeedTest;
  VAR i, row, col, rows, cols: INTEGER; c: ARRAY 2 OF CHAR;
BEGIN
  (* redrawn here, not by the terminal *)
  tty.SetRedrawStyle(FlTerminal.NoRedraw);
  S("~[H"); Send(tty);
  rows := tty.DisplayRows(); cols := tty.DisplayColumns();
  c[1] := 0X;
  FOR i := 1 TO 50 DO
    FOR row := 0 TO rows - 1 DO
      FOR col := 0 TO cols - 1 DO
        c[0] := CHR(ORD(" ") + Rand() MOD 50H);
        tty.SetTextFgColorXterm(Rand() MOD 8);
        tty.PlotChar(c, row, col)
      END
    END;
    tty.Redraw;
    Fl.Wait(0.005D0)
  END;
  S("~[c"); Send(tty);  (* reset terminal: white on black *)
  tty.SetRedrawStyle(FlTerminal.RateLimited);
  TestFirstPage
END SpeedTest;

(* Color bars, set by the API, not by escape sequences. *)
PROCEDURE ShowColorbars;
  CONST
    bar = "███████████";
    box1 = "██████████████";
    box2 = "█████████████";
    pluge = "███";
  VAR
    fgsave, bgsave, y, i: INTEGER;
    bars1, bars2: ARRAY 7 OF INTEGER;
    boxes: ARRAY 8 OF INTEGER;
BEGIN
  IF tty.CursorCol() # 0 THEN Nl(tty) END;
  fgsave := tty.TextFgColor(); bgsave := tty.TextBgColor();
  (* ECR-1-1978: gray, yellow, cyan, green, magenta, red, blue *)
  bars1[0] := Fl.RGB(0C0H, 0C0H, 0C0H); bars1[1] := Fl.RGB(0BFH, 0C0H, 37H);
  bars1[2] := Fl.RGB(2AH, 0C0H, 0BFH); bars1[3] := Fl.RGB(25H, 0C0H, 33H);
  bars1[4] := Fl.RGB(0BEH, 0, 0BBH); bars1[5] := Fl.RGB(0BDH, 05H, 18H);
  bars1[6] := Fl.RGB(16H, 0, 0BAH);
  bars2[0] := Fl.RGB(16H, 0, 0BAH); bars2[1] := Fl.RGB(11H, 11H, 11H);
  bars2[2] := Fl.RGB(0BEH, 0, 0BBH); bars2[3] := Fl.RGB(11H, 11H, 11H);
  bars2[4] := Fl.RGB(2AH, 0C0H, 0BFH); bars2[5] := Fl.RGB(11H, 11H, 11H);
  bars2[6] := Fl.RGB(0C0H, 0C0H, 0C0H);
  (* -I, 100% white, Q+, then the pluge: superblack, black, 4% black *)
  boxes[0] := Fl.RGB(05H, 21H, 4AH); boxes[1] := Fl.RGB(0FFH, 0FFH, 0FFH);
  boxes[2] := Fl.RGB(32H, 0, 67H); boxes[3] := Fl.RGB(11H, 11H, 11H);
  boxes[4] := Fl.RGB(03H, 03H, 03H); boxes[5] := Fl.RGB(11H, 11H, 11H);
  boxes[6] := Fl.RGB(1DH, 1DH, 1DH); boxes[7] := Fl.RGB(11H, 11H, 11H);
  S("~[2J~[H"); Send(tty);
  (* the 75% bars *)
  FOR y := 0 TO 15 DO
    FOR i := 0 TO 6 DO tty.SetTextFgColor(bars1[i]); tty.Append(bar) END;
    Nl(tty)
  END;
  (* the strip *)
  FOR y := 0 TO 1 DO
    FOR i := 0 TO 6 DO tty.SetTextFgColor(bars2[i]); tty.Append(bar) END;
    Nl(tty)
  END;
  (* the boxes at the bottom *)
  FOR y := 0 TO 6 DO
    FOR i := 0 TO 7 DO
      tty.SetTextFgColor(boxes[i]);
      IF i < 3 THEN tty.Append(box1)
      ELSIF i < 4 THEN tty.Append(box2)
      ELSIF i < 7 THEN tty.Append(pluge)
      ELSE tty.Append(box2)
      END
    END;
    IF y < 6 THEN Nl(tty) END
  END;
  tty.SetTextFgColor(fgsave); tty.SetTextBgColor(bgsave)
END ShowColorbars;

PROCEDURE AddLines(n: INTEGER);
  VAR i: INTEGER;
BEGIN
  IF tty.CursorCol() # 0 THEN Nl(tty) END;
  FOR i := 1 TO n DO
    S("Line "); Int(lines, 4, TRUE); S(" -- AAA BBB CCC DDD|"); Send(tty);
    INC(lines)
  END
END AddLines;

(* A command run, its output appended as it comes. *)
PROCEDURE DoCommand(VAR cmd: ARRAY OF CHAR);
  VAR p: Pipe.Pipe; s: ARRAY 4097 OF CHAR; err: ARRAY 256 OF CHAR; i, n: INTEGER;
BEGIN
  IF tty.CursorCol() # 0 THEN Nl(tty) END;
  NEW(p);
  IF ~Pipe.Open(p, cmd) THEN
    Pipe.Error(err);
    S("~[0;31mCan't execute '");
    i := 0; WHILE (i < 200) & (i < LEN(cmd)) & (cmd[i] # 0X) DO Ch(cmd[i]); INC(i) END;
    S("': "); R(err); S("~[0m|");
    tty.AppendUtf8(buf); Clear;
    RETURN
  END;
  (* reading without waiting keeps the window alive during a slow command *)
  p.SetNonBlocking;
  (* FLTK's append(NULL) clears the terminal's UTF-8 cache here, which
     FlTerminal can't: a character cut short is all that it drops *)
  LOOP
    Fl.Wait(0.05D0);
    n := p.Read(s);
    IF n = Pipe.Again THEN (* nothing yet *)
    ELSIF n > 0 THEN tty.Append(s)
    ELSE EXIT  (* the pipe closed *)
    END
  END;
  IF p.Close() # 0 THEN END;
  S("~[33;2m<<END_OF_OUTPUT>>~[0m|"); tty.AppendAscii(buf); Clear;
  tty.Redraw
END DoCommand;

(* The panel's inputs. *)

(* Puts the color c in in, as "#%08x". *)
PROCEDURE SetColorIn(in: FlInputs.Input; c: INTEGER);
  VAR s: ARRAY 16 OF CHAR;
BEGIN S("#"); X(c, 8); Take(s); in.SetValue(s)
END SetColorIn;

(* The panel set from the terminal. *)
PROCEDURE UpdateInputs;
  VAR b, i: INTEGER; out: SET; s: ARRAY 100 OF CHAR;
BEGIN
  scrollhistory.SetValue(tty.HistoryRows());
  redrawRate.SetValue(tty.RedrawRate());
  fontsize.SetValue(tty.TextSize());
  scrollbarsize.SetBounds(0, 80);
  scrollbarsize.SetStep(1);
  scrollbarsize.SetValue(tty.ScrollbarSize());
  showunknown.SetValue(tty.ShowUnknown());
  ansi.SetValue(tty.Ansi());
  b := tty.BoxType();
  i := 0; WHILE (i < LEN(boxes)) & (boxes[i] # b) DO INC(i) END;
  IF i = LEN(boxes) THEN i := 1 END;
  IF boxChoice.SetValue(i) THEN END;
  SetColorIn(colorIn, tty.Color());
  SetColorIn(textcolorIn, tty.TextFgColorDefault());  (* FLTK's textcolor() *)
  SetColorIn(textfgIn, tty.TextFgColor());
  SetColorIn(textbgIn, tty.TextBgColor());
  SetColorIn(textfgDefaultIn, tty.TextFgColorDefault());
  SetColorIn(textbgDefaultIn, tty.TextBgColorDefault());
  SetColorIn(cursorfgIn, tty.CursorFgColor());
  SetColorIn(cursorbgIn, tty.CursorBgColor());
  D(tty.MarginLeft()); S(", "); D(tty.MarginRight()); S(", ");
  D(tty.MarginTop()); S(", "); D(tty.MarginBottom()); Take(s);
  margins.SetValue(s);
  SetColorIn(selectionfgIn, tty.SelectionFgColor());
  SetColorIn(selectionbgIn, tty.SelectionBgColor());
  out := tty.OutputTranslate();
  lfToCrLf.SetValue(out * FlTerminal.OutLfToCrLf # {});
  lfToCr.SetValue(out * FlTerminal.OutLfToCr # {});
  crToLf.SetValue(out * FlTerminal.OutCrToLf # {})
END UpdateInputs;

PROCEDURE IsSpace(c: CHAR): BOOLEAN;
BEGIN RETURN (c = " ") OR (c >= 09X) & (c <= 0DX)
END IsSpace;

PROCEDURE Digit(c: CHAR; base: INTEGER): INTEGER;
  VAR d: INTEGER;
BEGIN
  IF (c >= "0") & (c <= "9") THEN d := ORD(c) - ORD("0")
  ELSIF (c >= "a") & (c <= "f") THEN d := ORD(c) - ORD("a") + 10
  ELSIF (c >= "A") & (c <= "F") THEN d := ORD(c) - ORD("A") + 10
  ELSE d := 99
  END;
  IF d >= base THEN d := -1 END;
  RETURN d
END Digit;

(* sscanf's %lu (base 10) or %lx (16) at s[i], as a color: the number mod
   2^32. FALSE if there is no number. *)
PROCEDURE ScanColor(VAR s: ARRAY OF CHAR; i, base: INTEGER; VAR c: INTEGER): BOOLEAN;
  VAR v: LONGINT; neg: BOOLEAN;
BEGIN
  WHILE IsSpace(s[i]) DO INC(i) END;
  neg := s[i] = "-"; IF (s[i] = "-") OR (s[i] = "+") THEN INC(i) END;
  IF (base = 16) & (s[i] = "0") & ((s[i + 1] = "x") OR (s[i + 1] = "X"))
      & (Digit(s[i + 2], 16) >= 0) THEN
    INC(i, 2)
  END;
  IF Digit(s[i], base) < 0 THEN RETURN FALSE END;
  v := 0;
  WHILE Digit(s[i], base) >= 0 DO
    v := (v * base + Digit(s[i], base)) MOD 100000000H; INC(i)
  END;
  IF neg THEN v := (100000000H - v) MOD 100000000H END;
  IF v >= 80000000H THEN DEC(v, 100000000H) END;
  c := SHORT(v);
  RETURN TRUE
END ScanColor;

(* FLTK's parse_color: "#" and a number in hex, or one in decimal. *)
PROCEDURE ParseColor(VAR s: ARRAY OF CHAR; VAR c: INTEGER): BOOLEAN;
BEGIN
  IF (s[0] = "#") & ScanColor(s, 1, 16, c) OR ScanColor(s, 0, 10, c) THEN
    RETURN TRUE
  END;
  S("Illegal color value '"); R(s); S("'|(can be e.g. '12' or '#0c', etc)");
  FlDialogs.Alert(buf); Clear;
  RETURN FALSE
END ParseColor;

PROCEDURE InputColor(in: FlInputs.Input; VAR c: INTEGER): BOOLEAN;
  VAR s: ARRAY 256 OF CHAR;
BEGIN in.Value(s); RETURN ParseColor(s, c)
END InputColor;

(* sscanf's %d at s[i]. *)
PROCEDURE ScanInt(VAR s: ARRAY OF CHAR; VAR i, n: INTEGER): BOOLEAN;
  VAR neg: BOOLEAN; v: LONGINT;
BEGIN
  WHILE IsSpace(s[i]) DO INC(i) END;
  neg := s[i] = "-"; IF (s[i] = "-") OR (s[i] = "+") THEN INC(i) END;
  IF Digit(s[i], 10) < 0 THEN RETURN FALSE END;
  v := 0;
  WHILE Digit(s[i], 10) >= 0 DO
    v := (v * 10 + Digit(s[i], 10)) MOD 100000000H; INC(i)
  END;
  IF neg THEN v := -v END;
  n := SHORT(v);
  RETURN TRUE
END ScanInt;

(* The callbacks. *)

PROCEDURE Quit(w: Fl.Widget);
BEGIN Platform.Exit(0)
END Quit;

PROCEDURE ScrollHistoryAction(w: Fl.Widget);
BEGIN tty.SetHistoryRows(SHORT(ENTIER(scrollhistory.Value() + 0.5D0)))
END ScrollHistoryAction;

PROCEDURE FontSizeAction(w: Fl.Widget);
BEGIN tty.SetTextSize(SHORT(ENTIER(fontsize.Value() + 0.5D0)))
END FontSizeAction;

PROCEDURE ScrollbarSizeAction(w: Fl.Widget);
BEGIN tty.SetScrollbarSize(SHORT(ENTIER(scrollbarsize.Value() + 0.5D0))); tty.Redraw
END ScrollbarSizeAction;

PROCEDURE RedrawRateAction(w: Fl.Widget);
BEGIN tty.SetRedrawRate(redrawRate.Value())
END RedrawRateAction;

PROCEDURE BoxAction(w: Fl.Widget);
BEGIN tty.SetBoxType(boxes[boxChoice.Value()]); tty.Redraw
END BoxAction;

PROCEDURE MarginsAction(w: Fl.Widget);
  VAR s: ARRAY 256 OF CHAR; i, k: INTEGER; m: ARRAY 4 OF INTEGER;
BEGIN
  margins.Value(s);
  i := 0; k := 0;
  WHILE (k < 4) & ((k = 0) OR (s[i] = ",")) DO
    IF k > 0 THEN INC(i) END;
    IF ScanInt(s, i, m[k]) THEN INC(k) ELSE k := 5 END
  END;
  IF k # 4 THEN
    FlDialogs.Alert("Margins: expected four comma separated integers");
    RETURN
  END;
  tty.SetMarginLeft(m[0]); tty.SetMarginRight(m[1]);
  tty.SetMarginTop(m[2]); tty.SetMarginBottom(m[3]);
  tty.Redraw
END MarginsAction;

PROCEDURE OutputTranslateAction(w: Fl.Widget);
  VAR out: SET;
BEGIN
  out := FlTerminal.OutOff;
  IF lfToCrLf.Value() THEN out := out + FlTerminal.OutLfToCrLf END;
  IF lfToCr.Value() THEN out := out + FlTerminal.OutLfToCr END;
  IF crToLf.Value() THEN out := out + FlTerminal.OutCrToLf END;
  tty.SetOutputTranslate(out)
END OutputTranslateAction;

PROCEDURE ShowUnknownAction(w: Fl.Widget);
BEGIN tty.SetShowUnknown(showunknown.Value()); tty.Redraw
END ShowUnknownAction;

PROCEDURE InteractiveCursorAction(w: Fl.Widget);
BEGIN tty.interactive := interactivecursor.Value()
END InteractiveCursorAction;

PROCEDURE AnsiAction(w: Fl.Widget);
BEGIN tty.SetAnsi(ansi.Value())
END AnsiAction;

(* Any of the color inputs. *)
PROCEDURE ColorAction(w: Fl.Widget);
  VAR c: INTEGER;
BEGIN
  IF ~InputColor(w(FlInputs.Input), c) THEN RETURN END;
  IF w = textcolorIn THEN tty.SetTextColor(c)
  ELSIF w = textfgIn THEN tty.SetTextFgColor(c)
  ELSIF w = textfgDefaultIn THEN tty.SetTextFgColorDefault(c)
  ELSIF w = cursorfgIn THEN tty.SetCursorFgColor(c)
  ELSIF w = selectionfgIn THEN tty.SetSelectionFgColor(c)
  ELSIF w = colorIn THEN tty.SetColor(c)
  ELSIF w = textbgIn THEN tty.SetTextBgColor(c)
  ELSIF w = textbgDefaultIn THEN tty.SetTextBgColorDefault(c)
  ELSIF w = cursorbgIn THEN tty.SetCursorBgColor(c)
  ELSIF w = selectionbgIn THEN tty.SetSelectionBgColor(c)
  END;
  UpdateInputs;
  tty.Redraw
END ColorAction;

(* The Terminal Color choice's items. *)
PROCEDURE TerminalColorAction(w: Fl.Widget);
  VAR gray: INTEGER;
BEGIN
  gray := Fl.RGB(0D0H, 0D0H, 0D0H);
  CASE colorChoice.Value() OF
  | 0: (* White on DarkAmber (XTERM) *)
    tty.SetColor(30200000H);  (* the amber background *)
    tty.SetTextFgColorXterm(7);  (* xterm's white, which Dim and Bold change *)
    tty.SetTextBgColor(-1)  (* 0xffffffff: see through *)
  | 1: (* White on Black (XTERM) *)
    tty.SetTextFgColorXterm(7); tty.SetTextBgColor(-1); tty.SetColor(0)
  | 2: (* White on DarkAmber (RGB) *)
    tty.SetColor(30200000H); tty.SetTextFgColor(gray); tty.SetTextBgColor(-1)
  | 3: (* White on Black (RGB) *)
    tty.SetTextFgColor(gray); tty.SetTextBgColor(-1); tty.SetColor(0)
  | 4: (* Black on White (RGB) *)
    tty.SetTextFgColor(0); tty.SetTextBgColor(gray); tty.SetColor(gray)
  | 5: (* Green on Dark Green (RGB) *)
    tty.SetTextFgColor(Fl.RGB(0, 0D0H, 40H));
    tty.SetTextBgColor(Fl.RGB(0, 20H, 08H)); tty.SetColor(Fl.RGB(0, 20H, 08H))
  | 6: (* Orange on Dark Orange (RGB) *)
    tty.SetTextFgColor(Fl.RGB(0D0H, 70H, 40H));
    tty.SetTextBgColor(Fl.RGB(20H, 10H, 0)); tty.SetColor(Fl.RGB(20H, 10H, 0))
  ELSE
  END;
  UpdateInputs;
  AddLines(5)
END TerminalColorAction;

PROCEDURE ResetApi(w: Fl.Widget);
BEGIN tty.ResetTerminal; tty.Redraw; lines := 1
END ResetApi;

PROCEDURE ResetAnsi(w: Fl.Widget);
BEGIN S("~c"); Send(tty); tty.Redraw; lines := 1
END ResetAnsi;

PROCEDURE HomeApi(w: Fl.Widget);
BEGIN tty.CursorHome; tty.Redraw
END HomeApi;

PROCEDURE HomeAnsi(w: Fl.Widget);
BEGIN S("~[H"); Send(tty); tty.Redraw
END HomeAnsi;

PROCEDURE ClearHistoryApi(w: Fl.Widget);
BEGIN tty.ClearHistory; tty.Redraw
END ClearHistoryApi;

PROCEDURE ClearHistoryAnsi(w: Fl.Widget);
BEGIN S("~[3J"); Send(tty); tty.Redraw
END ClearHistoryAnsi;

PROCEDURE ClearScreenApi(w: Fl.Widget);
BEGIN tty.Clear; tty.Redraw; lines := 1
END ClearScreenApi;

PROCEDURE ClearScreenAnsi(w: Fl.Widget);
BEGIN S("~[H~[2J"); Send(tty); tty.Redraw; lines := 1
END ClearScreenAnsi;

PROCEDURE ClearToColor(w: Fl.Widget);
  VAR c: INTEGER;
BEGIN
  IF ~InputColor(clearColor, c) THEN RETURN END;
  tty.ClearWith(c); tty.Redraw; lines := 1
END ClearToColor;

PROCEDURE SpeedAction(w: Fl.Widget);
BEGIN SpeedTest
END SpeedAction;

PROCEDURE RingAction(w: Fl.Widget);
BEGIN
  (* a smaller history, since the window shows all of it *)
  IF scrollhistory.Value() > 35.0D0 THEN
    scrollhistory.SetValue(35.0D0); scrollhistory.DoCallback
  END;
  ShowRingDebugWindow
END RingAction;

PROCEDURE UnicodeAction(w: Fl.Widget);
BEGIN TestFirstPage
END UnicodeAction;

PROCEDURE AddLinesAction(w: Fl.Widget);
BEGIN AddLines(50)
END AddLinesAction;

PROCEDURE ColorBarsAction(w: Fl.Widget);
BEGIN ShowColorbars
END ColorBarsAction;

PROCEDURE PrevTestAction(w: Fl.Widget);
BEGIN NextEscapeTest(-1)
END PrevTestAction;

PROCEDURE NextTestAction(w: Fl.Widget);
BEGIN NextEscapeTest(1)
END NextTestAction;

PROCEDURE ShowFileAction(w: Fl.Widget);
  VAR s: ARRAY 4096 OF CHAR;
BEGIN
  showfile.Deactivate; command.Deactivate;
  win.Redraw; Fl.Wait(0.01D0);
  showfile.Value(s); ShowFile(s);
  showfile.Activate; command.Activate;
  Fl.SetFocus(showfile);
  win.Redraw
END ShowFileAction;

PROCEDURE CommandAction(w: Fl.Widget);
  VAR s: ARRAY 4096 OF CHAR;
BEGIN
  showfile.Deactivate; command.Deactivate;
  win.Redraw; Fl.Wait(0.01D0);
  command.Value(s); DoCommand(s);
  showfile.Activate; command.Activate;
  Fl.SetFocus(command);
  win.Redraw
END CommandAction;

(* The panel. *)

PROCEDURE Spinner(VAR s: FlValuators.Spinner; y: INTEGER; label, tip: ARRAY OF CHAR;
    action: Action);
BEGIN
  NEW(s); FlValuators.OpenSpinner(s, 109, y, 115, 20, label);
  IF tip # "" THEN Tx(tip); s.SetTooltip(t) END;
  s.SetLabelSize(10); s.SetTextSize(10);
  s.action := action
END Spinner;

PROCEDURE Check(VAR b: FlButtons.CheckButton; x, y, w: INTEGER; label, tip: ARRAY OF CHAR;
    action: Action);
BEGIN
  NEW(b); FlButtons.OpenCheckButton(b, x, y, w, 24, label);
  Tx(tip); b.SetTooltip(t);
  b.SetDownBox(Fl.DownBox); b.SetLabelSize(9);
  b.action := action
END Check;

(* tip, and if dec, how a color may be written *)
PROCEDURE ColorInput(VAR in: FlInputs.Input; x, y: INTEGER; label, tip: ARRAY OF CHAR;
    dec: BOOLEAN);
BEGIN
  NEW(in); FlInputs.OpenInput(in, x, y, 77, 20, label);
  S(tip); IF dec THEN S("|Can be decimal (e.g. 12) or hex (e.g. #0c, #0000000c, etc)") END;
  Take(t); in.SetTooltip(t);
  in.SetLabelSize(9); in.SetTextFont(Fl.Courier); in.SetTextSize(9);
  in.action := ColorAction;
  in.SetWhen(Fl.WhenRelease + Fl.WhenEnterKey + Fl.WhenClosed)
END ColorInput;

PROCEDURE Button(x, y, w, h: INTEGER; label, tip: ARRAY OF CHAR; size: INTEGER;
    action: Action): FlButtons.Button;
  VAR b: FlButtons.Button;
BEGIN
  NEW(b); Tx(label); FlButtons.OpenButton(b, x, y, w, h, t);
  Tx(tip); b.SetTooltip(t);
  b.SetLabelSize(size);
  b.action := action;
  RETURN b
END Button;

PROCEDURE OpsButton(x, y: INTEGER; label, tip: ARRAY OF CHAR; action: Action);
BEGIN IF Button(x, y, 64, 24, label, tip, 8, action) = NIL THEN END
END OpsButton;

PROCEDURE BoxItem(label: ARRAY OF CHAR; box: INTEGER; flags: SET);
  VAR i: INTEGER;
BEGIN
  i := boxChoice.Add(label, 0, {}, BoxAction, flags);
  boxChoice.SetItemLabelSize(i, 8);
  boxes[i] := box
END BoxItem;

PROCEDURE ColorItem(label: ARRAY OF CHAR; flags: SET);
BEGIN colorChoice.SetItemLabelSize(colorChoice.Add(label, 0, {}, TerminalColorAction, flags), 9)
END ColorItem;

PROCEDURE MakeWindow;
  CONST
    inputWhen = Fl.WhenRelease + Fl.WhenEnterKey + Fl.WhenClosed;
  VAR
    scheme: FlMenus.SchemeChoice;
    box: Fl.Box;
    g, g2: Fl.Group;
    b: FlButtons.Button;
    tip: ARRAY 512 OF CHAR;
BEGIN
  NEW(win); Fl.OpenDoubleWindow(win, 897, 838, "Fl_Terminal Test");
  win.action := Quit;
  Spinner(scrollhistory, 10, "Scroll History", "Scrollback history size.|10,000 max.",
    ScrollHistoryAction);
  scrollhistory.SetBounds(0, 10000);
  Spinner(fontsize, 38, "Font Size", "", FontSizeAction);
  Spinner(scrollbarsize, 67, "Scrollbar Size", "Size of scrollbar width in pixels",
    ScrollbarSizeAction);
  Spinner(redrawRate, 94, "Min Redraw Time", "Minimum time between redraws|Default is 0.10 secs.",
    RedrawRateAction);
  redrawRate.SetKind(FlValuators.FloatSpinner);
  redrawRate.SetBounds(0.05D0, 5); redrawRate.SetStep(0.1D0);

  NEW(scheme); FlMenus.OpenSchemeChoice(scheme, 109, 120, 115, 20, "scheme");
  scheme.SetTooltip("Scheme");
  scheme.SetBoxType(Fl.UpBox); scheme.SetDownBox(Fl.BorderBox);
  scheme.SetColor(Fl.BackgroundColor); scheme.SetSelectionColor(Fl.SelectionColor);
  scheme.SetLabelSize(10); scheme.SetTextSize(10);
  scheme.SetAlign(Fl.AlignLeft); scheme.SetWhen(Fl.WhenRelease);

  NEW(boxChoice); FlMenus.OpenChoice(boxChoice, 109, 147, 115, 20, "box()");
  boxChoice.SetTooltip("The border box for the Fl_Terminal");
  boxChoice.SetDownBox(Fl.BorderBox); boxChoice.SetLabelSize(10); boxChoice.SetTextSize(10);
  BoxItem("FL_UP_FRAME", Fl.UpFrame, {});
  BoxItem("FL_DOWN_FRAME", Fl.DownFrame, {});
  BoxItem("FL_THIN_UP_FRAME", Fl.ThinUpFrame, {});
  BoxItem("FL_THIN_DOWN_FRAME", Fl.ThinDownFrame, {});
  BoxItem("FL_ENGRAVED_FRAME", Fl.EngravedFrame, {});
  BoxItem("FL_EMBOSSED_FRAME", Fl.EmbossedFrame, {});
  BoxItem("FL_BORDER_FRAME", Fl.BorderFrame, FlMenus.MenuDivider);
  BoxItem("FL_UP_BOX", Fl.UpBox, {});
  BoxItem("FL_DOWN_BOX", Fl.DownBox, {});
  BoxItem("FL_FLAT_BOX", Fl.FlatBox, {});
  BoxItem("FL_THIN_UP_BOX", Fl.ThinUpBox, {});
  BoxItem("FL_THIN_DOWN_BOX", Fl.ThinDownBox, {});
  BoxItem("FL_BORDER_BOX", Fl.BorderBox, {});
  BoxItem("FL_NO_BOX", Fl.NoBox, {});
  IF boxChoice.SetValue(0) THEN END;  (* as Fl_Menu_::menu() leaves it *)

  NEW(box); Fl.OpenBox(box, 110, 172, 114, 15, "Lt, Rt, Top, Bot");
  box.SetLabelSize(10);
  NEW(margins); FlInputs.OpenInput(margins, 110, 187, 114, 20, "Margins");
  margins.SetLabelSize(10); margins.SetTextSize(10);
  margins.action := MarginsAction; margins.SetWhen(inputWhen);

  Check(lfToCrLf, 333, 7, 77, "LF_TO_CRLF",
    "Line-feed (\n) performs carriage-return and line-feed (CRLF)", OutputTranslateAction);
  Check(lfToCr, 432, 7, 70, "LF_TO_CR",
    "Line-feed (\n) performs carriage-return (\r)", OutputTranslateAction);
  Check(crToLf, 528, 7, 70, "CR_TO_LF",
    "Carriage-return (\r) performs line-feed (\n)", OutputTranslateAction);
  Check(showunknown, 331, 31, 105, "show_unknown()",
    'Shows  unknown escape sequences/unprintable chars as "¿" character', ShowUnknownAction);
  Check(interactivecursor, 473, 31, 125, "Interactive Cursor",
    "Allow Up/Dn/Lt/Rt keys to move cursor|when terminal has focus", InteractiveCursorAction);
  Check(ansi, 331, 55, 95, "ansi()", "Handle ANSI/xterm escape sequences", AnsiAction);
  Check(stdoutRadio, 473, 55, 125, "Echo tests to stdout", "Also send test output to stdout", NIL);

  ColorInput(textcolorIn, 333, 79, "textcolor()",
    "The widget's text color. Has the effect of simultaneously setting:|> textfgcolor()|>textfgcolor_default()", TRUE);
  ColorInput(textfgIn, 333, 103, "textfgcolor()", "The text foreground color.", TRUE);
  ColorInput(textfgDefaultIn, 333, 127, "textfgcolor_default()",
    "The text foreground default color.", TRUE);
  ColorInput(cursorfgIn, 333, 151, "cursorfgcolor()", "Foreground color for text under the cursor.", FALSE);
  ColorInput(selectionfgIn, 333, 175, "selectionfgcolor()",
    "The mouse selection foreground color.", TRUE);
  ColorInput(colorIn, 521, 79, "color()", "The widget's background color().", TRUE);
  ColorInput(textbgIn, 521, 103, "textbgcolor()",
    "The text background color.|Refer to the docs for the special value 0xffffffff.", TRUE);
  ColorInput(textbgDefaultIn, 521, 127, "textbgcolor_default()",
    "The text background default color.|Refer to the docs for the special value 0xffffffff.", TRUE);
  ColorInput(cursorbgIn, 521, 151, "cursorbgcolor()",
    "Background color for the cursor.|This is the cursor block's color", FALSE);
  ColorInput(selectionbgIn, 521, 175, "selectionbgcolor()",
    "The mouse selection background color.", TRUE);

  NEW(colorChoice); FlMenus.OpenChoice(colorChoice, 379, 206, 180, 20, "Terminal Color");
  colorChoice.SetTooltip(
    "The (XTERM) colors can be influenced by Dim/Bold, whereas the (RGB) colors are not.");
  colorChoice.SetDownBox(Fl.BorderBox); colorChoice.SetLabelSize(9); colorChoice.SetTextSize(9);
  ColorItem("White on DarkAmber (XTERM)", {});
  ColorItem("White on Black (XTERM)", FlMenus.MenuDivider);
  ColorItem("White on DarkAmber (RGB)", {});
  ColorItem("White on Black (RGB)", {});
  ColorItem("Black on White (RGB)", {});
  ColorItem("Green on Dark Green (RGB)", {});
  ColorItem("Orange on Dark Orange (RGB)", {});
  IF colorChoice.SetValue(0) THEN END;

  NEW(g); Fl.OpenGroup(g, 608, 21, 152, 210, "Terminal Ops");
  g.SetBoxType(Fl.EngravedFrame); g.SetLabelSize(11);
  OpsButton(616, 26, "Reset Terminal|API",
    "Reset terminal using reset_terminal()|Clears: screen, history, sets default tabstops, etc.",
    ResetApi);
  OpsButton(686, 26, "Reset Terminal|ANSI",
    "Reset terminal using ESC[c|Clears: screen, history, sets default tabstops, etc.", ResetAnsi);
  OpsButton(616, 54, "Home Cursor|API",
    "Moves cursor to home position (top/left) using cursor_home()", HomeApi);
  OpsButton(686, 54, "Home Cursor|ANSI",
    "Moves cursor to home position (top/left) using ESC[H", HomeAnsi);
  OpsButton(616, 82, "Clear History|API", "Clear scrollback history using clear_history()",
    ClearHistoryApi);
  OpsButton(686, 82, "Clear History|ANSI", "Clear scrollback history using ESC[3J",
    ClearHistoryAnsi);
  OpsButton(616, 110, "Clear Screen|API",
    "Clear terminal screen using clear().|Moves what was on the screen to the scroll history.",
    ClearScreenApi);
  OpsButton(686, 110, "Clear Screen|ANSI",
    "Clear terminal screen using ESC[H + ESC[2J|Moves what was on the screen to the scroll history.",
    ClearScreenAnsi);
  NEW(g2); Fl.OpenGroup(g2, 616, 138, 134, 24, "");
  g2.SetBoxType(Fl.FlatBox); g2.SetColor(Fl.Dark2);
  OpsButton(616, 138, "Clear Screen|To Color",
    "Clear terminal screen to specific color|Moves what was on the screen to the scroll history.",
    ClearToColor);
  NEW(clearColor); FlInputs.OpenInput(clearColor, 686, 138, 64, 24, "");
  tip := 'The color used by "Clear Screen To Color" button|Can be decimal (e.g. 12) or hex (e.g. #0c, #ff000000, etc)';
  Tx(tip); clearColor.SetTooltip(t);
  clearColor.SetLabelSize(9); clearColor.SetTextFont(Fl.Courier); clearColor.SetTextSize(9);
  clearColor.SetWhen(inputWhen);
  clearColor.SetValue("#ff000000");
  g2.End;
  b := Button(640, 168, 90, 25, "Speed Test", "Runs a full screen random chars/colors|Shortcut: S",
    11, SpeedAction);
  b.SetShortcut(ORD("s"), {});
  b := Button(640, 198, 90, 25, "Ring Debug",
    "Show the Fl_Terminal raw ring buffer contents.|(Warning: This slows the UI and uses continuous cpu until closed)",
    11, RingAction);
  g.End;

  NEW(g); Fl.OpenGroup(g, 767, 21, 115, 210, "Terminal Tests");
  g.SetBoxType(Fl.EngravedFrame); g.SetLabelSize(11);
  b := Button(778, 31, 90, 30, "Unicode|Alignment",
    "Show a Unicode screen alignment test|Checks that troublesome Unicode chars don't cause misalignment",
    9, UnicodeAction);
  b := Button(778, 66, 90, 30, "+50 Lines",
    "Add 50 lines of text to terminal.|Tests screen history, scrollup", 9, AddLinesAction);
  b := Button(778, 101, 90, 30, "Color Bars",
    "Show colorbar test|Tests API for setting colors|Does *NOT* use ESC codes", 11, ColorBarsAction);
  NEW(box); Fl.OpenBox(box, 782, 173, 90, 15, "Self Tests"); box.SetLabelSize(10);
  b := Button(778, 191, 40, 30, "@<<",
    "Reverse through the ESC code self tests|Shortcut: SHIFT+E", 11, PrevTestAction);
  b.SetShortcut(ORD("e"), Fl.Shift);
  b := Button(828, 191, 40, 30, "@>>",
    "Advance through the ESC code self tests|Shortcut: 'e'", 11, NextTestAction);
  b.SetShortcut(ORD("e"), {});
  g.End;

  NEW(showfile); FlInputs.OpenInput(showfile, 109, 238, 773, 25, "Show File");
  showfile.SetTooltip("Type in the pathname of a file to cat to the screen");
  showfile.SetLabelSize(12); showfile.SetTextFont(Fl.Courier);
  showfile.action := ShowFileAction; showfile.SetWhen(Fl.WhenEnterKeyAlways);
  NEW(command); FlInputs.OpenInput(command, 109, 269, 773, 25, "Command");
  Tx("Command to run.|Hit ENTER to run command.|The command's stdout will appear in terminal.");
  command.SetTooltip(t);
  command.SetLabelSize(12); command.SetTextFont(Fl.Courier);
  command.action := CommandAction; command.SetWhen(Fl.WhenRelease + Fl.WhenEnterKey);

  NEW(tty); FlTerminal.OpenTerminal(tty, 10, 302, 872, 524, "");
  tty.SetBoxType(Fl.DownBox);
  tty.SetColor(Fl.ForegroundColor); tty.SetSelectionColor(Fl.BackgroundColor);
  tty.SetLabelSize(14); tty.SetAlign(Fl.AlignTop); tty.SetWhen(Fl.WhenRelease);
  win.SizeRange(897, 330, 0, 0);
  win.End;

  tty.SetColor(30200000H);  (* dark orange, which makes true black easy to see *)
  tty.SetTextSize(12);  (* smaller text, which the RGB test needs *)
  win.SetResizable(tty);
  command.SetWhen(Fl.WhenEnterKeyAlways);
  IF command.TakeFocus() THEN END;  (* the command has the keyboard to start with *)
  showfile.SetValue("/etc/login.defs");
  command.SetValue("ls -la --color && ping google.com -c 5");
  UpdateInputs
END MakeWindow;

BEGIN
  Clear;
  lines := 1; testnum := 0; testret := 1;
  LoadTests;
  MakeWindow;
  win.ShowArgs;
  TestFirstPage;  (* the first page of the tests *)
  Fl.Run
END Terminal.
