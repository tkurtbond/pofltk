MODULE TestGlu; (* FlGlu: GLU's view matrices and quadrics *)

IMPORT Fl, FlGl, FlGlu, Check;

CONST Limit = 500; (* of waits, so that valgrind has time *)

TYPE
  (* A window whose first draw makes the checks. *)
  View = POINTER TO RECORD (FlGl.GlWindowDesc)
    draws: INTEGER
  END;

VAR
  view: View;
  q: FlGlu.Quadric;
  before: INTEGER;

(* Whether the pixel at x, y, of the window's pixels from the bottom
   left, is grey g. *)
PROCEDURE Grey(x, y, g: INTEGER): BOOLEAN;
  VAR p: ARRAY 4 OF CHAR;
BEGIN
  FlGl.Flush;
  FlGl.ReadPixels(x, y, 1, 1, p);
  RETURN (ORD(p[0]) = g) & (ORD(p[1]) = g) & (ORD(p[2]) = g)
END Grey;

PROCEDURE Black;
BEGIN
  FlGl.ClearColor(0.0, 0.0, 0.0, 1.0);
  FlGl.Clear(FlGl.ColorBufferBit)
END Black;

PROCEDURE Near(a, b: REAL): BOOLEAN;
BEGIN RETURN ABS(a - b) < 0.0001
END Near;

PROCEDURE Identity;
BEGIN
  FlGl.MatrixMode(FlGl.Projection); FlGl.LoadIdentity;
  FlGl.MatrixMode(FlGl.Modelview); FlGl.LoadIdentity
END Identity;

PROCEDURE Matrices(w: View);
  VAR m: ARRAY 16 OF REAL; vp: ARRAY 4 OF INTEGER;
BEGIN
  FlGl.MatrixMode(FlGl.Projection); FlGl.LoadIdentity;
  (* 90 degrees: the focal length is 1 *)
  FlGlu.Perspective(90.0D0, 1.0D0, 1.0D0, 3.0D0);
  Check.Check(FlGl.GetFloat(FlGl.ProjectionMatrix, m)
    & Near(m[0], 1.0) & Near(m[5], 1.0) & Near(m[10], -2.0) & Near(m[11], -1.0)
    & Near(m[14], -3.0) & Near(m[15], 0.0), "Perspective");
  FlGl.LoadIdentity;
  FlGlu.Ortho2D(0.0D0, 2.0D0, 0.0D0, 4.0D0);
  Check.Check(FlGl.GetFloat(FlGl.ProjectionMatrix, m)
    & Near(m[0], 1.0) & Near(m[5], 0.5) & Near(m[10], -1.0)
    & Near(m[12], -1.0) & Near(m[13], -1.0), "Ortho2D");
  Check.Check(FlGl.GetInteger(FlGl.ViewportArea, vp) & (vp[2] = w.PixelW()), "the viewport");
  FlGl.LoadIdentity;
  (* the right half of the view, its centre at the view's three quarters *)
  FlGlu.PickMatrix(vp[2] * 3 DIV 4, vp[3] DIV 2, vp[2] DIV 2, vp[3], vp);
  Check.Check(FlGl.GetFloat(FlGl.ProjectionMatrix, m)
    & Near(m[0], 2.0) & Near(m[5], 1.0) & Near(m[12], -1.0) & Near(m[13], 0.0), "PickMatrix");
  FlGl.MatrixMode(FlGl.Modelview); FlGl.LoadIdentity;
  FlGlu.LookAt(0.0D0, 0.0D0, 5.0D0, 0.0D0, 0.0D0, 0.0D0, 0.0D0, 1.0D0, 0.0D0);
  Check.Check(FlGl.GetFloat(FlGl.ModelviewMatrix, m)
    & Near(m[0], 1.0) & Near(m[5], 1.0) & Near(m[10], 1.0) & Near(m[14], -5.0), "LookAt, along z");
  FlGl.LoadIdentity;
  FlGlu.LookAt(5.0D0, 0.0D0, 0.0D0, 0.0D0, 0.0D0, 0.0D0, 0.0D0, 1.0D0, 0.0D0);
  Check.Check(FlGl.GetFloat(FlGl.ModelviewMatrix, m)
    & Near(m[0], 0.0) & Near(m[8], -1.0) & Near(m[2], 1.0) & Near(m[14], -5.0), "LookAt, along x");
  Identity
END Matrices;

PROCEDURE Quadrics(w: View);
  VAR c, lo, hi: INTEGER;
BEGIN
  c := w.PixelW() DIV 2; lo := w.PixelW() DIV 4; hi := w.PixelW() * 3 DIV 4;
  q := FlGlu.NewQuadric();
  Check.Check((q # NIL) & q.IsOpen(), "a quadric");
  FlGl.Color3f(1.0, 1.0, 1.0);
  Black;
  q.Sphere(0.5D0, 16, 8);
  Check.Check(Grey(c, c, 255) & Grey(1, 1, 0), "a sphere");
  Black;
  q.Disk(0.25D0, 1.0D0, 16, 2);
  Check.Check(Grey(c, c, 0) & Grey(lo, c, 255), "a disk, with a hole");
  Black;
  (* from y, clockwise, through 90 degrees: the top right quarter *)
  q.PartialDisk(0.0D0, 1.0D0, 16, 1, 0.0D0, 90.0D0);
  Check.Check(Grey(hi, hi, 255) & Grey(lo, lo, 0) & Grey(lo, hi, 0), "a partial disk");
  Black;
  (* along z, seen end on: a ring, with no ends *)
  q.Cylinder(0.5D0, 0.5D0, 0.5D0, 16, 1);
  Check.Check(Grey(c, c, 0), "a cylinder has no ends");
  Black;
  q.Cylinder(0.0D0, 0.9D0, 0.5D0, 16, 1);
  Check.Check(Grey(c, c, 255), "a cone, seen from its point");
  Black;
  q.DrawStyle(FlGlu.Point);
  q.Disk(0.0D0, 1.0D0, 4, 1);
  Check.Check(Grey(lo, c + 1, 0), "points");
  q.DrawStyle(FlGlu.Line); q.Sphere(0.5D0, 4, 4);
  q.DrawStyle(FlGlu.Silhouette); q.Disk(0.0D0, 0.5D0, 4, 4);
  q.DrawStyle(FlGlu.Fill);
  q.Normals(FlGlu.NormalsNone); q.Sphere(0.5D0, 4, 4);
  q.Normals(FlGlu.NormalsFlat); q.Sphere(0.5D0, 4, 4);
  q.Normals(FlGlu.NormalsSmooth);
  q.Orientation(FlGlu.Inside); q.Sphere(0.5D0, 4, 4);
  q.Orientation(FlGlu.Outside);
  q.Texture(TRUE); q.Sphere(0.5D0, 4, 4); q.Texture(FALSE);
  Check.Check(FlGl.GetError() = FlGl.NoError, "the styles, without an error");
  q.Close;
  Check.Check(~q.IsOpen(), "closed");
  q.Close;
  Check.Check(~q.IsOpen(), "closed twice")
END Quadrics;

PROCEDURE (w: View) Draw*;
BEGIN
  INC(w.draws);
  IF w.draws = 1 THEN
    FlGl.Viewport(0, 0, w.PixelW(), w.PixelH());
    Identity;
    Matrices(w);
    Quadrics(w)
  END
END Draw;

BEGIN
  NEW(view);
  FlGl.OpenGlWindow(view, 40, 40, "");
  view.End;
  view.Show;
  before := 0;
  WHILE (view.draws = 0) & (before < Limit) DO Fl.Wait(0.02D0); INC(before) END;
  Check.Check(view.draws > 0, "the window draws");
  view.Delete;
  Check.Summary
END TestGlu.
