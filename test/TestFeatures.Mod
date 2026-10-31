MODULE TestFeatures; (* Fl.Has, against what fl_config.h says *)

IMPORT Fl, Check, Probe;

PROCEDURE Same(feature: INTEGER; label: ARRAY OF CHAR);
BEGIN Check.Check(Fl.Has(feature) = Probe.Configured(feature), label)
END Same;

BEGIN
  Same(Fl.Svg, "Svg is fl_config.h's");
  Check.Check(Fl.Has(Fl.Wayland) # Fl.Has(Fl.X11), "the display is Wayland's or X11's");
  Check.Check(~Fl.Has(Fl.Wayland) OR Probe.Configured(Fl.Wayland), "Wayland only in an FLTK with it");
  Check.Check(~Fl.Has(Fl.X11) OR Probe.Configured(Fl.X11), "and X11");
  Check.Check(~Fl.Has(3) & ~Fl.Has(-1), "a feature no one knows isn't there");
  Check.Summary
END TestFeatures.
