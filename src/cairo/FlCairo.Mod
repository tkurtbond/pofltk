MODULE FlCairo; (* A window drawn with cairo, and the part of cairo that FLTK's programs use *)

(* A CairoWindow is a double window whose DrawCairo draws on it with
   cairo, in the window's coordinates. DrawCairo comes after the window's
   box and widgets, so it draws over them, as part of the Draw it inherits:
   a program overriding Draw calls w.Draw^ to have it.

   It is given a Context, good for that call alone: one kept and used
   later halts with Fl.OutOfOrder. Each draw has a new one, so nothing set
   in it lasts. A call cairo refuses, such as a Restore with no Save or
   text that isn't UTF-8, makes the rest of the context's calls do
   nothing, and Ok FALSE; the next draw starts again.

   DrawCairo is for the display: on an FlImages or FlPrint surface a
   window shows its widgets without it, and to save what it drew, read
   the window back with FlImages.ReadImage.

   This isn't FLTK's Fl_Cairo_Window, which only an FLTK built for it has:
   it draws on any FLTK, on X11 and Wayland. It is a library of its own,
   pofltk-cairo, so a program using only widgets isn't linked with
   libcairo. A program names both libraries' paths.

   Cairo has hundreds of calls. This binds those of FLTK's programs, as
   FlDraw binds fl_draw.H, and a few as simple. The C++ part is
   FlCairo.cpp. *)

IMPORT SYSTEM, Fl;

CONST
(* BEGIN generated constants: tools/gen-constants.py writes this block,
   from FLTK's headers; edit the script, not the block. *)

  (* Context.SelectFontFace's slant *)
  SlantNormal* = 0;
  SlantItalic* = 1;
  SlantOblique* = 2;

  (* Context.SelectFontFace's weight *)
  WeightNormal* = 0;
  WeightBold* = 1;

  (* Context.SetAntialias's modes *)
  AntialiasDefault* = 0;
  AntialiasNone* = 1;
  AntialiasGray* = 2;
  AntialiasSubpixel* = 3;
  AntialiasFast* = 4;
  AntialiasGood* = 5;
  AntialiasBest* = 6;

  (* Pattern.SetExtend's modes *)
  ExtendNone* = 0;
  ExtendRepeat* = 1;
  ExtendReflect* = 2;
  ExtendPad* = 3;
(* END generated constants *)

TYPE
  CairoWindow* = POINTER TO CairoWindowDesc;
  CairoWindowDesc* = RECORD (Fl.DoubleWindowDesc) END;

  Context* = POINTER TO ContextDesc;
  ContextDesc = RECORD
    h: SYSTEM.ADDRESS   (* 0 once its draw is over *)
  END;

  (* A gradient, which a program closes when done with it. *)
  Pattern* = POINTER TO PatternDesc;
  PatternDesc = RECORD
    h: SYSTEM.ADDRESS   (* 0 once closed *)
  END;

  (* The size of some text in the current font (Context.GetTextExtents).
     The bearings run from where it is drawn to its top left; the advance
     is to where the next text would go. *)
  TextExtents* = RECORD
    xBearing*, yBearing*, width*, height*, xAdvance*, yAdvance*: LONGREAL
  END;

  DrawCairoProc = PROCEDURE (self, context: SYSTEM.ADDRESS);

PROCEDURE ["C", "ofl_cairo_register"] CRegister(draw: DrawCairoProc);
PROCEDURE ["C", "ofl_cairo_window_new"] CNew(placed, x, y, w, h: SYSTEM.INT32; label: ARRAY OF CHAR; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_cairo_status"] CStatus(c: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_cairo_save"] CSave(c: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_cairo_restore"] CRestore(c: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_cairo_translate"] CTranslate(c: SYSTEM.ADDRESS; x, y: LONGREAL);
PROCEDURE ["C", "ofl_cairo_scale"] CScale(c: SYSTEM.ADDRESS; x, y: LONGREAL);
PROCEDURE ["C", "ofl_cairo_rotate"] CRotate(c: SYSTEM.ADDRESS; angle: LONGREAL);
PROCEDURE ["C", "ofl_cairo_set_line_width"] CSetLineWidth(c: SYSTEM.ADDRESS; width: LONGREAL);
PROCEDURE ["C", "ofl_cairo_set_antialias"] CSetAntialias(c: SYSTEM.ADDRESS; mode: SYSTEM.INT32);
PROCEDURE ["C", "ofl_cairo_set_source_rgba"] CSetSourceRGBA(c: SYSTEM.ADDRESS; r, g, b, a: LONGREAL);
PROCEDURE ["C", "ofl_cairo_set_source"] CSetSource(c, p: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_cairo_new_path"] CNewPath(c: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_cairo_close_path"] CClosePath(c: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_cairo_move_to"] CMoveTo(c: SYSTEM.ADDRESS; x, y: LONGREAL);
PROCEDURE ["C", "ofl_cairo_line_to"] CLineTo(c: SYSTEM.ADDRESS; x, y: LONGREAL);
PROCEDURE ["C", "ofl_cairo_curve_to"] CCurveTo(c: SYSTEM.ADDRESS; x1, y1, x2, y2, x3, y3: LONGREAL);
PROCEDURE ["C", "ofl_cairo_rectangle"] CRectangle(c: SYSTEM.ADDRESS; x, y, w, h: LONGREAL);
PROCEDURE ["C", "ofl_cairo_arc"] CArc(c: SYSTEM.ADDRESS; x, y, radius, from, to: LONGREAL);
PROCEDURE ["C", "ofl_cairo_stroke"] CStroke(c: SYSTEM.ADDRESS; preserve: SYSTEM.INT32);
PROCEDURE ["C", "ofl_cairo_fill"] CFill(c: SYSTEM.ADDRESS; preserve: SYSTEM.INT32);
PROCEDURE ["C", "ofl_cairo_paint"] CPaint(c: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_cairo_clip"] CClip(c: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_cairo_select_font_face"] CSelectFontFace(c: SYSTEM.ADDRESS; family: ARRAY OF CHAR; slant, weight: SYSTEM.INT32);
PROCEDURE ["C", "ofl_cairo_set_font_size"] CSetFontSize(c: SYSTEM.ADDRESS; size: LONGREAL);
PROCEDURE ["C", "ofl_cairo_show_text"] CShowText(c: SYSTEM.ADDRESS; text: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_cairo_text_path"] CTextPath(c: SYSTEM.ADDRESS; text: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_cairo_text_extents"] CTextExtents(c: SYSTEM.ADDRESS; text: ARRAY OF CHAR; VAR xb, yb, w, h, xa, ya: LONGREAL);
PROCEDURE ["C", "ofl_cairo_linear"] CLinear(x0, y0, x1, y1: LONGREAL): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_cairo_radial"] CRadial(x0, y0, r0, x1, y1, r1: LONGREAL): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_cairo_add_color_stop"] CAddColorStop(p: SYSTEM.ADDRESS; offset, r, g, b, a: LONGREAL);
PROCEDURE ["C", "ofl_cairo_set_extend"] CSetExtend(p: SYSTEM.ADDRESS; extend: SYSTEM.INT32);
PROCEDURE ["C", "ofl_cairo_pattern_destroy"] CPatternDestroy(p: SYSTEM.ADDRESS);

PROCEDURE OpenCairoWindow*(win: CairoWindow; w, h: INTEGER; title-: ARRAY OF CHAR);
BEGIN
  Fl.EndOpen(win, CNew(0, 0, 0, w, h, title, Fl.BeginOpen(win)))
END OpenCairoWindow;

PROCEDURE OpenCairoWindowAt*(win: CairoWindow; x, y, w, h: INTEGER; title-: ARRAY OF CHAR);
BEGIN
  Fl.EndOpen(win, CNew(1, x, y, w, h, title, Fl.BeginOpen(win)))
END OpenCairoWindowAt;

(* Draws nothing. *)
PROCEDURE (w: CairoWindow) DrawCairo*(c: Context);
END DrawCairo;

PROCEDURE Live(c: Context): SYSTEM.ADDRESS;
BEGIN
  ASSERT(c # NIL, Fl.NilArgument);
  ASSERT(c.h # 0, Fl.OutOfOrder);
  RETURN c.h
END Live;

PROCEDURE LivePattern(p: Pattern): SYSTEM.ADDRESS;
BEGIN
  ASSERT(p # NIL, Fl.NilArgument);
  ASSERT(p.h # 0, Fl.ClosedResource);
  RETURN p.h
END LivePattern;

(* FALSE once cairo has refused a call of this context's. *)
PROCEDURE (c: Context) Ok*(): BOOLEAN;
BEGIN RETURN CStatus(Live(c)) = 0
END Ok;

PROCEDURE (c: Context) Save*;
BEGIN CSave(Live(c))
END Save;

PROCEDURE (c: Context) Restore*;
BEGIN CRestore(Live(c))
END Restore;

PROCEDURE (c: Context) Translate*(x, y: LONGREAL);
BEGIN CTranslate(Live(c), x, y)
END Translate;

PROCEDURE (c: Context) Scale*(x, y: LONGREAL);
BEGIN CScale(Live(c), x, y)
END Scale;

(* angle is in radians. *)
PROCEDURE (c: Context) Rotate*(angle: LONGREAL);
BEGIN CRotate(Live(c), angle)
END Rotate;

PROCEDURE (c: Context) SetLineWidth*(width: LONGREAL);
BEGIN CSetLineWidth(Live(c), width)
END SetLineWidth;

(* mode is one of the Antialias constants. *)
PROCEDURE (c: Context) SetAntialias*(mode: INTEGER);
BEGIN
  ASSERT((mode >= AntialiasDefault) & (mode <= AntialiasBest), Fl.IndexOutOfRange);
  CSetAntialias(Live(c), mode)
END SetAntialias;

(* Each of r, g and b is from 0 to 1. *)
PROCEDURE (c: Context) SetSourceRGB*(r, g, b: LONGREAL);
BEGIN CSetSourceRGBA(Live(c), r, g, b, 1)
END SetSourceRGB;

PROCEDURE (c: Context) SetSourceRGBA*(r, g, b, a: LONGREAL);
BEGIN CSetSourceRGBA(Live(c), r, g, b, a)
END SetSourceRGBA;

(* Cairo keeps p as long as it needs it, so p can be closed after. *)
PROCEDURE (c: Context) SetSource*(p: Pattern);
BEGIN CSetSource(Live(c), LivePattern(p))
END SetSource;

PROCEDURE (c: Context) NewPath*;
BEGIN CNewPath(Live(c))
END NewPath;

PROCEDURE (c: Context) ClosePath*;
BEGIN CClosePath(Live(c))
END ClosePath;

PROCEDURE (c: Context) MoveTo*(x, y: LONGREAL);
BEGIN CMoveTo(Live(c), x, y)
END MoveTo;

PROCEDURE (c: Context) LineTo*(x, y: LONGREAL);
BEGIN CLineTo(Live(c), x, y)
END LineTo;

PROCEDURE (c: Context) CurveTo*(x1, y1, x2, y2, x3, y3: LONGREAL);
BEGIN CCurveTo(Live(c), x1, y1, x2, y2, x3, y3)
END CurveTo;

PROCEDURE (c: Context) Rectangle*(x, y, w, h: LONGREAL);
BEGIN CRectangle(Live(c), x, y, w, h)
END Rectangle;

(* From angle from to angle to, in radians, clockwise on the screen. *)
PROCEDURE (c: Context) Arc*(x, y, radius, from, to: LONGREAL);
BEGIN CArc(Live(c), x, y, radius, from, to)
END Arc;

PROCEDURE (c: Context) Stroke*;
BEGIN CStroke(Live(c), 0)
END Stroke;

(* Stroke, keeping the path. *)
PROCEDURE (c: Context) StrokePreserve*;
BEGIN CStroke(Live(c), 1)
END StrokePreserve;

PROCEDURE (c: Context) Fill*;
BEGIN CFill(Live(c), 0)
END Fill;

(* Fill, keeping the path. *)
PROCEDURE (c: Context) FillPreserve*;
BEGIN CFill(Live(c), 1)
END FillPreserve;

(* Paint the source everywhere the clip allows. *)
PROCEDURE (c: Context) Paint*;
BEGIN CPaint(Live(c))
END Paint;

(* Limit drawing to the path, and clear it. Restore undoes this. *)
PROCEDURE (c: Context) Clip*;
BEGIN CClip(Live(c))
END Clip;

(* family is one such as "Sans", slant a Slant constant, weight a Weight
   one. *)
PROCEDURE (c: Context) SelectFontFace*(family-: ARRAY OF CHAR; slant, weight: INTEGER);
BEGIN
  ASSERT((slant >= SlantNormal) & (slant <= SlantOblique), Fl.IndexOutOfRange);
  ASSERT((weight >= WeightNormal) & (weight <= WeightBold), Fl.IndexOutOfRange);
  CSelectFontFace(Live(c), family, slant, weight)
END SelectFontFace;

PROCEDURE (c: Context) SetFontSize*(size: LONGREAL);
BEGIN CSetFontSize(Live(c), size)
END SetFontSize;

(* Draw text, which is UTF-8, from the current point. *)
PROCEDURE (c: Context) ShowText*(text-: ARRAY OF CHAR);
BEGIN CShowText(Live(c), text)
END ShowText;

(* Add text's outline to the path. *)
PROCEDURE (c: Context) TextPath*(text-: ARRAY OF CHAR);
BEGIN CTextPath(Live(c), text)
END TextPath;

PROCEDURE (c: Context) GetTextExtents*(text-: ARRAY OF CHAR; VAR e: TextExtents);
BEGIN
  CTextExtents(Live(c), text, e.xBearing, e.yBearing, e.width, e.height, e.xAdvance, e.yAdvance)
END GetTextExtents;

(* A gradient along the line from x0, y0 to x1, y1, in the coordinates of
   the context it is set on. *)
PROCEDURE LinearPattern*(x0, y0, x1, y1: LONGREAL): Pattern;
  VAR p: Pattern;
BEGIN NEW(p); p.h := CLinear(x0, y0, x1, y1); RETURN p
END LinearPattern;

(* A gradient between two circles. *)
PROCEDURE RadialPattern*(x0, y0, r0, x1, y1, r1: LONGREAL): Pattern;
  VAR p: Pattern;
BEGIN NEW(p); p.h := CRadial(x0, y0, r0, x1, y1, r1); RETURN p
END RadialPattern;

(* The color at offset, from 0 at the gradient's start to 1 at its end. *)
PROCEDURE (p: Pattern) AddColorStopRGB*(offset, r, g, b: LONGREAL);
BEGIN CAddColorStop(LivePattern(p), offset, r, g, b, 1)
END AddColorStopRGB;

PROCEDURE (p: Pattern) AddColorStopRGBA*(offset, r, g, b, a: LONGREAL);
BEGIN CAddColorStop(LivePattern(p), offset, r, g, b, a)
END AddColorStopRGBA;

(* What is beyond the ends: one of the Extend constants. *)
PROCEDURE (p: Pattern) SetExtend*(extend: INTEGER);
BEGIN
  ASSERT((extend >= ExtendNone) & (extend <= ExtendPad), Fl.IndexOutOfRange);
  CSetExtend(LivePattern(p), extend)
END SetExtend;

PROCEDURE (p: Pattern) Close*;
BEGIN
  IF p.h # 0 THEN CPatternDestroy(p.h); p.h := 0 END
END Close;

PROCEDURE DrawCairoD(self, context: SYSTEM.ADDRESS);
  VAR w: CairoWindow; c: Context;
BEGIN
  w := SYSTEM.VAL(CairoWindow, self);
  NEW(c); c.h := context;
  w.DrawCairo(c);
  c.h := 0
END DrawCairoD;

BEGIN
  CRegister(DrawCairoD)
END FlCairo.
