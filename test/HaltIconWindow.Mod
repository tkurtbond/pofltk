MODULE HaltIconWindow; (* a window's label is its title (Fl.Unsupported) *)

IMPORT Fl, FlImages;

VAR
  w: Fl.Window;
  i: FlImages.FileIcon;

BEGIN
  NEW(w); Fl.OpenWindow(w, 100, 100, "HaltIconWindow");
  NEW(i); FlImages.OpenFileIcon(i, "*", FlImages.IconAny);
  i.Label(w)
END HaltIconWindow.
