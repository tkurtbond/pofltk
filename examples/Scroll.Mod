MODULE Scroll; (* FLTK's test/scroll.cxx in Oberon-2 *)

(* A scroll of 80 buttons and a drawing, bigger than its window: the
   light button gives the scroll a frame, and the choices change which
   scrollbars it shows and where. *)

IMPORT MathL, Fl, FlButtons, FlDraw, FlLayout, FlMenus;

TYPE
  Drawing = POINTER TO RECORD (Fl.BoxDesc) END;

VAR
  window: Fl.Window;
  thescroll: FlLayout.Scroll;
  drawing: Drawing;
  box: Fl.Box;
  but1: FlButtons.LightButton;
  choice, achoice: FlMenus.Choice;
  b: FlButtons.Button;
  label: ARRAY 20 OF CHAR;
  n, x, y, i: INTEGER;

(* A star of lines between 20 points on an ellipse filling the widget. *)
PROCEDURE (d: Drawing) Draw*;
VAR i, j: INTEGER;
BEGIN
  d.DrawBox;
  FlDraw.PushMatrix;
  FlDraw.Translate(d.X() + d.W() DIV 2, d.Y() + d.H() DIV 2);
  FlDraw.Scale(d.W() DIV 2, d.H() DIV 2);
  FlDraw.SetColor(Fl.Black);
  FOR i := 0 TO 19 DO
    FOR j := i + 1 TO 19 DO
      FlDraw.BeginLine;
      FlDraw.Vertex(MathL.cos(MathL.pi * i / 10 + 0.1D0), MathL.sin(MathL.pi * i / 10 + 0.1D0));
      FlDraw.Vertex(MathL.cos(MathL.pi * j / 10 + 0.1D0), MathL.sin(MathL.pi * j / 10 + 0.1D0));
      FlDraw.EndLine
    END
  END;
  FlDraw.PopMatrix
END Draw;

PROCEDURE BoxCallback(o: Fl.Widget);
BEGIN
  IF o(FlButtons.Button).Value() THEN thescroll.SetBoxType(Fl.DownFrame)
  ELSE thescroll.SetBoxType(Fl.NoBox)
  END;
  thescroll.Redraw
END BoxCallback;

(* The items are the kinds, in order. *)
PROCEDURE TypeCallback(o: Fl.Widget);
BEGIN
  thescroll.SetKind(o(FlMenus.Choice).Value());
  thescroll.Redraw
END TypeCallback;

PROCEDURE AlignCallback(o: Fl.Widget);
BEGIN
  CASE o(FlMenus.Choice).Value() OF
    0: thescroll.SetScrollbarAlign(Fl.AlignLeft + Fl.AlignTop)
  | 1: thescroll.SetScrollbarAlign(Fl.AlignLeft + Fl.AlignBottom)
  | 2: thescroll.SetScrollbarAlign(Fl.AlignRight + Fl.AlignTop)
  | 3: thescroll.SetScrollbarAlign(Fl.AlignRight + Fl.AlignBottom)
  END
END AlignCallback;

(* n as text *)
PROCEDURE Num(n: INTEGER; VAR s: ARRAY OF CHAR);
VAR d: ARRAY 12 OF CHAR; i, j: INTEGER;
BEGIN
  i := 0; REPEAT d[i] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(i) UNTIL n = 0;
  j := 0; WHILE i > 0 DO DEC(i); s[j] := d[i]; INC(j) END;
  s[j] := 0X
END Num;

BEGIN
  NEW(window); Fl.OpenWindow(window, 5 * 75, 400, "");
  window.SetBoxType(Fl.NoBox);
  NEW(thescroll); FlLayout.OpenScroll(thescroll, 0, 0, 5 * 75, 300, "");
  n := 0;
  FOR y := 0 TO 15 DO
    FOR x := 0 TO 4 DO
      Num(n, label); INC(n);
      NEW(b);
      IF y >= 8 THEN FlButtons.OpenButton(b, x * 75, y * 25 + 5 * 75, 75, 25, label)
      ELSE FlButtons.OpenButton(b, x * 75, y * 25, 75, 25, label)
      END;
      b.SetColor(n);
      b.SetLabelColor(Fl.White)
    END
  END;
  NEW(drawing); Fl.OpenBox(drawing, 0, 8 * 25, 5 * 75, 5 * 75, "");
  drawing.SetAlign(Fl.AlignTop);
  drawing.SetBoxType(Fl.FlatBox);
  drawing.SetColor(Fl.White);
  thescroll.End;
  window.SetResizable(thescroll);

  NEW(box); Fl.OpenBox(box, 0, 300, 5 * 75, window.H() - 300, ""); (* gray area below the scroll *)
  box.SetBoxType(Fl.FlatBox);

  NEW(but1); FlButtons.OpenLightButton(but1, 150, 310, 200, 25, "box");
  but1.action := BoxCallback;

  NEW(choice); FlMenus.OpenChoice(choice, 150, 335, 200, 25, "type():");
  i := choice.Add("0", 0, {}, TypeCallback, {});
  i := choice.Add("HORIZONTAL", 0, {}, TypeCallback, {});
  i := choice.Add("VERTICAL", 0, {}, TypeCallback, {});
  i := choice.Add("BOTH", 0, {}, TypeCallback, {});
  i := choice.Add("HORIZONTAL_ALWAYS", 0, {}, TypeCallback, {});
  i := choice.Add("VERTICAL_ALWAYS", 0, {}, TypeCallback, {});
  i := choice.Add("BOTH_ALWAYS", 0, {}, TypeCallback, {});
  IF choice.SetValue(3) THEN END;

  NEW(achoice); FlMenus.OpenChoice(achoice, 150, 360, 200, 25, "scrollbar.align():");
  i := achoice.Add("left+top", 0, {}, AlignCallback, {});
  i := achoice.Add("left+bottom", 0, {}, AlignCallback, {});
  i := achoice.Add("right+top", 0, {}, AlignCallback, {});
  i := achoice.Add("right+bottom", 0, {}, AlignCallback, {});
  IF achoice.SetValue(3) THEN END;

  window.End;
  window.ShowArgs;
  Fl.Run
END Scroll.
