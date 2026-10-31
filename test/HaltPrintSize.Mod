MODULE HaltPrintSize; (* A drawing of no size halts with Fl.IndexOutOfRange, 74 *)
IMPORT FlPrint;
VAR f: FlPrint.EPSFile;
BEGIN
  IF ~FlPrint.Available() THEN HALT(99) END;
  NEW(f);
  IF FlPrint.OpenEPS(f, "../build/HaltPrint.eps", 0, 20, 0) THEN END
END HaltPrintSize.
