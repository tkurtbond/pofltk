MODULE FlHelp; (* Fl_Help_View and Fl_Help_Dialog: HTML pages, and a window for reading them *)

(* A HelpView shows a page of FLTK's small subset of HTML, from a file
   (Load) or from the program (SetValue), scrolled by scrollbars of its
   own. Clicking a link loads it. A link asks the view's Link method what
   to load, and so does each image in a page, so a program can keep its
   pages where it likes. A link to a place in the page only moves to it.

   FLTK gives a URI whose scheme is ftp, http, https, ipp, mailto or news
   to the system's browser, without asking Link. Images in a page go
   through FLTK's decoders, with none of FlImages' checks, so show only
   pages the program trusts; and they load only once
   FlImages.RegisterImages has run, unless a HelpDialog has been opened.

   Laying out a page moves the view to its top line, which runs its
   Callback: a Callback that sets the text must not do so every time.

   A HelpDialog is FLTK's window for reading help: a HelpView with buttons
   for moving back and forward, for the text's size, and for finding
   text. It is a resource, like FlDialogs.NativeFileChooser. The C++
   part is FlHelp.cpp. *)

IMPORT SYSTEM, GarbageCollectedHeap, Fl;

CONST
  MaxUri* = 16384;  (* more than FLTK ever gives Link, or takes from it *)

TYPE
  (* A page, and its scrollbars. FLTK's is a group, but its parts are its
     own, so this is a widget. *)
  HelpView* = POINTER TO HelpViewDesc;
  HelpViewDesc* = RECORD (Fl.WidgetDesc) END;

  HelpDialog* = POINTER TO HelpDialogDesc;
  HelpDialogDesc* = RECORD
    h: SYSTEM.ADDRESS
  END;

VAR
  openDialogs-: INTEGER;  (* dialogs opened and not yet closed or finalized *)

PROCEDURE ["C", "ofl_help_register"] CRegister(f: PROCEDURE (self, uri: SYSTEM.ADDRESS): SYSTEM.INT32);
PROCEDURE ["C", "ofl_help_new"] CNew(x, y, w, h: SYSTEM.INT32; label: ARRAY OF CHAR; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_help_answer"] CAnswer(v: SYSTEM.ADDRESS; s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_help_in_image"] CInImage(v: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_help_load"] CLoad(v: SYSTEM.ADDRESS; f: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_help_set_value"] CSetValue(v: SYSTEM.ADDRESS; s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_help_value"] CValue(v: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_help_text"] CText(v: SYSTEM.ADDRESS; what: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_help_find"] CFind(v: SYSTEM.ADDRESS; s: ARRAY OF CHAR; from: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_help_get"] CGet(v: SYSTEM.ADDRESS; what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_help_set"] CSet(v: SYSTEM.ADDRESS; what, n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_help_top_name"] CTopName(v: SYSTEM.ADDRESS; name: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_help_clear_selection"] CClearSelection(v: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_help_select_all"] CSelectAll(v: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_help_copy"] CCopy(v: SYSTEM.ADDRESS; clipboard: SYSTEM.INT32);

PROCEDURE ["C", "ofl_help_dialog_new"] CDialogNew(): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_help_dialog_delete"] CDialogDelete(d: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_help_dialog_show"] CDialogShow(d: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_help_dialog_hide"] CDialogHide(d: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_help_dialog_load"] CDialogLoad(d: SYSTEM.ADDRESS; f: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_help_dialog_set_value"] CDialogSetValue(d: SYSTEM.ADDRESS; s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_help_dialog_value"] CDialogValue(d: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_help_dialog_get"] CDialogGet(d: SYSTEM.ADDRESS; what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_help_dialog_set_size"] CDialogSetSize(d: SYSTEM.ADDRESS; s: SYSTEM.INT32);
PROCEDURE ["C", "ofl_help_dialog_top"] CDialogTop(d: SYSTEM.ADDRESS; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_help_dialog_top_name"] CDialogTopName(d: SYSTEM.ADDRESS; name: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_help_dialog_position"] CDialogPosition(d: SYSTEM.ADDRESS; x, y: SYSTEM.INT32);
PROCEDURE ["C", "ofl_help_dialog_resize"] CDialogResize(d: SYSTEM.ADDRESS; x, y, w, h: SYSTEM.INT32);

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

(* Help views *)

