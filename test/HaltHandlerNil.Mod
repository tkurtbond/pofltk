MODULE HaltHandlerNil; (* AddHandler of NIL halts with Fl.NilArgument, 72 *)
IMPORT FlImages;
BEGIN
  FlImages.AddHandler(NIL)
END HaltHandlerNil.
