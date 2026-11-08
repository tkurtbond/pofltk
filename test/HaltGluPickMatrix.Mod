MODULE HaltGluPickMatrix; (* PickMatrix of a viewport short of 4 halts with Fl.IndexOutOfRange, 74 *)
IMPORT FlGlu;
  VAR vp: ARRAY 3 OF INTEGER;
BEGIN
  vp[0] := 0; vp[1] := 0; vp[2] := 10;
  FlGlu.PickMatrix(1.0D0, 1.0D0, 1.0D0, 1.0D0, vp)
END HaltGluPickMatrix.
