MODULE HaltAbort; (* FLTK's fatal error, with its format filled in, reaches SetAbort's procedure *)

IMPORT Fl, Probe;

PROCEDURE Told(message-: ARRAY OF CHAR);
BEGIN ASSERT(message # "fatal 7", 42)
END Told;

BEGIN
  Fl.SetAbort(Told);
  Probe.Fatal("fatal")
END HaltAbort.
