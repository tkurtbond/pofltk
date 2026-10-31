MODULE HaltPrintUnderImage; (* Ending a print surface inside a later image surface halts with Fl.OutOfOrder, 77 *)
IMPORT FlImages, FlPrint;
VAR s: FlImages.Surface; f: FlPrint.EPSFile;
BEGIN
  IF ~FlPrint.Available() THEN HALT(99) END;
  NEW(s); FlImages.OpenSurface(s, 2, 2); NEW(f);
  IF FlPrint.OpenEPS(f, "../build/HaltPrint.eps", 20, 20, 0) THEN f.Begin; s.Begin; f.End END
END HaltPrintUnderImage.
