MODULE Tabs; (* FLTK's test/tabs.fl in Oberon-2 *)

(* The same pages in tabs, on the left, and in a wizard, on the right,
   whose buttons and the Home, arrow and End keys turn its pages. Tabs
   can be added, and closed where their group calls back on closing;
   the choice says what the tabs do when too many to fit. Cancel exits
   with status 1, OK with 0. *)

IMPORT Out, Fl, FlButtons, FlDialogs, FlInputs, FlLayout, FlMenus, FlValuators;

TYPE
  Action = PROCEDURE (w: Fl.Widget);

VAR
  fooWindow: Fl.DoubleWindow;
  tabsGroup: FlLayout.Tabs;
  wWizard: FlLayout.Wizard;
  o: Fl.Group;
  overflow: FlMenus.Choice;
  input: FlInputs.Input;
  cancel: FlButtons.Button;
  ok: FlButtons.ReturnButton;
  n, i: INTEGER;
  inTabs: BOOLEAN;

(* Appends s to t. *)
PROCEDURE Cat(s-: ARRAY OF CHAR; VAR t: ARRAY OF CHAR);
VAR i, j: INTEGER;
BEGIN
  i := 0; WHILE t[i] # 0X DO INC(i) END;
  j := 0; WHILE s[j] # 0X DO t[i] := s[j]; INC(i); INC(j) END;
  t[i] := 0X
END Cat;

(* Appends n to s. *)
PROCEDURE Num(n: INTEGER; VAR s: ARRAY OF CHAR);
VAR i: INTEGER;
BEGIN
  IF n >= 10 THEN Num(n DIV 10, s) END;
  i := 0; WHILE s[i] # 0X DO INC(i) END;
  s[i] := CHR(ORD("0") + n MOD 10); s[i + 1] := 0X
END Num;

PROCEDURE TabsCallback(w: Fl.Widget);
VAR sel: Fl.Widget; label: ARRAY 256 OF CHAR;
BEGIN
  sel := tabsGroup.Value();
  IF sel # NIL THEN
    sel.GetLabel(label);
    Out.String('Callback called for tab "'); Out.String(label); Out.String('"'); Out.Ln
  ELSE Out.String("Callback called"); Out.Ln
  END
END TabsCallback;

(* A tab's close button removes it. *)
PROCEDURE TabCallback(w: Fl.Widget);
VAR p: Fl.Group;
BEGIN
  IF Fl.CallbackReason() = Fl.ReasonClosed THEN p := w.Parent(); p.Remove(w) END
END TabCallback;

PROCEDURE Button1Callback(w: Fl.Widget);
BEGIN FlDialogs.Message("Test to see if this modal window prevents you from changing the tabs. It should.")
END Button1Callback;

PROCEDURE TestCallback(w: Fl.Widget);
BEGIN FlDialogs.Message("Make sure you cannot change the tabs while this modal window is up")
END TestCallback;

PROCEDURE FirstCallback(w: Fl.Widget);
BEGIN wWizard.SetValue(wWizard.Child(0))
END FirstCallback;

PROCEDURE PrevCallback(w: Fl.Widget);
BEGIN wWizard.Prev
END PrevCallback;

PROCEDURE NextCallback(w: Fl.Widget);
BEGIN wWizard.Next
END NextCallback;

PROCEDURE LastCallback(w: Fl.Widget);
BEGIN wWizard.SetValue(wWizard.Child(wWizard.Children() - 1))
END LastCallback;

(* No group is current in a callback, so the new tab is in none until
   it is added. *)
PROCEDURE AddCallback(w: Fl.Widget);
VAR x, y, width, h: INTEGER; tab: Fl.Group; box: Fl.Box; buf: ARRAY 64 OF CHAR;
BEGIN
  x := tabsGroup.X(); y := tabsGroup.Y() + 25;
  width := tabsGroup.W(); h := tabsGroup.H() - 25;
  buf := "tab"; Num(n, buf);
  NEW(tab); Fl.OpenGroup(tab, x, y, width, h, buf);
  tab.SetWhen(Fl.WhenClosed);
  tab.action := TabCallback;
  buf := "Empty tab "; Num(n, buf); Cat(".", buf);
  NEW(box); Fl.OpenBox(box, x + 5, y + 5, width - 10, h - 10, buf);
  box.SetAlign(Fl.AlignInside);
  tab.End;
  tabsGroup.Add(tab);
  INC(n)
END AddCallback;

PROCEDURE CompressCallback(w: Fl.Widget);
BEGIN tabsGroup.HandleOverflow(FlLayout.OverflowCompress)
END CompressCallback;

PROCEDURE ClipCallback(w: Fl.Widget);
BEGIN tabsGroup.HandleOverflow(FlLayout.OverflowClip)
END ClipCallback;

PROCEDURE PulldownCallback(w: Fl.Widget);
BEGIN tabsGroup.HandleOverflow(FlLayout.OverflowPulldown)
END PulldownCallback;

PROCEDURE DragCallback(w: Fl.Widget);
BEGIN tabsGroup.HandleOverflow(FlLayout.OverflowDrag)
END DragCallback;

PROCEDURE CancelCallback(w: Fl.Widget);
BEGIN HALT(1)
END CancelCallback;

PROCEDURE OkCallback(w: Fl.Widget);
BEGIN HALT(0)
END OkCallback;

PROCEDURE Title(x: INTEGER; label-: ARRAY OF CHAR);
VAR b: Fl.Box;
BEGIN
  NEW(b); Fl.OpenBox(b, x, 0, 130, 35, label);
  b.SetLabelType(Fl.EngravedLabel);
  b.SetLabelFont(Fl.HelveticaBold)
END Title;

(* A page: the tabs' when closable, the wizard's not. *)
PROCEDURE Page(VAR g: Fl.Group; x, w: INTEGER; label-, tip-: ARRAY OF CHAR; color: INTEGER; closable: BOOLEAN);
BEGIN
  NEW(g); Fl.OpenGroup(g, x, 60, w, 235, label);
  g.SetTooltip(tip);
  IF color >= 0 THEN g.SetSelectionColor(color) END;
  IF closable THEN g.action := TabCallback; g.SetWhen(Fl.WhenClosed) END
END Page;

PROCEDURE Input(x, y, w, h: INTEGER; label-: ARRAY OF CHAR): FlInputs.Input;
VAR i: FlInputs.Input;
BEGIN NEW(i); FlInputs.OpenInput(i, x, y, w, h, label); RETURN i
END Input;

PROCEDURE Button(x, y, w, h: INTEGER; label-: ARRAY OF CHAR; action: Action): FlButtons.Button;
VAR b: FlButtons.Button;
BEGIN
  NEW(b); FlButtons.OpenButton(b, x, y, w, h, label);
  IF action # NIL THEN b.action := action END;
  RETURN b
END Button;

PROCEDURE SubWindow(x, y, color: INTEGER; label-: ARRAY OF CHAR; align: SET);
VAR w: Fl.Window;
BEGIN
  NEW(w); Fl.OpenWindowAt(w, x, y, 40, 55, label);
  w.SetBoxType(Fl.ThinDownBox);
  w.SetColor(color);
  w.SetSelectionColor(Fl.BackgroundColor);
  w.SetLabelType(Fl.NormalLabel);
  w.SetLabelFont(Fl.Helvetica);
  w.SetLabelSize(14);
  w.SetLabelColor(Fl.ForegroundColor);
  w.SetAlign(align);
  w.SetWhen(Fl.WhenRelease);
  w.End
END SubWindow;

(* x in the tabs, or the wizard's *)
PROCEDURE P(tx, wx: INTEGER): INTEGER;
BEGIN IF inTabs THEN RETURN tx ELSE RETURN wx END
END P;

(* The pages, in the tabs if inTabs, else in the wizard. The tabs' first
   is shown and their pages close, the wizard's second shown. *)
PROCEDURE Pages;
VAR g, p: Fl.Group; i: FlInputs.Input; b: FlButtons.Button; c: FlValuators.Clock; x, w: INTEGER;
BEGIN
  x := P(10, 330); w := P(315, 320);
  IF inTabs THEN Page(g, x, w, "Label&1", "this tab tests correct keyboard navigation between text input fields", 1, TRUE)
  ELSE Page(g, x, w, "Label1", "this tab tests correct keyboard navigation between text input fields", 1, FALSE); g.Hide
  END;
  i := Input(P(70, 390), 80, 240, 40, "input:"); i.SetTooltip("This is the first input field");
  i := Input(P(70, 390), 120, 240, 30, "input2:"); i.SetTooltip("");
  i := Input(P(70, 390), 150, 240, 80, "input3:");
  g.End;
  p := g.Parent(); p.SetResizable(g);

  IF inTabs THEN Page(g, x, w, "tab&2", "tab2 tests among other things the cooperation of modal windows and tabs", 2, TRUE); g.Hide
  ELSE Page(g, x, w, "tab2", "tab2 tests among other things the cooperation of modal windows and tabs", 2, FALSE)
  END;
  b := Button(P(20, 350), 85, 100, 30, "button1", Button1Callback);
  i := Input(P(130, 455), 130, 175, 30, "input in box2");
  b := Button(P(25, 350), 170, 280, 30, 'This is stuff inside the Fl_Group "tab2"', NIL);
  b := Button(P(25, 350), 200, 280, 30, "Test event blocking by modal window", TestCallback);
  g.End;

  IF inTabs THEN Page(g, x, w, "tab&3", "tab3 checks for correct keyboard navigation", 3, TRUE)
  ELSE Page(g, x, w, "tab3", "tab3 checks for correct keyboard navigation", 3, FALSE)
  END;
  g.Hide;
  b := Button(P(20, 350), 80, 60, 80, "button2", NIL);
  b := Button(P(80, 410), 80, 60, 80, "button", NIL);
  b := Button(P(140, 470), 80, 60, 80, "button", NIL);
  g.End;

  IF inTabs THEN
    Page(g, x, w, "&tab4", "this tab shows the issue of indicating a selected tab if the tab layouts are very similar", 5, TRUE);
    g.SetLabelType(Fl.EngravedLabel)
  ELSE Page(g, x, w, "tab4", "this tab shows the issue of indicating a selected tab if the tab layouts are very similar", 5, FALSE)
  END;
  g.SetLabelFont(Fl.HelveticaItalic);
  g.Hide;
  b := Button(P(20, 350), 80, 60, 120, "button2", NIL);
  b := Button(P(80, 410), 80, 60, 120, "button", NIL);
  b := Button(P(140, 470), 80, 60, 120, "button", NIL);
  g.End;

  IF inTabs THEN Page(g, x, w, "@fileprint  &print", "tab5 verifies if visibility requests are handled correctly", -1, FALSE)
  ELSE
    Page(g, x, w, "     tab5      ", "tab5 verifies if visibility requests are handled correctly", -1, FALSE);
    g.SetLabelType(Fl.EngravedLabel)
  END;
  g.Hide;
  b := Button(P(20, 350), 80, 60, 80, "button2", NIL); b.SetTooltip("button2 has a different tooltip than tab5");
  b := Button(P(90, 420), 80, 60, 80, "button", NIL);
  NEW(c); FlValuators.OpenClock(c, P(185, 510), 80, 120, 120, "Make sure this clock does not use processor time when this tab is hidden or window is iconized");
  c.SetBoxType(Fl.OShadowBox);
  c.SetColor(238);
  c.SetSelectionColor(Fl.ForegroundColor);
  c.SetLabelFont(Fl.Times);
  c.SetLabelSize(10);
  c.SetAlign(Fl.AlignBottom + Fl.AlignWrap);
  SubWindow(P(20, 350), 190, 173, "", Fl.AlignInside);
  SubWindow(P(65, 395), 190, 167, "subwindows:", Fl.AlignTop);
  SubWindow(P(110, 440), 190, 239, "", Fl.AlignInside);
  g.End
END Pages;

PROCEDURE Key(x: INTEGER; label-, tip-: ARRAY OF CHAR; key: INTEGER; action: Action);
VAR b: FlButtons.Button;
BEGIN
  b := Button(x, 305, 30, 25, label, action);
  b.SetTooltip(tip);
  b.SetShortcut(key, {})
END Key;

BEGIN
  n := 6;
  NEW(fooWindow); Fl.OpenDoubleWindow(fooWindow, 660, 400, "Comparison of Fl_Tab (left) vs. Fl_Wizard (right)");
  Title(95, "class Fl_Tabs");
  NEW(tabsGroup); FlLayout.OpenTabs(tabsGroup, 10, 35, 315, 260, "");
  tabsGroup.SetTooltip("the various index cards test different aspects of the Fl_Tabs widget");
  tabsGroup.SetSelectionColor(4);
  tabsGroup.SetLabelColor(Fl.Background2Color);
  tabsGroup.action := TabsCallback;
  inTabs := TRUE; Pages;
  tabsGroup.End;
  fooWindow.SetResizable(tabsGroup);

  Title(410, "class Fl_Wizard");
  NEW(wWizard); FlLayout.OpenWizard(wWizard, 330, 35, 320, 260, "");
  inTabs := FALSE; Pages;
  wWizard.End;

  NEW(o); Fl.OpenGroup(o, 410, 305, 130, 25, "");
  Key(410, "@|<", "go to first page [Home]", Fl.KeyHome, FirstCallback);
  Key(440, "@<", "go to previous page [left arrow]", Fl.KeyLeft, PrevCallback);
  Key(480, "@>", "go to next page in wizard [right arrow]", Fl.KeyRight, NextCallback);
  Key(510, "@>|", "go to last page [End]", Fl.KeyEnd, LastCallback);
  o.End;

  IF Button(60, 309, 70, 25, "add tab", AddCallback) # NIL THEN END;
  NEW(overflow); FlMenus.OpenChoice(overflow, 212, 309, 95, 25, "overflow:");
  overflow.SetTooltip("Change how Fl_Tabs handles more tabs than fit into the tabs space.");
  overflow.SetDownBox(Fl.BorderBox);
  i := overflow.Add("compress", 0, {}, CompressCallback, {});
  i := overflow.Add("clip", 0, {}, ClipCallback, {});
  i := overflow.Add("pulldown", 0, {}, PulldownCallback, {});
  i := overflow.Add("drag", 0, {}, DragCallback, {});
  (* FLTK's menu() picks the first item; items added pick none *)
  IF overflow.SetValue(0) THEN END;

  NEW(input); FlInputs.OpenInput(input, 60, 345, 250, 25, "input:");
  NEW(cancel); FlButtons.OpenButton(cancel, 490, 345, 70, 30, "cancel");
  cancel.action := CancelCallback;
  NEW(ok); FlButtons.OpenReturnButton(ok, 570, 345, 70, 30, "OK");
  ok.action := OkCallback;
  fooWindow.End;
  fooWindow.ShowArgs;
  Fl.Run
END Tabs.
