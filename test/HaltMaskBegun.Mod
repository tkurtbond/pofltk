MODULE HaltMaskBegun; (* A mask for a surface begun halts with Fl.OutOfOrder, 77 *)
IMPORT FlImages;
VAR s: FlImages.Surface; m: FlImages.Image;
BEGIN
  NEW(s); FlImages.OpenSurface(s, 2, 2);
  NEW(m); s.GetImage(m);
  s.Begin;
  s.Mask(m)
END HaltMaskBegun.
