MODULE HaltGlutBitmapText; (* a bitmap font with no context halts with Fl.OutOfOrder, 77 *)
IMPORT FlGlut;
  VAR i: INTEGER;
BEGIN
  i := FlGlut.BitmapHeight(FlGlut.BitmapHelvetica12)
END HaltGlutBitmapText.
