MODULE HaltPrintOrder; (* A page ended that wasn't begun halts with Fl.OutOfOrder, 77 *)
IMPORT FlPrint;
VAR f: FlPrint.PostScriptFile;
BEGIN
  IF ~FlPrint.Available() THEN HALT(99) END;
  NEW(f);
  IF FlPrint.OpenPostScript(f, "../build/HaltPrint.ps", FlPrint.A4, FlPrint.Portrait) THEN f.EndPage END
END HaltPrintOrder.
