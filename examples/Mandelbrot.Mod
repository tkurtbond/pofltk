MODULE Mandelbrot;  (* FLTK's test/mandelbrot.cxx: the Mandelbrot set and its Julia sets, drawn a line at a time when idle *)

IMPORT SYSTEM, Fl, FlButtons, FlDraw, FlImages, FlInputs, FlPrint, FlValuators, InStr, OutStr, RealDigits;

CONST
  maxBrightness = 16;
  defaultBrightness = 16;
  maxIterations = 14;
  defaultIterations = 7;
  paletteSize = 256;

TYPE
  Action = PROCEDURE (w: Fl.Widget);

  DrawingWindow = POINTER TO DrawingWindowDesc;

  DrawingArea = POINTER TO RECORD (Fl.BoxDesc)
    win: DrawingWindow;
    buffer: POINTER TO ARRAY OF CHAR;
    useColors, julia: BOOLEAN;
    cw, ch: INTEGER;  (* the picture's size *)
    dx, dy, dw, dh: INTEGER;  (* drawing box offsets *)
    nextline, drawn, iterations, brightness: INTEGER;
    jX, jY, cx, cy, scale: LONGREAL;
    sx, sy, sw, sh: INTEGER  (* selection box *)
  END;

  DrawingWindowDesc = RECORD (Fl.WindowDesc)
    d: DrawingArea;
    xInput, yInput, wInput: FlInputs.FloatInput
  END;

VAR
  palette: ARRAY paletteSize OF INTEGER;
  mbrot, jbrot: DrawingWindow;
  idle: Fl.Idle;
  ix, iy, button: INTEGER;  (* where a drag started, and its button *)
  dragged: BOOLEAN;
  args: INTEGER;
  done: BOOLEAN;

PROCEDURE Hex(ch: CHAR): INTEGER;
BEGIN
  IF ch >= "A" THEN RETURN ORD(ch) - ORD("A") + 10 ELSE RETURN ORD(ch) - ORD("0") END
END Hex;

(* From the entry first on, the colors in s, six hexadecimal digits each *)
PROCEDURE Pal(first: INTEGER; s: ARRAY OF CHAR);
  VAR i, j, c: INTEGER;
BEGIN
  i := 0;
  WHILE s[i] # 0X DO
    c := 0;
    FOR j := 0 TO 5 DO c := c * 16 + Hex(s[i + j]) END;
    palette[first] := c;
    INC(first); INC(i, 6)
  END
END Pal;

(* v as "%.<decimals>f" writes it, with a "+" too if plus, from
   RealDigits' exact digits, rounded as printf rounds them. *)
PROCEDURE Fixed(v: LONGREAL; decimals: INTEGER; plus: BOOLEAN; VAR s: ARRAY OF CHAR);
  VAR d: ARRAY 40 OF CHAR; count, e, p: INTEGER;
BEGIN
  s[0] := 0X;
  IF SYSTEM.VAL(HUGEINT, v) < 0 THEN OutStr.Char("-", s); v := -v
  ELSIF plus THEN OutStr.Char("+", s)
  END;
  IF v = 0.0D0 THEN count := 0; e := 0 ELSE RealDigits.Fixed(v, decimals, 30, d, count, e) END;
  p := e; IF p < 0 THEN p := 0 END;
  WHILE p >= -decimals DO
    IF (e - p >= 0) & (e - p < count) THEN OutStr.Char(d[e - p], s) ELSE OutStr.Char("0", s) END;
    IF (p = 0) & (decimals > 0) THEN OutStr.Char(".", s) END;
    DEC(p)
  END
END Fixed;

(* v as "%.2g" writes it *)
PROCEDURE General(v: LONGREAL; VAR s: ARRAY OF CHAR);
  VAR d: ARRAY 4 OF CHAR; e: INTEGER; magnitude: LONGREAL;
BEGIN
  magnitude := ABS(v);
  IF magnitude = 0.0D0 THEN COPY("0", s); RETURN END;
  RealDigits.Digits(magnitude, 2, d, e);
  IF (e < -4) OR (e >= 2) THEN
    s[0] := 0X;
    IF v < 0.0D0 THEN OutStr.Char("-", s) END;
    OutStr.Char(d[0], s);
    IF d[1] # "0" THEN OutStr.Char(".", s); OutStr.Char(d[1], s) END;
    OutStr.Char("e", s);
    IF e < 0 THEN OutStr.Char("-", s); e := -e ELSE OutStr.Char("+", s) END;
    IF e < 10 THEN OutStr.Char("0", s) END;
    OutStr.Int(e, 0, s)
  ELSE
    IF d[1] = "0" THEN Fixed(v, -e, FALSE, s) ELSE Fixed(v, 1 - e, FALSE, s) END
  END
END General;

(* The number at the start of the input's text, as atof reads it: 0 if none *)
PROCEDURE Number(i: FlInputs.FloatInput): LONGREAL;
  VAR s: ARRAY 128 OF CHAR; x: LONGREAL; pos: LONGINT;
BEGIN
  i.Value(s);
  pos := 0; x := 0.0D0;
  InStr.LongReal(x, s, pos);
  IF ~InStr.Done THEN x := 0.0D0 END;
  RETURN x
END Number;

PROCEDURE WindowOf(w: Fl.Widget): DrawingWindow;
  VAR g: Fl.Group;
BEGIN g := w.Parent(); RETURN g(DrawingWindow)
END WindowOf;

PROCEDURE (win: DrawingWindow) UpdateLabel;
  VAR s: ARRAY 128 OF CHAR;
BEGIN
  Fixed(win.d.cx, 10, TRUE, s); win.xInput.SetValue(s);
  Fixed(win.d.cy, 10, TRUE, s); win.yInput.SetValue(s);
  General(win.d.scale, s); win.wInput.SetValue(s)
END UpdateLabel;

PROCEDURE (a: DrawingArea) NewDisplay;
BEGIN
  a.drawn := 0; a.nextline := 0;
  Fl.AddIdle(idle)
END NewDisplay;

PROCEDURE (a: DrawingArea) NewBuffer;
BEGIN
  IF a.buffer # NIL THEN a.buffer := NIL; a.NewDisplay END
END NewBuffer;

PROCEDURE (a: DrawingArea) EraseBox;
BEGIN
  a.win.MakeCurrent;
  FlDraw.OverlayClear
END EraseBox;

PROCEDURE (a: DrawingArea) Draw*;
BEGIN
  IF a.dx = 0 THEN
    a.dx := Fl.BoxDX(a.BoxType());
    a.dy := Fl.BoxDY(a.BoxType());
    a.dw := Fl.BoxDW(a.BoxType());
    a.dh := Fl.BoxDH(a.BoxType());
    DEC(a.cw, a.dw);
    DEC(a.ch, a.dh)
  END;
  a.DrawBox;
  a.drawn := 0;
  Fl.AddIdle(idle)
END Draw;

PROCEDURE (a: DrawingArea) Resize*(x, y, w, h: INTEGER);
BEGIN
  IF (w # a.W()) OR (h # a.H()) THEN
    a.cw := w - a.dw;
    a.ch := h - a.dh;
    a.NewBuffer
  END;
  a.Resize^(x, y, w, h)
END Resize;

(* The value (0 to 1) of a point that escaped, as a color at p *)
PROCEDURE (a: DrawingArea) PutColor(t: REAL; p: INTEGER);
  VAR c: INTEGER;
BEGIN
  c := palette[ENTIER((1.0 - t) * paletteSize) MOD paletteSize];
  a.buffer[p] := CHR(c DIV 10000H);
  a.buffer[p + 1] := CHR(c DIV 100H MOD 100H);
  a.buffer[p + 2] := CHR(c MOD 100H)
END PutColor;

(* Computes the line a.nextline *)
PROCEDURE (a: DrawingArea) ComputeLine(linebytes: INTEGER);
  VAR xi, i, n, p: INTEGER; xx, yy, yi, wx, wy, t: LONGREAL; escaped: BOOLEAN;
BEGIN
  IF a.buffer = NIL THEN NEW(a.buffer, linebytes * a.ch) END;
  yy := a.cy + (a.ch DIV 2 - a.nextline) * a.scale / a.cw;
  yi := yy;
  IF a.julia THEN yy := a.jY END;
  p := a.nextline * linebytes;
  FOR xi := 0 TO a.cw - 1 DO
    xx := a.cx + (xi - a.cw DIV 2) * a.scale / a.cw;
    wx := xx; wy := yi;
    IF a.julia THEN xx := a.jX END;
    i := 0; escaped := FALSE;
    WHILE (i < a.iterations) & ~escaped DO
      t := wx * wx - wy * wy + xx;
      wy := 2 * wx * wy + yy;
      wx := t;
      IF wx * wx + wy * wy > 4 THEN
        escaped := TRUE;
        t := 1 - i / 1024.0D0;
        wx := t;
        IF t <= 0 THEN t := 0
        ELSE
          FOR n := 1 TO a.brightness DO t := t * wx END
        END;
        IF a.useColors THEN a.PutColor(SHORT(t), p)
        ELSE a.buffer[p] := CHR(255 - ENTIER(254 * t))
        END
      END;
      INC(i)
    END;
    IF ~escaped THEN
      a.buffer[p] := 0X;
      IF a.useColors THEN a.buffer[p + 1] := 0X; a.buffer[p + 2] := 0X END
    END;
    IF a.useColors THEN INC(p, 3) ELSE INC(p) END
  END;
  INC(a.nextline)
END ComputeLine;

(* Draws a line computed, or computes one: FALSE when there is no more to do *)
PROCEDURE (a: DrawingArea) IdleStep(): BOOLEAN;
  VAR yy, linebytes: INTEGER;
BEGIN
  IF ~a.win.Visible() THEN RETURN FALSE END;
  IF a.drawn < a.nextline THEN
    a.win.MakeCurrent;
    yy := a.drawn + a.Y() + a.dy;
    IF (yy >= a.sy) & (yy <= a.sy + a.sh) THEN a.EraseBox END;
    IF a.useColors THEN
      FlDraw.DrawImage(a.buffer^, a.drawn * a.cw * 3, a.X() + a.dx, yy, a.cw, 1, 3, 0)
    ELSE
      FlDraw.DrawImageMono(a.buffer^, a.drawn * a.cw, a.X() + a.dx, yy, a.cw, 1, 1, a.cw)
    END;
    INC(a.drawn);
    RETURN TRUE
  END;
  IF a.useColors THEN linebytes := a.cw * 3 ELSE linebytes := a.cw END;
  IF a.nextline < a.ch THEN
    a.ComputeLine(linebytes);
    RETURN a.nextline <= a.ch
  END;
  RETURN FALSE
END IdleStep;

PROCEDURE RunIdle(i: Fl.Idle);
BEGIN
  IF ~mbrot.d.IdleStep() & ~((jbrot # NIL) & jbrot.d.IdleStep()) THEN Fl.RemoveIdle(i) END
END RunIdle;

PROCEDURE XInputCB(w: Fl.Widget);
  VAR win: DrawingWindow;
BEGIN win := WindowOf(w); win.d.cx := Number(w(FlInputs.FloatInput)); win.d.NewDisplay
END XInputCB;

PROCEDURE YInputCB(w: Fl.Widget);
  VAR win: DrawingWindow;
BEGIN win := WindowOf(w); win.d.cy := Number(w(FlInputs.FloatInput)); win.d.NewDisplay
END YInputCB;

PROCEDURE WInputCB(w: Fl.Widget);
  VAR win: DrawingWindow;
BEGIN win := WindowOf(w); win.d.scale := Number(w(FlInputs.FloatInput)); win.d.NewDisplay
END WInputCB;

PROCEDURE BrightnessCB(w: Fl.Widget);
  VAR win: DrawingWindow;
BEGIN
  win := WindowOf(w);
  win.d.brightness := SHORT(ENTIER(w(FlValuators.Slider).Value()));
  win.d.NewDisplay
END BrightnessCB;

PROCEDURE IterationsCB(w: Fl.Widget);
  VAR win: DrawingWindow;
BEGIN
  win := WindowOf(w);
  win.d.iterations := SHORT(ASH(1, ENTIER(w(FlValuators.Slider).Value())));
  win.d.NewDisplay
END IterationsCB;

PROCEDURE CoordinateInput(i: FlInputs.FloatInput; x, w: INTEGER; label: ARRAY OF CHAR; cb: Action);
BEGIN
  FlInputs.OpenFloatInput(i, x, 15, w, 30, label);
  i.SetBoxType(Fl.ThinDownBox);
  i.SetColor(48);
  i.SetSelectionColor(Fl.Background2Color);
  i.SetLabelFont(Fl.TimesBoldItalic);
  i.SetLabelSize(16);
  i.SetTextFont(Fl.TimesBoldItalic);
  i.SetTextSize(12);
  i.action := cb;
  i.SetWhen(Fl.WhenEnterKey + Fl.WhenRelease)
END CoordinateInput;

PROCEDURE ControlSlider(y: INTEGER; label: ARRAY OF CHAR; min, max, value: INTEGER; cb: Action);
  VAR s: FlValuators.Slider;
BEGIN
  NEW(s); FlValuators.OpenHorSlider(s, 80, y, 160, 15, label);
  s.SetBoxType(Fl.ThinDownBox);
  s.SetLabelSize(10);
  s.SetStep(1.0D0);
  s.SetSliderSize(0.1D0);
  s.action := cb;
  s.SetAlign(Fl.AlignLeft);
  s.SetBounds(min, max);
  s.SetValue(value);
  s.SetSliderBox(Fl.UpBox)
END ControlSlider;

PROCEDURE MakeWindow(VAR win: DrawingWindow);
  VAR a: DrawingArea; help: Fl.Box; text: ARRAY 100 OF CHAR; i: INTEGER;
BEGIN
  NEW(win); Fl.OpenWindow(win, 450, 520, "");
  NEW(a); Fl.OpenBox(a, 20, 80, 410, 430, "");
  a.win := win; win.d := a;
  a.cw := 410; a.ch := 430;
  a.scale := 4.0D0;
  a.iterations := SHORT(ASH(1, defaultIterations));
  a.brightness := defaultBrightness;
  a.SetBoxType(Fl.DownBox);
  a.SetColor(Fl.ForegroundColor);
  a.SetSelectionColor(Fl.Dark1);
  win.SetResizable(a);
  NEW(win.xInput); CoordinateInput(win.xInput, 30, 125, "x:", XInputCB);
  NEW(win.yInput); CoordinateInput(win.yInput, 175, 125, "y:", YInputCB);
  NEW(win.wInput); CoordinateInput(win.wInput, 325, 105, "w:", WInputCB);
  ControlSlider(50, "brightness:", 0, maxBrightness, a.brightness, BrightnessCB);
  text := "left click: zoom out, drag: zoom in?right click: Julia set, ctrl-M: mode, ctrl-P: Print";
  i := 0; WHILE text[i] # "?" DO INC(i) END; text[i] := 0AX;
  NEW(help); Fl.OpenBox(help, 240, 50, 190, 30, text);
  help.SetLabelSize(8);
  help.SetAlign(Fl.AlignRight + Fl.AlignInside);
  ControlSlider(65, "iterations:", 1, maxIterations, defaultIterations, IterationsCB);
  win.SizeRange(220, 220, 0, 0);
  win.End
END MakeWindow;

PROCEDURE (a: DrawingArea) ShowJulia;
  VAR s, n: ARRAY 128 OF CHAR;
BEGIN
  IF jbrot = NIL THEN
    MakeWindow(jbrot);
    jbrot.d.julia := TRUE;
    jbrot.d.cx := 0.0D0;
    jbrot.d.cy := 0.0D0;
    jbrot.d.scale := 4.0D0;
    jbrot.d.useColors := mbrot.d.useColors;
    jbrot.UpdateLabel
  END;
  jbrot.d.jX := a.cx + (ix - a.X() - a.cw DIV 2) * a.scale / a.cw;
  jbrot.d.jY := a.cy + (a.ch DIV 2 - iy + a.Y()) * a.scale / a.cw;
  s := "Julia ";
  Fixed(jbrot.d.jX, 7, FALSE, n); OutStr.String(n, s);
  OutStr.Char(" ", s);
  Fixed(jbrot.d.jY, 7, FALSE, n); OutStr.String(n, s);
  jbrot.SetLabel(s);
  jbrot.Show;
  jbrot.d.NewDisplay
END ShowJulia;

PROCEDURE (a: DrawingArea) Clamp(VAR x, y: INTEGER);
BEGIN
  x := Fl.EventX();
  IF x < a.X() THEN x := a.X() END;
  IF x >= a.X() + a.W() THEN x := a.X() + a.W() - 1 END;
  y := Fl.EventY();
  IF y < a.Y() THEN y := a.Y() END;
  IF y >= a.Y() + a.H() THEN y := a.Y() + a.H() - 1 END
END Clamp;

(* The left button let go *)
PROCEDURE (a: DrawingArea) Zoom;
BEGIN
  a.EraseBox;
  IF dragged & (a.sw > 3) & (a.sh > 3) THEN
    a.cx := a.cx + (a.sx + a.sw DIV 2 - a.X() - a.cw DIV 2) * a.scale / a.cw;
    a.cy := a.cy + (-a.sy - a.sh DIV 2 + a.Y() + a.ch DIV 2) * a.scale / a.cw;
    a.scale := a.sw * a.scale / a.cw
  ELSIF ~dragged THEN
    a.scale := 2 * a.scale;
    IF a.julia THEN
      IF a.scale >= 4 THEN
        a.scale := 4.0D0;
        a.cx := 0.0D0; a.cy := 0.0D0
      END
    ELSIF a.scale >= 2.5D0 THEN
      a.scale := 2.5D0;
      a.cx := -0.75D0;
      a.cy := 0.0D0
    END
  ELSE
    RETURN
  END;
  a.win.UpdateLabel;
  a.NewDisplay
END Zoom;

PROCEDURE (a: DrawingArea) Handle*(e: INTEGER): BOOLEAN;
  VAR x2, y2: INTEGER;
BEGIN
  CASE e OF
    Fl.EvPush:
      a.EraseBox;
      a.Clamp(ix, iy);
      dragged := FALSE;
      button := Fl.EventButton();
      RETURN TRUE
  | Fl.EvDrag:
      dragged := TRUE;
      a.EraseBox;
      a.Clamp(x2, y2);
      IF button # Fl.LeftMouse THEN ix := x2; iy := y2; RETURN TRUE END;
      IF ix < x2 THEN a.sx := ix; a.sw := x2 - ix ELSE a.sx := x2; a.sw := ix - x2 END;
      IF iy < y2 THEN a.sy := iy; a.sh := y2 - iy ELSE a.sy := y2; a.sh := iy - y2 END;
      a.win.MakeCurrent;
      FlDraw.OverlayRect(a.sx, a.sy, a.sw, a.sh);
      RETURN TRUE
  | Fl.EvRelease:
      IF button = Fl.LeftMouse THEN a.Zoom
      ELSIF ~a.julia THEN a.ShowJulia
      END;
      RETURN TRUE
  ELSE
    RETURN FALSE
  END
END Handle;

PROCEDURE Print(w: Fl.Widget);
  VAR printer: FlPrint.Printer; image: FlImages.Image; win: DrawingWindow;
BEGIN
  win := WindowOf(w);
  IF win.Visible() & FlPrint.Available() THEN
    win.MakeCurrent;
    NEW(image);
    IF FlImages.ReadImage(image, 0, 0, win.W(), win.H(), FALSE) THEN
      NEW(printer); FlPrint.OpenPrinter(printer);
      IF printer.BeginJob(1) = 0 THEN
        printer.BeginPage;
        printer.Scale(0.7D0, 0.7D0);
        image.Draw(0, 0);
        printer.EndPage;
        IF printer.EndJob() THEN END
      END;
      printer.Close;
      image.Close
    END
  END
END Print;

PROCEDURE ToggleColor(w: Fl.Widget);
BEGIN
  mbrot.d.useColors := ~mbrot.d.useColors;
  mbrot.d.NewBuffer;
  IF jbrot # NIL THEN
    jbrot.d.useColors := mbrot.d.useColors;
    jbrot.d.NewBuffer
  END
END ToggleColor;

PROCEDURE Quit(w: Fl.Widget);
BEGIN HALT(0)
END Quit;

PROCEDURE ShortcutButton(key: CHAR; cb: Action);
  VAR b: FlButtons.Button;
BEGIN
  NEW(b); FlButtons.OpenButton(b, 0, 0, 0, 0, "");
  b.action := cb;
  b.SetShortcut(ORD(key), Fl.Ctrl)
END ShortcutButton;

BEGIN
  Pal(0, "CC0000CA0002C90004C70006C60008C4000AC3000CC1000EBF0010BE0012");
  Pal(10, "BC0014BB0016B90018B8001AB6001BB4001DB3001FB10021B00023AE0025");
  Pal(20, "AD0027AB0029A9002BA8002DA6002FA50031A30033A20035A000379E0039");
  Pal(30, "9D003B9B003D9A003F98004197004395004594004792004990004B8F004D");
  Pal(40, "8D004E8C00508A005289005487005685005884005A82005C81005E7F0060");
  Pal(50, "7E00627C00647A006679006877006A76006C74006E7300707100726F0074");
  Pal(60, "6E00766C00786B007A69007C68007E660080640081630083610085600087");
  Pal(70, "5E00895D008B5B008D59008F58009156009355009553009752009950009B");
  Pal(80, "4E009D4D009F4B00A14A00A34800A54700A74500A94300AB4200AD4000AF");
  Pal(90, "3F00B13D00B33C00B43A00B63800B83700BA3500BC3400BE3200C03100C2");
  Pal(100, "2F00C42E00C62C00C82A00CA2900CC2700CE2600D02400D22300D42100D6");
  Pal(110, "1F00D81E00DA1C00DC1B00DE1900E01800E21600E41400E61300E71100E9");
  Pal(120, "1000EB0E00ED0D00EF0B00F10900F30800F50600F70500F90300FB0200FD");
  Pal(130, "0000FF0202FD0404FB0606F90808F70A0AF50C0CF30E0EF11010EF1212ED");
  Pal(140, "1414EB1616E91818E71A1AE61B1BE41D1DE21F1FE02121DE2323DC2525DA");
  Pal(150, "2727D82929D62B2BD42D2DD22F2FD03131CE3333CC3535CA3737C83939C6");
  Pal(160, "3B3BC43D3DC23F3FC04141BE4343BC4545BA4747B84949B64B4BB44D4DB3");
  Pal(170, "4E4EB15050AF5252AD5454AB5656A95858A75A5AA55C5CA35E5EA160609F");
  Pal(180, "62629D64649B6666996868976A6A956C6C936E6E9170708F72728D74748B");
  Pal(190, "7676897878877A7A857C7C837E7E8180808081817E83837C85857A878778");
  Pal(200, "8989768B8B748D8D728F8F7091916E93936C95956A9797689999669B9B64");
  Pal(210, "9D9D629F9F60A1A15EA3A35CA5A55AA7A758A9A956ABAB54ADAD52AFAF50");
  Pal(220, "B1B14EB3B34DB4B44BB6B649B8B847BABA45BCBC43BEBE41C0C03FC2C23D");
  Pal(230, "C4C43BC6C639C8C837CACA35CCCC33CECE31D0D02FD2D22DD4D42BD6D629");
  Pal(240, "D8D827DADA25DCDC23DEDE21E0E01FE2E21DE4E41BE6E61AE7E718E9E916");
  Pal(250, "EBEB14EFEF10F3F30CF7F708FBFB04FFFF00");
  NEW(idle); idle.action := RunIdle;
  MakeWindow(mbrot);
  mbrot.Begin;
  ShortcutButton("p", Print);
  ShortcutButton("m", ToggleColor);
  mbrot.End;
  mbrot.d.cx := -0.75D0;
  mbrot.d.scale := 2.5D0;
  mbrot.UpdateLabel;
  args := 1; done := Fl.ParseArgs(NIL, args);
  done := Fl.Visual(Fl.VisualRgb);
  mbrot.action := Quit;
  mbrot.ShowArgs;
  Fl.Run
END Mandelbrot.
