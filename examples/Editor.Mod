MODULE Editor; (* FLTK's test/editor.cxx in Oberon-2 *)

(* The editor of the FLTK Programmer's Guide's chapter "Designing a Simple
   Text Editor", as FLTK's build has it, at its tutorial's last chapter,
   10: a menu bar, a text editor that can be split in two, files, cut,
   copy and paste, find and replace, line numbers, word wrap and the
   highlighting of C and C++. A word on the command line not an option is
   a file to load. FLTK's fl_open_callback, for files opened from macOS's
   Finder, is left out: it is macOS's alone. *)

IMPORT SYSTEM, Args, OutStr, Platform, Fl, FlButtons, FlInputs, FlLayout,
  FlMenus, FlDialogs, FlText;

CONST
  PathMax = 2048;  (* FL_PATH_MAX *)
  TS = 14;         (* the editor's text size *)

TYPE
  Name = ARRAY PathMax OF CHAR;
  Text = POINTER TO ARRAY OF CHAR;
  Word = ARRAY 13 OF CHAR;

  (* The text, which marks the file changed, and restyles itself while it
     is highlighted: FLTK's text_changed_callback and style_update. *)
  Buffer = POINTER TO RECORD (FlText.TextBufferDesc) END;

  (* The Find and Replace dialog. *)
  ReplaceDialog = POINTER TO RECORD (Fl.DoubleWindowDesc)
    findTextInput, replaceTextInput: FlInputs.Input;
    findNextButton, replaceAndFindButton, closeButton: FlButtons.Button
  END;

VAR
  appWindow: Fl.DoubleWindow;
  appMenuBar: FlMenus.MenuBar;
  textChanged: BOOLEAN;
  appFilename: Name;
  appEditor, appSplitEditor: FlText.TextEditor;
  appTextBuffer: Buffer;
  lastFindText, lastReplaceText: ARRAY 1024 OF CHAR;
  replaceDialog: ReplaceDialog;
  appTile: FlLayout.Tile;
  appStyleBuffer: FlText.TextBuffer;
  highlighting: BOOLEAN;  (* whether style_update is a modify callback *)
  codeKeywords: ARRAY 34 OF Word;  (* C and C++'s keywords, sorted *)
  codeTypes: ARRAY 36 OF Word;     (* and its types *)
  i: INTEGER;
  ok: BOOLEAN;

PROCEDURE ["C", "strerror"] StrError(e: SYSTEM.INT32): SYSTEM.ADDRESS;

(* Appends strerror(errno) to s. *)
PROCEDURE AppendError(e: INTEGER; VAR s: ARRAY OF CHAR);
  VAR a: SYSTEM.ADDRESS; c: CHAR;
BEGIN
  a := StrError(e);
  SYSTEM.GET(a, c);
  WHILE c # 0X DO OutStr.Char(c, s); INC(a); SYSTEM.GET(a, c) END
END AppendError;

(* FlDialogs.Choice, with each "|" of text a line feed *)
PROCEDURE Choice(text, b0, b1, b2: ARRAY OF CHAR): INTEGER;
  VAR s: ARRAY 256 OF CHAR; i: INTEGER;
BEGIN
  COPY(text, s);
  i := 0; WHILE s[i] # 0X DO IF s[i] = "|" THEN s[i] := 0AX END; INC(i) END;
  RETURN FlDialogs.Choice(s, b0, b1, b2)
END Choice;

(* Tutorial chapter 2: the menu bar and the window's title *)

PROCEDURE UpdateTitle;
  VAR fname: Name; buf: ARRAY PathMax + 3 OF CHAR;
BEGIN
  IF appFilename[0] # 0X THEN
    FlDialogs.FilenameName(appFilename, fname);
    buf := ""; OutStr.String(fname, buf);
    IF textChanged THEN OutStr.String(" *", buf) END;
    appWindow.SetLabel(buf)
  ELSE
    appWindow.SetLabel("FLTK Editor")
  END
END UpdateTitle;

PROCEDURE SetChanged(v: BOOLEAN);
BEGIN
  IF v # textChanged THEN
    textChanged := v;
    UpdateTitle
  END
END SetChanged;

(* "" is none. *)
PROCEDURE SetFilename(newFilename: ARRAY OF CHAR);
BEGIN
  COPY(newFilename, appFilename);
  UpdateTitle
END SetFilename;

(* Tutorial chapter 3: the editor *)

PROCEDURE MenuNewCallback(w: Fl.Widget);
  VAR c: INTEGER;
BEGIN
  IF textChanged THEN
    c := Choice(
      "Changes in your text have not been saved.|Do you want to start a new text anyway?",
      "New", "Cancel", "");
    IF c = 1 THEN RETURN END
  END;
  appTextBuffer.SetText("");
  SetFilename("");
  SetChanged(FALSE)
END MenuNewCallback;

(* Tutorial chapter 4: files *)

(* Offers chooser the file name, and its directory, to start with. *)
PROCEDURE Preset(chooser: FlDialogs.NativeFileChooser);
  VAR tempFilename, name: Name; n: INTEGER;
BEGIN
  IF appFilename[0] # 0X THEN
    COPY(appFilename, tempFilename);
    FlDialogs.FilenameName(tempFilename, name);
    chooser.SetPresetFile(name);
    n := 0; WHILE tempFilename[n] # 0X DO INC(n) END;
    i := 0; WHILE name[i] # 0X DO INC(i); DEC(n) END;
    tempFilename[n] := 0X;
    chooser.SetDirectory(tempFilename)
  END
END Preset;

(* The alert for a file not loaded or saved. *)
PROCEDURE Failed(what, name: ARRAY OF CHAR; e: INTEGER);
  VAR s: ARRAY 2 * PathMax OF CHAR;
BEGIN
  s := ""; OutStr.String(what, s); OutStr.Char(0AX, s);
  OutStr.String(name, s); OutStr.Char(0AX, s);
  AppendError(e, s);
  FlDialogs.Alert(s)
END Failed;

PROCEDURE MenuSaveAsCallback(w: Fl.Widget);
  VAR fileChooser: FlDialogs.NativeFileChooser; name: Name;
BEGIN
  NEW(fileChooser); FlDialogs.OpenNativeFileChooser(fileChooser, FlDialogs.BrowseSaveFile);
  fileChooser.SetTitle("Save File As...");
  Preset(fileChooser);
  IF fileChooser.Show() = FlDialogs.Chosen THEN
    fileChooser.FileName(0, name);
    IF appTextBuffer.SaveFile(name) THEN
      SetFilename(name);
      SetChanged(FALSE)
    ELSE
      Failed("Failed to save file", name, Platform.Error())
    END
  END;
  fileChooser.Close
END MenuSaveAsCallback;

PROCEDURE MenuSaveCallback(w: Fl.Widget);
BEGIN
  IF appFilename[0] = 0X THEN
    MenuSaveAsCallback(NIL)
  ELSE
    IF appTextBuffer.SaveFile(appFilename) THEN
      SetChanged(FALSE)
    ELSE
      Failed("Failed to save file", appFilename, Platform.Error())
    END
  END
END MenuSaveCallback;

(* The window's callback too: closing it, or Escape. *)
PROCEDURE MenuQuitCallback(w: Fl.Widget);
  VAR r: INTEGER;
BEGIN
  IF textChanged THEN
    r := Choice(
      "The current file has not been saved.|Would you like to save it now?",
      "Cancel", "Save", "Don't Save");
    IF r = 0 THEN RETURN END;  (* cancel *)
    IF r = 1 THEN              (* save *)
      MenuSaveCallback(NIL);
      RETURN
    END
  END;
  Fl.HideAllWindows
END MenuQuitCallback;

PROCEDURE Load(filename: ARRAY OF CHAR);
BEGIN
  IF appTextBuffer.LoadFile(filename) THEN
    SetFilename(filename);
    SetChanged(FALSE)
  ELSE
    Failed("Failed to load file", filename, Platform.Error())
  END
END Load;

PROCEDURE MenuOpenCallback(w: Fl.Widget);
  VAR r: INTEGER; fileChooser: FlDialogs.NativeFileChooser; name: Name;
BEGIN
  IF textChanged THEN
    r := Choice(
      "The current file has not been saved.|Would you like to save it now?",
      "Cancel", "Save", "Don't Save");
    IF r = 0 THEN RETURN END;               (* cancel *)
    IF r = 1 THEN MenuSaveCallback(NIL) END (* save *)
  END;
  NEW(fileChooser); FlDialogs.OpenNativeFileChooser(fileChooser, FlDialogs.BrowseFile);
  fileChooser.SetTitle("Open File...");
  Preset(fileChooser);
  IF fileChooser.Show() = FlDialogs.Chosen THEN
    fileChooser.FileName(0, name);
    Load(name)
  END;
  fileChooser.Close
END MenuOpenCallback;

(* A word on the command line not an option is a file to load. *)
PROCEDURE ArgsHandler(i: INTEGER): INTEGER;
  VAR arg: Name;
BEGIN
  Args.Get(i, arg);
  IF arg[0] # "-" THEN
    Load(arg);
    RETURN 1
  END;
  RETURN 0
END ArgsHandler;

(* Tutorial chapter 5: cut, copy and paste *)

(* Calls editing function kf of the editor with the focus, if one has it. *)
PROCEDURE EditFocus(kf: INTEGER);
  VAR e: Fl.Widget;
BEGIN
  e := Fl.Focus();
  IF (e # NIL) & ((e = appEditor) OR (e = appSplitEditor)) THEN
    IF e(FlText.TextEditor).Builtin(kf, 0) THEN END
  END
END EditFocus;

PROCEDURE MenuUndoCallback(w: Fl.Widget);
BEGIN EditFocus(FlText.KfUndo)
END MenuUndoCallback;

PROCEDURE MenuRedoCallback(w: Fl.Widget);
BEGIN EditFocus(FlText.KfRedo)
END MenuRedoCallback;

PROCEDURE MenuCutCallback(w: Fl.Widget);
BEGIN EditFocus(FlText.KfCut)
END MenuCutCallback;

PROCEDURE MenuCopyCallback(w: Fl.Widget);
BEGIN EditFocus(FlText.KfCopy)
END MenuCopyCallback;

PROCEDURE MenuPasteCallback(w: Fl.Widget);
BEGIN EditFocus(FlText.KfPaste)
END MenuPasteCallback;

PROCEDURE MenuDeleteCallback(w: Fl.Widget);
BEGIN EditFocus(FlText.KfDelete)
END MenuDeleteCallback;

(* Tutorial chapter 6: find *)

(* The editor with the focus, if the split one has it, else the first. *)
PROCEDURE FocusEditor(): FlText.TextEditor;
  VAR e: Fl.Widget;
BEGIN
  e := Fl.Focus();
  IF (e # NIL) & (e = appSplitEditor) THEN RETURN appSplitEditor END;
  RETURN appEditor
END FocusEditor;

PROCEDURE Length(s: ARRAY OF CHAR): INTEGER;
  VAR n: INTEGER;
BEGIN
  n := 0; WHILE s[n] # 0X DO INC(n) END;
  RETURN n
END Length;

PROCEDURE FindNext(needle: ARRAY OF CHAR): BOOLEAN;
  VAR editor: FlText.TextEditor; pos: INTEGER; s: ARRAY 1100 OF CHAR;
BEGIN
  editor := FocusEditor();
  pos := editor.InsertPosition();
  IF appTextBuffer.SearchForward(pos, needle, FALSE, pos) THEN
    appTextBuffer.Select(pos, pos + Length(needle));
    editor.SetInsertPosition(pos + Length(needle));
    editor.ShowInsertPosition;
    RETURN TRUE
  ELSE
    s := "No further occurrences of '"; OutStr.String(needle, s);
    OutStr.String("' found!", s);
    FlDialogs.Alert(s);
    RETURN FALSE
  END
END FindNext;

PROCEDURE MenuFindCallback(w: Fl.Widget);
  VAR findText: ARRAY 1024 OF CHAR;
BEGIN
  findText := lastFindText;
  IF FlDialogs.Input("Find in text:", findText) THEN
    lastFindText := findText;
    ok := FindNext(findText)
  END
END MenuFindCallback;

PROCEDURE MenuFindNextCallback(w: Fl.Widget);
BEGIN
  IF lastFindText[0] # 0X THEN
    ok := FindNext(lastFindText)
  ELSE
    MenuFindCallback(NIL)
  END
END MenuFindNextCallback;

(* Tutorial chapter 7: replace *)

PROCEDURE ReplaceSelection(newText: ARRAY OF CHAR);
  VAR editor: FlText.TextEditor; start, end: INTEGER;
BEGIN
  editor := FocusEditor();
  IF appTextBuffer.Selection(start, end) THEN
    appTextBuffer.RemoveSelection;
    appTextBuffer.Insert(start, newText);
    appTextBuffer.Select(start, start + Length(newText));
    editor.SetInsertPosition(start + Length(newText));
    editor.ShowInsertPosition
  END
END ReplaceSelection;

(* The dialog shows the last texts found and replaced. *)
PROCEDURE (d: ReplaceDialog) Show*;
BEGIN
  d.findTextInput.SetValue(lastFindText);
  d.replaceTextInput.SetValue(lastReplaceText);
  d.Show^
END Show;

PROCEDURE FindNextCallback(w: Fl.Widget);
BEGIN
  replaceDialog.findTextInput.Value(lastFindText);
  replaceDialog.replaceTextInput.Value(lastReplaceText);
  IF lastFindText[0] # 0X THEN
    ok := FindNext(lastFindText)
  END
END FindNextCallback;

PROCEDURE ReplaceAndFindCallback(w: Fl.Widget);
  VAR s: ARRAY 1024 OF CHAR;
BEGIN
  replaceDialog.replaceTextInput.Value(s);
  ReplaceSelection(s);
  FindNextCallback(NIL)
END ReplaceAndFindCallback;

PROCEDURE CloseCallback(w: Fl.Widget);
BEGIN replaceDialog.Hide
END CloseCallback;

(* As FLTK's constructor, which leaves the dialog the current group, as
   this does: nothing is made after it but FLTK's own dialogs, which put
   the current group aside. *)
PROCEDURE NewReplaceDialog(label: ARRAY OF CHAR): ReplaceDialog;
  VAR d: ReplaceDialog; buttonField: FlLayout.Flex;
BEGIN
  NEW(d); Fl.OpenDoubleWindow(d, 430, 110, label);
  NEW(d.findTextInput); FlInputs.OpenInput(d.findTextInput, 100, 10, 320, 25, "Find:");
  NEW(d.replaceTextInput); FlInputs.OpenInput(d.replaceTextInput, 100, 40, 320, 25, "Replace:");
  NEW(buttonField); FlLayout.OpenFlex(buttonField, 100, 70, d.W() - 100, 40, "");
  buttonField.SetKind(FlLayout.Row);
  buttonField.SetMargins(0, 5, 10, 10);
  buttonField.SetGap(10);
  NEW(d.findNextButton); FlButtons.OpenButton(d.findNextButton, 0, 0, 0, 0, "Next");
  d.findNextButton.action := FindNextCallback;
  NEW(d.replaceAndFindButton); FlButtons.OpenButton(d.replaceAndFindButton, 0, 0, 0, 0, "Replace");
  d.replaceAndFindButton.action := ReplaceAndFindCallback;
  NEW(d.closeButton); FlButtons.OpenButton(d.closeButton, 0, 0, 0, 0, "Close");
  d.closeButton.action := CloseCallback;
  buttonField.End;
  d.SetNonModal;
  RETURN d
END NewReplaceDialog;

PROCEDURE MenuReplaceCallback(w: Fl.Widget);
BEGIN
  IF replaceDialog = NIL THEN
    replaceDialog := NewReplaceDialog("Find and Replace")
  END;
  replaceDialog.Show
END MenuReplaceCallback;

PROCEDURE MenuReplaceNextCallback(w: Fl.Widget);
BEGIN
  IF lastFindText[0] = 0X THEN
    MenuReplaceCallback(NIL)
  ELSE
    ReplaceSelection(lastReplaceText);
    ok := FindNext(lastFindText)
  END
END MenuReplaceNextCallback;

(* Tutorial chapter 8: line numbers and word wrap *)

(* Whether the toggle just picked in menu w is on. *)
PROCEDURE Checked(w: Fl.Widget): BOOLEAN;
  VAR menu: FlMenus.Menu;
BEGIN
  menu := w(FlMenus.Menu);
  RETURN menu.ItemFlags(menu.Value()) * FlMenus.MenuValue # {}
END Checked;

PROCEDURE MenuLinenumbersCallback(w: Fl.Widget);
  VAR on: BOOLEAN;
BEGIN
  on := Checked(w);
  IF on THEN appEditor.SetLineNumberWidth(40)
  ELSE appEditor.SetLineNumberWidth(0)
  END;
  appEditor.Redraw;
  IF appSplitEditor # NIL THEN
    IF on THEN appSplitEditor.SetLineNumberWidth(40)
    ELSE appSplitEditor.SetLineNumberWidth(0)
    END;
    appSplitEditor.Redraw
  END
END MenuLinenumbersCallback;

PROCEDURE MenuWordwrapCallback(w: Fl.Widget);
  VAR on: BOOLEAN;
BEGIN
  on := Checked(w);
  IF on THEN appEditor.SetWrapMode(FlText.WrapAtBounds, 0)
  ELSE appEditor.SetWrapMode(FlText.WrapNone, 0)
  END;
  appEditor.Redraw;
  IF appSplitEditor # NIL THEN
    IF on THEN appSplitEditor.SetWrapMode(FlText.WrapAtBounds, 0)
    ELSE appSplitEditor.SetWrapMode(FlText.WrapNone, 0)
    END;
    appSplitEditor.Redraw
  END
END MenuWordwrapCallback;

(* Tutorial chapter 9: the split editor *)

PROCEDURE MenuSplitCallback(w: Fl.Widget);
  VAR hSplit: INTEGER;
BEGIN
  IF Checked(w) THEN
    hSplit := appTile.H() DIV 2;
    appEditor.Size(appTile.W(), hSplit);
    appSplitEditor.Resize(appTile.X(), appTile.Y() + hSplit,
      appTile.W(), appTile.H() - hSplit);
    appSplitEditor.Show
  ELSE
    appEditor.Size(appTile.W(), appTile.H());
    appSplitEditor.Resize(appTile.X(), appTile.Y() + appTile.H(),
      appTile.W(), 0);
    appSplitEditor.Hide
  END;
  appTile.SetResizable(appEditor);
  appTile.InitSizes;
  appTile.Redraw
END MenuSplitCallback;

(* Tutorial chapter 10: syntax highlighting *)

PROCEDURE InitWords;
  VAR n: INTEGER;

  PROCEDURE K(w: ARRAY OF CHAR);
  BEGIN COPY(w, codeKeywords[n]); INC(n)
  END K;

  PROCEDURE T(w: ARRAY OF CHAR);
  BEGIN COPY(w, codeTypes[n]); INC(n)
  END T;

BEGIN
  n := 0;
  K("and"); K("and_eq"); K("asm"); K("bitand"); K("bitor"); K("break");
  K("case"); K("catch"); K("compl"); K("continue"); K("default");
  K("delete"); K("do"); K("else"); K("false"); K("for"); K("goto");
  K("if"); K("new"); K("not"); K("not_eq"); K("operator"); K("or");
  K("or_eq"); K("return"); K("switch"); K("template"); K("this");
  K("throw"); K("true"); K("try"); K("while"); K("xor"); K("xor_eq");
  ASSERT(n = LEN(codeKeywords));
  n := 0;
  T("auto"); T("bool"); T("char"); T("class"); T("const");
  T("const_cast"); T("double"); T("dynamic_cast"); T("enum");
  T("explicit"); T("extern"); T("float"); T("friend"); T("inline");
  T("int"); T("long"); T("mutable"); T("namespace"); T("private");
  T("protected"); T("public"); T("register"); T("short"); T("signed");
  T("sizeof"); T("static"); T("static_cast"); T("struct"); T("template");
  T("typedef"); T("typename"); T("union"); T("unsigned"); T("virtual");
  T("void"); T("volatile");
  ASSERT(n = LEN(codeTypes))
END InitWords;

(* Whether word is in the sorted list: FLTK's bsearch. *)
PROCEDURE Known(word: ARRAY OF CHAR; VAR list: ARRAY OF Word): BOOLEAN;
  VAR lo, hi, mid: INTEGER;
BEGIN
  lo := 0; hi := SHORT(LEN(list)) - 1;
  WHILE lo <= hi DO
    mid := (lo + hi) DIV 2;
    IF word = list[mid] THEN RETURN TRUE
    ELSIF word < list[mid] THEN hi := mid - 1
    ELSE lo := mid + 1
    END
  END;
  RETURN FALSE
END Known;

(* islower and isalnum, of ASCII: FLTK's program runs in the C locale. *)
PROCEDURE Lower(c: CHAR): BOOLEAN;
BEGIN RETURN (c >= "a") & (c <= "z")
END Lower;

PROCEDURE AlNum(c: CHAR): BOOLEAN;
BEGIN RETURN Lower(c) OR (c >= "A") & (c <= "Z") OR (c >= "0") & (c <= "9")
END AlNum;

(* Styles length bytes of text, each text[i] getting style[i]:
     A - Plain
     B - Line comments
     C - Block comments
     D - Strings
     E - Directives
     F - Types
     G - Keywords
   text has a 0X after them, and style[0] is the style the text starts
   in. FLTK's style_parse walks a pointer to each; here one index does. *)
PROCEDURE StyleParse(VAR text, style: ARRAY OF CHAR; length: INTEGER);
  VAR
    current: CHAR;
    col, i, j, k: INTEGER;
    last, next: BOOLEAN;  (* next: the character's style is set: C's continue *)
    buf: ARRAY 255 OF CHAR;
BEGIN
  current := style[0]; col := 0; last := FALSE; i := 0;
  WHILE i < length DO
    next := FALSE;
    IF (current = "B") OR (current = "F") OR (current = "G") THEN current := "A" END;
    IF current = "A" THEN
      (* Check for directives, comments, strings, and keywords... *)
      IF (col = 0) & (text[i] = "#") THEN
        (* Set style to directive *)
        current := "E"
      ELSIF (text[i] = "/") & (text[i + 1] = "/") THEN
        current := "B";
        WHILE (i < length) & (text[i] # 0AX) DO style[i] := "B"; INC(i) END;
        IF i = length THEN RETURN END
      ELSIF (text[i] = "/") & (text[i + 1] = "*") THEN
        current := "C"
      ELSIF (text[i] = "\") & (text[i + 1] = '"') THEN
        (* Quoted quote... *)
        style[i] := current; style[i + 1] := current;
        INC(i, 2); INC(col, 2); next := TRUE
      ELSIF text[i] = '"' THEN
        current := "D"
      ELSIF ~last & (Lower(text[i]) OR (text[i] = "_")) THEN
        (* Might be a keyword... *)
        j := i; k := 0;
        WHILE (Lower(text[j]) OR (text[j] = "_")) & (k < LEN(buf) - 1) DO
          buf[k] := text[j]; INC(k); INC(j)
        END;
        IF ~Lower(text[j]) & (text[j] # "_") THEN
          buf[k] := 0X;
          IF Known(buf, codeTypes) THEN
            WHILE i < j DO style[i] := "F"; INC(i); INC(col) END;
            last := TRUE; next := TRUE
          ELSIF Known(buf, codeKeywords) THEN
            WHILE i < j DO style[i] := "G"; INC(i); INC(col) END;
            last := TRUE; next := TRUE
          END
        END
      END
    ELSIF (current = "C") & (text[i] = "*") & (text[i + 1] = "/") THEN
      (* Close a C comment... *)
      style[i] := current; style[i + 1] := current;
      INC(i, 2); current := "A"; INC(col, 2); next := TRUE
    ELSIF current = "D" THEN
      (* Continuing in string... *)
      IF (text[i] = "\") & (text[i + 1] = '"') THEN
        (* Quoted end quote... *)
        style[i] := current; style[i + 1] := current;
        INC(i, 2); INC(col, 2); next := TRUE
      ELSIF text[i] = '"' THEN
        (* End quote... *)
        style[i] := current; INC(i); INC(col);
        current := "A"; next := TRUE
      END
    END;
    IF ~next THEN
      (* Copy style info... *)
      IF (current = "A") & ((text[i] = "{") OR (text[i] = "}")) THEN style[i] := "G"
      ELSE style[i] := current
      END;
      INC(col);
      last := AlNum(text[i]) OR (text[i] = "_") OR (text[i] = ".");
      IF text[i] = 0AX THEN
        (* Reset column and possibly reset the style *)
        col := 0;
        IF (current = "B") OR (current = "E") THEN current := "A" END
      END;
      INC(i)
    END
  END
END StyleParse;

(* Styles the whole text. *)
PROCEDURE StyleInit;
  VAR style, text: Text; n, i: INTEGER;
BEGIN
  n := appTextBuffer.Length();
  NEW(style, n + 1); NEW(text, n + 1);
  appTextBuffer.GetText(text^);
  FOR i := 0 TO n - 1 DO style[i] := "A" END;
  style[n] := 0X;
  IF appStyleBuffer = NIL THEN NEW(appStyleBuffer); FlText.OpenBuffer(appStyleBuffer) END;
  StyleParse(text^, style^, n);
  appStyleBuffer.SetText(style^)
END StyleInit;

(* Restyles the text after a change: the styles of what was inserted,
   then the lines it touched, and the rest of the text if the last
   line's last style changed. FLTK's style_update. *)
PROCEDURE StyleUpdate(pos, nInserted, nDeleted: INTEGER);
  VAR start, end, i: INTEGER; last: CHAR; style, text: Text;

  PROCEDURE Restyle;
  BEGIN
    NEW(text, end - start + 1); NEW(style, end - start + 1);
    appTextBuffer.TextRange(start, end, text^);
    appStyleBuffer.TextRange(start, end, style^);
    StyleParse(text^, style^, end - start);
    appStyleBuffer.Replace(start, end, style^);
    appEditor.RedisplayRange(start, end)
  END Restyle;

BEGIN
  (* If this is just a selection change, just unselect the style buffer... *)
  IF (nInserted = 0) & (nDeleted = 0) THEN
    appStyleBuffer.Unselect;
    RETURN
  END;
  (* Track changes in the text buffer... *)
  IF nInserted > 0 THEN
    (* Insert characters into the style buffer... *)
    NEW(style, nInserted + 1);
    FOR i := 0 TO nInserted - 1 DO style[i] := "A" END;
    style[nInserted] := 0X;
    appStyleBuffer.Replace(pos, pos + nDeleted, style^)
  ELSE
    (* Just delete characters in the style buffer... *)
    appStyleBuffer.Remove(pos, pos + nDeleted)
  END;
  (* Select the area that was just updated to avoid unnecessary callbacks... *)
  appStyleBuffer.Select(pos, pos + nInserted - nDeleted);
  (* Re-parse the changed region; we do this by parsing from the
     beginning of the line of the changed region to the end of the line
     of the changed region... Then we check the last style character and
     keep updating if we have a multi-line comment character... *)
  start := appTextBuffer.LineStart(pos);
  end := appTextBuffer.LineEnd(pos + nInserted);
  NEW(text, end - start + 1); NEW(style, end - start + 1);
  appTextBuffer.TextRange(start, end, text^);
  appStyleBuffer.TextRange(start, end, style^);
  IF start = end THEN last := 0X ELSE last := style[end - start - 1] END;
  StyleParse(text^, style^, end - start);
  appStyleBuffer.Replace(start, end, style^);
  appEditor.RedisplayRange(start, end);
  IF (start = end) OR (last # style[end - start - 1]) THEN
    (* Either the user deleted some text, or the last character on the
       line changed styles, so reparse the remainder of the buffer... *)
    end := appTextBuffer.Length();
    Restyle
  END
END StyleUpdate;

(* The modify callbacks: FLTK calls the newest first, so style_update
   before text_changed_callback. *)
PROCEDURE (b: Buffer) Modified*(pos, inserted, deleted, restyled: INTEGER);
BEGIN
  IF highlighting THEN StyleUpdate(pos, inserted, deleted) END;
  IF (inserted # 0) OR (deleted # 0) THEN SetChanged(TRUE) END
END Modified;

(* The style table, once: each display draws in it while it is given the
   style buffer. *)
PROCEDURE AddStyles(e: FlText.TextEditor);
  VAR c: CHAR;
BEGIN
  c := e.AddStyle(Fl.Black, Fl.Courier, TS, 0, 0);              (* A - Plain *)
  c := e.AddStyle(Fl.DarkGreen, Fl.HelveticaItalic, TS, 0, 0);  (* B - Line comments *)
  c := e.AddStyle(Fl.DarkGreen, Fl.HelveticaItalic, TS, 0, 0);  (* C - Block comments *)
  c := e.AddStyle(Fl.Blue, Fl.Courier, TS, 0, 0);               (* D - Strings *)
  c := e.AddStyle(Fl.DarkRed, Fl.Courier, TS, 0, 0);            (* E - Directives *)
  c := e.AddStyle(Fl.DarkRed, Fl.CourierBold, TS, 0, 0);        (* F - Types *)
  c := e.AddStyle(Fl.Blue, Fl.CourierBold, TS, 0, 0)            (* G - Keywords *)
END AddStyles;

PROCEDURE MenuSyntaxhighlightCallback(w: Fl.Widget);
  VAR on: BOOLEAN;
BEGIN
  on := Checked(w);
  IF on THEN
    StyleInit;
    appEditor.SetStyleBuffer(appStyleBuffer);
    highlighting := TRUE
  ELSE
    highlighting := FALSE;
    appEditor.SetStyleBuffer(NIL)
  END;
  appEditor.Redraw;
  IF appSplitEditor # NIL THEN
    IF on THEN appSplitEditor.SetStyleBuffer(appStyleBuffer)
    ELSE appSplitEditor.SetStyleBuffer(NIL)
    END;
    appSplitEditor.Redraw
  END
END MenuSyntaxhighlightCallback;

(* The program, chapter by chapter *)

PROCEDURE BuildAppWindow;
BEGIN
  NEW(appWindow); Fl.OpenDoubleWindow(appWindow, 640, 480, "FLTK Editor");
  appWindow.SetXClass("fl_editor")
END BuildAppWindow;

PROCEDURE BuildAppMenuBar;
BEGIN
  appWindow.Begin;
  NEW(appMenuBar); FlMenus.OpenMenuBar(appMenuBar, 0, 0, appWindow.W(), 25, "");
  i := appMenuBar.Add("File/Quit Editor", ORD("q"), Fl.Command, MenuQuitCallback, {});
  appWindow.action := MenuQuitCallback;
  appWindow.End
END BuildAppMenuBar;

PROCEDURE BuildMainEditor;
  VAR ix: INTEGER;
BEGIN
  appWindow.Begin;
  NEW(appTextBuffer); FlText.OpenBuffer(appTextBuffer);
  NEW(appEditor); FlText.OpenTextEditor(appEditor, 0, appMenuBar.H(),
    appWindow.W(), appWindow.H() - appMenuBar.H(), "");
  appEditor.SetBuffer(appTextBuffer);
  appEditor.SetTextFont(Fl.Courier);
  appWindow.SetResizable(appEditor);
  appWindow.End;
  (* FLTK finds Quit by its callback, find_index(menu_quit_callback) *)
  ix := appMenuBar.FindIndex("File/Quit Editor");
  i := appMenuBar.Insert(ix, "New", ORD("n"), Fl.Command, MenuNewCallback, {})
END BuildMainEditor;

PROCEDURE AddFileSupport;
  VAR ix: INTEGER;
BEGIN
  ix := appMenuBar.FindIndex("File/Quit Editor");
  i := appMenuBar.Insert(ix, "Open", ORD("o"), Fl.Command, MenuOpenCallback, FlMenus.MenuDivider);
  i := appMenuBar.Insert(ix + 1, "Save", ORD("s"), Fl.Command, MenuSaveCallback, {});
  i := appMenuBar.Insert(ix + 2, "Save as...", ORD("S"), Fl.Command, MenuSaveAsCallback, FlMenus.MenuDivider)
END AddFileSupport;

PROCEDURE CutCopyPaste;
BEGIN
  i := appMenuBar.Add("Edit/Undo", ORD("z"), Fl.Command, MenuUndoCallback, {});
  i := appMenuBar.Add("Edit/Redo", ORD("Z"), Fl.Command, MenuRedoCallback, FlMenus.MenuDivider);
  i := appMenuBar.Add("Edit/Cut", ORD("x"), Fl.Command, MenuCutCallback, {});
  i := appMenuBar.Add("Edit/Copy", ORD("c"), Fl.Command, MenuCopyCallback, {});
  i := appMenuBar.Add("Edit/Paste", ORD("v"), Fl.Command, MenuPasteCallback, {});
  i := appMenuBar.Add("Edit/Delete", 0, {}, MenuDeleteCallback, {})
END CutCopyPaste;

PROCEDURE ImplementFind;
BEGIN
  i := appMenuBar.Add("Find/Find...", ORD("f"), Fl.Command, MenuFindCallback, {});
  i := appMenuBar.Add("Find/Find Next", ORD("g"), Fl.Command, MenuFindNextCallback, FlMenus.MenuDivider)
END ImplementFind;

PROCEDURE ImplementReplace;
BEGIN
  i := appMenuBar.Add("Find/Replace...", ORD("r"), Fl.Command, MenuReplaceCallback, {});
  i := appMenuBar.Add("Find/Replace Next", ORD("t"), Fl.Command, MenuReplaceNextCallback, {})
END ImplementReplace;

PROCEDURE EditorFeatures;
BEGIN
  i := appMenuBar.Add("Window/Line Numbers", ORD("l"), Fl.Command, MenuLinenumbersCallback, FlMenus.MenuToggle);
  i := appMenuBar.Add("Window/Word Wrap", 0, {}, MenuWordwrapCallback, FlMenus.MenuToggle)
END EditorFeatures;

PROCEDURE SplitEditor;
BEGIN
  appWindow.Begin;
  NEW(appTile); FlLayout.OpenTile(appTile, appEditor.X(), appEditor.Y(),
    appEditor.W(), appEditor.H(), "");
  appWindow.Remove(appEditor);
  appTile.Add(appEditor);
  NEW(appSplitEditor); FlText.OpenTextEditor(appSplitEditor, appTile.X(),
    appTile.Y() + appTile.H(), appTile.W(), 0, "");
  appSplitEditor.SetBuffer(appTextBuffer);
  appSplitEditor.SetTextFont(Fl.Courier);
  appSplitEditor.Hide;
  appTile.End;
  appTile.SizeRange(appEditor, 25, 25, MAX(INTEGER), MAX(INTEGER));
  appTile.SizeRange(appSplitEditor, 25, 25, MAX(INTEGER), MAX(INTEGER));
  appTile.InitSizes;
  appWindow.End;
  appWindow.SetResizable(appTile);
  appTile.SetResizable(appEditor);
  i := appMenuBar.Add("Window/Split", ORD("i"), Fl.Command, MenuSplitCallback, FlMenus.MenuToggle)
END SplitEditor;

PROCEDURE SyntaxHighlighting;
BEGIN
  InitWords;
  AddStyles(appEditor); AddStyles(appSplitEditor);
  i := appMenuBar.Add("Window/Syntax Highlighting", 0, {}, MenuSyntaxhighlightCallback, FlMenus.MenuToggle)
END SyntaxHighlighting;

BEGIN
  BuildAppWindow;
  BuildAppMenuBar;
  BuildMainEditor;
  AddFileSupport;
  CutCopyPaste;
  ImplementFind;
  ImplementReplace;
  EditorFeatures;
  SplitEditor;
  SyntaxHighlighting;
  (* FLTK's Fl::args_to_utf8 does nothing but on Windows *)
  ok := Fl.ParseArgs(ArgsHandler, i);
  appWindow.ShowArgs;
  Fl.Run
END Editor.
