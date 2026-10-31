MODULE HaltBitmapBits; (* a bitmap's bits too few halts with Fl.IndexOutOfRange *)

IMPORT Fl, FlImages;

VAR
  i: FlImages.Image;
  bits: ARRAY 3 OF CHAR;

BEGIN
  NEW(i); FlImages.OpenBitmap(i, bits, 9, 2)
END HaltBitmapBits.
