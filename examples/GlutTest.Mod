MODULE GlutTest; (* FLTK's test/glut_test.cxx: calls GLUT's functions with a current window and without one *)

(* It shows nothing and waits for nothing. FLTK's program calls each function
   twice, the second time with no current window, when each must do nothing.
   Two things differ, since FlGlut halts on what FLTK lets pass: the menu it
   attaches is a real one, and with no current window there is nothing to
   destroy. *)

IMPORT FlGlut, Out;

VAR
  win1, win2, current, i: INTEGER;

PROCEDURE Show(name-: ARRAY OF CHAR; value: INTEGER);
BEGIN Out.String(name); Out.String(" = "); Out.Int(value, 0); Out.Ln
END Show;

PROCEDURE DisplayFunc;
END DisplayFunc;

PROCEDURE ReshapeFunc(w, h: INTEGER);
END ReshapeFunc;

PROCEDURE KeyboardFunc(key: CHAR; x, y: INTEGER);
END KeyboardFunc;

PROCEDURE MouseFunc(b, state, x, y: INTEGER);
END MouseFunc;

PROCEDURE MotionFunc(x, y: INTEGER);
END MotionFunc;

PROCEDURE PassiveMotionFunc(x, y: INTEGER);
END PassiveMotionFunc;

PROCEDURE EntryFunc(s: INTEGER);
END EntryFunc;

PROCEDURE VisibilityFunc(s: INTEGER);
END VisibilityFunc;

PROCEDURE IdleFunc;
END IdleFunc;

PROCEDURE TimerFunc(value: INTEGER);
END TimerFunc;

PROCEDURE MenuStateFunc(state: INTEGER);
END MenuStateFunc;

PROCEDURE MenuStatusFunc(status, x, y: INTEGER);
END MenuStatusFunc;

PROCEDURE SpecialFunc(key, x, y: INTEGER);
END SpecialFunc;

PROCEDURE OverlayDisplayFunc;
END OverlayDisplayFunc;

PROCEDURE MenuFunc(value: INTEGER);
END MenuFunc;

BEGIN
  FlGlut.Init;

  win1 := FlGlut.CreateWindow("Window 1");
  win2 := FlGlut.CreateWindow("Window 2");
  Out.String("Window 1 created, number = "); Out.Int(win1, 0); Out.Ln;
  Out.String("Window 2 created, number = "); Out.Int(win2, 0); Out.Ln;

  i := FlGlut.CreateMenu(MenuFunc);
  FlGlut.AddMenuEntry("Item", 1);

  (* first with a current window, then without *)
  FOR i := 0 TO 1 DO
    current := FlGlut.GetWindow();
    Out.String("Window "); Out.Int(current, 0); Out.String(" is current"); Out.Ln;

    FlGlut.PostRedisplay;
    FlGlut.SetWindowTitle("Non-existent");
    FlGlut.SetIconTitle("Non-existent");
    FlGlut.PositionWindow(10, 20);
    FlGlut.ReshapeWindow(100, 200);
    FlGlut.PopWindow;
    FlGlut.IconifyWindow;
    FlGlut.ShowWindow;
    FlGlut.HideWindow;
    FlGlut.FullScreen;
    FlGlut.SetCursor(FlGlut.CursorInfo);

    FlGlut.EstablishOverlay;
    FlGlut.RemoveOverlay;
    FlGlut.UseLayer(FlGlut.Normal);
    FlGlut.UseLayer(FlGlut.Overlay);
    FlGlut.PostOverlayRedisplay;
    FlGlut.ShowOverlay;
    FlGlut.HideOverlay;

    FlGlut.AttachMenu(FlGlut.LeftButton);
    FlGlut.DetachMenu(FlGlut.LeftButton);

    FlGlut.DisplayFunc(DisplayFunc);
    FlGlut.ReshapeFunc(ReshapeFunc);
    FlGlut.KeyboardFunc(KeyboardFunc);
    FlGlut.MouseFunc(MouseFunc);
    FlGlut.MotionFunc(MotionFunc);
    FlGlut.PassiveMotionFunc(PassiveMotionFunc);
    FlGlut.EntryFunc(EntryFunc);
    FlGlut.VisibilityFunc(VisibilityFunc);
    FlGlut.IdleFunc(IdleFunc);
    FlGlut.TimerFunc(1000, TimerFunc, 42);
    FlGlut.MenuStateFunc(MenuStateFunc);
    FlGlut.MenuStatusFunc(MenuStatusFunc);
    FlGlut.SpecialFunc(SpecialFunc);
    FlGlut.OverlayDisplayFunc(OverlayDisplayFunc);

    FlGlut.SwapBuffers;

    Show("GLUT_WINDOW_X", FlGlut.Get(FlGlut.GetWindowX));
    Show("GLUT_WINDOW_Y", FlGlut.Get(FlGlut.GetWindowY));
    Show("GLUT_WINDOW_WIDTH", FlGlut.Get(FlGlut.GetWindowWidth));
    Show("GLUT_WINDOW_HEIGHT", FlGlut.Get(FlGlut.GetWindowHeight));
    Show("GLUT_WINDOW_PARENT", FlGlut.Get(FlGlut.GetWindowParent));
    Show("GLUT_OVERLAY_POSSIBLE", FlGlut.LayerGet(FlGlut.OverlayPossible));
    Show("GLUT_NORMAL_DAMAGED", FlGlut.LayerGet(FlGlut.NormalDamaged));

    Out.String("Destroy the current window ("); Out.Int(FlGlut.GetWindow(), 0); Out.String(")");
    Out.Ln; Out.Ln;
    IF current # 0 THEN FlGlut.DestroyWindow(current) END
  END;

  Out.String("All tests done, exiting."); Out.Ln
END GlutTest.
