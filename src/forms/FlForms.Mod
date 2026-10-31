MODULE FlForms; (* FLTK's Forms compatibility classes: Timer, Free, FormsBitmap, FormsPixmap, FormsText *)

(* The classes of libfltk_forms, which FLTK keeps for programs written for
   the Forms library, and which a new program mostly doesn't need: Fl's
   timeouts do what a Timer does, a Widget's Draw and Handle what a Free
   does, and FlImages.SetImage what a FormsBitmap does. The rest of
   FL/forms.H, the C calls of old programs, isn't bound.

   This is a library of its own, pofltk-forms, so a program using only
   widgets isn't linked with libfltk_forms, and FLTK can be built without
   it. A program names both libraries' paths.

   The C++ part is FlForms.cpp. *)

IMPORT SYSTEM, Fl, FlImages;

CONST
(* BEGIN generated constants: tools/gen-constants.py writes this block,
   from FLTK's headers; edit the script, not the block. *)

  (* a Timer's kinds (OpenTimer) *)
  NormalTimer* = 0;
  ValueTimer* = 1;
  HiddenTimer* = 2;

  (* a Free's kinds (OpenFree) *)
  NormalFree* = 1;
  SleepingFree* = 2;
  InputFree* = 3;
  ContinuousFree* = 4;
  AllFree* = 5;

  (* the events a Free gets beside FLTK's own (Free.HandleFree) *)
  FreeDraw* = 100;
  FreeStep* = 101;
(* END generated constants *)

TYPE
  (* A clock counting a time down, shown or not, which calls back when it
     runs out. A shown one then blinks, until clicked. *)
  Timer* = POINTER TO TimerDesc;
  TimerDesc* = RECORD (Fl.WidgetDesc) END;

  (* A widget that hears everything through one method, HandleFree. *)
  Free* = POINTER TO FreeDesc;
  FreeDesc* = RECORD (Fl.WidgetDesc) END;

  (* A bitmap at a widget's top left, colored by the widget's color, with
     its box in the selection color. Black, with no box and its label
     below it, to start with. *)
  FormsBitmap* = POINTER TO FormsBitmapDesc;
  FormsBitmapDesc* = RECORD (Fl.WidgetDesc) END;

  (* A pixmap in a widget, as a FormsBitmap holds a bitmap. *)
  FormsPixmap* = POINTER TO FormsPixmapDesc;
  FormsPixmapDesc* = RECORD (Fl.WidgetDesc) END;

  (* A box whose label is always inside it: drawing it adds Fl.AlignInside
     to its alignment. Its label is at the left to start with, and it has
     no box. *)
  FormsText* = POINTER TO FormsTextDesc;
  FormsTextDesc* = RECORD (Fl.WidgetDesc) END;

  EventProc = PROCEDURE (self: SYSTEM.ADDRESS; event, x, y, key: SYSTEM.INT32): SYSTEM.INT32;

PROCEDURE ["C", "ofl_forms_register"] CRegister(event: EventProc);
PROCEDURE ["C", "ofl_forms_new"] CNew(class, type, x, y, w, h: SYSTEM.INT32; label: ARRAY OF CHAR; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_forms_show"] CShow(w, i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_timer_value"] CValue(t: SYSTEM.ADDRESS): LONGREAL;
PROCEDURE ["C", "ofl_timer_set_value"] CSetValue(t: SYSTEM.ADDRESS; v: LONGREAL);
PROCEDURE ["C", "ofl_timer_up"] CUp(t: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_timer_set_up"] CSetUp(t: SYSTEM.ADDRESS; on: SYSTEM.INT32);
PROCEDURE ["C", "ofl_timer_suspended"] CSuspended(t: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_timer_set_suspended"] CSetSuspended(t: SYSTEM.ADDRESS; on: SYSTEM.INT32);

PROCEDURE Int(b: BOOLEAN): SYSTEM.INT32;
BEGIN IF b THEN RETURN 1 END; RETURN 0
END Int;

(* Makes t a Timer of the kind, NormalTimer, ValueTimer or HiddenTimer,
   stopped. A HiddenTimer isn't shown. *)
PROCEDURE OpenTimer*(t: Timer; kind, x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN
  ASSERT((kind >= NormalTimer) & (kind <= HiddenTimer), Fl.IndexOutOfRange);
  Fl.EndOpen(t, CNew(0, kind, x, y, w, h, label, Fl.BeginOpen(t)))
END OpenTimer;

(* The seconds left. *)
PROCEDURE (t: Timer) Value*(): LONGREAL;
BEGIN RETURN CValue(Fl.Live(t))
END Value;

(* Starts t, at v seconds; at 0 or less it stops. *)
PROCEDURE (t: Timer) SetValue*(v: LONGREAL);
BEGIN CSetValue(Fl.Live(t), v)
END SetValue;

(* Whether a ValueTimer shows the time gone, not the time left, as it
   does to start with. *)
PROCEDURE (t: Timer) CountsUp*(): BOOLEAN;
BEGIN RETURN CUp(Fl.Live(t)) # 0
END CountsUp;

PROCEDURE (t: Timer) SetCountsUp*(on: BOOLEAN);
BEGIN CSetUp(Fl.Live(t), Int(on))
END SetCountsUp;

(* Whether t is stopped: suspended, or never started. *)
PROCEDURE (t: Timer) Suspended*(): BOOLEAN;
BEGIN RETURN CSuspended(Fl.Live(t)) # 0
END Suspended;

PROCEDURE (t: Timer) SetSuspended*(on: BOOLEAN);
BEGIN CSetSuspended(Fl.Live(t), Int(on))
END SetSuspended;

(* Makes f a Free of the kind: NormalFree; SleepingFree, inactive;
   InputFree, which takes the focus; ContinuousFree, which gets a FreeStep
   event 100 times a second, which isn't free; or AllFree, both. *)
PROCEDURE OpenFree*(f: Free; kind, x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN
  ASSERT((kind >= NormalFree) & (kind <= AllFree), Fl.IndexOutOfRange);
  Fl.EndOpen(f, CNew(1, kind, x, y, w, h, label, Fl.BeginOpen(f)))
END OpenFree;

(* What f does, for each event of FLTK's (Fl.EvPush and the rest) but the
   shortcuts, and FreeDraw, when it must draw itself as Draw would, and
   FreeStep. TRUE does its Callback. x and y are the mouse, and key is the
   key (Fl.EventKey), or a mouse event's button (Fl.EventButton); all are
   0 for FreeDraw, and key is for FreeStep. f takes every event it is
   sent: an event goes no further. *)
PROCEDURE (f: Free) HandleFree*(event, x, y, key: INTEGER): BOOLEAN;
BEGIN RETURN FALSE
END HandleFree;

PROCEDURE OpenFormsBitmap*(b: FormsBitmap; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Fl.EndOpen(b, CNew(2, 0, x, y, w, h, label, Fl.BeginOpen(b)))
END OpenFormsBitmap;

(* Shows i, a bitmap (FlImages.OpenBitmap, or a bitmap's file), or nothing
   if i is NIL. b keeps it, whatever becomes of i. An image of another
   sort halts (Fl.Unsupported). *)
PROCEDURE (b: FormsBitmap) SetBitmap*(i: FlImages.Image);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := 0; IF i # NIL THEN h := FlImages.ImageHandle(i) END;
  ASSERT(CShow(Fl.Live(b), h) # 0, Fl.Unsupported)
END SetBitmap;

PROCEDURE OpenFormsPixmap*(p: FormsPixmap; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Fl.EndOpen(p, CNew(3, 0, x, y, w, h, label, Fl.BeginOpen(p)))
END OpenFormsPixmap;

(* Shows i, a pixmap (FlImages.OpenXPM, or a file of XPM or GIF), or
   nothing if i is NIL. p keeps it, whatever becomes of i. An image of
   another sort halts (Fl.Unsupported). *)
PROCEDURE (p: FormsPixmap) SetPixmap*(i: FlImages.Image);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := 0; IF i # NIL THEN h := FlImages.ImageHandle(i) END;
  ASSERT(CShow(Fl.Live(p), h) # 0, Fl.Unsupported)
END SetPixmap;

PROCEDURE OpenFormsText*(t: FormsText; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN Fl.EndOpen(t, CNew(4, 0, x, y, w, h, label, Fl.BeginOpen(t)))
END OpenFormsText;

PROCEDURE EventD(self: SYSTEM.ADDRESS; event, x, y, key: SYSTEM.INT32): SYSTEM.INT32;
  VAR f: Free;
BEGIN f := SYSTEM.VAL(Free, self); RETURN Int(f.HandleFree(event, x, y, key))
END EventD;

BEGIN
  CRegister(EventD)
END FlForms.
