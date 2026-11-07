MODULE HaltPopup; (* a pop-up of a menu in no window, with no window shown to pop over *)

IMPORT Fl, FlMenus;

VAR m: FlMenus.MenuButton; i: INTEGER;

BEGIN
  NEW(m); FlMenus.OpenMenuButton(m, 0, 0, 100, 25, "Pop");
  i := m.Add("One", 0, {}, NIL, {});
  i := m.Popup()
END HaltPopup.
