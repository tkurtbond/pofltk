MODULE CairoTest; (* FLTK's test/cairo_test.cxx: three shiny buttons and a title, with cairo *)

IMPORT Fl, FlCairo;

CONST DefWidth = 0.03D0;

TYPE
  Win = POINTER TO RECORD (FlCairo.CairoWindowDesc) END;

VAR
  window: Win;

PROCEDURE CenteredText(c: FlCairo.Context; x0, y0, rectWidth, rectHeight: LONGREAL; text-: ARRAY OF CHAR);
  VAR e: FlCairo.TextExtents; x, y: LONGREAL;
BEGIN
  c.SelectFontFace("Sans", FlCairo.SlantOblique, FlCairo.WeightBold);
  c.SetSourceRGBA(0.9D0, 0.9D0, 0.4D0, 0.6D0);
  c.GetTextExtents(text, e);
  x := e.width / 2 + e.xBearing;
  y := e.height / 2 + e.yBearing;
  c.MoveTo(x0 + rectWidth / 2 - x, y0 + rectHeight / 2 - y);
  c.TextPath(text);
  c.FillPreserve;
  c.SetSourceRGBA(0, 0, 0, 1);
  c.SetLineWidth(0.004D0);
  c.Stroke;
  c.SetLineWidth(DefWidth)
END CenteredText;

(* A button with a radial gradient, its corners rounded by curves. *)
PROCEDURE RoundButton(c: FlCairo.Context; x0, y0, rectWidth, rectHeight, radius, r, g, bl: LONGREAL);
  VAR x1, y1: LONGREAL; p: FlCairo.Pattern;
BEGIN
  x1 := x0 + rectWidth; y1 := y0 + rectHeight;
  IF (rectWidth = 0) OR (rectHeight = 0) THEN RETURN END;
  IF rectWidth / 2 < radius THEN
    IF rectHeight / 2 < radius THEN
      c.MoveTo(x0, (y0 + y1) / 2);
      c.CurveTo(x0, y0, x0, y0, (x0 + x1) / 2, y0);
      c.CurveTo(x1, y0, x1, y0, x1, (y0 + y1) / 2);
      c.CurveTo(x1, y1, x1, y1, (x1 + x0) / 2, y1);
      c.CurveTo(x0, y1, x0, y1, x0, (y0 + y1) / 2)
    ELSE
      c.MoveTo(x0, y0 + radius);
      c.CurveTo(x0, y0, x0, y0, (x0 + x1) / 2, y0);
      c.CurveTo(x1, y0, x1, y0, x1, y0 + radius);
      c.LineTo(x1, y1 - radius);
      c.CurveTo(x1, y1, x1, y1, (x1 + x0) / 2, y1);
      c.CurveTo(x0, y1, x0, y1, x0, y1 - radius)
    END
  ELSIF rectHeight / 2 < radius THEN
    c.MoveTo(x0, (y0 + y1) / 2);
    c.CurveTo(x0, y0, x0, y0, x0 + radius, y0);
    c.LineTo(x1 - radius, y0);
    c.CurveTo(x1, y0, x1, y0, x1, (y0 + y1) / 2);
    c.CurveTo(x1, y1, x1, y1, x1 - radius, y1);
    c.LineTo(x0 + radius, y1);
    c.CurveTo(x0, y1, x0, y1, x0, (y0 + y1) / 2)
  ELSE
    c.MoveTo(x0, y0 + radius);
    c.CurveTo(x0, y0, x0, y0, x0 + radius, y0);
    c.LineTo(x1 - radius, y0);
    c.CurveTo(x1, y0, x1, y0, x1, y0 + radius);
    c.LineTo(x1, y1 - radius);
    c.CurveTo(x1, y1, x1, y1, x1 - radius, y1);
    c.LineTo(x0 + radius, y1);
    c.CurveTo(x0, y1, x0, y1, x0, y1 - radius)
  END;
  c.ClosePath;

  p := FlCairo.RadialPattern(0.25D0, 0.24D0, 0.11D0, 0.24D0, 0.14D0, 0.35D0);
  p.SetExtend(FlCairo.ExtendReflect);
  p.AddColorStopRGBA(1.0D0, r, g, bl, 1);
  p.AddColorStopRGBA(0.0D0, 1, 1, 1, 1);
  c.SetSource(p);
  c.FillPreserve;
  p.Close;

  c.SetSourceRGBA(0, 0, 0.5D0, 0.3D0);
  c.Stroke;
  c.SetFontSize(0.075D0);
  CenteredText(c, x0, y0, rectWidth, rectHeight, "FLTK loves Cairo!")
END RoundButton;

PROCEDURE (w: Win) DrawCairo*(c: FlCairo.Context);
BEGIN
  c.SetLineWidth(DefWidth);
  c.Scale(w.W(), w.H());
  RoundButton(c, 0.1D0, 0.1D0, 0.8D0, 0.2D0, 0.4D0, 1, 0, 0);
  RoundButton(c, 0.1D0, 0.4D0, 0.8D0, 0.2D0, 0.4D0, 0, 1, 0);
  RoundButton(c, 0.1D0, 0.7D0, 0.8D0, 0.2D0, 0.4D0, 0, 0, 1)
END DrawCairo;

BEGIN
  NEW(window);
  FlCairo.OpenCairoWindow(window, 350, 350, "FLTK loves Cairo");
  window.SetResizable(window);
  window.SetColor(Fl.White);
  window.End;
  window.Show;
  Fl.Run
END CairoTest.
