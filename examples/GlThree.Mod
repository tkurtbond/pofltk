MODULE GlThree; (* For the examples: GLEW, and the OpenGL 3 code of FLTK's two examples *)

(* OpenGL 3's shaders aren't in FlGl, which binds the part of GL that FLTK's
   other programs use, and only GLEW's loader reaches them on most systems:
   so they stay here, in C++, the examples' own as test/Probe is the tests'.
   Its C++ part is GlThree.cpp. Each of these takes a current context. *)

IMPORT FlGl, SYSTEM;

PROCEDURE ["C", "ofl_gl3_glew_init"] CGlewInit(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl3_glew_version"] CGlewVersion(VAR s: ARRAY OF CHAR; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl3_err"] CErr(s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_gl3_has_quad"] CHasQuad(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_gl3_make_quad"] CMakeQuad(VAR log: ARRAY OF CHAR; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_gl3_draw_quad"] CDrawQuad;
PROCEDURE ["C", "ofl_gl3_push_quad"] CPushQuad;
PROCEDURE ["C", "ofl_gl3_reset_quad"] CResetQuad;
PROCEDURE ["C", "ofl_gl3_make_triangles"] CMakeTriangles;
PROCEDURE ["C", "ofl_gl3_draw_triangles"] CDrawTriangles;

(* Loads GL's functions; FALSE, with a warning from FLTK, if it can't. *)
PROCEDURE InitGlew*(): BOOLEAN;
BEGIN RETURN CGlewInit() # 0
END InitGlew;

PROCEDURE GlewVersion*(VAR s: ARRAY OF CHAR);
BEGIN CGlewVersion(s, SHORT(LEN(s)))
END GlewVersion;

(* The major version of GL's version string. *)
PROCEDURE GlMajor*(): INTEGER;
  VAR s: ARRAY 128 OF CHAR; i, major: INTEGER;
BEGIN
  FlGl.Version(s);
  i := 0; major := 0;
  WHILE (s[i] >= "0") & (s[i] <= "9") DO
    major := 10 * major + ORD(s[i]) - ORD("0"); INC(i)
  END;
  RETURN major
END GlMajor;

(* To standard error, as FLTK's programs report. *)
PROCEDURE Err*(s-: ARRAY OF CHAR);
BEGIN CErr(s)
END Err;

PROCEDURE HasQuad*(): BOOLEAN;
BEGIN RETURN CHasQuad() # 0
END HasQuad;

(* Makes OpenGL3test's shaders and quad; log is its messages. *)
PROCEDURE MakeQuad*(VAR log: ARRAY OF CHAR);
BEGIN CMakeQuad(log, SHORT(LEN(log)))
END MakeQuad;

PROCEDURE DrawQuad*;
BEGIN CDrawQuad
END DrawQuad;

(* Reshapes the quad, as a click on it does. *)
PROCEDURE PushQuad*;
BEGIN CPushQuad
END PushQuad;

(* Forgets the quad, before its window's context goes. *)
PROCEDURE ResetQuad*;
BEGIN CResetQuad
END ResetQuad;

(* Makes OpenGL3-glut-test's shaders and triangles. *)
PROCEDURE MakeTriangles*;
BEGIN CMakeTriangles
END MakeTriangles;

PROCEDURE DrawTriangles*;
BEGIN CDrawTriangles
END DrawTriangles;

END GlThree.
