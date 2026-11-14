MODULE TestDialogs; (* FlDialogs: each dialog answered by keys, as a user would *)

IMPORT Platform, Fl, FlDialogs, FlTest, Check, Probe;

VAR
  fc: FlDialogs.NativeFileChooser;
  names: FlDialogs.Names;
  title: ARRAY 16 OF CHAR;
  s, picked: ARRAY 256 OF CHAR;
  home: ARRAY 256 OF CHAR;
  cut: ARRAY 4 OF CHAR;
  tiny: ARRAY 1 OF CHAR;
  long: ARRAY 6000 OF CHAR;
  box2: Fl.Box;
  i, r, g, b, font, size, c, calls, box, color, label, x0, y0: INTEGER;
  x, y, z: LONGREAL;
  ok: BOOLEAN;
  str: Fl.String;
  big: ARRAY 301 OF CHAR;
  win: Fl.Window;
  chooser: FlDialogs.ColorChooser;

PROCEDURE Picked(name-: ARRAY OF CHAR);
BEGIN COPY(name, picked)
END Picked;

PROCEDURE Count(w: Fl.Widget);
BEGIN INC(calls)
END Count;

(* Whether the last dialog was answered. *)
PROCEDURE Answered(): BOOLEAN;
  VAR t: ARRAY 256 OF CHAR;
BEGIN RETURN FlTest.Answered(t)
END Answered;

(* Whether the last dialog was answered, and had title t. *)
PROCEDURE Titled(t: ARRAY OF CHAR): BOOLEAN;
  VAR u: ARRAY 256 OF CHAR;
BEGIN RETURN FlTest.Answered(u) & (u = t)
END Titled;

(* A dialog with this icon text, for this call alone: FLTK keeps the pointer. *)
PROCEDURE ShowIcon(text: ARRAY OF CHAR);
  VAR s: ARRAY 8 OF CHAR;
BEGIN
  COPY(text, s); FlDialogs.SetIconLabel(s);
  FlTest.Enter; FlDialogs.Message("An icon")
END ShowIcon;

PROCEDURE Ends(s, end: ARRAY OF CHAR): BOOLEAN;
  VAR i, j: INTEGER;
BEGIN
  i := 0; WHILE s[i] # 0X DO INC(i) END;
  j := 0; WHILE end[j] # 0X DO INC(j) END;
  IF j > i THEN RETURN FALSE END;
  WHILE (j > 0) & (s[i - 1] = end[j - 1]) DO DEC(i); DEC(j) END;
  RETURN j = 0
END Ends;

(* Whether names are those in order, separated by spaces. *)
PROCEDURE Order(names: FlDialogs.Names; order: ARRAY OF CHAR): BOOLEAN;
  VAR i, j, k: INTEGER;
