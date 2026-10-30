MODULE HaltTrackNil; (* Tracking NIL halts with Fl.NilArgument, 72 *)
IMPORT Fl;
VAR t: Fl.Tracker;
BEGIN NEW(t); t.Track(NIL)
END HaltTrackNil.
