MODULE Fractals; (* FLTK's test/fractals.cxx and fracviewer.cxx: fractal mountains, trees and an island, in a GLUT window inside an FLTK window *)

(* Philip Winston's GLUT demo, with FLTK's buttons above the GLUT window.
   The left button drags the view round (and lets go of it spinning), the
   middle button and the wheel move nearer or further, and the right button
   is a GLUT menu. In flying mode, keys 0 to 9, "+" and "-" set the speed.

   It follows the C++ in its arithmetic, float where that is float and
   double where that is double, and its random numbers are POSIX's drand48,
   written out here, so that it draws what FLTK's program draws. *)

IMPORT Fl, FlButtons, FlGl, FlGlu, FlGlut, Math, MathL, Platform, Strings;

CONST
  (* the display lists *)
  mountain = 1; tree = 2; island = 3; stem = 5; leaf = 6;
  mountainMat = 7; waterMat = 8; leafMat = 9; treeMat = 10;
  stemAndLeaves = 11; axes = 12;

  maxLevel = 8;     (* the levels are 0 to maxLevel *)
  numRands = 191;

  (* the menu's choices *)
  menuQuit = 0; menuRand = 1; menuAxes = 3;

  (* the viewer's movement modes *)
  flying = 0; polar = 1;

  (* the viewer's settings, as fracviewer.cxx's *)
  initPolarAz = 0.0; initPolarEl = 30.0; initDist = 4.0;
  initAzSpin = 0.5; initElSpin = 0.0;
  initEx = 0.0; initEy = -2.0; initEz = -2.0;
  initMove = 0.01; minMove = 0.001;
  moveFraction = 0.25;
  elSens = 0.5; azSens = 0.5; distSens = 0.01; eSens = 0.01;
  minAzSpin = 0.1; minElSpin = 0.1;
  slowDaz = 0.90; slowDel = 0.90;
  prevDaz = 0.80; prevDel = 0.80;
  curDaz = 0.20; curDel = 0.20;

TYPE
  Vec = ARRAY 3 OF REAL;
  LevelButton = POINTER TO RECORD (FlButtons.ButtonDesc) level: INTEGER END;
  FractButton = POINTER TO RECORD (FlButtons.ButtonDesc) fract: INTEGER END;
  MenuButton = POINTER TO RECORD (FlButtons.ButtonDesc) value: INTEGER END;

VAR
  rebuild: BOOLEAN;     (* rebuild the display list in the next display? *)
  fractal: INTEGER;     (* what fractal is being built *)
  level: INTEGER;       (* levels of recursion *)
  drawAxes: BOOLEAN;

  rand48: HUGEINT;      (* drand48's state, 48 bits *)

  dispFactor, dispBias: ARRAY maxLevel + 1 OF REAL;
  randTable: ARRAY numRands OF REAL;
  verts: ARRAY 3 OF Vec;    (* the corners of a mountain *)
  slopes: ARRAY 3 OF REAL;  (* the slopes between them *)
  pegged: ARRAY 3 OF BOOLEAN;   (* is this edge pegged, not displaced? *)
  cutoff: REAL;
  treeSeed: HUGEINT;

  winWidth, winHeight: INTEGER;
  fpsTime: LONGINT; fpsCount, fps: INTEGER;

  (* the viewer *)
  moveMode: INTEGER;
  ex, ey, ez, eyeMove, eyeDist, azSpin, elSpin, eyeAz, eyeEl: REAL;
  moving: BOOLEAN;
  downX, downY, downB: INTEGER;
  downDist, downEl, downAz, downEx, downEy, downEz, downEyeMove: REAL;
  dAz, dEl, lastAz, lastEl: REAL;
  adjustingAzEl, allowIdle: BOOLEAN;
  redisplayWindow: INTEGER;

  window: Fl.Window;
  glut: FlGlut.Window;

(* POSIX's drand48, as glibc computes it *)

PROCEDURE Srand48(seed: HUGEINT);
BEGIN rand48 := (seed MOD 100000000H) * 10000H + 330EH
END Srand48;

PROCEDURE Drand48(): LONGREAL;
  CONST a = 5DEECE66DH; c = 0BH; two24 = 1000000H; two48 = 1000000000000H;
  VAR r: LONGREAL;
BEGIN
  (* a * x overflows 64 bits, so x is taken in halves of 24 bits *)
  rand48 := (a * (rand48 MOD two24) + (a * (rand48 DIV two24)) MOD two24 * two24 + c)
    MOD two48;
  r := rand48;
  RETURN r / two48
END Drand48;

(* C's conversion of a float to an integer, toward zero *)
PROCEDURE Trunc(x: REAL): HUGEINT;
BEGIN
  IF x < 0 THEN RETURN -ENTIER(-x) ELSE RETURN ENTIER(x) END
END Trunc;

PROCEDURE Now(): LONGINT;
  VAR sec, usec: LONGINT;
BEGIN Platform.GetTimeOfDay(sec, usec); RETURN sec
END Now;

PROCEDURE ToRad(x: REAL): LONGREAL;
BEGIN RETURN (MathL.pi / 180.0D0) * x
END ToRad;

(* Vectors *)

PROCEDURE Normalize(VAR v: Vec);
  VAR d: REAL;
BEGIN
  d := Math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
  IF d # 0 THEN v[0] := v[0] / d; v[1] := v[1] / d; v[2] := v[2] / d END
END Normalize;

(* cp is the normalized cross product of v1 and v2 *)
PROCEDURE NCrossProd(VAR v1, v2, cp: Vec);
BEGIN
  cp[0] := v1[1] * v2[2] - v1[2] * v2[1];
  cp[1] := v1[2] * v2[0] - v1[0] * v2[2];
  cp[2] := v1[0] * v2[1] - v1[1] * v2[0];
  Normalize(cp)
END NCrossProd;

PROCEDURE TriagNormal(VAR v1, v2, v3, norm: Vec);
  VAR vec1, vec2: Vec; i: INTEGER;
BEGIN
  FOR i := 0 TO 2 DO vec1[i] := v3[i] - v1[i]; vec2[i] := v2[i] - v1[i] END;
  NCrossProd(vec2, vec1, norm)
END TriagNormal;

PROCEDURE XzLength(VAR v1, v2: Vec): REAL;
BEGIN
  RETURN Math.sqrt((v1[0] - v2[0]) * (v1[0] - v2[0]) + (v1[2] - v2[2]) * (v1[2] - v2[2]))
END XzLength;

PROCEDURE XzSlope(VAR v1, v2: Vec): REAL;
BEGIN
  IF v1[0] # v2[0] THEN RETURN (v1[2] - v2[2]) / (v1[0] - v2[0])
  ELSE RETURN MAX(REAL)
  END
END XzSlope;

(* Mountains *)

(* a new table of random numbers, -0.5 to 0.5 *)
PROCEDURE InitRandTable(seed: LONGINT);
  VAR i: INTEGER;
BEGIN
  Srand48(seed);
  FOR i := 0 TO numRands - 1 DO randTable[i] := SHORT(Drand48() - 0.5D0) END
END InitRandTable;

(* the midpoint of v1 and v2, displaced if it should be *)
PROCEDURE Midpoint(VAR mid, v1, v2: Vec; edge, lvl: INTEGER);
  VAR hash: HUGEINT; s, d: REAL; t: LONGREAL;
BEGIN
  mid[0] := (v1[0] + v2[0]) / 2;
  mid[1] := (v1[1] + v2[1]) / 2;
  mid[2] := (v1[2] + v2[2]) / 2;
  d := XzSlope(verts[edge], mid) - slopes[edge];
  IF ~pegged[edge] OR (ABS(d) > 0.00001D0) THEN
    s := (v1[0] + v2[0]) * 23344; Srand48(Trunc(s));
    t := Drand48() * 7334334; hash := ENTIER(t);
    s := (v2[2] + v1[2]) * 43433; Srand48(Trunc(s));
    t := Drand48() * 634344 + hash; hash := ENTIER(t) MOD numRands;
    mid[1] := mid[1] + (randTable[hash] + dispBias[lvl]) * dispFactor[lvl]
  END
END Midpoint;

(* the recursive mountain, with an edge allowed to be pegged *)
PROCEDURE FMR(VAR v1, v2, v3: Vec; lvl: INTEGER);
  VAR norm, m1, m2, m3: Vec;
BEGIN
  IF lvl = level THEN
    IF (v1[1] > cutoff) OR (v2[1] > cutoff) OR (v3[1] > cutoff) THEN
      TriagNormal(v1, v2, v3, norm);
      FlGl.Normal3f(norm[0], norm[1], norm[2]);
      FlGl.Vertex3f(v1[0], v1[1], v1[2]);
      FlGl.Vertex3f(v2[0], v2[1], v2[2]);
      FlGl.Vertex3f(v3[0], v3[1], v3[2])
    END
  ELSE
    Midpoint(m1, v1, v2, 0, lvl);
    Midpoint(m2, v2, v3, 1, lvl);
    Midpoint(m3, v3, v1, 2, lvl);
    FMR(v1, m1, m3, lvl + 1);
    FMR(m1, v2, m2, lvl + 1);
    FMR(m3, m2, v3, lvl + 1);
    FMR(m1, m2, m3, lvl + 1)
  END
END FMR;

PROCEDURE FractalMountain(VAR v1, v2, v3: Vec; peg: ARRAY OF BOOLEAN);
  VAR lengths: ARRAY maxLevel + 1 OF REAL; fraction, bias: ARRAY 8 OF REAL;
    avgLen: REAL; i, j: INTEGER;
BEGIN
  fraction[0] := 0.3; fraction[1] := 0.3; fraction[2] := 0.4; fraction[3] := 0.2;
  fraction[4] := 0.3; fraction[5] := 0.2; fraction[6] := 0.4; fraction[7] := 0.4;
  FOR i := 0 TO 7 DO bias[i] := 0.1 END;
  (* the C++ divides only the last by 3 *)
  avgLen := XzLength(v1, v2) + XzLength(v2, v3) + XzLength(v3, v1) / 3;
  FOR i := 0 TO 2 DO
    verts[0][i] := v1[i]; verts[1][i] := v2[i]; verts[2][i] := v3[i];
    pegged[i] := peg[i]
  END;
  slopes[0] := XzSlope(verts[0], verts[1]);
  slopes[1] := XzSlope(verts[1], verts[2]);
  slopes[2] := XzSlope(verts[2], verts[0]);
  lengths[0] := avgLen;
  FOR i := 1 TO level - 1 DO lengths[i] := lengths[i - 1] / 2 END;
  FOR i := 0 TO level - 1 DO
    IF i <= 7 THEN j := i ELSE j := 7 END;
    dispFactor[i] := lengths[i] * fraction[j];
    dispBias[i] := bias[j]
  END;
  FlGl.Begin(FlGl.Triangles);
  FMR(v1, v2, v3, 0);
  FlGl.End
END FractalMountain;

PROCEDURE SetVec(VAR v: Vec; x, y, z: REAL);
BEGIN v[0] := x; v[1] := y; v[2] := z
END SetVec;

PROCEDURE CreateMountain;
  VAR v1, v2, v3: Vec; peg: ARRAY 3 OF BOOLEAN;
BEGIN
  SetVec(v1, 0, 0, -1); SetVec(v2, -1, 0, 1); SetVec(v3, 1, 0, 1);
  peg[0] := TRUE; peg[1] := TRUE; peg[2] := TRUE;
  FlGl.NewList(mountain, FlGl.Compile);
  FlGl.PushAttrib(FlGl.LightingBit);
  FlGl.CallList(mountainMat);
  FractalMountain(v1, v2, v3, peg);
  FlGl.PopAttrib;
  FlGl.EndList
END CreateMountain;

PROCEDURE NewMountain;
BEGIN InitRandTable(Now())
END NewMountain;

(* Trees *)

PROCEDURE ^ FractalTree(lvl: INTEGER; seed: HUGEINT);

PROCEDURE Branch(yAngle: REAL; lvl: INTEGER; seed: HUGEINT);
BEGIN
  FlGl.PushMatrix;
  FlGl.Rotatef(SHORT(yAngle + Drand48() * 40.0D0), 0, 1, 0);
  FlGl.Rotatef(SHORT(30.0D0 + Drand48() * 20.0D0), 0, 0, 1);
  FractalTree(lvl, seed);
  FlGl.PopMatrix
END Branch;

PROCEDURE FractalTree(lvl: INTEGER; seed: HUGEINT);
BEGIN
  IF lvl = level THEN
    FlGl.PushMatrix;
    FlGl.Rotatef(SHORT(Drand48() * 180), 0, 1, 0);
    FlGl.CallList(stemAndLeaves);
    FlGl.PopMatrix
  ELSE
    FlGl.CallList(stem);
    FlGl.PushMatrix;
    FlGl.Rotatef(SHORT(Drand48() * 180.0D0), 0, 1, 0);
    FlGl.Translatef(0, 1, 0);
    FlGl.Scalef(0.7, 0.7, 0.7);
    Srand48(seed + 1); Branch(110, lvl + 1, seed + 4);
    Srand48(seed + 2); Branch(-130, lvl + 1, seed + 5);
    Srand48(seed + 3); Branch(-20, lvl + 1, seed + 6);
    FlGl.PopMatrix
  END
END FractalTree;

PROCEDURE Leaf(yAngle, xAngle: REAL);
BEGIN
  FlGl.PushMatrix;
  FlGl.Rotatef(yAngle, 0, 1, 0);
  FlGl.Rotatef(xAngle, 1, 0, 0);
  FlGl.CallList(leaf);
  FlGl.PopMatrix
END Leaf;

(* the display lists of a leaf, a stem with leaves, and a stem *)
PROCEDURE CreateTreeLists;
  VAR cyl: FlGlu.Quadric; i: INTEGER;
BEGIN
  cyl := FlGlu.NewQuadric();

  FlGl.NewList(stem, FlGl.Compile);
  FlGl.PushMatrix;
  FlGl.Rotatef(-90, 1, 0, 0);
  cyl.Cylinder(0.1D0, 0.08D0, 1, 10, 2);
  FlGl.PopMatrix;
  FlGl.EndList;

  FlGl.NewList(leaf, FlGl.Compile);
  FlGl.Begin(FlGl.Triangles);
  FlGl.Normal3f(-0.1, 0.0, 0.25);   (* not normalized *)
  FlGl.Vertex3f(0.0, 0.0, 0.0);
  FlGl.Vertex3f(0.25, 0.25, 0.1);
  FlGl.Vertex3f(0.0, 0.5, 0.0);
  FlGl.Normal3f(0.1, 0.0, 0.25);
  FlGl.Vertex3f(0.0, 0.0, 0.0);
  FlGl.Vertex3f(0.0, 0.5, 0.0);
  FlGl.Vertex3f(-0.25, 0.25, 0.1);
  FlGl.End;
  FlGl.EndList;

  FlGl.NewList(stemAndLeaves, FlGl.Compile);
  FlGl.PushMatrix;
  FlGl.PushAttrib(FlGl.LightingBit);
  FlGl.CallList(stem);
  FlGl.CallList(leafMat);
  FOR i := 0 TO 2 DO
    FlGl.Translatef(0.0, 0.333, 0.0);
    FlGl.Rotatef(90, 0, 1, 0);
    Leaf(0, 50);
    Leaf(180, 60)
  END;
  FlGl.PopAttrib;
  FlGl.PopMatrix;
  FlGl.EndList;

  cyl.Close
END CreateTreeLists;

PROCEDURE CreateTree;
BEGIN
  Srand48(treeSeed);
  FlGl.NewList(tree, FlGl.Compile);
  FlGl.PushMatrix;
  FlGl.PushAttrib(FlGl.LightingBit);
  FlGl.CallList(treeMat);
  FlGl.Translatef(0, -1, 0);
  FractalTree(0, treeSeed);
  FlGl.PopAttrib;
  FlGl.PopMatrix;
  FlGl.EndList
END CreateTree;

PROCEDURE NewTree;
BEGIN treeSeed := Now()
END NewTree;

(* The island *)

PROCEDURE Hill(angle, x, y, z: REAL);
BEGIN
  FlGl.PushMatrix;
  IF angle # 0 THEN FlGl.Rotatef(angle, 0, 1, 0) END;
  FlGl.Translatef(x, y, z);
  FlGl.CallList(mountain);
  FlGl.PopMatrix
END Hill;

PROCEDURE CreateIsland;
BEGIN
  cutoff := 0.06;
  CreateMountain;
  cutoff := -1;
  FlGl.NewList(island, FlGl.Compile);
  FlGl.PushAttrib(FlGl.LightingBit);
  FlGl.MatrixMode(FlGl.Modelview);
  FlGl.PushMatrix;
  FlGl.CallList(waterMat);
  FlGl.Begin(FlGl.Quads);
  FlGl.Normal3f(0.0, 1.0, 0.0);
  FlGl.Vertex3f(10.0, 0.01, 10.0);
  FlGl.Vertex3f(10.0, 0.01, -10.0);
  FlGl.Vertex3f(-10.0, 0.01, -10.0);
  FlGl.Vertex3f(-10.0, 0.01, 10.0);
  FlGl.End;
  Hill(0, 0.0, -0.1, 0.0);
  Hill(135, 0.2, -0.15, -0.4);
  Hill(-60, 0.7, -0.07, 0.5);
  Hill(-175, -0.7, -0.05, -0.5);
  Hill(165, -0.9, -0.12, 0.0);
  FlGl.PopMatrix;
  FlGl.PopAttrib;
  FlGl.EndList
END CreateIsland;

PROCEDURE NewFractals;
BEGIN NewMountain; NewTree
END NewFractals;

PROCEDURE Create(fract: INTEGER);
BEGIN
  CASE fract OF
  | mountain: CreateMountain
  | tree: CreateTree
  | island: CreateIsland
  ELSE
  END
END Create;

(* OpenGL *)

PROCEDURE Set4(VAR v: ARRAY OF REAL; a, b, c, d: REAL);
BEGIN v[0] := a; v[1] := b; v[2] := c; v[3] := d
END Set4;

PROCEDURE MaterialList(list, face: INTEGER; ambuse, specular: ARRAY OF REAL; shininess: REAL);
  VAR s: ARRAY 1 OF REAL;
BEGIN
  s[0] := shininess;
  FlGl.NewList(list, FlGl.Compile);
  FlGl.Material(face, FlGl.AmbientAndDiffuse, ambuse);
  FlGl.Material(face, FlGl.Specular, specular);
  FlGl.Material(face, FlGl.Shininess, s);
  FlGl.EndList
END MaterialList;

PROCEDURE SetupMaterials;
  VAR amb, spec: ARRAY 4 OF REAL;
BEGIN
  Set4(amb, 0.426, 0.256, 0.108, 1.0); Set4(spec, 0.394, 0.272, 0.167, 1.0);
  MaterialList(mountainMat, FlGl.Front, amb, spec, 10.0);
  Set4(amb, 0.0, 0.1, 0.5, 1.0); Set4(spec, 0.0, 0.1, 0.5, 1.0);
  MaterialList(waterMat, FlGl.Front, amb, spec, 10.0);
  Set4(amb, 0.4, 0.25, 0.1, 1.0); Set4(spec, 0.0, 0.0, 0.0, 1.0);
  MaterialList(treeMat, FlGl.Front, amb, spec, 0.0);
  Set4(amb, 0.0, 0.8, 0.0, 1.0); Set4(spec, 0.0, 0.8, 0.0, 1.0);
  MaterialList(leafMat, FlGl.FrontAndBack, amb, spec, 10.0)
END SetupMaterials;

PROCEDURE MyGLInit;
  VAR v: ARRAY 4 OF REAL;
BEGIN
  Set4(v, 0.0, 0.0, 0.0, 1.0); FlGl.Light(FlGl.Light0, FlGl.Ambient, v);
  Set4(v, 1.0, 1.0, 1.0, 1.0); FlGl.Light(FlGl.Light0, FlGl.Diffuse, v);
  FlGl.Light(FlGl.Light0, FlGl.Specular, v);
  Set4(v, 0.0, 0.3, 0.3, 0.0); FlGl.Light(FlGl.Light0, FlGl.Position, v);
  Set4(v, 0.4, 0.4, 0.4, 1.0); FlGl.LightModel(FlGl.LightModelAmbient, v);
  FlGl.Enable(FlGl.Lighting);
  FlGl.Enable(FlGl.Light0);
  FlGl.DepthFunc(FlGl.Lequal);
  FlGl.Enable(FlGl.DepthTest);
  FlGl.Enable(FlGl.Normalize);
  FlGl.ShadeModel(FlGl.Smooth);
  SetupMaterials;
  CreateTreeLists;
  FlGl.Flush
END MyGLInit;

(* The viewer, fracviewer.cxx *)

PROCEDURE PolarLookFrom(dist, elevation, azimuth: REAL);
BEGIN
  FlGl.Translatef(0, 0, -dist);
  FlGl.Rotatef(elevation, 1, 0, 0);
  FlGl.Rotatef(azimuth, 0, 1, 0)
END PolarLookFrom;

PROCEDURE FlyLookFrom(x, y, z, az, el: REAL);
  VAR lookAt, perp, up: Vec;
BEGIN
  lookAt[0] := SHORT(MathL.sin(ToRad(az)) * MathL.cos(ToRad(el)));
  lookAt[1] := SHORT(MathL.sin(ToRad(el)));
  lookAt[2] := SHORT(-MathL.cos(ToRad(az)) * MathL.cos(ToRad(el)));
  Normalize(lookAt);
  perp[0] := lookAt[2]; perp[1] := 0; perp[2] := -lookAt[0];
  Normalize(perp);
  NCrossProd(lookAt, perp, up);
  FlGlu.LookAt(x, y, z, x + lookAt[0], y + lookAt[1], z + lookAt[2], up[0], up[1], up[2])
END FlyLookFrom;

PROCEDURE ViewTransform;
BEGIN
  IF moveMode = flying THEN FlyLookFrom(ex, ey, ez, eyeAz, eyeEl)
  ELSE PolarLookFrom(eyeDist, eyeEl, eyeAz)
  END
END ViewTransform;

(* keeps the view upright *)
PROCEDURE ConstrainEl(): BOOLEAN;
BEGIN
  IF eyeEl <= -90 THEN eyeEl := -89.99; RETURN TRUE
  ELSIF eyeEl >= 90 THEN eyeEl := 89.99; RETURN TRUE
  END;
  RETURN FALSE
END ConstrainEl;

(* the idle procedure, which moves the eye *)
PROCEDURE Move;
BEGIN
  IF moveMode = flying THEN
    ex := ex + SHORT(eyeMove * MathL.sin(ToRad(eyeAz)) * MathL.cos(ToRad(eyeEl)));
    ey := ey + SHORT(eyeMove * MathL.sin(ToRad(eyeEl)));
    ez := ez - SHORT(eyeMove * MathL.cos(ToRad(eyeAz)) * MathL.cos(ToRad(eyeEl)))
  ELSE
    eyeEl := eyeEl + elSpin;
    eyeAz := eyeAz + azSpin;
    IF ConstrainEl() THEN
      elSpin := -elSpin;
      IF ABS(elSpin) > ABS(azSpin) THEN
        IF azSpin > 0 THEN azSpin := ABS(elSpin) ELSE azSpin := -ABS(elSpin) END
      END
    END
  END;
  IF adjustingAzEl THEN dAz := dAz * slowDaz; dEl := dEl * slowDel END;
  IF allowIdle THEN
    FlGlut.SetWindow(redisplayWindow);
    FlGlut.PostRedisplay
  END
END Move;

(* installs Move as the idle procedure only if the view will change *)
PROCEDURE MoveOn(on: BOOLEAN);
BEGIN
  IF on & ((moveMode = flying) & (eyeMove # 0)
      OR (moveMode = polar) & ((azSpin # 0) OR (elSpin # 0) OR adjustingAzEl)) THEN
    moving := TRUE;
    IF allowIdle THEN FlGlut.IdleFunc(Move) END
  ELSE
    moving := FALSE;
    IF allowIdle THEN FlGlut.IdleFunc(NIL) END
  END
END MoveOn;

PROCEDURE SetAllowIdle(allow: BOOLEAN);
BEGIN
  allowIdle := allow;
  IF allow THEN MoveOn(TRUE) END
END SetAllowIdle;

(* Flying stays where it is; polar starts again, looking at the origin. *)
PROCEDURE SwitchMoveMode(move: INTEGER);
BEGIN
  IF move = flying THEN
    IF moveMode = flying THEN RETURN END;
    ex := SHORT(-eyeDist * MathL.sin(ToRad(eyeAz)) * MathL.cos(ToRad(eyeEl)));
    ey := SHORT(eyeDist * MathL.sin(ToRad(eyeEl)));
    ez := SHORT(eyeDist * (MathL.cos(ToRad(eyeAz)) * MathL.cos(ToRad(eyeEl))));
    eyeEl := -eyeEl;
    eyeMove := initMove
  ELSIF move = polar THEN
    eyeDist := initDist;
    eyeAz := initPolarAz;
    eyeEl := initPolarEl;
    azSpin := initAzSpin;
    elSpin := initElSpin
  END;
  moveMode := move;
  MoveOn(TRUE);
  FlGlut.PostRedisplay
END SwitchMoveMode;

(* moves the eye by delta along its view, and the polar distance *)
PROCEDURE Approach(delta: REAL);
  VAR t: REAL;
BEGIN
  t := eSens * delta;
  ex := SHORT(downEx - t * MathL.sin(ToRad(eyeAz)) * MathL.cos(ToRad(eyeEl)));
  ey := SHORT(downEy - t * MathL.sin(ToRad(eyeEl)));
  ez := SHORT(downEz + t * MathL.cos(ToRad(eyeAz)) * MathL.cos(ToRad(eyeEl)))
END Approach;

PROCEDURE SaveDown;
BEGIN
  downDist := eyeDist;
  downEx := ex; downEy := ey; downEz := ez;
  downEyeMove := eyeMove;
  eyeMove := 0
END SaveDown;

PROCEDURE HandleButton(button, state, x, y: INTEGER);
  VAR deltaY: REAL;
BEGIN
  IF (state = FlGlut.Down) & ((button = 3) OR (button = 4)) THEN
    (* FLTK's GLUT sends the wheel as buttons 3 and 4 *)
    IF button = 3 THEN deltaY := -0.25 ELSE deltaY := 0.25 END;
    downB := -1;
    SaveDown;
    eyeDist := downDist + deltaY;
    Approach(deltaY);
    eyeMove := downEyeMove;
    FlGlut.PostRedisplay
  ELSIF button > FlGlut.RightButton THEN
  ELSIF (state = FlGlut.Down) & (downB = -1) THEN
    downX := x; downY := y;
    downB := button;
    IF button = FlGlut.LeftButton THEN
      downEl := eyeEl; lastEl := eyeEl;
      downAz := eyeAz; lastAz := eyeAz;
      azSpin := 0; elSpin := 0; dAz := 0; dEl := 0;
      adjustingAzEl := TRUE;
      MoveOn(TRUE)
    ELSIF button = FlGlut.MiddleButton THEN
      SaveDown
    END
  ELSIF (state = FlGlut.Up) & (button = downB) THEN
    downB := -1;
    IF button = FlGlut.LeftButton THEN
      IF moveMode # flying THEN
        azSpin := -dAz;
        IF (azSpin < minAzSpin) & (azSpin > -minAzSpin) THEN azSpin := 0 END;
        elSpin := -dEl;
        IF (elSpin < minElSpin) & (elSpin > -minElSpin) THEN elSpin := 0 END
      END;
      adjustingAzEl := FALSE;
      MoveOn(TRUE)
    ELSIF button = FlGlut.MiddleButton THEN
      eyeMove := downEyeMove
    END
  END
END HandleButton;

PROCEDURE HandleMotion(x, y: INTEGER);
  VAR deltaX, deltaY: INTEGER; b: BOOLEAN;
BEGIN
  deltaX := x - downX; deltaY := y - downY;
  IF downB = FlGlut.LeftButton THEN
    eyeEl := downEl + elSens * deltaY;
    b := ConstrainEl();
    eyeAz := downAz + azSens * deltaX;
    dAz := prevDaz * dAz + curDaz * (lastAz - eyeAz);
    dEl := prevDel * dEl + curDel * (lastEl - eyeEl);
    lastAz := eyeAz;
    lastEl := eyeEl
  ELSIF downB = FlGlut.MiddleButton THEN
    eyeDist := downDist + distSens * deltaY;
    Approach(deltaY)
  END;
  FlGlut.PostRedisplay
END HandleMotion;

PROCEDURE SetMove(newMove: REAL);
BEGIN
  IF newMove > minMove THEN eyeMove := newMove; MoveOn(TRUE)
  ELSE eyeMove := 0; MoveOn(FALSE)
  END
END SetMove;

(* 0 to 9 set the speed, "+" and "-" change it, in flying mode *)
PROCEDURE HandleKeys(key: CHAR; x, y: INTEGER);
  VAR n: INTEGER;
BEGIN
  IF moveMode = flying THEN
    IF (key >= "0") & (key <= "9") THEN
      n := ORD(key) - ORD("0"); SetMove(n * n * 0.001)
    ELSIF key = "+" THEN
      IF eyeMove = 0 THEN SetMove(minMove)
      ELSE eyeMove := eyeMove * (1 + moveFraction); SetMove(eyeMove)
      END
    ELSIF key = "-" THEN
      eyeMove := eyeMove * (1 - moveFraction); SetMove(eyeMove)
    END
  END
END HandleKeys;

PROCEDURE ViewerInit(allow: BOOLEAN);
BEGIN
  FlGlut.MouseFunc(HandleButton);
  FlGlut.MotionFunc(HandleMotion);
  FlGlut.KeyboardFunc(HandleKeys);
  redisplayWindow := FlGlut.GetWindow();
  SetAllowIdle(allow)
END ViewerInit;

(* x, y and z axes, about 10 by 10 by 10 *)
PROCEDURE MakeAxesList(list: INTEGER);
  VAR amb: ARRAY 4 OF REAL; trans: REAL; i, j: INTEGER;

  PROCEDURE On(b: BOOLEAN): REAL;
  BEGIN IF b THEN RETURN 1 ELSE RETURN 0 END
  END On;

BEGIN
  Set4(amb, 0.5, 0.0, 0.0, 1.0);
  trans := -10;
  FlGl.NewList(list, FlGl.Compile);
  FlGl.PushAttrib(FlGl.LightingBit);
  FlGl.MatrixMode(FlGl.Modelview);
  FlGl.Material(FlGl.Front, FlGl.AmbientAndDiffuse, amb);
  FlGl.Begin(FlGl.Lines);
  FlGl.Vertex3f(15, 0, 0); FlGl.Vertex3f(-15, 0, 0);
  FlGl.Vertex3f(0, 15, 0); FlGl.Vertex3f(0, -15, 0);
  FlGl.Vertex3f(0, 0, 15); FlGl.Vertex3f(0, 0, -15);
  FlGl.End;
  (* The C++ steps along each axis, its cubes commented out. *)
  FOR i := 0 TO 2 DO
    FlGl.PushMatrix;
    FlGl.Translatef(trans * On(i = 0), trans * On(i = 1), trans * On(i = 2));
    FOR j := 0 TO 20 DO FlGl.Translatef(On(i = 0), On(i = 1), On(i = 2)) END;
    FlGl.PopMatrix
  END;
  FlGl.PopAttrib;
  FlGl.EndList
END MakeAxesList;

(* GLUT's procedures *)

PROCEDURE Reshape(w, h: INTEGER);
BEGIN
  FlGl.Viewport(0, 0, w, h);
  winWidth := w; winHeight := h
END Reshape;

PROCEDURE IntToStr(n: INTEGER; VAR s: ARRAY OF CHAR);
  VAR d: ARRAY 12 OF CHAR; i, j: INTEGER;
BEGIN
  i := 0;
  REPEAT d[i] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(i) UNTIL n = 0;
  j := 0;
  WHILE i > 0 DO DEC(i); s[j] := d[i]; INC(j) END;
  s[j] := 0X
END IntToStr;

PROCEDURE Display;
  VAR aspect: LONGREAL; buf, num: ARRAY 32 OF CHAR; curTime: LONGINT;
BEGIN
  FlGl.Clear(FlGl.ColorBufferBit + FlGl.DepthBufferBit);
  FlGl.MatrixMode(FlGl.Projection);
  FlGl.LoadIdentity;
  aspect := winWidth; aspect := aspect / winHeight;
  FlGlu.Perspective(60.0D0, aspect, 0.01D0, 100);
  ViewTransform;
  FlGl.MatrixMode(FlGl.Modelview);
  FlGl.LoadIdentity;
  IF rebuild THEN Create(fractal); rebuild := FALSE END;
  FlGl.CallList(fractal);
  IF drawAxes THEN FlGl.CallList(axes) END;

  FlGl.MatrixMode(FlGl.Projection);
  FlGl.LoadIdentity;
  FlGlu.Ortho2D(0, winWidth, 0, winHeight);
  buf := "FPS="; IntToStr(fps, num); Strings.Append(num, buf);
  FlGl.Color3f(1.0, 1.0, 1.0);
  FlGl.Font(Fl.Helvetica, 12);
  FlGl.DrawTextAt(buf, 10, 10);
  (* glFinish, not glFlush, as the C++ says, so as not to get many frames
     ahead of the display *)
  FlGl.GlFinish;

  INC(fpsCount);
  curTime := Now();
  IF curTime - fpsTime >= 2 THEN
    fps := SHORT((fps + fpsCount DIV (curTime - fpsTime)) DIV 2);
    fpsTime := curTime;
    fpsCount := 0
  END
END Display;

PROCEDURE Visible(v: INTEGER);
BEGIN
  IF v = FlGlut.Visible THEN SetAllowIdle(TRUE)
  ELSE FlGlut.IdleFunc(NIL); SetAllowIdle(FALSE)
  END
END Visible;

PROCEDURE MenuUse(v: INTEGER);
BEGIN
  IF v = FlGlut.MenuNotInUse THEN SetAllowIdle(TRUE)
  ELSE FlGlut.IdleFunc(NIL); SetAllowIdle(FALSE)
  END
END MenuUse;

(* The menus *)

PROCEDURE SetLevel(value: INTEGER);
BEGIN level := value; rebuild := TRUE; FlGlut.PostRedisplay
END SetLevel;

PROCEDURE ChooseFract(value: INTEGER);
BEGIN fractal := value; rebuild := TRUE; FlGlut.PostRedisplay
END ChooseFract;

PROCEDURE HandleMenu(value: INTEGER);
BEGIN
  IF value = menuQuit THEN HALT(0)
  ELSIF value = menuRand THEN NewFractals; rebuild := TRUE; FlGlut.PostRedisplay
  ELSIF value = menuAxes THEN drawAxes := ~drawAxes; FlGlut.PostRedisplay
  END
END HandleMenu;

PROCEDURE MenuInit;
  VAR sub1, sub2, sub3, i: INTEGER; name: ARRAY 2 OF CHAR;
BEGIN
  sub1 := FlGlut.CreateMenu(SetLevel);
  name[1] := 0X;
  FOR i := 0 TO maxLevel DO name[0] := CHR(ORD("0") + i); FlGlut.AddMenuEntry(name, i) END;
  sub2 := FlGlut.CreateMenu(ChooseFract);
  FlGlut.AddMenuEntry("Moutain", mountain);
  FlGlut.AddMenuEntry("Tree", tree);
  FlGlut.AddMenuEntry("Island", island);
  sub3 := FlGlut.CreateMenu(SwitchMoveMode);
  FlGlut.AddMenuEntry("Flying", flying);
  FlGlut.AddMenuEntry("Polar", polar);
  i := FlGlut.CreateMenu(HandleMenu);
  FlGlut.AddSubMenu("Level", sub1);
  FlGlut.AddSubMenu("Fractal", sub2);
  FlGlut.AddSubMenu("Movement", sub3);
  FlGlut.AddMenuEntry("New Fractal", menuRand);
  FlGlut.AddMenuEntry("Toggle Axes", menuAxes);
  FlGlut.AddMenuEntry("Quit", menuQuit);
  FlGlut.AttachMenu(FlGlut.RightButton)
END MenuInit;

(* FLTK's buttons, which do what the menus do *)

PROCEDURE (b: LevelButton) Callback*;
BEGIN SetLevel(b.level)
END Callback;

PROCEDURE (b: FractButton) Callback*;
BEGIN ChooseFract(b.fract)
END Callback;

PROCEDURE (b: MenuButton) Callback*;
BEGIN HandleMenu(b.value)
END Callback;

PROCEDURE MakeWindow;
  VAR g: Fl.Group; lb: LevelButton; fb: FractButton; mb: MenuButton;
    i: INTEGER; name: ARRAY 2 OF CHAR;

  PROCEDURE Fract(x: INTEGER; label: ARRAY OF CHAR; fract: INTEGER);
  BEGIN NEW(fb); FlButtons.OpenButton(fb, x, 10, 100, 30, label); fb.fract := fract
  END Fract;

  PROCEDURE Menu(x, y: INTEGER; label: ARRAY OF CHAR; value: INTEGER);
  BEGIN NEW(mb); FlButtons.OpenButton(mb, x, y, 100, 30, label); mb.value := value
  END Menu;

BEGIN
  NEW(window); Fl.OpenWindow(window, 512 + 20, 512 + 100, "");
  window.SetResizable(window);
  NEW(g); Fl.OpenGroup(g, 110, 50, 400 - 110, 30, "Level:");
  g.SetAlign(Fl.AlignLeft);
  name[1] := 0X;
  FOR i := 0 TO maxLevel DO
    name[0] := CHR(ORD("0") + i);
    NEW(lb); FlButtons.OpenButton(lb, 110 + 30 * i, 50, 30, 30, name); lb.level := i
  END;
  g.End;
  Menu(400, 50, "New Fractal", menuRand);
  Fract(10, "Mountain", mountain);
  Fract(110, "Tree", tree);
  Fract(210, "Island", island);
  Menu(400, 10, "Quit", menuQuit);
  window.ShowArgs;   (* GLUT dies unless its parent is shown *)

  (* glutCreateWindow, with the window made inside the shown one *)
  window.Begin;
  FlGlut.InitDisplayMode(FlGlut.Double + FlGlut.Rgba + FlGlut.Depth + FlGlut.Multisample);
  NEW(glut); FlGlut.OpenWindowAt(glut, 10, 90, 512, 512, "Fractal Planet?");
  glut.SetResizable(glut);
  glut.Show;
  glut.MakeCurrent;
  glut.Redraw;
  window.End;
  window.SetResizable(glut)
END MakeWindow;

BEGIN
  rebuild := TRUE; fractal := tree; level := 4;
  cutoff := -1;
  winWidth := 1; winHeight := 1;
  moveMode := polar;
  ex := initEx; ey := initEy; ez := initEz; eyeMove := initMove;
  eyeDist := initDist; azSpin := initAzSpin; elSpin := initElSpin;
  eyeAz := initPolarAz; eyeEl := initPolarEl;
  downB := -1;

  FlGl.UseHighRes(TRUE);
  MakeWindow;
  ViewerInit(TRUE);   (* TRUE, since there is no other idle procedure *)
  FlGlut.ReshapeFunc(Reshape);
  FlGlut.DisplayFunc(Display);
  FlGlut.VisibilityFunc(Visible);
  FlGlut.MenuStateFunc(MenuUse);
  NewFractals;
  MakeAxesList(axes);
  MyGLInit;
  MenuInit;
  FlGlut.MainLoop
END Fractals.
