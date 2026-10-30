MODULE Selections; (* A text buffer's three selections: primary, secondary and highlight *)

(* The buffer tells this program of each change to its text and to its
   selections, by Modified, so the labels below always say what they
   hold. *)

IMPORT Fl, FlButtons, FlText, OutStr;

TYPE
  Buffer = POINTER TO RECORD (FlText.TextBufferDesc) END;

VAR
  win: Fl.Window;
  buffer: Buffer;
  editor: FlText.TextEditor;
  toSecondary, toHighlight, clear, replace: FlButtons.Button;
  primaryBox, secondaryBox, highlightBox: Fl.Box;

PROCEDURE Show(box: Fl.Box; name: ARRAY OF CHAR; s: FlText.Selection);
  VAR label: ARRAY 64 OF CHAR;
BEGIN
  IF box # NIL THEN
    label := ""; OutStr.String(name, label); OutStr.String(": ", label);
    IF s.Selected() THEN
      OutStr.Int(s.Start(), 0, label); OutStr.String(" to ", label);
      OutStr.Int(s.End(), 0, label); OutStr.String(", ", label);
      OutStr.Int(s.Length(), 0, label); OutStr.String(" bytes", label)
    ELSE
      OutStr.String("none", label)
    END;
    box.SetLabel(label)
  END
END Show;

PROCEDURE (b: Buffer) Modified*(pos, inserted, deleted, restyled: INTEGER);
  VAR primary, secondary: FlText.Selection;
BEGIN
  primary := b.PrimarySelection(); secondary := b.SecondarySelection();
  Show(primaryBox, "Primary", primary);
  Show(secondaryBox, "Secondary", secondary);
  Show(highlightBox, "Highlight", b.HighlightSelection());
  IF toSecondary # NIL THEN
    IF primary.Selected() THEN
      toSecondary.Activate; toHighlight.Activate
    ELSE
      toSecondary.Deactivate; toHighlight.Deactivate
    END;
    IF secondary.Selected() THEN replace.Activate ELSE replace.Deactivate END
  END
END Modified;

PROCEDURE ToSecondary(w: Fl.Widget);
  VAR start, end: INTEGER;
BEGIN
  IF buffer.Selection(start, end) THEN
    buffer.Unselect; buffer.SecondarySelect(start, end)
  END
END ToSecondary;

PROCEDURE ToHighlight(w: Fl.Widget);
  VAR start, end: INTEGER;
BEGIN
  IF buffer.Selection(start, end) THEN
    buffer.Unselect; buffer.Highlight(start, end)
  END
END ToHighlight;

PROCEDURE Clear(w: Fl.Widget);
BEGIN
  buffer.Unselect; buffer.SecondaryUnselect; buffer.Unhighlight
END Clear;

(* The secondary selection's text gives way to the primary's, or to its
   own text in capitals if there is no primary selection. *)
PROCEDURE Replace(w: Fl.Widget);
  VAR s: ARRAY 256 OF CHAR; i: INTEGER; primary: FlText.Selection;
BEGIN
  primary := buffer.PrimarySelection();
  IF primary.Selected() THEN
    buffer.SelectionText(s)
  ELSE
    buffer.SecondaryText(s);
    i := 0;
    WHILE s[i] # 0X DO s[i] := CAP(s[i]); INC(i) END
  END;
  buffer.ReplaceSecondary(s)
END Replace;

PROCEDURE Status(VAR b: Fl.Box; y: INTEGER);
BEGIN
  NEW(b); Fl.OpenBox(b, 10, y, 300, 22, "");
  b.SetAlign(Fl.AlignInside + Fl.AlignLeft)
END Status;

PROCEDURE Button(VAR b: FlButtons.Button; x: INTEGER; label: ARRAY OF CHAR; action: PROCEDURE (w: Fl.Widget));
BEGIN
  NEW(b); FlButtons.OpenButton(b, x, 190, 110, 25, label);
  b.action := action
END Button;

BEGIN
  NEW(win); Fl.OpenWindow(win, 480, 300, "Selections");
  NEW(buffer); FlText.OpenBuffer(buffer);
  buffer.SetText("Select some of this text with the mouse, then make it the secondary selection or a highlight. A buffer has one of each, and they can overlap.");
  NEW(editor); FlText.OpenTextEditor(editor, 10, 10, 460, 170, "");
  editor.SetBuffer(buffer);
  editor.SetWrapMode(FlText.WrapAtBounds, 0);
  Button(toSecondary, 10, "To &secondary", ToSecondary);
  Button(toHighlight, 125, "To &highlight", ToHighlight);
  Button(replace, 240, "&Replace", Replace);
  Button(clear, 360, "&Clear", Clear);
  Status(primaryBox, 225); Status(secondaryBox, 247); Status(highlightBox, 269);
  win.End;
  win.SetResizable(editor);
  buffer.Modified(0, 0, 0, 0);
  win.ShowArgs;
  Fl.Run
END Selections.
