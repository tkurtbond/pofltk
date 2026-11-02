MODULE FlImages; (* Images: loaded from files or memory, made from pixels, drawn offscreen; multi-labels *)

(* An Image is a picture FLTK can draw: loaded from a PNG, JPEG, GIF, BMP,
   XPM, XBM, ICO, PNM or SVG file (the format told by its contents),
   decoded from bytes in memory, made from RGB pixels or the bits of a
   bitmap, or another image tiled. A Shared image is one of a pool, found
   by its file's name. An AnimGIF is an animated GIF, whose frames FLTK shows one after another
   in its canvas widget. It is a resource the program
   owns, as a TextBuffer is: Close it when done. A widget showing it as
   its label keeps it until the widget is deleted or shows another, so
   closing an image a widget shows is safe; so does a browser showing it
   on a line, and a menu showing it on an item. A MultiLabel puts text
   and images side by side, in a widget's label or a menu item. An image the program loses
   without closing is closed by the collector. Using a closed image halts
   (Fl.ClosedResource).

   An image is drawn in a Draw method, as the rest of FlDraw is; or into
   a Surface, an image being drawn offscreen, or a CopySurface, drawing
   for the clipboard.

   A FileIcon is a small picture of a kind of file, for file browsers and
   labels. It is not an Image, and it lasts the program: nothing frees
   one, since FLTK keeps its address wherever it shows.

   Bad data is not an error: a file that can't be read or decoded comes
   back as FALSE. An XPM file's colors should be written "#rrggbb": FLTK
   knows color names ("red") on X11 alone, and draws them gray under
   Wayland. The C++ part is FlImages.cpp. *)

IMPORT SYSTEM, GarbageCollectedHeap, Fl, FlBrowsers, FlMenus;

