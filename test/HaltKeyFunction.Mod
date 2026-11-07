MODULE HaltKeyFunction; (* A key bound to a number that names none of FLTK's functions: halts with Fl.IndexOutOfRange *)

IMPORT Fl, FlText;

VAR
  win: Fl.Window;
  e: FlText.TextEditor;

BEGIN
  NEW(win); Fl.OpenWindow(win, 100, 100, "HaltKeyFunction");
  NEW(e); FlText.OpenTextEditor(e, 0, 0, 100, 100, "");
  win.End;
  e.BindBuiltin(ORD("a"), Fl.Ctrl, FlText.KfRedo + 1)
END HaltKeyFunction.
