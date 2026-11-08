MODULE Subwindow; (* FLTK's test/subwindow.cxx in Oberon-2 *)

(* A window inside a window, each with its own toggle button, inputs, menu
   button and a box that turns red while the mouse is in it; the inner
   window shows a hand pointer, and takes the focus when clicked. A
   right click anywhere pops up a menu. FLTK's DEBUG and DEBUG_POS
   printing and drawing are left out, as FLTK's build leaves them. *)

IMPORT Fl, FlButtons, FlInputs, FlMenus;

TYPE
  (* A box that is red while the mouse is in it. *)
  EnterExit = POINTER TO RECORD (Fl.BoxDesc) END;

  (* FLTK's testwindow: a window that takes the focus when clicked, and
     keeps the last character typed in it, where and what. *)
  TestWindow = POINTER TO RECORD (Fl.WindowDesc)
    cx, cy: INTEGER; key: CHAR;
    crsr: INTEGER
  END;

CONST
  bigmess = "this|is|only|a test";

VAR
  window, subwindow: TestWindow;
  popup: FlMenus.MenuButton;

PROCEDURE (b: EnterExit) Handle*(event: INTEGER): BOOLEAN;
BEGIN
  IF event = Fl.EvEnter THEN b.SetColor(Fl.Red); b.Redraw; RETURN TRUE
  ELSIF event = Fl.EvLeave THEN b.SetColor(Fl.Gray); b.Redraw; RETURN TRUE
  ELSE RETURN FALSE
  END
END Handle;

PROCEDURE NewEnterExit(x, y, w, h: INTEGER; label: ARRAY OF CHAR);
  VAR b: EnterExit;
BEGIN
  NEW(b); Fl.OpenBox(b, x, y, w, h, label); b.SetBoxType(Fl.BorderBox)
END NewEnterExit;

PROCEDURE (w: TestWindow) Handle*(event: INTEGER): BOOLEAN;
  VAR text: ARRAY 8 OF CHAR;
BEGIN
  IF w.crsr # Fl.CursorDefault THEN
    IF event = Fl.EvEnter THEN w.SetCursor(w.crsr) END;
    IF event = Fl.EvLeave THEN w.SetCursor(Fl.CursorDefault) END
  END;
  IF w.Handle^(event) THEN RETURN TRUE END;
  IF event = Fl.EvFocus THEN RETURN TRUE END;
  IF event = Fl.EvPush THEN Fl.SetFocus(w); RETURN TRUE END;
  IF event = Fl.EvKeyDown THEN
    Fl.EventText(text);
    IF text[0] # 0X THEN
      IF (Fl.EventKey() = Fl.KeyEscape) OR Fl.EventCommand() THEN RETURN FALSE END;
      w.key := text[0];
      w.cx := Fl.EventX();
      w.cy := Fl.EventY();
      w.Redraw;
      RETURN TRUE
    END
  END;
  RETURN FALSE
END Handle;

(* FLTK's add of a string: each item between the "|"s. *)
PROCEDURE AddItems(m: FlMenus.Menu; s: ARRAY OF CHAR);
  VAR item: ARRAY 64 OF CHAR; i, j, n: INTEGER;
BEGIN
  i := 0;
  REPEAT
    j := 0;
    WHILE (s[i] # 0X) & (s[i] # "|") DO item[j] := s[i]; INC(i); INC(j) END;
    item[j] := 0X;
    n := m.Add(item, 0, {}, NIL, {});
    IF s[i] = "|" THEN INC(i) END
  UNTIL s[i] = 0X
END AddItems;

PROCEDURE NewMenuButton(x, y, w, h: INTEGER; label: ARRAY OF CHAR);
  VAR m: FlMenus.MenuButton;
BEGIN
  NEW(m); FlMenus.OpenMenuButton(m, x, y, w, h, label); AddItems(m, bigmess)
END NewMenuButton;

PROCEDURE NewToggle(x, y, w, h: INTEGER; label: ARRAY OF CHAR);
  VAR b: FlButtons.ToggleButton;
BEGIN NEW(b); FlButtons.OpenToggleButton(b, x, y, w, h, label)
END NewToggle;

PROCEDURE NewInput(x, y, w, h: INTEGER; label: ARRAY OF CHAR);
  VAR i: FlInputs.Input;
BEGIN NEW(i); FlInputs.OpenInput(i, x, y, w, h, label)
END NewInput;

PROCEDURE Build;
  VAR text: Fl.Box;
BEGIN
  NEW(window); Fl.OpenWindow(window, 400, 400, "outer");
  window.SetBoxType(Fl.UpBox); window.crsr := Fl.CursorDefault;
  NewToggle(310, 310, 80, 80, "&outer");
  NewEnterExit(10, 310, 80, 80, "enterexit");
  NewInput(160, 310, 140, 25, "input1:");
  NewInput(160, 340, 140, 25, "input2:");
  NewMenuButton(5, 150, 80, 25, "menu&1");
  NEW(subwindow); Fl.OpenWindowAt(subwindow, 100, 100, 200, 200, "inner");
  subwindow.SetBoxType(Fl.DownBox);
  NewToggle(110, 110, 80, 80, "&inner");
  NewEnterExit(10, 110, 80, 80, "enterexit");
  NewMenuButton(50, 20, 80, 25, "menu&2");
  NewInput(55, 50, 140, 25, "input1:");
  NewInput(55, 80, 140, 25, "input2:");
  subwindow.SetResizable(subwindow);
  window.SetResizable(subwindow);
  subwindow.End;
  subwindow.crsr := Fl.CursorHand;
  NEW(text); Fl.OpenBox(text, 0, 0, 400, 100,
    "A child Fl_Window with children of its own may be useful for imbedding controls into a GL or display that needs a different visual.  There are bugs with the origins being different between drawing and events, which I hope I have solved.");
  text.SetBoxType(Fl.NoBox);
  text.SetAlign(Fl.AlignWrap);
  NEW(popup); FlMenus.OpenMenuButton(popup, 0, 0, 400, 400, "");
  popup.SetKind(FlMenus.Popup3);
  AddItems(popup, "This|is|a popup|menu");
  AddItems(popup, bigmess);
  window.End
END Build;

BEGIN
  Build;
  window.ShowArgs;
  Fl.Run
END Subwindow.
