MODULE Icons; (* Images FLTK reads and shares: an XBM file, a bitmap made here, each size in an ICO, one image on many buttons *)

(* A bitmap is drawn in its widget's label color. A Shared image is one
   file's pixels however many widgets show them. Run from examples/, as
   make test runs it. *)

IMPORT Fl, FlButtons, FlImages, OutStr;

CONST
  scale = 8;  (* the test images are tiny *)
  ico = "../test/images/rb.ico";
  xbm = "../test/images/rb.xbm";
  gif = "../test/images/rb.gif";

VAR
  win: Fl.Window;
  info: Fl.Box;
  quit: FlButtons.Button;
  i: FlImages.Image;
  x, id: INTEGER;
  s: FlImages.Shared;
  text: ARRAY 64 OF CHAR;

(* Shows image i, enlarged, in a box at x, y, and closes it: the box keeps
   the copy it shows. *)
PROCEDURE Show(x, y: INTEGER; i: FlImages.Image; label: ARRAY OF CHAR);
  VAR b: Fl.Box; large: FlImages.Image;
BEGIN
  NEW(b); Fl.OpenBox(b, x, y, 80, 60, label);
  b.SetBoxType(Fl.DownBox); b.SetLabelColor(Fl.Blue);
  NEW(large); i.Copy(large, i.W() * scale, i.H() * scale);
  FlImages.SetImage(b, large);
  large.Close; i.Close
END Show;

(* Makes i a checkered bitmap, four by two: a byte a row, its lowest bit
   leftmost. *)
PROCEDURE Checks(i: FlImages.Image);
  VAR bits: ARRAY 2 OF CHAR;
BEGIN
  bits[0] := 5X; bits[1] := 0AX;
  FlImages.OpenBitmap(i, bits, 4, 2)
END Checks;

PROCEDURE SharedButton(x: INTEGER; label: ARRAY OF CHAR);
  VAR b: FlButtons.Button; s: FlImages.Shared;
BEGIN
  NEW(b); FlButtons.OpenButton(b, x, 120, 80, 60, label);
  NEW(s); ASSERT(FlImages.GetShared(s, gif, 64, 32));
  FlImages.SetImage(b, s);
  s.Close
END SharedButton;

PROCEDURE Quit(w: Fl.Widget);
BEGIN win.Hide
END Quit;

BEGIN
  NEW(win); Fl.OpenWindow(win, 370, 280, "Icons");
  NEW(i); ASSERT(FlImages.Load(i, xbm));
  Show(10, 20, i, "XBM");
  NEW(i); Checks(i);
  Show(100, 20, i, "bitmap");
  x := 190; id := 0;
  WHILE id < FlImages.ICOCount(ico) DO
    NEW(i); ASSERT(FlImages.LoadICO(i, ico, id));
    text := "ICO "; OutStr.Int(i.W(), 0, text); OutStr.Char("x", text); OutStr.Int(i.H(), 0, text);
    Show(x, 20, i, text);
    INC(x, 90); INC(id)
  END;
  SharedButton(10, "one"); SharedButton(100, "two"); SharedButton(190, "three");
  (* a size of the file holds a reference to the file itself *)
  NEW(s); ASSERT(FlImages.FindShared(s, gif, 64, 32));
  text := ""; OutStr.Int(s.RefCount() - 1, 0, text); OutStr.String(" buttons, ", text);
  OutStr.Int(FlImages.SharedCount(), 0, text); OutStr.String(" images in the pool", text);
  s.Close;
  NEW(info); Fl.OpenBox(info, 10, 215, 350, 25, text);
  NEW(quit); FlButtons.OpenButton(quit, 280, 245, 80, 25, "Quit"); quit.action := Quit;
  win.End;
  win.Show;
  Fl.Run
END Icons.
