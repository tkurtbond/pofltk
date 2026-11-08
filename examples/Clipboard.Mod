MODULE Clipboard; (* FLTK's test/clipboard.cxx in Oberon-2 *)

(* A viewer of the clipboard: two tabs, one showing an image on a chess
   pattern, with its size below, and one showing text, in Courier. It
   shows what the clipboard holds at the start, and again whenever the
   clipboard changes or the Refresh button is pressed, and Save PNG
   writes the image to a file the user chooses. *)

IMPORT Fl, FlDraw, FlButtons, FlLayout, FlText, FlImages, FlDialogs;

CONST
  TabColor = Fl.Dark3;

TYPE
  (* a box with a chess pattern below its image *)
  Chess = POINTER TO RECORD (Fl.BoxDesc) END;

  (* the tabs, which take what is pasted *)
  Viewer = POINTER TO RECORD (FlLayout.TabsDesc) END;

  Text = POINTER TO ARRAY OF CHAR;

VAR
  imageBox: Chess;
  imageSize: Fl.Box;
  display: FlText.TextDisplay;
  buffer: FlText.TextBuffer;
  clImg: FlImages.Image;  (* the image from the clipboard, or NIL *)
  tabs: Viewer;

(* Appends n to s, as printf's "%d". *)
PROCEDURE Int(n: INTEGER; VAR s: ARRAY OF CHAR);
  VAR d: ARRAY 16 OF CHAR; k, i: INTEGER; neg: BOOLEAN;
BEGIN
  neg := n < 0; IF neg THEN n := -n END;
  k := 0; REPEAT d[k] := CHR(ORD("0") + n MOD 10); n := n DIV 10; INC(k) UNTIL n = 0;
  IF neg THEN d[k] := "-"; INC(k) END;
  i := 0; WHILE s[i] # 0X DO INC(i) END;
  WHILE k > 0 DO DEC(k); s[i] := d[k]; INC(i) END;
  s[i] := 0X
END Int;

PROCEDURE (b: Chess) Draw*;
  CONST side = 4; side2 = 2 * side;
  VAR x, y, w, h, i, j: INTEGER;
BEGIN
  b.DrawBox;
  IF clImg # NIL THEN  (* the chess pattern below the box's centered image *)
    w := clImg.W(); h := clImg.H();
    x := b.X() + (b.W() - w) DIV 2;
    y := b.Y() + (b.H() - h) DIV 2;
    FlDraw.PushClip(x, y, w, h);
    FlDraw.PushClip(b.X(), b.Y(), b.W(), b.H());
    FlDraw.SetColor(Fl.White);
    FlDraw.RectF(x, y, w, h);
    FlDraw.SetColor(Fl.Light2);
    j := y;
    WHILE j < y + h DO
      i := x + (j - y) MOD side2;
      WHILE i < x + w DO FlDraw.RectF(i, j, side, side); INC(i, side2) END;
      INC(j, side)
    END;
    FlDraw.PopClip;
    FlDraw.PopClip
  END;
  b.DrawLabel  (* the box's image *)
END Draw;

PROCEDURE (t: Viewer) Handle*(event: INTEGER): BOOLEAN;
  VAR img, old: FlImages.Image; title: ARRAY 32 OF CHAR; text: Text; i: INTEGER;
    win: Fl.Window;
BEGIN
  IF event # Fl.EvPaste THEN RETURN t.Handle^(event) END;
  IF Fl.EventIsImage() THEN  (* an image is being pasted *)
    NEW(img);
    IF ~FlImages.TakePastedImage(img) THEN RETURN TRUE END;
    title := ""; Int(img.W(), title);  (* the image's own size *)
    i := 0; WHILE title[i] # 0X DO INC(i) END; title[i] := "x"; title[i + 1] := 0X;
    Int(img.H(), title);
    old := clImg; clImg := img;
    IF (img.W() > imageBox.W()) OR (img.H() > imageBox.H()) THEN
      img.Scale(imageBox.W(), imageBox.H(), TRUE, FALSE)
    END;
    FlImages.SetImage(imageBox, img);  (* the scaled image *)
    IF old # NIL THEN old.Close END;
    imageSize.SetLabel(title);
    t.SetValue(imageBox.Parent());
    win := t.Window(); win.Redraw
  ELSE  (* text is being pasted *)
    NEW(text, Fl.EventLength() + 1);
    Fl.EventText(text^);
    buffer.SetText(text^);
    t.SetValue(display);
    display.Redraw
  END;
  RETURN TRUE
END Handle;

(* Pastes the clipboard's image, or else its text, into the tabs. *)
PROCEDURE Refresh;
BEGIN
  IF Fl.ClipboardHasImage() THEN Fl.PasteImage(tabs)
  ELSIF Fl.ClipboardHasText() THEN Fl.Paste(tabs, Fl.Clipboard)
  END
END Refresh;

PROCEDURE RefreshCb(w: Fl.Widget);
BEGIN Refresh
END RefreshCb;

PROCEDURE SaveCb(w: Fl.Widget);
  VAR fnfc: FlDialogs.NativeFileChooser; name: ARRAY 4096 OF CHAR;
    filter: ARRAY 16 OF CHAR; ok: BOOLEAN;
BEGIN
  IF (clImg # NIL) & clImg.IsOpen() THEN
    NEW(fnfc); FlDialogs.OpenNativeFileChooser(fnfc, FlDialogs.BrowseSaveFile);
    fnfc.SetTitle("Please select a .png file");
    filter := "PNG|*.png|"; filter[3] := 9X; filter[9] := 0AX;
    fnfc.SetFilter(filter);
    fnfc.SetOptions(FlDialogs.SaveAsConfirm + FlDialogs.UseFilterExt);
    IF (fnfc.Show() = FlDialogs.Chosen) & (fnfc.Count() > 0) THEN
      fnfc.FileName(0, name);
      ok := clImg.SavePNG(name)
    END;
    fnfc.Close
  ELSE FlDialogs.Message("No image available")
  END
END SaveCb;

(* Called after the clipboard changes, or the program is activated. *)
PROCEDURE ClipCallback(source: INTEGER);
BEGIN IF source = Fl.Clipboard THEN Refresh END
END ClipCallback;

PROCEDURE Build;
  VAR win: Fl.Window; g, g2: Fl.Group; refresh, save: FlButtons.Button;
BEGIN
  FlImages.RegisterImages;  (* for X11, to paste images *)
  NEW(win); Fl.OpenWindow(win, 500, 550, "FLTK Clipboard Viewer");
  NEW(tabs); FlLayout.OpenTabs(tabs, 0, 0, 500, 500, "");
  NEW(g); Fl.OpenGroup(g, 5, 30, 490, 460, "image");  (* the image form *)
  g.SetBoxType(Fl.FlatBox);
  NEW(imageBox); Fl.OpenBox(imageBox, 5, 30, 490, 450, "");
  imageBox.SetBoxType(Fl.FlatBox);
  imageBox.SetAlign(Fl.AlignCenter + Fl.AlignClip);
  NEW(imageSize); Fl.OpenBox(imageSize, 5, 485, 490, 10, "");
  imageSize.SetBoxType(Fl.NoBox);
  g.End;
  g.SetSelectionColor(TabColor);

  NEW(buffer); FlText.OpenBuffer(buffer);
  NEW(display);  (* the text form *)
  FlText.OpenTextDisplay(display, 5, 30, 490, 460, "text/plain");
  display.SetBuffer(buffer);
  display.SetSelectionColor(TabColor);
  display.SetTextFont(Fl.Courier);
  tabs.End;
  tabs.SetResizable(display);

  NEW(g2); Fl.OpenGroup(g2, 10, 510, 330, 25, "");
  NEW(refresh); FlButtons.OpenButton(refresh, 10, 510, 200, 25, "Refresh from clipboard");
  refresh.action := RefreshCb;
  NEW(save); FlButtons.OpenButton(save, 220, 510, 100, 25, "Save PNG");
  save.action := SaveCb;
  g2.End;
  g2.SetResizable(NIL);
  win.End;
  win.SetResizable(tabs);
  win.ShowArgs;
  ClipCallback(Fl.Clipboard);  (* the clipboard's content at the start *)
  Fl.AddClipboardNotify(ClipCallback);  (* and whenever it changes *)
  FlImages.SetScalingAlgorithm(FlImages.ScalingBilinear)
END Build;

BEGIN
  Build;
  Fl.Run
END Clipboard.
