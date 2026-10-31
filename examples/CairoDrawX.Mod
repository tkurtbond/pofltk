MODULE CairoDrawX; (* FLTK's examples/cairo-draw-x.cxx: an X across a window, with cairo *)

IMPORT Fl, FlCairo;

TYPE
  Win = POINTER TO RECORD (FlCairo.CairoWindowDesc) END;

VAR
  window: Win;

PROCEDURE (w: Win) DrawCairo*(c: FlCairo.Context);
  VAR xmax, ymax: LONGREAL;
BEGIN
  xmax := w.W() - 1; ymax := w.H() - 1;
  c.SetAntialias(FlCairo.AntialiasDefault);
  c.SetLineWidth(1);
  c.SetSourceRGB(1, 0.5D0, 0);
  c.MoveTo(0, 0); c.LineTo(xmax, ymax);
  c.MoveTo(0, ymax); c.LineTo(xmax, 0);
  c.Stroke
END DrawCairo;

BEGIN
  NEW(window);
  FlCairo.OpenCairoWindow(window, 300, 300, "Cairo Draw 'X'");
  window.SetColor(Fl.Black);
  window.SizeRange(50, 50, -1, -1);
  window.SetResizable(window);
  window.End;
  window.Show;
  Fl.Run
END CairoDrawX.
