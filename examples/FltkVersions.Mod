MODULE FltkVersions; (* FLTK's test/fltk-versions.cxx in Oberon-2 *)

(* The system and back end, and FLTK's version, API version and ABI
   version, each as the headers pofltk was built with have it and as the
   library running has it, and whether the two agree; printed, and shown
   in a window. A mismatch of the ABI versions is also shown in a
   message. *)

IMPORT Out, Fl, FlDialogs, FlLayout;

CONST
  ww = 640; mw = 750; (* initial and largest window width *)
  wh = 200; mh = 300; (* initial and largest window height *)

VAR
  window: Fl.Window;
  grid: FlLayout.Grid;
  title: Fl.Box;
  box: ARRAY 9 OF Fl.Box;
  version: ARRAY 9, 80 OF CHAR;
  platform: ARRAY 64 OF CHAR;
  s: ARRAY 128 OF CHAR;
  versions, i: INTEGER;
  built, running: LONGREAL;

(* Appends t to s. *)
PROCEDURE Cat(t-: ARRAY OF CHAR; VAR s: ARRAY OF CHAR);
  VAR i, j: INTEGER;
BEGIN
  i := 0; WHILE s[i] # 0X DO INC(i) END;
  j := 0; WHILE t[j] # 0X DO s[i] := t[j]; INC(i); INC(j) END;
  s[i] := 0X
END Cat;

(* Appends n to s, right aligned in width, as printf's "%<width>d". *)
PROCEDURE Int(n, width: INTEGER; VAR s: ARRAY OF CHAR);
  VAR d: ARRAY 16 OF CHAR; k, i: INTEGER; neg: BOOLEAN;
BEGIN
  neg := n < 0; IF neg THEN n := -n END;
  k := 0; REPEAT d[k] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(k) UNTIL n = 0;
  IF neg THEN d[k] := "-"; INC(k) END;
  i := 0; WHILE s[i] # 0X DO INC(i) END;
  WHILE width > k DO s[i] := " "; INC(i); DEC(width) END;
  WHILE k > 0 DO DEC(k); s[i] := d[k]; INC(i) END;
  s[i] := 0X
END Int;

(* Appends v to s as printf's "%6.4f", for a version under 10. *)
PROCEDURE Real(v: LONGREAL; VAR s: ARRAY OF CHAR);
  VAR n, d: INTEGER; f: ARRAY 2 OF CHAR;
BEGIN
  n := SHORT(ENTIER(v * 10000.0D0 + 0.5D0));
  Int(n DIV 10000, 1, s); Cat(".", s);
  f[1] := 0X; d := 1000;
  WHILE d > 0 DO f[0] := CHR(ORD("0") + n DIV d MOD 10); Cat(f, s); d := d DIV 10 END
END Real;

PROCEDURE Verdict(ok: BOOLEAN; VAR s: ARRAY OF CHAR);
BEGIN s[0] := 0X; IF ok THEN Cat("OK", s) ELSE Cat("FAIL", s) END
END Verdict;

(* The system and back end; opens the display. *)
PROCEDURE GetPlatform(VAR s: ARRAY OF CHAR);
BEGIN
  s[0] := 0X;
  IF Fl.Has(Fl.X11) THEN Cat("Unix/Linux (X11)", s)
  ELSIF Fl.Has(Fl.Wayland) THEN Cat("Unix/Linux (Wayland)", s)
  ELSE Cat("platform unknown, unsupported, or display not opened", s)
  END
END GetPlatform;

(* A box's font, size and alignment. *)
PROCEDURE SetAttributes(w: Fl.Widget);
BEGIN
  w.SetLabelFont(Fl.Courier);
  w.SetLabelSize(16);
  w.SetAlign(Fl.AlignCenter + Fl.AlignInside)
END SetAttributes;

BEGIN
  GetPlatform(platform);
  Out.String("System/platform   = "); Out.String(platform); Out.Ln;

  versions := 0;
  built := Fl.BuiltVersion(); running := Fl.Version();
  version[0] := "FL_VERSION        = "; Real(built, version[0]);
  version[1] := "Fl::version()     = "; Real(running, version[1]);
  Verdict(built = running, version[2]);
  version[3] := "FL_API_VERSION    = "; Int(Fl.BuiltApiVersion(), 6, version[3]);
  version[4] := "Fl::api_version() = "; Int(Fl.ApiVersion(), 6, version[4]);
  Verdict(Fl.BuiltApiVersion() = Fl.ApiVersion(), version[5]);
  version[6] := "FL_ABI_VERSION    = "; Int(Fl.BuiltAbiVersion(), 6, version[6]);
  version[7] := "Fl::abi_version() = "; Int(Fl.AbiVersion(), 6, version[7]);
  Verdict(Fl.BuiltAbiVersion() = Fl.AbiVersion(), version[8]);
  versions := 9;

  FOR i := 0 TO versions - 1 DO
    Out.String(version[i]);
    IF i MOD 3 = 1 THEN Out.String("  ") ELSE Out.Ln END
  END;

  IF Fl.BuiltAbiVersion() # Fl.AbiVersion() THEN
    s := "*** FLTK ABI version mismatch: headers = "; Int(Fl.BuiltAbiVersion(), 0, s);
    Cat(", lib = ", s); Int(Fl.AbiVersion(), 0, s); Cat(" ***", s);
    Out.String(s); Out.Ln;
    FlDialogs.Message(s)
  END;

  NEW(window); Fl.OpenWindow(window, ww, wh, "");
  NEW(grid); FlLayout.OpenGrid(grid, 0, 0, ww, wh, "");
  grid.SetMargins(20, 20, 20, 20); grid.SetGap(5, 5);
  grid.SetLayout(4, 3);

  NEW(title); Fl.OpenBox(title, 0, 0, 0, 0, platform);
  SetAttributes(title);
  title.SetLabelFont(Fl.HelveticaBold);
  grid.PlaceSpan(title, 0, 0, 1, 3, FlLayout.GridFill);
  grid.SetRowHeight(0, 40);
  title.SetLabelSize(20);

  FOR i := 0 TO 2 DO
    NEW(box[3 * i]); Fl.OpenBox(box[3 * i], 0, 0, 270, 0, version[3 * i]);
    NEW(box[3 * i + 1]); Fl.OpenBox(box[3 * i + 1], 0, 0, 270, 0, version[3 * i + 1]);
    NEW(box[3 * i + 2]); Fl.OpenBox(box[3 * i + 2], 0, 0, 40, 0, version[3 * i + 2]);
    grid.Place(box[3 * i], i + 1, 0, FlLayout.GridFill);
    grid.Place(box[3 * i + 1], i + 1, 1, FlLayout.GridFill);
    grid.Place(box[3 * i + 2], i + 1, 2, FlLayout.GridFill);
    grid.SetRowHeight(i + 1, 30)
  END;
  FOR i := 0 TO 8 DO SetAttributes(box[i]) END;

  window.End;
  window.SetResizable(grid);
  window.SizeRange(ww, wh, mw, mh);
  window.ShowArgs;
  Fl.Run
END FltkVersions.
