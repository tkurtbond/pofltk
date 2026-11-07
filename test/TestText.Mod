MODULE TestText; (* FlText: buffers, their lifetime, displays, styles and editors *)

IMPORT SYSTEM, GC := GarbageCollectedHeap, Fl, FlText, Check, Probe;

CONST file = "../build/TestText.txt";

TYPE
  (* records each change *)
  Watched = POINTER TO RECORD (FlText.TextBufferDesc)
    calls, pos, inserted, deleted: INTEGER
  END;

  (* Waits for a dialog, FLTK's alert that a file was transcoded, and
     sends Escape; then fires once more, as TestPrint's Answer does. *)
  Answer = POINTER TO RECORD (Fl.TimerDesc)
    title: ARRAY 64 OF CHAR;
    tries, seen: INTEGER;
    sent: BOOLEAN
  END;

VAR
  win, lwin: Fl.Window;
  b, other, styles: FlText.TextBuffer;
  primary, secondary, lit: FlText.Selection;
  w: Watched;
  d, d2, ld: FlText.TextDisplay;
  e: FlText.TextEditor;
  s, t: ARRAY 256 OF CHAR;
  i, j, pos, x, y: INTEGER;
  c: CHAR;
  ok: BOOLEAN;
  answer: Answer;

(* Whether the last capture has anything but its background, the color at
   x0, y1 - 1, in x0 to x1 - 1 and y0 to y1 - 1. *)
PROCEDURE Inked(x0, y0, x1, y1: INTEGER): BOOLEAN;
  VAR x, y, bg: INTEGER; found: BOOLEAN;
BEGIN
  bg := Probe.Pixel(x0, y1 - 1); found := FALSE; y := y0;
  WHILE ~found & (y < y1) DO
    x := x0;
    WHILE ~found & (x < x1) DO found := Probe.Pixel(x, y) # bg; INC(x) END;
    INC(y)
  END;
  RETURN found
END Inked;

PROCEDURE (w: Watched) Modified*(pos, inserted, deleted, restyled: INTEGER);
BEGIN INC(w.calls); w.pos := pos; w.inserted := inserted; w.deleted := deleted
END Modified;

PROCEDURE (a: Answer) Fire*;
  VAR ok: BOOLEAN;
BEGIN
  IF a.sent THEN (* only to wake the loop *)
  ELSIF ~Probe.Modal(a.title) THEN
    INC(a.tries); IF a.tries < 400 THEN Fl.RepeatTimeout(a, 0.05D0) END
  ELSIF a.seen < 2 THEN  (* let it settle *)
    INC(a.seen); Fl.RepeatTimeout(a, 0.05D0)
  ELSE
    ok := Probe.ModalKey(Fl.KeyEscape, {}, 1BX);
    a.sent := TRUE; Fl.RepeatTimeout(a, 0.01D0)
  END
END Fire;

(* a, b and c joined by newlines, as many as given ("" ends them) *)
PROCEDURE Lines(a, b, c: ARRAY OF CHAR; VAR s: ARRAY OF CHAR);
  VAR i: INTEGER;
  PROCEDURE Add(t: ARRAY OF CHAR);
    VAR j: INTEGER;
  BEGIN
    IF t # "" THEN
      IF i > 0 THEN s[i] := 0AX; INC(i) END;
      j := 0; WHILE t[j] # 0X DO s[i] := t[j]; INC(i); INC(j) END
    END
  END Add;
BEGIN i := 0; Add(a); Add(b); Add(c); s[i] := 0X
END Lines;

(* Allocates and drops garbage, then collects, so the collector runs and
   the stack a lost object was on is reused (polibfyaml's TestLiveness). *)
PROCEDURE Churn;
  VAR i: INTEGER; p: POINTER TO ARRAY OF CHAR;
BEGIN
  FOR i := 1 TO 200 DO NEW(p, 1000); p[0] := "x" END;
  GC.Collect
END Churn;

(* Overwrites the stack below the caller's frame, where a procedure that
   has returned (Lose, Show) may have left an object's address for the
   collector's conservative scan to take for a reference. Called between
   them and Churn, at the same depth: on 32-bit x86 (OpenBSD i386) a lost
   buffer's address survived in Churn's own frame, so the buffer outlived
   the first collection. SYSTEM.PUT, so that the stores happen at any -opt. *)
PROCEDURE Scrub;
  VAR a: ARRAY 4096 OF LONGINT; i: INTEGER; zero: LONGINT;
BEGIN
  FOR i := 0 TO LEN(a) - 1 DO SYSTEM.PUT(SYSTEM.ADR(a[i]), zero) END
END Scrub;

(* A buffer made and lost, without Close. *)
PROCEDURE Lose;
  VAR b: FlText.TextBuffer;
BEGIN NEW(b); FlText.OpenBuffer(b); b.SetText("lost")
END Lose;

(* A buffer shown by d and lost, without Close. *)
PROCEDURE Show(d: FlText.TextDisplay);
  VAR b: FlText.TextBuffer;
BEGIN NEW(b); FlText.OpenBuffer(b); b.SetText("shown"); d.SetBuffer(b)
END Show;

(* Checks the buffer Show gave d: still open, with its text. A procedure,
   not the module body, so that no copy of its address outlives the call:
   at -opt 0 (32-bit x86's default) every value the body computes keeps a
   stack slot of its own until the body ends, and the collector's
   conservative scan would take it for a reference. *)
PROCEDURE CheckShown(d: FlText.TextDisplay);
  VAR shown: FlText.TextBuffer; t: ARRAY 16 OF CHAR;
BEGIN
  shown := d.Buffer();
  Check.Check((FlText.openBuffers = 2) & shown.IsOpen(), "a buffer shown isn't collected");
  shown.GetText(t);
  Check.Check(t = "shown", "and keeps its text")
END CheckShown;

BEGIN
  (* First, while no other call has left the buffer's address on the
     stack, where the collector's conservative scan would take it for a
     reference. *)
  Lose; Scrub; Churn;
  Check.Check(FlText.openBuffers = 0, "a buffer lost without Close is closed by the collector");

  (* buffers *)
  NEW(b); FlText.OpenBuffer(b);
  Check.Check(b.IsOpen() & (b.Length() = 0) & (FlText.openBuffers = 1), "a new buffer is empty");
  b.SetText("one two"); b.Append(" three"); b.Insert(0, "zero ");
  b.GetText(s);
  Check.Check((s = "zero one two three") & (b.Length() = 18), "SetText, Append, Insert");
  b.TextRange(5, 8, s);
  Check.Check(s = "one", "TextRange");
  b.Remove(0, 5); b.Replace(0, 3, "1");
  b.GetText(s);
  Check.Check(s = "1 two three", "Remove, Replace");
  b.GetText(s); i := 0; WHILE i < 3 DO s[i] := "x"; INC(i) END;
  b.TextRange(0, 3, s);
  Check.Check(s = "1 t", "GetText truncates to fit");
  s := "caf__!"; s[3] := 0C3X; s[4] := 0A9X; b.SetText(s);
  Check.Check((b.Length() = 6) & (b.CharAt(3) = 0E9H) & (b.ByteAt(3) = 0C3X) & (b.NextChar(3) = 5)
    & (b.PrevChar(5) = 3) & (b.Align(4) = 3) & (b.CharAt(99) = 0), "UTF-8: CharAt, ByteAt, NextChar, PrevChar, Align");
  Check.Check(b.TabDistance() = 8, "tab stops every 8 columns to start with");

  (* undo *)
  b.SetText("");
  b.Insert(0, "abc"); b.Insert(3, "def");
  Check.Check(b.CanUndo() & ~b.CanRedo(), "CanUndo");
  ok := b.Undo(pos); b.GetText(s);
  Check.Check(ok & (s = "") & (pos = 0), "Undo undoes insertions one after another together");
  ok := b.Redo(pos); b.GetText(s);
  Check.Check(ok & (s = "abcdef") & (pos = 6), "Redo");

  (* the three selections *)
  b.SetText("one two three four");
  primary := b.PrimarySelection(); secondary := b.SecondarySelection(); lit := b.HighlightSelection();
  b.Unselect;
  Check.Check(~primary.Selected() & ~secondary.Selected() & ~lit.Selected()
    & (primary.Start() = 0) & (primary.End() = 0) & (primary.Length() = 0), "no selection is set to start with");
  b.Select(4, 7); b.SecondarySelect(8, 13); b.Highlight(14, 18);
  Check.Check(primary.Selected() & (primary.Start() = 4) & (primary.End() = 7) & (primary.Length() = 3)
    & primary.Includes(4) & primary.Includes(6) & ~primary.Includes(7) & ~primary.Includes(3),
    "a Selection reads the primary selection");
  Check.Check(secondary.Selected() & (secondary.Start() = 8) & (secondary.End() = 13)
    & lit.Selected() & (lit.Start() = 14) & (lit.End() = 18), "the secondary and the highlight");
  b.SecondaryText(s);
  Check.Check(s = "three", "SecondaryText");
  b.HighlightText(s);
  Check.Check(s = "four", "HighlightText");
  b.Replace(0, 3, "first");
  Check.Check((primary.Start() = 6) & (secondary.Start() = 10) & (lit.Start() = 16),
    "they move with the text");
  b.ReplaceSecondary("3");
  b.GetText(s);
  Check.Check((s = "first two 3 four") & ~secondary.Selected(), "ReplaceSecondary");
  b.SecondarySelect(6, 9);
  b.RemoveSecondary;
  b.GetText(s);
  Check.Check((s = "first  3 four") & ~secondary.Selected(), "RemoveSecondary");
  b.SecondarySelect(0, 5);
  b.SecondaryUnselect; b.Unhighlight;
  Check.Check(~secondary.Selected() & ~lit.Selected(), "SecondaryUnselect and Unhighlight");
  b.Unselect;

  (* selection, lines, words, search *)
  Lines("first line", "second line", "third", s); b.SetText(s);
  Check.Check(~b.Selection(i, j), "nothing is selected to start with");
  b.Select(6, 10);
  b.SelectionText(s);
  Check.Check(b.Selection(i, j) & (i = 6) & (j = 10) & (s = "line"), "Select, Selection, SelectionText");
  b.ReplaceSelection("row"); b.LineText(0, s);
  Check.Check(s = "first row", "ReplaceSelection; LineText");
  Check.Check((b.LineStart(13) = 10) & (b.LineEnd(13) = 21) & (b.CountLines(0, b.Length()) = 2)
    & (b.SkipLines(0, 2) = 22) & (b.RewindLines(25, 1) = 10), "lines");
  Check.Check((b.WordStart(13) = 10) & (b.WordEnd(13) = 16), "words");
  Check.Check((b.CountDisplayedCharacters(0, 9) = 9) & (b.CountDisplayedCharacters(-5, 999) = b.Length())
    & (b.SkipDisplayedCharacters(0, 50) = 9) & (b.SkipDisplayedCharacters(-3, 2) = 2), "characters shown, clamped");
  Check.Check(b.FindCharForward(0, ORD("s"), i) & (i = 3) & b.FindCharBackward(99, ORD("f"), j) & (j = 0)
    & ~b.FindCharForward(-4, ORD("z"), pos) & (pos = b.Length()), "FindChar");
  Check.Check(b.SearchForward(0, "LINE", FALSE, i) & (i = 17) & ~b.SearchForward(0, "LINE", TRUE, i)
    & b.SearchBackward(b.Length(), "r", TRUE, i) & (i = 25), "search");
  Check.Check(b.SearchForward(0, "third", TRUE, i) & (i = 22) & ~b.SearchForward(23, "third", TRUE, i)
    & b.SearchBackward(b.Length(), "third", TRUE, i) & (i = 22) & b.SearchBackward(99, "first", TRUE, i) & (i = 0)
    & ~b.SearchForward(0, "thirdd", TRUE, i), "matching case, up to the end of the text");
  Check.Check(b.SearchBackward(99, "FIRST", FALSE, i) & (i = 0) & ~b.SearchForward(99, "first", FALSE, i),
    "not matching case, from past the end");

  (* files *)
  s := "saved_"; s[5] := 0AX; b.SetText(s);
  Check.Check(b.SaveFile(file), "SaveFile");
  b.SetText("");
  Check.Check(b.LoadFile(file) & (b.Length() = 6), "LoadFile");
  Check.Check(b.AppendFile(file) & b.InsertFile(file, 0) & (b.Length() = 18), "AppendFile, InsertFile");
  Check.Check(b.SaveRange(file, 0, 3) & b.LoadFile(file) & (b.Length() = 3), "SaveRange");
  Check.Check(~b.LoadFile("../build/no such file"), "a file that isn't there is FALSE");
  (* A Latin-1 letter in the last three bytes of a file: FLTK's own
     loadfile would stop before it, with no warning. *)
  s := "cafe_"; s[3] := 0E9X; s[4] := 0AX; b.SetText(s);
  Check.Check(b.SaveFile(file) & (b.Length() = 5), "SaveFile, Latin-1");
  NEW(answer); Fl.AddTimeout(answer, 0.05D0);
  Check.Check(b.LoadFile(file) & (b.Length() = 6), "LoadFile transcodes a Latin-1 end");
  b.GetText(t);
  Check.Check((t[3] = 0C3X) & (t[4] = 0A9X) & (t[5] = 0AX) & answer.sent, "into UTF-8, with FLTK's warning");
  s[3] := 80X; s[4] := 0X; b.SetText(s);
  NEW(answer); Fl.AddTimeout(answer, 0.05D0);
  Check.Check(b.SaveFile(file) & b.LoadFile(file) & (b.Length() = 6), "a byte from 80X to 9FX is CP1252's");
  b.GetText(t);
  Check.Check((t[3] = 0E2X) & (t[4] = 82X) & (t[5] = 0ACX) & answer.sent, "the euro sign");
  s := "plain_"; s[5] := 0AX; b.SetText(s);
  Check.Check(b.SaveFile(file) & b.LoadFile(file) & (b.Length() = 6), "UTF-8 is read as it is");

  (* Modified *)
  NEW(w); FlText.OpenBuffer(w);
  w.SetText("abc"); w.calls := 0;
  w.Insert(1, "XY");
  Check.Check((w.calls = 1) & (w.pos = 1) & (w.inserted = 2) & (w.deleted = 0), "Modified after each change");
  w.Remove(0, 4);
  Check.Check((w.calls = 2) & (w.pos = 0) & (w.inserted = 0) & (w.deleted = 4), "a removal");

  (* closing and collecting *)
  w.Close; w.Close;
  Check.Check(~w.IsOpen() & (FlText.openBuffers = 1), "Close, twice");

  (* displays *)
  NEW(win); Fl.OpenWindow(win, 400, 300, "TestText");
  NEW(d); FlText.OpenTextDisplay(d, 0, 0, 200, 100, "");
  NEW(d2); FlText.OpenTextDisplay(d2, 200, 0, 200, 100, "");
  NEW(e); FlText.OpenTextEditor(e, 0, 100, 400, 100, "");
  Check.Check((d.Buffer() = NIL) & Probe.Capture(d), "a display without a buffer draws");
  Check.Check((d.LineNumberWidth() = 0) & (d.ScrollbarSize() = 0) & e.InsertMode() & ~e.TabNav(),
    "no line numbers, Fl's scrollbar size, inserting, Tab typed, to start with");
  Lines("hello", "world", "", s); b.SetText(s);
  d.SetBuffer(b);
  d.SetInsertPosition(2); d.Insert("XX");
  b.GetText(s); Lines("heXXllo", "world", "", t);
  Check.Check((d.Buffer() = b) & (s = t) & (d.InsertPosition() = 4),
    "Insert types at the cursor");
  (* MoveDown keeps the cursor's x, so in a proportional font where it
     lands depends on the font's widths: "heXX" is nearer "worl" in Noto
     Sans, nearer "world" in DejaVu Sans (OpenBSD). Courier makes it
     column 4. *)
  d.SetTextFont(Fl.Courier);
  ok := d.MoveDown(); i := d.InsertPosition();
  ok := d.MoveRight(); j := d.InsertPosition();
  d.SetTextFont(Fl.Helvetica);

  Check.Check((i = 12) & (j = 13) & (d.LineStart(j) = 8) & (d.LineEnd(1) = 7), "moving the cursor, and lines");
  Check.Check(~d.MoveDown(), "FALSE at the last line");
  d.SetWrapMode(FlText.WrapAtColumn, 3);
  Check.Check(Probe.Capture(d) & (d.CountLines(0, b.Length()) > 1), "wrapping");
  (* "heXXllo" wraps two to a row in Courier, so "world" is the fifth row *)
  d.SetTextFont(Fl.Courier); ok := Probe.Capture(d);
  Check.Check((d.WrappedRow(0) = 0) & (d.WrappedRow(3) = 0) & (d.WrappedRow(4) = 1)
    & (d.WrappedColumn(0, 1) = 1) & (d.WrappedColumn(1, 1) = 3) & (d.WrappedColumn(3, 1) = 7)
    & (d.WrappedColumn(4, 1) = 1), "WrappedRow and WrappedColumn: the buffer's line and column of a row's");
  (* every row, and past the last: FLTK reads one past its rows' starts *)
  FOR i := 0 TO 20 DO j := d.WrappedRow(i); j := d.WrappedColumn(i, 1) END;
  Check.Check((d.WrappedRow(99) = 99) & (d.WrappedColumn(-1, 2) = 2), "a row off the screen is itself");
  d.RedisplayRange(0, 3); d.RedisplayRange(-9, 999);
  Check.Check(Probe.Capture(d), "RedisplayRange");
  d.SetTextFont(Fl.Helvetica);
  d.SetWrapMode(FlText.WrapNone, 0);
  Check.Check(Probe.Capture(d) & d.PositionToXY(0, x, y), "PositionToXY of text shown");

  (* a buffer closed while shown lives on until no display shows it *)
  NEW(other); FlText.OpenBuffer(other); other.SetText("still here");
  d.SetBuffer(other); d2.SetBuffer(other);
  other.Close;
  d.SetInsertPosition(5); d.Insert("!");
  Check.Check((FlText.openBuffers = 1) & Probe.Capture(d) & (d.InsertPosition() = 6),
    "a closed buffer shown still works in its displays");
  d.Delete;
  Check.Check(Probe.Capture(d2) & (d2.InsertPosition() = 0), "after one is deleted, in the other");
  d2.SetBuffer(b);
  Show(d2); Scrub; Churn;
  CheckShown(d2);

  (* styles *)
  NEW(styles); FlText.OpenBuffer(styles);
  b.SetText("XXXXXXXX"); styles.SetText("AAAABBBB");
  d2.SetBuffer(b); d2.SetStyleBuffer(styles);
  Check.Check(Probe.Capture(d2), "a style buffer with no styles yet draws the plain text");
  c := d2.AddStyle(Fl.Black, Fl.Courier, 14, FlText.AttrBgcolor, Fl.Red);
  Check.Check((c = "A") & (d2.AddStyle(Fl.Black, Fl.Courier, 14, 0, Fl.White) = "B")
    & (d2.StyleBuffer() = styles), "AddStyle gives the styles' characters");
  styles.Close;
  ok := Probe.Capture(d2) & d2.PositionToXY(1, x, y);
  Check.Check(ok & (Probe.Pixel(x - d2.X() + 1, y - d2.Y() + 2) = Fl.RGB(255, 0, 0)), "style A's background is drawn");
  d2.ClearStyles;
  Check.Check(Probe.Capture(d2) & (Probe.Pixel(x - d2.X() + 1, y - d2.Y() + 2) # Fl.RGB(255, 0, 0)), "ClearStyles");

  (* an editor *)
  b.SetText("");
  e.SetBuffer(b);
  ok := e.TakeFocus();
  ok := Probe.Key(Fl.EvKeyDown, ORD("a"), {}, "a");
  ok := Probe.Key(Fl.EvKeyDown, ORD("b"), {}, "b");
  ok := Probe.Key(Fl.EvKeyDown, Fl.KeyBackSpace, {}, 08X);
  ok := Probe.Key(Fl.EvKeyDown, ORD("c"), {}, "c");
  b.GetText(s);
  Check.Check((s = "ac") & (e.InsertPosition() = 2), "typing in an editor");
  e.SetInsertMode(FALSE); e.SetInsertPosition(0);
  ok := Probe.Key(Fl.EvKeyDown, ORD("z"), {}, "z");
  b.GetText(s);
  Check.Check(s = "zc", "typing over");

  (* Line numbers' format and alignment. FLTK draws line numbers only in a
     window shown (visible_r), so this display has a window of its own. *)
  NEW(lwin); Fl.OpenWindow(lwin, 200, 100, "TestText numbers");
  NEW(ld); FlText.OpenTextDisplay(ld, 0, 0, 200, 100, ""); lwin.End;
  ld.SetBuffer(b); b.SetText("one");
  lwin.Show; lwin.WaitForExpose;
  ld.SetLineNumberWidth(40); ld.LineNumberFormat(s);
  Check.Check((s = "%d") & (ld.LineNumberAlign() = Fl.AlignRight), "line numbers are %d, on the right, to start with");
  Check.Check(Probe.Capture(ld) & Inked(4, 4, 36, 30), "and drawn");
  ld.SetLineNumberFormat("%-4d%%"); ld.LineNumberFormat(s);
  Check.Check(s = "%-4d%%", "a format with flags, a width and %%");
  ld.SetLineNumberFormat(""); ld.LineNumberFormat(s);
  Check.Check((s = "") & Probe.Capture(ld) & ~Inked(4, 4, 36, 30), "one with no number shows none");
  ld.SetLineNumberFormat("%03x"); ld.SetLineNumberAlign(Fl.AlignLeft);
  Check.Check((ld.LineNumberAlign() = Fl.AlignLeft) & Probe.Capture(ld) & Inked(4, 4, 36, 30), "SetLineNumberAlign");
  lwin.Delete;

  b.Close;
  win.Delete;
  Check.Check((Fl.OpenWidgets() = 0) & (FlText.openBuffers = 1), "every widget deleted; one buffer is still shown by d2");
  d2 := NIL; other := NIL; Scrub; Churn;
  Check.Check(FlText.openBuffers = 0, "collected with its display");
  Check.Summary
END TestText.
