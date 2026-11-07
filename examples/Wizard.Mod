MODULE Wizard; (* FLTK's test/wizard.cxx in Oberon-2 *)

(* A wizard of three panels, which the buttons step through, wrapping
   around at either end. *)

IMPORT Fl, FlButtons, FlLayout;

VAR
  window: Fl.Window;
  wizard: FlLayout.Wizard;
  p1, p2, p3: Fl.Group;
  buttons: Fl.Group;
  prev, next: FlButtons.Button;

PROCEDURE Panel(VAR p: Fl.Group; x, y, w, h, c: INTEGER; t-: ARRAY OF CHAR);
BEGIN
  NEW(p); Fl.OpenGroup(p, x, y, w, h, t);
  p.SetAlign(Fl.AlignInside + Fl.AlignCenter);
  p.SetBoxType(Fl.EngravedBox);
  p.SetLabelColor(c);
  p.SetLabelSize(20);
  p.End
END Panel;

PROCEDURE NextPanel(w: Fl.Widget);
BEGIN
  IF wizard.Value() = p3 THEN wizard.SetValue(p1) ELSE wizard.Next END
END NextPanel;

PROCEDURE PrevPanel(w: Fl.Widget);
BEGIN
  IF wizard.Value() = p1 THEN wizard.SetValue(p3) ELSE wizard.Prev END
END PrevPanel;

BEGIN
  NEW(window); Fl.OpenWindow(window, 300, 165, "Fl_Wizard test");
  NEW(wizard); FlLayout.OpenWizard(wizard, 5, 5, 290, 100, "");
  Panel(p1, 5, 5, 290, 100, Fl.Red, "Panel 1");
  Panel(p2, 5, 5, 290, 100, Fl.Magenta, "Panel 2");
  Panel(p3, 5, 5, 290, 100, Fl.Blue, "Panel 3");
  wizard.SetValue(p1);
  wizard.End;
  NEW(buttons); Fl.OpenGroup(buttons, 5, 110, 290, 50, "");
  buttons.SetBoxType(Fl.EngravedBox);
  NEW(prev); FlButtons.OpenButton(prev, 15, 120, 110, 30, "@< Prev Panel");
  prev.action := PrevPanel;
  prev.SetAlign(Fl.AlignInside + Fl.AlignCenter + Fl.AlignLeft);
  NEW(next); FlButtons.OpenButton(next, 175, 120, 110, 30, "Next Panel @>");
  next.SetAlign(Fl.AlignInside + Fl.AlignCenter + Fl.AlignRight);
  next.action := NextPanel;
  buttons.End;
  window.End;
  window.ShowArgs;
  Fl.Run
END Wizard.
