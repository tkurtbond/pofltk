MODULE Sudoku; (* FLTK's test/sudoku.cxx in Oberon-2 *)

(* Michael Sweet's Sudoku: click a cell or move to it with the arrow keys,
   and type a number from 1 to 9; 0, Delete or BackSpace clears it. With
   Shift or Caps Lock a number is a hint, shown small. A double click
   fills in the next number the cell's square hasn't got. The game, the
   difficulty and the window's place are kept in FLTK's preferences.

   The C++ program plays a note for each row of a solved puzzle, through
   ALSA, or X11's bell, or nothing under Wayland; this port plays none.
   Its notes' Fl::check is kept. Its random numbers are C's, seeded from
   C's time(), as the C++ program's are, so both deal the same game in the
   same second. Its faults are kept. When NewGame has to start again, the
   C++ program sets its row to -3 and goes on placing the numbers left,
   reading and writing rows -3 to -1, the 27 bytes before grid_values_:
   the end of the window object, two pointers and the seed. What it reads
   there decides how many random numbers it takes, and so the game dealt;
   this port keeps 27 bytes of its own before the grid, as they are on
   x86-64 when the pointers have no byte from 1 to 9 (a heap address that
   has one deals another game, and so does FLTK's program now and then).
   And the C++ program sets FL_MENU_VALUE on
   items[10 + difficulty], which is Undo, Redo, a submenu's end or the
   Difficulty title, not the difficulty's radio item, so no difficulty
   shows as chosen until one is picked; this port marks none. *)

IMPORT SYSTEM, Fl, FlDraw, FlImages, FlMenus, FlDialogs, FlHelp, FlPreferences;

CONST
  Before = 27;
  GroupSize = 160; CellSize = 50; CellOffset = 5; MenuOffset = 25;

  (* sudoku.xbm, 32 by 32, in hexadecimal *)
  IconW = 32; IconH = 32;
  IconBits0 = "ffffffffffffffff030c30c063cc33cf634c33cc634c33cc63cc33cc630c33cc";
  IconBits1 = "630c33cc030c30c0ffffffffffffffff030c30c0d3cc33cfd3cc30ccd3cc33ce";
  IconBits2 = "f3cc32cec3cc32ccc3cc33cf030c30c0ffffffffffffffff030c30c0f3cc33cf";
  IconBits3 = "834c33c1f3cc33cf334c33cc334c33ccf3cc33cf030c30c0ffffffffffffffff";


TYPE
  (* An Fl_Widget in the C++ program; a box here, whose Handle passes
     over FL_ENTER and FL_LEAVE, as Fl_Widget's does. *)
  Cell = POINTER TO CellDesc;
  CellDesc = RECORD (Fl.BoxDesc)
    row, col: INTEGER;
    readonly: BOOLEAN;
    value: INTEGER;
    hintMap: SET
  END;

  Board = POINTER TO BoardDesc;
  BoardDesc = RECORD (Fl.DoubleWindowDesc) END;

  GameState = ARRAY 81 OF INTEGER;

VAR
  sudoku: Board;
  menubar: FlMenus.SysMenuBar;
  grid: Fl.Group;
  seed: LONGINT;
  (* the C++ program's grid_values_, and the 27 bytes before it, which
     its NewGame reads and writes (the module comment) *)
  gridValues: ARRAY Before + 81 OF INTEGER;
  gridCells: ARRAY 9, 9 OF Cell;
  gridGroups: ARRAY 3, 3 OF Fl.Group;
  difficulty: INTEGER;
  sound: BOOLEAN;  (* the C++ program's sound_ # NULL *)
  undoStack: ARRAY 64 OF GameState;
  undoHead, undoTail, redoHead: INTEGER;
  helpDialog: FlHelp.HelpDialog;
  prefs: FlPreferences.Preferences;
  align: ARRAY 9 OF SET;
  helpText: ARRAY 4096 OF CHAR;
  helpLen: INTEGER;

PROCEDURE ["C", "rand"] Rand(): SYSTEM.INT32;
PROCEDURE ["C", "srand"] SRand(seed: SYSTEM.INT32);
(* time()'s low 32 bits: NetBSD's header renames time to __time50, and
   the bare symbol is its old time() of a 32-bit time_t, which leaves the
   high half of a LONGINT unset on i386. *)
PROCEDURE ["C", "time"] CTime(t: SYSTEM.ADDRESS): SYSTEM.INT32;

(* C's % of a value not negative *)
PROCEDURE Random(n: INTEGER): INTEGER;
BEGIN RETURN Rand() MOD n
END Random;

PROCEDURE Play(note: CHAR);
BEGIN IF Fl.Check() THEN END
END Play;

(* text "<name><j>.<k>" *)
PROCEDURE Name(name: ARRAY OF CHAR; j, k: INTEGER; VAR s: ARRAY OF CHAR);
  VAR i: INTEGER;
BEGIN
  i := 0; WHILE name[i] # 0X DO s[i] := name[i]; INC(i) END;
  s[i] := CHR(ORD("0") + j); s[i + 1] := "."; s[i + 2] := CHR(ORD("0") + k);
  s[i + 3] := 0X
END Name;

(* Cell *)

PROCEDURE (c: Cell) SetReadonly(r: BOOLEAN);
BEGIN c.readonly := r; c.Redraw
END SetReadonly;

PROCEDURE (c: Cell) SetHint(n: INTEGER);
BEGIN INCL(c.hintMap, n); c.Redraw
END SetHint;

PROCEDURE (c: Cell) ClearHint(n: INTEGER);
BEGIN EXCL(c.hintMap, n); c.Redraw
END ClearHint;

PROCEDURE (c: Cell) ClearHints;
BEGIN c.hintMap := {}; c.Redraw
END ClearHints;

PROCEDURE (c: Cell) SetValue(v: INTEGER);
BEGIN c.value := v; c.Redraw
END SetValue;

PROCEDURE (c: Cell) State(): INTEGER;
  VAR s: INTEGER;
BEGIN
  s := ORD(c.hintMap) DIV 2 + c.value * 1000H;
  IF c.readonly THEN INC(s, 200H) END;
  RETURN s
END State;

PROCEDURE (c: Cell) SetState(s: INTEGER);
BEGIN
  c.hintMap := SYSTEM.VAL(SET, s MOD 200H * 2);
  c.readonly := s DIV 200H MOD 2 = 1;
  c.value := s DIV 1000H MOD 10H;
  IF c.readonly THEN c.SetColor(Fl.Gray) ELSE c.SetColor(Fl.Light3) END;
  c.Redraw
END SetState;

PROCEDURE (c: Cell) Draw*;
  VAR col, i: INTEGER; s: ARRAY 2 OF CHAR;
BEGIN
  IF c.readonly THEN FlDraw.DrawBox(Fl.UpBox, c.X(), c.Y(), c.W(), c.H(), c.Color())
  ELSE FlDraw.DrawBox(Fl.DownBox, c.X(), c.Y(), c.W(), c.H(), c.Color())
  END;
  IF Fl.Focus() = c THEN
    col := Fl.ColorAverage(Fl.SelectionColor, c.Color(), 0.5D0);
    FlDraw.SetColor(col);
    FlDraw.RectF(c.X() + 4, c.Y() + 4, c.W() - 8, c.H() - 8);
    FlDraw.SetColor(Fl.Contrast(c.LabelColor(), col))
  ELSE FlDraw.SetColor(c.LabelColor())
  END;
  s[1] := 0X;
  IF c.value # 0 THEN
    s[0] := CHR(c.value + ORD("0"));
    FlDraw.SetFont(Fl.HelveticaBold, c.H() - 10);
    FlDraw.TextAligned(s, c.X(), c.Y(), c.W(), c.H(), Fl.AlignCenter)
  ELSE
    FlDraw.SetFont(Fl.HelveticaBold, c.H() DIV 5);
    FOR i := 1 TO 9 DO
      IF i IN c.hintMap THEN
        s[0] := CHR(i + ORD("0"));
        FlDraw.TextAligned(s, c.X() + 5, c.Y() + 5, c.W() - 10, c.H() - 10, align[i - 1])
      END
    END
  END
END Draw;

PROCEDURE ^ NextValue(c: Cell): INTEGER;
PROCEDURE ^ ClearHintsFor(row, col, val: INTEGER);
PROCEDURE ^ UndoCheckpoint;

PROCEDURE (c: Cell) Handle*(event: INTEGER): BOOLEAN;
  VAR key: INTEGER;
BEGIN
  CASE event OF
  | Fl.EvFocus: Fl.SetFocus(c); c.Redraw; RETURN TRUE
  | Fl.EvUnfocus: c.Redraw; RETURN TRUE
  | Fl.EvPush:
    IF ~c.readonly & Fl.EventInside(c.X(), c.Y(), c.W(), c.H()) THEN
      IF Fl.EventClicks() # 0 THEN
        IF c.value # 0 THEN
          IF c.value < 9 THEN c.SetValue(c.value + 1) ELSE c.SetValue(1) END
        ELSE c.SetValue(NextValue(c))
        END
      END;
      Fl.SetFocus(c); c.Redraw; RETURN TRUE
    END
  | Fl.EvKeyDown:
    IF Fl.EventState() * Fl.Ctrl = {} THEN
      key := Fl.EventKey() - ORD("0");
      IF (key < 0) OR (key > 9) THEN key := Fl.EventKey() - Fl.KeyKP - ORD("0") END;
      IF (key > 0) & (key <= 9) THEN
        IF c.readonly THEN FlDialogs.Beep(FlDialogs.BeepError); RETURN TRUE END;
        IF Fl.EventState() * (Fl.Shift + Fl.CapsLock) # {} THEN
          IF key IN c.hintMap THEN c.ClearHint(key) ELSE c.SetHint(key) END;
          UndoCheckpoint; c.Redraw
        ELSE
          c.SetValue(key); ClearHintsFor(c.row, c.col, key); UndoCheckpoint;
          c.DoCallback
        END;
        RETURN TRUE
      ELSIF (key = 0) OR (Fl.EventKey() = Fl.KeyBackSpace) OR (Fl.EventKey() = Fl.KeyDelete) THEN
        IF c.readonly THEN FlDialogs.Beep(FlDialogs.BeepError); RETURN TRUE END;
        IF Fl.EventState() * (Fl.Shift + Fl.CapsLock) # {} THEN
          c.ClearHints; UndoCheckpoint
        ELSE
          c.SetValue(0); c.DoCallback; UndoCheckpoint
        END;
        RETURN TRUE
      END
    END
  ELSE
  END;
  IF (event = Fl.EvEnter) OR (event = Fl.EvLeave) THEN RETURN FALSE END;
  RETURN c.Handle^(event)
END Handle;

PROCEDURE NewCell(row, col, x, y, w, h: INTEGER): Cell;
  VAR c: Cell;
BEGIN
  NEW(c); Fl.OpenBox(c, x, y, w, h, "");
  c.row := row; c.col := col; c.readonly := FALSE; c.hintMap := {};
  c.SetValue(0);
  RETURN c
END NewCell;

(* The game *)

PROCEDURE SaveState(VAR s: GameState);
  VAR j, k: INTEGER;
BEGIN
  FOR j := 0 TO 8 DO FOR k := 0 TO 8 DO s[j * 9 + k] := gridCells[j, k].State() END END
END SaveState;

PROCEDURE LoadState(VAR s: GameState);
  VAR j, k: INTEGER;
BEGIN
  FOR j := 0 TO 8 DO FOR k := 0 TO 8 DO gridCells[j, k].SetState(s[j * 9 + k]) END END
END LoadState;

PROCEDURE Undo;
BEGIN
  IF undoHead # undoTail THEN
    undoHead := (undoHead - 1) MOD 64;
    LoadState(undoStack[undoHead]); sudoku.Redraw
  ELSE FlDialogs.Beep(FlDialogs.BeepError)
  END
END Undo;

PROCEDURE Redo;
BEGIN
  IF undoHead # redoHead THEN
    undoHead := (undoHead + 1) MOD 64;
    LoadState(undoStack[undoHead]); sudoku.Redraw
  ELSE FlDialogs.Beep(FlDialogs.BeepError)
  END
END Redo;

PROCEDURE ClearUndo;
BEGIN
  undoHead := 0; undoTail := 0; redoHead := 0;
  SaveState(undoStack[undoHead])
END ClearUndo;

PROCEDURE UndoCheckpoint;
BEGIN
  IF undoHead = redoHead THEN redoHead := (redoHead + 1) MOD 64 END;
  undoHead := (undoHead + 1) MOD 64;
  IF undoHead = undoTail THEN undoTail := (undoTail + 1) MOD 64 END;
  SaveState(undoStack[undoHead])
END UndoCheckpoint;

PROCEDURE SetTitle;
BEGIN
  CASE difficulty OF
  | 0: sudoku.SetLabel("Sudoku - Easy")
  | 1: sudoku.SetLabel("Sudoku - Medium")
  | 2: sudoku.SetLabel("Sudoku - Hard")
  | 3: sudoku.SetLabel("Sudoku - Impossible")
  END
END SetTitle;

PROCEDURE CheckGame(highlight: BOOLEAN);
  VAR empty, correct: BOOLEAN; j, k, m, jj, kk, jjj, kkk, val: INTEGER; cell: Cell;
BEGIN
  empty := FALSE; correct := TRUE;
  FOR j := 0 TO 8 DO
    FOR k := 0 TO 8 DO
      cell := gridCells[j, k]; val := cell.value;
      IF ~cell.readonly THEN
        IF val = 0 THEN empty := TRUE
        ELSE
          m := 0;
          WHILE (m < 9) & ~((j # m) & (gridCells[m, k].value = val)
              OR (k # m) & (gridCells[j, m].value = val)) DO INC(m) END;
          IF m < 9 THEN
            IF highlight THEN cell.SetColor(Fl.Yellow); cell.Redraw END;
            correct := FALSE
          ELSIF highlight THEN cell.SetColor(Fl.Light3); cell.Redraw
          END
        END
      END
    END
  END;
  j := 0;
  WHILE j < 9 DO
    k := 0;
    WHILE k < 9 DO
      FOR jj := 0 TO 2 DO
        FOR kk := 0 TO 2 DO
          cell := gridCells[j + jj, k + kk]; val := cell.value;
          IF ~cell.readonly & (val # 0) THEN
            jjj := 0;
            LOOP
              IF jjj = 3 THEN EXIT END;
              kkk := 0;
              WHILE (kkk < 3) & ~((jj # jjj) & (kk # kkk)
                  & (gridCells[j + jjj, k + kkk].value = val)) DO INC(kkk) END;
              IF kkk < 3 THEN EXIT END;
              INC(jjj)
            END;
            IF jjj < 3 THEN
              IF highlight THEN cell.SetColor(Fl.Yellow); cell.Redraw END;
              correct := FALSE
            END
          END
        END
      END;
      INC(k, 3)
    END;
    INC(j, 3)
  END;
  IF ~empty & correct THEN
    FOR j := 0 TO 8 DO
      FOR k := 0 TO 8 DO
        cell := gridCells[j, k]; cell.SetColor(Fl.Green); cell.SetReadonly(TRUE)
      END;
      IF sound THEN Play(CHR(ORD("A") + gridCells[j, 8].value - 1)) END
    END
  END
END CheckGame;

PROCEDURE UpdateHelpers;
  VAR j, k, m, row, col, ro, co, v: INTEGER; taken: ARRAY 10 OF BOOLEAN; dst: Cell;
BEGIN
  FOR j := 0 TO 8 DO FOR k := 0 TO 8 DO gridCells[j, k].ClearHints END END;
  FOR j := 0 TO 80 DO
    FOR k := 0 TO 9 DO taken[k] := FALSE END;
    row := j DIV 9; col := j MOD 9;
    dst := gridCells[row, col];
    IF dst.value = 0 THEN
      FOR k := 0 TO 8 DO v := gridCells[row, k].value; IF v # 0 THEN taken[v] := TRUE END END;
      FOR k := 0 TO 8 DO v := gridCells[k, col].value; IF v # 0 THEN taken[v] := TRUE END END;
      ro := row DIV 3 * 3; co := col DIV 3 * 3;
      FOR k := 0 TO 2 DO
        FOR m := 0 TO 2 DO
          v := gridCells[ro + k, co + m].value; IF v # 0 THEN taken[v] := TRUE END
        END
      END;
      FOR m := 1 TO 9 DO IF ~taken[m] THEN dst.SetHint(m) END END
    END
  END;
  UndoCheckpoint
END UpdateHelpers;

PROCEDURE ClearHintsFor(row, col, val: INTEGER);
  VAR i, j: INTEGER;
BEGIN
  FOR i := 0 TO 8 DO gridCells[row, i].ClearHint(val) END;
  FOR i := 0 TO 8 DO gridCells[i, col].ClearHint(val) END;
  row := row DIV 3 * 3; col := col DIV 3 * 3;
  FOR i := 0 TO 2 DO FOR j := 0 TO 2 DO gridCells[row + i, col + j].ClearHint(val) END END
END ClearHintsFor;

PROCEDURE ClearValues;
  VAR j, k: INTEGER;
BEGIN
  FOR j := 0 TO 8 DO FOR k := 0 TO 8 DO gridValues[Before + j * 9 + k] := 0 END END
END ClearValues;

(* The bytes before grid_values_ in the C++ program on x86-64: the end of
   the Fl_Double_Window, zero; menubar_ and grid_, pointers whose four low
   bytes are taken to be no digit and whose four high ones are zero; and
   seed_, set by each NewGame. *)
PROCEDURE ClearBefore;
  VAR i: INTEGER;
BEGIN
  FOR i := 0 TO Before - 1 DO gridValues[i] := 0 END;
  FOR i := 3 TO 6 DO gridValues[i] := 0A0H END;
  FOR i := 11 TO 14 DO gridValues[i] := 0A0H END
END ClearBefore;

PROCEDURE NewGame(s: LONGINT);
  VAR j, k, m, n, t, count, mm, nn: INTEGER; cell: Cell; numbers: ARRAY 9 OF INTEGER;
BEGIN
  seed := s;
  FOR j := 0 TO 7 DO gridValues[Before - 8 + j] := SHORT(s MOD 100H); s := s DIV 100H END;
  SRand(SHORT(seed));
  ClearValues;
  j := 0;
  WHILE j < 9 DO
    k := 0;
    WHILE k < 9 DO
      FOR t := 1 TO 9 DO
        count := 0;
        LOOP
          IF count = 20 THEN EXIT END;
          m := j + Random(3); n := k + Random(3);
          IF gridValues[Before + m * 9 + n] = 0 THEN
            mm := 0; WHILE (mm < m) & (gridValues[Before + mm * 9 + n] # t) DO INC(mm) END;
            IF mm >= m THEN
              nn := 0; WHILE (nn < n) & (gridValues[Before + m * 9 + nn] # t) DO INC(nn) END;
              IF nn >= n THEN gridValues[Before + m * 9 + n] := t; EXIT END
            END
          END;
          INC(count)
        END;
        IF count = 20 THEN k := 9; j := -3; ClearValues END
      END;
      INC(k, 3)
    END;
    INC(j, 3)
  END;
  FOR j := 0 TO 8 DO
    FOR k := 0 TO 8 DO
      cell := gridCells[j, k];
      cell.SetValue(0); cell.SetReadonly(FALSE); cell.SetColor(Fl.Light3); cell.ClearHints
    END
  END;
  count := 11 * (5 - difficulty);
  FOR j := 0 TO 8 DO numbers[j] := j + 1 END;
  WHILE count > 0 DO
    FOR j := 0 TO 19 DO
      k := Random(9); m := Random(9);
      t := numbers[k]; numbers[k] := numbers[m]; numbers[m] := t
    END;
    j := 0;
    WHILE (count > 0) & (j < 9) DO
      t := numbers[j];
      k := 0;
      LOOP
        IF (count = 0) OR (k = 9) THEN EXIT END;
        cell := gridCells[j, k];
        IF (gridValues[Before + j * 9 + k] = t) & ~cell.readonly THEN
          cell.SetValue(gridValues[Before + j * 9 + k]); cell.SetReadonly(TRUE); cell.SetColor(Fl.Gray);
          DEC(count); EXIT
        END;
        INC(k)
      END;
      INC(j)
    END
  END;
  ClearUndo
END NewGame;

PROCEDURE NextValue(c: Cell): INTEGER;
  VAR j, k, m, n: INTEGER; numbers: ARRAY 9 OF BOOLEAN;
BEGIN
  j := 0;
  LOOP
    IF j = 9 THEN EXIT END;
    k := 0; WHILE (k < 9) & (gridCells[j, k] # c) DO INC(k) END;
    IF k < 9 THEN EXIT END;
    INC(j)
  END;
  IF j = 9 THEN RETURN 1 END;
  DEC(j, j MOD 3); DEC(k, k MOD 3);
  FOR m := 0 TO 8 DO numbers[m] := FALSE END;
  FOR m := 0 TO 2 DO
    FOR n := 0 TO 2 DO
      c := gridCells[j + m, k + n];
      IF c.value # 0 THEN numbers[c.value - 1] := TRUE END
    END
  END;
  FOR j := 0 TO 8 DO IF ~numbers[j] THEN RETURN j + 1 END END;
  RETURN 1
END NextValue;

PROCEDURE SolveGame;
  VAR j, k: INTEGER; cell: Cell;
BEGIN
  FOR j := 0 TO 8 DO
    FOR k := 0 TO 8 DO
      cell := gridCells[j, k];
      cell.SetValue(gridValues[Before + j * 9 + k]); cell.SetReadonly(TRUE); cell.SetColor(Fl.Gray)
    END;
    IF sound THEN Play(CHR(ORD("A") + gridCells[j, 8].value - 1)) END
  END;
  UndoCheckpoint
END SolveGame;

PROCEDURE LoadGame;
  VAR j, k, val: INTEGER; solved: BOOLEAN; cell: Cell; name: ARRAY 32 OF CHAR;
BEGIN
  ClearValues;
  solved := TRUE;
  j := 0;
  WHILE j < 9 DO
    k := 0;
    WHILE k < 9 DO
      cell := gridCells[j, k];
      Name("value", j, k, name);
      IF ~prefs.HasEntry(name) THEN
        j := 9; gridValues[Before] := 0; k := 9
      ELSE
        gridValues[Before + j * 9 + k] := prefs.Int(name, 0);
        Name("state", j, k, name); cell.SetValue(prefs.Int(name, 0));
        Name("readonly", j, k, name); val := prefs.Int(name, 0);
        cell.SetReadonly(val # 0);
        IF val # 0 THEN cell.SetColor(Fl.Gray)
        ELSE cell.SetColor(Fl.Light3); solved := FALSE
        END;
        Name("hint", j, k, name);
        cell.hintMap := SYSTEM.VAL(SET, prefs.Int(name, 0));
        INC(k)
      END
    END;
    INC(j)
  END;
  IF solved OR (gridValues[Before] = 0) THEN NewGame(CTime(0)) ELSE CheckGame(FALSE) END;
  ClearUndo
END LoadGame;

PROCEDURE SaveGame;
  VAR j, k, m, r: INTEGER; cell: Cell; name: ARRAY 32 OF CHAR;
BEGIN
  FOR j := 0 TO 8 DO
    FOR k := 0 TO 8 DO
      cell := gridCells[j, k];
      Name("value", j, k, name); prefs.SetInt(name, gridValues[Before + j * 9 + k]);
      Name("state", j, k, name); prefs.SetInt(name, cell.value);
      IF cell.readonly THEN r := 1 ELSE r := 0 END;
      Name("readonly", j, k, name); prefs.SetInt(name, r);
      FOR m := 0 TO 7 DO
        Name("hint", j, k, name); prefs.SetInt(name, ORD(cell.hintMap))
      END
    END
  END
END SaveGame;

(* The window *)

PROCEDURE (b: Board) Resize*(x, y, w, h: INTEGER);
BEGIN
  b.Resize^(x, y, w, h);
  prefs.SetInt("x", x); prefs.SetInt("y", y);
  prefs.SetInt("width", w); prefs.SetInt("height", h)
END Resize;

(* Callbacks *)

PROCEDURE CheckCB(w: Fl.Widget);
BEGIN CheckGame(TRUE)
END CheckCB;

PROCEDURE CloseCB(w: Fl.Widget);
BEGIN
  SaveGame; sudoku.Hide;
  IF helpDialog # NIL THEN helpDialog.Hide END
END CloseCB;

PROCEDURE NewCB(w: Fl.Widget);
BEGIN
  IF gridCells[0, 0].Color() # Fl.Green THEN
    IF FlDialogs.Choice("Are you sure you want to change the difficulty level and discard the current game?",
        "Keep Current Game", "Start New Game", "") = 0 THEN RETURN END
  END;
  NewGame(CTime(0))
END NewCB;

PROCEDURE Diff(w: Fl.Widget; diff: INTEGER);
  VAR note: ARRAY 128 OF CHAR; i: INTEGER;
BEGIN
  IF diff # difficulty THEN
    difficulty := diff;
    NewCB(w);
    SetTitle;
    IF diff > 1 THEN
      IF prefs.Int("difficulty_warning", 0) = 0 THEN
        prefs.SetInt("difficulty_warning", 1);
        note := "Note: 'Hard' and 'Impossible' puzzles may have more than one possible solution.|This is not an error or bug.";
        i := 0; WHILE note[i] # 0X DO IF note[i] = "|" THEN note[i] := 0AX END; INC(i) END;
        FlDialogs.Alert(note)
      END
    END;
    prefs.SetInt("difficulty", difficulty)
  END
END Diff;

PROCEDURE EasyCB(w: Fl.Widget);
BEGIN Diff(w, 0)
END EasyCB;

PROCEDURE MediumCB(w: Fl.Widget);
BEGIN Diff(w, 1)
END MediumCB;

PROCEDURE HardCB(w: Fl.Widget);
BEGIN Diff(w, 2)
END HardCB;

PROCEDURE ImpossibleCB(w: Fl.Widget);
BEGIN Diff(w, 3)
END ImpossibleCB;

PROCEDURE UpdateHelpersCB(w: Fl.Widget);
BEGIN UpdateHelpers
END UpdateHelpersCB;

(* the help page; Line adds a line to it *)
PROCEDURE Line(t: ARRAY OF CHAR);
  VAR i: INTEGER;
BEGIN
  i := 0; WHILE t[i] # 0X DO helpText[helpLen] := t[i]; INC(helpLen); INC(i) END;
  helpText[helpLen] := 0AX; helpText[helpLen + 1] := 0X; INC(helpLen)
END Line;

PROCEDURE MakeHelpText;
BEGIN
  helpLen := 0;
  Line("<HTML>");
  Line("<HEAD>");
  Line("<TITLE>Sudoku Help</TITLE>");
  Line("</HEAD>");
  Line("<BODY BGCOLOR='#ffffff'>");
  Line("<H2>About the Game</H2>");
  Line("<P>Sudoku (pronounced soo-dough-coo with the emphasis on the");
  Line("first syllable) is a simple number-based puzzle/game played on a");
  Line("9x9 grid that is divided into 3x3 subgrids. The goal is to enter");
  Line("a number from 1 to 9 in each cell so that each number appears");
  Line("only once in each column and row. In addition, each 3x3 subgrid");
  Line("may only contain one of each number.</P>");
  Line("<P>This version of the puzzle is copyright 2005-2010 by Michael R");
  Line("Sweet.</P>");
  Line("<P><B>Note:</B> The 'Hard' and 'Impossible' difficulty");
  Line("levels generate Sudoku puzzles with multiple possible solutions.");
  Line("While some purists insist that these cannot be called 'Sudoku'");
  Line("puzzles, the author (me) has personally solved many such puzzles");
  Line("in published/printed Sudoku books and finds them far more");
  Line("interesting than the simple single solution variety. If you don't");
  Line("like it, don't play with the difficulty set to 'High' or");
  Line("'Impossible'.</P>");
  Line("<H2>How to Play the Game</H2>");
  Line("<P>At the start of a new game, Sudoku fills in a random selection");
  Line("of cells for you - the number of cells depends on the difficulty");
  Line("level you use. Click in any of the empty cells or use the arrow");
  Line("keys to highlight individual cells and press a number from 1 to 9");
  Line("to fill in the cell. To clear a cell, press 0, Delete, or");
  Line("Backspace. When you have successfully completed all subgrids, the");
  Line("entire puzzle is highlighted in green until you start a new");
  Line("game.</P>");
  Line("<P>As you work to complete the puzzle, you can display possible");
  Line("solutions inside each cell by holding the Shift key and pressing");
  Line("each number in turn. Repeat the process to remove individual");
  Line("numbers, or press a number without the Shift key to replace them");
  Line("with the actual number to use.</P>");
  Line("</BODY>");
END MakeHelpText;

PROCEDURE HelpCB(w: Fl.Widget);
BEGIN
  IF helpDialog = NIL THEN
    NEW(helpDialog); FlHelp.OpenHelpDialog(helpDialog);
    MakeHelpText; helpDialog.SetValue(helpText)
  END;
  helpDialog.Show
END HelpCB;

PROCEDURE MuteCB(w: Fl.Widget);
BEGIN
  IF sound THEN sound := FALSE; prefs.SetInt("mute_sound", 1)
  ELSE sound := TRUE; prefs.SetInt("mute_sound", 0)
  END
END MuteCB;

PROCEDURE RestartCB(w: Fl.Widget);
  VAR solved: BOOLEAN; j, k, v: INTEGER; cell: Cell;
BEGIN
  solved := TRUE;
  FOR j := 0 TO 8 DO
    FOR k := 0 TO 8 DO
      cell := gridCells[j, k];
      cell.ClearHints;
      IF ~cell.readonly THEN
        solved := FALSE;
        v := cell.value;
        cell.SetValue(0); cell.SetColor(Fl.Light3);
        IF (v # 0) & sound THEN Play(CHR(ORD("A") + v - 1)) END
      END
    END
  END;
  IF solved THEN NewGame(seed) ELSE ClearUndo END
END RestartCB;

PROCEDURE SolveCB(w: Fl.Widget);
BEGIN SolveGame
END SolveCB;

PROCEDURE ResetCB(w: Fl.Widget);
BEGIN
  w.SetColor(Fl.Light3); w.Redraw;
  CheckGame(FALSE)
END ResetCB;

PROCEDURE UndoCB(w: Fl.Widget);
BEGIN Undo
END UndoCB;

PROCEDURE RedoCB(w: Fl.Widget);
BEGIN Redo
END RedoCB;

PROCEDURE Item(label: ARRAY OF CHAR; key: CHAR; state: SET; action: FlMenus.Action; flags: SET);
  VAR k: INTEGER;
BEGIN
  IF key = 0X THEN k := 0 ELSE k := ORD(key) END;
  IF menubar.Add(label, k, state, action, flags) >= 0 THEN END
END Item;

PROCEDURE Hex(c: CHAR): INTEGER;
BEGIN
  IF c <= "9" THEN RETURN ORD(c) - ORD("0") ELSE RETURN ORD(c) - ORD("a") + 10 END
END Hex;

(* bits[at ...], from the hexadecimal h *)
PROCEDURE Bits(h: ARRAY OF CHAR; at: INTEGER; VAR bits: ARRAY OF CHAR);
  VAR i: INTEGER;
BEGIN
  i := 0;
  WHILE h[2 * i] # 0X DO bits[at + i] := CHR(Hex(h[2 * i]) * 16 + Hex(h[2 * i + 1])); INC(i) END
END Bits;

PROCEDURE MakeIcon;
  VAR bits: ARRAY IconW * IconH DIV 8 OF CHAR;
    bm, icon: FlImages.Image; surf: FlImages.Surface;
BEGIN
  Bits(IconBits0, 0, bits); Bits(IconBits1, 32, bits);
  Bits(IconBits2, 64, bits); Bits(IconBits3, 96, bits);
  NEW(bm); FlImages.OpenBitmap(bm, bits, IconW, IconH);
  (* Fl_Image_Surface(w, h, 1) in the C++ program, which is the same at
     a scale of 1 *)
  NEW(surf); FlImages.OpenSurface(surf, IconW, IconH);
  surf.Begin;
  FlDraw.SetColor(Fl.White); FlDraw.RectF(0, 0, IconW, IconH);
  FlDraw.SetColor(Fl.Black); bm.Draw(0, 0);
  surf.End;
  NEW(icon); surf.GetImage(icon);
  FlImages.SetIcon(sudoku, icon);
  icon.Close; surf.Close; bm.Close
END MakeIcon;

PROCEDURE Make;
  VAR j, k, x, y, w, h: INTEGER; g: Fl.Group; muted: BOOLEAN;
BEGIN
  undoHead := 0; undoTail := 0; redoHead := 0;
  ClearBefore;
  NEW(sudoku); Fl.OpenDoubleWindow(sudoku, GroupSize * 3, GroupSize * 3 + MenuOffset, "Sudoku");
  muted := prefs.Int("mute_sound", 0) # 0;
  sound := ~muted;
  difficulty := prefs.Int("difficulty", 0);
  IF (difficulty < 0) OR (difficulty > 3) THEN difficulty := 0 END;

  NEW(menubar); FlMenus.OpenSysMenuBar(menubar, 0, 0, 3 * GroupSize, 25, "");
  Item("&Game/&New Game", "n", Fl.Command, NewCB, FlMenus.MenuDivider);
  Item("&Game/&Check Game", "c", Fl.Command, CheckCB, {});
  Item("&Game/&Restart Game", "r", Fl.Command, RestartCB, {});
  Item("&Game/&Solve Game", "s", Fl.Command, SolveCB, FlMenus.MenuDivider);
  Item("&Game/&Update Helpers", 0X, {}, UpdateHelpersCB, {});
  IF muted THEN
    Item("&Game/&Mute Sound", "m", Fl.Command, MuteCB,
      FlMenus.MenuToggle + FlMenus.MenuDivider + FlMenus.MenuValue)
  ELSE Item("&Game/&Mute Sound", "m", Fl.Command, MuteCB, FlMenus.MenuToggle + FlMenus.MenuDivider)
  END;
  Item("&Game/&Quit", "q", Fl.Command, CloseCB, {});
  Item("&Edit/&Undo", "z", Fl.Command, UndoCB, {});
  Item("&Edit/&Redo", "Z", Fl.Command, RedoCB, {});
  Item("&Difficulty/&Easy", 0X, {}, EasyCB, FlMenus.MenuRadio);
  Item("&Difficulty/&Medium", 0X, {}, MediumCB, FlMenus.MenuRadio);
  Item("&Difficulty/&Hard", 0X, {}, HardCB, FlMenus.MenuRadio);
  Item("&Difficulty/&Impossible", 0X, {}, ImpossibleCB, FlMenus.MenuRadio);
  IF menubar.Add("&Help/&About Sudoku", Fl.KeyF + 1, {}, HelpCB, {}) >= 0 THEN END;

  NEW(grid); Fl.OpenGroup(grid, 0, MenuOffset, 3 * GroupSize, 3 * GroupSize, "");
  FOR j := 0 TO 2 DO
    FOR k := 0 TO 2 DO
      NEW(g); Fl.OpenGroup(g, k * GroupSize, j * GroupSize + MenuOffset, GroupSize, GroupSize, "");
      g.SetBoxType(Fl.BorderBox);
      IF (j = 1) # (k = 1) THEN g.SetColor(Fl.Dark3) ELSE g.SetColor(Fl.Dark2) END;
      g.End;
      gridGroups[j, k] := g
    END
  END;
  FOR j := 0 TO 8 DO
    FOR k := 0 TO 8 DO
      gridCells[j, k] := NewCell(j, k,
        k * CellSize + CellOffset + k DIV 3 * (GroupSize - 3 * CellSize),
        j * CellSize + CellOffset + MenuOffset + j DIV 3 * (GroupSize - 3 * CellSize),
        CellSize, CellSize);
      gridCells[j, k].action := ResetCB
    END
  END;
  grid.End;
  sudoku.End;

  MakeIcon;
  sudoku.action := CloseCB;
  sudoku.SetResizable(grid);
  sudoku.SizeRangeStep(3 * GroupSize, 3 * GroupSize + MenuOffset, 0, 0, 5, 5, TRUE);
  IF prefs.HasEntry("x") THEN
    x := prefs.Int("x", -1); y := prefs.Int("y", -1);
    w := prefs.Int("width", 3 * GroupSize); h := prefs.Int("height", 3 * GroupSize + MenuOffset);
    sudoku.Resize(x, y, w, h)
  END;
  SetTitle;
  ClearUndo
END Make;

BEGIN
  align[0] := Fl.AlignTopLeft; align[1] := Fl.AlignTop; align[2] := Fl.AlignTopRight;
  align[3] := Fl.AlignLeft; align[4] := {}; align[5] := Fl.AlignRight;
  align[6] := Fl.AlignBottomLeft; align[7] := Fl.AlignBottom; align[8] := Fl.AlignBottomRight;
  NEW(prefs); FlPreferences.Open(prefs, FlPreferences.User, "fltk.org", "sudoku");
  Make;
  sudoku.ShowArgs;
  LoadGame;
  Fl.Run;
  IF prefs.Flush() THEN END
END Sudoku.
