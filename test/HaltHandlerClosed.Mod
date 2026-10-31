MODULE HaltHandlerClosed; (* A handler answering with a closed image halts with Fl.ClosedResource, 73 *)
IMPORT FlImages;
VAR s: FlImages.Shared; ok: BOOLEAN;

PROCEDURE Answer(name-, header-: ARRAY OF CHAR; n: INTEGER): FlImages.Image;
  VAR i: FlImages.Image; bits: ARRAY 3 OF CHAR;
BEGIN
  NEW(i); FlImages.OpenRGB(i, bits, 1, 1, 3, 0);
  i.Close;
  RETURN i
END Answer;

BEGIN
  FlImages.AddHandler(Answer);
  NEW(s); ok := FlImages.GetShared(s, "images/rb.rbx", 0, 0)
END HaltHandlerClosed.
