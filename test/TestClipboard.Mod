MODULE TestClipboard; (* Fl's clipboard, and FlImages' images on it *)

IMPORT Fl, FlDraw, FlInputs, FlImages, Check, Probe;

TYPE
  (* Keeps what is pasted into it: the text, or the image if take. *)
  Receiver = POINTER TO RECORD (Fl.BoxDesc)
    pastes: INTEGER;
    text: ARRAY 64 OF CHAR;
    take, isImage, accept: BOOLEAN;
    img: FlImages.Image
  END;

  (* Takes part in drag and drop if accept: keeps the last such event it
     got, and how many. *)
  DndBox = POINTER TO RECORD (Fl.BoxDesc)
    accept: BOOLEAN;
    last, events: INTEGER
  END;

VAR
  win, dwin: Fl.Window;
  r: Receiver;
  d: DndBox;
  in: FlInputs.Input;
  i: FlImages.Image;
  bits: ARRAY 12 OF CHAR;
  s: ARRAY 64 OF CHAR;
  n: INTEGER;
  ok: BOOLEAN;
  lost: FlImages.CopySurface;

PROCEDURE (r: Receiver) Handle*(event: INTEGER): BOOLEAN;
  VAR ok: BOOLEAN;
BEGIN
  IF event = Fl.EvPaste THEN
    INC(r.pastes); r.isImage := Fl.EventIsImage();
    IF r.isImage THEN
      IF r.take THEN NEW(r.img); ok := FlImages.TakePastedImage(r.img) END
    ELSE Fl.EventText(r.text)
    END;
    RETURN r.accept
  END;
  RETURN r.Handle^(event)
END Handle;

PROCEDURE (d: DndBox) Handle*(event: INTEGER): BOOLEAN;
BEGIN
  IF (event >= Fl.EvDndEnter) & (event <= Fl.EvDndRelease) THEN
    d.last := event; INC(d.events);
    RETURN d.accept
  END;
  RETURN d.Handle^(event)
END Handle;

(* Drawing on a CopySurface and pasting it back: red, with a blue box
   drawn at its right. *)
PROCEDURE CopySurfaces;
  VAR c: FlImages.CopySurface; t: FlImages.Surface; b: Fl.Box; w: Fl.Window; j: FlImages.Image;
