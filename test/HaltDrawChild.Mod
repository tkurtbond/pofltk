MODULE HaltDrawChild; (* Drawing a widget that isn't the group's child halts with Fl.NotAChild, 76 *)
IMPORT Fl;
VAR g: Fl.Group; b: Fl.Box;
BEGIN
  NEW(b); Fl.OpenBox(b, 0, 0, 10, 10, "");
  NEW(g); Fl.OpenGroup(g, 0, 0, 100, 100, "");
  g.End;
  g.DrawChild(b)
END HaltDrawChild.
