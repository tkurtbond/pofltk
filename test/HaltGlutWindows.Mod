MODULE HaltGlutWindows; (* A 32nd window halts with Fl.Unsupported, 78 *)
IMPORT FlGlut;
VAR i, n: INTEGER;
BEGIN
  FlGlut.InitWindowSize(10, 10);
  FOR i := 1 TO 32 DO n := FlGlut.CreateWindow("") END
END HaltGlutWindows.
