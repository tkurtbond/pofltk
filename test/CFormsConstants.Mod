MODULE CFormsConstants; (* FLTK's values of C expressions, for TestFormsConstants *)

(* Written by tools/gen-constants.py; its C++ part is CFormsConstants.cpp. *)

IMPORT SYSTEM;

PROCEDURE ["C", "ofltest_formsconstant"] CConstant(name: ARRAY OF CHAR; VAR value: SYSTEM.INT32): SYSTEM.INT32;

(* The value of the C expression name, in value; FALSE if there is none. *)
PROCEDURE Value*(name-: ARRAY OF CHAR; VAR value: INTEGER): BOOLEAN;
  VAR v: SYSTEM.INT32;
BEGIN
  v := 0;
  IF CConstant(name, v) # 0 THEN value := v; RETURN TRUE END;
  RETURN FALSE
END Value;

END CFormsConstants.
