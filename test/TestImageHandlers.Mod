MODULE TestImageHandlers; (* FlImages: the program's image handlers *)

IMPORT Fl, FlImages, Check, Probe;

CONST
  Custom = "images/rb.rbx";   (* a format of this test's, 6 bytes *)
  Long = "images/long.rbx";   (* the same, 100 bytes, a 0X the seventh *)
  Known = "images/rb.bmp";
  Gone = "images/no-such-file";

VAR
  a, b: FlImages.Shared;
  made: FlImages.Image;     (* what the handler made last *)
  seen, long: ARRAY 400 OF CHAR;
  head: ARRAY FlImages.MaxHeader + 1 OF CHAR;
  headLen, firstAt, secondAt, count, onceAsked, i: INTEGER;
  red, blue: INTEGER;
  swapped: BOOLEAN;         (* blue left and red right, not rb's *)

(* Knows no file, and notes when it was asked. *)
PROCEDURE First(name-, header-: ARRAY OF CHAR; n: INTEGER): FlImages.Image;
BEGIN
  INC(count); firstAt := count;
  RETURN NIL
END First;

(* Makes the 4x2 image of a file starting RB, as rb.bmp shows, or the other
   way round if swapped. *)
PROCEDURE Second(name-, header-: ARRAY OF CHAR; n: INTEGER): FlImages.Image;
  VAR bits: ARRAY 24 OF CHAR; i: INTEGER;
BEGIN
  INC(count); secondAt := count;
  COPY(name, seen); headLen := n;
  FOR i := 0 TO n DO head[i] := header[i] END;
  IF (header[0] # "R") OR (header[1] # "B") THEN RETURN NIL END;
  FOR i := 0 TO 23 DO bits[i] := 0X END;
  FOR i := 0 TO 7 DO
    IF (i MOD 4 < 2) # swapped THEN bits[i * 3] := 0FFX ELSE bits[i * 3 + 2] := 0FFX END
  END;
  IF made # NIL THEN made.Close END;
  NEW(made); FlImages.OpenRGB(made, bits, 4, 2, 3, 0);
  RETURN made
END Second;

(* Removes itself as it is asked. *)
PROCEDURE Once(name-, header-: ARRAY OF CHAR; n: INTEGER): FlImages.Image;
BEGIN
  INC(onceAsked); FlImages.RemoveHandler(Once);
  RETURN NIL
END Once;

BEGIN
  red := Fl.RGB(255, 0, 0); blue := Fl.RGB(0, 0, 255);
  NEW(a);
  Check.Check(~FlImages.GetShared(a, Custom, 0, 0), "no handler, a format FlImages can't read");
  FlImages.AddHandler(First); FlImages.AddHandler(Second); FlImages.AddHandler(First);

  (* FlImages' own loading *)
  count := 0;
  Check.Check(FlImages.GetShared(a, Known, 0, 0), "a file FlImages can read");
  Check.Check(count = 0, "asks no handler");
  a.Close;
  NEW(a);
  Check.Check(~FlImages.GetShared(a, Gone, 0, 0) & (count = 0), "nor for a file not there");

  count := 0;
  Check.Check(FlImages.GetShared(a, Custom, 0, 0), "a handler's image goes into the pool");
  Check.Check((firstAt = 1) & (secondAt = 2) & (count = 2), "the first handler added first, a repeat ignored");
  Check.Check(seen = Custom, "the handler gets the name");
  Check.Check((headLen = 6) & (head[0] = "R") & (head[4] = "2") & (head[5] = 0AX) & (head[6] = 0X),
    "the file's start, its length and a 0X");
  Check.Check((a.W() = 4) & (a.H() = 2) & (a.Pixel(0, 0) = red) & (a.Pixel(3, 1) = blue), "its pixels");
  made.Close; made := NIL;
  Check.Check((a.Pixel(0, 0) = red), "the pool has a copy, so the handler's image can close");
  NEW(b);
  Check.Check(FlImages.FindShared(b, Custom, 0, 0), "and the pool finds it by name");
  b.Close;

  (* reloading *)
  swapped := TRUE;
  Check.Check(a.Reload() & (a.Pixel(0, 0) = blue), "Reload asks again");
  swapped := FALSE;
  FlImages.RemoveHandler(Second); FlImages.RemoveHandler(Second);
  count := 0;
  Check.Check(~a.Reload() & (a.Pixel(0, 0) = blue) & (count = 1),
    "a handler removed isn't asked; Reload is FALSE, the image unchanged");
  a.Close;
  FlImages.AddHandler(Second);

  (* a long header, and a long name *)
  NEW(a);
  Check.Check(FlImages.GetShared(a, Long, 0, 0), "a longer file");
  Check.Check((headLen = FlImages.MaxHeader) & (head[6] = 0X) & (head[7] = "x")
    & (head[FlImages.MaxHeader - 1] = "x") & (head[FlImages.MaxHeader] = 0X), "shows its first bytes, 0X among them");
  a.Close;
  long := "images/";
  FOR i := 7 TO 306 BY 2 DO long[i] := "."; long[i + 1] := "/" END;
  long[307] := "r"; long[308] := "b"; long[309] := "."; long[310] := "r"; long[311] := "b";
  long[312] := "x"; long[313] := 0X;
  NEW(a);
  Check.Check(FlImages.GetShared(a, long, 0, 0) & (seen = long), "a long name isn't cut");
  a.Close;

  (* FLTK's own loading, as a file chooser's preview *)
  count := 0;
  Check.Check(Probe.SharedWidth(Custom) = 4, "FLTK's loading asks the handlers");
  Check.Check((count = 2) & (headLen = 6), "with the same header");
  count := 0;
  Check.Check(Probe.SharedWidth(Known) = 0, "of any file: those FLTK has been given no handler for");
  Check.Check(count = 2, "so they say no");

  (* a handler may remove itself *)
  FlImages.RemoveHandler(First); FlImages.RemoveHandler(Second);
  FlImages.AddHandler(Once); FlImages.AddHandler(Second);
  count := 0;
  NEW(a);
  Check.Check(FlImages.GetShared(a, Custom, 0, 0), "a handler removes itself, and the next is asked");
  Check.Check(onceAsked = 1, "once");
  a.Close;
  made.Close; made := NIL;
  NEW(a);
  Check.Check(FlImages.GetShared(a, Custom, 0, 0) & (onceAsked = 1), "and not again");
  a.Close;
  made.Close;

  Check.Check(FlImages.SharedCount() = 0, "the pool empty");
  Check.Check(FlImages.openImages = 0, "every image closed");
  Check.Summary
END TestImageHandlers.
