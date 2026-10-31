MODULE TestFileIcons; (* FlImages: file icons *)

(* Icons are never freed, and the list changes how a file browser draws, so
   this has a process of its own. *)

IMPORT Fl, FlBrowsers, FlDraw, FlImages, Check, Probe;

TYPE
  (* Draws its icon on white. *)
  Picture = POINTER TO RECORD (Fl.BoxDesc) icon: FlImages.FileIcon END;

VAR
  win: Fl.Window;
  pic: Picture;
  box: Fl.Box;
  br: FlBrowsers.FileBrowser;
  i, j, k, found: FlImages.FileIcon;
  ml: FlImages.MultiLabel;
  s: ARRAY 64 OF CHAR;
  n, red, blue: INTEGER;
  ok: BOOLEAN;

PROCEDURE (p: Picture) Draw*;
BEGIN
  FlDraw.SetColor(Fl.White); FlDraw.RectF(p.X(), p.Y(), p.W(), p.H());
  p.icon.Draw(p.X(), p.Y(), p.W(), p.H(), Fl.Red, TRUE)
END Draw;

(* Whether the middle of w, 40 by 40, is color c. *)
PROCEDURE Middle(w: Fl.Widget; c: INTEGER): BOOLEAN;
  VAR ok: BOOLEAN;
BEGIN
  ok := Probe.Capture(w) & (Probe.Pixel(20, 20) = c);
  Probe.Release;
  RETURN ok
END Middle;

