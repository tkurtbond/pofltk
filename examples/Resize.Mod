MODULE Resize; (* FLTK's test/resize.fl in Oberon-2 *)

(* A window the program moves and resizes: the arrows move it 50
   pixels, and grow and shrink resize it by 20. *)

IMPORT Fl, FlButtons;

TYPE
  Action = PROCEDURE (w: Fl.Widget);

VAR
  w: Fl.DoubleWindow;
  box: Fl.Box;
  text: ARRAY 256 OF CHAR;

PROCEDURE Win(o: Fl.Widget): Fl.Window;
BEGIN RETURN o.Window()
END Win;

PROCEDURE Left(o: Fl.Widget);
VAR w: Fl.Window;
BEGIN w := Win(o); w.Position(w.X() - 50, w.Y())
END Left;

PROCEDURE Down(o: Fl.Widget);
VAR w: Fl.Window;
BEGIN w := Win(o); w.Position(w.X(), w.Y() + 50)
END Down;

PROCEDURE Right(o: Fl.Widget);
VAR w: Fl.Window;
BEGIN w := Win(o); w.Position(w.X() + 50, w.Y())
END Right;

PROCEDURE Up(o: Fl.Widget);
VAR w: Fl.Window;
BEGIN w := Win(o); w.Position(w.X(), w.Y() - 50)
END Up;

PROCEDURE Grow(o: Fl.Widget);
VAR w: Fl.Window;
BEGIN w := Win(o); w.Size(w.W() + 20, w.H() + 20)
END Grow;

PROCEDURE Shrink(o: Fl.Widget);
VAR w: Fl.Window;
BEGIN w := Win(o); w.Size(w.W() - 20, w.H() - 20)
END Shrink;

PROCEDURE Button(x, y, width: INTEGER; label-: ARRAY OF CHAR; action: Action; big: BOOLEAN);
VAR b: FlButtons.Button;
BEGIN
  NEW(b); FlButtons.OpenButton(b, x, y, width, 40, label);
  IF big THEN b.SetLabelFont(Fl.HelveticaBold); b.SetLabelSize(18) END;
  b.action := action
END Button;

BEGIN
  NEW(w); Fl.OpenDoubleWindow(w, 366, 261, "");
  Button(20, 40, 40, "@<-", Left, FALSE);
  Button(60, 80, 40, "@2->", Down, FALSE);
  Button(100, 40, 40, "@->", Right, FALSE);
  Button(60, 0, 40, "@8->", Up, FALSE);
  Button(30, 130, 110, "grow", Grow, TRUE);
  Button(30, 190, 110, "shrink", Shrink, TRUE);
  text := "This is a test of program-generated resize() of a window.  The window should move or resize once when each button is clicked.  The program and window manager should not go into fits echoing resizes back and forth!";
  NEW(box); Fl.OpenBox(box, 150, 10, 160, 220, text);
  box.SetBoxType(Fl.BorderBox);
  box.SetAlign(Fl.AlignWrap + Fl.AlignLeft + Fl.AlignInside);
  w.SetResizable(w);
  w.End;
  w.ShowArgs;
  Fl.Run
END Resize.
