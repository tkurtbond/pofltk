MODULE CursorTest; (* FLTK's test/cursor.cxx: FLTK's standard cursors, by name or number, and one of the program's *)

IMPORT Fl, FlDraw, FlImages, FlMenus, FlValuators;

VAR
  win: Fl.DoubleWindow;
  choice: FlMenus.Choice;
  slider: FlValuators.ValueSlider;
  cursors: ARRAY 21 OF INTEGER;
  xpm: ARRAY 39 OF ARRAY 40 OF CHAR;
  n: INTEGER;
  ok: BOOLEAN;

PROCEDURE ChoiceCB(w: Fl.Widget);
BEGIN
  slider.SetValue(cursors[choice.Value()]);
  FlDraw.Cursor(cursors[choice.Value()])
END ChoiceCB;

PROCEDURE CustomCB(w: Fl.Widget);
  VAR i: FlImages.Image;
BEGIN
  NEW(i); ASSERT(FlImages.OpenXPM(i, xpm, LEN(xpm)));
  i.Scale(16, 16, TRUE, FALSE);
  FlImages.SetCursor(win, i, i.W() DIV 2, i.H() DIV 2);
  i.Close
END CustomCB;

PROCEDURE SliderCB(w: Fl.Widget);
BEGIN FlDraw.Cursor(SHORT(ENTIER(slider.Value())))
END SliderCB;

PROCEDURE Item(label: ARRAY OF CHAR; cursor: INTEGER);
BEGIN
  cursors[n] := cursor;
  n := choice.Add(label, 0, {}, ChoiceCB, {}) + 1
END Item;

BEGIN
  xpm[0] := "32 32 6 1";
  xpm[1] := "- c #000";
  xpm[2] := "= c #444";
  xpm[3] := "c c none";
  xpm[4] := "d c #cccccc";
  xpm[5] := ". c #888";
  xpm[6] := ", c #888";
  xpm[7] := "cccccccccccccccccccccccccccccccc";
  xpm[8] := "cccccccccccccccccccccccccccccccc";
  xpm[9] := "ccccccc==================ccccccc";
  xpm[10] := "cccccccc================cccccccc";
  xpm[11] := "ccccccccc==============ccccccccc";
  xpm[12] := "cccccccccc============cccccccccc";
  xpm[13] := "ccccccccccc==========ccccccccccc";
  xpm[14] := "cccccccccccc========cccccccccccc";
  xpm[15] := "ccccccccccccc======ccccccccccccc";
  xpm[16] := "cccccccccccccc====cccccccccccccc";
  xpm[17] := "cc==.cccccccccc==ccccccccccc==cc";
  xpm[18] := "cc.====..cccccccccccccc..====.cc";
  xpm[19] := "cccc.======================.cccc";
  xpm[20] := "cccccccc..============..cccccccc";
  xpm[21] := "cccccccccccccccccccccccccccccccc";
  xpm[22] := "cccccccccccccccccccccccccccccccc";
  xpm[23] := "cccccccc..============..cccccccc";
  xpm[24] := "cccc.======================.cccc";
  xpm[25] := "cc.====..cccccccccccccc..====.cc";
  xpm[26] := "cc==.cccccccccc==ccccccccccc==cc";
  xpm[27] := "cccccccccccccc====cccccccccccccc";
  xpm[28] := "ccccccccccccc======ccccccccccccc";
  xpm[29] := "cccccccccccc========cccccccccccc";
  xpm[30] := "ccccccccccc==========ccccccccccc";
  xpm[31] := "cccccccccc============cccccccccc";
  xpm[32] := "ccccccccc==============ccccccccc";
  xpm[33] := "cccccccc================cccccccc";
  xpm[34] := "ccccccc==================ccccccc";
  xpm[35] := "cccccccccccccccccccccccccccccccc";
  xpm[36] := "cccccccccccccccccccccccccccccccc";
  xpm[37] := "cccccccccccccccccccccccccccccccc";
  xpm[38] := "cccccccccccccccccccccccccccccccc";

  NEW(win); Fl.OpenDoubleWindow(win, 400, 300, "");

  NEW(choice); FlMenus.OpenChoice(choice, 80, 100, 200, 25, "Cursor:");
  n := 0;
  Item("FL_CURSOR_DEFAULT", Fl.CursorDefault);
  Item("FL_CURSOR_ARROW", Fl.CursorArrow);
  Item("FL_CURSOR_CROSS", Fl.CursorCross);
  Item("FL_CURSOR_WAIT", Fl.CursorWait);
  Item("FL_CURSOR_INSERT", Fl.CursorInsert);
  Item("FL_CURSOR_HAND", Fl.CursorHand);
  Item("FL_CURSOR_HELP", Fl.CursorHelp);
  Item("FL_CURSOR_MOVE", Fl.CursorMove);
  Item("FL_CURSOR_NS", Fl.CursorNs);
  Item("FL_CURSOR_WE", Fl.CursorWe);
  Item("FL_CURSOR_NWSE", Fl.CursorNwse);
  Item("FL_CURSOR_NESW", Fl.CursorNesw);
  Item("FL_CURSOR_N", Fl.CursorN);
  Item("FL_CURSOR_NE", Fl.CursorNe);
  Item("FL_CURSOR_E", Fl.CursorE);
  Item("FL_CURSOR_SE", Fl.CursorSe);
  Item("FL_CURSOR_S", Fl.CursorS);
  Item("FL_CURSOR_SW", Fl.CursorSw);
  Item("FL_CURSOR_W", Fl.CursorW);
  Item("FL_CURSOR_NW", Fl.CursorNw);
  Item("FL_CURSOR_NONE", Fl.CursorNone);
  n := choice.Add("custom cursor", 0, {}, CustomCB, {});
  ok := choice.SetValue(0);
  choice.SetWhen(Fl.WhenRelease + Fl.WhenNotChanged);

  NEW(slider); FlValuators.OpenHorValueSlider(slider, 80, 180, 310, 30, "Cursor:");
  slider.SetAlign(Fl.AlignLeft);
  slider.SetStep(1);
  slider.SetPrecision(0);
  slider.SetBounds(0, 255);
  slider.SetValue(0);
  slider.action := SliderCB;

  win.SetResizable(win);
  win.End;
  win.ShowArgs;
  Fl.Run
END CursorTest.
