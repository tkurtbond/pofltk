MODULE HaltFilterTab; (* a filter's name holding a tab, which would split it (Fl.Unsupported) *)

IMPORT FlDialogs;

VAR c: FlDialogs.NativeFileChooser; name: ARRAY 8 OF CHAR;

BEGIN
  NEW(c); FlDialogs.OpenNativeFileChooser(c, FlDialogs.BrowseFile);
  name := "a b"; name[1] := 09X;
  c.AddFilter(name, "*.txt")
END HaltFilterTab.
