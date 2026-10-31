MODULE Fonts; (* FLTK's test/fonts.cxx: every font the system has, at its sizes; F1 opens an editor of vector fonts *)

(* FLTK's copies each font's sizes at the start. This asks for a font's
   as it is picked, as it can with no pointer of FLTK's to keep. *)

IMPORT Files, OutStr, Strings, Fl, FlBrowsers, FlButtons, FlDialogs, FlDraw, FlLayout, FlUtf8;

CONST
  maxSizes = 256;
  points = 128;  (* of a character in the editor *)

TYPE
  FontDisplay = POINTER TO RECORD (Fl.BoxDesc)
    font, size: INTEGER
  END;

  LetterBox = POINTER TO RECORD (Fl.GroupDesc) END;

  (* An editor's dot, which adds its point to the character. *)
  Dot = POINTER TO RECORD (FlButtons.ButtonDesc)
    point: CHAR
  END;

  MainWindow = POINTER TO RECORD (Fl.DoubleWindowDesc) END;

VAR
  form: MainWindow;
  tile: FlLayout.Tile;
  editor: Fl.DoubleWindow;  (* NIL until F1 *)
  letter: LetterBox;
  textobj: FontDisplay;
  fontobj, sizeobj: FlBrowsers.HoldBrowser;
  pickedSize: INTEGER;
  label: ARRAY 1000H OF CHAR;
  currentChar: INTEGER;
  vec: ARRAY 256, points + 1 OF CHAR;

PROCEDURE (d: FontDisplay) Draw*;
BEGIN
  d.DrawBox;
  FlDraw.SetFont(d.font, d.size);
  FlDraw.SetColor(Fl.Black);
  FlDraw.TextAligned(label, d.X() + 3, d.Y() + 3, d.W() - 6, d.H() - 6, d.Align())
END Draw;

(* Adds a size to the sizes' list, in bold if the font has it. *)
PROCEDURE AddSize(size: INTEGER; has: BOOLEAN);
  VAR buf, n: ARRAY 20 OF CHAR;
BEGIN
  IF has THEN buf := "@b" ELSE buf := "" END;
  OutStr.Int(size, 0, n);
  Strings.Append(n, buf);
  sizeobj.Add(buf)
END AddSize;

PROCEDURE FontCB(w: Fl.Widget);
  VAR
    fn, n, i, j, picked: INTEGER;
    s: ARRAY maxSizes OF INTEGER;
    ok: BOOLEAN;
BEGIN
  fn := fontobj.Value();
  IF fn # 0 THEN
    DEC(fn);
    textobj.font := fn;
    sizeobj.Clear;
    n := Fl.GetFontSizes(fn, s);
    IF n > maxSizes THEN n := maxSizes END;
    IF n = 0 THEN
      (* no sizes *)
    ELSIF s[0] = 0 THEN  (* many sizes *)
      j := 1; i := 1;
      WHILE (i < 64) OR (i < s[n - 1]) DO
        IF (j < n) & (i = s[j]) THEN AddSize(i, TRUE); INC(j) ELSE AddSize(i, FALSE) END;
        INC(i)
      END;
      IF pickedSize <= sizeobj.Count() THEN ok := sizeobj.Select(pickedSize, TRUE) END
    ELSE  (* some sizes *)
      picked := 0;
      FOR i := 0 TO n - 1 DO
        IF s[i] <= pickedSize THEN picked := i END;
        AddSize(s[i], TRUE)
      END;
      ok := sizeobj.Select(picked + 1, TRUE)
    END;
    textobj.Redraw
  END
END FontCB;

PROCEDURE SizeCB(w: Fl.Widget);
  VAR
    i, k, n: INTEGER;
    c: ARRAY 20 OF CHAR;
BEGIN
  i := sizeobj.Value();
  IF i # 0 THEN
    sizeobj.GetText(i, c);
    k := 0;
    WHILE (c[k] < "0") OR (c[k] > "9") DO INC(k) END;
    n := 0;
    WHILE (c[k] >= "0") & (c[k] <= "9") DO n := n * 10 + ORD(c[k]) - ORD("0"); INC(k) END;
    pickedSize := n;
    textobj.size := n;
    textobj.Redraw
  END
END SizeCB;

PROCEDURE (b: LetterBox) Draw*;
  VAR
    rendering: BOOLEAN;
    i, cmd: INTEGER;
    s: ARRAY 8 OF CHAR;
BEGIN
  b.DrawBox;
  FlDraw.PushClip(b.X(), b.Y(), b.W(), b.H());
  b.GetLabel(s);
  FlDraw.SetFont(b.LabelFont(), b.LabelSize());
  FlDraw.SetColor(b.LabelColor());
  FlDraw.TextAligned(s, b.X(), b.Y() - 5, b.W(), b.H() - 16, Fl.AlignCenter);

  FlDraw.SetColor(Fl.Blue);
  FlDraw.LineStyle(FlDraw.Solid + FlDraw.CapRound + FlDraw.JoinRound, 10);
  rendering := FALSE;
  i := 0;
  cmd := ORD(vec[currentChar, 0]);
  WHILE cmd # 0 DO
    IF cmd > 63 THEN
      IF (cmd = 64) & rendering THEN FlDraw.EndLine; rendering := FALSE END
    ELSE
      IF ~rendering THEN FlDraw.BeginLine; rendering := TRUE END;
      FlDraw.Vertex((cmd DIV 8) * 16 + 18, (cmd MOD 8) * 32 + 26)
    END;
    INC(i);
    cmd := ORD(vec[currentChar, i])
  END;
  IF rendering THEN FlDraw.EndLine END;
  FlDraw.LineStyle(FlDraw.Solid, 1);

  FOR i := 0 TO b.Children() - 1 DO b.DrawChild(b.Child(i)) END;
  FlDraw.PopClip
END Draw;

(* Adds a point to the current character, while it has room. *)
PROCEDURE AddCmd(cmd: CHAR);
  VAR i: INTEGER;
BEGIN
  i := 0;
  WHILE (i < points) & (vec[currentChar, i] # 0X) DO INC(i) END;
  IF i < points THEN vec[currentChar, i] := cmd END;
  letter.Redraw
END AddCmd;

PROCEDURE AddPointCB(w: Fl.Widget);
BEGIN AddCmd(w(Dot).point)
END AddPointCB;

PROCEDURE AddGapCB(w: Fl.Widget);
BEGIN AddCmd(CHR(64))
END AddGapCB;

PROCEDURE ClearCB(w: Fl.Widget);
  VAR i: INTEGER;
BEGIN
  FOR i := 0 TO points DO vec[currentChar, i] := 0X END;
  letter.Redraw
END ClearCB;

PROCEDURE ShowChar;
  VAR b: ARRAY 2 OF CHAR;
BEGIN
  b[0] := CHR(currentChar); b[1] := 0X;
  letter.SetLabel(b);
  letter.Redraw
END ShowChar;

PROCEDURE PrevCB(w: Fl.Widget);
BEGIN currentChar := (currentChar - 1) MOD 256; ShowChar
END PrevCB;

PROCEDURE NextCB(w: Fl.Widget);
BEGIN currentChar := (currentChar + 1) MOD 256; ShowChar
END NextCB;

PROCEDURE BackCB(w: Fl.Widget);
  VAR i: INTEGER;
BEGIN
  IF vec[currentChar, 0] # 0X THEN
    i := 0;
    WHILE vec[currentChar, i] # 0X DO INC(i) END;
    vec[currentChar, i - 1] := 0X;
    letter.Redraw
  END
END BackCB;

PROCEDURE Put(VAR r: Files.Rider; s: ARRAY OF CHAR);
  VAR i: INTEGER;
BEGIN
  i := 0;
  WHILE s[i] # 0X DO Files.Write(r, s[i]); INC(i) END
END Put;

(* c as %02o or %02X, in base 8 or 16. *)
PROCEDURE PutDigits(VAR r: Files.Rider; c, base: INTEGER);
  CONST digits = "0123456789ABCDEF";
  VAR high: INTEGER; d: ARRAY 17 OF CHAR;
BEGIN
  d := digits;
  high := c DIV base;
  IF high >= base THEN Files.Write(r, d[high DIV base]); high := high MOD base END;
  Files.Write(r, d[high]);
  Files.Write(r, d[c MOD base])
END PutDigits;

PROCEDURE SaveCB(w: Fl.Widget);
  VAR
    filename: ARRAY 1024 OF CHAR;
    f: Files.File;
    r: Files.Rider;
    i, k: INTEGER;
BEGIN
  filename := "";
  IF FlDialogs.ChooseFile("Save font as:", "", filename, FALSE) THEN
    f := Files.New(filename);
    IF f = NIL THEN
      FlDialogs.Alert("can't open file for writing")
    ELSE
      Files.Set(r, f, 0);
      Put(r, 0AX); Put(r, "static const char *font_data[128] = {"); Put(r, 0AX); Put(r, "  ");
      FOR i := 0 TO 127 DO
        Put(r, "/*");
        IF (i >= 32) & (i < 127) THEN Files.Write(r, CHR(i)) ELSE PutDigits(r, i, 16) END;
        Put(r, "*/");
        IF vec[i, 0] = 0X THEN
          Put(r, "0")
        ELSE
          Put(r, 22X);
          k := 0;
          WHILE vec[i, k] # 0X DO
            Put(r, "\"); PutDigits(r, ORD(vec[i, k]), 8);
            INC(k)
          END;
          Put(r, 22X)
        END;
        IF i < 127 THEN Put(r, ", ") END;
        IF i MOD 4 = 3 THEN Put(r, 0AX); Put(r, "  ") END
      END;
      Put(r, "};"); Put(r, 0AX); Put(r, 0AX);
      Files.Register(f);
      Files.Close(f)
    END
  END
END SaveCB;

PROCEDURE AddButton(x, y: INTEGER; title: ARRAY OF CHAR; action: PROCEDURE (w: Fl.Widget)): FlButtons.Button;
  VAR b: FlButtons.Button;
BEGIN
  NEW(b); FlButtons.OpenButton(b, x, y, 70, 20, title);
  b.action := action;
  RETURN b
END AddButton;

PROCEDURE CreateEditor;
  VAR
    i, j: INTEGER;
    d: Dot;
    b: FlButtons.Button;
BEGIN
  NEW(editor); Fl.OpenDoubleWindow(editor, 400, 400, "");
  NEW(letter); Fl.OpenGroup(letter, 10, 10, 128, 256, "A");
  letter.SetAlign(Fl.AlignCenter);
  letter.SetLabelSize(200);
  letter.SetLabelColor(Fl.Dark3);
  letter.SetBoxType(Fl.DownBox);
  FOR i := 0 TO 7 DO
    FOR j := 0 TO 7 DO
      NEW(d); FlButtons.OpenButton(d, i * 16 + 13, j * 32 + 21, 10, 10, "");
      d.SetBoxType(Fl.OvalBox);
      d.point := CHR(i * 8 + j);
      d.action := AddPointCB
    END
  END;
  letter.End;

  b := AddButton(10, 290, "Gap", AddGapCB);
  b := AddButton(90, 290, "Clear", ClearCB);
  b := AddButton(10, 315, "<-", PrevCB);
  b.SetShortcut(Fl.KeyLeft, {});
  b := AddButton(90, 315, "->", NextCB);
  b.SetShortcut(Fl.KeyRight, {});
  b := AddButton(10, 340, "Back", BackCB);
  b := AddButton(90, 340, "Save", SaveCB);
  b.SetShortcut(ORD("s"), Fl.CommandModifier());
  editor.End
END CreateEditor;

PROCEDURE (win: MainWindow) Handle*(e: INTEGER): BOOLEAN;
BEGIN
  IF (e = Fl.EvKeyDown) & (Fl.EventKey() = Fl.KeyF + 1) THEN
    IF editor = NIL THEN CreateEditor END;
    editor.Show;
    RETURN TRUE
  END;
  RETURN win.Handle^(e)
END Handle;

(* The sample text: ASCII, then a spread of what follows it. *)
PROCEDURE MakeLabel;
  VAR
    n, i, c, k, bytes: INTEGER;
    enc: ARRAY 8 OF CHAR;
BEGIN
  label := "Hello, world!";
  i := 0; WHILE label[i] # 0X DO INC(i) END;
  label[i] := 0AX; INC(i);
  FOR c := ORD(" ") + 1 TO 126 DO
    IF c MOD 32 = 0 THEN label[i] := 0AX; INC(i) END;
    IF c = ORD("@") THEN label[i] := "@"; INC(i) END;
    label[i] := CHR(c); INC(i)
  END;
  label[i] := 0AX; INC(i);
  n := 0; c := 0A1H;
  WHILE c < 600H DO
    INC(n);
    IF n MOD 32 = 0 THEN label[i] := 0AX; INC(i) END;
    bytes := FlUtf8.Encode(c, enc);
    FOR k := 0 TO bytes - 1 DO label[i] := enc[k]; INC(i) END;
    INC(c, 9)
  END;
  label[i] := 0X
END MakeLabel;

PROCEDURE CreateTheForms;
  VAR textgroup, fontgroup: Fl.Group;
BEGIN
  MakeLabel;

  NEW(form); Fl.OpenDoubleWindow(form, 550, 370, "");

  NEW(tile); FlLayout.OpenTile(tile, 0, 0, 550, 370, "");

  NEW(textgroup); Fl.OpenGroup(textgroup, 0, 0, 550, 185, "");
  textgroup.SetBoxType(Fl.FlatBox);
  NEW(textobj); Fl.OpenBox(textobj, 10, 10, 530, 170, "");
  textobj.SetBoxType(Fl.EngravedBox);
  textobj.font := 0; textobj.size := 14;
  textobj.SetAlign(Fl.AlignTop + Fl.AlignLeft + Fl.AlignInside + Fl.AlignClip);
  textobj.SetColor(9);
  textobj.SetSelectionColor(47);
  textgroup.SetResizable(textobj);
  textgroup.End;

  NEW(fontgroup); Fl.OpenGroup(fontgroup, 0, 185, 550, 185, "");
  fontgroup.SetBoxType(Fl.FlatBox);
  NEW(fontobj); FlBrowsers.OpenHoldBrowser(fontobj, 10, 190, 390, 170, "");
  fontobj.SetBoxType(Fl.EngravedBox);
  fontobj.SetColor(53);
  fontobj.SetSelectionColor(3);
  fontobj.action := FontCB;
  NEW(sizeobj); FlBrowsers.OpenHoldBrowser(sizeobj, 410, 190, 130, 170, "");
  sizeobj.SetBoxType(Fl.EngravedBox);
  sizeobj.SetColor(53);
  sizeobj.SetSelectionColor(3);
  sizeobj.action := SizeCB;
  fontgroup.SetResizable(fontobj);
  fontgroup.End;

  tile.End;

  form.SetResizable(tile);
  form.End
END CreateTheForms;

(* Lists the fonts; "@." keeps a name's own "@" from being formatting. *)
PROCEDURE ListFonts;
  VAR
    i, k, t: INTEGER;
    name, buffer: ARRAY 256 OF CHAR;
    ok: BOOLEAN;
BEGIN
  k := Fl.SetFonts();
  FOR i := 0 TO k - 1 DO
    Fl.GetFontName(i, name, t);
    IF t # 0 THEN
      buffer := "";
      IF t MOD 2 = Fl.Bold THEN Strings.Append("@b", buffer) END;
      IF t >= Fl.Italic THEN Strings.Append("@i", buffer) END;
      Strings.Append("@.", buffer);
      Strings.Append(name, buffer);
      fontobj.Add(buffer)
    ELSE
      fontobj.Add(name)
    END
  END;
  ok := fontobj.Select(1, TRUE);
  FontCB(fontobj)
END ListFonts;

VAR
  args: INTEGER;
  done: BOOLEAN;

BEGIN
  pickedSize := 14;
  currentChar := ORD("A");
  args := 1; done := Fl.ParseArgs(NIL, args);
  Fl.GetSystemColors;
  CreateTheForms;
  ListFonts;
  form.ShowArgs;
  Fl.Run
END Fonts.
