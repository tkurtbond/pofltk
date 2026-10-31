MODULE HaltPrintNesting; (* Ending a surface that isn't the one last begun halts with Fl.OutOfOrder, 77 *)
IMPORT FlPrint;
VAR f, g: FlPrint.EPSFile;
BEGIN
  IF ~FlPrint.Available() THEN HALT(99) END;
  NEW(f); NEW(g);
  IF FlPrint.OpenEPS(f, "../build/HaltPrint.eps", 20, 20, 0) & FlPrint.OpenEPS(g, "../build/HaltPrint2.eps", 20, 20, 0) THEN
    f.Begin; g.Begin; f.End
  END
END HaltPrintNesting.
