MODULE UtCore; (* FLTK's test/unittest_core.cxx and unittests.cxx's Ut_Suite in Oberon-2 *)

(* The core tests, logged as Google Test does, as FLTK's are: to the
   page's terminal, a test every 0.15 seconds from the page's first
   showing, or all at once to the standard output (Unittests --core).
   FLTK's tests of Fl_String, its own string class, have nothing here to
   test, so this page runs the tests of the fl_filename functions FLTK's
   file has, but leaves out (their suite needs Fl_String): suite
   fl_filename, tests ext, setext, relative and absolute. A failed check
   names its place in this file by the test's check number, not by the
   line, since Oberon has no __LINE__. *)

IMPORT Fl, FlDialogs, FlTerminal, Out, Ut;

CONST
  Label* = "Core Functionality";
  Suite = "fl_filename";
  NTests = 4;

TYPE
  Test = PROCEDURE (): BOOLEAN;

  Page = POINTER TO RECORD (Fl.GroupDesc)
    ran: BOOLEAN  (* its tests have been started *)
  END;

  Tick = POINTER TO RECORD (Fl.TimerDesc) END;

VAR
  tty: FlTerminal.Terminal;  (* where the log goes; NIL for the standard output *)
  red, green, normal: ARRAY 8 OF CHAR;  (* the log's colors *)
  tests: ARRAY NTests OF Test;
  names: ARRAY NTests, 16 OF CHAR;
  done, failed: ARRAY NTests OF BOOLEAN;
  numPassed, numFailed: INTEGER;
  suiteDone: BOOLEAN;
  name: ARRAY 16 OF CHAR;  (* the running test's, for its checks' log *)

(* Logging *)

PROCEDURE Put(s: ARRAY OF CHAR);
BEGIN IF tty # NIL THEN tty.Append(s) ELSE Out.String(s) END
END Put;

PROCEDURE Ln;
  VAR s: ARRAY 2 OF CHAR;
BEGIN
  IF tty # NIL THEN s[0] := 0AX; s[1] := 0X; tty.Append(s) ELSE Out.Ln END
END Ln;

PROCEDURE PutInt(n: INTEGER);
  VAR s: ARRAY 12 OF CHAR; d: ARRAY 12 OF CHAR; i, j: INTEGER;
BEGIN
  i := 0;
  REPEAT d[i] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(i) UNTIL n = 0;
  j := 0; WHILE i > 0 DO DEC(i); s[j] := d[i]; INC(j) END;
  s[j] := 0X; Put(s)
END PutInt;

(* "[tag]" in color c, then text *)
PROCEDURE Tag(c, tag: ARRAY OF CHAR);
BEGIN Put(c); Put(tag); Put(normal); Put(" ")
END Tag;

PROCEDURE Plural(n: INTEGER);
BEGIN IF n # 1 THEN Put("s") END
END Plural;

(* Turns the log's colors on or off (Unittests --color=1, --color=0). *)
PROCEDURE Color*(on: BOOLEAN);
BEGIN
  IF on THEN
    red := "x[31m"; red[0] := 1BX;
    green := "x[32m"; green[0] := 1BX;
    normal := "x[0m"; normal[0] := 1BX
  ELSE red := ""; green := ""; normal := ""
  END
END Color;

(* A check: TRUE if actual is expected, else logged as EXPECT_STREQ's. *)
PROCEDURE StrEq(n: INTEGER; cond, actual, expected: ARRAY OF CHAR): BOOLEAN;
BEGIN
  IF actual = expected THEN RETURN TRUE END;
  Put("UtCore.Mod("); Put(name); Put(", check "); PutInt(n); Put("): error:"); Ln;
  Put("Value of: "); Put(cond); Ln;
  Put("  Actual: "); Put(actual); Ln;
  Put("Expected: "); Put(expected); Ln;
  RETURN FALSE
END StrEq;

(* The tests *)

PROCEDURE Ext(): BOOLEAN;
  VAR r: ARRAY 64 OF CHAR;
BEGIN
  FlDialogs.FilenameExt("test.txt", r);
  IF ~StrEq(1, 'FilenameExt("test.txt")', r, ".txt") THEN RETURN FALSE END;
  FlDialogs.FilenameExt("test", r);
  IF ~StrEq(2, 'FilenameExt("test")', r, "") THEN RETURN FALSE END;
  FlDialogs.FilenameExt("", r);
  RETURN StrEq(3, 'FilenameExt("")', r, "")
END Ext;

PROCEDURE SetExt(): BOOLEAN;
  VAR r: ARRAY 64 OF CHAR;
BEGIN
  r := "test.txt"; FlDialogs.FilenameSetExt(r, ".rtf");
  IF ~StrEq(1, 'FilenameSetExt("test.txt", ".rtf")', r, "test.rtf") THEN RETURN FALSE END;
  r := "test"; FlDialogs.FilenameSetExt(r, ".rtf");
  IF ~StrEq(2, 'FilenameSetExt("test", ".rtf")', r, "test.rtf") THEN RETURN FALSE END;
  r := "test.txt"; FlDialogs.FilenameSetExt(r, "");
  IF ~StrEq(3, 'FilenameSetExt("test.txt", "")', r, "test") THEN RETURN FALSE END;
  r := ""; FlDialogs.FilenameSetExt(r, ".rtf");
  IF ~StrEq(4, 'FilenameSetExt("", ".rtf")', r, ".rtf") THEN RETURN FALSE END;
  r := "path/test"; FlDialogs.FilenameSetExt(r, ".rtf");
  RETURN StrEq(5, 'FilenameSetExt("path/test", ".rtf")', r, "path/test.rtf")
END SetExt;

PROCEDURE Relative(): BOOLEAN;
  CONST base = "/var/tmp/somedir";
  VAR r: ARRAY 64 OF CHAR;
BEGIN
  IF FlDialogs.FilenameRelativeTo("/var/tmp/somedir/foo.txt", base, r) THEN END;
  IF ~StrEq(1, 'FilenameRelativeTo("/var/tmp/somedir/foo.txt", base)', r, "foo.txt") THEN RETURN FALSE END;
  IF FlDialogs.FilenameRelativeTo("/var/tmp/foo.txt", base, r) THEN END;
  IF ~StrEq(2, 'FilenameRelativeTo("/var/tmp/foo.txt", base)', r, "../foo.txt") THEN RETURN FALSE END;
  IF FlDialogs.FilenameRelativeTo("./foo.txt", base, r) THEN END;
  IF ~StrEq(3, 'FilenameRelativeTo("./foo.txt", base)', r, "./foo.txt") THEN RETURN FALSE END;
  IF FlDialogs.FilenameRelativeTo("../foo.txt", base, r) THEN END;
  RETURN StrEq(4, 'FilenameRelativeTo("../foo.txt", base)', r, "../foo.txt")
END Relative;

PROCEDURE Absolute(): BOOLEAN;
  CONST base = "/var/tmp/somedir";
  VAR r: ARRAY 64 OF CHAR;
BEGIN
  IF FlDialogs.FilenameAbsoluteTo("foo.txt", base, r) THEN END;
  IF ~StrEq(1, 'FilenameAbsoluteTo("foo.txt", base)', r, "/var/tmp/somedir/foo.txt") THEN RETURN FALSE END;
  IF FlDialogs.FilenameAbsoluteTo("/var/tmp/foo.txt", base, r) THEN END;
  IF ~StrEq(2, 'FilenameAbsoluteTo("/var/tmp/foo.txt", base)', r, "/var/tmp/foo.txt") THEN RETURN FALSE END;
  IF FlDialogs.FilenameAbsoluteTo("./foo.txt", base, r) THEN END;
  IF ~StrEq(3, 'FilenameAbsoluteTo("./foo.txt", base)', r, "/var/tmp/somedir/foo.txt") THEN RETURN FALSE END;
  IF FlDialogs.FilenameAbsoluteTo("../foo.txt", base, r) THEN END;
  RETURN StrEq(4, 'FilenameAbsoluteTo("../foo.txt", base)', r, "/var/tmp/foo.txt")
END Absolute;

(* Running them, as Ut_Suite does *)

PROCEDURE Run(i: INTEGER): BOOLEAN;
BEGIN
  name := names[i];
  Tag(green, "[ RUN      ]"); Put(Suite); Put("."); Put(name); Ln;
  failed[i] := ~tests[i]();
  IF failed[i] THEN Tag(red, "[  FAILED  ]") ELSE Tag(green, "[       OK ]") END;
  Put(Suite); Put("."); Put(name); Ln;
  done[i] := TRUE;
  RETURN ~failed[i]
END Run;

PROCEDURE Prolog;
BEGIN
  numPassed := 0; numFailed := 0;
  Tag(green, "[==========]"); Put("Running "); PutInt(NTests);
  Put(" tests from 1 test case."); Ln
END Prolog;

PROCEDURE SuiteHeading;
BEGIN
  Tag(green, "[----------]"); PutInt(NTests); Put(" test"); Plural(NTests);
  Put(" from "); Put(Suite); Ln
END SuiteHeading;

PROCEDURE Epilog;
  VAR i: INTEGER;
BEGIN
  Tag(green, "[==========]"); PutInt(NTests); Put(" tests from 1 test case ran."); Ln;
  IF numPassed > 0 THEN
    Tag(green, "[  PASSED  ]"); PutInt(numPassed); Put(" test"); Plural(numPassed); Put("."); Ln
  END;
  IF numFailed > 0 THEN
    Tag(red, "[  FAILED  ]"); PutInt(numFailed); Put(" test"); Plural(numFailed);
    Put(", listed below:"); Ln
  END;
  FOR i := 0 TO NTests - 1 DO
    IF failed[i] THEN Tag(red, "[  FAILED  ]"); Put(Suite); Put("."); Put(names[i]); Ln END
  END
END Epilog;

(* Runs the next test, or logs the end: FALSE once that is done. As
   FLTK's run_next_test, a suite's end takes a step of its own. *)
PROCEDURE RunNext(): BOOLEAN;
  VAR i: INTEGER;
BEGIN
  IF suiteDone THEN Epilog; RETURN FALSE END;
  IF ~done[0] THEN Prolog; SuiteHeading END;
  i := 0; WHILE (i < NTests) & done[i] DO INC(i) END;
  IF i = NTests THEN suiteDone := TRUE
  ELSIF Run(i) THEN INC(numPassed)
  ELSE INC(numFailed)
  END;
  RETURN TRUE
END RunNext;

(* Runs every test, logging to the standard output: the number failed. *)
PROCEDURE RunAll*(): INTEGER;
  VAR i: INTEGER;
BEGIN
  tty := NIL;
  Prolog; SuiteHeading;
  FOR i := 0 TO NTests - 1 DO
    IF Run(i) THEN INC(numPassed) ELSE INC(numFailed) END
  END;
  Epilog;
  RETURN numFailed
END RunAll;

PROCEDURE (t: Tick) Fire*;
BEGIN IF RunNext() THEN Fl.RepeatTimeout(t, 0.15D0) END
END Fire;

(* Showing the page the first time starts its tests. *)
PROCEDURE (p: Page) Show*;
  VAR t: Tick;
BEGIN
  p.Show^;
  IF ~p.ran THEN NEW(t); Fl.AddTimeout(t, 0.5D0); p.ran := TRUE END
END Show;

PROCEDURE Create*(): Fl.Widget;
  VAR p: Page;
BEGIN
  NEW(p); Fl.OpenGroup(p, Ut.X, Ut.Y, Ut.W, Ut.H, "");
  NEW(tty); FlTerminal.OpenTerminal(tty, Ut.X + 4, Ut.Y + 4, Ut.W - 8, Ut.H - 8, "Unittest Log");
  tty.SetAnsi(TRUE);
  p.End;
  RETURN p
END Create;

BEGIN
  Color(TRUE);
  tests[0] := Ext; names[0] := "ext";
  tests[1] := SetExt; names[1] := "setext";
  tests[2] := Relative; names[2] := "relative";
  tests[3] := Absolute; names[3] := "absolute"
END UtCore.
