MODULE TestGluConstants; (* pofltk's constants are FLTK's *)

(* Written by tools/gen-constants.py: one check per constant, against the
   value the installed FLTK's headers give (CGluConstants). A failure means
   FLTK's headers changed: run the script again, and see what moved. *)

IMPORT SYSTEM, Out, FlGlu, Check, CGluConstants;

VAR checked, wrong: INTEGER;

PROCEDURE Same(oberon: INTEGER; c-: ARRAY OF CHAR);
  VAR v: INTEGER;
BEGIN
  INC(checked);
  IF ~CGluConstants.Value(c, v) OR (v # oberon) THEN
    INC(wrong); Out.String("  differs from C: "); Out.String(c); Out.Ln
  END
END Same;

BEGIN
  checked := 0; wrong := 0;
  Same(FlGlu.Fill, "GLU_FILL");
  Same(FlGlu.Line, "GLU_LINE");
  Same(FlGlu.Silhouette, "GLU_SILHOUETTE");
  Same(FlGlu.Point, "GLU_POINT");
  Same(FlGlu.NormalsNone, "GLU_NONE");
  Same(FlGlu.NormalsFlat, "GLU_FLAT");
  Same(FlGlu.NormalsSmooth, "GLU_SMOOTH");
  Same(FlGlu.Outside, "GLU_OUTSIDE");
  Same(FlGlu.Inside, "GLU_INSIDE");
  Check.Check((wrong = 0) & (checked = 9), "each of 9 constants and values is FLTK's");
  Check.Summary
END TestGluConstants.
