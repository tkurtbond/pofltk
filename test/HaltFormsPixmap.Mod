MODULE HaltFormsPixmap; (* A FormsPixmap given RGB pixels halts with Fl.Unsupported, 78 *)
IMPORT FlForms, FlImages;
VAR p: FlForms.FormsPixmap; i: FlImages.Image; ok: BOOLEAN;
BEGIN
  NEW(p); FlForms.OpenFormsPixmap(p, 0, 0, 10, 10, "");
  NEW(i); ok := FlImages.Load(i, "images/rb.ppm"); ASSERT(ok);
  p.SetPixmap(i)
END HaltFormsPixmap.
