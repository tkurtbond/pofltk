MODULE HaltSharedCopy; (* a copy of a Shared must be one (Fl.Unsupported) *)

IMPORT Fl, FlImages, Check;

VAR
  s: FlImages.Shared;
  i: FlImages.Image;

BEGIN
  NEW(s); Check.Check(FlImages.GetShared(s, "images/rb.bmp", 0, 0), "loads");
  NEW(i); s.Copy(i, 2, 2)
END HaltSharedCopy.
