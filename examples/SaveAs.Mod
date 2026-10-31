MODULE SaveAs; (* a drawing, saved as PostScript, EPS, PDF or SVG *)

(* One procedure draws the picture, in the window and in each file: what
   FlDraw draws goes to the surface begun. A page is a job with one page,
   A4, with the picture in its middle, scaled down to fit if it must be;
   EPS and SVG are the picture's own size. A file that can't be written
   isn't the program's fault, so it says so and carries on. *)

IMPORT Fl, FlButtons, FlDialogs, FlDraw, FlPrint;

CONST
  width = 400; height = 300;
  postScript = 0; eps = 1; pdf = 2; svg = 3;

TYPE
  Picture = POINTER TO RECORD (Fl.BoxDesc) END;
  Save = POINTER TO RECORD (FlButtons.ButtonDesc) format: INTEGER END;

VAR
  window: Fl.DoubleWindow;
  picture: Picture;

(* The picture, with its top left at x, y. *)
PROCEDURE Scene(x, y: INTEGER);
  VAR i: INTEGER;
BEGIN
  FlDraw.SetColor(Fl.RGB(135, 206, 235)); FlDraw.RectF(x, y, width, height);
  FlDraw.SetColor(Fl.Yellow); FlDraw.Pie(x + 300, y + 30, 60, 60, 0, 360);
  FlDraw.SetColor(Fl.DarkYellow);
  FlDraw.LineStyle(FlDraw.Solid, 3);
  FOR i := 0 TO 7 DO
    FlDraw.PushMatrix;
    FlDraw.Translate(x + 330, y + 60);
    FlDraw.Rotate(i * 45);
    FlDraw.BeginLine;
    FlDraw.Vertex(40, 0); FlDraw.Vertex(55, 0);
    FlDraw.EndLine;
    FlDraw.PopMatrix
  END;

  FlDraw.SetColor(Fl.DarkGreen);
  FlDraw.BeginPolygon;
  FlDraw.Curve(x, y + 220, x + 130, y + 150, x + 270, y + 280, x + width, y + 200);
  FlDraw.Vertex(x + width, y + height);
  FlDraw.Vertex(x, y + height);
  FlDraw.EndPolygon;

  FlDraw.SetColor(Fl.Red); FlDraw.RectF(x + 80, y + 150, 100, 70);
  FlDraw.SetColor(Fl.DarkRed); FlDraw.Polygon3(x + 70, y + 150, x + 130, y + 100, x + 190, y + 150);
  FlDraw.SetColor(Fl.White); FlDraw.RectF(x + 95, y + 165, 25, 25);
  FlDraw.SetColor(Fl.Black);
  FlDraw.LineStyle(FlDraw.Solid, 1);
  FlDraw.Rect(x + 95, y + 165, 25, 25);
  FlDraw.Line(x + 107, y + 165, x + 107, y + 190);
  FlDraw.Line(x + 95, y + 177, x + 120, y + 177);

  FlDraw.LineStyle(FlDraw.Dash + FlDraw.CapRound, 2);
  FlDraw.XYLine(x + 20, y + 280, x + width - 20);
  FlDraw.LineStyle(FlDraw.Solid, 0);

  FlDraw.SetFont(Fl.TimesBold, 24);
  FlDraw.Text("Drawn by Oberon", x + 20, y + 40)
END Scene;

PROCEDURE (p: Picture) Draw*;
BEGIN Scene(p.X(), p.Y())
END Draw;

(* One page, with the picture in its middle. *)
PROCEDURE Page(d: FlPrint.PagedDevice);
  VAR w, h: INTEGER; s, t: LONGREAL;
BEGIN
  d.BeginPage;
  d.PrintableRect(w, h);
  s := 1; t := w / width;
  IF t < s THEN s := t END;
  t := h / height;
  IF t < s THEN s := t END;
  d.Scale(s, s);
  d.PrintableRect(w, h);
  d.SetOrigin(w DIV 2, h DIV 2);
  Scene(-width DIV 2, -height DIV 2);
  d.EndPage
END Page;

(* One drawing. *)
PROCEDURE Drawing(s: FlPrint.FileSurface): BOOLEAN;
BEGIN
  s.Begin; Scene(0, 0); s.End;
  RETURN s.Finish()
END Drawing;

(* Whether the file was written. *)
PROCEDURE Write(format: INTEGER; path-: ARRAY OF CHAR): BOOLEAN;
  VAR ps: FlPrint.PostScriptFile; pd: FlPrint.PDFFile;
    e: FlPrint.EPSFile; s: FlPrint.SVGFile; good: BOOLEAN;
BEGIN
  good := FALSE;
  CASE format OF
  postScript:
    NEW(ps);
    IF FlPrint.OpenPostScript(ps, path, FlPrint.A4, FlPrint.Portrait) THEN
      Page(ps); good := ps.EndJob(); ps.Close
    END
  | eps:
    NEW(e);
    IF FlPrint.OpenEPS(e, path, width, height, Fl.White) THEN
      good := Drawing(e); e.Close
    END
  | pdf:
    NEW(pd);
    IF FlPrint.OpenPDF(pd, path, FlPrint.A4, FlPrint.Portrait) THEN
      Page(pd); good := pd.EndJob(); pd.Close
    END
  | svg:
    NEW(s);
    IF FlPrint.OpenSVG(s, path, width, height) THEN
      good := Drawing(s); s.Close
    END
  END;
  RETURN good
END Write;

PROCEDURE (s: Save) Callback*;
  VAR c: FlDialogs.NativeFileChooser; path, message: ARRAY 1024 OF CHAR;
BEGIN
  NEW(c); FlDialogs.OpenNativeFileChooser(c, FlDialogs.BrowseSaveFile);
  c.SetOptions(FlDialogs.SaveAsConfirm + FlDialogs.UseFilterExt);
  CASE s.format OF
    postScript: c.SetTitle("Save as PostScript"); c.SetFilter("*.ps")
  | eps: c.SetTitle("Save as EPS"); c.SetFilter("*.eps")
  | pdf: c.SetTitle("Save as PDF"); c.SetFilter("*.pdf")
  | svg: c.SetTitle("Save as SVG"); c.SetFilter("*.svg")
  END;
  IF c.Show() = FlDialogs.Chosen THEN
    c.FileName(0, path);
    IF ~Write(s.format, path) THEN
      FlPrint.Error(message);
      IF message[0] = 0X THEN message := "It wasn't written." END;
      FlDialogs.Alert(message)
    END
  END;
  c.Close
END Callback;

PROCEDURE AddSave(x, format: INTEGER; label-: ARRAY OF CHAR);
  VAR s: Save;
BEGIN
  NEW(s); s.format := format;
  FlButtons.OpenButton(s, x, height + 20, 90, 30, label)
END AddSave;

BEGIN
  NEW(window); Fl.OpenDoubleWindow(window, width + 20, height + 60, "SaveAs");
  NEW(picture); Fl.OpenBox(picture, 10, 10, width, height, "");
  AddSave(10, postScript, "PostScript");
  AddSave(113, eps, "EPS");
  AddSave(217, pdf, "PDF");
  AddSave(320, svg, "SVG");
  window.End;
  window.Show;
  Fl.Run
END SaveAs.
