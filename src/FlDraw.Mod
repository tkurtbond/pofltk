MODULE FlDraw; (* Drawing: colors, lines, shapes, paths, text, clipping *)

(* FLTK's fl_draw.H, for a widget's Draw. FLTK draws only while a Draw
   runs (or into an image surface), so these belong in Draw methods and
   procedures they call. Coordinates are the window's, as a widget's X
   and Y are: a widget draws in X() .. X() + W() - 1, and so on.

   The shapes (Line, Rect, ...) take integer coordinates and ignore the
   transformation; the paths (BeginLine ... Vertex ... EndLine, Circle,
   Curve, ArcPath) take real ones and apply it (PushMatrix, Translate,
   Scale, Rotate). Angles are in degrees, counterclockwise from three
   o'clock.

   Text is drawn in the font SetFont last set. FLTK's own drawing (labels,
   boxes) sets the font and color too, so a Draw sets them before it uses
   them.

   Three things here work outside a Draw, on what a window shows:
   OverlayRect, OverlayClear and Scroll. Each needs a window made current
   first (Window.MakeCurrent), and halts with Fl.OutOfOrder without one,
   as Antialias does with nothing to draw on; FLTK crashes.

   An Offscreen is a picture to draw on and copy from: a Draw copies it
   into a window. FlImages has images, pixmaps (DrawPixmap) and what a
   window shows (CaptureWindow).

   The C++ part is FlDraw.cpp. *)

IMPORT SYSTEM, GarbageCollectedHeap, Fl;

