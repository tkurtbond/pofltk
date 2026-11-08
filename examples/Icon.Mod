MODULE Icon; (* FLTK's test/icon.cxx in Oberon-2 *)

(* A window's icon, a square of one color the choice picks, or none.
   The window system shows it in the title bar, the task bar and the
   like; Wayland has none. *)

IMPORT Fl, FlMenus, FlImages;

VAR
  win: Fl.DoubleWindow;
  choice: FlMenus.Choice;
  colors: ARRAY 4 OF INTEGER;
  i: INTEGER;

(* Sets the window's icon to the color of the item picked, or none. *)
PROCEDURE ChoiceCB(w: Fl.Widget);
  VAR c: INTEGER; buffer: ARRAY 32 * 32 * 3 OF CHAR; icon: FlImages.Image;
BEGIN
  c := colors[choice.Value()];
  IF c # 0 THEN
    (* the window copies its icon, so this one can go *)
    NEW(icon); FlImages.OpenRGB(icon, buffer, 32, 32, 3, 0);
    icon.ColorAverage(c, 0.0);
    FlImages.SetIcon(win, icon);
    icon.Close
  ELSE
    FlImages.SetIcon(win, NIL)
  END
END ChoiceCB;

BEGIN
  NEW(win); Fl.OpenDoubleWindow(win, 400, 300, "FLTK Window Icon Test");
  NEW(choice); FlMenus.OpenChoice(choice, 120, 100, 200, 25, "Window icon:");
  colors[0] := 0; colors[1] := Fl.Red; colors[2] := Fl.Green; colors[3] := Fl.Blue;
  i := choice.Add("None", 0, {}, ChoiceCB, {});
  i := choice.Add("Red", 0, {}, ChoiceCB, {});
  i := choice.Add("Green", 0, {}, ChoiceCB, {});
  i := choice.Add("Blue", 0, {}, ChoiceCB, {});
  IF choice.SetValue(0) THEN END;  (* FLTK's menu() sets the first item *)
  choice.action := ChoiceCB;
  choice.SetWhen(Fl.WhenRelease + Fl.WhenNotChanged);
  choice.SetTooltip("Sets the application icon for window manager. Affects e.g. titlebar, toolbar, Dock, Alt-Tab..");
  win.End;
  win.ShowArgs;
  choice.DoCallback;  (* make default take effect *)
  Fl.Run
END Icon.
