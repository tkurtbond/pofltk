MODULE GridLogin; (* FLTK's test/grid_login.cxx in Oberon-2 *)

(* A login dialog laid out by a grid of six rows and six columns: an
   image beside a title, the user name and password fields and two
   buttons. The outer rows and columns take the extra space, so the rest
   stays together in the middle. *)

IMPORT Fl, FlButtons, FlInputs, FlLayout;

VAR
  win: Fl.DoubleWindow;
  grid: FlLayout.Grid;
  ibox, title: Fl.Box;
  i1, i2: FlInputs.Input;
  reg, login: FlButtons.Button;
  cw, rw: ARRAY 6 OF INTEGER;
  i: INTEGER;

BEGIN
  NEW(win); Fl.OpenDoubleWindow(win, 480, 200, 'Fl_Grid "Login" Layout');
  NEW(grid); FlLayout.OpenGrid(grid, 5, 5, 470, 190, "");
  grid.SetMargins(2, 2, 2, 2); grid.SetGap(2, 2);
  grid.SetLayout(6, 6);

  (* image (150x200) in the left column *)
  NEW(ibox); Fl.OpenBox(ibox, 0, 0, 150, 200, "Image");
  ibox.SetBoxType(Fl.BorderBox);
  ibox.SetColor(Fl.RGB(0, 200, 0));
  grid.PlaceSpan(ibox, 1, 1, 4, 1, FlLayout.GridCenter);

  (* the title in the top row *)
  NEW(title); Fl.OpenBox(title, 0, 0, 200, 60, "");
  title.SetLabel("Welcome to Fl_Grid");
  title.SetAlign(Fl.AlignCenter);
  title.SetLabelFont(Fl.Bold + Fl.Italic);
  title.SetLabelSize(16);
  grid.PlaceSpan(title, 1, 3, 1, 2, FlLayout.GridHorizontal + FlLayout.GridCenter);

  grid.SetColWidth(2, 90); (* placeholder for the inputs' labels *)

  NEW(i1); FlInputs.OpenInput(i1, 0, 0, 150, 30, "Username:");
  grid.PlaceSpan(i1, 2, 3, 1, 2, FlLayout.GridHorizontal);
  grid.SetRowGap(2, 10);

  NEW(i2); FlInputs.OpenInput(i2, 0, 0, 150, 30, "Password:");
  grid.PlaceSpan(i2, 3, 3, 1, 2, FlLayout.GridHorizontal);
  grid.SetRowGap(3, 10);

  NEW(reg); FlButtons.OpenButton(reg, 0, 0, 80, 30, "Register");
  grid.PlaceSpan(reg, 4, 3, 1, 1, FlLayout.GridHorizontal);
  grid.SetColGap(3, 20);

  NEW(login); FlButtons.OpenButton(login, 0, 0, 80, 30, "Login");
  grid.PlaceSpan(login, 4, 4, 1, 1, FlLayout.GridHorizontal);

  cw[0] := 20; cw[1] := 0; cw[2] := 0; cw[3] := 10; cw[4] := 10; cw[5] := 20;
  rw[0] := 10; rw[1] := 0; rw[2] := 0; rw[3] := 0; rw[4] := 0; rw[5] := 10;
  FOR i := 0 TO 5 DO grid.SetColWeight(i, cw[i]); grid.SetRowWeight(i, rw[i]) END;

  grid.End;
  grid.Layout;
  win.End;

  grid.SetColor(Fl.RGB(250, 250, 250));
  win.SetColor(Fl.RGB(250, 250, 250));
  win.SetResizable(grid);
  win.Resize(0, 0, 600, 300);
  win.SizeRange(550, 250, 0, 0);
  win.ShowArgs;
  Fl.Run;
  win.Delete
END GridLogin.
