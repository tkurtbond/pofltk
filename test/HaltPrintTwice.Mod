MODULE HaltPrintTwice; (* A surface opened twice halts with Fl.OpenedTwice, 71 *)
IMPORT FlPrint;
VAR f: FlPrint.EPSFile; ok: BOOLEAN;
BEGIN
  IF ~FlPrint.Available() THEN HALT(99) END;
  NEW(f);
  ok := FlPrint.OpenEPS(f, "../build/HaltPrint.eps", 20, 20, 0);
  ok := FlPrint.OpenEPS(f, "../build/HaltPrint.eps", 20, 20, 0)
END HaltPrintTwice.
