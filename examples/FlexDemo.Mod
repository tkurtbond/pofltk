MODULE FlexDemo; (* FLTK's test/flex_demo.cxx in Oberon-2 *)

(* Rows and columns of buttons, boxes and inputs in nested flexes, some
   of fixed size, to show how a flex shares its space. The first
   button of the second row hides or shows that row's OK button and
   box, and adds a box to the first row or deletes it again. *)

IMPORT Fl, FlButtons, FlInputs, FlLayout;

VAR
  window: Fl.DoubleWindow;
  col, row1, col1, row4: FlLayout.Flex;
  okay: FlButtons.Button; (* the OK button the toggle hides *)
  box3: Fl.Box; (* the box it adds to the first row, or NIL *)
  w: Fl.Widget;
  b: Fl.Box;
  cancel, ok: FlButtons.Button;

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
  NEW(b); FlButtons.OpenButton(b, 0, 0, 120, 30, label);
  b.SetColor(Fl.RGB(225, 225, 225));
  RETURN b
END Button;

PROCEDURE Box(w, h: INTEGER; label-: ARRAY OF CHAR): Fl.Box;
VAR b: Fl.Box;
BEGIN NEW(b); Fl.OpenBox(b, 0, 0, w, h, label); RETURN b
END Box;

PROCEDURE Input;
VAR i: FlInputs.Input;
BEGIN NEW(i); FlInputs.OpenInput(i, 0, 0, 120, 10, "")
END Input;

PROCEDURE ToggleCallback(w: Fl.Widget);
VAR flex: FlLayout.Flex; g: Fl.Group; box: Fl.Widget;
BEGIN
  g := okay.Parent(); flex := g(FlLayout.Flex);
  box := flex.Child(1);
  IF okay.Visible() THEN
    okay.Hide;
    w.SetLabel("show OK button");
    box.Hide
  ELSE
    okay.Show;
    w.SetLabel("hide OK button");
    box.Show
  END;
  flex.Layout;

  (* and add a box to the first row, or delete it again; no group is
     current, as everything has ended *)
  g := flex.Parent(); box := g.Child(0); flex := box(FlLayout.Flex);
  IF box3 = NIL THEN
    box3 := Box(0, 0, "Box3");
    flex.Insert(box3, flex.Children() - 1)
  ELSE
    box3.Delete; box3 := NIL
  END;
  flex.Layout
END ToggleCallback;

PROCEDURE Row(): FlLayout.Flex;
VAR row, col2: FlLayout.Flex; toggle, b: FlButtons.Button; box2: Fl.Box;
BEGIN
  row := Flex(FlLayout.Row);
  toggle := Button("hide OK button");
  toggle.SetTooltip("hide() or show() OK button");
  box2 := Box(120, 10, "Box2");
  okay := Button("OK");
  Input;
  toggle.action := ToggleCallback;

  col2 := Flex(FlLayout.Column);
  b := Button("Top2");
  b := Button("Bottom2");
  col2.End;
  col2.SetMargins(0, 0, 0, 0); col2.SetGap(5); (* FLTK's margin(0, 5) *)
  col2.SetBoxType(Fl.FlatBox);
  col2.SetColor(Fl.RGB(255, 128, 128));

  row.SetFixed(box2, 50);
  row.SetFixed(col2, 100);
  row.End;
  row.SetBoxType(Fl.DownBox);
  row.SetColor(Fl.Green);
  RETURN row
END Row;

BEGIN
  NEW(window); Fl.OpenDoubleWindow(window, 100, 100, "Simple GUI Example");
  NEW(col); FlLayout.OpenFlex(col, 5, 5, 90, 90, "");
  col.SetKind(FlLayout.Column);
  row1 := Flex(FlLayout.Row);
  row1.SetColor(Fl.Yellow);
  row1.SetBoxType(Fl.FlatBox);
  w := Button("Cancel");
  b := Box(120, 10, "Box1");
  w := Button("OK");
  Input;
  col1 := Flex(FlLayout.Column);
  w := Button("Top1");
  w := Button("Bottom1");
  col1.SetBoxType(Fl.FlatBox);
  col1.SetColor(Fl.RGB(255, 128, 128));
  col1.SetMargins(5, 5, 5, 5); col1.SetGap(5); (* margin(5, 5) *)
  col1.End;
  row1.End;

  col.SetFixed(Row(), 90);

  w := Button("Something1");

  row4 := Flex(FlLayout.Row);
  cancel := Button("Cancel");
  ok := Button("OK");
  Input;
  row4.SetFixed(cancel, 100);
  row4.SetFixed(ok, 100);
  row4.End;

  w := Button("Something2");

  col.SetFixed(row4, 30);
  col.SetMargins(6, 10, 6, 10);
  col.SetGap(6);
  col.End;

  window.SetResizable(col);
  window.SetColor(Fl.RGB(160, 180, 240));
  window.SetBoxType(Fl.FlatBox);
  window.End;

  window.SizeRange(550, 330, 0, 0);
  window.Resize(0, 0, 640, 480);
  window.ShowArgs;
  Fl.Run;
  window.Delete
END FlexDemo.
