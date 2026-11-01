MODULE HaltGlutStrokeText; (* stroke text with no context halts with Fl.OutOfOrder, 77 *)
IMPORT FlGlut;
BEGIN
  FlGlut.StrokeString(FlGlut.StrokeRoman, "A")
END HaltGlutStrokeText.
