MODULE BreakCairo; (* For TestPrint: a PDF surface Cairo can't make, and the next file descriptor *)

(* Its C++ part is BreakCairo.cpp, which replaces Cairo's
   cairo_pdf_surface_create_for_stream in the program that imports this. *)

IMPORT SYSTEM;

PROCEDURE ["C", "ofltest_break_pdf"] CBreakPDF(on: SYSTEM.INT32);
PROCEDURE ["C", "ofltest_next_fd"] CNextFd(): SYSTEM.INT32;

(* Whether Cairo fails to make a PDF surface, as out of memory. *)
PROCEDURE BreakPDF*(on: BOOLEAN);
BEGIN IF on THEN CBreakPDF(1) ELSE CBreakPDF(0) END
END BreakPDF;

(* The lowest file descriptor free, which a file left open raises. *)
PROCEDURE NextFd*(): INTEGER;
BEGIN RETURN CNextFd()
END NextFd;

END BreakCairo.
