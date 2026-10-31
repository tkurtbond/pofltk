MODULE HaltHandleEvent; (* an event for a window not shown *)

IMPORT Fl;

VAR w: Fl.Window; ok: BOOLEAN;

BEGIN
  NEW(w); Fl.OpenWindow(w, 20, 20, ""); w.End;
  ok := Fl.HandleEvent(Fl.EvMove, w)
END HaltHandleEvent.
