MODULE FlDialogs; (* FLTK's common dialogs: messages, questions, input, colors and files; directories listed *)

(* Each procedure shows a modal dialog and waits for the user, handling
   events meanwhile, so timers fire and windows are redrawn, but no other
   window takes input. A cancelled dialog is not an error: it comes back as
   FALSE, or a Choice of Escaped or Closed.

   Text is shown as it is, never taken as a printf format. The C++ part is
   FlDialogs.cpp. *)

IMPORT SYSTEM, GarbageCollectedHeap, Fl;

CONST
(* BEGIN generated constants: tools/gen-constants.py writes this block,
   from FLTK's headers; edit the script, not the block. *)

  (* kinds of beep (Beep) *)
  BeepDefault* = 0;
  BeepMessage* = 1;
  BeepError* = 2;
  BeepQuestion* = 3;
  BeepPassword* = 4;
  BeepNotification* = 5;

  (* what a native file chooser asks for (OpenNativeFileChooser) *)
  BrowseFile* = 0;
  BrowseDirectory* = 1;
  BrowseMultiFile* = 2;
  BrowseMultiDirectory* = 3;
  BrowseSaveFile* = 4;
  BrowseSaveDirectory* = 5;

  (* a native file chooser's options (NativeFileChooser.SetOptions) *)
  SaveAsConfirm* = {0};
  NewFolder* = {1};
  Preview* = {2};
  UseFilterExt* = {3};

  (* what a file chooser asks for (OpenFileChooser) *)
  ChooserSingle* = {};
  ChooserMulti* = {0};
  ChooserCreate* = {1};
  ChooserDirectory* = {2};
(* END generated constants *)

  (* Choice when no button was pushed *)
  Escaped* = -1;  (* the Escape key *)
  Closed* = -2;   (* the window's close button *)

  (* Position's results *)
  NoPosition* = 0;       (* none set *)
  PositionAt* = 1;       (* the next dialog's top left *)
  PositionCentred* = 2;  (* the next dialog's centre *)

  (* how ChooseColor shows the color: FLTK has no names for these *)
  ColorDefault* = -1;  (* as last time *)
  ColorRGB* = 0;       (* red, green and blue from 0 to 1 *)
  ColorByte* = 1;      (* from 0 to 255 *)
  ColorHex* = 2;       (* as one hexadecimal number *)
  ColorHSV* = 3;       (* hue, saturation and value *)

  (* what NativeFileChooser.Show gives *)
  Chosen* = 0;
  Cancelled* = 1;
  Failed* = -1;  (* ErrorMessage says why *)

  (* which of FLTK's chooser's own texts SetChooserLabel sets *)
  LabelAddFavorites* = 0;       (* Add to Favorites *)
  LabelAllFiles* = 1;           (* All Files, with its pattern *)
  LabelCustomFilter* = 2;       (* Custom Filter *)
  LabelExistingFile* = 3;       (* the alert for a file that isn't there *)
  LabelFavorites* = 4;          (* Favorites *)
  LabelFilename* = 5;           (* Filename: *)
  LabelFilesystems* = 6;        (* File Systems, or My Computer *)
  LabelHidden* = 7;             (* Show hidden files *)
  LabelManageFavorites* = 8;    (* Manage Favorites *)
  LabelNewDirectory* = 9;       (* the new directory dialog's question *)
  LabelNewDirectoryTip* = 10;   (* the new directory button's tooltip *)
  LabelPreview* = 11;           (* Preview *)
  LabelSave* = 12;              (* the favorites window's Save button *)
  LabelShow* = 13;              (* Show: *)

  (* the order of a directory's names (ListDirectory): by their bytes, or
     ignoring case; with runs of digits as numbers, or not *)
  AlphaSort* = 0;
  CaseAlphaSort* = 1;
  NumericSort* = 2;
  CaseNumericSort* = 3;

TYPE
  (* The desktop's own file chooser: zenity's, kdialog's or GTK's,
     whichever the program and FLTK's options allow and the system has,
     or else FLTK's. A resource the program owns: Close it when done, or
     the collector does. *)
  NativeFileChooser* = POINTER TO NativeFileChooserDesc;
  NativeFileChooserDesc* = RECORD
    h: SYSTEM.ADDRESS
  END;

  (* What SetFilePicked calls. *)
  FilePicked* = PROCEDURE (name-: ARRAY OF CHAR);

  (* FLTK's color chooser as a widget: a hue box, a value slider and three
     inputs, for a panel of the program's own. Its Callback runs when the
     user changes the color. FLTK's is a group, but its parts are its own,
     so this is a widget. *)
  ColorChooser* = POINTER TO ColorChooserDesc;
  ColorChooserDesc* = RECORD (Fl.WidgetDesc) END;

  (* FLTK's own file chooser, in a window of its own, which stays open
     while the program does something else: not modal to the program's
     code, as ChooseFile is, though the window is modal to the user. A
     resource the program owns, open until Close, so a chooser nothing
     else points to still calls back; the program ends with it closed,
     or it is closed then. Its previews go through FLTK's decoders, with
     none of FlImages' checks. *)
  FileChooser* = POINTER TO FileChooserDesc;
  FileChooserDesc* = RECORD
    h: SYSTEM.ADDRESS;
    next: FileChooser;   (* in choosers, while open *)
    extra: Fl.Widget     (* what SetExtra gave *)
  END;

  (* A directory's names (ListDirectory), and other text of unknown
     length *)
  Name* = Fl.String;
  Names* = POINTER TO ARRAY OF Name;

VAR
  openChoosers-: INTEGER;  (* choosers opened and not yet closed or finalized *)
  choosers: FileChooser;   (* every open FileChooser: FLTK calls back into them *)
  filePicked: FilePicked;  (* SetFilePicked's *)

PROCEDURE ["C", "ofl_dialog_message"] CMessage(alert: SYSTEM.INT32; text: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_dialog_choice"] CChoice(text, b0, b1, b2: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_dialog_input_text"] CInputText(password: SYSTEM.INT32; label, value: ARRAY OF CHAR; max: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_dialog_input"] CInput(password: SYSTEM.INT32; label: ARRAY OF CHAR; VAR buf: ARRAY OF CHAR; n, max: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_dialog_title"] CTitle(dflt: SYSTEM.INT32; title: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_dialog_hotspot"] CHotspot(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_dialog_set_hotspot"] CSetHotspot(on: SYSTEM.INT32);
PROCEDURE ["C", "ofl_dialog_font"] CFont(VAR font, size: SYSTEM.INT32);
PROCEDURE ["C", "ofl_dialog_set_font"] CSetFont(font, size: SYSTEM.INT32);
PROCEDURE ["C", "ofl_beep"] CBeep(kind: SYSTEM.INT32);
PROCEDURE ["C", "ofl_color_chooser"] CColorChooser(title: ARRAY OF CHAR; VAR r, g, b: SYSTEM.INT32; mode: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_show_colormap"] CShowColormap(old: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_color_chooser_new"] CColorChooserNew(x, y, w, h: SYSTEM.INT32; label: ARRAY OF CHAR; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_color_chooser_get"] CColorChooserGet(c: SYSTEM.ADDRESS; what: SYSTEM.INT32): LONGREAL;
PROCEDURE ["C", "ofl_color_chooser_set_hsv"] CColorChooserSetHSV(c: SYSTEM.ADDRESS; h, s, v: LONGREAL): SYSTEM.INT32;
PROCEDURE ["C", "ofl_color_chooser_set_rgb"] CColorChooserSetRGB(c: SYSTEM.ADDRESS; r, g, b: LONGREAL): SYSTEM.INT32;
PROCEDURE ["C", "ofl_color_chooser_mode"] CColorChooserMode(c: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_color_chooser_set_mode"] CColorChooserSetMode(c: SYSTEM.ADDRESS; m: SYSTEM.INT32);
PROCEDURE ["C", "ofl_hsv_to_rgb"] CHSVToRGB(h, s, v: LONGREAL; VAR r, g, b: LONGREAL);
PROCEDURE ["C", "ofl_rgb_to_hsv"] CRGBToHSV(r, g, b: LONGREAL; VAR h, s, v: LONGREAL);
PROCEDURE ["C", "ofl_file_chooser"] CFileChooser(dir: SYSTEM.INT32; title, pattern: ARRAY OF CHAR; VAR buf: ARRAY OF CHAR; n, relative: SYSTEM.INT32): SYSTEM.INT32;

PROCEDURE ["C", "ofl_fnfc_new"] CFnfcNew(kind: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_fnfc_close"] CFnfcClose(c: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_fnfc_set_text"] CFnfcSetText(c: SYSTEM.ADDRESS; what: SYSTEM.INT32; s: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_fnfc_add_filter"] CFnfcAddFilter(c: SYSTEM.ADDRESS; name, pattern: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_fnfc_set_int"] CFnfcSetInt(c: SYSTEM.ADDRESS; what, v: SYSTEM.INT32);
PROCEDURE ["C", "ofl_fnfc_get_int"] CFnfcGetInt(c: SYSTEM.ADDRESS; what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_fnfc_show"] CFnfcShow(c: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_fnfc_filename"] CFnfcFilename(c: SYSTEM.ADDRESS; i: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_fnfc_errmsg"] CFnfcErrmsg(c: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_fc_register"] CFcRegister(f: PROCEDURE (self: SYSTEM.ADDRESS));
PROCEDURE ["C", "ofl_fc_new"] CFcNew(dir, pattern: ARRAY OF CHAR; type: SYSTEM.INT32; title: ARRAY OF CHAR; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_fc_close"] CFcClose(c: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_fc_show"] CFcShow(c: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_fc_hide"] CFcHide(c: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_fc_get"] CFcGet(c: SYSTEM.ADDRESS; what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_fc_set"] CFcSet(c: SYSTEM.ADDRESS; what, v: SYSTEM.INT32);
PROCEDURE ["C", "ofl_fc_text"] CFcText(c: SYSTEM.ADDRESS; what, i: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_fc_set_text"] CFcSetText(c: SYSTEM.ADDRESS; what: SYSTEM.INT32; s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_fc_rescan"] CFcRescan(c: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_fc_position"] CFcPosition(c: SYSTEM.ADDRESS; x, y: SYSTEM.INT32);
PROCEDURE ["C", "ofl_fc_resize"] CFcResize(c: SYSTEM.ADDRESS; x, y, w, h: SYSTEM.INT32);
PROCEDURE ["C", "ofl_fc_set_extra"] CFcSetExtra(c, extra: SYSTEM.ADDRESS; gone: SYSTEM.INT32);
PROCEDURE ["C", "ofl_fc_set_label"] CFcSetLabel(which: SYSTEM.INT32; s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_file_chosen_register"] CChosenRegister(f: PROCEDURE (name: SYSTEM.ADDRESS));
PROCEDURE ["C", "ofl_dialog_icon"] CIcon(VAR box, font, size, color, labelColor: SYSTEM.INT32);
PROCEDURE ["C", "ofl_dialog_set_icon"] CSetIcon(box, font, size, color, labelColor: SYSTEM.INT32);
PROCEDURE ["C", "ofl_dialog_icon_label"] CIconLabel(dflt: SYSTEM.INT32; s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_dialog_set_position"] CSetPosition(x, y, center: SYSTEM.INT32);
PROCEDURE ["C", "ofl_dialog_position_over"] CPositionOver(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_dialog_position"] CPosition(VAR x, y: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_file_chooser_ok"] CFileChooserOK(s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_filename_absolute"] CFilenameAbsolute(from, base: SYSTEM.ADDRESS; VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_filename_expand"] CFilenameExpand(from: SYSTEM.ADDRESS; VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_filename_isdir"] CFilenameIsDir(name: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_filename_match"] CFilenameMatch(name, pattern: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_filename_part"] CFilenamePart(ext: SYSTEM.INT32; name: SYSTEM.ADDRESS; VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_filename_setext"] CFilenameSetExt(VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32; ext: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_decode_uri"] CDecodeURI(VAR uri: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_filename_relative"] CFilenameRelative(from, base: SYSTEM.ADDRESS; VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_filename_list"] CFilenameList(dir: ARRAY OF CHAR; sort: SYSTEM.INT32; VAR n: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_filename_length"] CFilenameLength(l: SYSTEM.ADDRESS; i: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_filename_get"] CFilenameGet(l: SYSTEM.ADDRESS; i: SYSTEM.INT32; VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_filename_free"] CFilenameFree(l: SYSTEM.ADDRESS);

(* Copies the C string at a into s, truncated to fit; "" for none. *)
PROCEDURE FromC(a: SYSTEM.ADDRESS; VAR s: ARRAY OF CHAR);
  VAR i: LONGINT; c: CHAR;
BEGIN
  i := 0;
  IF a # 0 THEN
    SYSTEM.GET(a, c);
    WHILE (c # 0X) & (i < LEN(s) - 1) DO
      s[i] := c; INC(i); SYSTEM.GET(a + i, c)
    END
  END;
  s[i] := 0X
END FromC;

(* A copy of the C string at a; NIL for none. *)
PROCEDURE Copy(a: SYSTEM.ADDRESS): Name;
  VAR n: LONGINT; c: CHAR; s: Name;
BEGIN
  IF a = 0 THEN RETURN NIL END;
  n := 0; SYSTEM.GET(a, c);
  WHILE c # 0X DO INC(n); SYSTEM.GET(a + n, c) END;
  NEW(s, n + 1); FromC(a, s^);
  RETURN s
END Copy;

(* Whether s holds a tab or a line feed. *)
PROCEDURE HasBreak(s-: ARRAY OF CHAR): BOOLEAN;
  VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(s)) & (s[i] # 0X) & (s[i] # 09X) & (s[i] # 0AX) DO INC(i) END;
  RETURN (i < LEN(s)) & (s[i] # 0X)
END HasBreak;

PROCEDURE Int(b: BOOLEAN): SYSTEM.INT32;
BEGIN IF b THEN RETURN 1 ELSE RETURN 0 END
END Int;

PROCEDURE Byte(n: INTEGER): INTEGER;
BEGIN
  IF n < 0 THEN RETURN 0 ELSIF n > 255 THEN RETURN 255 ELSE RETURN n END
END Byte;

(* Shows text, with a button to close it. *)
PROCEDURE Message*(text-: ARRAY OF CHAR);
BEGIN CMessage(0, text)
END Message;

(* The same, marked as a warning. *)
PROCEDURE Alert*(text-: ARRAY OF CHAR);
BEGIN CMessage(1, text)
END Alert;

(* Shows text, with up to three buttons, from the right: b0, b1, b2, an
   empty label being no button. b1 is pushed by Enter. Returns the button
   pushed, 0 to 2, or Escaped or Closed. *)
PROCEDURE Choice*(text-, b0-, b1-, b2-: ARRAY OF CHAR): INTEGER;
BEGIN RETURN CChoice(text, b0, b1, b2)
END Choice;

(* Asks for a line of text, starting with value, the cursor after it;
   TRUE and the text in
   value (truncated to fit) if the user pushed OK, FALSE and value
   unchanged if Cancel. *)
PROCEDURE Input*(label-: ARRAY OF CHAR; VAR value: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CInput(0, label, value, SHORT(LEN(value)), 0) # 0
END Input;

(* The same, the text hidden as it is typed. *)
PROCEDURE Password*(label-: ARRAY OF CHAR; VAR value: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CInput(1, label, value, SHORT(LEN(value)), 0) # 0
END Password;

(* Input and Password, letting at most max characters be typed (not
   bytes: a character of UTF-8 counts once). max 0 or less is no limit. *)
PROCEDURE InputLimited*(label-: ARRAY OF CHAR; VAR value: ARRAY OF CHAR; max: INTEGER): BOOLEAN;
BEGIN
  RETURN CInput(0, label, value, SHORT(LEN(value)), max) # 0
END InputLimited;

PROCEDURE PasswordLimited*(label-: ARRAY OF CHAR; VAR value: ARRAY OF CHAR; max: INTEGER): BOOLEAN;
BEGIN
  RETURN CInput(1, label, value, SHORT(LEN(value)), max) # 0
END PasswordLimited;

(* Asks for a line of text, starting with value: the text, of any
   length, if the user pushed OK, NIL if Cancel. *)
PROCEDURE InputText*(label-, value-: ARRAY OF CHAR): Fl.String;
BEGIN RETURN Copy(CInputText(0, label, value, 0))
END InputText;

(* The same, the text hidden as it is typed. *)
PROCEDURE PasswordText*(label-, value-: ARRAY OF CHAR): Fl.String;
BEGIN RETURN Copy(CInputText(1, label, value, 0))
END PasswordText;

(* The window title of the next of these dialogs (Message to Password)
   only; SetDefaultTitle, of every one given none. "" is none. *)
PROCEDURE SetTitle*(title-: ARRAY OF CHAR);
BEGIN CTitle(0, title)
END SetTitle;

PROCEDURE SetDefaultTitle*(title-: ARRAY OF CHAR);
BEGIN CTitle(1, title)
END SetDefaultTitle;

(* TRUE if the dialogs are shown under the mouse, as to start with; else
   centred on the screen. *)
PROCEDURE Hotspot*(): BOOLEAN;
BEGIN RETURN CHotspot() # 0
END Hotspot;

PROCEDURE SetHotspot*(on: BOOLEAN);
BEGIN CSetHotspot(Int(on))
END SetHotspot;

(* The font and size of the dialogs' text: a font of Fl's; size 0 is
   FLTK's normal size. *)
PROCEDURE Font*(VAR font, size: INTEGER);
  VAR f, s: SYSTEM.INT32;
BEGIN CFont(f, s); font := f; size := s
END Font;

PROCEDURE SetFont*(font, size: INTEGER);
BEGIN CSetFont(font, size)
END SetFont;

(* What each dialog's icon looks like: a box type, font, size and colors
   of Fl's. *)
PROCEDURE Icon*(VAR box, font, size, color, labelColor: INTEGER);
  VAR b, f, s, c, l: SYSTEM.INT32;
BEGIN CIcon(b, f, s, c, l); box := b; font := f; size := s; color := c; labelColor := l
END Icon;

PROCEDURE SetIcon*(box, font, size, color, labelColor: INTEGER);
BEGIN CSetIcon(box, font, size, color, labelColor)
END SetIcon;

(* The text of the next dialog's icon only; SetDefaultIconLabel, of every
   one given none. "" is the dialog's own, an "i", "?" or "!". *)
PROCEDURE SetIconLabel*(s-: ARRAY OF CHAR);
BEGIN CIconLabel(0, s)
END SetIconLabel;

PROCEDURE SetDefaultIconLabel*(s-: ARRAY OF CHAR);
BEGIN CIconLabel(1, s)
END SetDefaultIconLabel;

(* Where the next dialog goes, on the screen, whatever Hotspot says: its
   top left at x, y, or its centre if centred. *)
PROCEDURE SetPosition*(x, y: INTEGER; centred: BOOLEAN);
BEGIN CSetPosition(x, y, Int(centred))
END SetPosition;

(* The next dialog goes centred on w. *)
PROCEDURE SetPositionOver*(w: Fl.Widget);
BEGIN CPositionOver(Fl.Live(w))
END SetPositionOver;

(* What is set for the next dialog, one of the Position constants, and
   where. The next dialog uses it up. *)
PROCEDURE Position*(VAR x, y: INTEGER): INTEGER;
  VAR X, Y, r: SYSTEM.INT32;
BEGIN r := CPosition(X, Y); x := X; y := Y; RETURN r
END Position;

(* Sounds the system's beep of this kind, one of the Beep constants. *)
PROCEDURE Beep*(kind: INTEGER);
BEGIN CBeep(kind)
END Beep;

(* Asks for a color, starting with r, g, b, each from 0 to 255 (others are
   brought into that range); mode is one of the Color constants. TRUE and
   the color in r, g, b if the user pushed OK. With ColorDefault, the mode
   last used, a component of 0 shows as "0", not "0.000", as in FLTK's own
   programs; any other mode shows every field with its decimals
   (doc/fltk-issues.md, 168). *)
PROCEDURE ChooseColor*(title-: ARRAY OF CHAR; VAR r, g, b: INTEGER; mode: INTEGER): BOOLEAN;
  VAR R, G, B: SYSTEM.INT32;
BEGIN
  R := Byte(r); G := Byte(g); B := Byte(b);
  IF CColorChooser(title, R, G, B, mode) # 0 THEN r := R; g := G; b := B; RETURN TRUE END;
  RETURN FALSE
END ChooseColor;

(* Pops up FLTK's colormap at the mouse, old marked, and returns the color
   picked: an index color of Fl's; old if none was. *)
PROCEDURE ChooseFromColormap*(old: INTEGER): INTEGER;
BEGIN RETURN CShowColormap(old)
END ChooseFromColormap;

(* Color choosers *)

PROCEDURE OpenColorChooser*(c: ColorChooser; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Fl.EndOpen(c, CColorChooserNew(x, y, w, h, label, Fl.BeginOpen(c)))
END OpenColorChooser;

(* The hue, from 0 up to 6: 0 is red, 1 yellow, 2 green and so on. *)
PROCEDURE (c: ColorChooser) Hue*(): LONGREAL;
BEGIN RETURN CColorChooserGet(Fl.Live(c), 0)
END Hue;

(* The saturation and value, and red, green and blue, each from 0 to 1. *)
PROCEDURE (c: ColorChooser) Saturation*(): LONGREAL;
BEGIN RETURN CColorChooserGet(Fl.Live(c), 1)
END Saturation;

PROCEDURE (c: ColorChooser) Value*(): LONGREAL;
BEGIN RETURN CColorChooserGet(Fl.Live(c), 2)
END Value;

PROCEDURE (c: ColorChooser) R*(): LONGREAL;
BEGIN RETURN CColorChooserGet(Fl.Live(c), 3)
END R;

PROCEDURE (c: ColorChooser) G*(): LONGREAL;
BEGIN RETURN CColorChooserGet(Fl.Live(c), 4)
END G;

PROCEDURE (c: ColorChooser) B*(): LONGREAL;
BEGIN RETURN CColorChooserGet(Fl.Live(c), 5)
END B;

(* Sets the color, without a call of Callback: TRUE if it changed. A hue is
   taken modulo 6, and s and v are brought into 0 to 1. *)
PROCEDURE (c: ColorChooser) SetHSV*(h, s, v: LONGREAL): BOOLEAN;
BEGIN RETURN CColorChooserSetHSV(Fl.Live(c), h, s, v) # 0
END SetHSV;

(* Sets the color, without a call of Callback: TRUE if it changed. FLTK
   leaves each as it is, so keep them from 0 to 1. *)
PROCEDURE (c: ColorChooser) SetRGB*(r, g, b: LONGREAL): BOOLEAN;
BEGIN RETURN CColorChooserSetRGB(Fl.Live(c), r, g, b) # 0
END SetRGB;

(* How the inputs show the color: ColorRGB, ColorByte, ColorHex or ColorHSV. *)
PROCEDURE (c: ColorChooser) Mode*(): INTEGER;
BEGIN RETURN CColorChooserMode(Fl.Live(c))
END Mode;

PROCEDURE (c: ColorChooser) SetMode*(m: INTEGER);
BEGIN
  ASSERT((m >= ColorRGB) & (m <= ColorHSV), Fl.IndexOutOfRange);
  CColorChooserSetMode(Fl.Live(c), m)
END SetMode;

(* Converts a color between the two forms, as a ColorChooser's ranges. *)
PROCEDURE HSVToRGB*(h, s, v: LONGREAL; VAR r, g, b: LONGREAL);
BEGIN CHSVToRGB(h, s, v, r, g, b)
END HSVToRGB;

PROCEDURE RGBToHSV*(r, g, b: LONGREAL; VAR h, s, v: LONGREAL);
BEGIN CRGBToHSV(r, g, b, h, s, v)
END RGBToHSV;

(* FLTK's file chooser: asks for a file matching pattern ("*.txt", or
   several, each a name and a pattern in brackets, separated by tabs, as
   FLTK's Fl_File_Chooser::filter documents; "" is any), starting at path ("" for
   the one chosen last, or the current directory). TRUE and the file in
   path (truncated to fit), relative to the current directory if relative,
   if the user pushed OK. The file need not exist. *)
PROCEDURE ChooseFile*(title-, pattern-: ARRAY OF CHAR; VAR path: ARRAY OF CHAR; relative: BOOLEAN): BOOLEAN;
BEGIN RETURN CFileChooser(0, title, pattern, path, SHORT(LEN(path)), Int(relative)) # 0
END ChooseFile;

PROCEDURE ChosenD(name: SYSTEM.ADDRESS);
  VAR s: ARRAY 4096 OF CHAR;
BEGIN
  IF filePicked # NIL THEN FromC(name, s); filePicked(s) END
END ChosenD;

(* Calls p with each file the user picks while ChooseFile or
   ChooseDirectory is up, before OK is pushed, as for a preview; NIL for
   none. *)
PROCEDURE SetFilePicked*(p: FilePicked);
BEGIN filePicked := p
END SetFilePicked;

(* The same as ChooseFile, for a directory. *)
PROCEDURE ChooseDirectory*(title-: ARRAY OF CHAR; VAR path: ARRAY OF CHAR; relative: BOOLEAN): BOOLEAN;
BEGIN RETURN CFileChooser(1, title, "", path, SHORT(LEN(path)), Int(relative)) # 0
END ChooseDirectory;

(* Native file choosers *)

PROCEDURE CloseChooser(c: NativeFileChooser);
BEGIN
  IF c.h # 0 THEN CFnfcClose(c.h); c.h := 0; DEC(openChoosers) END
END CloseChooser;

(* GC finalizer: a chooser lost without Close. *)
PROCEDURE FinalizeChooser(obj: SYSTEM.PTR);
BEGIN CloseChooser(SYSTEM.VAL(NativeFileChooser, obj))
END FinalizeChooser;

(* c's handle, halting if c is closed. *)
PROCEDURE Hd(c: NativeFileChooser): SYSTEM.ADDRESS;
BEGIN
  ASSERT(c # NIL, Fl.NilArgument); ASSERT(c.h # 0, Fl.ClosedResource);
  RETURN c.h
END Hd;

(* Opens c, a chooser asking for kind: BrowseFile and the rest. *)
PROCEDURE OpenNativeFileChooser*(c: NativeFileChooser; kind: INTEGER);
BEGIN
  ASSERT(c # NIL, Fl.NilArgument); ASSERT(c.h = 0, Fl.OpenedTwice);
  ASSERT((kind >= BrowseFile) & (kind <= BrowseSaveDirectory), Fl.IndexOutOfRange);
  c.h := CFnfcNew(kind); ASSERT(c.h # 0);  (* out of memory *)
  INC(openChoosers);
  GarbageCollectedHeap.RegisterFinalizer(c, FinalizeChooser)
END OpenNativeFileChooser;

(* Frees c; idempotent. *)
PROCEDURE (c: NativeFileChooser) Close*;
BEGIN CloseChooser(c)
END Close;

PROCEDURE (c: NativeFileChooser) IsOpen*(): BOOLEAN;
BEGIN RETURN c.h # 0
END IsOpen;

PROCEDURE (c: NativeFileChooser) SetKind*(kind: INTEGER);
BEGIN
  ASSERT((kind >= BrowseFile) & (kind <= BrowseSaveDirectory), Fl.IndexOutOfRange);
  CFnfcSetInt(Hd(c), 0, kind)
END SetKind;

PROCEDURE (c: NativeFileChooser) Kind*(): INTEGER;
BEGIN RETURN CFnfcGetInt(Hd(c), 0)
END Kind;

(* SaveAsConfirm and the rest; a chooser may ignore those it can't do. *)
PROCEDURE (c: NativeFileChooser) SetOptions*(options: SET);
BEGIN CFnfcSetInt(Hd(c), 1, SYSTEM.VAL(SYSTEM.INT32, options))
END SetOptions;

PROCEDURE (c: NativeFileChooser) Options*(): SET;
BEGIN RETURN SYSTEM.VAL(SET, CFnfcGetInt(Hd(c), 1))
END Options;

PROCEDURE SetText(c: NativeFileChooser; what: INTEGER; s-: ARRAY OF CHAR);
BEGIN ASSERT(CFnfcSetText(Hd(c), what, s) # 0)  (* out of memory *)
END SetText;

PROCEDURE (c: NativeFileChooser) SetTitle*(title-: ARRAY OF CHAR);
BEGIN SetText(c, 0, title)
END SetTitle;

(* The files offered: patterns, one a line ("*.txt"), or a name, a tab
   and a pattern ("Text" + 09X + "*.{txt,md}"), lines separated by
   0AX. *)
PROCEDURE (c: NativeFileChooser) SetFilter*(filter-: ARRAY OF CHAR);
BEGIN SetText(c, 1, filter)
END SetFilter;

(* Adds a filter to those SetFilter gave, or AddFilter added: files
   matching pattern ("*.{yaml,yml}"), offered as name ("YAML"), or as the
   pattern if name is "". Neither may hold a tab or a line feed. *)
PROCEDURE (c: NativeFileChooser) AddFilter*(name-, pattern-: ARRAY OF CHAR);
BEGIN
  ASSERT(~HasBreak(name) & ~HasBreak(pattern), Fl.Unsupported);
  ASSERT(CFnfcAddFilter(Hd(c), name, pattern) # 0)  (* out of memory *)
END AddFilter;

(* The number of filters SetFilter and AddFilter gave; FilterValue, the
   one chosen, from 0. *)
PROCEDURE (c: NativeFileChooser) Filters*(): INTEGER;
BEGIN RETURN CFnfcGetInt(Hd(c), 3)
END Filters;

PROCEDURE (c: NativeFileChooser) SetFilterValue*(i: INTEGER);
BEGIN CFnfcSetInt(Hd(c), 2, i)
END SetFilterValue;

PROCEDURE (c: NativeFileChooser) FilterValue*(): INTEGER;
BEGIN RETURN CFnfcGetInt(Hd(c), 2)
END FilterValue;

(* Where the chooser starts. *)
PROCEDURE (c: NativeFileChooser) SetDirectory*(dir-: ARRAY OF CHAR);
BEGIN SetText(c, 2, dir)
END SetDirectory;

(* The file name offered to start with, for BrowseSaveFile. *)
PROCEDURE (c: NativeFileChooser) SetPresetFile*(name-: ARRAY OF CHAR);
BEGIN SetText(c, 3, name)
END SetPresetFile;

(* Shows c and waits for the user: Chosen, Cancelled, or Failed
   (ErrorMessage says why). *)
PROCEDURE (c: NativeFileChooser) Show*(): INTEGER;
  VAR r: INTEGER;
BEGIN
  r := CFnfcShow(Hd(c));
  IF r > 0 THEN RETURN Cancelled ELSIF r < 0 THEN RETURN Failed ELSE RETURN Chosen END
END Show;

(* The number of files chosen, by the last Show. *)
PROCEDURE (c: NativeFileChooser) Count*(): INTEGER;
BEGIN RETURN CFnfcGetInt(Hd(c), 4)
END Count;

(* File i chosen, 0 to Count() - 1, as an absolute path, truncated to
   fit. *)
PROCEDURE (c: NativeFileChooser) FileName*(i: INTEGER; VAR name: ARRAY OF CHAR);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Hd(c); ASSERT((i >= 0) & (i < CFnfcGetInt(h, 4)), Fl.IndexOutOfRange);
  FromC(CFnfcFilename(h, i), name)
END FileName;

(* File i chosen, 0 to Count() - 1, as an absolute path, of any length. *)
PROCEDURE (c: NativeFileChooser) Name*(i: INTEGER): Fl.String;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Hd(c); ASSERT((i >= 0) & (i < CFnfcGetInt(h, 4)), Fl.IndexOutOfRange);
  RETURN Copy(CFnfcFilename(h, i))
END Name;

PROCEDURE (c: NativeFileChooser) ErrorMessage*(VAR msg: ARRAY OF CHAR);
BEGIN FromC(CFnfcErrmsg(Hd(c)), msg)
END ErrorMessage;

(* File choosers *)

(* Runs when the chooser's selection or file name changes, and when the
   user takes its OK button. The first of these isn't an answer: the
   program knows that one by the chooser being no longer Visible. The
   default does nothing. c may be Closed here. *)
PROCEDURE (c: FileChooser) Callback*;
BEGIN
END Callback;

PROCEDURE CallbackD(self: SYSTEM.ADDRESS);
  VAR c: FileChooser;
BEGIN c := SYSTEM.VAL(FileChooser, self); c.Callback
END CallbackD;

PROCEDURE CloseFileChooser(c: FileChooser);
  VAR p: FileChooser;
BEGIN
  IF c.h # 0 THEN
    IF choosers = c THEN
      choosers := c.next
    ELSE
      p := choosers;
      WHILE p.next # c DO p := p.next END;
      p.next := c.next
    END;
    c.next := NIL; c.extra := NIL;
    CFcClose(c.h); c.h := 0; DEC(openChoosers)
  END
END CloseFileChooser;

(* GC finalizer: runs as the program ends, since choosers holds c. *)
PROCEDURE FinalizeFileChooser(obj: SYSTEM.PTR);
BEGIN CloseFileChooser(SYSTEM.VAL(FileChooser, obj))
END FinalizeFileChooser;

(* c's handle, halting if c is closed. *)
PROCEDURE FcH(c: FileChooser): SYSTEM.ADDRESS;
BEGIN
  ASSERT(c # NIL, Fl.NilArgument); ASSERT(c.h # 0, Fl.ClosedResource);
  RETURN c.h
END FcH;

(* Opens c, hidden: listing dir, or the current directory for "", showing
   the files that match filter, as SetFilter's. type is ChooserSingle, or
   a union of ChooserMulti, ChooserCreate and ChooserDirectory. *)
PROCEDURE OpenFileChooser*(c: FileChooser; dir-, filter-: ARRAY OF CHAR; type: SET; title-: ARRAY OF CHAR);
BEGIN
  ASSERT(c # NIL, Fl.NilArgument); ASSERT(c.h = 0, Fl.OpenedTwice);
  c.h := CFcNew(dir, filter, ORD(type), title, SYSTEM.VAL(SYSTEM.ADDRESS, c));
  ASSERT(c.h # 0);  (* out of memory *)
  c.next := choosers; choosers := c; c.extra := NIL;
  INC(openChoosers);
  GarbageCollectedHeap.RegisterFinalizer(c, FinalizeFileChooser)
END OpenFileChooser;

(* Frees c; idempotent. The window hides at once. Closed in a callback,
   its own or a widget's, the rest waits for the event loop. *)
PROCEDURE (c: FileChooser) Close*;
BEGIN CloseFileChooser(c)
END Close;

PROCEDURE (c: FileChooser) IsOpen*(): BOOLEAN;
BEGIN RETURN c.h # 0
END IsOpen;

(* Lists the directory and shows the window, and returns: wait for the
   user with Fl.Wait while Visible. *)
PROCEDURE (c: FileChooser) Show*;
BEGIN CFcShow(FcH(c))
END Show;

PROCEDURE (c: FileChooser) Hide*;
BEGIN CFcHide(FcH(c))
END Hide;

PROCEDURE (c: FileChooser) Shown*(): BOOLEAN;
BEGIN RETURN CFcGet(FcH(c), 0) # 0
END Shown;

PROCEDURE (c: FileChooser) Visible*(): BOOLEAN;
BEGIN RETURN CFcGet(FcH(c), 1) # 0
END Visible;

(* The number of files chosen. A name in the chooser's field counts, and
   before any is chosen that is its directory. *)
PROCEDURE (c: FileChooser) Count*(): INTEGER;
BEGIN RETURN CFcGet(FcH(c), 2)
END Count;

(* File i chosen, from 1, in s; FALSE, and "", if there is none. Only a
   ChooserMulti chooser has more than one; for the rest, and for a
   ChooserMulti chooser with nothing selected, it is the chooser's field,
   whatever i is (see Count). *)
PROCEDURE (c: FileChooser) ValueAt*(i: INTEGER; VAR s: ARRAY OF CHAR): BOOLEAN;
  VAR a: SYSTEM.ADDRESS;
BEGIN
  ASSERT(i >= 1, Fl.IndexOutOfRange);
  a := CFcText(FcH(c), 4, i); FromC(a, s);
  RETURN a # 0
END ValueAt;

(* File i chosen, from 1, as ValueAt gives it, of any length; NIL if
   there is none. *)
PROCEDURE (c: FileChooser) Name*(i: INTEGER): Fl.String;
BEGIN
  ASSERT(i >= 1, Fl.IndexOutOfRange);
  RETURN Copy(CFcText(FcH(c), 4, i))
END Name;

(* The file chosen, the first if there are several. *)
PROCEDURE (c: FileChooser) Value*(VAR s: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN c.ValueAt(1, s)
END Value;

(* Chooses the file named s, moving to its directory. *)
PROCEDURE (c: FileChooser) SetValue*(s-: ARRAY OF CHAR);
BEGIN CFcSetText(FcH(c), 4, s)
END SetValue;

PROCEDURE (c: FileChooser) Directory*(VAR s: ARRAY OF CHAR);
BEGIN FromC(CFcText(FcH(c), 0, 0), s)
END Directory;

PROCEDURE (c: FileChooser) SetDirectory*(dir-: ARRAY OF CHAR);
BEGIN CFcSetText(FcH(c), 0, dir)
END SetDirectory;

(* The pattern in use, without its name. *)
PROCEDURE (c: FileChooser) Filter*(VAR s: ARRAY OF CHAR);
BEGIN FromC(CFcText(FcH(c), 1, 0), s)
END Filter;

(* The filters offered, separated by tabs: each a pattern, or a name with
   the pattern after it in round brackets. All Files and Custom Filter
   are added to them. *)
PROCEDURE (c: FileChooser) SetFilter*(filter-: ARRAY OF CHAR);
BEGIN CFcSetText(FcH(c), 1, filter)
END SetFilter;

(* The number of filters offered, All Files and Custom Filter with them. *)
PROCEDURE (c: FileChooser) FilterCount*(): INTEGER;
BEGIN RETURN CFcGet(FcH(c), 4)
END FilterCount;

(* The filter in use, from 0. *)
PROCEDURE (c: FileChooser) FilterValue*(): INTEGER;
BEGIN RETURN CFcGet(FcH(c), 3)
END FilterValue;

(* Uses filter i, which asks the user for a pattern if it is the last,
   Custom Filter. *)
PROCEDURE (c: FileChooser) SetFilterValue*(i: INTEGER);
BEGIN
  ASSERT((i >= 0) & (i < c.FilterCount()), Fl.IndexOutOfRange);
  CFcSet(FcH(c), 3, i)
END SetFilterValue;

(* Reads the directory again, keeping the file name. *)
PROCEDURE (c: FileChooser) Rescan*;
BEGIN CFcRescan(FcH(c))
END Rescan;

PROCEDURE (c: FileChooser) Preview*(): BOOLEAN;
BEGIN RETURN CFcGet(FcH(c), 5) # 0
END Preview;

(* Whether the chooser previews the file chosen. FLTK saves this among
   the user's preferences, as every chooser's starting value. *)
PROCEDURE (c: FileChooser) SetPreview*(on: BOOLEAN);
BEGIN CFcSet(FcH(c), 5, Int(on))
END SetPreview;

PROCEDURE (c: FileChooser) ShowHidden*(): BOOLEAN;
BEGIN RETURN CFcGet(FcH(c), 6) # 0
END ShowHidden;

(* Whether names beginning with "." are listed. *)
PROCEDURE (c: FileChooser) SetShowHidden*(on: BOOLEAN);
BEGIN CFcSet(FcH(c), 6, Int(on))
END SetShowHidden;

PROCEDURE (c: FileChooser) Type*(): SET;
BEGIN RETURN SYSTEM.VAL(SET, CFcGet(FcH(c), 7))
END Type;

PROCEDURE (c: FileChooser) SetType*(type: SET);
BEGIN CFcSet(FcH(c), 7, ORD(type))
END SetType;

PROCEDURE (c: FileChooser) GetLabel*(VAR s: ARRAY OF CHAR);
BEGIN FromC(CFcText(FcH(c), 2, 0), s)
END GetLabel;

(* The window's title. *)
PROCEDURE (c: FileChooser) SetLabel*(s-: ARRAY OF CHAR);
BEGIN CFcSetText(FcH(c), 2, s)
END SetLabel;

PROCEDURE (c: FileChooser) GetOkLabel*(VAR s: ARRAY OF CHAR);
BEGIN FromC(CFcText(FcH(c), 3, 0), s)
END GetOkLabel;

PROCEDURE (c: FileChooser) SetOkLabel*(s-: ARRAY OF CHAR);
BEGIN CFcSetText(FcH(c), 3, s)
END SetOkLabel;

(* The file list's background. *)
PROCEDURE (c: FileChooser) Color*(): INTEGER;
BEGIN RETURN CFcGet(FcH(c), 8)
END Color;

PROCEDURE (c: FileChooser) SetColor*(color: INTEGER);
BEGIN CFcSet(FcH(c), 8, color)
END SetColor;

PROCEDURE (c: FileChooser) IconSize*(): INTEGER;
BEGIN RETURN CFcGet(FcH(c), 9)
END IconSize;

PROCEDURE (c: FileChooser) SetIconSize*(s: INTEGER);
BEGIN CFcSet(FcH(c), 9, s)
END SetIconSize;

PROCEDURE (c: FileChooser) TextColor*(): INTEGER;
BEGIN RETURN CFcGet(FcH(c), 10)
END TextColor;

PROCEDURE (c: FileChooser) SetTextColor*(color: INTEGER);
BEGIN CFcSet(FcH(c), 10, color)
END SetTextColor;

PROCEDURE (c: FileChooser) TextFont*(): INTEGER;
BEGIN RETURN CFcGet(FcH(c), 11)
END TextFont;

PROCEDURE (c: FileChooser) SetTextFont*(font: INTEGER);
BEGIN CFcSet(FcH(c), 11, font)
END SetTextFont;

PROCEDURE (c: FileChooser) TextSize*(): INTEGER;
BEGIN RETURN CFcGet(FcH(c), 12)
END TextSize;

PROCEDURE (c: FileChooser) SetTextSize*(s: INTEGER);
BEGIN CFcSet(FcH(c), 12, s)
END SetTextSize;

PROCEDURE (c: FileChooser) X*(): INTEGER;
BEGIN RETURN CFcGet(FcH(c), 13)
END X;

PROCEDURE (c: FileChooser) Y*(): INTEGER;
BEGIN RETURN CFcGet(FcH(c), 14)
END Y;

PROCEDURE (c: FileChooser) W*(): INTEGER;
BEGIN RETURN CFcGet(FcH(c), 15)
END W;

PROCEDURE (c: FileChooser) H*(): INTEGER;
BEGIN RETURN CFcGet(FcH(c), 16)
END H;

PROCEDURE (c: FileChooser) SetPosition*(x, y: INTEGER);
BEGIN CFcPosition(FcH(c), x, y)
END SetPosition;

PROCEDURE (c: FileChooser) Resize*(x, y, w, h: INTEGER);
BEGIN CFcResize(FcH(c), x, y, w, h)
END Resize;

(* Puts w, which no group need hold, under the chooser's own widgets,
   the window growing to fit, in place of the extra widget there, which
   leaves the window and is returned: NIL for none, or for one since
   deleted. NIL as w leaves none. The program opened it, and deletes it,
   before or after Close: the chooser doesn't. *)
PROCEDURE (c: FileChooser) SetExtra*(w: Fl.Widget): Fl.Widget;
  VAR old: Fl.Widget; e: SYSTEM.ADDRESS; gone: SYSTEM.INT32;
BEGIN
  gone := 0; e := 0; old := c.extra;
  IF (old # NIL) & ~old.IsOpen() THEN gone := 1; old := NIL END;
  IF w # NIL THEN e := Fl.Live(w) END;
  CFcSetExtra(FcH(c), e, gone);
  c.extra := w;
  RETURN old
END SetExtra;

(* Sets one of the texts of every chooser opened from now on, which
   the Label constants name: for translations. Some apply as the texts are
   next used, so a chooser already open may show either. *)
PROCEDURE SetChooserLabel*(which: INTEGER; s-: ARRAY OF CHAR);
BEGIN
  ASSERT((which >= LabelAddFavorites) & (which <= LabelShow), Fl.IndexOutOfRange);
  CFcSetLabel(which, s)
END SetChooserLabel;

(* The OK button's label in ChooseFile and ChooseDirectory; "" is FLTK's
   own. *)
PROCEDURE SetFileChooserOK*(s-: ARRAY OF CHAR);
BEGIN CFileChooserOK(s)
END SetFileChooserOK;

(* Directories *)

(* Sets to, cut to fit, to from as a name relative to the current
   directory: "foo.txt", "../foo.txt", or "." for the directory itself.
   Only the text is looked at, so from must have no "." or ".." in it, and
   a from that isn't absolute comes back as it is. FALSE if to is the same
   as from. *)
PROCEDURE FilenameRelative*(from-: ARRAY OF CHAR; VAR to: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CFilenameRelative(SYSTEM.ADR(from), 0, to, SHORT(LEN(to))) # 0
END FilenameRelative;

(* The same, relative to directory base, which must be absolute too. *)
PROCEDURE FilenameRelativeTo*(from-, base-: ARRAY OF CHAR; VAR to: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CFilenameRelative(SYSTEM.ADR(from), SYSTEM.ADR(base), to, SHORT(LEN(to))) # 0
END FilenameRelativeTo;

(* Sets to, cut to fit, to from made absolute, against the current
   directory, or with FilenameAbsoluteTo against base. The "." and ".."
   that start from are taken out, by the text alone, and any later ones
   left; more ".." than there are directories stay, after the root. FALSE,
   and to the same as from, if from is already absolute, or starts with
   "|". *)
PROCEDURE FilenameAbsolute*(from-: ARRAY OF CHAR; VAR to: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CFilenameAbsolute(SYSTEM.ADR(from), 0, to, SHORT(LEN(to))) # 0
END FilenameAbsolute;

PROCEDURE FilenameAbsoluteTo*(from-, base-: ARRAY OF CHAR; VAR to: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CFilenameAbsolute(SYSTEM.ADR(from), SYSTEM.ADR(base), to, SHORT(LEN(to))) # 0
END FilenameAbsoluteTo;

(* Sets to, cut to fit, to from with each part between slashes that is
   "~", "~user" or "$VARIABLE" replaced by that home directory or that
   variable's value. A value starting with a slash ends what came before
   it. A value is put in as it is: "$" in it isn't looked at again. A name
   that doesn't exist is left. FALSE if nothing was replaced. *)
PROCEDURE FilenameExpand*(from-: ARRAY OF CHAR; VAR to: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CFilenameExpand(SYSTEM.ADR(from), to, SHORT(LEN(to))) # 0
END FilenameExpand;

(* TRUE if name exists and is a directory. *)
PROCEDURE FilenameIsDir*(name-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CFilenameIsDir(name) # 0
END FilenameIsDir;

(* TRUE if name fits pattern, whatever the case of A to Z: "?" is any one
   byte, "*" any bytes, "[a-c]" and "[!a-c]" one byte of or not of a set,
   "{a|b}" or "{a,b}" any one of a list, and a backslash takes the next
   byte as it is. *)
PROCEDURE FilenameMatch*(name-, pattern-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CFilenameMatch(name, pattern) # 0
END FilenameMatch;

(* Sets to, cut to fit, to what follows name's last slash. *)
PROCEDURE FilenameName*(name-: ARRAY OF CHAR; VAR to: ARRAY OF CHAR);
BEGIN CFilenamePart(0, SYSTEM.ADR(name), to, SHORT(LEN(to)))
END FilenameName;

(* Sets to, cut to fit, to name's extension: from the last "." after its
   last slash, so all of ".bashrc", and "" if there is none. *)
PROCEDURE FilenameExt*(name-: ARRAY OF CHAR; VAR to: ARRAY OF CHAR);
BEGIN CFilenamePart(1, SYSTEM.ADR(name), to, SHORT(LEN(to)))
END FilenameExt;

(* Puts ext in place of name's extension, or after its name if it has
   none; cut to fit. ext has its "."; "" takes the extension off. *)
PROCEDURE FilenameSetExt*(VAR name: ARRAY OF CHAR; ext-: ARRAY OF CHAR);
BEGIN CFilenameSetExt(name, SHORT(LEN(name)), ext)
END FilenameSetExt;

(* Replaces each "%" and two hexadecimal digits in uri by that byte. It
   stops at a "%" with no digit after it, and at the end, so leaves a "%"
   in the last two bytes; "%00" ends the text. *)
PROCEDURE DecodeURI*(VAR uri: ARRAY OF CHAR);
BEGIN CDecodeURI(uri)
END DecodeURI;

(* Lists directory dir's names in names, in the order sort says, with "."
   and ".."; FLTK adds a "/" to each directory's name. FALSE, and names
   NIL, if dir can't be read. *)
PROCEDURE ListDirectory*(dir-: ARRAY OF CHAR; sort: INTEGER; VAR names: Names): BOOLEAN;
  VAR l: SYSTEM.ADDRESS; n: SYSTEM.INT32; i: INTEGER;
BEGIN
  ASSERT((sort >= AlphaSort) & (sort <= CaseNumericSort), Fl.IndexOutOfRange);
  names := NIL;
  l := CFilenameList(dir, sort, n);
  IF l = 0 THEN RETURN FALSE END;
  NEW(names, n);
  FOR i := 0 TO n - 1 DO
    NEW(names[i], CFilenameLength(l, i) + 1);
    CFilenameGet(l, i, names[i]^, SHORT(LEN(names[i]^)))
  END;
  CFilenameFree(l);
  RETURN TRUE
END ListDirectory;

BEGIN
  CFcRegister(CallbackD);
  CChosenRegister(ChosenD)
END FlDialogs.
