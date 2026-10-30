MODULE Trackers; (* Fl.Tracker: a callback that may delete its own widget *)

(* Each click takes one from the count, and the last click deletes the
   button, which goes when events are next handled: here, in its own
   callback. The callback uses a tracker to see whether it is still there. *)

IMPORT Fl, FlButtons;

VAR
  window: Fl.Window;
  button: FlButtons.Button;
  left: Fl.Box;
  count: INTEGER;
  text: ARRAY 2 OF CHAR;

PROCEDURE CountDown(w: Fl.Widget);
  VAR t: Fl.Tracker; ignored: BOOLEAN;
BEGIN
  NEW(t); t.Track(w);
  DEC(count);
  IF count = 0 THEN w.Delete END;
  ignored := Fl.Check();
  IF t.Exists() THEN w.Redraw END;
  text[0] := CHR(ORD("0") + count); left.SetLabel(text)
END CountDown;

BEGIN
  NEW(window); Fl.OpenWindow(window, 200, 120, "Trackers");
  NEW(button); FlButtons.OpenButton(button, 40, 20, 120, 30, "count down");
  button.action := CountDown;
  NEW(left); Fl.OpenBox(left, 40, 60, 120, 30, "");
  count := 3; text[0] := "3"; text[1] := 0X; left.SetLabel(text);
  window.End;
  window.Show;
  Fl.Run
END Trackers.
