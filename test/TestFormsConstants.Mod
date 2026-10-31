MODULE TestFormsConstants; (* pofltk's constants are FLTK's *)

(* Written by tools/gen-constants.py: one check per constant, against the
   value the installed FLTK's headers give (CFormsConstants). A failure means
   FLTK's headers changed: run the script again, and see what moved. *)

IMPORT SYSTEM, Out, FlForms, Check, CFormsConstants;

VAR checked, wrong: INTEGER;

PROCEDURE Same(oberon: INTEGER; c-: ARRAY OF CHAR);
  VAR v: INTEGER;
BEGIN
  INC(checked);
  IF ~CFormsConstants.Value(c, v) OR (v # oberon) THEN
    INC(wrong); Out.String("  differs from C: "); Out.String(c); Out.Ln
  END
END Same;

BEGIN
  checked := 0; wrong := 0;
  Same(FlForms.NormalTimer, "FL_NORMAL_TIMER");
  Same(FlForms.ValueTimer, "FL_VALUE_TIMER");
  Same(FlForms.HiddenTimer, "FL_HIDDEN_TIMER");
  Same(FlForms.NormalFree, "FL_NORMAL_FREE");
  Same(FlForms.SleepingFree, "FL_SLEEPING_FREE");
  Same(FlForms.InputFree, "FL_INPUT_FREE");
  Same(FlForms.ContinuousFree, "FL_CONTINUOUS_FREE");
  Same(FlForms.AllFree, "FL_ALL_FREE");
  Same(FlForms.FreeDraw, "FL_DRAW");
  Same(FlForms.FreeStep, "FL_STEP");
  Check.Check((wrong = 0) & (checked = 10), "each of 10 constants and values is FLTK's");
  Check.Summary
END TestFormsConstants.
