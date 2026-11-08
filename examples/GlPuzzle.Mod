MODULE GlPuzzle; (* FLTK's test/glpuzzle.cxx: a sliding block puzzle in GLUT, which solves itself *)

(* The left button slides a piece, or turns the puzzle if it misses; the
   middle button turns it and lets it go spinning; the right button is a
   GLUT menu. Keys: "n" (or a space) puts it back upright, "r" resets the
   puzzle, "s" solves it, "d" destroys the piece under the mouse, "b"
   toggles the depth buffer, Esc quits. "-n" on the command line turns
   spinning off, "-s" makes the window single buffered.

   trackball.c, which FLTK's program includes, is here too. The arithmetic
   follows the C++, float where that is float and double where that is
   double, so that it draws what FLTK's program draws. *)

IMPORT Args, Fl, FlGl, FlGlu, FlGlut, Math, MathL, Out, Strings;

CONST
  width = 4; height = 5;
  pieces = 10;
  offsetX = -2.0; offsetY = -2.5; offsetZ = -0.5;
  hashSize = 10691;
  moveSpeed = 0.2;
  timerDelay = 13;     (* milliseconds, 72 frames a second *)
  trackballSize = 0.8;
  maxVelocity = 0.1;
  renormCount = 97;

TYPE
  Config = ARRAY height, width OF INTEGER;
  Quat = ARRAY 4 OF REAL;
  Vec = ARRAY 3 OF REAL;

  Puzzle = POINTER TO PuzzleDesc;
  PuzzleDesc = RECORD
    back, soln: Puzzle;   (* the position before, and after on the way to the solution *)
    pieces: Config;
    next: Puzzle;         (* in its hash chain *)
    hash: HUGEINT
  END;

  List = POINTER TO RECORD puzzle: Puzzle; next: List END;

VAR
  convert: ARRAY pieces + 1 OF INTEGER;   (* pieces of one shape are alike *)
  colors: ARRAY pieces + 1, 3 OF INTEGER;
  xSize, ySize: ARRAY pieces + 1 OF INTEGER;
  zSize: ARRAY pieces + 1 OF REAL;
  startConfig, thePuzzle: Config;
  xAdds, yAdds: ARRAY 4 OF INTEGER;

  boxCoords: ARRAY 24 OF Vec;
  boxNormals: ARRAY 26 OF Vec;
  boxFaces: ARRAY 26, 4 OF INTEGER;
  containerCoords: ARRAY 24 OF Vec;
  containerNormals: ARRAY 24 OF Vec;
  containerFaces: ARRAY 24, 4 OF INTEGER;

  hashTable: ARRAY hashSize OF Puzzle;
  startPuzzle: Puzzle;
  puzzles, lastEntry: List;

  visible: BOOLEAN;
  movingPiece: INTEGER;
  moveX, moveY: REAL;
  curQuat, lastQuat: Quat;
  doubleBuffer, depth: BOOLEAN;
  w, h: INTEGER;
  viewport: ARRAY 4 OF INTEGER;

  selected: BOOLEAN;
  selectX, selectY: INTEGER;
  selStartX, selStartY: REAL;

  leftMouse, middleMouse: BOOLEAN;
  mouseX, mouseY: INTEGER;
  solving, spinning, enableSpinning: BOOLEAN;
  selPiece: INTEGER;
  timerActive, timerPending: BOOLEAN;
  quatCount: INTEGER;   (* add_quats' count *)

PROCEDURE ^ ChangeState;
PROCEDURE ^ Animate(value: INTEGER);

(* C's conversion of a float to an integer, toward zero *)
PROCEDURE Trunc(x: REAL): INTEGER;
BEGIN
  IF x < 0 THEN RETURN -SHORT(ENTIER(-x)) ELSE RETURN SHORT(ENTIER(x)) END
END Trunc;

(* trackball.c *)

PROCEDURE VCross(v1-, v2-: ARRAY OF REAL; VAR cross: ARRAY OF REAL);
  VAR t: Vec;
BEGIN
  t[0] := v1[1] * v2[2] - v1[2] * v2[1];
  t[1] := v1[2] * v2[0] - v1[0] * v2[2];
  t[2] := v1[0] * v2[1] - v1[1] * v2[0];
  cross[0] := t[0]; cross[1] := t[1]; cross[2] := t[2]
END VCross;

PROCEDURE VLength(v-: ARRAY OF REAL): REAL;
BEGIN RETURN Math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2])
END VLength;

PROCEDURE VScale(VAR v: ARRAY OF REAL; d: REAL);
BEGIN v[0] := v[0] * d; v[1] := v[1] * d; v[2] := v[2] * d
END VScale;

PROCEDURE VDot(v1-, v2-: ARRAY OF REAL): REAL;
BEGIN RETURN v1[0] * v2[0] + v1[1] * v2[1] + v1[2] * v2[2]
END VDot;

PROCEDURE AxisToQuat(VAR a: Vec; phi: REAL; VAR q: Quat);
BEGIN
  VScale(a, 1.0 / VLength(a));
  q[0] := a[0]; q[1] := a[1]; q[2] := a[2];
  VScale(q, Math.sin(phi / 2.0));
  q[3] := Math.cos(phi / 2.0)
END AxisToQuat;

(* a point on a sphere of radius r, or on a hyperbola away from its centre *)
PROCEDURE ProjectToSphere(r, x, y: REAL): REAL;
  VAR d, t: REAL;
BEGIN
  d := Math.sqrt(x * x + y * y);
  IF d < r * 0.70710678118654752440D0 THEN RETURN Math.sqrt(r * r - d * d)
  ELSE t := SHORT(r / 1.41421356237309504880D0); RETURN t * t / d
  END
END ProjectToSphere;

(* the rotation, in q, of a drag from p1 to p2, each -1 to 1 across the window *)
PROCEDURE Trackball(VAR q: Quat; p1x, p1y, p2x, p2y: REAL);
  VAR a, p1, p2, d: Vec; t: REAL;
BEGIN
  IF (p1x = p2x) & (p1y = p2y) THEN
    q[0] := 0; q[1] := 0; q[2] := 0; q[3] := 1.0
  ELSE
    p1[0] := p1x; p1[1] := p1y; p1[2] := ProjectToSphere(trackballSize, p1x, p1y);
    p2[0] := p2x; p2[1] := p2y; p2[2] := ProjectToSphere(trackballSize, p2x, p2y);
    VCross(p2, p1, a);
    d[0] := p1[0] - p2[0]; d[1] := p1[1] - p2[1]; d[2] := p1[2] - p2[2];
    t := VLength(d) / (2.0 * trackballSize);
    IF t > maxVelocity THEN t := maxVelocity END;
    IF t < -maxVelocity THEN t := -maxVelocity END;
    AxisToQuat(a, SHORT(2.0D0 * MathL.arcsin(t)), q)
  END
END Trackball;

(* trackball.c divides by the square of the magnitude *)
PROCEDURE NormalizeQuat(VAR q: Quat);
  VAR mag: REAL; i: INTEGER;
BEGIN
  mag := q[0] * q[0] + q[1] * q[1] + q[2] * q[2] + q[3] * q[3];
  FOR i := 0 TO 3 DO q[i] := q[i] / mag END
END NormalizeQuat;

PROCEDURE AddQuats(q1-, q2-: Quat; VAR dest: Quat);
  VAR t1, t2, t3, tf: Quat;
BEGIN
  t1 := q1; VScale(t1, q2[3]);
  t2 := q2; VScale(t2, q1[3]);
  VCross(q2, q1, t3);
  tf[0] := t1[0] + t2[0]; tf[1] := t1[1] + t2[1]; tf[2] := t1[2] + t2[2];
  tf[0] := t3[0] + tf[0]; tf[1] := t3[1] + tf[1]; tf[2] := t3[2] + tf[2];
  tf[3] := q1[3] * q2[3] - VDot(q1, q2);
  dest := tf;
  INC(quatCount);
  IF quatCount > renormCount THEN quatCount := 0; NormalizeQuat(dest) END
END AddQuats;

(* m is row by row, as C's float m[4][4] *)
PROCEDURE BuildRotMatrix(VAR m: ARRAY OF REAL; q-: Quat);
BEGIN
  m[0] := 1.0 - 2.0 * (q[1] * q[1] + q[2] * q[2]);
  m[1] := 2.0 * (q[0] * q[1] - q[2] * q[3]);
  m[2] := 2.0 * (q[2] * q[0] + q[1] * q[3]);
  m[3] := 0.0;
  m[4] := 2.0 * (q[0] * q[1] + q[2] * q[3]);
  m[5] := 1.0 - 2.0 * (q[2] * q[2] + q[0] * q[0]);
  m[6] := 2.0 * (q[1] * q[2] - q[0] * q[3]);
  m[7] := 0.0;
  m[8] := 2.0 * (q[2] * q[0] - q[1] * q[3]);
  m[9] := 2.0 * (q[1] * q[2] + q[0] * q[3]);
  m[10] := 1.0 - 2.0 * (q[1] * q[1] + q[0] * q[0]);
  m[11] := 0.0;
  m[12] := 0.0; m[13] := 0.0; m[14] := 0.0; m[15] := 1.0
END BuildRotMatrix;

(* The puzzle *)

(* the C++'s int overflows and is taken as unsigned *)
PROCEDURE Hash(VAR config: Config): HUGEINT;
  VAR value: HUGEINT; i, j: INTEGER;
BEGIN
  value := 0;
  FOR i := 0 TO height - 1 DO
    FOR j := 0 TO width - 1 DO
      value := (value + convert[config[i, j]]) * 6 MOD 100000000H
    END
  END;
  RETURN value
END Hash;

PROCEDURE Solution(VAR config: Config): BOOLEAN;
BEGIN RETURN (config[4, 1] = 10) & (config[4, 2] = 10)
END Solution;

PROCEDURE SetTitle(prefix: ARRAY OF CHAR; n: INTEGER; suffix: ARRAY OF CHAR);
  VAR s: ARRAY 256 OF CHAR; d: ARRAY 12 OF CHAR; i, j: INTEGER;
BEGIN
  i := 0;
  REPEAT d[i] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(i) UNTIL n = 0;
  COPY(prefix, s); j := Strings.Length(s);
  WHILE i > 0 DO DEC(i); s[j] := d[i]; INC(j) END;
  s[j] := 0X;
  Strings.Append(suffix, s);
  FlGlut.SetWindowTitle(s)
END SetTitle;

PROCEDURE DrawBox(piece: INTEGER; xOff, yOff: REAL);
  VAR xLen, yLen, i, k, f, n: INTEGER; x, y, z, zLen: REAL;
BEGIN
  xLen := xSize[piece]; yLen := ySize[piece]; zLen := zSize[piece];
  FlGl.Color3ub(colors[piece, 0], colors[piece, 1], colors[piece, 2]);
  FlGl.Begin(FlGl.Quads);
  n := 4;
  FOR i := 0 TO 25 DO
    IF i = 18 THEN FlGl.End; FlGl.Begin(FlGl.Triangles); n := 3 END;
    FlGl.Normal3f(boxNormals[i, 0], boxNormals[i, 1], boxNormals[i, 2]);
    FOR k := 0 TO n - 1 DO
      f := boxFaces[i, k];
      IF f # -1 THEN
        x := boxCoords[f, 0] + offsetX;
        IF boxCoords[f, 0] > 0.5 THEN x := x + (xLen - 1) END;
        y := boxCoords[f, 1] + offsetY;
        IF boxCoords[f, 1] > 0.5 THEN y := y + (yLen - 1) END;
        z := boxCoords[f, 2] + offsetZ;
        IF boxCoords[f, 2] > 0.5 THEN z := z + (zLen - 1) END;
        FlGl.Vertex3f(xOff + x, yOff + y, z)
      END
    END
  END;
  FlGl.End
END DrawBox;

(* Y is reversed, because the model has it reversed *)
PROCEDURE DrawContainer;
  VAR i, k, f: INTEGER;
BEGIN
  FlGl.Color3ub(209, 103, 23);   (* bright wood *)
  FlGl.Begin(FlGl.Quads);
  FOR i := 0 TO 23 DO
    FlGl.Normal3f(containerNormals[i, 0], -containerNormals[i, 1], containerNormals[i, 2]);
    FOR k := 3 TO 0 BY -1 DO
      f := containerFaces[i, k];
      FlGl.Vertex3f(containerCoords[f, 0] + offsetX, -(containerCoords[f, 1] + offsetY),
        containerCoords[f, 2] + offsetZ)
    END
  END;
  FlGl.End
END DrawContainer;

PROCEDURE DrawAll;
  VAR i, j, piece: INTEGER; done: ARRAY pieces + 1 OF BOOLEAN; m: ARRAY 16 OF REAL;
BEGIN
  BuildRotMatrix(m, curQuat);
  FlGl.MatrixMode(FlGl.Modelview);
  FlGl.LoadIdentity;
  FlGl.Translatef(0, 0, -10);
  FlGl.MultMatrixf(m);
  FlGl.Rotatef(180, 0, 0, 1);
  IF depth THEN FlGl.Clear(FlGl.ColorBufferBit + FlGl.DepthBufferBit)
  ELSE FlGl.Clear(FlGl.ColorBufferBit)
  END;
  FOR i := 1 TO pieces DO done[i] := FALSE END;
  FlGl.LoadName(0);
  DrawContainer;
  FOR i := 0 TO height - 1 DO
    FOR j := 0 TO width - 1 DO
      piece := thePuzzle[i, j];
      IF (piece # 0) & ~done[piece] THEN
        done[piece] := TRUE;
        FlGl.LoadName(piece);
        IF piece = movingPiece THEN DrawBox(piece, moveX, moveY)
        ELSE DrawBox(piece, SHORT(j), SHORT(i))
        END
      END
    END
  END
END DrawAll;

PROCEDURE Aspect(): LONGREAL;
  VAR a: LONGREAL;
BEGIN a := viewport[2]; RETURN a * 1.0D0 / viewport[3]
END Aspect;

PROCEDURE Redraw;
BEGIN
  FlGl.MatrixMode(FlGl.Projection);
  FlGl.LoadIdentity;
  FlGlu.Perspective(45, Aspect(), 0.1D0, 100.0D0);
  DrawAll;
  IF doubleBuffer THEN FlGlut.SwapBuffers ELSE FlGl.GlFinish END
END Redraw;

PROCEDURE SolidifyChain(puzzle: Puzzle);
  VAR i: INTEGER;
BEGIN
  i := 0;
  WHILE puzzle.back # NIL DO
    INC(i);
    puzzle.back.soln := puzzle;
    puzzle := puzzle.back
  END;
  SetTitle("", i, " moves to complete!")
END SolidifyChain;

PROCEDURE Same(VAR a, b: Config): BOOLEAN;
  VAR i, j: INTEGER;
BEGIN
  FOR i := 0 TO width - 1 DO
    FOR j := 0 TO height - 1 DO
      IF convert[a[j, i]] # convert[b[j, i]] THEN RETURN FALSE END
    END
  END;
  RETURN TRUE
END Same;

(* adds config, reached from back, unless it is known: TRUE if it solves the puzzle *)
PROCEDURE AddConfig(VAR config: Config; back: Puzzle): BOOLEAN;
  VAR hash: HUGEINT; p: Puzzle; entry: List; slot: INTEGER;
BEGIN
  hash := Hash(config);
  slot := SHORT(hash MOD hashSize);
  p := hashTable[slot];
  WHILE p # NIL DO
    IF (p.hash = hash) & Same(config, p.pieces) THEN RETURN FALSE END;
    p := p.next
  END;
  NEW(p);
  p.next := hashTable[slot];
  p.hash := hash;
  p.pieces := config;
  p.back := back;
  p.soln := NIL;
  hashTable[slot] := p;
  NEW(entry); entry.puzzle := p; entry.next := NIL;
  IF lastEntry # NIL THEN lastEntry.next := entry ELSE puzzles := entry END;
  lastEntry := entry;
  IF back = NIL THEN startPuzzle := p END;
  IF Solution(config) THEN SolidifyChain(p); RETURN TRUE END;
  RETURN FALSE
END AddConfig;

(* Can the space at x, y move in dir? The new configuration is in newPieces. *)
PROCEDURE CanMove0(VAR pieces: Config; x, y, dir: INTEGER; VAR newPieces: Config): BOOLEAN;
  VAR piece, xAdd, yAdd, l, m, newX, newY: INTEGER;
BEGIN
  xAdd := xAdds[dir]; yAdd := yAdds[dir];
  IF (x + xAdd < 0) OR (x + xAdd >= width) OR (y + yAdd < 0) OR (y + yAdd >= height) THEN
    RETURN FALSE
  END;
  piece := pieces[y + yAdd, x + xAdd];
  IF piece = 0 THEN RETURN FALSE END;
  newPieces := pieces;
  FOR l := 0 TO width - 1 DO
    FOR m := 0 TO height - 1 DO
      IF newPieces[m, l] = piece THEN newPieces[m, l] := 0 END
    END
  END;
  xAdd := -xAdd; yAdd := -yAdd;
  FOR l := 0 TO width - 1 DO
    FOR m := 0 TO height - 1 DO
      IF pieces[m, l] = piece THEN
        newX := l + xAdd; newY := m + yAdd;
        IF (newX < 0) OR (newX >= width) OR (newY < 0) OR (newY >= height) THEN RETURN FALSE END;
        IF newPieces[newY, newX] # 0 THEN RETURN FALSE END;
        newPieces[newY, newX] := piece
      END
    END
  END;
  RETURN TRUE
END CanMove0;

(* Can the piece at x, y move in dir? *)
PROCEDURE CanMove(VAR pieces: Config; x, y, dir: INTEGER; VAR newPieces: Config): BOOLEAN;
  VAR xAdd, yAdd: INTEGER;
BEGIN
  xAdd := xAdds[dir]; yAdd := yAdds[dir];
  IF (x + xAdd < 0) OR (x + xAdd >= width) OR (y + yAdd < 0) OR (y + yAdd >= height) THEN
    RETURN FALSE
  END;
  IF pieces[y + yAdd, x + xAdd] = pieces[y, x] THEN
    RETURN CanMove(pieces, x + xAdd, y + yAdd, dir, newPieces)
  END;
  IF pieces[y + yAdd, x + xAdd] # 0 THEN RETURN FALSE END;
  RETURN CanMove0(pieces, x + xAdd, y + yAdd, (dir + 2) MOD 4, newPieces)
END CanMove;

PROCEDURE GenerateNewConfigs(puzzle: Puzzle): BOOLEAN;
  VAR i, j, k: INTEGER; pieces, newPieces: Config;
BEGIN
  pieces := puzzle.pieces;
  FOR i := 0 TO width - 1 DO
    FOR j := 0 TO height - 1 DO
      IF pieces[j, i] = 0 THEN
        FOR k := 0 TO 3 DO
          IF CanMove0(pieces, i, j, k, newPieces) & AddConfig(newPieces, puzzle) THEN
            RETURN TRUE
          END
        END
      END
    END
  END;
  RETURN FALSE
END GenerateNewConfigs;

PROCEDURE FreeSolutions;
  VAR i: INTEGER;
BEGIN
  puzzles := NIL; lastEntry := NIL;
  FOR i := 0 TO hashSize - 1 DO hashTable[i] := NIL END;
  startPuzzle := NIL
END FreeSolutions;

(* moves the solution on a step: FALSE when it is done *)
PROCEDURE ContinueSolving(): BOOLEAN;
  VAR next: Puzzle; i, j, movedPiece, moveDir, fromX, fromY, toX, toY: INTEGER;
    found: BOOLEAN;
BEGIN
  IF startPuzzle = NIL THEN RETURN FALSE END;
  IF startPuzzle.soln = NIL THEN FreeSolutions; RETURN FALSE END;
  next := startPuzzle.soln;
  movedPiece := 0; moveDir := 0; fromX := 0; fromY := 0;
  found := FALSE; i := 0;
  WHILE ~found & (i < height) DO
    j := 0;
    WHILE ~found & (j < width) DO
      IF startPuzzle.pieces[i, j] # next.pieces[i, j] THEN
        found := TRUE;
        IF startPuzzle.pieces[i, j] # 0 THEN
          movedPiece := startPuzzle.pieces[i, j];
          fromX := j; fromY := i;
          IF (i < height - 1) & (next.pieces[i + 1, j] = movedPiece) THEN moveDir := 3
          ELSE moveDir := 2
          END
        ELSE
          movedPiece := next.pieces[i, j];
          IF (i < height - 1) & (startPuzzle.pieces[i + 1, j] = movedPiece) THEN
            fromX := j; fromY := i + 1; moveDir := 1
          ELSE
            fromX := j + 1; fromY := i; moveDir := 0
          END
        END
      END;
      INC(j)
    END;
    INC(i)
  END;
  IF ~found THEN
    FlGlut.SetWindowTitle("What!  No change?");
    FreeSolutions;
    RETURN FALSE
  END;
  IF movingPiece = 0 THEN
    movingPiece := movedPiece;
    moveX := SHORT(fromX); moveY := SHORT(fromY)
  END;
  moveX := moveX + xAdds[moveDir] * moveSpeed;
  moveY := moveY + yAdds[moveDir] * moveSpeed;
  toX := fromX + xAdds[moveDir];
  toY := fromY + yAdds[moveDir];
  IF (moveX > toX - moveSpeed / 2) & (moveX < toX + moveSpeed / 2)
      & (moveY > toY - moveSpeed / 2) & (moveY < toY + moveSpeed / 2) THEN
    startPuzzle := next;
    movingPiece := 0
  END;
  thePuzzle := startPuzzle.pieces;
  ChangeState;
  RETURN TRUE
END ContinueSolving;

(* finds a solution, breadth first: FALSE if the puzzle is already solved *)
PROCEDURE SolvePuzzle(): BOOLEAN;
  VAR i: INTEGER;
BEGIN
  IF Solution(thePuzzle) THEN
    FlGlut.SetWindowTitle("Puzzle already solved!");
    RETURN FALSE
  END;
  IF AddConfig(thePuzzle, NIL) THEN END;
  i := 0;
  WHILE (puzzles # NIL) & ~GenerateNewConfigs(puzzles.puzzle) DO
    INC(i);
    puzzles := puzzles.next
  END;
  IF puzzles = NIL THEN
    FreeSolutions;
    SetTitle("I can't solve it! (", i, " positions examined)")
  END;
  RETURN TRUE
END SolvePuzzle;

(* the piece drawn under the mouse, 0 if none *)
PROCEDURE SelectPiece(x, y: INTEGER): INTEGER;
  VAR hits, closest: INTEGER; dist, d: HUGEINT;
BEGIN
  FlGl.SelectBuffer(1024);
  IF FlGl.RenderMode(FlGl.Select) = 0 THEN END;
  FlGl.InitNames;
  FlGl.PushName(0);   (* LoadName won't work with no names on the stack *)
  FlGl.MatrixMode(FlGl.Projection);
  FlGl.LoadIdentity;
  FlGlu.PickMatrix(x, h - y, 4, 4, viewport);
  FlGlu.Perspective(45, Aspect(), 0.1D0, 100.0D0);
  DrawAll;
  hits := FlGl.RenderMode(FlGl.Render);
  IF hits <= 0 THEN RETURN 0 END;
  (* each record is one name, so four values, and the depths are unsigned *)
  closest := 0;
  dist := 0FFFFFFFFH;
  WHILE hits > 0 DO
    d := FlGl.SelectValue((hits - 1) * 4 + 1) MOD 100000000H;
    IF d < dist THEN
      dist := d;
      closest := FlGl.SelectValue((hits - 1) * 4 + 3)
    END;
    DEC(hits)
  END;
  RETURN closest
END SelectPiece;

PROCEDURE NukePiece(piece: INTEGER);
  VAR i, j: INTEGER;
BEGIN
  FOR i := 0 TO height - 1 DO
    FOR j := 0 TO width - 1 DO
      IF thePuzzle[i, j] = piece THEN thePuzzle[i, j] := 0 END
    END
  END
END NukePiece;

PROCEDURE MultMatrices(a-, b-: ARRAY OF REAL; VAR r: ARRAY OF REAL);
  VAR i, j: INTEGER;
BEGIN
  FOR i := 0 TO 3 DO
    FOR j := 0 TO 3 DO
      r[i * 4 + j] := a[i * 4 + 0] * b[0 * 4 + j] + a[i * 4 + 1] * b[1 * 4 + j]
        + a[i * 4 + 2] * b[2 * 4 + j] + a[i * 4 + 3] * b[3 * 4 + j]
    END
  END
END MultMatrices;

(* inverse := src inverted, src and inverse the same array *)
PROCEDURE InvertMatrix(VAR m: ARRAY OF REAL): BOOLEAN;
  VAR i, j, k, swap: INTEGER; t: REAL; temp: ARRAY 4, 4 OF REAL;
BEGIN
  FOR i := 0 TO 3 DO FOR j := 0 TO 3 DO temp[i, j] := m[i * 4 + j] END END;
  FOR i := 0 TO 15 DO m[i] := 0 END;
  m[0] := 1; m[5] := 1; m[10] := 1; m[15] := 1;
  FOR i := 0 TO 3 DO
    swap := i;   (* the largest element in the column *)
    FOR j := i + 1 TO 3 DO
      IF ABS(temp[j, i]) > ABS(temp[i, i]) THEN swap := j END
    END;
    IF swap # i THEN
      FOR k := 0 TO 3 DO
        t := temp[i, k]; temp[i, k] := temp[swap, k]; temp[swap, k] := t;
        t := m[i * 4 + k]; m[i * 4 + k] := m[swap * 4 + k]; m[swap * 4 + k] := t
      END
    END;
    IF temp[i, i] = 0 THEN RETURN FALSE END;   (* singular *)
    t := temp[i, i];
    FOR k := 0 TO 3 DO temp[i, k] := temp[i, k] / t; m[i * 4 + k] := m[i * 4 + k] / t END;
    FOR j := 0 TO 3 DO
      IF j # i THEN
        t := temp[j, i];
        FOR k := 0 TO 3 DO
          temp[j, k] := temp[j, k] - temp[i, k] * t;
          m[j * 4 + k] := m[j * 4 + k] - m[i * 4 + k] * t
        END
      END
    END
  END;
  RETURN TRUE
END InvertMatrix;

(* The object's x and y under the mouse, at the height of piece's top. *)
PROCEDURE ComputeCoords(piece, x, y: INTEGER; VAR selX, selY: REAL): BOOLEAN;
  VAR model, proj, final: ARRAY 16 OF REAL; in0, in1, a, b, c, d, top, bot, z, wt, ht: REAL;
BEGIN
  IF piece = 0 THEN RETURN FALSE END;
  ht := zSize[piece] - 0.1 + offsetZ;
  IF FlGl.GetFloat(FlGl.ProjectionMatrix, proj) & FlGl.GetFloat(FlGl.ModelviewMatrix, model) THEN END;
  MultMatrices(model, proj, final);
  IF ~InvertMatrix(final) THEN RETURN FALSE END;
  in0 := (2.0 * (x - viewport[0]) / viewport[2]) - 1;
  in1 := (2.0 * ((h - y) - viewport[1]) / viewport[3]) - 1;
  a := in0 * final[0 * 4 + 2] + in1 * final[1 * 4 + 2] + final[3 * 4 + 2];
  b := final[2 * 4 + 2];
  c := in0 * final[0 * 4 + 3] + in1 * final[1 * 4 + 3] + final[3 * 4 + 3];
  d := final[2 * 4 + 3];
  (* (a + b z) / (c + d z) = ht, so z = (ht c - a) / (b - ht d) *)
  top := ht * c - a;
  bot := b - ht * d;
  IF bot = 0.0 THEN RETURN FALSE END;
  z := top / bot;
  wt := c + d * z;
  selX := (in0 * final[0 * 4 + 0] + in1 * final[1 * 4 + 0] + z * final[2 * 4 + 0]
    + final[3 * 4 + 0]) / wt - offsetX;
  selY := (in0 * final[0 * 4 + 1] + in1 * final[1 * 4 + 1] + z * final[2 * 4 + 1]
    + final[3 * 4 + 1]) / wt - offsetY;
  RETURN TRUE
END ComputeCoords;

PROCEDURE GrabPiece(piece: INTEGER; selX, selY: REAL);
  VAR hit: INTEGER;
BEGIN
  selectX := Trunc(selX); selectY := Trunc(selY);
  IF (selectX < 0) OR (selectY < 0) OR (selectX >= width) OR (selectY >= height) THEN RETURN END;
  hit := thePuzzle[selectY, selectX];
  IF hit # piece THEN RETURN END;
  IF hit # 0 THEN
    movingPiece := hit;
    WHILE (selectX > 0) & (thePuzzle[selectY, selectX - 1] = movingPiece) DO DEC(selectX) END;
    WHILE (selectY > 0) & (thePuzzle[selectY - 1, selectX] = movingPiece) DO DEC(selectY) END;
    moveX := SHORT(selectX); moveY := SHORT(selectY);
    selected := TRUE;
    selStartX := selX; selStartY := selY
  ELSE
    selected := FALSE
  END;
  ChangeState
END GrabPiece;

PROCEDURE MoveSelection(selX, selY: REAL);
  VAR deltaX, deltaY: REAL; dir: INTEGER; newPieces: Config;
BEGIN
  IF ~selected THEN RETURN END;
  deltaX := selX - selStartX;
  deltaY := selY - selStartY;
  IF ABS(deltaX) > ABS(deltaY) THEN
    deltaY := 0;
    IF deltaX > 0 THEN
      IF deltaX > 1 THEN deltaX := 1 END;
      dir := 2
    ELSE
      IF deltaX < -1 THEN deltaX := -1 END;
      dir := 0
    END
  ELSE
    deltaX := 0;
    IF deltaY > 0 THEN
      IF deltaY > 1 THEN deltaY := 1 END;
      dir := 3
    ELSE
      IF deltaY < -1 THEN deltaY := -1 END;
      dir := 1
    END
  END;
  IF CanMove(thePuzzle, selectX, selectY, dir, newPieces) THEN
    moveX := deltaX + selectX;
    moveY := deltaY + selectY;
    IF deltaX > 0.5 THEN thePuzzle := newPieces; INC(selectX); selStartX := selStartX + 1
    ELSIF deltaX < -0.5 THEN thePuzzle := newPieces; DEC(selectX); selStartX := selStartX - 1
    ELSIF deltaY > 0.5 THEN thePuzzle := newPieces; INC(selectY); selStartY := selStartY + 1
    ELSIF deltaY < -0.5 THEN thePuzzle := newPieces; DEC(selectY); selStartY := selStartY - 1
    END
  ELSIF (deltaY > 0) & (thePuzzle[selectY, selectX] = 10) & (selectX = 1) & (selectY = 3) THEN
    (* the solution piece may be seen to move out of the box *)
    moveX := SHORT(selectX);
    moveY := selY - selStartY + selectY
  ELSE
    moveX := SHORT(selectX);
    moveY := SHORT(selectY)
  END
END MoveSelection;

PROCEDURE DropSelection;
BEGIN
  IF selected THEN movingPiece := 0; selected := FALSE; ChangeState END
END DropSelection;

PROCEDURE Reshape(width, height: INTEGER);
BEGIN
  w := width; h := height;
  FlGl.Viewport(0, 0, w, h);
  IF FlGl.GetInteger(FlGl.ViewportArea, viewport) THEN END
END Reshape;

PROCEDURE StopSolving;
BEGIN
  FreeSolutions;
  solving := FALSE;
  FlGlut.ChangeToMenuEntry(2, "Solve", 2);
  FlGlut.SetWindowTitle("glpuzzle");
  movingPiece := 0
END StopSolving;

PROCEDURE ToggleSolve;
BEGIN
  IF solving THEN StopSolving
  ELSE
    FlGlut.ChangeToMenuEntry(2, "Stop solving", 2);
    FlGlut.SetWindowTitle("Solving...");
    IF SolvePuzzle() THEN solving := TRUE END
  END;
  ChangeState;
  FlGlut.PostRedisplay
END ToggleSolve;

PROCEDURE ResetPosition;
BEGIN
  spinning := FALSE;
  Trackball(curQuat, 0.0, 0.0, 0.0, 0.0);
  IF ~timerPending THEN timerPending := TRUE; FlGlut.TimerFunc(timerDelay, Animate, 0) END
END ResetPosition;

PROCEDURE Reset;
BEGIN
  ResetPosition;
  IF solving THEN StopSolving; ChangeState END;
  thePuzzle := startConfig;
  FlGlut.PostRedisplay
END Reset;

PROCEDURE Keyboard(c: CHAR; x, y: INTEGER);
  VAR piece: INTEGER;
BEGIN
  CASE c OF
  | 1BX: HALT(0)
  | " ", "n", "N": ResetPosition
  | "D", "d":
    IF solving THEN StopSolving; ChangeState END;
    piece := SelectPiece(x, y);
    IF piece # 0 THEN NukePiece(piece) END;
    FlGlut.PostRedisplay
  | "R", "r": Reset
  | "S", "s": ToggleSolve
  | "B", "b":
    depth := ~depth;
    IF depth THEN FlGl.Enable(FlGl.DepthTest) ELSE FlGl.Disable(FlGl.DepthTest) END;
    FlGlut.PostRedisplay
  ELSE
  END
END Keyboard;

PROCEDURE Motion(x, y: INTEGER);
  VAR selX, selY: REAL;
BEGIN
  IF middleMouse & ~leftMouse THEN
    IF (mouseX # x) OR (mouseY # y) THEN
      Trackball(lastQuat, (2.0 * mouseX - w) / w, (h - 2.0 * mouseY) / h,
        (2.0 * x - w) / w, (h - 2.0 * y) / h);
      spinning := enableSpinning
    ELSE
      spinning := FALSE
    END;
    ChangeState
  ELSE
    (* As in the C++, an unset selX and selY are moved to when ComputeCoords
       fails; MoveSelection does nothing then unless a piece is selected. *)
    IF ComputeCoords(selPiece, x, y, selX, selY) THEN MoveSelection(selX, selY) END
  END;
  mouseX := x; mouseY := y;
  FlGlut.PostRedisplay
END Motion;

PROCEDURE Mouse(b, s, x, y: INTEGER);
  VAR selX, selY: REAL;
BEGIN
  mouseX := x; mouseY := y;
  IF s = FlGlut.Down THEN
    IF b = FlGlut.LeftButton THEN
      IF solving THEN StopSolving END;
      leftMouse := TRUE;
      selPiece := SelectPiece(mouseX, mouseY);
      IF selPiece = 0 THEN
        leftMouse := FALSE;
        middleMouse := TRUE   (* turn the puzzle *)
      ELSIF ComputeCoords(selPiece, mouseX, mouseY, selX, selY) THEN
        GrabPiece(selPiece, selX, selY)
      END;
      FlGlut.PostRedisplay
    ELSIF b = FlGlut.MiddleButton THEN
      middleMouse := TRUE;
      FlGlut.PostRedisplay
    END
  ELSIF leftMouse THEN
    leftMouse := FALSE;
    DropSelection;
    FlGlut.PostRedisplay
  ELSIF middleMouse THEN
    middleMouse := FALSE;
    FlGlut.PostRedisplay
  END;
  Motion(x, y)
END Mouse;

PROCEDURE Animate(value: INTEGER);
BEGIN
  timerPending := FALSE;
  IF spinning THEN AddQuats(lastQuat, curQuat, curQuat) END;
  FlGlut.PostRedisplay;
  IF solving & ~ContinueSolving() THEN
    solving := FALSE;
    FlGlut.ChangeToMenuEntry(2, "Solve", 2);
    FlGlut.SetWindowTitle("glpuzzle")
  END;
  IF ~solving & ~spinning OR ~visible THEN timerActive := FALSE END;
  IF timerActive & ~timerPending THEN
    timerPending := TRUE;
    FlGlut.TimerFunc(timerDelay, Animate, 0)
  END
END Animate;

PROCEDURE ChangeState;
BEGIN
  IF visible THEN
    IF ~solving & ~spinning THEN timerActive := FALSE
    ELSE
      timerActive := TRUE;
      IF ~timerPending THEN timerPending := TRUE; FlGlut.TimerFunc(timerDelay, Animate, 0) END
    END
  ELSE
    timerActive := FALSE
  END
END ChangeState;

PROCEDURE Set4(VAR v: ARRAY OF REAL; a, b, c, d: REAL);
BEGIN v[0] := a; v[1] := b; v[2] := c; v[3] := d
END Set4;

PROCEDURE InitGl;
  VAR v: ARRAY 4 OF REAL; one: ARRAY 1 OF REAL;
BEGIN
  FlGl.Enable(FlGl.CullFace);
  FlGl.SetCullFace(FlGl.Back);
  FlGl.Enable(FlGl.DepthTest);
  FlGl.ClearDepth(1.0D0);
  FlGl.ClearColor(0.5, 0.5, 0.5, 0.0);
  Set4(v, 0.1, 0.1, 0.1, 1.0); FlGl.Light(FlGl.Light0, FlGl.Ambient, v);
  Set4(v, 1.0, 1.0, 1.0, 0.0); FlGl.Light(FlGl.Light0, FlGl.Diffuse, v);
  Set4(v, 0.0, 0.0, 0.0, 0.0); FlGl.Light(FlGl.Light0, FlGl.Specular, v);
  Set4(v, 0.8660254, 0.5, 1, 0); FlGl.Light(FlGl.Light0, FlGl.Position, v);
  FlGl.Enable(FlGl.Light0);
  one[0] := 0; FlGl.LightModel(FlGl.LightModelLocalViewer, one);
  FlGl.LightModel(FlGl.LightModelTwoSide, one);
  Set4(v, 0.0, 0.0, 0.0, 0.0); FlGl.LightModel(FlGl.LightModelAmbient, v);
  FlGl.Enable(FlGl.Lighting);
  Set4(v, 0.0, 0.0, 0.0, 1.0); FlGl.Material(FlGl.Front, FlGl.Ambient, v);
  one[0] := 40.0; FlGl.Material(FlGl.Front, FlGl.Shininess, one);
  Set4(v, 0.0, 0.0, 0.0, 0.0); FlGl.Material(FlGl.Front, FlGl.Specular, v);
  Set4(v, 1.0, 0.0, 0.0, 0.0); FlGl.Material(FlGl.Front, FlGl.Diffuse, v);
  FlGl.SetColorMaterial(FlGl.FrontAndBack, FlGl.Diffuse);
  FlGl.Enable(FlGl.ColorMaterial);
  FlGl.ShadeModel(FlGl.Flat);
  Trackball(curQuat, 0.0, 0.0, 0.0, 0.0)
  (* The C++ seeds random numbers here, and never uses them. *)
END InitGl;

PROCEDURE Visibility(v: INTEGER);
BEGIN visible := v = FlGlut.Visible; ChangeState
END Visibility;

PROCEDURE Menu(choice: INTEGER);
BEGIN
  CASE choice OF
  | 1: ResetPosition
  | 2: ToggleSolve
  | 3: Reset
  | 4: HALT(0)
  ELSE
  END
END Menu;

PROCEDURE Usage;
BEGIN
  Out.String("Usage: puzzle [-s]"); Out.Ln;
  Out.String("   -s:  Run in single buffered mode"); Out.Ln;
  HALT(255)   (* the C++'s exit(-1) *)
END Usage;

(* Tables *)

PROCEDURE V(VAR v: Vec; x, y, z: REAL);
BEGIN v[0] := x; v[1] := y; v[2] := z
END V;

PROCEDURE F(VAR f: ARRAY OF INTEGER; a, b, c, d: INTEGER);
BEGIN f[0] := a; f[1] := b; f[2] := c; f[3] := d
END F;

PROCEDURE Row(VAR c: Config; i, a, b, d, e: INTEGER);
BEGIN c[i, 0] := a; c[i, 1] := b; c[i, 2] := d; c[i, 3] := e
END Row;

PROCEDURE InitTables;
  VAR i: INTEGER;
BEGIN
  convert[0] := 0;
  FOR i := 1 TO 4 DO convert[i] := 1 END;
  FOR i := 5 TO 8 DO convert[i] := 2 END;
  convert[9] := 3; convert[10] := 4;
  colors[0, 0] := 0; colors[0, 1] := 0; colors[0, 2] := 0;
  FOR i := 1 TO 10 DO colors[i, 0] := 255; colors[i, 1] := 255; colors[i, 2] := 127 END;
  FOR i := 5 TO 8 DO colors[i, 1] := 127; colors[i, 2] := 255 END;
  colors[9, 1] := 127; colors[10, 2] := 255;
  FOR i := 0 TO 10 DO xSize[i] := 1; ySize[i] := 1; zSize[i] := 1 END;
  xSize[0] := 0; ySize[0] := 0; zSize[0] := 0;
  FOR i := 5 TO 8 DO ySize[i] := 2 END;
  xSize[9] := 2; xSize[10] := 2; ySize[10] := 2; zSize[10] := 0.6;
  Row(startConfig, 0, 8, 10, 10, 7);
  Row(startConfig, 1, 8, 10, 10, 7);
  Row(startConfig, 2, 6, 9, 9, 5);
  Row(startConfig, 3, 6, 4, 3, 5);
  Row(startConfig, 4, 2, 0, 0, 1);
  thePuzzle := startConfig;
  xAdds[0] := -1; xAdds[1] := 0; xAdds[2] := 1; xAdds[3] := 0;
  yAdds[0] := 0; yAdds[1] := -1; yAdds[2] := 0; yAdds[3] := 1;

  V(boxCoords[0], 0.2, 0.2, 0.9); V(boxCoords[1], 0.8, 0.2, 0.9);
  V(boxCoords[2], 0.8, 0.8, 0.9); V(boxCoords[3], 0.2, 0.8, 0.9);
  V(boxCoords[4], 0.2, 0.1, 0.8); V(boxCoords[5], 0.8, 0.1, 0.8);
  V(boxCoords[6], 0.9, 0.2, 0.8); V(boxCoords[7], 0.9, 0.8, 0.8);
  V(boxCoords[8], 0.8, 0.9, 0.8); V(boxCoords[9], 0.2, 0.9, 0.8);
  V(boxCoords[10], 0.1, 0.8, 0.8); V(boxCoords[11], 0.1, 0.2, 0.8);
  V(boxCoords[12], 0.2, 0.1, 0.2); V(boxCoords[13], 0.8, 0.1, 0.2);
  V(boxCoords[14], 0.9, 0.2, 0.2); V(boxCoords[15], 0.9, 0.8, 0.2);
  V(boxCoords[16], 0.8, 0.9, 0.2); V(boxCoords[17], 0.2, 0.9, 0.2);
  V(boxCoords[18], 0.1, 0.8, 0.2); V(boxCoords[19], 0.1, 0.2, 0.2);
  V(boxCoords[20], 0.2, 0.2, 0.1); V(boxCoords[21], 0.8, 0.2, 0.1);
  V(boxCoords[22], 0.8, 0.8, 0.1); V(boxCoords[23], 0.2, 0.8, 0.1);

  V(boxNormals[0], 0, 0, 1); V(boxNormals[1], 0, 1, 0); V(boxNormals[2], 1, 0, 0);
  V(boxNormals[3], 0, 0, -1); V(boxNormals[4], 0, -1, 0); V(boxNormals[5], -1, 0, 0);
  V(boxNormals[6], 0.7071, 0.7071, 0.0); V(boxNormals[7], 0.7071, -0.7071, 0.0);
  V(boxNormals[8], -0.7071, 0.7071, 0.0); V(boxNormals[9], -0.7071, -0.7071, 0.0);
  V(boxNormals[10], 0.7071, 0.0, 0.7071); V(boxNormals[11], 0.7071, 0.0, -0.7071);
  V(boxNormals[12], -0.7071, 0.0, 0.7071); V(boxNormals[13], -0.7071, 0.0, -0.7071);
  V(boxNormals[14], 0.0, 0.7071, 0.7071); V(boxNormals[15], 0.0, 0.7071, -0.7071);
  V(boxNormals[16], 0.0, -0.7071, 0.7071); V(boxNormals[17], 0.0, -0.7071, -0.7071);
  V(boxNormals[18], 0.5774, 0.5774, 0.5774); V(boxNormals[19], 0.5774, 0.5774, -0.5774);
  V(boxNormals[20], 0.5774, -0.5774, 0.5774); V(boxNormals[21], 0.5774, -0.5774, -0.5774);
  V(boxNormals[22], -0.5774, 0.5774, 0.5774); V(boxNormals[23], -0.5774, 0.5774, -0.5774);
  V(boxNormals[24], -0.5774, -0.5774, 0.5774); V(boxNormals[25], -0.5774, -0.5774, -0.5774);

  F(boxFaces[0], 0, 1, 2, 3); F(boxFaces[1], 9, 8, 16, 17);
  F(boxFaces[2], 6, 14, 15, 7); F(boxFaces[3], 20, 23, 22, 21);
  F(boxFaces[4], 12, 13, 5, 4); F(boxFaces[5], 19, 11, 10, 18);
  F(boxFaces[6], 7, 15, 16, 8); F(boxFaces[7], 13, 14, 6, 5);
  F(boxFaces[8], 18, 10, 9, 17); F(boxFaces[9], 19, 12, 4, 11);
  F(boxFaces[10], 1, 6, 7, 2); F(boxFaces[11], 14, 21, 22, 15);
  F(boxFaces[12], 11, 0, 3, 10); F(boxFaces[13], 20, 19, 18, 23);
  F(boxFaces[14], 3, 2, 8, 9); F(boxFaces[15], 17, 16, 22, 23);
  F(boxFaces[16], 4, 5, 1, 0); F(boxFaces[17], 20, 21, 13, 12);
  F(boxFaces[18], 2, 7, 8, -1); F(boxFaces[19], 16, 15, 22, -1);
  F(boxFaces[20], 5, 6, 1, -1); F(boxFaces[21], 13, 21, 14, -1);
  F(boxFaces[22], 10, 3, 9, -1); F(boxFaces[23], 18, 17, 23, -1);
  F(boxFaces[24], 11, 4, 0, -1); F(boxFaces[25], 20, 12, 19, -1);

  V(containerCoords[0], -0.1, -0.1, 1.0); V(containerCoords[1], -0.1, -0.1, -0.1);
  V(containerCoords[2], 4.1, -0.1, -0.1); V(containerCoords[3], 4.1, -0.1, 1.0);
  V(containerCoords[4], 1.0, -0.1, 0.6); V(containerCoords[5], 3.0, -0.1, 0.6);
  V(containerCoords[6], 1.0, -0.1, 0.0); V(containerCoords[7], 3.0, -0.1, 0.0);
  V(containerCoords[8], 1.0, 0.0, 0.0); V(containerCoords[9], 3.0, 0.0, 0.0);
  V(containerCoords[10], 3.0, 0.0, 0.6); V(containerCoords[11], 1.0, 0.0, 0.6);
  V(containerCoords[12], 0.0, 0.0, 1.0); V(containerCoords[13], 4.0, 0.0, 1.0);
  V(containerCoords[14], 4.0, 0.0, 0.0); V(containerCoords[15], 0.0, 0.0, 0.0);
  V(containerCoords[16], 0.0, 5.0, 0.0); V(containerCoords[17], 0.0, 5.0, 1.0);
  V(containerCoords[18], 4.0, 5.0, 1.0); V(containerCoords[19], 4.0, 5.0, 0.0);
  V(containerCoords[20], -0.1, 5.1, -0.1); V(containerCoords[21], 4.1, 5.1, -0.1);
  V(containerCoords[22], 4.1, 5.1, 1.0); V(containerCoords[23], -0.1, 5.1, 1.0);

  FOR i := 0 TO 4 DO V(containerNormals[i], 0, -1, 0) END;
  FOR i := 5 TO 7 DO V(containerNormals[i], 0, 1, 0) END;
  FOR i := 8 TO 10 DO V(containerNormals[i], 1, 0, 0) END;
  FOR i := 11 TO 13 DO V(containerNormals[i], -1, 0, 0) END;
  V(containerNormals[14], 0, 1, 0);
  V(containerNormals[15], 0, 0, -1); V(containerNormals[16], 0, 0, -1);
  FOR i := 17 TO 23 DO V(containerNormals[i], 0, 0, 1) END;

  F(containerFaces[0], 1, 6, 4, 0); F(containerFaces[1], 0, 4, 5, 3);
  F(containerFaces[2], 1, 2, 7, 6); F(containerFaces[3], 7, 2, 3, 5);
  F(containerFaces[4], 16, 19, 18, 17);
  F(containerFaces[5], 23, 22, 21, 20); F(containerFaces[6], 12, 11, 8, 15);
  F(containerFaces[7], 10, 13, 14, 9);
  F(containerFaces[8], 15, 16, 17, 12); F(containerFaces[9], 2, 21, 22, 3);
  F(containerFaces[10], 6, 8, 11, 4);
  F(containerFaces[11], 1, 0, 23, 20); F(containerFaces[12], 14, 13, 18, 19);
  F(containerFaces[13], 9, 7, 5, 10);
  F(containerFaces[14], 12, 13, 10, 11);
  F(containerFaces[15], 1, 20, 21, 2); F(containerFaces[16], 4, 11, 10, 5);
  F(containerFaces[17], 15, 8, 19, 16); F(containerFaces[18], 19, 8, 9, 14);
  F(containerFaces[19], 8, 6, 7, 9); F(containerFaces[20], 0, 3, 13, 12);
  F(containerFaces[21], 13, 3, 22, 18); F(containerFaces[22], 18, 22, 23, 17);
  F(containerFaces[23], 17, 23, 0, 12)
END InitTables;

PROCEDURE Options;
  VAR i, n: INTEGER; s: ARRAY 256 OF CHAR;
BEGIN
  (* glutInit takes FLTK's options; the rest are the program's *)
  i := 1;
  WHILE i < Args.argc DO
    n := Fl.Arg(i);
    IF n > 0 THEN INC(i, n)
    ELSE
      Args.Get(i, s);
      IF (s[0] = "-") & (s[1] = "n") THEN enableSpinning := FALSE   (* spinning can annoy *)
      ELSIF (s[0] = "-") & (s[1] = "s") THEN doubleBuffer := FALSE
      ELSE Usage
      END;
      INC(i)
    END
  END
END Options;

PROCEDURE Help(s: ARRAY OF CHAR);
BEGIN Out.String(s); Out.Ln
END Help;

BEGIN
  w := 400; h := 300;
  doubleBuffer := TRUE; depth := TRUE; enableSpinning := TRUE;
  InitTables;

  FlGl.UseHighRes(TRUE);
  FlGlut.Init;
  Options;
  FlGlut.InitWindowSize(w, h);
  IF doubleBuffer THEN
    FlGlut.InitDisplayMode(FlGlut.Depth + FlGlut.Rgb + FlGlut.Double + FlGlut.Multisample)
  ELSE
    FlGlut.InitDisplayMode(FlGlut.Depth + FlGlut.Rgb + FlGlut.Single + FlGlut.Multisample)
  END;
  IF FlGlut.CreateWindow("glpuzzle") = 0 THEN END;
  visible := TRUE;   (* FLTK's addition: a bug in the original? *)
  InitGl;
  IF FlGl.GetInteger(FlGl.ViewportArea, viewport) THEN END;

  Help("");
  Help("n   Normal position - stop spinning");
  Help("r   Reset puzzle");
  Help("s   Solve puzzle (may take a few seconds to compute)");
  Help("d   Destroy a piece - makes the puzzle easier");
  Help("b   Toggles the depth buffer on and off");
  Help("");
  Help("Left mouse moves pieces");
  Help("Middle mouse spins the puzzle");
  Help("Right mouse has menu");

  FlGlut.ReshapeFunc(Reshape);
  FlGlut.DisplayFunc(Redraw);
  FlGlut.KeyboardFunc(Keyboard);
  FlGlut.MotionFunc(Motion);
  FlGlut.MouseFunc(Mouse);
  FlGlut.VisibilityFunc(Visibility);
  IF FlGlut.CreateMenu(Menu) = 0 THEN END;
  FlGlut.AddMenuEntry("Normal pos", 1);
  FlGlut.AddMenuEntry("Solve", 2);
  FlGlut.AddMenuEntry("Reset", 3);
  FlGlut.AddMenuEntry("Quit", 4);
  FlGlut.AttachMenu(FlGlut.RightButton);
  FlGlut.MainLoop
END GlPuzzle.
