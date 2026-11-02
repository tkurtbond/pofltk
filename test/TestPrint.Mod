MODULE TestPrint; (* FlPrint: files written and read back, the order of things, and what fails *)

(* No test here may break Cairo on a PostScript file: FLTK then uses the
   file after closing it (doc/fltk-issues.md, 101). *)

IMPORT Files, Fl, FlDraw, FlImages, FlPrint, Check, Probe;

CONST
  tries = 400;  (* of 0.05 s, waiting for a dialog; generous, for valgrind *)
  ps = "../build/TestPrint.ps";
  pdf = "../build/TestPrint.pdf";
  eps = "../build/TestPrint.eps";
  svg = "../build/TestPrint.svg";
  full = "/dev/full";
  nowhere = "/nonexistent/TestPrint.out";

TYPE
  (* Draws in Oberon, as a widget's Draw does on the screen. *)
  Picture = POINTER TO RECORD (Fl.BoxDesc) END;

  (* Waits for a dialog, notes its title and sends Escape; then fires once
     more, as TestDialogs' Answer does. *)
  Answer = POINTER TO RECORD (Fl.TimerDesc)
    title: ARRAY 64 OF CHAR;
    tries, seen: INTEGER;
    sent: BOOLEAN
  END;

VAR
  data: ARRAY 400000 OF CHAR;
  size, draws: INTEGER;
  win: Fl.Window;
  box: Fl.Box;
  picture: Picture;
  answer: Answer;
  noPDF: BOOLEAN;

PROCEDURE (p: Picture) Draw*;
BEGIN
  INC(draws);
  FlDraw.SetColor(Fl.Red); FlDraw.RectF(p.X(), p.Y(), p.W(), p.H())
END Draw;

PROCEDURE (a: Answer) Fire*;
  VAR ok: BOOLEAN;
BEGIN
  IF a.sent THEN (* only to wake the loop *)
  ELSIF ~Probe.Modal(a.title) THEN
    INC(a.tries); IF a.tries < tries THEN Fl.RepeatTimeout(a, 0.05D0) END
  ELSIF a.seen < 2 THEN  (* let it settle *)
    INC(a.seen); Fl.RepeatTimeout(a, 0.05D0)
  ELSE
    ok := Probe.ModalKey(Fl.KeyEscape, {}, 1BX);
    a.sent := TRUE; Fl.RepeatTimeout(a, 0.01D0)
  END
END Fire;

PROCEDURE Escape;
BEGIN NEW(answer); Fl.AddTimeout(answer, 0.05D0)
END Escape;

(* Reads name into data; its length, or -1 if it can't be read. *)
PROCEDURE Read(name: ARRAY OF CHAR): INTEGER;
  VAR f: Files.File; r: Files.Rider;
BEGIN
  size := -1;
  f := Files.Old(name);
  IF f # NIL THEN
    size := SHORT(Files.Length(f)); ASSERT(size <= LEN(data));
    Files.Set(r, f, 0); Files.ReadBytes(r, data, size); Files.Close(f)
  END;
  RETURN size
END Read;

(* TRUE if text is in data at i. *)
PROCEDURE At(text: ARRAY OF CHAR; i: INTEGER): BOOLEAN;
  VAR j: INTEGER;
BEGIN
  j := 0;
  WHILE (text[j] # 0X) & (i + j < size) & (data[i + j] = text[j]) DO INC(j) END;
  RETURN text[j] = 0X
END At;

PROCEDURE Has(text: ARRAY OF CHAR): BOOLEAN;
  VAR i: INTEGER;
BEGIN
  i := 0;
  WHILE (i < size) & ~At(text, i) DO INC(i) END;
  RETURN i < size
END Has;

(* TRUE if text is in s. *)
PROCEDURE Says(s-, text: ARRAY OF CHAR): BOOLEAN;
  VAR i, j: INTEGER;
BEGIN
  i := 0;
  REPEAT
    j := 0;
    WHILE (text[j] # 0X) & (s[i + j] = text[j]) DO INC(j) END;
    IF text[j] = 0X THEN RETURN TRUE END;
    INC(i)
  UNTIL s[i] = 0X;
  RETURN FALSE
END Says;

(* TRUE if there is a reason to give. *)
PROCEDURE Reason(): BOOLEAN;
  VAR s: ARRAY 256 OF CHAR;
BEGIN s := ""; FlPrint.Error(s); RETURN s[0] # 0X
END Reason;

PROCEDURE Draw;
  VAR dashes: ARRAY 2 OF INTEGER;
BEGIN
  FlDraw.SetColor(Fl.Blue); FlDraw.Rect(10, 10, 100, 50);
  FlDraw.Text("text", 20, 30);
  dashes[0] := 7; dashes[1] := 3;
  FlDraw.LineStyleDashes(FlDraw.Solid, 1, dashes);
  FlDraw.XYLine(10, 70, 100);
  FlDraw.LineStyle(FlDraw.Solid, 0)
END Draw;

(* So much that a file's buffer must be written before it is closed. *)
PROCEDURE DrawLots;
  VAR i: INTEGER;
BEGIN
  FOR i := 0 TO 20000 DO FlDraw.Line(i MOD 100, 0, 100, i MOD 97); FlDraw.Text("text", 20, i MOD 89) END
END DrawLots;

PROCEDURE TestPostScript;
  VAR f: FlPrint.PostScriptFile; w, h, x, y, l, t, r, b, plain: INTEGER;
BEGIN
  NEW(f); Check.Check(~f.IsOpen(), "a surface starts closed");
  Check.Check(FlPrint.OpenPostScript(f, ps, FlPrint.A4, FlPrint.Portrait), "OpenPostScript");
  Check.Check(f.IsOpen() & (FlPrint.openSurfaces = 1), "open, and counted");
  f.PrintableRect(w, h); f.Margins(l, t, r, b);
  Check.Check((w > 400) & (w < 595) & (h > 600) & (h < 842), "PrintableRect, A4 in points");
  Check.Check((l >= 0) & (l + w + r = 595) & (t + h + b = 842), "Margins and PrintableRect make the page");

  f.BeginPage;
  Draw;
  f.SetOrigin(30, 40); f.Origin(x, y);
  Check.Check((x = 30) & (y = 40), "SetOrigin, Origin");
  f.Translate(5, 5); f.Translate(5, 5);
  Draw;
  f.Untranslate; f.Untranslate;
  f.Origin(x, y); Check.Check((x = 30) & (y = 40), "Translate leaves the origin");
  f.SetOrigin(0, 0);
  f.EndPage;

  f.BeginPage;
  f.Scale(0.5D0, 0.5D0); f.PrintableRect(w, h);
  Check.Check((w > 800) & (h > 1200), "Scale widens what fits");
  f.Rotate(10.0D0); Draw;
  f.EndPage;
  f.BeginPage;
  f.PrintableRect(x, y);
  Check.Check((x < 595) & (y < 842), "a new page starts unscaled");
  f.EndPage;
  Check.Check(f.EndJob(), "EndJob: written");
  Check.Check(f.IsOpen(), "EndJob leaves it open");
  f.Close; f.Close;
  Check.Check(~f.IsOpen() & (FlPrint.openSurfaces = 0), "Close, twice");
  Check.Check(Read(ps) > 0, "the file exists");
  Check.Check(At("%!PS", 0), "PostScript");
  Check.Check(Has("%%Page: 3"), "of three pages");

  NEW(f);
  Check.Check(FlPrint.OpenPostScript(f, ps, FlPrint.Letter, FlPrint.Landscape), "Landscape");
  f.PrintableRect(w, h); Check.Check(w > h, "wider than high");
  f.BeginPage; f.EndPage; f.Close;
  Check.Check(Read(ps) > 0, "Close finishes the job");
  plain := size;

  NEW(f);
  Check.Check(FlPrint.OpenPostScript(f, ps, FlPrint.Letter, FlPrint.Landscape), "a widget on a page");
  draws := 0;
  f.BeginPage; f.DrawWidget(picture, 50, 50); f.DrawWidget(box, 50, 100); f.EndPage;
  Check.Check(draws = 1, "a widget's Draw runs");
  Check.Check(f.EndJob(), "and is written"); f.Close;
  Check.Check(Read(ps) > plain, "making the file bigger");

  NEW(f);
  Check.Check(FlPrint.OpenPostScript(f, ps, FlPrint.A4, FlPrint.Portrait), "closing halfway");
  f.BeginPage; f.Translate(1, 1); f.Translate(1, 1); Draw;
  f.Close;
  Check.Check(~f.IsOpen() & (Read(ps) > 0), "Close ends the page");
  Check.Check(At("%!PS", 0), "and the file is whole");

  NEW(f);
  Check.Check(FlPrint.OpenPostScript(f, ps, FlPrint.A4, FlPrint.Portrait + FlPrint.Reversed), "Reversed");
  Check.Check(f.EndJob(), "no pages at all");
  f.Close
END TestPostScript;

PROCEDURE TestPDF;
  VAR f: FlPrint.PDFFile; w, h: INTEGER;
BEGIN
  NEW(f);
  IF ~FlPrint.OpenPDF(f, pdf, FlPrint.A4, FlPrint.Portrait) THEN
    Check.Check(Reason(), "no PDF here, and why");
    Check.Skip("PDF needs Pango"); noPDF := TRUE
  ELSE
    Check.Check(FlPrint.openSurfaces = 1, "OpenPDF");
    f.PrintableRect(w, h);
    Check.Check((w > 400) & (w < 596) & (h > 600) & (h < 843), "PrintableRect");
    f.BeginPage; Draw; f.DrawWidget(box, 50, 100); f.EndPage;
    f.BeginPage; f.Scale(2.0D0, 2.0D0); f.Rotate(45.0D0); Draw; f.EndPage;
    Check.Check(f.EndJob(), "EndJob: written");
    f.Close; Check.Check(FlPrint.openSurfaces = 0, "Close");
    Check.Check(Read(pdf) > 0, "the file exists");
    Check.Check(At("%PDF", 0), "PDF");
    Check.Check(Has("/Count 2"), "of two pages")
  END
END TestPDF;

PROCEDURE TestEPS;
  VAR f: FlPrint.EPSFile; w, h: INTEGER;
BEGIN
  NEW(f);
  Check.Check(FlPrint.OpenEPS(f, eps, 200, 100, Fl.White), "OpenEPS");
  f.PrintableRect(w, h); Check.Check((w = 200) & (h = 100), "its size");
  f.Begin;
  Draw; f.Translate(5, 5); f.DrawWidget(box, 50, 20); f.Untranslate;
  f.End;
  f.Begin; Draw; f.End;  (* drawing again is drawing more *)
  Check.Check(f.Finish(), "Finish: written");
  f.Close; Check.Check(FlPrint.openSurfaces = 0, "Close");
  Check.Check(Read(eps) > 0, "the file exists");
  Check.Check(At("%!PS-Adobe-3.0 EPSF", 0), "EPS");
  Check.Check(Has("%%BoundingBox: "), "with a bounding box")
END TestEPS;

PROCEDURE TestSVG;
  VAR f: FlPrint.SVGFile; w, h: INTEGER;
BEGIN
  NEW(f);
  IF ~Fl.Has(Fl.Svg) THEN
    Check.Check(~FlPrint.OpenSVG(f, svg, 200, 100) & Reason(), "no SVG here, and why");
    Check.Skip("this FLTK has no SVG")
  ELSE
    Check.Check(FlPrint.OpenSVG(f, svg, 200, 100), "OpenSVG");
    f.PrintableRect(w, h); Check.Check((w = 200) & (h = 100), "its size");
    draws := 0;
    f.Begin; f.DrawWidget(picture, 0, 0); FlDraw.SetFont(Fl.TimesBold, 24); Draw; f.End;
    Check.Check(draws = 1, "a widget's Draw runs");
    Check.Check(f.Finish(), "Finish: written");
    f.Close; Check.Check(FlPrint.openSurfaces = 0, "Close");
    Check.Check(Read(svg) > 0, "the file exists");
    Check.Check(Has("<svg") & Has("</svg>"), "SVG");
    Check.Check(Has(">text<"), "with its text");
    Check.Check(Has('font-family="Times"') & Has('font-size="24"'), "in the font set");
    Check.Check(Has("stroke-dasharray:7.000,3.000"), "LineStyleDashes")
  END
END TestSVG;

(* The Print dialog's and FLTK's chooser's windows *)
PROCEDURE TestDialogs;
  VAR p: FlPrint.Printer; f: FlPrint.PDFFile; r, i: INTEGER;
BEGIN
  Fl.SetOption(Fl.OptionPrinterUsesGtk, FALSE); Fl.SetOption(Fl.OptionFnfcUsesGtk, FALSE);
  Fl.SetOption(Fl.OptionFnfcUsesZenity, FALSE); Fl.SetOption(Fl.OptionFnfcUsesKdialog, FALSE);

  FOR i := FlPrint.DialogPrinter TO FlPrint.PDFDefault DO FlPrint.SetPrinterText(i, "Text") END;
  FlPrint.SetPrinterText(FlPrint.DialogTitle, "Drucken");

  NEW(p); FlPrint.OpenPrinter(p);
  Check.Check(p.IsOpen() & (FlPrint.openSurfaces = 1), "OpenPrinter");
  Escape; r := p.BeginJob(1);
  Check.Check(r = FlPrint.JobCancelled, "BeginJob, cancelled");
  Check.Check(answer.title = "Drucken", "SetPrinterText");
  Escape; r := p.BeginJob(0);
  Check.Check(r = FlPrint.JobCancelled, "and again");
  p.Close; Check.Check(FlPrint.openSurfaces = 0, "Close");

  IF noPDF THEN Check.Skip("PDF needs Pango")
  ELSE
    NEW(f); Escape; r := FlPrint.OpenPDFChooser(f, "TestPrint.pdf");
    Check.Check((r = FlPrint.JobCancelled) & ~f.IsOpen(), "OpenPDFChooser, cancelled");
    Check.Check(FlPrint.openSurfaces = 0, "nothing opened")
  END
END TestDialogs;

(* Files that can't be written: FALSE, not a halt. *)
PROCEDURE TestFailing;
  VAR p: FlPrint.PostScriptFile; q: FlPrint.PDFFile; e: FlPrint.EPSFile; s: FlPrint.SVGFile;
    device: Files.File;
BEGIN
  NEW(p); Check.Check(~FlPrint.OpenPostScript(p, nowhere, FlPrint.A4, FlPrint.Portrait), "PostScript: no such directory");
  Check.Check(~p.IsOpen() & Reason(), "unopened, and why");
  Check.Check(FlPrint.OpenPostScript(p, ps, FlPrint.A4, FlPrint.Portrait), "it can be opened after that");
  p.Close;
  NEW(q); Check.Check(~FlPrint.OpenPDF(q, nowhere, FlPrint.A4, FlPrint.Portrait) & ~q.IsOpen() & Reason(), "PDF");
  NEW(e); Check.Check(~FlPrint.OpenEPS(e, nowhere, 20, 20, Fl.White) & ~e.IsOpen() & Reason(), "EPS");
  NEW(s); Check.Check(~FlPrint.OpenSVG(s, nowhere, 20, 20) & ~s.IsOpen() & Reason(), "SVG");
  Check.Check(FlPrint.openSurfaces = 0, "nothing opened");

  device := Files.Old(full);
  IF device = NIL THEN Check.Skip("no /dev/full")
  ELSE
    Files.Close(device);
    NEW(p); Check.Check(FlPrint.OpenPostScript(p, full, FlPrint.A4, FlPrint.Portrait), "a full disk, PostScript");
    p.BeginPage; DrawLots; p.EndPage;
    Check.Check(~p.EndJob() & Reason(), "EndJob says so");
    p.Close;

    IF noPDF THEN Check.Skip("PDF needs Pango")
    ELSE
      NEW(q); Check.Check(FlPrint.OpenPDF(q, full, FlPrint.A4, FlPrint.Portrait), "PDF");
      q.BeginPage; DrawLots; q.EndPage;
      Check.Check(~q.EndJob() & Reason(), "EndJob says so, with no alert");
      q.Close
    END;

    NEW(e); Check.Check(FlPrint.OpenEPS(e, full, 20, 20, Fl.White), "EPS");
    e.Begin; DrawLots; e.End;
    Check.Check(~e.Finish() & Reason(), "Finish says so");
    e.Close;

    IF Fl.Has(Fl.Svg) THEN
      NEW(s); Check.Check(FlPrint.OpenSVG(s, full, 20, 20), "SVG");
      s.Begin; DrawLots; s.End;
      Check.Check(~s.Finish() & Reason(), "Finish says so");
      s.Close
    END
  END;
  Check.Check(FlPrint.openSurfaces = 0, "all closed")
END TestFailing;

(* Surfaces nest, with FlImages' too. *)
PROCEDURE TestNesting;
  VAR p: FlPrint.PostScriptFile; e: FlPrint.EPSFile; s: FlImages.Surface; i: FlImages.Image;
BEGIN
  NEW(p); Check.Check(FlPrint.OpenPostScript(p, ps, FlPrint.A4, FlPrint.Portrait), "nesting: a page");
  NEW(e); Check.Check(FlPrint.OpenEPS(e, eps, 40, 40, Fl.White), "and a drawing");
  NEW(s); FlImages.OpenSurface(s, 4, 4);
  p.BeginPage;
    e.Begin;
      s.Begin; FlDraw.SetColor(Fl.Red); FlDraw.RectF(0, 0, 4, 4); s.End;
      Draw;
    e.End;
    Draw;
  p.EndPage;
  NEW(i); s.GetImage(i);
  Check.Check(i.IsOpen() & (i.W() = 4), "an image surface inside them works");
  i.Close; s.Close;
  s.Close;
  e.Close;
  Check.Check(p.EndJob(), "and the page is written"); p.Close;
  Check.Check(Read(eps) > 0, "the drawing is too");
  Check.Check(FlPrint.openSurfaces = 0, "both closed");

  NEW(s); FlImages.OpenSurface(s, 4, 4);
  NEW(e); Check.Check(FlPrint.OpenEPS(e, eps, 40, 40, Fl.White), "a drawing inside an image surface");
  s.Begin; e.Begin; Draw; e.End; s.End;
  e.Close; s.Close
END TestNesting;

(* What needs a window on the screen *)
PROCEDURE TestWindow;
  VAR e: FlPrint.EPSFile; bare: INTEGER;
BEGIN
  Check.Check((win.DecoratedW() = win.W()) & (win.DecoratedH() = win.H()), "DecoratedW, DecoratedH: a window not shown has no title bar");
  NEW(e); Check.Check(FlPrint.OpenEPS(e, eps, 200, 200, Fl.White), "a window not shown");
  e.Begin;
  e.DrawWidget(win, 0, 0); e.DrawDecoratedWindow(win, 0, 0); e.PrintWindowPart(win, 0, 0, 50, 50, 0, 0);
  e.End;
  Check.Check(e.Finish(), "draws nothing");
  e.Close;
  bare := Read(eps);

  win.Show; win.WaitForExpose;
  Check.Check(win.Shown(), "shown");
  Check.Check((win.DecoratedW() >= win.W()) & (win.DecoratedH() >= win.H()), "DecoratedW, DecoratedH, of one that is");
  NEW(e); Check.Check(FlPrint.OpenEPS(e, eps, 200, 200, Fl.White), "a window shown");
  e.Begin; e.DrawWidget(win, 0, 0); e.End;
  Check.Check(e.Finish(), "DrawWidget"); e.Close;
  Check.Check(Read(eps) > bare, "draws it");
  NEW(e); Check.Check(FlPrint.OpenEPS(e, eps, 200, 200, Fl.White), "PrintWindowPart");
  e.Begin; e.PrintWindowPart(win, 0, 0, 50, 50, 10, 10); e.End;
  Check.Check(e.Finish(), "PrintWindowPart runs"); e.Close;
  Check.Check(Read(eps) > bare, "and draws it");
  NEW(e); Check.Check(FlPrint.OpenEPS(e, eps, 200, 200, Fl.White), "DrawDecoratedWindow");
  e.Begin; e.DrawDecoratedWindow(win, 0, 0); e.End;
  Check.Check(e.Finish(), "DrawDecoratedWindow runs"); e.Close;
  Check.Check(Read(eps) > bare, "and draws it");
  win.Hide
END TestWindow;

(* FLTK built with --disable-print: nothing opens but a printer, and SVG. *)
PROCEDURE TestNoPrint;
  VAR p: FlPrint.Printer; f: FlPrint.PostScriptFile; q: FlPrint.PDFFile; e: FlPrint.EPSFile;
BEGIN
  NEW(f); Check.Check(~FlPrint.OpenPostScript(f, ps, FlPrint.A4, FlPrint.Portrait) & ~f.IsOpen() & Reason(), "no PostScript, and why");
  NEW(q); Check.Check(~FlPrint.OpenPDF(q, pdf, FlPrint.A4, FlPrint.Portrait) & ~q.IsOpen() & Reason(), "no PDF");
  Check.Check(FlPrint.OpenPDFChooser(q, "") = FlPrint.JobFailed, "no PDF chooser");
  NEW(e); Check.Check(~FlPrint.OpenEPS(e, eps, 20, 20, Fl.White) & ~e.IsOpen() & Reason(), "no EPS");
  FlPrint.SetPrinterText(FlPrint.DialogTitle, "Drucken");
  FlPrint.SetPrinterText(FlPrint.PDFDefault, "Text");
  NEW(p); FlPrint.OpenPrinter(p);
  Check.Check(p.BeginJob(1) = FlPrint.JobFailed, "a printer fails");
  p.Close;
  Check.Check(FlPrint.openSurfaces = 0, "nothing left open");
  Check.Skip("this FLTK can't print")
END TestNoPrint;

BEGIN
  NEW(win); Fl.OpenWindow(win, 120, 120, "TestPrint");
  NEW(box); Fl.OpenBox(box, 0, 0, 100, 40, "hello"); box.SetBoxType(Fl.UpBox);
  NEW(picture); Fl.OpenBox(picture, 0, 40, 100, 40, "");
  win.End;

  IF FlPrint.Available() THEN
    TestPostScript;
    TestPDF;
    TestEPS;
    TestSVG;
    TestDialogs;
    TestFailing;
    TestNesting;
    TestWindow
  ELSE
    TestNoPrint;
    TestSVG
  END;

  win.Delete;
  Check.Summary
END TestPrint.
