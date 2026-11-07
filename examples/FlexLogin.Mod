MODULE FlexLogin; (* FLTK's test/flex_login.cxx in Oberon-2 *)

(* A login form laid out with flexes alone: rows inside columns inside
   a row inside a column, with empty boxes taking the space left over,
   so the form stays the same size and in the middle as the window
   grows. Compare GridLogin. *)

IMPORT Fl, FlButtons, FlInputs, FlLayout;

VAR
  win: Fl.DoubleWindow;
  col: FlLayout.Flex;

(* A flex of kind, at no size, for its parent to lay out. *)
PROCEDURE Flex(kind: INTEGER): FlLayout.Flex;
VAR f: FlLayout.Flex;
BEGIN
  NEW(f); FlLayout.OpenFlex(f, 0, 0, 0, 0, ""); f.SetKind(kind);
  RETURN f
END Flex;

PROCEDURE Button(label-: ARRAY OF CHAR): FlButtons.Button;
VAR b: FlButtons.Button;
BEGIN
  NEW(b); FlButtons.OpenButton(b, 0, 0, 100, 25, label);
  b.SetColor(Fl.RGB(225, 225, 225));
  RETURN b
END Button;

PROCEDURE Box(label-: ARRAY OF CHAR): Fl.Box;
VAR b: Fl.Box;
BEGIN NEW(b); Fl.OpenBox(b, 0, 0, 0, 0, label); RETURN b
END Box;

(* A row of a label and a 180 pixel input. *)
PROCEDURE Field(label-: ARRAY OF CHAR): FlLayout.Flex;
VAR row: FlLayout.Flex; b: Fl.Box; i: FlInputs.Input;
BEGIN
  row := Flex(FlLayout.Row);
  b := Box(label);
  b.SetAlign(Fl.AlignInside + Fl.AlignRight);
  NEW(i); FlInputs.OpenInput(i, 0, 0, 0, 0, "");
  row.SetFixed(i, 180);
  row.End;
  RETURN row
END Field;

(* The widgets in parent, a column. *)
PROCEDURE ButtonsPanel(parent: FlLayout.Flex);
VAR title, pad, b: Fl.Box; urow, prow, brow: FlLayout.Flex; reg, login: FlButtons.Button;
BEGIN
  b := Box("");
  title := Box("Welcome to Fl_Flex");
  title.SetAlign(Fl.AlignCenter);
  title.SetLabelFont(Fl.Bold + Fl.Italic);
  title.SetLabelSize(16);

  urow := Field("Username:");
  prow := Field("Password:");

  pad := Box("");

  brow := Flex(FlLayout.Row);
  b := Box("");
  reg := Button("Register");
  login := Button("Login");
  brow.SetFixed(reg, 80);
  brow.SetFixed(login, 80);
  brow.SetGap(20);
  brow.End;

  b := Box("");

  parent.SetFixed(title, 60);
  parent.SetFixed(urow, 30);
  parent.SetFixed(prow, 30);
  parent.SetFixed(pad, 1);
  parent.SetFixed(brow, 30);
  parent.SetFixed(b, 30)
END ButtonsPanel;

(* The widgets in parent, a row. *)
PROCEDURE MiddlePanel(parent: FlLayout.Flex);
VAR b, box, spacer: Fl.Box; bp: FlLayout.Flex;
BEGIN
  b := Box("");
  box := Box("Image");
  box.SetBoxType(Fl.BorderBox);
  box.SetColor(Fl.RGB(0, 200, 0));
  spacer := Box("");

  bp := Flex(FlLayout.Column);
  ButtonsPanel(bp);
  bp.End;

  b := Box("");

  parent.SetFixed(box, 150);
  parent.SetFixed(spacer, 10);
  parent.SetFixed(bp, 300)
END MiddlePanel;

(* The widgets in parent, a column: the middle panel, of fixed height,
   between boxes that take what is left. *)
PROCEDURE MainPanel(parent: FlLayout.Flex);
VAR b: Fl.Box; mp: FlLayout.Flex;
BEGIN
  b := Box("");
  mp := Flex(FlLayout.Row);
  MiddlePanel(mp);
  mp.End;
  b := Box("");
  parent.SetFixed(mp, 200)
END MainPanel;

BEGIN
  NEW(win); Fl.OpenDoubleWindow(win, 100, 100, 'Fl_Flex "Login" Layout');
  NEW(col); FlLayout.OpenFlex(col, 5, 5, 90, 90, "");
  col.SetKind(FlLayout.Column);
  MainPanel(col);
  col.End;

  win.SetResizable(col);
  win.SetColor(Fl.RGB(250, 250, 250));
  win.End;

  win.Resize(0, 0, 600, 300); (* the same size as GridLogin's *)
  win.SizeRange(550, 250, 0, 0);
  win.ShowArgs;
  Fl.Run;
  win.Delete
END FlexLogin.
