MODULE HandleEvents; (* FLTK's test/handle_events.cxx in Oberon-2 *)

(* Writes each event the window gets to standard error, with where it
   happened, and what it uses. *)

IMPORT SYSTEM, Err, Fl, FlButtons;

TYPE
  App = POINTER TO RECORD (Fl.DoubleWindowDesc)
    eventnum: INTEGER  (* the last event's, from 1 to 999 *)
  END;

VAR
  win: App;
  quit: FlButtons.Button;

(* x in lower case hexadecimal, as printf's "%x". *)
PROCEDURE Hex(x: INTEGER);
BEGIN
  IF x >= 16 THEN Hex(x DIV 16) END;
  IF x MOD 16 < 10 THEN Err.Char(CHR(ORD("0") + x MOD 16))
  ELSE Err.Char(CHR(ORD("a") + x MOD 16 - 10))
  END
END Hex;

(* s as printf's "%-18.18s". *)
PROCEDURE Name(s: ARRAY OF CHAR);
  VAR i: INTEGER;
BEGIN
  i := 0;
  WHILE (i < 18) & (s[i] # 0X) DO Err.Char(s[i]); INC(i) END;
  WHILE i < 18 DO Err.Char(" "); INC(i) END
END Name;

(* evaluates and prints the current event *)
PROCEDURE (a: App) PrintEvent(ev: INTEGER);
  VAR screen: INTEGER; name: ARRAY 32 OF CHAR;
BEGIN
  INC(a.eventnum);
  screen := a.ScreenNum();
  Fl.EventName(ev, name);
  Err.Char("["); Err.Int(a.eventnum, 3);
  Err.String(", win("); Err.Int(a.X(), 0); Err.Char(","); Err.Int(a.Y(), 0);
  Err.Char(","); Err.Int(a.W(), 0); Err.Char(","); Err.Int(a.H(), 0);
  Err.String("), screen "); Err.Int(screen, 0);
  Err.String(", scale "); Err.Int(ENTIER(Fl.ScreenScale(screen) * 100.0D0 + 0.5D0), 3);
  Err.String("%] "); Name(name);
  Err.String(" at ("); Err.Int(Fl.EventX(), 4); Err.String(", ");
  Err.Int(Fl.EventY(), 4); Err.Char(")");
  a.eventnum := a.eventnum MOD 999
END PrintEvent;

PROCEDURE (a: App) Handle*(ev: INTEGER): BOOLEAN;
  VAR res: BOOLEAN; buttons: INTEGER; text: ARRAY 64 OF CHAR;
BEGIN
  a.PrintEvent(ev);  (* common for all events *)
  res := a.Handle^(ev);
  (* bits: 1 left, 2 middle, 4 right button *)
  buttons := SHORT(ORD(Fl.EventButtons()) DIV 1000000H);
  CASE ev OF
  | Fl.EvPush:
    Err.String(", button "); Err.Int(Fl.EventButton(), 0);
    Err.String(" down, buttons = 0x"); Hex(buttons);
    res := TRUE
  | Fl.EvRelease:
    Err.String(", button "); Err.Int(Fl.EventButton(), 0);
    Err.String(" up,   buttons = 0x"); Hex(buttons);
    res := TRUE
  | Fl.EvMouseWheel:
    Err.String(", dx = "); Err.Int(Fl.EventDx(), 0);
    Err.String(", dy = "); Err.Int(Fl.EventDy(), 0);
    res := TRUE
  | Fl.EvEnter, Fl.EvLeave:
    res := TRUE
  | Fl.EvMove, Fl.EvDrag:
    Err.String(",          mouse buttons = 0x"); Hex(buttons);
    res := TRUE
  | Fl.EvKeyDown:
    Fl.EventText(text);
    IF (text[0] >= "a") & (text[0] <= "z") THEN
      Err.String(", Text = '"); Err.String(text); Err.Char("'");
      res := TRUE
    ELSE  (* "ignore" everything else *)
      Err.String(", ignored '"); Err.String(text); Err.Char("'")
    END
  | Fl.EvKeyUp:
    res := TRUE
  | Fl.EvFocus, Fl.EvUnfocus:
    res := TRUE
  ELSE
  END;
  Err.Ln;
  RETURN res
END Handle;

(* closes the window *)
PROCEDURE Quit(b: Fl.Widget);
  VAR w: Fl.Window;
BEGIN w := b.Window(); w.Hide
END Quit;

BEGIN
  NEW(win); Fl.OpenDoubleWindowAt(win, 10, 10, 240, 240, "");
  NEW(quit); FlButtons.OpenButton(quit, 90, 100, 60, 40, "Quit");
  quit.SetBoxType(Fl.ThinUpBox);
  quit.action := Quit;
  win.End;
  win.SetResizable(win);
  win.ShowArgs;
  Fl.Run
END HandleEvents.
