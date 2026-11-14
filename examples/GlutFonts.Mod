MODULE GlutFonts; (* GLUT's bitmap and stroke fonts, each underlined by its measure *)

(* Each bitmap font draws a line at the raster position, a pixel size of its
   own, and each stroke font draws one at the origin, 100 units to a capital,
   scaled here to a quarter. A yellow line under each is as long as
   BitmapLength or StrokeLength says the text is, and the rows are
   BitmapHeight and StrokeHeight apart. "q" quits. *)

IMPORT Fl, FlGl, FlGlut;

CONST
  margin = 20;
  gap = 8;          (* between rows, in pixels *)
  scale = 0.25;     (* of the stroke fonts *)

VAR
  form: Fl.Window;
  view: FlGlut.Window;
  width, height: INTEGER;

PROCEDURE Underline(x, y, length: REAL);
BEGIN
  FlGl.Color3f(1.0, 1.0, 0.0);
  FlGl.Begin(FlGl.Lines);
  FlGl.Vertex3f(x, y - 2.0, 0.0); FlGl.Vertex3f(x + length, y - 2.0, 0.0);
  FlGl.End;
  FlGl.Color3f(1.0, 1.0, 1.0)
END Underline;

(* A row of a bitmap font, its top at y; gives the next row's top. *)
PROCEDURE BitmapRow(font: INTEGER; s-: ARRAY OF CHAR; y: INTEGER): INTEGER;
  VAR base: INTEGER;
BEGIN
  base := y - FlGlut.BitmapHeight(font);
  FlGl.DrawTextAt("", margin, base);  (* sets the raster position *)
  FlGlut.BitmapString(font, s);
  Underline(margin, base, FlGlut.BitmapLength(font, s));
  RETURN base - gap
END BitmapRow;

(* A row of a stroke font, likewise. *)
PROCEDURE StrokeRow(font: INTEGER; s-: ARRAY OF CHAR; y: INTEGER): INTEGER;
  VAR base: REAL;
BEGIN
  base := y - FlGlut.StrokeHeight(font) * scale;
  FlGl.PushMatrix;
  FlGl.Translatef(margin, base, 0.0);
  FlGl.Scalef(scale, scale, 1.0);
  FlGlut.StrokeString(font, s);
  FlGl.PopMatrix;
  Underline(margin, base, FlGlut.StrokeLength(font, s) * scale);
  RETURN SHORT(ENTIER(base)) - gap
END StrokeRow;

PROCEDURE Display;
  VAR y: INTEGER;
BEGIN
  FlGl.ClearColor(0.0, 0.0, 0.3, 1.0);
  FlGl.Clear(FlGl.ColorBufferBit);
  FlGl.Color3f(1.0, 1.0, 1.0);
  y := height - margin;
  y := BitmapRow(FlGlut.Bitmap9By15, "Bitmap9By15: GLUT's fonts", y);
  y := BitmapRow(FlGlut.Bitmap8By13, "Bitmap8By13: GLUT's fonts", y);
  y := BitmapRow(FlGlut.BitmapTimesRoman10, "BitmapTimesRoman10: GLUT's fonts", y);
  y := BitmapRow(FlGlut.BitmapTimesRoman24, "BitmapTimesRoman24: GLUT's fonts", y);
  y := BitmapRow(FlGlut.BitmapHelvetica10, "BitmapHelvetica10: GLUT's fonts", y);
  y := BitmapRow(FlGlut.BitmapHelvetica12, "BitmapHelvetica12: GLUT's fonts", y);
  y := BitmapRow(FlGlut.BitmapHelvetica18, "BitmapHelvetica18: GLUT's fonts", y);
  y := StrokeRow(FlGlut.StrokeRoman, "Roman: GLUT", y);
  y := StrokeRow(FlGlut.StrokeMonoRoman, "MonoRoman: GLUT", y);
  FlGlut.SwapBuffers
END Display;

(* One GL unit to a pixel, with y up. *)
PROCEDURE Reshape(w, h: INTEGER);
BEGIN
  width := w; height := h;
  FlGl.Viewport(0, 0, w, h);
  FlGl.LoadIdentity;
  FlGl.Ortho(0.0D0, w, 0.0D0, h, -1.0D0, 1.0D0)
END Reshape;

(* Hiding the FLTK window around the GLUT one ends MainLoop, as in
   GlutCube. *)
PROCEDURE Keyboard(key: CHAR; x, y: INTEGER);
BEGIN
  IF key = "q" THEN form.Hide END
END Keyboard;

BEGIN
  FlGlut.Init;
  NEW(form); Fl.OpenWindow(form, 480, 340, "GLUT's fonts");
  FlGlut.InitDisplayMode(FlGlut.Double + FlGlut.Rgb);
  NEW(view); FlGlut.OpenWindowAt(view, 0, 0, 480, 340, "");
  view.MakeCurrent;
  FlGlut.DisplayFunc(Display);
  FlGlut.ReshapeFunc(Reshape);
  FlGlut.KeyboardFunc(Keyboard);
  form.End;
  form.SetResizable(view);
  form.ShowArgs;
  FlGlut.MainLoop
END GlutFonts.
