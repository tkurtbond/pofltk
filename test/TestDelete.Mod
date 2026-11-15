MODULE TestDelete; (* However FLTK destroys a widget, Fl closes its object *)

(* PLAN.md, "Lifetime and the collector": FLTK deletes a widget's user
   data with it (AUTO_DELETE_USER_DATA), and Fl closes the object then:
   explicitly, with its parent group, deleted inside its own callback
   (later, by Fl::delete_widget), and as a shown window. Also: a label is
   copied, so changing the string it came from changes nothing.

   A widget deleted inside a callback is only queued, and stays in its
   group until FLTK runs the queue; deleted again before then, with its
   group or by itself, outside a callback or inside one, it is deleted
   once (doc/fltk-issues.md, 72). *)

IMPORT Fl, Check;

TYPE
  SelfDeleting = POINTER TO RECORD (Fl.BoxDesc)
    openInside: BOOLEAN  (* IsOpen right after Delete, inside the callback *)
  END;

  (* Its callback runs run. *)
  Trigger = POINTER TO RECORD (Fl.BoxDesc)
    run: PROCEDURE
  END;

VAR
  win: Fl.Window;
  g, inner: Fl.Group;
  a, b, c: Fl.Box;
  s: SelfDeleting;
  t: Fl.Box;
  trigger: Trigger;
  label: ARRAY 16 OF CHAR;
  got: ARRAY 32 OF CHAR;
  shown: BOOLEAN;
  rebuilder: Trigger;          (* g's child, rebuilding g in its callback *)
  laterRuns, inside: INTEGER;
  aOpenLater: BOOLEAN;
  i: INTEGER;

PROCEDURE (w: SelfDeleting) Callback*;
BEGIN w.Delete; w.openInside := w.IsOpen()
END Callback;

PROCEDURE (w: Trigger) Callback*;
BEGIN w.run
END Callback;

PROCEDURE ClearG;
BEGIN g.Clear
END ClearG;

PROCEDURE DeleteA;
BEGIN a.Delete
END DeleteA;

PROCEDURE DeleteGThenA;
BEGIN g.Delete; a.Delete
END DeleteGThenA;

PROCEDURE DeleteGThenClear;
BEGIN g.Delete; g.Clear
END DeleteGThenClear;

PROCEDURE AtLater;
BEGIN INC(laterRuns); aOpenLater := a.IsOpen()
END AtLater;

PROCEDURE DeleteAThenLater;
BEGIN a.Delete; Fl.Later(AtLater)
END DeleteAThenLater;

(* Rebuilds g, rebuilder's own group, with two new boxes. *)
PROCEDURE Rebuild;
  VAR x, y: Fl.Box;
BEGIN
  g.Clear; g.Begin;
  NEW(x); Fl.OpenBox(x, 0, 0, 10, 10, "new 1");
  NEW(y); Fl.OpenBox(y, 0, 20, 10, 10, "new 2");
  g.End; inside := g.Children()
END Rebuild;

(* g holding a and inner, inner holding b. *)
PROCEDURE Family;
BEGIN
  NEW(g); Fl.OpenGroup(g, 0, 0, 100, 100, "g");
  NEW(a); Fl.OpenBox(a, 0, 0, 10, 10, "child");
  NEW(inner); Fl.OpenGroup(inner, 0, 0, 50, 50, "inner");
  NEW(b); Fl.OpenBox(b, 0, 0, 10, 10, "grandchild");
  inner.End; g.End
END Family;

(* Runs action inside a callback. *)
PROCEDURE Inside(action: PROCEDURE);
BEGIN trigger.run := action; trigger.DoCallback
END Inside;

PROCEDURE AllClosed(): BOOLEAN;
BEGIN RETURN ~g.IsOpen() & ~a.IsOpen() & ~inner.IsOpen() & ~b.IsOpen() & (Fl.OpenWidgets() = 1)
END AllClosed;

BEGIN
  (* explicitly *)
  NEW(a); Fl.OpenBox(a, 0, 0, 10, 10, "a");
  Check.Check(a.IsOpen() & (Fl.OpenWidgets() = 1), "an opened box is open");
  a.Delete;
  Check.Check(~a.IsOpen() & (a.h = 0) & (Fl.OpenWidgets() = 0), "Delete closes it at once");

  (* with its parent group, to any depth *)
  NEW(g); Fl.OpenGroup(g, 0, 0, 100, 100, "g");
  NEW(a); Fl.OpenBox(a, 0, 0, 10, 10, "child");
  NEW(inner); Fl.OpenGroup(inner, 0, 0, 50, 50, "inner");
  NEW(b); Fl.OpenBox(b, 0, 0, 10, 10, "grandchild");
  inner.End; g.End;
  Check.Check((g.Children() = 2) & (inner.Children() = 1) & (Fl.OpenWidgets() = 4),
    "a group with a box and a group with a box");
  g.Delete;
  Check.Check(~g.IsOpen() & ~a.IsOpen() & ~inner.IsOpen() & ~b.IsOpen()
    & (Fl.OpenWidgets() = 0), "deleting the group closes all four");

  (* inside its own callback: later *)
  NEW(s); Fl.OpenBox(s, 0, 0, 10, 10, "s");
  s.DoCallback;
  Check.Check(s.openInside, "deleted inside its callback, it stays open until that returns");
  Check.Check(s.IsOpen() & (Fl.OpenWidgets() = 1), "and after the callback, until FLTK runs");
  shown := Fl.Check();
  Check.Check(~s.IsOpen() & (Fl.OpenWidgets() = 0), "Fl.Check deletes it");

  (* queued, then deleted again before FLTK runs the queue *)
  NEW(trigger); Fl.OpenBox(trigger, 0, 0, 10, 10, "trigger");
  Family; Inside(ClearG);
  Check.Check(a.IsOpen() & inner.IsOpen() & (g.Children() = 2), "cleared inside a callback: the children queued, still there");
  g.Delete;
  Check.Check(AllClosed(), "then the group deleted outside one: each child deleted once");
  shown := Fl.Check();
  Check.Check(Fl.OpenWidgets() = 1, "and FLTK's queue deletes nothing again");

  Family; Inside(ClearG);
  g.Clear;
  Check.Check(~a.IsOpen() & ~inner.IsOpen() & ~b.IsOpen() & g.IsOpen() & (g.Children() = 0),
    "cleared inside a callback, then again outside one: each child deleted once");
  g.Delete; shown := Fl.Check();
  Check.Check(AllClosed(), "and the group with it");

  Family; Inside(DeleteA);
  a.Delete;
  Check.Check(~a.IsOpen() & (g.Children() = 1), "deleted inside a callback, then again outside one: deleted once");
  g.Delete; shown := Fl.Check();
  Check.Check(AllClosed(), "the rest with their group");

  Family; Inside(DeleteGThenA);
  shown := Fl.Check();
  Check.Check(AllClosed(), "inside a callback, a group deleted, then its child: each deleted once");

  Family; Inside(DeleteGThenClear);
  shown := Fl.Check();
  Check.Check(AllClosed(), "inside a callback, a group deleted, then cleared: each deleted once");

  (* Later: once, after the widgets deleted in the callback are gone *)
  Family; laterRuns := 0; aOpenLater := TRUE; Inside(DeleteAThenLater);
  Check.Check((laterRuns = 0) & a.IsOpen() & (Fl.PendingTimers() = 1),
    "Later calls nothing at once, and counts as a pending timer");
  i := 0;
  WHILE (laterRuns = 0) & (i < 200) DO Fl.Wait(0.01D0); INC(i) END;
  Check.Check((laterRuns = 1) & ~aOpenLater & (Fl.PendingTimers() = 0),
    "the event loop calls it after deleting what the callback deleted");
  Fl.Wait(0.01D0); shown := Fl.Check();
  Check.Check(laterRuns = 1, "and only once");
  g.Delete;
  Check.Check(AllClosed(), "the rest with their group");
  trigger.Delete;

  (* a group rebuilt in the callback of one of its own children *)
  Family; g.Begin;
  NEW(rebuilder); Fl.OpenBox(rebuilder, 0, 60, 10, 10, "rebuild");
  g.End; rebuilder.run := Rebuild;
  rebuilder.DoCallback;
  Check.Check((inside = 5) & rebuilder.IsOpen() & a.IsOpen(),
    "rebuilt in its own child's callback: the old children counted till it returns");
  shown := Fl.Check();
  Check.Check(~rebuilder.IsOpen() & ~a.IsOpen() & ~inner.IsOpen() & ~b.IsOpen()
    & (g.Children() = 2) & (Fl.OpenWidgets() = 3),
    "then only the new ones, the old deleted once");
  g.Delete;
  Check.Check(Fl.OpenWidgets() = 0, "and the new ones with their group");

  (* a shown window *)
  NEW(win); Fl.OpenWindow(win, 120, 80, "TestDelete");
  NEW(c); Fl.OpenBox(c, 10, 10, 100, 20, "");
  win.End; win.Show; shown := Fl.Check();
  Check.Check(win.Visible() & (Fl.OpenWidgets() = 2), "a shown window with a box");

  (* the label is FLTK's copy *)
  label := "first"; c.SetLabel(label); label := "XXXXX";
  c.GetLabel(got);
  Check.Check(got = "first", "a label is copied");
  c.SetLabel("a longer label"); got := ""; c.GetLabel(got);
  Check.Check(got = "a longer label", "SetLabel replaces it");

  win.Delete;
  Check.Check(~win.IsOpen() & ~c.IsOpen() & (Fl.OpenWidgets() = 0),
    "deleting the shown window closes it and its box");
  shown := Fl.Check();
  Check.Check(~shown, "no window is shown");
  Check.Summary
END TestDelete.
