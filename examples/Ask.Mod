MODULE Ask; (* FLTK's test/ask.cxx in Oberon-2 *)

(* The common dialogs, nested: closing the window asks first, and every
   5 seconds, up to 10 times, a question pops up over whatever is open.
   The password is limited to 20 characters, as FLTK's program is when
   FLTK uses std::string, and as its dialog says. *)

IMPORT Fl, FlButtons, FlDialogs;

TYPE
  (* the nested question, every 5 seconds *)
  Popper = POINTER TO RECORD (Fl.TimerDesc) END;

VAR
  window: Fl.DoubleWindow;
  b: FlButtons.ReturnButton;
  b2: FlButtons.Button;
  popper: Popper;
  stop: BOOLEAN;
  n: INTEGER;

(* s with each "|" a line feed *)
PROCEDURE Lines(VAR s: ARRAY OF CHAR);
VAR i: INTEGER;
BEGIN
  i := 0; WHILE s[i] # 0X DO IF s[i] = "|" THEN s[i] := 0AX END; INC(i) END
END Lines;

(* Appends n, not negative, to s. *)
PROCEDURE Num(n: INTEGER; VAR s: ARRAY OF CHAR);
VAR i: INTEGER;
BEGIN
  IF n >= 10 THEN Num(n DIV 10, s) END;
  i := 0; WHILE s[i] # 0X DO INC(i) END;
  s[i] := CHR(ORD("0") + n MOD 10); s[i + 1] := 0X
END Num;

(* Renames the button with what is typed. *)
PROCEDURE RenameInput(o: Fl.Widget);
VAR s: ARRAY 1024 OF CHAR;
BEGIN
  FlDialogs.SetIconLabel("§");
  o.GetLabel(s);
  IF FlDialogs.Input("Input (no size limit, use ctrl/j for newline):", s) THEN o.SetLabel(s) END
END RenameInput;

PROCEDURE RenamePassword(o: Fl.Widget);
VAR s: ARRAY 1024 OF CHAR;
BEGIN
  FlDialogs.SetIconLabel("€");
  o.GetLabel(s);
  IF FlDialogs.PasswordLimited("Enter password (max. 20 characters):", s, 20) THEN o.SetLabel(s) END
END RenamePassword;

PROCEDURE WindowCallback(win: Fl.Widget);
VAR hotspot: BOOLEAN; rep: INTEGER;
BEGIN
  hotspot := FlDialogs.Hotspot();
  FlDialogs.SetHotspot(FALSE);
  FlDialogs.SetTitle("note: no hotspot set for this dialog");
  rep := FlDialogs.Choice("Are you sure you want to quit?", "Cancel", "Quit", "Dunno");
  FlDialogs.SetHotspot(hotspot);
  IF rep = 1 THEN HALT(0)
  ELSIF rep = 2 THEN  (* Dunno *)
    FlDialogs.SetPositionOver(win);
    FlDialogs.SetTitle("This dialog must be centered over the main window");
    FlDialogs.Message("Well, maybe you should know before we quit.")
  END
END WindowCallback;

(* Shows a question, nested in any dialog already open, until stopped by
   its button or the Enter key, or 10 have been shown. Closing it, or
   Escape, just closes it. *)
PROCEDURE (p: Popper) Fire*;
CONST delta = 5.0D0; nmax = 10;
VAR box, font, size, c, labelColor: INTEGER; title: ARRAY 40 OF CHAR; text: ARRAY 512 OF CHAR;
BEGIN
  INC(n);
  IF n >= nmax THEN stop := TRUE END;
  FlDialogs.Icon(box, font, size, c, labelColor);
  IF stop THEN FlDialogs.SetIcon(box, font, size, Fl.White, labelColor); RETURN END;
  Fl.RepeatTimeout(p, delta);
  (* change the icon box's color *)
  c := (c + 1) MOD 32;
  IF c = labelColor THEN INC(c) END;
  FlDialogs.SetIcon(box, font, size, c, labelColor);
  title := "Message #"; Num(n, title);
  FlDialogs.SetTitle(title);
  text := "Timeout. Click the 'Close' button or press Escape.|Note: this message had been blocked in FLTK 1.3|and earlier if another message window was open.|This message should pop up every 5 seconds (max. 10 times)|in FLTK 1.4 and later until stopped by clicking the button|below or by pressing the Enter (Return) key.|";
  Lines(text);
  (* fl_choice's Escape and close are 0, Close *)
  IF FlDialogs.Choice(text, "Close", "Stop these funny popups", "") = 1 THEN stop := TRUE END
END Fire;

BEGIN
  NEW(window); Fl.OpenDoubleWindow(window, 200, 105, "");
  NEW(b); FlButtons.OpenReturnButton(b, 20, 10, 160, 35, "Test text");
  b.action := RenameInput;
  NEW(b2); FlButtons.OpenButton(b2, 20, 50, 160, 35, "MyPassword");
  b2.action := RenamePassword;
  window.End;
  window.SetResizable(b);
  window.ShowArgs;
  window.action := WindowCallback;
  NEW(popper); Fl.AddTimeout(popper, 5.0D0);
  Fl.Run
END Ask.
