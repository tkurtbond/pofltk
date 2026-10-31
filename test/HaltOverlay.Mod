MODULE HaltOverlay; (* An overlay with no window current halts with Fl.OutOfOrder, 77 *)
IMPORT FlDraw;
BEGIN
  FlDraw.OverlayRect(0, 0, 10, 10)
END HaltOverlay.
