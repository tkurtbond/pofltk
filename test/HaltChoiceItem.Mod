MODULE HaltChoiceItem; (* An input choice's index that names no item: halts with Fl.IndexOutOfRange *)

IMPORT Fl, FlInputs;

VAR
  win: Fl.Window;
  c: FlInputs.InputChoice;

BEGIN
  NEW(win); Fl.OpenWindow(win, 100, 100, "HaltChoiceItem");
  NEW(c); FlInputs.OpenInputChoice(c, 10, 10, 80, 25, "");
  win.End;
  c.Add("a");
  c.SetValueIndex(1)
END HaltChoiceItem.
