MODULE Symbols; (* FLTK's test/symbols.cxx: every symbol a label can show, turned and sized by sliders *)

IMPORT Fl, FlValuators, Strings;

CONST W = 70; H = 70; rows = 6; cols = 7;

TYPE
  (* A box showing a symbol, as itself or, with no box, as text. *)
  Cell = POINTER TO RECORD (Fl.BoxDesc)
    symbol: ARRAY 20 OF CHAR
  END;

VAR
  win: Fl.DoubleWindow;
  orientation, size: FlValuators.ValueSlider;
  n: INTEGER;

(* A symbol's name in a label: "@", or "@@" for its text, then the size
   and the orientation, and then the symbol. *)
PROCEDURE Label(start, symbol: ARRAY OF CHAR; val, sze: INTEGER; VAR s: ARRAY OF CHAR);
  VAR d: ARRAY 2 OF CHAR;
BEGIN
  COPY(start, s);
  d[1] := 0X;
  IF sze > 0 THEN Strings.Append("+", s) ELSIF sze < 0 THEN Strings.Append("-", s) END;
  IF sze # 0 THEN d[0] := CHR(ORD("0") + ABS(sze)); Strings.Append(d, s) END;
  IF val # 0 THEN d[0] := CHR(ORD("0") + val); Strings.Append(d, s) END;
  Strings.Append(symbol, s)
END Label;

PROCEDURE SliderCB(w: Fl.Widget);
  VAR i, val, sze: INTEGER; c: Fl.Widget; s: ARRAY 40 OF CHAR;
BEGIN
  val := SHORT(ENTIER(orientation.Value()));
  sze := SHORT(ENTIER(size.Value()));
  FOR i := 0 TO win.Children() - 1 DO
    c := win.Child(i);
    IF c IS Cell THEN
      IF c.BoxType() = Fl.NoBox THEN Label("@@", c(Cell).symbol, val, sze, s)
      ELSE Label("@", c(Cell).symbol, val, sze, s)
      END;
      c.SetLabel(s)
    END
  END;
  win.Redraw
END SliderCB;

PROCEDURE OpenCell(x, y: INTEGER; symbol: ARRAY OF CHAR; start: ARRAY OF CHAR; box: INTEGER): Cell;
  VAR c: Cell; s: ARRAY 40 OF CHAR;
BEGIN
  Label(start, symbol, 0, 0, s);
  NEW(c); Fl.OpenBox(c, x, y, W - 20, H - 20, s);
  c.SetBoxType(box);
  COPY(symbol, c.symbol);
  RETURN c
END OpenCell;

PROCEDURE Bt(symbol: ARRAY OF CHAR);
  VAR x, y: INTEGER; c: Cell;
BEGIN
  x := n MOD cols * W + 10; y := n DIV cols * H + 10;
  INC(n);
  c := OpenCell(x, y, symbol, "@@", Fl.NoBox);
  c.SetAlign(Fl.AlignBottom);
  c.SetLabelSize(11);
  c := OpenCell(x, y, symbol, "@", Fl.UpBox);
  c.SetLabelColor(Fl.Dark3)
END Bt;

PROCEDURE OpenSlider(s: FlValuators.ValueSlider; x: INTEGER; label: ARRAY OF CHAR; min, max: INTEGER);
BEGIN
  FlValuators.OpenHorValueSlider(s, x, win.H() - 40, 206, 16, label);
  s.SetBounds(min, max);
  s.SetValue(0);
  s.SetStep(1);
  s.action := SliderCB
END OpenSlider;

BEGIN
  NEW(win); Fl.OpenDoubleWindow(win, cols * W, rows * H + 60, "");
  n := 0;
  Bt("->");
  Bt(">");
  Bt(">>");
  Bt(">|");
  Bt(">[]");
  Bt("|>");
  Bt("<-");
  Bt("<");
  Bt("<<");
  Bt("|<");
  Bt("[]<");
  Bt("<|");
  Bt("<->");
  Bt("-->");
  Bt("+");
  Bt("->|");
  Bt("||");
  Bt("arrow");
  Bt("returnarrow");
  Bt("square");
  Bt("circle");
  Bt("line");
  Bt("menu");
  Bt("UpArrow");
  Bt("DnArrow");
  Bt("search");
  Bt("FLTK");
  Bt("filenew");
  Bt("fileopen");
  Bt("filesave");
  Bt("filesaveas");
  Bt("fileprint");
  Bt("refresh");
  Bt("reload");
  Bt("undo");
  Bt("redo");
  Bt("import");
  Bt("export");

  NEW(orientation); OpenSlider(orientation, 25, "Orientation", 0, 9);
  NEW(size); OpenSlider(size, 260, "Size", -3, 9);

  win.End;
  win.SetResizable(win);
  win.ShowArgs;
  Fl.Run
END Symbols.
