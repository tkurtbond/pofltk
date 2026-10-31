MODULE HaltHelpImage; (* a view's page set as it asks about an image (Fl.OutOfOrder) *)

IMPORT FlHelp;

TYPE
  View = POINTER TO RECORD (FlHelp.HelpViewDesc) END;

VAR v: View;

PROCEDURE (v: View) Link*(uri-: ARRAY OF CHAR; VAR name: ARRAY OF CHAR): BOOLEAN;
BEGIN v.SetValue("<p>No</p>"); RETURN FALSE
END Link;

BEGIN
  NEW(v); FlHelp.OpenHelpView(v, 0, 0, 100, 100, "");
  v.SetValue('<img src="a.png">')
END HaltHelpImage.
