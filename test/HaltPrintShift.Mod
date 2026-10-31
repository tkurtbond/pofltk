MODULE HaltPrintShift; (* A page ended with a Translate not undone halts with Fl.OutOfOrder, 77 *)
IMPORT FlPrint;
VAR f: FlPrint.EPSFile;
BEGIN
  IF ~FlPrint.Available() THEN HALT(99) END;
  NEW(f);
  IF FlPrint.OpenEPS(f, "../build/HaltPrint.eps", 20, 20, 0) THEN f.Begin; f.Translate(1, 1); f.End END
END HaltPrintShift.
