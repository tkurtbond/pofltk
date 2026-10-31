MODULE HaltFrame; (* Letters that are not in fours halt with Fl.IndexOutOfRange, 74 *)
IMPORT FlDraw;
BEGIN
  FlDraw.Frame("AAA", 0, 0, 10, 10)
END HaltFrame.
