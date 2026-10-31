MODULE HaltCairoClosed; (* a closed pattern halts with Fl.ClosedResource, 73 *)

IMPORT FlCairo;

VAR p: FlCairo.Pattern;

BEGIN
  p := FlCairo.LinearPattern(0, 0, 1, 0);
  p.Close;
  p.AddColorStopRGB(0, 1, 0, 0)
END HaltCairoClosed.
