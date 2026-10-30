MODULE TestTracker; (* Fl.Tracker: whether a widget still exists *)

IMPORT Fl, FlButtons, Check;

TYPE
  (* deletes itself in its callback, and asks a tracker on either side *)
  Selfish = POINTER TO RECORD (FlButtons.ButtonDesc)
    during, after: BOOLEAN
  END;

VAR
  win: Fl.Window;
  b: Fl.Box;
  s: Selfish;
  t: Fl.Tracker;
  child: Fl.Box;
  g: Fl.Group;
  ignored: BOOLEAN;

PROCEDURE (w: Selfish) Callback*;
BEGIN
  w.Delete;
  w.during := t.Exists();
  ignored := Fl.Check(); (* handles events, so deletes w *)
  w.after := t.Exists()
END Callback;

BEGIN
  NEW(t);
  Check.Check(~t.Exists() & t.Deleted() & (t.Widget() = NIL), "a tracker tracking nothing");

  NEW(win); Fl.OpenWindow(win, 200, 200, "TestTracker");
  NEW(b); Fl.OpenBox(b, 0, 0, 10, 10, "");
  NEW(g); Fl.OpenGroup(g, 0, 20, 100, 100, "");
  NEW(child); Fl.OpenBox(child, 0, 20, 10, 10, "");
  g.End;
  NEW(s); FlButtons.OpenButton(s, 0, 150, 50, 25, "");
  win.End;

  t.Track(b);
  Check.Check(t.Exists() & ~t.Deleted() & (t.Widget() = b), "an open widget exists");
  b.Delete;
  Check.Check(~t.Exists() & t.Deleted() & (t.Widget() = NIL), "and doesn't once deleted");

  t.Track(child);
  g.Delete;
  Check.Check(t.Deleted(), "a child goes with its group");

  t.Track(win);
  Check.Check(t.Exists(), "a tracker can move to another widget");

  (* The case a tracker is for: a callback that deletes its own widget.
     FLTK deletes it after the callback, so it exists until then. *)
  t.Track(s);
  s.DoCallback;
  Check.Check(s.during, "a widget deleted in its own callback exists until events are handled");
  Check.Check(~s.after & t.Deleted(), "then it is gone, while its callback runs");

  win.Delete;
  Check.Check(Fl.OpenWidgets() = 0, "every widget deleted");
  Check.Summary
END TestTracker.
