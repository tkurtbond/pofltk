MODULE Probe; (* For pofltk's tests: what FlTest doesn't give programs *)

(* What pofltk's own tests need to look inside FLTK and pofltk: what a
   widget keeps, the grab, a window's icon and placing, FLTK's
   configuration, pipes, the environment. A widget's pixels and events
   sent as from the user are FlTest's, which programs can use too.

   Its C++ part is Probe.cpp. *)

IMPORT SYSTEM, Fl;

PROCEDURE ["C", "ofltest_fatal"] CFatal(text: ARRAY OF CHAR);
PROCEDURE ["C", "ofltest_set_key"] CSetKey(key: SYSTEM.INT32; s: ARRAY OF CHAR);
PROCEDURE ["C", "ofltest_clipboard_notice"] CClipboardNotice(source: SYSTEM.INT32);
PROCEDURE ["C", "ofltest_kept"] CKept(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofltest_pipe"] CPipe(VAR fds: ARRAY OF SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofltest_write"] CWrite(fd: SYSTEM.INT32; s: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofltest_read"] CRead(fd: SYSTEM.INT32; VAR buf: ARRAY OF CHAR; n: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofltest_close"] CClose(fd: SYSTEM.INT32);
PROCEDURE ["C", "ofltest_grab"] CGrab(VAR r: ARRAY OF SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofltest_icon_words"] CIconWords(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofltest_forced_position"] CForcedPosition(w: SYSTEM.ADDRESS): SYSTEM.INT32;
PROCEDURE ["C", "ofltest_shared_width"] CSharedWidth(name: ARRAY OF CHAR): SYSTEM.INT32;
PROCEDURE ["C", "ofltest_configured"] CConfigured(feature: SYSTEM.INT32): SYSTEM.INT32;
PROCEDURE ["C", "ofltest_setenv"] CSetEnv(name, value: ARRAY OF CHAR);

(* How many resources w keeps beside its label images: a browser's
   line icons. *)
PROCEDURE Kept*(w: Fl.Widget): INTEGER;
BEGIN RETURN CKept(w.h)
END Kept;

(* The screen rectangle of the window FLTK grabs events to, an open menu;
   FALSE if there is none. *)
PROCEDURE Grab*(VAR x, y, w, h: INTEGER): BOOLEAN;
  VAR r: ARRAY 4 OF SYSTEM.INT32; ok: BOOLEAN;
BEGIN
  ok := CGrab(r) # 0;
  IF ok THEN x := r[0]; y := r[1]; w := r[2]; h := r[3] END;
  RETURN ok
END Grab;

(* The 32-bit words of the icons shown window w gave the window manager:
   for each, its width, height and pixels; -1 off X11. *)
PROCEDURE IconWords*(w: Fl.Window): INTEGER;
BEGIN RETURN CIconWords(w.h)
END IconWords;

(* Whether window w is to be shown where the program put it, not where
   the window manager chooses (FLTK's protected force_position). *)
PROCEDURE ForcedPosition*(w: Fl.Window): BOOLEAN;
BEGIN RETURN CForcedPosition(w.h) # 0
END ForcedPosition;

(* TRUE if fl_config.h gives feature, as Fl numbers them: that this FLTK
   has it, on some display. *)
PROCEDURE Configured*(feature: INTEGER): BOOLEAN;
BEGIN RETURN CConfigured(feature) # 0
END Configured;

(* The width of what FLTK's own Fl_Shared_Image::get makes of file name,
   as FLTK's widgets load one, or 0. *)
PROCEDURE SharedWidth*(name-: ARRAY OF CHAR): INTEGER;
BEGIN RETURN CSharedWidth(name)
END SharedWidth;

(* A pipe, for Fl.FdWatch: its read end r and write end w; TRUE if it
   was made. *)
PROCEDURE Pipe*(VAR r, w: INTEGER): BOOLEAN;
  VAR fds: ARRAY 2 OF SYSTEM.INT32; ok: BOOLEAN;
BEGIN
  ok := CPipe(fds) # 0; r := fds[0]; w := fds[1];
  RETURN ok
END Pipe;

(* Writes s to fd; the bytes written, or -1. *)
PROCEDURE Write*(fd: INTEGER; s-: ARRAY OF CHAR): INTEGER;
BEGIN RETURN CWrite(fd, s)
END Write;

(* Reads what fd has, up to LEN(s) - 1 bytes, into s; the bytes read, or
   -1. *)
PROCEDURE Read*(fd: INTEGER; VAR s: ARRAY OF CHAR): INTEGER;
BEGIN RETURN CRead(fd, s, SHORT(LEN(s)))
END Read;

PROCEDURE Close*(fd: INTEGER);
BEGIN CClose(fd)
END Close;

(* Sets an environment variable. *)
(* Makes key and s the event's, for what asks about it. *)
PROCEDURE SetKey*(key: INTEGER; s-: ARRAY OF CHAR);
BEGIN CSetKey(key, s)
END SetKey;

(* FLTK's fatal error: text, and 7, by its printf format. *)
PROCEDURE Fatal*(text: ARRAY OF CHAR);
BEGIN CFatal(text)
END Fatal;

(* As the window system tells FLTK of another program's copy. *)
PROCEDURE ClipboardNotice*(source: INTEGER);
BEGIN CClipboardNotice(source)
END ClipboardNotice;

PROCEDURE SetEnv*(name-, value-: ARRAY OF CHAR);
BEGIN CSetEnv(name, value)
END SetEnv;

END Probe.
