MODULE HaltChooserClosed; (* a closed file chooser used (Fl.ClosedResource) *)

IMPORT FlDialogs;

VAR c: FlDialogs.FileChooser;

BEGIN
  NEW(c); FlDialogs.OpenFileChooser(c, ".", "*", FlDialogs.ChooserSingle, "t");
  c.Close;
  c.Show
END HaltChooserClosed.
