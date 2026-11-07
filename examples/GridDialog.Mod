MODULE GridDialog; (* FLTK's test/grid_dialog.cxx in Oberon-2 *)

(* A dialog like fl_ask's, laid out by a grid of two rows and Buttons + 2
   columns: an icon at the top left, a message beside it, wrapped to the
   window's width, across the rest of the top row, and the buttons in
   the bottom row's right hand columns. Column 1 is the one that widens,
   and holds no button. "Quit" ends the program and "Copy" copies the
   message; each button prints its number and label. *)

IMPORT Out, Fl, FlButtons, FlLayout;

CONST
  Rows = 2;
  Buttons = 4; (* FLTK's default; 1 to 5 to test *)
  Cols = Buttons + 2;
  ButtonH = 25;
  IconW = 60;
  IconH = 70;
  Margin = 10;
  Gap = 8;

VAR
  win: Fl.DoubleWindow;
  grid: FlLayout.Grid;
  icon, messageBox: Fl.Box;
  buttons: ARRAY Buttons OF FlButtons.Button;
  labels, tooltips: ARRAY 5, 64 OF CHAR;
  buttonW: ARRAY 5 OF INTEGER;
  colWeights, rowWeights: ARRAY 7 OF INTEGER;
  minW, minH, i: INTEGER;

PROCEDURE ButtonCallback(w: Fl.Widget);
  VAR val: INTEGER; label: ARRAY 64 OF CHAR; text: ARRAY 256 OF CHAR; win: Fl.Window;
BEGIN
  val := 0; WHILE buttons[val] # w DO INC(val) END;
  w.GetLabel(label);
  Out.String("Button "); Out.Int(val, 0); Out.String(": '"); Out.String(label); Out.Char("'"); Out.Ln;
  CASE val OF
    0: win := w.Window(); win.Hide
  | 1: messageBox.GetLabel(text); Fl.Copy(text, Fl.Clipboard);
      Out.String("Message copied to clipboard."); Out.Ln
  ELSE
  END
END ButtonCallback;

BEGIN
  labels[0] := "Quit"; labels[1] := "Copy"; labels[2] := "Cancel";
  labels[3] := "OK"; labels[4] := "More ...";
  tooltips[0] := "Quit this program";
  tooltips[1] := "Copy the message text to the clipboard";
  tooltips[2] := "Cancel - does nothing";
  tooltips[3] := "OK - does nothing";
  tooltips[4] := "More buttons could be added here";
  (* the buttons' widths, left to right, to save measuring their text *)
  buttonW[0] := 50; buttonW[1] := 50; buttonW[2] := 70; buttonW[3] := 40; buttonW[4] := 100;
  FOR i := 0 TO 6 DO colWeights[i] := 0; rowWeights[i] := 0 END;
  colWeights[1] := 100; rowWeights[0] := 100;

  minW := IconW + 2 * Margin + (Buttons + 1) * Gap;
  minH := IconH + 10 + 2 * Margin + Gap + ButtonH;
  FOR i := 0 TO Buttons - 1 DO INC(minW, buttonW[i]) END;

  NEW(win); Fl.OpenDoubleWindow(win, minW, minH, "Fl_Grid Based Dialog");
  NEW(grid); FlLayout.OpenGrid(grid, 0, 0, win.W(), win.H(), "");
  grid.SetMargins(Margin, Margin, Margin, Margin); grid.SetGap(Gap, Gap);
  grid.SetLayout(Rows, Cols);
  grid.SetColor(Fl.White);
  grid.SetTooltip('Resize the window to see this dialog "in action"');

  (* child 0: the icon, or image, of fixed size *)
  NEW(icon); Fl.OpenBox(icon, 0, 0, IconW, IconH, "ICON");
  grid.PlaceSpan(icon, 0, 0, 1, 1, FlLayout.GridTop);
  icon.SetBoxType(Fl.ThinUpBox);
  icon.SetColor(Fl.RGB(0DDH, 0FFH, 0FFH));
  icon.SetAlign(Fl.AlignCenter + Fl.AlignInside + Fl.AlignClip);
  icon.SetTooltip("This could also be a full Fl_Image or subclass thereof");

  (* child 1: the message *)
  NEW(messageBox); Fl.OpenBox(messageBox, 0, 0, 0, 0, "");
  grid.PlaceSpan(messageBox, 0, 1, 1, Buttons + 1, FlLayout.GridFill);
  messageBox.SetLabel("This is a long message in an Fl_Grid based dialog that may wrap over more than one line. Resize the window to see how it (un)wraps.");
  messageBox.SetAlign(Fl.AlignTop + Fl.AlignInside + Fl.AlignWrap);
  messageBox.SetTooltip("The text in this box can be copied to the clipboard");

  (* children 2 on: the buttons, left to right for the Tab order *)
  FOR i := 0 TO Buttons - 1 DO
    NEW(buttons[i]); FlButtons.OpenButton(buttons[i], 0, 0, buttonW[i], ButtonH, labels[i]);
    grid.Place(buttons[i], 1, i + 2, FlLayout.GridFill);
    buttons[i].action := ButtonCallback;
    buttons[i].SetTooltip(tooltips[i])
  END;
  grid.End;

  (* the weights for resizing *)
  FOR i := 0 TO Rows - 1 DO grid.SetRowWeight(i, rowWeights[i]) END;
  FOR i := 0 TO Cols - 1 DO grid.SetColWeight(i, colWeights[i]) END;

  win.End;
  win.SetResizable(grid);
  win.SizeRange(minW, minH, 3 * minW, minH + 50);
  win.ShowArgs;
  Fl.Run;
  win.Delete
END GridDialog.
