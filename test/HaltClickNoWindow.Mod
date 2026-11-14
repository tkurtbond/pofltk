MODULE HaltClickNoWindow; (* FlTest.Click of a widget in no window *)

IMPORT Fl, FlButtons, FlTest;

VAR b: FlButtons.Button;

BEGIN
  NEW(b); FlButtons.OpenButton(b, 0, 0, 10, 10, "");
  IF FlTest.Click(b) THEN END
END HaltClickNoWindow.
