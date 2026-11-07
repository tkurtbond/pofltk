MODULE ResizeBox; (* FLTK's test/resizebox.cxx in Oberon-2 *)

(* Where the resizable box is decides how a window's children grow:
   the arrows put a box of no size on a side of the middle square, and
   "off" makes the window keep its size. The window must be at its
   smallest when the box moves. *)

IMPORT Fl, FlButtons, FlDialogs;

CONST
  W1 = 40;
  B = 0;
  W3 = 5 * W1 + 6 * B;

TYPE
  Arrow = POINTER TO RECORD (FlButtons.RadioButtonDesc) side: INTEGER END;

VAR
  window: Fl.DoubleWindow;
  box: Fl.Box;
  b: Arrow;
  x, y: INTEGER;

(* s with each "|" a line feed *)
PROCEDURE Lines(VAR s: ARRAY OF CHAR);
VAR i: INTEGER;
BEGIN
  i := 0; WHILE s[i] # 0X DO IF s[i] = "|" THEN s[i] := 0AX END; INC(i) END
END Lines;

PROCEDURE ArrowCallback(o: Fl.Widget);
VAR w: INTEGER; s: ARRAY 32 OF CHAR;
BEGIN
  w := o(Arrow).side;
  IF (window.W() # W3) OR (window.H() # W3) THEN
    FlDialogs.Message("Put window back to minimum size before changing");
    RETURN
  END;
  window.InitSizes;
  CASE w OF
    0: box.Hide; window.SetBoxType(Fl.FlatBox); window.SetResizable(NIL); RETURN
  | 8: box.Resize(W1 + B, W1, 2 * W1, B)
  | 2: box.Resize(W1 + B, W1 + B + 2 * W1, 2 * W1, B)
  | 4: box.Resize(W1 + B, W1, B, 2 * W1)
  | 6: box.Resize(W1 + B + 2 * W1, W1 + B, B, 2 * W1)
  END;
  window.SetBoxType(Fl.NoBox);
  IF (w = 6) OR (w = 4) THEN s := "re|siz|ab|le"; Lines(s); box.SetLabel(s)
  ELSE box.SetLabel("resizable")
  END;
  box.Show;
  window.SetResizable(box);
  window.Redraw
END ArrowCallback;

PROCEDURE Frame(x, y, w, h, color: INTEGER);
VAR n: Fl.Box;
BEGIN
  NEW(n); Fl.OpenBox(n, x, y, w, h, "");
  n.SetBoxType(Fl.EngravedBox); (* FL_FRAME_BOX *)
  n.SetColor(color)
END Frame;

PROCEDURE NewArrow(x, y: INTEGER; label-: ARRAY OF CHAR; side: INTEGER): Arrow;
VAR a: Arrow;
BEGIN
  NEW(a); FlButtons.OpenRadioButton(a, x, y, 20, 20, label);
  a.side := side; a.action := ArrowCallback;
  RETURN a
END NewArrow;

BEGIN
  NEW(window); Fl.OpenDoubleWindow(window, W3, W3, "");
  window.SetBoxType(Fl.NoBox);
  FOR x := 0 TO 3 DO
    FOR y := 0 TO 3 DO
      IF ((x = 1) OR (x = 2)) & ((y = 1) OR (y = 2)) THEN (* the middle *)
      ELSE Frame(x * (B + W1) + B, y * (B + W1) + B, W1, W1, x + y + 8)
      END
    END
  END;
  Frame(B, 4 * W1 + 5 * B, 4 * W1 + 3 * B, W1, 12);
  Frame(4 * W1 + 5 * B, B, W1, 5 * W1 + 4 * B, 13);
  Frame(W1 + B + B, W1 + B + B, 2 * W1 + B, 2 * W1 + B, 8);

  b := NewArrow(W1 + B + 50, W1 + B + 30, "@6>", 6);
  IF NewArrow(W1 + B + 30, W1 + B + 10, "@8>", 8) # NIL THEN END;
  IF NewArrow(W1 + B + 10, W1 + B + 30, "@4>", 4) # NIL THEN END;
  IF NewArrow(W1 + B + 30, W1 + B + 50, "@2>", 2) # NIL THEN END;
  IF NewArrow(W1 + B + 30, W1 + B + 30, "off", 0) # NIL THEN END;

  NEW(box); Fl.OpenBox(box, 0, 0, 0, 0, "resizable");
  box.SetBoxType(Fl.FlatBox);
  box.SetColor(Fl.Dark2);
  b.SetValue(TRUE);
  b.DoCallback;
  window.End;

  window.SizeRange(W3, W3, 0, 0);
  window.ShowArgs;
  Fl.Run
END ResizeBox.
