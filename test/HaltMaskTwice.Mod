MODULE HaltMaskTwice; (* A second mask with no GetImage between halts with Fl.OutOfOrder, 77 *)
IMPORT FlImages;
VAR s: FlImages.Surface; m: FlImages.Image;
BEGIN
  NEW(s); FlImages.OpenSurface(s, 2, 2);
  NEW(m); s.GetImage(m);
  s.Mask(m);
  s.Mask(m)
END HaltMaskTwice.