BEGIN
  Fl.Copy("before", Fl.Clipboard);
  NEW(c); FlImages.OpenCopySurface(c, 8, 6);
  Check.Check(c.IsOpen() & (FlImages.openSurfaces = 1), "OpenCopySurface");
  NEW(w); Fl.OpenWindow(w, 8, 6, ""); w.End;
  NEW(b); Fl.OpenBox(b, 0, 0, 4, 6, ""); b.SetBoxType(Fl.FlatBox); b.SetColor(Fl.Blue);
  c.Begin;
  FlDraw.SetColor(Fl.Red); FlDraw.RectF(0, 0, 8, 6);
  c.DrawWidget(b, 4, 0);
  c.End;
  Check.Check(~Fl.ClipboardHasImage(), "the clipboard isn't written until Close");
  c.Close; c.Close;
  Check.Check(~c.IsOpen() & (FlImages.openSurfaces = 0), "Close");
  Check.Check(Fl.ClipboardHasImage(), "Close puts it on the clipboard");
  r.take := TRUE;
  Fl.PasteImage(r);
  Check.Check((r.img # NIL) & (r.img.DataW() = 8) & (r.img.DataH() = 6)
    & (r.img.Pixel(1, 3) = Fl.RGB(255, 0, 0)) & (r.img.Pixel(6, 3) = Fl.RGB(0, 0, 255)),
    "and pastes as drawn");
  r.img.Close; r.img := NIL; r.take := FALSE;

  (* Copy surfaces and image surfaces nest. *)
  NEW(t); FlImages.OpenSurface(t, 2, 2);
  NEW(c); FlImages.OpenCopySurface(c, 2, 2);
  t.Begin; c.Begin; FlDraw.SetColor(Fl.Red); FlDraw.RectF(0, 0, 2, 2); c.End;
  FlDraw.SetColor(Fl.Blue); FlDraw.RectF(0, 0, 2, 2); t.End;
  NEW(j); t.GetImage(j);
  Check.Check(j.Pixel(1, 1) = Fl.RGB(0, 0, 255), "they nest with image surfaces");
  j.Close; t.Close;
  c.Begin; c.Close;
  Check.Check(~c.IsOpen(), "Close ends one begun");

  (* A window, with its title bar where FLTK can get at it. *)
  w.Show; w.WaitForExpose;
  NEW(c); FlImages.OpenCopySurface(c, w.DecoratedW(), w.DecoratedH());
  c.Begin; c.DrawDecoratedWindow(w, 0, 0); c.End; c.Close;
  Check.Check(Fl.ClipboardHasImage(), "DrawDecoratedWindow");
  w.Hide;
  b.Delete; w.Delete;

  (* Left to the finalizer, when the program ends. *)
  NEW(lost); FlImages.OpenCopySurface(lost, 2, 2);
  lost := NIL
END CopySurfaces;

BEGIN
  NEW(win); Fl.OpenWindow(win, 100, 100, "TestClipboard");
  NEW(r); Fl.OpenBox(r, 0, 0, 10, 10, ""); r.accept := TRUE;
  NEW(in); FlInputs.OpenInput(in, 0, 20, 100, 20, "");
  win.End;

  (* Before the program owns either, under X11 no window is shown to ask
     for another program's data: nothing is pasted. *)
  Fl.Paste(r, Fl.Selection); Fl.Paste(r, Fl.Clipboard);
  Check.Check(r.pastes = 0, "Paste with nothing to paste");

  (* Text *)
  Fl.Copy("hello", Fl.Clipboard);
  Check.Check(Fl.ClipboardHasText() & ~Fl.ClipboardHasImage(), "Copy: the clipboard holds text");
  Fl.Paste(r, Fl.Clipboard);
  Check.Check((r.pastes = 1) & ~r.isImage & (r.text = "hello"), "Paste of the program's own text: at once");
  in.SetValue("ab"); in.Select(1, 1);
  Fl.Paste(in, Fl.Clipboard);
  in.Value(s);
  Check.Check(s = "ahellob", "an input pastes at its cursor");
  IF ~Fl.Has(Fl.Wayland) THEN
    Fl.Copy("sel", Fl.Selection);
    Fl.Paste(r, Fl.Selection);
    Check.Check((r.pastes = 2) & (r.text = "sel"), "the selection buffer (X11)");
    Fl.Paste(r, Fl.Clipboard);
    Check.Check(r.text = "hello", "apart from the clipboard");
    r.pastes := 1
  ELSE
    Fl.Copy("sel", Fl.Selection);
    Fl.Paste(r, Fl.Selection);
    Check.Check(r.pastes = 1, "no selection buffer (Wayland)")
  END;
  Fl.Copy("both", Fl.Both);
  Fl.Paste(r, Fl.Clipboard);
  Check.Check(r.text = "both", "Both");

  (* Images *)
  bits[0] := 0FFX; bits[1] := 0X; bits[2] := 0X; bits[3] := 0X; bits[4] := 0X; bits[5] := 0FFX;
  NEW(i); FlImages.OpenRGB(i, bits, 2, 1, 3, 0);
  i.CopyToClipboard;
  Check.Check(Fl.ClipboardHasImage() & ~Fl.ClipboardHasText(), "CopyToClipboard");
  n := r.pastes;
  Fl.PasteImage(r);
  Check.Check((r.pastes = n + 1) & r.isImage & (r.img = NIL), "PasteImage: an EvPaste with an image");
  r.take := TRUE;
  Fl.PasteImage(r);
  Check.Check((r.img # NIL) & r.img.IsOpen() & (r.img.DataW() = 2) & (r.img.DataH() = 1)
    & (r.img.Pixel(0, 0) = Fl.RGB(255, 0, 0)) & (r.img.Pixel(1, 0) = Fl.RGB(0, 0, 255)),
    "TakePastedImage: the image, as copied");
  r.img.Close; r.img := NIL;
  (* An image not taken is freed, whatever Handle returns: valgrind sees
     no leak and no double free. *)
  r.take := FALSE; r.accept := FALSE;
  Fl.PasteImage(r);
  r.accept := TRUE;
  Fl.PasteImage(r);
  Check.Check(r.pastes = n + 4, "an image not taken, refused or accepted");
  i.Close;
  CopySurfaces;

  (* Drag and drop, as the window system sends it while the user drags:
     FLTK's routing, from Fl::handle, decides which widget gets which. In
     a window of its own, with no input: EvDndLeave to a window never
     shown crashes FLTK in an Fl_Input (doc/fltk-issues.md, 53). *)
  NEW(dwin); Fl.OpenWindow(dwin, 100, 100, "TestClipboard: drag and drop");
  NEW(d); Fl.OpenBox(d, 50, 50, 20, 20, "");
  dwin.End;
  d.accept := TRUE;
  Check.Check(Probe.Mouse(dwin, Fl.EvDndEnter, 55, 55, 0, {}, 0) & (d.last = Fl.EvDndEnter)
    & (Fl.BelowMouse() = d), "EvDndEnter: a widget that takes it is below the mouse");
  Check.Check(Probe.Mouse(dwin, Fl.EvDndDrag, 60, 60, 0, {}, 0) & (d.last = Fl.EvDndDrag) & (d.events = 2),
    "EvDndDrag over it");
  Check.Check(Probe.Mouse(dwin, Fl.EvDndRelease, 60, 60, 0, {}, 0) & (d.last = Fl.EvDndRelease),
    "EvDndRelease: TRUE takes the drop");
  ok := Probe.Mouse(dwin, Fl.EvDndDrag, 90, 5, 0, {}, 0);  (* FALSE: the window has no use for it *)
  Check.Check((d.last = Fl.EvDndLeave) & (d.events = 4) & (Fl.BelowMouse() = dwin), "EvDndLeave: dragged off it");
  ok := Probe.Mouse(dwin, Fl.EvDndLeave, 90, 5, 0, {}, 0);
  Check.Check((d.events = 5) & (d.last = Fl.EvDndLeave) & (Fl.BelowMouse() = NIL),
    "EvDndLeave: out of the window, which passes it to each child again");
  d.accept := FALSE; d.events := 0;
  Check.Check(~Probe.Mouse(dwin, Fl.EvDndEnter, 55, 55, 0, {}, 0) & (d.last = Fl.EvDndEnter)
    & (Fl.BelowMouse() # d), "EvDndEnter refused: not below the mouse");
  ok := Probe.Mouse(dwin, Fl.EvDndLeave, 90, 5, 0, {}, 0);
  dwin.Delete;

  win.Delete;
  Check.Check((FlImages.openImages = 0) & (Fl.OpenWidgets() = 0), "every image and widget closed");
  Check.Summary
END TestClipboard.
