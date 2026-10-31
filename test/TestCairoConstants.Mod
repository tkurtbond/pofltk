MODULE TestCairoConstants; (* pofltk's constants are FLTK's *)

(* Written by tools/gen-constants.py: one check per constant, against the
   value the installed FLTK's headers give (CCairoConstants). A failure means
   FLTK's headers changed: run the script again, and see what moved. *)

IMPORT SYSTEM, Out, FlCairo, Check, CCairoConstants;

VAR checked, wrong: INTEGER;

PROCEDURE Same(oberon: INTEGER; c-: ARRAY OF CHAR);
  VAR v: INTEGER;
BEGIN
  INC(checked);
  IF ~CCairoConstants.Value(c, v) OR (v # oberon) THEN
    INC(wrong); Out.String("  differs from C: "); Out.String(c); Out.Ln
  END
END Same;

BEGIN
  checked := 0; wrong := 0;
  Same(FlCairo.SlantNormal, "CAIRO_FONT_SLANT_NORMAL");
  Same(FlCairo.SlantItalic, "CAIRO_FONT_SLANT_ITALIC");
  Same(FlCairo.SlantOblique, "CAIRO_FONT_SLANT_OBLIQUE");
  Same(FlCairo.WeightNormal, "CAIRO_FONT_WEIGHT_NORMAL");
  Same(FlCairo.WeightBold, "CAIRO_FONT_WEIGHT_BOLD");
  Same(FlCairo.AntialiasDefault, "CAIRO_ANTIALIAS_DEFAULT");
  Same(FlCairo.AntialiasNone, "CAIRO_ANTIALIAS_NONE");
  Same(FlCairo.AntialiasGray, "CAIRO_ANTIALIAS_GRAY");
  Same(FlCairo.AntialiasSubpixel, "CAIRO_ANTIALIAS_SUBPIXEL");
  Same(FlCairo.AntialiasFast, "CAIRO_ANTIALIAS_FAST");
  Same(FlCairo.AntialiasGood, "CAIRO_ANTIALIAS_GOOD");
  Same(FlCairo.AntialiasBest, "CAIRO_ANTIALIAS_BEST");
  Same(FlCairo.ExtendNone, "CAIRO_EXTEND_NONE");
  Same(FlCairo.ExtendRepeat, "CAIRO_EXTEND_REPEAT");
  Same(FlCairo.ExtendReflect, "CAIRO_EXTEND_REFLECT");
  Same(FlCairo.ExtendPad, "CAIRO_EXTEND_PAD");
  Check.Check((wrong = 0) & (checked = 16), "each of 16 constants and values is FLTK's");
  Check.Summary
END TestCairoConstants.
