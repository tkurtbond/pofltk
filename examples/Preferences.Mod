MODULE Preferences; (* FLTK's test/preferences.fl in Oberon-2 *)

(* A morning's preferences, kept between runs in the user's settings
   (FlPreferences): OK writes them and closes the window, Cancel closes
   it alone. The texts are translated, English or German, by a small
   table standing in for GNU gettext, as FLTK's program does; the
   language is read before the window is made, so a change of it shows
   at the next start, and translates an input's Cut, Copy and Paste
   menu too. *)

IMPORT Out, Fl, FlButtons, FlInputs, FlValuators, FlMenus, FlDialogs, FlPreferences;

CONST
  project = "fltk.org";
  application = "test/preferences";
  words = 41;

VAR
  language: INTEGER;  (* 0 English, 1 German *)
  table: ARRAY words, 2 OF ARRAY 80 OF CHAR;
  nTable: INTEGER;
  myWindow: Fl.DoubleWindow;
  wAlarm, wPaper: FlInputs.Input;
  wEggs: FlInputs.IntInput;
  wAmPm, wWear, wDrink, wBread, wLanguage: FlMenus.Choice;
  wLeft, wRight: FlButtons.RoundButton;
  wShower, wShave, wBrush, wMilk, wButter: FlButtons.CheckButton;
  wMinutes: FlValuators.ValueSlider;
  cancel, ok: FlButtons.Button;
  group: Fl.Group;
  box: Fl.Box;
  s, t, u: ARRAY 128 OF CHAR;

PROCEDURE Pair(en-, de-: ARRAY OF CHAR);
BEGIN COPY(en, table[nTable, 0]); COPY(de, table[nTable, 1]); INC(nTable)
END Pair;

PROCEDURE Equal(a-, b-: ARRAY OF CHAR): BOOLEAN;
VAR i: INTEGER;
BEGIN
  i := 0; WHILE (a[i] = b[i]) & (a[i] # 0X) DO INC(i) END;
  RETURN a[i] = b[i]
END Equal;

(* t is text in the current language: gettext. *)
PROCEDURE Tr(text-: ARRAY OF CHAR; VAR t: ARRAY OF CHAR);
VAR i: INTEGER;
BEGIN
  i := 0; WHILE (i < nTable) & ~Equal(text, table[i, 0]) DO INC(i) END;
  IF i < nTable THEN COPY(table[i, language], t) ELSE COPY(text, t) END
END Tr;

PROCEDURE Translations;
BEGIN
  Pair("Alarm at:", "Wecken um:");
  Pair("Bread:", "Brot:");
  Pair("Breakfast:", "Frühstück:");
  Pair("Cancel", "Abbrechen");
  Pair("Copy", "Kopieren");
  Pair("Cut", "Ausschneiden");
  Pair("Drink:", "Getränk:");
  Pair("English", "Englisch");
  Pair("German", "Deutsch");
  Pair("Get Up:", "Aufstehen:");
  Pair("Language:", "Sprache:");
  Pair("My Preferences", "Meine Vorlieben");
  Pair("NY Times", "Der Spiegel");
  Pair("Newspaper:", "Tageszeitung:");
  Pair("OK", "OK");
  Pair("Paste", "Einfügen");
  Pair("Please restart the app to use your new language setting.",
    "Bitte starten Sie die App erneut um Ihre Spracheinstellung zu nutzen.");
  Pair("Wear:", "Schuhwerk:");
  Pair("a.m.", "früh");
  Pair("bare foot", "barfuß");
  Pair("brush teeth", "Zähne putzen");
  Pair("coffee", "Kaffee");
  Pair("eggs", "Eier");
  Pair("flip flops", "Schlappen");
  Pair("juice", "Saft");
  Pair("left side", "linke Seite");
  Pair("min.", "Min.");
  Pair("of the bed", "vom Bett");
  Pair("p.m.", "spät");
  Pair("right side", "rechte Seite");
  Pair("rye", "Roggen");
  Pair("sandals", "Sandalen");
  Pair("shave", "rasieren");
  Pair("shoes", "Schuhe");
  Pair("shower", "duschen");
  Pair("sourdough", "Sauerteig");
  Pair("tea", "Tee");
  Pair("wheat", "Weizen");
  Pair("white", "Weißbrot");
  Pair("with butter", "mit Butter");
  Pair("with milk", "mit Milch")
END Translations;

(* Adds text, translated, to c. *)
PROCEDURE Item(c: FlMenus.Choice; text-: ARRAY OF CHAR);
VAR t: ARRAY 80 OF CHAR; i: INTEGER;
BEGIN Tr(text, t); i := c.Add(t, 0, {}, NIL, {})
END Item;

(* Opens c with its label translated and FLUID's settings. *)
PROCEDURE OpenChoice(c: FlMenus.Choice; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
VAR t: ARRAY 80 OF CHAR;
BEGIN
  Tr(label, t); FlMenus.OpenChoice(c, x, y, w, h, t);
  c.SetDownBox(Fl.BorderBox)
END OpenChoice;

PROCEDURE OpenCheck(b: FlButtons.CheckButton; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
VAR t: ARRAY 80 OF CHAR;
BEGIN
  Tr(label, t); FlButtons.OpenCheckButton(b, x, y, w, h, t);
  b.SetDownBox(Fl.DownBox)
END OpenCheck;

PROCEDURE OpenRound(b: FlButtons.RoundButton; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
VAR t: ARRAY 80 OF CHAR;
BEGIN
  Tr(label, t); FlButtons.OpenRoundButton(b, x, y, w, h, t);
  b.SetKind(FlButtons.Radio);
  b.SetDownBox(Fl.RoundDownBox)
END OpenRound;

(* Appends n, not negative, to s. *)
PROCEDURE Num(n: INTEGER; VAR s: ARRAY OF CHAR);
VAR i: INTEGER;
BEGIN
  IF n >= 10 THEN Num(n DIV 10, s) END;
  i := 0; WHILE s[i] # 0X DO INC(i) END;
  s[i] := CHR(ORD("0") + n MOD 10); s[i + 1] := 0X
END Num;

(* The language, read before the window is made. *)
PROCEDURE ReadLanguagePrefs;
VAR app: FlPreferences.Preferences;
BEGIN
  NEW(app); FlPreferences.Open(app, FlPreferences.User, project, application);
  language := app.Int("language", 0);
  app.Close
END ReadLanguagePrefs;

PROCEDURE ReadPrefs;
VAR
  app, bed, eat: FlPreferences.Preferences;
  path, buffer, default: ARRAY 4096 OF CHAR;
  paper: POINTER TO ARRAY OF CHAR;
  i, n, side, tasks: INTEGER;
BEGIN
  NEW(app); FlPreferences.Open(app, FlPreferences.User, project, application);
  (* FLTK's program asks Fl_Preferences::filename where the file will
     be before opening it; it is the same name *)
  app.FileName(path);
  IF path = "" THEN Out.String("Location of future Preferences file not found."); Out.Ln
  ELSE Out.String("Preferences file will be located at:"); Out.Ln; Out.String(path); Out.Ln
  END;
  IF path = "" THEN Out.String("App Preferences are memory mapped."); Out.Ln
  ELSE Out.String("App Preferences file is actually located at:"); Out.Ln; Out.String(path); Out.Ln
  END;
  IF app.UserdataPath(path) THEN Out.String("Preferences user data directory is located at:"); Out.Ln; Out.String(path); Out.Ln
  ELSE Out.String("Location of Preferences user data directory not found."); Out.Ln
  END;

  IF wLanguage.SetValue(language) THEN END;

  NEW(bed); app.Group(bed, "Bed");
  bed.GetText("alarm", "8:00", buffer); buffer[79] := 0X;
  wAlarm.SetValue(buffer);
  IF wAmPm.SetValue(bed.Int("ampm", 0)) THEN END;
  IF wWear.SetValue(bed.Int("wear", 1)) THEN END;
  side := bed.Int("side", 2);
  IF side = 1 THEN wLeft.SetValue(TRUE) END;
  IF side = 2 THEN wRight.SetValue(TRUE) END;
  tasks := bed.Int("taskFlags", 5);
  IF ODD(tasks) THEN wShower.SetValue(TRUE) END;
  IF ODD(tasks DIV 2) THEN wShave.SetValue(TRUE) END;
  IF ODD(tasks DIV 4) THEN wBrush.SetValue(TRUE) END;

  NEW(eat); app.Group(eat, "Breakfast");
  IF wDrink.SetValue(eat.Int("drink", 1)) THEN END;
  wMilk.SetValue(eat.Int("wMilk", 0) # 0);
  IF wBread.SetValue(eat.Int("bread", 0)) THEN END;
  wButter.SetValue(eat.Int("wButter", 1) # 0);
  buffer := ""; Num(eat.Int("nEggs", 2), buffer);
  wEggs.SetValue(buffer);
  wMinutes.SetValue(eat.Real("minutes", 3.2D0));
  Tr("NY Times", default);
  n := eat.TextLength("newspaper");
  IF n < LEN(default) THEN n := LEN(default) END;
  NEW(paper, n + 1);
  eat.GetText("newspaper", default, paper^);
  wPaper.SetValue(paper^);
  eat.GetText("foo", "bar", buffer);
  app.Close
END ReadPrefs;

(* b as C's int *)
PROCEDURE Int(b: BOOLEAN): INTEGER;
BEGIN IF b THEN RETURN 1 ELSE RETURN 0 END
END Int;

PROCEDURE WritePrefs;
VAR
  app, bed, eat, eatMore: FlPreferences.Preferences;
  buffer: ARRAY 4096 OF CHAR;
  side, tasks, sum: INTEGER;

  PROCEDURE Found(p: FlPreferences.Preferences; name-: ARRAY OF CHAR);
  BEGIN IF p.HasGroup(name) THEN INC(sum) END
  END Found;

BEGIN
  NEW(app); FlPreferences.Open(app, FlPreferences.User, project, application);
  app.SetInt("language", wLanguage.Value());

  NEW(bed); app.Group(bed, "Bed");
  wAlarm.Value(buffer); bed.SetText("alarm", buffer);
  bed.SetInt("ampm", wAmPm.Value());
  bed.SetInt("wear", wWear.Value());
  side := 0;
  IF wLeft.Value() THEN side := 1 END;
  IF wRight.Value() THEN side := 2 END;
  bed.SetInt("side", side);
  tasks := 0;
  IF wShower.Value() THEN INC(tasks, 1) END;
  IF wShave.Value() THEN INC(tasks, 2) END;
  IF wBrush.Value() THEN INC(tasks, 4) END;
  bed.SetInt("taskFlags", tasks);

  NEW(eat); app.Group(eat, "Breakfast");
  eat.SetInt("drink", wDrink.Value());
  eat.SetInt("wMilk", Int(wMilk.Value()));
  eat.SetInt("bread", wBread.Value());
  eat.SetInt("wButter", Int(wButter.Value()));
  wEggs.Value(buffer); eat.SetText("nEggs", buffer);
  eat.SetReal("minutes", wMinutes.Value());
  wPaper.Value(buffer); eat.SetText("newspaper", buffer);
  (* "bar\nfly\rBackslash: \\ and bell: \007 and delete: \177\n", in C *)
  buffer := "bar|fly|Backslash: \ and bell: | and delete: ||";
  buffer[3] := 0AX; buffer[7] := 0DX; buffer[31] := 07X; buffer[45] := 7FX; buffer[46] := 0AX;
  eat.SetText("foo", buffer);
  eat.SetText("3", "Test3");  (* Fl_Preferences::Name(3) *)

  (* a group in a group *)
  NEW(eatMore); eat.Group(eatMore, "More");
  eatMore.SetText("more", "stuff");

  (* each of these is found *)
  sum := 0;
  Found(app, "Breakfast");         (* eat, from app *)
  Found(app, "Breakfast/More");    (* eatMore, from app *)
  Found(app, "./Breakfast/More");  (* eatMore, from the database *)
  Found(eat, "More");              (* eatMore, from eat *)
  Found(eat, "./Breakfast/More");  (* eatMore, from the database *)
  Found(eat, ".");                 (* eat itself *)
  Found(eat, "./");                (* the database: app *)
  IF sum # 7 THEN
    buffer := "Assertion failed: Not all group entries were found!"; buffer[17] := 0AX;
    FlDialogs.Message(buffer)
  END;
  app.Close
END WritePrefs;

PROCEDURE CloseWindow(w: Fl.Widget);
BEGIN myWindow.Delete
END CloseWindow;

PROCEDURE SaveAndCloseWindow(w: Fl.Widget);
BEGIN WritePrefs; myWindow.Delete
END SaveAndCloseWindow;

PROCEDURE LanguageChanged(w: Fl.Widget);
VAR t: ARRAY 128 OF CHAR;
BEGIN
  Tr("Please restart the app to use your new language setting.", t);
  FlDialogs.Message(t)
END LanguageChanged;

BEGIN
  Translations;
  ReadLanguagePrefs;
  Tr("Cut", s); Tr("Copy", t); Tr("Paste", u);
  FlInputs.SetMenuTexts(s, t, u);
  Tr("My Preferences", s);
  NEW(myWindow); Fl.OpenDoubleWindow(myWindow, 322, 355, s);
  myWindow.action := CloseWindow;
  Tr("Cancel", s);
  NEW(cancel); FlButtons.OpenButton(cancel, 118, 316, 90, 24, s);
  cancel.action := CloseWindow;
  Tr("OK", s);
  NEW(ok); FlButtons.OpenButton(ok, 217, 316, 90, 24, s);
  ok.action := SaveAndCloseWindow;

  Tr("Get Up:", s);
  NEW(group); Fl.OpenGroup(group, 15, 22, 144, 248, s);
  group.SetBoxType(Fl.EngravedFrame);
  group.SetAlign(Fl.AlignTopLeft);
  Tr("Alarm at:", s);
  NEW(wAlarm); FlInputs.OpenInput(wAlarm, 25, 47, 60, 20, s);
  wAlarm.SetAlign(Fl.AlignTopLeft);
  NEW(wAmPm); OpenChoice(wAmPm, 85, 47, 60, 20, "");
  Item(wAmPm, "a.m."); Item(wAmPm, "p.m.");
  NEW(wWear); OpenChoice(wWear, 25, 92, 120, 20, "Wear:");
  wWear.SetAlign(Fl.AlignTopLeft);
  Item(wWear, "shoes"); Item(wWear, "sandals"); Item(wWear, "flip flops"); Item(wWear, "bare foot");
  NEW(group); Fl.OpenGroup(group, 25, 112, 120, 76, "");
  NEW(wLeft); OpenRound(wLeft, 35, 112, 100, 24, "left side");
  NEW(wRight); OpenRound(wRight, 35, 136, 100, 24, "right side");
  Tr("of the bed", s);
  NEW(box); Fl.OpenBox(box, 35, 160, 100, 24, s);
  group.End;
  NEW(wShower); OpenCheck(wShower, 25, 188, 105, 24, "shower");
  NEW(wShave); OpenCheck(wShave, 25, 212, 105, 24, "shave");
  NEW(wBrush); OpenCheck(wBrush, 25, 236, 105, 24, "brush teeth");
  group := group.Parent(); group.End;

  Tr("Breakfast:", s);
  NEW(group); Fl.OpenGroup(group, 163, 22, 144, 248, s);
  group.SetBoxType(Fl.EngravedFrame);
  group.SetAlign(Fl.AlignTopLeft);
  NEW(wDrink); OpenChoice(wDrink, 173, 48, 120, 20, "Drink:");
  wDrink.SetAlign(Fl.AlignTopLeft);
  Item(wDrink, "coffee"); Item(wDrink, "tea"); Item(wDrink, "juice");
  NEW(wMilk); OpenCheck(wMilk, 173, 68, 100, 24, "with milk");
  NEW(wBread); OpenChoice(wBread, 173, 116, 120, 20, "Bread:");
  wBread.SetAlign(Fl.AlignTopLeft);
  Item(wBread, "wheat"); Item(wBread, "white"); Item(wBread, "rye"); Item(wBread, "sourdough");
  NEW(wButter); OpenCheck(wButter, 173, 136, 100, 24, "with butter");
  Tr("eggs", s);
  NEW(wEggs); FlInputs.OpenIntInput(wEggs, 173, 168, 30, 20, s);
  wEggs.SetAlign(Fl.AlignRight);
  Tr("min.", s);
  NEW(wMinutes); FlValuators.OpenHorValueSlider(wMinutes, 173, 196, 70, 20, s);
  wMinutes.SetBounds(2.0D0, 6.0D0);
  wMinutes.SetValue(3.1D0);
  wMinutes.SetAlign(Fl.AlignRight);
  Tr("Newspaper:", s);
  NEW(wPaper); FlInputs.OpenInput(wPaper, 173, 239, 120, 20, s);
  wPaper.SetAlign(Fl.AlignTopLeft);
  group.End;

  NEW(wLanguage); OpenChoice(wLanguage, 185, 283, 105, 20, "Language:");
  wLanguage.action := LanguageChanged;
  Item(wLanguage, "English"); Item(wLanguage, "German");
  myWindow.End;
  ReadPrefs;
  myWindow.ShowArgs;
  Fl.Run
END Preferences.
