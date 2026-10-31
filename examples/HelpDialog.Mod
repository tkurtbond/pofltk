MODULE HelpDialog; (* FLTK's test/help_dialog.cxx: a help file in FLTK's own help window *)

(* HelpDialog [file]

   Shows the file, by default test/help.html from examples/, as make test
   runs it; FLTK's test/help_dialog.html is its own program's. Animated
   GIFs move: a timer redraws the windows, as FLTK's program does, though
   it redraws only the first. *)

IMPORT Args, Out, Fl, FlHelp, FlImages;

TYPE
  Refresh = POINTER TO RECORD (Fl.TimerDesc) END;

VAR
  help: FlHelp.HelpDialog;
  refresh: Refresh;
  name: ARRAY 2048 OF CHAR;
  i: INTEGER;
  text: ARRAY 4096 OF CHAR;

PROCEDURE (t: Refresh) Fire*;
BEGIN
  Fl.Redraw;
  Fl.RepeatTimeout(t, 0.1D0)
END Fire;

BEGIN
  FlImages.RegisterImages;
  FlImages.SetAnimateGIFs(TRUE);
  NEW(help); FlHelp.OpenHelpDialog(help);
  IF ~Fl.ParseArgs(NIL, i) THEN
    Fl.ArgsHelp(text); Out.String(text); Out.Ln; HALT(1)
  END;
  IF i < Args.argc THEN Args.Get(i, name) ELSE name := "../test/help.html" END;
  IF ~help.Load(name) THEN Out.String("Can't read "); Out.String(name); Out.Ln END;
  help.Show;
  NEW(refresh); Fl.AddTimeout(refresh, 0.1D0);
  Fl.Run;
  help.Close
END HelpDialog.
