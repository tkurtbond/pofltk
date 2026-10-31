MODULE HaltShareBitmap; (* ShareImage takes an RGB image alone (Fl.Unsupported) *)

IMPORT Fl, FlImages;

VAR
  s: FlImages.Shared;
  i: FlImages.Image;
  bits: ARRAY 2 OF CHAR;

BEGIN
  NEW(i); FlImages.OpenBitmap(i, bits, 4, 2);
  NEW(s); FlImages.ShareImage(s, i)
END HaltShareBitmap.
