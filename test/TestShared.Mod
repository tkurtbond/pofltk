MODULE TestShared; (* FlImages: the pool of shared images *)

IMPORT GC:=GarbageCollectedHeap, Files, Fl, FlBrowsers, FlDraw, FlImages, FlMenus, Check, Probe;

CONST
  Name = "images/rb.bmp";
  Reloaded = "../build/TestShared.png";  (* in the build directory *)

VAR
  win: Fl.Window;
  b1, b2: Fl.Box;
  tree: FlBrowsers.Tree;
  choice: FlMenus.Choice;
  a, b, c: FlImages.Shared;
  i, tiled: FlImages.Image;
  bits: ARRAY 12 OF CHAR;
  name: ARRAY 64 OF CHAR;
  n, item, res, red, blue: INTEGER;
  ok: BOOLEAN;

(* A 1 by 1 RGB image of red r and blue 255 - r, in file Reloaded. *)
PROCEDURE WriteFile(r: INTEGER);
  VAR i: FlImages.Image; ok: BOOLEAN;
BEGIN
  bits[0] := CHR(r); bits[1] := 0X; bits[2] := CHR(255 - r);
  NEW(i); FlImages.OpenRGB(i, bits, 1, 1, 3, 0);
  ok := i.SavePNG(Reloaded); ASSERT(ok);
  i.Close
END WriteFile;

