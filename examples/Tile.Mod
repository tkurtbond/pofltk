MODULE Tile; (* FLTK's test/tile.cxx in Oberon-2 *)

(* A tile of boxes and a child window: drag the borders between them
   to resize them, each no smaller than 30 by 30. Box 0 is the tile's
   resizable, so it takes up what the window grows. *)

IMPORT Fl, FlLayout;

VAR
  window, w1: Fl.DoubleWindow;
  tile: FlLayout.Tile;
  box0, box1: Fl.Box;
  label: ARRAY 64 OF CHAR;

(* s with each "|" a line feed *)
PROCEDURE Lines(VAR s: ARRAY OF CHAR);
VAR i: INTEGER;
BEGIN
  i := 0; WHILE s[i] # 0X DO IF s[i] = "|" THEN s[i] := 0AX END; INC(i) END
END Lines;

PROCEDURE Box(VAR b: Fl.Box; x, y, w, h: INTEGER; label-: ARRAY OF CHAR; color: INTEGER);
BEGIN
  NEW(b); Fl.OpenBox(b, x, y, w, h, label);
  b.SetBoxType(Fl.DownBox);
  b.SetColor(color);
  b.SetLabelSize(36);
  b.SetAlign(Fl.AlignClip)
END Box;

PROCEDURE Boxes;
VAR b: Fl.Box;
BEGIN
  Box(b, 0, 150, 70, 150, "2a", 12);
  Box(b, 70, 150, 80, 150, "2b", 13);
  Box(b, 150, 150, 150, 70, "3a", 12);
  Box(b, 150, 150 + 70, 150, 80, "3b", 13)
END Boxes;

BEGIN
  NEW(window); Fl.OpenDoubleWindow(window, 300, 300, "");
  window.SetBoxType(Fl.NoBox);
  window.SetResizable(window);

  NEW(tile); FlLayout.OpenTile(tile, 0, 0, 300, 300, "");
  tile.InitSizeRange(30, 30); (* all children's size shall be at least 30x30 *)

  Box(box0, 0, 0, 150, 150, "0", 9);
  tile.SetResizable(box0);

  NEW(w1); Fl.OpenDoubleWindowAt(w1, 150, 0, 150, 150, "1");
  w1.SetBoxType(Fl.NoBox);
  label := "1|This is a child window"; Lines(label);
  NEW(box1); Fl.OpenBox(box1, 0, 0, 150, 150, label);
  box1.SetBoxType(Fl.DownBox);
  box1.SetColor(19);
  box1.SetLabelSize(18);
  box1.SetAlign(Fl.AlignClip + Fl.AlignInside + Fl.AlignWrap);
  w1.SetResizable(box1);
  w1.End;

  Boxes;
  tile.End;
  window.End;

  w1.Show;
  window.SizeRange(90, 90, 0, 0);
  window.ShowArgs;
  Fl.Run
END Tile.
