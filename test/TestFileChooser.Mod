MODULE TestFileChooser; (* FlDialogs.FileChooser: FLTK's chooser, kept by the program *)

IMPORT SYSTEM, GC := GarbageCollectedHeap, Fl, FlDialogs, FlButtons, Check, Probe;

CONST tries = 400;  (* of 0.05 s, waiting for a window; generous, for valgrind *)

TYPE
  Chooser = POINTER TO RECORD (FlDialogs.FileChooserDesc)
    calls: INTEGER;
    closes, reads: BOOLEAN;
    got: ARRAY 256 OF CHAR
  END;

  (* Waits for the chooser's window to be modal, then types Enter, then
     fires once more to end any loop (TestDialogs' Answer). *)
  Answer = POINTER TO RECORD (Fl.TimerDesc)
    tries, seen: INTEGER;
    sent: BOOLEAN
  END;

  Closer = POINTER TO RECORD (FlButtons.ButtonDesc)
    c: FlDialogs.FileChooser
  END;

VAR
  answer: Answer;
  s: ARRAY 256 OF CHAR;
  old: BOOLEAN;
  ok: BOOLEAN;
  str: FlDialogs.Name;

PROCEDURE (c: Chooser) Callback*;
  VAR ok: BOOLEAN;
BEGIN
  INC(c.calls);
  IF c.reads THEN ok := c.Value(c.got) END;
  IF c.closes THEN c.Close END
END Callback;

PROCEDURE (a: Answer) Fire*;
  VAR title: ARRAY 64 OF CHAR; ok: BOOLEAN;
BEGIN
  IF a.sent THEN (* only to wake the loop *)
  ELSIF ~Probe.Modal(title) THEN
    INC(a.tries); IF a.tries < tries THEN Fl.RepeatTimeout(a, 0.05D0) END
  ELSIF a.seen < 2 THEN
    INC(a.seen); Fl.RepeatTimeout(a, 0.05D0)
  ELSE
    ok := Probe.ModalKey(Fl.KeyEnter, {}, 0DX);
    a.sent := TRUE; Fl.RepeatTimeout(a, 0.01D0)
  END
END Fire;

PROCEDURE (b: Closer) Callback*;
BEGIN b.c.Close
END Callback;

PROCEDURE Ends(s, end: ARRAY OF CHAR): BOOLEAN;
  VAR i, j: INTEGER;
BEGIN
  i := 0; WHILE s[i] # 0X DO INC(i) END;
  j := 0; WHILE end[j] # 0X DO INC(j) END;
  IF j > i THEN RETURN FALSE END;
  WHILE (j > 0) & (s[i - 1] = end[j - 1]) DO DEC(i); DEC(j) END;
  RETURN j = 0
END Ends;

(* Shows c, answers it with Enter, and waits for its window to hide, or
   for c to close. *)
PROCEDURE Answered(c: Chooser);
  VAR n: INTEGER;
BEGIN
  c.Show;
  NEW(answer); Fl.AddTimeout(answer, 0.05D0);
  n := 0;
  WHILE c.IsOpen() & c.Visible() & (n < tries) DO Fl.Wait(0.05D0); INC(n) END;
  WHILE answer.Pending() DO Fl.Wait(0.05D0) END
END Answered;

PROCEDURE Open(VAR c: Chooser);
BEGIN NEW(c); FlDialogs.OpenFileChooser(c, ".", "*.Mod", FlDialogs.ChooserSingle, "Open")
END Open;

PROCEDURE TestSettings;
  VAR c: Chooser; x: INTEGER; two: ARRAY 32 OF CHAR;
BEGIN
  two := "A (*.a)?B (*.b)"; two[7] := 09X;
  NEW(c);
  Check.Check(~c.IsOpen(), "a chooser isn't open before Open");
  FlDialogs.OpenFileChooser(c, "names", two, FlDialogs.ChooserMulti, "Title");
  Check.Check(c.IsOpen() & (FlDialogs.openChoosers = 1), "open");
  Check.Check(~c.Shown() & ~c.Visible(), "hidden to start with");
  c.GetLabel(s); Check.Check(s = "Title", "its label");
  c.SetLabel("Another"); c.GetLabel(s); Check.Check(s = "Another", "SetLabel");
  c.SetOkLabel("Take"); c.GetOkLabel(s); Check.Check(s = "Take", "SetOkLabel");
  c.Directory(s); Check.Check(Ends(s, "/names"), "its directory, absolute");
  c.SetDirectory("."); c.Directory(s); Check.Check(Ends(s, "/test"), "SetDirectory");
  Check.Check(c.FilterCount() = 4, "its filters, with All Files and Custom Filter");
  Check.Check(c.FilterValue() = 0, "the first in use");
  c.Filter(s); Check.Check(s = "*.a", "Filter gives the pattern in use");
  c.SetFilterValue(1); Check.Check(c.FilterValue() = 1, "SetFilterValue");
  c.Filter(s); Check.Check(s = "*.b", "and another's");
  c.SetFilterValue(0);
  c.SetFilter("*.Mod"); Check.Check(c.FilterCount() = 3, "SetFilter");
  Check.Check(c.Type() = FlDialogs.ChooserMulti, "Type");
  c.SetType(FlDialogs.ChooserCreate + FlDialogs.ChooserDirectory);
  Check.Check(c.Type() = FlDialogs.ChooserCreate + FlDialogs.ChooserDirectory, "SetType, a union");
  c.SetType(FlDialogs.ChooserSingle);
  Check.Check(c.Type() = {}, "ChooserSingle is none of them");

  c.SetColor(Fl.Yellow); Check.Check(c.Color() = Fl.Yellow, "SetColor");
  c.SetTextColor(Fl.Red); Check.Check(c.TextColor() = Fl.Red, "SetTextColor");
  c.SetTextFont(Fl.Courier); Check.Check(c.TextFont() = Fl.Courier, "SetTextFont");
  c.SetTextSize(11); Check.Check(c.TextSize() = 11, "SetTextSize");
  c.SetIconSize(20); Check.Check(c.IconSize() = 20, "SetIconSize");
  c.SetPosition(30, 40); Check.Check((c.X() = 30) & (c.Y() = 40), "SetPosition");
  x := c.W();
  c.Resize(10, 20, x + 10, 400);
  Check.Check((c.X() = 10) & (c.Y() = 20) & (c.W() = x + 10) & (c.H() = 400), "Resize");

  (* Preview is kept among the user's preferences: leave it as it was. *)
  old := c.Preview();
  c.SetPreview(~old); Check.Check(c.Preview() = ~old, "SetPreview");
  c.SetPreview(old);

  Check.Check(~c.ShowHidden(), "hidden files aren't listed");
  c.SetShowHidden(TRUE); Check.Check(c.ShowHidden(), "SetShowHidden");
  c.SetShowHidden(FALSE);
  c.Rescan;

  Check.Check(c.Value(s) & Ends(s, "/names"), "with no file chosen, the first directory");
  Check.Check(c.Count() = 1, "counts as one");
  c.SetValue("TestFileChooser.Mod");
  Check.Check(c.Value(s) & Ends(s, "/test/TestFileChooser.Mod"), "SetValue");
  Check.Check(c.Count() = 1, "one chosen");
  Check.Check(c.ValueAt(1, s), "ValueAt");
  str := c.Name(1);
  Check.Check((str # NIL) & (str^ = s), "Name");
  c.SetValue("");
  Check.Check(~c.Value(s) & (s = "") & (c.Count() = 0), "SetValue of nothing");
  Check.Check(c.Name(1) = NIL, "Name is NIL then");

  c.Close;
  Check.Check(~c.IsOpen() & (FlDialogs.openChoosers = 0), "closed");
  c.Close;
  Check.Check(~c.IsOpen() & (FlDialogs.openChoosers = 0), "Close again does nothing")
END TestSettings;

PROCEDURE TestCurrentGroup;
  VAR w: Fl.Window; c: Chooser; b: Fl.Box;
BEGIN
  NEW(w); Fl.OpenWindow(w, 100, 100, "group");
  Open(c);
  NEW(b); Fl.OpenBox(b, 0, 0, 10, 10, "");
  w.End;
  Check.Check(b.Parent() = w, "Open leaves the current group as it was");
  c.Close;
  w.Delete
END TestCurrentGroup;

PROCEDURE TestShow;
  VAR c: Chooser;
BEGIN
  Open(c); c.reads := TRUE;
  c.SetValue("TestFileChooser.Mod");
  Answered(c);
  Check.Check(c.calls >= 1, "Enter on a file calls back");
  Check.Check(Ends(c.got, "/test/TestFileChooser.Mod"), "and the file is there");
  Check.Check(~c.Visible(), "and hides the chooser");
  c.Close
END TestShow;

PROCEDURE TestCloseInCallback;
  VAR c: Chooser; i: INTEGER; b: BOOLEAN;
BEGIN
  Open(c); c.closes := TRUE;
  c.SetValue("TestFileChooser.Mod");
  Answered(c);
  Check.Check((c.calls = 1) & ~c.IsOpen(), "Close in the chooser's callback");
  Check.Check(FlDialogs.openChoosers = 0, "counts it closed");
  FOR i := 1 TO 5 DO b := Fl.Check() END
END TestCloseInCallback;

PROCEDURE TestCloseInWidgetCallback;
  VAR c: Chooser; b: Closer; old: Fl.Widget; i: INTEGER; ok: BOOLEAN;
BEGIN
  Open(c);
  NEW(b); FlButtons.OpenButton(b, 0, 0, 100, 25, "Close");
  b.c := c;
  old := c.SetExtra(b);
  b.DoCallback;
  Check.Check(~c.IsOpen(), "Close in a callback of its extra widget");
  FOR i := 1 TO 5 DO ok := Fl.Check() END;
  Check.Check(b.IsOpen() & (b.Parent() = NIL), "which outlives it");
  b.Delete
END TestCloseInWidgetCallback;

PROCEDURE TestExtra;
  VAR c: Chooser; a, b: Fl.Box; h: INTEGER; old: Fl.Widget;
BEGIN
  Open(c); h := c.H();
  NEW(a); Fl.OpenBox(a, 0, 0, 100, 30, "");
  NEW(b); Fl.OpenBox(b, 0, 0, 100, 20, "");
  Check.Check(c.SetExtra(a) = NIL, "the first extra widget replaces none");
  Check.Check(c.H() = h + 34, "the window grows for it");
  old := c.SetExtra(b);
  Check.Check(old = a, "SetExtra returns the last one");
  Check.Check(c.H() = h + 24, "the window fits the new one");
  Check.Check(a.IsOpen(), "which is the program's to delete");
  a.Delete;
  b.Delete;
  NEW(a); Fl.OpenBox(a, 0, 0, 100, 30, "");
  old := c.SetExtra(a);
  Check.Check(old = NIL, "an extra widget deleted comes back NIL");
  Check.Check(c.H() = h + 34, "and its room went with it");
  old := c.SetExtra(NIL);
  Check.Check((old = a) & (c.H() = h), "NIL leaves none");
  old := c.SetExtra(a);
  c.Show; c.Hide;
  a.Delete;     (* the extra widget deleted, then the chooser *)
  c.Close;

  Open(c);
  NEW(a); Fl.OpenBox(a, 0, 0, 100, 30, "");
  old := c.SetExtra(a);
  c.Close;      (* the chooser, then the extra widget *)
  Check.Check(a.IsOpen(), "the extra widget outlives the chooser");
  a.Delete
END TestExtra;

(* A chooser nothing else points to. *)
PROCEDURE Lose;
  VAR c: Chooser;
BEGIN
  Open(c)
END Lose;

PROCEDURE Scrub;
  VAR a: ARRAY 4096 OF LONGINT; i: INTEGER; zero: LONGINT;
BEGIN
  zero := 0;
  FOR i := 0 TO LEN(a) - 1 DO SYSTEM.PUT(SYSTEM.ADR(a[i]), zero) END
END Scrub;

PROCEDURE TestKept;
BEGIN
  Lose; Scrub; GC.Collect;
  Check.Check(FlDialogs.openChoosers = 1, "a chooser stays open with nothing pointing to it")
END TestKept;

PROCEDURE TestLabels;
  VAR c: Chooser;
BEGIN
  FlDialogs.SetChooserLabel(FlDialogs.LabelAllFiles, "Modules (*.Mod)");
  FlDialogs.SetChooserLabel(FlDialogs.LabelPreview, "Look");
  FlDialogs.SetChooserLabel(FlDialogs.LabelFilename, "Name:");
  NEW(c); FlDialogs.OpenFileChooser(c, ".", "", FlDialogs.ChooserSingle, "Open");
  c.SetFilterValue(0);
  c.Filter(s);
  Check.Check(s = "*.Mod", "SetChooserLabel sets the All Files filter");
  c.Show; c.Hide;
  c.Close;
  FlDialogs.SetChooserLabel(FlDialogs.LabelAllFiles, "All Files (*)");
  FlDialogs.SetChooserLabel(FlDialogs.LabelPreview, "Preview");
  FlDialogs.SetChooserLabel(FlDialogs.LabelFilename, "Filename:")
END TestLabels;

BEGIN
  TestSettings;
  TestCurrentGroup;
  TestShow;
  TestCloseInCallback;
  TestCloseInWidgetCallback;
  TestExtra;
  TestLabels;
  TestKept;
  Check.Summary
END TestFileChooser.
