MODULE HaltColumnWidth; (* A browser column width below -1 halts with Fl.Unsupported, 78 *)
IMPORT FlBrowsers;
VAR b: FlBrowsers.Browser; w: ARRAY 2 OF INTEGER;
BEGIN
  NEW(b); FlBrowsers.OpenBrowser(b, 0, 0, 10, 10, "");
  w[0] := 20; w[1] := -2;
  b.SetColumnWidths(w, 2)
END HaltColumnWidth.
