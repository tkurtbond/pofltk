MODULE TestUtf8; (* FlUtf8: bad text, text filling its array, and buffers too short *)

IMPORT C := Check, U := FlUtf8;

VAR
  i, n, size: INTEGER;
  s, t: ARRAY 64 OF CHAR;
  e, f: ARRAY 8 OF CHAR;
  two: ARRAY 2 OF CHAR;    (* full, with no 0X *)
  one: ARRAY 1 OF CHAR;
  four: ARRAY 4 OF CHAR;
  long, longer: ARRAY 6000 OF CHAR;

(* Writes bytes to s, with a 0X. *)
PROCEDURE Set(VAR s: ARRAY OF CHAR; a, b, c, d, e, f: INTEGER);
BEGIN
  s[0] := CHR(a); s[1] := CHR(b); s[2] := CHR(c); s[3] := CHR(d);
  s[4] := CHR(e); s[5] := CHR(f); s[6] := 0X
END Set;

(* Writes t to s at `at`, with a 0X. *)
PROCEDURE Add(VAR s: ARRAY OF CHAR; at: INTEGER; t-: ARRAY OF CHAR);
  VAR i: INTEGER;
BEGIN
  i := 0;
  WHILE t[i] # 0X DO s[at + i] := t[i]; INC(i) END;
  s[at + i] := 0X
END Add;

PROCEDURE Same(a-, b-: ARRAY OF CHAR): BOOLEAN;
  VAR i: INTEGER;
