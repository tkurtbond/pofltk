MODULE Console; (* A terminal showing the output of commands typed in a line below it *)

(* Enter runs the line with the shell, and its output and errors come
   into the terminal as they are written, with their colors, if they
   have any: try "ls --color=always /" or "ping -c 3 localhost". The
   line takes no input until the command ends. The window waits while
   a line of output is being written, as a pipe reads whole lines. *)

IMPORT Err, Strings, Fl, FlInputs, FlTerminal, Pipe;

CONST
  ESC = 1BX;
  LF = 0AX;
  green = "1;32";
  red = "1;31";
  normal = "0";

TYPE
  (* Adds each line of the command's output to the terminal. *)
  Watch = POINTER TO RECORD (Fl.FdWatchDesc)
    pipe: Pipe.Pipe
  END;
  Command = POINTER TO RECORD (FlInputs.InputDesc) END;

VAR
  win: Fl.DoubleWindow;
  tty: FlTerminal.Terminal;
  line: Command;

(* Appends a sequence setting the text's color or attributes. *)
PROCEDURE Sgr(code-: ARRAY OF CHAR);
BEGIN tty.Append(ESC); tty.Append("["); tty.Append(code); tty.Append("m")
END Sgr;

PROCEDURE Say(color-, s-: ARRAY OF CHAR);
BEGIN Sgr(color); tty.Append(s); tty.Append(LF); Sgr(normal)
END Say;

(* Appends n's decimal digits to s. *)
PROCEDURE Digits(n: INTEGER; VAR s: ARRAY OF CHAR);
  VAR r: ARRAY 2 OF CHAR;
BEGIN
  IF n >= 10 THEN Digits(n DIV 10, s) END;
  r[0] := CHR(ORD("0") + n MOD 10); r[1] := 0X;
  Strings.Append(r, s)
END Digits;

(* The command is over: the line takes the next one. *)
PROCEDURE Ready;
  VAR ignored: BOOLEAN;
BEGIN
  line.SetValue("");
  line.Activate;
  ignored := line.TakeFocus()
END Ready;

PROCEDURE (w: Watch) Ready*;
  VAR s: ARRAY 1024 OF CHAR; status: INTEGER;
BEGIN
  IF w.pipe.ReadLine(s) THEN
    tty.Append(s)
  ELSE
    Fl.UnwatchFd(w);
    status := w.pipe.Close();
    Sgr(normal);                           (* the command may have left a color set *)
    IF status # 0 THEN
      s := "exit status ";
      IF status < 0 THEN Strings.Append("unknown", s) ELSE Digits(status, s) END;
      Say(red, s)
    END;
    Ready
  END
END Ready;

PROCEDURE (c: Command) Callback*;
  VAR s: ARRAY 1024 OF CHAR; cmd: ARRAY 1050 OF CHAR; w: Watch; shown: ARRAY 1030 OF CHAR;
BEGIN
  c.Value(s);
  IF s = "" THEN RETURN END;
  shown := "$ "; Strings.Append(s, shown);
  Say(green, shown);
  (* the braces send the errors of every command in the line *)
  cmd := "{ "; Strings.Append(s, cmd);
  Strings.Append(LF, cmd); Strings.Append("} 2>&1", cmd);
  NEW(w); NEW(w.pipe);
  IF Pipe.Open(w.pipe, cmd) THEN
    c.Deactivate;
    Fl.WatchFd(w, w.pipe.Fd(), Fl.FdRead)
  ELSE
    Say(red, "popen failed");
    Ready
  END
END Callback;

BEGIN
  NEW(win); Fl.OpenDoubleWindow(win, 640, 400, "Console");
  NEW(tty); FlTerminal.OpenTerminal(tty, 0, 0, 640, 365, "");
  tty.SetAnsi(TRUE);
  tty.SetHistoryRows(1000);
  NEW(line); FlInputs.OpenInput(line, 70, 370, 560, 25, "Run:");
  line.SetWhen(Fl.WhenEnterKeyAlways);    (* the callback on Enter *)
  win.End;
  win.SetResizable(tty);
  Say(green, "Type a command below, and press Enter.");
  win.ShowArgs;
  Fl.Run
END Console.
