MODULE Coordinates; (* FLTK's test/coordinates.cxx in Oberon-2 *)

(* Where a widget's x and y are measured from: two subwindows, whose
   boxes are placed relative to them, and two groups, whose boxes are
   placed relative to the main window; below them, the mouse's position
   in the main window as it moves. *)

IMPORT Fl;

TYPE
  MainWindow = POINTER TO RECORD (Fl.WindowDesc) END;

VAR
  window: MainWindow;
  messageBox: Fl.Box;

(* s with each "|" a line feed *)
PROCEDURE Lines(VAR s: ARRAY OF CHAR);
VAR i: INTEGER;
BEGIN
  i := 0; WHILE s[i] # 0X DO IF s[i] = "|" THEN s[i] := 0AX END; INC(i) END
END Lines;

(* Appends t to s. *)
PROCEDURE Cat(t-: ARRAY OF CHAR; VAR s: ARRAY OF CHAR);
  VAR i, j: INTEGER;
BEGIN
  i := 0; WHILE s[i] # 0X DO INC(i) END;
  j := 0; WHILE t[j] # 0X DO s[i] := t[j]; INC(i); INC(j) END;
  s[i] := 0X
END Cat;

(* Appends n to s, right aligned in width, as printf's "%<width>d". *)
PROCEDURE Int(n, width: INTEGER; VAR s: ARRAY OF CHAR);
  VAR d: ARRAY 16 OF CHAR; k, i: INTEGER; neg: BOOLEAN;
BEGIN
  neg := n < 0; IF neg THEN n := -n END;
  k := 0; REPEAT d[k] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(k) UNTIL n = 0;
  IF neg THEN d[k] := "-"; INC(k) END;
  i := 0; WHILE s[i] # 0X DO INC(i) END;
  WHILE width > k DO s[i] := " "; INC(i); DEC(width) END;
  WHILE k > 0 DO DEC(k); s[i] := d[k]; INC(i) END;
  s[i] := 0X
END Int;

(* FLTK's Box: a down box with a small label in color c. *)
PROCEDURE NewBox(x, y, w, h, c: INTEGER; t: ARRAY OF CHAR);
  VAR b: Fl.Box;
BEGIN
  Lines(t);
  NEW(b); Fl.OpenBox(b, x, y, w, h, t);
  b.SetAlign(Fl.AlignInside + Fl.AlignCenter);
  b.SetBoxType(Fl.DownBox);
  b.SetLabelColor(c);
  b.SetLabelSize(11)
END NewBox;

(* FLTK's Title: a label in color c, at the top of its box. *)
PROCEDURE NewTitle(x, y, w, h, c: INTEGER; t: ARRAY OF CHAR);
  VAR b: Fl.Box;
BEGIN
  Lines(t);
  NEW(b); Fl.OpenBox(b, x, y, w, h, t);
  b.SetAlign(Fl.AlignInside + Fl.AlignCenter + Fl.AlignTop);
  b.SetBoxType(Fl.NoBox);
  b.SetLabelColor(c);
  b.SetLabelSize(12)
END NewTitle;

PROCEDURE (w: MainWindow) Handle*(event: INTEGER): BOOLEAN;
  VAR result: BOOLEAN; buffer: ARRAY 128 OF CHAR;
BEGIN
  result := w.Handle^(event);
  IF (event = Fl.EvEnter) OR (event = Fl.EvLeave) THEN
    result := TRUE;
    messageBox.SetLabel("")
  ELSIF (event = Fl.EvMove) OR (event = Fl.EvDrag) THEN
    result := TRUE;
    IF (0 < Fl.EventX()) & (Fl.EventX() < w.W())
      & (0 < Fl.EventY()) & (Fl.EventY() < w.H()) THEN
      buffer := "Mouse position relative to main window: ";
      Int(Fl.EventX(), 3, buffer); Cat(",", buffer); Int(Fl.EventY(), 3, buffer);
      messageBox.SetLabel(buffer)
    ELSE messageBox.SetLabel("")
    END
  END;
  RETURN result
END Handle;

PROCEDURE Build;
  VAR tl, br: Fl.Window; tr, bl: Fl.Group;
BEGIN
  NEW(window); Fl.OpenWindow(window, 500, 232, "FLTK Coordinate Systems");

  NEW(tl); Fl.OpenWindowAt(tl, 0, 0, 250, 100, "");
  tl.SetBoxType(Fl.EngravedBox);
  NewTitle(10, 10, 230, 40, Fl.Red,
    "Fl_Window TL(0, 0, 250, 100)|x, y relative to main window");
  NewBox(25, 50, 200, 40, Fl.Red,
    "Fl_Box tl(25, 50, 200, 40)|x, y relative to TL window");
  tl.End;

  NEW(br); Fl.OpenWindowAt(br, 250, 100, 250, 100, "");
  br.SetBoxType(Fl.EngravedBox);
  NewTitle(10, 10, 230, 40, Fl.Magenta,
    "Fl_Window BR(250, 100, 250, 100)|x, y relative to main window");
  NewBox(25, 50, 200, 40, Fl.Magenta,
    "Fl_Box br(25, 50, 200, 40)|x, y relative to BR window");
  br.End;

  NEW(tr); Fl.OpenGroup(tr, 250, 0, 250, 100, "");
  tr.SetBoxType(Fl.EngravedBox);
  NewTitle(260, 10, 230, 40, Fl.Blue,
    "Fl_Group TR(250, 0, 250, 100)|x, y relative to main window");
  NewBox(275, 50, 200, 40, Fl.Blue,
    "Fl_Box tr(275, 50, 200, 40)|x, y relative to main window");
  tr.End;

  NEW(bl); Fl.OpenGroup(bl, 0, 100, 250, 100, "");
  bl.SetBoxType(Fl.EngravedBox);
  NewTitle(10, 110, 230, 40, Fl.Black,
    "Fl_Group BL(0, 100, 250, 100)|x, y relative to main window");
  NewBox(25, 150, 200, 40, Fl.Black,
    "Fl_Box bl(25, 150, 200, 40)|x, y relative to main window");
  bl.End;

  NEW(messageBox); Fl.OpenBox(messageBox, 0, 201, 500, 30, "");
  messageBox.SetAlign(Fl.AlignInside + Fl.AlignCenter);
  messageBox.SetBoxType(Fl.EngravedBox);
  messageBox.SetLabelFont(Fl.Courier);
  messageBox.SetLabelSize(12);

  window.End
END Build;

BEGIN
  Build;
  window.ShowArgs;
  Fl.Run
END Coordinates.
