MODULE Demo; (* FLTK's test/demo.cxx in Oberon-2 *)

(* The launcher of the other ports: a window of up to nine buttons, each
   a program or a menu of more, read from a menu file of FLTK's form
   (examples/Demo.menu, which names the ports as FLTK's demo.menu names
   its programs). A click on the panel outside the buttons goes back a
   menu, and the right button shows or hides a terminal listing what was
   run.

   A program is run from the directory of Demo itself, as FLTK's are,
   in the background (sh's "&"), with the menu file's directory as the
   working directory, where the files the menu names are. FLTK's demo
   runs fluid and fltk-options from FLTK's build tree; this one runs them
   from PATH, where FLTK installs them. The menu file is the command
   line's argument, or Demo.menu beside the program, or else in
   examples/ beside the program's build/; make test runs it in examples/
   as "Demo Demo.menu". FLTK's demo lists the paths of fluid and
   fltk-options in its terminal too; they have none here. *)

IMPORT Args, Err, Platform, Fl, FlButtons, FlMenus, FlDialogs, FlTerminal, Pipe;

CONST
  FormW = 350; FormH = 440;
  TtyW = 780; TtyH = 200;
  MaxMenu = 32;
  NameLen = 64;  (* as FLTK's: a menu's name, an item's name or command *)

TYPE
  Menu = RECORD
    name: ARRAY NameLen OF CHAR;
    numb: INTEGER;
    iname, icommand: ARRAY 9, NameLen OF CHAR
  END;
  Path = ARRAY 1024 OF CHAR;

VAR
  form: Fl.DoubleWindow;
  tty: FlTerminal.Terminal;
  but: ARRAY 9 OF FlButtons.Button;
  exitButton: FlButtons.Button;
  menus: ARRAY MaxMenu OF Menu;
  mennumb: INTEGER;
  (* the menus shown, the last on top: push_menu's stack *)
  stack: ARRAY 64, 32 OF CHAR;
  stsize: INTEGER;
  appPath, dataPath, menu: Path;
  nl: ARRAY 2 OF CHAR;  (* a line feed *)

  (* button to item for n + 1 items, and item to button: FLTK's tables *)
  b2n, n2b: ARRAY 9, 9 OF INTEGER;

PROCEDURE Row(VAR t: ARRAY OF ARRAY OF INTEGER; r, a, b, c, d, e, f, g, h, i: INTEGER);
BEGIN
  t[r, 0] := a; t[r, 1] := b; t[r, 2] := c; t[r, 3] := d; t[r, 4] := e;
  t[r, 5] := f; t[r, 6] := g; t[r, 7] := h; t[r, 8] := i
END Row;

PROCEDURE Tables;
BEGIN
  Row(b2n, 0, -1, -1, -1, -1,  0, -1, -1, -1, -1);
  Row(b2n, 1, -1, -1, -1,  0, -1,  1, -1, -1, -1);
  Row(b2n, 2,  0, -1, -1, -1,  1, -1, -1, -1,  2);
  Row(b2n, 3,  0, -1,  1, -1, -1, -1,  2, -1,  3);
  Row(b2n, 4,  0, -1,  1, -1,  2, -1,  3, -1,  4);
  Row(b2n, 5,  0, -1,  1,  2, -1,  3,  4, -1,  5);
  Row(b2n, 6,  0, -1,  1,  2,  3,  4,  5, -1,  6);
  Row(b2n, 7,  0,  1,  2,  3, -1,  4,  5,  6,  7);
  Row(b2n, 8,  0,  1,  2,  3,  4,  5,  6,  7,  8);
  Row(n2b, 0,  4, -1, -1, -1, -1, -1, -1, -1, -1);
  Row(n2b, 1,  3,  5, -1, -1, -1, -1, -1, -1, -1);
  Row(n2b, 2,  0,  4,  8, -1, -1, -1, -1, -1, -1);
  Row(n2b, 3,  0,  2,  6,  8, -1, -1, -1, -1, -1);
  Row(n2b, 4,  0,  2,  4,  6,  8, -1, -1, -1, -1);
  Row(n2b, 5,  0,  2,  3,  5,  6,  8, -1, -1, -1);
  Row(n2b, 6,  0,  2,  3,  4,  5,  6,  8, -1, -1);
  Row(n2b, 7,  0,  1,  2,  3,  5,  6,  7,  8, -1);
  Row(n2b, 8,  0,  1,  2,  3,  4,  5,  6,  7,  8)
END Tables;

(* Appends b to a, as far as a holds. *)
PROCEDURE Cat(VAR a: ARRAY OF CHAR; b: ARRAY OF CHAR);
  VAR i, j: INTEGER;
BEGIN
  i := 0; WHILE a[i] # 0X DO INC(i) END;
  j := 0;
  WHILE (b[j] # 0X) & (i < LEN(a) - 1) DO a[i] := b[j]; INC(i); INC(j) END;
  a[i] := 0X
END Cat;

(* Cuts path at its last "/", as FLTK's fix_path does. *)
PROCEDURE StripName(VAR path: ARRAY OF CHAR);
  VAR i, last: INTEGER;
BEGIN
  i := 0; last := -1;
  WHILE path[i] # 0X DO IF path[i] = "/" THEN last := i END; INC(i) END;
  IF last >= 0 THEN path[last] := 0X END
END StripName;

(* Writes "name       = value" and a line feed to the terminal. *)
PROCEDURE DebugVar(name, value: ARRAY OF CHAR);
  VAR s: ARRAY 2 * 1024 + 64 OF CHAR; i: INTEGER;
BEGIN
  COPY(name, s);
  i := 0; WHILE s[i] # 0X DO INC(i) END;
  WHILE i < 10 DO s[i] := " "; INC(i) END;
  s[i] := 0X;
  Cat(s, " = "); Cat(s, value); Cat(s, nl);
  tty.Append(s)
END DebugVar;

PROCEDURE Fatal(a, b, c: ARRAY OF CHAR);
BEGIN
  (* Fl::fatal's default, off Windows *)
  Err.String(a); Err.String(b); Err.String(c); Err.Ln;
  Platform.Exit(1)
END Fatal;

(* Maintaining and building up the menus. *)

PROCEDURE FindMenu(name: ARRAY OF CHAR): INTEGER;
  VAR i: INTEGER;
BEGIN
  FOR i := 0 TO mennumb - 1 DO
    IF menus[i].name = name THEN RETURN i END
  END;
  RETURN -1
END FindMenu;

PROCEDURE CreateMenu(name: ARRAY OF CHAR);
BEGIN
  IF mennumb = MaxMenu - 1 THEN RETURN END;
  COPY(name, menus[mennumb].name);
  menus[mennumb].numb := 0;
  INC(mennumb)
END CreateMenu;

PROCEDURE AddToMenu(men, item, comm: ARRAY OF CHAR);
  VAR n: INTEGER;
BEGIN
  n := FindMenu(men);
  IF n < 0 THEN CreateMenu(men); n := FindMenu(men) END;
  (* FLTK's demo drops the 32nd menu's items, and each past the 9th *)
  IF (n < 0) OR (menus[n].numb = 9) THEN RETURN END;
  COPY(item, menus[n].iname[menus[n].numb]);
  COPY(comm, menus[n].icommand[menus[n].numb]);
  INC(menus[n].numb)
END AddToMenu;

(* Pushing and popping menus *)

PROCEDURE PushMenu(name: ARRAY OF CHAR);
  VAR men, n, i, bn: INTEGER;
BEGIN
  men := FindMenu(name);
  IF men < 0 THEN RETURN END;
  n := menus[men].numb;
  FOR i := 0 TO 8 DO but[i].Hide END;
  FOR i := 0 TO n - 1 DO
    bn := n2b[n - 1, i];
    but[bn].Show;
    but[bn].SetLabel(menus[men].iname[i]);
    IF menus[men].icommand[i, 0] # "@" THEN but[bn].SetTooltip(menus[men].icommand[i])
    ELSE but[bn].SetTooltip("")
    END
  END;
  COPY(name, stack[stsize]);
  INC(stsize)
END PushMenu;

PROCEDURE PopMenu;
  VAR name: ARRAY 32 OF CHAR;
BEGIN
  IF stsize <= 1 THEN RETURN END;
  DEC(stsize, 2);
  COPY(stack[stsize], name);
  PushMenu(name)
END PopMenu;

(* The callbacks *)

(* Shows or hides the terminal: the window grows to show it, and can
   then be resized; it shrinks back to its fixed size without. *)
PROCEDURE ShowTty(show: BOOLEAN);
BEGIN
  IF show THEN
    tty.Show;
    form.SizeRange(FormW, FormH + TtyH DIV 2, 0, 0);
    form.Size(TtyW + 20, FormH + TtyH + 10);
    tty.Size(TtyW, TtyH)
  ELSE
    tty.Hide;
    form.SizeRange(FormW, FormH, FormW, FormH);
    form.Size(FormW, FormH);
    tty.Resize(10, FormH - 1, FormW - 20, 1)
  END;
  form.InitSizes;
  IF exitButton.TakeFocus() THEN END
END ShowTty;

PROCEDURE ShowTtyCb(w: Fl.Widget);
BEGIN ShowTty(TRUE)
END ShowTtyCb;

PROCEDURE HideTtyCb(w: Fl.Widget);
BEGIN ShowTty(FALSE)
END HideTtyCb;

PROCEDURE DoBack(w: Fl.Widget);
BEGIN PopMenu
END DoBack;

PROCEDURE DoExit(w: Fl.Widget);
BEGIN Platform.Exit(0)
END DoExit;

(* Runs a button's program, or shows its menu. *)
PROCEDURE DoBut(w: Fl.Widget);
  VAR men, n, bn, b, i, j: INTEGER;
    cmd, params: ARRAY NameLen OF CHAR;
    command: ARRAY 2 * 1024 + 40 OF CHAR;
    name: ARRAY 32 OF CHAR;
BEGIN
  b := 0; WHILE but[b] # w DO INC(b) END;
  COPY(stack[stsize - 1], name);
  men := FindMenu(name);
  n := menus[men].numb;
  bn := b2n[n - 1, b];
  IF menus[men].icommand[bn, 0] = "@" THEN
    PushMenu(menus[men].icommand[bn]);
    RETURN
  END;
  (* the command, without its leading spaces, and its parameters *)
  i := 0; WHILE menus[men].icommand[bn, i] = " " DO INC(i) END;
  j := 0;
  WHILE (menus[men].icommand[bn, i] # 0X) & (menus[men].icommand[bn, i] # " ") DO
    cmd[j] := menus[men].icommand[bn, i]; INC(i); INC(j)
  END;
  cmd[j] := 0X;
  params := "";
  IF menus[men].icommand[bn, i] = " " THEN
    INC(i); j := 0;
    WHILE menus[men].icommand[bn, i] # 0X DO
      params[j] := menus[men].icommand[bn, i]; INC(i); INC(j)
    END;
    params[j] := 0X
  END;
  (* FLTK's tools from PATH, as FLTK compares: "fluid", "fltk-" *)
  IF (cmd[0] = "f") & (cmd[1] = "l") & ((cmd[2] = "u") & (cmd[3] = "i") & (cmd[4] = "d")
      OR (cmd[2] = "t") & (cmd[3] = "k") & (cmd[4] = "-")) THEN
    command := ""
  ELSE
    COPY(appPath, command); Cat(command, "/")
  END;
  Cat(command, cmd);
  IF params # "" THEN Cat(command, " "); Cat(command, params) END;
  Cat(command, " &");
  DebugVar("Command", command);
  (* FLTK's alert gives errno too, which Platform doesn't *)
  IF Platform.System(command) = -1 THEN
    COPY("Could not start program", params);
    FlDialogs.Alert(params)
  END
END DoBut;

(* Loads the menu file. Returns whether successful. *)
PROCEDURE LoadTheMenu(name: ARRAY OF CHAR): BOOLEAN;
  VAR f: Pipe.Pipe; line: ARRAY 256 OF CHAR;
    mname, iname, cname: ARRAY NameLen OF CHAR;
    i, j, k: INTEGER;

  (* the end of a field: ":", the line's end, or the text's *)
  PROCEDURE End(c: CHAR): BOOLEAN;
  BEGIN RETURN (c = ":") OR (c = 0AX) OR (c = 0X)
  END End;

BEGIN
  NEW(f);
  IF ~Pipe.OpenFile(f, name) THEN RETURN FALSE END;
  WHILE f.ReadLine(line) DO
    (* remove the carriage returns *)
    i := 0; k := 0;
    REPEAT
      IF line[i] # 0DX THEN line[k] := line[i]; INC(k) END; INC(i)
    UNTIL line[i - 1] = 0X;
    i := 0;
    WHILE (line[i] = " ") OR (line[i] = 09X) DO INC(i) END;
    IF (line[i] # 0AX) & (line[i] # 0X) & (line[i] # "#") THEN
      j := 0;
      WHILE ~End(line[i]) DO
        IF j < NameLen - 1 THEN mname[j] := line[i]; INC(j) END; INC(i)
      END;
      mname[j] := 0X;
      IF line[i] = ":" THEN INC(i) END;
      j := 0;
      WHILE ~End(line[i]) DO
        IF (line[i] = "\") & (line[i + 1] # 0X) THEN
          INC(i);
          IF line[i] = "n" THEN line[i] := 0AX END
        END;
        IF j < NameLen - 1 THEN iname[j] := line[i]; INC(j) END; INC(i)
      END;
      iname[j] := 0X;
      IF line[i] = ":" THEN INC(i) END;
      j := 0;
      WHILE ~End(line[i]) DO
        IF j < NameLen - 1 THEN cname[j] := line[i]; INC(j) END; INC(i)
      END;
      cname[j] := 0X;
      AddToMenu(mname, iname, cname)
    END
  END;
  RETURN f.Close() = 0
END LoadTheMenu;

PROCEDURE Button(VAR b: FlButtons.Button; x, y, w, h: INTEGER; label: ARRAY OF CHAR);
BEGIN NEW(b); FlButtons.OpenButton(b, x, y, w, h, label)
END Button;

PROCEDURE CreateTheForms;
  VAR demogrp: Fl.Group; box: Fl.Box; b: FlButtons.Button;
    scheme: FlMenus.SchemeChoice; popup: FlMenus.MenuButton; i: INTEGER;
BEGIN
  NEW(form); Fl.OpenDoubleWindow(form, FormW, FormH, "FLTK Demonstration");
  (* the demo's group *)
  NEW(demogrp); Fl.OpenGroup(demogrp, 0, 0, FormW, FormH - 1, "");
  (* the title *)
  NEW(box); Fl.OpenBox(box, 10, 15, 330, 40, "FLTK Demonstration");
  box.SetBoxType(Fl.EngravedBox);  (* FL_FRAME_BOX *)
  box.SetColor(Fl.Gray - 4);
  box.SetLabelSize(24);
  box.SetLabelFont(Fl.Bold);
  box.SetLabelType(Fl.EngravedLabel);
  NEW(box); Fl.OpenBox(box, 10, 65, 330, 330, "");
  box.SetBoxType(Fl.EngravedBox);
  box.SetColor(Fl.Gray - 8);
  NEW(scheme); FlMenus.OpenSchemeChoice(scheme, 90, 405, 100, 25, "Scheme:");
  scheme.SetLabelFont(Fl.HelveticaBold);
  Button(exitButton, 280, 405, 60, 25, "Exit");
  exitButton.action := DoExit;
  IF exitButton.TakeFocus() THEN END;
  (* the panel behind the buttons: a click goes back a menu *)
  Button(b, 10, 15, 330, 380, "");
  b.SetKind(FlButtons.Hidden);
  b.action := DoBack;
  b.SetTooltip("Use right mouse button to show/hide debug terminal");
  FOR i := 0 TO 8 DO
    Button(but[i], 30 + i MOD 3 * 100, 85 + i DIV 3 * 100, 90, 90, "");
    but[i].SetAlign(Fl.AlignWrap);
    but[i].action := DoBut
  END;
  (* the right button's menu, over the whole group *)
  NEW(popup); FlMenus.OpenMenuButton(popup, 0, 0, FormW, FormH, "");
  popup.SetBoxType(Fl.NoBox);
  popup.SetKind(FlMenus.Popup3);
  IF popup.Add("Show debug terminal", 0, {}, ShowTtyCb, {}) >= 0 THEN END;
  IF popup.Add("Hide debug terminal", 0, {}, HideTtyCb, {}) >= 0 THEN END;
  (* so that the demo isn't resized with the window when the terminal shows *)
  NEW(box); Fl.OpenBox(box, FormW - 1, 0, 1, FormH, "");
  box.SetBoxType(Fl.NoBox);
  demogrp.SetResizable(box);
  demogrp.End;
  (* the terminal, in the window, not the demo's group *)
  NEW(tty); FlTerminal.OpenTerminal(tty, 10, FormH - 1, FormW - 20, 1, "");
  tty.SetHistoryRows(50);
  tty.SetDisplayRows(2);
  tty.SetDisplayColumns(100);
  tty.SetAnsi(TRUE);
  tty.Hide;
  tty.SetTextSize(12);
  form.End;
  form.SetResizable(tty)
END CreateTheForms;

PROCEDURE Main;
  VAR i: INTEGER; arg, s, help: Path; ok: BOOLEAN; id: Platform.FileIdentity;
BEGIN
  nl[0] := 0AX; nl[1] := 0X;
  Tables;
  Args.Get(0, arg);
  IF FlDialogs.FilenameAbsolute(arg, appPath) THEN END;
  StripName(appPath);
  dataPath := appPath;
  (* the menu file: <data path>/<the program's name>.menu *)
  COPY(dataPath, menu); Cat(menu, "/");
  FlDialogs.FilenameName(arg, s); Cat(menu, s);
  FlDialogs.FilenameSetExt(menu, ".menu");
  (* not there: this repository's examples/, beside build/, where FLTK's
     CMake build has its data/ beside bin/ *)
  IF Platform.IdentifyByName(menu, id) # 0 THEN
    COPY(appPath, dataPath); StripName(dataPath); Cat(dataPath, "/examples");
    COPY(dataPath, menu); Cat(menu, "/");
    FlDialogs.FilenameName(arg, s); Cat(menu, s);
    FlDialogs.FilenameSetExt(menu, ".menu")
  END;
  i := 1;
  ok := Fl.ParseArgs(NIL, i);
  IF ~ok OR (i < Args.argc - 1) THEN
    (* Fl::fatal's default, off Windows *)
    Fl.ArgsHelp(help);
    Err.String("Usage: "); Err.String(arg); Err.String(" <switches> <menufile>"); Err.Ln;
    Err.String(help); Err.Ln;
    Platform.Exit(1)
  END;
  IF i < Args.argc THEN
    (* the menu file and the data path both *)
    Args.Get(i, s);
    IF FlDialogs.FilenameAbsolute(s, menu) THEN END;
    dataPath := menu; StripName(dataPath)
  END;
  IF Platform.Chdir(dataPath) # 0 THEN (* ignored *) END;
  CreateTheForms;
  DebugVar("app_path", appPath);
  DebugVar("data_path", dataPath);
  DebugVar("menu file", menu);
  DebugVar("cwd", Platform.CWD);
  tty.Append(nl);
  IF ~LoadTheMenu(menu) THEN Fatal("Can't open menu file '", menu, "'") END;
  PushMenu("@main");
  form.ShowArgs;
  form.SizeRange(FormW, FormH, FormW, FormH);
  Fl.Run
END Main;

BEGIN Main
END Demo.
