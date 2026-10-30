MODULE FileInputs; (* A file input, which shows a path's directories as buttons *)

(* Click a directory above the text to cut the path back to it. *)

IMPORT Fl, FlInputs;

VAR
  window: Fl.Window;
  path: FlInputs.FileInput;
  shown: Fl.Box;

PROCEDURE Changed(w: Fl.Widget);
  VAR s: ARRAY 256 OF CHAR;
BEGIN path.Value(s); shown.SetLabel(s)
END Changed;

BEGIN
  NEW(window); Fl.OpenWindow(window, 400, 120, "FileInputs");
  NEW(path); FlInputs.OpenFileInput(path, 50, 20, 330, 40, "path:");
  path.SetValue("/usr/share/doc/fltk-devel/html");
  path.SetWhen(Fl.WhenChanged);
  path.action := Changed;
  NEW(shown); Fl.OpenBox(shown, 50, 70, 330, 30, "");
  window.End;
  Changed(path);
  window.Show;
  Fl.Run
END FileInputs.
