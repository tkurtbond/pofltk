MODULE Checkers; (* FLTK's test/checkers.cxx in Oberon-2 *)

(* Bill Spitzak's checkers, on Steve Poulsen's algorithm of 1979: drag a
   black piece to move it, and the computer moves white. A click of the
   right or middle button pops up the menu, whose items have shortcuts too;
   while the computer thinks, a click pops up a shorter one, to stop it.

   The C++ program has a VT100 interface too, compiled out; this port has
   the FLTK one alone. Its random numbers are seeded from C's time(), as
   the C++ program's are, so both play the same game from the same second.
   Its faults are kept, so that it plays as the C++ program does: a king
   that reaches the top row is marked as kinged by the move, and undoing
   the move takes its crown. A square outside the names gives "?", as the
   C++ program's checked usermoves() does. *)

IMPORT SYSTEM, Fl, FlDraw, FlImages, FlMenus, FlDialogs, FlValuators, Out, OutStr, CheckersPieces;

CONST
  (* the scoring parameters, all divided by 5 from the original code; the
     C++ program marks some signs as seeming backwards (-) *)
  Spiece = 800;       (* value of a piece *)
  Sking = 1200;       (* value of a king *)
  Sadvan = 160;       (* value of mypieces/theirpieces-1 *)
  Sallpin = 80;       (* mobil = 0 *)
  Sdeny = 10;         (* moves the enemy can make that will be jumped *)
  Spin = 32;          (* enemy pieces that have no move except jumped *)
  Sthreat = -10;      (* enemy pieces we can jump if not moved (-) *)
  Sgrad = 1;          (* score of piece positions *)
  Sback = 10;         (* back row occupied so the enemy can't make a king *)
  Smoc2 = 200;        (* more mobility, more center *)
  Smoc3 = -8;         (* less mobility, less center *)
  Smoc4 = -80;        (* more mobility, less center *)
  Smode2 = -14;       (* less mobility, less denied *)
  Smode3 = -40;       (* more mobility, more denied (-) *)
  Sdemmo = -20;       (* more denied, more moves (-) *)
  Scent = 10;         (* pieces in the center *)
  Skcent = 100;       (* kings in the center *)
  DepthPenalty = 4;
  Noise = 2;          (* values this close or closer are equal *)

  (* pieces, so that Black and White are bits *)
  Empty = 0; Black = 1; White = 2; King = 4; BlackKing = 5; WhiteKing = 6; Blue = 8;
  Friend = Black; FriendKing = BlackKing; Enemy = White; EnemyKing = WhiteKing;

  BoxSize = 52; Border = 4; BoardSize = 8 * BoxSize + Border; BmOffset = 3;
  ISize = 62;
  Steps = 35;

  UserMoves = "B1D1F1H1A2C2E2G2??B3D3F3H3A4C4E4G4??B5D5F5H5A6C6E6G6??B7D7F7H7A8C8E8G8??";

TYPE
  (* Board positions:        Border positions:
              WHITE               00  01  02  03  04
          05  06  07  08        04  XX  XX  XX  XX
        09  10  11  12            XX  XX  XX  XX  13
          14  15  16  17        13  XX  XX  XX  XX
        18  19  20  21            XX  XX  XX  XX  22
          23  24  25  26        22  XX  XX  XX  XX
        27  28  29  30            XX  XX  XX  XX  31
          32  33  34  35        31  XX  XX  XX  XX
        36  37  38  39            XX  XX  XX  XX  40
              BLACK             40  41  42  43  44 *)
  Position = ARRAY 45 OF INTEGER;
  PositionPtr = POINTER TO Position;

  Node = POINTER TO NodeDesc;
  NodeDesc = RECORD
    father, son, brother: Node;   (* son: the best son; brother: the next *)
    value: INTEGER;               (* a C short: of this position to the player moving *)
    from, to: INTEGER;            (* the move to reach this position *)
    jump: SET;                    (* the squares jumped, bit i square 10 + i *)
    mobil, deny, pin, threat: INTEGER;
    gradient: INTEGER;            (* a C short *)
    who: INTEGER;                 (* 0 black's move, 1 white's *)
    king: INTEGER;                (* 1: the move kings the piece *)
    back, moc2, moc3, moc4, mode2, mode3, demmo: INTEGER
  END;

  Board = POINTER TO RECORD (Fl.DoubleWindowDesc) END;

VAR
  maxevaluate, maxnodes, maxply: INTEGER;
  forcejumps: BOOLEAN;
  nodes: INTEGER;
  flip: ARRAY 9 OF INTEGER;
  offset: ARRAY 9, 4 OF INTEGER;
  b, flipboard, tb: PositionPtr;  (* tb is b, or flipboard if the enemy is black *)
  evaluated: INTEGER;
  centralsquares, isProtected: ARRAY 45 OF INTEGER;
  deniedmoves, undeniedmoves: INTEGER;
  freelist: Node;
  seed: INTEGER;
  jumphappened: BOOLEAN;
  depth: INTEGER;
  debug: BOOLEAN;
  root, undoroot: Node;
  jumpboards: ARRAY 24 OF Position;
  nextjump: INTEGER;
  user: INTEGER;
  playing, autoplay: BOOLEAN;
  abortflag: BOOLEAN;

  png: ARRAY 4 OF FlImages.Image;
  eraseThis, dragging, dragx, dragy: INTEGER;
  showlegal: INTEGER;
  busy: BOOLEAN;
  deltax, deltay: INTEGER;
  board: Board;
  menu, busymenu: FlMenus.MenuButton;
  copyrightWindow, intelWindow: Fl.Window;
  intelOutput: FlValuators.ValueOutput;
  copyright: ARRAY 1024 OF CHAR;

(* time()'s low 32 bits: NetBSD's header renames time to __time50, and
   the bare symbol is its old time() of a 32-bit time_t, which leaves the
   high half of a LONGINT unset on i386. *)
PROCEDURE ["C", "time"] CTime(t: SYSTEM.ADDRESS): SYSTEM.INT32;

(* x as a C short *)
PROCEDURE Short(x: INTEGER): INTEGER;
BEGIN RETURN (x + 32768) MOD 65536 - 32768
END Short;

(* C's /, which truncates *)
PROCEDURE Div(x, y: INTEGER): INTEGER;
BEGIN
  IF (x < 0) # (y < 0) THEN RETURN -((-x) DIV y) ELSE RETURN x DIV y END
END Div;

(* C's int() of a double *)
PROCEDURE Trunc(r: LONGREAL): INTEGER;
BEGIN
  IF r < 0.0 THEN RETURN -SHORT(ENTIER(-r)) ELSE RETURN SHORT(ENTIER(r)) END
END Trunc;

PROCEDURE Bit(b: BOOLEAN): INTEGER;
BEGIN IF b THEN RETURN 1 ELSE RETURN 0 END
END Bit;

(* whether piece p has bit, one of Black, White and King *)
PROCEDURE Has(p, bit: INTEGER): BOOLEAN;
BEGIN RETURN ODD(p DIV bit)
END Has;

(* The algorithm *)

(* Whether the enemy at target can be jumped from direction by our
   piece. *)
PROCEDURE Check(target, direction: INTEGER): BOOLEAN;
  VAR dst, src, aa, bb: INTEGER; safe: BOOLEAN;
BEGIN
  dst := target - direction;
  IF tb[dst] # Empty THEN RETURN FALSE END;
  src := target + direction;
  IF tb[src] = FriendKing THEN
  ELSIF (direction < 0) OR (tb[src] # Friend) THEN RETURN FALSE
  END;
  aa := tb[target]; bb := tb[src];
  tb[target] := Empty; tb[src] := Empty;
  safe :=
       Has(tb[src - 4], Friend) & Has(tb[src - 8], Enemy)
    OR Has(tb[src - 5], Friend) & Has(tb[src - 10], Enemy)
    OR Has(tb[dst - 4], Enemy) & (tb[dst + 4] = Empty)
    OR Has(tb[dst - 5], Enemy) & (tb[dst + 5] = Empty)
    OR Has(tb[src + 4], Friend) & (tb[src + 8] = EnemyKing)
    OR Has(tb[src + 5], Friend) & (tb[src + 10] = EnemyKing)
    OR (tb[dst + 4] = EnemyKing) & (tb[dst - 4] = Empty)
    OR (tb[dst + 5] = EnemyKing) & (tb[dst - 5] = Empty);
  tb[target] := aa; tb[src] := bb;
  RETURN safe
END Check;

PROCEDURE AnalyzeMove(direction, src: INTEGER);
  VAR target, a: INTEGER;
BEGIN
  target := src + direction;
  IF tb[target] = Empty THEN
    IF tb[target + direction] = Empty THEN isProtected[target] := 1 END;
    a := tb[src]; tb[src] := Empty;
    IF Check(target, 4) OR Check(target, 5) OR
       Check(target, -4) OR Check(target, -5) OR
       Has(tb[src + 4], Enemy) & Check(src + 4, 4) OR
       Has(tb[src + 5], Enemy) & Check(src + 5, 5) OR
       Has(tb[src - 4], Enemy) & Check(src - 4, -4) OR
       Has(tb[src - 5], Enemy) & Check(src - 5, -5) THEN
      INC(deniedmoves)
    ELSE INC(undeniedmoves)
    END;
    tb[src] := a
  END
END AnalyzeMove;

PROCEDURE Row(name: ARRAY OF CHAR; a, b, c: INTEGER; three: BOOLEAN);
BEGIN
  Out.String(name); Out.Char(9X); Out.Int(a, 0); Out.Char(9X); Out.Int(b, 0);
  IF three THEN Out.Char(9X); Out.Int(c, 0) END
END Row;

PROCEDURE EvaluateBoard(n: Node; print: BOOLEAN);
  VAR
    i, p, x, total: INTEGER;
    friendpieces, enemypieces, friendkings, enemykings: INTEGER;
    friendkcent, friendcent, enemykcent, enemycent: INTEGER;
    gradient: ARRAY 40 OF INTEGER;
    f: Node;
BEGIN
  IF n.who = 0 THEN tb := b (* the move was black's *)
  ELSE
    FOR i := 0 TO 44 DO flipboard[44 - i] := flip[b[i]] END;
    tb := flipboard
  END;
  FOR i := 0 TO 44 DO isProtected[i] := 0 END;
  friendpieces := 0; enemypieces := 0; friendkings := 0; enemykings := 0;
  friendkcent := 0; friendcent := 0; enemykcent := 0; enemycent := 0;
  n.mobil := 0; n.deny := 0; n.pin := 0; n.threat := 0;
  FOR i := 5 TO 39 DO
    p := tb[i];
    IF (p = EnemyKing) OR (p = Enemy) THEN
      IF p = EnemyKing THEN
        INC(enemykings);
        INC(enemykcent, centralsquares[i]);
        deniedmoves := 0;
        undeniedmoves := 0;
        IF i > 8 THEN AnalyzeMove(-4, i); AnalyzeMove(-5, i) END
      ELSE
        deniedmoves := 0;
        undeniedmoves := 0
      END;
      INC(enemypieces);
      INC(enemycent, centralsquares[i]);
      IF i < 36 THEN AnalyzeMove(4, i); AnalyzeMove(5, i) END;
      IF (deniedmoves # 0) & (undeniedmoves = 0) THEN INC(n.pin) END;
      INC(n.deny, deniedmoves);
      INC(n.mobil, undeniedmoves)
    ELSIF (p = FriendKing) OR (p = Friend) THEN
      IF p = FriendKing THEN
        INC(friendkings);
        INC(friendkcent, centralsquares[i]);
        IF Has(tb[i + 4], Enemy) & (tb[i + 8] = Empty) & ~((tb[i + 4] = EnemyKing) & (tb[i - 4] = Empty)) THEN
          INC(n.threat)
        END;
        IF Has(tb[i + 5], Enemy) & (tb[i + 10] = Empty) & ~((tb[i + 5] = EnemyKing) & (tb[i - 5] = Empty)) THEN
          INC(n.threat)
        END
      END;
      INC(friendpieces);
      INC(friendcent, centralsquares[i]);
      IF Has(tb[i - 4], Enemy) & (tb[i - 8] = Empty) & (tb[i + 4] # Empty) THEN INC(n.threat) END;
      IF Has(tb[i - 5], Enemy) & (tb[i - 10] = Empty) & (tb[i + 5] # Empty) THEN INC(n.threat) END
    END
  END;
  FOR i := 4 TO 8 DO
    IF tb[i] # Empty THEN gradient[i] := 0 ELSE gradient[i] := 32 END
  END;
  total := 0;
  FOR i := 9 TO 39 DO
    x := (gradient[i - 4] + gradient[i - 5]) DIV 2;
    IF tb[i] = Friend THEN INC(total, x) END;
    IF Has(tb[i], Friend) OR (tb[i] = Empty) & (isProtected[i] = 0) THEN gradient[i] := x
    ELSE gradient[i] := 0
    END
  END;
  n.gradient := Short(total);
  n.back := Bit((tb[39] = Friend) & (tb[37] = Friend) & (enemykings = 0));
  f := n.father;
  n.moc2 := Bit((f.mobil > n.mobil) & (friendcent > enemycent));
  n.moc3 := Bit((f.mobil <= n.mobil) & (friendcent < enemycent));
  n.moc4 := Bit((f.mobil > n.mobil) & (friendcent < enemycent));
  n.mode2 := Bit((f.mobil <= n.mobil) & (n.deny < f.deny));
  n.mode3 := Bit((f.mobil > n.mobil) & (n.deny > f.deny));
  n.demmo := Bit((n.deny > f.deny) & (f.deny + f.mobil > n.deny + n.mobil));
  total :=
    Spiece * (friendpieces - enemypieces) +
    (Sking - Spiece) * (friendkings - enemykings) +
    Sdeny * (n.deny - f.deny) +
    Spin * (n.pin - f.pin) +
    Sthreat * (n.threat - f.threat) +
    Sgrad * (n.gradient - f.gradient) +
    Sback * (n.back - f.back) +
    Smoc2 * (n.moc2 - f.moc2) +
    Smoc3 * (n.moc3 - f.moc3) +
    Smoc4 * (n.moc4 - f.moc4) +
    Smode2 * (n.mode2 - f.mode2) +
    Smode3 * (n.mode3 - f.mode3) +
    Sdemmo * (n.demmo - f.demmo) +
    Scent * (friendcent - enemycent) +
    (Skcent - Scent) * (friendkcent - enemykcent);
  IF n.mobil = 0 THEN INC(total, Sallpin) END;
  IF enemypieces = 0 THEN total := 30000
  ELSIF friendpieces > enemypieces THEN
    INC(total, (Sadvan * friendpieces) DIV enemypieces - Sadvan)
  ELSE DEC(total, (Sadvan * enemypieces) DIV friendpieces - Sadvan)
  END;
  IF print THEN
    Out.String("	Parent	New	Score"); Out.Ln;
    Row("pieces", enemypieces, friendpieces, Spiece * (friendpieces - enemypieces), TRUE); Out.Ln;
    Row("kings", enemykings, friendkings, (Sking - Spiece) * (friendkings - enemykings), TRUE); Out.Ln;
    Row("mobil", f.mobil, n.mobil, 0, FALSE); Out.Ln;
    Row("deny", f.deny, n.deny, Sdeny * (n.deny - f.deny), TRUE); Out.Ln;
    Row("pin", f.pin, n.pin, Spin * (n.pin - f.pin), TRUE); Out.Ln;
    Row("threat", f.threat, n.threat, Sthreat * (n.threat - f.threat), TRUE); Out.Ln;
    Row("grad", f.gradient, n.gradient, Sgrad * (n.gradient - f.gradient), TRUE); Out.Ln;
    Row("back", f.back, n.back, Sback * (n.back - f.back), TRUE); Out.Ln;
    Row("moc2", f.moc2, n.moc2, Smoc2 * (n.moc2 - f.moc2), TRUE); Out.Ln;
    Row("moc3", f.moc3, n.moc3, Smoc3 * (n.moc3 - f.moc3), TRUE); Out.Ln;
    Row("moc4", f.moc4, n.moc4, Smoc4 * (n.moc4 - f.moc4), TRUE); Out.Ln;
    Row("mode2", f.mode2, n.mode2, Smode2 * (n.mode2 - f.mode2), TRUE); Out.Ln;
    Row("mode3", f.mode3, n.mode3, Smode3 * (n.mode3 - f.mode3), TRUE); Out.Ln;
    Row("demmo", f.demmo, n.demmo, Sdemmo * (n.demmo - f.demmo), TRUE); Out.Ln;
    (* the C++ program's format has "n" for its "\n" here *)
    Row("cent", enemycent, friendcent, Scent * (friendcent - enemycent), TRUE); Out.Char("n");
    Row("kcent", enemykcent, friendkcent, Skcent * (friendkcent - enemykcent), TRUE); Out.Ln;
    Out.String("total:			"); Out.Int(total, 0); Out.Ln
  ELSE
    n.value := Short(total);
    INC(evaluated)
  END
END EvaluateBoard;

(* Tree management *)

PROCEDURE NewNode(): Node;
  VAR n: Node;
BEGIN
  IF freelist # NIL THEN
    n := freelist;
    freelist := n.brother
  ELSE NEW(n)
  END;
  n.father := NIL; n.son := NIL; n.brother := NIL;
  n.value := 0; n.from := 0; n.to := 0; n.jump := {};
  n.mobil := 0; n.deny := 0; n.pin := 0; n.threat := 0; n.gradient := 0;
  n.who := 0; n.king := 0; n.back := 0; n.moc2 := 0; n.moc3 := 0; n.moc4 := 0;
  n.mode2 := 0; n.mode3 := 0; n.demmo := 0;
  INC(nodes);
  RETURN n
END NewNode;

PROCEDURE Extract(n: Node);
  VAR i, j: Node;
BEGIN
  i := n.father;
  IF i # NIL THEN
    j := i.son;
    IF j = n THEN i.son := n.brother
    ELSE
      WHILE j # NIL DO
        i := j; j := j.brother;
        IF j = n THEN i.brother := n.brother; j := NIL END
      END
    END
  END;
  n.brother := NIL
END Extract;

PROCEDURE KillNode(x: Node);
  VAR y: Node;
BEGIN
  IF x # NIL THEN
    y := x;
    LOOP
      DEC(nodes);
      KillNode(y.son); y.son := NIL;
      IF y.brother = NIL THEN EXIT END;
      y := y.brother
    END;
    y.brother := freelist;
    freelist := x
  END
END KillNode;

(* seed := (seed * 13077 + 5051) % 0100000, in C's int *)
PROCEDURE NextSeed;
  VAR x: LONGINT;
BEGIN
  x := LONG(seed) * 13077 + 5051;
  x := x MOD 100000000H;
  IF x >= 80000000H THEN x := x - 100000000H END;
  IF x < 0 THEN seed := -SHORT((-x) MOD 32768) ELSE seed := SHORT(x MOD 32768) END
END NextSeed;

PROCEDURE Insert(n: Node);
  VAR val, val1: INTEGER; prev, p: Node; done: BOOLEAN;
BEGIN
  val := n.value;
  prev := NIL; p := n.father.son; done := FALSE;
  WHILE ~done & (p # NIL) DO
    val1 := p.value;
    IF ABS(val - val1) <= Noise THEN
      NextSeed;
      done := (4 IN SYSTEM.VAL(SET, seed)) & (5 IN SYSTEM.VAL(SET, seed))
    ELSE done := val > val1
    END;
    IF ~done THEN prev := p; p := p.brother END
  END;
  n.brother := p;
  IF prev = NIL THEN n.father.son := n ELSE prev.brother := n END
END Insert;

(* Moves the piece on i to j, kinging it as the C++ program does: by its
   precedence, a piece moving to the top row is kinged unless it is a
   white piece that isn't a king. *)
PROCEDURE Place(n: Node; i, j: INTEGER; oldpiece: INTEGER);
  VAR kinged: BOOLEAN;
BEGIN
  IF ~Has(oldpiece, King) & (n.who # 0) THEN kinged := j >= 36 ELSE kinged := j <= 8 END;
  IF kinged THEN
    n.king := 1;
    IF Has(oldpiece, King) THEN b[j] := oldpiece ELSE b[j] := oldpiece + King END
  ELSE b[j] := oldpiece
  END
END Place;

PROCEDURE MovePiece(f: Node; i: INTEGER; jnode: Node);
  VAR k, direction, j, jumploc, oldpiece, jumpedpiece: INTEGER; n: Node;
BEGIN
  k := 0;
  WHILE (k < 4) & (offset[b[i], k] # 0) DO
    direction := offset[b[i], k];
    j := i + direction;
    IF b[j] = Empty THEN
      IF (jnode = NIL) & (~forcejumps OR (f.son = NIL) OR (f.son.jump = {})) THEN
        n := NewNode();
        n.father := f;
        n.who := 1 - f.who;
        n.from := i;
        n.to := j;
        oldpiece := b[i]; b[i] := Empty;
        Place(n, i, j, oldpiece);
        EvaluateBoard(n, FALSE);
        Insert(n);
        b[i] := oldpiece; b[j] := Empty
      END
    ELSIF (Has(b[j], White) # Has(b[i], White)) & (Has(b[j], Black) # Has(b[i], Black)) & (b[j + direction] = Empty) THEN
      IF forcejumps & (f.son # NIL) & (f.son.jump = {}) THEN
        KillNode(f.son);
        f.son := NIL
      END;
      jumploc := j;
      INC(j, direction);
      n := NewNode();
      n.father := f;
      n.who := 1 - f.who;
      n.from := i;
      n.to := j;
      n.jump := {jumploc - 10};
      oldpiece := b[i]; b[i] := Empty;
      Place(n, i, j, oldpiece);
      IF jnode # NIL THEN
        n.from := jnode.from;
        n.jump := n.jump + jnode.jump;
        IF jnode.king # 0 THEN n.king := 1 END
      END;
      jumpedpiece := b[jumploc];
      b[jumploc] := Empty;
      jumphappened := FALSE;
      MovePiece(f, j, n);
      IF forcejumps & jumphappened THEN KillNode(n)
      ELSE EvaluateBoard(n, FALSE); Insert(n)
      END;
      b[i] := oldpiece; b[j] := Empty;
      b[jumploc] := jumpedpiece;
      jumphappened := TRUE
    END;
    INC(k)
  END
END MovePiece;

PROCEDURE ExpandNode(f: Node);
  VAR turn, i: INTEGER;
BEGIN
  IF (f.son = NIL) & (f.value <= 28000) THEN
    IF f.who # 0 THEN turn := Black ELSE turn := White END;
    FOR i := 5 TO 39 DO
      IF Has(b[i], turn) THEN MovePiece(f, i, NIL) END
    END;
    IF f.son # NIL THEN
      f.value := Short(-f.son.value);
      IF f.brother # NIL THEN f.value := Short(f.value - DepthPenalty) END
    ELSE f.value := 30000
    END
  END
END ExpandNode;

PROCEDURE MakeMove(n: Node);
  VAR i: INTEGER;
BEGIN
  b[n.to] := b[n.from];
  IF (n.king # 0) & ~Has(b[n.to], King) THEN INC(b[n.to], King) END;
  b[n.from] := Empty;
  IF n.jump # {} THEN
    FOR i := 0 TO 31 DO
      IF i IN n.jump THEN b[10 + i] := Empty END
    END
  END
END MakeMove;

PROCEDURE DidAbort(): BOOLEAN;
BEGIN
  IF Fl.Check() THEN END;
  IF abortflag THEN
    autoplay := FALSE;
    abortflag := FALSE;
    RETURN TRUE
  END;
  RETURN FALSE
END DidAbort;

PROCEDURE FullExpand(f: Node; level: INTEGER): BOOLEAN;
  VAR oldboard: Position; n: Node; i: INTEGER; ret: BOOLEAN;
    sons: ARRAY 64 OF Node;
BEGIN
  IF DidAbort() OR (nodes > maxnodes - maxply * 10) OR (evaluated > maxevaluate) THEN RETURN FALSE END;
  ExpandNode(f);
  IF f.son = NIL THEN RETURN TRUE END;
  oldboard := b^;
  n := f.son;
  IF (n.jump = {}) & (n.brother # NIL) THEN
    IF level < 1 THEN RETURN TRUE END;
    DEC(level)
  END;
  i := 0;
  WHILE n # NIL DO sons[i] := n; INC(i); n := n.brother END;
  sons[i] := NIL;
  ret := TRUE; i := 0;
  WHILE ret & (sons[i] # NIL) DO
    n := sons[i]; INC(i);
    MakeMove(n);
    ret := FullExpand(n, level);
    b^ := oldboard;
    Extract(n);
    Insert(n)
  END;
  f.value := Short(-f.son.value);
  RETURN ret
END FullExpand;

PROCEDURE Descend(f: Node): BOOLEAN;
  VAR n: Node; ret: BOOLEAN;
BEGIN
  IF DidAbort() OR (nodes > maxnodes) OR (depth >= maxply) THEN RETURN FALSE END;
  IF f.son # NIL THEN
    n := f.son;
    MakeMove(n);
    INC(depth);
    ret := Descend(n);
    DEC(depth);
    Extract(n);
    Insert(n);
    f.value := Short(-f.son.value);
    RETURN ret
  ELSE ExpandNode(f); RETURN TRUE
  END
END Descend;

(* The best move after root, or NIL if there is none, a loss. *)
PROCEDURE CalcMove(root: Node): Node;
  VAR x: INTEGER; saveboard: Position; more: BOOLEAN;
BEGIN
  ExpandNode(root);
  IF root.son = NIL THEN RETURN NIL END;
  IF debug THEN Out.String("calcmove() initial nodes = "); Out.Int(nodes, 0); Out.Ln END;
  evaluated := 0;
  IF root.son.brother # NIL THEN
    x := 1;
    WHILE (ABS(root.value) < 28000) & FullExpand(root, x) DO INC(x) END;
    saveboard := b^;
    more := TRUE;
    WHILE more & (ABS(root.value) < 28000) DO
      more := Descend(root);
      b^ := saveboard
    END
  END;
  IF debug THEN
    Out.String(" evaluated "); Out.Int(evaluated, 0);
    Out.String(", nodes = "); Out.Int(nodes, 0); Out.Ln
  END;
  RETURN root.son
END CalcMove;

(* The game *)

PROCEDURE NewGame;
  VAR n: INTEGER;
BEGIN
  FOR n := 0 TO 4 DO b[n] := Blue END;
  FOR n := 5 TO 17 DO b[n] := White END;
  FOR n := 18 TO 26 DO b[n] := Empty END;
  FOR n := 27 TO 39 DO b[n] := Black END;
  FOR n := 40 TO 44 DO b[n] := Blue END;
  b[13] := Blue; b[22] := Blue; b[31] := Blue;
  centralsquares[15] := 1; centralsquares[16] := 1;
  centralsquares[19] := 1; centralsquares[20] := 1;
  centralsquares[24] := 1; centralsquares[25] := 1;
  centralsquares[28] := 1; centralsquares[29] := 1;
  (* the search tree, with white to move, so that black moves first *)
  nextjump := 0;
  KillNode(undoroot);
  root := NewNode(); undoroot := root;
  root.who := 1;
  user := 0;
  playing := TRUE
END NewGame;

PROCEDURE DoMove(move: Node);
BEGIN
  IF move.jump # {} THEN jumpboards[nextjump] := b^; INC(nextjump) END;
  MakeMove(move);
  Extract(move);
  KillNode(root.son);
  root.son := move;
  root := move;
  IF debug THEN EvaluateBoard(move, TRUE) END
END DoMove;

PROCEDURE UndoMove(): Node;
  VAR n: Node;
BEGIN
  n := root;
  IF n = undoroot THEN RETURN NIL END;
  IF n.jump # {} THEN DEC(nextjump); b^ := jumpboards[nextjump]
  ELSE
    b[n.from] := b[n.to];
    IF n.king # 0 THEN b[n.from] := b[n.from] MOD King END;
    b[n.to] := Empty
  END;
  root := n.father;
  KillNode(n);
  root.son := NIL;
  root.value := 0; (* so that it doesn't think the game is over *)
  playing := TRUE;
  IF root = undoroot THEN user := 0 END;
  RETURN n
END UndoMove;

(* Square x's letter (y 1) or digit (y 2), or "?" outside the names. *)
PROCEDURE UserMove(x, y: INTEGER): INTEGER;
  VAR idx: INTEGER; s: ARRAY 74 OF CHAR;
BEGIN
  s := UserMoves;
  idx := 2 * (x - 5) + y - 1;
  IF (idx < 0) OR (idx > 72) THEN RETURN ORD("?") END;
  RETURN ORD(s[idx])
END UserMove;

(* The FLTK interface *)

PROCEDURE MakePieces;
  VAR i, len: INTEGER; buf: ARRAY CheckersPieces.Max OF CHAR;
BEGIN
  IF png[0] = NIL THEN
    FOR i := 0 TO 3 DO
      CheckersPieces.Get(i, buf, len);
      NEW(png[i]);
      IF FlImages.LoadData(png[i], buf, len) THEN END
    END;
    FOR i := 0 TO 3 DO png[i].Scale(png[i].DataW() DIV 2, png[i].DataH() DIV 2, TRUE, FALSE) END
  END
END MakePieces;

PROCEDURE DrawPiece(which, x, y: INTEGER);
BEGIN
  IF FlDraw.NotClipped(x, y, ISize, ISize) THEN
    CASE which OF
      Black: png[0].Draw(x, y)
    | White: png[1].Draw(x, y)
    | BlackKing: png[2].Draw(x, y)
    | WhiteKing: png[3].Draw(x, y)
    ELSE
    END
  END
END DrawPiece;

PROCEDURE SquareX(i: INTEGER): INTEGER;
BEGIN RETURN (UserMove(i, 1) - ORD("A")) * BoxSize + BmOffset
END SquareX;

PROCEDURE SquareY(i: INTEGER): INTEGER;
BEGIN RETURN (UserMove(i, 2) - ORD("1")) * BoxSize + BmOffset
END SquareY;

PROCEDURE (w: Board) Draw*;
  VAR x, y, j, x1, y1, x2, y2, num: INTEGER; n: Node; buf: ARRAY 20 OF CHAR;
BEGIN
  MakePieces;
  (* the board itself *)
  FlDraw.DrawBox(w.BoxType(), 0, 0, w.W(), w.H(), w.Color());
  (* the dark squares *)
  FlDraw.SetColor(10);
  FOR x := 0 TO 7 DO
    FOR y := 0 TO 7 DO
      IF ~ODD(x + y) THEN
        FlDraw.RectF(Border + x * BoxSize, Border + y * BoxSize, BoxSize - Border, BoxSize - Border)
      END
    END
  END;
  (* the lines around the squares *)
  FlDraw.SetColor(Fl.Dark3);
  FOR x := 0 TO 8 DO
    FlDraw.RectF(x * BoxSize, 0, Border, w.H());
    FlDraw.RectF(0, x * BoxSize, w.W(), Border)
  END;
  FOR j := 5 TO 39 DO
    IF j # eraseThis THEN DrawPiece(b[j], SquareX(j), SquareY(j)) END
  END;
  IF showlegal # 0 THEN
    FlDraw.SetColor(Fl.White);
    n := root.son;
    WHILE n # NIL DO
      x1 := SquareX(n.from) + BoxSize DIV 2 - 5;
      y1 := SquareY(n.from) + BoxSize DIV 2 - 5;
      x2 := SquareX(n.to) + BoxSize DIV 2 - 5;
      y2 := SquareY(n.to) + BoxSize DIV 2 - 5;
      FlDraw.Line(x1, y1, x2, y2);
      FlDraw.PushMatrix;
      FlDraw.MultMatrix(x2 - x1, y2 - y1, y1 - y2, x2 - x1, x2, y2);
      FlDraw.BeginPolygon;
      FlDraw.Vertex(0.0D0, 0.0D0);
      FlDraw.Vertex(-0.3D0, 0.1D0);
      FlDraw.Vertex(-0.3D0, -0.1D0);
      FlDraw.EndPolygon;
      FlDraw.PopMatrix;
      IF showlegal = 2 THEN n := n.son ELSE n := n.brother END
    END;
    num := 1;
    FlDraw.SetColor(Fl.Black);
    FlDraw.SetFont(Fl.Bold, 10);
    n := root.son;
    WHILE n # NIL DO
      x1 := SquareX(n.from) + BoxSize DIV 2 - 5;
      y1 := SquareY(n.from) + BoxSize DIV 2 - 5;
      x2 := SquareX(n.to) + BoxSize DIV 2 - 5;
      y2 := SquareY(n.to) + BoxSize DIV 2 - 5;
      buf := ""; OutStr.Int(num, 0, buf);
      FlDraw.Text(buf, x1 + Trunc((x2 - x1) * 0.85D0) - 3, y1 + Trunc((y2 - y1) * 0.85D0) + 5);
      INC(num);
      IF showlegal = 2 THEN n := n.son ELSE n := n.brother END
    END
  END;
  IF dragging # 0 THEN DrawPiece(dragging, dragx, dragy) END
END Draw;

PROCEDURE (w: Board) DropPiece(j: INTEGER);
  VAR x, y: INTEGER;
BEGIN
  IF eraseThis # 0 THEN
    eraseThis := 0;
    dragging := 0;
    x := SquareX(j);
    y := SquareY(j);
    IF (x # dragx) OR (y # dragy) THEN
      w.DamageArea(Fl.DamageScroll, dragx, dragy, ISize, ISize);
      w.DamageArea(Fl.DamageScroll, x, y, ISize, ISize)
    END
  END
END DropPiece;

(* Drags the piece on square j to dx, dy. *)
PROCEDURE (w: Board) DragPiece(j, dx, dy: INTEGER);
BEGIN
  dy := dy - dy MOD 2 + dx MOD 2; (* so that the halftone shadows line up *)
  IF j # eraseThis THEN w.DropPiece(eraseThis) END; (* should not happen *)
  IF eraseThis = 0 THEN (* pick up the piece *)
    dragx := SquareX(j); dragy := SquareY(j);
    eraseThis := j;
    dragging := b[j]
  END;
  IF (dx # dragx) OR (dy # dragy) THEN
    w.DamageArea(Fl.DamageAll, dragx, dragy, ISize, ISize);
    w.DamageArea(Fl.DamageAll, dx, dy, ISize, ISize)
  END;
  dragx := dx;
  dragy := dy
END DragPiece;

(* Shows move: called before the move, or after its undo. *)
PROCEDURE (w: Board) Animate(move: Node; backwards: BOOLEAN);
  VAR f, t, x, y, x1, y1, x2, y2, j: INTEGER;
BEGIN
  IF showlegal # 0 THEN showlegal := 0; w.Redraw END;
  IF move # NIL THEN
    f := move.from;
    t := move.to;
    IF backwards THEN x := f; f := t; t := x END;
    x1 := SquareX(f);
    y1 := SquareY(f);
    x2 := SquareX(t);
    y2 := SquareY(t);
    FOR j := 0 TO Steps - 1 DO
      x := x1 + Div((x2 - x1) * j, Steps);
      y := y1 + Div((y2 - y1) * j, Steps);
      w.DragPiece(move.from, x, y);
      Fl.Flush;
      Fl.Wait(0.01D0)
    END;
    w.DropPiece(t);
    IF move.jump # {} THEN w.Redraw END
  END
END Animate;

PROCEDURE (w: Board) ComputerMove(help: BOOLEAN);
  VAR move: Node;
BEGIN
  IF playing THEN
    w.SetCursor(Fl.CursorWait);
    Fl.Flush;
    busy := TRUE; abortflag := FALSE;
    move := CalcMove(root);
    busy := FALSE;
    IF move # NIL THEN
      IF ~help & (move.value <= -30000) THEN
        IF move.who # 0 THEN FlDialogs.Message("White resigns")
        ELSE FlDialogs.Message("Black resigns")
        END;
        playing := FALSE; autoplay := FALSE;
        w.SetCursor(Fl.CursorDefault);
        RETURN
      END;
      w.Animate(move, FALSE);
      DoMove(move)
    END;
    ExpandNode(root);
    IF root.son = NIL THEN
      IF root.who # 0 THEN FlDialogs.Message("Black has no move")
      ELSE FlDialogs.Message("White has no move")
      END;
      playing := FALSE; autoplay := FALSE
    END;
    IF ~autoplay THEN w.SetCursor(Fl.CursorDefault) END
  END
END ComputerMove;

PROCEDURE (w: Board) Handle*(e: INTEGER): BOOLEAN;
  VAR t, n: Node; x, y, d, d1, dist: INTEGER;
BEGIN
  IF busy THEN
    IF e = Fl.EvPush THEN
      IF busymenu.PopupAt(Fl.EventX(), Fl.EventY(), "", -1) >= 0 THEN END;
      RETURN TRUE
    ELSIF e = Fl.EvShortcut THEN RETURN busymenu.TestShortcut() >= 0
    ELSE RETURN FALSE
    END
  END;
  IF e = Fl.EvPush THEN
    IF Fl.EventButton() > 1 THEN
      IF menu.PopupAt(Fl.EventX(), Fl.EventY(), "", -1) >= 0 THEN END;
      RETURN TRUE
    END;
    IF playing THEN
      ExpandNode(root);
      t := root.son;
      WHILE t # NIL DO
        x := SquareX(t.from);
        y := SquareY(t.from);
        IF Fl.EventInside(x, y, BoxSize, BoxSize) THEN
          deltax := Fl.EventX() - x;
          deltay := Fl.EventY() - y;
          w.DragPiece(t.from, x, y);
          RETURN TRUE
        END;
        t := t.brother
      END
    END;
    RETURN FALSE
  ELSIF e = Fl.EvShortcut THEN RETURN menu.TestShortcut() >= 0
  ELSIF e = Fl.EvDrag THEN
    w.DragPiece(eraseThis, Fl.EventX() - deltax, Fl.EventY() - deltay);
    RETURN TRUE
  ELSIF e = Fl.EvRelease THEN
    (* the closest legal move it was dropped on *)
    dist := 50 * 50; n := NIL;
    t := root.son;
    WHILE t # NIL DO
      IF t.from = eraseThis THEN
        d1 := Fl.EventX() - deltax - SquareX(t.to);
        d := d1 * d1;
        d1 := Fl.EventY() - deltay - SquareY(t.to);
        INC(d, d1 * d1);
        IF d < dist THEN dist := d; n := t END
      END;
      t := t.brother
    END;
    IF n = NIL THEN w.DropPiece(eraseThis); RETURN TRUE END; (* none found *)
    w.DropPiece(n.to);
    DoMove(n);
    IF showlegal # 0 THEN showlegal := 0; w.Redraw END;
    IF n.jump # {} THEN w.Redraw END;
    w.ComputerMove(FALSE);
    RETURN TRUE
  ELSE RETURN FALSE
  END
END Handle;

(* The menus' items *)

PROCEDURE Quit(w: Fl.Widget);
BEGIN HALT(0)
END Quit;

PROCEDURE AutoplayCB(w: Fl.Widget);
BEGIN
  IF autoplay THEN autoplay := FALSE
  ELSIF playing THEN
    autoplay := TRUE;
    WHILE autoplay DO board.ComputerMove(FALSE); board.ComputerMove(FALSE) END
  END
END AutoplayCB;

PROCEDURE Append(s: ARRAY OF CHAR; nl: BOOLEAN);
BEGIN
  OutStr.String(s, copyright);
  IF nl THEN OutStr.Char(0AX, copyright) END
END Append;

PROCEDURE CopyrightCB(w: Fl.Widget);
  VAR box: Fl.Box;
BEGIN
  IF copyrightWindow = NIL THEN
    NEW(copyrightWindow); Fl.OpenWindow(copyrightWindow, 400, 270, "Copyright");
    copyrightWindow.SetColor(Fl.White);
    NEW(box); Fl.OpenBox(box, 20, 0, 380, 270, copyright);
    box.SetLabelSize(10);
    box.SetAlign(Fl.AlignLeft + Fl.AlignInside + Fl.AlignWrap);
    copyrightWindow.End
  END;
  copyrightWindow.Hotspot(copyrightWindow, FALSE);
  copyrightWindow.SetNonModal;
  copyrightWindow.Show
END CopyrightCB;

(* Sets the flags of the item picked in w, a menu, to Toggle, with Value if
   on, as the C++ program sets them. *)
PROCEDURE SetToggle(w: Fl.Widget; on: BOOLEAN);
  VAR m: FlMenus.Menu;
BEGIN
  m := w(FlMenus.Menu);
  IF on THEN m.SetItemFlags(m.Value(), FlMenus.MenuToggle + FlMenus.MenuValue)
  ELSE m.SetItemFlags(m.Value(), FlMenus.MenuToggle)
  END
END SetToggle;

PROCEDURE DebugCB(w: Fl.Widget);
BEGIN
  debug := ~debug;
  SetToggle(w, debug)
END DebugCB;

PROCEDURE ForcedCB(w: Fl.Widget);
BEGIN
  forcejumps := ~forcejumps;
  SetToggle(w, forcejumps);
  KillNode(root.son); root.son := NIL;
  IF showlegal # 0 THEN ExpandNode(root); board.Redraw END
END ForcedCB;

PROCEDURE MoveCB(w: Fl.Widget);
BEGIN
  IF playing THEN board.ComputerMove(TRUE) END;
  IF playing THEN board.ComputerMove(FALSE) END
END MoveCB;

PROCEDURE NewGameCB(w: Fl.Widget);
BEGIN
  showlegal := 0;
  NewGame;
  board.Redraw
END NewGameCB;

PROCEDURE LegalCB(w: Fl.Widget);
BEGIN
  IF showlegal = 1 THEN showlegal := 0; board.Redraw
  ELSIF playing THEN
    ExpandNode(root);
    showlegal := 1; board.Redraw
  END
END LegalCB;

PROCEDURE PredictCB(w: Fl.Widget);
BEGIN
  IF showlegal = 2 THEN showlegal := 0; board.Redraw
  ELSE
    IF playing THEN ExpandNode(root) END;
    showlegal := 2; board.Redraw
  END
END PredictCB;

PROCEDURE SwitchCB(w: Fl.Widget);
BEGIN
  user := 1 - user;
  board.ComputerMove(FALSE)
END SwitchCB;

PROCEDURE UndoCB(w: Fl.Widget);
BEGIN
  board.Animate(UndoMove(), TRUE);
  board.Animate(UndoMove(), TRUE)
END UndoCB;

PROCEDURE IntelSliderCB(w: Fl.Widget);
  VAR v: LONGREAL; n: INTEGER;
BEGIN
  v := w(FlValuators.Slider).Value();
  n := Trunc(v * v);
  intelOutput.SetValue(n);
  maxevaluate := n; maxnodes := n
END IntelSliderCB;

PROCEDURE IntelCB(w: Fl.Widget);
  VAR s: FlValuators.Slider;
BEGIN
  IF intelWindow = NIL THEN
    NEW(intelWindow); Fl.OpenWindow(intelWindow, 200, 25, "Checkers Intelligence");
    NEW(s); FlValuators.OpenSlider(s, 60, 0, 140, 25, "");
    s.SetKind(FlValuators.HorNiceSlider); (* not a HorNiceSlider's box *)
    s.SetBounds(1.0D0, 500.0D0); s.SetValue(50.0D0);
    s.action := IntelSliderCB;
    NEW(intelOutput); FlValuators.OpenValueOutput(intelOutput, 0, 0, 60, 25, "");
    intelOutput.SetValue(maxevaluate);
    intelWindow.SetResizable(s);
    (* the C++ program leaves the window the current group, which no later
       widget is made in *)
    intelWindow.End
  END;
  intelWindow.Hotspot(intelWindow, FALSE);
  intelWindow.SetNonModal;
  intelWindow.Show
END IntelCB;

PROCEDURE StopCB(w: Fl.Widget);
BEGIN abortflag := TRUE
END StopCB;

PROCEDURE ContinueCB(w: Fl.Widget);
END ContinueCB;

PROCEDURE Item(m: FlMenus.Menu; label: ARRAY OF CHAR; key: CHAR; action: FlMenus.Action; flags: SET);
  VAR k: INTEGER;
BEGIN
  IF key = 0X THEN k := 0 ELSE k := ORD(key) END;
  IF m.Add(label, k, {}, action, flags) >= 0 THEN END
END Item;

PROCEDURE MakeMenus;
BEGIN
  NEW(menu); FlMenus.OpenMenuButton(menu, 0, 0, 0, 0, "");
  Item(menu, "Autoplay", "a", AutoplayCB, {});
  Item(menu, "Legal moves", "l", LegalCB, {});
  Item(menu, "Move for me", "m", MoveCB, {});
  Item(menu, "New game", "n", NewGameCB, {});
  Item(menu, "Predict", "p", PredictCB, {});
  Item(menu, "Switch sides", "s", SwitchCB, {});
  Item(menu, "Undo", "u", UndoCB, FlMenus.MenuDivider);
  Item(menu, "Forced jumps rule", "f", ForcedCB, FlMenus.MenuToggle + FlMenus.MenuValue);
  Item(menu, "Debug", "d", DebugCB, FlMenus.MenuToggle);
  Item(menu, "Intelligence...", "i", IntelCB, FlMenus.MenuDivider);
  Item(menu, "Copyright", "c", CopyrightCB, {});
  Item(menu, "Quit", "q", Quit, {});

  NEW(busymenu); FlMenus.OpenMenuButton(busymenu, 0, 0, 0, 0, "");
  Item(busymenu, "Stop", ".", StopCB, {});
  Item(busymenu, "Autoplay", "a", AutoplayCB, {});
  Item(busymenu, "Continue", 0X, ContinueCB, {});
  Item(busymenu, "Debug", "d", DebugCB, FlMenus.MenuToggle);
  Item(busymenu, "Intelligence...", "i", IntelCB, {});
  Item(busymenu, "Copyright", "c", CopyrightCB, {});
  Item(busymenu, "Quit", "q", Quit, {})
END MakeMenus;

PROCEDURE InitTables;
  VAR i, k: INTEGER;
BEGIN
  flip[0] := Empty; flip[1] := White; flip[2] := Black; flip[3] := 0; flip[4] := 0;
  flip[5] := WhiteKing; flip[6] := BlackKing; flip[7] := 0; flip[8] := Blue;
  FOR i := 0 TO 8 DO FOR k := 0 TO 3 DO offset[i, k] := 0 END END;
  offset[1, 0] := -5; offset[1, 1] := -4;
  offset[2, 0] := 4; offset[2, 1] := 5;
  offset[5, 0] := 4; offset[5, 1] := 5; offset[5, 2] := -4; offset[5, 3] := -5;
  offset[6, 0] := 4; offset[6, 1] := 5; offset[6, 2] := -4; offset[6, 3] := -5;

  copyright := "";
  Append("Checkers game", TRUE);
  Append("Copyright (C) 1997-2010 Bill Spitzak    spitzak@@d2.com", TRUE);
  Append("Original Pascal code:", TRUE);
  Append("Copyright 1978, Oregon Minicomputer Software, Inc.", TRUE);
  Append("2340 SW Canyon Road, Portland, Oregon 97201", TRUE);
  Append("Written by Steve Poulsen 18-Jan-79", TRUE);
  Append("", TRUE);
  Append("This program is free software; you can redistribute it and/or modify ", FALSE);
  Append("it under the terms of the GNU General Public License as published by ", FALSE);
  Append("the Free Software Foundation; either version 2 of the License, or ", FALSE);
  Append("(at your option) any later version.", TRUE);
  Append("", TRUE);
  Append("This program is distributed in the hope that it will be useful, ", FALSE);
  Append("but WITHOUT ANY WARRANTY; without even the implied warranty of ", FALSE);
  Append("MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the ", FALSE);
  Append("GNU General Public License for more details.", TRUE);
  Append("", TRUE);
  Append("You should have received a copy of the GNU Library General Public ", FALSE);
  Append("License along with this library; if not, write to the Free Software ", FALSE);
  Append("Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 ", FALSE);
  Append("USA.", FALSE)
END InitTables;

BEGIN
  maxevaluate := 2500; maxnodes := 2500; maxply := 20;
  forcejumps := TRUE;
  NEW(b); NEW(flipboard); tb := b;
  InitTables;
  seed := CTime(0);
  NewGame;
  IF Fl.Visual(Fl.VisualDouble + Fl.VisualIndex) THEN END;
  NEW(board); Fl.OpenDoubleWindow(board, BoardSize, BoardSize, "FLTK Checkers");
  board.SetColor(15);
  board.End;
  board.SetColor(Fl.BackgroundColor);
  board.action := Quit;
  MakeMenus;
  board.ShowArgs;
  Fl.Run
END Checkers.
