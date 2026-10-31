MODULE FlPrint; (* printing, and drawing into PostScript, PDF, EPS and SVG files *)

(* A surface takes what FlDraw draws, and what a widget would show on the
   screen, and sends it to a printer or a file instead.

   A PagedDevice is a job of pages: a Printer, a PostScriptFile or a
   PDFFile. A PostScriptFile or PDFFile is opened on a file, and its job
   begins then; a Printer is opened, and BeginJob asks the user. Then each
   page is BeginPage, its drawing, and EndPage, and EndJob finishes.

     VAR f: FlPrint.PDFFile; w, h: INTEGER;

     NEW(f);
     IF FlPrint.OpenPDF(f, "out.pdf", FlPrint.A4, FlPrint.Portrait) THEN
       f.BeginPage;
       f.PrintableRect(w, h);
       FlDraw.Rect(0, 0, w, h);
       f.DrawWidget(window, 0, 0);
       f.EndPage;
       IF ~f.EndJob() THEN (* it wasn't written *) END;
       f.Close
     END;

   A FileSurface is one drawing of a size given at the start: an EPSFile
   or an SVGFile. Drawing goes to it between Begin and End, and Finish
   finishes.

   Drawing is in points on a page, a 72nd of an inch, unless Scale says
   otherwise, and in the surface's pixels on a FileSurface. Each page,
   and each Begin, starts in Helvetica at Fl.NormalSize().

   Surfaces nest, with FlImages' too, and the last one begun must end
   first. Anything out of order halts with Fl.OutOfOrder. Close ends what
   is under way, ignoring whether the file was written, and frees the
   surface. One never closed is freed by the collector, and its file is
   left unfinished, perhaps empty.

   A file that can't be written is bad outside data, not a programmer's
   error: an Open, EndJob or Finish returns FALSE, and Error says why, if
   it can.

   FLTK can't survive a page Cairo refuses. A surface checks what it is
   given, but FlDraw can't: on a PostScriptFile or Printer, don't draw
   with FlDraw.Scale of 0, with a NaN, or with a negative font size
   (doc/fltk-issues.md, 101).

   The C++ part is FlPrint.cpp. *)

IMPORT SYSTEM, GarbageCollectedHeap, Fl;

CONST
(* BEGIN generated constants: tools/gen-constants.py writes this block,
   from FLTK's headers; edit the script, not the block. *)

  (* the page: its format (Fl_Paged_Device::Page_Format) *)
  A0* = 0;
  A1* = 1;
  A2* = 2;
  A3* = 3;
  A4* = 4;
  A5* = 5;
  A6* = 6;
  A7* = 7;
  A8* = 8;
  A9* = 9;
  B0* = 10;
  B1* = 11;
  B2* = 12;
  B3* = 13;
  B4* = 14;
  B5* = 15;
  B6* = 16;
  B7* = 17;
  B8* = 18;
  B9* = 19;
  B10* = 20;
  C5E* = 21;
  DLE* = 22;
  Executive* = 23;
  Folio* = 24;
  Ledger* = 25;
  Legal* = 26;
  Letter* = 27;
  Tabloid* = 28;
  Envelope* = 29;
  PageFormats* = 30;

  (* and its layout (Fl_Paged_Device::Page_Layout) *)
  Portrait* = 0;
  Landscape* = 256;
  Reversed* = 512;
(* END generated constants *)

  (* Printer.BeginJob and OpenPDFChooser *)
  JobOk* = 0;
  JobCancelled* = 1;  (* the user cancelled *)
  JobFailed* = 2;     (* Error says why *)

  (* FLTK's texts, for SetPrinterText: its print dialog's, *)
  DialogTitle* = 0;
  DialogPrinter* = 1;
  DialogRange* = 2;
  DialogCopies* = 3;
  DialogAll* = 4;
  DialogPages* = 5;
  DialogFrom* = 6;
  DialogTo* = 7;
  DialogProperties* = 8;
  DialogCopyNo* = 9;
  DialogPrintButton* = 10;
  DialogCancelButton* = 11;
  DialogPrintToFile* = 12;
  (* its printer properties dialog's, *)
  PropertyTitle* = 13;
  PropertyPageSize* = 14;
  PropertyMode* = 15;
  PropertyUse* = 16;
  PropertySave* = 17;
  PropertyCancel* = 18;
  (* and those of the dialog OpenPDFChooser shows after the file. *)
  PDFTitle* = 19;
  PDFPageSize* = 20;
  PDFOrientation* = 21;
  PDFDefault* = 22;

TYPE
  WidgetSurface* = POINTER TO WidgetSurfaceDesc;
  WidgetSurfaceDesc* = RECORD
    h: SYSTEM.ADDRESS;
    below: WidgetSurface;  (* the surface begun before this one *)
    job: BOOLEAN;          (* it can take pages or drawing *)
    begun: BOOLEAN;        (* drawing goes to it *)
    shifts: INTEGER        (* Translates not yet undone *)
  END;

  PagedDevice* = POINTER TO PagedDeviceDesc;
  PagedDeviceDesc* = RECORD (WidgetSurfaceDesc) END;

  Printer* = POINTER TO PrinterDesc;
  PrinterDesc* = RECORD (PagedDeviceDesc)
    from, to: SYSTEM.INT32
  END;

  PostScriptFile* = POINTER TO PostScriptFileDesc;
  PostScriptFileDesc* = RECORD (PagedDeviceDesc) END;

  PDFFile* = POINTER TO PDFFileDesc;
  PDFFileDesc* = RECORD (PagedDeviceDesc) END;

  FileSurface* = POINTER TO FileSurfaceDesc;
  FileSurfaceDesc* = RECORD (WidgetSurfaceDesc) END;

  EPSFile* = POINTER TO EPSFileDesc;
  EPSFileDesc* = RECORD (FileSurfaceDesc) END;

  SVGFile* = POINTER TO SVGFileDesc;
  SVGFileDesc* = RECORD (FileSurfaceDesc) END;

VAR
  openSurfaces-: INTEGER;  (* surfaces opened and not yet closed or finalized *)
  current: WidgetSurface;  (* the surface last begun and not ended *)

PROCEDURE ["C", "ofl_print_printer"] CPrinter(): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_print_postscript"] CPostScript(path: ARRAY OF CHAR; format, layout: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_print_pdf"] CPDF(path: ARRAY OF CHAR; chooser, format, layout: SYSTEM.INT32; VAR h: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_print_eps"] CEPS(path: ARRAY OF CHAR; w, h, background: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_print_svg"] CSVG(path: ARRAY OF CHAR; w, h: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_print_job"] CJob(h: SYSTEM.ADDRESS; pages: SYSTEM.INT32; VAR from, to: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_print_finish"] CFinish(h: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_print_close"] CClose(h: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_print_begin"] CBegin(h: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_print_end"] CEnd(h: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_print_current"] CCurrent(h: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_print_translate"] CTranslate(h: SYSTEM.ADDRESS; x, y: SYSTEM.INT32);
PROCEDURE ["C", "ofl_print_untranslate"] CUntranslate(h: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_print_draw"] CDraw(h, w: SYSTEM.ADDRESS; x, y: SYSTEM.INT32);
PROCEDURE ["C", "ofl_print_decorated"] CDecorated(h, w: SYSTEM.ADDRESS; x, y: SYSTEM.INT32);
PROCEDURE ["C", "ofl_print_part"] CPart(h, win: SYSTEM.ADDRESS; x, y, w, ht, dx, dy: SYSTEM.INT32);
PROCEDURE ["C", "ofl_print_rect"] CRect(h: SYSTEM.ADDRESS; VAR w, ht: SYSTEM.INT32);
PROCEDURE ["C", "ofl_print_get_origin"] CGetOrigin(h: SYSTEM.ADDRESS; VAR x, y: SYSTEM.INT32);
PROCEDURE ["C", "ofl_print_set_origin"] CSetOrigin(h: SYSTEM.ADDRESS; x, y: SYSTEM.INT32);
PROCEDURE ["C", "ofl_print_margins"] CMargins(h: SYSTEM.ADDRESS; VAR l, t, r, b: SYSTEM.INT32);
PROCEDURE ["C", "ofl_print_scale"] CScale(h: SYSTEM.ADDRESS; x, y: LONGREAL): SYSTEM.INT32;
PROCEDURE ["C", "ofl_print_rotate"] CRotate(h: SYSTEM.ADDRESS; angle: LONGREAL): SYSTEM.INT32;
PROCEDURE ["C", "ofl_print_error"] CError(VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_print_available"] CAvailable(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_print_text"] CText(which: SYSTEM.INT32; text: ARRAY OF CHAR): SYSTEM.INT32;

(* Making and freeing them *)

PROCEDURE Free(s: WidgetSurface);
BEGIN
  IF s.h # 0 THEN CClose(s.h); s.h := 0; DEC(openSurfaces) END
END Free;

PROCEDURE Finalize(obj: SYSTEM.PTR);
BEGIN Free(SYSTEM.VAL(WidgetSurface, obj))
END Finalize;

(* s's handle, halting if it is closed. *)
PROCEDURE S(s: WidgetSurface): SYSTEM.ADDRESS;
BEGIN
  ASSERT(s # NIL, Fl.NilArgument); ASSERT(s.h # 0, Fl.ClosedResource);
  RETURN s.h
END S;

(* s's handle, between a Begin or BeginPage and its end. *)
PROCEDURE D(s: WidgetSurface): SYSTEM.ADDRESS;
  VAR h: SYSTEM.ADDRESS;
BEGIN h := S(s); ASSERT(s.begun, Fl.OutOfOrder); RETURN h
END D;

(* s's handle, in a job. *)
PROCEDURE J(s: WidgetSurface): SYSTEM.ADDRESS;
  VAR h: SYSTEM.ADDRESS;
BEGIN h := S(s); ASSERT(s.job, Fl.OutOfOrder); RETURN h
END J;

PROCEDURE Unopened(s: WidgetSurface);
BEGIN ASSERT(s # NIL, Fl.NilArgument); ASSERT(s.h = 0, Fl.OpenedTwice)
END Unopened;

PROCEDURE Opened(s: WidgetSurface; h: SYSTEM.ADDRESS; job: BOOLEAN): BOOLEAN;
BEGIN
  IF h = 0 THEN RETURN FALSE END;
  s.h := h; s.job := job; s.begun := FALSE; s.shifts := 0; INC(openSurfaces);
  GarbageCollectedHeap.RegisterFinalizer(s, Finalize);
  RETURN TRUE
END Opened;

PROCEDURE CheckPage(format, layout: INTEGER);
BEGIN
  ASSERT((format >= 0) & (format < PageFormats), Fl.Unsupported);
  ASSERT((layout = Portrait) OR (layout = Landscape) OR (layout = Portrait + Reversed)
         OR (layout = Landscape + Reversed), Fl.Unsupported)
END CheckPage;

(* Makes p a printer. Nothing happens until BeginJob. *)
PROCEDURE OpenPrinter*(p: Printer);
BEGIN Unopened(p); ASSERT(Opened(p, CPrinter(), FALSE))
END OpenPrinter;

(* Makes f a job writing PostScript to path, as pages of a format and
   layout: A4 or another format, and Portrait, Landscape or either +
   Reversed. FALSE if path can't be written. *)
PROCEDURE OpenPostScript*(f: PostScriptFile; path-: ARRAY OF CHAR; format, layout: INTEGER): BOOLEAN;
BEGIN
  Unopened(f); CheckPage(format, layout);
  RETURN Opened(f, CPostScript(path, format, layout), TRUE)
END OpenPostScript;

(* The same, for PDF. FALSE too if this FLTK has no Pango, which it needs
   for PDF. *)
PROCEDURE OpenPDF*(f: PDFFile; path-: ARRAY OF CHAR; format, layout: INTEGER): BOOLEAN;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  Unopened(f); CheckPage(format, layout); h := 0;
  RETURN (CPDF(path, 0, format, layout, h) = 0) & Opened(f, h, TRUE)
END OpenPDF;

(* Lets the user pick a file, and then a format and layout, offering name,
   and makes f a job writing PDF there. JobOk, JobCancelled, or JobFailed,
   and f is left unopened unless JobOk. *)
PROCEDURE OpenPDFChooser*(f: PDFFile; name-: ARRAY OF CHAR): INTEGER;
  VAR h: SYSTEM.ADDRESS; r: INTEGER;
BEGIN
  Unopened(f); h := 0; r := CPDF(name, 1, 0, 0, h);
  IF (r = JobOk) & ~Opened(f, h, TRUE) THEN r := JobFailed END;
  RETURN r
END OpenPDFChooser;

(* Makes f a drawing of w by h pixels, to go to path as EPS. background
   is the color transparent parts of images are blended with, where FLTK
   can't draw them as they are. FALSE if path can't be written. *)
PROCEDURE OpenEPS*(f: EPSFile; path-: ARRAY OF CHAR; w, h, background: INTEGER): BOOLEAN;
BEGIN
  Unopened(f); ASSERT((w > 0) & (h > 0), Fl.IndexOutOfRange);
  RETURN Opened(f, CEPS(path, w, h, background), TRUE)
END OpenEPS;

(* The same, for SVG. FALSE, with path untouched, if this FLTK has no SVG
   (Fl.Has(Fl.Svg)). *)
PROCEDURE OpenSVG*(f: SVGFile; path-: ARRAY OF CHAR; w, h: INTEGER): BOOLEAN;
BEGIN
  Unopened(f); ASSERT((w > 0) & (h > 0), Fl.IndexOutOfRange);
  RETURN Opened(f, CSVG(path, w, h), TRUE)
END OpenSVG;

(* Whether this FLTK prints: FLTK built with --disable-print doesn't. Without
   it, a Printer opens and BeginJob gives JobFailed, and files other than
   SVG don't open. *)
PROCEDURE Available*(): BOOLEAN;
BEGIN RETURN CAvailable() # 0
END Available;

(* Why the last Open, BeginJob, EndJob or Finish that failed did. *)
PROCEDURE Error*(VAR s: ARRAY OF CHAR);
BEGIN CError(s, SHORT(LEN(s)))
END Error;

(* Replaces one of FLTK's texts, such as DialogTitle, to translate it.
   FLTK builds its print dialog once, so set them before the first
   BeginJob. *)
PROCEDURE SetPrinterText*(which: INTEGER; text-: ARRAY OF CHAR);
BEGIN ASSERT(CText(which, text) # 0, Fl.IndexOutOfRange)
END SetPrinterText;

(* Beginning and ending *)

PROCEDURE Start(s: WidgetSurface);
BEGIN
  CBegin(J(s)); s.begun := TRUE; s.shifts := 0;
  s.below := current; current := s
END Start;

PROCEDURE Stop(s: WidgetSurface);
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := D(s); ASSERT(s.shifts = 0, Fl.OutOfOrder);
  ASSERT((current = s) & (CCurrent(h) # 0), Fl.OutOfOrder);
  CEnd(h); s.begun := FALSE; current := s.below; s.below := NIL
END Stop;

(* Finishes s's file; whether it was written. *)
PROCEDURE Ended(s: WidgetSurface): BOOLEAN;
BEGIN s.job := FALSE; RETURN CFinish(s.h) # 0
END Ended;

PROCEDURE (s: WidgetSurface) IsOpen*(): BOOLEAN;
BEGIN RETURN s.h # 0
END IsOpen;

(* Ends what is under way, as End, EndPage, EndJob and Finish would, and
   frees s; idempotent. Whether the file was written is lost: call EndJob
   or Finish first to know. *)
PROCEDURE (s: WidgetSurface) Close*;
  VAR written: BOOLEAN;
BEGIN
  IF s.h # 0 THEN
    IF s.begun THEN
      WHILE s.shifts > 0 DO CUntranslate(s.h); DEC(s.shifts) END;
      Stop(s)
    END;
    IF s.job THEN written := Ended(s) END;
    Free(s)
  END
END Close;

(* Drawing, between Begin and End or BeginPage and EndPage *)

(* Moves the origin by x, y, until Untranslate. Translates nest, and each
   must be undone before the page or drawing ends. *)
PROCEDURE (s: WidgetSurface) Translate*(x, y: INTEGER);
BEGIN CTranslate(D(s), x, y); INC(s.shifts)
END Translate;

PROCEDURE (s: WidgetSurface) Untranslate*;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := D(s); ASSERT(s.shifts > 0, Fl.OutOfOrder);
  CUntranslate(h); DEC(s.shifts)
END Untranslate;

(* Draws w and its children with w's top left at x, y. A widget not
   visible draws nothing. *)
PROCEDURE (s: WidgetSurface) DrawWidget*(w: Fl.Widget; x, y: INTEGER);
  VAR h: SYSTEM.ADDRESS;
BEGIN h := D(s); CDraw(h, Fl.Live(w), x, y)
END DrawWidget;

(* Draws w, with its title bar where the window system lets FLTK get at
   it, with its top left at x, y. A window never shown draws nothing. *)
PROCEDURE (s: WidgetSurface) DrawDecoratedWindow*(w: Fl.Window; x, y: INTEGER);
  VAR h: SYSTEM.ADDRESS;
BEGIN h := D(s); CDecorated(h, Fl.Live(w), x, y)
END DrawDecoratedWindow;

(* Draws the wd by ht pixels at x, y of w, as it is on the screen, at dx,
   dy. It reads the screen, so w must be shown; a window not shown draws
   nothing. It runs Fl.Check. *)
PROCEDURE (s: WidgetSurface) PrintWindowPart*(w: Fl.Window; x, y, wd, ht, dx, dy: INTEGER);
  VAR h: SYSTEM.ADDRESS;
BEGIN h := D(s); CPart(h, Fl.Live(w), x, y, wd, ht, dx, dy)
END PrintWindowPart;

(* The size of what can be drawn on: inside the margins of a page, in the
   units Scale gives. *)
PROCEDURE (s: WidgetSurface) PrintableRect*(VAR w, h: INTEGER);
  VAR a, b: SYSTEM.INT32;
BEGIN CRect(J(s), a, b); w := a; h := b
END PrintableRect;

PROCEDURE (s: WidgetSurface) Origin*(VAR x, y: INTEGER);
  VAR a, b: SYSTEM.INT32;
BEGIN CGetOrigin(J(s), a, b); x := a; y := b
END Origin;

(* Puts drawing's 0, 0 at x, y of what can be drawn on, however Scale and
   Rotate have left it. *)
PROCEDURE (s: WidgetSurface) SetOrigin*(x, y: INTEGER);
BEGIN CSetOrigin(D(s), x, y)
END SetOrigin;

(* Pages *)

(* Starts a page, and sends drawing to it. *)
PROCEDURE (d: PagedDevice) BeginPage*;
BEGIN ASSERT(~d.begun, Fl.OutOfOrder); Start(d)
END BeginPage;

(* Ends the page. d must be the surface last begun, with each Translate
   undone. *)
PROCEDURE (d: PagedDevice) EndPage*;
BEGIN Stop(d)
END EndPage;

(* Finishes the job, with no page under way: whether its file was
   written, or for a Printer, whether FLTK reported no error. Only a
   Printer can have another job. *)
PROCEDURE (d: PagedDevice) EndJob*(): BOOLEAN;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := J(d); ASSERT(~d.begun, Fl.OutOfOrder);
  RETURN Ended(d)
END EndJob;

(* The page's margins, outside what PrintableRect gives. *)
PROCEDURE (d: PagedDevice) Margins*(VAR left, top, right, bottom: INTEGER);
  VAR l, t, r, b: SYSTEM.INT32;
BEGIN CMargins(J(d), l, t, r, b); left := l; top := t; right := r; bottom := b
END Margins;

(* Scales what follows on this page by x across and y down, from the
   page's own size, whatever Scale said before. Neither can be 0. *)
PROCEDURE (d: PagedDevice) Scale*(x, y: LONGREAL);
BEGIN ASSERT(CScale(D(d), x, y) # 0, Fl.Unsupported)
END Scale;

(* Rotates what follows on this page by angle degrees counterclockwise,
   from the page's own rotation. *)
PROCEDURE (d: PagedDevice) Rotate*(angle: LONGREAL);
BEGIN ASSERT(CRotate(D(d), angle) # 0, Fl.Unsupported)
END Rotate;

(* Shows the print dialog, for a job of pages (0 if unknown), and starts
   the job the user asks for: JobOk, JobCancelled or JobFailed. *)
PROCEDURE (p: Printer) BeginJob*(pages: INTEGER): INTEGER;
  VAR h: SYSTEM.ADDRESS; r: INTEGER;
BEGIN
  h := S(p); ASSERT(~p.job, Fl.OutOfOrder);
  r := CJob(h, pages, p.from, p.to); p.job := r = JobOk;
  RETURN r
END BeginJob;

(* The pages the user chose in the last BeginJob. *)
PROCEDURE (p: Printer) Range*(VAR from, to: INTEGER);
  VAR h: SYSTEM.ADDRESS;
BEGIN h := J(p); from := p.from; to := p.to
END Range;

(* One drawing *)

(* Sends drawing to s, until End. *)
PROCEDURE (s: FileSurface) Begin*;
BEGIN ASSERT(~s.begun, Fl.OutOfOrder); Start(s)
END Begin;

(* Sends drawing back where it went before Begin. s must be the surface
   last begun, with each Translate undone. *)
PROCEDURE (s: FileSurface) End*;
BEGIN Stop(s)
END End;

(* Finishes the file; whether it was written. *)
PROCEDURE (s: FileSurface) Finish*(): BOOLEAN;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := J(s); ASSERT(~s.begun, Fl.OutOfOrder);
  RETURN Ended(s)
END Finish;

END FlPrint.
