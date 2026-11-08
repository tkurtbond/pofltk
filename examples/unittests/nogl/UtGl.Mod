MODULE UtGl; (* Unittests' OpenGL windows, where FLTK hasn't GL *)

(* ../gl/UtGl.Mod's interface, for an FLTK without GL: the pages leave
   their OpenGL tests out, as FLTK's do without HAVE_GL. *)

IMPORT Fl;

CONST Have* = FALSE;

TYPE Paint* = PROCEDURE (w: Fl.Widget);

PROCEDURE Open*(x, y, w, h: INTEGER; paint: Paint; widgets: BOOLEAN): Fl.Widget;
BEGIN HALT(99)
END Open;

PROCEDURE UseHighRes*;
END UseHighRes;

END UtGl.
