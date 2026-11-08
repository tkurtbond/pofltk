MODULE Blocks; (* FLTK's test/blocks.cxx in Oberon-2 *)

(* "Block Attack!", Michael Sweet's game: columns of blocks scroll in from
   the right, and a click on two or more adjacent blocks of a colour, or on
   a bomb, blasts them; the game ends when the columns fill the window.
   Space starts or pauses it, "?" shows the help, "+" goes up a level,
   Alt+Shift+H sets the high score to the score, and "f" shows the frames
   a second. The high score is kept in FLTK's preferences, as the C++
   program keeps it.

   FLTK's program plays an explosion through ALSA, CoreAudio or Windows'
   sound alone; where its test/ is built without them, as here, it is
   silent, and so is this port. Its random numbers and its clock are C's
   rand(), seeded with srand(time(NULL)), and time(), so that both play
   the same game from the same second. Its REALs are the C++ program's
   floats.

   One change: when the timer removes a column's last block, the C++
   program steps its column pointer back, before the first column if it
   was that one, and reads a count there to end its inner loop; this port
   ends the loop instead, and goes on with the column that moved into the
   empty one's place, as the C++ program then does. *)

IMPORT SYSTEM, Fl, FlButtons, FlDraw, FlImages, FlPreferences, OutStr, BlocksPixmaps;

CONST
  Cols = 25; Rows = 15; Size = 32; Blast = 100;
  (* the timer's interval is multiplied by these on (a) a new level, (b)
     a click on a normal block, (c) one on a bomb *)
  LevelFactor = 0.900; NormalFactor = 0.999; BombFactor = 0.995;

TYPE
  Block = RECORD
    color: INTEGER;   (* 1 to 7; negated while marked; Blast and up as it blasts *)
    bomb: BOOLEAN;
    y: REAL
  END;

  Column = RECORD
    numBlocks: INTEGER;
    blocks: ARRAY Rows OF Block;
    x: REAL
  END;

  Window = POINTER TO RECORD (Fl.DoubleWindowDesc)
    frames, framesPerSecond: INTEGER;
    frameTime: LONGINT;
    showFps: BOOLEAN;
    helpButton, playButton: FlButtons.Button;
    numColumns: INTEGER;
    columns: ARRAY Cols OF Column;
    count: INTEGER;
    help: BOOLEAN;
    highScore: INTEGER;
    interval: REAL;
    level, numColors, openedColumns: INTEGER;
    paused: BOOLEAN;
    score: INTEGER;
    title: ARRAY 255 OF CHAR;
    titleY: INTEGER
  END;

  Ticker = POINTER TO RECORD (Fl.TimerDesc) END;

VAR
  screenBitmap, screenTile: FlImages.Image;
  screenBits: ARRAY 8 OF CHAR;
  prefs: FlPreferences.Preferences;
  bw: Window;
  ticker: Ticker;
  helpText, titleText: ARRAY 128 OF CHAR;

PROCEDURE ["C", "rand"] Rand(): SYSTEM.INT32;
PROCEDURE ["C", "srand"] SRand(seed: SYSTEM.INT32);
(* time()'s low 32 bits: NetBSD's header renames time to __time50, and
   the bare symbol is its old time() of a 32-bit time_t, which leaves the
   high half of a LONGINT unset on i386. *)
PROCEDURE ["C", "time"] CTime(t: SYSTEM.ADDRESS): SYSTEM.INT32;

PROCEDURE Time(): LONGINT;
BEGIN RETURN CTime(0)
END Time;

(* C's (int) of a float that is never negative here. *)
PROCEDURE Int(r: REAL): INTEGER;
BEGIN RETURN SHORT(ENTIER(r))
END Int;

(* The explosion: FLTK's play_explosion, silent, checks for events first. *)
PROCEDURE PlayExplosion;
BEGIN IF Fl.Check() THEN END
END PlayExplosion;

PROCEDURE (w: Window) Init;
BEGIN
  w.frames := 0; w.framesPerSecond := 0; w.frameTime := Time();
  w.showFps := FALSE; w.count := 0; w.help := FALSE; w.interval := -1.0;
  w.level := 1; w.numColors := 3; w.numColumns := 0; w.paused := FALSE;
  w.score := 0; w.title := ""; w.titleY := 0
END Init;

(* Marks every block of color, as a bomb of it blasts them; the count of
   them, plus 1. *)
PROCEDURE (w: Window) Bomb(color: INTEGER): INTEGER;
  VAR j, k, count: INTEGER;
BEGIN
  IF color >= Blast THEN RETURN 0 END;
  count := 1;
  FOR j := 0 TO w.numColumns - 1 DO
    FOR k := 0 TO w.columns[j].numBlocks - 1 DO
      IF w.columns[j].blocks[k].color = color THEN
        w.columns[j].blocks[k].color := -color; INC(count)
      END
    END
  END;
  RETURN count
END Bomb;

(* Marks the block at col, row and the blocks of its colour joined to it;
   the count of them. *)
PROCEDURE (w: Window) Click(col, row: INTEGER): INTEGER;
  VAR count, color: INTEGER;
BEGIN
  color := w.columns[col].blocks[row].color;
  IF (color < 0) OR (color >= Blast) THEN RETURN 0 END;
  WHILE (row > 0) & (w.columns[col].blocks[row - 1].color = color) DO DEC(row) END;
  count := 0;
  WHILE (row < w.columns[col].numBlocks) & (w.columns[col].blocks[row].color = color) DO
    w.columns[col].blocks[row].color := -color;
    IF (col > 0) & (row < w.columns[col - 1].numBlocks)
        & (w.columns[col - 1].blocks[row].color = color) THEN
      INC(count, w.Click(col - 1, row))
    END;
    IF (col < w.numColumns - 1) & (row < w.columns[col + 1].numBlocks)
        & (w.columns[col + 1].blocks[row].color = color) THEN
      INC(count, w.Click(col + 1, row))
    END;
    INC(count); INC(row)
  END;
  RETURN count
END Click;

PROCEDURE (w: Window) UpLevel;
BEGIN
  w.interval := w.interval * LevelFactor;
  w.openedColumns := 0;
  IF w.numColors < 7 THEN INC(w.numColors) END;
  INC(w.level);
  w.title := ""; OutStr.String("Level: ", w.title); OutStr.Int(w.level, 0, w.title);
  w.titleY := w.H()
END UpLevel;

PROCEDURE (w: Window) NewGame;
BEGIN
  SRand(SHORT(Time()));
  w.Init;
  w.interval := 0.01666666666;
  w.openedColumns := 0;
  w.title := "Level: 1";
  w.titleY := w.H();
  w.Redraw
END NewGame;

PROCEDURE (w: Window) Draw*;
  VAR j, k, xx, yy, sz: INTEGER; curtime: LONGINT; s: ARRAY 255 OF CHAR;
BEGIN
  FlDraw.SetColor(Fl.Black);
  FlDraw.RectF(0, 0, w.W(), w.H());

  FOR j := 0 TO w.numColumns - 1 DO
    FOR k := 0 TO w.columns[j].numBlocks - 1 DO
      xx := w.W() - Int(w.columns[j].x);
      yy := w.H() - Size - Int(w.columns[j].blocks[k].y);
      IF w.columns[j].blocks[k].color >= Blast THEN
        INC(w.columns[j].blocks[k].color);
        BlocksPixmaps.blast.Draw(xx, yy)
      ELSIF w.columns[j].blocks[k].bomb THEN
        BlocksPixmaps.bomb[ABS(w.columns[j].blocks[k].color) - 1].Draw(xx, yy)
      ELSE
        BlocksPixmaps.normal[ABS(w.columns[j].blocks[k].color) - 1].Draw(xx, yy)
      END
    END
  END;

  IF (w.interval < 0.0) OR w.paused THEN
    FlDraw.SetColor(Fl.Black);
    screenTile.DrawPart(0, 0, w.W(), w.H(), 0, 0)
  END;

  w.playButton.Redraw;
  w.helpButton.Redraw;
  w.DrawChildren;

  IF (w.paused OR (w.interval < 0.0)) & (w.playButton.W() = 80) THEN
    IF w.help THEN
      FlDraw.SetFont(Fl.HelveticaBold, 24);
      FlDraw.SetColor(Fl.Black);
      FlDraw.TextAligned(helpText, 171, 3, w.W() - 250, w.H() - 6, Fl.AlignWrap + Fl.AlignLeft);
      FlDraw.SetColor(Fl.Yellow);
      FlDraw.TextAligned(helpText, 168, 0, w.W() - 250, w.H(), Fl.AlignWrap + Fl.AlignLeft)
    ELSE
      IF w.interval < 0.0 THEN
        IF (w.numColumns > 0) & (Time() MOD 8 < 4) THEN s := "Game Over"
        ELSE COPY(titleText, s)
        END
      ELSE s := "Paused"
      END;
      FlDraw.SetFont(Fl.HelveticaBold, 32);
      FlDraw.SetColor(Fl.Black);
      FlDraw.TextAligned(s, 6, 6, w.W() - 6, w.H() - 6, Fl.AlignCenter);
      FlDraw.SetColor(Fl.Yellow);
      FlDraw.TextAligned(s, 0, 0, w.W(), w.H(), Fl.AlignCenter)
    END
  END;

  curtime := Time();
  INC(w.frames);
  IF curtime > w.frameTime THEN
    w.framesPerSecond := (w.framesPerSecond + 3 * w.frames DIV SHORT(curtime - w.frameTime)) DIV 4;
    w.frames := 0;
    w.frameTime := curtime
  END;

  s := " Score: "; OutStr.Int(w.score, 0, s);
  FlDraw.SetColor(Fl.White);
  FlDraw.SetFont(Fl.Helvetica, 14);
  FlDraw.TextAligned(s, 40, 0, w.W() - 40, 20, Fl.AlignLeft);

  s := "High Score: "; OutStr.Int(w.highScore, 0, s); OutStr.Char(" ", s);
  FlDraw.TextAligned(s, 0, 0, w.W(), 20, Fl.AlignRight);

  IF (w.level > 1) OR (w.titleY <= 0) THEN
    s := "Level: "; OutStr.Int(w.level, 0, s); OutStr.Char(" ", s);
    FlDraw.TextAligned(s, 0, 0, w.W(), 20, Fl.AlignCenter)
  END;

  IF w.showFps THEN
    s := "FPS: "; OutStr.Int(w.framesPerSecond, 0, s); OutStr.Char(" ", s);
    FlDraw.TextAligned(s, 0, w.H() - 20, w.W(), 20, Fl.AlignLeft)
  END;

  IF (w.titleY > 0) & (w.interval > 0.0) THEN
    sz := 14 + w.titleY * 86 DIV w.H();
    FlDraw.SetFont(Fl.HelveticaBold, sz);
    FlDraw.SetColor(Fl.Yellow);
    FlDraw.TextAligned(w.title, 0, w.titleY, w.W(), sz, Fl.AlignCenter)
  END
END Draw;

PROCEDURE (w: Window) Handle*(event: INTEGER): BOOLEAN;
  VAR j, k, mx, my, count, hitCol, hitRow: INTEGER; text: ARRAY 32 OF CHAR;
BEGIN
  IF w.Handle^(event) THEN RETURN TRUE
  ELSIF (w.interval < 0.0) OR w.paused THEN RETURN FALSE
  END;
  IF event = Fl.EvKeyDown THEN
    Fl.EventText(text);
    IF (Fl.EventState() * (Fl.Ctrl + Fl.Alt + Fl.Meta) = {}) & (text = "+") THEN
      w.UpLevel; RETURN TRUE
    END;
    IF (Fl.EventState() * (Fl.Alt + Fl.Shift) = Fl.Alt + Fl.Shift) & (text = "H") THEN
      w.highScore := w.score;
      prefs.SetInt("high_score", w.highScore);
      RETURN TRUE
    END;
    IF text = "f" THEN w.showFps := ~w.showFps END
  ELSIF event = Fl.EvPush THEN
    mx := w.W() - Fl.EventX() + Size;
    my := w.H() - Fl.EventY();
    count := 0; hitCol := -1;
    j := 0;
    WHILE (count = 0) & (j < w.numColumns) DO
      k := 0;
      WHILE k < w.columns[j].numBlocks DO
        IF (mx >= w.columns[j].x) & (mx < w.columns[j].x + Size)
            & (my >= w.columns[j].blocks[k].y) & (my < w.columns[j].blocks[k].y + Size) THEN
          hitCol := j; hitRow := k;
          IF w.columns[j].blocks[k].bomb THEN count := w.Bomb(w.columns[j].blocks[k].color)
          ELSE count := w.Click(j, k)
          END;
          k := w.columns[j].numBlocks
        ELSE INC(k)
        END
      END;
      INC(j)
    END;

    IF count < 2 THEN
      FOR j := 0 TO w.numColumns - 1 DO
        FOR k := 0 TO w.columns[j].numBlocks - 1 DO
          w.columns[j].blocks[k].color := ABS(w.columns[j].blocks[k].color)
        END
      END
    ELSE
      DEC(count);
      IF w.columns[hitCol].blocks[hitRow].bomb THEN
        PlayExplosion;
        w.interval := w.interval * BombFactor;
        INC(w.score, count)
      ELSE
        PlayExplosion;
        w.interval := w.interval * NormalFactor;
        INC(w.score, count * count)
      END;
      IF w.score > w.highScore THEN
        w.highScore := w.score;
        prefs.SetInt("high_score", w.highScore)
      END;
      FOR j := 0 TO w.numColumns - 1 DO
        FOR k := 0 TO w.columns[j].numBlocks - 1 DO
          IF w.columns[j].blocks[k].color < 0 THEN w.columns[j].blocks[k].color := Blast END
        END
      END
    END;
    RETURN TRUE
  END;
  RETURN FALSE
END Handle;

PROCEDURE HelpCB(b: Fl.Widget);
BEGIN
  bw.help := ~bw.help; bw.paused := bw.help;
  bw.playButton.SetLabel("@>");
  bw.Redraw
END HelpCB;

PROCEDURE PlayCB(b: Fl.Widget);
BEGIN
  IF bw.interval < 0.0 THEN bw.NewGame ELSE bw.paused := ~bw.paused END;
  IF bw.paused THEN b.SetLabel("@>")
  ELSE b.SetLabel("@-2||"); bw.help := FALSE
  END
END PlayCB;

PROCEDURE (t: Ticker) Fire*;
  VAR i, j, k, s: INTEGER; lastx, lasty: REAL; removed: BOOLEAN;
BEGIN
  (* the blocks blasted, drawn 6 times, go; then the columns they empty *)
  i := 0;
  WHILE i < bw.numColumns DO
    j := 0; removed := FALSE;
    WHILE ~removed & (j < bw.columns[i].numBlocks) DO
      IF bw.columns[i].blocks[j].color > Blast + 5 THEN
        bw.Redraw;
        DEC(bw.columns[i].numBlocks);
        FOR k := j TO bw.columns[i].numBlocks - 1 DO
          bw.columns[i].blocks[k] := bw.columns[i].blocks[k + 1]
        END;
        IF bw.columns[i].numBlocks = 0 THEN
          DEC(bw.numColumns);
          FOR k := i TO bw.numColumns - 1 DO bw.columns[k] := bw.columns[k + 1] END;
          removed := TRUE
        END
      ELSE INC(j)
      END
    END;
    IF ~removed THEN INC(i) END
  END;

  (* columns close up to the right, and blocks fall *)
  lastx := bw.columns[0].x;
  FOR i := 0 TO bw.numColumns - 1 DO
    IF bw.columns[i].x > lastx THEN
      bw.columns[i].x := bw.columns[i].x - 8;
      bw.Redraw
    END;
    lastx := bw.columns[i].x + Size;
    IF ~bw.paused & (bw.interval > 0.0) THEN
      bw.Redraw;
      bw.columns[i].x := bw.columns[i].x + 0.25
    END;
    lasty := 0;
    FOR j := 0 TO bw.columns[i].numBlocks - 1 DO
      IF bw.columns[i].blocks[j].y > lasty THEN
        bw.Redraw;
        bw.columns[i].blocks[j].y := bw.columns[i].blocks[j].y - 4
      END;
      lasty := bw.columns[i].blocks[j].y + Size
    END
  END;

  IF bw.titleY > 0 THEN
    bw.Redraw;
    DEC(bw.titleY, 2)
  END;

  IF ~bw.paused & (bw.interval > 0.0) THEN
    DEC(bw.count);
    IF bw.count <= 0 THEN
      bw.Redraw;
      bw.count := 4 * Size;
      IF bw.numColumns = Cols THEN
        bw.interval := -1.0;
        PlayExplosion;
        bw.playButton.SetLabel("@>")
      ELSE
        INC(bw.openedColumns);
        IF bw.openedColumns > 2 * Cols THEN bw.UpLevel END;
        FOR k := bw.numColumns TO 1 BY -1 DO bw.columns[k] := bw.columns[k - 1] END;
        INC(bw.numColumns);
        bw.columns[0].x := 0;
        bw.columns[0].numBlocks := Rows;
        FOR j := 0 TO Rows - 1 DO
          bw.columns[0].blocks[j].bomb := (bw.numColors > 3) & (Rand() MOD 128 < bw.numColors);
          bw.columns[0].blocks[j].color := 1 + Rand() MOD bw.numColors;
          bw.columns[0].blocks[j].y := j * (Size + 8) + 24
        END
      END
    END
  ELSE
    DEC(bw.count);
    IF bw.count <= 0 THEN
      bw.count := 40;
      bw.Redraw
    END
  END;

  (* the play button grows when paused or over, and shrinks in play *)
  IF (bw.paused OR (bw.interval < 0.0)) & (bw.playButton.W() < 80) THEN
    s := bw.playButton.W() + 5;
    bw.playButton.Resize(s, (s - 20) * (bw.H() - s) DIV 120, s, s);
    bw.playButton.SetLabelSize(s DIV 2 + 4);
    bw.Redraw
  ELSIF ~bw.paused & (bw.interval > 0.0) & (bw.playButton.W() > 20) THEN
    s := bw.playButton.W() - 2;
    bw.playButton.Resize(s, (s - 20) * (bw.H() - s) DIV 120, s, s);
    bw.playButton.SetLabelSize(s DIV 2 + 4);
    bw.Redraw
  END;

  IF bw.interval > 0.0 THEN Fl.RepeatTimeout(t, bw.interval)
  ELSE Fl.RepeatTimeout(t, 0.1D0)
  END
END Fire;

PROCEDURE Open(w: Window; width, height: INTEGER; title: ARRAY OF CHAR);
BEGIN
  Fl.OpenDoubleWindow(w, width, height, title);
  w.Init;

  NEW(w.helpButton); FlButtons.OpenButton(w.helpButton, 0, 0, 20, 20, "?");
  w.helpButton.action := HelpCB;
  w.helpButton.SetShortcut(ORD("?"), {});

  NEW(w.playButton); FlButtons.OpenButton(w.playButton, 80, (w.H() - 80) DIV 2, 80, 80, "@>");
  w.playButton.action := PlayCB;
  w.playButton.SetLabelSize(44);
  w.playButton.SetShortcut(ORD(" "), {});

  w.highScore := prefs.Int("high_score", 0);

  NEW(ticker); Fl.AddTimeout(ticker, 0.01666666D0)
END Open;

BEGIN
  screenBits[0] := 0FFX; screenBits[1] := 55X; screenBits[2] := 0FFX; screenBits[3] := 0AAX;
  screenBits[4] := 0FFX; screenBits[5] := 55X; screenBits[6] := 0FFX; screenBits[7] := 0AAX;
  NEW(screenBitmap); FlImages.OpenBitmap(screenBitmap, screenBits, 8, 8);
  NEW(screenTile); FlImages.OpenTiled(screenTile, screenBitmap, 0, 0);
  NEW(prefs); FlPreferences.Open(prefs, FlPreferences.User, "fltk.org", "blocks");
  helpText := "Click on adjacent blocks of the same color. Clear all blocks before they reach the left side.";
  titleText := "Block Attack!"; OutStr.Ln(titleText); OutStr.String("by Michael R Sweet", titleText);

  IF Fl.SetScheme("plastic") THEN END;
  Fl.SetOption(Fl.OptionVisibleFocus, FALSE);
  NEW(bw); Open(bw, Cols * Size, Rows * Size + 20, "Block Attack!");
  bw.End;
  bw.ShowArgs;
  Fl.Run;
  Fl.RemoveTimeout(ticker)
END Blocks.
