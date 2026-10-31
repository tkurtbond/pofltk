MODULE TestHelp; (* FlHelp: help views, their links and images, and the help dialog *)

IMPORT Strings, Fl, FlHelp, FlImages, Check, Probe;

TYPE
  (* A view that counts what it is asked, says no to what no names, and
     keeps "page:" pages in the program. *)
  View = POINTER TO RECORD (FlHelp.HelpViewDesc)
    links, images, calls: INTEGER;
    no: ARRAY 64 OF CHAR;
    last: ARRAY 256 OF CHAR
  END;

  Lost = POINTER TO RECORD (FlHelp.HelpViewDesc) END;

VAR
  s: ARRAY 4096 OF CHAR;
  ok: BOOLEAN;

PROCEDURE Contains(s-, part: ARRAY OF CHAR): BOOLEAN;
  VAR i, j: INTEGER;
BEGIN
  i := 0;
  WHILE s[i] # 0X DO
    j := 0;
    WHILE (part[j] # 0X) & (s[i + j] = part[j]) DO INC(j) END;
    IF part[j] = 0X THEN RETURN TRUE END;
    INC(i)
  END;
  RETURN FALSE
END Contains;

PROCEDURE (v: View) Link*(uri-: ARRAY OF CHAR; VAR name: ARRAY OF CHAR): BOOLEAN;
BEGIN
  INC(v.links); COPY(uri, v.last);
  IF uri = v.no THEN RETURN FALSE END;
  IF Contains(uri, "images/") THEN INC(v.images) END;
  IF uri = "page:two" THEN
    v.SetValue("<title>Two</title><p>The page called two.</p>");
    RETURN FALSE
  END;
  COPY(uri, name);
  RETURN TRUE
END Link;

PROCEDURE (v: View) Callback*;
BEGIN INC(v.calls)
END Callback;

PROCEDURE (v: Lost) Link*(uri-: ARRAY OF CHAR; VAR name: ARRAY OF CHAR): BOOLEAN;
BEGIN RETURN FALSE
END Link;

PROCEDURE TestSettings;
  VAR w: Fl.Window; v: View; i, top: INTEGER; page: ARRAY 8192 OF CHAR;
BEGIN
  NEW(w); Fl.OpenWindow(w, 200, 100, "help");
  NEW(v); FlHelp.OpenHelpView(v, 0, 0, 200, 100, "");
  w.End;
  v.Value(s); Check.Check(s = "", "a view starts with no text");
  v.Title(s); Check.Check(s = "Untitled", "and FLTK's title");
  v.Directory(s); Check.Check(s = "", "no directory");
  v.FileName(s); Check.Check(s = "", "no file");

  v.SetValue("<title>One</title><p>First <b>words</b>.</p>");
  v.Value(s); Check.Check(Contains(s, "First <b>words"), "SetValue");
  v.Title(s); Check.Check(s = "One", "Title");
  Check.Check(v.PageSize() > 0, "PageSize");

  page := '<a name="top">t</a>';
  FOR i := 1 TO 60 DO
    Strings.Append("<p>A line of text.</p>", page)
  END;
  Strings.Append('<a name="end">here</a><p>needle</p>', page);
  v.SetValue(page);
  Check.Check(v.TopLine() = 0, "a page starts at its top");
  v.SetTopLine(50); Check.Check(v.TopLine() = 50, "SetTopLine");
  v.SetTopLineName("end"); top := v.TopLine();
  Check.Check(top > 50, "SetTopLineName");
  v.SetTopLineName("nothing"); Check.Check(v.TopLine() = top, "a name not there moves nothing");
  v.SetTopLine(0);
  i := v.Find("NEEDLE", 0);
  Check.Check((i > 0) & (v.TopLine() > 0), "Find ignores case and scrolls");
  Check.Check(v.Find("needle", i + 1) = -1, "and goes from where it is told");
  Check.Check(v.Find("no such text", 0) = -1, "Find of nothing there");
  v.SetLeftLine(0); Check.Check(v.LeftLine() = 0, "LeftLine");

  v.SetTextColor(Fl.Blue); Check.Check(v.TextColor() = Fl.Blue, "SetTextColor");
  v.SetTextFont(Fl.Courier); Check.Check(v.TextFont() = Fl.Courier, "SetTextFont");
  v.SetTextSize(18); Check.Check(v.TextSize() = 18, "SetTextSize");
  v.SetScrollbarSize(12); Check.Check(v.ScrollbarSize() = 12, "SetScrollbarSize");

  Check.Check(~v.TextSelected(), "nothing selected");
  v.SelectAll; Check.Check(v.TextSelected(), "SelectAll");
  v.Copy(TRUE); v.Copy(FALSE);
  v.ClearSelection; Check.Check(~v.TextSelected(), "ClearSelection");

  v.calls := 0;
  v.SetValue("<p>Again</p>");
  Check.Check(v.calls > 0, "laying out a page calls back");
  v.SetValue("");
  v.Value(s); Check.Check(s = "", "SetValue of nothing");
  w.Delete
END TestSettings;

PROCEDURE TestLoad;
  VAR w: Fl.Window; v: View; n: INTEGER;
BEGIN
  NEW(w); Fl.OpenWindow(w, 300, 200, "help");
  NEW(v); FlHelp.OpenHelpView(v, 0, 0, 300, 200, "");
  w.End;
  Check.Check(v.Load("help.html"), "Load");
  Check.Check(v.images = 2, "each image is asked about");
  v.Title(s); Check.Check(s = "Help Test", "its title");
  v.FileName(s); Check.Check(s = "help.html", "its file");
  v.Value(s); Check.Check(Contains(s, "findme"), "its text");
  n := v.images;
  ok := Probe.Capture(v); ok := Probe.Capture(v);
  Check.Check(v.images = n, "and not asked again to draw");
  Check.Check(v.Load("help.html"), "Load again");
  Check.Check(v.images = n, "nor to load the same images");

  v.no := "help2.html";
  Check.Check(~v.Load("help2.html"), "Link's FALSE fails Load");
  v.FileName(s); Check.Check(s = "help.html", "and leaves the page");

  Check.Check(~v.Load("no-such-file.html"), "a file that can't be read");
  v.Value(s); Check.Check(Contains(s, "no-such-file"), "shows FLTK's message");

  Check.Check(v.Load("page:two"), "SetValue in Link makes it a success");
  v.Value(s); Check.Check(Contains(s, "called two"), "with Link's page");
  w.Delete
END TestLoad;

PROCEDURE TestBrokenImage;
  VAR w: Fl.Window; v: View; l: Lost;
BEGIN
  NEW(w); Fl.OpenWindow(w, 300, 200, "help");
  NEW(v); FlHelp.OpenHelpView(v, 0, 0, 300, 100, "");
  NEW(l); FlHelp.OpenHelpView(l, 0, 100, 300, 100, "");
  w.End;
  v.no := "images/rb.ppm";
  Check.Check(v.Load("help.html"), "Link's FALSE for an image doesn't stop the page");
  ok := Probe.Capture(v);
  l.SetValue('<p><img src="nothing.png"></p>');
  ok := Probe.Capture(l);
  v.SetValue("<p>Next</p>");
  Check.Check(v.images >= 1, "the other image is still asked about");
  l.Delete;
  w.Delete
END TestBrokenImage;

(* Clicks at x, y in w, from the top of v's page, until a link is there. *)
PROCEDURE ClickLink(w: Fl.Window; v: View): BOOLEAN;
  VAR y: INTEGER; ok: BOOLEAN;
BEGIN
  v.links := 0;
  y := 5;
  WHILE (y < 150) & (v.links = 0) DO
    ok := Probe.Mouse(w, Fl.EvPush, 20, y, Fl.LeftMouse, Fl.Button1, 0);
    ok := Probe.Mouse(w, Fl.EvRelease, 20, y, Fl.LeftMouse, {}, 1);
    INC(y, 4)
  END;
  RETURN v.links > 0
END ClickLink;

PROCEDURE TestClick;
  VAR w: Fl.Window; v: View; y: INTEGER; ok: BOOLEAN; before: INTEGER;
BEGIN
  NEW(w); Fl.OpenWindow(w, 300, 200, "help");
  NEW(v); FlHelp.OpenHelpView(v, 0, 0, 300, 200, "");
  w.End; w.Show;
  ok := Fl.Check();
  v.SetValue('<h1>Top</h1><p><a href="page:two">Two</a></p>');
  ok := Probe.Capture(v);
  Check.Check(ClickLink(w, v), "a click on a link asks Link");
  Check.Check(v.last = "page:two", "with its uri");
  v.Value(s); Check.Check(Contains(s, "called two"), "and Link's page shows");

  v.SetValue('<h1>Top</h1><p><a href="help2.html">Two</a></p>');
  ok := Probe.Capture(v);
  Check.Check(ClickLink(w, v), "a link to a file");
  v.Title(s); Check.Check(s = "Second Page", "loads it");
  Check.Check(Contains(v.last, "help2.html"), "as a file");

  (* The page replaced with a link held down: nothing follows it. *)
  v.SetValue('<h1>Top</h1><p><a href="page:two">Two</a></p>');
  ok := Probe.Capture(v);
  v.links := 0;
  y := 5;
  WHILE (y < 150) & (v.links = 0) DO
    ok := Probe.Mouse(w, Fl.EvPush, 20, y, Fl.LeftMouse, Fl.Button1, 0);
    before := v.links;
    v.SetValue("<p>Replaced, and a good deal longer than it was before</p>");
    ok := Probe.Capture(v);
    ok := Probe.Mouse(w, Fl.EvRelease, 20, y, Fl.LeftMouse, {}, 1);
    v.SetValue('<h1>Top</h1><p><a href="page:two">Two</a></p>');
    ok := Probe.Capture(v);
    INC(y, 4)
  END;
  Check.Check(v.links = 0, "a link whose page has gone isn't followed");
  w.Delete
END TestClick;

PROCEDURE TestDialog;
  VAR d: FlHelp.HelpDialog; w: Fl.Window; b: Fl.Box;
BEGIN
  NEW(d);
  Check.Check(~d.IsOpen(), "a dialog isn't open before Open");
  NEW(w); Fl.OpenWindow(w, 100, 100, "group");
  FlHelp.OpenHelpDialog(d);
  NEW(b); Fl.OpenBox(b, 0, 0, 10, 10, "");
  w.End;
  Check.Check(b.Parent() = w, "Open leaves the current group as it was");
  w.Delete;
  Check.Check(d.IsOpen() & (FlHelp.openDialogs = 1), "open");
  Check.Check(~d.Visible(), "hidden");
  Check.Check(d.Load("help.html"), "Load");
  d.Value(s); Check.Check(Contains(s, "findme"), "Value");
  d.SetTopLine(0);
  d.SetTopLineName("nothing");
  Check.Check(~d.Load("no-such-file.html"), "a file that can't be read");
  d.SetValue("<p>In the dialog</p>");
  d.Value(s); Check.Check(Contains(s, "In the dialog"), "SetValue");
  d.SetTextSize(16); Check.Check(d.TextSize() = 16, "SetTextSize");
  d.SetPosition(10, 20); Check.Check((d.X() = 10) & (d.Y() = 20), "SetPosition");
  d.Resize(5, 6, 400, 300);
  Check.Check((d.X() = 5) & (d.Y() = 6) & (d.W() = 400) & (d.H() = 300), "Resize");
  d.Show; Check.Check(d.Visible(), "Show");
  ok := Fl.Check();
  d.Hide; Check.Check(~d.Visible(), "Hide");
  d.Close;
  Check.Check(~d.IsOpen() & (FlHelp.openDialogs = 0), "closed");
  d.Close;
  Check.Check(FlHelp.openDialogs = 0, "Close again does nothing")
END TestDialog;

BEGIN
  FlImages.RegisterImages;
  TestSettings;
  TestLoad;
  TestBrokenImage;
  TestClick;
  TestDialog;
  Check.Summary
END TestHelp.
