MODULE UtGl; (* Unittests' OpenGL windows, where FLTK has GL *)

(* The OpenGL windows of Unittests' pages, which draw with FlDraw, as
   their native windows do. Unittests is built with this module where
   FLTK has GL, and with ../nogl/UtGl.Mod where it hasn't (the
   makefile's import path), as FLTK's has HAVE_GL. *)

IMPORT Fl, FlDraw, FlGl;

CONST Have* = TRUE;

TYPE
  (* Draws a test in w, its origin at w's top left. *)
  Paint* = PROCEDURE (w: Fl.Widget);

  Window = POINTER TO RECORD (FlGl.GlWindowDesc)
    paint: Paint;
    widgets: BOOLEAN  (* draws its box and widgets, not its color *)
  END;

PROCEDURE (w: Window) Draw*;
BEGIN
  w.DrawBegin;
  IF w.widgets THEN w.DrawWindow
  ELSE FlDraw.SetColor(w.Color()); FlDraw.RectF(0, 0, w.W(), w.H())
  END;
  w.paint(w);
  w.DrawEnd
END Draw;

(* A flat GL window that draws with paint, after its box and widgets if
   widgets is TRUE, or after filling itself with its color. *)
PROCEDURE Open*(x, y, w, h: INTEGER; paint: Paint; widgets: BOOLEAN): Fl.Widget;
  VAR win: Window;
BEGIN
  NEW(win); FlGl.OpenGlWindowAt(win, x, y, w, h, "");
  win.paint := paint; win.widgets := widgets;
  win.SetBoxType(Fl.FlatBox);
  win.End;
  RETURN win
END Open;

(* Lets GL windows use a high-resolution display's every pixel. *)
PROCEDURE UseHighRes*;
BEGIN FlGl.UseHighRes(TRUE)
END UseHighRes;

END UtGl.
