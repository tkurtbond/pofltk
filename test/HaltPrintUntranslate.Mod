MODULE HaltPrintUntranslate; (* An Untranslate with no Translate halts with Fl.OutOfOrder, 77: FLTK would close the file (doc/fltk-issues.md, 101) *)
IMPORT FlPrint;
VAR f: FlPrint.PostScriptFile;
BEGIN
  IF ~FlPrint.Available() THEN HALT(99) END;
  NEW(f);
  IF FlPrint.OpenPostScript(f, "../build/HaltPrint.ps", FlPrint.A4, FlPrint.Portrait) THEN f.BeginPage; f.Untranslate END
END HaltPrintUntranslate.