BEGIN
  j := 0;
  FOR i := 0 TO SHORT(LEN(names^)) - 1 DO
    k := 0;
    WHILE (order[j] # " ") & (order[j] # 0X) & (order[j] = names[i][k]) DO INC(j); INC(k) END;
    IF names[i][k] # 0X THEN RETURN FALSE END;
    IF order[j] = " " THEN INC(j) ELSIF (order[j] # 0X) OR (i # LEN(names^) - 1) THEN RETURN FALSE END
  END;
  RETURN order[j] = 0X
END Order;

BEGIN
  Check.Check(FlDialogs.Hotspot(), "dialogs are shown under the mouse to start with");
  FlDialogs.SetHotspot(FALSE);
  Check.Check(~FlDialogs.Hotspot(), "SetHotspot");
  FlDialogs.Font(font, size);
  FlDialogs.SetFont(Fl.Courier, 16); FlDialogs.Font(font, size);
  Check.Check((font = Fl.Courier) & (size = 16), "SetFont");
  FlDialogs.SetFont(Fl.Helvetica, 0);

  FlTest.Enter; FlDialogs.Message("100% done");
  Check.Check(Answered(), "Message waits for the user; Enter closes it");
  FlTest.Escape; FlDialogs.Alert("Careful");
  Check.Check(Answered(), "Alert; Escape closes it");

  FlTest.Enter; i := FlDialogs.Choice("Save?", "No", "Yes", "Cancel");
  Check.Check(i = 1, "Enter pushes Choice's b1");
  FlTest.Escape; i := FlDialogs.Choice("Save?", "No", "Yes", "Cancel");
  Check.Check(i = FlDialogs.Escaped, "Escape is Escaped");
  FlTest.Answer("", ORD("n")); i := FlDialogs.Choice("Save?", "&No", "&Yes", "&Cancel");
  Check.Check(i = 0, "b0, by its shortcut");
  FlTest.Answer("", ORD("c")); i := FlDialogs.Choice("Save?", "&No", "&Yes", "&Cancel");
  Check.Check(i = 2, "b2");
  FlTest.Enter; i := FlDialogs.Choice("Go on?", "", "Go", "");
  Check.Check(i = 1, "an empty label is no button");

  s := "abc";
  FlTest.Answer("xy", Fl.KeyEnter); ok := FlDialogs.Input("Name:", s);
  Check.Check(ok & (s = "abcxy"), "Input starts with the text, the cursor after it");
  FlTest.Escape; ok := FlDialogs.Input("Name:", s);
  Check.Check(~ok & (s = "abcxy"), "cancelled, the text is unchanged");
  FOR i := 0 TO 299 DO big[i] := CHR(ORD("a") + i MOD 26) END; big[300] := 0X;
  FlTest.Answer("xy", Fl.KeyEnter); str := FlDialogs.InputText("Name:", big);
  Check.Check((str # NIL) & (LEN(str^) = 303) & (str[299] = big[299]) & (str[300] = "x") & (str[301] = "y"),
    "InputText, of any length");
  FlTest.Escape; str := FlDialogs.InputText("Name:", "abc");
  Check.Check(str = NIL, "NIL if cancelled");
  FlTest.Answer("pass", Fl.KeyEnter); str := FlDialogs.PasswordText("Password:", "");
  Check.Check((str # NIL) & (str^ = "pass"), "PasswordText");
  s := "";
  FlTest.Answer("secret", Fl.KeyEnter); ok := FlDialogs.Password("Password:", s);
  Check.Check(ok & (s = "secret"), "Password");
  s := "";
  FlTest.Answer("secret", Fl.KeyEnter); ok := FlDialogs.PasswordLimited("Password:", s, 3);
  Check.Check(ok & (s = "sec"), "PasswordLimited takes no more than its limit");
  s := "x"; s[0] := 0C3X; s[1] := 0A9X; s[2] := 0X;  (* an e acute, two bytes *)
  FlTest.Answer("abc", Fl.KeyEnter); ok := FlDialogs.InputLimited("Name:", s, 3);
  Check.Check(ok & (s[0] = 0C3X) & (s[1] = 0A9X) & (s[2] = "a") & (s[3] = "b") & (s[4] = 0X),
    "InputLimited counts characters, not bytes");
  s := "";
  FlTest.Answer("abcd", Fl.KeyEnter); ok := FlDialogs.InputLimited("Name:", s, 0);
  Check.Check(ok & (s = "abcd"), "and a limit of 0 is none");

  FlDialogs.SetTitle("Once");
  FlTest.Enter; FlDialogs.Message("titled");
  Check.Check(Titled("Once"), "SetTitle titles the next dialog");
  FlTest.Enter; FlDialogs.Message("untitled");
  Check.Check(Titled(""), "and that one only");
  FlDialogs.SetDefaultTitle("Always");
  FlTest.Enter; FlDialogs.Message("titled");
  FlTest.Enter; FlDialogs.Message("titled");
  Check.Check(Titled("Always"), "SetDefaultTitle titles every one");
  FlDialogs.SetDefaultTitle("");

  r := 10; g := 300; b := -5;
  FlTest.Enter; ok := FlDialogs.ChooseColor("Color", r, g, b, FlDialogs.ColorByte);
  Check.Check(ok & (Titled("Color")) & (r = 10) & (g = 255) & (b = 0),
    "ChooseColor: OK gives the color, brought into range");
  r := 1; g := 2; b := 3;
  FlTest.Escape; ok := FlDialogs.ChooseColor("Color", r, g, b, FlDialogs.ColorDefault);
  Check.Check(~ok & (r = 1) & (g = 2) & (b = 3), "cancelled, unchanged");

  s := "TestDialogs.Mod";
  picked := "";
  FlDialogs.SetFilePicked(Picked);
  FlTest.Enter; ok := FlDialogs.ChooseFile("Open", "*.Mod", s, TRUE);
  Check.Check(ok & (Titled("Open")) & (s = "TestDialogs.Mod"), "ChooseFile, relative");
  Check.Check(Ends(picked, "/TestDialogs.Mod"), "SetFilePicked");
  FlDialogs.SetFilePicked(NIL);
  picked := "";
  FlTest.Enter; ok := FlDialogs.ChooseFile("Open", "*.Mod", s, FALSE);
  Check.Check(ok & (s[0] = "/") & Ends(s, "/test/TestDialogs.Mod"), "and absolute");
  Check.Check(picked = "", "SetFilePicked(NIL) stops it");
  s := "New.txt";
  FlTest.Enter; ok := FlDialogs.ChooseFile("Save", "", s, TRUE);
  Check.Check(ok & (s = "New.txt"), "a file that doesn't exist");
  FlTest.Escape; ok := FlDialogs.ChooseFile("Save", "", s, TRUE);
  Check.Check(~ok & (s = "New.txt"), "cancelled, unchanged");
  s := "..";
  FlTest.Enter; ok := FlDialogs.ChooseDirectory("Folder", s, FALSE);
  Check.Check(ok & (s[0] = "/") & ~Ends(s, "/test"), "ChooseDirectory");

  (* FLTK's own chooser, which keys can answer, and not the desktop's *)
  Fl.SetOption(Fl.OptionFnfcUsesGtk, FALSE); Fl.SetOption(Fl.OptionFnfcUsesZenity, FALSE);
  Fl.SetOption(Fl.OptionFnfcUsesKdialog, FALSE);
  Check.Check(~Fl.Option(Fl.OptionFnfcUsesGtk) & ~Fl.Option(Fl.OptionFnfcUsesZenity), "SetOption");
  NEW(fc); FlDialogs.OpenNativeFileChooser(fc, FlDialogs.BrowseFile);
  Check.Check(fc.IsOpen() & (fc.Kind() = FlDialogs.BrowseFile) & (FlDialogs.openChoosers = 1), "OpenNativeFileChooser");
  title := "Native"; fc.SetTitle(title); title := "Changed";
  s := "Oberon?*.Mod?Text?*.txt"; s[6] := 09X; s[12] := 0AX; s[17] := 09X;
  fc.SetFilter(s);
  fc.SetFilterValue(1);
  Check.Check((fc.Filters() = 2) & (fc.FilterValue() = 1), "SetFilter, SetFilterValue");
  fc.AddFilter("YAML", "*.{yaml,yml}"); fc.AddFilter("", "*.c");
  fc.SetFilterValue(3);
  Check.Check((fc.Filters() = 4) & (fc.FilterValue() = 3), "AddFilter");
  fc.SetFilter(""); fc.AddFilter("Oberon", "*.Mod");
  Check.Check(fc.Filters() = 1, "after SetFilter, AddFilter adds to its filters");
  fc.SetFilter(s);
  fc.SetFilterValue(0);
  fc.SetOptions({}); fc.SetOptions(FlDialogs.SaveAsConfirm);
  Check.Check(fc.Options() = FlDialogs.SaveAsConfirm, "SetOptions");
  fc.SetOptions({});
  fc.SetDirectory("."); fc.SetPresetFile("TestDialogs.Mod");
  FlTest.Enter; i := fc.Show();
  Check.Check(Titled("Native"), "the title, copied");
  Check.Check(i = FlDialogs.Chosen, "Show: Chosen");
  IF fc.Count() = 1 THEN fc.FileName(0, s) ELSE s := "" END;
  Check.Check((s[0] = "/") & Ends(s, "/test/TestDialogs.Mod"), "FileName: the file chosen, absolute");
  IF fc.Count() = 1 THEN str := fc.Name(0) ELSE str := NIL END;
  Check.Check((str # NIL) & (str^ = s), "Name");
  FlTest.Escape; i := fc.Show();
  Check.Check((i = FlDialogs.Cancelled) & (fc.Count() = 0), "Show: Cancelled");
  fc.SetKind(FlDialogs.BrowseSaveFile); fc.SetPresetFile("New.txt");
  Check.Check(fc.Kind() = FlDialogs.BrowseSaveFile, "SetKind");
  FlTest.Enter; i := fc.Show();
  IF fc.Count() = 1 THEN fc.FileName(0, s) ELSE s := "" END;
  Check.Check((i = FlDialogs.Chosen) & Ends(s, "/test/New.txt"), "BrowseSaveFile: a file that doesn't exist");
  fc.Close; fc.Close;
  Check.Check(~fc.IsOpen() & (FlDialogs.openChoosers = 0), "Close");

  FlTest.Escape; c := FlDialogs.ChooseFromColormap(Fl.Red);
  Check.Check(c = Fl.Red, "ChooseFromColormap gives back old if none is picked");

  (* test/names: empty files, whose names each sort orders differently *)
  ok := FlDialogs.ListDirectory("names", FlDialogs.AlphaSort, names);
  Check.Check(ok & (names # NIL) & (LEN(names^) = 10), "ListDirectory: every name, with . and ..");
  IF ok & (LEN(names^) = 10) THEN
    Check.Check((names[0]^ = "./") & (names[1]^ = "../") & (names[2]^ = "B1")
      & (names[3]^ = "a10") & (names[9]^ = "ab12z"), "sorted, a directory's name ending in /");
    Check.Check(LEN(names[2]^) = 3, "each name just long enough")
  END;
  Check.Check(ok & Order(names, "./ ../ B1 a10 a1yb a1za a2 ab12 ab12y ab12z"), "AlphaSort: by bytes");
  ok := FlDialogs.ListDirectory("names", FlDialogs.CaseAlphaSort, names);
  Check.Check(ok & Order(names, "./ ../ a10 a1yb a1za a2 ab12 ab12y ab12z B1"), "CaseAlphaSort: case ignored");
  ok := FlDialogs.ListDirectory("names", FlDialogs.NumericSort, names);
  Check.Check(ok & Order(names, "./ ../ B1 a1yb a1za a2 a10 ab12 ab12y ab12z"),
    "NumericSort: numbers by value, then what follows, a name before a longer one it starts (FLTK's is wrong)");
  ok := FlDialogs.ListDirectory("names", FlDialogs.CaseNumericSort, names);
  Check.Check(ok & Order(names, "./ ../ a1yb a1za a2 a10 ab12 ab12y ab12z B1"), "CaseNumericSort");
  ok := FlDialogs.ListDirectory("no-such-directory", FlDialogs.CaseNumericSort, names);
  Check.Check(~ok & (names = NIL), "a directory that can't be read");

  (* a color chooser, in a window of the program's *)
  NEW(win); Fl.OpenWindow(win, 220, 110, "TestDialogs");
  NEW(chooser); FlDialogs.OpenColorChooser(chooser, 5, 5, 200, 95, "");
  win.End;
  chooser.action := Count; calls := 0;
  Check.Check(chooser.SetRGB(1.0D0, 0.0D0, 0.0D0), "SetRGB says it changed the color");
  Check.Check(~chooser.SetRGB(1.0D0, 0.0D0, 0.0D0), "and when it didn't");
  x := chooser.Hue(); y := chooser.Saturation(); z := chooser.Value();
  Check.Check((x = 0.0D0) & (y = 1.0D0) & (z = 1.0D0), "red's hue, saturation and value");
  Check.Check(chooser.SetHSV(8.0D0, 2.0D0, 1.0D0), "SetHSV");
  x := chooser.Hue(); y := chooser.Saturation();
  Check.Check((x = 2.0D0) & (y = 1.0D0), "takes the hue modulo 6, and limits the saturation");
  x := chooser.R(); y := chooser.G(); z := chooser.B();
  Check.Check((x = 0.0D0) & (y = 1.0D0) & (z = 0.0D0), "and sets red, green and blue");
  Check.Check(calls = 0, "neither calls back");
  chooser.SetMode(FlDialogs.ColorHSV);
  Check.Check(chooser.Mode() = FlDialogs.ColorHSV, "Mode reads back");
  chooser.SetMode(FlDialogs.ColorRGB);
  ok := FlTest.Mouse(win, Fl.EvPush, 25, 60, Fl.LeftMouse, Fl.Button1, 0);
  ok := FlTest.Mouse(win, Fl.EvRelease, 25, 60, Fl.LeftMouse, {}, 0);
  x := chooser.Hue();
  Check.Check((calls >= 1) & (x # 2.0D0), "a click on the hue box changes the color, and calls back");
  win.Delete;
  FlDialogs.HSVToRGB(4.0D0, 1.0D0, 1.0D0, x, y, z);
  Check.Check((x = 0.0D0) & (y = 0.0D0) & (z = 1.0D0), "HSVToRGB");
  FlDialogs.RGBToHSV(0.0D0, 0.0D0, 1.0D0, x, y, z);
  Check.Check((x = 4.0D0) & (y = 1.0D0) & (z = 1.0D0), "RGBToHSV");

  (* relative names *)
  Check.Check(FlDialogs.FilenameRelativeTo("/a/c", "/a/b", s) & (s = "../c"), "FilenameRelativeTo: a sibling");
  Check.Check(FlDialogs.FilenameRelativeTo("/a/b/c", "/a/b", s) & (s = "c"), "a child");
  Check.Check(FlDialogs.FilenameRelativeTo("/a/b", "/a/b", s) & (s = "."), "the directory itself");
  Check.Check(FlDialogs.FilenameRelativeTo("/a/bc", "/a/b", s) & (s = "../bc"), "a name that starts the same");
  Check.Check(~FlDialogs.FilenameRelativeTo("x/y", "/a/b", s) & (s = "x/y"), "a relative name is left, and FALSE");
  s := "/a/c";
  Check.Check(FlDialogs.FilenameRelativeTo(s, "/a/b", s) & (s = "../c"), "from and to the same variable");
  Check.Check(FlDialogs.FilenameRelativeTo("/a/cdef", "/a/b", cut) & (cut = "../"), "cut to fit");
  Check.Check(~FlDialogs.FilenameRelative("x/y", s) & (s = "x/y"), "FilenameRelative: a relative name");
  Check.Check(FlDialogs.FilenameRelative("/no/such", s) & (s[0] = ".") & (s[1] = "."), "against the current directory");

  (* absolute names *)
  Check.Check(FlDialogs.FilenameAbsoluteTo("foo", "/a/b", s) & (s = "/a/b/foo"), "FilenameAbsoluteTo");
  Check.Check(FlDialogs.FilenameAbsoluteTo("../foo", "/a/b", s) & (s = "/a/foo"), "takes out ..");
  Check.Check(FlDialogs.FilenameAbsoluteTo("./x/../y", "/a", s) & (s = "/a/x/../y"), "takes out what starts it alone");
  Check.Check(FlDialogs.FilenameAbsoluteTo("../../x", "/a", s) & (s = "/../x"), "a .. too many stays");
  Check.Check(FlDialogs.FilenameAbsoluteTo("x", "", s) & (s = "/x"), "an empty base is the root");
  Check.Check(FlDialogs.FilenameAbsoluteTo("x", "/a/", s) & (s = "/a/x"), "a base with a slash");
  Check.Check(~FlDialogs.FilenameAbsoluteTo("/p/q", "/a/b", s) & (s = "/p/q"), "an absolute name is left, and FALSE");
  Check.Check(~FlDialogs.FilenameAbsoluteTo("|cmd", "/a", s) & (s = "|cmd"), "a pipe is left");
  s := "foo";
  Check.Check(FlDialogs.FilenameAbsoluteTo(s, "/a", s) & (s = "/a/foo"), "from and to the same variable");
  Check.Check(FlDialogs.FilenameAbsoluteTo("../foo", "/a/b", cut) & (cut = "/a/"), "cut after the .. is out");
  Check.Check(FlDialogs.FilenameAbsoluteTo("../foo", "/a/b", tiny) & (tiny = ""), "room for the 0X alone");
  Check.Check(FlDialogs.FilenameAbsolute("TestDialogs.Mod", s) & (s[0] = "/") & Ends(s, "/TestDialogs.Mod"), "against the current directory");

  (* expanded names *)
  Check.Check(~FlDialogs.FilenameExpand("a/b/c", s) & (s = "a/b/c"), "FilenameExpand: nothing to do");
  Check.Check(~FlDialogs.FilenameExpand("", s) & (s = ""), "an empty name");
  Check.Check(~FlDialogs.FilenameExpand("$POFLTK_NO_SUCH/x", s) & (s = "$POFLTK_NO_SUCH/x"), "an unset variable is left");
  Check.Check(~FlDialogs.FilenameExpand("~pofltk-no-such/x", s) & (s = "~pofltk-no-such/x"), "an unknown user is left");
  Check.Check(~FlDialogs.FilenameExpand("a~/b$", s) & (s = "a~/b$"), "only the start of a part counts");
  Platform.GetEnv("HOME", home);
  Probe.SetEnv("HOME", "/pofltk/home/");
  Check.Check(FlDialogs.FilenameExpand("~/x", s) & (s = "/pofltk/home/x"), "~ is HOME, its last slash dropped");
  Check.Check(FlDialogs.FilenameExpand("~", s) & (s = "/pofltk/home"), "~ alone");
  Check.Check(FlDialogs.FilenameExpand("$HOME/x", s) & (s = "/pofltk/home/x"), "a variable");
  Check.Check(FlDialogs.FilenameExpand("before/$HOME/x", s) & (s = "/pofltk/home/x"), "a value with a slash ends what came before it");
  Check.Check(FlDialogs.FilenameExpand("$HOME/$HOME", s) & (s = "/pofltk/home"), "and so does a second");
  Check.Check(FlDialogs.FilenameExpand("$HOME/x", cut) & (cut = "/po"), "cut to fit");
  Check.Check(FlDialogs.FilenameExpand("$HOME/x", tiny) & (tiny = ""), "room for the 0X alone");
  s := "$HOME";
  Check.Check(FlDialogs.FilenameExpand(s, s) & (s = "/pofltk/home"), "from and to the same variable");
  Probe.SetEnv("HOME", home);
  Check.Check(FlDialogs.FilenameExpand("~root/x", s) & (s[0] = "/") & Ends(s, "/x"), "~user");
  Probe.SetEnv("POFLTK_REL", "in/side");
  Check.Check(FlDialogs.FilenameExpand("a/$POFLTK_REL/b", s) & (s = "a/in/side/b"), "a value with no slash stays in place");
  Probe.SetEnv("POFLTK_EMPTY", "");
  Check.Check(FlDialogs.FilenameExpand("a/$POFLTK_EMPTY/b", s) & (s = "a//b"), "an empty value");
  Probe.SetEnv("POFLTK_SELF", "$POFLTK_SELF");
  Check.Check(FlDialogs.FilenameExpand("$POFLTK_SELF/x", s) & (s = "$POFLTK_SELF/x"), "a value naming itself, which never ends in FLTK");
  Check.Check(FlDialogs.FilenameExpand("$POFLTK_SELF/x", cut), "too long for the buffer, which crashes FLTK");
  FOR i := 0 TO LEN(long) - 2 DO long[i] := "a" END;
  long[0] := "/"; long[LEN(long) - 1] := 0X;
  Probe.SetEnv("POFLTK_LONG", long);
  Check.Check(FlDialogs.FilenameExpand("$POFLTK_LONG/x", s) & (s[0] = "/") & (s[LEN(s) - 2] = "a"), "a value longer than FLTK's buffers");

  (* the rest of filename.H *)
  Check.Check(FlDialogs.FilenameIsDir("names"), "FilenameIsDir: a directory");
  Check.Check(FlDialogs.FilenameIsDir("names/"), "with a slash");
  Check.Check(FlDialogs.FilenameIsDir("/"), "the root");
  Check.Check(~FlDialogs.FilenameIsDir("TestDialogs.Mod"), "a file");
  Check.Check(~FlDialogs.FilenameIsDir("no-such-directory"), "nothing");
  Check.Check(~FlDialogs.FilenameIsDir(""), "an empty name");
  FOR i := 0 TO LEN(long) - 3 DO long[i] := "a" END;
  long[LEN(long) - 2] := "/"; long[LEN(long) - 1] := 0X;
  Check.Check(~FlDialogs.FilenameIsDir(long), "a name longer than FLTK's buffer, with a slash");

  Check.Check(FlDialogs.FilenameMatch("a.txt", "*.txt"), "FilenameMatch");
  Check.Check(FlDialogs.FilenameMatch("A.TXT", "*.txt"), "whatever the case");
  Check.Check(~FlDialogs.FilenameMatch("a.txt", "*.c"), "no match");
  Check.Check(FlDialogs.FilenameMatch("a.txt.bak", "*.{txt,bak}"), "a list");
  Check.Check(FlDialogs.FilenameMatch("b", "[a-c]") & ~FlDialogs.FilenameMatch("d", "[a-c]"), "a set");
  Check.Check(~FlDialogs.FilenameMatch("a", "[!a]"), "a set refused");
  Check.Check(FlDialogs.FilenameMatch("*", "\*") & ~FlDialogs.FilenameMatch("a", "\*"), "a backslash");
  Check.Check(FlDialogs.FilenameMatch("", "*") & FlDialogs.FilenameMatch("", ""), "empty names");
  s[0] := 0C3X; s[1] := 0A9X; s[2] := 0X;
  Check.Check(~FlDialogs.FilenameMatch(s, "?") & FlDialogs.FilenameMatch(s, "??"), "? is a byte");
  ok := FlDialogs.FilenameMatch("a", "[a"); ok := FlDialogs.FilenameMatch("a", "[a-");
  ok := FlDialogs.FilenameMatch("a", "["); ok := FlDialogs.FilenameMatch("a", "[!");
  ok := FlDialogs.FilenameMatch("a", "{a"); ok := FlDialogs.FilenameMatch("a", "{a,");
  ok := FlDialogs.FilenameMatch("a", "\"); ok := FlDialogs.FilenameMatch("a", "[\");
  Check.Check(TRUE, "a pattern left open reads nothing it shouldn't");

  FlDialogs.FilenameName("/a/b.c", s); Check.Check(s = "b.c", "FilenameName");
  FlDialogs.FilenameName("/a/b/", s); Check.Check(s = "", "of a directory");
  FlDialogs.FilenameName("b", s); Check.Check(s = "b", "with no directory");
  FlDialogs.FilenameName("/a/bcdefg", cut); Check.Check(cut = "bcd", "cut to fit");
  s := "/a/b"; FlDialogs.FilenameName(s, s); Check.Check(s = "b", "from and to the same variable");
  FlDialogs.FilenameExt("/a/b.c", s); Check.Check(s = ".c", "FilenameExt");
  FlDialogs.FilenameExt("a.b.c", s); Check.Check(s = ".c", "the last");
  FlDialogs.FilenameExt("a.d/b", s); Check.Check(s = "", "none, with a dot before");
  FlDialogs.FilenameExt(".bashrc", s); Check.Check(s = ".bashrc", "all of a dot file");
  FlDialogs.FilenameExt("a.extension", cut); Check.Check(cut = ".ex", "cut to fit");

  s := "a.txt"; FlDialogs.FilenameSetExt(s, ".c"); Check.Check(s = "a.c", "FilenameSetExt");
  s := "a"; FlDialogs.FilenameSetExt(s, ".c"); Check.Check(s = "a.c", "with none");
  s := "a.txt"; FlDialogs.FilenameSetExt(s, ""); Check.Check(s = "a", "taken off");
  s := "a.txt"; FlDialogs.FilenameSetExt(s, ".longer.ext"); Check.Check(s = "a.longer.ext", "longer");
  cut := "a.c"; FlDialogs.FilenameSetExt(cut, ".long"); Check.Check(cut = "a.l", "cut to fit");
  s := ".c"; FlDialogs.FilenameSetExt(s, s); Check.Check(s = ".c", "name and ext the same variable");

  s := "a%20b"; FlDialogs.DecodeURI(s); Check.Check(s = "a b", "DecodeURI");
  s := "%41%42c"; FlDialogs.DecodeURI(s); Check.Check(s = "ABc", "several");
  s := "plain"; FlDialogs.DecodeURI(s); Check.Check(s = "plain", "nothing to do");
  s := "a%"; FlDialogs.DecodeURI(s); Check.Check(s = "a%", "a % at the end");
  s := "%zz%41"; FlDialogs.DecodeURI(s); Check.Check(s = "%zz%41", "stops at a bad %");
  s := "a%00b"; FlDialogs.DecodeURI(s); Check.Check(s = "a", "%00 ends it");
  s := ""; FlDialogs.DecodeURI(s); Check.Check(s = "", "empty");

  (* a dialog's icon and place *)
  FlDialogs.Icon(box, font, size, color, label);
  Check.Check((box = Fl.ThinUpBox) & (font = Fl.TimesBold) & (size = 34) & (color = Fl.White) & (label = Fl.Blue), "Icon: FLTK's to start with");
  FlDialogs.SetIcon(Fl.FlatBox, Fl.Helvetica, 20, Fl.Yellow, Fl.Red);
  FlDialogs.Icon(box, font, size, color, label);
  Check.Check((box = Fl.FlatBox) & (font = Fl.Helvetica) & (size = 20) & (color = Fl.Yellow) & (label = Fl.Red), "SetIcon");
  FlDialogs.SetDefaultIconLabel("D");
  Check.Check(FlDialogs.Position(x0, y0) = FlDialogs.NoPosition, "no position to start with");
  FlDialogs.SetPosition(30, 40, FALSE);
  Check.Check((FlDialogs.Position(x0, y0) = FlDialogs.PositionAt) & (x0 = 30) & (y0 = 40), "SetPosition");
  FlDialogs.SetPosition(50, 60, TRUE);
  Check.Check((FlDialogs.Position(x0, y0) = FlDialogs.PositionCentred) & (x0 = 50) & (y0 = 60), "centred");
  ShowIcon("T");
  Check.Check(FlDialogs.Position(x0, y0) = FlDialogs.NoPosition, "a dialog uses it up");
  FlDialogs.SetDefaultIconLabel("");
  FlDialogs.SetIcon(Fl.ThinUpBox, Fl.TimesBold, 34, Fl.White, Fl.Blue);
  ShowIcon("");
  Check.Check(Answered(), "SetIconLabel, SetIcon: dialogs still run");
  NEW(win); Fl.OpenWindow(win, 220, 110, "TestDialogs");
  NEW(box2); Fl.OpenBox(box2, 20, 30, 40, 10, "");
  win.End;
  FlDialogs.SetPositionOver(box2);
  ok := FlDialogs.Position(x0, y0) = FlDialogs.PositionCentred;
  Check.Check(ok & (x0 - win.X() = 40) & (y0 - win.Y() = 35), "SetPositionOver");
  win.Delete;
  FlDialogs.SetPosition(0, 0, FALSE);
  ShowIcon("");
  FlDialogs.SetFileChooserOK("Take it");
  FlDialogs.SetFileChooserOK("");

  Check.Check(Fl.OpenWidgets() = 0, "no widget left open");
  Check.Summary
END TestDialogs.
