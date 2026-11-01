MODULE HaltGlutStrokeFont; (* a bitmap font isn't a stroke font: Fl.IndexOutOfRange, 74 *)
IMPORT FlGlut;
  VAR i: INTEGER;
BEGIN
  i := FlGlut.StrokeWidth(FlGlut.Bitmap8By13, "A")
END HaltGlutStrokeFont.
