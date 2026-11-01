MODULE HaltGlutBitmapFont; (* a stroke font isn't a bitmap font: Fl.IndexOutOfRange, 74 *)
IMPORT FlGlut;
BEGIN
  FlGlut.BitmapString(FlGlut.StrokeRoman, "A")
END HaltGlutBitmapFont.
