MODULE FileChooser; (* FLTK's test/file_chooser.cxx: every way of asking a file chooser for files *)

(* FileChooser [filter]

   The button by Filter shows the chooser; its callback, and the files
   it was left with, are listed. The filter is patterns, or names with
   a pattern in round brackets, separated by tabs.

   FLTK's program writes its log to an Fl_Terminal, which isn't bound
   yet (PLAN.md, Phase 18): this one's is a browser. It also previews
   PDF and PostScript with Ghostscript, through Fl_Shared_Image's
   handlers, which aren't bound. Its Files list shows each file's icon
   and its name relative to here: Fl_File_Browser's own add and
   fl_filename_relative aren't bound either. *)

IMPORT Args, Strings, Fl, FlBrowsers, FlButtons, FlDialogs, FlImages, FlInputs, FlMenus;

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

PROCEDURE Log(prefix-, s-: ARRAY OF CHAR);
  VAR line: ARRAY 2200 OF CHAR;
BEGIN
  COPY(prefix, line); Strings.Append(s, line);
  tty.Add(line);
  tty.SetBottomLine(tty.Count())
END Log;

PROCEDURE (c: Chooser) Callback*;
  VAR s: ARRAY 2048 OF CHAR;
BEGIN
  Log("fc_callback", "");
  IF ~c.Value(s) THEN s := "(null)" END;
  Log("    filename = ", s)
END Callback;

PROCEDURE (b: Show) Callback*;
  VAR s: ARRAY 2048 OF CHAR; i, count: INTEGER;
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
      Log("Picked: ", s);
      files.Add(s);
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
