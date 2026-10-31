MODULE HaltPrintPage; (* EndJob with a page under way halts with Fl.OutOfOrder, 77 *)
IMPORT FlPrint;
VAR f: FlPrint.PostScriptFile; ok: BOOLEAN;
BEGIN
  IF ~FlPrint.Available() THEN HALT(99) END;
  NEW(f);
  IF FlPrint.OpenPostScript(f, "../build/HaltPrint.ps", FlPrint.A4, FlPrint.Portrait) THEN f.BeginPage; ok := f.EndJob() END
END HaltPrintPage.
