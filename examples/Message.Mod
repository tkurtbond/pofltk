MODULE Message; (* FLTK's test/message.cxx in Oberon-2 *)

(* The common dialogs, one after another: a message, an alert, two
   choices, an input and a password, each answer printed. The program
   ends after the last.

   FLTK's program writes its numbers with printf ("%g"); they are
   constants, so the text here has them written out. fl_choice gives 0 for Escape or closing the dialog,
   where FlDialogs.Choice gives Escaped or Closed, so those print 0. *)

IMPORT Args, Err, Out, Fl, FlDialogs;

VAR
  s: ARRAY 1024 OF CHAR;
  i, r: INTEGER;

(* s with each "|" a line feed *)
PROCEDURE Lines(VAR s: ARRAY OF CHAR);
VAR i: INTEGER;
BEGIN
  i := 0; WHILE s[i] # 0X DO IF s[i] = "|" THEN s[i] := 0AX END; INC(i) END
END Lines;

PROCEDURE Choice(r: INTEGER);
BEGIN
  IF r < 0 THEN r := 0 END;
  Out.String("fl_choice returned "); Out.Int(r, 0); Out.Ln
END Choice;

BEGIN
  IF Fl.SetSystemScheme() THEN END;
  IF ~Fl.ParseArgs(NIL, i) OR (i < Args.argc) THEN
    (* as FLTK's Fl::args(argc, argv) does *)
    Fl.ArgsHelp(s); Err.String("options are:"); Err.Ln; Err.String(s); Err.Ln
  END;
  Fl.GetSystemColors;

  FlDialogs.Message("Spelling check sucessful, 1002 errors found with 19.4805% confidence");

  s := 'Quantum fluctuations in the space-time continuum detected,|you have 10 seconds to comply.||"In physics, spacetime is any mathematical model that combines|space and time into a single construct called the space-time|continuum. Spacetime is usually interpreted with space being|three-dimensional and time playing the role of the|fourth dimension." - Wikipedia';
  Lines(s);
  FlDialogs.Alert(s);

  Choice(FlDialogs.Choice("Do you really want to continue?", "No", "Yes", ""));
  Choice(FlDialogs.Choice("Choose one of the following:", "choice0", "choice1", "choice2"));

  s := "this is the default value";
  IF FlDialogs.Input("Please enter a string for 'testing':", s) THEN
    Out.String('fl_input returned "'); Out.String(s); Out.String('"')
  ELSE Out.String('fl_input returned "NULL"')
  END;
  Out.Ln;

  s := "";
  IF FlDialogs.Password("Enter somebody's password:", s) THEN
    Out.String('fl_password returned "'); Out.String(s); Out.String('"')
  ELSE Out.String('fl_password returned "NULL"')
  END;
  Out.Ln
END Message.
