MODULE HaltDrawImage; (* Pixels beyond the data halt with Fl.IndexOutOfRange, 74 *)
IMPORT FlDraw;
VAR data: ARRAY 11 OF CHAR;
BEGIN
  FlDraw.DrawImage(data, 0, 0, 0, 2, 2, 3, 0)
END HaltDrawImage.
