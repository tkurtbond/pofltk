MODULE OpenGL3GlutTest; (* FLTK's examples/OpenGL3-glut-test.cxx: two triangles drawn by OpenGL 3 shaders, through GLUT *)

(* The shaders are in GlThree, in C++, which also has GLEW. *)

IMPORT FlDialogs, FlGl, FlGlut, GlThree, OutStr;

VAR
  s: ARRAY 256 OF CHAR;
  version: ARRAY 128 OF CHAR;
  win: INTEGER;

PROCEDURE Display;
BEGIN GlThree.DrawTriangles
END Display;

BEGIN
  FlGl.UseHighRes(TRUE);
  FlGlut.Init;
  FlGlut.InitDisplayMode(FlGlut.Double + FlGlut.Rgba + FlGl.OpenGL3);
  FlGlut.InitWindowSize(400, 400);
  win := FlGlut.CreateWindow("Triangle Test");

  IF GlThree.InitGlew() THEN END;
  GlThree.GlewVersion(version);
  s := "Status: Using GLEW ";
  OutStr.String(version, s); OutStr.Ln(s);
  GlThree.Err(s);

  FlGl.Version(version);
  s := "OpenGL version ";
  OutStr.String(version, s); OutStr.String(" supported", s); OutStr.Ln(s);
  GlThree.Err(s);

  IF GlThree.GlMajor() < 3 THEN
    s := "";
    OutStr.Ln(s); OutStr.String("This platform does not support OpenGL V3", s); OutStr.Ln(s); OutStr.Ln(s);
    GlThree.Err(s);
    s := "OpenGL version ";
    OutStr.String(version, s); OutStr.String(" supported.", s); OutStr.Ln(s);
    OutStr.String("This platform does not support OpenGL V3!", s);
    FlDialogs.Alert(s);
    HALT(1)
  END;

  GlThree.MakeTriangles;
  FlGlut.DisplayFunc(Display);
  FlGlut.MainLoop
END OpenGL3GlutTest.
