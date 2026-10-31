MODULE Boxtype; (* FLTK's test/boxtype.cxx: every box and frame type, on a bright background *)

(* FLTK's BoxGroup draws an outline for debugging when it is turned on,
   and otherwise is a group with no box, as here. A scheme is chosen with
   the command line's -s, as FLTK's is, or with the choice. *)

IMPORT Fl, FlButtons, FlMenus, Strings;

CONST W = 200; H = 50; rows = 14;

VAR
  win: Fl.DoubleWindow;
  bg: Fl.Group;
  choice: FlMenus.SchemeChoice;
  title, name: ARRAY 100 OF CHAR;
  n, i: INTEGER;
  ok: BOOLEAN;

PROCEDURE Bt(name: ARRAY OF CHAR; type: INTEGER);
  VAR b: FlButtons.Button;
BEGIN
  NEW(b); FlButtons.OpenButton(b, n MOD 4 * W + 10, n DIV 4 * H + 10, W - 20, H - 20, name);
  INC(n);
  b.SetBoxType(type);
  b.SetLabelSize(11)
END Bt;

BEGIN
  NEW(win); Fl.OpenDoubleWindow(win, 4 * W, rows * H, "");
  win.SetBoxType(Fl.FlatBox);
  i := 1; ok := Fl.ParseArgs(NIL, i);
  Fl.GetSystemColors;
  win.SetColor(Fl.RGB(51, 173, 255));  (* light blue, to show boxes from frames *)

  (* the window's title shows the scheme *)
  Fl.GetScheme(name);
  ok := Fl.SetScheme(name);
  IF name = "" THEN name := "none" END;
  title := "FLTK boxtypes: scheme = '"; Strings.Append(name, title); Strings.Append("'", title);
  win.SetLabel(title);

  NEW(bg); Fl.OpenGroup(bg, 0, 0, win.W(), win.H(), "");
  bg.SetBoxType(Fl.NoBox);

  n := 0;
  Bt("FL_NO_BOX", Fl.NoBox);
  Bt("FL_FLAT_BOX", Fl.FlatBox);
  n := n + 2;
  Bt("FL_UP_BOX", Fl.UpBox);
  Bt("FL_DOWN_BOX", Fl.DownBox);
  Bt("FL_UP_FRAME", Fl.UpFrame);
  Bt("FL_DOWN_FRAME", Fl.DownFrame);
  Bt("FL_THIN_UP_BOX", Fl.ThinUpBox);
  Bt("FL_THIN_DOWN_BOX", Fl.ThinDownBox);
  Bt("FL_THIN_UP_FRAME", Fl.ThinUpFrame);
  Bt("FL_THIN_DOWN_FRAME", Fl.ThinDownFrame);
  Bt("FL_ENGRAVED_BOX", Fl.EngravedBox);
  Bt("FL_EMBOSSED_BOX", Fl.EmbossedBox);
  Bt("FL_ENGRAVED_FRAME", Fl.EngravedFrame);
  Bt("FL_EMBOSSED_FRAME", Fl.EmbossedFrame);
  Bt("FL_BORDER_BOX", Fl.BorderBox);
  Bt("FL_SHADOW_BOX", Fl.ShadowBox);
  Bt("FL_BORDER_FRAME", Fl.BorderFrame);
  Bt("FL_SHADOW_FRAME", Fl.ShadowFrame);
  Bt("FL_ROUNDED_BOX", Fl.RoundedBox);
  Bt("FL_RSHADOW_BOX", Fl.RShadowBox);
  Bt("FL_ROUNDED_FRAME", Fl.RoundedFrame);
  Bt("FL_RFLAT_BOX", Fl.RFlatBox);
  Bt("FL_OVAL_BOX", Fl.OvalBox);
  Bt("FL_OSHADOW_BOX", Fl.OShadowBox);
  Bt("FL_OVAL_FRAME", Fl.OvalFrame);
  Bt("FL_OFLAT_BOX", Fl.OFlatBox);
  Bt("FL_ROUND_UP_BOX", Fl.RoundUpBox);
  Bt("FL_ROUND_DOWN_BOX", Fl.RoundDownBox);
  Bt("FL_DIAMOND_UP_BOX", Fl.DiamondUpBox);
  Bt("FL_DIAMOND_DOWN_BOX", Fl.DiamondDownBox);
  Bt("FL_PLASTIC_UP_BOX", Fl.PlasticUpBox);
  Bt("FL_PLASTIC_DOWN_BOX", Fl.PlasticDownBox);
  Bt("FL_PLASTIC_UP_FRAME", Fl.PlasticUpFrame);
  Bt("FL_PLASTIC_DOWN_FRAME", Fl.PlasticDownFrame);
  Bt("FL_PLASTIC_THIN_UP_BOX", Fl.PlasticThinUpBox);
  Bt("FL_PLASTIC_THIN_DOWN_BOX", Fl.PlasticThinDownBox);
  n := n + 2;
  Bt("FL_PLASTIC_ROUND_UP_BOX", Fl.PlasticRoundUpBox);
  Bt("FL_PLASTIC_ROUND_DOWN_BOX", Fl.PlasticRoundDownBox);
  n := n + 2;
  Bt("FL_GTK_UP_BOX", Fl.GtkUpBox);
  Bt("FL_GTK_DOWN_BOX", Fl.GtkDownBox);
  Bt("FL_GTK_UP_FRAME", Fl.GtkUpFrame);
  Bt("FL_GTK_DOWN_FRAME", Fl.GtkDownFrame);
  Bt("FL_GTK_THIN_UP_BOX", Fl.GtkThinUpBox);
  Bt("FL_GTK_THIN_DOWN_BOX", Fl.GtkThinDownBox);
  Bt("FL_GTK_THIN_UP_FRAME", Fl.GtkThinUpFrame);
  Bt("FL_GTK_THIN_DOWN_FRAME", Fl.GtkThinDownFrame);
  Bt("FL_GTK_ROUND_UP_BOX", Fl.GtkRoundUpBox);
  Bt("FL_GTK_ROUND_DOWN_BOX", Fl.GtkRoundDownBox);
  bg.End;
  win.SetResizable(win);
  NEW(choice); FlMenus.OpenSchemeChoice(choice, 610, 10, 150, 30, "Scheme:");
  win.End;
  win.ShowArgs;
  Fl.Run
END Boxtype.
