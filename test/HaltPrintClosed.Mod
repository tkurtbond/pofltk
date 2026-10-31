MODULE HaltPrintClosed; (* A surface used after Close halts with Fl.ClosedResource, 73 *)
IMPORT FlPrint;
VAR f: FlPrint.PostScriptFile;
BEGIN
  IF ~FlPrint.Available() THEN HALT(99) END;
  NEW(f);
  IF FlPrint.OpenPostScript(f, "../build/HaltPrint.ps", FlPrint.A4, FlPrint.Portrait) THEN f.Close; f.BeginPage END
END HaltPrintClosed.
