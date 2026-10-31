MODULE HaltPrintScale; (* A Scale of 0 halts with Fl.Unsupported, 78: FLTK would close the file (doc/fltk-issues.md, 101) *)
IMPORT FlPrint;
VAR f: FlPrint.PostScriptFile;
BEGIN
  IF ~FlPrint.Available() THEN HALT(99) END;
  NEW(f);
  IF FlPrint.OpenPostScript(f, "../build/HaltPrint.ps", FlPrint.A4, FlPrint.Portrait) THEN f.BeginPage; f.Scale(1.0D0, 0.0D0) END
END HaltPrintScale.
