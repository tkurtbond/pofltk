MODULE HaltGlutShape; (* a shape of no slices halts with Fl.IndexOutOfRange, 74 *)
IMPORT FlGlut;
BEGIN
  FlGlut.Sphere(TRUE, 1.0D0, 0, 8)
END HaltGlutShape.
