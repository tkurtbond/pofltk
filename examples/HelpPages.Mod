MODULE HelpPages; (* A help view whose pages are in the program, kept and followed by its Link method *)

(* A link's address needn't be a file: this view's Link method answers
   those starting "page:" by setting the view's text, and lets the others
   load. An address with a colon reaches Link as it is written; one
   without comes joined to the page's directory. Run from examples/, as
   make test runs it. *)

IMPORT Fl, FlButtons, FlHelp, FlImages, Strings;

CONST
  home = "page:home";

TYPE
  View = POINTER TO RECORD (FlHelp.HelpViewDesc)
    back: ARRAY 8, 256 OF CHAR;  (* the pages followed, newest last; then no more *)
    backs: INTEGER
  END;
  Back = POINTER TO RECORD (FlButtons.ButtonDesc) END;
  Quit = POINTER TO RECORD (FlButtons.ButtonDesc) END;

VAR
  win: Fl.Window;
  view: View;
  title: Fl.Box;
  back: Back;
  quit: Quit;
  current: ARRAY 256 OF CHAR;  (* the page shown *)
  ok: BOOLEAN;

PROCEDURE Page(uri-: ARRAY OF CHAR; VAR text: ARRAY OF CHAR): BOOLEAN;
BEGIN
  IF uri = home THEN
    COPY('<head><title>Home</title></head><body><h1>Pages in a Program</h1><p>Nothing here is in a file. See <a href="page:views">views</a>, <a href="page:links">links</a> or <a href="../test/help.html">a file</a>.</p>', text)
  ELSIF uri = "page:views" THEN
    COPY('<head><title>Views</title></head><body><h2>Views</h2><p>A <b>HelpView</b> shows HTML, and has a scroll bar when it needs one.</p><p><a href="page:home">Home</a></p>', text)
  ELSIF uri = "page:links" THEN
    COPY('<head><title>Links</title></head><body><h2>Links</h2><p>A <b>Link</b> method is asked about each link and each image.</p><p><a href="page:home">Home</a></p>', text)
  ELSE
    RETURN FALSE
  END;
  RETURN TRUE
END Page;

(* The view goes on to uri: remembers the page it leaves. *)
PROCEDURE Follow(v: View; uri-: ARRAY OF CHAR);
BEGIN
  IF (current # "") & (v.backs < LEN(v.back)) THEN
    COPY(current, v.back[v.backs]); INC(v.backs)
  END;
  COPY(uri, current)
END Follow;

PROCEDURE (v: View) Link*(uri-: ARRAY OF CHAR; VAR name: ARRAY OF CHAR): BOOLEAN;
  VAR text: ARRAY 512 OF CHAR;
BEGIN
  IF Page(uri, text) THEN
    Follow(v, uri);
    v.SetValue(text);
    RETURN FALSE
  END;
  IF Strings.Pos(".html", uri, 0) >= 0 THEN Follow(v, uri) END;  (* not an image *)
  COPY(uri, name);
  RETURN TRUE
END Link;

(* The page has changed: show its title. *)
PROCEDURE (v: View) Callback*;
  VAR s: ARRAY 64 OF CHAR;
BEGIN
  v.Title(s); title.SetLabel(s)
END Callback;

PROCEDURE (b: Back) Callback*;
  VAR ok: BOOLEAN;
BEGIN
  IF view.backs > 0 THEN
    DEC(view.backs);
    current := "";  (* so Follow keeps nothing *)
    ok := view.Load(view.back[view.backs])
  END
END Callback;

PROCEDURE (b: Quit) Callback*;
BEGIN win.Hide
END Callback;

BEGIN
  FlImages.RegisterImages;  (* for the images of the file it links to *)
  NEW(win); Fl.OpenWindow(win, 420, 300, "Help Pages");
  NEW(title); Fl.OpenBox(title, 10, 10, 220, 25, "");
  NEW(back); FlButtons.OpenButton(back, 240, 10, 80, 25, "Back");
  NEW(quit); FlButtons.OpenButton(quit, 330, 10, 80, 25, "Quit");
  NEW(view); FlHelp.OpenHelpView(view, 10, 45, 400, 245, "");
  win.End;
  win.SetResizable(view);
  ok := view.Load(home); ASSERT(ok);
  win.Show;
  Fl.Run
END HelpPages.
