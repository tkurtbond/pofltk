MODULE HaltCairoExtend; (* cairo takes any number as an extend: halts with Fl.IndexOutOfRange, 74 *)

IMPORT FlCairo;

VAR p: FlCairo.Pattern;

BEGIN
  p := FlCairo.LinearPattern(0, 0, 1, 0);
  p.SetExtend(FlCairo.ExtendPad + 1)
END HaltCairoExtend.