(* Opens v, showing nothing. *)
PROCEDURE OpenHelpView*(v: HelpView; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Fl.EndOpen(v, CNew(x, y, w, h, label, Fl.BeginOpen(v)))
END OpenHelpView;

(* What to read for uri, a page's name to Load or in a link, or an
   image's: file: or nothing before it is a file's name, a link given
   relative to the page or the current directory. TRUE, and the file's
   name in name. The default gives uri as it is.

   FALSE for a link leaves the page as it is; a program with pages of
   its own may SetValue one here first, for a link alone, and Load then
   gives TRUE. FALSE for an image shows it broken.

   Link is asked once about each image's uri in the view's life, and
   then must leave the view's page, font and size alone: SetValue, Load,
   SetTextFont and SetTextSize halt there (Fl.OutOfOrder). *)
PROCEDURE (v: HelpView) Link*(uri-: ARRAY OF CHAR; VAR name: ARRAY OF CHAR): BOOLEAN;
BEGIN COPY(uri, name); RETURN TRUE
END Link;

PROCEDURE LinkD(self, uri: SYSTEM.ADDRESS): SYSTEM.INT32;
  VAR v: HelpView; u, name: ARRAY MaxUri OF CHAR;
BEGIN
  v := SYSTEM.VAL(HelpView, self);
  FromC(uri, u);
  IF v.Link(u, name) THEN CAnswer(Fl.Live(v), name); RETURN 1 END;
  RETURN 0
END LinkD;

PROCEDURE Laying(v: HelpView): SYSTEM.ADDRESS;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Fl.Live(v);
  ASSERT(CInImage(h) = 0, Fl.OutOfOrder);
  RETURN h
END Laying;

(* Loads the page in file, which may end in # and a target to move to,
   after asking Link. FALSE if Link said no, or the file can't be read:
   the view then shows FLTK's message saying so. *)
PROCEDURE (v: HelpView) Load*(file-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CLoad(Laying(v), file) # 0
END Load;

(* Shows the page s, FLTK taking a copy. *)
PROCEDURE (v: HelpView) SetValue*(s-: ARRAY OF CHAR);
BEGIN CSetValue(Laying(v), s)
END SetValue;

(* The page's text, "" for none. *)
PROCEDURE (v: HelpView) Value*(VAR s: ARRAY OF CHAR);
BEGIN FromC(CValue(Fl.Live(v)), s)
END Value;

(* The page's directory, its file's name, and its TITLE, "" for none. *)
PROCEDURE (v: HelpView) Directory*(VAR s: ARRAY OF CHAR);
BEGIN FromC(CText(Fl.Live(v), 0), s)
END Directory;

PROCEDURE (v: HelpView) FileName*(VAR s: ARRAY OF CHAR);
BEGIN FromC(CText(Fl.Live(v), 1), s)
END FileName;

(* The page's title, or FLTK's "Untitled". *)
PROCEDURE (v: HelpView) Title*(VAR s: ARRAY OF CHAR);
BEGIN FromC(CText(Fl.Live(v), 2), s)
END Title;

(* Scrolls to the first s from offset from in the page's text, ignoring
   case, and returns where it starts; -1 if there is none. *)
PROCEDURE (v: HelpView) Find*(s-: ARRAY OF CHAR; from: INTEGER): INTEGER;
BEGIN RETURN CFind(Fl.Live(v), s, from)
END Find;

(* The line at the top of the view, in pixels from the page's top. *)
PROCEDURE (v: HelpView) TopLine*(): INTEGER;
BEGIN RETURN CGet(Fl.Live(v), 0)
END TopLine;

PROCEDURE (v: HelpView) SetTopLine*(n: INTEGER);
BEGIN CSet(Fl.Live(v), 0, n)
END SetTopLine;

(* Scrolls to the A NAME called name, if the page has one. *)
PROCEDURE (v: HelpView) SetTopLineName*(name-: ARRAY OF CHAR);
BEGIN CTopName(Fl.Live(v), name)
END SetTopLineName;

PROCEDURE (v: HelpView) LeftLine*(): INTEGER;
BEGIN RETURN CGet(Fl.Live(v), 1)
END LeftLine;

PROCEDURE (v: HelpView) SetLeftLine*(n: INTEGER);
BEGIN CSet(Fl.Live(v), 1, n)
END SetLeftLine;

(* The page's height in pixels. *)
PROCEDURE (v: HelpView) PageSize*(): INTEGER;
BEGIN RETURN CGet(Fl.Live(v), 2)
END PageSize;

PROCEDURE (v: HelpView) TextColor*(): INTEGER;
BEGIN RETURN CGet(Fl.Live(v), 3)
END TextColor;

PROCEDURE (v: HelpView) SetTextColor*(c: INTEGER);
BEGIN CSet(Fl.Live(v), 3, c)
END SetTextColor;

PROCEDURE (v: HelpView) TextFont*(): INTEGER;
BEGIN RETURN CGet(Fl.Live(v), 4)
END TextFont;

PROCEDURE (v: HelpView) SetTextFont*(f: INTEGER);
BEGIN CSet(Laying(v), 4, f)
END SetTextFont;

PROCEDURE (v: HelpView) TextSize*(): INTEGER;
BEGIN RETURN CGet(Fl.Live(v), 5)
END TextSize;

PROCEDURE (v: HelpView) SetTextSize*(s: INTEGER);
BEGIN CSet(Laying(v), 5, s)
END SetTextSize;

(* Its scrollbars' width, 0 for Fl.ScrollbarSize's. *)
PROCEDURE (v: HelpView) ScrollbarSize*(): INTEGER;
BEGIN RETURN CGet(Fl.Live(v), 6)
END ScrollbarSize;

PROCEDURE (v: HelpView) SetScrollbarSize*(s: INTEGER);
BEGIN CSet(Fl.Live(v), 6, s)
END SetScrollbarSize;

PROCEDURE (v: HelpView) TextSelected*(): BOOLEAN;
BEGIN RETURN CGet(Fl.Live(v), 7) # 0
END TextSelected;

PROCEDURE (v: HelpView) ClearSelection*;
BEGIN CClearSelection(Fl.Live(v))
END ClearSelection;

PROCEDURE (v: HelpView) SelectAll*;
BEGIN CSelectAll(Fl.Live(v))
END SelectAll;

(* Copies the selected text, to the clipboard or, without, the selection
   buffer. *)
PROCEDURE (v: HelpView) Copy*(clipboard: BOOLEAN);
BEGIN
  IF clipboard THEN CCopy(Fl.Live(v), 1) ELSE CCopy(Fl.Live(v), 0) END
END Copy;

(* Help dialogs *)

PROCEDURE CloseDialog(d: HelpDialog);
BEGIN
  IF d.h # 0 THEN CDialogDelete(d.h); d.h := 0; DEC(openDialogs) END
END CloseDialog;

(* GC finalizer: a dialog lost without Close. *)
PROCEDURE FinalizeDialog(obj: SYSTEM.PTR);
BEGIN CloseDialog(SYSTEM.VAL(HelpDialog, obj))
END FinalizeDialog;

(* d's handle, halting if d is closed. *)
PROCEDURE Hd(d: HelpDialog): SYSTEM.ADDRESS;
BEGIN
  ASSERT(d # NIL, Fl.NilArgument); ASSERT(d.h # 0, Fl.ClosedResource);
  RETURN d.h
END Hd;

(* Opens d, hidden. *)
PROCEDURE OpenHelpDialog*(d: HelpDialog);
BEGIN
  ASSERT(d # NIL, Fl.NilArgument); ASSERT(d.h = 0, Fl.OpenedTwice);
  d.h := CDialogNew(); ASSERT(d.h # 0);  (* out of memory *)
  INC(openDialogs);
  GarbageCollectedHeap.RegisterFinalizer(d, FinalizeDialog)
END OpenHelpDialog;

(* Frees d, hiding it; idempotent. *)
PROCEDURE (d: HelpDialog) Close*;
BEGIN CloseDialog(d)
END Close;

PROCEDURE (d: HelpDialog) IsOpen*(): BOOLEAN;
BEGIN RETURN d.h # 0
END IsOpen;

PROCEDURE (d: HelpDialog) Show*;
BEGIN CDialogShow(Hd(d))
END Show;

PROCEDURE (d: HelpDialog) Hide*;
BEGIN CDialogHide(Hd(d))
END Hide;

PROCEDURE (d: HelpDialog) Visible*(): BOOLEAN;
BEGIN RETURN CDialogGet(Hd(d), 0) # 0
END Visible;

(* Loads the page in file; FALSE if it can't be read, FLTK's message
   saying so then being the page. *)
PROCEDURE (d: HelpDialog) Load*(file-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CDialogLoad(Hd(d), file) # 0
END Load;

PROCEDURE (d: HelpDialog) SetValue*(s-: ARRAY OF CHAR);
BEGIN CDialogSetValue(Hd(d), s)
END SetValue;

PROCEDURE (d: HelpDialog) Value*(VAR s: ARRAY OF CHAR);
BEGIN FromC(CDialogValue(Hd(d)), s)
END Value;

PROCEDURE (d: HelpDialog) TextSize*(): INTEGER;
BEGIN RETURN CDialogGet(Hd(d), 1)
END TextSize;

PROCEDURE (d: HelpDialog) SetTextSize*(s: INTEGER);
BEGIN CDialogSetSize(Hd(d), s)
END SetTextSize;

PROCEDURE (d: HelpDialog) SetTopLine*(n: INTEGER);
BEGIN CDialogTop(Hd(d), n)
END SetTopLine;

PROCEDURE (d: HelpDialog) SetTopLineName*(name-: ARRAY OF CHAR);
BEGIN CDialogTopName(Hd(d), name)
END SetTopLineName;

PROCEDURE (d: HelpDialog) X*(): INTEGER;
BEGIN RETURN CDialogGet(Hd(d), 2)
END X;

PROCEDURE (d: HelpDialog) Y*(): INTEGER;
BEGIN RETURN CDialogGet(Hd(d), 3)
END Y;

PROCEDURE (d: HelpDialog) W*(): INTEGER;
BEGIN RETURN CDialogGet(Hd(d), 4)
END W;

PROCEDURE (d: HelpDialog) H*(): INTEGER;
BEGIN RETURN CDialogGet(Hd(d), 5)
END H;

PROCEDURE (d: HelpDialog) SetPosition*(x, y: INTEGER);
BEGIN CDialogPosition(Hd(d), x, y)
END SetPosition;

PROCEDURE (d: HelpDialog) Resize*(x, y, w, h: INTEGER);
BEGIN CDialogResize(Hd(d), x, y, w, h)
END Resize;

BEGIN
  CRegister(LinkD)
END FlHelp.
