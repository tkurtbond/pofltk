MODULE HaltPrintFormat; (* A page format FLTK has no size for halts with Fl.Unsupported, 78 *)
IMPORT FlPrint;
VAR f: FlPrint.PostScriptFile;
BEGIN
  IF ~FlPrint.Available() THEN HALT(99) END;
  NEW(f);
  IF FlPrint.OpenPostScript(f, "../build/HaltPrint.ps", FlPrint.PageFormats, FlPrint.Portrait) THEN END
END HaltPrintFormat.
