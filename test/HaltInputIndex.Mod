MODULE HaltInputIndex; (* Input.Index past the text halts with Fl.IndexOutOfRange, 74 *)
IMPORT Fl, FlInputs;
VAR win: Fl.Window; in: FlInputs.Input; c: INTEGER;
BEGIN
  NEW(win); Fl.OpenWindow(win, 100, 100, "HaltInputIndex");
  NEW(in); FlInputs.OpenInput(in, 10, 10, 80, 25, "");
  win.End;
  in.SetValue("ab");
  c := in.Index(3)
END HaltInputIndex.
