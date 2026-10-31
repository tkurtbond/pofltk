MODULE Utf8Test;  (* FLTK's test/utf8.cxx, without its font chooser, which Fonts shows: Unicode in inputs, and the first 65536 characters *)

IMPORT Args, Fl, FlDraw, FlInputs, FlLayout, FlUtf8, OutStr;

CONST
  inputWidth = 240;  (* of the inputs on the left *)
  windowWidth = inputWidth + 10 + 5 * 75;
  windowHeight = 400;
  extraFont = Fl.TimesBoldItalic;

TYPE
  (* Draws its text from the right, FlDraw.RightToLeft *)
  RightLeftInput = POINTER TO RECORD (FlInputs.InputDesc) END;

  (* Shows the first character dropped on it, its bytes and its code *)
  UCharDropBox = POINTER TO RECORD (FlInputs.OutputDesc) END;

VAR
  win: Fl.DoubleWindow;
  scroll: FlLayout.Scroll;
  i7, i8: FlInputs.Input;
  o9: FlInputs.Output;
  dropBox: UCharDropBox;
  right: RightLeftInput;
  text: ARRAY 200 OF CHAR;
  arabic: ARRAY 8 OF INTEGER;
  spaced: ARRAY 14 OF INTEGER;

PROCEDURE (i: RightLeftInput) Draw*;
  VAR b: INTEGER; s: ARRAY 256 OF CHAR;
BEGIN
  b := i.BoxType();
  IF i.Damage() * Fl.DamageAll # {} THEN i.DrawBox END;
  FlDraw.SetColor(i.TextColor());
  FlDraw.SetFont(i.TextFont(), i.TextSize());
  i.Value(s);
  FlDraw.RightToLeft(s, i.X() + Fl.BoxDX(b) + 3 + i.W() - Fl.BoxDW(b) - 6,
                     i.Y() + Fl.BoxDY(b) + FlDraw.Height() - FlDraw.Descent())
END Draw;

(* i8 shows i7's text, with its bytes outside ASCII in octal *)
PROCEDURE I7CB(w: Fl.Widget);
  VAR s: ARRAY 256 OF CHAR; buf: ARRAY 2048 OF CHAR; i: INTEGER; c: CHAR;
BEGIN
  w(FlInputs.Input).Value(s);
  buf[0] := 0X;
  i := 0;
  WHILE s[i] # 0X DO
    c := s[i];
    IF (c < " ") OR (c > 7EX) THEN
      OutStr.Char("\", buf);
      OutStr.Int(ORD(c) DIV 64, 0, buf);
      OutStr.Int(ORD(c) DIV 8 MOD 8, 0, buf);
      OutStr.Int(ORD(c) MOD 8, 0, buf)
    ELSE
      IF c = "\" THEN OutStr.Char("\", buf) END;
      OutStr.Char(c, buf)
    END;
    INC(i)
  END;
  i8.SetValue(buf)
END I7CB;

PROCEDURE PutHex(n: INTEGER; VAR s: ARRAY OF CHAR);
  VAR digits: ARRAY 17 OF CHAR;
BEGIN
  digits := "0123456789abcdef";
  OutStr.Char(digits[n MOD 16], s)
END PutHex;

PROCEDURE (d: UCharDropBox) Paste;
  VAR t: ARRAY 16 OF CHAR; buffer: ARRAY 200 OF CHAR; i, n, ucode: INTEGER;
BEGIN
  Fl.EventText(t);
  ucode := FlUtf8.Decode(t, 0, n);
  IF n = 0 THEN d.SetValue(""); RETURN END;
  buffer[0] := 0X;
  FOR i := 0 TO n - 1 DO OutStr.Char(t[i], buffer) END;
  OutStr.Char(" ", buffer);
  FOR i := 0 TO n - 1 DO
    OutStr.String("\x", buffer);
    PutHex(ORD(t[i]) DIV 16, buffer);
    PutHex(ORD(t[i]), buffer)
  END;
  OutStr.String(" 0x", buffer);
  FOR i := 5 TO 0 BY -1 DO PutHex(SHORT(ASH(ucode, -4 * i)), buffer) END;
  d.SetValue(buffer)
END Paste;

PROCEDURE (d: UCharDropBox) Handle*(e: INTEGER): BOOLEAN;
BEGIN
  CASE e OF
    Fl.EvDndEnter, Fl.EvDndDrag, Fl.EvDndRelease: RETURN TRUE
  | Fl.EvPaste: d.Paste; RETURN TRUE
  ELSE RETURN d.Handle^(e)
  END
END Handle;

(* A number as strtoul reads it with base 0: decimal, 0x hexadecimal or 0 octal *)
PROCEDURE ParseNumber(s: ARRAY OF CHAR): INTEGER;
  VAR i, base, n, digit: INTEGER; done: BOOLEAN;
BEGIN
  i := 0; base := 10; n := 0;
  IF s[0] = "0" THEN
    IF (s[1] = "x") OR (s[1] = "X") THEN base := 16; i := 2 ELSE base := 8 END
  END;
  done := FALSE;
  WHILE ~done DO
    IF (s[i] >= "0") & (s[i] <= "9") THEN digit := ORD(s[i]) - ORD("0")
    ELSIF (s[i] >= "a") & (s[i] <= "f") THEN digit := ORD(s[i]) - ORD("a") + 10
    ELSIF (s[i] >= "A") & (s[i] <= "F") THEN digit := ORD(s[i]) - ORD("A") + 10
    ELSE digit := base
    END;
    IF digit >= base THEN done := TRUE ELSE n := n * base + digit; INC(i) END
  END;
  RETURN n
END ParseNumber;

(* Characters 16 * y on, in two inputs at the row *)
PROCEDURE Row(y, row: INTEGER);
  VAR buf: ARRAY 100 OF CHAR; bu: ARRAY 25 OF CHAR; one: ARRAY 8 OF CHAR;
      b: FlInputs.Input; x, o, l, k: INTEGER;
BEGIN
  o := 0;
  FOR x := 0 TO 15 DO
    l := FlUtf8.Encode(16 * y + x, one);
    FOR k := 0 TO l - 1 DO buf[o] := one[k]; INC(o) END
  END;
  buf[o] := 0X;
  bu := "0x";
  OutStr.Hex(y * 16, 6, bu);
  NEW(b); FlInputs.OpenInput(b, inputWidth + 10, row * 25, 80, 25, "");
  b.SetTextFont(Fl.Courier);
  b.SetValue(bu);
  NEW(b); FlInputs.OpenInput(b, inputWidth + 90, row * 25, 380, 25, "");
  b.SetTextFont(extraFont);
  b.SetValue(buf)
END Row;

PROCEDURE Rows;
  VAR y, off, endList: INTEGER; bx: Fl.Box; arg: ARRAY 40 OF CHAR;
BEGIN
  off := 2;
  endList := 10000H DIV 16;
  IF Args.argc > 1 THEN
    Args.Get(1, arg);
    off := ParseNumber(arg);
    endList := off + 10000H;
    off := off DIV 16;
    endList := endList DIV 16
  END;
  y := off;
  WHILE y < endList DO
    (* skip Unicode space reserved for surrogate pairs (U+D800 ... U+DFFF) *)
    IF y = 0D80H THEN
      NEW(bx); Fl.OpenBox(bx, inputWidth + 10, (y - off) * 25, 460, 25, "U+D800 … U+DFFF: UTF-16 surrogate pairs");
      bx.SetColor(Fl.Lighter(Fl.Yellow));
      bx.SetBoxType(Fl.DownBox);
      bx.SetAlign(Fl.AlignInside + Fl.AlignLeft);
      y := 0E00H;
      INC(off, 127)
    END;
    IF y < endList THEN Row(y, y - off) END;
    INC(y)
  END
END Rows;

PROCEDURE AddInput(y, h, size: INTEGER; s: ARRAY OF CHAR);
  VAR i: FlInputs.Input;
BEGIN
  NEW(i); FlInputs.OpenInput(i, 5, y, inputWidth, h, "");
  i.SetValue(s);
  IF size > 0 THEN i.SetTextFont(extraFont); i.SetTextSize(size) END
END AddInput;

PROCEDURE AddCase(y: INTEGER; s: ARRAY OF CHAR; upper: BOOLEAN);
  VAR to: ARRAY 200 OF CHAR; n: INTEGER;
BEGIN
  IF upper THEN n := FlUtf8.ToUpper(s, to) ELSE n := FlUtf8.ToLower(s, to) END;
  AddInput(y, 25, 0, to)
END AddCase;

(* The n characters of ucs as UTF-8 *)
PROCEDURE FromCodes(ucs: ARRAY OF INTEGER; n: INTEGER; VAR s: ARRAY OF CHAR);
  VAR one: ARRAY 8 OF CHAR; i, k, l, o: INTEGER;
BEGIN
  o := 0;
  FOR i := 0 TO n - 1 DO
    l := FlUtf8.Encode(ucs[i], one);
    FOR k := 0 TO l - 1 DO s[o] := one[k]; INC(o) END
  END;
  s[o] := 0X
END FromCodes;

PROCEDURE AddRightLeft(y: INTEGER; s: ARRAY OF CHAR);
BEGIN
  NEW(right); FlInputs.OpenInput(right, 5, y, inputWidth, 50, "");
  right.SetTextFont(extraFont);
  right.SetTextSize(30);
  right.SetValue(s)
END AddRightLeft;

PROCEDURE SetCodes;
  VAR i: INTEGER;
BEGIN
  arabic[0] := 1610; arabic[1] := 1608; arabic[2] := 1606; arabic[3] := 1604;
  arabic[4] := 1603; arabic[5] := 1608; arabic[6] := 1583;
  FOR i := 0 TO 6 DO spaced[2 * i] := arabic[i]; IF i < 6 THEN spaced[2 * i + 1] := 20H END END
END SetCodes;

BEGIN
  SetCodes;
  Fl.SetFont(extraFont, "-*-*-*-*-*-*-*-*-*-*-*-*-iso10646-1");

  NEW(win); Fl.OpenDoubleWindow(win, windowWidth, windowHeight, "Unicode Display Test");
  AddInput(5, 25, 0, "ABCabcàèéïßîöüã123😄👍.");
  NEW(scroll); FlLayout.OpenScroll(scroll, inputWidth + 10, 0, 5 * 75, windowHeight, "");
  Rows;
  scroll.End;
  win.SetResizable(scroll);

  AddCase(35, "ABCabcàèéïßîöüã123😄👍.", FALSE);
  AddCase(65, "ABCabcàèéïßîöüã123😄👍.", TRUE);
  AddInput(90, 25, 14, "\->ê=ê");

  FromCodes(arabic, 7, text);
  AddRightLeft(115, text);

  NEW(i7); FlInputs.OpenInput(i7, 5, 230, inputWidth, 25, "");
  NEW(i8); FlInputs.OpenInput(i8, 5, 260, inputWidth, 25, "");
  i7.action := I7CB;
  i7.SetTextSize(20);
  i7.SetValue(text);
  i7.SetWhen(Fl.WhenChanged);

  FromCodes(spaced, 13, text);
  AddRightLeft(175, text);

  NEW(dropBox); FlInputs.OpenOutput(dropBox, 5, 300, inputWidth, 30, "");
  dropBox.SetTextSize(16);
  dropBox.SetValue("unichar drop box");

  (* Greg Ercolano's Japanese test sequence: "Do nothing." *)
  NEW(o9); FlInputs.OpenOutput(o9, 5, 330, inputWidth, 45, "");
  o9.SetTextFont(extraFont);
  o9.SetTextSize(30);
  o9.SetValue("何も行る。");

  win.End;
  FlDraw.SetStatus(0, 370, 100, 30);
  Fl.GetSystemColors;
  win.Show;
  Fl.Run
END Utf8Test.
