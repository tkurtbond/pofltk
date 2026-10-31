MODULE SimpleTerminal; (* FLTK's examples/simple-terminal.cxx: a program's status messages, in a terminal in its window *)

(* FLTK's program prints ctime's text every 2 seconds. Oberon's library
   has no clock that tells the date, so this one asks date(1) for the
   same text, line feed and all. *)

IMPORT Strings, Fl, FlTerminal, Pipe;

CONST
  height = 120;  (* of the terminal *)
  ESC = 1BX;
  LF = 0AX;
  dateCmd = "LC_ALL=C date '+%a %b %e %T %Y'";

TYPE
  Tick = POINTER TO RECORD (Fl.TimerDesc) END;

VAR
  win: Fl.DoubleWindow;
  box: Fl.Box;
  tty: FlTerminal.Terminal;
  tick: Tick;
  s: ARRAY 80 OF CHAR;

(* Appends a sequence setting the text's color or attributes. *)
PROCEDURE Sgr(code-: ARRAY OF CHAR);
BEGIN tty.Append(ESC); tty.Append("["); tty.Append(code); tty.Append("m")
END Sgr;

(* Appends a date/time message to the terminal every 2 seconds. *)
PROCEDURE (t: Tick) Fire*;
  VAR p: Pipe.Pipe; s: ARRAY 64 OF CHAR; ignored: INTEGER;
BEGIN
  s := "";
  NEW(p);
  IF Pipe.Open(p, dateCmd) THEN
    IF ~p.ReadLine(s) THEN s := "" END;
    ignored := p.Close()
  END;
  tty.Append("Timer tick: ");
  Sgr("32"); tty.Append(s); Sgr("0");
  tty.Append(LF);
  Fl.RepeatTimeout(t, 2.0D0)
END Fire;

BEGIN
  NEW(win); Fl.OpenDoubleWindow(win, 500, 200 + height, "Your App");
  NEW(box); Fl.OpenBox(box, 0, 0, win.W(), 200, "");
  s := "Your app GUI in this area."; Strings.Append(LF, s); Strings.Append(LF, s);
  Strings.Append("Your app's debugging output in tty below", s);
  box.SetLabel(s);

  (* a simple terminal at the bottom, for a scrolling history of status messages *)
  NEW(tty); FlTerminal.OpenTerminal(tty, 0, 200, win.W(), height, "");
  tty.SetAnsi(TRUE);                      (* so that ESC[32m is a color *)

  win.End;
  win.SetResizable(win);
  win.ShowArgs;
  NEW(tick); Fl.AddTimeout(tick, 0.5D0);
  Fl.Run
END SimpleTerminal.
