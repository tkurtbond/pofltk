MODULE Offscreen; (* FLTK's test/offscreen.cxx: lines drawn on an offscreen picture bigger than the window, which the mouse drags *)

(* FLTK's picks its lines with rand(), seeded by the time. poc has no
   rand, so this has its own generator, with a fixed seed. *)

IMPORT Fl, FlDraw;

CONST
  offscreenSize = 1000;
  winSize = 512;
  firstUsefulColor = 56;
  lastUsefulColor = 255;
  numIterations = 300;
  maxLineWidth = 9;
  deltaTime = 0.1D0;

TYPE
  OscrBox = POINTER TO RECORD (Fl.BoxDesc)
    oscr: FlDraw.Offscreen;  (* NIL until first drawn *)
    x1, y1: INTEGER;         (* drag start *)
    dragging: BOOLEAN;
    pageX, pageY: INTEGER;   (* top left of the view *)
    iters: INTEGER;          (* lines since the picture was cleared *)
    icol: INTEGER;           (* the last line's color *)
    ox, oy: INTEGER;         (* the last line's end *)
    scale: LONGREAL          (* the screen's scale, which the picture has *)
  END;

  Anim = POINTER TO RECORD (Fl.TimerDesc) END;

VAR
  win: Fl.DoubleWindow;
  box: OscrBox;
  anim: Anim;
  seed: LONGINT;

(* A number from 0 to v - 1: a linear congruential generator's. *)
PROCEDURE Random(v: INTEGER): INTEGER;
BEGIN
  seed := (seed * 1103515245 + 12345) MOD 80000000H;
  RETURN SHORT(seed DIV 100H MOD v)
END Random;

(* The scale of the window's screen. *)
PROCEDURE Scale(): LONGREAL;
BEGIN RETURN Fl.ScreenScale(Fl.ScreenAt(win.X(), win.Y()))
END Scale;

PROCEDURE (b: OscrBox) Draw*;
BEGIN
  FlDraw.SetColor(Fl.GrayRamp(19));  (* a light gray background *)
  FlDraw.RectF(b.X(), b.Y(), b.W(), b.H());

  IF b.oscr # NIL THEN
    IF b.scale # Scale() THEN
      b.oscr.Rescale;
      b.scale := Scale()
    END;
    b.oscr.Copy(b.X(), b.Y(), b.W(), b.H(), b.pageX, b.pageY)
  ELSE
    win.MakeCurrent;
    NEW(b.oscr); FlDraw.OpenOffscreen(b.oscr, offscreenSize, offscreenSize);
    b.scale := Scale()
  END
END Draw;

(* n kept between lo and hi. *)
PROCEDURE Clamp(n, lo, hi: INTEGER): INTEGER;
BEGIN
  IF n < lo THEN RETURN lo ELSIF n > hi THEN RETURN hi ELSE RETURN n END
END Clamp;

(* Drags the view, once there is a picture. *)
PROCEDURE (b: OscrBox) Handle*(e: INTEGER): BOOLEAN;
  VAR used: BOOLEAN; x2, y2: INTEGER;
BEGIN
  used := b.Handle^(e);
  IF b.oscr # NIL THEN
    IF e = Fl.EvEnter THEN win.SetCursor(Fl.CursorMove); used := TRUE
    ELSIF e = Fl.EvLeave THEN win.SetCursor(Fl.CursorDefault); used := TRUE
    ELSIF e = Fl.EvPush THEN
      b.x1 := Fl.EventXRoot(); b.y1 := Fl.EventYRoot();
      b.dragging := TRUE; used := TRUE
    ELSIF e = Fl.EvDrag THEN
      IF b.dragging THEN
        x2 := Fl.EventXRoot(); y2 := Fl.EventYRoot();
        b.pageX := Clamp(b.pageX + b.x1 - x2, -b.W(), offscreenSize);
        b.pageY := Clamp(b.pageY + b.y1 - y2, -b.H(), offscreenSize);
        b.x1 := x2; b.y1 := y2;
        b.Redraw
      END;
      used := TRUE
    ELSIF e = Fl.EvRelease THEN b.dragging := FALSE; used := TRUE
    END
  END;
  RETURN used
END Handle;

(* One more line on the picture. *)
PROCEDURE (b: OscrBox) OscrDrawing;
  VAR ex, ey: INTEGER;
BEGIN
  IF b.oscr = NIL THEN RETURN END;
  b.oscr.Begin;
  IF b.iters > numIterations THEN  (* start afresh *)
    FlDraw.SetColor(Fl.White);
    FlDraw.RectF(0, 0, offscreenSize, offscreenSize);
    b.iters := 0
  END;
  INC(b.iters);
  INC(b.icol);
  IF b.icol > lastUsefulColor THEN b.icol := firstUsefulColor END;
  FlDraw.SetColor(b.icol);
  ex := Random(offscreenSize); ey := Random(offscreenSize);
  FlDraw.LineStyle(FlDraw.Solid, Random(maxLineWidth));
  FlDraw.Line(b.ox, b.oy, ex, ey);
  b.ox := ex; b.oy := ey;
  FlDraw.LineStyle(FlDraw.Solid, 0);
  b.oscr.End;
  b.Redraw
END OscrDrawing;

PROCEDURE (a: Anim) Fire*;
BEGIN
  box.OscrDrawing;
  Fl.RepeatTimeout(a, deltaTime)
END Fire;

BEGIN
  seed := 1;
  NEW(win); Fl.OpenDoubleWindow(win, winSize, winSize, "Offscreen demo");
  NEW(box); Fl.OpenBox(box, 5, 5, winSize - 10, winSize - 10, "");
  box.oscr := NIL; box.dragging := FALSE;
  box.pageX := (offscreenSize - winSize) DIV 2; box.pageY := box.pageX;
  box.iters := numIterations + 1;
  box.icol := firstUsefulColor;
  box.ox := offscreenSize DIV 2; box.oy := offscreenSize DIV 2;
  win.End;
  win.SetResizable(box);
  win.ShowArgs;
  NEW(anim); Fl.AddTimeout(anim, deltaTime);
  Fl.Run
END Offscreen.
