MODULE HaltOffscreenCopy; (* Copying an offscreen onto itself halts with Fl.OutOfOrder, 77 *)
IMPORT FlDraw;
VAR o: FlDraw.Offscreen;
BEGIN
  NEW(o); FlDraw.OpenOffscreen(o, 10, 10); o.Begin; o.Copy(0, 0, 5, 5, 0, 0)
END HaltOffscreenCopy.
