MODULE FlGlu; (* the part of GLU, OpenGL's utility library, that FLTK's programs use *)

(* GLU sets up GL's matrices from a view (Perspective, LookAt, Ortho2D,
   PickMatrix) and draws quadrics, cylinders, spheres and disks, with
   the context current: in a GL window's Draw, or after its MakeCurrent.

   A Quadric holds how its shapes are drawn. It is GLU's, not collected:
   Close it when done. A method of one closed halts with
   Fl.ClosedResource.

   This is a library of its own, pofltk-glu, since GLU isn't FLTK's or
   GL's, and a system can have GL without it. A program using it names
   pofltk-gl's path too.

   The C++ part is FlGlu.cpp. *)

IMPORT SYSTEM, Fl;

CONST
(* BEGIN generated constants: tools/gen-constants.py writes this block,
   from FLTK's headers; edit the script, not the block. *)

  (* Quadric.DrawStyle's styles *)
  Fill* = 100012;
  Line* = 100011;
  Silhouette* = 100013;
  Point* = 100010;

  (* Quadric.Normals' kinds *)
  NormalsNone* = 100002;
  NormalsFlat* = 100001;
  NormalsSmooth* = 100000;

  (* Quadric.Orientation's directions *)
  Outside* = 100020;
  Inside* = 100021;
(* END generated constants *)

TYPE
  Quadric* = POINTER TO QuadricDesc;
  QuadricDesc* = RECORD
    h: SYSTEM.ADDRESS
  END;

PROCEDURE ["C", "ofl_glu_perspective"] CPerspective(fovy, aspect, near, far: LONGREAL);
PROCEDURE ["C", "ofl_glu_look_at"] CLookAt(ex, ey, ez, cx, cy, cz, ux, uy, uz: LONGREAL);
PROCEDURE ["C", "ofl_glu_ortho2d"] COrtho2D(l, r, b, t: LONGREAL);
PROCEDURE ["C", "ofl_glu_pick_matrix"] CPickMatrix(x, y, w, h: LONGREAL; viewport: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_glu_new_quadric"] CNewQuadric(): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_glu_delete_quadric"] CDeleteQuadric(q: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_glu_quadric_draw_style"] CDrawStyle(q: SYSTEM.ADDRESS; style: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glu_quadric_normals"] CNormals(q: SYSTEM.ADDRESS; normals: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glu_quadric_orientation"] COrientation(q: SYSTEM.ADDRESS; o: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glu_quadric_texture"] CTexture(q: SYSTEM.ADDRESS; on: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glu_cylinder"] CCylinder(q: SYSTEM.ADDRESS; base, top, height: LONGREAL; slices, stacks: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glu_sphere"] CSphere(q: SYSTEM.ADDRESS; r: LONGREAL; slices, stacks: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glu_disk"] CDisk(q: SYSTEM.ADDRESS; inner, outer: LONGREAL; slices, loops: SYSTEM.INT32);
PROCEDURE ["C", "ofl_glu_partial_disk"] CPartialDisk(q: SYSTEM.ADDRESS; inner, outer: LONGREAL; slices, loops: SYSTEM.INT32; start, sweep: LONGREAL);

(* The view *)

(* A projection of the field of view fovy, in degrees, up and down; aspect
   is the view's width over its height. *)
PROCEDURE Perspective*(fovy, aspect, near, far: LONGREAL);
BEGIN CPerspective(fovy, aspect, near, far)
END Perspective;

(* Looks from the eye ex, ey, ez at the centre cx, cy, cz, with ux, uy, uz
   up. *)
PROCEDURE LookAt*(ex, ey, ez, cx, cy, cz, ux, uy, uz: LONGREAL);
BEGIN CLookAt(ex, ey, ez, cx, cy, cz, ux, uy, uz)
END LookAt;

PROCEDURE Ortho2D*(left, right, bottom, top: LONGREAL);
BEGIN COrtho2D(left, right, bottom, top)
END Ortho2D;

(* Narrows the projection to a w by h region about x, y, in the window's
   pixels from the bottom, of viewport, as FlGl.GetInteger(ViewportArea)
   gives it: for picking with FlGl's Select mode. GLU does nothing if w or
   h isn't above 0. *)
PROCEDURE PickMatrix*(x, y, w, h: LONGREAL; viewport-: ARRAY OF INTEGER);
BEGIN
  ASSERT(LEN(viewport) >= 4, Fl.IndexOutOfRange);
  CPickMatrix(x, y, w, h, SYSTEM.ADR(viewport))
END PickMatrix;

(* Quadrics *)

(* A new quadric, drawn Fill, with NormalsSmooth, Outside, and no texture
   coordinates; NIL if GLU has no memory for it. *)
PROCEDURE NewQuadric*(): Quadric;
  VAR q: Quadric; h: SYSTEM.ADDRESS;
BEGIN
  h := CNewQuadric();
  IF h = 0 THEN RETURN NIL END;
  NEW(q); q.h := h; RETURN q
END NewQuadric;

PROCEDURE (q: Quadric) Close*;
BEGIN
  IF q.h # 0 THEN CDeleteQuadric(q.h); q.h := 0 END
END Close;

PROCEDURE (q: Quadric) IsOpen*(): BOOLEAN;
BEGIN RETURN q.h # 0
END IsOpen;

PROCEDURE Check(q: Quadric);
BEGIN ASSERT(q.h # 0, Fl.ClosedResource)
END Check;

PROCEDURE CheckCounts(a, b: INTEGER);
BEGIN ASSERT((a >= 1) & (b >= 1), Fl.IndexOutOfRange)
END CheckCounts;

(* style is Fill, Line, Silhouette or Point. *)
PROCEDURE (q: Quadric) DrawStyle*(style: INTEGER);
BEGIN
  Check(q);
  ASSERT((style = Fill) OR (style = Line) OR (style = Silhouette) OR (style = Point), Fl.Unsupported);
  CDrawStyle(q.h, style)
END DrawStyle;

(* normals is NormalsNone, NormalsFlat or NormalsSmooth. *)
PROCEDURE (q: Quadric) Normals*(normals: INTEGER);
BEGIN
  Check(q);
  ASSERT((normals = NormalsNone) OR (normals = NormalsFlat) OR (normals = NormalsSmooth), Fl.Unsupported);
  CNormals(q.h, normals)
END Normals;

(* Outside or Inside: which way the normals point. *)
PROCEDURE (q: Quadric) Orientation*(o: INTEGER);
BEGIN
  Check(q);
  ASSERT((o = Outside) OR (o = Inside), Fl.Unsupported);
  COrientation(q.h, o)
END Orientation;

(* Whether its shapes have texture coordinates. *)
PROCEDURE (q: Quadric) Texture*(on: BOOLEAN);
BEGIN
  Check(q);
  IF on THEN CTexture(q.h, 1) ELSE CTexture(q.h, 0) END
END Texture;

(* A cylinder along z from 0 to height, of radius base at 0 and top at
   height. slices, around z, and stacks, along it, are at least 1. *)
PROCEDURE (q: Quadric) Cylinder*(base, top, height: LONGREAL; slices, stacks: INTEGER);
BEGIN
  Check(q); CheckCounts(slices, stacks);
  CCylinder(q.h, base, top, height, slices, stacks)
END Cylinder;

PROCEDURE (q: Quadric) Sphere*(radius: LONGREAL; slices, stacks: INTEGER);
BEGIN
  Check(q); CheckCounts(slices, stacks);
  CSphere(q.h, radius, slices, stacks)
END Sphere;

(* A disk at z 0, with a hole of radius inner; loops are rings about it. *)
PROCEDURE (q: Quadric) Disk*(inner, outer: LONGREAL; slices, loops: INTEGER);
BEGIN
  Check(q); CheckCounts(slices, loops);
  CDisk(q.h, inner, outer, slices, loops)
END Disk;

(* The part of a disk from start degrees clockwise from y, through sweep. *)
PROCEDURE (q: Quadric) PartialDisk*(inner, outer: LONGREAL; slices, loops: INTEGER; start, sweep: LONGREAL);
BEGIN
  Check(q); CheckCounts(slices, loops);
  CPartialDisk(q.h, inner, outer, slices, loops, start, sweep)
END PartialDisk;

END FlGlu.
