MODULE HaltGlutEmptyMenu; (* Attaching a menu with no items halts with Fl.OutOfOrder, 77 *)
IMPORT FlGlut;
VAR m: INTEGER;

PROCEDURE Picked(v: INTEGER);
END Picked;

BEGIN
  m := FlGlut.CreateMenu(Picked);
  FlGlut.AttachMenu(FlGlut.LeftButton)
END HaltGlutEmptyMenu.
