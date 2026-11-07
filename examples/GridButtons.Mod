MODULE GridButtons; (* FLTK's test/grid_buttons.cxx in Oberon-2 *)

(* A row of five buttons in a grid of one row and seven columns: the two
   empty columns take the extra width, and the buttons beside each keep
   together, with no gap. A group below takes the rest of the window. *)

IMPORT Fl, FlButtons, FlLayout;

VAR
  win: Fl.DoubleWindow;
  grid: FlLayout.Grid;
  g1: Fl.Group;
  b0, b1, b3, b4, b6: FlButtons.Button;
  weights: ARRAY 7 OF INTEGER;
  i: INTEGER;

PROCEDURE Button(VAR b: FlButtons.Button; label-: ARRAY OF CHAR);
BEGIN NEW(b); FlButtons.OpenButton(b, 0, 0, 80, 30, label)
END Button;

BEGIN
  NEW(win); Fl.OpenDoubleWindow(win, 460, 200, "Fl_Grid Row with 5 Buttons");
  NEW(grid); FlLayout.OpenGrid(grid, 0, 0, win.W(), 50, "");
  grid.SetMargins(10, 10, 10, 10); grid.SetGap(10, 10);
  grid.SetLayout(1, 7);

  Button(b0, "New"); Button(b1, "Options"); Button(b3, "About");
  Button(b4, "Help"); Button(b6, "Quit");
  grid.End;

  (* assign the buttons to grid cells *)
  grid.Place(b0, 0, 0, FlLayout.GridFill);
  grid.Place(b1, 0, 1, FlLayout.GridFill);
  grid.SetColGap(1, 0);
  grid.Place(b3, 0, 3, FlLayout.GridFill);
  grid.Place(b4, 0, 4, FlLayout.GridFill);
  grid.SetColGap(4, 0);
  grid.Place(b6, 0, 6, FlLayout.GridFill);

  (* the empty columns 2 and 5 take the extra width *)
  weights[0] := 0; weights[1] := 0; weights[2] := 50; weights[3] := 0;
  weights[4] := 0; weights[5] := 50; weights[6] := 0;
  FOR i := 0 TO 6 DO grid.SetColWeight(i, weights[i]) END;

  NEW(g1); Fl.OpenGroup(g1, 0, 50, win.W(), win.H() - 50, "");
  g1.End;
  win.End;
  win.SetResizable(g1);
  win.SizeRange(win.W(), 100, 0, 0);
  win.ShowArgs;
  Fl.Run;
  win.Delete
END GridButtons.