BEGIN
  red := Fl.RGB(255, 0, 0); blue := Fl.RGB(0, 0, 255);
  Check.Check(FlImages.FirstFileIcon() = NIL, "no icons to begin with");

  (* made from shapes *)
  NEW(i); FlImages.OpenFileIcon(i, "*.foo", FlImages.IconPlain);
  Check.Check((i.Size() = 0) & (i.Type() = FlImages.IconPlain), "OpenFileIcon: empty, of its type");
  i.GetPattern(s);
  Check.Check(s = "*.foo", "its pattern");
  s := "*.changed";
  i.AddColor(FlImages.IconColor);
  i.Add(FlImages.IconPolygon);
  i.AddVertex(1000, 1000); i.AddVertex(9000, 1000); i.AddVertex(9000, 9000); i.AddVertex(1000, 9000);
  i.Add(FlImages.IconEnd);
  Check.Check(i.Size() > 0, "shapes added");
  NEW(j); FlImages.OpenFileIcon(j, "*.bar", FlImages.IconAny);
  j.AddOutlinePolygon(Fl.Black); j.AddColor(Fl.Blue);
  j.AddVertex(0, 0); j.AddVertex(10000, 0); j.AddVertex(10000, 10000); j.AddVertex(0, 10000);
  j.Add(FlImages.IconEnd);
  Check.Check((FlImages.FirstFileIcon() = j) & (j.Next() = i) & (i.Next() = NIL),
    "the list holds them, last made first");
  found := FlImages.FindFileIcon("x.foo", FlImages.IconPlain);
  Check.Check(found = i, "FindFileIcon by the pattern and type");
  found := FlImages.FindFileIcon("x.foo", FlImages.IconDirectory);
  Check.Check(found = NIL, "and no other type");
  found := FlImages.FindFileIcon("x.baz", FlImages.IconPlain);
  Check.Check(found = NIL, "or pattern");

  (* drawn and shown *)
  NEW(win); Fl.OpenWindow(win, 200, 100, "TestFileIcons");
  NEW(pic); Fl.OpenBox(pic, 0, 0, 40, 40, ""); pic.icon := i;
  NEW(box); Fl.OpenBox(box, 50, 0, 40, 40, "");
  win.End;
  box.SetColor(Fl.White);
  Check.Check(Middle(pic, red), "Draw draws it, in the color for IconColor");
  pic.icon := j;
  Check.Check(Middle(pic, blue), "or in its own");
  j.Label(box);
  box.SetLabelColor(Fl.Blue);
  Check.Check(Middle(box, blue), "a widget's label");
  box.GetLabel(s);
  Check.Check(s = "", "reads as no text");
  box.SetLabel("text");
  box.SetLabelColor(Fl.Black);
  box.GetLabel(s);
  Check.Check((s = "text") & (box.LabelType() = Fl.NormalLabel), "and text replaces it");
  j.Label(box);
  box.SetLabelType(Fl.ShadowLabel);
  box.SetLabelColor(Fl.Blue);
  Check.Check(Middle(box, blue), "drawn still");
  NEW(ml); FlImages.OpenMultiLabel(ml); ml.SetText(0, "a", Fl.NormalLabel); ml.SetText(1, "b", Fl.NormalLabel);
  FlImages.SetMultiLabel(box, ml);
  j.Label(box);
  Check.Check(Middle(box, blue), "it replaces a multi-label");
  FlImages.SetMultiLabel(box, ml);
  Check.Check(~Middle(box, blue), "and one replaces it");
  ml.Close;
  FlImages.SetMultiLabel(box, NIL);
  box.SetLabel("");

  (* loaded *)
  NEW(k); FlImages.OpenFileIcon(k, "*.loaded", FlImages.IconPlain);
  Check.Check(~k.Load("images/nothing.png") & (k.Size() = 0), "no file: FALSE");
  Check.Check(~k.Load("images/nothing.fti") & (k.Size() = 0), "no .fti file: FALSE");
  Check.Check(~k.Load("images/bad.fti") & (k.Size() = 0), "a bad .fti file: FALSE, and empty");
  Check.Check(~k.Load("images/rb.xbm") & (k.Size() = 0), "a bitmap has no pixels to read");
  Check.Check(k.Load("images/box.fti") & (k.Size() > 0), "a .fti file");
  pic.icon := k;
  Check.Check(Middle(pic, red), "drawn in IconColor as it says");
  k.Clear;
  Check.Check(k.Size() = 0, "Clear");
  Check.Check(k.Load("images/rb.bmp") & (k.Size() = 68), "a BMP, each row two runs");
  Check.Check(Probe.Capture(pic) & (Probe.Pixel(10, 10) = red) & (Probe.Pixel(30, 10) = blue), "its colors");
  Probe.Release;
  k.Clear;
  Check.Check(k.Load("images/rb.gif") & (k.Size() = 68), "a GIF");
  k.Clear;
  Check.Check(k.Load("images/rb.xpm") & (k.Size() = 68), "an XPM");
  k.Clear;
  IF Fl.Has(Fl.Svg) THEN
    Check.Check(k.Load("images/rb.svg") & (k.Size() > 0), "an SVG")
  ELSE Check.Skip("no SVG")
  END;
  k.Clear;
  Check.Check(k.Load("images/rb.ico"), "an ICO");

  (* a file browser's icons *)
  win.Begin;
  NEW(br); FlBrowsers.OpenFileBrowser(br, 100, 0, 100, 100, "");
  win.End;
  br.Add("one"); br.Add("two");
  FlImages.SetFileIcon(br, 1, i); FlImages.SetFileIcon(br, 2, NIL);
  ok := Probe.Capture(br); Probe.Release;
  Check.Check(ok, "a file browser draws a line's icon");

  (* FLTK's own icons *)
  FlImages.LoadSystemIcons;
  found := FlImages.FirstFileIcon(); n := 0;
  WHILE found # NIL DO INC(n); found := found.Next() END;
  Check.Check(n > 3, "LoadSystemIcons adds to the list, each with an object");
  found := FlImages.FindFileIcon("/tmp", FlImages.IconDirectory);
  Check.Check((found # NIL) & (found.Type() = FlImages.IconDirectory), "a directory's icon");
  found := FlImages.FirstFileIcon();
  Check.Check((found = FlImages.FirstFileIcon()) & (found # NIL), "one object for an icon");
  Check.Check(br.LoadDirectory("images") & (br.Count() > 0), "a browser uses them, as it loads");
  ok := Probe.Capture(br); Probe.Release;
  Check.Check(ok, "and draws");

  win.Delete;
  Check.Check(Fl.OpenWidgets() = 0, "every widget deleted");
  Check.Summary
END TestFileIcons.
