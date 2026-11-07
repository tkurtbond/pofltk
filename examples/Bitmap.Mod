MODULE Bitmap; (* FLTK's test/bitmap.cxx: a bitmap on a button, placed by its label's alignment *)

IMPORT Fl, FlButtons, FlImages;

CONST
  width = 75; height = 75;  (* FLTK's pixmaps/sorceress.xbm *)

VAR
  w: Fl.DoubleWindow;
  b: FlButtons.Button;
  leftb, rightb, topb, bottomb, insideb, overb, inactb: FlButtons.ToggleButton;
  image: FlImages.Image;
  bits: ARRAY 750 OF CHAR;
  n: INTEGER;

(* The next row of the bitmap, in hexadecimal. *)
PROCEDURE Row(s: ARRAY OF CHAR);
  VAR i: INTEGER;

  PROCEDURE Digit(c: CHAR): INTEGER;
  BEGIN
    IF c >= "a" THEN RETURN ORD(c) - ORD("a") + 10 END;
    RETURN ORD(c) - ORD("0")
  END Digit;

BEGIN
  i := 0;
  WHILE s[i] # 0X DO
    bits[n] := CHR(Digit(s[i]) * 16 + Digit(s[i + 1])); INC(n); INC(i, 2)
  END
END Row;

PROCEDURE Bits;
BEGIN
  Row("fc7e4020900007802300");
  Row("00c6c14198b801076600");
  Row("159f03478cc6dc7bcc00");
  Row("b0710e4d0666738e8f01");
  Row("18c4394b02230c041e03");
  Row("0c08c7ef083006071c02");
  Row("063018aec8983f782006");
  Row("022060a0c41dc0ff4104");
  Row("fa6380a1a43d0084bf04");
  Row("0f06fca1346b011cc905");
  Row("06c706be111e43309105");
  Row("c36102301b30cc201100");
  Row("c13c03200a00e8602100");
  Row("611bc16308f0c6c72103");
  Row("f808e1cf0afc4d994307");
  Row("3c0cf19f0bfc5b814702");
  Row("1604311c0b1f17894d06");
  Row("1a043138020756894904");
  Row("0b04b17282a1549a4904");
  Row("1d6650e7c2f0549a5804");
  Row("0d62c11f44fc51909004");
  Row("8663e07404ef311a9100");
  Row("02e2c1fd84f9300a9100");
  Row("82a9c0b984f931168100");
  Row("42a9db7f0cff1c161100");
  Row("02280b0708601c029100");
  Row("46290e00000010161102");
  Row("06290400000010169106");
  Row("a62a0400000018249104");
  Row("862a0400000018279304");
  Row("964a0400000004029104");
  Row("864a0c0000001e239304");
  Row("56880800000090219304");
  Row("520a09800100d0219504");
  Row("570a0f802700d8209d04");
  Row("5d081c806700e4018504");
  Row("798a3f000000f4118506");
  Row("39087d000018b7108103");
  Row("2912cb007e3028008503");
  Row("2910be81ff270c108503");
  Row("2932fac1ff2794118503");
  Row("28206ce1ff070c018501");
  Row("28625ce38f034e918005");
  Row("3940f4c2ff009f918405");
  Row("31c6e8077f80cd00c404");
  Row("3106c90e00c04888e004");
  Row("7904db1200300cc8e404");
  Row("6d06b62300181cc08404");
  Row("250cffc2004e06b08004");
  Row("3f8ab383ffc303918404");
  Row("2ed80f3f00005f838404");
  Row("2a70fd7f0000c8c08404");
  Row("4be22f01000858608004");
  Row("5b82ff010008d0a08404");
  Row("7280e5000008d2204404");
  Row("ca02ff000008dea04404");
  Row("82026d000008f6b04002");
  Row("82073f00000844584402");
  Row("933f1f000030884f4403");
  Row("83233e0000001860e007");
  Row("e30ffe0000007070e407");
  Row("c71bfe010000e03ce407");
  Row("c7e3fe1f0000ff1ffc07");
  Row("c703f83300c0f007ff07");
  Row("8702fc430060f0ffff07");
  Row("8f06be870030f8ffff07");
  Row("8f149c8f0000fcffff07");
  Row("9f8d8a0f0000feffff07");
  Row("bf0b801f0000ffffff07");
  Row("7f3a803f0080ffffff07");
  Row("ff20c03f0080ffffff07");
  Row("ff01e07f00c0ffffff07");
  Row("ff0ff8ff40e0ffffff07");
  Row("ffffffff40f0ffffff07");
  Row("ffffffff41f0ffffff07")
END Bits;

PROCEDURE ButtonCB(o: Fl.Widget);
  VAR a: SET;
BEGIN
  a := {};
  IF leftb.Value() THEN a := a + Fl.AlignLeft END;
  IF rightb.Value() THEN a := a + Fl.AlignRight END;
  IF topb.Value() THEN a := a + Fl.AlignTop END;
  IF bottomb.Value() THEN a := a + Fl.AlignBottom END;
  IF insideb.Value() THEN a := a + Fl.AlignInside END;
  IF overb.Value() THEN a := a + Fl.AlignTextOverImage END;
  b.SetAlign(a);
  IF inactb.Value() THEN b.Deactivate ELSE b.Activate END;
  w.Redraw
END ButtonCB;

PROCEDURE Toggle(VAR t: FlButtons.ToggleButton; x, y, width: INTEGER; label: ARRAY OF CHAR);
BEGIN
  NEW(t); FlButtons.OpenToggleButton(t, x, y, width, 25, label); t.action := ButtonCB
END Toggle;

BEGIN
  NEW(w); Fl.OpenDoubleWindow(w, 400, 400, "Bitmap");
  NEW(b); FlButtons.OpenButton(b, 140, 160, 120, 120, "Bitmap");
  n := 0; Bits;
  NEW(image); FlImages.OpenBitmap(image, bits, width, height);
  FlImages.SetImage(b, image);
  Toggle(leftb, 25, 50, 50, "left");
  Toggle(rightb, 75, 50, 50, "right");
  Toggle(topb, 125, 50, 50, "top");
  Toggle(bottomb, 175, 50, 50, "bottom");
  Toggle(insideb, 225, 50, 50, "inside");
  Toggle(overb, 25, 75, 100, "text over");
  Toggle(inactb, 125, 75, 100, "inactive");
  w.SetResizable(w);
  w.End;
  w.ShowArgs;
  Fl.Run
END Bitmap.
