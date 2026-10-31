MODULE HaltFormsTimerKind; (* A kind of timer there is none of halts with Fl.IndexOutOfRange, 74 *)
IMPORT FlForms;
VAR t: FlForms.Timer;
BEGIN
  NEW(t); FlForms.OpenTimer(t, 3, 0, 0, 10, 10, "")
END HaltFormsTimerKind.
