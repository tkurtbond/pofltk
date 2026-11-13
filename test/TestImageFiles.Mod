MODULE TestImageFiles; (* FlImages: bitmaps, XBM files and ICO files *)

IMPORT Files, Fl, FlDraw, FlImages, Check;

VAR
  i, j: FlImages.Image;
  a: FlImages.AnimGIF;
  s: FlImages.Surface;
  bits: ARRAY 2 OF CHAR;
  data: ARRAY 4096 OF CHAR;
  n: INTEGER;
  red, blue, white: INTEGER;

(* Reads file name into data, returning its size. *)
PROCEDURE Read(name: ARRAY OF CHAR): INTEGER;
  VAR f: Files.File; r: Files.Rider; n: INTEGER;
BEGIN
  f := Files.Old(name); n := SHORT(Files.Length(f)); ASSERT(n <= LEN(data));
  Files.Set(r, f, 0); Files.ReadBytes(r, data, n); Files.Close(f);
  RETURN n
END Read;

(* Draws i in red on a new white surface 8 by 4, and takes the result. *)
PROCEDURE Shown(i: FlImages.Image): FlImages.Image;
  VAR s: FlImages.Surface; r: FlImages.Image;
BEGIN
  NEW(s); FlImages.OpenSurface(s, 8, 4);
  s.Begin;
  FlDraw.SetColor(Fl.White); FlDraw.RectF(0, 0, 8, 4);
  FlDraw.SetColor(Fl.Red); i.Draw(0, 0);
  s.End;
  NEW(r); s.GetImage(r); s.Close;
  RETURN r
END Shown;

(* Whether i shows as bits 03X, 03X do: its left half of 4 by 2 red, its
   right half white. *)
PROCEDURE ShowsLeftHalf(i: FlImages.Image): BOOLEAN;
  VAR r: FlImages.Image; ok: BOOLEAN;
BEGIN
  r := Shown(i);
  ok := (r.Pixel(0, 0) = red) & (r.Pixel(1, 1) = red) & (r.Pixel(2, 0) = white)
    & (r.Pixel(3, 1) = white) & (r.Pixel(4, 0) = white);
  r.Close;
  RETURN ok
END ShowsLeftHalf;

(* Whether i, 4 by 2 or twice that, has a red left half and a blue right. *)
PROCEDURE RedLeftBlueRight(i: FlImages.Image): BOOLEAN;
  VAR x: INTEGER;
BEGIN
  x := i.DataW() - 1;
  RETURN (i.Kind() = FlImages.RGB) & (i.Pixel(0, 0) = red) & (i.Pixel(x, 0) = blue)
    & (i.Pixel(0, i.DataH() - 1) = red) & (i.Pixel(x, i.DataH() - 1) = blue)
END RedLeftBlueRight;

