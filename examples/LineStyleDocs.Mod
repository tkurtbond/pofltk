MODULE LineStyleDocs; (* FLTK's test/line_style_docs.cxx in Oberon-2 *)

(* The line styles, caps and joins, each in a box of a grid, drawn thin
   and thick: the picture in FLTK's documentation of fl_line_style. The
   thick lines grow with the window. *)

IMPORT Fl, FlDraw, FlLayout;

CONST
  sep = 22;  (* the separation between items *)

TYPE
  StyleBox = POINTER TO RECORD (Fl.BoxDesc) style: INTEGER END;

VAR
  width: ARRAY 2 OF INTEGER;  (* line widths: thin, and thick for the size *)
  textWidth: INTEGER;
  win: Fl.DoubleWindow;
  grid: FlLayout.Grid;

PROCEDURE StyleName(style: INTEGER; VAR s: ARRAY OF CHAR);
BEGIN
  CASE style OF
    FlDraw.Solid: COPY("FL_SOLID", s)
  | FlDraw.Dash: COPY("FL_DASH", s)
  | FlDraw.Dot: COPY("FL_DOT", s)
  | FlDraw.DashDot: COPY("FL_DASHDOT", s)
  | FlDraw.DashDotDot: COPY("FL_DASHDOTDOT", s)
  | FlDraw.CapFlat: COPY("FL_CAP_FLAT", s)
  | FlDraw.CapRound: COPY("FL_CAP_ROUND", s)
  | FlDraw.CapSquare: COPY("FL_CAP_SQUARE", s)
  | FlDraw.JoinMiter: COPY("FL_JOIN_MITER", s)
  | FlDraw.JoinRound: COPY("FL_JOIN_ROUND", s)
  | FlDraw.JoinBevel: COPY("FL_JOIN_BEVEL", s)
  ELSE COPY("(?)", s)
  END
END StyleName;

PROCEDURE (b: StyleBox) Draw*;
  VAR name: ARRAY 16 OF CHAR; h, x, y, dx, dy, i: INTEGER;
BEGIN
  b.DrawBox;
  IF b.style >= 0 THEN  (* not an empty box *)
    (* the font, and the widest text *)
    FlDraw.SetFont(Fl.Helvetica, 12);
    FlDraw.SetColor(Fl.Black);
    IF textWidth = 0 THEN FlDraw.Measure("FL_DASHDOTDOT", textWidth, h) END;

    (* the text *)
    x := b.X() + sep DIV 2;
    StyleName(b.style, name);
    FlDraw.Text(name, x, b.Y() + b.H() DIV 2 + FlDraw.Height() DIV 2 - 2);

    (* the lines' sizes and widths, from the box's *)
    INC(x, textWidth + sep DIV 2);
    dx := (b.W() - textWidth - 5 * sep) DIV 4;  (* horizontal distance *)
    dy := b.H() - sep;
    y := b.Y() + sep DIV 2;
    IF (dx >= 80) OR (dy >= 80) THEN width[1] := 9
    ELSIF (dx >= 60) OR (dy >= 60) THEN width[1] := 8
    ELSIF (dx >= 40) OR (dy >= 40) THEN width[1] := 7
    ELSE width[1] := 5
    END;

    (* the lines, thin and thick *)
    FOR i := 0 TO 1 DO
      FlDraw.LineStyle(b.style, width[i]);
      FlDraw.Line3(x, y, x + dx, y, x + dx, y + dy);  (* a corner *)
      INC(x, dx + sep);
      FlDraw.Line3(x, y, x + dx, y, x, y + dy);  (* a Z's top and slant *)
      INC(x, dx + sep)
    END;

    (* the default line settings again *)
    FlDraw.LineStyle(FlDraw.Solid, 0)
  END
END Draw;

PROCEDURE Style(s, row, col: INTEGER);
  VAR b: StyleBox;
BEGIN
  NEW(b); Fl.OpenBox(b, 0, 0, 0, 0, "");
  b.SetBoxType(Fl.FlatBox);
  b.SetColor(Fl.White);
  b.style := s;
  grid.Place(b, row, col, FlLayout.GridFill)
END Style;

BEGIN
  width[0] := 1; width[1] := 4;
  NEW(win); Fl.OpenDoubleWindow(win, 740, 400, "fl_line_style()");
  win.SetColor(Fl.White);

  (* a grid with a white 4 pixel border and a light gray background, so
     margins and gaps show through *)
  NEW(grid); FlLayout.OpenGrid(grid, 4, 4, win.W() - 8, win.H() - 8, "");
  grid.SetBoxType(Fl.FlatBox);
  grid.SetColor(Fl.RGB(0D0H, 0D0H, 0D0H));
  grid.SetLayout(6, 2); grid.SetMargins(4, 4, 4, 4); grid.SetGap(4, 4);

  (* the first column *)
  Style(FlDraw.Solid, 0, 0);
  Style(FlDraw.Dash, 1, 0);
  Style(FlDraw.Dot, 2, 0);
  Style(FlDraw.DashDot, 3, 0);
  Style(FlDraw.DashDotDot, 4, 0);
  Style(-1, 5, 0);  (* an empty box *)

  (* the second column *)
  Style(FlDraw.CapFlat, 0, 1);
  Style(FlDraw.CapRound, 1, 1);
  Style(FlDraw.CapSquare, 2, 1);
  Style(FlDraw.JoinMiter, 3, 1);
  Style(FlDraw.JoinRound, 4, 1);
  Style(FlDraw.JoinBevel, 5, 1);

  grid.End;
  win.End;
  win.SetResizable(win);
  win.SizeRange(660, 340, 0, 0);  (* not too small *)
  win.ShowArgs;
  Fl.Run
END LineStyleDocs.
