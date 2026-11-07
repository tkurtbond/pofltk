MODULE FlUtf8; (* FLTK's UTF-8: walking strings, characters, their case and width, conversions *)

(* A string here is an ARRAY OF CHAR of UTF-8, ended by 0X or by the
   array. Offsets and lengths are in bytes, and a character is its Unicode
   number. An offset that isn't in the string halts (Fl.IndexOutOfRange).

   Text that isn't good UTF-8 is not an error: FLTK reads a byte that
   doesn't belong as a character of its own, CP1252 for 80X to 9FX and
   Latin-1 above, as Decode does here.

   A procedure writing a string returns the length of the whole of it,
   and writes to `to` as much as fits, cut between characters, with a 0X,
   so a result of LEN(to) or more means it was cut short. The C++ part is
   FlUtf8.cpp. *)

IMPORT SYSTEM, Fl;

PROCEDURE ["C", "ofl_utf8_len"] CLen(c: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_utf8_len1"] CLen1(c: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_utf8_bytes"] CBytes(ucs: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_utf8_encode"] CEncode(ucs: SYSTEM.INT32; to: SYSTEM.ADDRESS; size: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_utf8_decode"] CDecode(a: SYSTEM.ADDRESS; n, at: SYSTEM.INT32; VAR size: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_utf8_fwd"] CFwd(a: SYSTEM.ADDRESS; n, at: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_utf8_back"] CBack(a: SYSTEM.ADDRESS; n, at: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_utf8_strlen"] CStrlen(a: SYSTEM.ADDRESS; n, chars: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_utf8_nb_char"] CNbChar(a: SYSTEM.ADDRESS; n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_utf8_test"] CTest(a: SYSTEM.ADDRESS; n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_utf8_next_composed"] CNextComposed(a: SYSTEM.ADDRESS; n, at: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_utf8_previous_composed"] CPreviousComposed(a: SYSTEM.ADDRESS; n, at: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_utf8_nonspacing"] CNonspacing(ucs: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_utf8_wcwidth_"] CWidth(ucs: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_utf8_wcwidth"] CWidthAt(a: SYSTEM.ADDRESS; n, at: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_utf8_tolower"] CLower(ucs: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_utf8_toupper"] CUpper(ucs: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_utf8_case"] CCase(a: SYSTEM.ADDRESS; n: SYSTEM.INT32; to: SYSTEM.ADDRESS; size, upper: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_utf8_strcasecmp"] CCompare(a: SYSTEM.ADDRESS; na: SYSTEM.INT32; b: SYSTEM.ADDRESS; nb: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_utf8_strncasecmp"] CCompareN(a: SYSTEM.ADDRESS; na: SYSTEM.INT32; b: SYSTEM.ADDRESS; nb, n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_utf8_toa"] CToA(a: SYSTEM.ADDRESS; n: SYSTEM.INT32; to: SYSTEM.ADDRESS; size: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_utf8_froma"] CFromA(a: SYSTEM.ADDRESS; n: SYSTEM.INT32; to: SYSTEM.ADDRESS; size: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_utf8_locale"] CLocale(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_utf8_to_mb"] CToMb(a: SYSTEM.ADDRESS; n: SYSTEM.INT32; to: SYSTEM.ADDRESS; size: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_utf8_from_mb"] CFromMb(a: SYSTEM.ADDRESS; n: SYSTEM.INT32; to: SYSTEM.ADDRESS; size: SYSTEM.INT32): SYSTEM.INT32;

(* The bytes of s before its 0X, or all of them. *)
PROCEDURE Length*(s-: ARRAY OF CHAR): INTEGER;
  VAR n: LONGINT;
BEGIN
  n := 0;
  WHILE (n < LEN(s)) & (s[n] # 0X) DO INC(n) END;
  RETURN SHORT(n)
END Length;

(* The offset at, checked to be in s or just after it. *)
PROCEDURE Place(n, at: INTEGER);
BEGIN ASSERT((at >= 0) & (at <= n), Fl.IndexOutOfRange)
END Place;

(* Walking *)

(* The bytes of the character c begins, up to 6 as FLTK counts them, or
   -1 if c can't begin one. *)
PROCEDURE Size*(c: CHAR): INTEGER;
BEGIN RETURN CLen(ORD(c))
END Size;

(* As Size, but 1 for a c that can't begin a character. *)
PROCEDURE Size1*(c: CHAR): INTEGER;
BEGIN RETURN CLen1(ORD(c))
END Size1;

(* The bytes Encode gives for ucs: 3, for U+FFFD, if it is negative or past
   U+10FFFF. A surrogate is encoded as it is, in 3. *)
PROCEDURE Bytes*(ucs: INTEGER): INTEGER;
BEGIN RETURN CBytes(ucs)
END Bytes;

(* Writes ucs and a 0X to `to`. Returns its bytes, or 0, writing only the
   0X, if `to` is too short. `to` needs 5 bytes for any character. *)
PROCEDURE Encode*(ucs: INTEGER; VAR to: ARRAY OF CHAR): INTEGER;
BEGIN RETURN CEncode(ucs, SYSTEM.ADR(to), SHORT(LEN(to)))
END Encode;

(* The character at s[at], and in size the bytes it takes. *)
PROCEDURE Decode*(s-: ARRAY OF CHAR; at: INTEGER; VAR size: INTEGER): INTEGER;
  VAR n: INTEGER; bytes, ucs: SYSTEM.INT32;
BEGIN
  n := Length(s);
  ASSERT((at >= 0) & (at < n), Fl.IndexOutOfRange);
  ucs := CDecode(SYSTEM.ADR(s), n, at, bytes);
  size := bytes;
  RETURN ucs
END Decode;

(* at, moved forward to the start of a character if it is inside one. *)
PROCEDURE Forward*(s-: ARRAY OF CHAR; at: INTEGER): INTEGER;
  VAR n: INTEGER;
BEGIN
  n := Length(s); Place(n, at);
  RETURN CFwd(SYSTEM.ADR(s), n, at)
END Forward;

(* at, moved back to the start of a character if it is inside one. *)
PROCEDURE Backward*(s-: ARRAY OF CHAR; at: INTEGER): INTEGER;
  VAR n: INTEGER;
BEGIN
  n := Length(s); Place(n, at);
  RETURN CBack(SYSTEM.ADR(s), n, at)
END Backward;

(* The bytes of the first `chars` characters of s, or of s if it is
   shorter. *)
PROCEDURE BytesOf*(s-: ARRAY OF CHAR; chars: INTEGER): INTEGER;
BEGIN
  ASSERT(chars >= 0, Fl.IndexOutOfRange);
  RETURN CStrlen(SYSTEM.ADR(s), Length(s), chars)
END BytesOf;

(* The characters in s. *)
PROCEDURE Count*(s-: ARRAY OF CHAR): INTEGER;
BEGIN RETURN CNbChar(SYSTEM.ADR(s), Length(s))
END Count;

(* 0 if s isn't UTF-8, else the bytes of its longest character. *)
PROCEDURE Test*(s-: ARRAY OF CHAR): INTEGER;
BEGIN RETURN CTest(SYSTEM.ADR(s), Length(s))
END Test;

(* The start of what follows at: the next character, or, for an emoji
   sequence (a flag, a keycap, characters joined), what follows that. It
   doesn't take a letter and its combining marks as one. Length(s) if
   nothing follows. *)
PROCEDURE NextComposed*(s-: ARRAY OF CHAR; at: INTEGER): INTEGER;
  VAR n: INTEGER;
BEGIN
  n := Length(s); Place(n, at);
  IF at = n THEN RETURN n END;
  RETURN CNextComposed(SYSTEM.ADR(s), n, at)
END NextComposed;

(* The start of what comes before at, as NextComposed sees it. 0 if
   nothing comes before. *)
PROCEDURE PreviousComposed*(s-: ARRAY OF CHAR; at: INTEGER): INTEGER;
  VAR n: INTEGER;
BEGIN
  n := Length(s); Place(n, at);
  IF at = 0 THEN RETURN 0 END;
  RETURN CPreviousComposed(SYSTEM.ADR(s), n, at)
END PreviousComposed;

(* Characters *)

(* Whether ucs is drawn over the character before it. *)
PROCEDURE Nonspacing*(ucs: INTEGER): BOOLEAN;
BEGIN RETURN CNonspacing(ucs) # 0
END Nonspacing;

(* The columns ucs takes in a terminal: 0, 1 or 2, or -1 for a control
   character. *)
PROCEDURE Width*(ucs: INTEGER): INTEGER;
BEGIN RETURN CWidth(ucs)
END Width;

(* The columns of the character at s[at]. *)
PROCEDURE WidthAt*(s-: ARRAY OF CHAR; at: INTEGER): INTEGER;
  VAR n: INTEGER;
BEGIN
  n := Length(s);
  ASSERT((at >= 0) & (at < n), Fl.IndexOutOfRange);
  RETURN CWidthAt(SYSTEM.ADR(s), n, at)
END WidthAt;

PROCEDURE Lower*(ucs: INTEGER): INTEGER;
BEGIN RETURN CLower(ucs)
END Lower;

PROCEDURE Upper*(ucs: INTEGER): INTEGER;
BEGIN RETURN CUpper(ucs)
END Upper;

PROCEDURE ToLower*(s-: ARRAY OF CHAR; VAR to: ARRAY OF CHAR): INTEGER;
BEGIN RETURN CCase(SYSTEM.ADR(s), Length(s), SYSTEM.ADR(to), SHORT(LEN(to)), 0)
END ToLower;

PROCEDURE ToUpper*(s-: ARRAY OF CHAR; VAR to: ARRAY OF CHAR): INTEGER;
BEGIN RETURN CCase(SYSTEM.ADR(s), Length(s), SYSTEM.ADR(to), SHORT(LEN(to)), 1)
END ToUpper;

(* Less than 0, 0 or more than 0 as a is before, the same as or after b,
   ignoring case. *)
PROCEDURE CompareNoCase*(a-, b-: ARRAY OF CHAR): INTEGER;
BEGIN RETURN CCompare(SYSTEM.ADR(a), Length(a), SYSTEM.ADR(b), Length(b))
END CompareNoCase;

(* As CompareNoCase, on the first n characters of each. *)
PROCEDURE CompareNoCaseN*(a-, b-: ARRAY OF CHAR; n: INTEGER): INTEGER;
BEGIN
  ASSERT(n >= 0, Fl.IndexOutOfRange);
  RETURN CCompareN(SYSTEM.ADR(a), Length(a), SYSTEM.ADR(b), Length(b), n)
END CompareNoCaseN;

(* Conversions *)

(* s as Latin-1, with "?" for a character that has none; a sequence that
   composes is one "?". *)
PROCEDURE ToLatin1*(s-: ARRAY OF CHAR; VAR to: ARRAY OF CHAR): INTEGER;
BEGIN RETURN CToA(SYSTEM.ADR(s), Length(s), SYSTEM.ADR(to), SHORT(LEN(to)))
END ToLatin1;

PROCEDURE FromLatin1*(s-: ARRAY OF CHAR; VAR to: ARRAY OF CHAR): INTEGER;
BEGIN RETURN CFromA(SYSTEM.ADR(s), Length(s), SYSTEM.ADR(to), SHORT(LEN(to)))
END FromLatin1;

(* Whether the locale's encoding is UTF-8, so ToLocale and FromLocale
   copy. *)
PROCEDURE Utf8Locale*(): BOOLEAN;
BEGIN RETURN CLocale() # 0
END Utf8Locale;

(* s in the locale's encoding, or as it is if it won't convert. *)
PROCEDURE ToLocale*(s-: ARRAY OF CHAR; VAR to: ARRAY OF CHAR): INTEGER;
BEGIN RETURN CToMb(SYSTEM.ADR(s), Length(s), SYSTEM.ADR(to), SHORT(LEN(to)))
END ToLocale;

(* s, in the locale's encoding, as UTF-8, or as it is if it won't
   convert. *)
PROCEDURE FromLocale*(s-: ARRAY OF CHAR; VAR to: ARRAY OF CHAR): INTEGER;
BEGIN RETURN CFromMb(SYSTEM.ADR(s), Length(s), SYSTEM.ADR(to), SHORT(LEN(to)))
END FromLocale;

END FlUtf8.
