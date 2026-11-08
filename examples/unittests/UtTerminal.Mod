MODULE UtTerminal; (* FLTK's test/unittest_terminal.cxx in Oberon-2 *)

(* Two terminals: one showing the ANSI colors, one shades of gray, each
   told the date every 3 seconds. FLTK's test prints ctime's text; Oberon's
   library has no clock that tells the date, so this one asks date(1) for
   the same text, as SimpleTerminal does. *)

IMPORT Fl, FlTerminal, Pipe, Ut;

CONST
  Label* = "Terminal";
  dateCmd = "LC_ALL=C date '+%a %b %e %T %Y'";

TYPE
  Tick = POINTER TO RECORD (Fl.TimerDesc)
    tty: FlTerminal.Terminal
  END;

(* Appends s, with each "~" an escape and each "|" a line feed. *)
PROCEDURE Put(tty: FlTerminal.Terminal; s: ARRAY OF CHAR);
  VAR i: INTEGER;
BEGIN
  Ut.Lines(s);
  i := 0; WHILE s[i] # 0X DO IF s[i] = "~" THEN s[i] := 1BX END; INC(i) END;
  tty.Append(s)
END Put;

PROCEDURE AnsiPattern(tty: FlTerminal.Terminal);
BEGIN
  Put(tty, "~[30mBlack          Courier 14~[0m Normal text|");
  Put(tty, "~[31mRed            Courier 14~[0m Normal text|");
  Put(tty, "~[32mGreen          Courier 14~[0m Normal text|");
  Put(tty, "~[33mYellow         Courier 14~[0m Normal text|");
  Put(tty, "~[34mBlue           Courier 14~[0m Normal text|");
  Put(tty, "~[35mMagenta        Courier 14~[0m Normal text|");
  Put(tty, "~[36mCyan           Courier 14~[0m Normal text|");
  Put(tty, "~[37mWhite          Courier 14~[0m Normal text|");
  Put(tty, "~[1;30mBright Black   Courier 14~[0m Normal text|");
  Put(tty, "~[1;31mBright Red     Courier 14~[0m Normal text|");
  Put(tty, "~[1;32mBright Green   Courier 14~[0m Normal text|");
  Put(tty, "~[1;33mBright Yellow  Courier 14~[0m Normal text|");
  Put(tty, "~[1;34mBright Blue    Courier 14~[0m Normal text|");
  Put(tty, "~[1;35mBright Magenta Courier 14~[0m Normal text|");
  Put(tty, "~[1;36mBright Cyan    Courier 14~[0m Normal text|");
  Put(tty, "~[1;37mBright White   Courier 14~[0m Normal text|");
  Put(tty, "|");
  Put(tty, "~[31mRed~[32mGreen~[33mYellow~[34mBlue~[35mMagenta~[36mCyan~[37mWhite~[0m - ");
  Put(tty, "~[31mX~[32mX~[33mX~[34mX~[35mX~[36mX~[37mX~[0m|");
  Put(tty, "~[1;31mRed~[1;32mGreen~[1;33mYellow~[34mBlue~[35mMagenta~[36mCyan~[1;37mWhite~[1;0m - ");
  Put(tty, "~[1;31mX~[1;32mX~[1;33mX~[1;34mX~[1;35mX~[1;36mX~[1;37mX~[0m|")
END AnsiPattern;

PROCEDURE GrayPattern(tty: FlTerminal.Terminal);
BEGIN
  Put(tty, "Grayscale Test Pattern|");
  Put(tty, "--------------------------|");
  (* xterm's sequences setting an RGB color *)
  Put(tty, "~[38;2;255;255;255m 100% white     Courier 14|");
  Put(tty, "~[38;2;230;230;230m 90%  white     Courier 14|");
  Put(tty, "~[38;2;205;205;205m 80%  white     Courier 14|");
  Put(tty, "~[38;2;179;179;179m 70%  white     Courier 14|");
  Put(tty, "~[38;2;154;154;154m 60%  white     Courier 14|");
  Put(tty, "~[38;2;128;128;128m 50%  white     Courier 14|");
  Put(tty, "~[38;2;102;102;102m 40%  white     Courier 14|");
  Put(tty, "~[38;2;77;77;77m 30%  white     Courier 14|");
  Put(tty, "~[38;2;51;51;51m 20%  white     Courier 14|");
  Put(tty, "~[38;2;26;26;26m 10%  white     Courier 14|");
  Put(tty, "~[38;2;0;0;0m  0%  white     Courier 14|");
  Put(tty, "~[0m")
END GrayPattern;

PROCEDURE (t: Tick) Fire*;
  VAR p: Pipe.Pipe; s: ARRAY 64 OF CHAR; ignored: INTEGER;
BEGIN
  s := "";
  NEW(p);
  IF Pipe.Open(p, dateCmd) THEN
    IF ~p.ReadLine(s) THEN s := "" END;
    ignored := p.Close()
  END;
  (* the line keeps its line feed, as ctime's text has one *)
  IF s = "" THEN s := "|"; Ut.Lines(s) END;
  t.tty.Append("The time and date is now: "); t.tty.Append(s);
  Fl.RepeatTimeout(t, 3.0D0)
END Fire;

PROCEDURE Start(tty: FlTerminal.Terminal);
  VAR t: Tick;
BEGIN NEW(t); t.tty := tty; Fl.AddTimeout(t, 0.5D0)
END Start;

PROCEDURE Create*(): Fl.Widget;
  VAR g: Fl.Group; tty1, tty2: FlTerminal.Terminal; ttyH, ttyY1, ttyY2: INTEGER;
BEGIN
  NEW(g); Fl.OpenGroup(g, Ut.X, Ut.Y, Ut.W, Ut.H, "");
  ttyH := SHORT(ENTIER(Ut.H / 2.25D0 + 0.5D0));
  ttyY1 := Ut.Y + 20; ttyY2 := Ut.Y + ttyH + 40;
  NEW(tty1); FlTerminal.OpenTerminal(tty1, Ut.X, ttyY1, Ut.W, ttyH, "Tty 1: Colors");
  AnsiPattern(tty1); Start(tty1);
  NEW(tty2); FlTerminal.OpenTerminal(tty2, Ut.X, ttyY2, Ut.W, ttyH, "Tty 2: Grayscale");
  GrayPattern(tty2); Start(tty2);
  g.End;
  RETURN g
END Create;

END UtTerminal.
