MODULE HaltFormsFreeKind; (* A kind of free there is none of halts with Fl.IndexOutOfRange, 74 *)
IMPORT FlForms;
VAR f: FlForms.Free;
BEGIN
  NEW(f); FlForms.OpenFree(f, 0, 0, 0, 10, 10, "")
END HaltFormsFreeKind.
