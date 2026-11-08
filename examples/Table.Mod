MODULE Table; (* FLTK's test/table.cxx: every aspect of a TableRow, set from the widgets below it *)

IMPORT OutStr, Strings, Fl, FlDraw, FlButtons, FlInputs, FlMenus, FlDialogs, FlTable, FlTerminal;

CONST
  TerminalHeight = 120;

TYPE
  DemoTable = POINTER TO RECORD (FlTable.TableRowDesc)
    cellBgColor, cellFgColor: INTEGER;  (* the cells' background and text *)
    showCallbacks: BOOLEAN              (* whether the callbacks are written *)
  END;

VAR
  win: Fl.Window;
  tty: FlTerminal.Terminal;
  table: DemoTable;
  setRows, rowHeightAll, positionRow, setCols, colWidthAll, positionCol,
  rowHeaderWidth, rowHeaderColor, colHeaderHeight, colHeaderColor,
  tableColor, cellBgColor, cellFgColor: FlInputs.Input;
  rowHeader, rowResize, colHeader, colResize: FlButtons.CheckButton;
  tableBox, widgetBox, type: FlMenus.Choice;
  tableBoxes, widgetBoxes: ARRAY 17 OF INTEGER;  (* each choice's item's box *)

(* C's atoi: leading blanks, a sign, then digits. *)
PROCEDURE Atoi(s-: ARRAY OF CHAR): INTEGER;
  VAR i, n: INTEGER; neg: BOOLEAN;
BEGIN
  i := 0; n := 0;
  WHILE (s[i] = " ") OR (s[i] >= 09X) & (s[i] <= 0DX) DO INC(i) END;
  neg := s[i] = "-";
  IF (s[i] = "-") OR (s[i] = "+") THEN INC(i) END;
  WHILE (s[i] >= "0") & (s[i] <= "9") DO n := n * 10 + (ORD(s[i]) - ORD("0")); INC(i) END;
  IF neg THEN n := -n END;
  RETURN n
END Atoi;

(* The number in i. *)
PROCEDURE ValueOf(i: Fl.Widget): INTEGER;
  VAR s: ARRAY 256 OF CHAR;
BEGIN
  i(FlInputs.Input).Value(s);
  RETURN Atoi(s)
END ValueOf;

PROCEDURE SetInt(i: FlInputs.Input; n: INTEGER);
  VAR s: ARRAY 20 OF CHAR;
BEGIN
  s := ""; OutStr.Int(n, 0, s); i.SetValue(s)
END SetInt;

PROCEDURE (t: DemoTable) DrawCell*(context, r, c, x, y, w, h: INTEGER);
  VAR s: ARRAY 40 OF CHAR; color: INTEGER;
BEGIN
  s := ""; OutStr.Int(r, 0, s); Strings.Append("/", s); OutStr.Int(c, 0, s);
  IF context = FlTable.ContextStartPage THEN
    FlDraw.SetFont(Fl.Helvetica, 16)
  ELSIF (context = FlTable.ContextColHeader) OR (context = FlTable.ContextRowHeader) THEN
    FlDraw.PushClip(x, y, w, h);
    IF context = FlTable.ContextColHeader THEN color := t.ColHeaderColor() ELSE color := t.RowHeaderColor() END;
    FlDraw.DrawBox(Fl.ThinUpBox, x, y, w, h, color);
    FlDraw.SetColor(Fl.Black);
    FlDraw.TextAligned(s, x, y, w, h, Fl.AlignCenter);
    FlDraw.PopClip
  ELSIF context = FlTable.ContextCell THEN
    FlDraw.PushClip(x, y, w, h);
    IF t.RowSelected(r) THEN FlDraw.SetColor(t.SelectionColor()) ELSE FlDraw.SetColor(t.cellBgColor) END;
    FlDraw.RectF(x, y, w, h);
    FlDraw.SetColor(t.cellFgColor);
    FlDraw.TextAligned(s, x, y, w, h, Fl.AlignCenter);
    FlDraw.SetColor(t.Color());
    FlDraw.Rect(x, y, w, h);
    FlDraw.PopClip
  ELSIF context = FlTable.ContextTable THEN
    s := "TABLE CONTEXT CALLED"; Strings.Append(0AX, s); tty.Append(s)
  END
END DrawCell;

(* Written whenever someone clicks on a part of the table. *)
PROCEDURE EventCb(w: Fl.Widget);
  VAR t: DemoTable; s, name: ARRAY 200 OF CHAR;
BEGIN
  t := w(DemoTable);
  t.GetLabel(name);
  IF name = "" THEN name := "?" END;
  IF t.showCallbacks THEN
    s := "'"; Strings.Append(name, s);
    Strings.Append("' callback: Row=", s); OutStr.Int(t.CallbackRow(), 0, s);
    Strings.Append(" Col=", s); OutStr.Int(t.CallbackCol(), 0, s);
    Strings.Append(" Context=", s); OutStr.Int(t.CallbackContext(), 0, s);
    Strings.Append(" Event=", s); OutStr.Int(Fl.Event(), 0, s);
    Strings.Append(" InteractiveResize? ", s); IF t.IsInteractiveResize() THEN Strings.Append("1", s) ELSE Strings.Append("0", s) END;
    Strings.Append(0AX, s);
    tty.Append(s)
  END
END EventCb;

PROCEDURE SetRowsCb(w: Fl.Widget);
  VAR n: INTEGER;
BEGIN
  n := ValueOf(w); IF n < 0 THEN n := 0 END;
  table.SetRows(n)
END SetRowsCb;

PROCEDURE SetColsCb(w: Fl.Widget);
  VAR n: INTEGER;
BEGIN
  n := ValueOf(w); IF n < 0 THEN n := 0 END;
  table.SetCols(n)
END SetColsCb;

PROCEDURE SetRowHeaderCb(w: Fl.Widget);
BEGIN table.SetRowHeader(w(FlButtons.CheckButton).Value())
END SetRowHeaderCb;

PROCEDURE SetColHeaderCb(w: Fl.Widget);
BEGIN table.SetColHeader(w(FlButtons.CheckButton).Value())
END SetColHeaderCb;

PROCEDURE SetRowResizeCb(w: Fl.Widget);
BEGIN table.SetRowResize(w(FlButtons.CheckButton).Value())
END SetRowResizeCb;

PROCEDURE SetColResizeCb(w: Fl.Widget);
BEGIN table.SetColResize(w(FlButtons.CheckButton).Value())
END SetColResizeCb;

PROCEDURE SetPositionRowCb(w: Fl.Widget);
  VAR n: INTEGER;
BEGIN
  n := ValueOf(w);
  IF (n < 0) OR (n >= table.Rows()) THEN FlDialogs.Alert("Must be in range 0 thru #rows")
  ELSE table.SetRowPosition(n)
  END
END SetPositionRowCb;

PROCEDURE SetPositionColCb(w: Fl.Widget);
  VAR n: INTEGER;
BEGIN
  n := ValueOf(w);
  IF (n < 0) OR (n >= table.Cols()) THEN FlDialogs.Alert("Must be in range 0 thru #cols")
  ELSE table.SetColPosition(n)
  END
END SetPositionColCb;

PROCEDURE SetRowHeaderWidthCb(w: Fl.Widget);
  VAR n: INTEGER;
BEGIN
  n := ValueOf(w); IF n < 1 THEN n := 1; w(FlInputs.Input).SetValue("1") END;
  table.SetRowHeaderWidth(n)
END SetRowHeaderWidthCb;

PROCEDURE SetColHeaderHeightCb(w: Fl.Widget);
  VAR n: INTEGER;
BEGIN
  n := ValueOf(w); IF n < 1 THEN n := 1; w(FlInputs.Input).SetValue("1") END;
  table.SetColHeaderHeight(n)
END SetColHeaderHeightCb;

PROCEDURE SetRowHeaderColorCb(w: Fl.Widget);
  VAR n: INTEGER;
BEGIN
  n := ValueOf(w);
  IF n < 0 THEN FlDialogs.Alert("Must be a color >0") ELSE table.SetRowHeaderColor(n) END
END SetRowHeaderColorCb;

PROCEDURE SetColHeaderColorCb(w: Fl.Widget);
  VAR n: INTEGER;
BEGIN
  n := ValueOf(w);
  IF n < 0 THEN FlDialogs.Alert("Must be a color >0") ELSE table.SetColHeaderColor(n) END
END SetColHeaderColorCb;

PROCEDURE SetRowHeightAllCb(w: Fl.Widget);
  VAR n: INTEGER;
BEGIN
  n := ValueOf(w); IF n < 0 THEN n := 0; w(FlInputs.Input).SetValue("0") END;
  table.SetRowHeightAll(n)
END SetRowHeightAllCb;

PROCEDURE SetColWidthAllCb(w: Fl.Widget);
  VAR n: INTEGER;
BEGIN
  n := ValueOf(w); IF n < 0 THEN n := 0; w(FlInputs.Input).SetValue("0") END;
  table.SetColWidthAll(n)
END SetColWidthAllCb;

PROCEDURE SetTableColorCb(w: Fl.Widget);
  VAR n: INTEGER;
BEGIN
  n := ValueOf(w);
  IF n < 0 THEN FlDialogs.Alert("Must be a color >0") ELSE table.SetColor(n) END;
  table.Redraw
END SetTableColorCb;

PROCEDURE SetCellFgColorCb(w: Fl.Widget);
  VAR n: INTEGER;
BEGIN
  n := ValueOf(w);
  IF n < 0 THEN FlDialogs.Alert("Must be a color >0") ELSE table.cellFgColor := n END;
  table.Redraw
END SetCellFgColorCb;

PROCEDURE SetCellBgColorCb(w: Fl.Widget);
  VAR n: INTEGER;
BEGIN
  n := ValueOf(w);
  IF n < 0 THEN FlDialogs.Alert("Must be a color >0") ELSE table.cellBgColor := n END;
  table.Redraw
END SetCellBgColorCb;

(* Each choice's items share one action, which goes by the item chosen. *)
PROCEDURE TableBoxCb(w: Fl.Widget);
BEGIN
  table.SetTableBox(tableBoxes[w(FlMenus.Choice).Value()]);
  table.Redraw
END TableBoxCb;

PROCEDURE WidgetBoxCb(w: Fl.Widget);
BEGIN
  table.SetBoxType(widgetBoxes[w(FlMenus.Choice).Value()]);
  table.Resize(table.X(), table.Y(), table.W(), table.H())
END WidgetBoxCb;

PROCEDURE TypeCb(w: Fl.Widget);
BEGIN table.SetSelectMode(w(FlMenus.Choice).Value())  (* SelectNone, SelectSingle, SelectMulti *)
END TypeCb;

PROCEDURE AddBox(c: FlMenus.Choice; label: ARRAY OF CHAR; box: INTEGER; VAR boxes: ARRAY OF INTEGER; action: FlMenus.Action);
  VAR i: INTEGER;
BEGIN
  i := c.Add(label, 0, {}, action, {});
  boxes[i] := box
END AddBox;

PROCEDURE OpenInput(VAR i: FlInputs.Input; x, y: INTEGER; label: ARRAY OF CHAR; action: FlMenus.Action);
BEGIN
  NEW(i); FlInputs.OpenInput(i, x, y, 120, 25, label);
  i.SetLabelSize(12);
  i.action := action;
  i.SetWhen(Fl.WhenRelease)
END OpenInput;

PROCEDURE OpenCheck(VAR b: FlButtons.CheckButton; x, y: INTEGER; label: ARRAY OF CHAR; action: FlMenus.Action; on: BOOLEAN);
BEGIN
  NEW(b); FlButtons.OpenCheckButton(b, x, y, 120, 25, label);
  b.SetLabelSize(12);
  b.action := action;
  b.SetValue(on)
END OpenCheck;

PROCEDURE OpenChoice(VAR c: FlMenus.Choice; x, y: INTEGER; label: ARRAY OF CHAR);
BEGIN
  NEW(c); FlMenus.OpenChoice(c, x, y, 120, 25, label);
  c.SetLabelSize(12);
  c.SetTextSize(12)
END OpenChoice;

PROCEDURE Build;
  VAR ok: BOOLEAN; i: INTEGER;
BEGIN
  NEW(win); Fl.OpenWindow(win, 900, 730 + TerminalHeight, "");
  NEW(tty); FlTerminal.OpenTerminal(tty, 0, 730, win.W(), TerminalHeight, "");

  NEW(table); FlTable.OpenTableRow(table, 20, 20, 860, 460, "Demo");
  table.cellBgColor := Fl.White; table.cellFgColor := Fl.Black; table.showCallbacks := FALSE;
  table.action := EventCb;
  table.End;
  table.SetSelectionColor(Fl.Yellow);
  table.SetWhen(Fl.WhenRelease + Fl.WhenChanged);
  table.SetTableBox(Fl.NoBox);
  table.SetColResizeMin(4);
  table.SetRowResizeMin(4);
  table.SetRowHeader(TRUE);  (* rows *)
  table.SetRowHeaderWidth(60);
  table.SetRowResize(TRUE);
  table.SetRows(500);
  table.SetRowHeightAll(20);
  table.SetCols(500);        (* columns *)
  table.SetColHeader(TRUE);
  table.SetColHeaderHeight(25);
  table.SetColResize(TRUE);
  table.SetColWidthAll(80);
  table.showCallbacks := TRUE;  (* after initialization, show the table's callbacks *)

  win.Begin;
  OpenInput(setRows, 150, 500, "Rows", SetRowsCb); SetInt(setRows, table.Rows());
  OpenInput(rowHeightAll, 400, 500, "Row Height", SetRowHeightAllCb); SetInt(rowHeightAll, table.RowHeight(0));
  OpenInput(positionRow, 650, 500, "Row Position", SetPositionRowCb); positionRow.SetValue("1");
  OpenInput(setCols, 150, 530, "Cols", SetColsCb); SetInt(setCols, table.Cols());
  OpenInput(colWidthAll, 400, 530, "Col Width", SetColWidthAllCb); SetInt(colWidthAll, table.ColWidth(0));
  OpenInput(positionCol, 650, 530, "Col Position", SetPositionColCb); positionCol.SetValue("1");

  OpenInput(rowHeaderWidth, 150, 570, "Row Header Width", SetRowHeaderWidthCb);
  SetInt(rowHeaderWidth, table.RowHeaderWidth());
  OpenInput(rowHeaderColor, 400, 570, "Row Header Color", SetRowHeaderColorCb);
  SetInt(rowHeaderColor, table.RowHeaderColor());
  OpenCheck(rowHeader, 550, 570, "Row Headers?", SetRowHeaderCb, table.RowHeader());
  OpenCheck(rowResize, 700, 570, "Row Resize?", SetRowResizeCb, table.RowResize());

  OpenInput(colHeaderHeight, 150, 600, "Col Header Height", SetColHeaderHeightCb);
  SetInt(colHeaderHeight, table.ColHeaderHeight());
  OpenInput(colHeaderColor, 400, 600, "Col Header Color", SetColHeaderColorCb);
  SetInt(colHeaderColor, table.ColHeaderColor());
  OpenCheck(colHeader, 550, 600, "Col Headers?", SetColHeaderCb, table.ColHeader());
  OpenCheck(colResize, 700, 600, "Col Resize?", SetColResizeCb, table.ColResize());

  OpenChoice(tableBox, 150, 640, "Table Box");
  AddBox(tableBox, "No Box", Fl.NoBox, tableBoxes, TableBoxCb);
  AddBox(tableBox, "Flat Box", Fl.FlatBox, tableBoxes, TableBoxCb);
  AddBox(tableBox, "Up Box", Fl.UpBox, tableBoxes, TableBoxCb);
  AddBox(tableBox, "Down Box", Fl.DownBox, tableBoxes, TableBoxCb);
  AddBox(tableBox, "Up Frame", Fl.UpFrame, tableBoxes, TableBoxCb);
  AddBox(tableBox, "Down Frame", Fl.DownFrame, tableBoxes, TableBoxCb);
  AddBox(tableBox, "Thin Up Box", Fl.ThinUpBox, tableBoxes, TableBoxCb);
  AddBox(tableBox, "Thin Down Box", Fl.ThinDownBox, tableBoxes, TableBoxCb);
  AddBox(tableBox, "Thin Up Frame", Fl.ThinUpFrame, tableBoxes, TableBoxCb);
  AddBox(tableBox, "Thin Down Frame", Fl.ThinDownFrame, tableBoxes, TableBoxCb);
  AddBox(tableBox, "Engraved Box", Fl.EngravedBox, tableBoxes, TableBoxCb);
  AddBox(tableBox, "Embossed Box", Fl.EmbossedBox, tableBoxes, TableBoxCb);
  AddBox(tableBox, "Engraved Frame", Fl.EngravedFrame, tableBoxes, TableBoxCb);
  AddBox(tableBox, "Embossed Frame", Fl.EmbossedFrame, tableBoxes, TableBoxCb);
  AddBox(tableBox, "Border Box", Fl.BorderBox, tableBoxes, TableBoxCb);
  AddBox(tableBox, "Shadow Box", Fl.ShadowBox, tableBoxes, TableBoxCb);
  AddBox(tableBox, "Border Frame", Fl.BorderFrame, tableBoxes, TableBoxCb);
  ok := tableBox.SetValue(0);

  OpenChoice(widgetBox, 150, 670, "Widget Box");
  AddBox(widgetBox, "No Box", Fl.NoBox, widgetBoxes, WidgetBoxCb);
  AddBox(widgetBox, "Up Frame", Fl.UpFrame, widgetBoxes, WidgetBoxCb);
  AddBox(widgetBox, "Down Frame", Fl.DownFrame, widgetBoxes, WidgetBoxCb);
  AddBox(widgetBox, "Thin Up Frame", Fl.ThinUpFrame, widgetBoxes, WidgetBoxCb);
  AddBox(widgetBox, "Thin Down Frame", Fl.ThinDownFrame, widgetBoxes, WidgetBoxCb);
  AddBox(widgetBox, "Engraved Frame", Fl.EngravedFrame, widgetBoxes, WidgetBoxCb);
  AddBox(widgetBox, "Embossed Frame", Fl.EmbossedFrame, widgetBoxes, WidgetBoxCb);
  AddBox(widgetBox, "Border Frame", Fl.BorderFrame, widgetBoxes, WidgetBoxCb);
  ok := widgetBox.SetValue(2);  (* down frame *)

  OpenInput(tableColor, 400, 640, "Table Color", SetTableColorCb); SetInt(tableColor, table.Color());
  OpenInput(cellBgColor, 400, 670, "Cell BG Color", SetCellBgColorCb); SetInt(cellBgColor, table.cellBgColor);
  OpenInput(cellFgColor, 400, 700, "Cell FG Color", SetCellFgColorCb); SetInt(cellFgColor, table.cellFgColor);

  OpenChoice(type, 650, 640, "Type");
  i := type.Add("SelectNone", 0, {}, TypeCb, {});
  i := type.Add("SelectSingle", 0, {}, TypeCb, {});
  i := type.Add("SelectMulti", 0, {}, TypeCb, {});
  ok := type.SetValue(2);
  win.End;
  win.SetResizable(table)
END Build;

BEGIN
  Build;
  win.ShowArgs;
  Fl.Run
END Table.
