MODULE HaltMakeCurrent; (* A window not shown can't be current: Fl.OutOfOrder, 77 *)
IMPORT Fl;
VAR w: Fl.Window;
BEGIN
  NEW(w); Fl.OpenWindow(w, 10, 10, ""); w.End; w.MakeCurrent
END HaltMakeCurrent.
