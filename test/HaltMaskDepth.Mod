MODULE HaltMaskDepth; (* A mask not of 3 bytes a pixel halts with Fl.Unsupported, 78 *)
IMPORT FlImages;
VAR s: FlImages.Surface; m: FlImages.Image; bits: ARRAY 1 OF CHAR;
BEGIN
  NEW(s); FlImages.OpenSurface(s, 2, 2);
  bits[0] := 0FFX;
  NEW(m); FlImages.OpenRGB(m, bits, 1, 1, 1, 0);
  s.Mask(m)
END HaltMaskDepth.
