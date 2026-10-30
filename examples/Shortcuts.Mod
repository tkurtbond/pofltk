MODULE Shortcuts; (* Choosing a button's shortcut with a shortcut button *)

(* Click the shortcut button and press a key, and it is the other
   button's shortcut. The shortcut button takes keys until it loses the
   focus, so click the other button before trying it. *)

IMPORT Out, Fl, FlButtons;

VAR
  window: Fl.Window;
  choose: FlButtons.ShortcutButton;
  button: FlButtons.Button;
  presses: INTEGER;

PROCEDURE Chosen(w: Fl.Widget);
  VAR key: INTEGER; state: SET;
BEGIN choose.Value(key, state); button.SetShortcut(key, state)
END Chosen;

PROCEDURE Pressed(w: Fl.Widget);
BEGIN INC(presses); Out.String("pressed "); Out.Int(presses, 0); Out.Ln
END Pressed;

BEGIN
  NEW(window); Fl.OpenWindow(window, 300, 120, "Shortcuts");
  NEW(choose); FlButtons.OpenShortcutButton(choose, 110, 20, 170, 30, "shortcut:");
  choose.SetWhen(Fl.WhenChanged);
  choose.action := Chosen;
  NEW(button); FlButtons.OpenButton(button, 110, 70, 170, 30, "press me");
  button.action := Pressed;
  choose.SetValue(ORD("p"), Fl.Alt);
  button.SetShortcut(ORD("p"), Fl.Alt);
  window.End;
  window.Show;
  Fl.Run
END Shortcuts.
