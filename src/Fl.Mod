MODULE Fl; (* pofltk's core: widgets, groups, windows, boxes, timers, the event loop *)

(* Each widget type extends Widget, and a program extends those in turn:
   NEW(b); Fl.OpenBox(b, ...) makes the FLTK widget for b, whatever
   extension of Box b is. FLTK then calls b's Draw, Handle, Resize and
   Callback; while Handle runs, the Event procedures below say what the
   event was. Draw draws with FlDraw.

   FLTK owns its widgets: one lives until it is deleted, by Delete or
   with its parent group, and its Oberon object lives at least as long,
   kept reachable here (the registry) because the collector never sees
   pointers held only by FLTK. When FLTK destroys a widget it tells this
   module (pofltk.h, Ref), which forgets the object and marks it closed.
   A method of a widget that isn't open - never opened, or deleted -
   halts with NotOpen. PLAN.md, "Object model" and "Lifetime and the
   collector", has the reasons.

   Timers work the same way: a pending timer is kept reachable here until
   it fires or is removed; so is an idle callback while it is added, and
   a file descriptor's watch while it watches.

   The C++ part is Fl.cpp, with pofltk.h. *)

IMPORT SYSTEM, Args;

CONST
  (* pofltk's own version, kept here and nowhere else: 0.x.y until a
     release meant for others, the minor number for features, the patch
     number for fixes, as poc's. Version, ApiVersion and the rest below
     are FLTK's. *)
  PofltkVersion* = "0.3.0";
  PofltkApiVersion* = 300;   (* major * 10000 + minor * 100 + patch, as FLTK's FL_API_VERSION *)

  (* ASSERT codes of programmer errors (PLAN.md, "Halt codes") *)
  NotOpen* = 70;        (* a method of a widget never opened, or deleted *)
  OpenedTwice* = 71;    (* an Open of a widget opened before *)
  NilArgument* = 72;    (* NIL where a widget or timer is required *)
  ClosedResource* = 73; (* a resource used after Close, or missing where needed *)
  IndexOutOfRange* = 74; (* a child index outside the group *)
  NotFiring* = 75;      (* RepeatTimeout outside its timer's Fire *)
  NotAChild* = 76;      (* a widget that must be a group's child isn't *)
  OutOfOrder* = 77;     (* an End that doesn't match the last Begin *)
  Unsupported* = 78;    (* an argument a call can't take, or what this FLTK lacks (Has) *)

  (* what an FLTK may lack, for Has *)
  Svg* = 0;          (* SVG images: Load and LoadData read them *)
  Wayland* = 1;      (* the display is Wayland's *)
  X11* = 2;          (* the display is X11's *)

  (* where Copy puts text, and Paste takes it from: FLTK has no names *)
  Selection* = 0;  (* the selection buffer, pasted with the middle button on X11 *)
  Clipboard* = 1;  (* the clipboard, for cut, copy and paste *)
  Both* = 2;       (* Copy only *)

  (* Widget.state *)
  new = 0; open = 1; closed = 2;

  (* FL_GRAY_RAMP and FL_COLOR_CUBE: where the gray ramp and color cube
     start in FLTK's colormap (GrayRamp, ColorCube; TestConstants checks) *)
  grayRamp = 32; colorCube = 56;

(* BEGIN generated constants: tools/gen-constants.py writes this block,
   from FLTK's headers; edit the script, not the block. *)

  (* events (Fl_Event), the argument of Handle *)
  EvNone* = 0;
  EvPush* = 1;
  EvRelease* = 2;
  EvEnter* = 3;
  EvLeave* = 4;
  EvDrag* = 5;
  EvFocus* = 6;
  EvUnfocus* = 7;
  EvKeyDown* = 8;
  EvKeyUp* = 9;
  EvClose* = 10;
  EvMove* = 11;
  EvShortcut* = 12;
  EvDeactivate* = 13;
  EvActivate* = 14;
  EvHide* = 15;
  EvShow* = 16;
  EvPaste* = 17;
  EvSelectionClear* = 18;
  EvMouseWheel* = 19;
  EvDndEnter* = 20;
  EvDndDrag* = 21;
  EvDndLeave* = 22;
  EvDndRelease* = 23;
  EvScreenConfigurationChanged* = 24;
  EvFullscreen* = 25;
  EvZoomGesture* = 26;
  EvZoomEvent* = 27;

  (* when a widget calls its Callback (Fl_When) *)
  WhenNever* = {};
  WhenChanged* = {0};
  WhenNotChanged* = {1};
  WhenRelease* = {2};
  WhenReleaseAlways* = {1, 2};
  WhenEnterKey* = {3};
  WhenEnterKeyAlways* = {1, 3};
  WhenEnterKeyChanged* = {0, 1, 3};
  WhenClosed* = {4};

  (* box types (Fl_Boxtype); Fl.cpp defines every one at start-up *)
  NoBox* = 0;
  FlatBox* = 1;
  UpBox* = 2;
  DownBox* = 3;
  UpFrame* = 4;
  DownFrame* = 5;
  ThinUpBox* = 6;
  ThinDownBox* = 7;
  ThinUpFrame* = 8;
  ThinDownFrame* = 9;
  EngravedBox* = 10;
  EmbossedBox* = 11;
  EngravedFrame* = 12;
  EmbossedFrame* = 13;
  BorderBox* = 14;
  ShadowBox* = 15;
  BorderFrame* = 16;
  ShadowFrame* = 17;
  RoundedBox* = 18;
  RShadowBox* = 19;
  RoundedFrame* = 20;
  RFlatBox* = 21;
  RoundUpBox* = 22;
  RoundDownBox* = 23;
  DiamondUpBox* = 24;
  DiamondDownBox* = 25;
  OvalBox* = 26;
  OShadowBox* = 27;
  OvalFrame* = 28;
  OFlatBox* = 29;
  PlasticUpBox* = 30;
  PlasticDownBox* = 31;
  PlasticUpFrame* = 32;
  PlasticDownFrame* = 33;
  PlasticThinUpBox* = 34;
  PlasticThinDownBox* = 35;
  PlasticRoundUpBox* = 36;
  PlasticRoundDownBox* = 37;
  GtkUpBox* = 38;
  GtkDownBox* = 39;
  GtkUpFrame* = 40;
  GtkDownFrame* = 41;
  GtkThinUpBox* = 42;
  GtkThinDownBox* = 43;
  GtkThinUpFrame* = 44;
  GtkThinDownFrame* = 45;
  GtkRoundUpBox* = 46;
  GtkRoundDownBox* = 47;
  GleamUpBox* = 48;
  GleamDownBox* = 49;
  GleamUpFrame* = 50;
  GleamDownFrame* = 51;
  GleamThinUpBox* = 52;
  GleamThinDownBox* = 53;
  GleamRoundUpBox* = 54;
  GleamRoundDownBox* = 55;
  OxyUpBox* = 56;
  OxyDownBox* = 57;
  OxyUpFrame* = 58;
  OxyDownFrame* = 59;
  OxyThinUpBox* = 60;
  OxyThinDownBox* = 61;
  OxyThinUpFrame* = 62;
  OxyThinDownFrame* = 63;
  OxyRoundUpBox* = 64;
  OxyRoundDownBox* = 65;
  OxyButtonUpBox* = 66;
  OxyButtonDownBox* = 67;
  FreeBoxtype* = 68;

  (* label types (Fl_Labeltype); multi, icon and image labels come with images *)
  NormalLabel* = 0;
  NoLabel* = 1;
  ShadowLabel* = 2;
  EngravedLabel* = 3;
  EmbossedLabel* = 4;

  (* label alignment (Fl_Align) *)
  AlignCenter* = {};
  AlignTop* = {0};
  AlignBottom* = {1};
  AlignLeft* = {2};
  AlignRight* = {3};
  AlignInside* = {4};
  AlignTextOverImage* = {5};
  AlignImageOverText* = {};
  AlignClip* = {6};
  AlignWrap* = {7};
  AlignImageNextToText* = {8};
  AlignTextNextToImage* = {5, 8};
  AlignImageBackdrop* = {9};
  AlignTopLeft* = {0, 2};
  AlignTopRight* = {0, 3};
  AlignBottomLeft* = {1, 2};
  AlignBottomRight* = {1, 3};
  AlignLeftTop* = {0, 1, 2};
  AlignRightTop* = {0, 1, 3};
  AlignLeftBottom* = {0, 2, 3};
  AlignRightBottom* = {1, 2, 3};
  AlignNoWrap* = {};
  AlignPositionMask* = {0, 1, 2, 3};
  AlignImageMask* = {5, 8, 9};

  (* fonts (Fl_Font); add Bold, Italic or BoldItalic to Helvetica, Courier or Times *)
  Helvetica* = 0;
  HelveticaBold* = 1;
  HelveticaItalic* = 2;
  HelveticaBoldItalic* = 3;
  Courier* = 4;
  CourierBold* = 5;
  CourierItalic* = 6;
  CourierBoldItalic* = 7;
  Times* = 8;
  TimesBold* = 9;
  TimesItalic* = 10;
  TimesBoldItalic* = 11;
  Symbol* = 12;
  Screen* = 13;
  ScreenBold* = 14;
  ZapfDingbats* = 15;
  FreeFont* = 16;
  Bold* = 1;
  Italic* = 2;
  BoldItalic* = 3;

  (* colors (Fl_Color): an index into FLTK's colormap, or RGB(r, g, b) *)
  ForegroundColor* = 0;
  Background2Color* = 7;
  InactiveColor* = 8;
  SelectionColor* = 15;
  Gray0* = 32;
  Dark3* = 39;
  Dark2* = 45;
  Dark1* = 47;
  BackgroundColor* = 49;
  Light1* = 50;
  Light2* = 52;
  Light3* = 54;
  Gray* = 49;
  Black* = 56;
  Red* = 88;
  Green* = 63;
  Yellow* = 95;
  Blue* = 216;
  Magenta* = 248;
  Cyan* = 223;
  DarkRed* = 72;
  DarkGreen* = 60;
  DarkYellow* = 76;
  DarkBlue* = 136;
  DarkMagenta* = 152;
  DarkCyan* = 140;
  White* = 255;
  FreeColor* = 16;
  NumFreeColor* = 16;
  NumGray* = 24;
  NumRed* = 5;
  NumGreen* = 8;
  NumBlue* = 5;

  (* keys (Fl::event_key): a character's code for most; KeyF + n is F<n>, KeyKP + c keypad c *)
  KeyButton* = 65256;
  KeyBackSpace* = 65288;
  KeyTab* = 65289;
  KeyIsoKey* = 65292;
  KeyEnter* = 65293;
  KeyPause* = 65299;
  KeyScrollLock* = 65300;
  KeyEscape* = 65307;
  KeyKana* = 65326;
  KeyEisu* = 65327;
  KeyYen* = 65328;
  KeyJISUnderscore* = 65329;
  KeyHome* = 65360;
  KeyLeft* = 65361;
  KeyUp* = 65362;
  KeyRight* = 65363;
  KeyDown* = 65364;
  KeyPageUp* = 65365;
  KeyPageDown* = 65366;
  KeyEnd* = 65367;
  KeyPrint* = 65377;
  KeyInsert* = 65379;
  KeyMenu* = 65383;
  KeyHelp* = 65384;
  KeyNumLock* = 65407;
  KeyKP* = 65408;
  KeyKPEnter* = 65421;
  KeyKPLast* = 65469;
  KeyF* = 65469;
  KeyFLast* = 65504;
  KeyShiftL* = 65505;
  KeyShiftR* = 65506;
  KeyControlL* = 65507;
  KeyControlR* = 65508;
  KeyCapsLock* = 65509;
  KeyMetaL* = 65511;
  KeyMetaR* = 65512;
  KeyAltL* = 65513;
  KeyAltR* = 65514;
  KeyDelete* = 65535;
  KeyAltGr* = 65027;
  KeyVolumeDown* = 61201;
  KeyVolumeMute* = 61202;
  KeyVolumeUp* = 61203;
  KeyMediaPlay* = 61204;
  KeyMediaStop* = 61205;
  KeyMediaPrev* = 61206;
  KeyMediaNext* = 61207;
  KeyHomePage* = 61208;
  KeyMail* = 61209;
  KeySearch* = 61211;
  KeyBack* = 61222;
  KeyForward* = 61223;
  KeyStop* = 61224;
  KeyRefresh* = 61225;
  KeySleep* = 61231;
  KeyFavorites* = 61232;

  (* mouse buttons (Fl::event_button) *)
  LeftMouse* = 1;
  MiddleMouse* = 2;
  RightMouse* = 3;
  BackMouse* = 4;
  ForwardMouse* = 5;

  (* the shift keys and mouse buttons held (Fl::event_state); Command is Ctrl, but Meta on macOS *)
  Shift* = {16};
  CapsLock* = {17};
  Ctrl* = {18};
  Alt* = {19};
  NumLock* = {20};
  Meta* = {22};
  ScrollLock* = {23};
  Button1* = {24};
  Button2* = {25};
  Button3* = {26};
  Button4* = {27};
  Button5* = {28};
  Buttons* = {24, 25, 26, 27, 28};
  Command* = {18};
  Control* = {22};

  (* what needs redrawing (Fl_Damage), Widget.Damage *)
  DamageChild* = {0};
  DamageExpose* = {1};
  DamageScroll* = {2};
  DamageOverlay* = {3};
  DamageUser1* = {4};
  DamageUser2* = {5};
  DamageAll* = {7};

  (* mouse cursors (Fl_Cursor), Window.SetCursor *)
  CursorDefault* = 0;
  CursorArrow* = 35;
  CursorCross* = 66;
  CursorWait* = 76;
  CursorInsert* = 77;
  CursorHand* = 31;
  CursorHelp* = 47;
  CursorMove* = 27;
  CursorNs* = 78;
  CursorWe* = 79;
  CursorNwse* = 80;
  CursorNesw* = 81;
  CursorN* = 70;
  CursorNe* = 69;
  CursorE* = 49;
  CursorSe* = 8;
  CursorS* = 9;
  CursorSw* = 7;
  CursorW* = 36;
  CursorNw* = 68;
  CursorNone* = 255;

  (* FLTK's options (Fl::Fl_Option), Option and SetOption *)
  OptionArrowFocus* = 0;
  OptionVisibleFocus* = 1;
  OptionDndText* = 2;
  OptionShowTooltips* = 3;
  OptionFnfcUsesGtk* = 4;
  OptionFnfcUsesZenity* = 5;
  OptionFnfcUsesKdialog* = 6;
  OptionPrinterUsesGtk* = 7;
  OptionShowScaling* = 8;
  OptionSimpleZoomShortcut* = 9;

  (* how Contrast chooses (SetContrastMode) *)
  ContrastNone* = 0;
  ContrastLegacy* = 1;
  ContrastCielab* = 2;
  ContrastCustom* = 3;

  (* why a widget called back (CallbackReason) *)
  ReasonUnknown* = 0;
  ReasonSelected* = 1;
  ReasonDeselected* = 2;
  ReasonReselected* = 3;
  ReasonOpened* = 4;
  ReasonClosed* = 5;
  ReasonDragged* = 6;
  ReasonCancelled* = 7;
  ReasonChanged* = 8;
  ReasonGotFocus* = 9;
  ReasonLostFocus* = 10;
  ReasonReleased* = 11;
  ReasonEnterKey* = 12;
  ReasonUser* = 32;

  (* what Visual asks for, added together *)
  VisualRgb* = 0;
  VisualIndex* = 1;
  VisualSingle* = 0;
  VisualDouble* = 2;
  VisualRgb8* = 64;

  (* what a watched file descriptor waits for (FdWatch, WatchFd) *)
  FdRead* = {0};
  FdWrite* = {2};
  FdExcept* = {3};
(* END generated constants *)

  MaxFont* = 65535;  (* the last number SetFont takes: a limit of pofltk's *)

TYPE
  (* Text whose length isn't known before it is read: what Input.Text,
     TextBuffer.Text and the other getters of text return, holding the
     text and a 0X, and no more. *)
  String* = POINTER TO ARRAY OF CHAR;

  Widget* = POINTER TO WidgetDesc;
  WidgetDesc* = RECORD
    h-: SYSTEM.ADDRESS;  (* the Fl_Widget *; 0 unless open *)
    state: SHORTINT;
    prev, next: Widget;  (* the registry, while open *)
    (* called by the default Callback, when set *)
    action*: PROCEDURE (w: Widget)
  END;

  Group* = POINTER TO GroupDesc;
  GroupDesc* = RECORD (WidgetDesc) END;

  Window* = POINTER TO WindowDesc;
  WindowDesc* = RECORD (GroupDesc) END;

  DoubleWindow* = POINTER TO DoubleWindowDesc;
  DoubleWindowDesc* = RECORD (WindowDesc) END;

  (* A window that draws on the screen directly, however FLTK's other
     windows do it. *)
  (* a window with a picture over its widgets, drawn by DrawOverlay, that
     changes without their being redrawn: a selection's rectangle. FLTK
     erases it first. *)
  OverlayWindow* = POINTER TO OverlayWindowDesc;
  OverlayWindowDesc* = RECORD (DoubleWindowDesc) END;

  SingleWindow* = POINTER TO SingleWindowDesc;
  SingleWindowDesc* = RECORD (WindowDesc) END;

  (* A window for a menu or the like, which a program makes itself. *)
  MenuWindow* = POINTER TO MenuWindowDesc;
  MenuWindowDesc* = RECORD (SingleWindowDesc) END;

  (* FLTK's Fl_Rect: a place and size. Right and Bottom are the first
     coordinates outside it. *)
  Rect* = RECORD
    x*, y*, w*, h*: INTEGER
  END;

  (* Says whether a widget still exists, across a call that may delete
     it. *)
  Tracker* = POINTER TO TrackerDesc;
  TrackerDesc* = RECORD
    w: Widget  (* NIL once it is found deleted *)
  END;

  Box* = POINTER TO BoxDesc;
  BoxDesc* = RECORD (WidgetDesc) END;

  Timer* = POINTER TO TimerDesc;
  TimerDesc* = RECORD
    pending: BOOLEAN;
    prev, next: Timer;   (* the pending timers *)
    (* called by the default Fire, when set *)
    action*: PROCEDURE (t: Timer)
  END;

  (* Runs whenever the event loop has nothing else to do, while added
     (AddIdle): its Run, whose default calls its action. *)
  Idle* = POINTER TO IdleDesc;
  IdleDesc* = RECORD
    added: BOOLEAN;
    prev, next: Idle;    (* the idles added *)
    action*: PROCEDURE (i: Idle)
  END;

  (* Runs each time the event loop is about to wait, while added
     (AddCheck): its Run, whose default calls its action. *)
  Checker* = POINTER TO CheckerDesc;
  CheckerDesc* = RECORD
    added: BOOLEAN;
    prev, next: Checker; (* the checkers added *)
    action*: PROCEDURE (c: Checker)
  END;

  (* Watches a file descriptor, fd, for what when says (FdRead, FdWrite,
     FdExcept), while it watches (WatchFd): its Ready, whose default
     calls its action, runs when the descriptor is ready for one of them.
     FLTK doesn't say which. *)
  FdWatch* = POINTER TO FdWatchDesc;
  FdWatchDesc* = RECORD
    fd-: INTEGER;
    when-: SET;          (* {} when it isn't watching *)
    prev, next: FdWatch; (* the watches watching *)
    action*: PROCEDURE (w: FdWatch)
  END;

  (* Sees every event first (SetEventDispatch), with its window: NIL for
     one FLTK made itself, such as a menu's or a dialog's, or for an
     event with none. It returns TRUE if the event was used, as
     HandleDefault, which hands the event on, says. *)
  EventDispatch* = PROCEDURE (event: INTEGER; w: Window): BOOLEAN;

  (* Sees an event no widget used (AddHandler), such as an EvShortcut no
     widget took. It returns TRUE if it used the event, which then goes
     to no other handler. *)
  EventHandler* = PROCEDURE (event: INTEGER): BOOLEAN;
  HandlerNode = POINTER TO RECORD
    h: EventHandler;
    next: HandlerNode
  END;

  (* Asked for a color against bg, with context and size as ContrastSized
     has them (SetContrastFunction). *)
  ContrastFunction* = PROCEDURE (fg, bg, context, size: INTEGER): INTEGER;

  (* Draws a box of color c (SetBoxtype), as any drawing, with FlDraw. *)
  BoxDraw* = PROCEDURE (x, y, w, h, c: INTEGER);

  (* Told that w, the program's, is to close (SetAtclose). *)
  Atclose* = PROCEDURE (w: Window);

  (* Told FLTK's fatal error (SetAbort). *)
  Abort* = PROCEDURE (message-: ARRAY OF CHAR);

  (* Told that source, Selection or Clipboard, has another program's
     contents (AddClipboardNotify). *)
  ClipboardNotify* = PROCEDURE (source: INTEGER);

  ClipboardNode = POINTER TO RECORD
    h: ClipboardNotify;  (* NIL once removed *)
    next: ClipboardNode
  END;

  (* A moment, as Now gives it. FLTK's seconds are a time_t, whose size
     differs, so here a LONGREAL, which holds them exactly. *)
  Timestamp* = RECORD
    sec-: LONGREAL;
    usec-: INTEGER
  END;

  SelfProc = PROCEDURE (self: SYSTEM.ADDRESS);
  HandleProc = PROCEDURE (self: SYSTEM.ADDRESS; event: SYSTEM.INT32): SYSTEM.INT32;
  ResizeProc = PROCEDURE (self: SYSTEM.ADDRESS; x, y, w, h: SYSTEM.INT32);
  DispatchProc = PROCEDURE (event: SYSTEM.INT32; self: SYSTEM.ADDRESS): SYSTEM.INT32;
  HandlerProc = PROCEDURE (event: SYSTEM.INT32): SYSTEM.INT32;
  ClipboardProc = PROCEDURE (source: SYSTEM.INT32);
  ArgProc = PROCEDURE (i: SYSTEM.INT32): SYSTEM.INT32;

  (* A program's own command-line options (ParseArgs): given argument i
     (Args.Get), the number of words of it the program uses: 0 if it
     isn't one of them, 1 for an option alone, 2 for one with a value. *)
  ArgHandler* = PROCEDURE (i: INTEGER): INTEGER;

VAR
  widgets: Widget;  (* every open widget: the registry *)
  timers: Timer;    (* every pending timer *)
  openCount, pendingCount: LONGINT;
  firing: Timer;    (* the timer whose Fire is running, or NIL *)
  argHandler: ArgHandler;  (* the handler of the ParseArgs running *)
  idles: Idle;               (* every idle added *)
  watches: FdWatch;          (* every watch watching *)
  dispatch: EventDispatch;   (* the event dispatch, or NIL for FLTK's own *)
  dispatching: INTEGER;      (* how many dispatch calls are running *)
  handlers: HandlerNode;     (* the event handlers, newest first *)
  checkers: Checker;         (* every checker added *)
  atclose: Atclose;          (* SetAtclose's, or NIL for FLTK's own *)
  abort: Abort;              (* SetAbort's, or NIL for FLTK's own *)
  notices: ClipboardNode;    (* the clipboard's, newest first *)

PROCEDURE ["C", "ofl_overlay_window_new"] COverlayWindowNew(placed, x, y, w, h: SYSTEM.INT32; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_register_overlay"] CRegisterOverlay(drawOverlay: SelfProc);
PROCEDURE ["C", "ofl_overlay_can_do"] COverlayCanDo(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_overlay_redraw"] COverlayRedraw(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_register"] CRegister(callback, draw: SelfProc; handle: HandleProc; resize: ResizeProc; deleted, timeout: SelfProc);
PROCEDURE ["C", "ofl_group_new"] CGroupNew(x, y, w, h: SYSTEM.INT32; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_window_new"] CWindowNew(placed, x, y, w, h: SYSTEM.INT32; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_double_window_new"] CDoubleWindowNew(placed, x, y, w, h: SYSTEM.INT32; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_single_window_new"] CSingleWindowNew(menu, placed, x, y, w, h: SYSTEM.INT32; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_window_set_xclass"] CSetXClass(w: SYSTEM.ADDRESS; name: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_window_xclass"] CXClass(w: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_group_draw_child"] CDrawChild(g, w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_group_draw_children"] CDrawChildren(g: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_tooltip_delay"] CTooltipDelay(what: SYSTEM.INT32): LONGREAL;
PROCEDURE ["C", "ofl_tooltip_set_delay"] CTooltipSetDelay(what: SYSTEM.INT32; v: LONGREAL);
PROCEDURE ["C", "ofl_tooltip_setting"] CTooltipSetting(what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_tooltip_set_setting"] CTooltipSetSetting(what, v: SYSTEM.INT32);
PROCEDURE ["C", "ofl_tooltip_current"] CTooltipCurrent(): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_tooltip_set_current"] CTooltipSetCurrent(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_tooltip_enter_area"] CEnterArea(w: SYSTEM.ADDRESS; x, y, width, height: SYSTEM.INT32; text: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_scheme_count"] CSchemeCount(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_scheme_name"] CSchemeName(i: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_add_scheme_name"] CAddSchemeName(name: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_box_new"] CBoxNew(x, y, w, h: SYSTEM.INT32; self: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_widget_delete"] CDelete(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_show"] CShow(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_hide"] CHide(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_redraw"] CRedraw(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_redraw_label"] CRedrawLabel(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_measure_label"] CMeasureLabel(w: SYSTEM.ADDRESS; wrap: SYSTEM.INT32; VAR ww, hh: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_do_callback"] CDoCallback(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_visible"] CVisible(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_set_visible"] CSetVisible(w: SYSTEM.ADDRESS; v: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_default_callback"] CDefaultCallback(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_window_default_callback"] CWindowDefaultCallback(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_base_draw"] CBaseDraw(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_base_handle"] CBaseHandle(w: SYSTEM.ADDRESS; event: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_copy_label"] CCopyLabel(w: SYSTEM.ADDRESS; label: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_widget_label"] CLabel(w: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_widget_x"] CX(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_y"] CY(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_w"] CW(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_h"] CH(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_base_resize"] CBaseResize(w: SYSTEM.ADDRESS; x, y, width, height: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_draw_box"] CDrawBox(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_draw_label"] CDrawLabel(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_draw_focus"] CDrawFocus(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_changed"] CChanged(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_set_changed"] CSetChanged(w: SYSTEM.ADDRESS; c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_damage"] CDamage(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_set_damage"] CSetDamage(w: SYSTEM.ADDRESS; d: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_clear_damage"] CClearDamage(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_damage_area"] CDamageArea(w: SYSTEM.ADDRESS; d, x, y, ww, h: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_take_focus"] CTakeFocus(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_visible_focus"] CVisibleFocus(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_set_visible_focus"] CSetVisibleFocus(w: SYSTEM.ADDRESS; v: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_event_inside"] CWidgetEventInside(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_window_cursor"] CCursor(w: SYSTEM.ADDRESS; c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_window_decorated_w"] CDecoratedW(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_window_decorated_h"] CDecoratedH(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event"] CEvent(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_x"] CEventX(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_y"] CEventY(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_x_root"] CEventXRoot(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_y_root"] CEventYRoot(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_dx"] CEventDx(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_dy"] CEventDy(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_button"] CEventButton(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_clicks"] CEventClicks(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_set_event_clicks"] CSetEventClicks(n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_event_is_click"] CEventIsClick(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_is_click_off"] CEventIsClickOff;
PROCEDURE ["C", "ofl_event_key"] CEventKey(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_original_key"] CEventOriginalKey(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_key_down"] CEventKeyDown(k: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_get_key"] CGetKey(k: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_state"] CEventState(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_text"] CEventText(): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_event_length"] CEventLength(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_copy"] CCopy(text: ARRAY OF CHAR; n, destination: SYSTEM.INT32);
PROCEDURE ["C", "ofl_paste"] CPaste(receiver: SYSTEM.ADDRESS; source, image: SYSTEM.INT32);
PROCEDURE ["C", "ofl_clipboard_contains"] CClipboardContains(image: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_is_image"] CEventIsImage(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_dnd"] CDnd(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_dnd_text_ops"] CDndTextOps(what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_option"] COption(o, what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_inside"] CEventInside(x, y, w, h: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_focus"] CFocus(): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_belowmouse"] CBelowmouse(): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_pushed"] CPushed(): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_any"] CAny(which: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_open_uri"] COpenURI(uri: ARRAY OF CHAR; VAR msg: ARRAY OF CHAR; n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_register_loop"] CRegisterLoop(idle, fd: SelfProc; dispatch: DispatchProc; handler: HandlerProc);
PROCEDURE ["C", "ofl_register_statics"] CRegisterStatics(check, atclose, abort: SelfProc; clipboard: ClipboardProc);
PROCEDURE ["C", "ofl_event_handlers"] CEventHandlers(on: SYSTEM.INT32);
PROCEDURE ["C", "ofl_redraw_all"] CRedrawAll;
PROCEDURE ["C", "ofl_window_shown_any"] CWindowShownAny(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_add_idle"] CAddIdle(self: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_remove_idle"] CRemoveIdle(self: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_add_fd"] CAddFd(fd, when: SYSTEM.INT32; self: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_remove_fd"] CRemoveFd(fd, when: SYSTEM.INT32);
PROCEDURE ["C", "ofl_event_dispatch"] CEventDispatch(on: SYSTEM.INT32);
PROCEDURE ["C", "ofl_handle_default"] CHandleDefault(event: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_set_event_key"] CSetEventKey(key: SYSTEM.INT32);
PROCEDURE ["C", "ofl_set_event_text"] CSetEventText(s: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_screen"] CScreen(what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_screen_count"] CScreenCount(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_scrollbar_size"] CScrollbarSize(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_set_scrollbar_size"] CSetScrollbarSize(n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_screen_xywh"] CScreenXYWH(n, work: SYSTEM.INT32; VAR x, y, w, h: SYSTEM.INT32);
PROCEDURE ["C", "ofl_screen_num"] CScreenNum(x, y: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_args"] CArgs(argc: SYSTEM.INT32; argv: SYSTEM.ADDRESS; VAR i: SYSTEM.INT32; handler: ArgProc): SYSTEM.INT32;
PROCEDURE ["C", "ofl_arg"] CArg(argc: SYSTEM.INT32; argv: SYSTEM.ADDRESS; i: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_args_help"] CArgsHelp(): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_window_show_args"] CWindowShowArgs(w: SYSTEM.ADDRESS; argc: SYSTEM.INT32; argv: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_set_focus"] CSetFocus(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_group_begin"] CBegin(g: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_group_end"] CEnd(g: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_group_children"] CChildren(g: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_group_child"] CChild(g: SYSTEM.ADDRESS; i: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_run"] CRun(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_check"] CCheck(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_wait"] CWait(seconds: LONGREAL);
PROCEDURE ["C", "ofl_add_timeout"] CAddTimeout(seconds: LONGREAL; self: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_repeat_timeout"] CRepeatTimeout(seconds: LONGREAL; self: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_remove_timeout"] CRemoveTimeout(self: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_position"] CPosition(w: SYSTEM.ADDRESS; x, y: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_size"] CSize(w: SYSTEM.ADDRESS; width, height: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_parent"] CParent(w: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_widget_visible_r"] CVisibleR(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_activate"] CActivate(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_deactivate"] CDeactivate(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_widget_window"] CWindow(w: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_widget_output"] COutput(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_set_output"] CSetOutput(w: SYSTEM.ADDRESS; on: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_active"] CActive(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_active_r"] CActiveR(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_color"] CColor(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_set_color"] CSetColor(w: SYSTEM.ADDRESS; c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_selection_color"] CSelectionColor(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_set_selection_color"] CSetSelectionColor(w: SYSTEM.ADDRESS; c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_box"] CBoxType(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_set_box"] CSetBoxType(w: SYSTEM.ADDRESS; b: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_labelfont"] CLabelFont(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_set_labelfont"] CSetLabelFont(w: SYSTEM.ADDRESS; f: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_labelsize"] CLabelSize(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_set_labelsize"] CSetLabelSize(w: SYSTEM.ADDRESS; s: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_label_margin"] CLabelMargin(w: SYSTEM.ADDRESS; which: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_set_label_margin"] CSetLabelMargin(w: SYSTEM.ADDRESS; which, px: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_labelcolor"] CLabelColor(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_set_labelcolor"] CSetLabelColor(w: SYSTEM.ADDRESS; c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_labeltype"] CLabelType(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_set_labeltype"] CSetLabelType(w: SYSTEM.ADDRESS; t: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_align"] CAlign(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_set_align"] CSetAlign(w: SYSTEM.ADDRESS; a: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_when"] CWhen(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_widget_set_when"] CSetWhen(w: SYSTEM.ADDRESS; when: SYSTEM.INT32);
PROCEDURE ["C", "ofl_widget_copy_tooltip"] CCopyTooltip(w: SYSTEM.ADDRESS; text: ARRAY OF CHAR);
PROCEDURE ["C", "ofl_widget_tooltip"] CTooltip(w: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_group_add"] CAdd(g, w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_group_insert"] CInsert(g, w: SYSTEM.ADDRESS; i: SYSTEM.INT32);
PROCEDURE ["C", "ofl_group_remove"] CRemove(g, w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_group_find"] CFind(g, w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_group_clear"] CClear(g: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_group_init_sizes"] CInitSizes(g: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_group_set_resizable"] CSetResizable(g, w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_group_resizable"] CResizable(g: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_window_shown"] CShown(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_window_make_current"] CMakeCurrent(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_window_wait_for_expose"] CWaitForExpose(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_window_size_range"] CSizeRange(w: SYSTEM.ADDRESS; minw, minh, maxw, maxh, dw, dh, aspect: SYSTEM.INT32);
PROCEDURE ["C", "ofl_window_get_size_range"] CGetSizeRange(w: SYSTEM.ADDRESS; VAR minw, minh, maxw, maxh, dw, dh, aspect: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_window_set_modal"] CSetModal(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_window_set_non_modal"] CSetNonModal(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_window_hotspot_at"] CHotspotAt(w: SYSTEM.ADDRESS; x, y, off: SYSTEM.INT32);
PROCEDURE ["C", "ofl_window_hotspot"] CHotspot(w, o: SYSTEM.ADDRESS; off: SYSTEM.INT32);
PROCEDURE ["C", "ofl_window_modal"] CModal(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_window_fullscreen"] CFullscreen(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_window_fullscreen_off"] CFullscreenOff(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_window_fullscreen_active"] CFullscreenActive(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_window_fullscreen_screens"] CFullscreenScreens(w: SYSTEM.ADDRESS; top, bottom, left, right: SYSTEM.INT32);
PROCEDURE ["C", "ofl_window_iconize"] CIconize(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_window_maximize"] CMaximize(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_window_un_maximize"] CUnMaximize(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_window_maximize_active"] CMaximizeActive(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_window_free_position"] CFreePosition(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_window_set_border"] CSetBorder(w: SYSTEM.ADDRESS; b: SYSTEM.INT32);
PROCEDURE ["C", "ofl_window_border"] CBorder(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_window_screen_num"] CWindowScreenNum(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_window_set_screen_num"] CWindowSetScreenNum(w: SYSTEM.ADDRESS; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_set_color"] CSetIndexColor(i, c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_get_rgb"] CGetRGB(c: SYSTEM.INT32; VAR r, g, b: SYSTEM.INT32);
PROCEDURE ["C", "ofl_menu_linespacing"] CMenuLinespacing(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_set_menu_linespacing"] CSetMenuLinespacing(n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_shortcut_label"] CShortcutLabel(s: SYSTEM.INT32; VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_background"] CBackground(r, g, b: SYSTEM.INT32);
PROCEDURE ["C", "ofl_background2"] CBackground2(r, g, b: SYSTEM.INT32);
PROCEDURE ["C", "ofl_foreground"] CForeground(r, g, b: SYSTEM.INT32);
PROCEDURE ["C", "ofl_color_average"] CColorAverage(c1, c2: SYSTEM.INT32; weight: LONGREAL): SYSTEM.INT32;
PROCEDURE ["C", "ofl_contrast"] CContrast(fg, bg: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_inactive"] CInactive(c: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_normal_size"] CNormalSize(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_set_normal_size"] CSetNormalSize(s: SYSTEM.INT32);
PROCEDURE ["C", "ofl_box_d"] CBoxD(b, what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_has"] CHas(feature: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_set_scheme"] CSetScheme(name: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_set_system_scheme"] CSetSystemScheme(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_scheme"] CScheme(): SYSTEM.ADDRESS;

(* s := the C string at a, truncated to fit s; "" if a is 0. *)
PROCEDURE FromC(a: SYSTEM.ADDRESS; VAR s: ARRAY OF CHAR);
  VAR i: LONGINT; c: CHAR;
BEGIN
  i := 0;
  IF a # 0 THEN
    SYSTEM.GET(a, c);
    WHILE (c # 0X) & (i < LEN(s) - 1) DO
      s[i] := c; INC(i); SYSTEM.GET(a + i, c)
    END
  END;
  s[i] := 0X
END FromC;

(* The registry *)

PROCEDURE Register(w: Widget);
BEGIN
  w.prev := NIL; w.next := widgets;
  IF widgets # NIL THEN widgets.prev := w END;
  widgets := w; INC(openCount)
END Register;

PROCEDURE Unregister(w: Widget);
BEGIN
  IF w.prev = NIL THEN widgets := w.next ELSE w.prev.next := w.next END;
  IF w.next # NIL THEN w.next.prev := w.prev END;
  w.prev := NIL; w.next := NIL; DEC(openCount)
END Unregister;

(* The handle of w, which must be open: for pofltk's modules, whose
   methods pass it to their C++ part. *)
PROCEDURE Live*(w: Widget): SYSTEM.ADDRESS;
BEGIN
  ASSERT(w # NIL, NilArgument); ASSERT(w.state = open, NotOpen);
  RETURN w.h
END Live;

(* For pofltk's modules only: makes w the Oberon object of h, the widget
   their C++ part has just made with ofl::open(..., self) - self being
   SelfOf(w), which must have come from BeginOpen(w) first. *)
PROCEDURE BeginOpen*(w: Widget): SYSTEM.ADDRESS;
BEGIN
  ASSERT(w # NIL, NilArgument); ASSERT(w.state = new, OpenedTwice);
  RETURN SYSTEM.VAL(SYSTEM.ADDRESS, w)
END BeginOpen;

PROCEDURE EndOpen*(w: Widget; h: SYSTEM.ADDRESS);
BEGIN
  w.h := h; w.state := open; Register(w)
END EndOpen;

(* The number of open widgets: those the registry holds. *)
PROCEDURE OpenWidgets*(): LONGINT;
BEGIN RETURN openCount
END OpenWidgets;

(* Opening the widget types of this module. x, y are relative to the
   window, as FLTK's are; the label is copied. *)

PROCEDURE OpenGroup*(g: Group; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN
  EndOpen(g, CGroupNew(x, y, w, h, BeginOpen(g))); CCopyLabel(g.h, label)
END OpenGroup;

(* A window the window manager places. *)
PROCEDURE OpenWindow*(win: Window; w, h: INTEGER; title-: ARRAY OF CHAR);
BEGIN
  EndOpen(win, CWindowNew(0, 0, 0, w, h, BeginOpen(win))); CCopyLabel(win.h, title)
END OpenWindow;

(* A window at x, y on the screen. *)
PROCEDURE OpenWindowAt*(win: Window; x, y, w, h: INTEGER; title-: ARRAY OF CHAR);
BEGIN
  EndOpen(win, CWindowNew(1, x, y, w, h, BeginOpen(win))); CCopyLabel(win.h, title)
END OpenWindowAt;

PROCEDURE OpenDoubleWindow*(win: DoubleWindow; w, h: INTEGER; title-: ARRAY OF CHAR);
BEGIN
  EndOpen(win, CDoubleWindowNew(0, 0, 0, w, h, BeginOpen(win))); CCopyLabel(win.h, title)
END OpenDoubleWindow;

PROCEDURE OpenDoubleWindowAt*(win: DoubleWindow; x, y, w, h: INTEGER; title-: ARRAY OF CHAR);
BEGIN
  EndOpen(win, CDoubleWindowNew(1, x, y, w, h, BeginOpen(win))); CCopyLabel(win.h, title)
END OpenDoubleWindowAt;

PROCEDURE OpenOverlayWindow*(win: OverlayWindow; w, h: INTEGER; title-: ARRAY OF CHAR);
BEGIN
  EndOpen(win, COverlayWindowNew(0, 0, 0, w, h, BeginOpen(win))); CCopyLabel(win.h, title)
END OpenOverlayWindow;

PROCEDURE OpenOverlayWindowAt*(win: OverlayWindow; x, y, w, h: INTEGER; title-: ARRAY OF CHAR);
BEGIN
  EndOpen(win, COverlayWindowNew(1, x, y, w, h, BeginOpen(win))); CCopyLabel(win.h, title)
END OpenOverlayWindowAt;

PROCEDURE OpenSingleWindow*(win: SingleWindow; w, h: INTEGER; title-: ARRAY OF CHAR);
BEGIN
  EndOpen(win, CSingleWindowNew(0, 0, 0, 0, w, h, BeginOpen(win))); CCopyLabel(win.h, title)
END OpenSingleWindow;

PROCEDURE OpenSingleWindowAt*(win: SingleWindow; x, y, w, h: INTEGER; title-: ARRAY OF CHAR);
BEGIN
  EndOpen(win, CSingleWindowNew(0, 1, x, y, w, h, BeginOpen(win))); CCopyLabel(win.h, title)
END OpenSingleWindowAt;

PROCEDURE OpenMenuWindow*(win: MenuWindow; w, h: INTEGER; title-: ARRAY OF CHAR);
BEGIN
  EndOpen(win, CSingleWindowNew(1, 0, 0, 0, w, h, BeginOpen(win))); CCopyLabel(win.h, title)
END OpenMenuWindow;

PROCEDURE OpenMenuWindowAt*(win: MenuWindow; x, y, w, h: INTEGER; title-: ARRAY OF CHAR);
BEGIN
  EndOpen(win, CSingleWindowNew(1, 1, x, y, w, h, BeginOpen(win))); CCopyLabel(win.h, title)
END OpenMenuWindowAt;

PROCEDURE OpenBox*(b: Box; x, y, w, h: INTEGER; label-: ARRAY OF CHAR);
BEGIN
  EndOpen(b, CBoxNew(x, y, w, h, BeginOpen(b))); CCopyLabel(b.h, label)
END OpenBox;

(* Widget *)

(* TRUE while w is open: opened, and not yet deleted. *)
PROCEDURE (w: Widget) IsOpen*(): BOOLEAN;
BEGIN RETURN w.state = open
END IsOpen;

(* Deletes w's FLTK widget, and its children if it is a group. Inside a
   Callback, Draw, Handle or Fire, FLTK deletes it after that returns, so
   w stays open until then. *)
PROCEDURE (w: Widget) Delete*;
BEGIN CDelete(Live(w))
END Delete;

PROCEDURE (w: Widget) Show*;
BEGIN CShow(Live(w))
END Show;

PROCEDURE (w: Widget) Hide*;
BEGIN CHide(Live(w))
END Hide;

PROCEDURE (w: Widget) Visible*(): BOOLEAN;
BEGIN RETURN CVisible(Live(w)) # 0
END Visible;

(* Sets whether the widget is visible, as Show and Hide do, but with no
   event to it and no redraw. A window opened with no group current is a
   top level, and not visible till shown; added to a group, it needs this
   to show with it. *)
PROCEDURE (w: Widget) SetVisible*(on: BOOLEAN);
BEGIN
  IF on THEN CSetVisible(Live(w), 1) ELSE CSetVisible(Live(w), 0) END
END SetVisible;

PROCEDURE (w: Widget) Redraw*;
BEGIN CRedraw(Live(w))
END Redraw;

(* Redraws w's label alone, and for a label outside w, the part of its
   window under it. *)
PROCEDURE (w: Widget) RedrawLabel*;
BEGIN CRedrawLabel(Live(w))
END RedrawLabel;

(* The size of w's label, text and image, in its font, wrapped at wrap
   pixels, or not if wrap is 0; 0 0 for no label. It sets the current
   font (FlDraw) to the label's. *)
PROCEDURE (w: Widget) MeasureLabel*(wrap: INTEGER; VAR width, height: INTEGER);
  VAR ww, hh: SYSTEM.INT32;
BEGIN CMeasureLabel(Live(w), wrap, ww, hh); width := ww; height := hh
END MeasureLabel;

(* Calls w's Callback, as FLTK does. *)
PROCEDURE (w: Widget) DoCallback*;
BEGIN CDoCallback(Live(w))
END DoCallback;

(* What FLTK calls when w is used: its action, if set, else FLTK's
   default (for a widget, queueing it for Fl::readqueue). *)
PROCEDURE (w: Widget) Callback*;
BEGIN
  IF w.action # NIL THEN w.action(w) ELSE CDefaultCallback(Live(w)) END
END Callback;

(* FLTK's drawing of w, which an extension's Draw may call. *)
PROCEDURE (w: Widget) Draw*;
BEGIN CBaseDraw(Live(w))
END Draw;

(* FLTK's handling of event, TRUE if w used it. *)
PROCEDURE (w: Widget) Handle*(event: INTEGER): BOOLEAN;
BEGIN RETURN CBaseHandle(Live(w), event) # 0
END Handle;

(* Copied; it replaces a multi-label (FlImages.SetMultiLabel). *)
PROCEDURE (w: Widget) SetLabel*(label-: ARRAY OF CHAR);
BEGIN CCopyLabel(Live(w), label)
END SetLabel;

(* The label, truncated to fit label, "" for none or a multi-label. *)
PROCEDURE (w: Widget) GetLabel*(VAR label: ARRAY OF CHAR);
BEGIN FromC(CLabel(Live(w)), label)
END GetLabel;

(* The tooltip is copied too. "" removes it. *)
PROCEDURE (w: Widget) SetTooltip*(text-: ARRAY OF CHAR);
BEGIN CCopyTooltip(Live(w), text)
END SetTooltip;

PROCEDURE (w: Widget) GetTooltip*(VAR text: ARRAY OF CHAR);
BEGIN FromC(CTooltip(Live(w)), text)
END GetTooltip;

(* The label's font, size, color and type: a font such as Helvetica, a
   size in pixels, a color, NormalLabel or another label type. *)
PROCEDURE (w: Widget) LabelFont*(): INTEGER;
BEGIN RETURN CLabelFont(Live(w))
END LabelFont;

PROCEDURE (w: Widget) SetLabelFont*(f: INTEGER);
BEGIN CSetLabelFont(Live(w), f)
END SetLabelFont;

PROCEDURE (w: Widget) LabelSize*(): INTEGER;
BEGIN RETURN CLabelSize(Live(w))
END LabelSize;

PROCEDURE (w: Widget) SetLabelSize*(s: INTEGER);
BEGIN CSetLabelSize(Live(w), s)
END SetLabelSize;

(* The label's margins: the gap in pixels between the label and the
   widget's left and right edges (horizontal) or top and bottom edges
   (vertical), on the sides it is aligned to, both when centred. They
   can be negative; FLTK keeps each in a signed byte, so outside -128 to
   127 they halt (IndexOutOfRange). *)
PROCEDURE (w: Widget) HorizontalLabelMargin*(): INTEGER;
BEGIN RETURN CLabelMargin(Live(w), 0)
END HorizontalLabelMargin;

PROCEDURE (w: Widget) SetHorizontalLabelMargin*(px: INTEGER);
BEGIN
  ASSERT((px >= -128) & (px <= 127), IndexOutOfRange);
  CSetLabelMargin(Live(w), 0, px)
END SetHorizontalLabelMargin;

PROCEDURE (w: Widget) VerticalLabelMargin*(): INTEGER;
BEGIN RETURN CLabelMargin(Live(w), 1)
END VerticalLabelMargin;

PROCEDURE (w: Widget) SetVerticalLabelMargin*(px: INTEGER);
BEGIN
  ASSERT((px >= -128) & (px <= 127), IndexOutOfRange);
  CSetLabelMargin(Live(w), 1, px)
END SetVerticalLabelMargin;

(* The gap in pixels between the label's image and its text, 0 to 255
   (a byte in FLTK); outside that it halts (IndexOutOfRange). *)
PROCEDURE (w: Widget) LabelImageSpacing*(): INTEGER;
BEGIN RETURN CLabelMargin(Live(w), 2)
END LabelImageSpacing;

PROCEDURE (w: Widget) SetLabelImageSpacing*(gap: INTEGER);
BEGIN
  ASSERT((gap >= 0) & (gap <= 255), IndexOutOfRange);
  CSetLabelMargin(Live(w), 2, gap)
END SetLabelImageSpacing;

PROCEDURE (w: Widget) LabelColor*(): INTEGER;
BEGIN RETURN CLabelColor(Live(w))
END LabelColor;

PROCEDURE (w: Widget) SetLabelColor*(c: INTEGER);
BEGIN CSetLabelColor(Live(w), c)
END SetLabelColor;

PROCEDURE (w: Widget) LabelType*(): INTEGER;
BEGIN RETURN CLabelType(Live(w))
END LabelType;

(* NormalLabel to EmbossedLabel. The types of a multi-label, an image or
   an icon (5 to 7) halt (Unsupported): FlImages.SetMultiLabel gives a
   widget a multi-label, which it keeps whatever type is set. *)
PROCEDURE (w: Widget) SetLabelType*(t: INTEGER);
BEGIN ASSERT((t < 5) OR (t > 7), Unsupported); CSetLabelType(Live(w), t)
END SetLabelType;

(* Where the label goes: a set of the Align constants. *)
PROCEDURE (w: Widget) Align*(): SET;
BEGIN RETURN SYSTEM.VAL(SET, CAlign(Live(w)))
END Align;

PROCEDURE (w: Widget) SetAlign*(a: SET);
BEGIN CSetAlign(Live(w), ORD(a))
END SetAlign;

(* The box drawn around w: NoBox, UpBox or another box type. Named so as
   not to read as the type Box. *)
PROCEDURE (w: Widget) BoxType*(): INTEGER;
BEGIN RETURN CBoxType(Live(w))
END BoxType;

PROCEDURE (w: Widget) SetBoxType*(b: INTEGER);
BEGIN CSetBoxType(Live(w), b)
END SetBoxType;

PROCEDURE (w: Widget) Color*(): INTEGER;
BEGIN RETURN CColor(Live(w))
END Color;

PROCEDURE (w: Widget) SetColor*(c: INTEGER);
BEGIN CSetColor(Live(w), c)
END SetColor;

PROCEDURE (w: Widget) SelectionColor*(): INTEGER;
BEGIN RETURN CSelectionColor(Live(w))
END SelectionColor;

PROCEDURE (w: Widget) SetSelectionColor*(c: INTEGER);
BEGIN CSetSelectionColor(Live(w), c)
END SetSelectionColor;

(* When FLTK calls w's Callback: a set of the When constants. *)
PROCEDURE (w: Widget) When*(): SET;
BEGIN RETURN SYSTEM.VAL(SET, CWhen(Live(w)))
END When;

PROCEDURE (w: Widget) SetWhen*(when: SET);
BEGIN CSetWhen(Live(w), ORD(when))
END SetWhen;

PROCEDURE (w: Widget) Activate*;
BEGIN CActivate(Live(w))
END Activate;

PROCEDURE (w: Widget) Deactivate*;
BEGIN CDeactivate(Live(w))
END Deactivate;

(* An output widget looks as it would, but takes no events: its group
   passes it none, though Handle still gets what is sent to it alone. *)
PROCEDURE (w: Widget) SetOutput*(on: BOOLEAN);
BEGIN IF on THEN CSetOutput(Live(w), 1) ELSE CSetOutput(Live(w), 0) END
END SetOutput;

PROCEDURE (w: Widget) Output*(): BOOLEAN;
BEGIN RETURN COutput(Live(w)) # 0
END Output;

(* TRUE unless w itself was deactivated. *)
PROCEDURE (w: Widget) Active*(): BOOLEAN;
BEGIN RETURN CActive(Live(w)) # 0
END Active;

(* TRUE if w and every group it is in are active. *)
PROCEDURE (w: Widget) ActiveR*(): BOOLEAN;
BEGIN RETURN CActiveR(Live(w)) # 0
END ActiveR;

(* TRUE if w and every group it is in are visible. *)
PROCEDURE (w: Widget) VisibleR*(): BOOLEAN;
BEGIN RETURN CVisibleR(Live(w)) # 0
END VisibleR;

(* The group w is in, or NIL: none, or one FLTK made rather than pofltk. *)
PROCEDURE (w: Widget) Parent*(): Group;
  VAR p: Widget;
BEGIN
  p := SYSTEM.VAL(Widget, CParent(Live(w)));
  IF (p # NIL) & (p IS Group) THEN RETURN p(Group) END;
  RETURN NIL
END Parent;

(* The window w is in, not w itself, or NIL: none, or one FLTK made
   rather than pofltk. *)
PROCEDURE (w: Widget) Window*(): Window;
  VAR p: Widget;
BEGIN
  p := SYSTEM.VAL(Widget, CWindow(Live(w)));
  IF (p # NIL) & (p IS Window) THEN RETURN p(Window) END;
  RETURN NIL
END Window;

PROCEDURE (w: Widget) X*(): INTEGER;
BEGIN RETURN CX(Live(w))
END X;

PROCEDURE (w: Widget) Y*(): INTEGER;
BEGIN RETURN CY(Live(w))
END Y;

PROCEDURE (w: Widget) W*(): INTEGER;
BEGIN RETURN CW(Live(w))
END W;

PROCEDURE (w: Widget) H*(): INTEGER;
BEGIN RETURN CH(Live(w))
END H;

(* Moves and sizes w: FLTK's resizing, which an extension's Resize may
   call. FLTK calls Resize whenever w moves or changes size: by Position
   or Size, or as its group is resized. *)
PROCEDURE (w: Widget) Resize*(x, y, width, height: INTEGER);
BEGIN CBaseResize(Live(w), x, y, width, height)
END Resize;

(* Each calls Resize. *)
PROCEDURE (w: Widget) Position*(x, y: INTEGER);
BEGIN CPosition(Live(w), x, y)
END Position;

PROCEDURE (w: Widget) Size*(width, height: INTEGER);
BEGIN CSize(Live(w), width, height)
END Size;

(* For an extension's Draw: FLTK's drawing of w's box, in its box type
   and color; of its label, as aligned; and of the dotted box showing it
   has the keyboard focus, if it has. *)
PROCEDURE (w: Widget) DrawBox*;
BEGIN CDrawBox(Live(w))
END DrawBox;

PROCEDURE (w: Widget) DrawLabel*;
BEGIN CDrawLabel(Live(w))
END DrawLabel;

PROCEDURE (w: Widget) DrawFocus*;
BEGIN CDrawFocus(Live(w))
END DrawFocus;

(* TRUE if the user has changed w's value: FLTK sets it before running
   the Callback for a change, and clears it when the Callback returns, or
   the program sets the value. So it tells a Callback whether it runs for
   a change. *)
PROCEDURE (w: Widget) Changed*(): BOOLEAN;
BEGIN RETURN CChanged(Live(w)) # 0
END Changed;

PROCEDURE (w: Widget) SetChanged*(c: BOOLEAN);
BEGIN
  IF c THEN CSetChanged(Live(w), 1) ELSE CSetChanged(Live(w), 0) END
END SetChanged;

(* What needs redrawing: a set of the Damage constants, {} for nothing.
   Redraw sets DamageAll. *)
PROCEDURE (w: Widget) Damage*(): SET;
BEGIN RETURN SYSTEM.VAL(SET, CDamage(Live(w)))
END Damage;

(* Adds d to what needs redrawing, and has FLTK redraw w soon. *)
PROCEDURE (w: Widget) SetDamage*(d: SET);
BEGIN CSetDamage(Live(w), ORD(d))
END SetDamage;

(* Sets what needs redrawing to {}, without redrawing: FLTK does this
   after a Draw. *)
PROCEDURE (w: Widget) ClearDamage*;
BEGIN CClearDamage(Live(w))
END ClearDamage;

(* Adds d to what needs redrawing, in the area x, y, w, h of the widget's
   window alone, which draws only there, the rest clipped, at the next
   flush. The widget and the groups up to its window get d too, the window
   DamageChild. A window not shown, or an area outside the window, is
   ignored. *)
PROCEDURE (w: Widget) DamageArea*(d: SET; x, y, ww, h: INTEGER);
BEGIN CDamageArea(Live(w), ORD(d), x, y, ww, h)
END DamageArea;

(* Gives w the keyboard focus, if it takes it: TRUE if it did. *)
PROCEDURE (w: Widget) TakeFocus*(): BOOLEAN;
BEGIN RETURN CTakeFocus(Live(w)) # 0
END TakeFocus;

(* Whether w may take the focus by the keyboard and shows it has it;
   TRUE to start with. *)
PROCEDURE (w: Widget) VisibleFocus*(): BOOLEAN;
BEGIN RETURN CVisibleFocus(Live(w)) # 0
END VisibleFocus;

PROCEDURE (w: Widget) SetVisibleFocus*(v: BOOLEAN);
BEGIN
  IF v THEN CSetVisibleFocus(Live(w), 1) ELSE CSetVisibleFocus(Live(w), 0) END
END SetVisibleFocus;

(* TRUE if the event's position is inside w. *)
PROCEDURE (w: Widget) EventInside*(): BOOLEAN;
BEGIN RETURN CWidgetEventInside(Live(w)) # 0
END EventInside;

(* Group *)

(* Widgets opened after Begin are added to g, until End. Opening a group
   or window begins it. *)
PROCEDURE (g: Group) Begin*;
BEGIN CBegin(Live(g))
END Begin;

PROCEDURE (g: Group) End*;
BEGIN CEnd(Live(g))
END End;

PROCEDURE (g: Group) Children*(): INTEGER;
BEGIN RETURN CChildren(Live(g))
END Children;

(* Adds w as g's last child, removing it from any group it was in. *)
PROCEDURE (g: Group) Add*(w: Widget);
BEGIN CAdd(Live(g), Live(w))
END Add;

(* Adds w before child i, or last if i is Children() or more. *)
PROCEDURE (g: Group) Insert*(w: Widget; i: INTEGER);
BEGIN CInsert(Live(g), Live(w), i)
END Insert;

(* Takes w out of g without deleting it; nothing if it isn't g's. *)
PROCEDURE (g: Group) Remove*(w: Widget);
BEGIN CRemove(Live(g), Live(w))
END Remove;

(* w's index among g's children, or -1 if it isn't one. *)
PROCEDURE (g: Group) Find*(w: Widget): INTEGER;
  VAR h: SYSTEM.ADDRESS; i: INTEGER;
BEGIN
  h := Live(g); i := CFind(h, Live(w));
  IF i = CChildren(h) THEN i := -1 END;
  RETURN i
END Find;

(* Deletes every child pofltk opened, as Delete does each; children FLTK
   made itself, such as a scroll's scrollbars, stay. *)
PROCEDURE (g: Group) Clear*;
BEGIN CClear(Live(g))
END Clear;

(* Makes g forget the sizes it saved of itself and its children, after
   the program moves or resizes them: else the next resize of g puts them
   back where they were. *)
PROCEDURE (g: Group) InitSizes*;
BEGIN CInitSizes(Live(g))
END InitSizes;

(* The child, or g itself, that grows and shrinks when g is resized; NIL
   for none, so nothing does. *)
PROCEDURE (g: Group) SetResizable*(w: Widget);
BEGIN
  IF w = NIL THEN CSetResizable(Live(g), 0) ELSE CSetResizable(Live(g), Live(w)) END
END SetResizable;

PROCEDURE (g: Group) Resizable*(): Widget;
BEGIN RETURN SYSTEM.VAL(Widget, CResizable(Live(g)))
END Resizable;

(* Child i, from 0, or NIL if FLTK made it rather than pofltk. *)
PROCEDURE (g: Group) Child*(i: INTEGER): Widget;
  VAR h: SYSTEM.ADDRESS;
BEGIN
  h := Live(g); ASSERT((i >= 0) & (i < CChildren(h)), IndexOutOfRange);
  RETURN SYSTEM.VAL(Widget, CChild(h, i))
END Child;

(* For an extension's Draw: draws w, which must be one of g's children,
   with all of it damaged, as a group draws a child; so Draw can put it
   over what it drew itself. Halts with NotAChild otherwise. *)
PROCEDURE (g: Group) DrawChild*(w: Widget);
BEGIN ASSERT(g.Find(w) >= 0, NotAChild); CDrawChild(g.h, w.h)
END DrawChild;

(* For an extension's Draw: draws g's children as FLTK's own Draw of a
   group does, after its box: each child by its damage (all of it if g's
   damage is DamageAll), and the labels outside them. So Draw can draw
   its own background in place of the box. *)
PROCEDURE (g: Group) DrawChildren*;
BEGIN CDrawChildren(Live(g))
END DrawChildren;

(* Window *)

(* Shows w, as Show does, with FLTK's command-line options (ParseArgs,
   which this calls first if no ParseArgs or Arg has): its title, its
   class name, and, for the first window shown this way, its geometry;
   and the colors and scheme. A title or class not given is the
   program's name. *)
(* Draws a window's overlay, as Draw draws a widget. It is here, not on
   OverlayWindow, so that any window class with an overlay shares it;
   other windows never call it. *)
PROCEDURE (w: Window) DrawOverlay*;
END DrawOverlay;

(* Marks the overlay to be drawn again. It stays clear until this is first
   called, so call it after Show for an overlay to start with. *)
PROCEDURE (w: OverlayWindow) RedrawOverlay*;
BEGIN COverlayRedraw(Live(w))
END RedrawOverlay;

(* Whether the display has a real overlay. Without one, as on X11 and
   Wayland, FLTK redraws the window from its back buffer, and overlays
   work the same, a little slower. *)
PROCEDURE (w: OverlayWindow) CanDoOverlay*(): BOOLEAN;
BEGIN RETURN COverlayCanDo(Live(w)) # 0
END CanDoOverlay;

(* Shows w as FLTK's show(argc, argv) does: with the options on the
   program's command line (Args), and the system's colours
   (Fl::get_system_colors). Those set the background, and so FLTK's
   grey ramp, which even at the default background moves Dark3 and Dark1
   from FLTK's built-in ramp (doc/fltk-issues.md, 154). A port of
   an FLTK program that calls show(argc, argv) calls this. *)
PROCEDURE (w: Window) ShowArgs*;
BEGIN CWindowShowArgs(Live(w), Args.argc, Args.argv)
END ShowArgs;

(* With no action, FLTK's default: hide the window (Fl::atclose). *)
PROCEDURE (w: Window) Callback*;
BEGIN
  IF w.action # NIL THEN w.action(w) ELSE CWindowDefaultCallback(Live(w)) END
END Callback;

(* TRUE once the window is on the screen: shown, and not since hidden. *)
PROCEDURE (w: Window) Shown*(): BOOLEAN;
BEGIN RETURN CShown(Live(w)) # 0
END Shown;

(* Sends drawing to w, outside a Draw, for FlDraw's OverlayRect and Scroll.
   What is drawn lasts until FLTK next draws w. A window not shown halts
   with OutOfOrder; under Wayland, use WaitForExpose first. *)
PROCEDURE (w: Window) MakeCurrent*;
BEGIN ASSERT(CMakeCurrent(Live(w)) # 0, OutOfOrder)
END MakeCurrent;

(* Waits until a window just shown is on the screen, handling events
   meanwhile; returns at once if it is there, or not shown. Under Wayland
   a menu popped up over a window not yet on the screen kills the program
   (doc/fltk-issues.md, 28), so MenuButton.Popup waits first. *)
PROCEDURE (w: Window) WaitForExpose*;
BEGIN CWaitForExpose(Live(w))
END WaitForExpose;

(* The sizes the user may give the window; 0 for a maximum is no limit. *)
PROCEDURE (w: Window) SizeRange*(minw, minh, maxw, maxh: INTEGER);
BEGIN CSizeRange(Live(w), minw, minh, maxw, maxh, 0, 0, 0)
END SizeRange;

(* SizeRange, with the user's sizes in steps of dw by dh from the minimum
   (0 for any size), and with aspect the window keeping its minimum's
   shape. The window system may ignore the steps and the shape. *)
PROCEDURE (w: Window) SizeRangeStep*(minw, minh, maxw, maxh, dw, dh: INTEGER; aspect: BOOLEAN);
  VAR a: SYSTEM.INT32;
BEGIN
  IF aspect THEN a := 1 ELSE a := 0 END;
  CSizeRange(Live(w), minw, minh, maxw, maxh, dw, dh, a)
END SizeRangeStep;

(* The size range SizeRange or SizeRangeStep gave the window. FALSE if
   none was given: FLTK then decides one as the window is shown, from its
   resizable widget, and the values are its last. *)
PROCEDURE (w: Window) GetSizeRange*(VAR minw, minh, maxw, maxh, dw, dh: INTEGER; VAR aspect: BOOLEAN): BOOLEAN;
  VAR a0, a1, a2, a3, a4, a5, a6: SYSTEM.INT32; set: BOOLEAN;
BEGIN
  set := CGetSizeRange(Live(w), a0, a1, a2, a3, a4, a5, a6) # 0;
  minw := a0; minh := a1; maxw := a2; maxh := a3; dw := a4; dh := a5;
  aspect := a6 # 0;
  RETURN set
END GetSizeRange;

(* A modal window takes every event while it is shown. *)
PROCEDURE (w: Window) SetModal*;
BEGIN CSetModal(Live(w))
END SetModal;

(* A non-modal window stays above the others, without taking their
   events. *)
PROCEDURE (w: Window) SetNonModal*;
BEGIN CSetNonModal(Live(w))
END SetNonModal;

(* Moves the window so that its point x, y is under the mouse, kept on the
   screen with its borders unless offscreen. *)
PROCEDURE (w: Window) HotspotAt*(x, y: INTEGER; offscreen: BOOLEAN);
  VAR off: SYSTEM.INT32;
BEGIN
  IF offscreen THEN off := 1 ELSE off := 0 END;
  CHotspotAt(Live(w), x, y, off)
END HotspotAt;

(* The same, with the middle of o, the window or a widget in it, under the
   mouse. *)
PROCEDURE (w: Window) Hotspot*(o: Widget; offscreen: BOOLEAN);
  VAR off: SYSTEM.INT32;
BEGIN
  IF offscreen THEN off := 1 ELSE off := 0 END;
  CHotspot(Live(w), Live(o), off)
END Hotspot;

PROCEDURE (w: Window) Modal*(): BOOLEAN;
BEGIN RETURN CModal(Live(w)) # 0
END Modal;

(* Fills the screen with the window, unless the window can't be resized:
   one with neither a resizable widget nor a size range. Showing such a
   window fixes its size range for good, so a resizable widget set later
   doesn't help; SizeRange does (doc/fltk-issues.md, 149). *)
PROCEDURE (w: Window) Fullscreen*;
BEGIN CFullscreen(Live(w))
END Fullscreen;

PROCEDURE (w: Window) FullscreenOff*;
BEGIN CFullscreenOff(Live(w))
END FullscreenOff;

(* The screens a full screen window spans: the ones whose top, bottom,
   left and right edges it takes, numbered as Fl.ScreenXYWH numbers them;
   any negative is the window's own screen, as to start with. Wayland
   ignores them. *)
PROCEDURE (w: Window) FullscreenScreens*(top, bottom, left, right: INTEGER);
BEGIN CFullscreenScreens(Live(w), top, bottom, left, right)
END FullscreenScreens;

(* Minimizes the window, or shows it minimized if it isn't shown. *)
PROCEDURE (w: Window) Iconize*;
BEGIN CIconize(Live(w))
END Iconize;

(* Lets the window manager place the window when it is next shown,
   undoing the position an OpenWindowAt, a Resize or a show gave it. *)
PROCEDURE (w: Window) FreePosition*;
BEGIN CFreePosition(Live(w))
END FreePosition;

PROCEDURE (w: Window) FullscreenActive*(): BOOLEAN;
BEGIN RETURN CFullscreenActive(Live(w)) # 0
END FullscreenActive;

(* Fills the screen's work area with the window, and UnMaximize gives it
   back its size. Each does nothing unless the window is shown, at the top
   level, resizable and not full screen. With no window manager FLTK
   resizes the window itself; with one, the manager does, later. *)
PROCEDURE (w: Window) Maximize*;
BEGIN CMaximize(Live(w))
END Maximize;

PROCEDURE (w: Window) UnMaximize*;
BEGIN CUnMaximize(Live(w))
END UnMaximize;

(* Whether the window is maximized: from Maximize until UnMaximize, or as
   the window manager says. *)
PROCEDURE (w: Window) MaximizeActive*(): BOOLEAN;
BEGIN RETURN CMaximizeActive(Live(w)) # 0
END MaximizeActive;

(* Whether the window manager puts its border, title and controls around
   the window, as to start with; a window shown changes at once. *)
PROCEDURE (w: Window) SetBorder*(on: BOOLEAN);
BEGIN
  IF on THEN CSetBorder(Live(w), 1) ELSE CSetBorder(Live(w), 0) END
END SetBorder;

PROCEDURE (w: Window) Border*(): BOOLEAN;
BEGIN RETURN CBorder(Live(w)) # 0
END Border;

(* The screen the window is on, from 0 to ScreenCount() - 1: a
   subwindow's is its top window's. 0 for a window never shown, unless
   set. *)
PROCEDURE (w: Window) ScreenNum*(): INTEGER;
BEGIN RETURN CWindowScreenNum(Live(w))
END ScreenNum;

(* The screen to show the window on, from 0 to ScreenCount() - 1, or it
   halts (IndexOutOfRange). Set it, and the window's place on that
   screen, before Show: a window shown keeps its screen. *)
PROCEDURE (w: Window) SetScreenNum*(n: INTEGER);
BEGIN
  ASSERT((n >= 0) & (n < CScreenCount()), IndexOutOfRange);
  CWindowSetScreenNum(Live(w), n)
END SetScreenNum;

(* The name a window system groups the window by, as FLTK's xclass. FLTK
   makes the first one set the default for every window. *)
PROCEDURE (w: Window) SetXClass*(name-: ARRAY OF CHAR);
BEGIN CSetXClass(Live(w), name)
END SetXClass;

PROCEDURE (w: Window) XClass*(VAR name: ARRAY OF CHAR);
BEGIN FromC(CXClass(Live(w)), name)
END XClass;

(* The mouse pointer's shape over the window: CursorDefault, or another
   cursor constant. *)
PROCEDURE (w: Window) SetCursor*(c: INTEGER);
BEGIN CCursor(Live(w), c)
END SetCursor;

(* The window's size with its frame and title bar, as the window system
   says; its own, if not shown. *)
PROCEDURE (w: Window) DecoratedW*(): INTEGER;
BEGIN RETURN CDecoratedW(Live(w))
END DecoratedW;

PROCEDURE (w: Window) DecoratedH*(): INTEGER;
BEGIN RETURN CDecoratedH(Live(w))
END DecoratedH;

(* Colors. A color is an index into FLTK's colormap (the color constants,
   GrayRamp, ColorCube), or an RGB color, which is never one. *)

(* The color r, g, b, each 0 to 255. *)
PROCEDURE RGB*(r, g, b: INTEGER): INTEGER;
BEGIN
  (* r, g, b and 0 in bytes 3..0: an Fl_Color's bits, as an INTEGER *)
  RETURN SYSTEM.VAL(INTEGER, LONG((r * 256 + g) * 256 + b) * 256)
END RGB;

(* Gray i of FLTK's ramp from black, 0, to white, NumGray - 1. *)
PROCEDURE GrayRamp*(i: INTEGER): INTEGER;
BEGIN RETURN i + grayRamp
END GrayRamp;

(* The colormap's color r, g, b, from 0 to NumRed - 1, NumGreen - 1 and
   NumBlue - 1. *)
PROCEDURE ColorCube*(r, g, b: INTEGER): INTEGER;
BEGIN RETURN (b * NumRed + r) * NumGreen + g + colorCube
END ColorCube;

(* Sets colormap entry i to c, an RGB color. *)
PROCEDURE SetIndexColor*(i, c: INTEGER);
BEGIN CSetIndexColor(i, c)
END SetIndexColor;

(* The red, green and blue of c, each 0 to 255. *)
PROCEDURE GetRGB*(c: INTEGER; VAR r, g, b: INTEGER);
  VAR cr, cg, cb: SYSTEM.INT32;
BEGIN CGetRGB(c, cr, cg, cb); r := cr; g := cg; b := cb
END GetRGB;

(* The colors of FLTK's scheme: the background of most widgets, of text
   and list widgets, and the color of labels and text. *)
PROCEDURE SetBackground*(r, g, b: INTEGER);
BEGIN CBackground(r, g, b)
END SetBackground;

PROCEDURE SetBackground2*(r, g, b: INTEGER);
BEGIN CBackground2(r, g, b)
END SetBackground2;

PROCEDURE SetForeground*(r, g, b: INTEGER);
BEGIN CForeground(r, g, b)
END SetForeground;

(* c1 * weight + c2 * (1 - weight), weight from 0 to 1. *)
PROCEDURE ColorAverage*(c1, c2: INTEGER; weight: LONGREAL): INTEGER;
BEGIN RETURN CColorAverage(c1, c2, weight)
END ColorAverage;

PROCEDURE Lighter*(c: INTEGER): INTEGER;
BEGIN RETURN CColorAverage(c, White, 0.67D0)
END Lighter;

PROCEDURE Darker*(c: INTEGER): INTEGER;
BEGIN RETURN CColorAverage(c, Black, 0.67D0)
END Darker;

(* fg, or black or white if fg wouldn't show against bg. *)
PROCEDURE Contrast*(fg, bg: INTEGER): INTEGER;
BEGIN RETURN CContrast(fg, bg)
END Contrast;

(* c as FLTK draws it on an inactive widget. *)
PROCEDURE Inactive*(c: INTEGER): INTEGER;
BEGIN RETURN CInactive(c)
END Inactive;

(* The label size of widgets opened from now on, 14 to start with. *)
PROCEDURE NormalSize*(): INTEGER;
BEGIN RETURN CNormalSize()
END NormalSize;

PROCEDURE SetNormalSize*(s: INTEGER);
BEGIN CSetNormalSize(s)
END SetNormalSize;

(* The border of box type b, as drawn: how far inside a box's left and
   top edges what it holds starts (BoxDX, BoxDY), and how much narrower
   and shorter it is (BoxDW, BoxDH). b is from 0 to 255. *)
PROCEDURE BoxD(b, what: INTEGER): INTEGER;
BEGIN ASSERT((b >= 0) & (b <= 255), IndexOutOfRange); RETURN CBoxD(b, what)
END BoxD;

PROCEDURE BoxDX*(b: INTEGER): INTEGER;
BEGIN RETURN BoxD(b, 0)
END BoxDX;

PROCEDURE BoxDY*(b: INTEGER): INTEGER;
BEGIN RETURN BoxD(b, 1)
END BoxDY;

PROCEDURE BoxDW*(b: INTEGER): INTEGER;
BEGIN RETURN BoxD(b, 2)
END BoxDW;

PROCEDURE BoxDH*(b: INTEGER): INTEGER;
BEGIN RETURN BoxD(b, 3)
END BoxDH;

(* Rectangles *)

PROCEDURE (VAR r: Rect) Set*(x, y, w, h: INTEGER);
BEGIN r.x := x; r.y := y; r.w := w; r.h := h
END Set;

(* w's place and size. *)
PROCEDURE (VAR r: Rect) SetFrom*(w: Widget);
BEGIN r.Set(w.X(), w.Y(), w.W(), w.H())
END SetFrom;

PROCEDURE (VAR r: Rect) Right*(): INTEGER;
BEGIN RETURN r.x + r.w
END Right;

PROCEDURE (VAR r: Rect) Bottom*(): INTEGER;
BEGIN RETURN r.y + r.h
END Bottom;

(* Moves the right or bottom edge alone, so the width or height changes. *)
PROCEDURE (VAR r: Rect) SetRight*(right: INTEGER);
BEGIN r.w := right - r.x
END SetRight;

PROCEDURE (VAR r: Rect) SetBottom*(bottom: INTEGER);
BEGIN r.h := bottom - r.y
END SetBottom;

(* Shrinks r by each amount on its side, or enlarges it for a negative
   amount, with no check that anything is left. *)
PROCEDURE (VAR r: Rect) InsetSides*(left, top, right, bottom: INTEGER);
BEGIN
  INC(r.x, left); INC(r.y, top);
  DEC(r.w, left + right); DEC(r.h, top + bottom)
END InsetSides;

PROCEDURE (VAR r: Rect) Inset*(d: INTEGER);
BEGIN r.InsetSides(d, d, d, d)
END Inset;

(* Shrinks r by the frame of box type b, to what b's box has inside. *)
PROCEDURE (VAR r: Rect) InsetBox*(b: INTEGER);
BEGIN
  INC(r.x, BoxDX(b)); INC(r.y, BoxDY(b));
  DEC(r.w, BoxDW(b)); DEC(r.h, BoxDH(b))
END InsetBox;

PROCEDURE (VAR r: Rect) Equal*(other-: Rect): BOOLEAN;
BEGIN
  RETURN (r.x = other.x) & (r.y = other.y) & (r.w = other.w) & (r.h = other.h)
END Equal;

(* TRUE if this FLTK has feature: Svg, Wayland or X11, for a
   program that must run on any FLTK. Wayland and X11 open the display. *)
PROCEDURE Has*(feature: INTEGER): BOOLEAN;
BEGIN RETURN CHas(feature) # 0
END Has;

(* FLTK's look: "none" (or "base"), "plastic", "gtk+", "gleam" or "oxy".
   TRUE if the look is now a scheme. FALSE for "none", "base" or "", and
   for a name FLTK doesn't know, which also leaves the look "none". *)
PROCEDURE SetScheme*(name-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CSetScheme(name) # 0
END SetScheme;

(* Sets the system's scheme, as SetScheme does: the environment
   variable FLTK_SCHEME, or on X11 without it the X resource "scheme" of
   the first window's class (or "fltk"), which opens the display. Every
   SetScheme sets FLTK_SCHEME, so after one this is the scheme it set. *)
PROCEDURE SetSystemScheme*(): BOOLEAN;
BEGIN RETURN CSetSystemScheme() # 0
END SetSystemScheme;

(* The scheme's name, "" for none. *)
PROCEDURE GetScheme*(VAR name: ARRAY OF CHAR);
BEGIN FromC(CScheme(), name)
END GetScheme;

(* How many schemes FLTK knows, and each one's name, from 0: "base",
   "plastic", "gtk+", "gleam", "oxy", then any added. *)
PROCEDURE SchemeCount*(): INTEGER;
BEGIN RETURN CSchemeCount()
END SchemeCount;

PROCEDURE SchemeName*(i: INTEGER; VAR name: ARRAY OF CHAR);
BEGIN
  ASSERT((i >= 0) & (i < CSchemeCount()), IndexOutOfRange);
  FromC(CSchemeName(i), name)
END SchemeName;

(* Adds name, copied, for a program that defines its own look. FALSE if
   FLTK has it already, or won't take it: it must be 12 characters at
   most, of lower-case letters, digits, "$", "+", "_" and ".". *)
PROCEDURE AddSchemeName*(name-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CAddSchemeName(name) > 0
END AddSchemeName;

(* Tooltips, all of them. Delays are in seconds. *)

(* Before a tooltip shows, and how long it stays. *)
PROCEDURE TooltipDelay*(): LONGREAL;
BEGIN RETURN CTooltipDelay(0)
END TooltipDelay;

PROCEDURE SetTooltipDelay*(d: LONGREAL);
BEGIN CTooltipSetDelay(0, d)
END SetTooltipDelay;

PROCEDURE TooltipHideDelay*(): LONGREAL;
BEGIN RETURN CTooltipDelay(1)
END TooltipHideDelay;

PROCEDURE SetTooltipHideDelay*(d: LONGREAL);
BEGIN CTooltipSetDelay(1, d)
END SetTooltipHideDelay;

(* Before the next tooltip shows, soon after one has: it is usually
   shorter. *)
PROCEDURE TooltipHoverDelay*(): LONGREAL;
BEGIN RETURN CTooltipDelay(2)
END TooltipHoverDelay;

PROCEDURE SetTooltipHoverDelay*(d: LONGREAL);
BEGIN CTooltipSetDelay(2, d)
END SetTooltipHoverDelay;

PROCEDURE TooltipFont*(): INTEGER;
BEGIN RETURN CTooltipSetting(0)
END TooltipFont;

PROCEDURE SetTooltipFont*(f: INTEGER);
BEGIN CTooltipSetSetting(0, f)
END SetTooltipFont;

PROCEDURE TooltipSize*(): INTEGER;
BEGIN RETURN CTooltipSetting(1)
END TooltipSize;

PROCEDURE SetTooltipSize*(s: INTEGER);
BEGIN CTooltipSetSetting(1, s)
END SetTooltipSize;

PROCEDURE TooltipColor*(): INTEGER;
BEGIN RETURN CTooltipSetting(2)
END TooltipColor;

PROCEDURE SetTooltipColor*(c: INTEGER);
BEGIN CTooltipSetSetting(2, c)
END SetTooltipColor;

PROCEDURE TooltipTextColor*(): INTEGER;
BEGIN RETURN CTooltipSetting(3)
END TooltipTextColor;

PROCEDURE SetTooltipTextColor*(c: INTEGER);
BEGIN CTooltipSetSetting(3, c)
END SetTooltipTextColor;

(* The space around the text. *)
PROCEDURE TooltipMarginWidth*(): INTEGER;
BEGIN RETURN CTooltipSetting(4)
END TooltipMarginWidth;

PROCEDURE SetTooltipMarginWidth*(n: INTEGER);
BEGIN CTooltipSetSetting(4, n)
END SetTooltipMarginWidth;

PROCEDURE TooltipMarginHeight*(): INTEGER;
BEGIN RETURN CTooltipSetting(5)
END TooltipMarginHeight;

PROCEDURE SetTooltipMarginHeight*(n: INTEGER);
BEGIN CTooltipSetSetting(5, n)
END SetTooltipMarginHeight;

(* The widest a tooltip's text gets before it wraps. *)
PROCEDURE TooltipWrapWidth*(): INTEGER;
BEGIN RETURN CTooltipSetting(6)
END TooltipWrapWidth;

PROCEDURE SetTooltipWrapWidth*(n: INTEGER);
BEGIN CTooltipSetSetting(6, n)
END SetTooltipWrapWidth;

PROCEDURE TooltipsEnabled*(): BOOLEAN;
BEGIN RETURN CTooltipSetting(7) # 0
END TooltipsEnabled;

PROCEDURE EnableTooltips*(on: BOOLEAN);
BEGIN IF on THEN CTooltipSetSetting(7, 1) ELSE CTooltipSetSetting(7, 0) END
END EnableTooltips;

(* The widget whose tooltip is showing or about to, or NIL; NIL too if
   FLTK made the widget. *)
PROCEDURE TooltipCurrent*(): Widget;
BEGIN RETURN SYSTEM.VAL(Widget, CTooltipCurrent())
END TooltipCurrent;

(* Sets it, with no tooltip shown, so a tooltip for another widget waits
   its delay. w may be NIL. A w with no tooltip, nor any group around it,
   leaves none current. *)
PROCEDURE SetTooltipCurrent*(w: Widget);
BEGIN
  IF w = NIL THEN CTooltipSetCurrent(0) ELSE CTooltipSetCurrent(Live(w)) END
END SetTooltipCurrent;

(* For a Handle that gives parts of a widget tooltips of their own: when
   the mouse enters the area x, y, width, height of w, in w's window's
   coordinates, shows text there as w's tooltip. text is copied. "" ends
   it, and the last one should, when the mouse leaves. *)
PROCEDURE EnterArea*(w: Widget; x, y, width, height: INTEGER; text-: ARRAY OF CHAR);
BEGIN CEnterArea(Live(w), x, y, width, height, text)
END EnterArea;

(* Trackers *)

(* t watches w, which must be open. *)
PROCEDURE (t: Tracker) Track*(w: Widget);
BEGIN
  ASSERT(w # NIL, NilArgument); ASSERT(w.state = open, NotOpen);
  t.w := w
END Track;

(* FLTK's tracker clears when ~Fl_Widget runs, and so does this: a widget
   Delete has queued, inside a callback, exists until events are next
   handled, which may be in that callback. *)
PROCEDURE (t: Tracker) Exists*(): BOOLEAN;
BEGIN
  IF (t.w # NIL) & ~t.w.IsOpen() THEN t.w := NIL END;
  RETURN t.w # NIL
END Exists;

PROCEDURE (t: Tracker) Deleted*(): BOOLEAN;
BEGIN RETURN ~t.Exists()
END Deleted;

(* The widget, or NIL if it was deleted or none is tracked. *)
PROCEDURE (t: Tracker) Widget*(): Widget;
VAR w: Widget;
BEGIN
  IF t.Exists() THEN w := t.w ELSE w := NIL END;
  RETURN w
END Widget;

(* Events. While a widget's Handle runs, these say what the event was:
   where, which key or button, what text. A position is in the window's
   coordinates, as a widget's X and Y are, unless it is Root. *)

(* The event being handled: EvPush, or another event constant. *)
PROCEDURE Event*(): INTEGER;
BEGIN RETURN CEvent()
END Event;

PROCEDURE EventX*(): INTEGER;
BEGIN RETURN CEventX()
END EventX;

PROCEDURE EventY*(): INTEGER;
BEGIN RETURN CEventY()
END EventY;

(* The position on the screen. *)
PROCEDURE EventXRoot*(): INTEGER;
BEGIN RETURN CEventXRoot()
END EventXRoot;

PROCEDURE EventYRoot*(): INTEGER;
BEGIN RETURN CEventYRoot()
END EventYRoot;

(* How far an EvMouseWheel turned: across, and down (positive) or up. *)
PROCEDURE EventDx*(): INTEGER;
BEGIN RETURN CEventDx()
END EventDx;

PROCEDURE EventDy*(): INTEGER;
BEGIN RETURN CEventDy()
END EventDy;

(* The button of an EvPush or EvRelease: LeftMouse, MiddleMouse, ... *)
PROCEDURE EventButton*(): INTEGER;
BEGIN RETURN CEventButton()
END EventButton;

(* For an EvPush: 0 for a single click, 1 for a double, and so on. *)
PROCEDURE EventClicks*(): INTEGER;
BEGIN RETURN CEventClicks()
END EventClicks;

(* Sets EventClicks: 0 makes the next click a single one. *)
PROCEDURE SetEventClicks*(n: INTEGER);
BEGIN CSetEventClicks(n)
END SetEventClicks;

(* TRUE if the mouse hasn't moved far, or for long, since the EvPush, so
   that it is still a click. *)
PROCEDURE EventIsClick*(): BOOLEAN;
BEGIN RETURN CEventIsClick() # 0
END EventIsClick;

(* Makes EventIsClick FALSE until the next EvPush. *)
PROCEDURE EventIsClickOff*;
BEGIN CEventIsClickOff
END EventIsClickOff;

(* The key of an EvKeyDown or EvKeyUp: a character's code, unshifted
   ("a" for "A"), or a Key constant; for a mouse button, KeyButton plus
   the button. *)
PROCEDURE EventKey*(): INTEGER;
BEGIN RETURN CEventKey()
END EventKey;

(* EventKey, before FLTK's keypad translation (NumLock off). *)
PROCEDURE EventOriginalKey*(): INTEGER;
BEGIN RETURN CEventOriginalKey()
END EventOriginalKey;

(* TRUE if key was held down when the event happened. *)
PROCEDURE EventKeyDown*(key: INTEGER): BOOLEAN;
BEGIN RETURN CEventKeyDown(key) # 0
END EventKeyDown;

(* TRUE if key is held down now, whatever the event. (FLTK's name: KeyDown
   is the down arrow.) *)
PROCEDURE GetKey*(key: INTEGER): BOOLEAN;
BEGIN RETURN CGetKey(key) # 0
END GetKey;

(* The shift keys and buttons held during the event: a set of Shift,
   Ctrl, Button1 and the other state constants. *)
PROCEDURE EventState*(): SET;
BEGIN RETURN SYSTEM.VAL(SET, CEventState())
END EventState;

(* The text of an EvKeyDown (what the key types, UTF-8) or an EvPaste,
   truncated to fit text; "" for none. *)
PROCEDURE EventText*(VAR text: ARRAY OF CHAR);
BEGIN FromC(CEventText(), text)
END EventText;

(* The length of EventText's text, in bytes, untruncated. *)
PROCEDURE EventLength*(): INTEGER;
BEGIN RETURN CEventLength()
END EventLength;

(* The clipboard, and drag and drop *)

(* Puts text, up to its 0X, in the selection buffer, the clipboard, or
   both (Selection, Clipboard, Both). Under Wayland, which has no
   selection buffer, Both is the clipboard alone (doc/fltk-issues.md,
   50). *)
PROCEDURE Copy*(text-: ARRAY OF CHAR; destination: INTEGER);
  VAR n: INTEGER;
BEGIN
  ASSERT((destination >= Selection) & (destination <= Both), IndexOutOfRange);
  n := 0; WHILE (n < LEN(text)) & (text[n] # 0X) DO INC(n) END;
  CCopy(text, n, destination)
END Copy;

(* Asks for the text in source, Selection or Clipboard, to be sent to
   receiver as an EvPaste, its text in EventText: at once, if the program
   copied it itself, else later, as the window system delivers it, or
   never. Under Wayland only the clipboard can be pasted from; under X11
   another program's text needs a window shown. *)
PROCEDURE Paste*(receiver: Widget; source: INTEGER);
BEGIN
  ASSERT((source = Selection) OR (source = Clipboard), IndexOutOfRange);
  CPaste(Live(receiver), source, 0)
END Paste;

(* The same for an image on the clipboard: the receiver's Handle takes it
   with FlImages.TakePastedImage. *)
PROCEDURE PasteImage*(receiver: Widget);
BEGIN CPaste(Live(receiver), Clipboard, 1)
END PasteImage;

(* Whether the clipboard holds text, or an image. *)
PROCEDURE ClipboardHasText*(): BOOLEAN;
BEGIN RETURN CClipboardContains(0) # 0
END ClipboardHasText;

PROCEDURE ClipboardHasImage*(): BOOLEAN;
BEGIN RETURN CClipboardContains(1) # 0
END ClipboardHasImage;

(* In an EvPaste, TRUE if it carries an image, not text. *)
PROCEDURE EventIsImage*(): BOOLEAN;
BEGIN RETURN CEventIsImage() # 0
END EventIsImage;

(* Starts dragging the text last copied to the selection buffer, from a
   Handle's EvPush or EvDrag. A widget it is dragged over gets EvDndEnter,
   EvDndDrag and EvDndLeave, and if it returned TRUE for them,
   EvDndRelease and then the text as an EvPaste where it is dropped. On
   X11 Dnd returns when the text is dropped; under Wayland at once, the
   compositor doing the dragging. *)
PROCEDURE Dnd*;
VAR r: INTEGER;
BEGIN r := CDnd()
END Dnd;

(* Whether text widgets let the user drag text out of them and drop it in;
   TRUE to start with. *)
PROCEDURE DndTextOps*(): BOOLEAN;
BEGIN RETURN CDndTextOps(0) # 0
END DndTextOps;

PROCEDURE SetDndTextOps*(on: BOOLEAN);
VAR r: INTEGER;
BEGIN IF on THEN r := CDndTextOps(2) ELSE r := CDndTextOps(1) END
END SetDndTextOps;

(* FLTK's options, OptionArrowFocus and the rest: the user's and the
   system's (set with FLTK's fltk-options), unless SetOption overrides
   one for the rest of the run. *)
PROCEDURE Option*(o: INTEGER): BOOLEAN;
BEGIN
  ASSERT((o >= OptionArrowFocus) & (o <= OptionSimpleZoomShortcut), IndexOutOfRange);
  RETURN COption(o, 0) # 0
END Option;

PROCEDURE SetOption*(o: INTEGER; on: BOOLEAN);
  VAR r: INTEGER;
BEGIN
  ASSERT((o >= OptionArrowFocus) & (o <= OptionSimpleZoomShortcut), IndexOutOfRange);
  IF on THEN r := COption(o, 2) ELSE r := COption(o, 1) END
END SetOption;

(* TRUE if the event's position is inside the rectangle x, y, w, h. *)
PROCEDURE EventInside*(x, y, w, h: INTEGER): BOOLEAN;
BEGIN RETURN CEventInside(x, y, w, h) # 0
END EventInside;

(* The widget with the keyboard focus, or NIL: none, or one FLTK made. *)
PROCEDURE Focus*(): Widget;
BEGIN RETURN SYSTEM.VAL(Widget, CFocus())
END Focus;

(* Gives w the focus without asking it, as TakeFocus does; NIL for none. *)
PROCEDURE SetFocus*(w: Widget);
BEGIN
  IF w = NIL THEN CSetFocus(0) ELSE CSetFocus(Live(w)) END
END SetFocus;

(* The widget under the mouse, which gets EvMove and EvMouseWheel, and the
   one that took the last EvPush, which gets EvDrag and EvRelease; NIL
   for none, or one FLTK made. *)
PROCEDURE BelowMouse*(): Widget;
BEGIN RETURN SYSTEM.VAL(Widget, CBelowmouse())
END BelowMouse;

PROCEDURE Pushed*(): Widget;
BEGIN RETURN SYSTEM.VAL(Widget, CPushed())
END Pushed;

(* Whether any widget has the focus, is below the mouse, or took the push,
   the program's or one FLTK made, such as a value input's field, for
   which Focus, BelowMouse and Pushed give NIL (doc/fltk-issues.md, 171). *)
PROCEDURE HasFocus*(): BOOLEAN;
BEGIN RETURN CAny(0) # 0
END HasFocus;

PROCEDURE HasBelowMouse*(): BOOLEAN;
BEGIN RETURN CAny(1) # 0
END HasBelowMouse;

PROCEDURE HasPushed*(): BOOLEAN;
BEGIN RETURN CAny(2) # 0
END HasPushed;

(* Screens, numbered from 0 *)

(* The work area of the main screen, screen 0: the screen less what the
   desktop keeps, such as panels. *)
PROCEDURE ScreenX*(): INTEGER;
BEGIN RETURN CScreen(0)
END ScreenX;

PROCEDURE ScreenY*(): INTEGER;
BEGIN RETURN CScreen(1)
END ScreenY;

PROCEDURE ScreenW*(): INTEGER;
BEGIN RETURN CScreen(2)
END ScreenW;

PROCEDURE ScreenH*(): INTEGER;
BEGIN RETURN CScreen(3)
END ScreenH;

PROCEDURE ScreenCount*(): INTEGER;
BEGIN RETURN CScreenCount()
END ScreenCount;

(* Screen n's place and size, from 0 to ScreenCount() - 1. *)
PROCEDURE ScreenXYWH*(n: INTEGER; VAR x, y, w, h: INTEGER);
  VAR cx, cy, cw, ch: SYSTEM.INT32;
BEGIN
  ASSERT((n >= 0) & (n < CScreenCount()), IndexOutOfRange);
  CScreenXYWH(n, 0, cx, cy, cw, ch); x := cx; y := cy; w := cw; h := ch
END ScreenXYWH;

(* Screen n's work area. *)
PROCEDURE ScreenWorkArea*(n: INTEGER; VAR x, y, w, h: INTEGER);
  VAR cx, cy, cw, ch: SYSTEM.INT32;
BEGIN
  ASSERT((n >= 0) & (n < CScreenCount()), IndexOutOfRange);
  CScreenXYWH(n, 1, cx, cy, cw, ch); x := cx; y := cy; w := cw; h := ch
END ScreenWorkArea;

(* The width of scrollbars: of every widget's whose own is 0, as it is
   unless set (Browser, Table, Tree and the rest have SetScrollbarSize).
   FLTK's is 16. *)
PROCEDURE ScrollbarSize*(): INTEGER;
BEGIN RETURN CScrollbarSize()
END ScrollbarSize;

(* From 1 up, or it halts (IndexOutOfRange). *)
PROCEDURE SetScrollbarSize*(n: INTEGER);
BEGIN ASSERT(n >= 1, IndexOutOfRange); CSetScrollbarSize(n)
END SetScrollbarSize;

(* The screen the point x, y is on; 0 if it is on none. *)
PROCEDURE ScreenAt*(x, y: INTEGER): INTEGER;
BEGIN RETURN CScreenNum(x, y)
END ScreenAt;

(* Command-line options *)

(* The C++ part's handler: argHandler's, checked. *)
PROCEDURE CallArgHandler(i: SYSTEM.INT32): SYSTEM.INT32;
  VAR n: INTEGER;
BEGIN
  n := argHandler(i);
  ASSERT((n >= 0) & (n <= Args.argc - i), IndexOutOfRange);
  RETURN n
END CallArgHandler;

(* Parses the command line's options (Args), the program's and FLTK's,
   from argument 1: handler, if not NIL, is offered each first, then
   FLTK (Arg). i is the number of the first argument not parsed:
   Args.argc if all were, or the first not an option (not starting with
   "-", or starting with "--", or "-" alone), or the first option
   neither knows, or that lacks its value, when the result is FALSE.
   FLTK's options take effect at once (-scheme, -kbd, -dnd, -tooltips,
   and the rest), or are kept for ShowArgs. ArgsHelp lists them. *)
PROCEDURE ParseArgs*(handler: ArgHandler; VAR i: INTEGER): BOOLEAN;
  VAR r: INTEGER; n: SYSTEM.INT32;
BEGIN
  argHandler := handler;
  IF handler = NIL THEN r := CArgs(Args.argc, Args.argv, n, NIL)
  ELSE r := CArgs(Args.argc, Args.argv, n, CallArgHandler)
  END;
  argHandler := NIL; i := n;
  RETURN r # 0
END ParseArgs;

(* Parses argument i, if it is one of FLTK's options: the number of words
   used, 0 if it isn't one. *)
PROCEDURE Arg*(i: INTEGER): INTEGER;
BEGIN
  ASSERT((i >= 0) & (i < Args.argc), IndexOutOfRange);
  RETURN CArg(Args.argc, Args.argv, i)
END Arg;

(* FLTK's options, a line each, indented a space (" -bg2 color" and the
   rest, without a heading), truncated to fit s. *)
PROCEDURE ArgsHelp*(VAR s: ARRAY OF CHAR);
BEGIN FromC(CArgsHelp(), s)
END ArgsHelp;

(* The pixels between a menu's lines, for menus opened from now on. *)
PROCEDURE MenuLinespacing*(): INTEGER;
BEGIN RETURN CMenuLinespacing()
END MenuLinespacing;

PROCEDURE SetMenuLinespacing*(n: INTEGER);
BEGIN CSetMenuLinespacing(n)
END SetMenuLinespacing;

(* A shortcut as FLTK shows it ("Ctrl+S"), truncated to fit s. Beyond
   letters and FLTK's named keys it depends on the back end: X11 names a
   key by its keysym ("Ctrl+EuroSign", "Enter" for 0DX), and Wayland
   gives the character itself (the euro sign, and 0DX) (doc/fltk-issues.md,
   167). *)
PROCEDURE ShortcutLabel*(key: INTEGER; state: SET; VAR s: ARRAY OF CHAR);
BEGIN CShortcutLabel(key + ORD(state), s, SHORT(LEN(s)))
END ShortcutLabel;

(* Opens uri with the desktop's program for it (xdg-open, on Linux),
   which runs on by itself: a file:, ftp:, http:, https:, mailto: or
   news: URI. TRUE if the program was started, with msg its command;
   FALSE, with msg why not, if uri's scheme isn't one of those, or no
   program could be found. msg is truncated to fit. *)
PROCEDURE OpenURI*(uri-: ARRAY OF CHAR; VAR msg: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN COpenURI(uri, msg, SHORT(LEN(msg))) # 0
END OpenURI;

(* Timer *)

(* What a timer does when it fires: its action, if set. *)
PROCEDURE (t: Timer) Fire*;
BEGIN
  IF t.action # NIL THEN t.action(t) END
END Fire;

PROCEDURE (t: Timer) Pending*(): BOOLEAN;
BEGIN RETURN t.pending
END Pending;

PROCEDURE Link(t: Timer);
BEGIN
  t.prev := NIL; t.next := timers;
  IF timers # NIL THEN timers.prev := t END;
  timers := t; t.pending := TRUE; INC(pendingCount)
END Link;

PROCEDURE Unlink(t: Timer);
BEGIN
  IF t.prev = NIL THEN timers := t.next ELSE t.prev.next := t.next END;
  IF t.next # NIL THEN t.next.prev := t.prev END;
  t.prev := NIL; t.next := NIL; t.pending := FALSE; DEC(pendingCount)
END Unlink;

(* Has t fire once, seconds from now. A timer is pending at most once:
   adding a pending one moves it. *)
PROCEDURE AddTimeout*(t: Timer; seconds: LONGREAL);
  VAR self: SYSTEM.ADDRESS;
BEGIN
  ASSERT(t # NIL, NilArgument); self := SYSTEM.VAL(SYSTEM.ADDRESS, t);
  IF t.pending THEN CRemoveTimeout(self); Unlink(t) END;
  Link(t); CAddTimeout(seconds, self)
END AddTimeout;

(* From t's own Fire only: has t fire again, seconds after it was due,
   so a repeating timer doesn't drift. *)
PROCEDURE RepeatTimeout*(t: Timer; seconds: LONGREAL);
BEGIN
  ASSERT(t # NIL, NilArgument); ASSERT((t = firing) & ~t.pending, NotFiring);
  Link(t); CRepeatTimeout(seconds, SYSTEM.VAL(SYSTEM.ADDRESS, t))
END RepeatTimeout;

(* t won't fire; nothing if it isn't pending. *)
PROCEDURE RemoveTimeout*(t: Timer);
BEGIN
  ASSERT(t # NIL, NilArgument);
  IF t.pending THEN CRemoveTimeout(SYSTEM.VAL(SYSTEM.ADDRESS, t)); Unlink(t) END
END RemoveTimeout;

PROCEDURE PendingTimers*(): LONGINT;
BEGIN RETURN pendingCount
END PendingTimers;

(* Idle callbacks *)

(* What an idle callback does: its action, if set. *)
PROCEDURE (i: Idle) Run*;
BEGIN
  IF i.action # NIL THEN i.action(i) END
END Run;

PROCEDURE (i: Idle) Added*(): BOOLEAN;
BEGIN RETURN i.added
END Added;

(* Has i run whenever the event loop is idle, until RemoveIdle. While one
   is added, Wait doesn't wait. Adding one added does nothing. *)
PROCEDURE AddIdle*(i: Idle);
BEGIN
  ASSERT(i # NIL, NilArgument);
  IF ~i.added THEN
    i.prev := NIL; i.next := idles;
    IF idles # NIL THEN idles.prev := i END;
    idles := i; i.added := TRUE;
    CAddIdle(SYSTEM.VAL(SYSTEM.ADDRESS, i))
  END
END AddIdle;

(* i won't run again, even from its own Run; nothing if it isn't added. *)
PROCEDURE RemoveIdle*(i: Idle);
BEGIN
  ASSERT(i # NIL, NilArgument);
  IF i.added THEN
    CRemoveIdle(SYSTEM.VAL(SYSTEM.ADDRESS, i));
    IF i.prev = NIL THEN idles := i.next ELSE i.prev.next := i.next END;
    IF i.next # NIL THEN i.next.prev := i.prev END;
    i.prev := NIL; i.next := NIL; i.added := FALSE
  END
END RemoveIdle;

(* Checks *)

PROCEDURE ["C", "ofl_add_check"] CAddCheck(self: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_remove_check"] CRemoveCheck(self: SYSTEM.ADDRESS);

(* What a checker does: its action, if set. *)
PROCEDURE (c: Checker) Run*;
BEGIN
  IF c.action # NIL THEN c.action(c) END
END Run;

PROCEDURE (c: Checker) Added*(): BOOLEAN;
BEGIN RETURN c.added
END Added;

(* Has c run each time the event loop is about to wait, until
   RemoveCheck. Adding one added does nothing. *)
PROCEDURE AddCheck*(c: Checker);
BEGIN
  ASSERT(c # NIL, NilArgument);
  IF ~c.added THEN
    c.prev := NIL; c.next := checkers;
    IF checkers # NIL THEN checkers.prev := c END;
    checkers := c; c.added := TRUE;
    CAddCheck(SYSTEM.VAL(SYSTEM.ADDRESS, c))
  END
END AddCheck;

(* c won't run again, even from its own Run; nothing if it isn't added. *)
PROCEDURE RemoveCheck*(c: Checker);
BEGIN
  ASSERT(c # NIL, NilArgument);
  IF c.added THEN
    CRemoveCheck(SYSTEM.VAL(SYSTEM.ADDRESS, c));
    IF c.prev = NIL THEN checkers := c.next ELSE c.prev.next := c.next END;
    IF c.next # NIL THEN c.next.prev := c.prev END;
    c.prev := NIL; c.next := NIL; c.added := FALSE
  END
END RemoveCheck;

(* File descriptors *)

(* What a watch does when its descriptor is ready: its action, if set. *)
PROCEDURE (w: FdWatch) Ready*;
BEGIN
  IF w.action # NIL THEN w.action(w) END
END Ready;

PROCEDURE (w: FdWatch) Watching*(): BOOLEAN;
BEGIN RETURN w.when # {}
END Watching;

PROCEDURE Unwatch(w: FdWatch);
BEGIN
  IF w.prev = NIL THEN watches := w.next ELSE w.prev.next := w.next END;
  IF w.next # NIL THEN w.next.prev := w.prev END;
  w.prev := NIL; w.next := NIL; w.when := {}
END Unwatch;

(* w stops watching; nothing if it isn't. Ready may stop its own watch. *)
PROCEDURE UnwatchFd*(w: FdWatch);
BEGIN
  ASSERT(w # NIL, NilArgument);
  IF w.when # {} THEN CRemoveFd(w.fd, ORD(w.when)); Unwatch(w) END
END UnwatchFd;

(* Has w watch fd for when: one or more of FdRead, FdWrite and FdExcept,
   or it halts (Unsupported). A watch watches one descriptor: watching
   another stops the first. As in FLTK, a descriptor has one watch for
   each of them, so another watch of fd stops watching for these. *)
PROCEDURE WatchFd*(w: FdWatch; fd: INTEGER; when: SET);
  VAR v, next: FdWatch;
BEGIN
  ASSERT(w # NIL, NilArgument); ASSERT(fd >= 0, IndexOutOfRange);
  ASSERT((when # {}) & (when - (FdRead + FdWrite + FdExcept) = {}), Unsupported);
  UnwatchFd(w);
  v := watches;
  WHILE v # NIL DO
    next := v.next;
    IF (v.fd = fd) & (v.when * when # {}) THEN
      v.when := v.when - when;           (* FLTK's add_fd took these from it *)
      IF v.when = {} THEN Unwatch(v) END
    END;
    v := next
  END;
  w.fd := fd; w.when := when;
  w.prev := NIL; w.next := watches;
  IF watches # NIL THEN watches.prev := w END;
  watches := w;
  CAddFd(fd, ORD(when), SYSTEM.VAL(SYSTEM.ADDRESS, w))
END WatchFd;

(* The event dispatch *)

(* d sees every event first, and hands it on with HandleDefault; NIL for
   FLTK's own dispatch. *)
PROCEDURE SetEventDispatch*(d: EventDispatch);
BEGIN
  dispatch := d;
  IF d = NIL THEN CEventDispatch(0) ELSE CEventDispatch(1) END
END SetEventDispatch;

(* Event handlers *)

(* Adds h to the handlers, which see the events no widget used, newest
   first; h may be added more than once. *)
PROCEDURE AddHandler*(h: EventHandler);
  VAR n: HandlerNode;
BEGIN
  ASSERT(h # NIL, NilArgument);
  IF handlers = NIL THEN CEventHandlers(1) END;
  NEW(n); n.h := h; n.next := handlers; handlers := n
END AddHandler;

(* Removes h, added last; nothing if it isn't added. *)
PROCEDURE RemoveHandler*(h: EventHandler);
  VAR n, prev: HandlerNode;
BEGIN
  n := handlers; prev := NIL;
  WHILE (n # NIL) & (n.h # h) DO prev := n; n := n.next END;
  IF n # NIL THEN
    IF prev = NIL THEN handlers := n.next ELSE prev.next := n.next END;
    n.h := NIL;  (* removed; n.next stays, for HandlerD *)
    IF handlers = NIL THEN CEventHandlers(0) END
  END
END RemoveHandler;

(* Redraws every window shown. *)
PROCEDURE Redraw*;
BEGIN CRedrawAll
END Redraw;

(* Whether any window is shown, the program's or FLTK's own (a dialog's,
   a menu's). *)
PROCEDURE WindowShown*(): BOOLEAN;
BEGIN RETURN CWindowShownAny() # 0
END WindowShown;

(* In the event dispatch only (NotFiring): FLTK's own handling of the
   event, for the dispatch's window; TRUE if a widget used it. *)
PROCEDURE HandleDefault*(event: INTEGER): BOOLEAN;
BEGIN ASSERT(dispatching > 0, NotFiring); RETURN CHandleDefault(event) # 0
END HandleDefault;

(* The event's key (EventKey) and text (EventText) become these, for
   what handles it next: as the event dispatch remaps a key. EventLength
   is the text's length. *)
PROCEDURE SetEventKey*(key: INTEGER);
BEGIN CSetEventKey(key)
END SetEventKey;

PROCEDURE SetEventText*(text-: ARRAY OF CHAR);
BEGIN CSetEventText(text)
END SetEventText;

(* The event loop *)

(* Handles events until no window is shown. *)
PROCEDURE Run*;
  VAR r: SYSTEM.INT32;
BEGIN r := CRun()
END Run;

(* Handles the events waiting now, without waiting; TRUE if a window is
   shown. *)
PROCEDURE Check*(): BOOLEAN;
BEGIN RETURN CCheck() # 0
END Check;

(* Check, for a call that doesn't want to know whether a window is
   shown. *)
PROCEDURE HandlePending*;
  VAR r: SYSTEM.INT32;
BEGIN r := CCheck()
END HandlePending;

(* Waits up to seconds for events, and handles them. *)
PROCEDURE Wait*(seconds: LONGREAL);
BEGIN CWait(seconds)
END Wait;

(* The dispatchers the C++ part calls (pofltk.h), registered below. *)

PROCEDURE CallbackD(self: SYSTEM.ADDRESS);
  VAR w: Widget;
BEGIN w := SYSTEM.VAL(Widget, self); w.Callback
END CallbackD;

PROCEDURE DrawOverlayD(self: SYSTEM.ADDRESS);
  VAR w: Widget;
BEGIN
  w := SYSTEM.VAL(Widget, self);
  w(Window).DrawOverlay
END DrawOverlayD;

PROCEDURE DrawD(self: SYSTEM.ADDRESS);
  VAR w: Widget;
BEGIN w := SYSTEM.VAL(Widget, self); w.Draw
END DrawD;

PROCEDURE ResizeD(self: SYSTEM.ADDRESS; x, y, w, h: SYSTEM.INT32);
  VAR wd: Widget;
BEGIN wd := SYSTEM.VAL(Widget, self); wd.Resize(x, y, w, h)
END ResizeD;

PROCEDURE HandleD(self: SYSTEM.ADDRESS; event: SYSTEM.INT32): SYSTEM.INT32;
  VAR w: Widget;
BEGIN
  w := SYSTEM.VAL(Widget, self);
  IF w.Handle(event) THEN RETURN 1 ELSE RETURN 0 END
END HandleD;

(* FLTK is destroying the widget: forget it. *)
PROCEDURE DeletedD(self: SYSTEM.ADDRESS);
  VAR w: Widget;
BEGIN
  w := SYSTEM.VAL(Widget, self); Unregister(w); w.h := 0; w.state := closed
END DeletedD;

(* Unlinked before Fire runs, so Fire may add or repeat it. *)
PROCEDURE TimeoutD(self: SYSTEM.ADDRESS);
  VAR t, outer: Timer;
BEGIN
  t := SYSTEM.VAL(Timer, self); Unlink(t);
  outer := firing; firing := t; t.Fire; firing := outer
END TimeoutD;

PROCEDURE ["C", "ofl_flush"] CFlush;
PROCEDURE ["C", "ofl_ready"] CReady(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_run_checks"] CRunChecks;
PROCEDURE ["C", "ofl_run_idle"] CRunIdle;
PROCEDURE ["C", "ofl_program_should_quit"] CProgramShouldQuit(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_set_program_should_quit"] CSetProgramShouldQuit(q: SYSTEM.INT32);
PROCEDURE ["C", "ofl_hide_all_windows"] CHideAllWindows;
PROCEDURE ["C", "ofl_damage_any"] CDamageAny(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_first_window"] CFirstWindow(): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_next_window"] CNextWindow(w: SYSTEM.ADDRESS): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_set_first_window"] CSetFirstWindow(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_set_atclose"] CSetAtclose(on: SYSTEM.INT32);
PROCEDURE ["C", "ofl_default_atclose"] CDefaultAtclose(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_set_abort"] CSetAbort(on: SYSTEM.INT32);
PROCEDURE ["C", "ofl_now"] CNow(offset: LONGREAL; VAR sec: LONGREAL; VAR usec: SYSTEM.INT32);
PROCEDURE ["C", "ofl_seconds_since"] CSecondsSince(sec: LONGREAL; usec: SYSTEM.INT32): LONGREAL;
PROCEDURE ["C", "ofl_seconds_between"] CSecondsBetween(s1: LONGREAL; u1: SYSTEM.INT32; s2: LONGREAL; u2: SYSTEM.INT32): LONGREAL;
PROCEDURE ["C", "ofl_ticks_since"] CTicksSince(sec: LONGREAL; usec: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_ticks_between"] CTicksBetween(s1: LONGREAL; u1: SYSTEM.INT32; s2: LONGREAL; u2: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_font_end"] CFontEnd(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_get_font"] CGetFont(f: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_get_font_name"] CGetFontName(f: SYSTEM.INT32; VAR attributes: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_get_font_sizes"] CGetFontSizes(f: SYSTEM.INT32; sizes: SYSTEM.ADDRESS; n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_set_font"] CSetFont(f: SYSTEM.INT32; name: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_set_font_from"] CSetFontFrom(to, from: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_set_fonts"] CSetFonts(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_contrast_mode"] CContrastMode(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_set_contrast_mode"] CSetContrastMode(mode: SYSTEM.INT32);
PROCEDURE ["C", "ofl_contrast_level"] CContrastLevel(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_set_contrast_level"] CSetContrastLevel(level: SYSTEM.INT32);
PROCEDURE ["C", "ofl_set_contrast_function"] CSetContrastFunction(f: ContrastFunction);
PROCEDURE ["C", "ofl_contrast_sized"] CContrastSized(fg, bg, context, size: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_lightness"] CLightness(c: SYSTEM.INT32): LONGREAL;
PROCEDURE ["C", "ofl_luminance"] CLuminance(c: SYSTEM.INT32): LONGREAL;
PROCEDURE ["C", "ofl_box_kind"] CBoxKind(b, what: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_parse_color"] CParseColor(name: SYSTEM.ADDRESS; VAR r, g, b: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_modifier"] CModifier(control: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_set_boxtype"] CSetBoxtype(b: SYSTEM.INT32; draw: BoxDraw; dx, dy, dw, dh: SYSTEM.INT32);
PROCEDURE ["C", "ofl_set_boxtype_from"] CSetBoxtypeFrom(to, from: SYSTEM.INT32);
PROCEDURE ["C", "ofl_get_boxtype"] CGetBoxtype(b: SYSTEM.INT32): BoxDraw;
PROCEDURE ["C", "ofl_box_color"] CBoxColor(c: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_set_box_color"] CSetBoxColor(c: SYSTEM.INT32);
PROCEDURE ["C", "ofl_draw_box_active"] CDrawBoxActive(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_box_border_radius_max"] CBoxBorderRadiusMax(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_set_box_border_radius_max"] CSetBoxBorderRadiusMax(r: SYSTEM.INT32);
PROCEDURE ["C", "ofl_box_shadow_width"] CBoxShadowWidth(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_set_box_shadow_width"] CSetBoxShadowWidth(w: SYSTEM.INT32);
PROCEDURE ["C", "ofl_free_color"] CFreeColor(c, overlay: SYSTEM.INT32);
PROCEDURE ["C", "ofl_get_system_colors"] CGetSystemColors;
PROCEDURE ["C", "ofl_own_colormap"] COwnColormap;
PROCEDURE ["C", "ofl_visual"] CVisual(mode: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_is_scheme"] CIsScheme(name: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofl_reload_scheme"] CReloadScheme(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_callback_reason"] CCallbackReason(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_event_name"] CEventName(e: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_font_const_name"] CFontConstName(f: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_reason_name"] CReasonName(r: SYSTEM.INT32): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_compose"] CCompose(VAR del: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_compose_reset"] CComposeReset;
PROCEDURE ["C", "ofl_test_shortcut"] CTestShortcut(s: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofl_get_mouse"] CGetMouse(VAR x, y: SYSTEM.INT32);
PROCEDURE ["C", "ofl_grab"] CGrab(): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_set_grab"] CSetGrab(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_handle_event"] CHandleEvent(event: SYSTEM.INT32; w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofl_selection"] CSelection(owner: SYSTEM.ADDRESS; text: SYSTEM.ADDRESS; n: SYSTEM.INT32);
PROCEDURE ["C", "ofl_selection_owner"] CSelectionOwner(): SYSTEM.ADDRESS;
PROCEDURE ["C", "ofl_set_selection_owner"] CSetSelectionOwner(w: SYSTEM.ADDRESS);
PROCEDURE ["C", "ofl_selection_to_clipboard"] CSelectionToClipboard(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_set_selection_to_clipboard"] CSetSelectionToClipboard(on: SYSTEM.INT32);
PROCEDURE ["C", "ofl_clipboard_notify"] CClipboardNotify(on: SYSTEM.INT32);
PROCEDURE ["C", "ofl_screen_dpi"] CScreenDpi(n: SYSTEM.INT32; VAR h, v: LONGREAL);
PROCEDURE ["C", "ofl_screen_scale"] CScreenScale(n: SYSTEM.INT32): LONGREAL;
PROCEDURE ["C", "ofl_set_screen_scale"] CSetScreenScale(n: SYSTEM.INT32; factor: LONGREAL);
PROCEDURE ["C", "ofl_screen_scaling_supported"] CScreenScalingSupported(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_keyboard_screen_scaling"] CKeyboardScreenScaling(on: SYSTEM.INT32);
PROCEDURE ["C", "ofl_enable_im"] CEnableIM(on: SYSTEM.INT32);
PROCEDURE ["C", "ofl_version"] CVersion(): LONGREAL;
PROCEDURE ["C", "ofl_api_version"] CApiVersion(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_abi_version"] CAbiVersion(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_built_version"] CBuiltVersion(): LONGREAL;
PROCEDURE ["C", "ofl_built_api_version"] CBuiltApiVersion(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_built_abi_version"] CBuiltAbiVersion(): SYSTEM.INT32;
PROCEDURE ["C", "ofl_abi_check"] CAbiCheck(): SYSTEM.INT32;

PROCEDURE Int(b: BOOLEAN): SYSTEM.INT32;
BEGIN IF b THEN RETURN 1 ELSE RETURN 0 END
END Int;

(* FLTK's loop *)

(* Draws what needs it now, not when the loop next waits. *)
PROCEDURE Flush*;
BEGIN CFlush
END Flush;

(* Whether an event or a timer is waiting. *)
PROCEDURE Ready*(): BOOLEAN;
BEGIN RETURN CReady() # 0
END Ready;

PROCEDURE RunChecks*;
BEGIN CRunChecks
END RunChecks;

(* Runs the idles once, as the loop does with nothing else to do. *)
PROCEDURE RunIdle*;
BEGIN CRunIdle
END RunIdle;

(* Whether the system asked the program to quit, on macOS alone. *)
PROCEDURE ProgramShouldQuit*(): BOOLEAN;
BEGIN RETURN CProgramShouldQuit() # 0
END ProgramShouldQuit;

PROCEDURE SetProgramShouldQuit*(q: BOOLEAN);
BEGIN CSetProgramShouldQuit(Int(q))
END SetProgramShouldQuit;

(* Hides every window shown, FLTK's too, each by its close callback,
   unless one stays. *)
PROCEDURE HideAllWindows*;
BEGIN CHideAllWindows
END HideAllWindows;

(* Whether any window needs drawing. *)
PROCEDURE AnyDamage*(): BOOLEAN;
BEGIN RETURN CDamageAny() # 0
END AnyDamage;

(* The windows shown, the program's alone, most recent first: FirstWindow
   then NextWindow, until NIL. *)
PROCEDURE FirstWindow*(): Window;
BEGIN RETURN SYSTEM.VAL(Window, CFirstWindow())
END FirstWindow;

(* NIL if w is the last, or isn't shown. *)
PROCEDURE NextWindow*(w: Window): Window;
BEGIN RETURN SYSTEM.VAL(Window, CNextWindow(Live(w)))
END NextWindow;

(* Makes w the first window, and the one a new dialog sits over; nothing
   if it isn't shown. *)
PROCEDURE SetFirstWindow*(w: Window);
BEGIN CSetFirstWindow(Live(w))
END SetFirstWindow;

(* a is told when one of the program's windows is to close, in place of
   hiding it (a window's Callback's default); NIL for FLTK's own. FLTK's
   windows are hidden as ever. *)
PROCEDURE SetAtclose*(a: Atclose);
BEGIN atclose := a; CSetAtclose(Int(a # NIL))
END SetAtclose;

(* What FLTK does when a window is to close: hides it. *)
PROCEDURE DefaultAtclose*(w: Window);
BEGIN CDefaultAtclose(Live(w))
END DefaultAtclose;

(* a is told FLTK's fatal error, in place of writing it out; NIL for
   FLTK's own. The program ends then, by exit(1), if a returns. *)
PROCEDURE SetAbort*(a: Abort);
BEGIN abort := a; CSetAbort(Int(a # NIL))
END SetAbort;

(* Time *)

(* offset seconds from now. *)
PROCEDURE Now*(VAR t: Timestamp; offset: LONGREAL);
  VAR u: SYSTEM.INT32;
BEGIN CNow(offset, t.sec, u); t.usec := u
END Now;

PROCEDURE SecondsSince*(VAR t: Timestamp): LONGREAL;
BEGIN RETURN CSecondsSince(t.sec, t.usec)
END SecondsSince;

(* later minus earlier *)
PROCEDURE SecondsBetween*(VAR later, earlier: Timestamp): LONGREAL;
BEGIN RETURN CSecondsBetween(later.sec, later.usec, earlier.sec, earlier.usec)
END SecondsBetween;

(* In 60ths of a second. *)
PROCEDURE TicksSince*(VAR t: Timestamp): HUGEINT;
  VAR h: HUGEINT;
BEGIN h := CTicksSince(t.sec, t.usec); RETURN h
END TicksSince;

PROCEDURE TicksBetween*(VAR later, earlier: Timestamp): HUGEINT;
  VAR h: HUGEINT;
BEGIN
  h := CTicksBetween(later.sec, later.usec, earlier.sec, earlier.usec);
  RETURN h
END TicksBetween;

(* Fonts. A number is a font's in 0 to FontEnd() - 1, or has none: such a
   number's name is empty, and it draws as Helvetica. *)

PROCEDURE FontEnd*(): INTEGER;
BEGIN RETURN CFontEnd()
END FontEnd;

PROCEDURE CheckFont(f: INTEGER);
BEGIN ASSERT((f >= 0) & (f < CFontEnd()), IndexOutOfRange)
END CheckFont;

(* The name FLTK finds font f by, which SetFont takes. *)
PROCEDURE GetFont*(f: INTEGER; VAR name: ARRAY OF CHAR);
BEGIN CheckFont(f); FromC(CGetFont(f), name)
END GetFont;

(* The name to show, and Bold, Italic or BoldItalic in attributes. *)
PROCEDURE GetFontName*(f: INTEGER; VAR name: ARRAY OF CHAR; VAR attributes: INTEGER);
  VAR a: SYSTEM.INT32;
BEGIN
  CheckFont(f); FromC(CGetFontName(f, a), name); attributes := a
END GetFontName;

(* Puts f's sizes in sizes, as many as fit, ascending, and returns how
   many; a first size of 0 means any size will do. *)
PROCEDURE GetFontSizes*(f: INTEGER; VAR sizes: ARRAY OF INTEGER): INTEGER;
BEGIN
  CheckFont(f);
  RETURN CGetFontSizes(f, SYSTEM.ADR(sizes), SHORT(LEN(sizes)))
END GetFontSizes;

(* Makes f the font name says, up to 0 to MaxFont, which may be past
   FontEnd(), and cut to 126 bytes. On X11 with neither Cairo nor Pango,
   name's first character is its style: " " plain, "B" bold, "I" italic,
   "P" both. *)
PROCEDURE SetFont*(f: INTEGER; name-: ARRAY OF CHAR);
  VAR n: LONGINT;
BEGIN
  ASSERT((f >= 0) & (f <= MaxFont), IndexOutOfRange);
  n := 0; WHILE (n < LEN(name)) & (name[n] # 0X) DO INC(n) END;
  ASSERT(n < LEN(name), IndexOutOfRange);
  CSetFont(f, SYSTEM.ADR(name))
END SetFont;

(* Makes font to what font from is, which must have a name. *)
PROCEDURE SetFontFrom*(to, from: INTEGER);
BEGIN
  ASSERT((to >= 0) & (to <= MaxFont), IndexOutOfRange);
  CheckFont(from);
  ASSERT(CSetFontFrom(to, from) # 0, IndexOutOfRange)
END SetFontFrom;

(* Adds every font the system has, from FreeFont on, over any font set
   there, and returns FontEnd(). The first call can take seconds. *)
PROCEDURE SetFonts*(): INTEGER;
BEGIN RETURN CSetFonts()
END SetFonts;

(* Colors *)

PROCEDURE ContrastMode*(): INTEGER;
BEGIN RETURN CContrastMode()
END ContrastMode;

(* mode is ContrastNone to ContrastCustom. Each mode has its level.
   ContrastCustom with no SetContrastFunction contrasts as ContrastCielab
   at Custom's level, which is 0 to start, and so changes no colour, even
   white on white: set a level in Custom mode, such as 39, CIELAB's, for
   CIELAB's contrast (doc/fltk-issues.md, 162). *)
PROCEDURE SetContrastMode*(mode: INTEGER);
BEGIN
  ASSERT((mode >= ContrastNone) & (mode <= ContrastCustom), IndexOutOfRange);
  CSetContrastMode(mode)
END SetContrastMode;

PROCEDURE ContrastLevel*(): INTEGER;
BEGIN RETURN CContrastLevel()
END ContrastLevel;

(* The current mode's level, 0 to 100: more is less likely to change. *)
PROCEDURE SetContrastLevel*(level: INTEGER);
BEGIN CSetContrastLevel(level)
END SetContrastLevel;

(* f is ContrastCustom's; NIL for none. *)
PROCEDURE SetContrastFunction*(f: ContrastFunction);
BEGIN CSetContrastFunction(f)
END SetContrastFunction;

(* Contrast, for text (context 0) or a line, of size pixels if known. *)
PROCEDURE ContrastSized*(fg, bg, context, size: INTEGER): INTEGER;
BEGIN RETURN CContrastSized(fg, bg, context, size)
END ContrastSized;

(* CIELAB's L*, as the eye sees c: 0.0 for black to 100.0 for white. *)
PROCEDURE Lightness*(c: INTEGER): LONGREAL;
BEGIN RETURN CLightness(c)
END Lightness;

(* The light c gives: 0.0 to 1.0. *)
PROCEDURE Luminance*(c: INTEGER): LONGREAL;
BEGIN RETURN CLuminance(c)
END Luminance;

(* name's color, "#rrggbb" and the like, or an X11 name on X11; FALSE,
   with r, g and b unchanged, if there is none. *)
PROCEDURE ParseColor*(name-: ARRAY OF CHAR; VAR r, g, b: INTEGER): BOOLEAN;
  VAR n: LONGINT; cr, cg, cb: SYSTEM.INT32;
BEGIN
  n := 0; WHILE (n < LEN(name)) & (name[n] # 0X) DO INC(n) END;
  ASSERT(n < LEN(name), IndexOutOfRange);
  IF CParseColor(SYSTEM.ADR(name), cr, cg, cb) = 0 THEN RETURN FALSE END;
  r := cr; g := cg; b := cb;
  RETURN TRUE
END ParseColor;

(* The state a program's commands use: Ctrl, or Meta on macOS. *)
PROCEDURE CommandModifier*(): SET;
BEGIN RETURN SYSTEM.VAL(SET, CModifier(0))
END CommandModifier;

(* The other: Meta, or Ctrl on macOS. *)
PROCEDURE ControlModifier*(): SET;
BEGIN RETURN SYSTEM.VAL(SET, CModifier(1))
END ControlModifier;

(* c, as Color would be, grayed while drawing an inactive box. *)
PROCEDURE BoxColor*(c: INTEGER): INTEGER;
BEGIN RETURN CBoxColor(c)
END BoxColor;

(* In a BoxDraw, sets the color to draw with to BoxColor(c). *)
PROCEDURE SetBoxColor*(c: INTEGER);
BEGIN CSetBoxColor(c)
END SetBoxColor;

(* In a BoxDraw, whether the box is active. *)
PROCEDURE DrawBoxActive*(): BOOLEAN;
BEGIN RETURN CDrawBoxActive() # 0
END DrawBoxActive;

PROCEDURE BoxBorderRadiusMax*(): INTEGER;
BEGIN RETURN CBoxBorderRadiusMax()
END BoxBorderRadiusMax;

(* Below 5 is taken as 5. *)
PROCEDURE SetBoxBorderRadiusMax*(r: INTEGER);
BEGIN CSetBoxBorderRadiusMax(r)
END SetBoxBorderRadiusMax;

PROCEDURE BoxShadowWidth*(): INTEGER;
BEGIN RETURN CBoxShadowWidth()
END BoxShadowWidth;

(* Below 1 is taken as 1. *)
PROCEDURE SetBoxShadowWidth*(w: INTEGER);
BEGIN CSetBoxShadowWidth(w)
END SetBoxShadowWidth;

(* Box types, 0 to 255 *)

PROCEDURE CheckBox(b: INTEGER);
BEGIN ASSERT((b >= 0) & (b <= 255), IndexOutOfRange)
END CheckBox;

(* The filled box of frame or down box b, and others as they are. *)
PROCEDURE BoxFilled*(b: INTEGER): INTEGER;
BEGIN CheckBox(b); RETURN CBoxKind(b, 0)
END BoxFilled;

(* The pressed form of b. *)
PROCEDURE BoxDown*(b: INTEGER): INTEGER;
BEGIN CheckBox(b); RETURN CBoxKind(b, 1)
END BoxDown;

(* The frame of b. *)
PROCEDURE BoxFrame*(b: INTEGER): INTEGER;
BEGIN CheckBox(b); RETURN CBoxKind(b, 2)
END BoxFrame;

(* Makes b draw with draw, which must draw only within what dx, dy, dw
   and dh, 0 to 255, leave for the widget's edge (BoxDx). A scheme set
   later can replace a box type it uses. *)
PROCEDURE SetBoxtype*(b: INTEGER; draw: BoxDraw; dx, dy, dw, dh: INTEGER);
BEGIN
  CheckBox(b);
  ASSERT(draw # NIL, NilArgument);
  ASSERT((dx >= 0) & (dx <= 255) & (dy >= 0) & (dy <= 255)
    & (dw >= 0) & (dw <= 255) & (dh >= 0) & (dh <= 255), IndexOutOfRange);
  CSetBoxtype(b, draw, dx, dy, dw, dh)
END SetBoxtype;

PROCEDURE SetBoxtypeFrom*(to, from: INTEGER);
BEGIN CheckBox(to); CheckBox(from); CSetBoxtypeFrom(to, from)
END SetBoxtypeFrom;

(* What draws b, to call with a color from a BoxDraw of its own. *)
PROCEDURE GetBoxtype*(b: INTEGER): BoxDraw;
BEGIN CheckBox(b); RETURN CGetBoxtype(b)
END GetBoxtype;

(* The color map *)

(* Lets index color c, 0 to 255, be set again, on the X11 of a colormap. *)
PROCEDURE ReleaseColor*(c: INTEGER; overlay: BOOLEAN);
BEGIN
  ASSERT((c >= 0) & (c <= 255), IndexOutOfRange);
  CFreeColor(c, Int(overlay))
END ReleaseColor;

(* Takes the colors the system gives, as Background and the like. *)
PROCEDURE GetSystemColors*;
BEGIN CGetSystemColors
END GetSystemColors;

PROCEDURE OwnColormap*;
BEGIN COwnColormap
END OwnColormap;

(* Asks for a visual of mode, VisualRgb and the rest added together, for
   the windows to come; FALSE if there is none. *)
PROCEDURE Visual*(mode: INTEGER): BOOLEAN;
BEGIN RETURN CVisual(mode) # 0
END Visual;

PROCEDURE IsScheme*(name-: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN CIsScheme(name) # 0
END IsScheme;

(* Applies the scheme again, over any box type set since it was, and
   redraws. *)
PROCEDURE ReloadScheme*(): BOOLEAN;
BEGIN RETURN CReloadScheme() # 0
END ReloadScheme;

(* Events *)

PROCEDURE EventAlt*(): BOOLEAN;
BEGIN RETURN Alt * EventState() # {}
END EventAlt;

PROCEDURE EventCtrl*(): BOOLEAN;
BEGIN RETURN Ctrl * EventState() # {}
END EventCtrl;

PROCEDURE EventShift*(): BOOLEAN;
BEGIN RETURN Shift * EventState() # {}
END EventShift;

PROCEDURE EventCommand*(): BOOLEAN;
BEGIN RETURN CommandModifier() * EventState() # {}
END EventCommand;

(* Which buttons are held: of Button1, Button2 and Button3 and so on. *)
PROCEDURE EventButtons*(): SET;
BEGIN RETURN EventState() * {24 .. 30}
END EventButtons;

(* Why the widget's Callback runs: ReasonUnknown and the rest. *)
PROCEDURE CallbackReason*(): INTEGER;
BEGIN RETURN CCallbackReason()
END CallbackReason;

(* The names of FLTK's own constants, as FL/names.h gives them, for
   showing: "FL_PUSH" for EvPush, "FL_COURIER" for Courier,
   "FL_REASON_CHANGED" for ReasonChanged. A number with no name, such as
   a font past ZapfDingbats or an unused reason, gives "". *)
PROCEDURE EventName*(event: INTEGER; VAR name: ARRAY OF CHAR);
BEGIN FromC(CEventName(event), name)
END EventName;

PROCEDURE FontConstName*(font: INTEGER; VAR name: ARRAY OF CHAR);
BEGIN FromC(CFontConstName(font), name)
END FontConstName;

PROCEDURE ReasonName*(reason: INTEGER; VAR name: ARRAY OF CHAR);
BEGIN FromC(CReasonName(reason), name)
END ReasonName;

(* In a Handle of an EvKeyDown, for an editor of text: TRUE if EventText
   is to be taken, after deleting del bytes before the cursor. *)
PROCEDURE Compose*(VAR del: INTEGER): BOOLEAN;
  VAR d, r: SYSTEM.INT32;
BEGIN r := CCompose(d); del := d; RETURN r # 0
END Compose;

PROCEDURE ComposeReset*;
BEGIN CComposeReset
END ComposeReset;

(* Whether the event is key and state as a shortcut. *)
PROCEDURE TestShortcut*(key: INTEGER; state: SET): BOOLEAN;
BEGIN RETURN CTestShortcut(key + ORD(state)) # 0
END TestShortcut;

(* Where the mouse is now, on the screen; Wayland gives where it last
   was over a window. *)
PROCEDURE GetMouse*(VAR x, y: INTEGER);
  VAR cx, cy: SYSTEM.INT32;
BEGIN CGetMouse(cx, cy); x := cx; y := cy
END GetMouse;

(* The window with the grab, if it is the program's; NIL with no grab, or
   one FLTK made, such as a pop-up menu's window (HasGrab). *)
PROCEDURE Grab*(): Window;
BEGIN RETURN SYSTEM.VAL(Window, CGrab())
END Grab;

(* Whether any window has the grab, the program's or FLTK's
   (doc/fltk-issues.md, 171). *)
PROCEDURE HasGrab*(): BOOLEAN;
BEGIN RETURN CAny(3) # 0
END HasGrab;

(* Gives w, shown, every event, wherever it happens, until SetGrab(NIL)
   or w is deleted. *)
PROCEDURE SetGrab*(w: Window);
BEGIN
  IF w = NIL THEN CSetGrab(0)
  ELSE ASSERT(w.Shown(), OutOfOrder); CSetGrab(Live(w))
  END
END SetGrab;

(* Sends event to shown window w as the window system would. *)
PROCEDURE HandleEvent*(event: INTEGER; w: Window): BOOLEAN;
BEGIN
  ASSERT(w # NIL, NilArgument);
  ASSERT(w.Shown(), OutOfOrder);
  RETURN CHandleEvent(event, Live(w)) # 0
END HandleEvent;

(* The selection and the clipboard *)

(* As Copy to Selection, recording owner, for SelectionOwner. FLTK 1.4
   sends no EvSelectionClear, whatever its documentation says, so owner
   isn't told when it loses the selection (doc/fltk-issues.md, 132). *)
PROCEDURE SetSelection*(owner: Widget; text-: ARRAY OF CHAR);
  VAR n: LONGINT;
BEGIN
  n := 0; WHILE (n < LEN(text)) & (text[n] # 0X) DO INC(n) END;
  ASSERT(n < LEN(text), IndexOutOfRange);
  CSelection(Live(owner), SYSTEM.ADR(text), SHORT(n))
END SetSelection;

PROCEDURE SelectionOwner*(): Widget;
BEGIN RETURN SYSTEM.VAL(Widget, CSelectionOwner())
END SelectionOwner;

(* owner is NIL for none. *)
PROCEDURE SetSelectionOwner*(owner: Widget);
BEGIN
  IF owner = NIL THEN CSetSelectionOwner(0)
  ELSE CSetSelectionOwner(Live(owner))
  END
END SetSelectionOwner;

(* Whether what goes in the selection goes in the clipboard too. *)
PROCEDURE SelectionToClipboard*(): BOOLEAN;
BEGIN RETURN CSelectionToClipboard() # 0
END SelectionToClipboard;

PROCEDURE SetSelectionToClipboard*(on: BOOLEAN);
BEGIN CSetSelectionToClipboard(Int(on))
END SetSelectionToClipboard;

(* n is told when another program changes the selection or the clipboard;
   n may be added more than once. X11 needs XFixes. *)
PROCEDURE AddClipboardNotify*(n: ClipboardNotify);
  VAR c: ClipboardNode;
BEGIN
  ASSERT(n # NIL, NilArgument);
  IF notices = NIL THEN CClipboardNotify(1) END;
  NEW(c); c.h := n; c.next := notices; notices := c
END AddClipboardNotify;

(* Removes n, added last; nothing if it isn't added. *)
PROCEDURE RemoveClipboardNotify*(n: ClipboardNotify);
  VAR c, prev: ClipboardNode;
BEGIN
  c := notices; prev := NIL;
  WHILE (c # NIL) & (c.h # n) DO prev := c; c := c.next END;
  IF c # NIL THEN
    IF prev = NIL THEN notices := c.next ELSE prev.next := c.next END;
    c.h := NIL;
    IF notices = NIL THEN CClipboardNotify(0) END
  END
END RemoveClipboardNotify;

(* Screens and input *)

(* Screen n's dots per inch, across and up. *)
PROCEDURE ScreenDPI*(n: INTEGER; VAR h, v: LONGREAL);
BEGIN
  ASSERT((n >= 0) & (n < CScreenCount()), IndexOutOfRange);
  CScreenDpi(n, h, v)
END ScreenDPI;

PROCEDURE ScreenScale*(n: INTEGER): LONGREAL;
BEGIN
  ASSERT((n >= 0) & (n < CScreenCount()), IndexOutOfRange);
  RETURN CScreenScale(n)
END ScreenScale;

(* Scales screen n's windows by factor, above 0; nothing if
   ScreenScalingSupported() is 0. *)
PROCEDURE SetScreenScale*(n: INTEGER; factor: LONGREAL);
BEGIN
  ASSERT((n >= 0) & (n < CScreenCount()), IndexOutOfRange);
  ASSERT(factor > 0.0D0, IndexOutOfRange);
  CSetScreenScale(n, factor)
END SetScreenScale;

(* 0 for no scaling, 1 for one scale for all screens, 2 for one each. *)
PROCEDURE ScreenScalingSupported*(): INTEGER;
BEGIN RETURN CScreenScalingSupported()
END ScreenScalingSupported;

(* Whether ctrl-plus and ctrl-minus scale the screen. *)
PROCEDURE KeyboardScreenScaling*(on: BOOLEAN);
BEGIN CKeyboardScreenScaling(Int(on))
END KeyboardScreenScaling;

(* The system's input method, on by default. *)
PROCEDURE EnableIM*;
BEGIN CEnableIM(1)
END EnableIM;

PROCEDURE DisableIM*;
BEGIN CEnableIM(0)
END DisableIM;

(* The version *)

(* As 1.0405, of the library running. *)
PROCEDURE Version*(): LONGREAL;
BEGIN RETURN CVersion()
END Version;

(* As 10405. *)
PROCEDURE ApiVersion*(): INTEGER;
BEGIN RETURN CApiVersion()
END ApiVersion;

PROCEDURE AbiVersion*(): INTEGER;
BEGIN RETURN CAbiVersion()
END AbiVersion;

(* FLTK's FL_VERSION, FL_API_VERSION and FL_ABI_VERSION: the versions of
   the headers pofltk was built with, which Version, ApiVersion and
   AbiVersion, the library running, should match. *)
PROCEDURE BuiltVersion*(): LONGREAL;
BEGIN RETURN CBuiltVersion()
END BuiltVersion;

PROCEDURE BuiltApiVersion*(): INTEGER;
BEGIN RETURN CBuiltApiVersion()
END BuiltApiVersion;

PROCEDURE BuiltAbiVersion*(): INTEGER;
BEGIN RETURN CBuiltAbiVersion()
END BuiltAbiVersion;

(* Whether the library running suits pofltk's C++ parts. *)
PROCEDURE AbiCheck*(): BOOLEAN;
BEGIN RETURN CAbiCheck() # 0
END AbiCheck;

PROCEDURE IdleD(self: SYSTEM.ADDRESS);
  VAR i: Idle;
BEGIN i := SYSTEM.VAL(Idle, self); i.Run
END IdleD;

PROCEDURE FdD(self: SYSTEM.ADDRESS);
  VAR w: FdWatch;
BEGIN w := SYSTEM.VAL(FdWatch, self); w.Ready
END FdD;

PROCEDURE CheckerD(self: SYSTEM.ADDRESS);
  VAR c: Checker;
BEGIN c := SYSTEM.VAL(Checker, self); c.Run
END CheckerD;

PROCEDURE AtcloseD(self: SYSTEM.ADDRESS);
BEGIN atclose(SYSTEM.VAL(Window, self))
END AtcloseD;

PROCEDURE AbortD(text: SYSTEM.ADDRESS);
  VAR message: ARRAY 1024 OF CHAR;
BEGIN FromC(text, message); abort(message)
END AbortD;

(* As HandlerD: one may remove itself or another. *)
PROCEDURE ClipboardD(source: SYSTEM.INT32);
  VAR c: ClipboardNode;
BEGIN
  c := notices;
  WHILE c # NIL DO
    IF c.h # NIL THEN c.h(source) END;
    c := c.next
  END
END ClipboardD;

(* self is the event's window's object, or 0. *)
PROCEDURE DispatchD(event: SYSTEM.INT32; self: SYSTEM.ADDRESS): SYSTEM.INT32;
  VAR w: Window; used: BOOLEAN;
BEGIN
  IF self = 0 THEN w := NIL ELSE w := SYSTEM.VAL(Window, self) END;
  INC(dispatching);
  IF dispatch # NIL THEN used := dispatch(event, w) ELSE used := CHandleDefault(event) # 0 END;
  DEC(dispatching);
  IF used THEN RETURN 1 ELSE RETURN 0 END
END DispatchD;

(* Each handler in turn, until one uses the event. One may remove itself
   or another: a node removed keeps its next, and its h is NIL, so it is
   passed over. One added meanwhile is first, and not called. *)
PROCEDURE HandlerD(event: SYSTEM.INT32): SYSTEM.INT32;
  VAR n: HandlerNode;
BEGIN
  n := handlers;
  WHILE n # NIL DO
    IF (n.h # NIL) & n.h(event) THEN RETURN 1 END;
    n := n.next
  END;
  RETURN 0
END HandlerD;

BEGIN
  CRegister(CallbackD, DrawD, HandleD, ResizeD, DeletedD, TimeoutD);
  CRegisterOverlay(DrawOverlayD);
  CRegisterLoop(IdleD, FdD, DispatchD, HandlerD);
  CRegisterStatics(CheckerD, AtcloseD, AbortD, ClipboardD)
END Fl.