(* Whether w's first pixel of image, at x, y, shows the left of rb.bmp. *)
PROCEDURE ShowsRed(w: Fl.Widget; x, y: INTEGER): BOOLEAN;
  VAR ok: BOOLEAN;
BEGIN
  ok := Probe.Capture(w) & (Probe.Pixel(x, y) = red);
  Probe.Release;
  RETURN ok
END ShowsRed;

(* Two boxes show an image a holds no longer; they are deleted, first 2
   then 1 or the other way. *)
PROCEDURE TwoShowing(firstFirst: BOOLEAN);
  VAR w: Fl.Window; x, y: Fl.Box; s: FlImages.Shared;
BEGIN
  NEW(w); Fl.OpenWindow(w, 60, 30, "two");
  NEW(x); Fl.OpenBox(x, 0, 0, 30, 30, "");
  NEW(y); Fl.OpenBox(y, 30, 0, 30, 30, "");
  w.End;
  NEW(s); Check.Check(FlImages.GetShared(s, Name, 0, 0), "get");
  FlImages.SetImage(x, s); FlImages.SetImage(y, s); s.Close;
  Check.Check((FlImages.SharedCount() = 1) & ShowsRed(x, 13, 14), "two widgets keep it, after Close");
  IF firstFirst THEN x.Delete ELSE y.Delete END;
  Check.Check(FlImages.SharedCount() = 1, "and one, with the other deleted");
  IF firstFirst THEN Check.Check(ShowsRed(y, 13, 14), "and it shows");
  ELSE Check.Check(ShowsRed(x, 13, 14), "and it shows")
  END;
  IF firstFirst THEN y.Delete ELSE x.Delete END;
  Check.Check(FlImages.SharedCount() = 0, "the last deleted takes it from the pool");
  w.Delete
END TwoShowing;

(* Gets the image, and loses it. *)
PROCEDURE Lose;
  VAR s: FlImages.Shared;
BEGIN NEW(s); Check.Check(FlImages.GetShared(s, Name, 0, 0), "to lose")
END Lose;

PROCEDURE Churn;
  VAR i: INTEGER; p: POINTER TO ARRAY OF CHAR;
BEGIN
  FOR i := 1 TO 200 DO NEW(p, 1000); p[0] := "x" END;
  GC.Collect
END Churn;

BEGIN
  red := Fl.RGB(255, 0, 0); blue := Fl.RGB(0, 0, 255);
  Check.Check(FlImages.SharedCount() = 0, "the pool starts empty");

  (* from the pool, once *)
  NEW(a); Check.Check(FlImages.GetShared(a, Name, 0, 0), "GetShared loads a file");
  Check.Check((a.W() = 4) & (a.H() = 2) & (a.Pixel(0, 0) = red) & (a.Pixel(3, 1) = blue)
    & (a.Kind() = FlImages.RGB), "its pixels, and what it is, are those of the image");
  Check.Check(a.Original() & (a.RefCount() = 1) & (FlImages.SharedCount() = 1), "an original, one reference");
  a.GetName(name);
  Check.Check(name = Name, "its name");
  NEW(b); Check.Check(FlImages.GetShared(b, Name, 0, 0), "GetShared again");
  Check.Check((a.RefCount() = 2) & (FlImages.SharedCount() = 1), "shares it");
  b.Close;
  Check.Check((a.RefCount() = 1) & ~b.IsOpen(), "Close lets go of a reference");
  NEW(b);
  Check.Check(~FlImages.GetShared(b, "images/nothing.png", 0, 0) & ~b.IsOpen()
    & (FlImages.SharedCount() = 1), "a file that won't load is FALSE, and stays out of the pool");
  Check.Check(~FlImages.GetShared(b, "images/not-xbm.h", 0, 0), "as does one it can't decode");
  Check.Check(FlImages.FindShared(b, Name, 0, 0) & (a.RefCount() = 2), "FindShared finds it");
  b.Close; NEW(b);
  Check.Check(~FlImages.FindShared(b, "images/rb.gif", 0, 0) & (FlImages.SharedCount() = 1),
    "and loads nothing");
  Check.Check(~FlImages.FindShared(b, Name, 8, 4), "nor makes a size");

  (* other sizes *)
  Check.Check(FlImages.GetShared(b, Name, 8, 4), "GetShared at another size");
  Check.Check((b.W() = 8) & (b.H() = 4) & ~b.Original() & (b.RefCount() = 1) & (a.RefCount() = 2)
    & (FlImages.SharedCount() = 2), "an entry of its own, which holds a reference to the original");
  NEW(c); Check.Check(FlImages.FindShared(c, Name, 8, 4) & (b.RefCount() = 2), "FindShared of that size");
  c.Close; NEW(c);
  a.Copy(c, 4, 2);
  Check.Check(a.RefCount() = 3, "a copy of its own size is the same entry");
  c.Close; NEW(c);
  a.Copy(c, 8, 4);
  Check.Check((b.RefCount() = 2) & (FlImages.SharedCount() = 2), "a copy of another size, that size's entry");
  c.Close; NEW(c);
  a.Close;
  Check.Check((FlImages.SharedCount() = 2) & (b.RefCount() = 1), "an original stays while a size needs it");
  b.Copy(c, 2, 1);
  Check.Check((c.W() = 2) & (c.DataW() = 2) & (c.Pixel(0, 0) = red) & (c.RefCount() = 1)
    & (FlImages.SharedCount() = 3), "a copy of a size, from another size");
  c.Close; b.Close;
  Check.Check(FlImages.SharedCount() = 0, "the last size to go takes the original");

  (* a bitmap, depth 0, and a pixmap, whose pixels another Shared changes *)
  NEW(a); Check.Check(FlImages.GetShared(a, "images/rb.xbm", 0, 0), "an XBM file in the pool");
  Check.Check(a.Kind() = FlImages.Bitmap, "is a bitmap");
  a.Close; NEW(a);
  Check.Check(FlImages.GetShared(a, "images/rb.gif", 0, 0) & (a.Kind() = FlImages.Pixmap), "a GIF, a pixmap");
  NEW(b); Check.Check(FlImages.GetShared(b, "images/rb.gif", 0, 0), "two of it");
  Check.Check((a.Pixel(0, 0) = red) & (b.Pixel(0, 0) = red), "with its pixels");
  b.ColorAverage(Fl.Blue, 0.0);
  Check.Check((a.Pixel(0, 0) = b.Pixel(0, 0)) & (a.Pixel(0, 0) # red), "a change reaches both");
  a.Close; b.Close;
  IF Fl.Has(Fl.Svg) THEN
    NEW(a);
    Check.Check(FlImages.GetShared(a, "images/rb.svg", 0, 0) & (a.Pixel(0, 0) = red), "an SVG file in the pool");
    a.Close
  ELSE Check.Skip("no SVG")
  END;

  (* changes reach every holder *)
  NEW(a); Check.Check(FlImages.GetShared(a, Name, 0, 0), "again");
  NEW(b); Check.Check(FlImages.GetShared(b, Name, 0, 0), "and again");
  a.Scale(2, 1, FALSE, TRUE);
  Check.Check((b.W() = 2) & (b.DataW() = 4), "Scale is seen by all sharing the entry");
  a.Scale(4, 2, FALSE, TRUE);
  a.Desaturate;
  Check.Check(b.Pixel(0, 0) # red, "as a change to its pixels is");
  a.Close; b.Close;

  (* a shared image kept by FLTK's classes that change and delete a copy *)
  NEW(a); Check.Check(FlImages.GetShared(a, Name, 0, 0), "once more");
  NEW(win); Fl.OpenWindow(win, 200, 200, "TestShared");
  NEW(tree); FlBrowsers.OpenTree(tree, 0, 0, 120, 100, "");
  NEW(b1); Fl.OpenBox(b1, 0, 100, 30, 30, "");
  NEW(b2); Fl.OpenBox(b2, 30, 100, 30, 30, "");
  NEW(choice); FlMenus.OpenChoice(choice, 60, 100, 100, 25, "");
  win.End;
  FlImages.SetOpenIcon(tree, a); FlImages.SetCloseIcon(tree, a); FlImages.SetUserIcon(tree, a);
  Check.Check((a.Pixel(0, 0) = red) & (a.RefCount() = 1) & (FlImages.SharedCount() = 1),
    "a tree's icons leave the pool's image alone");
  FlImages.SetOpenIcon(tree, NIL); FlImages.SetCloseIcon(tree, NIL); FlImages.SetUserIcon(tree, NIL);
  Check.Check((a.Pixel(0, 0) = red) & (a.RefCount() = 1), "going too");
  NEW(i); FlImages.OpenTiled(i, a, 12, 4);
  i.Desaturate;
  Check.Check(a.Pixel(0, 0) = red, "as does tiling it");
  i.Close;
  NEW(i); FlImages.OpenTiled(i, a, 12, 4);
  NEW(tiled); i.Copy(tiled, 8, 4); i.Close; tiled.Close;
  Check.Check(a.RefCount() = 1, "and a tiled image's copy");

  (* widgets *)
  FlImages.SetImage(b1, a); FlImages.SetInactiveImage(b2, a); b2.Deactivate;
  Check.Check(ShowsRed(b1, 13, 14) & ShowsRed(b2, 13, 14), "an image, and an inactive image");
  item := choice.Add("One", 0, {}, NIL, {});
  FlImages.SetItemImage(choice, item, a);
  FlImages.SetItemImage(choice, item, NIL);
  choice.Clear;
  a.Close;
  win.Delete;
  Check.Check(FlImages.SharedCount() = 0, "a window deleted, all let go");

  (* an image made by the program *)
  bits[0] := 0FFX; bits[1] := 0X; bits[2] := 0X;
  NEW(i); FlImages.OpenRGB(i, bits, 1, 1, 3, 0);
  NEW(a); FlImages.ShareImage(a, i);
  i.Close;
  a.GetName(name);
  Check.Check((name # "") & (a.Pixel(0, 0) = red) & a.Original() & (FlImages.SharedCount() = 1),
    "ShareImage: a copy, in the pool");
  NEW(b); Check.Check(FlImages.FindShared(b, name, 0, 0), "found by the name FLTK gave it");
  b.Close; NEW(b);
  a.Copy(b, 2, 2);
  Check.Check((b.W() = 2) & (FlImages.SharedCount() = 2), "and copied");
  a.Close; NEW(c);
  b.Copy(c, 3, 3);
  Check.Check((c.W() = 3) & (FlImages.SharedCount() = 3), "with no file, from the pool's pixels");
  b.Close; c.Close;
  Check.Check(FlImages.SharedCount() = 0, "and gone with them");

  (* reloading: the original, and an entry that keeps its size *)
  WriteFile(255);
  NEW(a); Check.Check(FlImages.GetShared(a, Reloaded, 0, 0) & (a.Pixel(0, 0) = red), "a file");
  NEW(b); Check.Check(FlImages.GetShared(b, Reloaded, 8, 4) & (b.Pixel(7, 3) = red), "scaled");
  WriteFile(0);
  Check.Check(a.Pixel(0, 0) = red, "keeps its pixels as the file changes");
  Check.Check(a.Reload() & (a.Pixel(0, 0) = blue), "until Reload");
  Check.Check(b.Pixel(0, 0) = red, "which is of that entry alone");
  Check.Check(b.Reload() & (b.Pixel(7, 3) = blue) & (b.DataW() = 8), "a scaled one keeps its size");
  NEW(c); Check.Check(FlImages.FindShared(c, Reloaded, 8, 4), "so the pool still finds it");
  c.Close; NEW(c);
  Files.Delete(Reloaded, res);
  Check.Check(~a.Reload() & (a.Pixel(0, 0) = blue), "Reload of a file gone is FALSE, the image unchanged");
  b.Close; a.Close;

  Check.Check((FlImages.openImages = 0), "every image closed");
  TwoShowing(TRUE); TwoShowing(FALSE);
  Lose; Churn;
  Check.Check(FlImages.SharedCount() = 0, "a Shared the program loses lets go, by the collector");
  Check.Check(Fl.OpenWidgets() = 0, "every widget deleted");

  Check.Summary
END TestShared.
