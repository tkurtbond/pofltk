MODULE Device; (* a subset of FLTK's test/device.cxx: a window of drawings, copied to a surface of the user's choice *)

(* FLTK's window draws with every kind of primitive, and GO copies the
   window, a subwindow or a group to an image surface, the clipboard, a
   printer or a file, captures it from the screen, or shows it through a
   mask. fl_line of three points and fl_xyline of two segments aren't
   bound, so those are drawn segment by segment. FLTK's PostScript device
   asks for a file with its own dialog; here the program asks, and opens
   the file. *)

IMPORT Fl, FlButtons, FlDialogs, FlDraw, FlImages, FlPrint, FlValuators, MathL;

CONST
  imageSide = 80;
  bitmapSide = 75;  (* FLTK's pixmaps/sorceress.xbm *)

  imageSurface = 0; printer = 1; postScript = 2; pdf = 3; svg = 4; capture = 5;
  copy = 6; mask = 7;

TYPE
  Clipping = POINTER TO RECORD (Fl.BoxDesc) END;
  Primitives = POINTER TO RECORD (Fl.BoxDesc) END;
  SubPixel = POINTER TO RECORD (Fl.BoxDesc) END;
  LineStyles = POINTER TO RECORD (Fl.BoxDesc) END;
  Complex = POINTER TO RECORD (Fl.BoxDesc) END;
  CrossedButton = POINTER TO RECORD (FlButtons.ButtonDesc) END;
  Operation = POINTER TO RECORD (FlButtons.RadioRoundButtonDesc) operation: INTEGER END;
  Target = POINTER TO RECORD (FlButtons.RadioRoundButtonDesc) target: Fl.Widget END;
  Go = POINTER TO RECORD (FlButtons.ButtonDesc) END;
  Copy = POINTER TO RECORD (Fl.WindowDesc) image: FlImages.Image END;

VAR
  w2, w3: Fl.Window;
  group: Fl.Group;
  target: Fl.Widget;
  operation: INTEGER;
  bits: ARRAY 750 OF CHAR;
  n: INTEGER;

(* Text for a label, with "|" for each line's end. *)
PROCEDURE SetLines(w: Fl.Widget; s: ARRAY OF CHAR);
  VAR i: INTEGER;
BEGIN
  i := 0;
  WHILE s[i] # 0X DO
    IF s[i] = "|" THEN s[i] := 0AX END;
    INC(i)
  END;
  w.SetLabel(s)
END SetLines;

PROCEDURE (b: Clipping) Draw*;
  VAR x, y, w, h: INTEGER;
BEGIN
  b.Draw^;
  x := b.X(); y := b.Y(); w := b.W(); h := b.H();
  FlDraw.SetColor(Fl.Red);
  FlDraw.RectF(x + 5, y + 5, w - 10, h - 10);
  FlDraw.PushClip(x + 6, y + 6, w - 12, h - 12);
  FlDraw.SetColor(Fl.DarkGreen);
  FlDraw.RectF(x + 5, y + 5, w - 10, h - 10);
  FlDraw.PopClip;
  FlDraw.SetColor(Fl.Yellow);
  FlDraw.RectF(x + 7, y + 7, w - 14, h - 14);
  FlDraw.SetColor(Fl.Blue);

  FlDraw.Rect(x + 8, y + 8, w - 16, h - 16);
  FlDraw.PushClip(x + 25, y + 25, w - 50, h - 50);
  FlDraw.SetColor(Fl.Black);
  FlDraw.Rect(x + 24, y + 24, w - 48, h - 48);
  FlDraw.Line(x + 27, y + 27, x + w - 27, y + h - 27);
  FlDraw.Line(x + 27, y + h - 27, x + w - 27, y + 27);
  FlDraw.PopClip
END Draw;

PROCEDURE (b: Primitives) Draw*;
  VAR x, y, d: INTEGER; dashes: ARRAY 4 OF INTEGER;
BEGIN
  b.Draw^;
  x := b.X(); y := b.Y();
  d := y + 5;
  WHILE d < 48 + y DO FlDraw.XYLine(x + 5, d, x + 48); INC(d, 2) END;

  FlDraw.PushClip(x + 52, y + 5, 45, 43);
  d := y + 5;
  WHILE d < 150 + y DO FlDraw.Line(x + 52, d, x + 92, d - 40); INC(d, 3) END;
  FlDraw.PopClip;

  FlDraw.LineStyle(FlDraw.Dash, 0);
  FlDraw.XYLine(x + 5, y + 55, x + 48);
  FlDraw.LineStyle(FlDraw.Dot, 0);
  FlDraw.XYLine(x + 5, y + 58, x + 48);
  FlDraw.LineStyle(FlDraw.DashDot, 0);
  FlDraw.XYLine(x + 5, y + 61, x + 48);
  FlDraw.LineStyle(FlDraw.DashDotDot, 0);
  FlDraw.XYLine(x + 5, y + 64, x + 48);
  dashes[0] := 7; dashes[1] := 3; dashes[2] := 7; dashes[3] := 2;
  FlDraw.LineStyleDashes(FlDraw.Solid, 0, dashes);
  FlDraw.XYLine(x + 5, y + 67, x + 48);
  FlDraw.LineStyle(FlDraw.Solid, 0);

  FlDraw.Line(x + 5, y + 72, x + 25, y + 95);
  FlDraw.Line(x + 8, y + 72, x + 28, y + 95);
  FlDraw.Line(x + 28, y + 95, x + 31, y + 72);

  FlDraw.SetColor(Fl.Yellow);
  FlDraw.Polygon3(x + 11, y + 72, x + 27, y + 91, x + 29, y + 72);
  FlDraw.SetColor(Fl.Red);
  FlDraw.Loop3(x + 11, y + 72, x + 27, y + 91, x + 29, y + 72);

  FlDraw.SetColor(Fl.Blue);
  FlDraw.LineStyle(FlDraw.Solid, 6);
  FlDraw.Loop3(x + 31, y + 12, x + 47, y + 31, x + 49, y + 12);
  FlDraw.LineStyle(FlDraw.Solid, 0);

  FlDraw.SetColor(Fl.RGB(200, 0, 200));
  FlDraw.Polygon4(x + 35, y + 72, x + 33, y + 95, x + 48, y + 95, x + 43, y + 72);
  FlDraw.SetColor(Fl.Green);
  FlDraw.Loop4(x + 35, y + 72, x + 33, y + 95, x + 48, y + 95, x + 43, y + 72);

  FlDraw.SetColor(Fl.Blue);
  FlDraw.YXLine(x + 65, y + 63, y + 66);
  FlDraw.SetColor(Fl.Green);
  FlDraw.YXLine(x + 66, y + 66, y + 63);

  FlDraw.SetColor(Fl.Blue);
  FlDraw.Rect(x + 80, y + 55, 5, 5);
  FlDraw.SetColor(Fl.Yellow);
  FlDraw.RectF(x + 81, y + 56, 3, 3);
  FlDraw.SetColor(Fl.Black);
  FlDraw.Point(x + 82, y + 57);

  FlDraw.SetColor(Fl.Blue);
  FlDraw.Rect(x + 56, y + 79, 24, 17);
  FlDraw.SetColor(Fl.Cyan);
  FlDraw.RectF(x + 57, y + 80, 22, 15);
  FlDraw.SetColor(Fl.Red);
  FlDraw.Arc(x + 57, y + 80, 22, 15, 40, 270);
  FlDraw.SetColor(Fl.Yellow);
  FlDraw.Pie(x + 58, y + 81, 20, 13, 40, 270);

  FlDraw.LineStyle(FlDraw.Solid, 0);

  FlDraw.SetColor(Fl.Black);
  FlDraw.Point(x + 58, y + 58);
  FlDraw.SetColor(Fl.Red);
  FlDraw.YXLine(x + 59, y + 58, y + 59);
  FlDraw.SetColor(Fl.Green);
  FlDraw.YXLine(x + 60, y + 59, y + 58);
  FlDraw.SetColor(Fl.Black);
  FlDraw.XYLine(x + 61, y + 58, x + 62);
  FlDraw.SetColor(Fl.Red);
  FlDraw.XYLine(x + 62, y + 59, x + 61);

  FlDraw.SetColor(Fl.Green);
  FlDraw.YXLine(x + 57, y + 58, y + 59);
  FlDraw.XYLine(x + 57, y + 59, x + 58);
  FlDraw.SetColor(Fl.Blue);
  FlDraw.XYLine(x + 58, y + 60, x + 56);
  FlDraw.YXLine(x + 56, y + 60, y + 58);
  FlDraw.SetColor(Fl.Red);
  FlDraw.XYLine(x + 58, y + 61, x + 56);
  FlDraw.YXLine(x + 56, y + 61, y + 63);
  FlDraw.SetColor(Fl.Green);
  FlDraw.YXLine(x + 57, y + 63, y + 62);
  FlDraw.XYLine(x + 57, y + 62, x + 58);

  FlDraw.SetColor(Fl.Blue);
  FlDraw.Line(x + 58, y + 63, x + 60, y + 65);
  FlDraw.SetColor(Fl.Black);
  FlDraw.Line(x + 61, y + 65, x + 59, y + 63);

  FlDraw.SetColor(Fl.Black)
END Draw;

PROCEDURE (b: SubPixel) Draw*;
  VAR x, y: INTEGER; d: LONGREAL;
BEGIN
  b.Draw^;
  x := b.X(); y := b.Y();
  FlDraw.PushClip(x + 5, y + 5, 45, 43);
  d := y + 5;
  WHILE d < 95 + y DO
    FlDraw.BeginLine;
    FlDraw.Vertex(x + 5, d);
    FlDraw.Vertex(x + 48, d);
    FlDraw.EndLine;
    d := d + 1.63D0
  END;
  FlDraw.PopClip;

  FlDraw.PushClip(x + 52, y + 5, 45, 43);
  d := y + 5;
  WHILE d < 150 + y DO
    FlDraw.BeginLine;
    FlDraw.Vertex(x + 52, d);
    FlDraw.Vertex(x + 92, d - 43);
    FlDraw.EndLine;
    d := d + 2.3052D0
  END;
  FlDraw.PopClip
END Draw;

(* A line in a color and style, from the left at height d, turning down
   at 200 - d to the bottom. *)
PROCEDURE Bent(color, style, d: INTEGER);
BEGIN
  FlDraw.SetColor(color);
  FlDraw.LineStyle(style, 5);
  FlDraw.BeginLine;
  FlDraw.Vertex(10, d);
  FlDraw.Vertex(200 - d, d);
  FlDraw.Vertex(200 - d, 190);
  FlDraw.EndLine;
  FlDraw.LineStyle(FlDraw.Solid, 0)
END Bent;

PROCEDURE (b: LineStyles) Draw*;
  VAR dashes: ARRAY 6 OF INTEGER;
BEGIN
  b.Draw^;
  FlDraw.PushMatrix;
  FlDraw.Translate(b.X(), b.Y());
  FlDraw.Scale(0.75D0, 0.75D0);

  Bent(Fl.Black, FlDraw.Solid, 160);
  Bent(Fl.Red, FlDraw.Solid + FlDraw.CapFlat + FlDraw.JoinMiter, 150);
  Bent(Fl.Green, FlDraw.Solid + FlDraw.CapRound + FlDraw.JoinRound, 140);
  Bent(Fl.Blue, FlDraw.Solid + FlDraw.CapSquare + FlDraw.JoinBevel, 130);
  Bent(Fl.Black, FlDraw.Dash, 120);
  Bent(Fl.Red, FlDraw.Dash + FlDraw.CapFlat, 110);
  Bent(Fl.Green, FlDraw.Dash + FlDraw.CapRound, 100);
  Bent(Fl.Blue, FlDraw.Dash + FlDraw.CapSquare, 90);
  Bent(Fl.Black, FlDraw.Dot, 80);
  Bent(Fl.Red, FlDraw.Dot + FlDraw.CapFlat, 70);
  Bent(Fl.Green, FlDraw.Dot + FlDraw.CapRound, 60);
  Bent(Fl.Blue, FlDraw.Dot + FlDraw.CapSquare, 50);
  Bent(Fl.Black, FlDraw.DashDot + FlDraw.CapRound + FlDraw.JoinRound, 40);
  Bent(Fl.Red, FlDraw.DashDotDot + FlDraw.CapSquare + FlDraw.JoinBevel, 30);
  Bent(Fl.Green, FlDraw.DashDotDot + FlDraw.CapRound + FlDraw.JoinRound, 20);

  dashes[0] := 10; dashes[1] := 3; dashes[2] := 4;
  dashes[3] := 2; dashes[4] := 2; dashes[5] := 1;
  FlDraw.SetColor(Fl.Blue);
  FlDraw.LineStyleDashes(FlDraw.Solid, 5, dashes);
  FlDraw.BeginLine;
  FlDraw.Vertex(10, 10);
  FlDraw.Vertex(190, 10);
  FlDraw.Vertex(190, 190);
  FlDraw.EndLine;
  FlDraw.LineStyle(FlDraw.Solid, 0);

  FlDraw.PopMatrix;
  FlDraw.SetColor(Fl.Black)
END Draw;

PROCEDURE (b: Complex) Draw*;
BEGIN
  b.Draw^;
  FlDraw.PushMatrix;
  FlDraw.Translate(b.X(), b.Y());

  FlDraw.PushMatrix;
  FlDraw.MultMatrix(1, 3, 0, 1, 0, -20);
  FlDraw.SetColor(Fl.Green);
  FlDraw.BeginPolygon;
  FlDraw.Vertex(10, 10);
  FlDraw.Vertex(100, -80);
  FlDraw.Vertex(100, -190);
  FlDraw.EndPolygon;

  FlDraw.SetColor(Fl.Red);
  FlDraw.LineStyle(FlDraw.DashDot, 7);
  FlDraw.BeginLoop;
  FlDraw.Vertex(10, 10);
  FlDraw.Vertex(100, -80);
  FlDraw.Vertex(100, -190);
  FlDraw.EndLoop;
  FlDraw.LineStyle(FlDraw.Solid, 0);

  FlDraw.SetColor(Fl.Blue);
  FlDraw.LineStyle(FlDraw.Solid, 3);
  FlDraw.BeginLoop;
  FlDraw.Circle(60, -50, 30);
  FlDraw.EndLoop;
  FlDraw.LineStyle(FlDraw.Solid, 0);
  FlDraw.PopMatrix;

  FlDraw.Scale(1.8D0, 1);

  FlDraw.SetColor(Fl.Yellow);
  FlDraw.BeginPolygon;
  FlDraw.ArcPath(30, 90, 20, -45, 200);
  FlDraw.EndPolygon;

  FlDraw.SetColor(Fl.Black);
  FlDraw.LineStyle(FlDraw.Dash, 3);
  FlDraw.BeginLine;
  FlDraw.ArcPath(30, 90, 20, -45, 200);
  FlDraw.EndLine;
  FlDraw.LineStyle(FlDraw.Solid, 0);

  FlDraw.Translate(15, 0);
  FlDraw.Scale(1.5D0, 3);
  FlDraw.BeginComplexPolygon;
  FlDraw.Vertex(30, 70);
  FlDraw.ArcPath(45, 55, 10, 200, 90);
  FlDraw.ArcPath(55, 45, 8, -170, 20);
  FlDraw.Vertex(60, 40);
  FlDraw.Vertex(30, 20);
  FlDraw.Vertex(40, 5);
  FlDraw.Vertex(60, 25);
  FlDraw.Curve(35, 30, 30, 53, 0, 35, 65, 65);
  FlDraw.Gap;
  FlDraw.Vertex(50, 25);
  FlDraw.Vertex(40, 10);
  FlDraw.Vertex(35, 20);
  FlDraw.EndComplexPolygon;

  FlDraw.PopMatrix
END Draw;

PROCEDURE (b: CrossedButton) Draw*;
  VAR type, col: INTEGER;
BEGIN
  IF b.Value() THEN
    type := b.DownBox();
    IF type = Fl.NoBox THEN type := Fl.DownBox END;
    col := b.SelectionColor()
  ELSE
    type := b.BoxType(); col := b.Color()
  END;
  FlDraw.DrawBox(type, b.X(), b.Y(), b.W(), b.H(), col);
  FlDraw.SetColor(Fl.White);
  FlDraw.LineStyle(FlDraw.Solid, 5);
  FlDraw.Line(b.X() + 15, b.Y() + 10, b.X() + b.W() - 15, b.Y() + b.H() - 23);
  FlDraw.Line(b.X() + b.W() - 15, b.Y() + 10, b.X() + 15, b.Y() + b.H() - 23);
  FlDraw.LineStyle(FlDraw.Solid, 0);
  b.DrawLabel
END Draw;

(* The window a copy is shown in. *)
PROCEDURE (c: Copy) Callback*;
BEGIN c.image.Close; c.Delete
END Callback;

(* Shows i with a yellow margin, and closes it when the window closes. *)
PROCEDURE ShowCopy(i: FlImages.Image; margin: INTEGER; title: ARRAY OF CHAR);
  VAR c: Copy; b: Fl.Box;
BEGIN
  NEW(c); c.image := i;
  Fl.OpenWindow(c, i.W() + 2 * margin, i.H() + 2 * margin, title);
  c.SetColor(Fl.Yellow);
  NEW(b); Fl.OpenBox(b, margin, margin, i.W(), i.H(), "");
  FlImages.SetImage(b, i);
  c.End;
  c.Show
END ShowCopy;

PROCEDURE ToImage;
  VAR s: FlImages.Surface; i: FlImages.Image; w, h: INTEGER; decorated: BOOLEAN;
BEGIN
  decorated := (target IS Fl.Window) & (target.Parent() = NIL);
  IF decorated THEN
    w := target(Fl.Window).DecoratedW(); h := target(Fl.Window).DecoratedH()
  ELSE
    w := target.W(); h := target.H()
  END;
  NEW(s); FlImages.OpenSurface(s, w, h);
  s.Begin;
  FlDraw.SetColor(Fl.Yellow); FlDraw.RectF(0, 0, w, h);
  IF decorated THEN s.DrawDecoratedWindow(target(Fl.Window), 0, 0)
  ELSE s.DrawWidget(target, 0, 0)
  END;
  s.End;
  NEW(i); s.GetImage(i);
  s.Close;
  ShowCopy(i, 5, "Image surface")
END ToImage;

(* What the screen shows of the target, from the window it is in. *)
PROCEDURE ToCapture;
  VAR win: Fl.Widget; i: FlImages.Image; x, y: INTEGER;
BEGIN
  win := target; x := 0; y := 0;
  IF ~(target IS Fl.Window) THEN
    x := target.X(); y := target.Y();
    REPEAT win := win.Parent() UNTIL win IS Fl.Window
  END;
  NEW(i);
  IF FlImages.CaptureWindow(i, win(Fl.Window), x, y, target.W(), target.H()) THEN
    ShowCopy(i, 5, "fl_capture_window()")
  END
END ToCapture;

(* Puts the target on the clipboard, as an image, for another program to
   paste. Closing the surface does it, so nothing here shows. *)
PROCEDURE ToCopy;
  VAR s: FlImages.CopySurface;
BEGIN
  NEW(s);
  IF (target IS Fl.Window) & (target.Parent() = NIL) THEN
    FlImages.OpenCopySurface(s, target(Fl.Window).DecoratedW(), target(Fl.Window).DecoratedH());
    s.Begin;
    s.DrawDecoratedWindow(target(Fl.Window), 0, 0)
  ELSE
    FlImages.OpenCopySurface(s, target.W() + 10, target.H() + 20);
    s.Begin;
    FlDraw.SetColor(Fl.Yellow); FlDraw.RectF(0, 0, target.W() + 10, target.H() + 20);
    s.DrawWidget(target, 5, 10)
  END;
  s.End;
  s.Close
END ToCopy;

(* The target through a white ellipse on yellow, and a window also through
   a ring with FLTK's name in it. *)
PROCEDURE ToMask;
  VAR
    s: FlImages.Surface; m, i: FlImages.Image;
    w, h, mini, dx, dy, textW, textH: INTEGER;
BEGIN
  w := target.W(); h := target.H();
  NEW(s); FlImages.OpenSurface(s, w, h);
  s.Begin;
  FlDraw.SetColor(Fl.Black); FlDraw.RectF(0, 0, w, h);
  FlDraw.SetColor(Fl.White); FlDraw.Pie(0, 0, w, h, 0.0D0, 360.0D0);
  IF (target IS Fl.Window) & (target.Parent() = NIL) THEN
    IF w < h THEN mini := w * 66 DIV 100 ELSE mini := h * 66 DIV 100 END;
    FlDraw.SetColor(Fl.Black);
    FlDraw.Pie(w DIV 2 - mini DIV 2, h DIV 2 - mini DIV 2, mini, mini, 0.0D0, 360.0D0);
    FlDraw.SetColor(Fl.White);
    FlDraw.SetFont(Fl.TimesBold, 120);
    FlDraw.TextExtents("FLTK", dx, dy, textW, textH);
    FlDraw.Text("FLTK", w DIV 2 - textW DIV 2, h DIV 2 + textH DIV 2)
  END;
  NEW(m); s.GetImage(m);
  FlDraw.SetColor(Fl.Yellow); FlDraw.RectF(0, 0, w, h);
  s.End;
  s.Mask(m);
  m.Close;
  s.Begin;
  s.DrawWidget(target, 0, 0);
  NEW(i); s.GetImage(i);
  s.End;
  s.Close;
  ShowCopy(i, 0, "Fl_Image_Surface::mask()")
END ToMask;

(* One page, of the target as large as it fits, in the middle. *)
PROCEDURE ToPage(d: FlPrint.PagedDevice);
  VAR targetW, targetH, w, h: INTEGER; s, t: LONGREAL;
BEGIN
  d.BeginPage;
  IF target IS Fl.Window THEN
    targetW := target(Fl.Window).DecoratedW(); targetH := target(Fl.Window).DecoratedH()
  ELSE
    targetW := target.W(); targetH := target.H()
  END;
  d.PrintableRect(w, h);
  s := 1; t := 1;
  IF targetW > w THEN t := w / targetW END;
  IF targetH > h THEN s := h / targetH END;
  IF t < s THEN s := t END;
  d.Scale(s, s);
  d.PrintableRect(w, h);
  d.SetOrigin(w DIV 2, h DIV 2);
  IF target IS Fl.Window THEN
    d.DrawDecoratedWindow(target(Fl.Window), -(targetW DIV 2), -(targetH DIV 2))
  ELSE
    d.DrawWidget(target, -(targetW DIV 2), -(targetH DIV 2))
  END;
  d.EndPage
END ToPage;

PROCEDURE Say;
  VAR message: ARRAY 256 OF CHAR;
BEGIN
  FlPrint.Error(message);
  IF message[0] = 0X THEN message := "It wasn't written." END;
  FlDialogs.Alert(message)
END Say;

(* Whether the user gave a file to write. *)
PROCEDURE PickFile(title-, filter-: ARRAY OF CHAR; VAR path: ARRAY OF CHAR): BOOLEAN;
  VAR c: FlDialogs.NativeFileChooser; picked: BOOLEAN;
BEGIN
  NEW(c); FlDialogs.OpenNativeFileChooser(c, FlDialogs.BrowseSaveFile);
  c.SetTitle(title);
  c.SetFilter(filter);
  c.SetOptions(FlDialogs.SaveAsConfirm + FlDialogs.UseFilterExt);
  picked := c.Show() = FlDialogs.Chosen;
  IF picked THEN c.FileName(0, path) END;
  c.Close;
  RETURN picked
END PickFile;

PROCEDURE ToPrinter;
  VAR p: FlPrint.Printer;
BEGIN
  NEW(p); FlPrint.OpenPrinter(p);
  CASE p.BeginJob(1) OF
    FlPrint.JobOk: ToPage(p); IF ~p.EndJob() THEN Say END
  | FlPrint.JobCancelled:
  | FlPrint.JobFailed: Say
  END;
  p.Close
END ToPrinter;

PROCEDURE ToPostScript;
  VAR f: FlPrint.PostScriptFile; path: ARRAY 1024 OF CHAR;
BEGIN
  IF PickFile("Save a .ps file", "*.ps", path) THEN
    NEW(f);
    IF FlPrint.OpenPostScript(f, path, FlPrint.A4, FlPrint.Portrait) THEN
      ToPage(f);
      IF ~f.EndJob() THEN Say END;
      f.Close
    ELSE Say
    END
  END
END ToPostScript;

PROCEDURE ToPDF;
  VAR f: FlPrint.PDFFile;
BEGIN
  NEW(f);
  IF FlPrint.OpenPDF(f, "FLTK.pdf", FlPrint.A4, FlPrint.Portrait) THEN
    ToPage(f);
    IF ~f.EndJob() THEN Say END;
    f.Close
  ELSE Say
  END
END ToPDF;

PROCEDURE ToSVG;
  VAR f: FlPrint.SVGFile; path: ARRAY 1024 OF CHAR; w, h: INTEGER;
BEGIN
  IF PickFile("Save a .svg file", "*.svg", path) THEN
    IF target IS Fl.Window THEN
      w := target(Fl.Window).DecoratedW(); h := target(Fl.Window).DecoratedH()
    ELSE
      w := target.W(); h := target.H()
    END;
    NEW(f);
    IF FlPrint.OpenSVG(f, path, w, h) THEN
      f.Begin;
      IF target IS Fl.Window THEN f.DrawDecoratedWindow(target(Fl.Window), 0, 0)
      ELSE f.DrawWidget(target, 0, 0)
      END;
      f.End;
      IF ~f.Finish() THEN Say END;
      f.Close
    ELSE Say
    END
  END
END ToSVG;

PROCEDURE (b: Go) Callback*;
BEGIN
  CASE operation OF
    imageSurface: ToImage
  | printer: ToPrinter
  | postScript: ToPostScript
  | pdf: ToPDF
  | svg: ToSVG
  | capture: ToCapture
  | copy: ToCopy
  | mask: ToMask
  END
END Callback;

PROCEDURE (b: Operation) Callback*;
BEGIN operation := b.operation
END Callback;

PROCEDURE (b: Target) Callback*;
BEGIN target := b.target
END Callback;

(* FLTK's image: red, green and blue corners, clear in the middle. *)
PROCEDURE RGBImage(i: FlImages.Image);
  VAR image: POINTER TO ARRAY OF CHAR; p, x, y, alpha: INTEGER; fx, fy: LONGREAL;

  PROCEDURE Put(v: INTEGER);
  BEGIN image[p] := CHR(v); INC(p)
  END Put;

BEGIN
  NEW(image, 4 * imageSide * imageSide); p := 0;
  FOR y := 0 TO imageSide - 1 DO
    fy := y / (imageSide - 1);
    FOR x := 0 TO imageSide - 1 DO
      fx := x / (imageSide - 1);
      Put(SHORT(ENTIER(255 * ((1 - fx) * (1 - fy)))));  (* red in upper-left *)
      Put(SHORT(ENTIER(255 * ((1 - fx) * fy))));  (* green in lower-left *)
      Put(SHORT(ENTIER(255 * (fx * fy))));        (* blue in lower-right *)
      alpha := SHORT(ENTIER(350 * MathL.sqrt((fx - 0.5D0) * (fx - 0.5D0) + (fy - 0.5D0) * (fy - 0.5D0))));
      IF alpha < 255 THEN Put(alpha) ELSE Put(255) END
    END
  END;
  FlImages.OpenRGB(i, image^, imageSide, imageSide, 4, 0)
END RGBImage;

(* The next row of the bitmap, in hexadecimal. *)
PROCEDURE Row(s: ARRAY OF CHAR);
  VAR i: INTEGER;

  PROCEDURE Digit(c: CHAR): INTEGER;
  BEGIN
    IF c >= "a" THEN RETURN ORD(c) - ORD("a") + 10 END;
    RETURN ORD(c) - ORD("0")
  END Digit;

BEGIN
  i := 0;
  WHILE s[i] # 0X DO
    bits[n] := CHR(Digit(s[i]) * 16 + Digit(s[i + 1])); INC(n); INC(i, 2)
  END
END Row;

PROCEDURE Sorceress;
BEGIN
  Row("fc7e4020900007802300");
  Row("00c6c14198b801076600");
  Row("159f03478cc6dc7bcc00");
  Row("b0710e4d0666738e8f01");
  Row("18c4394b02230c041e03");
  Row("0c08c7ef083006071c02");
  Row("063018aec8983f782006");
  Row("022060a0c41dc0ff4104");
  Row("fa6380a1a43d0084bf04");
  Row("0f06fca1346b011cc905");
  Row("06c706be111e43309105");
  Row("c36102301b30cc201100");
  Row("c13c03200a00e8602100");
  Row("611bc16308f0c6c72103");
  Row("f808e1cf0afc4d994307");
  Row("3c0cf19f0bfc5b814702");
  Row("1604311c0b1f17894d06");
  Row("1a043138020756894904");
  Row("0b04b17282a1549a4904");
  Row("1d6650e7c2f0549a5804");
  Row("0d62c11f44fc51909004");
  Row("8663e07404ef311a9100");
  Row("02e2c1fd84f9300a9100");
  Row("82a9c0b984f931168100");
  Row("42a9db7f0cff1c161100");
  Row("02280b0708601c029100");
  Row("46290e00000010161102");
  Row("06290400000010169106");
  Row("a62a0400000018249104");
  Row("862a0400000018279304");
  Row("964a0400000004029104");
  Row("864a0c0000001e239304");
  Row("56880800000090219304");
  Row("520a09800100d0219504");
  Row("570a0f802700d8209d04");
  Row("5d081c806700e4018504");
  Row("798a3f000000f4118506");
  Row("39087d000018b7108103");
  Row("2912cb007e3028008503");
  Row("2910be81ff270c108503");
  Row("2932fac1ff2794118503");
  Row("28206ce1ff070c018501");
  Row("28625ce38f034e918005");
  Row("3940f4c2ff009f918405");
  Row("31c6e8077f80cd00c404");
  Row("3106c90e00c04888e004");
  Row("7904db1200300cc8e404");
  Row("6d06b62300181cc08404");
  Row("250cffc2004e06b08004");
  Row("3f8ab383ffc303918404");
  Row("2ed80f3f00005f838404");
  Row("2a70fd7f0000c8c08404");
  Row("4be22f01000858608004");
  Row("5b82ff010008d0a08404");
  Row("7280e5000008d2204404");
  Row("ca02ff000008dea04404");
  Row("82026d000008f6b04002");
  Row("82073f00000844584402");
  Row("933f1f000030884f4403");
  Row("83233e0000001860e007");
  Row("e30ffe0000007070e407");
  Row("c71bfe010000e03ce407");
  Row("c7e3fe1f0000ff1ffc07");
  Row("c703f83300c0f007ff07");
  Row("8702fc430060f0ffff07");
  Row("8f06be870030f8ffff07");
  Row("8f149c8f0000fcffff07");
  Row("9f8d8a0f0000feffff07");
  Row("bf0b801f0000ffffff07");
  Row("7f3a803f0080ffffff07");
  Row("ff20c03f0080ffffff07");
  Row("ff01e07f00c0ffffff07");
  Row("ff0ff8ff40e0ffffff07");
  Row("ffffffff40f0ffffff07");
  Row("ffffffff41f0ffffff07")
END Sorceress;

PROCEDURE Porsche(i: FlImages.Image);
  VAR x: ARRAY 69, 65 OF CHAR;
BEGIN
  x[0] := "64 64 4 1";
  x[1] := "  c #background";
  x[2] := ". c #000000000000";
  x[3] := "X c #ffd100";
  x[4] := "o c #FFFF00000000";
  x[5] := "                                                                ";
  x[6] := "                   ..........................                   ";
  x[7] := "              .....................................             ";
  x[8] := "        ............XXXXXXXXXXXXXXXXXXXXXXXX............        ";
  x[9] := "        ......XXXXXXX...XX...XXXXXXXX...XXXXXXXXXX......        ";
  x[10] := "        ..XXXXXXXXXX..X..XX..XXXX.XXXX..XXXXXXXXXXXXXX..        ";
  x[11] := "        ..XXXXXXXXXX..X..XX..XXX..XXXX..X...XXXXXXXXXX..        ";
  x[12] := "        ..XXXXXXXXXX..XXXXX..XX.....XX..XX.XXXXXXXXXXX..        ";
  x[13] := "        ..XXXXXXXXX.....XXX..XXX..XXXX..X.XXXXXXXXXXXX..        ";
  x[14] := "        ..XXXXXXXXXX..XXXXX..XXX..XXXX....XXXXXXXXXXXX..        ";
  x[15] := "        ..XXXXXXXXXX..XXXXX..XXX..XXXX..X..XXXXXXXXXXX..        ";
  x[16] := "        ..XXXXXXXXXX..XXXXX..XXX..X.XX..XX..XXXXXXXXXX..        ";
  x[17] := "        ..XXXXXXXXX....XXX....XXX..XX....XX..XXXXXXXXX..        ";
  x[18] := "        ..XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX..        ";
  x[19] := "        ..XXXXXXXXX..........................XXXXXXXXX..        ";
  x[20] := "        ..XXX.......XXXXXXXXXXX...................XXXX..        ";
  x[21] := "        ......XX.XXX.XXX..XXXXX.........................        ";
  x[22] := "        ..XXXXX.XXX.XXX.XXXX.XX.........................        ";
  x[23] := "        ..XXXX.XXX.XX.......XXX.........................        ";
  x[24] := "        ..XXXX.......XXXXXX..XX..ooooooooooooooooooooo..        ";
  x[25] := "        ..X.....XXXXXXXXXXXXXXX..ooooooooooooooooooooo..        ";
  x[26] := "        ..X...XXXXXXXXXXXXXXXXX..ooooooooooooooooooooo..        ";
  x[27] := "        ..X..XXXXXXX.XX.XXXXXXX..ooooooooooooooooooooo..        ";
  x[28] := "        ..XXXXX.XXX.XX.XXXXXXXX..ooooooooooooooooooooo..        ";
  x[29] := "        ..XXXX.XXX.XX.XX................................        ";
  x[30] := "        ..XXXX.X.........X....X.X.X.....................        ";
  x[31] := "        ..XXXX...XXXXXXX.X..X...X.X.X.X.................        ";
  x[32] := "        ..X....XXXXXXXXXX.X...X.X.X.....................        ";
  x[33] := "        ..X...XXXXXXXXXX.XXXXXXXXXXXXXX.................        ";
  x[34] := "        ..X..XXXXXX.XX.X.XXX...XXXXXXXX.................        ";
  x[35] := "        ..XXXXX.XX.XX.XX.XX.....XXXXXXX.oooooooooooooo..        ";
  x[36] := "        ..XXXX.XX.XX.XX..XX.X...XXXXX.X.oooooooooooooo..        ";
  x[37] := "        ..XXXX.X.......X.XXXX...XXXX..X.oooooooooooooo..        ";
  x[38] := "        ..X......XXXXXX..XXXX...XXXX..X.oooooooooooooo..        ";
  x[39] := "        ..X...XXXXXXXXXX.XXX.....XXX.XX.oooooooooooooo..        ";
  x[40] := "        ..X..XXXXXXXXXXX.X...........XX.oooooooooooooo..        ";
  x[41] := "        .................X.X.........XX.................        ";
  x[42] := "        .................X.X.XXXX....XX.XXXXXXXXXXXXXX..        ";
  x[43] := "        .................XXX.XXXXX.X.XX.XXX.XX.XXXXXXX..        ";
  x[44] := "         ................XXXX.XXX..X..X.XX.XX.XXX.XXX..         ";
  x[45] := "         ................XXXXXXXX.XX.XX.X.XX.XXX.XXXX..         ";
  x[46] := "         .................XXXXXX.XX.XX.X..........XXX..         ";
  x[47] := "          ..oooooooooooooo.XXXXXXXXXX....XXXXXXXX..X..          ";
  x[48] := "          ..ooooooooooooooo.XXXXXXXX....XXXXXXXXXXXX..          ";
  x[49] := "           ..ooooooooooooooo........XXXXXXX.XX.XXXX..           ";
  x[50] := "           ..oooooooooooooooooo..XXXXX.XXX.XX.XX.XX..           ";
  x[51] := "            ..ooooooooooooooooo..XXXX.XXX.XX.XX.XX..            ";
  x[52] := "            ..ooooooooooooooooo..XXX.XX........XXX..            ";
  x[53] := "             ....................XXX....XXXXXX..X..             ";
  x[54] := "              ...................XX...XXXXXXXXXXX.              ";
  x[55] := "              ...................X...XXXXXXXXXXX..              ";
  x[56] := "               ..................X..XXXX.XXXXXX..               ";
  x[57] := "                .................XXX.XX.XX.XXX..                ";
  x[58] := "                 ................XX.XX.XX.XXX..                 ";
  x[59] := "                  ..ooooooooooo..XX.......XX..                  ";
  x[60] := "                   ..oooooooooo..X...XXXX.X..                   ";
  x[61] := "                    ..ooooooooo..X..XXXXXX..                    ";
  x[62] := "                     ...ooooooo..X..XXXX...                     ";
  x[63] := "                      ....ooooo..XXXXX....                      ";
  x[64] := "                        ....ooo..XXX....                        ";
  x[65] := "                          ....o..X....                          ";
  x[66] := "                            ........                            ";
  x[67] := "                              ....                              ";
  x[68] := "                                                                ";
  ASSERT(FlImages.OpenXPM(i, x, 69))
END Porsche;

PROCEDURE AddOperation(x, y, what: INTEGER; label-: ARRAY OF CHAR);
  VAR b: Operation;
BEGIN
  NEW(b); FlButtons.OpenRadioRoundButton(b, x, y, 150, 12, label);
  b.operation := what; b.SetLabelSize(12);
  IF what = imageSurface THEN b.SetValue(TRUE) END
END AddOperation;

PROCEDURE AddTarget(x, w: INTEGER; what: Fl.Widget; label-: ARRAY OF CHAR);
  VAR b: Target;
BEGIN
  NEW(b); FlButtons.OpenRadioRoundButton(b, x, 57, w, 12, label);
  b.target := what; b.SetLabelSize(12);
  IF what = w2 THEN b.SetValue(TRUE) END
END AddTarget;

PROCEDURE Drawings;
  VAR clipping: Clipping; primitives: Primitives; subPixel: SubPixel;
    styles: LineStyles; complex: Complex; b: CrossedButton; i: FlImages.Image;
BEGIN
  NEW(clipping); Fl.OpenBox(clipping, 10, 156, 100, 100, "");
  SetLines(clipping, 'Clipping and rect(f):|Yellow rect.framed|by B-Y-G-R rect. 1 p.|thick. Your printer may |render very thin lines|surrounding "X"');
  clipping.SetAlign(Fl.AlignTop); clipping.SetLabelSize(10);

  NEW(primitives); Fl.OpenBox(primitives, 110, 96, 100, 100, "Integer primitives");
  primitives.SetLabelSize(10); primitives.SetAlign(Fl.AlignTop);

  NEW(subPixel); Fl.OpenBox(subPixel, 220, 156, 100, 100, "");
  SetLines(subPixel, "Sub-pixel drawing of|lines 1.63 points apart|On the screen you|can see aliasing, the|printer should render|them properly");
  subPixel.SetLabelSize(10); subPixel.SetAlign(Fl.AlignTop);

  NEW(styles); Fl.OpenBox(styles, 330, 96, 150, 150, "Line styles");
  styles.SetLabelSize(10); styles.SetAlign(Fl.AlignTop);

  NEW(complex); Fl.OpenBox(complex, 140, 286, 230, 250, "");
  SetLines(complex, "Complex (double) drawings:|Blue ellipse may not be|correctly transformed|due to non-orthogonal|transformation");
  complex.SetLabelSize(10); complex.SetAlign(Fl.AlignTop);

  NEW(i); RGBImage(i);
  NEW(b); FlButtons.OpenButton(b, 10, 261, 100, 100, "RGB with alpha");
  FlImages.SetImage(b, i); i.Close;

  NEW(i); Porsche(i);
  NEW(b); FlButtons.OpenButton(b, 10, 361, 100, 100, "Pixmap");
  FlImages.SetImage(b, i); i.Close;

  n := 0; Sorceress;
  NEW(i); FlImages.OpenBitmap(i, bits, bitmapSide, bitmapSide);
  NEW(b); FlButtons.OpenButton(b, 10, 461, 100, 100, "Bitmap");
  b.SetLabelColor(Fl.Green);
  FlImages.SetImage(b, i); i.Close
END Drawings;

PROCEDURE Controls;
  VAR clock: FlValuators.Clock; ret: FlButtons.ReturnButton; b: FlButtons.Button;
    inner: Fl.Group; round: FlButtons.RoundButton; check: FlButtons.CheckButton; tx: Fl.Box;
BEGIN
  NEW(clock); FlValuators.OpenClock(clock, 360, 246, 120, 120, "");
  NEW(ret); FlButtons.OpenReturnButton(ret, 360, 376, 120, 30, "Return");
  ret.Deactivate;
  NEW(b); FlButtons.OpenButton(b, 360, 406, 30, 30, "@->|");
  b.SetLabelColor(Fl.Dark3);
  NEW(b); FlButtons.OpenButton(b, 390, 406, 30, 30, "@UpArrow");
  b.SetLabelColor(Fl.Dark3);
  NEW(b); FlButtons.OpenButton(b, 420, 406, 30, 30, "@DnArrow");
  b.SetLabelColor(Fl.Dark3);
  NEW(b); FlButtons.OpenButton(b, 450, 406, 30, 30, "@+");
  b.SetLabelColor(Fl.Dark3);
  NEW(b); FlButtons.OpenButton(b, 360, 441, 120, 30, "Hello, World");
  b.SetLabelFont(Fl.Bold + Fl.Italic);
  b.SetLabelType(Fl.ShadowLabel);
  b.SetBoxType(Fl.RoundUpBox);
  NEW(b); FlButtons.OpenButton(b, 360, 476, 120, 30, "Plastic");
  b.SetBoxType(Fl.PlasticUpBox);

  NEW(group); Fl.OpenGroup(group, 360, 511, 120, 40, "");
  group.SetBoxType(Fl.UpBox);
  NEW(inner); Fl.OpenGroup(inner, 365, 516, 110, 30, "");
  inner.SetBoxType(Fl.ThinUpFrame);
  NEW(round); FlButtons.OpenRoundButton(round, 365, 516, 40, 30, "rad");
  round.SetValue(TRUE);
  NEW(check); FlButtons.OpenCheckButton(check, 410, 516, 60, 30, "check");
  check.SetValue(TRUE);
  inner.End;
  group.End;
  group.Deactivate;

  NEW(tx); Fl.OpenBox(tx, 120, 508, 230, 50, "");
  SetLines(tx, "Background is not printed because|encapsulating group, which we are| printing, has not set the box type");
  tx.SetBoxType(Fl.ShadowBox);
  tx.SetLabelSize(12);
  tx.Hide
END Controls;

PROCEDURE Choices;
  VAR g: Fl.Group; b: Fl.Box; go: Go;
BEGIN
  NEW(w3); Fl.OpenWindowAt(w3, 2, 5, w2.W() - 10, 73, "");
  w3.SetBoxType(Fl.DownBox);
  NEW(g); Fl.OpenGroup(g, 0, 0, w3.W(), w3.H(), "");
  AddOperation(5, 4, imageSurface, "Fl_Image_Surface");
  AddOperation(170, 4, copy, "Fl_Copy_Surface");
  AddOperation(5, 17, printer, "Fl_Printer");
  AddOperation(170, 17, postScript, "Fl_PostScript_File_Device");
  AddOperation(5, 30, pdf, "Fl_PDF_File_Surface");
  AddOperation(170, 30, svg, "Fl_SVG_File_Surface");
  AddOperation(5, 43, capture, "fl_capture_window()");
  AddOperation(170, 43, mask, "Fl_Image_Surface::mask()");
  g.End;

  NEW(g); Fl.OpenGroup(g, 0, 0, w3.W(), w3.H(), "");
  NEW(b); Fl.OpenBox(b, 4, 55, 340, 16, "");
  b.SetBoxType(Fl.BorderBox); b.SetColor(Fl.Light3);
  AddTarget(5, 140, w2, "Decorated window");
  AddTarget(160, 100, w3, "Sub-window");
  AddTarget(275, 60, group, "Group");
  g.End;

  NEW(go); FlButtons.OpenButton(go, 380, (w3.H() - 25) DIV 2, 100, 25, "GO");
  w3.End
END Choices;

PROCEDURE Build;
  VAR c2: Fl.Group;
BEGIN
  NEW(w2); Fl.OpenWindow(w2, 500, 568, "Graphics test");
  NEW(c2); Fl.OpenGroup(c2, 3, 56, 494, 514, "");
  Drawings;
  Controls;
  c2.End;
  Choices;
  w2.End
END Build;

BEGIN
  Build;
  target := w2; operation := imageSurface;
  w2.ShowArgs;
  Fl.Run
END Device.
