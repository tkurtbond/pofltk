MODULE HaltFormsBitmap; (* A FormsBitmap given a pixmap halts with Fl.Unsupported, 78 *)
IMPORT FlForms, FlImages;
VAR b: FlForms.FormsBitmap; i: FlImages.Image; ok: BOOLEAN;
BEGIN
  NEW(b); FlForms.OpenFormsBitmap(b, 0, 0, 10, 10, "");
  NEW(i); ok := FlImages.Load(i, "images/rb.xpm"); ASSERT(ok);
  b.SetBitmap(i)
END HaltFormsBitmap.
