MODULE Pack; (* FLTK's test/pack.cxx in Oberon-2 *)

(* A pack of 24 buttons in a scroll; the light buttons lay it out
   horizontally or vertically, and the slider sets its spacing. FLTK's
   program can be built to use an Fl_Flex, or no scroll; this is its
   default build, a pack in a scroll. *)

IMPORT Fl, FlButtons, FlLayout, FlValuators;

TYPE
  KindButton = POINTER TO KindButtonDesc;
  KindButtonDesc = RECORD (FlButtons.RadioLightButtonDesc) kind: INTEGER END;

VAR
  w: Fl.DoubleWindow;
  scroll: FlLayout.Scroll;
  pack: FlLayout.Pack;
  b: FlButtons.Button;
  horizontal, vertical: KindButton;
  spacing: FlValuators.ValueSlider;
  i, xx: INTEGER;
  ltxt: ARRAY 8 OF CHAR;

PROCEDURE KindCallback(o: Fl.Widget);
VAR i: INTEGER; p: Fl.Group; c: Fl.Widget;
BEGIN
  FOR i := 0 TO pack.Children() - 1 DO c := pack.Child(i); c.Resize(0, 0, 25, 25) END;
  pack.SetKind(o(KindButton).kind);
  pack.Resize(scroll.X(), scroll.Y(), scroll.W(), scroll.H());
  p := pack.Parent(); p.Redraw;
  pack.Redraw
END KindCallback;

PROCEDURE SpacingCallback(o: Fl.Widget);
VAR p: Fl.Group;
BEGIN
  pack.SetSpacing(SHORT(ENTIER(o(FlValuators.ValueSlider).Value())));
  p := pack.Parent(); p.Redraw
END SpacingCallback;

PROCEDURE Kind(VAR b: KindButton; x: INTEGER; label-: ARRAY OF CHAR; kind: INTEGER);
BEGIN
  NEW(b); FlButtons.OpenRadioLightButton(b, x, 305, 165, 25, label);
  b.kind := kind; b.action := KindCallback
END Kind;

BEGIN
  NEW(w); Fl.OpenDoubleWindow(w, 360, 370, "");
  NEW(scroll); FlLayout.OpenScroll(scroll, 10, 10, 340, 285, "");

  NEW(pack); FlLayout.OpenPack(pack, 10, 10, 340, 285, "");
  pack.SetBoxType(Fl.DownFrame);
  xx := 35;
  FOR i := 0 TO 23 DO
    ltxt := "b";
    IF i + 1 >= 10 THEN ltxt[1] := CHR(ORD("0") + (i + 1) DIV 10); ltxt[2] := CHR(ORD("0") + (i + 1) MOD 10); ltxt[3] := 0X
    ELSE ltxt[1] := CHR(ORD("0") + i + 1); ltxt[2] := 0X
    END;
    NEW(b); FlButtons.OpenButton(b, xx, xx, 25, 25, ltxt);
    INC(xx, 10)
  END;
  pack.End;
  w.SetResizable(pack);
  scroll.End;

  Kind(horizontal, 10, "HORIZONTAL", FlLayout.PackHorizontal);
  Kind(vertical, 185, "VERTICAL", FlLayout.PackVertical);
  vertical.SetValue(TRUE);

  NEW(spacing); FlValuators.OpenHorValueSlider(spacing, 100, 335, 250, 25, "Spacing: ");
  spacing.SetAlign(Fl.AlignLeft);
  spacing.SetBounds(0, 30);
  spacing.SetStep(1);
  spacing.action := SpacingCallback;

  w.End;
  w.SizeRange(300, 300, 0, 0);
  w.ShowArgs;
  Fl.Run
END Pack.
