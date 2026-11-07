MODULE GridAlignment; (* FLTK's test/grid_alignment.cxx in Oberon-2 *)

(* Boxes of fixed and variable size in a grid of seven rows and columns,
   each aligned in its cell in another way: filling it, centred, at a
   corner or a side; a title and a footer spanning several cells; a line
   spanning five rows; and two inputs and a button. *)

IMPORT Fl, FlButtons, FlInputs, FlLayout;

VAR
  win: Fl.DoubleWindow;
  grid: FlLayout.Grid;
  b: Fl.Box;
  i1, i2: FlInputs.Input;
  bt: FlButtons.Button;
  row, col: INTEGER;

(* A flat box of w by h in color. *)
PROCEDURE Box(w, h, color: INTEGER): Fl.Box;
  VAR b: Fl.Box;
BEGIN
  NEW(b); Fl.OpenBox(b, 0, 0, w, h, "");
  b.SetBoxType(Fl.FlatBox); b.SetColor(color);
  RETURN b
END Box;

BEGIN
  NEW(win); Fl.OpenDoubleWindow(win, 440, 350, "Fl_Grid Alignment Test");
  NEW(grid); FlLayout.OpenGrid(grid, 10, 10, 420, 330, "");
  grid.SetMargins(8, 8, 8, 8); grid.SetGap(4, 4);
  grid.SetLayout(7, 7);
  grid.SetBoxType(Fl.FlatBox);
  grid.SetColor(Fl.White);

  (* boxes in the top and bottom rows *)
  FOR col := 0 TO 6 DO
    grid.SetColWidth(col, 50);
    b := Box(20, 20, Fl.Blue);
    IF col = 5 THEN
      b.Size(4, 20);              (* narrower *)
      grid.SetColWidth(col, 4);   (* its least width *)
      grid.SetColWeight(col, 0)   (* not widened *)
    END;
    grid.Place(b, 0, col, FlLayout.GridFill);
    IF col = 5 THEN b := Box(4, 20, Fl.Red) ELSE b := Box(20, 20, Fl.Red) END;
    grid.Place(b, 6, col, FlLayout.GridFill)
  END;

  (* boxes in the left and right columns *)
  grid.SetRowHeight(0, 40);
  grid.SetRowHeight(6, 40);
  FOR row := 1 TO 5 DO
    grid.SetRowHeight(row, 40);
    b := Box(20, 20, Fl.Red);
    CASE row OF
      1: grid.Place(b, row, 0, FlLayout.GridFill)
    | 2: grid.Place(b, row, 0, FlLayout.GridCenter)
    | 3, 4: grid.Place(b, row, 0, FlLayout.GridBottomRight)
    | 5: grid.Place(b, row, 0, FlLayout.GridTopRight)
    END;
    b := Box(20, 20, Fl.Green);
    grid.Place(b, row, 6, FlLayout.GridCenter)
  END;

  (* two more, aligned inside their cells by their own size *)
  grid.Place(Box(20, 20, Fl.Magenta), 4, 1, FlLayout.GridBottomLeft);
  grid.Place(Box(20, 20, Fl.Magenta), 5, 1, FlLayout.GridTopLeft);

  (* a vertical line spanning five rows *)
  grid.PlaceSpan(Box(2, 2, Fl.Black), 1, 5, 5, 1, FlLayout.GridVertical + FlLayout.GridRight);

  (* a title spanning five cells, centred *)
  NEW(b); Fl.OpenBox(b, 0, 0, 1, 1, "");
  b.SetLabel("Hello, Fl_Grid !");
  b.SetLabelFont(Fl.Bold + Fl.Italic);
  b.SetLabelSize(30);
  b.SetLabelType(Fl.ShadowLabel);
  grid.PlaceSpan(b, 1, 1, 1, 5, FlLayout.GridFill);

  (* a footer spanning three cells, at the right *)
  NEW(b); Fl.OpenBox(b, 0, 0, 1, 10, "");
  b.SetLabel("FLTK/test/grid_alignment.cxx");
  b.SetLabelFont(Fl.Courier);
  b.SetLabelSize(11);
  b.SetAlign(Fl.AlignInside + Fl.AlignRight);
  grid.PlaceSpan(b, 5, 2, 1, 3, FlLayout.GridHorizontal + FlLayout.GridBottom);

  (* inputs of fixed height, as wide as their cells *)
  NEW(i1); FlInputs.OpenInput(i1, 0, 0, 100, 30, "Username:");
  grid.PlaceSpan(i1, 2, 3, 1, 2, FlLayout.GridHorizontal);
  NEW(i2); FlInputs.OpenInput(i2, 0, 0, 100, 30, "Password:");
  grid.PlaceSpan(i2, 3, 3, 1, 2, FlLayout.GridHorizontal);

  (* the login button spans two columns *)
  NEW(bt); FlButtons.OpenButton(bt, 0, 0, 10, 30, "Login");
  grid.PlaceSpan(bt, 4, 3, 1, 2, FlLayout.GridHorizontal);

  grid.SetRowWeight(1, 90);
  grid.SetRowWeight(2, 0);
  grid.SetRowWeight(3, 0);
  grid.SetRowWeight(4, 0);
  grid.SetColWeight(0, 30);
  grid.SetColWeight(4, 90);
  grid.SetRowGap(5, 12);

  grid.End;
  grid.Layout;
  win.End;
  win.SetResizable(grid);
  win.SizeRange(440, 350, 0, 0);
  win.ShowArgs;
  Fl.Run;
  grid.ClearLayout;
  win.Delete
END GridAlignment.
