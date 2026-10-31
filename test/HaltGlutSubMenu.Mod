MODULE HaltGlutSubMenu; (* Adding to a menu used as a submenu halts with Fl.OutOfOrder, 77 *)
IMPORT FlGlut;
VAR sub, top: INTEGER;

PROCEDURE Picked(v: INTEGER);
END Picked;

BEGIN
  sub := FlGlut.CreateMenu(Picked);
  FlGlut.AddMenuEntry("one", 1);
  top := FlGlut.CreateMenu(Picked);
  FlGlut.AddSubMenu("sub", sub);
  FlGlut.SetMenu(sub);
  FlGlut.AddMenuEntry("two", 2)
END HaltGlutSubMenu.