BEGIN
  i := 0;
  WHILE (i < LEN(a)) & (i < LEN(b)) & (a[i] = b[i]) & (a[i] # 0X) DO INC(i) END;
  RETURN (i < LEN(a)) & (i < LEN(b)) & (a[i] = b[i])
END Same;

BEGIN
  C.Check(U.Length("") = 0, "Length of nothing");
  two[0] := "a"; two[1] := "b";
  C.Check(U.Length(two) = 2, "Length of an array with no 0X");

  (* walking *)
  C.Check(U.Size("a") = 1, "Size of ASCII");
  C.Check(U.Size(0C3X) = 2, "Size of two");
  C.Check(U.Size(0E2X) = 3, "Size of three");
  C.Check(U.Size(0F0X) = 4, "Size of four");
  C.Check(U.Size(080X) = -1, "Size of a continuation byte");
  C.Check(U.Size1(080X) = 1, "Size1 of a continuation byte");
  C.Check(U.Size1(0E2X) = 3, "Size1 of three");
  C.Check(U.Bytes(41H) = 1, "Bytes of ASCII");
  C.Check(U.Bytes(0E9H) = 2, "Bytes of two");
  C.Check(U.Bytes(20ACH) = 3, "Bytes of three");
  C.Check(U.Bytes(1F600H) = 4, "Bytes of four");
  C.Check(U.Bytes(110000H) = 3, "Bytes past Unicode");
  C.Check(U.Bytes(-1) = 3, "Bytes of a negative number");

  n := U.Encode(20ACH, e);
  C.Check((n = 3) & (e[0] = 0E2X) & (e[1] = 082X) & (e[2] = 0ACX) & (e[3] = 0X), "Encode");
  n := U.Encode(1F600H, e);
  C.Check((n = 4) & (e[0] = 0F0X) & (e[3] = 080X) & (e[4] = 0X), "Encode of four");
  n := U.Encode(110000H, e);
  C.Check((n = 3) & (e[0] = 0EFX) & (e[1] = 0BFX) & (e[2] = 0BDX), "Encode past Unicode");
  n := U.Encode(20ACH, four);
  C.Check((n = 3) & (four[3] = 0X), "Encode that just fits");
  n := U.Encode(1F600H, four);
  C.Check((n = 0) & (four[0] = 0X), "Encode too long");
  n := U.Encode(41H, one);
  C.Check((n = 0) & (one[0] = 0X), "Encode into one byte");

  Set(s, ORD("a"), 0E2H, 082H, 0ACH, 0F0H, 09FH);    (* the last cut short *)
  C.Check(U.Decode(s, 0, size) = 61H, "Decode ASCII");
  C.Check(size = 1, "its size");
  C.Check(U.Decode(s, 1, size) = 20ACH, "Decode three");
  C.Check(size = 3, "its size");
  C.Check(U.Decode(s, 4, size) = 0F0H, "Decode a character cut short");
  C.Check(size = 1, "its size");
  C.Check(U.Decode(s, 2, size) = 201AH, "Decode a continuation byte, by CP1252");
  C.Check(size = 1, "its size");
  two[0] := 0E2X; two[1] := 082X;
  C.Check(U.Decode(two, 0, size) = 0E2H, "Decode at the end of a full array");
  C.Check(size = 1, "its size");

  Set(s, ORD("a"), 0E2H, 082H, 0ACH, ORD("b"), 0);
  C.Check(U.Forward(s, 0) = 0, "Forward at a start");
  C.Check(U.Forward(s, 2) = 4, "Forward inside");
  C.Check(U.Forward(s, 3) = 4, "Forward at the last byte");
  C.Check(U.Forward(s, 5) = 5, "Forward at the end");
  C.Check(U.Backward(s, 3) = 1, "Backward inside");
  C.Check(U.Backward(s, 1) = 1, "Backward at a start");
  C.Check(U.Backward(s, 5) = 5, "Backward at the end");
  two[0] := 0E2X; two[1] := 082X;
  C.Check(U.Forward(two, 2) = 2, "Forward at the end of a full array");
  C.Check(U.Forward(two, 1) = 1, "Forward in a character cut short");
  C.Check(U.Backward(two, 2) = 2, "Backward at the end of a full array");

  C.Check(U.BytesOf(s, 0) = 0, "BytesOf none");
  C.Check(U.BytesOf(s, 1) = 1, "BytesOf one");
  C.Check(U.BytesOf(s, 2) = 4, "BytesOf two");
  C.Check(U.BytesOf(s, 3) = 5, "BytesOf all");
  C.Check(U.BytesOf(s, 99) = 5, "BytesOf too many");
  C.Check(U.BytesOf(two, 1) = 2, "BytesOf a character cut short");
  e[0] := 0F0X; e[1] := 0X;
  C.Check(U.BytesOf(e, 2) = 1, "BytesOf a lone lead byte");
  C.Check(U.Count(s) = 3, "Count");
  C.Check(U.Count("") = 0, "Count of nothing");
  C.Check(U.Test("abc") = 1, "Test of ASCII");
  C.Check(U.Test(s) = 3, "Test of three");
  C.Check(U.Test(two) = 0, "Test of a character cut short");

  (* FLTK composes emoji sequences alone, not a letter and its mark *)
  n := U.Encode(1F1E6H, e); Add(s, 0, e);
  n := U.Encode(1F1E7H, e); Add(s, 4, e);
  Add(s, 8, "x");
  C.Check(U.NextComposed(s, 0) = 8, "NextComposed of a flag");
  C.Check(U.NextComposed(s, 8) = 9, "NextComposed to the end");
  C.Check(U.NextComposed(s, 9) = 9, "NextComposed at the end");
  C.Check(U.PreviousComposed(s, 9) = 8, "PreviousComposed");
  C.Check(U.PreviousComposed(s, 8) = 0, "PreviousComposed of a flag");
  C.Check(U.PreviousComposed(s, 0) = 0, "PreviousComposed at the start");
  Add(s, 0, "9");
  n := U.Encode(0FE0FH, e); Add(s, 1, e);
  n := U.Encode(20E3H, e); Add(s, 4, e);
  C.Check(U.NextComposed(s, 0) = 7, "NextComposed of a keycap");
  C.Check(U.PreviousComposed(s, 7) = 0, "PreviousComposed of a keycap");
  Set(s, ORD("e"), 0CCH, 081H, 0, 0, 0);
  C.Check(U.NextComposed(s, 0) = 1, "NextComposed stops at a mark");
  e[0] := 0F0X; e[1] := 0X;
  C.Check(U.NextComposed(e, 0) = 1, "NextComposed of a lone lead byte");
  Set(s, ORD("a"), 0E2H, 080H, 08DH, 0, 0);    (* a joiner, last *)
  C.Check(U.NextComposed(s, 0) = 4, "NextComposed of a joiner at the end");
  Set(s, ORD("a"), 0E2H, 080H, 08DH, 080H, 0);    (* and a stray byte *)
  n := U.NextComposed(s, 0);
  C.Check((n > 0) & (n <= 5), "NextComposed of a joiner and a stray byte");
  Set(s, 0EFH, 0B8H, 08FH, 0, 0, 0);    (* a selector, first *)
  C.Check(U.PreviousComposed(s, 3) = 0, "PreviousComposed of a selector at the start");
  Set(s, 0F0H, 09FH, 087H, 0A6H, 0, 0);    (* half a flag *)
  C.Check(U.NextComposed(s, 0) = 4, "NextComposed of half a flag");
  four[0] := 0F0X; four[1] := 09FX; four[2] := 087X; four[3] := 0A6X;
  C.Check(U.NextComposed(four, 0) = 4, "NextComposed of half a flag filling its array");
  four[0] := "a"; four[1] := 0E2X; four[2] := 080X; four[3] := 08DX;
  C.Check(U.NextComposed(four, 0) = 4, "NextComposed of a joiner filling its array");
  C.Check(U.PreviousComposed(four, 4) = 1, "PreviousComposed of a joiner filling its array");

  (* characters *)
  C.Check(U.Nonspacing(0301H), "Nonspacing of a mark");
  C.Check(~U.Nonspacing(41H), "Nonspacing of a letter");
  C.Check(~U.Nonspacing(-1), "Nonspacing of a negative number");
  C.Check(U.Width(41H) = 1, "Width of a letter");
  C.Check(U.Width(0301H) = 0, "Width of a mark");
  C.Check(U.Width(4E00H) = 2, "Width of an ideograph");
  C.Check(U.Width(7) = -1, "Width of a control character");
  Set(s, 0E4H, 0B8H, 080H, ORD("a"), 0, 0);
  C.Check(U.WidthAt(s, 0) = 2, "WidthAt an ideograph");
  C.Check(U.WidthAt(s, 3) = 1, "WidthAt a letter");
  two[0] := 0E2X; two[1] := 082X;
  C.Check(U.WidthAt(two, 0) = 1, "WidthAt a character cut short");
  C.Check(U.WidthAt(two, 1) = 1, "WidthAt a continuation byte");
  C.Check(U.Lower(0C9H) = 0E9H, "Lower");
  C.Check(U.Upper(0E9H) = 0C9H, "Upper");
  C.Check(U.Lower(-1) = -1, "Lower of a negative number");
  C.Check(U.Upper(110000H) = 110000H, "Upper past Unicode");

  Set(s, ORD("A"), 0C3H, 089H, ORD("B"), 0, 0);
  n := U.ToLower(s, t);
  C.Check((n = 4) & (t[0] = "a") & (t[1] = 0C3X) & (t[2] = 0A9X) & (t[3] = "b") & (t[4] = 0X), "ToLower");
  n := U.ToUpper(t, f);
  C.Check((n = 4) & Same(f, s), "ToUpper");
  n := U.ToLower(s, four);
  C.Check((n = 4) & (four[0] = "a") & (four[2] = 0A9X) & (four[3] = 0X), "ToLower that just doesn't fit");
  n := U.ToLower(s, e);
  Set(s, ORD("A"), 0C3H, 089H, 0, 0, 0);
  n := U.ToLower(s, two);
  C.Check((n = 3) & (two[0] = "a") & (two[1] = 0X), "ToLower cut between characters");
  n := U.ToLower(s, one);
  C.Check((n = 3) & (one[0] = 0X), "ToLower into one byte");
  long[0] := 0X;
  FOR i := 0 TO 1999 DO long[i] := 080X END; long[2000] := 0X;
  n := U.ToUpper(long, longer);
  C.Check(n = 6000, "ToUpper of bad bytes, each three");
  C.Check(longer[5999] = 0X, "its 0X");
  e[0] := 0C3X; e[1] := 0X;
  n := U.ToLower(e, t);
  C.Check(n >= 1, "ToLower of a character cut short");

  C.Check(U.CompareNoCase("ABC", "abc") = 0, "CompareNoCase of the same");
  C.Check(U.CompareNoCase("ab", "abc") < 0, "CompareNoCase, shorter");
  C.Check(U.CompareNoCase("abd", "ABC") > 0, "CompareNoCase, after");
  Set(s, 0C3H, 089H, 0, 0, 0, 0); Set(t, 0C3H, 0A9H, 0, 0, 0, 0);
  C.Check(U.CompareNoCase(s, t) = 0, "CompareNoCase past ASCII");
  C.Check(U.CompareNoCaseN("abX", "ABY", 2) = 0, "CompareNoCaseN");
  C.Check(U.CompareNoCaseN("abX", "ABY", 3) < 0, "CompareNoCaseN of all");
  C.Check(U.CompareNoCaseN("a", "b", 0) = 0, "CompareNoCaseN of none");
  two[0] := 0E2X; two[1] := 082X;
  C.Check(U.CompareNoCase(two, two) = 0, "CompareNoCase of arrays with no 0X");

  (* conversions *)
  Set(s, ORD("a"), 0C3H, 0A9H, 0E2H, 082H, 0ACH);
  n := U.ToLatin1(s, t);
  C.Check((n = 3) & (t[0] = "a") & (t[1] = 0E9X) & (t[2] = "?") & (t[3] = 0X), "ToLatin1");
  n := U.ToLatin1(s, two);
  C.Check((n = 3) & (two[0] = "a") & (two[1] = 0X), "ToLatin1 cut short");
  n := U.ToLatin1(s, one);
  C.Check((n = 3) & (one[0] = 0X), "ToLatin1 into one byte");
  e[0] := 0C3X; e[1] := "a"; e[2] := 0C3X; e[3] := "b"; e[4] := 0X;
  n := U.ToLatin1(e, t);
  C.Check(n = 4, "ToLatin1 of bad text");
  n := U.ToLatin1(e, two);
  C.Check(n = 4, "and its count, cut short");

  Set(s, ORD("a"), 0E9H, ORD("b"), 0, 0, 0);
  n := U.FromLatin1(s, t);
  C.Check((n = 4) & (t[0] = "a") & (t[1] = 0C3X) & (t[2] = 0A9X) & (t[3] = "b") & (t[4] = 0X), "FromLatin1");
  n := U.FromLatin1(s, four);
  C.Check((n = 4) & (four[2] = 0A9X) & (four[3] = 0X), "FromLatin1 that just doesn't fit");
  n := U.FromLatin1(s, two);
  C.Check((n = 4) & (two[0] = "a") & (two[1] = 0X), "FromLatin1 cut between characters");

  Set(s, ORD("a"), ORD("b"), ORD("c"), 0, 0, 0);
  n := U.ToLocale(s, t);
  C.Check((n = 3) & Same(s, t), "ToLocale");
  n := U.FromLocale(s, t);
  C.Check((n = 3) & Same(s, t), "FromLocale");
  n := U.ToLocale(s, two);
  C.Check((n = 3) & (two[0] = "a") & (two[1] = 0X), "ToLocale too short");
  n := U.FromLocale(s, two);
  C.Check((n = 3) & (two[0] = "a") & (two[1] = 0X), "FromLocale too short");
  n := U.ToLocale(s, one);
  C.Check((n = 3) & (one[0] = 0X), "ToLocale into one byte");
  FOR i := 0 TO 1999 DO long[i] := "x" END; long[2000] := 0X;
  n := U.ToLocale(long, longer);
  C.Check((n = 2000) & Same(long, longer), "ToLocale, long");
  n := U.FromLocale(long, longer);
  C.Check((n = 2000) & Same(long, longer), "FromLocale, long");
  IF U.Utf8Locale() THEN
    Set(s, 0E2H, 082H, 0ACH, 0, 0, 0);
    n := U.ToLocale(s, two);
    C.Check((n = 3) & (two[0] = 0X), "ToLocale cut between characters")
  ELSE C.Skip("the locale isn't UTF-8")
  END;
  C.Summary
END TestUtf8.
