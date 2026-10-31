MODULE HaltPrintText; (* A text FLTK doesn't have halts with Fl.IndexOutOfRange, 74 *)
IMPORT FlPrint;
BEGIN
  IF ~FlPrint.Available() THEN HALT(99) END;
  FlPrint.SetPrinterText(23, "x")
END HaltPrintText.