BEGIN
  red := Fl.RGB(255, 0, 0); blue := Fl.RGB(0, 0, 255); white := Fl.RGB(255, 255, 255);

  (* a bitmap from bits *)
  bits[0] := 03X; bits[1] := 03X;
  NEW(i); FlImages.OpenBitmap(i, bits, 4, 2);
  Check.Check((i.Kind() = FlImages.Bitmap) & (i.W() = 4) & (i.H() = 2) & (i.Depth() = 0),
    "OpenBitmap makes a bitmap of that size");
  bits[0] := 0X; bits[1] := 0X;
  Check.Check(ShowsLeftHalf(i), "drawn in the color set, its unset bits not at all, from a copy of the bits");
  Check.Check(~i.SavePNG("/nonexistent"), "it has no pixels to save");
  i.Desaturate; i.ColorAverage(Fl.Blue, 0.5);
  Check.Check(ShowsLeftHalf(i), "and none to change");
  NEW(j); i.Copy(j, 8, 4);
  Check.Check((j.Kind() = FlImages.Bitmap) & (j.W() = 8), "a copy is a bitmap");
  j.Close; i.Close;

  (* XBM *)
  NEW(i);
  Check.Check(FlImages.Load(i, "images/rb.xbm"), "an XBM file loads");
  Check.Check((i.Kind() = FlImages.Bitmap) & (i.W() = 4) & (i.H() = 2) & ShowsLeftHalf(i),
    "as a bitmap, of its bits");
  i.Close;
  n := Read("images/rb.xbm");
  NEW(i);
  Check.Check(FlImages.LoadData(i, data, n) & ShowsLeftHalf(i), "and from memory");
  i.Close;
  NEW(i);
  Check.Check(~FlImages.Load(i, "images/not-xbm.h") & ~i.IsOpen(),
    "a file that merely starts #define doesn't load");
  Check.Check(~FlImages.Load(i, "images/short.xbm"), "nor one with too few bits");
  Check.Check(~FlImages.Load(i, "images/huge.xbm"), "nor one with an absurd size");
  n := Read("images/not-xbm.h");
  Check.Check(~FlImages.LoadData(i, data, n) & ~i.IsOpen(), "nor the first from memory");

  (* ICO *)
  Check.Check(FlImages.ICOCount("images/rb.ico") = 2, "ICOCount of an ICO with two sizes");
  Check.Check(FlImages.ICOCount("images/rb.xbm") = 0, "of something else, 0");
  Check.Check(FlImages.ICOCount("images/nothing.ico") = 0, "of no file, 0");
  Check.Check(FlImages.LoadICO(i, "images/rb.ico", 0) & (i.W() = 4) & (i.H() = 2) & RedLeftBlueRight(i),
    "LoadICO of its first");
  i.Close; NEW(i);
  Check.Check(FlImages.LoadICO(i, "images/rb.ico", 1) & (i.W() = 8) & (i.H() = 4) & RedLeftBlueRight(i),
    "of its second");
  i.Close; NEW(i);
  Check.Check(FlImages.LoadICO(i, "images/rb.ico", -1) & (i.W() = 8), "-1, the largest");
  i.Close; NEW(i);
  Check.Check(~FlImages.LoadICO(i, "images/rb.ico", 2) & ~FlImages.LoadICO(i, "images/rb.ico", -2),
    "no others");
  Check.Check(~FlImages.LoadICO(i, "images/rb.xbm", 0), "nor of something else");
  Check.Check(FlImages.Load(i, "images/rb.ico") & (i.W() = 8), "Load takes the largest");
  i.Close; NEW(i);
  n := Read("images/rb.ico");
  Check.Check(FlImages.ICODataCount(data, n) = 2, "ICODataCount");
  Check.Check(FlImages.LoadICOData(i, data, n, 0) & (i.W() = 4) & RedLeftBlueRight(i), "LoadICOData");
  i.Close; NEW(i);
  Check.Check(~FlImages.LoadICOData(i, data, n, 2), "with no such image");
  Check.Check(FlImages.LoadData(i, data, n) & (i.W() = 8) & RedLeftBlueRight(i), "LoadData, the largest");
  i.Close; NEW(i);

  (* headers that would have FLTK write past what it has *)
  Check.Check(~FlImages.Load(i, "images/colors.bmp") & ~i.IsOpen(), "a BMP with too many colors doesn't load");
  n := Read("images/colors.bmp");
  Check.Check(~FlImages.LoadData(i, data, n), "nor from memory");
  Check.Check(~FlImages.Load(i, "images/size.bmp"), "nor an absurd size");
  Check.Check(~FlImages.Load(i, "images/depth.bmp"), "nor a depth that isn't one");
  Check.Check(~FlImages.Load(i, "images/colors.ico") & ~FlImages.LoadICO(i, "images/colors.ico", 0),
    "nor such an ICO");
  n := Read("images/colors.ico");
  Check.Check(~FlImages.LoadData(i, data, n) & ~FlImages.LoadICOData(i, data, n, 0), "from memory either");

  Check.Check(~FlImages.Load(i, "images/loop.gif"), "nor a GIF whose codes loop");
  n := Read("images/loop.gif");
  Check.Check(~FlImages.LoadData(i, data, n), "from memory either");
  Check.Check(~FlImages.Load(i, "images/zero.gif"), "nor a GIF with an empty image");
  Check.Check(~FlImages.Load(i, "images/code.gif"), "nor one with an impossible code size");
  NEW(a);
  Check.Check(~FlImages.OpenAnimGIF(a, "images/loop.gif", NIL, {}), "nor such an animation");
  Check.Check(~FlImages.OpenAnimGIF(a, "images/beyond.gif", NIL, {}), "nor a frame off its screen");
  Check.Check(FlImages.Load(i, "images/beyond.gif"), "though that loads as a still image");
  i.Close; NEW(i);

  (* sizes whose bytes wrap an int: 65536 by 65536 is 0 *)
  Check.Check(~FlImages.Load(i, "images/wrap.png") & ~i.IsOpen(), "nor a PNG whose size wraps an int");
  n := Read("images/wrap.png");
  Check.Check(~FlImages.LoadData(i, data, n), "from memory either");
  Check.Check(~FlImages.Load(i, "images/wrap.jpg"), "nor such a JPEG");
  n := Read("images/wrap.jpg");
  Check.Check(~FlImages.LoadData(i, data, n), "from memory either");
  Check.Check(~FlImages.Load(i, "images/wrap.pgm"), "nor such a PNM");
  Check.Check(~FlImages.Load(i, "images/wrap.ico"), "nor such a PNG in an ICO");
  n := Read("images/wrap.ico");
  Check.Check(~FlImages.LoadData(i, data, n), "from memory either");

  (* an ICO holding a PNG, which FLTK reads from files alone *)
  Check.Check(FlImages.Load(i, "images/rbpng.ico") & (i.W() = 4) & RedLeftBlueRight(i),
    "an ICO holding a PNG loads");
  i.Close; NEW(i);
  n := Read("images/rbpng.ico");
  Check.Check(FlImages.LoadData(i, data, n) & (i.W() = 4) & RedLeftBlueRight(i), "and from memory");
  i.Close; NEW(i);
  Check.Check(FlImages.LoadICOData(i, data, n, 0) & (i.W() = 4), "by its id");
  i.Close; NEW(i);
  Check.Check(~FlImages.LoadICOData(i, data, n, 1), "and no other id");

  Check.Check(FlImages.openImages = 0, "every image closed");
  Check.Summary
END TestImageFiles.
