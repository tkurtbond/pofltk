MODULE Navigation; (* FLTK's test/navigation.cxx in Oberon-2 *)

(* A window filled with inputs of random sizes on a grid, none
   overlapping, put in the window in reading order, to try the keyboard's
   navigation among them; the light button turns arrow-key focus on and
   off. A first argument, a number, seeds the random numbers.

   FLTK's program takes its random numbers from C's rand(), seeded with
   srand(atoi(argv[1])); so does this port, so that it lays out the same
   inputs from the same seed on the same system. *)

IMPORT SYSTEM, Args, Fl, FlButtons, FlInputs;

CONST
  Width = 600; Height = 300; Grid = 25;

VAR
  window: Fl.Window;
  arrowfocus: FlButtons.LightButton;
  input: FlInputs.Input;
  o: Fl.Widget;
  s: ARRAY 1024 OF CHAR;
  i, j, n, x, y, w, h: INTEGER;

PROCEDURE ["C", "rand"] Rand(): SYSTEM.INT32;
PROCEDURE ["C", "srand"] SRand(seed: SYSTEM.INT32);
PROCEDURE ["C", "atoi"] Atoi(s: ARRAY OF CHAR): SYSTEM.INT32;

(* s with each "|" a line feed *)
PROCEDURE Lines(VAR s: ARRAY OF CHAR);
VAR i: INTEGER;
BEGIN
  i := 0; WHILE s[i] # 0X DO IF s[i] = "|" THEN s[i] := 0AX END; INC(i) END
END Lines;

PROCEDURE ArrowFocusCallback(w: Fl.Widget);
BEGIN Fl.SetOption(Fl.OptionArrowFocus, w(FlButtons.LightButton).Value())
END ArrowFocusCallback;

BEGIN
  IF Args.argc > 1 THEN Args.Get(1, s); SRand(Atoi(s)) END;
  Args.Get(0, s);
  NEW(window); Fl.OpenWindow(window, Width, Height + 40, s);
  NEW(arrowfocus); FlButtons.OpenLightButton(arrowfocus, 10, Height + 10, 130, 20, " Arrow Focus");
  arrowfocus.action := ArrowFocusCallback;
  arrowfocus.SetValue(Fl.Option(Fl.OptionArrowFocus));
  s := "Control horizontal arrow key focus navigation behavior.|e.g. Fl::OPTION_ARROW_FOCUS"; Lines(s);
  arrowfocus.SetTooltip(s);
  window.End; (* don't add the inputs by themselves *)
  FOR i := 0 TO 9999 DO
    (* a random size of input *)
    x := Rand() MOD (Width DIV Grid + 1) * Grid;
    y := Rand() MOD (Height DIV Grid + 1) * Grid;
    w := Rand() MOD (Width DIV Grid + 1) * Grid;
    IF w < x THEN w := x - w; DEC(x, w) ELSE w := w - x END;
    h := Rand() MOD (Height DIV Grid + 1) * Grid;
    IF h < y THEN h := y - h; DEC(y, h) ELSE h := h - y END;
    IF (w >= Grid) & (h >= Grid) & (w >= h) THEN
      (* where to insert it, and whether it overlaps another: j is the
         index of FLTK's j, or the end *)
      j := -1; n := 0;
      LOOP
        IF n = window.Children() THEN EXIT END;
        o := window.Child(n);
        IF (x < o.X() + o.W()) & (x + w > o.X()) & (y < o.Y() + o.H()) & (y + h > o.Y()) THEN EXIT END;
        IF (j < 0) & ((y < o.Y()) OR (y = o.Y()) & (x < o.X())) THEN j := n END;
        INC(n)
      END;
      IF n = window.Children() THEN
        IF j < 0 THEN j := n END;
        NEW(input); FlInputs.OpenInput(input, x, y, w, h, "");
        window.Insert(input, j)
      END
    END
  END;
  window.ShowArgs;
  Fl.Run
END Navigation.
