MODULE HaltGlutMenuNil; (* CreateMenu with no procedure halts with Fl.NilArgument, 72 *)
IMPORT FlGlut;
VAR m: INTEGER;
BEGIN
  m := FlGlut.CreateMenu(NIL)
END HaltGlutMenuNil.
