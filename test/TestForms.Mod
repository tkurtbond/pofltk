MODULE TestForms; (* FlForms: FLTK's Forms classes, Timer, Free, FormsBitmap, FormsPixmap and FormsText *)

(* images/rb.xpm and rb.gif are 4 by 2, red left and blue right, and
   images/anim.gif is three frames of that size. A widget shows them at
   its top left. *)

IMPORT Fl, FlForms, FlImages, FlTest, Check;

TYPE
  Ringing = POINTER TO RECORD (FlForms.TimerDesc)
    rung: INTEGER;
    dies: BOOLEAN   (* deletes itself as it rings *)
  END;

  Heard = POINTER TO RECORD (FlForms.FreeDesc)
    draws, pushes, drags, keys, steps, others, calls: INTEGER;
    x, y, key: INTEGER;
    called: BOOLEAN (* HandleFree's answer *)
  END;

VAR
  win: Fl.Window;
  t, t2: FlForms.Timer;
  r: Ringing;
  h: Heard;
  b: FlForms.FormsBitmap;
  p: FlForms.FormsPixmap;
  tx: FlForms.FormsText;
  i: FlImages.Image;
  a: FlImages.AnimGIF;
  bits: ARRAY 2 OF CHAR;
  left, right: INTEGER;
  ok, stopped: BOOLEAN;
  v: LONGREAL;
  red, green, blue: INTEGER;

PROCEDURE (r: Ringing) Callback*;
BEGIN
  INC(r.rung);
  IF r.dies THEN r.Delete END
END Callback;

PROCEDURE (f: Heard) HandleFree*(event, x, y, key: INTEGER): BOOLEAN;
BEGIN
  IF event = FlForms.FreeDraw THEN INC(f.draws)
  ELSIF event = FlForms.FreeStep THEN INC(f.steps)
  ELSIF event = Fl.EvPush THEN INC(f.pushes)
  ELSIF event = Fl.EvDrag THEN INC(f.drags)
  ELSIF event = Fl.EvKeyDown THEN INC(f.keys)
  ELSE INC(f.others)
  END;
  f.x := x; f.y := y; f.key := key;
  RETURN f.called
END HandleFree;

PROCEDURE (f: Heard) Callback*;
BEGIN INC(f.calls)
END Callback;

(* Pixel x, y of widget w as drawn. *)
PROCEDURE Pixel(w: Fl.Widget; x, y: INTEGER): INTEGER;
  VAR q: INTEGER;
BEGIN ok := FlTest.Capture(w); q := FlTest.Pixel(x, y); FlTest.Release; RETURN q
END Pixel;

(* How many pixels of w, as drawn, in columns x0 to x1 aren't color c. *)
PROCEDURE Ink(w: Fl.Widget; x0, x1, c: INTEGER): INTEGER;
  VAR x, y, n: INTEGER;
BEGIN
  n := 0; ok := FlTest.Capture(w);
  FOR y := 0 TO w.H() - 1 DO
    FOR x := x0 TO x1 DO
      IF FlTest.Pixel(x, y) # c THEN INC(n) END
    END
  END;
  FlTest.Release; RETURN n
END Ink;

(* Lets FLTK's timers run for at most about s seconds: a wait can end
   early, and 30 didn't always bring a 0.01 second timer, on artos. So
   wait for what must happen, as WaitRing and WaitSteps do. *)
PROCEDURE Run(s: LONGREAL);
  VAR k: INTEGER;
BEGIN FOR k := 1 TO SHORT(ENTIER(s * 100)) DO Fl.Wait(0.01D0) END
END Run;

PROCEDURE WaitRing(r: Ringing);
  VAR k: INTEGER;
BEGIN k := 0; WHILE (r.rung = 0) & (k < 1000) DO Fl.Wait(0.01D0); INC(k) END
END WaitRing;

PROCEDURE WaitSteps(h: Heard);
  VAR k: INTEGER;
BEGIN k := 0; WHILE (h.steps = 0) & (k < 1000) DO Fl.Wait(0.01D0); INC(k) END
END WaitSteps;

PROCEDURE TestTimers;
  VAR gone, left: INTEGER;
BEGIN
  NEW(t); FlForms.OpenTimer(t, FlForms.NormalTimer, 0, 0, 100, 30, "");
  Check.Check(t.Suspended(), "a timer starts stopped");
  v := t.Value(); Check.Check(v = 0.0D0, "with no time");
  Check.Check(~t.CountsUp(), "showing the time left");
  t.SetValue(1000.0D0);
  Check.Check(~t.Suspended(), "setting a time starts it");
  v := t.Value(); Check.Check((v > 0.0D0) & (v <= 1000.0D0), "and it has that time");
  t.SetSuspended(TRUE);
  Check.Check(t.Suspended(), "it can be suspended");
  t.SetSuspended(FALSE);
  Check.Check(~t.Suspended(), "and started again");
  t.Delete;
  Run(0.3D0);
  Check.Check(TRUE, "a timer deleted as it runs stops");

  NEW(r); r.rung := 0; r.dies := FALSE;
  FlForms.OpenTimer(r, FlForms.HiddenTimer, 0, 0, 10, 10, "");
  Check.Check(~r.Visible(), "a hidden timer isn't visible");
  r.SetValue(0.05D0);
  WaitRing(r);
  Check.Check(r.rung = 1, "it calls back as it runs out");
  v := r.Value(); Check.Check(v = 0.0D0, "with no time left");
  Check.Check(r.Suspended(), "and stops");
  Run(0.3D0);
  Check.Check(r.rung = 1, "calling back once");
  r.Delete;

  NEW(r); r.rung := 0; r.dies := TRUE;
  FlForms.OpenTimer(r, FlForms.HiddenTimer, 0, 0, 10, 10, "");
  r.SetValue(0.05D0);
  WaitRing(r);
  Run(0.3D0);
  Check.Check(~r.IsOpen(), "a timer can delete itself as it runs out");

  (* Text as long as "1:40.0" against text as long as "0.0": FLTK's header
     has these the other way around. *)
  NEW(t); FlForms.OpenTimer(t, FlForms.ValueTimer, 0, 0, 100, 30, "");
  t.SetBoxType(Fl.FlatBox); t.SetColor(Fl.White); t.SetLabelColor(Fl.Black);
  t.SetValue(100.0D0); t.SetSuspended(TRUE);
  left := Ink(t, 0, 99, Fl.RGB(255, 255, 255));
  t.SetCountsUp(TRUE);
  Check.Check(t.CountsUp(), "a timer can show the time gone");
  gone := Ink(t, 0, 99, Fl.RGB(255, 255, 255));
  Check.Check(left > gone, "the default shows the time left, the other the time gone");
  t.Delete
END TestTimers;

PROCEDURE TestFrees;
BEGIN
  NEW(win); Fl.OpenWindow(win, 100, 100, "free");
  NEW(h); h.called := FALSE;
  FlForms.OpenFree(h, FlForms.NormalFree, 10, 10, 40, 40, "");
  win.End;
  ok := FlTest.Capture(h); FlTest.Release;
  Check.Check(h.draws = 1, "a free draws through HandleFree");
  Check.Check((h.x = 0) & (h.y = 0) & (h.key = 0), "with nothing else to say");

  ok := FlTest.Mouse(win, Fl.EvPush, 20, 30, 1, {}, 1);
  Check.Check(h.pushes = 1, "a free hears a push");
  Check.Check((h.x = 20) & (h.y = 30), "and where");
  Check.Check(h.key = 1, "and with which button");
  Check.Check(h.calls = 0, "it doesn't call back when told not to");
  h.called := TRUE;
  ok := FlTest.Mouse(win, Fl.EvDrag, 25, 35, 1, {}, 1);
  Check.Check(h.drags = 1, "it hears a drag");
  Check.Check(h.calls = 1, "and calls back when told to");
  h.called := FALSE;
  ok := FlTest.Mouse(win, Fl.EvRelease, 25, 35, 1, {}, 1);

  Fl.SetFocus(h);
  ok := FlTest.Key(Fl.EvKeyDown, Fl.KeyEnter, {}, 0DX);
  Check.Check(h.keys = 1, "it hears a key");
  Check.Check(h.key = Fl.KeyEnter, "whole, though FLTK passes a char");
  Fl.SetFocus(NIL);
  win.Delete;

  NEW(h); h.called := FALSE;
  FlForms.OpenFree(h, FlForms.SleepingFree, 0, 0, 10, 10, "");
  Check.Check(~h.Active(), "a sleeping free is inactive");
  Check.Check(~h.TakeFocus(), "and takes no focus");
  h.Delete;

  NEW(h); h.called := FALSE;
  FlForms.OpenFree(h, FlForms.NormalFree, 0, 0, 10, 10, "");
  Check.Check(~h.TakeFocus(), "a normal free takes no focus");
  h.Delete;

  NEW(h); h.called := TRUE;
  FlForms.OpenFree(h, FlForms.InputFree, 0, 0, 10, 10, "");
  Check.Check(h.TakeFocus(), "an input free does");
  Fl.SetFocus(NIL);
  h.Delete;

  NEW(h); h.called := FALSE;
  FlForms.OpenFree(h, FlForms.ContinuousFree, 0, 0, 10, 10, "");
  WaitSteps(h);
  Check.Check(h.steps > 0, "a continuous free gets steps");
  h.Delete;
  Run(0.1D0);
  Check.Check(TRUE, "and stops when deleted");

  NEW(h); h.called := FALSE;
  FlForms.OpenFree(h, FlForms.AllFree, 0, 0, 10, 10, "");
  WaitSteps(h);
  Check.Check(h.steps > 0, "so does a free of all kinds");
  h.Delete
END TestFrees;

PROCEDURE TestBitmaps;
BEGIN
  red := Fl.RGB(255, 0, 0); green := Fl.RGB(0, 255, 0); blue := Fl.RGB(0, 0, 255);
  bits[0] := 0FFX; bits[1] := 0FFX;

  NEW(b); FlForms.OpenFormsBitmap(b, 0, 0, 20, 20, "");
  Check.Check(b.BoxType() = Fl.NoBox, "a bitmap has no box to start with");
  b.SetBoxType(Fl.FlatBox); b.SetColor(blue); b.SetSelectionColor(red);
  Check.Check(Pixel(b, 10, 10) = red, "a bitmap with none shows its box, in the selection color");
  NEW(i); FlImages.OpenBitmap(i, bits, 8, 2);
  b.SetBitmap(i);
  i.Close;
  Check.Check(Pixel(b, 1, 1) = blue, "its bits take its color, and it keeps them");
  Check.Check(Pixel(b, 10, 10) = red, "around them is its box");
  NEW(i); FlImages.OpenBitmap(i, bits, 2, 2);
  b.SetBitmap(i);
  Check.Check(Pixel(b, 4, 1) = red, "another bitmap replaces the first");
  b.SetBitmap(NIL);
  Check.Check(Pixel(b, 1, 1) = red, "and no bitmap shows none");
  b.SetBitmap(i);
  b.Delete;
  i.Close;
  Check.Check(TRUE, "a bitmap's widget can go first");

  NEW(p); FlForms.OpenFormsPixmap(p, 0, 0, 20, 20, "");
  Check.Check(p.BoxType() = Fl.NoBox, "a pixmap has no box to start with");
  p.SetBoxType(Fl.FlatBox); p.SetSelectionColor(green);
  NEW(i); ok := FlImages.Load(i, "images/rb.xpm");
  Check.Check(ok, "an XPM loads");
  p.SetPixmap(i);
  i.Close;
  Check.Check(Pixel(p, 0, 0) = red, "a pixmap shows its left");
  Check.Check(Pixel(p, 3, 0) = blue, "and its right");
  Check.Check(Pixel(p, 10, 10) = green, "around them is its box");
  NEW(i); ok := FlImages.Load(i, "images/rb.gif");
  p.SetPixmap(i);
  i.Close;
  Check.Check(Pixel(p, 0, 0) = red, "a GIF is a pixmap");
  p.SetPixmap(NIL);
  Check.Check(Pixel(p, 0, 0) = green, "and no pixmap shows none");

  (* Its timer goes on as long as the widget keeps it. *)
  NEW(a); ok := FlImages.OpenAnimGIF(a, "images/anim.gif", p, FlImages.DontSetAsImage + FlImages.DontStart);
  Check.Check(ok, "an animation loads");
  p.SetPixmap(a);
  a.Close;
  Check.Check(Pixel(p, 0, 0) = red, "and a pixmap shows it");
  NEW(a); ok := FlImages.OpenAnimGIF(a, "images/anim.gif", p, FlImages.DontSetAsImage);
  p.SetPixmap(a);
  a.Close;
  Run(0.35D0);
  ok := FlTest.Capture(p); FlTest.Release;
  Check.Check(TRUE, "the pixmap keeps one that plays, closed");
  NEW(a); ok := FlImages.OpenAnimGIF(a, "images/anim.gif", p, FlImages.DontSetAsImage);
  p.SetPixmap(a);
  Run(0.35D0);
  ok := FlTest.Capture(p); FlTest.Release;
  p.Delete;
  Run(0.35D0);
  Check.Check(a.Playing(), "an animation outlives its widget");
  a.Close;
  Run(0.1D0)
END TestBitmaps;

PROCEDURE TestText;
BEGIN
  NEW(tx); FlForms.OpenFormsText(tx, 0, 0, 100, 30, "x");
  Check.Check(tx.BoxType() = Fl.NoBox, "text has no box to start with");
  Check.Check(tx.Align() = Fl.AlignLeft, "and its label at the left");
  tx.SetBoxType(Fl.FlatBox); tx.SetColor(Fl.White); tx.SetLabelColor(Fl.Black);
  left := Ink(tx, 0, 49, Fl.RGB(255, 255, 255));
  right := Ink(tx, 50, 99, Fl.RGB(255, 255, 255));
  Check.Check((left > 0) & (right = 0), "its label is inside it");
  Check.Check(tx.Align() = Fl.AlignLeft + Fl.AlignInside, "and drawing it says so");
  tx.Delete
END TestText;

BEGIN
  TestTimers;
  TestFrees;
  TestBitmaps;
  TestText;
  Check.Summary
END TestForms.
