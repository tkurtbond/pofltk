MODULE HaltCursorTiled; (* A tiled image as a cursor halts with Fl.Unsupported, 78 *)
IMPORT Fl, FlImages;
VAR win: Fl.Window; tile, tiled: FlImages.Image; bits: ARRAY 3 OF CHAR;
BEGIN
  NEW(win); Fl.OpenWindow(win, 10, 10, ""); win.End;
  NEW(tile); FlImages.OpenRGB(tile, bits, 1, 1, 3, 0);
  NEW(tiled); FlImages.OpenTiled(tiled, tile, 10, 10);
  FlImages.SetCursor(win, tiled, 0, 0)
END HaltCursorTiled.
