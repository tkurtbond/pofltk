MODULE HaltUtf8Offset; (* An offset outside a string halts with Fl.IndexOutOfRange, 74 *)
IMPORT FlUtf8;
VAR n: INTEGER;
BEGIN
  n := FlUtf8.Forward("abc", 4)
END HaltUtf8Offset.
