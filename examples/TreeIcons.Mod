MODULE TreeIcons; (* A tree's icons and margins: icons for the whole tree and for one item, and the gaps around them *)

IMPORT Fl, FlBrowsers, FlButtons, FlImages, FlValuators;

CONST size = 12;

VAR
  win: Fl.Window;
  tree: FlBrowsers.Tree;
  openIcon, closeIcon, userIcon, starIcon, starGray: FlImages.Image;
  bottom, childBottom, iconLeft, labelLeft: FlValuators.ValueSlider;
  active, custom: FlButtons.CheckButton;
  special: FlBrowsers.TreeItem;
  item: FlBrowsers.TreeItem;

(* A square of one color, with a darker border; or, if diamond, only the
   diamond inside it, on the tree's own background. *)
PROCEDURE Icon(r, g, b: INTEGER; diamond: BOOLEAN): FlImages.Image;
  VAR
    i: FlImages.Image;
    bits: ARRAY 4 * size * size OF CHAR;
    x, y, n, dx, dy: INTEGER;
BEGIN
  n := 0;
  FOR y := 0 TO size - 1 DO
    FOR x := 0 TO size - 1 DO
      dx := ABS(2 * x + 1 - size); dy := ABS(2 * y + 1 - size);
      IF diamond & (dx + dy > size) THEN
        bits[n] := 0X; bits[n + 1] := 0X; bits[n + 2] := 0X; bits[n + 3] := 0X
      ELSIF (x = 0) OR (y = 0) OR (x = size - 1) OR (y = size - 1) THEN
        bits[n] := CHR(r DIV 2); bits[n + 1] := CHR(g DIV 2); bits[n + 2] := CHR(b DIV 2);
        bits[n + 3] := 0FFX
      ELSE
        bits[n] := CHR(r); bits[n + 1] := CHR(g); bits[n + 2] := CHR(b); bits[n + 3] := 0FFX
      END;
      INC(n, 4)
    END
  END;
  NEW(i); FlImages.OpenRGB(i, bits, size, size, 4, 0);
  RETURN i
END Icon;

PROCEDURE Margins(w: Fl.Widget);
BEGIN
  tree.SetMarginBottom(SHORT(ENTIER(bottom.Value())));
  tree.SetOpenChildMarginBottom(SHORT(ENTIER(childBottom.Value())));
  tree.SetUserIconMarginLeft(SHORT(ENTIER(iconLeft.Value())));
  tree.SetLabelMarginLeft(SHORT(ENTIER(labelLeft.Value())));
  tree.Redraw
END Margins;

PROCEDURE ActiveCB(w: Fl.Widget);
BEGIN special.Activate(active.Value()); tree.Redraw
END ActiveCB;

(* The tree's icons, or FLTK's own; a tree's user icon shows on every
   item with none of its own. *)
PROCEDURE CustomCB(w: Fl.Widget);
BEGIN
  IF custom.Value() THEN
    FlImages.SetOpenIcon(tree, openIcon);
    FlImages.SetCloseIcon(tree, closeIcon);
    FlImages.SetUserIcon(tree, userIcon)
  ELSE
    FlImages.SetOpenIcon(tree, NIL);
    FlImages.SetCloseIcon(tree, NIL);
    FlImages.SetUserIcon(tree, NIL)
  END;
  tree.Redraw
END CustomCB;

PROCEDURE Slider(VAR v: FlValuators.ValueSlider; y, value: INTEGER; label: ARRAY OF CHAR);
BEGIN
  NEW(v); FlValuators.OpenValueSlider(v, 290, y, 160, 20, label);
  v.SetKind(FlValuators.HorSlider);
  v.SetAlign(Fl.AlignTop);
  v.SetBounds(0.0D0, 30.0D0);
  v.SetStep(1.0D0);
  v.SetValue(value);
  v.action := Margins
END Slider;

BEGIN
  NEW(win); Fl.OpenWindow(win, 470, 340, "TreeIcons");
  NEW(tree); FlBrowsers.OpenTree(tree, 10, 10, 260, 320, "");
  item := tree.Add("Fruit/Apple");
  item := tree.Add("Fruit/Pear");
  special := tree.Add("Fruit/This item has its own icon");
  item := tree.Add("Fruit/Plum");
  item := tree.Add("Vegetables/Beet");
  item := tree.Add("Vegetables/Leek/Giant");
  item := tree.Add("Vegetables/Leek/Musselburgh");
  item := tree.Add("Nuts/Almond");

  openIcon := Icon(70, 170, 70, FALSE);
  closeIcon := Icon(190, 70, 70, FALSE);
  userIcon := Icon(90, 120, 200, FALSE);
  starIcon := Icon(240, 190, 40, TRUE);
  starGray := Icon(170, 170, 170, TRUE);
  FlImages.SetItemIcon(special, starIcon);
  FlImages.SetItemInactiveIcon(special, starGray);

  Slider(bottom, 30, tree.MarginBottom(), "Margin below the tree");
  Slider(childBottom, 80, tree.OpenChildMarginBottom(), "Margin below open children");
  Slider(iconLeft, 130, tree.UserIconMarginLeft(), "Margin left of the user icon");
  Slider(labelLeft, 180, tree.LabelMarginLeft(), "Margin left of the label");

  NEW(custom); FlButtons.OpenCheckButton(custom, 290, 220, 160, 25, "The tree's own icons");
  custom.SetValue(TRUE);
  custom.action := CustomCB;
  NEW(active); FlButtons.OpenCheckButton(active, 290, 250, 160, 25, "Item is active");
  active.SetValue(TRUE);
  active.action := ActiveCB;
  win.End;
  CustomCB(custom);
  win.ShowArgs;
  Fl.Run
END TreeIcons.
