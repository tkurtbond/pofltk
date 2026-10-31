MODULE HaltChooserFilter; (* a filter a file chooser hasn't (Fl.IndexOutOfRange) *)

IMPORT FlDialogs;

VAR c: FlDialogs.FileChooser;

BEGIN
  NEW(c); FlDialogs.OpenFileChooser(c, ".", "*", FlDialogs.ChooserSingle, "t");
  c.SetFilterValue(c.FilterCount())
END HaltChooserFilter.
