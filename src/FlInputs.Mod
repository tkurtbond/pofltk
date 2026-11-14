MODULE FlInputs; (* Text inputs and outputs: one line or many, numbers, secrets *)

(* Each type is FLTK's class of the same name, opened by its own Open
   procedure. An input's Callback runs, by default, when the user leaves
   it with its text changed (Fl.WhenRelease); Fl.WhenChanged runs it on
   every change, and Fl.WhenEnterKey when Enter is typed.

   The text is UTF-8, and FLTK copies what it is given. Positions in it
   are byte offsets, from 0.

   The C++ part is FlInputs.cpp. *)

IMPORT SYSTEM, Fl;

CONST
  (* the classes, as ofl_input_new numbers them *)
  input = 0; intInput = 1; floatInput = 2; multilineInput = 3;
  secretInput = 4; output = 5; multilineOutput = 6; fileInput = 7;
  inputChoice = 8;

  keyMask = 10000H;  (* FL_KEY_MASK + 1: a shortcut's key is below it *)

TYPE
  (* one line of text *)
  Input* = POINTER TO InputDesc;
  InputDesc* = RECORD (Fl.WidgetDesc) END;

  (* one line, taking only what may be part of a whole number (IntInput)
     or a real one (FloatInput) *)
  IntInput* = POINTER TO IntInputDesc;
  IntInputDesc* = RECORD (InputDesc) END;

  FloatInput* = POINTER TO FloatInputDesc;
  FloatInputDesc* = RECORD (InputDesc) END;

  (* many lines; Enter types a new line *)
  MultilineInput* = POINTER TO MultilineInputDesc;
  MultilineInputDesc* = RECORD (InputDesc) END;

  (* one line, shown as dots *)
  SecretInput* = POINTER TO SecretInputDesc;
  SecretInputDesc* = RECORD (InputDesc) END;

  (* text the user may select and copy, but not change; one line or many *)
  Output* = POINTER TO OutputDesc;
  OutputDesc* = RECORD (InputDesc) END;

  MultilineOutput* = POINTER TO MultilineOutputDesc;
  MultilineOutputDesc* = RECORD (OutputDesc) END;

  (* one line, for a file's path, with a bar above it of the path's
     directories: a click on one cuts the path there *)
  FileInput* = POINTER TO FileInputDesc;
  FileInputDesc* = RECORD (InputDesc) END;

  (* one line of text, with a button beside it that pops up a menu of
     texts to put in it. FLTK's is a group, but its input and button are
     its own, so this is a widget, and not an Input: Value is its text,
     and its Callback runs for each change, typed or chosen. Items are
     named by index, as FlMenus' are, and a label is a path, as there. *)
  InputChoice* = POINTER TO InputChoiceDesc;
  InputChoiceDesc* = RECORD (Fl.WidgetDesc) END;

PROCEDURE ["C", "ofl_input_new"] CNew(class, x, y, w, h: SYSTEM.INT32; label: ARRAY OF CHAR; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_input_value"] CValue(i: SYSTEM.ADDRESS; VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_set_value"] CSetValue(i: SYSTEM.ADDRESS; s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_input_set_menu_texts"] CSetMenuTexts(cut, copy, paste: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_input_menu_text"] CMenuText(which: SYSTEM.INT32; VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_file_input_set_value"] CFileSetValue(i: SYSTEM.ADDRESS; s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_file_input_down_box"] CFileDownBox(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_file_input_set_down_box"] CFileSetDownBox(i: SYSTEM.ADDRESS; b: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_ivalue"] CIValue(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_dvalue"] CDValue(i: SYSTEM.ADDRESS): LONGREAL;
PROCEDURE ["C", "ofl_input_set_ivalue"] CSetIValue(i: SYSTEM.ADDRESS; v: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_set_dvalue"] CSetDValue(i: SYSTEM.ADDRESS; v: LONGREAL);
PROCEDURE ["C", "ofl_input_size"] CSize(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_maximum_size"] CMaximumSize(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_set_maximum_size"] CSetMaximumSize(i: SYSTEM.ADDRESS; m: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_insert_position"] CInsertPosition(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_mark"] CMark(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_index"] CIndex(i: SYSTEM.ADDRESS; pos: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_set_position"] CSetPosition(i: SYSTEM.ADDRESS; p, m: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_replace"] CReplace(i: SYSTEM.ADDRESS; b, e: SYSTEM.INT32; s: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_cut"] CCut(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_cut_range"] CCutRange(i: SYSTEM.ADDRESS; a, b: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_insert"] CInsert(i: SYSTEM.ADDRESS; s: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_undo"] CUndo(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_redo"] CRedo(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_readonly"] CReadonly(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_set_readonly"] CSetReadonly(i: SYSTEM.ADDRESS; r: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_wrap"] CWrap(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_set_wrap"] CSetWrap(i: SYSTEM.ADDRESS; w: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_tab_nav"] CTabNav(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_set_tab_nav"] CSetTabNav(i: SYSTEM.ADDRESS; t: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_shortcut"] CShortcut(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_set_shortcut"] CSetShortcut(i: SYSTEM.ADDRESS; s: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_textfont"] CTextFont(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_set_textfont"] CSetTextFont(i: SYSTEM.ADDRESS; f: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_textsize"] CTextSize(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_set_textsize"] CSetTextSize(i: SYSTEM.ADDRESS; s: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_textcolor"] CTextColor(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_set_textcolor"] CSetTextColor(i: SYSTEM.ADDRESS; c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_cursor_color"] CCursorColor(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_set_cursor_color"] CSetCursorColor(i: SYSTEM.ADDRESS; c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_choice_add"] CChoiceAdd(i: SYSTEM.ADDRESS; s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_input_choice_clear"] CChoiceClear(i: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_input_choice_is_item"] CChoiceIsItem(i: SYSTEM.ADDRESS; n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_choice_length"] CChoiceLength(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_choice_item"] CChoiceItem(i: SYSTEM.ADDRESS; n: SYSTEM.INT32; VAR buf: ARRAY OF CHAR; size: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_choice_selected"] CChoiceSelected(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_choice_value"] CChoiceValue(i: SYSTEM.ADDRESS; VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_choice_text_length"] CChoiceTextLength(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_choice_set_value"] CChoiceSetValue(i: SYSTEM.ADDRESS; s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_input_choice_set_index"] CChoiceSetIndex(i: SYSTEM.ADDRESS; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_choice_update_menu"] CChoiceUpdateMenu(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_choice_changed"] CChoiceChanged(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_choice_set_changed"] CChoiceSetChanged(i: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_input_choice_clear_changed"] CChoiceClearChanged(i: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_input_choice_down_box"] CChoiceDownBox(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_choice_set_down_box"] CChoiceSetDownBox(i: SYSTEM.ADDRESS; b: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_choice_textfont"] CChoiceTextFont(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_choice_set_textfont"] CChoiceSetTextFont(i: SYSTEM.ADDRESS; f: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_choice_textsize"] CChoiceTextSize(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_choice_set_textsize"] CChoiceSetTextSize(i: SYSTEM.ADDRESS; s: SYSTEM.INT32);
PROCEDURE ["C", "ofl_input_choice_textcolor"] CChoiceTextColor(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_input_choice_set_textcolor"] CChoiceSetTextColor(i: SYSTEM.ADDRESS; c: SYSTEM.INT32);

PROCEDURE Open(i: Input; class, x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Fl.EndOpen(i, CNew(class, x, y, w, h, label, Fl.BeginOpen(i)))
END Open;

PROCEDURE Bool(b: BOOLEAN): SYSTEM.INT32;
BEGIN
  IF b THEN RETURN 1 END;
  RETURN 0
END Bool;

(* Opening each type. x, y are relative to the window, as FLTK's are; the
   label, shown beside the input, is copied. *)

(* Sets the texts of the menu an input, or a text widget of FlText, pops
   up on the right button: "Cut", "Copy" and "Paste" to start with (FLTK's
   Fl_Input::cut_menu_text and the rest), as for another language. *)
PROCEDURE SetMenuTexts*(cut-, copy-, paste-: ARRAY OF CHAR);
BEGIN CSetMenuTexts(cut, copy, paste)
END SetMenuTexts;

(* The menu's texts, each cut to fit. *)
PROCEDURE GetMenuTexts*(VAR cut, copy, paste: ARRAY OF CHAR);
BEGIN
  CMenuText(0, cut, SHORT(LEN(cut))); CMenuText(1, copy, SHORT(LEN(copy)));
  CMenuText(2, paste, SHORT(LEN(paste)))
END GetMenuTexts;

PROCEDURE OpenInput*(i: Input; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(i, input, x, y, w, h, label)
END OpenInput;

PROCEDURE OpenIntInput*(i: IntInput; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(i, intInput, x, y, w, h, label)
END OpenIntInput;

PROCEDURE OpenFloatInput*(i: FloatInput; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(i, floatInput, x, y, w, h, label)
END OpenFloatInput;

PROCEDURE OpenMultilineInput*(i: MultilineInput; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(i, multilineInput, x, y, w, h, label)
END OpenMultilineInput;

PROCEDURE OpenSecretInput*(i: SecretInput; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(i, secretInput, x, y, w, h, label)
END OpenSecretInput;

PROCEDURE OpenOutput*(i: Output; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(i, output, x, y, w, h, label)
END OpenOutput;

PROCEDURE OpenMultilineOutput*(i: MultilineOutput; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(i, multilineOutput, x, y, w, h, label)
END OpenMultilineOutput;

(* The text *)

(* The text, truncated to fit s; Length gives its whole length. *)
PROCEDURE (i: Input) Value*(VAR s: ARRAY OF CHAR);
BEGIN CValue(Fl.Live(i), s, SHORT(LEN(s)))
END Value;

(* Replaces the text, without calling the Callback, and clears Changed. *)
PROCEDURE (i: Input) SetValue*(s-: ARRAY OF CHAR);
BEGIN CSetValue(Fl.Live(i), s)
END SetValue;

(* The text as a number: 0 if it doesn't start with one. *)
PROCEDURE (i: Input) IntValue*(): INTEGER;
BEGIN RETURN CIValue(Fl.Live(i))
END IntValue;

PROCEDURE (i: Input) RealValue*(): LONGREAL;
BEGIN RETURN CDValue(Fl.Live(i))
END RealValue;

(* Sets the text to the number, as SetValue does. *)
PROCEDURE (i: Input) SetIntValue*(v: INTEGER);
BEGIN CSetIValue(Fl.Live(i), v)
END SetIntValue;

PROCEDURE (i: Input) SetRealValue*(v: LONGREAL);
BEGIN CSetDValue(Fl.Live(i), v)
END SetRealValue;

(* The length of the text, in bytes. *)
PROCEDURE (i: Input) Length*(): INTEGER;
BEGIN RETURN CSize(Fl.Live(i))
END Length;

(* The text, of any length, to its first 0X, if it has one. *)
PROCEDURE (i: Input) Text*(): Fl.String;
  VAR s: Fl.String;
BEGIN
  NEW(s, i.Length() + 1); i.Value(s^);
  RETURN s
END Text;

(* The most bytes the user may type in; 32767 to start with. *)
PROCEDURE (i: Input) MaximumSize*(): INTEGER;
BEGIN RETURN CMaximumSize(Fl.Live(i))
END MaximumSize;

PROCEDURE (i: Input) SetMaximumSize*(m: INTEGER);
BEGIN CSetMaximumSize(Fl.Live(i), m)
END SetMaximumSize;

(* The cursor, and the selection, which runs from the cursor to the mark;
   none if they are the same. *)
PROCEDURE (i: Input) InsertPosition*(): INTEGER;
BEGIN RETURN CInsertPosition(Fl.Live(i))
END InsertPosition;

PROCEDURE (i: Input) Mark*(): INTEGER;
BEGIN RETURN CMark(Fl.Live(i))
END Mark;

(* The character at byte pos of the text, 0 at its end (pos the text's
   length); a byte that isn't UTF-8 is read as CP1252 or Latin-1. *)
PROCEDURE (i: Input) Index*(pos: INTEGER): INTEGER;
VAR c: INTEGER;
BEGIN
  c := CIndex(Fl.Live(i), pos); ASSERT(c >= 0, Fl.IndexOutOfRange);
  RETURN c
END Index;

(* Puts the cursor at p and the mark at m, so selecting p .. m. *)
PROCEDURE (i: Input) Select*(p, m: INTEGER);
BEGIN CSetPosition(Fl.Live(i), p, m)
END Select;

(* Edits. Each is undoable, and returns FALSE if nothing changed. *)

(* Replaces bytes b .. e - 1 with s, and puts the cursor after it. *)
PROCEDURE (i: Input) Replace*(b, e: INTEGER; s-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CReplace(Fl.Live(i), b, e, s) # 0
END Replace;

(* Deletes the selection, without copying it. *)
PROCEDURE (i: Input) Cut*(): BOOLEAN;
BEGIN RETURN CCut(Fl.Live(i)) # 0
END Cut;

(* Deletes bytes a .. b - 1. *)
PROCEDURE (i: Input) CutRange*(a, b: INTEGER): BOOLEAN;
BEGIN RETURN CCutRange(Fl.Live(i), a, b) # 0
END CutRange;

(* Replaces the selection with s, or inserts s at the cursor. *)
PROCEDURE (i: Input) Insert*(s-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CInsert(Fl.Live(i), s) # 0
END Insert;

PROCEDURE (i: Input) Undo*(): BOOLEAN;
BEGIN RETURN CUndo(Fl.Live(i)) # 0
END Undo;

PROCEDURE (i: Input) Redo*(): BOOLEAN;
BEGIN RETURN CRedo(Fl.Live(i)) # 0
END Redo;

(* Settings *)

(* A read-only input is an output: the user may select, not change. *)
PROCEDURE (i: Input) Readonly*(): BOOLEAN;
BEGIN RETURN CReadonly(Fl.Live(i)) # 0
END Readonly;

PROCEDURE (i: Input) SetReadonly*(r: BOOLEAN);
BEGIN CSetReadonly(Fl.Live(i), Bool(r))
END SetReadonly;

(* Whether a multiline input or output wraps its lines at its width. *)
PROCEDURE (i: Input) Wrap*(): BOOLEAN;
BEGIN RETURN CWrap(Fl.Live(i)) # 0
END Wrap;

PROCEDURE (i: Input) SetWrap*(w: BOOLEAN);
BEGIN CSetWrap(Fl.Live(i), Bool(w))
END SetWrap;

(* Whether Tab moves the focus to the next widget (TRUE to start with),
   rather than typing a tab, in a multiline input. *)
PROCEDURE (i: Input) TabNav*(): BOOLEAN;
BEGIN RETURN CTabNav(Fl.Live(i)) # 0
END TabNav;

PROCEDURE (i: Input) SetTabNav*(t: BOOLEAN);
BEGIN CSetTabNav(Fl.Live(i), Bool(t))
END SetTabNav;

(* The key that gives i the focus, as a button's shortcut is. *)
PROCEDURE (i: Input) Shortcut*(VAR key: INTEGER; VAR state: SET);
  VAR s: INTEGER;
BEGIN
  s := CShortcut(Fl.Live(i));
  key := s MOD keyMask; state := SYSTEM.VAL(SET, s - key)
END Shortcut;

PROCEDURE (i: Input) SetShortcut*(key: INTEGER; state: SET);
BEGIN CSetShortcut(Fl.Live(i), key + ORD(state))
END SetShortcut;

(* The text's font, size and color, and the cursor's color. *)
PROCEDURE (i: Input) TextFont*(): INTEGER;
BEGIN RETURN CTextFont(Fl.Live(i))
END TextFont;

PROCEDURE (i: Input) SetTextFont*(f: INTEGER);
BEGIN CSetTextFont(Fl.Live(i), f)
END SetTextFont;

PROCEDURE (i: Input) TextSize*(): INTEGER;
BEGIN RETURN CTextSize(Fl.Live(i))
END TextSize;

PROCEDURE (i: Input) SetTextSize*(s: INTEGER);
BEGIN CSetTextSize(Fl.Live(i), s)
END SetTextSize;

PROCEDURE (i: Input) TextColor*(): INTEGER;
BEGIN RETURN CTextColor(Fl.Live(i))
END TextColor;

PROCEDURE (i: Input) SetTextColor*(c: INTEGER);
BEGIN CSetTextColor(Fl.Live(i), c)
END SetTextColor;

PROCEDURE (i: Input) CursorColor*(): INTEGER;
BEGIN RETURN CCursorColor(Fl.Live(i))
END CursorColor;

PROCEDURE (i: Input) SetCursorColor*(c: INTEGER);
BEGIN CSetCursorColor(Fl.Live(i), c)
END SetCursorColor;

(* File inputs *)

PROCEDURE OpenFileInput*(i: FileInput; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Open(i, fileInput, x, y, w, h, label)
END OpenFileInput;

PROCEDURE (i: FileInput) SetValue*(s-: ARRAY OF CHAR);
BEGIN CFileSetValue(Fl.Live(i), s)
END SetValue;

(* The box of each part of the bar. *)
PROCEDURE (i: FileInput) DownBox*(): INTEGER;
BEGIN RETURN CFileDownBox(Fl.Live(i))
END DownBox;

PROCEDURE (i: FileInput) SetDownBox*(b: INTEGER);
BEGIN CFileSetDownBox(Fl.Live(i), b)
END SetDownBox;

(* Input choices *)

PROCEDURE OpenInputChoice*(i: InputChoice; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Fl.EndOpen(i, CNew(inputChoice, x, y, w, h, label, Fl.BeginOpen(i)))
END OpenInputChoice;

(* Adds an item with the label s; "|" in s separates several. A tab
   ends an item's label, and what follows the last tab is its shortcut,
   as FLTK's fl_old_shortcut reads it: prefixes "#" Alt, "+" Shift, "^"
   Ctrl, "!" Meta and "@" Command, in that order, then a character or a
   number ("^a" is Ctrl+A). A label is cut to 1023 bytes, as
   FlMenus.Menu.Insert cuts one. *)
PROCEDURE (i: InputChoice) Add*(s-: ARRAY OF CHAR);
BEGIN CChoiceAdd(Fl.Live(i), s)
END Add;

PROCEDURE (i: InputChoice) Clear*;
BEGIN CChoiceClear(Fl.Live(i))
END Clear;

(* The menu's array's length, with its ends, as FlMenus.Menu.Length. *)
PROCEDURE (i: InputChoice) Length*(): INTEGER;
BEGIN RETURN CChoiceLength(Fl.Live(i))
END Length;

(* Whether n names an item. *)
PROCEDURE (i: InputChoice) IsItem*(n: INTEGER): BOOLEAN;
BEGIN RETURN CChoiceIsItem(Fl.Live(i), n) # 0
END IsItem;

(* Item n's label, truncated to fit s. *)
PROCEDURE (i: InputChoice) Item*(n: INTEGER; VAR s: ARRAY OF CHAR);
BEGIN
  ASSERT(i.IsItem(n), Fl.IndexOutOfRange);
  CChoiceItem(Fl.Live(i), n, s, SHORT(LEN(s)))
END Item;

(* The item last chosen, or -1. Typing doesn't change it, nor does
   SetValue, until UpdateMenu. *)
PROCEDURE (i: InputChoice) Selected*(): INTEGER;
BEGIN RETURN CChoiceSelected(Fl.Live(i))
END Selected;

(* The text, truncated to fit s. *)
PROCEDURE (i: InputChoice) Value*(VAR s: ARRAY OF CHAR);
BEGIN CChoiceValue(Fl.Live(i), s, SHORT(LEN(s)))
END Value;

(* The text, of any length. *)
PROCEDURE (i: InputChoice) Text*(): Fl.String;
  VAR s: Fl.String;
BEGIN
  NEW(s, CChoiceTextLength(Fl.Live(i)) + 1); i.Value(s^);
  RETURN s
END Text;

(* Sets the text, which need not be an item, and leaves Selected alone. *)
PROCEDURE (i: InputChoice) SetValue*(s-: ARRAY OF CHAR);
BEGIN CChoiceSetValue(Fl.Live(i), s)
END SetValue;

(* Selects item n, and sets the text to its label. *)
PROCEDURE (i: InputChoice) SetValueIndex*(n: INTEGER);
BEGIN
  ASSERT(i.IsItem(n), Fl.IndexOutOfRange);
  CChoiceSetIndex(Fl.Live(i), n)
END SetValueIndex;

(* Selects the first item whose label is the text; FALSE if none is. *)
PROCEDURE (i: InputChoice) UpdateMenu*(): BOOLEAN;
BEGIN RETURN CChoiceUpdateMenu(Fl.Live(i)) # 0
END UpdateMenu;

(* Changed counts the input's own state too. *)
PROCEDURE (i: InputChoice) Changed*(): BOOLEAN;
BEGIN RETURN CChoiceChanged(Fl.Live(i)) # 0
END Changed;

PROCEDURE (i: InputChoice) SetChanged*(c: BOOLEAN);
BEGIN
  IF c THEN CChoiceSetChanged(Fl.Live(i)) ELSE CChoiceClearChanged(Fl.Live(i)) END
END SetChanged;

(* The box of the menu's selected item. *)
PROCEDURE (i: InputChoice) DownBox*(): INTEGER;
BEGIN RETURN CChoiceDownBox(Fl.Live(i))
END DownBox;

PROCEDURE (i: InputChoice) SetDownBox*(b: INTEGER);
BEGIN CChoiceSetDownBox(Fl.Live(i), b)
END SetDownBox;

(* The text's font, size and color. *)
PROCEDURE (i: InputChoice) TextFont*(): INTEGER;
BEGIN RETURN CChoiceTextFont(Fl.Live(i))
END TextFont;

PROCEDURE (i: InputChoice) SetTextFont*(f: INTEGER);
BEGIN CChoiceSetTextFont(Fl.Live(i), f)
END SetTextFont;

PROCEDURE (i: InputChoice) TextSize*(): INTEGER;
BEGIN RETURN CChoiceTextSize(Fl.Live(i))
END TextSize;

PROCEDURE (i: InputChoice) SetTextSize*(s: INTEGER);
BEGIN CChoiceSetTextSize(Fl.Live(i), s)
END SetTextSize;

PROCEDURE (i: InputChoice) TextColor*(): INTEGER;
BEGIN RETURN CChoiceTextColor(Fl.Live(i))
END TextColor;

PROCEDURE (i: InputChoice) SetTextColor*(c: INTEGER);
BEGIN CChoiceSetTextColor(Fl.Live(i), c)
END SetTextColor;

END FlInputs.
