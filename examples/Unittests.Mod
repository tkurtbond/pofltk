MODULE Unittests; (* FLTK's test/unittests.cxx in Oberon-2 *)

(* A window of test pages, chosen from a browser: each page is a module
   of examples/unittests, as each is a file of FLTK's. The core page's
   tests can run on their own, with no window (Unittests --core), and
   then the program's status is the number failed. The makefile builds it
   with unittests/gl's UtGl where FLTK has GL, and unittests/nogl's where
   it hasn't. *)

IMPORT Args, Err, Platform, Fl, FlBrowsers, FlDialogs, FlDraw, Ut, UtGl,
  UtAbout, UtPoints, UtFastShapes, UtCircles, UtComplexShapes, UtText,
  UtUnicode, UtSymbol, UtImages, UtViewport, UtScrollbarSize, UtSchemes,
  UtTerminal, UtCore;

CONST
  NPages = 14;
  Sze = 16;  (* an alignment mark's size *)

TYPE
  (* Draws marks at its corners for the viewport page: a red line just
     outside the window, a green one just inside, and a box. *)
  MainWindow = POINTER TO RECORD (Fl.DoubleWindowDesc)
    alignment: BOOLEAN
  END;

VAR
  win: MainWindow;
  browser: FlBrowsers.HoldBrowser;
  pages: ARRAY NPages OF Fl.Widget;
  coreOnly: BOOLEAN;

PROCEDURE Box(x, y: INTEGER);
BEGIN
  FlDraw.SetColor(Fl.White); FlDraw.RectF(x, y, Sze - 2, Sze - 2);
  FlDraw.SetColor(Fl.Black); FlDraw.Rect(x, y, Sze - 2, Sze - 2)
END Box;

PROCEDURE (w: MainWindow) Draw*;
  VAR ww, h: INTEGER;
BEGIN
  w.Draw^;
  IF w.alignment THEN
    ww := w.W(); h := w.H();
    (* top left *)
    FlDraw.SetColor(Fl.Green); FlDraw.YXLine2(0, Sze, 0, Sze);
    FlDraw.SetColor(Fl.Red); FlDraw.YXLine2(-1, Sze, -1, Sze);
    Box(3, 3);
    (* bottom left *)
    FlDraw.SetColor(Fl.Green); FlDraw.YXLine2(0, h - Sze - 1, h - 1, Sze);
    FlDraw.SetColor(Fl.Red); FlDraw.YXLine2(-1, h - Sze - 1, h, Sze);
    Box(3, h - Sze - 1);
    (* bottom right *)
    FlDraw.SetColor(Fl.Green); FlDraw.YXLine2(ww - 1, h - Sze - 1, h - 1, ww - Sze - 1);
    FlDraw.SetColor(Fl.Red); FlDraw.YXLine2(ww, h - Sze - 1, h, ww - Sze - 1);
    Box(ww - Sze - 1, h - Sze - 1);
    (* top right *)
    FlDraw.SetColor(Fl.Green); FlDraw.YXLine2(ww - 1, Sze, 0, ww - Sze - 1);
    FlDraw.SetColor(Fl.Red); FlDraw.YXLine2(ww, Sze, -1, ww - Sze - 1);
    Box(ww - Sze - 1, 3)
  END
END Draw;

PROCEDURE TestAlignment(on: BOOLEAN);
BEGIN win.alignment := on; win.Redraw
END TestAlignment;

(* Shows the page chosen, and hides the rest. *)
PROCEDURE Choose(w: Fl.Widget);
  VAR i: INTEGER;
BEGIN
  FOR i := 0 TO NPages - 1 DO
    IF browser.Selected(i + 1) THEN pages[i].Show ELSE pages[i].Hide END
  END
END Choose;

PROCEDURE Arg(i: INTEGER): INTEGER;
  VAR s: ARRAY 16 OF CHAR;
BEGIN
  Args.Get(i, s);
  IF s = "--core" THEN coreOnly := TRUE; RETURN 1
  ELSIF s = "--color=0" THEN UtCore.Color(FALSE); RETURN 1
  ELSIF s = "--color=1" THEN UtCore.Color(TRUE); RETURN 1
  END;
  RETURN 0
END Arg;

PROCEDURE Usage;
  VAR s, name: ARRAY 256 OF CHAR;
BEGIN
  Args.Get(0, s); FlDialogs.FilenameName(s, name);
  IF name = "" THEN name := "unittests" END;
  Err.String("usage: "); Err.String(name); Err.String(" <switches>"); Err.Ln;
  Err.String(" --core : test core functionality only"); Err.Ln;
  (* FLTK's text has no line feed here *)
  Err.String(" --color=1, --color=0 : print test output in color or plain text");
  Err.String(" --help, -h : print this help page"); Err.Ln;
  HALT(1)
END Usage;

PROCEDURE Add(w: Fl.Widget; label: ARRAY OF CHAR; VAR n: INTEGER);
BEGIN
  w.Hide; pages[n] := w; INC(n);
  browser.Add(label)
END Add;

PROCEDURE Main;
  VAR i, n: INTEGER; scheme: ARRAY 32 OF CHAR;
BEGIN
  i := 1;
  IF ~Fl.ParseArgs(Arg, i) THEN Usage END;
  IF coreOnly THEN
    n := UtCore.RunAll();
    IF n > 0 THEN Platform.Exit(n) END;
    RETURN
  END;
  Fl.GetSystemColors;
  Fl.GetScheme(scheme); IF Fl.SetScheme(scheme) THEN END;
  IF Fl.Visual(Fl.VisualRgb) THEN END;
  UtGl.UseHighRes;
  NEW(win); Fl.OpenDoubleWindow(win, Ut.MainW, Ut.MainH, "FLTK Unit Tests");
  win.SizeRange(Ut.MainW, Ut.MainH, 0, 0);
  Ut.testAlignment := TestAlignment;
  NEW(browser);
  FlBrowsers.OpenHoldBrowser(browser, Ut.BrowserX, Ut.BrowserY, Ut.BrowserW, Ut.BrowserH, "Unit Tests");
  browser.SetAlign(Fl.AlignTop + Fl.AlignLeft);
  browser.SetWhen(Fl.WhenChanged);
  browser.action := Choose;
  browser.SetLineSpacing(2);
  n := 0;
  Add(UtAbout.Create(), UtAbout.Label, n);
  Add(UtPoints.Create(), UtPoints.Label, n);
  Add(UtFastShapes.Create(), UtFastShapes.Label, n);
  Add(UtCircles.Create(), UtCircles.Label, n);
  Add(UtComplexShapes.Create(), UtComplexShapes.Label, n);
  Add(UtText.Create(), UtText.Label, n);
  Add(UtUnicode.Create(), UtUnicode.Label, n);
  Add(UtSymbol.Create(), UtSymbol.Label, n);
  Add(UtImages.Create(), UtImages.Label, n);
  Add(UtViewport.Create(), UtViewport.Label, n);
  Add(UtScrollbarSize.Create(), UtScrollbarSize.Label, n);
  Add(UtSchemes.Create(), UtSchemes.Label, n);
  Add(UtTerminal.Create(), UtTerminal.Label, n);
  Add(UtCore.Create(), UtCore.Label, n);
  win.End;
  win.SetResizable(win);
  win.ShowArgs;
  IF browser.Select(1, TRUE) THEN END;
  Choose(browser);
  Fl.Run
END Main;

BEGIN Main
END Unittests.
