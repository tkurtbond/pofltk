MODULE MenuBar; (* FLTK's test/menubar.cxx: every kind of menu item, in a menu bar, a menu button, a choice and a pop-up *)

(* What FLTK's test writes to its terminal goes to standard error, until
   pofltk has Fl_Terminal; the window keeps the room for it. Its macOS
   system menu bar is left out, as FLTK's is on other systems. Items are
   added one by one, not from a table: a label added twice at one place
   is the same item, so an item that shares its label is added under a
   label of its own and then renamed. A menu given items one by one has
   no value at first, where FLTK's table gives it its first item, which
   a menu button shows under the mouse. *)

IMPORT Err, Out, Fl, FlDialogs, FlMenus, FlValuators, OutStr;

CONST
  terminalHeight = 120;
  width = 700;

VAR
  win: Fl.DoubleWindow;
  scheme: FlMenus.SchemeChoice;
  menubar: FlMenus.MenuBar;
  mb1, mb: FlMenus.MenuButton;
  ch: FlMenus.Choice;
  b: Fl.Box;
  slider: FlValuators.ValueSlider;
  label: ARRAY 64 OF CHAR;
  unique: INTEGER;
  ok: BOOLEAN;

PROCEDURE WindowCB(w: Fl.Widget);
BEGIN Out.String("window callback called"); Out.Ln; w(Fl.Window).Hide
END WindowCB;

PROCEDURE TestCB(w: Fl.Widget);
  VAR m: FlMenus.Menu; i, key: INTEGER; state: SET; s: ARRAY 256 OF CHAR;
BEGIN
  m := w(FlMenus.Menu); i := m.Value();
  IF i < 0 THEN Err.String("NULL")
  ELSE
    m.ItemLabel(i, s); Err.String(s);
    m.ItemShortcut(i, key, state);
    IF key # 0 THEN Fl.ShortcutLabel(key, state, s); Err.String(" - "); Err.String(s) END
  END;
  Err.Ln
END TestCB;

PROCEDURE QuitCB(w: Fl.Widget);
BEGIN HALT(0)
END QuitCB;

PROCEDURE Add(m: FlMenus.Menu; path: ARRAY OF CHAR; key: INTEGER; state, flags: SET): INTEGER;
BEGIN RETURN m.Add(path, key, state, NIL, flags)
END Add;

PROCEDURE A(m: FlMenus.Menu; path: ARRAY OF CHAR);
  VAR i: INTEGER;
BEGIN i := Add(m, path, 0, {}, {})
END A;

PROCEDURE S(m: FlMenus.Menu; path: ARRAY OF CHAR; key: INTEGER; state, flags: SET);
  VAR i: INTEGER;
BEGIN i := Add(m, path, key, state, flags)
END S;

(* Adds an item labelled label, in the submenu at path, which may have
   others with that label. *)
PROCEDURE Same(m: FlMenus.Menu; path, label: ARRAY OF CHAR; key: INTEGER; state, flags: SET);
  VAR s: ARRAY 64 OF CHAR;
BEGIN
  s := ""; OutStr.String(path, s); OutStr.String("/unique", s); OutStr.Int(unique, 0, s); INC(unique);
  m.SetItemLabel(Add(m, s, key, state, flags), label)
END Same;

PROCEDURE Styled(m: FlMenus.Menu; path: ARRAY OF CHAR; type, font, size: INTEGER);
  VAR i: INTEGER;
BEGIN
  i := Add(m, path, 0, {}, {});
  m.SetItemLabelType(i, type); m.SetItemLabelFont(i, font); m.SetItemLabelSize(i, size)
END Styled;

(* FLTK's menutable, whose last item but one is the submenu hugemenu. *)
PROCEDURE Table(m: FlMenus.Menu);
  VAR i, n: INTEGER; s: ARRAY 32 OF CHAR; none: SET;
BEGIN
  none := {};
  S(m, "foo", 0, none, FlMenus.MenuInactive);
  S(m, "&File/&Open", ORD("o"), Fl.Alt, FlMenus.MenuInactive);
  A(m, "&File/&Close");
  n := m.Add("&File/&Quit", ORD("q"), Fl.Alt, QuitCB, FlMenus.MenuDivider);
  Same(m, "&File", "shortcut", ORD("a"), none, none);
  Same(m, "&File", "shortcut", ORD("a"), Fl.Shift, none);
  Same(m, "&File", "shortcut", ORD("a"), Fl.Ctrl, none);
  Same(m, "&File", "shortcut", ORD("a"), Fl.Ctrl + Fl.Shift, none);
  Same(m, "&File", "shortcut", ORD("a"), Fl.Alt, none);
  Same(m, "&File", "shortcut", ORD("a"), Fl.Alt + Fl.Shift, none);
  Same(m, "&File", "shortcut", ORD("a"), Fl.Alt + Fl.Ctrl, none);
  Same(m, "&File", "shortcut", ORD("a"), Fl.Alt + Fl.Shift + Fl.Ctrl, FlMenus.MenuDivider);
  Same(m, "&File", "shortcut", 0DH, none, none);
  Same(m, "&File", "shortcut", Fl.KeyEnter, Fl.Ctrl, FlMenus.MenuDivider);
  Same(m, "&File", "shortcut", Fl.KeyF + 1, none, none);
  Same(m, "&File", "shortcut", Fl.KeyF + 1, Fl.Shift, none);
  Same(m, "&File", "shortcut", Fl.KeyF + 1, Fl.Ctrl, none);
  Same(m, "&File", "shortcut", Fl.KeyF + 1, Fl.Shift + Fl.Ctrl, none);
  Same(m, "&File", "shortcut", Fl.KeyF + 1, Fl.Alt, none);
  Same(m, "&File", "shortcut", Fl.KeyF + 1, Fl.Alt + Fl.Shift, none);
  Same(m, "&File", "shortcut", Fl.KeyF + 1, Fl.Alt + Fl.Ctrl, none);
  Same(m, "&File", "shortcut", Fl.KeyF + 1, Fl.Alt + Fl.Shift + Fl.Ctrl, FlMenus.MenuDivider);
  S(m, "&File/&Submenus", ORD("S"), Fl.Alt, FlMenus.Submenu);
  A(m, "&File/&Submenus/A very long menu item");
  S(m, "&File/&Submenus/&submenu", ORD("S"), Fl.Ctrl, FlMenus.Submenu);
  A(m, "&File/&Submenus/&submenu/item 1");
  A(m, "&File/&Submenus/&submenu/item 2");
  A(m, "&File/&Submenus/&submenu/item 3");
  A(m, "&File/&Submenus/&submenu/item 4");
  A(m, "&File/&Submenus/after submenu");
  S(m, "&Edit", Fl.KeyF + 2, none, FlMenus.Submenu);
  S(m, "&Edit/Undo", ORD("z"), Fl.Alt, none);
  S(m, "&Edit/Redo", ORD("r"), Fl.Alt, FlMenus.MenuDivider);
  S(m, "&Edit/Cut", ORD("x"), Fl.Alt, none);
  S(m, "&Edit/Copy", ORD("c"), Fl.Alt, none);
  S(m, "&Edit/Paste", ORD("v"), Fl.Alt, none);
  S(m, "&Edit/Inactive", ORD("d"), Fl.Alt, FlMenus.MenuInactive);
  S(m, "&Edit/Clear", 0, none, FlMenus.MenuDivider);
  S(m, "&Edit/Invisible", ORD("e"), Fl.Alt, FlMenus.MenuInvisible);
  A(m, "&Edit/Preferences");
  A(m, "&Edit/Size");
  S(m, "&Checkbox", Fl.KeyF + 3, none, FlMenus.Submenu);
  S(m, "&Checkbox/&Alpha", Fl.KeyF + 2, none, FlMenus.MenuToggle);
  S(m, "&Checkbox/&Beta", 0, none, FlMenus.MenuToggle);
  S(m, "&Checkbox/&Gamma", 0, none, FlMenus.MenuToggle);
  S(m, "&Checkbox/&Delta", 0, none, FlMenus.MenuToggle + FlMenus.MenuValue);
  S(m, "&Checkbox/&Epsilon", 0, none, FlMenus.MenuToggle);
  S(m, "&Checkbox/&Pi", 0, none, FlMenus.MenuToggle);
  S(m, "&Checkbox/&Mu", 0, none, FlMenus.MenuToggle + FlMenus.MenuDivider);
  i := Add(m, "&Checkbox/Red", 0, none, FlMenus.MenuToggle);
  m.SetItemLabelColor(i, Fl.Red);
  S(m, "&Checkbox/Black", 0, none, FlMenus.MenuToggle + FlMenus.MenuDivider);
  S(m, "&Checkbox/00", 0, none, FlMenus.MenuToggle);
  S(m, "&Checkbox/000", 0, none, FlMenus.MenuToggle);
  S(m, "&Radio/&Alpha", 0, none, FlMenus.MenuRadio);
  S(m, "&Radio/&Beta", 0, none, FlMenus.MenuRadio);
  S(m, "&Radio/&Gamma", 0, none, FlMenus.MenuRadio);
  S(m, "&Radio/&Delta", 0, none, FlMenus.MenuRadio + FlMenus.MenuValue);
  S(m, "&Radio/&Epsilon", 0, none, FlMenus.MenuRadio);
  S(m, "&Radio/&Pi", 0, none, FlMenus.MenuRadio);
  S(m, "&Radio/&Mu", 0, none, FlMenus.MenuRadio + FlMenus.MenuDivider);
  S(m, "&Radio/Red", 0, none, FlMenus.MenuRadio);
  S(m, "&Radio/Black", 0, none, FlMenus.MenuRadio + FlMenus.MenuDivider);
  S(m, "&Radio/00", 0, none, FlMenus.MenuRadio);
  S(m, "&Radio/000", 0, none, FlMenus.MenuRadio);
  Styled(m, "&Font/Normal", Fl.NormalLabel, 0, 14);
  Styled(m, "&Font/Bold", Fl.NormalLabel, Fl.Bold, 14);
  Styled(m, "&Font/Italic", Fl.NormalLabel, Fl.Italic, 14);
  Styled(m, "&Font/BoldItalic", Fl.NormalLabel, Fl.Bold + Fl.Italic, 14);
  Styled(m, "&Font/Small", Fl.NormalLabel, Fl.Bold + Fl.Italic, 10);
  Styled(m, "&Font/Emboss", Fl.EmbossedLabel, 0, 0);
  Styled(m, "&Font/Engrave", Fl.EngravedLabel, 0, 0);
  Styled(m, "&Font/Shadow", Fl.ShadowLabel, 0, 0);
  Styled(m, "&Font/@->", Fl.NormalLabel, 0, 0);
  S(m, "&International/Sharp Ess", 0DFH, none, none);
  S(m, "&International/A Umlaut", 0C4H, none, none);
  S(m, "&International/a Umlaut", 0E4H, none, none);
  S(m, "&International/Euro currency", 20ACH, Fl.Command, none);
  A(m, "&International/the &ü Umlaut");
  A(m, "&International/the capital &Ü");
  A(m, "&International/convert ¥ to &£");
  A(m, "&International/convert ¥ to &€");
  A(m, "&International/Hangul character Sios &ㅅ");
  S(m, "&International/Hangul character Cieuc", 3148H, none, none);
  S(m, "E&mpty", 0, none, FlMenus.Submenu);
  S(m, "&Inactive", 0, none, FlMenus.MenuInactive + FlMenus.Submenu);
  Same(m, "&Inactive", "A very long menu item", 0, none, none);
  Same(m, "&Inactive", "A very long menu item", 0, none, none);
  (* hidden last: FLTK's Add can't find a hidden item, to add to it *)
  i := Add(m, "Invisible", 0, none, FlMenus.Submenu);
  Same(m, "Invisible", "A very long menu item", 0, none, none);
  Same(m, "Invisible", "A very long menu item", 0, none, none);
  m.SetItemFlags(i, FlMenus.Submenu + FlMenus.MenuInvisible);
  FOR i := 0 TO 98 DO
    s := "&Huge/item "; OutStr.Int(i, 0, s); A(m, s)
  END;
  S(m, "button", Fl.KeyF + 4, none, FlMenus.MenuToggle)
END Table;

PROCEDURE Pulldown(m: FlMenus.Menu);
BEGIN
  S(m, "Red", ORD("r"), Fl.Alt, {});
  S(m, "Green", ORD("g"), Fl.Alt, {});
  S(m, "Blue", ORD("b"), Fl.Alt, {});
  S(m, "Strange", ORD("s"), Fl.Alt, FlMenus.MenuInactive);
  S(m, "&Charm", ORD("c"), Fl.Alt, {});
  S(m, "Truth", ORD("t"), Fl.Alt, {});
  S(m, "Beauty", ORD("b"), Fl.Alt, {})
END Pulldown;

PROCEDURE LinespacingCB(w: Fl.Widget);
BEGIN Fl.SetMenuLinespacing(SHORT(ENTIER(slider.Value())))
END LinespacingCB;

BEGIN
  NEW(win); Fl.OpenDoubleWindow(win, width, 400 + terminalHeight, "menubar");
  NEW(scheme); FlMenus.OpenSchemeChoice(scheme, 300, 50, 100, 25, "&scheme");
  win.action := WindowCB;
  NEW(menubar); FlMenus.OpenMenuBar(menubar, 0, 0, width, 30, "");
  Table(menubar);
  menubar.action := TestCB;
  NEW(mb1); FlMenus.OpenMenuButton(mb1, 100, 100, 120, 25, "&menubutton");
  Pulldown(mb1);
  ok := mb1.SetValue(0);
  mb1.SetTooltip("this is a menu button");
  mb1.action := TestCB;
  NEW(ch); FlMenus.OpenChoice(ch, 300, 100, 80, 25, "&choice:");
  Pulldown(ch);
  ok := ch.SetValue(0);
  ch.SetTooltip("this is a choice menu");
  ch.action := TestCB;
  NEW(mb); FlMenus.OpenMenuButton(mb, 0, 0, width, 400, "&popup");
  mb.SetKind(FlMenus.Popup3);
  Table(mb);
  mb.Remove(1);   (* delete the "File" submenu *)
  ok := mb.SetValue(0);
  mb.action := TestCB;
  label := "Press right button?for a pop-up menu"; label[18] := 0AX;
  NEW(b); Fl.OpenBox(b, 200, 200, 200, 100, label);
  win.SetResizable(mb);
  win.SizeRange(300, 400, 0, 400 + terminalHeight);

  NEW(slider); FlValuators.OpenValueSlider(slider, 500, 150, 150, 20, "Fl::menu_linespacing()");
  slider.SetTooltip("Changes the line spacing between all menu items");
  slider.SetKind(FlValuators.HorSlider);
  slider.SetValue(Fl.MenuLinespacing());
  slider.SetColor(46);
  slider.SetSelectionColor(1);
  slider.SetAlign(Fl.AlignLeft);
  slider.SetBounds(0.1D0, 50.0D0);
  slider.SetStep(1.0D0);
  slider.action := LinespacingCB;

  win.End;
  win.ShowArgs;
  Fl.Run
END MenuBar.
