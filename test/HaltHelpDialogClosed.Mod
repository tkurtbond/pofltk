MODULE HaltHelpDialogClosed; (* a closed help dialog used (Fl.ClosedResource) *)

IMPORT FlHelp;

VAR d: FlHelp.HelpDialog;

BEGIN
  NEW(d); FlHelp.OpenHelpDialog(d);
  d.Close;
  d.Show
END HaltHelpDialogClosed.
