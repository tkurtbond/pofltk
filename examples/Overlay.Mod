MODULE Overlay; (* FLTK's test/overlay.cxx: a red box in a window's overlay, resized by four buttons *)

(* A color number on the command line is used for the box. X11 and
   Wayland have no true overlay, so FLTK redraws the window under it. *)

IMPORT Args, Fl, FlButtons, FlDraw;

TYPE
  Overlaid = POINTER TO RECORD (Fl.OverlayWindowDesc) END;
  Action = PROCEDURE (w: Fl.Widget);

VAR
  ovl: Overlaid;
  width, height, i: INTEGER;
  ok: BOOLEAN;

PROCEDURE (o: Overlaid) DrawOverlay*;
BEGIN
  FlDraw.SetColor(Fl.Red);
  FlDraw.Rect((o.W() - width) DIV 2, (o.H() - height) DIV 2, width, height)
END DrawOverlay;

PROCEDURE Wider(w: Fl.Widget);
BEGIN INC(width, 20); ovl.RedrawOverlay
END Wider;

PROCEDURE Narrower(w: Fl.Widget);
BEGIN DEC(width, 20); ovl.RedrawOverlay
END Narrower;

PROCEDURE Taller(w: Fl.Widget);
BEGIN INC(height, 20); ovl.RedrawOverlay
END Taller;

PROCEDURE Shorter(w: Fl.Widget);
BEGIN DEC(height, 20); ovl.RedrawOverlay
END Shorter;

(* A number greater than 0 is the color to use for red. *)
PROCEDURE Arg(i: INTEGER): INTEGER;
  VAR s: ARRAY 16 OF CHAR; n, j, r, g, b: INTEGER;
BEGIN
  Args.Get(i, s); n := 0; j := 0;
  WHILE (s[j] >= "0") & (s[j] <= "9") DO n := n * 10 + ORD(s[j]) - ORD("0"); INC(j) END;
  IF n <= 0 THEN RETURN 0 END;
  Fl.GetRGB(n, r, g, b); Fl.SetIndexColor(Fl.Red, Fl.RGB(r, g, b));
  RETURN 1
END Arg;

(* "?" in label is a new line. *)
PROCEDURE Add(x, y: INTEGER; label: ARRAY OF CHAR; key: CHAR; action: Action);
  VAR b: FlButtons.Button; i: INTEGER;
BEGIN
  i := 0; WHILE label[i] # 0X DO IF label[i] = "?" THEN label[i] := 0AX END; INC(i) END;
  NEW(b); FlButtons.OpenButton(b, x, y, 100, 100, label);
  b.action := action; b.SetShortcut(ORD(key), {})
END Add;

BEGIN
  width := 10; height := 10;
  ok := Fl.ParseArgs(Arg, i);
  NEW(ovl); Fl.OpenOverlayWindow(ovl, 400, 400, "overlay");
  Add(50, 50, "wider?(a)", "a", Wider);
  Add(250, 50, "narrower?(b)", "b", Narrower);
  Add(50, 250, "taller?(c)", "c", Taller);
  Add(250, 250, "shorter?(d)", "d", Shorter);
  ovl.SetResizable(ovl);
  ovl.End;
  ovl.ShowArgs;
  ovl.RedrawOverlay;
  Fl.Run
END Overlay.
