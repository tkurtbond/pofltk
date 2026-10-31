MODULE Plugins; (* Two plugins, found by their class and run: the program knows only the class *)

(* A Plugin is an object of the program's own type, here a Painter, opened
   under a class and a name. Whatever opened one, the rest of the program
   finds it through a PluginManager of the class, by number or by name, so
   the browser and the canvas know nothing of Circle and Cross. These two
   are opened here. A library loaded by FlPreferences.Load would open its
   own the same way (FlPreferences' comment says how). *)

IMPORT Fl, FlBrowsers, FlDraw, FlPreferences;

CONST
  class = "painter";

TYPE
  Painter = POINTER TO PainterDesc;
  PainterDesc = RECORD (FlPreferences.PluginDesc) END;

  Circle = POINTER TO RECORD (PainterDesc) END;
  Cross = POINTER TO RECORD (PainterDesc) END;

  Canvas = POINTER TO RECORD (Fl.BoxDesc)
    painter: Painter
  END;

VAR
  win: Fl.DoubleWindow;
  list: FlBrowsers.HoldBrowser;
  canvas: Canvas;
  plugins: FlPreferences.PluginManager;
  circle: Circle;
  cross: Cross;

PROCEDURE (p: Painter) Paint(x, y, w, h: INTEGER);
END Paint;

PROCEDURE (p: Circle) Paint(x, y, w, h: INTEGER);
BEGIN
  FlDraw.SetColor(Fl.Red);
  FlDraw.Pie(x + 10, y + 10, w - 20, h - 20, 0.0D0, 360.0D0)
END Paint;

PROCEDURE (p: Cross) Paint(x, y, w, h: INTEGER);
BEGIN
  FlDraw.SetColor(Fl.Blue);
  FlDraw.Line(x + 10, y + 10, x + w - 11, y + h - 11);
  FlDraw.Line(x + 10, y + h - 11, x + w - 11, y + 10)
END Paint;

PROCEDURE (c: Canvas) Draw*;
BEGIN
  FlDraw.SetColor(Fl.White); FlDraw.RectF(c.X(), c.Y(), c.W(), c.H());
  IF c.painter # NIL THEN c.painter.Paint(c.X(), c.Y(), c.W(), c.H()) END
END Draw;

(* The plugin of the line chosen, whichever it is. *)
PROCEDURE Chosen(w: Fl.Widget);
  VAR p: FlPreferences.Plugin;
BEGIN
  IF list.Value() = 0 THEN canvas.painter := NIL
  ELSE p := plugins.PluginAt(list.Value() - 1); canvas.painter := p(Painter)
  END;
  canvas.Redraw
END Chosen;

PROCEDURE ListPlugins;
  VAR i: INTEGER; name: ARRAY 64 OF CHAR;
BEGIN
  FOR i := 0 TO plugins.Plugins() - 1 DO
    plugins.PluginName(i, name);
    list.Add(name)
  END
END ListPlugins;

BEGIN
  NEW(circle); FlPreferences.OpenPlugin(circle, class, "circle");
  NEW(cross); FlPreferences.OpenPlugin(cross, class, "cross");
  NEW(plugins); FlPreferences.OpenPluginManager(plugins, class);

  NEW(win); Fl.OpenDoubleWindow(win, 340, 200, "Plugins");
  NEW(list); FlBrowsers.OpenHoldBrowser(list, 10, 10, 120, 180, "");
  list.action := Chosen;
  ListPlugins;
  NEW(canvas); Fl.OpenBox(canvas, 140, 10, 190, 180, "");
  canvas.painter := NIL;
  win.SetResizable(canvas);
  win.End;
  win.ShowArgs;
  Fl.Run
END Plugins.
