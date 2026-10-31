MODULE FileChooser; (* FLTK's test/file_chooser.cxx: every way of asking a file chooser for files *)

(* FileChooser [filter]

   The button by Filter shows the chooser; its callback, and the files
   it was left with, are listed. The filter is patterns, or names with
   a pattern in round brackets, separated by tabs.

   The chooser previews PDF and PostScript with Ghostscript, if it is
   installed, through image handlers; they leave .preview.ppm and
   .preview.ps in the home directory, as FLTK's program does.

   FLTK's program writes its log to an Fl_Terminal, which isn't bound
   yet (PLAN.md, Phase 18): this one's is a browser. *)

IMPORT Args, Strings, Fl, FlBrowsers, FlButtons, FlDialogs, FlImages, FlInputs, FlMenus, Pipe;

CONST
  height = 120;  (* of the log *)

TYPE
  Chooser = POINTER TO RECORD (FlDialogs.FileChooserDesc) END;
  Show = POINTER TO RECORD (FlButtons.ButtonDesc) END;
  Toggle = POINTER TO RECORD (FlButtons.LightButtonDesc) what: SET END;
  Extra = POINTER TO RECORD (FlMenus.ChoiceDesc) END;
  Close = POINTER TO RECORD (FlButtons.ButtonDesc) END;

VAR
  fc: Chooser;
  win: Fl.DoubleWindow;
  tty: FlBrowsers.Browser;
  filter: FlInputs.Input;
  files: FlBrowsers.FileBrowser;
  encodings: Fl.Group;        (* the extra widgets, kept once made *)
  version: FlButtons.CheckButton;
  preview: FlImages.Image;    (* the last the handlers made *)

PROCEDURE Log(prefix-, s-: ARRAY OF CHAR);
  VAR line: ARRAY 2200 OF CHAR;
BEGIN
  COPY(prefix, line); Strings.Append(s, line);
  tty.Add(line);
  tty.SetBottomLine(tty.Count())
END Log;

(* Appends s to cmd, in quotes the shell keeps it in. *)
PROCEDURE Quote(s-: ARRAY OF CHAR; VAR cmd: ARRAY OF CHAR);
  VAR i: INTEGER; c: ARRAY 2 OF CHAR;
BEGIN
  Strings.Append("'", cmd);
  i := 0; c[1] := 0X;
  WHILE s[i] # 0X DO
    IF s[i] = "'" THEN Strings.Append("'\''", cmd)
    ELSE c[0] := s[i]; Strings.Append(c, cmd)
    END;
    INC(i)
  END;
  Strings.Append("'", cmd)
END Quote;

(* Runs cmd; whether it succeeded. *)
PROCEDURE Run(cmd-: ARRAY OF CHAR): BOOLEAN;
  VAR p: Pipe.Pipe;
BEGIN
  NEW(p);
  RETURN Pipe.Open(p, cmd) & (p.Close() = 0)
END Run;

(* Sets s to the file name in the home directory. *)
PROCEDURE HomeFile(name-: ARRAY OF CHAR; VAR s: ARRAY OF CHAR);
BEGIN
  Args.GetEnv("HOME", s);
  Strings.Append(name, s)
END HomeFile;

(* The image of file name that Ghostscript draws, with options before the
   name on its command line. *)
PROCEDURE Ghostscript(name-, options-: ARRAY OF CHAR): FlImages.Image;
  VAR ppm: ARRAY 2048 OF CHAR; cmd: ARRAY 8192 OF CHAR;
BEGIN
  HomeFile("/.preview.ppm", ppm);
  cmd := "gs -r100 -dFIXED -sDEVICE=ppmraw -dQUIET -dNOPAUSE -dBATCH -sstdout=%stderr -sOUTPUTFILE=";
  Quote(ppm, cmd);
  Strings.Append(options, cmd); Strings.Append(" ", cmd);
  Quote(name, cmd);
  Strings.Append(" 2>/dev/null", cmd);
  IF ~Run(cmd) THEN RETURN NIL END;
  IF preview # NIL THEN preview.Close END;
  NEW(preview);
  IF FlImages.Load(preview, ppm) THEN RETURN preview END;
  preview := NIL;
  RETURN NIL
END Ghostscript;

PROCEDURE PDFCheck(name-, header-: ARRAY OF CHAR; n: INTEGER): FlImages.Image;
BEGIN
  IF (n < 4) OR (header[0] # "%") OR (header[1] # "P") OR (header[2] # "D") OR (header[3] # "F") THEN
    RETURN NIL
  END;
  RETURN Ghostscript(name, " -dFirstPage=1 -dLastPage=1")
END PDFCheck;

(* PostScript has no page numbers for Ghostscript to go by, so structured
   PostScript is cut before its second page. *)
PROCEDURE PSCheck(name-, header-: ARRAY OF CHAR; n: INTEGER): FlImages.Image;
  VAR ps: ARRAY 2048 OF CHAR; cmd: ARRAY 8192 OF CHAR;
BEGIN
  IF (n < 2) OR (header[0] # "%") OR (header[1] # "!") THEN RETURN NIL END;
  HomeFile("/.preview.ps", ps);
  IF (n >= 4) & (header[2] = "P") & (header[3] = "S") & (name # ps) THEN
    cmd := "awk '/^%%Page:/ { if (++p > 1) exit } { print }' ";
    Quote(name, cmd);
    Strings.Append(" > ", cmd);
    Quote(ps, cmd);
    IF Run(cmd) THEN RETURN Ghostscript(ps, "") END
  END;
  RETURN Ghostscript(name, "")
END PSCheck;

(* Sets s to n's digits. *)
PROCEDURE Digits(n: INTEGER; VAR s: ARRAY OF CHAR);
  VAR r: ARRAY 2 OF CHAR;
BEGIN
  IF n < 10 THEN s[0] := 0X ELSE Digits(n DIV 10, s) END;
  r[0] := CHR(ORD("0") + n MOD 10); r[1] := 0X;
  Strings.Append(r, s)
END Digits;

PROCEDURE (c: Chooser) Callback*;
  VAR s: ARRAY 2048 OF CHAR;
BEGIN
  Log("fc_callback", "");
  IF ~c.Value(s) THEN s := "(null)" END;
  Log("    filename = ", s)
END Callback;

PROCEDURE (b: Show) Callback*;
  VAR
    s, relative: ARRAY 2048 OF CHAR; line: ARRAY 2100 OF CHAR;
    number: ARRAY 16 OF CHAR; i, count: INTEGER; ok: BOOLEAN;
BEGIN
  filter.Value(s);
  IF s # "" THEN fc.SetFilter(s) END;
  fc.Show;
  WHILE fc.Visible() DO Fl.Wait(0.1D0) END;
  count := fc.Count();
  IF count > 0 THEN
    files.Clear;
    i := 1;
    WHILE (i <= count) & fc.ValueAt(i, s) DO
      ok := FlDialogs.FilenameRelative(s, relative);
      Digits(i, line); Strings.Append("/", line);
      Digits(count, number); Strings.Append(number, line);
      Strings.Append(") Picked: '", line);
      Log(line, s);
      Log("     Relative: ", relative);
      FlImages.AddFile(files, relative, FlImages.FindFileIcon(s, FlImages.IconPlain));
      INC(i)
    END;
    files.Redraw
  END
END Callback;

PROCEDURE (b: Toggle) Callback*;
BEGIN fc.SetType(fc.Type() / b.what)
END Callback;

PROCEDURE (m: Extra) Callback*;
  VAR ch: FlMenus.Choice; i: INTEGER; old: Fl.Widget;
BEGIN
  IF m.Value() = 0 THEN old := fc.SetExtra(NIL)
  ELSIF m.Value() = 1 THEN
    IF encodings = NIL THEN
      NEW(encodings); Fl.OpenGroup(encodings, 0, 0, 254, 30, "");
      NEW(ch); FlMenus.OpenChoice(ch, 152, 2, 100, 25, "Choose Encoding:");
      i := ch.Add("ASCII", 0, {}, NIL, {});
      i := ch.Add("Koi8-r", 0, {}, NIL, {});
      i := ch.Add("win1251", 0, {}, NIL, {});
      i := ch.Add("Utf-8", 0, {}, NIL, {});
      encodings.End
    END;
    old := fc.SetExtra(encodings)
  ELSE
    IF version = NIL THEN
      NEW(version); FlButtons.OpenCheckButton(version, 5, 0, 200, 25, "Save binary 1.0 version")
    END;
    old := fc.SetExtra(version)
  END
END Callback;

PROCEDURE (b: Close) Callback*;
BEGIN win.Hide
END Callback;

PROCEDURE Light(x, w: INTEGER; label-: ARRAY OF CHAR; what: SET);
  VAR b: Toggle;
BEGIN
  NEW(b); FlButtons.OpenLightButton(b, x, 45, w, 25, label);
  b.what := what
END Light;

PROCEDURE Build;
  VAR
    grp: Fl.Group; show: Show; close: Close; extra: Extra; invis: Fl.Box;
    icon: FlImages.FileIcon; s: ARRAY 256 OF CHAR; i, argn, n: INTEGER;
BEGIN
  FlImages.LoadSystemIcons;
  NEW(fc); FlDialogs.OpenFileChooser(fc, ".", "*", FlDialogs.ChooserSingle, "Fl_File_Chooser Test");
  FlImages.AddHandler(PDFCheck);
  FlImages.AddHandler(PSCheck);

  NEW(win); Fl.OpenDoubleWindow(win, 400, 215 + height, "File Chooser Test");
  NEW(tty); FlBrowsers.OpenBrowser(tty, 0, 215, 400, height, "");

  (* limits resizing to the filter *)
  NEW(grp); Fl.OpenGroup(grp, 0, 10, 400, 25, "");
  NEW(filter); FlInputs.OpenInput(filter, 50, 10, 315, 25, "Filter:");
  argn := 1;
  WHILE argn < Args.argc DO
    n := Fl.Arg(argn);
    IF n = 0 THEN Args.Get(argn, s); filter.SetValue(s); argn := Args.argc
    ELSE INC(argn, n)
    END
  END;
  filter.Value(s);
  IF s = "" THEN
    s := "PDF Files (*.pdf)|PostScript Files (*.ps)|Image Files (*.{bmp,gif,jpg,png})|C/C++ Source Files (*.{c,C,cc,cpp,cxx})";
    FOR i := 0 TO Strings.Length(s) - 1 DO
      IF s[i] = "|" THEN s[i] := 09X END
    END;
    filter.SetValue(s)
  END;
  NEW(show); FlButtons.OpenButton(show, 365, 10, 25, 25, "");
  show.SetTooltip("Click to open file browser..");
  icon := FlImages.FindFileIcon(".", FlImages.IconDirectory);
  IF icon # NIL THEN show.SetLabelColor(Fl.Yellow); icon.Label(show)
  ELSE show.SetLabel("..")
  END;
  grp.End; grp.SetResizable(filter);

  (* keeps the light buttons from resizing *)
  NEW(grp); Fl.OpenGroup(grp, 0, 45, 400, 55, "");
  Light(50, 80, "MULTI", FlDialogs.ChooserMulti);
  Light(140, 90, "CREATE", FlDialogs.ChooserCreate);
  Light(240, 115, "DIRECTORY", FlDialogs.ChooserDirectory);
  NEW(extra); FlMenus.OpenChoice(extra, 150, 75, 150, 25, "Extra Group:");
  i := extra.Add("none", 0, {}, NIL, {});
  i := extra.Add("encodings group", 0, {}, NIL, {});
  i := extra.Add("check button", 0, {}, NIL, {});
  IF extra.SetValue(0) THEN END;
  grp.End; grp.SetResizable(NIL);

  NEW(files); FlBrowsers.OpenFileBrowser(files, 50, 105, 340, 75, "Files:");
  files.SetAlign(Fl.AlignLeft);

  (* keeps Close at the right edge, its own size *)
  NEW(grp); Fl.OpenGroup(grp, 0, 185, 400, 25, "");
  NEW(invis); Fl.OpenBox(invis, 100, 185, 1, 1, "");
  invis.SetBoxType(Fl.NoBox);
  NEW(close); FlButtons.OpenButton(close, 310, 185, 80, 25, "Close");
  grp.SetResizable(invis);
  grp.End;

  win.SetResizable(files);
  win.End
END Build;

BEGIN
  Build;
  win.ShowArgs;
  Fl.Run
END FileChooser.
