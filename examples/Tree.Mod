MODULE Tree; (* FLTK's test/tree.cxx in Oberon-2 *)

(* A tree, with controls for its every setting: margins, spacing,
   connectors, collapse icons, user icons, selection and reselection
   modes, when it calls back, its fonts and colours, and widgets in its
   items. Buttons test opening, closing, inserting, removing, swapping
   and selecting items, the callback flag, and loading a preferences
   file into the tree; the terminal below shows each callback.

   FLTK's program calls the tree's select, open and close with
   docallback set; pofltk never calls back for changes the program
   makes, so this one does what Fl_Tree does itself: sets the tree
   changed and calls Report, its callback's body, with the item and the
   reason. pofltk deletes an item's widget with the item, where FLTK
   leaves it in the tree, so the items let theirs go before they are
   removed. Fl_Tree::load has no binding: Load reads the file as it
   does. *)

IMPORT Fl, FlBrowsers, FlButtons, FlDialogs, FlImages, FlInputs, FlMenus,
  FlPreferences, FlTerminal, FlText, FlValuators;

CONST
  LF = 0AX;
  userData = 1234;  (* FLTK's tree's user data, shown in its callback *)

TYPE
  XPM = ARRAY 16, 16 OF CHAR;

VAR
  window: Fl.DoubleWindow;
  tree: FlBrowsers.Tree;
  g2: Fl.Group;
  g3: Fl.Group;
  margintopSlider: FlValuators.ValueSlider;
  marginleftSlider: FlValuators.ValueSlider;
  marginbottomSlider: FlValuators.ValueSlider;
  linespacingSlider: FlValuators.ValueSlider;
  usericonmarginleftSlider: FlValuators.ValueSlider;
  labelmarginleftSlider: FlValuators.ValueSlider;
  widgetmarginleftSlider: FlValuators.ValueSlider;
  openchildMarginbottomSlider: FlValuators.ValueSlider;
  connectorwidthSlider: FlValuators.ValueSlider;
  collapseiconsChooser: FlMenus.Choice;
  connectorstyleChooser: FlMenus.Choice;
  selectmodeChooser: FlMenus.Choice;
  reselectmodeChooser: FlMenus.Choice;
  whenmodeChooser: FlMenus.Choice;
  usericonRadio: FlButtons.CheckButton;
  showrootRadio: FlButtons.CheckButton;
  visiblefocusCheckbox: FlButtons.CheckButton;
  labelandwidgetRadio: FlButtons.CheckButton;
  itemheightfromwidgetRadio: FlButtons.CheckButton;
  globalvisiblefocusCheckbox: FlButtons.CheckButton;
  showitemBox: Fl.Group;
  b: FlButtons.Button;
  openallButton: FlButtons.Button;
  loaddbButton: FlButtons.Button;
  insertaboveButton: FlButtons.Button;
  rebuildtreeButton: FlButtons.Button;
  showpathnameButton: FlButtons.Button;
  closeallButton: FlButtons.Button;
  clearallButton: FlButtons.Button;
  testcallbackflagButton: FlButtons.Button;
  testrootshowselfButton: FlButtons.Button;
  add20kButton: FlButtons.Button;
  selectedLabelfontChoice: FlMenus.Choice;
  selectedLabelsizeSlider: FlValuators.ValueSlider;
  allLabelfgcolorButton: FlButtons.Button;
  allLabelbgcolorButton: FlButtons.Button;
  deactivateItemsToggle: FlButtons.LightButton;
  deactivateTreeToggle: FlButtons.LightButton;
  boldToggle: FlButtons.LightButton;
  showselectedButton: FlButtons.Button;
  clearselectedButton: FlButtons.Button;
  swapselectedButton: FlButtons.Button;
  selectallButton: FlButtons.Button;
  deselectallButton: FlButtons.Button;
  nextselectedButton: FlButtons.Button;
  bbbselectToggle: FlButtons.LightButton;
  bbbselect2Toggle: FlButtons.LightButton;
  bbbchild02selectToggle: FlButtons.LightButton;
  rootselectToggle: FlButtons.LightButton;
  rootselect2Toggle: FlButtons.LightButton;
  labelfontChoice: FlMenus.Choice;
  labelsizeSlider: FlValuators.ValueSlider;
  itemLabelfontChoice: FlMenus.Choice;
  itemLabelsizeSlider: FlValuators.ValueSlider;
  labelcolorButton: FlButtons.Button;
  colorButton: FlButtons.Button;
  selectionColorButton: FlButtons.Button;
  itemLabelfgcolorButton: FlButtons.Button;
  itemLabelbgcolorButton: FlButtons.Button;
  xItemLabelbgcolorButton: FlButtons.Button;
  treeScrollbarSizeSlider: FlValuators.ValueSlider;
  scrollbarSizeSlider: FlValuators.ValueSlider;
  testsuggsButton: FlButtons.Button;
  resizerBox: Fl.Box;
  tty: FlTerminal.Terminal;
  cbCounter: INTEGER;  (* G_cb_counter: the tree's callbacks *)
  itemId: INTEGER;  (* the next of Add 20,000's items *)
  in: FlInputs.Input;  (* the widgets RebuildTree puts in items *)
  but: FlButtons.Button;
  grp: Fl.Group;
  folder, folderOff, document, documentOff: FlImages.Image;  (* user icons *)
  openIcon, closeIcon: FlImages.Image;  (* the custom collapse icons *)
  helpWin: Fl.DoubleWindow;  (* the test suggestions, made once *)
  helpDisp: FlText.TextDisplay;
  helpBuf: FlText.TextBuffer;
  ok0: BOOLEAN;
  help: ARRAY 8192 OF CHAR;

(* Appends t to s. *)
PROCEDURE Cat(t-: ARRAY OF CHAR; VAR s: ARRAY OF CHAR);
  VAR i, j: INTEGER;
BEGIN
  i := 0; WHILE s[i] # 0X DO INC(i) END;
  j := 0; WHILE (j < LEN(t)) & (t[j] # 0X) DO s[i] := t[j]; INC(i); INC(j) END;
  s[i] := 0X
END Cat;

PROCEDURE Length(s-: ARRAY OF CHAR): INTEGER;
  VAR i: INTEGER;
BEGIN i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) DO INC(i) END; RETURN i
END Length;

(* Appends c to s. *)
PROCEDURE Char(c: CHAR; VAR s: ARRAY OF CHAR);
  VAR i: INTEGER;
BEGIN i := Length(s); s[i] := c; s[i + 1] := 0X
END Char;

(* Appends t to s in width, right aligned (printf's "%<width>s"). *)
PROCEDURE Pad(t-: ARRAY OF CHAR; width: INTEGER; VAR s: ARRAY OF CHAR);
  VAR n: INTEGER;
BEGIN
  n := Length(t);
  WHILE width > n DO Char("0", s); DEC(width) END;
  Cat(t, s)
END Pad;

(* Appends n to s in decimal, with zeros to width ("%0<width>d"). *)
PROCEDURE Int(n, width: INTEGER; VAR s: ARRAY OF CHAR);
  VAR d: ARRAY 16 OF CHAR; r: ARRAY 16 OF CHAR; k, i: INTEGER; neg: BOOLEAN;
BEGIN
  neg := n < 0; IF neg THEN n := -n END;
  k := 0; REPEAT d[k] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(k) UNTIL n = 0;
  IF neg THEN d[k] := "-"; INC(k) END;
  i := 0; WHILE k > 0 DO DEC(k); r[i] := d[k]; INC(i) END; r[i] := 0X;
  Pad(r, width, s)
END Int;

(* fluid's tooltips as tr.py wrote them: | for a line feed, ` for ". *)
PROCEDURE Lines(VAR s: ARRAY OF CHAR);
  VAR i: INTEGER;
BEGIN
  i := 0;
  WHILE (i < LEN(s)) & (s[i] # 0X) DO
    IF s[i] = "|" THEN s[i] := LF ELSIF s[i] = "`" THEN s[i] := 22X END;
    INC(i)
  END
END Lines;

PROCEDURE Tip(w: Fl.Widget; t-: ARRAY OF CHAR);
  VAR s: ARRAY 1024 OF CHAR;
BEGIN COPY(t, s); Lines(s); w.SetTooltip(s)
END Tip;

(* Adds each of t's |-separated items to m, in a 12-point label. *)
PROCEDURE Items(m: FlMenus.Menu; t-: ARRAY OF CHAR);
  VAR part: ARRAY 64 OF CHAR; i, j, k: INTEGER;
BEGIN
  i := 0;
  REPEAT
    j := 0;
    WHILE (i < LEN(t)) & (t[i] # 0X) & (t[i] # "|") DO part[j] := t[i]; INC(i); INC(j) END;
    part[j] := 0X;
    k := m.Add(part, 0, {}, NIL, {}); m.SetItemLabelSize(k, 12);
    IF (i < LEN(t)) & (t[i] = "|") THEN INC(i) END
  UNTIL (i >= LEN(t)) OR (t[i] = 0X)
END Items;

PROCEDURE FontItems(m: FlMenus.Menu);
BEGIN
  Items(m, "Helvetica|Helvetica Bold|Helvetica Italic|Helvetica Bold Italic|Courier|Courier Bold|Courier Italic|Courier Bold Italic|Times|Times Bold|Times Italic|Times Bold Italic|Symbol|Screen|Screen bold|Zapf Dingbats")
END FontItems;

PROCEDURE Print(s-: ARRAY OF CHAR);
BEGIN tty.Append(s)
END Print;

PROCEDURE ReasonName(r: INTEGER; VAR s: ARRAY OF CHAR);
BEGIN
  CASE r OF
    FlBrowsers.ReasonNone: Cat("none", s)
  | FlBrowsers.ReasonSelected: Cat("selected", s)
  | FlBrowsers.ReasonDeselected: Cat("deselected", s)
  | FlBrowsers.ReasonReselected: Cat("reselected", s)
  | FlBrowsers.ReasonOpened: Cat("opened", s)
  | FlBrowsers.ReasonClosed: Cat("closed", s)
  | FlBrowsers.ReasonDragged: Cat("dragged", s)
  ELSE Cat("???", s)
  END
END ReasonName;

(* The tree's callback, for item and reason: FLTK's Tree_CB. *)
PROCEDURE Report(item: FlBrowsers.TreeItem; reason: INTEGER);
  VAR s: ARRAY 512 OF CHAR; l: ARRAY 256 OF CHAR;
BEGIN
  INC(cbCounter);
  s := "TREE CALLBACK: ";
  IF item # NIL THEN
    item.GetLabel(l);
    Cat("label='", s); Cat(l, s); Cat("' userdata=", s); Int(userData, 0, s);
    Cat(" reason=", s); ReasonName(reason, s);
    Cat(", changed=", s); IF tree.Changed() THEN Cat("1", s) ELSE Cat("0", s) END;
    IF Fl.EventClicks() > 0 THEN Cat(", clicks=", s); Int(Fl.EventClicks() + 1, 0, s) END
  ELSE
    Cat("reason=", s); ReasonName(reason, s);
    Cat(", changed=", s); IF tree.Changed() THEN Cat("1", s) ELSE Cat("0", s) END;
    Cat(", item=(no item -- probably multiple items were changed at once)", s)
  END;
  Char(LF, s); Print(s);
  tree.SetChanged(FALSE)
END Report;

PROCEDURE CbTree(w: Fl.Widget);
BEGIN Report(tree.CallbackItem(), tree.CallbackReason())
END CbTree;

(* Fl_Tree's select, deselect, select_toggle, open, close and
   open_toggle with docallback, which pofltk doesn't have. *)
PROCEDURE TreeSelect(item: FlBrowsers.TreeItem; cb: BOOLEAN): BOOLEAN;
BEGIN
  IF ~item.IsSelected() THEN
    item.Select(TRUE); tree.SetChanged(TRUE);
    IF cb THEN Report(item, FlBrowsers.ReasonSelected) END;
    tree.Redraw; RETURN TRUE
  END;
  IF cb & (tree.ReselectMode() = FlBrowsers.SelectableAlways) THEN
    Report(item, FlBrowsers.ReasonReselected)
  END;
  RETURN FALSE
END TreeSelect;

PROCEDURE TreeDeselect(item: FlBrowsers.TreeItem; cb: BOOLEAN): BOOLEAN;
BEGIN
  IF item.IsSelected() THEN
    item.Select(FALSE); tree.SetChanged(TRUE);
    IF cb THEN Report(item, FlBrowsers.ReasonDeselected) END;
    tree.Redraw; RETURN TRUE
  END;
  RETURN FALSE
END TreeDeselect;

PROCEDURE TreeSelectToggle(item: FlBrowsers.TreeItem; cb: BOOLEAN);
BEGIN
  item.ToggleSelect; tree.SetChanged(TRUE);
  IF cb THEN
    IF item.IsSelected() THEN Report(item, FlBrowsers.ReasonSelected)
    ELSE Report(item, FlBrowsers.ReasonDeselected)
    END
  END;
  tree.Redraw
END TreeSelectToggle;

PROCEDURE TreeOpen(item: FlBrowsers.TreeItem; cb: BOOLEAN): BOOLEAN;
BEGIN
  IF item.IsOpen() THEN RETURN FALSE END;
  item.Open;
  IF cb THEN Report(item, FlBrowsers.ReasonOpened) END;
  RETURN TRUE
END TreeOpen;

PROCEDURE TreeClose(item: FlBrowsers.TreeItem; cb: BOOLEAN): BOOLEAN;
BEGIN
  IF ~item.IsOpen() THEN RETURN FALSE END;
  item.Close;
  IF cb THEN Report(item, FlBrowsers.ReasonClosed) END;
  RETURN TRUE
END TreeClose;

PROCEDURE TreeOpenToggle(item: FlBrowsers.TreeItem; cb: BOOLEAN);
  VAR ok: BOOLEAN;
BEGIN
  IF item.IsOpen() THEN ok := TreeClose(item, cb) ELSE ok := TreeOpen(item, cb) END
END TreeOpenToggle;

(* select_all and deselect_all, from item (NIL is the first). *)
PROCEDURE SelectAll(item: FlBrowsers.TreeItem; cb: BOOLEAN);
  VAR t: INTEGER; ok: BOOLEAN;
BEGIN
  IF item = NIL THEN item := tree.First() END;
  IF item # NIL THEN
    IF ~item.IsSelected() THEN ok := TreeSelect(item, cb) END;
    t := 0; WHILE t < item.Children() DO SelectAll(item.Child(t), cb); INC(t) END
  END
END SelectAll;

PROCEDURE DeselectAll(item: FlBrowsers.TreeItem; cb: BOOLEAN);
  VAR t: INTEGER; ok: BOOLEAN;
BEGIN
  IF item = NIL THEN item := tree.First() END;
  IF item # NIL THEN
    IF item.IsSelected() THEN ok := TreeDeselect(item, cb) END;
    t := 0; WHILE t < item.Children() DO DeselectAll(item.Child(t), cb); INC(t) END
  END
END DeselectAll;

(* Lets the widgets of item and its descendants go, so that removing
   them leaves the widgets out of the tree, as FLTK does, not deleted. *)
PROCEDURE Detach(item: FlBrowsers.TreeItem);
  VAR t: INTEGER;
BEGIN
  IF item # NIL THEN
    IF item.Widget() # NIL THEN item.SetWidget(NIL) END;
    t := 0; WHILE t < item.Children() DO Detach(item.Child(t)); INC(t) END
  END
END Detach;

PROCEDURE ClearTree;
BEGIN Detach(tree.Root()); tree.Clear
END ClearTree;

(* fl_color_chooser on val: FALSE if cancelled. *)
PROCEDURE EditColor(VAR val: INTEGER): BOOLEAN;
  VAR r, g, b: INTEGER; ret: BOOLEAN;
BEGIN
  Fl.GetRGB(val, r, g, b);
  ret := FlDialogs.ChooseColor("Choose Color", r, g, b, FlDialogs.ColorDefault);
  IF (r = 0) & (g = 0) & (b = 0) THEN val := Fl.Black ELSE val := Fl.RGB(r, g, b) END;
  RETURN ret
END EditColor;

PROCEDURE UpdateColorChips;
BEGIN
  colorButton.SetColor(tree.Color());
  labelcolorButton.SetColor(tree.LabelColor());
  selectionColorButton.SetColor(tree.SelectionColor());
  itemLabelfgcolorButton.SetColor(tree.ItemLabelColor());
  itemLabelbgcolorButton.SetColor(tree.ItemLabelBgColor());
  allLabelfgcolorButton.SetColor(tree.ItemLabelColor());
  allLabelbgcolorButton.SetColor(tree.ItemLabelBgColor());
  window.Redraw
END UpdateColorChips;

PROCEDURE GetSelectedItemFGColor(): INTEGER;
  VAR item: FlBrowsers.TreeItem;
BEGIN
  item := tree.First();
  WHILE item # NIL DO
    IF item.IsSelected() THEN RETURN item.LabelColor() END;
    item := item.Next()
  END;
  RETURN tree.ItemLabelColor()
END GetSelectedItemFGColor;

PROCEDURE GetSelectedItemBGColor(): INTEGER;
  VAR item: FlBrowsers.TreeItem;
BEGIN
  item := tree.First();
  WHILE item # NIL DO
    IF item.IsSelected() THEN RETURN item.LabelBgColor() END;
    item := item.Next()
  END;
  RETURN tree.ItemLabelBgColor()
END GetSelectedItemBGColor;

PROCEDURE MakeFolder(i: FlImages.Image);
  VAR x: XPM;
BEGIN
  x[0] := "11 11 3 1"; x[1] := ".  c None"; x[2] := "x  c #d8d833"; x[3] := "@  c #808011";
  x[4] := "..........."; x[5] := ".....@@@@.."; x[6] := "....@xxxx@."; x[7] := "@@@@@xxxx@@";
  x[8] := "@xxxxxxxxx@"; x[9] := "@xxxxxxxxx@"; x[10] := "@xxxxxxxxx@"; x[11] := "@xxxxxxxxx@";
  x[12] := "@xxxxxxxxx@"; x[13] := "@xxxxxxxxx@"; x[14] := "@@@@@@@@@@@";
  ASSERT(FlImages.OpenXPM(i, x, 15))
END MakeFolder;

PROCEDURE MakeDocument(i: FlImages.Image);
  VAR x: XPM; k: INTEGER;
BEGIN
  x[0] := "11 11 3 1"; x[1] := ".  c None"; x[2] := "x  c #d8d8f8"; x[3] := "@  c #202060";
  x[4] := ".@@@@@@@@@.";
  FOR k := 5 TO 13 DO x[k] := ".@xxxxxxx@." END;
  x[14] := ".@@@@@@@@@.";
  ASSERT(FlImages.OpenXPM(i, x, 15))
END MakeDocument;

(* Gives each item the folder or document icon, or none. *)
PROCEDURE AssignUserIcons;
  VAR item: FlBrowsers.TreeItem;
BEGIN
  IF folder = NIL THEN
    NEW(folder); MakeFolder(folder);
    NEW(folderOff); MakeFolder(folderOff); folderOff.Inactive;
    NEW(document); MakeDocument(document);
    NEW(documentOff); MakeDocument(documentOff); documentOff.Inactive
  END;
  item := tree.First();
  WHILE item # NIL DO
    IF usericonRadio.Value() THEN
      IF item.Children() > 0 THEN
        FlImages.SetItemIcon(item, folder); FlImages.SetItemInactiveIcon(item, folderOff)
      ELSE
        FlImages.SetItemIcon(item, document); FlImages.SetItemInactiveIcon(item, documentOff)
      END
    ELSE
      FlImages.SetItemIcon(item, NIL); FlImages.SetItemInactiveIcon(item, NIL)
    END;
    item := item.Next()
  END;
  tree.Redraw
END AssignUserIcons;

(* A press of a button in the tree: taller, until 50, if the items'
   heights come from their widgets. *)
PROCEDURE ButtonCB(w: Fl.Widget);
  VAR cw: Fl.Widget; l: ARRAY 64 OF CHAR; s: ARRAY 128 OF CHAR; height: INTEGER;
BEGIN
  w.GetLabel(l);
  IF l = "ccc button" THEN cw := w ELSE cw := w.Parent() END;
  height := cw.H() + 10;
  IF height > 50 THEN height := 20 END;
  cw.Resize(cw.X(), cw.Y(), cw.W(), height);
  tree.Redraw;
  s := "'"; Cat(l, s); Cat("' button pushed (height=", s); Int(height, 0, s); Cat(")", s);
  Char(LF, s); Print(s)
END ButtonCB;

(* Builds the tree from scratch. *)
PROCEDURE RebuildTree;
  VAR i: FlBrowsers.TreeItem; d1, d2: FlButtons.Button; k: INTEGER;
    s: ARRAY 64 OF CHAR; ok: BOOLEAN;
  CONST tipmsg = "A group of two buttons inside the tree.|If 'Item h() from widget' enabled, pressing either button enlarges the group and both buttons together.";
BEGIN
  ClearTree;
  i := tree.Add("Aaa"); i := tree.Add("Bbb"); i := tree.Add("Ccc"); i := tree.Add("Ddd");
  i := tree.Add("Bbb/child-01");
  i := tree.Add("Bbb/child-01/111"); i := tree.Add("Bbb/child-01/222"); i := tree.Add("Bbb/child-01/333");
  i := tree.Add("Bbb/child-02"); i := tree.Add("Bbb/child-03"); i := tree.Add("Bbb/child-04");

  i := tree.Find("Bbb/child-02");
  IF i # NIL THEN
    IF in = NIL THEN
      NEW(in); FlInputs.OpenInput(in, 1, 1, 100, 1, "Fl_Input test");
      in.SetLabelSize(10); in.SetTextSize(10); in.SetAlign(Fl.AlignRight);
      Tip(in, "Fl_Input inside tree.|The widget's label 'Fl_Input test' should appear to the widget's right.")
    END;
    in.Show; i.SetWidget(in)
  END;
  i := tree.Find("Bbb/child-03");
  IF i # NIL THEN
    IF but = NIL THEN
      NEW(but); FlButtons.OpenButton(but, 1, 1, 140, 1, "ccc button");
      but.SetLabelSize(10); but.action := ButtonCB;
      Tip(but, "Button inside tree.|If 'Item h() from widget' enabled, pressing button enlarges it.")
    END;
    but.Show; i.SetWidget(but)
  END;
  i := tree.Find("Bbb/child-04");
  IF i # NIL THEN
    IF grp = NIL THEN
      NEW(grp); Fl.OpenGroup(grp, 100, 100, 140, 18, "");
      grp.SetColor(Fl.White);
      NEW(d1); FlButtons.OpenButton(d1, grp.X() + 0, grp.Y() + 2, 65, 15, "D1");
      d1.SetLabelSize(10); d1.action := ButtonCB; Tip(d1, tipmsg);
      NEW(d2); FlButtons.OpenButton(d2, grp.X() + 75, grp.Y() + 2, 65, 15, "D2");
      d2.SetLabelSize(10); d2.action := ButtonCB; Tip(d2, tipmsg);
      grp.End;
      grp.SetResizable(grp)
    END;
    grp.Show; i.SetWidget(grp)
  END;

  (* Sorted items *)
  tree.SetSortOrder(FlBrowsers.TreeSortNone);
  i := tree.Add("Ascending"); i.Close;
  tree.SetSortOrder(FlBrowsers.TreeSortAscending);
  i := tree.Add("Ascending/Zzz"); i := tree.Add("Ascending/Xxx"); i := tree.Add("Ascending/Aaa");
  i := tree.Add("Ascending/Bbb"); i := tree.Add("Ascending/Yyy"); i := tree.Add("Ascending/Ccc");
  tree.SetSortOrder(FlBrowsers.TreeSortNone);
  i := tree.Add("Descending"); i.Close;
  tree.SetSortOrder(FlBrowsers.TreeSortDescending);
  i := tree.Add("Descending/Zzz"); i := tree.Add("Descending/Xxx"); i := tree.Add("Descending/Aaa");
  i := tree.Add("Descending/Bbb"); i := tree.Add("Descending/Yyy"); i := tree.Add("Descending/Ccc");

  (* Long lines *)
  tree.SetSortOrder(FlBrowsers.TreeSortNone);
  i := tree.Add("Long Line"); i.Close;
  i := tree.Add("Long Line/The quick brown fox jumped over the lazy dog. 0123456789");
  i := tree.Add("Long Line/Longer Line"); i.Close;
  i := tree.Add("Long Line/Longer Line/The quick brown fox jumped over the lazy dog. ---------------- 0123456789");

  (* 500 items, closed, with the callback FLTK's close does *)
  FOR k := 1 TO 500 DO s := "500 Items/item "; Int(k, 4, s); i := tree.Add(s) END;
  ok := TreeClose(tree.Find("500 Items"), TRUE);

  AssignUserIcons;
  tree.Redraw
END RebuildTree;

(* The tree's globals *)

PROCEDURE Ival(v: FlValuators.Valuator): INTEGER;
BEGIN RETURN SHORT(ENTIER(v.Value()))
END Ival;

PROCEDURE CbMargintopSlider(w: Fl.Widget);
BEGIN tree.SetMarginTop(Ival(margintopSlider)); tree.Redraw
END CbMargintopSlider;

PROCEDURE CbMarginleftSlider(w: Fl.Widget);
BEGIN tree.SetMarginLeft(Ival(marginleftSlider)); tree.Redraw
END CbMarginleftSlider;

PROCEDURE CbMarginbottomSlider(w: Fl.Widget);
BEGIN tree.SetMarginBottom(Ival(marginbottomSlider)); tree.Redraw
END CbMarginbottomSlider;

PROCEDURE CbLinespacingSlider(w: Fl.Widget);
BEGIN tree.SetLineSpacing(Ival(linespacingSlider)); tree.Redraw
END CbLinespacingSlider;

PROCEDURE CbUsericonmarginleftSlider(w: Fl.Widget);
BEGIN tree.SetUserIconMarginLeft(Ival(usericonmarginleftSlider)); tree.Redraw
END CbUsericonmarginleftSlider;

PROCEDURE CbLabelmarginleftSlider(w: Fl.Widget);
BEGIN tree.SetLabelMarginLeft(Ival(labelmarginleftSlider)); tree.Redraw
END CbLabelmarginleftSlider;

PROCEDURE CbWidgetmarginleftSlider(w: Fl.Widget);
BEGIN tree.SetWidgetMarginLeft(Ival(widgetmarginleftSlider)); tree.Redraw
END CbWidgetmarginleftSlider;

PROCEDURE CbOpenchildMarginbottomSlider(w: Fl.Widget);
BEGIN tree.SetOpenChildMarginBottom(Ival(openchildMarginbottomSlider)); tree.Redraw
END CbOpenchildMarginbottomSlider;

PROCEDURE CbConnectorwidthSlider(w: Fl.Widget);
BEGIN tree.SetConnectorWidth(Ival(connectorwidthSlider))
END CbConnectorwidthSlider;

PROCEDURE MakeCollapseIcons;
  VAR x: XPM; k: INTEGER;
BEGIN
  x[0] := "11 11 2 1"; x[1] := ".  c None"; x[2] := "@  c #000000";
  x[3] := "..........."; x[4] := "....@......"; x[5] := "....@@....."; x[6] := "....@@@....";
  x[7] := "....@@@@..."; x[8] := "....@@@@@.."; x[9] := "....@@@@..."; x[10] := "....@@@....";
  x[11] := "....@@....."; x[12] := "....@......"; x[13] := "...........";
  NEW(openIcon); ASSERT(FlImages.OpenXPM(openIcon, x, 14));
  FOR k := 3 TO 6 DO x[k] := "..........." END;
  x[7] := ".@@@@@@@@@."; x[8] := "..@@@@@@@.."; x[9] := "...@@@@@..."; x[10] := "....@@@....";
  x[11] := ".....@....."; x[12] := "..........."; x[13] := "...........";
  NEW(closeIcon); ASSERT(FlImages.OpenXPM(closeIcon, x, 14))
END MakeCollapseIcons;

PROCEDURE CbCollapseiconsChooser(w: Fl.Widget);
BEGIN
  CASE collapseiconsChooser.Value() OF
    0: tree.SetShowCollapse(TRUE);
       FlImages.SetOpenIcon(tree, NIL); FlImages.SetCloseIcon(tree, NIL)
  | 1: tree.SetShowCollapse(TRUE);
       IF openIcon = NIL THEN MakeCollapseIcons END;
       FlImages.SetOpenIcon(tree, openIcon); FlImages.SetCloseIcon(tree, closeIcon)
  | 2: tree.SetShowCollapse(FALSE)
  ELSE
  END
END CbCollapseiconsChooser;

PROCEDURE CbConnectorstyleChooser(w: Fl.Widget);
BEGIN
  CASE connectorstyleChooser.Value() OF
    0: tree.SetConnectorStyle(FlBrowsers.ConnectorNone)
  | 1: tree.SetConnectorStyle(FlBrowsers.ConnectorDotted)
  | 2: tree.SetConnectorStyle(FlBrowsers.ConnectorSolid)
  ELSE
  END
END CbConnectorstyleChooser;

PROCEDURE CbSelectmodeChooser(w: Fl.Widget);
BEGIN
  CASE selectmodeChooser.Value() OF
    0: tree.SetSelectMode(FlBrowsers.TreeSelectNone)
  | 1: tree.SetSelectMode(FlBrowsers.TreeSelectSingle)
  | 2: tree.SetSelectMode(FlBrowsers.TreeSelectMulti)
  | 3: tree.SetSelectMode(FlBrowsers.TreeSelectSingleDraggable)
  ELSE tree.SetSelectMode(FlBrowsers.TreeSelectSingle)
  END
END CbSelectmodeChooser;

PROCEDURE CbReselectmodeChooser(w: Fl.Widget);
BEGIN
  CASE reselectmodeChooser.Value() OF
    0: tree.SetReselectMode(FlBrowsers.SelectableOnce)
  | 1: tree.SetReselectMode(FlBrowsers.SelectableAlways)
  ELSE
  END
END CbReselectmodeChooser;

PROCEDURE CbWhenmodeChooser(w: Fl.Widget);
BEGIN
  CASE whenmodeChooser.Value() OF
    0: tree.SetWhen(Fl.WhenRelease)
  | 1: tree.SetWhen(Fl.WhenChanged)
  | 2: tree.SetWhen(Fl.WhenNever)
  ELSE tree.SetWhen(Fl.WhenRelease)
  END
END CbWhenmodeChooser;

PROCEDURE CbUsericonRadio(w: Fl.Widget);
BEGIN AssignUserIcons
END CbUsericonRadio;

PROCEDURE CbShowrootRadio(w: Fl.Widget);
BEGIN tree.SetShowRoot(showrootRadio.Value())
END CbShowrootRadio;

PROCEDURE CbVisiblefocusCheckbox(w: Fl.Widget);
BEGIN tree.SetVisibleFocus(visiblefocusCheckbox.Value())
END CbVisiblefocusCheckbox;

PROCEDURE CbLabelandwidgetRadio(w: Fl.Widget);
  VAR flags: SET;
BEGIN
  flags := tree.ItemDrawMode();
  IF labelandwidgetRadio.Value() THEN flags := flags + FlBrowsers.ItemDrawLabelAndWidget
  ELSE flags := flags - FlBrowsers.ItemDrawLabelAndWidget
  END;
  tree.SetItemDrawMode(flags); tree.Redraw
END CbLabelandwidgetRadio;

PROCEDURE CbItemheightfromwidgetRadio(w: Fl.Widget);
  VAR flags: SET;
BEGIN
  flags := tree.ItemDrawMode();
  IF itemheightfromwidgetRadio.Value() THEN flags := flags + FlBrowsers.ItemHeightFromWidget
  ELSE flags := flags - FlBrowsers.ItemHeightFromWidget
  END;
  tree.SetItemDrawMode(flags); tree.Redraw
END CbItemheightfromwidgetRadio;

PROCEDURE CbGlobalvisiblefocusCheckbox(w: Fl.Widget);
BEGIN Fl.SetOption(Fl.OptionVisibleFocus, globalvisiblefocusCheckbox.Value())
END CbGlobalvisiblefocusCheckbox;

(* The item to show: the first selected, or the first. *)
PROCEDURE ShowItem(): FlBrowsers.TreeItem;
  VAR item: FlBrowsers.TreeItem;
BEGIN
  item := tree.FirstSelected();
  IF item = NIL THEN item := tree.First() END;
  RETURN item
END ShowItem;

PROCEDURE CbShow(w: Fl.Widget);
  VAR item: FlBrowsers.TreeItem;
BEGIN item := ShowItem(); IF item # NIL THEN item.Show END
END CbShow;

PROCEDURE CbTop(w: Fl.Widget);
  VAR item: FlBrowsers.TreeItem;
BEGIN item := ShowItem(); IF item # NIL THEN item.ShowAtTop END
END CbTop;

PROCEDURE CbMid(w: Fl.Widget);
  VAR item: FlBrowsers.TreeItem;
BEGIN item := ShowItem(); IF item # NIL THEN item.ShowInMiddle END
END CbMid;

PROCEDURE CbBot(w: Fl.Widget);
  VAR item: FlBrowsers.TreeItem;
BEGIN item := ShowItem(); IF item # NIL THEN item.ShowAtBottom END
END CbBot;

(* The test buttons *)

PROCEDURE CbOpenallButton(w: Fl.Widget);
  VAR item: FlBrowsers.TreeItem;
BEGIN
  item := tree.First();
  WHILE item # NIL DO
    IF item.Children() > 0 THEN item.Open END;
    item := item.Next()
  END;
  tree.Redraw
END CbOpenallButton;

PROCEDURE CbCloseallButton(w: Fl.Widget);
  VAR item: FlBrowsers.TreeItem;
BEGIN
  item := tree.First();
  WHILE item # NIL DO
    IF ~item.IsRoot() & (item.Children() > 0) THEN item.Close END;
    item := item.Next()
  END;
  tree.Redraw
END CbCloseallButton;

(* Fl_Tree::load: each group of the preferences p an item, each entry
   an item "key = value", under the path of p's group. *)
PROCEDURE Load(p: FlPreferences.Preferences);
  VAR i, k: INTEGER; name, path: ARRAY 256 OF CHAR; key, val: ARRAY 256 OF CHAR;
    text: ARRAY 1024 OF CHAR; child: FlPreferences.Preferences; item: FlBrowsers.TreeItem;
BEGIN
  FOR i := 0 TO p.Groups() - 1 DO
    p.GroupName(i, name);
    NEW(child); p.Group(child, name);
    child.Path(path); item := tree.Add(path);
    Load(child); child.Close
  END;
  p.Path(path);
  FOR i := 0 TO p.Entries() - 1 DO
    p.EntryName(i, key);
    p.GetText(key, "", val);
    k := 0; WHILE key[k] # 0X DO IF key[k] = "/" THEN key[k] := "\" END; INC(k) END;
    k := 0; WHILE val[k] # 0X DO IF val[k] = "/" THEN val[k] := "\" END; INC(k) END;
    text := ""; Cat(path, text); Char("/", text); Cat(key, text); Cat(" = ", text);
    IF Length(val) < 40 THEN Cat(val, text) ELSE val[40] := 0X; Cat(val, text); Cat("...", text) END;
    IF text[0] = "/" THEN item := tree.Add(text) ELSE item := tree.Add(text) END
  END
END Load;

PROCEDURE CbLoaddbButton(w: Fl.Widget);
  VAR fn, dir, base: ARRAY 1024 OF CHAR; i, slash, dot: INTEGER;
    p: FlPreferences.Preferences;
BEGIN
  fn := "";
  IF ~FlDialogs.ChooseFile("Select a Preferences style Database", "Preferences(*.prefs)", fn, FALSE) THEN
    RETURN
  END;
  ClearTree;
  (* Fl_Preferences(filename, 0, 0) opens the file itself; OpenFile
     opens dir/application.prefs, so the name is split. *)
  slash := -1; dot := -1; i := 0;
  WHILE fn[i] # 0X DO
    IF fn[i] = "/" THEN slash := i ELSIF fn[i] = "." THEN dot := i END;
    INC(i)
  END;
  IF slash < 0 THEN dir := "." ELSE COPY(fn, dir); dir[slash] := 0X END;
  i := 0; WHILE (slash + 1 + i # dot) & (fn[slash + 1 + i] # 0X) DO base[i] := fn[slash + 1 + i]; INC(i) END;
  base[i] := 0X;
  NEW(p); FlPreferences.OpenFile(p, dir, "", base);
  Load(p); p.Close;
  tree.Redraw
END CbLoaddbButton;

PROCEDURE CbInsertaboveButton(w: Fl.Widget);
  VAR item, n: FlBrowsers.TreeItem;
BEGIN
  item := tree.First();
  WHILE item # NIL DO
    IF item.IsSelected() THEN
      n := item.InsertAbove("AaaAaa"); n := item.InsertAbove("BbbBbb"); n := item.InsertAbove("CccCcc")
    END;
    item := item.Next()
  END;
  tree.Redraw
END CbInsertaboveButton;

PROCEDURE CbRebuildtreeButton(w: Fl.Widget);
BEGIN RebuildTree
END CbRebuildtreeButton;

PROCEDURE CbShowpathnameButton(w: Fl.Widget);
  VAR item: FlBrowsers.TreeItem; path, l: ARRAY 1024 OF CHAR; s: ARRAY 2100 OF CHAR;
BEGIN
  item := tree.FirstSelected();
  IF item = NIL THEN FlDialogs.Message("No item was selected"); RETURN END;
  IF item.Path(path) THEN
    item.GetLabel(l);
    s := "Pathname for '"; Cat(l, s); Cat("' is: ", s); Char(22X, s); Cat(path, s); Char(22X, s);
    FlDialogs.Message(s)
  ELSE
    FlDialogs.Message("item_pathname() returned -1 (NOT FOUND)")
  END
END CbShowpathnameButton;

PROCEDURE CbClearallButton(w: Fl.Widget);
BEGIN ClearTree; tree.Redraw
END CbClearallButton;

(* fl_alert of two lines. *)
PROCEDURE Alert2(a-, b-: ARRAY OF CHAR);
  VAR s: ARRAY 512 OF CHAR;
BEGIN COPY(a, s); Char(LF, s); Cat(b, s); FlDialogs.Alert(s)
END Alert2;

PROCEDURE CbTestcallbackflagButton(w: Fl.Widget);
  VAR root: FlBrowsers.TreeItem; ok: BOOLEAN;
BEGIN
  root := tree.Root();
  Print("--- Checking docallback off"); Print(LF);
  IF root = NIL THEN RETURN END;

  (* "OFF" TEST *)
  cbCounter := 0; ok := TreeClose(root, FALSE); IF cbCounter # 0 THEN Alert2("FAILED 'OFF' TEST", " close(item) triggered cb!") END;
  cbCounter := 0; ok := TreeOpen(root, FALSE); IF cbCounter # 0 THEN Alert2("FAILED 'OFF' TEST", " open(item) triggered cb!") END;
  cbCounter := 0; TreeOpenToggle(root, FALSE); IF cbCounter # 0 THEN Alert2("FAILED 'OFF' TEST", " open_toggle(item) triggered cb!") END;
  cbCounter := 0; ok := TreeOpen(tree.Find("ROOT"), FALSE); IF cbCounter # 0 THEN Alert2("FAILED 'OFF' TEST", " open(path) triggered cb!") END;
  cbCounter := 0; ok := TreeClose(tree.Find("ROOT"), FALSE); IF cbCounter # 0 THEN Alert2("FAILED 'OFF' TEST", " close(path) triggered cb!") END;
  ok := TreeOpen(root, FALSE);

  cbCounter := 0; ok := TreeSelect(root, FALSE); IF cbCounter # 0 THEN Alert2("FAILED 'OFF' TEST", " select(item) triggered cb!") END;
  cbCounter := 0; ok := TreeDeselect(root, FALSE); IF cbCounter # 0 THEN Alert2("FAILED 'OFF' TEST", " deselect(item) triggered cb!") END;
  cbCounter := 0; TreeSelectToggle(root, FALSE); IF cbCounter # 0 THEN Alert2("FAILED 'OFF' TEST", " select_toggle(item) triggered cb!") END;
  cbCounter := 0; ok := TreeDeselect(tree.Find("ROOT"), FALSE); IF cbCounter # 0 THEN Alert2("FAILED 'OFF' TEST", " deselect(path) triggered cb!") END;
  cbCounter := 0; ok := TreeSelect(tree.Find("ROOT"), FALSE); IF cbCounter # 0 THEN Alert2("FAILED 'OFF' TEST", " select(path) triggered cb!") END;
  ok := TreeDeselect(tree.Find("ROOT"), TRUE);

  (* "ON" TEST *)
  cbCounter := 0; ok := TreeClose(root, TRUE); IF cbCounter = 0 THEN Alert2("FAILED 'ON' TEST", " close(item) cb wasn't triggered!") END;
  cbCounter := 0; ok := TreeOpen(root, TRUE); IF cbCounter = 0 THEN Alert2("FAILED 'ON' TEST", " open(item) cb wasn't triggered!") END;
  cbCounter := 0; TreeOpenToggle(root, TRUE); IF cbCounter = 0 THEN Alert2("FAILED 'ON' TEST", " open_toggle(item) cb wasn't triggered!") END;
  cbCounter := 0; ok := TreeOpen(root, TRUE); IF cbCounter = 0 THEN Alert2("FAILED 'ON' TEST", " open(item)[2] cb wasn't triggered!") END;
  cbCounter := 0; ok := TreeClose(root, TRUE); IF cbCounter = 0 THEN Alert2("FAILED 'ON' TEST", " close(item)[2] cb wasn't triggered!") END;
  cbCounter := 0; ok := TreeOpen(tree.Find("ROOT"), TRUE); IF cbCounter = 0 THEN Alert2("FAILED 'ON' TEST", " open(path) cb wasn't triggered!") END;
  cbCounter := 0; ok := TreeClose(tree.Find("ROOT"), TRUE); IF cbCounter = 0 THEN Alert2("FAILED 'ON' TEST", " close(path) cb wasn't triggered!") END;
  ok := TreeOpen(root, FALSE);

  cbCounter := 0; ok := TreeSelect(root, TRUE); IF cbCounter = 0 THEN Alert2("FAILED 'ON' TEST", " select(item) cb wasn't triggered!") END;
  cbCounter := 0; ok := TreeDeselect(root, TRUE); IF cbCounter = 0 THEN Alert2("FAILED 'ON' TEST", " deselect(item) cb wasn't triggered!") END;
  cbCounter := 0; TreeSelectToggle(root, TRUE); IF cbCounter = 0 THEN Alert2("FAILED 'ON' TEST", " select_toggle(item) cb wasn't triggered!") END;
  cbCounter := 0; ok := TreeDeselect(tree.Find("ROOT"), TRUE); IF cbCounter = 0 THEN Alert2("FAILED 'ON' TEST", " deselect(path) cb wasn't triggered!") END;
  cbCounter := 0; ok := TreeSelect(tree.Find("ROOT"), TRUE); IF cbCounter = 0 THEN Alert2("FAILED 'ON' TEST", " select(path) cb wasn't triggered!") END;
  ok := TreeDeselect(tree.Find("ROOT"), TRUE);

  (* "default" TEST (should be same as 'on') *)
  cbCounter := 0; ok := TreeClose(root, TRUE); IF cbCounter = 0 THEN FlDialogs.Alert("FAILED 'DEFAULT' TEST: close(item) cb wasn't triggered!") END;
  cbCounter := 0; ok := TreeOpen(root, TRUE); IF cbCounter = 0 THEN FlDialogs.Alert("FAILED 'DEFAULT' TEST: open(item) cb wasn't triggered!") END;
  cbCounter := 0; TreeOpenToggle(root, TRUE); IF cbCounter = 0 THEN FlDialogs.Alert("FAILED 'DEFAULT' TEST: open_toggle(item) cb wasn't triggered!") END;
  cbCounter := 0; ok := TreeOpen(tree.Find("ROOT"), TRUE); IF cbCounter = 0 THEN FlDialogs.Alert("FAILED 'DEFAULT' TEST: open(path) cb wasn't triggered!") END;
  cbCounter := 0; ok := TreeClose(tree.Find("ROOT"), TRUE); IF cbCounter = 0 THEN FlDialogs.Alert("FAILED 'DEFAULT' TEST: close(path) cb wasn't triggered!") END;
  ok := TreeOpen(root, FALSE);

  cbCounter := 0; ok := TreeSelect(root, TRUE); IF cbCounter = 0 THEN Alert2("FAILED 'DEFAULT' TEST", " select(item) cb wasn't triggered!") END;
  cbCounter := 0; ok := TreeDeselect(root, TRUE); IF cbCounter = 0 THEN Alert2("FAILED 'DEFAULT' TEST", " deselect(item) cb wasn't triggered!") END;
  cbCounter := 0; TreeSelectToggle(root, TRUE); IF cbCounter = 0 THEN Alert2("FAILED 'DEFAULT' TEST", " select_toggle(item) cb wasn't triggered!") END;
  cbCounter := 0; ok := TreeDeselect(tree.Find("ROOT"), TRUE); IF cbCounter = 0 THEN Alert2("FAILED 'DEFAULT' TEST", " deselect(path) cb wasn't triggered!") END;
  cbCounter := 0; ok := TreeSelect(tree.Find("ROOT"), TRUE); IF cbCounter = 0 THEN Alert2("FAILED 'DEFAULT' TEST", " select(path) cb wasn't triggered!") END;
  ok := TreeDeselect(tree.Find("ROOT"), TRUE);

  Alert2("TEST COMPLETED", " If you didn't see any error dialogs, test PASSED.")
END CbTestcallbackflagButton;

PROCEDURE CbTestrootshowselfButton(w: Fl.Widget);
  VAR root: FlBrowsers.TreeItem;
BEGIN
  root := tree.Root();
  Print("--- Show Tree"); Print(LF);
  IF root # NIL THEN tree.ShowSelf END
END CbTestrootshowselfButton;

PROCEDURE CbAdd20kButton(w: Fl.Widget);
  VAR item, parent, n: FlBrowsers.TreeItem; s: ARRAY 64 OF CHAR; k: INTEGER;
BEGIN
  item := tree.First();
  WHILE item # NIL DO
    IF item.IsSelected() THEN
      parent := item.Parent();
      IF parent = NIL THEN parent := tree.Root() END;
      FOR k := 0 TO 19999 DO
        s := "Item #"; Int(itemId + k, 0, s); n := parent.Add(s)
      END;
      INC(itemId, 20000);
      item := NIL
    ELSE item := item.Next()
    END
  END;
  tree.Redraw
END CbAdd20kButton;

(* The selected items *)

PROCEDURE CbSelectedLabelfontChoice(w: Fl.Widget);
  VAR item: FlBrowsers.TreeItem; val, count: INTEGER;
BEGIN
  item := tree.First();
  IF item = NIL THEN RETURN END;
  val := selectedLabelfontChoice.Value();
  count := 0; item := tree.First();
  WHILE item # NIL DO
    IF item.IsSelected() THEN item.SetLabelFont(val); INC(count) END;
    item := item.Next()
  END;
  IF count = 0 THEN
    item := tree.First(); WHILE item # NIL DO item.SetLabelFont(val); item := item.Next() END
  END;
  tree.Redraw
END CbSelectedLabelfontChoice;

PROCEDURE CbSelectedLabelsizeSlider(w: Fl.Widget);
  VAR item: FlBrowsers.TreeItem; size, count: INTEGER;
BEGIN
  size := Ival(selectedLabelsizeSlider);
  count := 0; item := tree.First();
  WHILE item # NIL DO
    IF item.IsSelected() THEN item.SetLabelSize(size); INC(count) END;
    item := item.Next()
  END;
  IF count = 0 THEN
    item := tree.First(); WHILE item # NIL DO item.SetLabelSize(size); item := item.Next() END
  END;
  tree.Redraw
END CbSelectedLabelsizeSlider;

PROCEDURE CbAllLabelfgcolorButton(w: Fl.Widget);
  VAR item: FlBrowsers.TreeItem; val, count: INTEGER;
BEGIN
  val := GetSelectedItemFGColor();
  IF ~EditColor(val) THEN RETURN END;
  allLabelfgcolorButton.SetColor(val);
  count := 0; item := tree.First();
  WHILE item # NIL DO
    IF item.IsSelected() THEN item.SetLabelColor(val); INC(count) END;
    item := item.Next()
  END;
  IF count = 0 THEN
    item := tree.First(); WHILE item # NIL DO item.SetLabelColor(val); item := item.Next() END
  END;
  tree.Redraw
END CbAllLabelfgcolorButton;

PROCEDURE CbAllLabelbgcolorButton(w: Fl.Widget);
  VAR item: FlBrowsers.TreeItem; val, count: INTEGER;
BEGIN
  val := GetSelectedItemBGColor();
  IF ~EditColor(val) THEN RETURN END;
  allLabelbgcolorButton.SetColor(val);
  count := 0; item := tree.First();
  WHILE item # NIL DO
    IF item.IsSelected() THEN item.SetLabelBgColor(val); INC(count) END;
    item := item.Next()
  END;
  IF count = 0 THEN
    item := tree.First(); WHILE item # NIL DO item.SetLabelBgColor(val); item := item.Next() END
  END;
  tree.Redraw
END CbAllLabelbgcolorButton;

PROCEDURE CbDeactivateItemsToggle(w: Fl.Widget);
  VAR item: FlBrowsers.TreeItem; on: BOOLEAN; count: INTEGER;
BEGIN
  on := ~deactivateItemsToggle.Value();
  count := 0; item := tree.First();
  WHILE item # NIL DO
    IF item.IsSelected() THEN item.Activate(on); INC(count) END;
    item := item.Next()
  END;
  IF count = 0 THEN
    item := tree.First(); WHILE item # NIL DO item.Activate(on); item := item.Next() END
  END;
  tree.Redraw
END CbDeactivateItemsToggle;

PROCEDURE CbDeactivateTreeToggle(w: Fl.Widget);
BEGIN
  IF deactivateTreeToggle.Value() THEN tree.Deactivate ELSE tree.Activate END
END CbDeactivateTreeToggle;

PROCEDURE CbBoldToggle(w: Fl.Widget);
  VAR item: FlBrowsers.TreeItem; face, count: INTEGER;
BEGIN
  IF boldToggle.Value() THEN face := Fl.HelveticaBold ELSE face := Fl.Helvetica END;
  count := 0; item := tree.First();
  WHILE item # NIL DO
    IF item.IsSelected() THEN item.SetLabelFont(face); INC(count) END;
    item := item.Next()
  END;
  IF count = 0 THEN
    item := tree.First(); WHILE item # NIL DO item.SetLabelFont(face); item := item.Next() END
  END;
  tree.Redraw
END CbBoldToggle;

PROCEDURE CbShowselectedButton(w: Fl.Widget);
  VAR item: FlBrowsers.TreeItem; l: ARRAY 256 OF CHAR; s: ARRAY 300 OF CHAR;
BEGIN
  Print("--- SELECTED ITEMS"); Print(LF);
  item := tree.FirstSelected();
  WHILE item # NIL DO
    item.GetLabel(l); s := 09X; Cat(l, s); Char(LF, s); Print(s);
    item := item.NextSelected()
  END
END CbShowselectedButton;

PROCEDURE CbClearselectedButton(w: Fl.Widget);
  VAR item: FlBrowsers.TreeItem;
BEGIN
  item := tree.First();
  WHILE item # NIL DO
    IF item.IsSelected() THEN
      Detach(item); item.Remove; item := tree.First()
    ELSE item := item.Next()
    END
  END;
  tree.Redraw
END CbClearselectedButton;

PROCEDURE CbSwapselectedButton(w: Fl.Widget);
  VAR item, a, b, pa, pb: FlBrowsers.TreeItem; ai, bi, t: INTEGER;
BEGIN
  a := NIL; b := NIL;
  item := tree.First();
  WHILE item # NIL DO
    IF item.IsSelected() THEN
      IF a = NIL THEN a := item
      ELSIF b = NIL THEN b := item
      ELSE FlDialogs.Alert("Too many items selected. (must select only two)"); RETURN
      END
    END;
    item := item.Next()
  END;
  IF (a = NIL) OR (b = NIL) THEN
    FlDialogs.Alert("Too few items selected. (you must select two)"); RETURN
  END;
  pa := a.Parent(); pb := b.Parent();
  IF ~FlBrowsers.Same(pa, pb) THEN
    FlDialogs.Alert("The two selected items must be siblings"); RETURN
  END;
  ai := -1; bi := -1;
  FOR t := 0 TO pa.Children() - 1 DO
    IF FlBrowsers.Same(pa.Child(t), a) THEN ai := t END;
    IF FlBrowsers.Same(pa.Child(t), b) THEN bi := t END
  END;
  pa.SwapChildren(ai, bi);
  tree.Redraw
END CbSwapselectedButton;

PROCEDURE CbSelectallButton(w: Fl.Widget);
BEGIN SelectAll(NIL, TRUE); tree.Redraw
END CbSelectallButton;

PROCEDURE CbDeselectallButton(w: Fl.Widget);
BEGIN DeselectAll(NIL, TRUE); tree.Redraw
END CbDeselectallButton;

PROCEDURE CbNextselectedButton(w: Fl.Widget);
  VAR item: FlBrowsers.TreeItem; l: ARRAY 256 OF CHAR; s: ARRAY 300 OF CHAR;
BEGIN
  Print("--- TEST next_selected():"); Print(LF);
  Print("    // Walk down the tree (forwards)"); Print(LF);
  item := tree.FirstSelected();
  WHILE item # NIL DO
    item.GetLabel(l); s := "    Selected item: "; Cat(l, s); Char(LF, s); Print(s);
    item := item.NextSelected()
  END;
  Print("    // Walk up the tree (backwards)"); Print(LF);
  item := tree.LastSelected();
  WHILE item # NIL DO
    item.GetLabel(l); s := "    Selected item: "; Cat(l, s); Char(LF, s); Print(s);
    item := item.PrevSelected()
  END
END CbNextselectedButton;

(* item, or an alert that path wasn't found. *)
PROCEDURE Found(path-, fail-: ARRAY OF CHAR): FlBrowsers.TreeItem;
  VAR item: FlBrowsers.TreeItem;
BEGIN
  item := tree.Find(path);
  IF item = NIL THEN FlDialogs.Alert(fail) END;
  RETURN item
END Found;

PROCEDURE CbBbbselectToggle(w: Fl.Widget);
  VAR item: FlBrowsers.TreeItem; ok: BOOLEAN;
BEGIN
  item := Found("/Bbb", "FAIL: Couldn't find item '/Bbb'???");
  IF item # NIL THEN
    IF bbbselectToggle.Value() THEN ok := TreeSelect(item, TRUE) ELSE ok := TreeDeselect(item, TRUE) END
  END
END CbBbbselectToggle;

PROCEDURE CbBbbselect2Toggle(w: Fl.Widget);
  VAR item: FlBrowsers.TreeItem;
BEGIN
  item := Found("/Bbb", "FAIL: Couldn't find item '/Bbb'???");
  IF item # NIL THEN
    IF bbbselect2Toggle.Value() THEN SelectAll(item, TRUE) ELSE DeselectAll(item, TRUE) END
  END
END CbBbbselect2Toggle;

PROCEDURE CbBbbchild02selectToggle(w: Fl.Widget);
  VAR item: FlBrowsers.TreeItem; ok: BOOLEAN;
BEGIN
  item := Found("/Bbb/child-02", "FAIL: Couldn't find item '/Bbb/child-02'");
  IF item # NIL THEN
    IF bbbchild02selectToggle.Value() THEN ok := TreeSelect(item, TRUE) ELSE ok := TreeDeselect(item, TRUE) END
  END
END CbBbbchild02selectToggle;

PROCEDURE CbRootselectToggle(w: Fl.Widget);
  VAR item: FlBrowsers.TreeItem; ok: BOOLEAN;
BEGIN
  item := Found("/ROOT", "FAIL: Couldn't find item '/ROOT'???");
  IF item # NIL THEN
    IF rootselectToggle.Value() THEN ok := TreeSelect(item, TRUE) ELSE ok := TreeDeselect(item, TRUE) END
  END
END CbRootselectToggle;

PROCEDURE CbRootselect2Toggle(w: Fl.Widget);
  VAR item: FlBrowsers.TreeItem;
BEGIN
  item := Found("/ROOT", "FAIL: Couldn't find item '/ROOT'???");
  IF item # NIL THEN
    IF rootselect2Toggle.Value() THEN SelectAll(item, TRUE) ELSE DeselectAll(item, TRUE) END
  END
END CbRootselect2Toggle;

(* The tree's fonts and colours *)

PROCEDURE CbLabelfontChoice(w: Fl.Widget);
BEGIN tree.SetLabelFont(labelfontChoice.Value()); window.Redraw
END CbLabelfontChoice;

PROCEDURE CbLabelsizeSlider(w: Fl.Widget);
BEGIN tree.SetLabelSize(Ival(labelsizeSlider)); window.Redraw
END CbLabelsizeSlider;

PROCEDURE CbItemLabelfontChoice(w: Fl.Widget);
BEGIN tree.SetItemLabelFont(itemLabelfontChoice.Value()); tree.Redraw
END CbItemLabelfontChoice;

PROCEDURE CbItemLabelsizeSlider(w: Fl.Widget);
BEGIN tree.SetItemLabelSize(Ival(itemLabelsizeSlider)); tree.Redraw
END CbItemLabelsizeSlider;

PROCEDURE CbLabelcolorButton(w: Fl.Widget);
  VAR val: INTEGER;
BEGIN
  val := tree.LabelColor();
  IF ~EditColor(val) THEN RETURN END;
  labelcolorButton.SetColor(val); tree.SetLabelColor(val); window.Redraw
END CbLabelcolorButton;

PROCEDURE CbColorButton(w: Fl.Widget);
  VAR val: INTEGER;
BEGIN
  val := tree.Color();
  IF ~EditColor(val) THEN RETURN END;
  colorButton.SetColor(val); tree.SetColor(val); UpdateColorChips; tree.Redraw
END CbColorButton;

PROCEDURE CbSelectionColorButton(w: Fl.Widget);
  VAR val: INTEGER;
BEGIN
  val := tree.SelectionColor();
  IF ~EditColor(val) THEN RETURN END;
  selectionColorButton.SetColor(val); tree.SetSelectionColor(val); tree.Redraw
END CbSelectionColorButton;

PROCEDURE CbItemLabelfgcolorButton(w: Fl.Widget);
  VAR val: INTEGER;
BEGIN
  val := tree.ItemLabelColor();
  IF ~EditColor(val) THEN RETURN END;
  tree.SetItemLabelColor(val); itemLabelfgcolorButton.SetColor(val); tree.Redraw
END CbItemLabelfgcolorButton;

PROCEDURE CbItemLabelbgcolorButton(w: Fl.Widget);
  VAR val: INTEGER;
BEGIN
  val := tree.ItemLabelBgColor();
  IF ~EditColor(val) THEN RETURN END;
  tree.SetItemLabelBgColor(val); itemLabelbgcolorButton.SetColor(val); tree.Redraw
END CbItemLabelbgcolorButton;

PROCEDURE CbXItemLabelbgcolorButton(w: Fl.Widget);
BEGIN tree.SetItemLabelBgColor(-1); UpdateColorChips; tree.Redraw
END CbXItemLabelbgcolorButton;

PROCEDURE CbTreeScrollbarSizeSlider(w: Fl.Widget);
BEGIN tree.SetScrollbarSize(Ival(treeScrollbarSizeSlider)); tree.Redraw
END CbTreeScrollbarSizeSlider;

PROCEDURE CbScrollbarSizeSlider(w: Fl.Widget);
BEGIN Fl.SetScrollbarSize(Ival(scrollbarSizeSlider)); tree.Redraw
END CbScrollbarSizeSlider;

PROCEDURE H(line-: ARRAY OF CHAR);
BEGIN Cat(line, help); Char(LF, help)
END H;

PROCEDURE MakeHelp;
BEGIN
  help := "";
  H("CHILD WIDGET SIZING TESTS");
  H("=========================");
  H("   1) Start program");
  H("   2) Click the 'ccc button' and D1/D2 buttons.");
  H("      Their sizes should not change.");
  H("   3) Click the 'Item h() from widget' checkbox.");
  H("   4) Click the 'ccc button' and D1/D2 buttons.");
  H("      Their sizes should change, getting larger vertically.");
  H("      This validates that widget's size can affect the tree.");
  H("   5) Disable the checkbox, widgets should resize back to the");
  H("      size of the other items.");
  H("   6) Hit ^A to select all items");
  H("   7) Under 'Selected Items', drag the 'Label Size' slider around.");
  H("      All the item's height should change, as well as child widgets.");
  H("   8) Put Label Size' slider back to normal");
  H("");
  H("CHILD WIDGET + LABEL ITEM DRAWING TESTS");
  H("=======================================");
  H("   1) Start program");
  H("   2) Click 'Show label + widget'.");
  H("      The widgets should all show item labels to their left.");
  H("   3) Disable same, item labels should disappear,");
  H("      showing the widgets in their place.");
  H("");
  H("COLORS");
  H("======");
  H("   1) Start program");
  H("   2) Change 'Tree Fonts+Colors' -> color()");
  H("   3) Entire tree's background color will change, including items.");
  H("   4) Change the 'Tree Fonts + Colors -> item_labelbgcolor()'");
  H("   6) Click the '111' item to select it.");
  H("   7) Click 'Test Operations -> Insert Above'");
  H("      New items should appear above the selected item using the new color.");
  H("      This color will be different from the background color.");
  H("   8) Change the 'Tree Fonts+Colors' -> color()");
  H("      The entire tree's bg should change, except the new items.");
  H("   9) Click the Tree Fonts+Colors -> item_labelbgcolor() 'X' button.");
  H("      This resets item_labelbgcolor() to the default 'transparent' color (0xffffffff)");
  H("  10) Again, click the 'Insert Above' button.");
  H("      New items will be created in the background color, and changing the color()");
  H("      should affect the new items too.");
  H("");
  H("SCROLLING");
  H("=========");
  H("   1) Open '500 items' and 'Long Line' so that both scrollbars appear:");
  H("        * The 'focus box' for the selected item should not be clipped");
  H("          horizontally by the vertical scrollbar.");
  H("        * Resizing the window horizontally should resize the focus box");
  H("        * Scrolling vertically/horizontally should show reveal all");
  H("          edges of the tree. One *exception* is the widget label");
  H("          to the right of the 'ccc button'; labels aren't part");
  H("          of the widget, and therefore don't affect scroll tabs");
  H("   2) Scroll vertical scroller to the middle of the tree");
  H("   3) Left click and drag up/down to extend the selection:");
  H("        * Selection should autoscroll if you drag off the top/bottom");
  H("        * Selection should work *even* if you drag horizontally");
  H("          off the window edge; moving up/down outside the window");
  H("          should continue to autoscroll");
  H("   4) Click either of the the scrollbar tabs and drag:");
  H("        * Even if you drag off the scrollbar, the scrollbar");
  H("          tab should continue to move");
  H("        * Should continue to work if you drag off the window edge");
  H("          horizontally drag off the window.");
  H("   5) Click 'Bbb' and hit 'Add 20,000', then position the");
  H("      'ccc button' so it's partially obscured by a scrollbar tab:");
  H("        * Clicking the obscured button should work");
  H("        * Clicking on the tab over the button should not 'click through'");
  H("          to the button.");
END MakeHelp;

PROCEDURE CbTestsuggsButton(w: Fl.Widget);
BEGIN
  IF helpWin = NIL THEN
    NEW(helpWin); Fl.OpenDoubleWindow(helpWin, 600, 600, "Test Suggestions");
    NEW(helpDisp); FlText.OpenTextDisplay(helpDisp, 0, 0, 600, 600, "");
    NEW(helpBuf); FlText.OpenBuffer(helpBuf);
    helpDisp.SetBuffer(helpBuf);
    helpDisp.SetTextFont(Fl.Courier); helpDisp.SetTextSize(12);
    MakeHelp; helpBuf.SetText(help);
    helpWin.End
  END;
  helpWin.SetResizable(helpDisp);
  helpWin.Show
END CbTestsuggsButton;

PROCEDURE BuildWindow;
  VAR s: ARRAY 1024 OF CHAR; ok: BOOLEAN;
BEGIN
  NEW(window); Fl.OpenDoubleWindow(window, 1045, 730, "tree");
  NEW(tree); FlBrowsers.OpenTree(tree, 15, 22, 320, 539, "Tree");
  Tip(tree, "Test tree");
  tree.SetBoxType(Fl.DownBox);
  tree.SetColor(55);
  tree.SetSelectionColor(Fl.SelectionColor);
  tree.SetLabelFont(0);
  tree.SetLabelSize(14);
  tree.SetLabelColor(Fl.ForegroundColor);
  tree.action := CbTree;
  tree.SetAlign(Fl.AlignTop);
  tree.SetWhen(Fl.WhenRelease);
  NEW(g2); Fl.OpenGroup(g2, 350, 5, 681, 556, "");
  NEW(g3); Fl.OpenGroup(g3, 350, 23, 330, 389, "Tree Globals");
  Tip(g3, "These controls only affect the selected items. If no items are selected, all existing items in tree are modified.");
  g3.SetBoxType(Fl.GtkDownBox);
  g3.SetColor(Fl.Dark1);
  g3.SetLabelSize(12);
  NEW(margintopSlider); FlValuators.OpenValueSlider(margintopSlider, 505, 36, 155, 16, "margintop()");
  Tip(margintopSlider, "Changes the top margin for the tree widget");
  margintopSlider.SetKind(1);
  margintopSlider.SetColor(46);
  margintopSlider.SetSelectionColor(1);
  margintopSlider.SetLabelSize(10);
  margintopSlider.SetTextSize(9);
  margintopSlider.action := CbMargintopSlider;
  margintopSlider.SetAlign(Fl.AlignLeft);
  margintopSlider.SetValue(tree.MarginTop());
  margintopSlider.SetBounds(0, 100);
  margintopSlider.SetStep(1);
  NEW(marginleftSlider); FlValuators.OpenValueSlider(marginleftSlider, 505, 56, 155, 16, "marginleft()");
  Tip(marginleftSlider, "Changes the left margin for the tree widget");
  marginleftSlider.SetKind(1);
  marginleftSlider.SetColor(46);
  marginleftSlider.SetSelectionColor(1);
  marginleftSlider.SetLabelSize(10);
  marginleftSlider.SetTextSize(9);
  marginleftSlider.action := CbMarginleftSlider;
  marginleftSlider.SetAlign(Fl.AlignLeft);
  marginleftSlider.SetValue(tree.MarginLeft());
  marginleftSlider.SetBounds(0, 200);
  marginleftSlider.SetStep(1);
  NEW(marginbottomSlider); FlValuators.OpenValueSlider(marginbottomSlider, 505, 76, 155, 16, "marginbottom()");
  Tip(marginbottomSlider, "Changes the bottom margin for the tree|Sets how far beyond bottom of tree you can scroll");
  marginbottomSlider.SetKind(1);
  marginbottomSlider.SetColor(46);
  marginbottomSlider.SetSelectionColor(1);
  marginbottomSlider.SetLabelSize(10);
  marginbottomSlider.SetTextSize(9);
  marginbottomSlider.action := CbMarginbottomSlider;
  marginbottomSlider.SetAlign(Fl.AlignLeft);
  marginbottomSlider.SetValue(tree.MarginBottom());
  marginbottomSlider.SetBounds(0, 275);
  marginbottomSlider.SetStep(1);
  marginbottomSlider.DoCallback;
  NEW(linespacingSlider); FlValuators.OpenValueSlider(linespacingSlider, 505, 96, 155, 16, "linespacing()");
  Tip(linespacingSlider, "Changes the spacing between items in the tree");
  linespacingSlider.SetKind(1);
  linespacingSlider.SetColor(46);
  linespacingSlider.SetSelectionColor(1);
  linespacingSlider.SetLabelSize(10);
  linespacingSlider.SetTextSize(9);
  linespacingSlider.action := CbLinespacingSlider;
  linespacingSlider.SetAlign(Fl.AlignLeft);
  linespacingSlider.SetValue(tree.LineSpacing());
  linespacingSlider.SetBounds(0, 100);
  linespacingSlider.SetStep(1);
  NEW(usericonmarginleftSlider); FlValuators.OpenValueSlider(usericonmarginleftSlider, 505, 116, 155, 16, "usericonmarginleft()");
  Tip(usericonmarginleftSlider, "Changes the left margin for the user icons (if any)");
  usericonmarginleftSlider.SetKind(1);
  usericonmarginleftSlider.SetColor(46);
  usericonmarginleftSlider.SetSelectionColor(1);
  usericonmarginleftSlider.SetLabelSize(10);
  usericonmarginleftSlider.SetTextSize(9);
  usericonmarginleftSlider.action := CbUsericonmarginleftSlider;
  usericonmarginleftSlider.SetAlign(Fl.AlignLeft);
  usericonmarginleftSlider.SetValue(tree.UserIconMarginLeft());
  usericonmarginleftSlider.SetBounds(0, 100);
  usericonmarginleftSlider.SetStep(1);
  NEW(labelmarginleftSlider); FlValuators.OpenValueSlider(labelmarginleftSlider, 505, 136, 155, 16, "labelmarginleft()");
  Tip(labelmarginleftSlider, "Changes the left margin for the item label");
  labelmarginleftSlider.SetKind(1);
  labelmarginleftSlider.SetColor(46);
  labelmarginleftSlider.SetSelectionColor(1);
  labelmarginleftSlider.SetLabelSize(10);
  labelmarginleftSlider.SetTextSize(9);
  labelmarginleftSlider.action := CbLabelmarginleftSlider;
  labelmarginleftSlider.SetAlign(Fl.AlignLeft);
  labelmarginleftSlider.SetValue(tree.LabelMarginLeft());
  labelmarginleftSlider.SetBounds(0, 100);
  labelmarginleftSlider.SetStep(1);
  NEW(widgetmarginleftSlider); FlValuators.OpenValueSlider(widgetmarginleftSlider, 505, 156, 155, 16, "widgetmarginleft()");
  Tip(widgetmarginleftSlider, "Changes the margin to the left of child FLTK widget()|`Show label + widget` must be 'on' for this to take effect, i.e.|item_draw_mode(FL_TREE_ITEM_DRAW_LABEL_AND_WIDGET)");
  widgetmarginleftSlider.SetKind(1);
  widgetmarginleftSlider.SetColor(46);
  widgetmarginleftSlider.SetSelectionColor(1);
  widgetmarginleftSlider.SetLabelSize(10);
  widgetmarginleftSlider.SetTextSize(9);
  widgetmarginleftSlider.action := CbWidgetmarginleftSlider;
  widgetmarginleftSlider.SetAlign(Fl.AlignLeft);
  widgetmarginleftSlider.SetValue(tree.WidgetMarginLeft());
  widgetmarginleftSlider.SetBounds(0, 100);
  widgetmarginleftSlider.SetStep(1);
  widgetmarginleftSlider.DoCallback;
  NEW(openchildMarginbottomSlider); FlValuators.OpenValueSlider(openchildMarginbottomSlider, 505, 176, 155, 16, "openchild_marginbottom()");
  Tip(openchildMarginbottomSlider, "Changes the vertical space below an open child tree");
  openchildMarginbottomSlider.SetKind(1);
  openchildMarginbottomSlider.SetColor(46);
  openchildMarginbottomSlider.SetSelectionColor(1);
  openchildMarginbottomSlider.SetLabelSize(10);
  openchildMarginbottomSlider.SetTextSize(9);
  openchildMarginbottomSlider.action := CbOpenchildMarginbottomSlider;
  openchildMarginbottomSlider.SetAlign(Fl.AlignLeft);
  openchildMarginbottomSlider.SetValue(tree.OpenChildMarginBottom());
  openchildMarginbottomSlider.SetBounds(0, 100);
  openchildMarginbottomSlider.SetStep(1);
  NEW(connectorwidthSlider); FlValuators.OpenValueSlider(connectorwidthSlider, 505, 195, 155, 16, "connectorwidth()");
  Tip(connectorwidthSlider, "Tests Fl_Tree::connectorwidth()");
  connectorwidthSlider.SetKind(1);
  connectorwidthSlider.SetColor(46);
  connectorwidthSlider.SetSelectionColor(1);
  connectorwidthSlider.SetLabelSize(11);
  connectorwidthSlider.SetTextSize(9);
  connectorwidthSlider.action := CbConnectorwidthSlider;
  connectorwidthSlider.SetAlign(Fl.AlignLeft);
  connectorwidthSlider.SetValue(tree.ConnectorWidth());
  connectorwidthSlider.SetBounds(1, 100);
  connectorwidthSlider.SetStep(1);
  connectorwidthSlider.SetColor(46);
  connectorwidthSlider.SetSelectionColor(Fl.Red);
  NEW(collapseiconsChooser); FlMenus.OpenChoice(collapseiconsChooser, 520, 221, 140, 21, "Collapse icons");
  Tip(collapseiconsChooser, "Tests Fl_Tree::openicon(), Fl_Tree::closeicon() and Fl_Tree::showcollapse().");
  collapseiconsChooser.SetDownBox(Fl.BorderBox);
  collapseiconsChooser.SetLabelSize(12);
  collapseiconsChooser.SetTextSize(11);
  collapseiconsChooser.action := CbCollapseiconsChooser;
  Items(collapseiconsChooser, "Default|Custom|Off");
  ok := collapseiconsChooser.SetValue(0);
  NEW(connectorstyleChooser); FlMenus.OpenChoice(connectorstyleChooser, 520, 245, 140, 21, "Line style");
  Tip(connectorstyleChooser, "Tests Fl_Tree::connectorstyle() bit flags");
  connectorstyleChooser.SetDownBox(Fl.BorderBox);
  connectorstyleChooser.SetLabelSize(12);
  connectorstyleChooser.SetTextSize(11);
  connectorstyleChooser.action := CbConnectorstyleChooser;
  Items(connectorstyleChooser, "None|Dotted|Solid");
  ok := connectorstyleChooser.SetValue(0);
  ok := connectorstyleChooser.SetValue(tree.ConnectorStyle());
  NEW(selectmodeChooser); FlMenus.OpenChoice(selectmodeChooser, 520, 269, 140, 21, "Selection Mode");
  Tip(selectmodeChooser, "Tests Fl_Tree::selectmode()|Sets how Fl_Tree handles mouse selection of tree items.|    NONE        -- Not selectable by keyboard/mouse|    SINGLE      -- Only one item at a time selectable by keyboard/mouse|    MULTI       -- Multiple items selectable|    SINGLE+DRAG -- Lets user drag items to different position in tree");
  selectmodeChooser.SetDownBox(Fl.BorderBox);
  selectmodeChooser.SetLabelSize(12);
  selectmodeChooser.SetTextSize(11);
  selectmodeChooser.action := CbSelectmodeChooser;
  Items(selectmodeChooser, "None|Single|Multi|Single + drag");
  ok := selectmodeChooser.SetValue(0);
  ok := selectmodeChooser.SetValue(2);
  CbSelectmodeChooser(selectmodeChooser);
  NEW(reselectmodeChooser); FlMenus.OpenChoice(reselectmodeChooser, 520, 293, 140, 21, "Item Reselect Mode");
  Tip(reselectmodeChooser, "Tests Fl_Tree::item_reselect_mode().|Enables 'reselect' events.|These happen when someone selects an item already selected|(mouse drags or multi-clicks)");
  reselectmodeChooser.SetDownBox(Fl.BorderBox);
  reselectmodeChooser.SetLabelSize(12);
  reselectmodeChooser.SetTextSize(11);
  reselectmodeChooser.action := CbReselectmodeChooser;
  Items(reselectmodeChooser, "Selectable Once|Selectable Always");
  ok := reselectmodeChooser.SetValue(0);
  ok := reselectmodeChooser.SetValue(1);
  reselectmodeChooser.DoCallback;
  NEW(whenmodeChooser); FlMenus.OpenChoice(whenmodeChooser, 520, 319, 140, 21, "When");
  Tip(whenmodeChooser, "Sets when() the tree's callback is invoked");
  whenmodeChooser.SetDownBox(Fl.BorderBox);
  whenmodeChooser.SetLabelSize(12);
  whenmodeChooser.SetTextSize(11);
  whenmodeChooser.action := CbWhenmodeChooser;
  Items(whenmodeChooser, "Changed|Released|Never");
  ok := whenmodeChooser.SetValue(0);
  ok := whenmodeChooser.SetValue(1);
  CbWhenmodeChooser(whenmodeChooser);
  NEW(usericonRadio); FlButtons.OpenCheckButton(usericonRadio, 485, 351, 20, 16, "Enable user icons?");
  Tip(usericonRadio, "Tests Fl_Tree_Item::usericon()");
  usericonRadio.SetDownBox(Fl.DownBox);
  usericonRadio.SetLabelSize(11);
  usericonRadio.action := CbUsericonRadio;
  usericonRadio.SetAlign(Fl.AlignLeftTop);
  usericonRadio.SetValue(TRUE);
  NEW(showrootRadio); FlButtons.OpenCheckButton(showrootRadio, 485, 368, 20, 16, "Show root?");
  Tip(showrootRadio, "Tests tree->showroot();");
  showrootRadio.SetDownBox(Fl.DownBox);
  showrootRadio.SetLabelSize(11);
  showrootRadio.action := CbShowrootRadio;
  showrootRadio.SetAlign(Fl.AlignLeftTop);
  showrootRadio.SetValue(tree.ShowRoot());
  NEW(visiblefocusCheckbox); FlButtons.OpenCheckButton(visiblefocusCheckbox, 485, 385, 20, 16, "Visible focus?");
  Tip(visiblefocusCheckbox, "Toggles the tree's visible_focus() box");
  visiblefocusCheckbox.SetDownBox(Fl.DownBox);
  visiblefocusCheckbox.SetLabelSize(11);
  visiblefocusCheckbox.action := CbVisiblefocusCheckbox;
  visiblefocusCheckbox.SetAlign(Fl.AlignLeftTop);
  visiblefocusCheckbox.SetValue(tree.VisibleFocus());
  NEW(labelandwidgetRadio); FlButtons.OpenCheckButton(labelandwidgetRadio, 645, 351, 20, 16, "Show label + widget");
  Tip(labelandwidgetRadio, "Tests Fl_Tree::item_draw_mode(FL_TREE_ITEM_DRAW_LABEL_AND_WIDGET)|Enables both label and widget() for display.|When enabled, widget should appear to the right of the item's label.|By default, the widget() is shown in place of the item's label.");
  labelandwidgetRadio.SetDownBox(Fl.DownBox);
  labelandwidgetRadio.SetLabelSize(11);
  labelandwidgetRadio.action := CbLabelandwidgetRadio;
  labelandwidgetRadio.SetAlign(Fl.AlignLeftTop);
  labelandwidgetRadio.SetValue(FALSE);
  labelandwidgetRadio.DoCallback;
  NEW(itemheightfromwidgetRadio); FlButtons.OpenCheckButton(itemheightfromwidgetRadio, 645, 368, 20, 16, "Item h() from widget");
  Tip(itemheightfromwidgetRadio, "Tests Fl_Tree::item_draw_mode(FL_TREE_ITEM_HEIGHT_FROM_WIDGET)|If enabled, item's height will track the widget()'s height.|When enabled, click 'ccc button' or 'D1/D2' buttons to test.");
  itemheightfromwidgetRadio.SetDownBox(Fl.DownBox);
  itemheightfromwidgetRadio.SetLabelSize(11);
  itemheightfromwidgetRadio.action := CbItemheightfromwidgetRadio;
  itemheightfromwidgetRadio.SetAlign(Fl.AlignLeftTop);
  itemheightfromwidgetRadio.SetValue(FALSE);
  itemheightfromwidgetRadio.DoCallback;
  NEW(globalvisiblefocusCheckbox); FlButtons.OpenCheckButton(globalvisiblefocusCheckbox, 645, 385, 20, 16, "Global visible focus?");
  Tip(globalvisiblefocusCheckbox, "Toggles the global Fl::visible_focus()");
  globalvisiblefocusCheckbox.SetDownBox(Fl.DownBox);
  globalvisiblefocusCheckbox.SetLabelSize(11);
  globalvisiblefocusCheckbox.action := CbGlobalvisiblefocusCheckbox;
  globalvisiblefocusCheckbox.SetAlign(Fl.AlignLeftTop);
  globalvisiblefocusCheckbox.SetValue(Fl.Option(Fl.OptionVisibleFocus));
  g3.End;
  NEW(g3); Fl.OpenGroup(g3, 350, 435, 330, 125, "Test Operations");
  Tip(g3, "These controls only affect the defaults for new items that are created. These test the Fl_Tree_Prefs methods.");
  g3.SetBoxType(Fl.GtkDownBox);
  g3.SetColor(Fl.Dark1);
  g3.SetLabelSize(12);
  s := "show_item()|"; Lines(s);
  NEW(showitemBox); Fl.OpenGroup(showitemBox, 370, 460, 70, 82, s);
  showitemBox.SetBoxType(Fl.GtkDownBox);
  showitemBox.SetLabelSize(11);
  NEW(b); FlButtons.OpenButton(b, 385, 469, 40, 17, "Show");
  Tip(b, "Tests show_item() with no position specified.|Makes the selected item visible IF it is off-screen.|No change made if it is not off-screen.");
  b.SetLabelSize(11);
  b.action := CbShow;
  NEW(b); FlButtons.OpenButton(b, 385, 486, 40, 16, "Top");
  Tip(b, "Test show_item_top().|Scrolls selected item to the top of the display|(only works if scrollbar showing)|To use:|1) open '500 items'|2) select item 0010|3) Hit Top/Mid/Bot");
  b.SetLabelSize(11);
  b.action := CbTop;
  NEW(b); FlButtons.OpenButton(b, 385, 502, 40, 16, "Mid");
  Tip(b, "Tests show_item_middle().|Scrolls the selected item to the middle of the display|To use:|  1) open '500 items'|  2) select 'item 0010'|  3) Hit Top/Mid/Bot");
  b.SetLabelSize(11);
  b.action := CbMid;
  NEW(b); FlButtons.OpenButton(b, 385, 518, 40, 16, "Bot");
  Tip(b, "Tests show_item_bottom().|Scrolls the selected item to the bottom of the display|To use:|  1) open '500 items'|  2) select 'item 0010'|  3) Hit Top/Mid/Bot");
  b.SetLabelSize(11);
  b.action := CbBot;
  showitemBox.End;
  NEW(openallButton); FlButtons.OpenButton(openallButton, 470, 451, 95, 16, "Open All");
  Tip(openallButton, "Opens all nodes that have children");
  openallButton.SetLabelSize(9);
  openallButton.action := CbOpenallButton;
  NEW(loaddbButton); FlButtons.OpenButton(loaddbButton, 470, 471, 95, 16, "Load Database...");
  Tip(loaddbButton, "Load the contents of an Fl_Preferences database into the tree view");
  loaddbButton.SetLabelSize(9);
  loaddbButton.action := CbLoaddbButton;
  NEW(insertaboveButton); FlButtons.OpenButton(insertaboveButton, 470, 491, 95, 16, "Insert Above");
  Tip(insertaboveButton, "Inserts three items above the selected items");
  insertaboveButton.SetLabelSize(9);
  insertaboveButton.action := CbInsertaboveButton;
  NEW(rebuildtreeButton); FlButtons.OpenButton(rebuildtreeButton, 470, 511, 95, 16, "Rebuild Tree");
  Tip(rebuildtreeButton, "Rebuilds the tree with defaults");
  rebuildtreeButton.SetLabelSize(9);
  rebuildtreeButton.action := CbRebuildtreeButton;
  NEW(showpathnameButton); FlButtons.OpenButton(showpathnameButton, 470, 531, 95, 16, "Show Pathname");
  Tip(showpathnameButton, "Tests Fl_Tree::item_pathname()|Show the pathname for the selected item.");
  showpathnameButton.SetLabelSize(9);
  showpathnameButton.action := CbShowpathnameButton;
  NEW(closeallButton); FlButtons.OpenButton(closeallButton, 570, 451, 95, 16, "Close All");
  Tip(closeallButton, "Closes all nodes that have children|(doesn't affect 'root')");
  closeallButton.SetLabelSize(9);
  closeallButton.action := CbCloseallButton;
  NEW(clearallButton); FlButtons.OpenButton(clearallButton, 570, 471, 95, 16, "Clear All");
  Tip(clearallButton, "Tests Fl_Tree::clear().|Clears all items");
  clearallButton.SetLabelSize(9);
  clearallButton.action := CbClearallButton;
  NEW(testcallbackflagButton); FlButtons.OpenButton(testcallbackflagButton, 570, 491, 95, 16, "Test Callback Flag");
  Tip(testcallbackflagButton, "Test the 'docallback' argument can disable callbacks.");
  testcallbackflagButton.SetLabelSize(9);
  testcallbackflagButton.action := CbTestcallbackflagButton;
  NEW(testrootshowselfButton); FlButtons.OpenButton(testrootshowselfButton, 570, 511, 95, 16, "Root Show Self");
  Tip(testrootshowselfButton, "Test the root->'show_self() method to show the entire tree on stdout");
  testrootshowselfButton.SetLabelSize(9);
  testrootshowselfButton.action := CbTestrootshowselfButton;
  NEW(add20kButton); FlButtons.OpenButton(add20kButton, 570, 531, 95, 16, "Add 20,000");
  Tip(add20kButton, "Adds 20,000 items to the selected item's parent");
  add20kButton.SetLabelSize(9);
  add20kButton.action := CbAdd20kButton;
  g3.End;
  NEW(g3); Fl.OpenGroup(g3, 696, 23, 335, 246, "Selected Items");
  Tip(g3, "These controls only affect the selected items. If no items are selected, all existing items in tree are modified.");
  g3.SetBoxType(Fl.GtkDownBox);
  g3.SetColor(Fl.Dark1);
  g3.SetLabelSize(12);
  NEW(selectedLabelfontChoice); FlMenus.OpenChoice(selectedLabelfontChoice, 863, 31, 140, 21, "Fl_Tree_Item::labelfont()");
  Tip(selectedLabelfontChoice, "Tests Fl_Tree_Item::labelfont();|Changes the font for the selected items's labels.|If none selected, all are changed.");
  selectedLabelfontChoice.SetDownBox(Fl.BorderBox);
  selectedLabelfontChoice.SetLabelSize(11);
  selectedLabelfontChoice.SetTextSize(11);
  selectedLabelfontChoice.action := CbSelectedLabelfontChoice;
  FontItems(selectedLabelfontChoice);
  ok := selectedLabelfontChoice.SetValue(0);
  ok := selectedLabelfontChoice.SetValue(tree.ItemLabelFont());
  NEW(selectedLabelsizeSlider); FlValuators.OpenValueSlider(selectedLabelsizeSlider, 863, 55, 140, 16, "Fl_Tree_Item::labelsize()");
  Tip(selectedLabelsizeSlider, "Tests Fl_Tree_Item::labelsize();|Changes the font size of the selected items's labels.|If none selected, all are changed.");
  selectedLabelsizeSlider.SetKind(1);
  selectedLabelsizeSlider.SetColor(46);
  selectedLabelsizeSlider.SetSelectionColor(1);
  selectedLabelsizeSlider.SetLabelSize(11);
  selectedLabelsizeSlider.SetTextSize(12);
  selectedLabelsizeSlider.action := CbSelectedLabelsizeSlider;
  selectedLabelsizeSlider.SetAlign(Fl.AlignLeft);
  selectedLabelsizeSlider.SetValue(tree.ItemLabelSize());
  selectedLabelsizeSlider.SetBounds(5, 200);
  selectedLabelsizeSlider.SetStep(1);
  selectedLabelsizeSlider.SetColor(46);
  selectedLabelsizeSlider.SetSelectionColor(Fl.Red);
  NEW(allLabelfgcolorButton); FlButtons.OpenButton(allLabelfgcolorButton, 863, 81, 16, 16, "Fl_Tree_Item::labelfgcolor()");
  Tip(allLabelfgcolorButton, "Sets the Fl_Tree_Item::labelfgcolor() for the selected items. If none selected, all are changed.");
  allLabelfgcolorButton.SetBoxType(Fl.DownBox);
  allLabelfgcolorButton.SetLabelSize(11);
  allLabelfgcolorButton.action := CbAllLabelfgcolorButton;
  allLabelfgcolorButton.SetAlign(Fl.AlignLeftTop);
  allLabelfgcolorButton.SetColor(GetSelectedItemFGColor());
  NEW(allLabelbgcolorButton); FlButtons.OpenButton(allLabelbgcolorButton, 863, 99, 16, 16, "Fl_Tree_Item::labelbgcolor()");
  Tip(allLabelbgcolorButton, "Sets the Fl_Tree_Item::labelbgcolor() for the selected items. If none selected, all are changed.");
  allLabelbgcolorButton.SetBoxType(Fl.DownBox);
  allLabelbgcolorButton.SetLabelSize(11);
  allLabelbgcolorButton.action := CbAllLabelbgcolorButton;
  allLabelbgcolorButton.SetAlign(Fl.AlignLeftTop);
  allLabelbgcolorButton.SetColor(GetSelectedItemBGColor());
  NEW(deactivateItemsToggle); FlButtons.OpenLightButton(deactivateItemsToggle, 758, 134, 100, 16, " Deactivate Items");
  Tip(deactivateItemsToggle, "Toggle the deactivation state of the selected items.|If none are selected, all are set.");
  deactivateItemsToggle.SetSelectionColor(1);
  deactivateItemsToggle.SetLabelSize(9);
  deactivateItemsToggle.action := CbDeactivateItemsToggle;
  NEW(deactivateTreeToggle); FlButtons.OpenLightButton(deactivateTreeToggle, 758, 154, 100, 16, " Deactivate Tree");
  Tip(deactivateTreeToggle, "Deactivates the entire tree widget");
  deactivateTreeToggle.SetSelectionColor(1);
  deactivateTreeToggle.SetLabelSize(9);
  deactivateTreeToggle.action := CbDeactivateTreeToggle;
  NEW(boldToggle); FlButtons.OpenLightButton(boldToggle, 758, 174, 100, 16, " Bold Font");
  Tip(boldToggle, "Toggles bold font for selected items|If nothing selected, all are changed");
  boldToggle.SetSelectionColor(1);
  boldToggle.SetLabelSize(9);
  boldToggle.action := CbBoldToggle;
  NEW(showselectedButton); FlButtons.OpenButton(showselectedButton, 864, 134, 95, 16, "Show Selected");
  Tip(showselectedButton, "Clears the selected items");
  showselectedButton.SetLabelSize(9);
  showselectedButton.action := CbShowselectedButton;
  NEW(clearselectedButton); FlButtons.OpenButton(clearselectedButton, 864, 154, 95, 16, "Remove Selected");
  Tip(clearselectedButton, "Removes the selected items");
  clearselectedButton.SetLabelSize(9);
  clearselectedButton.action := CbClearselectedButton;
  NEW(swapselectedButton); FlButtons.OpenButton(swapselectedButton, 864, 174, 95, 16, "Swap Selected");
  Tip(swapselectedButton, "Tests the Fl_Tree_Item::swap_children() method|Swaps two selected items (items must be siblings)");
  swapselectedButton.SetLabelSize(9);
  swapselectedButton.action := CbSwapselectedButton;
  NEW(selectallButton); FlButtons.OpenButton(selectallButton, 714, 199, 95, 16, "Select All");
  Tip(selectallButton, "Selects all items in the tree");
  selectallButton.SetLabelSize(9);
  selectallButton.action := CbSelectallButton;
  NEW(deselectallButton); FlButtons.OpenButton(deselectallButton, 714, 219, 95, 16, "Deselect All");
  Tip(deselectallButton, "Deselects all items in the tree");
  deselectallButton.SetLabelSize(9);
  deselectallButton.action := CbDeselectallButton;
  NEW(nextselectedButton); FlButtons.OpenButton(nextselectedButton, 713, 239, 95, 16, "next_selected()");
  Tip(nextselectedButton, "Tests the Fl_Tree::next_selected() function");
  nextselectedButton.SetLabelSize(9);
  nextselectedButton.action := CbNextselectedButton;
  NEW(bbbselectToggle); FlButtons.OpenLightButton(bbbselectToggle, 814, 199, 95, 16, " Select Bbb");
  Tip(bbbselectToggle, "Toggle selection of just the /Bbb item|(Not children)");
  bbbselectToggle.SetSelectionColor(1);
  bbbselectToggle.SetLabelSize(9);
  bbbselectToggle.action := CbBbbselectToggle;
  NEW(bbbselect2Toggle); FlButtons.OpenLightButton(bbbselect2Toggle, 814, 219, 95, 16, " Select Bbb+");
  Tip(bbbselect2Toggle, "Toggle selection of the /Bbb item and its children");
  bbbselect2Toggle.SetSelectionColor(1);
  bbbselect2Toggle.SetLabelSize(9);
  bbbselect2Toggle.action := CbBbbselect2Toggle;
  NEW(bbbchild02selectToggle); FlButtons.OpenLightButton(bbbchild02selectToggle, 814, 239, 95, 16, " Toggle child-02");
  Tip(bbbchild02selectToggle, "Toggle the single item `/Bbb/child-02` using the item's `pathname`.");
  bbbchild02selectToggle.SetSelectionColor(1);
  bbbchild02selectToggle.SetLabelSize(9);
  bbbchild02selectToggle.action := CbBbbchild02selectToggle;
  NEW(rootselectToggle); FlButtons.OpenLightButton(rootselectToggle, 914, 199, 100, 16, "Select ROOT");
  Tip(rootselectToggle, "Toggle selection of the ROOT item");
  rootselectToggle.SetSelectionColor(1);
  rootselectToggle.SetLabelSize(9);
  rootselectToggle.action := CbRootselectToggle;
  NEW(rootselect2Toggle); FlButtons.OpenLightButton(rootselect2Toggle, 914, 219, 100, 16, "Select ROOT+");
  Tip(rootselect2Toggle, "Toggle selection of the ROOT item and all children");
  rootselect2Toggle.SetSelectionColor(1);
  rootselect2Toggle.SetLabelSize(9);
  rootselect2Toggle.action := CbRootselect2Toggle;
  g3.End;
  NEW(g3); Fl.OpenGroup(g3, 695, 298, 335, 186, "Tree Fonts + Colors");
  Tip(g3, "These controls only affect the selected items. If no items are selected, all existing items in tree are modified.");
  g3.SetBoxType(Fl.GtkDownBox);
  g3.SetColor(Fl.Dark1);
  g3.SetLabelSize(12);
  NEW(labelfontChoice); FlMenus.OpenChoice(labelfontChoice, 848, 314, 140, 21, "labelfont()");
  Tip(labelfontChoice, "Sets the default font used for new items created. Does NOT affect existing items.");
  labelfontChoice.SetDownBox(Fl.BorderBox);
  labelfontChoice.SetLabelSize(12);
  labelfontChoice.SetTextSize(12);
  labelfontChoice.action := CbLabelfontChoice;
  FontItems(labelfontChoice);
  ok := labelfontChoice.SetValue(0);
  ok := labelfontChoice.SetValue(tree.LabelFont());
  NEW(labelsizeSlider); FlValuators.OpenValueSlider(labelsizeSlider, 848, 338, 140, 16, "labelsize()");
  Tip(labelsizeSlider, "Sets the font size for the  tree's label().|This is also the font size that will be used to draw the items IF their size hasn't been set with Fl_Tree_Item::labelsize() or Fl_Tree::item_labelsize()");
  labelsizeSlider.SetKind(1);
  labelsizeSlider.SetColor(46);
  labelsizeSlider.SetSelectionColor(1);
  labelsizeSlider.SetLabelSize(12);
  labelsizeSlider.SetTextSize(12);
  labelsizeSlider.action := CbLabelsizeSlider;
  labelsizeSlider.SetAlign(Fl.AlignLeft);
  labelsizeSlider.SetValue(tree.LabelSize());
  labelsizeSlider.SetBounds(1, 50);
  labelsizeSlider.SetStep(1);
  labelsizeSlider.SetColor(46);
  labelsizeSlider.SetSelectionColor(Fl.Red);
  NEW(itemLabelfontChoice); FlMenus.OpenChoice(itemLabelfontChoice, 848, 358, 140, 21, "Item_labelfont()");
  Tip(itemLabelfontChoice, "Sets the default font used for new items created.|.Also affects any items whose font has NOT specifically been set with item->labelfont().");
  itemLabelfontChoice.SetDownBox(Fl.BorderBox);
  itemLabelfontChoice.SetLabelSize(12);
  itemLabelfontChoice.SetTextSize(12);
  itemLabelfontChoice.action := CbItemLabelfontChoice;
  FontItems(itemLabelfontChoice);
  ok := itemLabelfontChoice.SetValue(0);
  ok := itemLabelfontChoice.SetValue(tree.ItemLabelFont());
  NEW(itemLabelsizeSlider); FlValuators.OpenValueSlider(itemLabelsizeSlider, 848, 383, 140, 16, "item_labelsize()");
  Tip(itemLabelsizeSlider, "Sets the default font size used for new items created.|.Also affects any items whose font size has NOT specifically been set with item->labelsize().");
  itemLabelsizeSlider.SetKind(1);
  itemLabelsizeSlider.SetColor(46);
  itemLabelsizeSlider.SetSelectionColor(1);
  itemLabelsizeSlider.SetLabelSize(12);
  itemLabelsizeSlider.SetTextSize(12);
  itemLabelsizeSlider.action := CbItemLabelsizeSlider;
  itemLabelsizeSlider.SetAlign(Fl.AlignLeft);
  itemLabelsizeSlider.SetValue(tree.ItemLabelSize());
  itemLabelsizeSlider.SetBounds(1, 50);
  itemLabelsizeSlider.SetStep(1);
  itemLabelsizeSlider.SetColor(46);
  itemLabelsizeSlider.SetSelectionColor(Fl.Red);
  NEW(labelcolorButton); FlButtons.OpenButton(labelcolorButton, 813, 414, 16, 16, "labelcolor()");
  Tip(labelcolorButton, "Changes Fl_Tree::labelcolor().|This affects the text color of the widget's label.");
  labelcolorButton.SetBoxType(Fl.DownBox);
  labelcolorButton.SetLabelSize(11);
  labelcolorButton.action := CbLabelcolorButton;
  labelcolorButton.SetAlign(Fl.AlignLeftTop);
  labelcolorButton.SetColor(tree.LabelColor());
  NEW(colorButton); FlButtons.OpenButton(colorButton, 813, 433, 16, 16, "color()");
  Tip(colorButton, "Changes Fl_Tree::color().|This affects the background color of the widget. It also affects the bg color of newly created  items *if*  Fl_Tree::item_labelbgcolor() hasn't been changed.");
  colorButton.SetBoxType(Fl.DownBox);
  colorButton.SetLabelSize(11);
  colorButton.action := CbColorButton;
  colorButton.SetAlign(Fl.AlignLeftTop);
  colorButton.SetColor(tree.Color());
  NEW(selectionColorButton); FlButtons.OpenButton(selectionColorButton, 813, 452, 16, 16, "selection_color()");
  Tip(selectionColorButton, "Sets the Fl_Tree::selection_color().|This affects the item's colors when they're selected.");
  selectionColorButton.SetBoxType(Fl.DownBox);
  selectionColorButton.SetLabelSize(11);
  selectionColorButton.action := CbSelectionColorButton;
  selectionColorButton.SetAlign(Fl.AlignLeftTop);
  selectionColorButton.SetColor(tree.SelectionColor());
  NEW(itemLabelfgcolorButton); FlButtons.OpenButton(itemLabelfgcolorButton, 973, 414, 16, 16, "item_labelfgcolor()");
  Tip(itemLabelfgcolorButton, "Sets the default label fg color for newly created  items.");
  itemLabelfgcolorButton.SetBoxType(Fl.DownBox);
  itemLabelfgcolorButton.SetLabelSize(12);
  itemLabelfgcolorButton.action := CbItemLabelfgcolorButton;
  itemLabelfgcolorButton.SetAlign(Fl.AlignLeftTop);
  itemLabelfgcolorButton.SetColor(tree.ItemLabelColor());
  NEW(itemLabelbgcolorButton); FlButtons.OpenButton(itemLabelbgcolorButton, 973, 433, 16, 16, "item_labelbgcolor()");
  Tip(itemLabelbgcolorButton, "Sets the default label bg color for newly created items. When set, this overrides the default behavior of using Fl_Tree::color().");
  itemLabelbgcolorButton.SetBoxType(Fl.DownBox);
  itemLabelbgcolorButton.SetLabelSize(12);
  itemLabelbgcolorButton.action := CbItemLabelbgcolorButton;
  itemLabelbgcolorButton.SetAlign(Fl.AlignLeftTop);
  itemLabelbgcolorButton.SetColor(tree.ItemLabelBgColor());
  NEW(xItemLabelbgcolorButton); FlButtons.OpenButton(xItemLabelbgcolorButton, 993, 433, 16, 16, "X");
  Tip(xItemLabelbgcolorButton, "Make the bgcolor 'transparent' (0xffffffff)");
  xItemLabelbgcolorButton.SetLabelSize(10);
  xItemLabelbgcolorButton.action := CbXItemLabelbgcolorButton;
  xItemLabelbgcolorButton.SetAlign(Fl.AlignCenter + Fl.AlignInside);
  g3.End;
  NEW(treeScrollbarSizeSlider); FlValuators.OpenValueSlider(treeScrollbarSizeSlider, 835, 499, 180, 16, "Fl_Tree::scrollbar_size()");
  Tip(treeScrollbarSizeSlider, "Tests Fl_Tree::scrollbar_size() effects on tree clipping.|The value is normally 0, which causes Fl_Tree to use the global Fl::scrollbar_size() instead.");
  treeScrollbarSizeSlider.SetKind(1);
  treeScrollbarSizeSlider.SetColor(46);
  treeScrollbarSizeSlider.SetSelectionColor(1);
  treeScrollbarSizeSlider.SetLabelSize(11);
  treeScrollbarSizeSlider.SetTextSize(9);
  treeScrollbarSizeSlider.action := CbTreeScrollbarSizeSlider;
  treeScrollbarSizeSlider.SetAlign(Fl.AlignLeft);
  treeScrollbarSizeSlider.SetValue(tree.ScrollbarSize());
  treeScrollbarSizeSlider.SetBounds(0, 30);
  treeScrollbarSizeSlider.SetStep(1);
  treeScrollbarSizeSlider.SetColor(46);
  treeScrollbarSizeSlider.SetSelectionColor(Fl.Red);
  NEW(scrollbarSizeSlider); FlValuators.OpenValueSlider(scrollbarSizeSlider, 835, 519, 180, 16, "Fl::scrollbar_size()");
  Tip(scrollbarSizeSlider, "Tests Fl::scrollbar_size() effects on tree clipping");
  scrollbarSizeSlider.SetKind(1);
  scrollbarSizeSlider.SetColor(46);
  scrollbarSizeSlider.SetSelectionColor(1);
  scrollbarSizeSlider.SetLabelSize(11);
  scrollbarSizeSlider.SetTextSize(9);
  scrollbarSizeSlider.action := CbScrollbarSizeSlider;
  scrollbarSizeSlider.SetAlign(Fl.AlignLeft);
  scrollbarSizeSlider.SetValue(Fl.ScrollbarSize());
  scrollbarSizeSlider.SetBounds(5, 30);
  scrollbarSizeSlider.SetStep(1);
  scrollbarSizeSlider.SetColor(46);
  scrollbarSizeSlider.SetSelectionColor(Fl.Red);
  NEW(testsuggsButton); FlButtons.OpenButton(testsuggsButton, 935, 545, 95, 16, "Test Suggestions");
  Tip(testsuggsButton, "Suggestions on how to do tests");
  testsuggsButton.SetLabelSize(9);
  testsuggsButton.action := CbTestsuggsButton;
  g2.SetResizable(NIL);
  g2.End;
  NEW(resizerBox); Fl.OpenBox(resizerBox, 0, 263, 15, 14, "");
  NEW(tty); FlTerminal.OpenTerminal(tty, 16, 571, 1014, 149, "");
  window.End;
END BuildWindow;

(* A widget the tree let go, deleted. *)
PROCEDURE DeleteLoose(w: Fl.Widget);
BEGIN
  IF (w # NIL) & (w.Parent() = NIL) THEN w.Delete END
END DeleteLoose;

BEGIN
  itemId := 501;
  BuildWindow;
  tree.SetRootLabel("ROOT");
  tree.SetReselectMode(FlBrowsers.SelectableAlways);
  RebuildTree;
  Fl.SetTooltipSize(10);
  window.SetResizable(tree);
  window.SizeRange(window.W(), window.H(), 0, 0);
  IF tree.When() = Fl.WhenChanged THEN ok0 := whenmodeChooser.SetValue(0)
  ELSIF tree.When() = Fl.WhenRelease THEN ok0 := whenmodeChooser.SetValue(1)
  ELSIF tree.When() = Fl.WhenNever THEN ok0 := whenmodeChooser.SetValue(2)
  END;
  window.ShowArgs;
  Fl.Run;
  IF helpWin # NIL THEN helpWin.Delete END;
  DeleteLoose(in); DeleteLoose(but); DeleteLoose(grp);
  window.Delete
END Tree.
