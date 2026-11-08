MODULE UtScrollbarSize; (* FLTK's test/unittest_scrollbarsize.cxx in Oberon-2 *)

IMPORT Fl, FlDraw, FlBrowsers, FlTable, FlText, FlTerminal, FlValuators, Ut;

CONST
  Label* = "Scrollbar Size";
  Long = "Long entry will show h-bar";

TYPE
  Table = POINTER TO RECORD (FlTable.TableDesc) END;
  Act = PROCEDURE (w: Fl.Widget);

VAR
  phonetics: ARRAY 26, 10 OF CHAR;
  (* the A widgets, sized by "A: Scroll Size" *)
  browA: FlBrowsers.MultiBrowser;
  treeA: FlBrowsers.Tree;
  tableA: Table;
  textA: FlText.TextDisplay;
  termA: FlTerminal.Terminal;

PROCEDURE (t: Table) DrawCell*(context, r, c, x, y, w, h: INTEGER);
  VAR s: ARRAY 2 OF CHAR;
BEGIN
  IF context = FlTable.ContextStartPage THEN FlDraw.SetFont(Fl.Helvetica, 8)
  ELSIF context = FlTable.ContextCell THEN
    s[0] := CHR(ORD("A") + r + c); s[1] := 0X;
    FlDraw.PushClip(x, y, w, h);
    FlDraw.SetColor(Fl.White); FlDraw.RectF(x, y, w, h);
    FlDraw.SetColor(Fl.Gray0); FlDraw.TextAligned(s, x, y, w, h, Fl.AlignCenter);
    FlDraw.SetColor(t.Color()); FlDraw.Rect(x, y, w, h);
    FlDraw.PopClip
  END
END DrawCell;

PROCEDURE MakeBrowser(VAR b: FlBrowsers.MultiBrowser; x, y, w, h: INTEGER; label: ARRAY OF CHAR);
  VAR t: INTEGER;
BEGIN
  NEW(b); FlBrowsers.OpenMultiBrowser(b, x, y, w, h, label);
  b.SetLabelSize(10); b.SetTextSize(10); b.SetAlign(Fl.AlignTop);
  FOR t := 0 TO LEN(phonetics) - 1 DO
    b.Add(phonetics[t]);
    IF phonetics[t][0] = "C" THEN b.Add(Long) END
  END
END MakeBrowser;

PROCEDURE MakeTree(VAR b: FlBrowsers.Tree; x, y, w, h: INTEGER; label: ARRAY OF CHAR);
  VAR t: INTEGER;
BEGIN
  NEW(b); FlBrowsers.OpenTree(b, x, y, w, h, label);
  b.SetLabelSize(10); b.SetItemLabelSize(10);
  b.SetSelectMode(FlBrowsers.TreeSelectMulti); b.SetAlign(Fl.AlignTop);
  FOR t := 0 TO LEN(phonetics) - 1 DO
    IF b.Add(phonetics[t]) = NIL THEN END;
    IF (phonetics[t][0] = "C") & (b.Add(Long) = NIL) THEN END
  END
END MakeTree;

PROCEDURE MakeTable(VAR t: Table; x, y, w, h: INTEGER; label: ARRAY OF CHAR);
BEGIN
  NEW(t); FlTable.OpenTable(t, x, y, w, h, label);
  t.SetRows(13); t.SetRowHeightAll(10);
  t.SetCols(13); t.SetColWidthAll(10);
  t.End;
  t.SetLabelSize(10); t.SetAlign(Fl.AlignTop)
END MakeTable;

PROCEDURE MakeText(VAR d: FlText.TextDisplay; x, y, w, h: INTEGER; label: ARRAY OF CHAR);
  VAR buf: FlText.TextBuffer; t: INTEGER; nl: ARRAY 2 OF CHAR;
BEGIN
  nl[0] := 0AX; nl[1] := 0X;
  NEW(d); FlText.OpenTextDisplay(d, x, y, w, h, label);
  NEW(buf); FlText.OpenBuffer(buf);
  d.SetLabelSize(10); d.SetTextSize(10);
  d.SetBuffer(buf);
  FOR t := 0 TO LEN(phonetics) - 1 DO
    buf.Append(phonetics[t]); buf.Append(nl);
    IF phonetics[t][0] = "C" THEN buf.Append(Long); buf.Append(nl) END
  END;
  buf.Close  (* the display keeps it *)
END MakeText;

PROCEDURE MakeTerm(VAR term: FlTerminal.Terminal; x, y, w, h: INTEGER; label: ARRAY OF CHAR);
  VAR s: ARRAY 32 OF CHAR;
BEGIN
  NEW(term); FlTerminal.OpenTerminal(term, x, y, w, h, label);
  term.SetLabelSize(8); term.SetTextSize(8);
  term.SetDisplayColumns(40);  (* wider than it is, to show the bar *)
  s := "Long entry will show h-bar|"; Ut.Lines(s); term.Append(s)
END MakeTerm;

PROCEDURE RedrawWindow(w: Fl.Widget);
  VAR win: Fl.Window;
BEGIN win := w.Window(); win.Redraw
END RedrawWindow;

PROCEDURE GlobalSize(w: Fl.Widget);
BEGIN
  Fl.SetScrollbarSize(SHORT(ENTIER(w(FlValuators.Valuator).Value())));
  RedrawWindow(w)
END GlobalSize;

PROCEDURE SizeA(w: Fl.Widget);
  VAR n: INTEGER;
BEGIN
  n := SHORT(ENTIER(w(FlValuators.Valuator).Value()));
  browA.SetScrollbarSize(n); treeA.SetScrollbarSize(n);
  tableA.SetScrollbarSize(n); textA.SetScrollbarSize(n);
  termA.SetScrollbarSize(n);
  RedrawWindow(w)
END SizeA;

PROCEDURE Slider(x, y: INTEGER; label: ARRAY OF CHAR; v: LONGREAL; action: Act);
  VAR s: FlValuators.ValueSlider;
BEGIN
  NEW(s); FlValuators.OpenHorValueSlider(s, x, y, 100, 18, label);
  s.SetValue(v); s.SetAlign(Fl.AlignLeft);
  s.SetBounds(0, 30); s.SetStep(1);
  s.action := action; s.SetLabelSize(12)
END Slider;

PROCEDURE Create*(): Fl.Widget;
  VAR
    g: Fl.Group; msg: Fl.Box;
    browB, browC: FlBrowsers.MultiBrowser; treeB, treeC: FlBrowsers.Tree;
    tableB, tableC: Table; textB, textC: FlText.TextDisplay;
    termB, termC: FlTerminal.Terminal;
    x, y, w, h, tgrpy, tgrph, ysep, browy, browh, treey, treeh, tabley, tableh,
    texty, texth, termy, mx: INTEGER;
BEGIN
  x := Ut.X; y := Ut.Y; w := Ut.W; h := Ut.H;
  NEW(g); Fl.OpenGroup(g, x, y, w, h, "");
  tgrpy := y + 30; tgrph := h - 30;
  ysep := 20;  (* between the rows of widgets *)
  browy := tgrpy + 14;
  browh := tgrph DIV 5 - 20;  (* five rows *)
  treey := browy + browh + ysep; treeh := browh;
  tabley := treey + treeh + ysep; tableh := browh;
  texty := tabley + tableh + ysep; texth := browh;
  termy := texty + texth + ysep;
  MakeBrowser(browA, x + 10, browy, 100, browh, "Browser A");
  MakeBrowser(browB, x + 120, browy, 100, browh, "Browser B");
  MakeBrowser(browC, x + 230, browy, 100, browh, "Browser C");
  MakeTree(treeA, x + 10, treey, 100, treeh, "Tree A");
  MakeTree(treeB, x + 120, treey, 100, treeh, "Tree B");
  MakeTree(treeC, x + 230, treey, 100, treeh, "Tree C");
  MakeTable(tableA, x + 10, tabley, 100, tableh, "Table A");
  MakeTable(tableB, x + 120, tabley, 100, tableh, "Table B");
  MakeTable(tableC, x + 230, tabley, 100, tableh, "Table C");
  MakeText(textA, x + 10, texty, 100, texth, "Text Display A");
  MakeText(textB, x + 120, texty, 100, texth, "Text Display B");
  MakeText(textC, x + 230, texty, 100, texth, "Text Display C");
  MakeTerm(termA, x + 10, termy, 100, texth, "Term A");
  MakeTerm(termB, x + 120, termy, 100, texth, "Term B");
  MakeTerm(termC, x + 230, termy, 100, texth, "Term C");
  Slider(x + 100, y, "Global Scroll Size", 16, GlobalSize);
  Slider(x + 350, y, "A: Scroll Size", 0, SizeA);
  mx := browC.X() + browC.W() + 20;
  NEW(msg); Fl.OpenBox(msg, mx, tgrpy, w - (mx - x), tgrph, "");
  Ut.SetLabel(msg, "|Verify global scrollbar sizing and per-widget scrollbar sizing. Scrollbar's size should change interactively as size sliders are changed. Changing 'Global Scroll Size' should affect all scrollbars AS LONG AS the 'A: Scroll Size' slider is 0. Otherwise its value takes precedence for all the 'A' group widgets.");
  msg.SetLabelSize(12);
  msg.SetAlign(Fl.AlignInside + Fl.AlignCenter + Fl.AlignLeft + Fl.AlignWrap);
  msg.SetBoxType(Fl.FlatBox);
  msg.SetColor(53);  (* 90% gray *)
  g.End;
  RETURN g
END Create;

BEGIN
  phonetics[0] := "Alpha"; phonetics[1] := "Bravo"; phonetics[2] := "Charlie";
  phonetics[3] := "Delta"; phonetics[4] := "Echo"; phonetics[5] := "Foxtrot";
  phonetics[6] := "Golf"; phonetics[7] := "Hotel"; phonetics[8] := "India";
  phonetics[9] := "Juliet"; phonetics[10] := "Kilo"; phonetics[11] := "Lima";
  phonetics[12] := "Mike"; phonetics[13] := "November"; phonetics[14] := "Oscar";
  phonetics[15] := "Papa"; phonetics[16] := "Quebec"; phonetics[17] := "Romeo";
  phonetics[18] := "Sierra"; phonetics[19] := "Tango"; phonetics[20] := "Uniform";
  phonetics[21] := "Victor"; phonetics[22] := "Whiskey"; phonetics[23] := "X-ray";
  phonetics[24] := "Yankee"; phonetics[25] := "Zulu"
END UtScrollbarSize.