CONST
(* BEGIN generated constants: tools/gen-constants.py writes this block,
   from FLTK's headers; edit the script, not the block. *)

  (* how an animation starts (OpenAnimGIF, AnimGIF.SetCanvas): DontStart, not playing; the canvas
     not sized to it, or not showing it; OptimizeMemory, frames kept at their own sizes;
     AnimLog and AnimDebug, FLTK's reports of the decoding, on standard output *)
  DontStart* = {0};
  DontResizeCanvas* = {1};
  DontSetAsImage* = {2};
  OptimizeMemory* = {3};
  AnimLog* = {6};
  AnimDebug* = {7};

  (* how RGB images are scaled as they are drawn (SetScalingAlgorithm) *)
  ScalingNearest* = 0;
  ScalingBilinear* = 1;

  (* what a file icon is for (OpenFileIcon, FindFileIcon); IconAny, anything *)
  IconAny* = 0;
  IconPlain* = 1;
  IconFifo* = 2;
  IconDevice* = 3;
  IconLink* = 4;
  IconDirectory* = 5;

  (* what is drawn in a file icon (FileIcon.Add): a Line, ClosedLine or Polygon
     is its vertices, then IconEnd; IconColor, as a color, is the color the
     icon is drawn with *)
  IconEnd* = 0;
  IconLine* = 2;
  IconClosedLine* = 3;
  IconPolygon* = 4;
  IconColor* = -1;
(* END generated constants *)

  (* what an image is (Image.Kind) *)
  RGB* = 0;     (* pixels, 1 to 4 bytes each: PNG, JPEG, BMP, PNM, SVG, and those made from pixels *)
  Pixmap* = 1;  (* a palette: GIF, XPM *)
  Other* = 2;   (* a tiled image (OpenTiled) *)
  Animation* = 3;  (* an animated GIF (AnimGIF) *)
  Bitmap* = 4;  (* bits drawn in the current color, the rest not drawn: XBM, OpenBitmap *)

  MaxHeader* = 64;  (* the most of a file an ImageHandler is shown *)

TYPE
  Image* = POINTER TO ImageDesc;
  ImageDesc* = RECORD
    h: SYSTEM.ADDRESS
  END;

  (* An animated GIF (FLTK's Fl_Anim_GIF_Image): drawn as the frame it is
     at, which, as it plays, it moves on from FLTK's timers, redrawing its
     canvas, a widget that shows it. Every Image procedure takes one,
     except the Open procedures of other images: an AnimGIF is always an
     animation, and another Image never is (Fl.Unsupported). *)
  AnimGIF* = POINTER TO AnimGIFDesc;
  AnimGIFDesc* = RECORD (ImageDesc) END;

  (* An image of FLTK's pool (Fl_Shared_Image), found by its file's name and
     size: GetShared of a file already there shares its pixels. Each
     Shared holds one of its references (RefCount), which widgets showing
     it keep after Close, as for any Image. The last to let go takes it
     out of the pool: Close is FLTK's release. A change to its pixels (Scale, ColorAverage,
     Desaturate) reaches everyone sharing them. Every Image procedure takes one,
     except the Open procedures of other images: a Shared is always of
     the pool, and another Image never is (Fl.Unsupported). *)
  Shared* = POINTER TO SharedDesc;
  SharedDesc* = RECORD (ImageDesc) END;

  (* A file icon (FLTK's Fl_File_Icon): lines and polygons on a square 10000
     units a side, with 0, 0 at its bottom left, for files of a pattern.
     FLTK's list of them, First and Next, holds them in the order last
     made first; those FLTK made appear with no Open. *)
  (* Makes an image of a file that Load can't read, or returns NIL for
     the next handler to try (AddHandler). header is the file's first n
     bytes, at most MaxHeader, followed by a 0X, which may also come
     among them. *)
  ImageHandler* = PROCEDURE (name-, header-: ARRAY OF CHAR; n: INTEGER): Image;
  HandlerLink = POINTER TO RECORD
    handler: ImageHandler;
    next: HandlerLink
  END;

  FileIcon* = POINTER TO FileIconDesc;
  FileIconDesc* = RECORD
    h: SYSTEM.ADDRESS;
    next: FileIcon  (* every object made: a browser or label keeps the icon *)
  END;

  (* A label of two parts, drawn side by side (FLTK's Fl_Multi_Label):
     each nothing, text, an image, or another multi-label, for more parts.
     A resource, as an Image is: the widgets and menu items showing it
     keep it, and it keeps its parts. *)
  MultiLabel* = POINTER TO MultiLabelDesc;
  MultiLabelDesc* = RECORD
    h: SYSTEM.ADDRESS
  END;

  (* Something drawn on offscreen: between Begin and End, FlDraw's
     drawing goes into it. *)
  WidgetSurface* = POINTER TO WidgetSurfaceDesc;
  WidgetSurfaceDesc* = RECORD
    h: SYSTEM.ADDRESS;
    below: WidgetSurface;  (* the surface begun before this one *)
    begun: BOOLEAN
  END;

  (* An image being drawn. *)
  Surface* = POINTER TO SurfaceDesc;
  SurfaceDesc* = RECORD (WidgetSurfaceDesc)
    masked: BOOLEAN  (* FLTK holds a mask GetImage hasn't used *)
  END;

  (* Drawing for the clipboard, put there by Close. *)
  CopySurface* = POINTER TO CopySurfaceDesc;
  CopySurfaceDesc* = RECORD (WidgetSurfaceDesc) END;

VAR
  openImages-: INTEGER;    (* images made and not yet closed or finalized *)
  openSurfaces-: INTEGER;  (* the same, for surfaces *)
  openMultiLabels-: INTEGER;  (* the same, for multi-labels *)
  current: WidgetSurface;  (* the surface last begun and not ended *)
  icons: FileIcon;         (* the objects of file icons *)
  handlers: HandlerLink;   (* in the order they were added *)

PROCEDURE ["C", "ofl_image_load"] CLoad(name: ARRAY OF CHAR): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_image_load_data"] CLoadData(data: ARRAY OF CHAR; n: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_image_ico"] CICO(name, data: SYSTEM.ADDRESS; n, id: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_image_ico_count"] CICOCount(name, data: SYSTEM.ADDRESS; n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_image_bitmap"] CBitmap(bits: ARRAY OF CHAR; w, h: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_image_xpm"] CXPM(lines: ARRAY OF ARRAY OF CHAR; n, stride: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_image_draw_pixmap"] CDrawPixmap(lines: ARRAY OF ARRAY OF CHAR; n, stride, x, y, bg: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_image_measure_pixmap"] CMeasurePixmap(lines: ARRAY OF ARRAY OF CHAR; n, stride: SYSTEM.INT32; VAR w, h: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_image_rgb"] CRGB(bits: ARRAY OF CHAR; w, h, d, ld: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_image_close"] CClose(i: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_image_get"] CGet(i: SYSTEM.ADDRESS; what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_image_copy"] CCopy(i: SYSTEM.ADDRESS; w, h: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_image_scale"] CScale(i: SYSTEM.ADDRESS; w, h, proportional, expand: SYSTEM.INT32);
PROCEDURE ["C", "ofl_image_change"] CChange(i: SYSTEM.ADDRESS; what, c: SYSTEM.INT32; weight: LONGREAL);
PROCEDURE ["C", "ofl_image_draw"] CDraw(i: SYSTEM.ADDRESS; x, y, w, h, cx, cy: SYSTEM.INT32);
PROCEDURE ["C", "ofl_image_pixel"] CPixel(i: SYSTEM.ADDRESS; x, y: SYSTEM.INT32; VAR r, g, b, a: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_image_save_png"] CSavePNG(i: SYSTEM.ADDRESS; name: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_image_copy_to_clipboard"] CCopyToClipboard(i: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_take_pasted_image"] CTakePastedImage(): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_anim_load"] CAnimLoad(name: SYSTEM.ADDRESS; data: SYSTEM.ADDRESS; n: SYSTEM.INT32; canvas: SYSTEM.ADDRESS; flags: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_anim_canvas"] CAnimCanvas(a, w: SYSTEM.ADDRESS; flags: SYSTEM.INT32);
PROCEDURE ["C", "ofl_anim_canvas_object"] CAnimCanvasObject(a: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_anim_get"] CAnimGet(a: SYSTEM.ADDRESS; what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_anim_frame_get"] CAnimFrameGet(a: SYSTEM.ADDRESS; what, n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_anim_do"] CAnimDo(a: SYSTEM.ADDRESS; what: SYSTEM.INT32);
PROCEDURE ["C", "ofl_anim_set_frame"] CAnimSetFrame(a: SYSTEM.ADDRESS; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_anim_delay"] CAnimDelay(a: SYSTEM.ADDRESS; n: SYSTEM.INT32): LONGREAL;
PROCEDURE ["C", "ofl_anim_set_delay"] CAnimSetDelay(a: SYSTEM.ADDRESS; n: SYSTEM.INT32; d: LONGREAL);
PROCEDURE ["C", "ofl_anim_speed"] CAnimSpeed(a: SYSTEM.ADDRESS): LONGREAL;
PROCEDURE ["C", "ofl_anim_set_speed"] CAnimSetSpeed(a: SYSTEM.ADDRESS; s: LONGREAL);
PROCEDURE ["C", "ofl_anim_resize"] CAnimResize(a: SYSTEM.ADDRESS; w, h: SYSTEM.INT32; scale: LONGREAL);
PROCEDURE ["C", "ofl_anim_name"] CAnimName(a: SYSTEM.ADDRESS; VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_anim_frame_image"] CAnimFrameImage(a: SYSTEM.ADDRESS; n: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_image_setting"] CSetting(which: SYSTEM.INT32): LONGREAL;
PROCEDURE ["C", "ofl_image_set_setting"] CSetSetting(which: SYSTEM.INT32; v: LONGREAL);
PROCEDURE ["C", "ofl_multi_new"] CMultiNew(): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_multi_close"] CMultiClose(m: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_multi_set"] CMultiSet(m: SYSTEM.ADDRESS; i, kind: SYSTEM.INT32; s: ARRAY OF CHAR; t: SYSTEM.INT32; p: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_multi_contains"] CMultiContains(m, n: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_multi_label"] CWidgetMultiLabel(w: SYSTEM.ADDRESS; m: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_menu_item_label"] CMenuItemLabel(m: SYSTEM.ADDRESS; i, kind: SYSTEM.INT32; p: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_browser_icon"] CBrowserIcon(b: SYSTEM.ADDRESS; line: SYSTEM.INT32; i: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_tree_icon"] CTreeIcon(t: SYSTEM.ADDRESS; what: SYSTEM.INT32; i: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_tree_item_icon"] CTreeItemIcon(t, p: SYSTEM.ADDRESS; what: SYSTEM.INT32; i: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_image"] CWidgetImage(w: SYSTEM.ADDRESS; slot: SYSTEM.INT32; i: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_window_icon"] CWindowIcon(w, i: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_window_shape"] CWindowShape(w, i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_window_image_cursor"] CWindowCursor(w, i: SYSTEM.ADDRESS; hotx, hoty: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_image_tiled"] CTiled(t: SYSTEM.ADDRESS; w, h: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_surface_new"] CSurfaceNew(w, h: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_surface_close"] CSurfaceClose(s: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_surface_begin"] CSurfaceBegin(s: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_surface_end"] CSurfaceEnd;
PROCEDURE ["C", "ofl_surface_current"] CSurfaceCurrent(s: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_surface_draw"] CSurfaceDraw(s, w: SYSTEM.ADDRESS; x, y: SYSTEM.INT32);
PROCEDURE ["C", "ofl_surface_decorated"] CSurfaceDecorated(s, w: SYSTEM.ADDRESS; x, y: SYSTEM.INT32);
PROCEDURE ["C", "ofl_surface_image"] CSurfaceImage(s: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_surface_mask"] CSurfaceMask(s, m: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_copy_new"] CCopyNew(w, h: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_read_image"] CReadImage(x, y, w, h, alpha: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_image_capture"] CCapture(win: SYSTEM.ADDRESS; x, y, w, h: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_shared_get"] CSharedGet(name: ARRAY OF CHAR; w, h: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_shared_find"] CSharedFind(name: ARRAY OF CHAR; w, h: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_shared_of_image"] CSharedOfImage(i: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_shared_count"] CSharedCount(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_shared_refcount"] CSharedRefCount(s: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_shared_original"] CSharedOriginal(s: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_shared_name"] CSharedName(s: SYSTEM.ADDRESS; VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_shared_reload"] CSharedReload(s: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_register_images"] CRegisterImages;
PROCEDURE ["C", "ofl_add_image_handler"] CAddHandler(f: PROCEDURE (name, header: SYSTEM.ADDRESS; n: SYSTEM.INT32): SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_file_icon_new"] CIconNew(pattern: ARRAY OF CHAR; type: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_file_icon_free"] CIconFree(i: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_file_icon_add"] CIconAdd(i: SYSTEM.ADDRESS; what, a, b: SYSTEM.INT32);
PROCEDURE ["C", "ofl_file_icon_clear"] CIconClear(i: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_file_icon_load"] CIconLoad(i: SYSTEM.ADDRESS; name: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_file_icon_load_system"] CIconLoadSystem;
PROCEDURE ["C", "ofl_file_icon_find"] CIconFind(name: ARRAY OF CHAR; type: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_file_icon_first"] CIconFirst(): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_file_icon_next"] CIconNext(i: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_file_icon_draw"] CIconDraw(i: SYSTEM.ADDRESS; x, y, w, h, color, active: SYSTEM.INT32);
PROCEDURE ["C", "ofl_file_icon_label"] CIconLabel(i, w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_file_icon_size"] CIconSize(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_file_icon_type"] CIconType(i: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_file_icon_pattern"] CIconPattern(i: SYSTEM.ADDRESS; VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_file_browser_add"] CFileBrowserAdd(b: SYSTEM.ADDRESS; s: ARRAY OF CHAR; i: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_file_browser_icon"] CFileBrowserIcon(b: SYSTEM.ADDRESS; line: SYSTEM.INT32; i: SYSTEM.ADDRESS);

PROCEDURE Int(b: BOOLEAN): SYSTEM.INT32;
BEGIN IF b THEN RETURN 1 ELSE RETURN 0 END
END Int;

(* Images *)

PROCEDURE CloseHandle(i: Image);
BEGIN
  IF i.h # 0 THEN CClose(i.h); i.h := 0; DEC(openImages) END
END CloseHandle;

(* GC finalizer: an image lost without Close. *)
PROCEDURE FinalizeImage(obj: SYSTEM.PTR);
BEGIN CloseHandle(SYSTEM.VAL(Image, obj))
END FinalizeImage;

(* Makes i the image h, if h isn't 0; TRUE if it is. *)
PROCEDURE Opened(i: Image; h: SYSTEM.ADDRESS): BOOLEAN;
BEGIN
  IF h = 0 THEN RETURN FALSE END;
  i.h := h; INC(openImages);
  GarbageCollectedHeap.RegisterFinalizer(i, FinalizeImage);
  RETURN TRUE
END Opened;

PROCEDURE New(i: Image);
BEGIN
  ASSERT(i # NIL, Fl.NilArgument); ASSERT(i.h = 0, Fl.OpenedTwice);
  ASSERT(~(i IS AnimGIF) & ~(i IS Shared), Fl.Unsupported)
END New;

PROCEDURE NewAnim(a: Image);
BEGIN
  ASSERT(a # NIL, Fl.NilArgument); ASSERT(a.h = 0, Fl.OpenedTwice);
  ASSERT(a IS AnimGIF, Fl.Unsupported)
END NewAnim;

PROCEDURE NewShared(s: Image);
BEGIN
  ASSERT(s # NIL, Fl.NilArgument); ASSERT(s.h = 0, Fl.OpenedTwice);
  ASSERT(s IS Shared, Fl.Unsupported)
END NewShared;

(* i's handle, halting if i is closed. *)
PROCEDURE Hd(i: Image): SYSTEM.ADDRESS;
BEGIN
  ASSERT(i # NIL, Fl.NilArgument); ASSERT(i.h # 0, Fl.ClosedResource);
  RETURN i.h
END Hd;

(* For pofltk's modules only: i's handle, for a C++ part of another
   library. It halts if i is closed. *)
PROCEDURE ImageHandle*(i: Image): SYSTEM.ADDRESS;
BEGIN RETURN Hd(i)
END ImageHandle;

(* Makes i the image in file name; FALSE, and i not open, if the file
   can't be read, or isn't an image FLTK can decode. *)
PROCEDURE Load*(i: Image; name-: ARRAY OF CHAR): BOOLEAN;
BEGIN New(i); RETURN Opened(i, CLoad(name))
END Load;

(* Makes i the image in the first n bytes of data: a PNG, JPEG, GIF, BMP,
   XBM, ICO or SVG file's contents (FLTK reads XPM and PNM from files
   alone), which are decoded, not kept; FALSE, and i not open, if they
   can't be decoded. Of an ICO, the largest image. *)
PROCEDURE LoadData*(i: Image; data-: ARRAY OF CHAR; n: INTEGER): BOOLEAN;
BEGIN
  New(i); ASSERT((n >= 0) & (n <= LEN(data)), Fl.IndexOutOfRange);
  RETURN Opened(i, CLoadData(data, n))
END LoadData;

(* Makes i image id of an ICO file, 0 its first, or -1 its largest. FALSE
   if the file can't be read or decoded, or has no such image. *)
PROCEDURE LoadICO*(i: Image; name-: ARRAY OF CHAR; id: INTEGER): BOOLEAN;
BEGIN
  New(i);
  RETURN Opened(i, CICO(SYSTEM.ADR(name), 0, 0, id))
END LoadICO;

(* LoadICO of the first n bytes of data. *)
PROCEDURE LoadICOData*(i: Image; data-: ARRAY OF CHAR; n, id: INTEGER): BOOLEAN;
BEGIN
  New(i); ASSERT((n >= 0) & (n <= LEN(data)), Fl.IndexOutOfRange);
  RETURN Opened(i, CICO(0, SYSTEM.ADR(data), n, id))
END LoadICOData;

(* How many images an ICO file has; 0 if it isn't one. *)
PROCEDURE ICOCount*(name-: ARRAY OF CHAR): INTEGER;
BEGIN RETURN CICOCount(SYSTEM.ADR(name), 0, 0)
END ICOCount;

(* ICOCount of the first n bytes of data. *)
PROCEDURE ICODataCount*(data-: ARRAY OF CHAR; n: INTEGER): INTEGER;
BEGIN
  ASSERT((n >= 0) & (n <= LEN(data)), Fl.IndexOutOfRange);
  RETURN CICOCount(0, SYSTEM.ADR(data), n)
END ICODataCount;

(* Makes i a bitmap of w by h pixels from bits, which it copies: rows of
   (w + 7) DIV 8 bytes, the lowest bit of a byte leftmost, as an XBM file
   writes them. Its set bits are drawn in the color last set, and the
   rest not at all, so it has no pixels to read. *)
PROCEDURE OpenBitmap*(i: Image; bits-: ARRAY OF CHAR; w, h: INTEGER);
BEGIN
  New(i); ASSERT((w > 0) & (h > 0), Fl.IndexOutOfRange);
  ASSERT(LEN(bits) DIV h >= (w + 7) DIV 8, Fl.IndexOutOfRange);
  ASSERT(Opened(i, CBitmap(bits, w, h)))  (* out of memory *)
END OpenBitmap;

(* Makes i the pixmap in the first n of lines, which are copied: the
   strings of an XPM file, without their quotes. The first holds the
   width, height, number of colors and characters a pixel (1 or 2); one
   line a color follows, then one a row of pixels. FALSE, and i not open,
   if the lines don't match the first, or can't be decoded. *)
PROCEDURE OpenXPM*(i: Image; lines-: ARRAY OF ARRAY OF CHAR; n: INTEGER): BOOLEAN;
BEGIN
  New(i); ASSERT((n >= 0) & (n <= LEN(lines)), Fl.IndexOutOfRange);
  RETURN Opened(i, CXPM(lines, n, SHORT(LEN(lines, 1))))
END OpenXPM;

(* Draws the pixmap in the lines OpenXPM takes at x, y, without keeping it,
   with bg as its color "None" where it can't be transparent. FALSE, and
   nothing drawn, if they don't make one. *)
PROCEDURE DrawPixmap*(lines-: ARRAY OF ARRAY OF CHAR; n, x, y, bg: INTEGER): BOOLEAN;
BEGIN
  ASSERT((n >= 0) & (n <= LEN(lines)), Fl.IndexOutOfRange);
  RETURN CDrawPixmap(lines, n, SHORT(LEN(lines, 1)), x, y, bg) # 0
END DrawPixmap;

(* The size of that pixmap. FALSE, and w and h unchanged, if there is none. *)
PROCEDURE MeasurePixmap*(lines-: ARRAY OF ARRAY OF CHAR; n: INTEGER; VAR w, h: INTEGER): BOOLEAN;
  VAR a, b: SYSTEM.INT32;
BEGIN
  ASSERT((n >= 0) & (n <= LEN(lines)), Fl.IndexOutOfRange);
  IF CMeasurePixmap(lines, n, SHORT(LEN(lines, 1)), a, b) = 0 THEN RETURN FALSE END;
  w := a; h := b;
  RETURN TRUE
END MeasurePixmap;

(* Makes i an image of w by h pixels, from bits, which are copied: d
   bytes a pixel (1 gray, 2 gray and alpha, 3 red, green and blue, 4 those
   and alpha), rows starting ld bytes apart, 0 for w * d. *)
PROCEDURE OpenRGB*(i: Image; bits-: ARRAY OF CHAR; w, h, d, ld: INTEGER);
  VAR row: INTEGER;
BEGIN
  New(i);
  ASSERT((w > 0) & (h > 0) & (d >= 1) & (d <= 4) & ((ld = 0) OR (ld >= w * d)), Fl.IndexOutOfRange);
  IF ld = 0 THEN row := w * d ELSE row := ld END;
  ASSERT(row * h <= LEN(bits), Fl.IndexOutOfRange);
  ASSERT(Opened(i, CRGB(bits, w, h, d, ld)))  (* out of memory *)
END OpenRGB;

(* Makes i the image tile, repeated to fill w by h pixels, or, if both
   are 0, the window it is drawn in: as the image of a box filling the
   window, a background. i holds tile, which may be closed. *)
PROCEDURE OpenTiled*(i, tile: Image; w, h: INTEGER);
  VAR t: SYSTEM.ADDRESS;
BEGIN
  t := Hd(tile); New(i); ASSERT((w >= 0) & (h >= 0), Fl.IndexOutOfRange);
  ASSERT(Opened(i, CTiled(t, w, h)))  (* out of memory *)
END OpenTiled;

(* Makes copy a copy of i's data, at w by h pixels: scaled, with FLTK's
   own scaling. A copy of an AnimGIF is one, with no canvas, playing if i
   has a frame shown, playing or not (doc/fltk-issues.md, 64). A copy of a
   Shared must be a Shared, and is the pool's entry of that size, with a
   reference of its own: of i's own size, the same image. *)
PROCEDURE (i: Image) Copy*(copy: Image; w, h: INTEGER);
  VAR s: SYSTEM.ADDRESS;
BEGIN
  s := Hd(i);
  IF i IS AnimGIF THEN NewAnim(copy)
  ELSIF i IS Shared THEN NewShared(copy)
  ELSE New(copy)
  END;
  ASSERT((w > 0) & (h > 0), Fl.IndexOutOfRange);
  ASSERT(Opened(copy, CCopy(s, w, h)))  (* out of memory *)
END Copy;

(* Gives up the program's hold on i; idempotent. Widgets showing i keep
   it. *)
PROCEDURE (i: Image) Close*;
BEGIN CloseHandle(i)
END Close;

PROCEDURE (i: Image) IsOpen*(): BOOLEAN;
BEGIN RETURN i.h # 0
END IsOpen;

(* The size i is drawn at: its data's, unless Scale changed it. *)
PROCEDURE (i: Image) W*(): INTEGER;
BEGIN RETURN CGet(Hd(i), 0)
END W;

PROCEDURE (i: Image) H*(): INTEGER;
BEGIN RETURN CGet(Hd(i), 1)
END H;

(* The size of i's data, in pixels. *)
PROCEDURE (i: Image) DataW*(): INTEGER;
BEGIN RETURN CGet(Hd(i), 3)
END DataW;

PROCEDURE (i: Image) DataH*(): INTEGER;
BEGIN RETURN CGet(Hd(i), 4)
END DataH;

(* Bytes a pixel, 1 to 4, as OpenRGB takes them; a Pixmap's as Pixel
   reads it, 4; a Bitmap's, 0. *)
PROCEDURE (i: Image) Depth*(): INTEGER;
BEGIN RETURN CGet(Hd(i), 2)
END Depth;

(* RGB, Pixmap or Other. *)
PROCEDURE (i: Image) Kind*(): INTEGER;
BEGIN RETURN CGet(Hd(i), 5)
END Kind;

(* Draws i at w by h pixels from now on, its data unchanged; keeping its
   proportions if proportional, within w by h, and larger than its data
   only if expand. *)
PROCEDURE (i: Image) Scale*(w, h: INTEGER; proportional, expand: BOOLEAN);
BEGIN CScale(Hd(i), w, h, Int(proportional), Int(expand))
END Scale;

(* Blends i's pixels with color c, a color of Fl's: weight 1 leaves them,
   0 makes them c. A Bitmap has none, and stays as it is. *)
PROCEDURE (i: Image) ColorAverage*(c: INTEGER; weight: REAL);
BEGIN CChange(Hd(i), 0, c, weight)
END ColorAverage;

(* Makes i's pixels gray. *)
PROCEDURE (i: Image) Desaturate*;
BEGIN CChange(Hd(i), 1, 0, 0)
END Desaturate;

(* Makes i look inactive, as FLTK draws an inactive label image. *)
PROCEDURE (i: Image) Inactive*;
BEGIN CChange(Hd(i), 0, Fl.Gray, 0.33)
END Inactive;

(* Draws i with its top left at x, y, in a Draw method or on a Surface. *)
PROCEDURE (i: Image) Draw*(x, y: INTEGER);
  VAR h: SYSTEM.ADDRESS;
BEGIN h := Hd(i); CDraw(h, x, y, CGet(h, 0), CGet(h, 1), 0, 0)
END Draw;

(* Draws the w by h part of i at cx, cy, at x, y. *)
PROCEDURE (i: Image) DrawPart*(x, y, w, h, cx, cy: INTEGER);
BEGIN CDraw(Hd(i), x, y, w, h, cx, cy)
END DrawPart;

(* i's handle, halting unless x, y is in its data. *)
PROCEDURE P(i: Image; x, y: INTEGER): SYSTEM.ADDRESS;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Hd(i);
  ASSERT((x >= 0) & (y >= 0) & (x < CGet(h, 3)) & (y < CGet(h, 4)), Fl.IndexOutOfRange);
  RETURN h
END P;

(* Pixel x, y of i's data, as Fl.RGB gives a color; gray, r = g = b. A
   tiled image and a Bitmap have no pixels to read (Fl.ClosedResource). *)
PROCEDURE (i: Image) Pixel*(x, y: INTEGER): INTEGER;
  VAR r, g, b, a: SYSTEM.INT32;
BEGIN
  ASSERT(CPixel(P(i, x, y), x, y, r, g, b, a) # 0, Fl.ClosedResource);  (* no pixels to read *)
  RETURN Fl.RGB(r, g, b)
END Pixel;

(* Its alpha, 0 transparent to 255 opaque; 255 if i has none. *)
PROCEDURE (i: Image) Alpha*(x, y: INTEGER): INTEGER;
  VAR r, g, b, a: SYSTEM.INT32;
BEGIN
  ASSERT(CPixel(P(i, x, y), x, y, r, g, b, a) # 0, Fl.ClosedResource);
  RETURN a
END Alpha;

(* Writes i to file name as a PNG; FALSE if it couldn't, as for an image
   with no pixels to read. *)
PROCEDURE (i: Image) SavePNG*(name-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CSavePNG(Hd(i), name) # 0
END SavePNG;

(* The clipboard *)

(* Puts i on the clipboard, as the window system's own image. *)
PROCEDURE (i: Image) CopyToClipboard*;
BEGIN CCopyToClipboard(Hd(i))
END CopyToClipboard;

(* In a Handle of an EvPaste that carries an image (Fl.PasteImage,
   Fl.EventIsImage), makes i that image, now the program's; FALSE, and i
   not open, if the event carries none. An image no Handle takes is
   freed after the event. *)
PROCEDURE TakePastedImage*(i: Image): BOOLEAN;
BEGIN New(i); RETURN Opened(i, CTakePastedImage())
END TakePastedImage;

(* Widgets and windows *)

PROCEDURE Handle(i: Image): SYSTEM.ADDRESS;
BEGIN IF i = NIL THEN RETURN 0 ELSE RETURN Hd(i) END
END Handle;

(* Shows i in w's label, as Fl.Widget.SetAlign places it; NIL for none.
   w keeps i until it shows another, or is deleted. *)
PROCEDURE SetImage*(w: Fl.Widget; i: Image);
BEGIN CWidgetImage(Fl.Live(w), 0, Handle(i))
END SetImage;

(* The same, for when w is inactive; with none, FLTK draws the image
   grayed. *)
PROCEDURE SetInactiveImage*(w: Fl.Widget; i: Image);
BEGIN CWidgetImage(Fl.Live(w), 1, Handle(i))
END SetInactiveImage;

(* The icon the window system shows for win, copied; NIL for none.
   Wayland has none, and ignores it. *)
PROCEDURE SetIcon*(win: Fl.Window; i: Image);
BEGIN CWindowIcon(Fl.Live(win), Handle(i))
END SetIcon;

(* Shapes win as i's pixels that aren't transparent, or for an image
   with no alpha, aren't black, scaled to win's size, and takes away its
   border; the rest of win is not drawn, and takes no clicks. win keeps a
   copy of i. An image with no pixels to read, a tiled one or a Bitmap,
   halts (Fl.Unsupported). FLTK can't make win a rectangle again. *)
PROCEDURE SetShape*(win: Fl.Window; i: Image);
BEGIN ASSERT(CWindowShape(Fl.Live(win), Hd(i)) # 0, Fl.Unsupported)
END SetShape;

(* Makes i the cursor over win, and over the window it is in; hotx, hoty
   is the point of i that clicks, which must be in it (Fl.IndexOutOfRange).
   FLTK takes a copy. It does nothing in a window not shown, and on X11
   without Xcursor it shows the default cursor. An image with no pixels to
   read, a tiled one or a Bitmap, halts (Fl.Unsupported). Window.SetCursor
   sets a standard cursor again. *)
PROCEDURE SetCursor*(win: Fl.Window; i: Image; hotx, hoty: INTEGER);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Fl.Live(win);
  ASSERT((hotx >= 0) & (hotx < i.W()) & (hoty >= 0) & (hoty < i.H()), Fl.IndexOutOfRange);
  ASSERT(CWindowCursor(h, Hd(i), hotx, hoty) # 0, Fl.Unsupported)
END SetCursor;

(* Shows i at the left of b's line, which is 1 to b.Count(); NIL for
   none. The line is made as tall as the image. b keeps i while a line
   shows it. *)
PROCEDURE SetLineIcon*(b: FlBrowsers.Browser; line: INTEGER; i: Image);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Fl.Live(b); ASSERT((line >= 1) & (line <= b.Count()), Fl.IndexOutOfRange);
  CBrowserIcon(h, line, Handle(i))
END SetLineIcon;

(* The icons of t, which it keeps while it shows them; NIL for none. An
   item with children shows the open icon when closed, for opening it,
   and the close icon when open, in place of FLTK's [+] and [-]. Every
   item shows the user icon, unless it has one of its own. FLTK makes
   their inactive forms. *)
PROCEDURE SetOpenIcon*(t: FlBrowsers.Tree; i: Image);
BEGIN CTreeIcon(Fl.Live(t), 0, Handle(i))
END SetOpenIcon;

PROCEDURE SetCloseIcon*(t: FlBrowsers.Tree; i: Image);
BEGIN CTreeIcon(Fl.Live(t), 1, Handle(i))
END SetCloseIcon;

PROCEDURE SetUserIcon*(t: FlBrowsers.Tree; i: Image);
BEGIN CTreeIcon(Fl.Live(t), 2, Handle(i))
END SetUserIcon;

(* The icon of item alone, and the one it shows while inactive, which
   without this is none: FLTK makes this form only of a tree's icons. *)
PROCEDURE SetItemIcon*(item: FlBrowsers.TreeItem; i: Image);
  VAR t, p: SYSTEM.ADDRESS;
BEGIN FlBrowsers.ItemHandles(item, t, p); CTreeItemIcon(t, p, 0, Handle(i))
END SetItemIcon;

PROCEDURE SetItemInactiveIcon*(item: FlBrowsers.TreeItem; i: Image);
  VAR t, p: SYSTEM.ADDRESS;
BEGIN FlBrowsers.ItemHandles(item, t, p); CTreeItemIcon(t, p, 1, Handle(i))
END SetItemInactiveIcon;

(* Animated GIFs *)

PROCEDURE Canvas(w: Fl.Widget): SYSTEM.ADDRESS;
BEGIN IF w = NIL THEN RETURN 0 ELSE RETURN Fl.Live(w) END
END Canvas;

(* Makes a the animation in GIF file name, with canvas, NIL for none:
   the canvas is sized to the animation and shows it, and it starts
   playing, unless flags say not. FALSE, and a not open, if the file
   can't be read, or isn't a GIF FLTK can decode. *)
PROCEDURE OpenAnimGIF*(a: AnimGIF; name-: ARRAY OF CHAR; canvas: Fl.Widget; flags: SET): BOOLEAN;
BEGIN
  NewAnim(a);
  RETURN Opened(a, CAnimLoad(SYSTEM.ADR(name), 0, 0, Canvas(canvas), ORD(flags)))
END OpenAnimGIF;

(* The same, decoded from the first n bytes of data, with no name. *)
PROCEDURE OpenAnimGIFData*(a: AnimGIF; data-: ARRAY OF CHAR; n: INTEGER; canvas: Fl.Widget; flags: SET): BOOLEAN;
BEGIN
  NewAnim(a); ASSERT((n >= 0) & (n <= LEN(data)), Fl.IndexOutOfRange);
  RETURN Opened(a, CAnimLoad(0, SYSTEM.ADR(data), n, Canvas(canvas), ORD(flags)))
END OpenAnimGIFData;

(* Makes w a's canvas, NIL for none, with flags as OpenAnimGIF's
   (DontStart aside): the old canvas, as in FLTK, loses its image, a or
   not. A playing animation starts again. A canvas deleted is no longer
   a's. *)
PROCEDURE (a: AnimGIF) SetCanvas*(w: Fl.Widget; flags: SET);
BEGIN CAnimCanvas(Hd(a), Canvas(w), ORD(flags))
END SetCanvas;

(* NIL for none. *)
PROCEDURE (a: AnimGIF) Canvas*(): Fl.Widget;
  VAR o: SYSTEM.ADDRESS;
BEGIN
  o := CAnimCanvasObject(Hd(a));
  IF o = 0 THEN RETURN NIL ELSE RETURN SYSTEM.VAL(Fl.Widget, o) END
END Canvas;

(* The number of frames, from 1 up. *)
PROCEDURE (a: AnimGIF) Frames*(): INTEGER;
BEGIN RETURN CAnimGet(Hd(a), 0)
END Frames;

(* The frame shown, from 0 to Frames() - 1. *)
PROCEDURE (a: AnimGIF) Frame*(): INTEGER;
BEGIN RETURN CAnimGet(Hd(a), 1)
END Frame;

(* Shows frame n, redrawing the canvas. Not while a plays, which halts
   (Fl.Unsupported). *)
PROCEDURE (a: AnimGIF) SetFrame*(n: INTEGER);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Hd(a); ASSERT((n >= 0) & (n < CAnimGet(h, 0)), Fl.IndexOutOfRange);
  ASSERT(CAnimGet(h, 4) = 0, Fl.Unsupported);
  CAnimSetFrame(h, n)
END SetFrame;

(* Plays from the next frame. *)
PROCEDURE (a: AnimGIF) Start*;
BEGIN CAnimDo(Hd(a), 0)
END Start;

PROCEDURE (a: AnimGIF) Stop*;
BEGIN CAnimDo(Hd(a), 1)
END Stop;

(* Shows the next frame, the first after the last, unless a plays. *)
PROCEDURE (a: AnimGIF) Next*;
BEGIN CAnimDo(Hd(a), 2)
END Next;

(* Whether a is playing: it stops after the number of times the GIF says
   to repeat it, typically never. *)
PROCEDURE (a: AnimGIF) Playing*(): BOOLEAN;
BEGIN RETURN CAnimGet(Hd(a), 4) # 0
END Playing;

(* Whether a has more than one frame. *)
PROCEDURE (a: AnimGIF) IsAnimated*(): BOOLEAN;
BEGIN RETURN CAnimGet(Hd(a), 6) # 0
END IsAnimated;

(* How long frame n is shown, in seconds, as the GIF says: 0 for one
   that isn't animated. Playing, a shows it for SetAnimMinDelay's delay
   at least. *)
PROCEDURE (a: AnimGIF) Delay*(n: INTEGER): LONGREAL;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Hd(a); ASSERT((n >= 0) & (n < CAnimGet(h, 0)), Fl.IndexOutOfRange);
  RETURN CAnimDelay(h, n)
END Delay;

PROCEDURE (a: AnimGIF) SetDelay*(n: INTEGER; d: LONGREAL);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Hd(a); ASSERT((n >= 0) & (n < CAnimGet(h, 0)), Fl.IndexOutOfRange);
  CAnimSetDelay(h, n, d)
END SetDelay;

(* How fast a plays: 1 as the GIF says, 2 twice as fast. *)
PROCEDURE (a: AnimGIF) Speed*(): LONGREAL;
BEGIN RETURN CAnimSpeed(Hd(a))
END Speed;

PROCEDURE (a: AnimGIF) SetSpeed*(s: LONGREAL);
BEGIN CAnimSetSpeed(Hd(a), s)
END SetSpeed;

(* The size of the GIF's own canvas, or the one Resize gave. *)
PROCEDURE (a: AnimGIF) CanvasW*(): INTEGER;
BEGIN RETURN CAnimGet(Hd(a), 2)
END CanvasW;

PROCEDURE (a: AnimGIF) CanvasH*(): INTEGER;
BEGIN RETURN CAnimGet(Hd(a), 3)
END CanvasH;

(* Where frame n is drawn, in the canvas: the whole of it, unless a was
   opened with OptimizeMemory and the GIF gives the frame less. *)
PROCEDURE (a: AnimGIF) FrameXYWH*(n: INTEGER; VAR x, y, w, h: INTEGER);
  VAR k: SYSTEM.ADDRESS;
BEGIN
  k := Hd(a); ASSERT((n >= 0) & (n < CAnimGet(k, 0)), Fl.IndexOutOfRange);
  x := CAnimFrameGet(k, 0, n); y := CAnimFrameGet(k, 1, n);
  w := CAnimFrameGet(k, 2, n); h := CAnimFrameGet(k, 3, n)
END FrameXYWH;

(* Makes i a copy of frame n's image. *)
PROCEDURE (a: AnimGIF) FrameImage*(n: INTEGER; i: Image);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Hd(a); ASSERT((n >= 0) & (n < CAnimGet(h, 0)), Fl.IndexOutOfRange);
  New(i); ASSERT(Opened(i, CAnimFrameImage(h, n)))  (* out of memory *)
END FrameImage;

(* Whether each frame is drawn afresh, rather than kept ready to draw:
   less memory, more time. FALSE to start with. *)
PROCEDURE (a: AnimGIF) FrameUncache*(): BOOLEAN;
BEGIN RETURN CAnimGet(Hd(a), 5) # 0
END FrameUncache;

PROCEDURE (a: AnimGIF) SetFrameUncache*(on: BOOLEAN);
BEGIN IF on THEN CAnimDo(Hd(a), 3) ELSE CAnimDo(Hd(a), 4) END
END SetFrameUncache;

(* Scales every frame to w by h pixels, or to the canvas's size if both
   are 0, sizing the canvas too unless SetCanvas said not. *)
PROCEDURE (a: AnimGIF) Resize*(w, h: INTEGER);
BEGIN ASSERT((w >= 0) & (h >= 0), Fl.IndexOutOfRange); CAnimResize(Hd(a), w, h, 0.0D0)
END Resize;

(* The same, to scale times its size. *)
PROCEDURE (a: AnimGIF) ResizeBy*(scale: LONGREAL);
BEGIN ASSERT(scale > 0.0D0, Fl.IndexOutOfRange); CAnimResize(Hd(a), -1, 0, scale)
END ResizeBy;

(* The name of the file a was loaded from; "" for memory. *)
PROCEDURE (a: AnimGIF) GetName*(VAR s: ARRAY OF CHAR);
BEGIN CAnimName(Hd(a), s, SHORT(LEN(s)))
END GetName;

(* The least delay between any animation's frames, in seconds; 0, none,
   to start with. *)
PROCEDURE AnimMinDelay*(): LONGREAL;
BEGIN RETURN CSetting(0)
END AnimMinDelay;

PROCEDURE SetAnimMinDelay*(d: LONGREAL);
BEGIN CSetSetting(0, d)
END SetAnimMinDelay;

(* How RGB images, and so animations' frames, are scaled to the size
   they are drawn at: ScalingNearest, or ScalingBilinear, smoother and
   slower, to start with. *)
PROCEDURE ScalingAlgorithm*(): INTEGER;
BEGIN RETURN SHORT(ENTIER(CSetting(1)))
END ScalingAlgorithm;

PROCEDURE SetScalingAlgorithm*(s: INTEGER);
BEGIN
  ASSERT((s = ScalingNearest) OR (s = ScalingBilinear), Fl.IndexOutOfRange);
  CSetSetting(1, s)
END SetScalingAlgorithm;

(* Whether GIFs FLTK loads itself, as a file chooser's preview, are
   animated; FALSE to start with. *)
PROCEDURE SetAnimateGIFs*(on: BOOLEAN);
BEGIN IF on THEN CSetSetting(2, 1.0D0) ELSE CSetSetting(2, 0.0D0) END
END SetAnimateGIFs;

(* Multi-labels *)

PROCEDURE CloseMulti(m: MultiLabel);
BEGIN
  IF m.h # 0 THEN CMultiClose(m.h); m.h := 0; DEC(openMultiLabels) END
END CloseMulti;

(* GC finalizer: a multi-label lost without Close. *)
PROCEDURE FinalizeMulti(obj: SYSTEM.PTR);
BEGIN CloseMulti(SYSTEM.VAL(MultiLabel, obj))
END FinalizeMulti;

(* m's handle, halting if m is closed. *)
PROCEDURE Mh(m: MultiLabel): SYSTEM.ADDRESS;
BEGIN
  ASSERT(m # NIL, Fl.NilArgument); ASSERT(m.h # 0, Fl.ClosedResource);
  RETURN m.h
END Mh;

(* Opens m with both parts nothing. *)
PROCEDURE OpenMultiLabel*(m: MultiLabel);
BEGIN
  ASSERT(m # NIL, Fl.NilArgument); ASSERT(m.h = 0, Fl.OpenedTwice);
  m.h := CMultiNew(); INC(openMultiLabels);
  GarbageCollectedHeap.RegisterFinalizer(m, FinalizeMulti)
END OpenMultiLabel;

(* Gives up the program's hold on m; idempotent. What shows m keeps it. *)
PROCEDURE (m: MultiLabel) Close*;
BEGIN CloseMulti(m)
END Close;

PROCEDURE (m: MultiLabel) IsOpen*(): BOOLEAN;
BEGIN RETURN m.h # 0
END IsOpen;

PROCEDURE Part(m: MultiLabel; part: INTEGER): SYSTEM.ADDRESS;
  VAR h: SYSTEM.ADDRESS;
BEGIN h := Mh(m); ASSERT((part = 0) OR (part = 1), Fl.IndexOutOfRange); RETURN h
END Part;

(* Part 0 is drawn first, at the left (or top, as the label is aligned),
   and part 1 after it. A change shows when what shows m is redrawn. *)

(* The part becomes text, copied, drawn as label type t (Fl.NormalLabel
   to Fl.EmbossedLabel); "" for nothing. *)
PROCEDURE (m: MultiLabel) SetText*(part: INTEGER; text-: ARRAY OF CHAR; t: INTEGER);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Part(m, part); ASSERT((t >= Fl.NormalLabel) & (t <= Fl.EmbossedLabel), Fl.Unsupported);
  IF text = "" THEN CMultiSet(h, part, 0, "", 0, 0) ELSE CMultiSet(h, part, 1, text, t, 0) END
END SetText;

(* The part becomes image i, which m keeps; NIL for nothing. *)
PROCEDURE (m: MultiLabel) SetImage*(part: INTEGER; i: Image);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Part(m, part);
  IF i = NIL THEN CMultiSet(h, part, 0, "", 0, 0) ELSE CMultiSet(h, part, 2, "", 0, Hd(i)) END
END SetImage;

(* The part becomes multi-label n, which m keeps; NIL for nothing. n
   that is m, or holds it, would be drawn forever, and halts
   (Fl.Unsupported). *)
PROCEDURE (m: MultiLabel) SetMulti*(part: INTEGER; n: MultiLabel);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Part(m, part);
  IF n = NIL THEN CMultiSet(h, part, 0, "", 0, 0)
  ELSE ASSERT(CMultiContains(Mh(n), h) = 0, Fl.Unsupported); CMultiSet(h, part, 3, "", 0, n.h)
  END
END SetMulti;

(* w's label becomes m, which w keeps until it shows another label, or
   is deleted; NIL for no label. Fl.Widget.SetLabel gives it text again.
   Not for a window, whose label is its title (Fl.Unsupported). *)
PROCEDURE SetMultiLabel*(w: Fl.Widget; m: MultiLabel);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Fl.Live(w); ASSERT(~(w IS Fl.Window), Fl.Unsupported);
  IF m = NIL THEN CWidgetMultiLabel(h, 0) ELSE CWidgetMultiLabel(h, Mh(m)) END
END SetMultiLabel;

(* Menu items *)

(* Item i of menu m shows image i, which the menu keeps while the item
   shows it; NIL for its text again. The item keeps its text, which its
   path is made of (ItemPath, FindIndex and Insert of FlMenus.Menu), and
   ItemLabel gives. Removing the item, or SetItemLabel, lets i go. *)
PROCEDURE SetItemImage*(m: FlMenus.Menu; item: INTEGER; i: Image);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Fl.Live(m); ASSERT(m.IsItem(item), Fl.IndexOutOfRange);
  IF i = NIL THEN CMenuItemLabel(h, item, 0, 0) ELSE CMenuItemLabel(h, item, 1, Hd(i)) END
END SetItemImage;

(* The same, for multi-label l. *)
PROCEDURE SetItemMultiLabel*(m: FlMenus.Menu; item: INTEGER; l: MultiLabel);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Fl.Live(m); ASSERT(m.IsItem(item), Fl.IndexOutOfRange);
  IF l = NIL THEN CMenuItemLabel(h, item, 0, 0) ELSE CMenuItemLabel(h, item, 2, Mh(l)) END
END SetItemMultiLabel;

(* Surfaces *)

PROCEDURE CloseSurface(s: WidgetSurface);
BEGIN
  IF s.h # 0 THEN CSurfaceClose(s.h); s.h := 0; DEC(openSurfaces) END
END CloseSurface;

PROCEDURE FinalizeSurface(obj: SYSTEM.PTR);
BEGIN CloseSurface(SYSTEM.VAL(WidgetSurface, obj))
END FinalizeSurface;

(* s's handle, halting if it is closed. *)
PROCEDURE S(s: WidgetSurface): SYSTEM.ADDRESS;
BEGIN
  ASSERT(s # NIL, Fl.NilArgument); ASSERT(s.h # 0, Fl.ClosedResource);
  RETURN s.h
END S;

PROCEDURE Opening(s: WidgetSurface; h: SYSTEM.ADDRESS);
BEGIN
  s.h := h; s.begun := FALSE; INC(openSurfaces);
  GarbageCollectedHeap.RegisterFinalizer(s, FinalizeSurface)
END Opening;

(* Makes s a surface of w by h pixels, white. *)
PROCEDURE OpenSurface*(s: Surface; w, h: INTEGER);
BEGIN
  ASSERT(s # NIL, Fl.NilArgument); ASSERT(s.h = 0, Fl.OpenedTwice);
  ASSERT((w > 0) & (h > 0), Fl.IndexOutOfRange);
  s.masked := FALSE;
  Opening(s, CSurfaceNew(w, h))
END OpenSurface;

(* Makes s a surface of w by h pixels, for the clipboard. Close puts what
   was drawn on the clipboard, as an image, with no window needed. FLTK
   has no way to give one up: a CopySurface lost without Close is written
   to the clipboard when it is collected, or the program ends. *)
PROCEDURE OpenCopySurface*(s: CopySurface; w, h: INTEGER);
BEGIN
  ASSERT(s # NIL, Fl.NilArgument); ASSERT(s.h = 0, Fl.OpenedTwice);
  ASSERT((w > 0) & (h > 0), Fl.IndexOutOfRange);
  Opening(s, CCopyNew(w, h))
END OpenCopySurface;

PROCEDURE (s: WidgetSurface) IsOpen*(): BOOLEAN;
BEGIN RETURN s.h # 0
END IsOpen;

(* Sends drawing to s, until End. Surfaces nest: End ends the last one
   begun, and drawing goes to the one before. *)
PROCEDURE (s: WidgetSurface) Begin*;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := S(s); ASSERT(~s.begun, Fl.OutOfOrder);
  CSurfaceBegin(h); s.begun := TRUE; s.below := current; current := s
END Begin;

(* Sends drawing back where it went before Begin. s must be the surface
   last begun. *)
PROCEDURE (s: WidgetSurface) End*;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := S(s); ASSERT(s.begun & (current = s) & (CSurfaceCurrent(h) # 0), Fl.OutOfOrder);
  CSurfaceEnd; s.begun := FALSE; current := s.below; s.below := NIL
END End;

(* Ends s if it is begun, and frees it; idempotent. *)
PROCEDURE (s: WidgetSurface) Close*;
BEGIN
  IF s.begun THEN s.End END;
  CloseSurface(s)
END Close;

(* Draws w and its children, as FLTK would on the screen, with w's top
   left at x, y; between Begin and End. *)
PROCEDURE (s: WidgetSurface) DrawWidget*(w: Fl.Widget; x, y: INTEGER);
  VAR h: SYSTEM.ADDRESS;
BEGIN h := S(s); ASSERT(s.begun, Fl.OutOfOrder); CSurfaceDraw(h, Fl.Live(w), x, y)
END DrawWidget;

(* Draws w, with its title bar where the window system lets FLTK get at
   it, with its top left at x, y; between Begin and End. *)
PROCEDURE (s: WidgetSurface) DrawDecoratedWindow*(w: Fl.Window; x, y: INTEGER);
  VAR h: SYSTEM.ADDRESS;
BEGIN h := S(s); ASSERT(s.begun, Fl.OutOfOrder); CSurfaceDecorated(h, Fl.Live(w), x, y)
END DrawDecoratedWindow;

(* Makes i an image of what has been drawn on s. *)
PROCEDURE (s: Surface) GetImage*(i: Image);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := S(s); New(i); ASSERT(Opened(i, CSurfaceImage(h)));  (* out of memory *)
  s.masked := FALSE
END GetImage;

(* What is drawn on s from now on shows only through m, an image of 3
   bytes a pixel scaled to s's size, usually a Surface's: fully where m
   is white, not where it is black, in part between, where what s had
   before stays. GetImage gives the two together, and a next Mask may
   follow it. The edge between them is soft, by a pixel or so, on Cairo.
   s must not be begun, and there can't be two Masks with no GetImage
   between (Fl.OutOfOrder), since FLTK loses the first; m can't be of
   another depth (Fl.Unsupported). FLTK doesn't keep m. *)
PROCEDURE (s: Surface) Mask*(m: Image);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := S(s); ASSERT(m # NIL, Fl.NilArgument);
  ASSERT(~s.begun & ~s.masked, Fl.OutOfOrder);
  ASSERT(CSurfaceMask(h, Hd(m)) # 0, Fl.Unsupported);
  s.masked := TRUE
END Mask;

(* Makes i an image of the w by h pixels at x, y of what is being drawn
   on, a Surface begun or a window in its Draw, as much of them as is on
   it. With alpha, 4 bytes a pixel, all opaque; else 3. FALSE, and i not
   open, if there is nothing to read, none of them is on it, or FLTK
   couldn't read them. *)
PROCEDURE ReadImage*(i: Image; x, y, w, h: INTEGER; alpha: BOOLEAN): BOOLEAN;
BEGIN
  New(i); ASSERT((w > 0) & (h > 0), Fl.IndexOutOfRange);
  RETURN Opened(i, CReadImage(x, y, w, h, Int(alpha)))
END ReadImage;

(* Makes i what window win shows of x, y, w, h, with its subwindows, outside
   a Draw, as much of that as is on win. FALSE, and i not open, if win isn't
   shown, or none of it is. *)
PROCEDURE CaptureWindow*(i: Image; win: Fl.Window; x, y, w, h: INTEGER): BOOLEAN;
BEGIN
  New(i);
  RETURN Opened(i, CCapture(Fl.Live(win), x, y, w, h))
END CaptureWindow;

(* Shared images *)

(* Makes s the pool's image of file name, loading it if it isn't there, in
   any format Load reads (a GIF as its first frame): at its own size if
   w and h are 0, or else scaled to w by h, an entry of the pool of its
   own, which holds a reference to that original. FALSE, and s not open, if it can't be loaded. *)
PROCEDURE GetShared*(s: Shared; name-: ARRAY OF CHAR; w, h: INTEGER): BOOLEAN;
BEGIN
  NewShared(s);
  ASSERT((w >= 0) & (h >= 0) & ((w = 0) = (h = 0)), Fl.IndexOutOfRange);
  RETURN Opened(s, CSharedGet(name, w, h))
END GetShared;

(* GetShared of an image the pool has, loading nothing; FALSE if it
   doesn't have it. *)
PROCEDURE FindShared*(s: Shared; name-: ARRAY OF CHAR; w, h: INTEGER): BOOLEAN;
BEGIN
  NewShared(s);
  ASSERT((w >= 0) & (h >= 0) & ((w = 0) = (h = 0)), Fl.IndexOutOfRange);
  RETURN Opened(s, CSharedFind(name, w, h))
END FindShared;

(* Makes s a new entry of the pool, holding a copy of RGB image i, under a
   name FLTK makes up (GetName). Any other kind of image halts
   (Fl.Unsupported). *)
PROCEDURE ShareImage*(s: Shared; i: Image);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Hd(i); NewShared(s);
  h := CSharedOfImage(h); ASSERT(h # 0, Fl.Unsupported);
  ASSERT(Opened(s, h))
END ShareImage;

(* How many images the pool has. *)
PROCEDURE SharedCount*(): INTEGER;
BEGIN RETURN CSharedCount()
END SharedCount;

(* How many references s's entry has, its holders and those of FLTK. *)
PROCEDURE (s: Shared) RefCount*(): INTEGER;
BEGIN RETURN CSharedRefCount(Hd(s))
END RefCount;

(* Whether s is the image at its file's own size, not one scaled from it. *)
PROCEDURE (s: Shared) Original*(): BOOLEAN;
BEGIN RETURN CSharedOriginal(Hd(s)) # 0
END Original;

(* The name s is found by. *)
PROCEDURE (s: Shared) GetName*(VAR name: ARRAY OF CHAR);
BEGIN CSharedName(Hd(s), name, SHORT(LEN(name)))
END GetName;

(* Reads s's file again, for everyone sharing it. FALSE if it can't be
   read, and s is as it was. *)
PROCEDURE (s: Shared) Reload*(): BOOLEAN;
BEGIN RETURN CSharedReload(Hd(s)) # 0
END Reload;

(* Lets FLTK's own loading of images read more than BMP, GIF and XBM, for
   what FLTK loads itself: the previews of its file chooser. *)
PROCEDURE RegisterImages*;
BEGIN CRegisterImages
END RegisterImages;

(* FLTK's call: asks the handlers about a file. *)
PROCEDURE AskHandlers(name, header: SYSTEM.ADDRESS; n: SYSTEM.INT32): SYSTEM.ADDRESS;
  VAR
    l, next: HandlerLink; r: Image; s: POINTER TO ARRAY OF CHAR;
    head: ARRAY MaxHeader + 1 OF CHAR; c: CHAR; i: LONGINT;
BEGIN
  i := 0;
  REPEAT SYSTEM.GET(name + i, c); INC(i) UNTIL c = 0X;
  NEW(s, i);
  i := 0;
  REPEAT SYSTEM.GET(name + i, c); s[i] := c; INC(i) UNTIL c = 0X;
  FOR i := 0 TO n - 1 DO SYSTEM.GET(header + i, head[i]) END;
  head[n] := 0X;
  l := handlers;
  WHILE l # NIL DO
    next := l.next;   (* a handler may remove itself *)
    r := l.handler(s^, head, n);
    IF r # NIL THEN RETURN Hd(r) END;
    l := next
  END;
  RETURN 0
END AskHandlers;

(* Adds handler h, after those added before, unless it is there already.
   GetShared and Reload ask the handlers about a file Load can't read,
   and FLTK's own loading (a file chooser's preview, a help view's image)
   about any file but XBM and XPM, after the handlers RegisterImages
   adds, if it ran first. The pool gets a copy of the image h returns,
   which stays h's to Close. h must not ask the pool for the same name:
   that asks h. *)
PROCEDURE AddHandler*(h: ImageHandler);
  VAR l, last: HandlerLink;
BEGIN
  ASSERT(h # NIL, Fl.NilArgument);
  last := NIL; l := handlers;
  WHILE l # NIL DO
    IF l.handler = h THEN RETURN END;
    last := l; l := l.next
  END;
  NEW(l); l.handler := h;
  IF last = NIL THEN handlers := l ELSE last.next := l END;
  CAddHandler(AskHandlers)
END AddHandler;

(* Removes handler h, if it was added. *)
PROCEDURE RemoveHandler*(h: ImageHandler);
  VAR l, last: HandlerLink;
BEGIN
  last := NIL; l := handlers;
  WHILE (l # NIL) & (l.handler # h) DO last := l; l := l.next END;
  IF l # NIL THEN
    IF last = NIL THEN handlers := l.next ELSE last.next := l.next END
  END
END RemoveHandler;

(* File icons *)

(* The object of icon h, 0 for NIL, made if FLTK made the icon. *)
PROCEDURE Object(h: SYSTEM.ADDRESS): FileIcon;
  VAR i: FileIcon;
BEGIN
  IF h = 0 THEN RETURN NIL END;
  i := icons;
  WHILE (i # NIL) & (i.h # h) DO i := i.next END;
  IF i = NIL THEN NEW(i); i.h := h; i.next := icons; icons := i END;
  RETURN i
END Object;

PROCEDURE IconHd(i: FileIcon): SYSTEM.ADDRESS;
BEGIN
  ASSERT(i # NIL, Fl.NilArgument); ASSERT(i.h # 0, Fl.NotOpen);
  RETURN i.h
END IconHd;

(* The icons the program made are freed as it ends, or valgrind would
   report them; FLTK makes its own from data it holds to the end. *)
PROCEDURE FinalizeFileIcon(obj: SYSTEM.PTR);
  VAR i: FileIcon;
BEGIN
  i := SYSTEM.VAL(FileIcon, obj);
  IF i.h # 0 THEN CIconFree(i.h); i.h := 0 END
END FinalizeFileIcon;

(* Makes i an empty icon for files whose names match pattern, of type
   (IconAny or the rest), first on FLTK's list, so it is found before
   any like it. *)
PROCEDURE OpenFileIcon*(i: FileIcon; pattern-: ARRAY OF CHAR; type: INTEGER);
BEGIN
  ASSERT(i # NIL, Fl.NilArgument); ASSERT(i.h = 0, Fl.OpenedTwice);
  ASSERT((type >= IconAny) & (type <= IconDirectory), Fl.IndexOutOfRange);
  i.h := CIconNew(pattern, type); i.next := icons; icons := i;
  GarbageCollectedHeap.RegisterFinalizer(i, FinalizeFileIcon)
END OpenFileIcon;

(* Starts a shape (IconLine, IconClosedLine or IconPolygon), or ends one
   (IconEnd). *)
PROCEDURE (i: FileIcon) Add*(op: INTEGER);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := IconHd(i);
  ASSERT((op = IconEnd) OR (op = IconLine) OR (op = IconClosedLine) OR (op = IconPolygon),
    Fl.IndexOutOfRange);
  CIconAdd(h, 0, op, 0)
END Add;

(* The color of what follows: a color of Fl's, or IconColor. *)
PROCEDURE (i: FileIcon) AddColor*(c: INTEGER);
BEGIN CIconAdd(IconHd(i), 1, c, 0)
END AddColor;

(* A polygon outlined in color c, its vertices and IconEnd to follow. *)
PROCEDURE (i: FileIcon) AddOutlinePolygon*(c: INTEGER);
BEGIN CIconAdd(IconHd(i), 3, c, 0)
END AddOutlinePolygon;

(* A vertex of the current shape. *)
PROCEDURE (i: FileIcon) AddVertex*(x, y: INTEGER);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := IconHd(i);
  ASSERT((x >= 0) & (x <= 10000) & (y >= 0) & (y <= 10000), Fl.IndexOutOfRange);
  CIconAdd(h, 2, x, y)
END AddVertex;

(* Empties i. *)
PROCEDURE (i: FileIcon) Clear*;
BEGIN CIconClear(IconHd(i))
END Clear;

(* Adds a picture to i, from file name: an SGI .fti file, or by its contents
   an image Load reads, with pixels to read, each row its runs of one
   color. FALSE if it can't be read, and for a .fti of bad text, i is
   empty. *)
PROCEDURE (i: FileIcon) Load*(name-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CIconLoad(IconHd(i), name) # 0
END Load;

(* Has FLTK make icons for the kinds of file, from the desktop's icon
   theme if it finds one, and always those of a plain file and a
   directory. Once only, whatever the times called. *)
PROCEDURE LoadSystemIcons*;
BEGIN CIconLoadSystem
END LoadSystemIcons;

(* The first icon on the list matching file name and type (IconAny, for
   FLTK to find what the file is), or NIL. *)
PROCEDURE FindFileIcon*(name-: ARRAY OF CHAR; type: INTEGER): FileIcon;
BEGIN
  ASSERT((type >= IconAny) & (type <= IconDirectory), Fl.IndexOutOfRange);
  RETURN Object(CIconFind(name, type))
END FindFileIcon;

(* The first icon on FLTK's list, or NIL. *)
PROCEDURE FirstFileIcon*(): FileIcon;
BEGIN RETURN Object(CIconFirst())
END FirstFileIcon;

(* The icon after i on FLTK's list, or NIL. *)
PROCEDURE (i: FileIcon) Next*(): FileIcon;
BEGIN RETURN Object(CIconNext(IconHd(i)))
END Next;

(* Draws i to fill w by h pixels at x, y, in color wherever it says
   IconColor, in a Draw method; dimmed unless active. *)
PROCEDURE (i: FileIcon) Draw*(x, y, w, h, color: INTEGER; active: BOOLEAN);
BEGIN CIconDraw(IconHd(i), x, y, w, h, color, Int(active))
END Draw;

(* Widget w shows i as its label, filling it, until it is given another
   (SetLabel, SetMultiLabel). A window has only text as a label
   (Fl.Unsupported). *)
PROCEDURE (i: FileIcon) Label*(w: Fl.Widget);
  VAR h, wh: SYSTEM.ADDRESS;
BEGIN
  h := IconHd(i); wh := Fl.Live(w);
  ASSERT(~(w IS Fl.Window), Fl.Unsupported);
  CIconLabel(h, wh)
END Label;

(* How many numbers i holds, 0 when it is empty. *)
PROCEDURE (i: FileIcon) Size*(): INTEGER;
BEGIN RETURN CIconSize(IconHd(i))
END Size;

PROCEDURE (i: FileIcon) Type*(): INTEGER;
BEGIN RETURN CIconType(IconHd(i))
END Type;

PROCEDURE (i: FileIcon) GetPattern*(VAR pattern: ARRAY OF CHAR);
BEGIN CIconPattern(IconHd(i), pattern, SHORT(LEN(pattern)))
END GetPattern;

(* Adds a line of text to file browser b, showing icon i, or none if i is
   NIL. *)
PROCEDURE AddFile*(b: FlBrowsers.FileBrowser; text-: ARRAY OF CHAR; i: FileIcon);
  VAR h, ih: SYSTEM.ADDRESS;
BEGIN
  h := Fl.Live(b);
  ih := 0;
  IF i # NIL THEN ih := IconHd(i) END;
  CFileBrowserAdd(h, text, ih)
END AddFile;

(* Line of file browser b shows icon i, or none if i is NIL, in place of
   the icon the browser found for it. *)
PROCEDURE SetFileIcon*(b: FlBrowsers.FileBrowser; line: INTEGER; i: FileIcon);
  VAR h, ih: SYSTEM.ADDRESS;
BEGIN
  h := Fl.Live(b); ASSERT((line >= 1) & (line <= b.Count()), Fl.IndexOutOfRange);
  ih := 0;
  IF i # NIL THEN ih := IconHd(i) END;
  CFileBrowserIcon(h, line, ih)
END SetFileIcon;

END FlImages.