CONST
(* BEGIN generated constants: tools/gen-constants.py writes this block,
   from FLTK's headers; edit the script, not the block. *)

  (* line styles (LineStyle): a dash pattern, plus a cap and a join *)
  Solid* = 0;
  Dash* = 1;
  Dot* = 2;
  DashDot* = 3;
  DashDotDot* = 4;
  CapFlat* = 256;
  CapRound* = 512;
  CapSquare* = 768;
  JoinMiter* = 4096;
  JoinRound* = 8192;
  JoinBevel* = 12288;

  (* kinds of arrow (DrawArrow) *)
  ArrowSingle* = 1;
  ArrowDouble* = 2;
  ArrowChoice* = 3;
  ArrowReturn* = 4;

  (* where an arrow points (DrawArrow) *)
  OrientRight* = 0;
  OrientNE* = 1;
  OrientUp* = 2;
  OrientNW* = 3;
  OrientLeft* = 4;
  OrientSW* = 5;
  OrientDown* = 6;
  OrientSE* = 7;
(* END generated constants *)

TYPE
  (* A symbol's drawing (AddSymbol): a procedure of a module, not one nested
     in a procedure, since FLTK keeps it for good. *)
  SymbolProc* = PROCEDURE (color: INTEGER);

  (* What to draw again after Scroll: Draw is called with each part. *)
  Area* = POINTER TO AreaDesc;
  AreaDesc* = RECORD END;

  (* The rows of DrawImageLines: Line is called for each. *)
  ImageSource* = POINTER TO ImageSourceDesc;
  ImageSourceDesc* = RECORD END;

  Offscreen* = POINTER TO OffscreenDesc;
  OffscreenDesc* = RECORD
    h: SYSTEM.ADDRESS;
    below: Offscreen;  (* the offscreen begun before this one *)
    begun: BOOLEAN
  END;

  Bytes = POINTER TO ARRAY OF CHAR;
  AreaDispatch = PROCEDURE (x, y, w, h: SYSTEM.INT32);
  LineDispatch = PROCEDURE (x, y, w: SYSTEM.INT32; buf: SYSTEM.ADDRESS);

VAR
  openOffscreens-: INTEGER;  (* those not closed yet *)
  current: Offscreen;        (* the offscreen last begun and not ended *)
  (* what the running Scroll or DrawImageLines calls back: C++ holds none *)
  area: Area;
  source: ImageSource;
  line: Bytes;
  lineD: INTEGER;

(* Draws x, y, w, h, in window coordinates. Nothing clips it to that. *)
PROCEDURE (a: Area) Draw*(x, y, w, h: INTEGER);
END Draw;

(* Fills buf, w pixels of as many bytes as DrawImageLines was given, with
   the pixels of row y from column x (both from the image's 0, 0). Line
   is called with FLTK's image drawing under way, which X11 can't re-enter
   (doc/fltk-issues.md, 133): FlDraw's images halt with Fl.OutOfOrder in
   it, and it must draw nothing else that shows an image. *)
PROCEDURE (s: ImageSource) Line*(x, y, w: INTEGER; VAR buf: ARRAY OF CHAR);
END Line;

PROCEDURE Int(b: BOOLEAN): SYSTEM.INT32;
BEGIN IF b THEN RETURN 1 END; RETURN 0
END Int;

PROCEDURE ["C", "ofl_draw_color"] CColor(c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_rgb"] CRGB(r, g, b: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_get_color"] CGetColor(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_draw_line_style"] CLineStyle(style, width: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_point"] CPoint(x, y: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_line"] CLine(x, y, x1, y1: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_rect"] CRect(x, y, w, h: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_rectf"] CRectF(x, y, w, h: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_loop3"] CLoop3(x0, y0, x1, y1, x2, y2: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_loop4"] CLoop4(x0, y0, x1, y1, x2, y2, x3, y3: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_polygon3"] CPolygon3(x0, y0, x1, y1, x2, y2: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_polygon4"] CPolygon4(x0, y0, x1, y1, x2, y2, x3, y3: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_xyline"] CXYLine(x, y, x1: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_yxline"] CYXLine(x, y, y1: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_arc"] CArc(x, y, w, h: SYSTEM.INT32; a1, a2: LONGREAL);
PROCEDURE ["C", "ofl_draw_pie"] CPie(x, y, w, h: SYSTEM.INT32; a1, a2: LONGREAL);
PROCEDURE ["C", "ofl_draw_push_matrix"] CPushMatrix;
PROCEDURE ["C", "ofl_draw_pop_matrix"] CPopMatrix;
PROCEDURE ["C", "ofl_draw_scale"] CScale(x, y: LONGREAL);
PROCEDURE ["C", "ofl_draw_translate"] CTranslate(x, y: LONGREAL);
PROCEDURE ["C", "ofl_draw_rotate"] CRotate(d: LONGREAL);
PROCEDURE ["C", "ofl_draw_begin_points"] CBeginPoints;
PROCEDURE ["C", "ofl_draw_begin_line"] CBeginLine;
PROCEDURE ["C", "ofl_draw_begin_loop"] CBeginLoop;
PROCEDURE ["C", "ofl_draw_begin_polygon"] CBeginPolygon;
PROCEDURE ["C", "ofl_draw_begin_complex_polygon"] CBeginComplexPolygon;
PROCEDURE ["C", "ofl_draw_gap"] CGap;
PROCEDURE ["C", "ofl_draw_end_points"] CEndPoints;
PROCEDURE ["C", "ofl_draw_end_line"] CEndLine;
PROCEDURE ["C", "ofl_draw_end_loop"] CEndLoop;
PROCEDURE ["C", "ofl_draw_end_polygon"] CEndPolygon;
PROCEDURE ["C", "ofl_draw_end_complex_polygon"] CEndComplexPolygon;
PROCEDURE ["C", "ofl_draw_vertex"] CVertex(x, y: LONGREAL);
PROCEDURE ["C", "ofl_draw_curve"] CCurve(x0, y0, x1, y1, x2, y2, x3, y3: LONGREAL);
PROCEDURE ["C", "ofl_draw_arc_path"] CArcPath(x, y, r, start, end: LONGREAL);
PROCEDURE ["C", "ofl_draw_circle"] CCircle(x, y, r: LONGREAL);
PROCEDURE ["C", "ofl_draw_font"] CFont(face, size: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_get_font"] CGetFont(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_draw_size"] CSize(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_draw_height"] CHeight(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_draw_descent"] CDescent(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_draw_width"] CWidth(s: ARRAY OF CHAR): LONGREAL;
PROCEDURE ["C", "ofl_draw_text"] CText(s: ARRAY OF CHAR; x, y: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_text_aligned"] CTextAligned(s: ARRAY OF CHAR; x, y, w, h, align: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_measure"] CMeasure(s: ARRAY OF CHAR; VAR w, h: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_push_clip"] CPushClip(x, y, w, h: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_push_no_clip"] CPushNoClip;
PROCEDURE ["C", "ofl_draw_pop_clip"] CPopClip;
PROCEDURE ["C", "ofl_draw_not_clipped"] CNotClipped(x, y, w, h: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_draw_clip_box"] CClipBox(x, y, w, h: SYSTEM.INT32; VAR cx, cy, cw, ch: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_box"] CDrawBox(type, x, y, w, h, c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_focus_rect"] CFocusRect(x, y, w, h: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_symbol"] CDrawSymbol(name: ARRAY OF CHAR; x, y, w, h, c: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_draw_add_symbol"] CAddSymbol(name: ARRAY OF CHAR; draw: SymbolProc; scalable: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_draw_box_focus"] CDrawBoxFocus(type, x, y, w, h, fg, bg: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_frame"] CFrame(s: ARRAY OF CHAR; x, y, w, h: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_frame2"] CFrame2(s: ARRAY OF CHAR; x, y, w, h: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_rounded_rect"] CRoundedRect(x, y, w, h, r: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_rounded_rectf"] CRoundedRectF(x, y, w, h, r: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_disc"] CDrawCircle(x, y, d, c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_radio"] CDrawRadio(x, y, d, c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_arrow"] CDrawArrow(x, y, w, h, type, orient, c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_check"] CDrawCheck(x, y, w, h, c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_overlay_rect"] COverlayRect(x, y, w, h: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_draw_overlay_clear"] COverlayClear(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_draw_scroll"] CScroll(x, y, w, h, dx, dy: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_draw_can_draw"] CCanDraw(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_draw_antialias"] CAntialias(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_draw_set_antialias"] CSetAntialias(on: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_cursor"] CCursor(c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_load_identity"] CLoadIdentity;
PROCEDURE ["C", "ofl_draw_load_matrix"] CLoadMatrix(a, b, c, d, x, y: LONGREAL);
PROCEDURE ["C", "ofl_draw_mult_matrix"] CMultMatrix(a, b, c, d, x, y: LONGREAL);
PROCEDURE ["C", "ofl_draw_transform_x"] CTransformX(x, y: LONGREAL): LONGREAL;
PROCEDURE ["C", "ofl_draw_transform_y"] CTransformY(x, y: LONGREAL): LONGREAL;
PROCEDURE ["C", "ofl_draw_transform_dx"] CTransformDX(x, y: LONGREAL): LONGREAL;
PROCEDURE ["C", "ofl_draw_transform_dy"] CTransformDY(x, y: LONGREAL): LONGREAL;
PROCEDURE ["C", "ofl_draw_transformed_vertex"] CTransformedVertex(x, y: LONGREAL);
PROCEDURE ["C", "ofl_draw_override_scale"] COverrideScale(): LONGREAL;
PROCEDURE ["C", "ofl_draw_restore_scale"] CRestoreScale(s: LONGREAL);
PROCEDURE ["C", "ofl_draw_text_extents"] CTextExtents(s: ARRAY OF CHAR; VAR dx, dy, w, h: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_text_angle"] CTextAngle(angle: SYSTEM.INT32; s: ARRAY OF CHAR; x, y: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_rtl"] CRtl(s: ARRAY OF CHAR; x, y: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_expand"] CExpand(from: SYSTEM.ADDRESS; VAR to: ARRAY OF CHAR; size: SYSTEM.INT32; maxw: LONGREAL; VAR n: SYSTEM.INT32; VAR width: LONGREAL; wrap, symbols: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_draw_set_spot"] CSetSpot(font, size, x, y, w, h: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_reset_spot"] CResetSpot;
PROCEDURE ["C", "ofl_draw_set_status"] CSetStatus(x, y, w, h: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_recode"] CRecode(kind: SYSTEM.INT32; from: ARRAY OF CHAR; VAR to: ARRAY OF CHAR; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_image"] CDrawImage(buf: SYSTEM.ADDRESS; x, y, w, h, d, l: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_image_mono"] CDrawImageMono(buf: SYSTEM.ADDRESS; x, y, w, h, d, l: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_image_lines"] CDrawImageLines(x, y, w, h, d: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_image_mono_lines"] CDrawImageMonoLines(x, y, w, h, d: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_can_blend"] CCanBlend(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_offscreen_new"] COffscreenNew(w, h: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_offscreen_close"] COffscreenClose(s: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_offscreen_begin"] COffscreenBegin(s: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_offscreen_end"] COffscreenEnd;
PROCEDURE ["C", "ofl_offscreen_current"] COffscreenCurrent(s: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_offscreen_copy"] COffscreenCopy(s: SYSTEM.ADDRESS; x, y, w, h, sx, sy: SYSTEM.INT32);
PROCEDURE ["C", "ofl_offscreen_rescale"] COffscreenRescale(s: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_draw_register"] CRegister(area: AreaDispatch; line: LineDispatch);

(* Colors and lines *)

(* What draws from now on: c, a color of Fl's (Fl.Red, Fl.RGB(...)). *)
PROCEDURE SetColor*(c: INTEGER);
BEGIN CColor(c)
END SetColor;

PROCEDURE SetRGB*(r, g, b: INTEGER);
BEGIN CRGB(r, g, b)
END SetRGB;

PROCEDURE Color*(): INTEGER;
BEGIN RETURN CGetColor()
END Color;

(* Lines from now on: style is Solid, Dash or another dash pattern, plus
   a cap and a join (Dash + CapRound + JoinRound); width is in pixels, 0
   for the thinnest. LineStyle(Solid, 0) goes back to FLTK's default,
   which a Draw that changes the style must do before it returns. *)
PROCEDURE LineStyle*(style, width: INTEGER);
BEGIN CLineStyle(style, width)
END LineStyle;

(* Shapes *)

PROCEDURE Point*(x, y: INTEGER);
BEGIN CPoint(x, y)
END Point;

PROCEDURE Line*(x, y, x1, y1: INTEGER);
BEGIN CLine(x, y, x1, y1)
END Line;

(* The outline of the rectangle, inside it. *)
PROCEDURE Rect*(x, y, w, h: INTEGER);
BEGIN CRect(x, y, w, h)
END Rect;

(* The rectangle, filled. *)
PROCEDURE RectF*(x, y, w, h: INTEGER);
BEGIN CRectF(x, y, w, h)
END RectF;

(* The outlines of a triangle and a quadrilateral. *)
PROCEDURE Loop3*(x0, y0, x1, y1, x2, y2: INTEGER);
BEGIN CLoop3(x0, y0, x1, y1, x2, y2)
END Loop3;

PROCEDURE Loop4*(x0, y0, x1, y1, x2, y2, x3, y3: INTEGER);
BEGIN CLoop4(x0, y0, x1, y1, x2, y2, x3, y3)
END Loop4;

(* The same, filled. *)
PROCEDURE Polygon3*(x0, y0, x1, y1, x2, y2: INTEGER);
BEGIN CPolygon3(x0, y0, x1, y1, x2, y2)
END Polygon3;

PROCEDURE Polygon4*(x0, y0, x1, y1, x2, y2, x3, y3: INTEGER);
BEGIN CPolygon4(x0, y0, x1, y1, x2, y2, x3, y3)
END Polygon4;

(* A horizontal line from x, y to x1, y; a vertical one to x, y1. *)
PROCEDURE XYLine*(x, y, x1: INTEGER);
BEGIN CXYLine(x, y, x1)
END XYLine;

PROCEDURE YXLine*(x, y, y1: INTEGER);
BEGIN CYXLine(x, y, y1)
END YXLine;

(* The arc of the ellipse inside x, y, w, h from angle a1 to a2, and the
   same, filled as a pie slice. *)
PROCEDURE Arc*(x, y, w, h: INTEGER; a1, a2: LONGREAL);
BEGIN CArc(x, y, w, h, a1, a2)
END Arc;

PROCEDURE Pie*(x, y, w, h: INTEGER; a1, a2: LONGREAL);
BEGIN CPie(x, y, w, h, a1, a2)
END Pie;

(* Paths and the transformation *)

(* Saves the transformation, for PopMatrix to restore; at most 32 deep. *)
PROCEDURE PushMatrix*;
BEGIN CPushMatrix
END PushMatrix;

PROCEDURE PopMatrix*;
BEGIN CPopMatrix
END PopMatrix;

PROCEDURE Scale*(x, y: LONGREAL);
BEGIN CScale(x, y)
END Scale;

PROCEDURE Translate*(x, y: LONGREAL);
BEGIN CTranslate(x, y)
END Translate;

(* By d degrees, counterclockwise. *)
PROCEDURE Rotate*(d: LONGREAL);
BEGIN CRotate(d)
END Rotate;

(* A path is a Begin, its Vertex, Curve, ArcPath and Circle calls, and the
   matching End: points, a line through them, a closed loop, a convex
   polygon, or any polygon, with Gap between its separate outlines. *)
PROCEDURE BeginPoints*;
BEGIN CBeginPoints
END BeginPoints;

PROCEDURE BeginLine*;
BEGIN CBeginLine
END BeginLine;

PROCEDURE BeginLoop*;
BEGIN CBeginLoop
END BeginLoop;

PROCEDURE BeginPolygon*;
BEGIN CBeginPolygon
END BeginPolygon;

PROCEDURE BeginComplexPolygon*;
BEGIN CBeginComplexPolygon
END BeginComplexPolygon;

PROCEDURE Gap*;
BEGIN CGap
END Gap;

PROCEDURE EndPoints*;
BEGIN CEndPoints
END EndPoints;

PROCEDURE EndLine*;
BEGIN CEndLine
END EndLine;

PROCEDURE EndLoop*;
BEGIN CEndLoop
END EndLoop;

PROCEDURE EndPolygon*;
BEGIN CEndPolygon
END EndPolygon;

PROCEDURE EndComplexPolygon*;
BEGIN CEndComplexPolygon
END EndComplexPolygon;

PROCEDURE Vertex*(x, y: LONGREAL);
BEGIN CVertex(x, y)
END Vertex;

(* A Bezier curve from x0, y0 to x3, y3, drawn toward x1, y1 and x2, y2. *)
PROCEDURE Curve*(x0, y0, x1, y1, x2, y2, x3, y3: LONGREAL);
BEGIN CCurve(x0, y0, x1, y1, x2, y2, x3, y3)
END Curve;

(* The arc of the circle at x, y, radius r, from angle start to end. *)
PROCEDURE ArcPath*(x, y, r, start, end: LONGREAL);
BEGIN CArcPath(x, y, r, start, end)
END ArcPath;

(* A circle: the whole path, between one Begin and End. *)
PROCEDURE Circle*(x, y, r: LONGREAL);
BEGIN CCircle(x, y, r)
END Circle;

(* Text *)

(* Text from now on: face is a font of Fl's (Fl.Helvetica, Fl.Courier +
   Fl.Bold), size in pixels. *)
PROCEDURE SetFont*(face, size: INTEGER);
BEGIN CFont(face, size)
END SetFont;

PROCEDURE Font*(): INTEGER;
BEGIN RETURN CGetFont()
END Font;

PROCEDURE Size*(): INTEGER;
BEGIN RETURN CSize()
END Size;

(* The font's line height, and how far below the baseline it reaches. *)
PROCEDURE Height*(): INTEGER;
BEGIN RETURN CHeight()
END Height;

PROCEDURE Descent*(): INTEGER;
BEGIN RETURN CDescent()
END Descent;

(* The width of s, in pixels. *)
PROCEDURE Width*(s-: ARRAY OF CHAR): LONGREAL;
BEGIN RETURN CWidth(s)
END Width;

(* s, from x on the baseline y. *)
PROCEDURE Text*(s-: ARRAY OF CHAR; x, y: INTEGER);
BEGIN CText(s, x, y)
END Text;

(* s in the box x, y, w, h, placed as a label is, by a set of Fl's Align
   constants, its lines split at each 0AX and, with Fl.AlignWrap, wrapped.
   "@" starts a symbol's name, as in a label; "@@" draws "@". *)
PROCEDURE TextAligned*(s-: ARRAY OF CHAR; x, y, w, h: INTEGER; align: SET);
BEGIN CTextAligned(s, x, y, w, h, ORD(align))
END TextAligned;

(* The width and height TextAligned would take for s. On entry w is the
   width to wrap at, 0 for none. *)
PROCEDURE Measure*(s-: ARRAY OF CHAR; VAR w, h: INTEGER);
  VAR cw, ch: SYSTEM.INT32;
BEGIN
  cw := w; ch := 0; CMeasure(s, cw, ch); w := cw; h := ch
END Measure;

(* Clipping *)

(* Draws only inside x, y, w, h, and the clip region before, until the
   matching PopClip. *)
PROCEDURE PushClip*(x, y, w, h: INTEGER);
BEGIN CPushClip(x, y, w, h)
END PushClip;

(* Draws anywhere, until the matching PopClip. *)
PROCEDURE PushNoClip*;
BEGIN CPushNoClip
END PushNoClip;

PROCEDURE PopClip*;
BEGIN CPopClip
END PopClip;

(* FALSE if nothing drawn in x, y, w, h would show, so it may be skipped. *)
PROCEDURE NotClipped*(x, y, w, h: INTEGER): BOOLEAN;
BEGIN RETURN CNotClipped(x, y, w, h) # 0
END NotClipped;

(* The bounding box of the part of x, y, w, h that would show, in cx, cy,
   cw, ch; cw or ch is 0 if none would. (FLTK's fl_clip_box also says
   whether the box is all of x, y, w, h, but says it wrongly:
   doc/fltk-issues.md, 2.) *)
PROCEDURE ClipBox*(x, y, w, h: INTEGER; VAR cx, cy, cw, ch: INTEGER);
  VAR X, Y, W, H: SYSTEM.INT32;
BEGIN
  CClipBox(x, y, w, h, X, Y, W, H);
  cx := X; cy := Y; cw := W; ch := H
END ClipBox;

(* Boxes and symbols *)

(* A box of type (Fl.UpBox or another box type), in color c. *)
PROCEDURE DrawBox*(type, x, y, w, h, c: INTEGER);
BEGIN CDrawBox(type, x, y, w, h, c)
END DrawBox;

(* The dotted box showing a widget has the focus. *)
PROCEDURE FocusRect*(x, y, w, h: INTEGER);
BEGIN CFocusRect(x, y, w, h)
END FocusRect;

(* The symbol name ("->", "circle", "+", ..., without the "@" a label
   uses) in x, y, w, h, in color c; FALSE if FLTK hasn't one by name. *)
PROCEDURE DrawSymbol*(name-: ARRAY OF CHAR; x, y, w, h, c: INTEGER): BOOLEAN;
BEGIN RETURN CDrawSymbol(name, x, y, w, h, c) # 0
END DrawSymbol;

(* Makes name a symbol, or replaces the one of that name, for good: FLTK's
   table has no removing, and room for some 60 beside FLTK's own. draw is
   called with the color, which it sets itself, to draw in a box of -1 to 1 by -1 to 1 with
   paths (Vertex and the rest, and y is up), and FlDraw's other calls,
   not integer shapes. If scalable, a label's size modifiers apply. FALSE
   if the table is full, or FLTK wouldn't find the name again: empty, not
   ASCII, or starting as a label's modifiers do, with a digit or one of
   #, $ and %, or + or - and a digit. *)
PROCEDURE AddSymbol*(name-: ARRAY OF CHAR; draw: SymbolProc; scalable: BOOLEAN): BOOLEAN;
BEGIN
  ASSERT(draw # NIL, Fl.NilArgument);
  RETURN CAddSymbol(name, draw, Int(scalable)) # 0
END AddSymbol;

(* FLTK's focus box for a box of type: a dotted line just inside x, y, w, h,
   in a color that shows fg on bg. It draws no box, and nothing when
   Fl.OptionVisibleFocus is off. *)
PROCEDURE DrawBoxFocus*(type, x, y, w, h, fg, bg: INTEGER);
BEGIN CDrawBoxFocus(type, x, y, w, h, fg, bg)
END DrawBoxFocus;

(* FLTK reads four letters at a time, past the end of s if they don't come
   out even, and uses each as an index into its grays. *)
PROCEDURE CheckFrame(s-: ARRAY OF CHAR);
  VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (i < LEN(s)) & (s[i] # 0X) DO
    ASSERT((s[i] >= "A") & (s[i] <= "X"), Fl.IndexOutOfRange); INC(i)
  END;
  ASSERT(i MOD 4 = 0, Fl.IndexOutOfRange)
END CheckFrame;

(* A frame of lines, four letters to a round from the edge inwards: top,
   left, bottom, right, each "A" (black) to "X" (white). "NNTT" is 1 pixel
   of gray at the top and left, and of light at the bottom and right. A number of letters not a multiple of 4, or
   one outside A to X, halts with Fl.IndexOutOfRange. *)
PROCEDURE Frame*(s-: ARRAY OF CHAR; x, y, w, h: INTEGER);
BEGIN CheckFrame(s); CFrame(s, x, y, w, h)
END Frame;

(* As Frame, in the order bottom, right, top, left. *)
PROCEDURE Frame2*(s-: ARRAY OF CHAR; x, y, w, h: INTEGER);
BEGIN CheckFrame(s); CFrame2(s, x, y, w, h)
END Frame2;

(* Rectangles with corners of radius r, as a line and filled. *)
PROCEDURE RoundedRect*(x, y, w, h, r: INTEGER);
BEGIN CRoundedRect(x, y, w, h, r)
END RoundedRect;

PROCEDURE RoundedRectF*(x, y, w, h, r: INTEGER);
BEGIN CRoundedRectF(x, y, w, h, r)
END RoundedRectF;

(* A filled circle of diameter d in color c, at the top left x, y, and the
   same as a radio button's: both as FLTK draws small ones, to the pixel. *)
PROCEDURE DrawCircle*(x, y, d, c: INTEGER);
BEGIN CDrawCircle(x, y, d, c)
END DrawCircle;

PROCEDURE DrawRadio*(x, y, d, c: INTEGER);
BEGIN CDrawRadio(x, y, d, c)
END DrawRadio;

(* An arrow (ArrowSingle or another) pointing as orient (OrientRight or
   another) says, in color c, in the middle of x, y, w, h. A kind or
   orientation not one of these halts with Fl.IndexOutOfRange. *)
PROCEDURE DrawArrow*(x, y, w, h, kind, orient, c: INTEGER);
BEGIN
  ASSERT((kind >= ArrowSingle) & (kind <= ArrowReturn), Fl.IndexOutOfRange);
  ASSERT((orient >= OrientRight) & (orient <= OrientSE), Fl.IndexOutOfRange);
  CDrawArrow(x, y, w, h, kind, orient, c)
END DrawArrow;

(* The mark of a check button, in color c, in x, y, w, h. *)
PROCEDURE DrawCheck*(x, y, w, h, c: INTEGER);
BEGIN CDrawCheck(x, y, w, h, c)
END DrawCheck;

(* A rectangle over what the current window shows, replacing the last,
   for a rubber band, between draws. No window current, or a surface,
   halts with Fl.OutOfOrder. Not for a window with an overlay. *)
PROCEDURE OverlayRect*(x, y, w, h: INTEGER);
BEGIN ASSERT(COverlayRect(x, y, w, h) # 0, Fl.OutOfOrder)
END OverlayRect;

(* Takes the last OverlayRect away. *)
PROCEDURE OverlayClear*;
BEGIN ASSERT(COverlayClear() # 0, Fl.OutOfOrder)
END OverlayClear;

(* Moves what x, y, w, h shows of the current window by dx, dy, and calls
   a.Draw for the parts to draw again, in window coordinates; with dx and
   dy both 0, neither. On a surface, which has nothing to move, a.Draw
   draws all of it. With neither, halts with Fl.OutOfOrder. *)
PROCEDURE Scroll*(x, y, w, h, dx, dy: INTEGER; a: Area);
  VAR outer: Area; done: BOOLEAN;
BEGIN
  ASSERT(a # NIL, Fl.NilArgument);
  outer := area; area := a;
  done := CScroll(x, y, w, h, dx, dy) # 0;
  area := outer;
  ASSERT(done, Fl.OutOfOrder)
END Scroll;

(* Whether lines and curves are smoothed: TRUE to start with on Cairo,
   where SetAntialias turns that off, for lines that must meet to the
   pixel. FLTK's plain X11 drawing never smooths, so there Antialias is
   always FALSE. Nothing to draw on halts with Fl.OutOfOrder. *)
PROCEDURE Antialias*(): BOOLEAN;
BEGIN
  ASSERT(CCanDraw() # 0, Fl.OutOfOrder);
  RETURN CAntialias() # 0
END Antialias;

PROCEDURE SetAntialias*(on: BOOLEAN);
BEGIN
  ASSERT(CCanDraw() # 0, Fl.OutOfOrder);
  CSetAntialias(Int(on))
END SetAntialias;

(* Sets the cursor of the first window shown (Fl.FirstWindow), and of no
   other; with none, does nothing. Window.SetCursor is for a given one. *)
PROCEDURE Cursor*(c: INTEGER);
BEGIN CCursor(c)
END Cursor;

(* More transformations: a matrix maps x, y to ax + cy + e, bx + dy + f,
   where here e and f are x and y *)

(* Back to no transformation at all. *)
PROCEDURE LoadIdentity*;
BEGIN CLoadIdentity
END LoadIdentity;

PROCEDURE LoadMatrix*(a, b, c, d, x, y: LONGREAL);
BEGIN CLoadMatrix(a, b, c, d, x, y)
END LoadMatrix;

(* Applies the matrix before the current transformation. *)
PROCEDURE MultMatrix*(a, b, c, d, x, y: LONGREAL);
BEGIN CMultMatrix(a, b, c, d, x, y)
END MultMatrix;

(* Where the current transformation takes x, y. *)
PROCEDURE TransformX*(x, y: LONGREAL): LONGREAL;
BEGIN RETURN CTransformX(x, y)
END TransformX;

PROCEDURE TransformY*(x, y: LONGREAL): LONGREAL;
BEGIN RETURN CTransformY(x, y)
END TransformY;

(* Where it takes the distance x, y: with no translation. *)
PROCEDURE TransformDX*(x, y: LONGREAL): LONGREAL;
BEGIN RETURN CTransformDX(x, y)
END TransformDX;

PROCEDURE TransformDY*(x, y: LONGREAL): LONGREAL;
BEGIN RETURN CTransformDY(x, y)
END TransformDY;

(* A vertex already transformed. *)
PROCEDURE TransformedVertex*(x, y: LONGREAL);
BEGIN CTransformedVertex(x, y)
END TransformedVertex;

(* Draws in pixels, without the screen's scale, until RestoreScale of what
   this returned. PushClip doesn't work between the two. *)
PROCEDURE OverrideScale*(): LONGREAL;
BEGIN RETURN COverrideScale()
END OverrideScale;

PROCEDURE RestoreScale*(s: LONGREAL);
BEGIN CRestoreScale(s)
END RestoreScale;

(* More text *)

(* The box s's ink fills, relative to where Text would draw it: dx, dy
   its top left from the start of the baseline, w, h its size. *)
PROCEDURE TextExtents*(s-: ARRAY OF CHAR; VAR dx, dy, w, h: INTEGER);
  VAR a, b, c, d: SYSTEM.INT32;
BEGIN
  CTextExtents(s, a, b, c, d); dx := a; dy := b; w := c; h := d
END TextExtents;

(* Text at angle degrees counterclockwise, about x, y. *)
PROCEDURE TextRotated*(angle: INTEGER; s-: ARRAY OF CHAR; x, y: INTEGER);
BEGIN CTextAngle(angle, s, x, y)
END TextRotated;

(* Text from right to left. *)
PROCEDURE RightToLeft*(s-: ARRAY OF CHAR; x, y: INTEGER);
BEGIN CRtl(s, x, y)
END RightToLeft;

(* The line of from starting at index start as FLTK draws it, in to, cut
   to fit: tabs as spaces to the next multiple of 8, control characters
   as ^X. It ends at a newline, the end of from, or, if wrap, at the last
   word that fits in maxw. n is its length in bytes before any cut, width
   how wide it is, and the result the index the next line starts at. If
   symbols, "@@" is one "@", and it also stops at any other "@", which
   starts a symbol, and the result is that "@": at the start of a line,
   the same start again. *)
PROCEDURE ExpandText*(from-: ARRAY OF CHAR; start: INTEGER; VAR to: ARRAY OF CHAR; maxw: LONGREAL;
                      VAR n: INTEGER; VAR width: LONGREAL; wrap, symbols: BOOLEAN): INTEGER;
  VAR c: SYSTEM.INT32; end: INTEGER;
BEGIN
  ASSERT((start >= 0) & (start < LEN(from)), Fl.IndexOutOfRange);
  end := start + CExpand(SYSTEM.ADR(from[start]), to, SHORT(LEN(to)), maxw, c, width,
                         Int(wrap), Int(symbols));
  n := c;
  RETURN end
END ExpandText;

(* Says where text is being typed, for the system's input of composed
   text. FLTK's X11 and Wayland drivers ignore its window argument, so this
   has none: the place is in the window with the focus. *)
PROCEDURE SetSpot*(font, size, x, y, w, h: INTEGER);
BEGIN CSetSpot(font, size, x, y, w, h)
END SetSpot;

(* That no text is being typed. *)
PROCEDURE ResetSpot*;
BEGIN CResetSpot
END ResetSpot;

(* Where the input method's status shows, on X11. *)
PROCEDURE SetStatus*(x, y, w, h: INTEGER);
BEGIN CSetStatus(x, y, w, h)
END SetStatus;

(* Encodings: from, up to its 0X, in to, cut to fit. On Unix FLTK takes
   the local encoding to be Latin-1, whatever the locale, so the Latin-1
   pair copy. *)

PROCEDURE Latin1ToLocal*(from-: ARRAY OF CHAR; VAR to: ARRAY OF CHAR);
BEGIN CRecode(0, from, to, SHORT(LEN(to)))
END Latin1ToLocal;

PROCEDURE LocalToLatin1*(from-: ARRAY OF CHAR; VAR to: ARRAY OF CHAR);
BEGIN CRecode(1, from, to, SHORT(LEN(to)))
END LocalToLatin1;

PROCEDURE MacRomanToLocal*(from-: ARRAY OF CHAR; VAR to: ARRAY OF CHAR);
BEGIN CRecode(2, from, to, SHORT(LEN(to)))
END MacRomanToLocal;

PROCEDURE LocalToMacRoman*(from-: ARRAY OF CHAR; VAR to: ARRAY OF CHAR);
BEGIN CRecode(3, from, to, SHORT(LEN(to)))
END LocalToMacRoman;

(* Images *)

(* FLTK reads pixels at d bytes apart in a row, and rows at l apart, so
   the bytes it reads are checked to lie in data: Fl.IndexOutOfRange. *)
PROCEDURE CheckImage(n: LONGINT; first, w, h, d, l: INTEGER);
  VAR across, down, low, high: HUGEINT; bytes: INTEGER;
BEGIN
  ASSERT(d # 0, Fl.IndexOutOfRange); ASSERT(first >= 0, Fl.IndexOutOfRange);
  across := w - 1; across := across * d;
  down := h - 1; down := down * l;
  low := first; high := first;
  IF across < 0 THEN low := low + across ELSE high := high + across END;
  IF down < 0 THEN low := low + down ELSE high := high + down END;
  bytes := ABS(d); IF bytes > 4 THEN bytes := 3 END;
  ASSERT((low >= 0) & (high + bytes <= n), Fl.IndexOutOfRange)
END CheckImage;

(* A row's bytes if l is 0, as FLTK takes it. *)
PROCEDURE RowBytes(w, d, l: INTEGER): INTEGER;
  VAR row: HUGEINT;
BEGIN
  IF l = 0 THEN
    row := w; row := row * ABS(d);
    ASSERT(row <= MAX(INTEGER), Fl.IndexOutOfRange);
    RETURN w * ABS(d)
  END;
  RETURN l
END RowBytes;

(* Draws w by h pixels from data at x, y: first is the index of the top left
   pixel's first byte, d how far apart in bytes pixels are in a row
   (negative for a row stored right to left), and l how far apart rows are
   (negative for last first; 0 for w * ABS(d)). A pixel is 3 bytes of red,
   green and blue, for d of 3 or more, or 1 of gray for 1. With 4 FLTK
   ignores the fourth. Anything beyond data halts with Fl.IndexOutOfRange.
   w or h under 1 draws nothing. *)
PROCEDURE DrawImage*(data-: ARRAY OF CHAR; first, x, y, w, h, d, l: INTEGER);
BEGIN
  ASSERT(source = NIL, Fl.OutOfOrder);
  IF (w > 0) & (h > 0) THEN
    ASSERT(d # 0, Fl.IndexOutOfRange);
    l := RowBytes(w, d, l); CheckImage(LEN(data), first, w, h, d, l);
    CDrawImage(SYSTEM.ADR(data[first]), x, y, w, h, d, l)
  END
END DrawImage;

(* As DrawImage, of grays: one byte of each pixel. *)
PROCEDURE DrawImageMono*(data-: ARRAY OF CHAR; first, x, y, w, h, d, l: INTEGER);
BEGIN
  ASSERT(source = NIL, Fl.OutOfOrder);
  IF (w > 0) & (h > 0) THEN
    ASSERT(d # 0, Fl.IndexOutOfRange);
    l := RowBytes(w, d, l); CheckImage(LEN(data), first, w, h, d, l);
    CDrawImageMono(SYSTEM.ADR(data[first]), x, y, w, h, d, l)
  END
END DrawImageMono;

PROCEDURE LineD(x, y, w: SYSTEM.INT32; buf: SYSTEM.ADDRESS);
BEGIN
  source.Line(x, y, w, line^);
  SYSTEM.MOVE(SYSTEM.ADR(line[0]), buf, w * lineD)
END LineD;

(* Sets up a Line buffer for w by d bytes for one call of CDrawImageLines
   or CDrawImageMonoLines. *)
PROCEDURE DrawLines(s: ImageSource; x, y, w, h, d: INTEGER; mono: BOOLEAN);
  VAR row: HUGEINT;
BEGIN
  ASSERT(s # NIL, Fl.NilArgument);
  ASSERT(source = NIL, Fl.OutOfOrder);
  ASSERT((d >= 1) & (d <= 4), Fl.IndexOutOfRange);
  IF (w > 0) & (h > 0) THEN
    row := w; row := row * d;
    ASSERT(row <= MAX(INTEGER), Fl.IndexOutOfRange);
    NEW(line, w * d); source := s; lineD := d;
    IF mono THEN CDrawImageMonoLines(x, y, w, h, d)
    ELSE CDrawImageLines(x, y, w, h, d)
    END;
    source := NIL; line := NIL
  END
END DrawLines;

(* As DrawImage, of pixels of d bytes (1 to 4) that s.Line gives a row at
   a time, without an image in memory. *)
PROCEDURE DrawImageLines*(s: ImageSource; x, y, w, h, d: INTEGER);
BEGIN DrawLines(s, x, y, w, h, d, FALSE)
END DrawImageLines;

PROCEDURE DrawImageMonoLines*(s: ImageSource; x, y, w, h, d: INTEGER);
BEGIN DrawLines(s, x, y, w, h, d, TRUE)
END DrawImageMonoLines;

(* Whether the display blends an image's alpha with what is under it. *)
PROCEDURE CanDoAlphaBlending*(): BOOLEAN;
BEGIN RETURN CCanBlend() # 0
END CanDoAlphaBlending;

(* Offscreens *)

PROCEDURE CloseOffscreen(s: Offscreen);
BEGIN
  IF s.h # 0 THEN COffscreenClose(s.h); s.h := 0; DEC(openOffscreens) END
END CloseOffscreen;

PROCEDURE FinalizeOffscreen(obj: SYSTEM.PTR);
BEGIN CloseOffscreen(SYSTEM.VAL(Offscreen, obj))
END FinalizeOffscreen;

(* s's handle, halting if it is closed. *)
PROCEDURE O(s: Offscreen): SYSTEM.ADDRESS;
BEGIN
  ASSERT(s # NIL, Fl.NilArgument); ASSERT(s.h # 0, Fl.ClosedResource);
  RETURN s.h
END O;

(* A picture of w by h, at the screen's resolution. *)
PROCEDURE OpenOffscreen*(s: Offscreen; w, h: INTEGER);
BEGIN
  ASSERT(s # NIL, Fl.NilArgument); ASSERT(s.h = 0, Fl.OpenedTwice);
  ASSERT((w > 0) & (h > 0), Fl.IndexOutOfRange);
  s.h := COffscreenNew(w, h); s.begun := FALSE; INC(openOffscreens);
  GarbageCollectedHeap.RegisterFinalizer(s, FinalizeOffscreen)
END OpenOffscreen;

PROCEDURE (s: Offscreen) IsOpen*(): BOOLEAN;
BEGIN RETURN s.h # 0
END IsOpen;

(* Drawing goes to s, from 0, 0, until End. Twice halts with Fl.OutOfOrder. *)
PROCEDURE (s: Offscreen) Begin*;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := O(s); ASSERT(~s.begun, Fl.OutOfOrder);
  COffscreenBegin(h); s.begun := TRUE; s.below := current; current := s
END Begin;

(* Sends drawing back where it went before Begin. s must be the offscreen
   last begun, with no surface of FlImages or FlPrint begun since. *)
PROCEDURE (s: Offscreen) End*;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := O(s); ASSERT(s.begun & (current = s) & (COffscreenCurrent(h) # 0), Fl.OutOfOrder);
  COffscreenEnd; s.begun := FALSE; current := s.below; s.below := NIL
END End;

(* Ends s if it is begun, and frees it; idempotent. *)
PROCEDURE (s: Offscreen) Close*;
BEGIN
  IF s.begun THEN s.End END;
  CloseOffscreen(s)
END Close;

(* Draws its w by h from sx, sy at x, y of where drawing goes. Halts with
   Fl.OutOfOrder while drawing goes to s itself. *)
PROCEDURE (s: Offscreen) Copy*(x, y, w, h, sx, sy: INTEGER);
  VAR a: SYSTEM.ADDRESS;
BEGIN
  a := O(s); ASSERT(~s.begun, Fl.OutOfOrder);
  COffscreenCopy(a, x, y, w, h, sx, sy)
END Copy;

(* After the screen's scale changes: keeps the picture, at the new one.
   Halts with Fl.OutOfOrder between Begin and End. *)
PROCEDURE (s: Offscreen) Rescale*;
  VAR a: SYSTEM.ADDRESS;
BEGIN
  a := O(s); ASSERT(~s.begun, Fl.OutOfOrder);
  COffscreenRescale(a)
END Rescale;

PROCEDURE AreaD(x, y, w, h: SYSTEM.INT32);
BEGIN area.Draw(x, y, w, h)
END AreaD;

BEGIN
  openOffscreens := 0;
  CRegister(AreaD, LineD)
END FlDraw.
