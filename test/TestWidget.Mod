MODULE TestWidget; (* Widget, group and window properties; colors and schemes *)

(* Each property set reads back as set, through FLTK. Drawing them is
   tested by pixels in Phase 2. *)

IMPORT Out, Fl, FlDraw, Check;

VAR
  win: Fl.Window;
  g: Fl.Group;
  single: Fl.SingleWindow;
  menu: Fl.MenuWindow;
  a, b, c, d: Fl.Box;
  s: ARRAY 64 OF CHAR;
  short: ARRAY 10 OF CHAR;
  sx, sy, sw, sh, wx, wy, ww, wh: INTEGER;
  r, gr, bl: INTEGER;
  shown: BOOLEAN;
  n, lw, lh, fw, fh: INTEGER;
  other: Fl.Window;

BEGIN
  NEW(win); Fl.OpenWindow(win, 300, 200, "TestWidget");
  NEW(g); Fl.OpenGroup(g, 10, 10, 200, 150, "g");
  NEW(a); Fl.OpenBox(a, 20, 20, 50, 20, "a");
  NEW(b); Fl.OpenBox(b, 20, 50, 50, 20, "b");
  g.End;
  NEW(c); Fl.OpenBox(c, 220, 20, 50, 20, "c");
  win.End;

  (* the label's look *)
  a.SetBoxType(Fl.RoundUpBox); a.SetLabelFont(Fl.Times + Fl.BoldItalic);
  a.SetLabelSize(24); a.SetLabelColor(Fl.Blue); a.SetLabelType(Fl.EngravedLabel);
  Check.Check((a.BoxType() = Fl.RoundUpBox) & (a.LabelFont() = Fl.TimesBoldItalic)
    & (a.LabelSize() = 24) & (a.LabelColor() = Fl.Blue) & (a.LabelType() = Fl.EngravedLabel),
    "box type, label font, size, color and type read back");
  Check.Check((b.BoxType() = Fl.NoBox) & (b.LabelFont() = Fl.Helvetica)
    & (b.LabelSize() = Fl.NormalSize()) & (b.LabelType() = Fl.NormalLabel),
    "a box's defaults: no box, Helvetica, the normal size, a normal label");
  a.SetAlign(Fl.AlignTopLeft + Fl.AlignInside + Fl.AlignWrap);
  Check.Check(a.Align() = {0, 2, 4, 7}, "an alignment set reads back");
  a.SetColor(Fl.RGB(10, 20, 30)); a.SetSelectionColor(Fl.DarkRed);
  Check.Check((a.Color() = Fl.RGB(10, 20, 30)) & (a.SelectionColor() = Fl.DarkRed),
    "color and selection color, an RGB color and an index");
  a.SetWhen(Fl.WhenRelease + Fl.WhenChanged);
  Check.Check(a.When() = Fl.WhenRelease + Fl.WhenChanged, "when reads back");

  (* tooltips are copied *)
  s := "tip"; a.SetTooltip(s); s := "XXX"; a.GetTooltip(s);
  Check.Check(s = "tip", "a tooltip is copied");
  a.SetTooltip(""); a.GetTooltip(s);
  Check.Check(s = "", "an empty tooltip removes it");

  (* geometry *)
  a.Position(30, 25); a.Size(60, 22);
  Check.Check((a.X() = 30) & (a.Y() = 25) & (a.W() = 60) & (a.H() = 22),
    "Position and Size");
  a.Resize(20, 20, 50, 20);
  Check.Check((a.X() = 20) & (a.W() = 50), "Resize");

  (* activation and visibility through the group *)
  g.Deactivate;
  Check.Check(~g.Active() & a.Active() & ~a.ActiveR() & c.ActiveR(),
    "a deactivated group's child is active, but not active_r");
  g.Activate;
  Check.Check(a.ActiveR(), "and active_r again once the group is activated");
  Check.Check(~Fl.WindowShown(), "WindowShown: none yet");
  win.Show; shown := Fl.Check();
  Check.Check(win.Shown() & a.VisibleR(), "a shown window's box is visible_r");
  Check.Check(Fl.WindowShown(), "WindowShown");
  g.Hide;
  Check.Check(a.Visible() & ~a.VisibleR(), "a hidden group's child: visible, not visible_r");
  g.Show;

  (* parents and children *)
  Check.Check((a.Parent() = g) & (g.Parent() = win) & (win.Parent() = NIL),
    "Parent finds each object");
  Check.Check((g.Find(b) = 1) & (g.Find(c) = -1) & (win.Find(c) = 1), "Find");
  g.Remove(a);
  Check.Check((g.Children() = 1) & (a.Parent() = NIL) & a.IsOpen(), "Remove keeps the widget");
  g.Insert(a, 0);
  Check.Check((g.Child(0) = a) & (g.Child(1) = b) & (a.Parent() = g), "Insert at 0");
  g.Add(c);
  Check.Check((g.Child(2) = c) & (win.Find(c) = -1) & (c.Parent() = g),
    "Add moves a widget from its group");
  win.SetResizable(g);
  Check.Check(win.Resizable() = g, "Resizable");
  win.SetResizable(NIL);
  Check.Check(win.Resizable() = NIL, "no resizable");

  (* Clear deletes, so closes, the children *)
  NEW(d); Fl.OpenBox(d, 0, 0, 10, 10, ""); g.Add(d);
  Check.Check((g.Children() = 4) & (Fl.OpenWidgets() = 6), "four children");
  g.Clear;
  Check.Check((g.Children() = 0) & ~a.IsOpen() & ~b.IsOpen() & ~c.IsOpen() & ~d.IsOpen()
    & (Fl.OpenWidgets() = 2), "Clear closes them");

  (* A group resizes its children from the sizes it saved: a child the
     program moved goes back, unless InitSizes forgets them. *)
  NEW(a); Fl.OpenBox(a, 20, 20, 10, 10, ""); g.Add(a);
  g.Resize(10, 10, 400, 150);
  Check.Check((a.X() = 30) & (a.W() = 20), "a group scales its children");
  a.Resize(100, 20, 10, 10);
  g.Resize(10, 10, 200, 150);
  Check.Check(a.X() = 20, "from the sizes it saved");
  a.Resize(100, 20, 10, 10);
  g.InitSizes;
  g.Resize(10, 10, 400, 150);
  Check.Check((a.X() = 190) & (a.W() = 20), "InitSizes: from where they are");
  g.Resize(10, 10, 200, 150); g.Clear;

  (* window modes *)
  win.SetNonModal;
  Check.Check(~win.Modal(), "non-modal isn't modal");
  win.SetModal;
  Check.Check(win.Modal(), "modal");

  (* a window's title is its label *)
  win.SetLabel("retitled"); win.GetLabel(s);
  Check.Check(s = "retitled", "a shown window's title");

  (* colors *)
  Fl.GetRGB(Fl.RGB(1, 2, 3), r, gr, bl);
  Check.Check((r = 1) & (gr = 2) & (bl = 3), "GetRGB of an RGB color");
  Fl.SetIndexColor(Fl.FreeColor, Fl.RGB(200, 100, 50));
  Fl.GetRGB(Fl.FreeColor, r, gr, bl);
  Check.Check((r = 200) & (gr = 100) & (bl = 50), "SetIndexColor, and GetRGB of an index");
  Check.Check(Fl.Contrast(Fl.Black, Fl.Black) = Fl.White, "black on black contrasts to white");
  Fl.GetRGB(Fl.ColorAverage(Fl.RGB(200, 0, 0), Fl.RGB(0, 0, 100), 0.5D0), r, gr, bl);
  Check.Check((r = 100) & (gr = 0) & (bl = 50), "ColorAverage");

  (* box borders, from FLTK's table of box types *)
  Check.Check((Fl.BoxDX(Fl.NoBox) = 0) & (Fl.BoxDW(Fl.NoBox) = 0), "BoxDX: none for NoBox");
  Check.Check((Fl.BoxDX(Fl.ThinUpBox) = 1) & (Fl.BoxDY(Fl.ThinUpBox) = 1)
    & (Fl.BoxDW(Fl.ThinUpBox) = 2) & (Fl.BoxDH(Fl.ThinUpBox) = 2), "BoxDX, BoxDY, BoxDW, BoxDH");
  Check.Check((Fl.BoxDX(Fl.EngravedBox) = 2) & (Fl.BoxDH(Fl.EngravedBox) = 4), "an engraved box's");

  (* Screens. Their sizes are the display's, and printed: xvfb-run's
     default screen is 640x480, and tools/with-sway.sh's output 1280x800,
     each its own work area. *)
  Check.Check(Fl.ScreenCount() >= 1, "ScreenCount");
  Fl.ScreenXYWH(0, sx, sy, sw, sh); Fl.ScreenWorkArea(0, wx, wy, ww, wh);
  Check.Check((sw > 0) & (sh > 0) & (wx >= sx) & (wy >= sy) & (wx + ww <= sx + sw) & (wy + wh <= sy + sh),
    "ScreenXYWH, and its work area inside it");
  Check.Check((Fl.ScreenX() = wx) & (Fl.ScreenY() = wy) & (Fl.ScreenW() = ww) & (Fl.ScreenH() = wh),
    "ScreenX, ScreenY, ScreenW, ScreenH: the main screen's work area");
  Check.Check((Fl.ScreenAt(sx + sw - 1, sy + sh - 1) = 0) & (Fl.ScreenAt(sx - 10000, sy - 10000) = 0),
    "ScreenAt: 0 on screen 0, and on none");
  Out.String("# screen 0: "); Out.Int(sx, 0); Out.Char(","); Out.Int(sy, 0); Out.Char(" ");
  Out.Int(sw, 0); Out.Char("x"); Out.Int(sh, 0); Out.String(", work area ");
  Out.Int(ww, 0); Out.Char("x"); Out.Int(wh, 0); Out.Ln;

  (* OpenURI: only what starts no program *)
  Check.Check(~Fl.OpenURI("foo:bar", s) & (s = 'URI scheme "foo" not supported.'),
    "OpenURI of a scheme FLTK doesn't open: FALSE, and why");
  Check.Check(~Fl.OpenURI("foo:bar", short) & (short = "URI schem"), "its message truncated to fit");

  (* schemes and the normal size *)
  Check.Check(Fl.SetScheme("gtk+"), "a known scheme");
  Fl.GetScheme(s);
  Check.Check(s = "gtk+", "reads back");
  Fl.SetNormalSize(18);
  NEW(d); Fl.OpenBox(d, 0, 0, 10, 10, "");
  Check.Check(d.LabelSize() = 18, "a box opened after SetNormalSize gets the size");
  d.Delete; Fl.SetNormalSize(14);

  (* schemes: FLTK's own come first *)
  Check.Check(Fl.SchemeCount() >= 5, "FLTK has at least its five schemes");
  Fl.SchemeName(0, s);
  Check.Check(s = "base", "the first is base");
  n := Fl.SchemeCount();
  Check.Check(Fl.AddSchemeName("mine"), "a new scheme name");
  Check.Check(Fl.SchemeCount() = n + 1, "counts");
  Fl.SchemeName(n, s);
  Check.Check(s = "mine", "and is last");
  Check.Check(~Fl.AddSchemeName("mine"), "a name already there isn't added");
  Check.Check(~Fl.AddSchemeName("Upper Case"), "nor one with characters FLTK refuses");
  Check.Check(~Fl.AddSchemeName("thirteenchars"), "nor one over twelve bytes");
  Check.Check(Fl.SchemeCount() = n + 1, "so none of those counted");

  (* the other windows *)
  win.SetXClass("Pofltk");
  win.XClass(s);
  Check.Check(s = "Pofltk", "a window's class reads back");
  NEW(single); Fl.OpenSingleWindow(single, 100, 80, "single");
  single.End;
  Check.Check((single.W() = 100) & (single.H() = 80), "a single window");
  single.Delete;
  NEW(single); Fl.OpenSingleWindowAt(single, 10, 20, 100, 80, "single");
  single.End;
  Check.Check((single.X() = 10) & (single.Y() = 20), "placed");
  single.Delete;
  NEW(menu); Fl.OpenMenuWindow(menu, 100, 80, "menu");
  menu.End;
  Check.Check(menu.H() = 80, "a menu window");
  menu.Show; shown := Fl.Check();
  Check.Check(menu.Shown(), "shows");
  menu.Delete;
  NEW(menu); Fl.OpenMenuWindowAt(menu, 10, 20, 100, 80, "menu");
  menu.End;
  Check.Check(menu.X() = 10, "placed");
  menu.Delete;

  (* measuring and redrawing a label: g.Clear deleted c *)
  NEW(c); Fl.OpenBox(c, 220, 20, 50, 20, ""); win.Add(c);
  c.SetLabel("Hello world"); c.SetLabelFont(Fl.Courier); c.SetLabelSize(14);
  c.MeasureLabel(0, lw, lh); FlDraw.SetFont(Fl.Courier, 14); FlDraw.Measure("Hello world", fw, fh);
  Check.Check((lw = fw) & (lh = fh) & (lw > 0), "MeasureLabel, as FlDraw.Measure");
  c.MeasureLabel(lw DIV 2, fw, fh);
  Check.Check((fw <= lw DIV 2) & (fh = 2 * lh), "MeasureLabel wrapped");
  c.SetLabel(""); c.MeasureLabel(0, lw, lh);
  Check.Check((lw = 0) & (lh = 0), "MeasureLabel of no label");
  c.SetLabel("c"); c.SetAlign(Fl.AlignBottom);
  n := 0; WHILE (win.Damage() # {}) & (n < 100) DO shown := Fl.Check(); INC(n) END;
  c.RedrawLabel;
  Check.Check((win.Damage() # {}) & (c.Damage() = {}), "RedrawLabel of a label outside its box damages the window");
  c.SetBoxType(Fl.FlatBox); c.SetAlign(Fl.AlignCenter);
  n := 0; WHILE (win.Damage() # {}) & (n < 100) DO shown := Fl.Check(); INC(n) END;
  c.RedrawLabel;
  Check.Check(c.Damage() # {}, "RedrawLabel of a label inside its box damages the box");

  (* Full screen on given screens, and minimized. win was shown with no
     resizable widget, which fixed its size range, and Fullscreen does
     nothing for a window that can't be resized: SizeRange first. *)
  win.Fullscreen;
  Check.Check(~win.FullscreenActive(), "Fullscreen of a window of fixed size does nothing");
  win.SizeRange(100, 100, 0, 0);
  win.FullscreenScreens(0, 0, 0, 0);
  win.Fullscreen;
  n := 0; WHILE ~win.FullscreenActive() & (n < 100) DO Fl.Wait(0.01D0); INC(n) END;
  Check.Check(win.FullscreenActive(), "full screen, on screen 0's edges");
  win.FullscreenScreens(-1, -1, -1, -1);
  win.FullscreenOff;
  n := 0; WHILE win.FullscreenActive() & (n < 100) DO Fl.Wait(0.01D0); INC(n) END;
  Check.Check(~win.FullscreenActive(), "and off");
  NEW(other); Fl.OpenWindow(other, 100, 80, "other"); other.End;
  other.Iconize; shown := Fl.Check();
  Check.Check(other.Shown(), "Iconize of a window not shown shows it, minimized");
  other.Delete;
  IF Fl.Has(Fl.Wayland) THEN
    win.Iconize;
    n := 0; WHILE win.Visible() & (n < 200) DO Fl.Wait(0.01D0); INC(n) END;
    Check.Check(~win.Visible(), "Iconize hides a shown window")
  ELSE Check.Skip("Iconize hides a shown window: X11 needs a window manager")
  END;

  win.Delete;
  Check.Check(Fl.OpenWidgets() = 0, "all deleted");
  Check.Summary
END TestWidget.
