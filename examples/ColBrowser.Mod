MODULE ColBrowser; (* FLTK's test/colbrowser.cxx in Oberon-2 *)

(* A browser of the colors named in a file, by default rgb.txt, X11's
   list: choosing a line shows its color and sets the sliders; moving a
   slider shows the color they make and chooses the nearest line. The
   file's name is a button, which asks for another file, whose colors
   are added to the lines, as FLTK's program does. FLTK's button keeps
   a pointer to the last name that loaded, once a name failed to, and
   shows a later one only when next redrawn; the port's shows it at
   once. *)

IMPORT Args, Err, Files, Fl, FlBrowsers, FlButtons, FlDialogs, FlValuators;

CONST
  MaxRGB = 3000;
  FreeCol4 = Fl.FreeColor + 3;
  IndianRed = 164;

TYPE
  RGBdb = RECORD r, g, b: INTEGER END;

VAR
  cl: Fl.DoubleWindow;
  rescol: Fl.Box;
  dbobj: FlButtons.Button;
  colbr: FlBrowsers.HoldBrowser;
  rs, gs, bs: FlValuators.ValueSlider;
  dbname: ARRAY 1024 OF CHAR; (* the name typed last that loaded *)
  labelIsDbname: BOOLEAN; (* whether dbobj shows dbname, as FLTK's keeps its pointer *)
  rgbdb: ARRAY MaxRGB OF RGBdb;
  name: ARRAY 1024 OF CHAR;
  help: ARRAY 4096 OF CHAR;
  i: INTEGER;

(* s with each "|" a line feed *)
PROCEDURE Lines(VAR s: ARRAY OF CHAR);
VAR i: INTEGER;
BEGIN
  i := 0; WHILE s[i] # 0X DO IF s[i] = "|" THEN s[i] := 0AX END; INC(i) END
END Lines;

(* Appends s to t. *)
PROCEDURE Cat(s-: ARRAY OF CHAR; VAR t: ARRAY OF CHAR);
VAR i, j: INTEGER;
BEGIN
  i := 0; WHILE t[i] # 0X DO INC(i) END;
  j := 0; WHILE s[j] # 0X DO t[i] := s[j]; INC(i); INC(j) END;
  t[i] := 0X
END Cat;

(* Appends n, 0 to 999, right-aligned in 3 places, to s. *)
PROCEDURE Num3(n: INTEGER; VAR s: ARRAY OF CHAR);
VAR d: ARRAY 4 OF CHAR;
BEGIN
  d[0] := CHR(ORD("0") + n DIV 100); d[1] := CHR(ORD("0") + n DIV 10 MOD 10);
  d[2] := CHR(ORD("0") + n MOD 10); d[3] := 0X;
  IF n < 100 THEN d[0] := " " END;
  IF n < 10 THEN d[1] := " " END;
  Cat(d, s)
END Num3;

PROCEDURE SetEntry(i: INTEGER);
BEGIN
  Fl.SetIndexColor(FreeCol4, Fl.RGB(rgbdb[i].r, rgbdb[i].g, rgbdb[i].b));
  rs.SetValue(rgbdb[i].r);
  gs.SetValue(rgbdb[i].g);
  bs.SetValue(rgbdb[i].b);
  rescol.Redraw
END SetEntry;

PROCEDURE BrowserCallback(ob: Fl.Widget);
VAR r: INTEGER;
BEGIN
  r := ob(FlBrowsers.Browser).Value();
  IF r > 0 THEN SetEntry(r - 1) END
END BrowserCallback;

(* A line of f, as fgets reads it, up to 510 bytes; eof if the file ended
   before a line feed. FALSE at the end of the file. *)
PROCEDURE GetLine(VAR r: Files.Rider; VAR buf: ARRAY OF CHAR; VAR eof: BOOLEAN): BOOLEAN;
VAR n: INTEGER; ch: CHAR;
BEGIN
  n := 0; ch := 0X; eof := FALSE;
  WHILE (n < 510) & (ch # 0AX) & ~eof DO
    Files.Read(r, ch);
    IF r.eof THEN eof := TRUE ELSE buf[n] := ch; INC(n) END
  END;
  buf[n] := 0X;
  RETURN n > 0
END GetLine;

PROCEDURE Space(c: CHAR): BOOLEAN;
BEGIN RETURN (c = " ") OR (c >= 09X) & (c <= 0DX)
END Space;

(* sscanf's " %d" at buf[p]: skips white space, then reads a number. *)
PROCEDURE Int(buf-: ARRAY OF CHAR; VAR p, n: INTEGER): BOOLEAN;
VAR neg: BOOLEAN;
BEGIN
  WHILE Space(buf[p]) DO INC(p) END;
  neg := buf[p] = "-";
  IF (buf[p] = "-") OR (buf[p] = "+") THEN INC(p) END;
  IF (buf[p] < "0") OR (buf[p] > "9") THEN RETURN FALSE END;
  n := 0;
  WHILE (buf[p] >= "0") & (buf[p] <= "9") DO n := n * 10 + ORD(buf[p]) - ORD("0"); INC(p) END;
  IF neg THEN n := -n END;
  RETURN TRUE
END Int;

(* An entry of the file, "r g b name", skipping a comment line starting
   with "!", the name with its spaces taken out. *)
PROCEDURE ReadEntry(VAR rd: Files.Rider; VAR r, g, b: INTEGER; VAR name: ARRAY OF CHAR): BOOLEAN;
VAR buf: ARRAY 512 OF CHAR; eof: BOOLEAN; p, i: INTEGER;
BEGIN
  IF ~GetLine(rd, buf, eof) THEN RETURN FALSE END;
  IF (buf[0] = "!") & GetLine(rd, buf, eof) THEN END;
  p := 0;
  IF ~Int(buf, p, r) OR ~Int(buf, p, g) OR ~Int(buf, p, b) THEN RETURN FALSE END;
  WHILE Space(buf[p]) DO INC(p) END;
  i := 0;
  WHILE buf[p] # 0X DO
    IF (buf[p] # " ") & (buf[p] # 0AX) THEN name[i] := buf[p]; INC(i) END;
    INC(p)
  END;
  name[i] := 0X;
  RETURN ~eof
END ReadEntry;

PROCEDURE LoadBrowser(fname-: ARRAY OF CHAR): BOOLEAN;
VAR f: Files.File; rd: Files.Rider; db, r, g, b, lr, lg, lb: INTEGER;
  name: ARRAY 512 OF CHAR; buf: ARRAY 1100 OF CHAR;
BEGIN
  f := Files.Old(fname);
  IF f = NIL THEN
    buf := "Load:|Can't open '"; Lines(buf); Cat(fname, buf); Cat("'", buf);
    FlDialogs.Alert(buf);
    RETURN FALSE
  END;
  Files.Set(rd, f, 0);
  db := 0; lr := -1; lg := -1; lb := -1;
  WHILE (db < MaxRGB) & ReadEntry(rd, r, g, b, name) DO
    rgbdb[db].r := r; rgbdb[db].g := g; rgbdb[db].b := b;
    (* unique the entries on the fly *)
    IF (lr # r) OR (lg # g) OR (lb # b) THEN
      INC(db); lr := r; lg := g; lb := b;
      buf := "("; Num3(r, buf); Cat(" ", buf); Num3(g, buf); Cat(" ", buf); Num3(b, buf);
      Cat(") ", buf); Cat(name, buf);
      colbr.Add(buf)
    END
  END;
  Files.Close(f);
  IF db = MaxRGB THEN DEC(db) END;
  rgbdb[db].r := 1000; (* sentinel *)
  colbr.SetTopLine(1);
  IF colbr.Select(1, TRUE) THEN END;
  SetEntry(0);
  RETURN TRUE
END LoadBrowser;

PROCEDURE SearchEntry(r, g, b: INTEGER): INTEGER;
VAR i, j, diffr, diffg, diffb: INTEGER; diff, mindiff: LONGREAL;
BEGIN
  mindiff := MAX(LONGREAL); i := 0; j := 0;
  WHILE (i < MaxRGB) & (rgbdb[i].r < 256) DO
    diffr := r - rgbdb[i].r; diffg := g - rgbdb[i].g; diffb := b - rgbdb[i].b;
    (* FLTK's program truncates to an unsigned *)
    diff := ENTIER(3.0D0 * (diffr * diffr) + 5.9D0 * (diffg * diffg) + 1.1D0 * (diffb * diffb));
    IF mindiff > diff THEN mindiff := diff; j := i END;
    INC(i)
  END;
  RETURN j
END SearchEntry;

PROCEDURE SearchRGB(w: Fl.Widget);
VAR r, g, b, i, top: INTEGER;
BEGIN
  top := colbr.TopLine();
  r := SHORT(ENTIER(rs.Value())); g := SHORT(ENTIER(gs.Value())); b := SHORT(ENTIER(bs.Value()));
  Fl.SetIndexColor(FreeCol4, Fl.RGB(r, g, b));
  rescol.Redraw;
  i := SearchEntry(r, g, b);
  (* change the top line only if necessary; FLTK clamps it to the lines *)
  IF (i < top) OR (i > top + 15) THEN
    IF i - 8 < 1 THEN colbr.SetTopLine(1) ELSE colbr.SetTopLine(i - 8) END
  END;
  IF colbr.Select(i + 1, TRUE) THEN END
END SearchRGB;

(* Asks for another file. *)
PROCEDURE DbCallback(ob: Fl.Widget);
VAR p: ARRAY 1024 OF CHAR;
BEGIN
  p := dbname;
  IF FlDialogs.Input("Enter New Database Name", p) & (p # dbname) THEN
    IF LoadBrowser(p) THEN
      dbname := p;
      IF labelIsDbname THEN ob.SetLabel(dbname) END
    ELSE ob.SetLabel(dbname); labelIsDbname := TRUE
    END
  END
END DbCallback;

PROCEDURE Done(w: Fl.Widget);
BEGIN HALT(0)
END Done;

PROCEDURE Slider(VAR s: FlValuators.ValueSlider; x, c: INTEGER);
BEGIN
  NEW(s); FlValuators.OpenValueSlider(s, x, 130, 30, 200, "");
  s.SetKind(FlValuators.VertFillSlider);
  s.SetColor(IndianRed); s.SetSelectionColor(c);
  s.SetBounds(0, 255);
  s.SetPrecision(0);
  s.action := SearchRGB;
  s.SetWhen(Fl.WhenRelease)
END Slider;

PROCEDURE CreateFormCl;
VAR title: Fl.Box; done: FlButtons.Button;
BEGIN
  NEW(cl); Fl.OpenDoubleWindow(cl, 400, 385, "");
  cl.SetBoxType(Fl.UpBox);
  cl.SetColor(IndianRed); cl.SetSelectionColor(Fl.Gray);

  NEW(title); Fl.OpenBox(title, 40, 10, 300, 30, "Color Browser");
  title.SetBoxType(Fl.NoBox);
  title.SetLabelColor(Fl.Red);
  title.SetLabelSize(32);
  title.SetLabelFont(Fl.HelveticaBold);
  title.SetLabelType(Fl.ShadowLabel);

  NEW(dbobj); FlButtons.OpenButton(dbobj, 40, 50, 300, 25, "");
  dbobj.SetBoxType(Fl.BorderBox);
  dbobj.SetColor(IndianRed); dbobj.SetSelectionColor(IndianRed);
  dbobj.action := DbCallback;

  NEW(colbr); FlBrowsers.OpenHoldBrowser(colbr, 10, 90, 280, 240, "");
  colbr.SetTextFont(Fl.Courier);
  colbr.action := BrowserCallback;
  colbr.SetBoxType(Fl.DownBox);

  NEW(rescol); Fl.OpenBox(rescol, 300, 90, 90, 35, "");
  rescol.SetColor(FreeCol4); rescol.SetSelectionColor(FreeCol4);
  rescol.SetBoxType(Fl.BorderBox);

  Slider(rs, 300, Fl.Red);
  Slider(gs, 330, Fl.Green);
  Slider(bs, 360, Fl.Blue);

  NEW(done); FlButtons.OpenButton(done, 160, 345, 80, 30, "Done");
  done.action := Done;

  cl.End;
  cl.SetResizable(cl)
END CreateFormCl;

BEGIN
  IF ~Fl.ParseArgs(NIL, i) THEN
    Fl.ArgsHelp(help); Err.String(help); Err.Ln; HALT(1)
  END;
  IF i < Args.argc THEN Args.Get(i, name) ELSE name := "rgb.txt" END;
  dbname := ""; labelIsDbname := FALSE;

  CreateFormCl;

  IF LoadBrowser(name) THEN dbobj.SetLabel(name) ELSE dbobj.SetLabel("None") END;
  dbobj.Redraw;

  cl.SizeRange(cl.W(), cl.H(), 2 * cl.W(), 2 * cl.H());

  cl.SetLabel("RGB Browser");
  cl.FreePosition;
  cl.ShowArgs;
  Fl.Run
END ColBrowser.
