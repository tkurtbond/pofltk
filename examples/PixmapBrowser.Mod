MODULE PixmapBrowser; (* FLTK's test/pixmap_browser.cxx: shows an image file, and prints the window or saves it as SVG *)

(* The chooser's FilePicked hook shows each file as the user moves over it.
   FLTK's -8 asks for fewer colors, and does nothing here. *)

IMPORT Args, Out, Fl, FlButtons, FlDialogs, FlImages, FlPrint;

CONST
  images = "*.{bm,bmp,gif,ico,jpg,pbm,pgm,png,ppm,xbm,xpm}";
  imagesSvg = "*.{bm,bmp,gif,ico,jpg,pbm,pgm,png,ppm,xbm,xpm,svg,svgz}";

TYPE
  Redrawing = POINTER TO RECORD (Fl.TimerDesc) END;

VAR
  window: Fl.DoubleWindow;
  box: Fl.Box;
  load, print, svg: FlButtons.Button;
  img: FlImages.Shared;
  name, path: ARRAY 1024 OF CHAR;
  animate: BOOLEAN;
  redrawing: Redrawing;
  i: INTEGER;

(* An animated image draws its next frame when it is next drawn. *)
PROCEDURE (t: Redrawing) Fire*;
BEGIN
  Fl.Redraw;
  IF Fl.WindowShown() THEN Fl.RepeatTimeout(t, 0.1D0) END
END Fire;

PROCEDURE LoadFile(n-: ARRAY OF CHAR);
BEGIN
  FlImages.SetImage(box, NIL);
  IF img # NIL THEN img.Close; img := NIL END;
  IF FlDialogs.FilenameIsDir(n) THEN
    box.SetLabel("@fileopen");  (* show a generic folder *)
    box.SetLabelSize(64);
    box.SetLabelColor(Fl.Light2);
    box.Redraw;
    RETURN
  END;
  NEW(img);
  IF FlImages.GetShared(img, n, 0, 0) THEN
    box.SetLabelSize(14);
    box.SetLabelColor(Fl.ForegroundColor);
    FlImages.SetImage(box, img);
    img.Scale(box.W(), box.H(), TRUE, FALSE);
    box.SetLabel("")
  ELSE
    img := NIL;
    box.SetLabel("@filenew");  (* an empty document *)
    box.SetLabelSize(64);
    box.SetLabelColor(Fl.Light2)
  END;
  box.Redraw
END LoadFile;

PROCEDURE FileCb(n-: ARRAY OF CHAR);
BEGIN
  IF n # name THEN
    LoadFile(n);
    COPY(n, name);
    window.SetLabel(name)
  END
END FileCb;

PROCEDURE ButtonCb(w: Fl.Widget);
  VAR chosen: BOOLEAN;
BEGIN
  path := name;
  FlDialogs.SetFilePicked(FileCb);
  IF Fl.Has(Fl.Svg) THEN
    chosen := FlDialogs.ChooseFile("Image file?", imagesSvg, path, FALSE)
  ELSE
    chosen := FlDialogs.ChooseFile("Image file?", images, path, FALSE)
  END;
  IF chosen THEN Out.String(path) ELSE Out.String("(null)") END;
  Out.Ln;
  FlDialogs.SetFilePicked(NIL)
END ButtonCb;

(* Says why the last thing failed. *)
PROCEDURE Failed;
  VAR message: ARRAY 256 OF CHAR;
BEGIN
  FlPrint.Error(message);
  IF message[0] = 0X THEN message := "It wasn't written." END;
  FlDialogs.Alert(message)
END Failed;

PROCEDURE PrintCb(w: Fl.Widget);
  VAR p: FlPrint.Printer; width, height: INTEGER; fw, fh: LONGREAL;
BEGIN
  NEW(p); FlPrint.OpenPrinter(p);
  IF p.BeginJob(1) = FlPrint.JobOk THEN
    p.BeginPage;
    p.PrintableRect(width, height);
    fw := window.DecoratedW() / width;
    fh := window.DecoratedH() / height;
    IF fh > fw THEN fw := fh END;
    p.Scale(1 / fw, 1 / fw);
    p.DrawDecoratedWindow(window, 0, 0);
    p.EndPage;
    IF ~p.EndJob() THEN Failed END
  END;
  p.Close
END PrintCb;

PROCEDURE SvgCb(w: Fl.Widget);
  VAR c: FlDialogs.NativeFileChooser; f: FlPrint.SVGFile; good: BOOLEAN;
BEGIN
  NEW(c); FlDialogs.OpenNativeFileChooser(c, FlDialogs.BrowseSaveFile);
  c.SetTitle("Pick a .svg file");
  c.SetFilter("*.svg");
  c.SetOptions(FlDialogs.SaveAsConfirm + FlDialogs.UseFilterExt);
  IF c.Show() = FlDialogs.Chosen THEN
    c.FileName(0, path);
    NEW(f);
    good := FlPrint.OpenSVG(f, path, window.DecoratedW(), window.DecoratedH());
    IF good THEN
      f.Begin; f.DrawDecoratedWindow(window, 0, 0); f.End;
      good := f.Finish();
      f.Close
    END;
    IF ~good THEN Failed END
  END;
  c.Close
END SvgCb;

(* -a animates GIFs. *)
PROCEDURE Arg(i: INTEGER): INTEGER;
  VAR a: ARRAY 256 OF CHAR;
BEGIN
  Args.Get(i, a);
  IF a = "-a" THEN animate := TRUE; RETURN 1 END;
  IF a = "-8" THEN RETURN 1 END;
  RETURN 0
END Arg;

BEGIN
  animate := FALSE;
  IF ~Fl.ParseArgs(Arg, i) THEN i := Args.argc END;
  IF animate THEN FlImages.SetAnimateGIFs(TRUE) END;

  NEW(window); Fl.OpenDoubleWindow(window, 400, 450, "");
  NEW(box); Fl.OpenBox(box, 10, 45, 380, 380, "");
  box.SetBoxType(Fl.ThinDownBox);
  box.SetAlign(Fl.AlignInside + Fl.AlignCenter + Fl.AlignClip);
  NEW(load); FlButtons.OpenButton(load, 150, 5, 100, 30, "load");
  load.action := ButtonCb;
  IF i < Args.argc THEN Args.Get(i, path); LoadFile(path) END;
  window.SetResizable(box);
  NEW(print); FlButtons.OpenButton(print, 300, 425, 50, 25, "Print");
  print.action := PrintCb;
  NEW(svg); FlButtons.OpenButton(svg, 190, 425, 100, 25, "save as SVG");
  svg.action := SvgCb;
  window.End;

  window.ShowArgs;
  IF animate THEN NEW(redrawing); Fl.AddTimeout(redrawing, 0.1D0) END;
  Fl.Run
END PixmapBrowser.
