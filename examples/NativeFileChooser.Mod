MODULE NativeFileChooser; (* FLTK's test/native-filechooser.cxx in Oberon-2 *)

(* The native file chooser: the buttons ask for a file, with the filter
   and the file given above, or a directory, starting from that file;
   the terminal shows what was chosen. A first argument not starting
   with "-" is the file to start with.

   FLTK's program shows its window with the arguments after that file,
   with the file in place of the program's name, which is only the
   window's class. This port takes the file as its own option
   (Fl.ParseArgs), which leaves FLTK's options after it to FLTK as
   before. *)

IMPORT Args, Err, Fl, FlButtons, FlDialogs, FlHelp, FlImages, FlInputs, FlTerminal;

CONST
  TerminalHeight = 120;
  Tab = "&lt;Tab&gt;";
  CtrlI = "<font color=#55f>&lt;Ctrl-I&gt;</font>";

VAR
  win: Fl.Window;
  filename: FlInputs.Input;
  filter: FlInputs.MultilineInput;
  tty: FlTerminal.Terminal;
  view: FlHelp.HelpView;
  but, butdir: FlButtons.Button;
  file: ARRAY 1024 OF CHAR;
  s: ARRAY 4096 OF CHAR;
  i, x, y: INTEGER;

(* s with each "|" a line feed, and each "^" a tab *)
PROCEDURE Lines(VAR s: ARRAY OF CHAR);
VAR i: INTEGER;
BEGIN
  i := 0;
  WHILE s[i] # 0X DO
    IF s[i] = "|" THEN s[i] := 0AX ELSIF s[i] = "^" THEN s[i] := 09X END;
    INC(i)
  END
END Lines;

(* Appends s to t. *)
PROCEDURE Cat(s-: ARRAY OF CHAR; VAR t: ARRAY OF CHAR);
VAR i, j: INTEGER;
BEGIN
  i := 0; WHILE t[i] # 0X DO INC(i) END;
  j := 0; WHILE s[j] # 0X DO t[i] := s[j]; INC(i); INC(j) END;
  t[i] := 0X
END Cat;

(* Argument 1, if it isn't an option, is the file to start with. *)
PROCEDURE FileArg(i: INTEGER): INTEGER;
VAR s: ARRAY 1024 OF CHAR;
BEGIN
  IF i = 1 THEN
    Args.Get(1, s);
    IF s[0] # "-" THEN file := s; RETURN 1 END
  END;
  RETURN 0
END FileArg;

(* Shows c and reports what it gives: what, "filename" or "dirname". *)
PROCEDURE Pick(c: FlDialogs.NativeFileChooser; what-: ARRAY OF CHAR);
VAR s, t: ARRAY 2048 OF CHAR;
BEGIN
  CASE c.Show() OF
  | FlDialogs.Failed:
    c.ErrorMessage(t); s := "ERROR: "; Cat(t, s); Cat("|", s); Lines(s); tty.Append(s)
  | FlDialogs.Cancelled:
    s := "*** CANCEL|"; Lines(s); tty.Append(s); FlDialogs.Beep(FlDialogs.BeepDefault)
  | FlDialogs.Chosen:
    (* FLTK's filename() gives "", not NULL, with nothing chosen *)
    IF c.Count() > 0 THEN c.FileName(0, t) ELSE t := "" END;
    filename.SetValue(t);
    COPY(what, s); Cat("='", s); Cat(t, s); Cat("'|", s); Lines(s); tty.Append(s)
  END;
  c.Close
END Pick;

PROCEDURE PickFile(w: Fl.Widget);
VAR c: FlDialogs.NativeFileChooser; s: ARRAY 2048 OF CHAR;
BEGIN
  NEW(c); FlDialogs.OpenNativeFileChooser(c, FlDialogs.BrowseFile);
  c.SetTitle("Pick a file");
  filter.Value(s); c.SetFilter(s);
  filename.Value(s); c.SetPresetFile(s);
  Pick(c, "filename")
END PickFile;

PROCEDURE PickDir(w: Fl.Widget);
VAR c: FlDialogs.NativeFileChooser; s: ARRAY 2048 OF CHAR;
BEGIN
  NEW(c); FlDialogs.OpenNativeFileChooser(c, FlDialogs.BrowseDirectory);
  c.SetTitle("Pick a Directory");
  filename.Value(s); c.SetDirectory(s);
  Pick(c, "dirname")
END PickDir;

BEGIN
  FlImages.RegisterImages;
  FlImages.LoadSystemIcons;

  file := "";
  IF ~Fl.ParseArgs(FileArg, i) OR (i < Args.argc) THEN
    (* as FLTK's Fl::args(argc, argv) does *)
    Fl.ArgsHelp(s); Err.String("options are:"); Err.Ln; Err.String(s); Err.Ln
  END;

  NEW(win); Fl.OpenWindow(win, 640, 400 + TerminalHeight, "Native File Chooser Test");
  win.SizeRange(win.W(), win.H(), 0, 0);
  NEW(tty); FlTerminal.OpenTerminal(tty, 0, 400, win.W(), TerminalHeight, "");

  x := 80; y := 10;
  NEW(filename); FlInputs.OpenInput(filename, x, y, win.W() - 80 - 10, 25, "Filename");
  IF file # "" THEN filename.SetValue(file) ELSE filename.SetValue(".") END;
  filename.SetTooltip("Default filename");

  INC(y, filename.H() + 10);
  NEW(filter); FlInputs.OpenMultilineInput(filter, x, y, filename.W(), 100, "Filter");
  s := "Text^*.txt|C Files^*.{cxx,h,c,cpp}|Tars^*.{tar,tar.gz}|Apps^*.app"; Lines(s);
  filter.SetValue(s);
  s := "Filter to be used for browser.|An empty string may be used.|"; Lines(s);
  filter.SetTooltip(s);

  INC(y, filter.H() + 10);
  NEW(view); FlHelp.OpenHelpView(view, x, y, filename.W(), 200, "");
  view.SetBoxType(Fl.FlatBox);
  view.SetColor(win.Color());
  view.SetTextFont(Fl.Helvetica);
  view.SetTextSize(10);
  s := "The Filter can be one or more filter patterns, one per line.|";
  Cat("Patterns can be:<ul>|", s);
  Cat('  <li>A single wildcard (e.g. <tt>"*.txt"</tt>)</li>|', s);
  Cat('  <li>Multiple wildcards (e.g. <tt>"*.{cxx,h,H}"</tt>)</li>|', s);
  Cat("  <li>A descriptive name followed by a ", s); Cat(Tab, s);
  Cat(' and a wildcard (e.g. <tt>"Text Files', s); Cat(Tab, s); Cat('*.txt"</tt>)</li>|', s);
  Cat("</ul>|", s);
  Cat('In the above "Filter" field, you can use <b><font color=#55f face=Courier>Ctrl-I</font></b> to enter ', s);
  Cat(Tab, s); Cat(" characters as needed.<br>|", s);
  Cat("Example:<pre>||", s);
  Cat("    Text", s); Cat(CtrlI, s); Cat("*.txt|", s);
  Cat("    C Files", s); Cat(CtrlI, s); Cat("*.{cxx,h,c,cpp}|", s);
  Cat("    Tars", s); Cat(CtrlI, s); Cat("*.{tar,tar.gz}|", s);
  Cat("    Apps", s); Cat(CtrlI, s); Cat("*.app|", s);
  Cat("</pre>|", s);
  Lines(s);
  view.SetValue(s);

  NEW(but); FlButtons.OpenButton(but, win.W() - x - 10, win.H() - TerminalHeight - 25 - 10, 80, 25, "Pick File");
  but.action := PickFile;
  NEW(butdir); FlButtons.OpenButton(butdir, but.X() - x - 10, win.H() - TerminalHeight - 25 - 10, 80, 25, "Pick Dir");
  butdir.action := PickDir;

  win.SetResizable(filter);
  win.End;
  win.ShowArgs;
  Fl.Run
END NativeFileChooser.
