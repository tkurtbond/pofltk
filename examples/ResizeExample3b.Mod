MODULE ResizeExample3b; (* FLTK's test/resize-example3b.cxx in Oberon-2 *)

(* A dialog, an icon, a message and a button in a group, shown at its
   first size and resized horizontally, vertically and both ways, with
   arrows showing the widths and heights before and after. The message is
   the group's resizable, so it grows, and the icon and button stay
   the same size. *)

IMPORT Fl, FlButtons, ResizeArrows;

CONST
  TLx = 35; TRx = 270; TGx = 470; TLw = 200; TGw = 120; TAw = 35;
  TLy = 35; BLy = 160; LGy = 250; TLh = 90; LGh = 90; LAh = 35;
  Ww = 590; Wh = 340;

VAR
  window: Fl.DoubleWindow;
  resizables: Fl.Group;

(* The dialog, and in key its resizable. *)
PROCEDURE ResizeDialog(x, y, w, h: INTEGER; label-: ARRAY OF CHAR; VAR key: Fl.Box): Fl.Group;
VAR g: Fl.Group; icon, message: Fl.Box; button: FlButtons.Button;
BEGIN
  NEW(g); Fl.OpenGroup(g, x, y, w, h, label);
  g.SetAlign(Fl.AlignTop + Fl.AlignLeft);
  g.SetBoxType(Fl.UpBox);
  NEW(icon); Fl.OpenBox(icon, x + 10, y + 10, 30, 30, "!");
  icon.SetBoxType(Fl.DownBox);
  NEW(message); Fl.OpenBox(message, x + 50, y + 10, 140, 30, "Out of Memory");
  message.SetBoxType(Fl.DownBox);
  message.SetColor(Fl.Yellow);
  NEW(button); FlButtons.OpenButton(button, x + 140, y + 50, 50, 30, "Darn!");
  g.End;
  key := message;
  g.SetResizable(key);
  RETURN g
END ResizeDialog;

(* A group of no box for an arrow. *)
PROCEDURE ArrowGroup(x, y, w, h: INTEGER): Fl.Group;
VAR g: Fl.Group;
BEGIN
  NEW(g); Fl.OpenGroup(g, x, y, w, h, "");
  g.SetBoxType(Fl.NoBox);
  g.SetColor(Fl.White);
  RETURN g
END ArrowGroup;

PROCEDURE Harrow(x, y, w, h: INTEGER; label-: ARRAY OF CHAR): ResizeArrows.Harrow;
VAR a: ResizeArrows.Harrow;
BEGIN NEW(a); ResizeArrows.OpenHarrow(a, x, y, w, h, label); RETURN a
END Harrow;

PROCEDURE Varrow(x, y, w, h: INTEGER; label-: ARRAY OF CHAR): ResizeArrows.Varrow;
VAR a: ResizeArrows.Varrow;
BEGIN NEW(a); ResizeArrows.OpenVarrow(a, x, y, w, h, label); RETURN a
END Varrow;

PROCEDURE Resizables(x, y, w, h: INTEGER): Fl.Group;
VAR r, tl, br, g: Fl.Group; tlk, trk, blk, brk: Fl.Box;
BEGIN
  NEW(r); Fl.OpenGroup(r, x, y, w, h, "");
  r.SetBoxType(Fl.UpBox);
  r.SetColor(Fl.White);
  tl := ResizeDialog(x + TLx, y + TLy, TLw, TLh, "Original Size", tlk);
  tl.SetResizable(NIL);
  g := ResizeDialog(x + TRx, y + TLy, TLw, TLh, "Horizontally Resized", trk);
  g := ResizeDialog(x + TLx, y + BLy, TLw, TLh, "Vertically Resized", blk);
  br := ResizeDialog(x + TRx, y + BLy, TLw, TLh, "Horizontally and Vertically Resized", brk);

  g := ArrowGroup(x + TLx, y + LGy, TLw, LGh);
  g.SetResizable(Harrow(blk.X(), g.Y(), blk.W(), LAh, "Initial|width"));
  g.End;
  g := ArrowGroup(x + TRx, y + LGy, TLw, LGh);
  g.SetResizable(Harrow(brk.X(), g.Y(), blk.W(), LAh, "Resized|width"));
  g.End;
  g := ArrowGroup(x + TGx, y + TLy, TGw, TLh);
  g.SetResizable(Varrow(g.X(), trk.Y(), TAw, trk.H(), "Initial|height"));
  g.End;
  g := ArrowGroup(x + TGx, y + BLy, TGw, TLh);
  g.SetResizable(Varrow(g.X(), brk.Y(), TAw, brk.H(), "Resized|height"));
  g.End;

  r.SetResizable(br);
  r.End;
  RETURN r
END Resizables;

BEGIN
  NEW(window); Fl.OpenDoubleWindow(window, Ww, Wh, "resize-example3b");
  window.SetColor(Fl.White);
  resizables := Resizables(0, 0, Ww, Wh);
  window.End;
  window.SetResizable(resizables);
  window.SizeRange(Ww, Wh, 0, 0);
  window.ShowArgs;
  window.Size(Ww + 50, Wh + 35);
  Fl.SetOption(Fl.OptionVisibleFocus, FALSE); (* no focus box *)
  Fl.Run
END ResizeExample3b.
