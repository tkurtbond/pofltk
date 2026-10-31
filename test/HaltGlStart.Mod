MODULE HaltGlStart; (* Start with no current window halts with Fl.OutOfOrder, 77 *)
IMPORT FlGl;
BEGIN
  IF ~FlGl.CanStart() THEN HALT(99) END;
  FlGl.Start
END HaltGlStart.
