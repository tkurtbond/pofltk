MODULE TestDisplay; (* Fl.CanOpenDisplay, asked before any display is open *)

IMPORT Fl, Check, Probe;

VAR
  backend, display, wayland: ARRAY 256 OF CHAR;
  hasBackend, hasDisplay, hasWayland: BOOLEAN;

(* None that can be opened: X11 chosen, and no server at its display. *)
PROCEDURE Unreachable;
BEGIN
  Probe.SetEnv("FLTK_BACKEND", "x11"); Probe.SetEnv("DISPLAY", ":9999");
  Probe.SetEnv("WAYLAND_DISPLAY", "no-such-wayland-display")
END Unreachable;

PROCEDURE Restore(name-: ARRAY OF CHAR; set: BOOLEAN; value-: ARRAY OF CHAR);
BEGIN IF set THEN Probe.SetEnv(name, value) ELSE Probe.UnsetEnv(name) END
END Restore;

PROCEDURE RestoreAll;
BEGIN
  Restore("FLTK_BACKEND", hasBackend, backend); Restore("DISPLAY", hasDisplay, display);
  Restore("WAYLAND_DISPLAY", hasWayland, wayland)
END RestoreAll;

BEGIN
  hasBackend := Probe.GetEnv("FLTK_BACKEND", backend);
  hasDisplay := Probe.GetEnv("DISPLAY", display);
  hasWayland := Probe.GetEnv("WAYLAND_DISPLAY", wayland);
  Check.Check(Fl.CanOpenDisplay(), "CanOpenDisplay: the test's display");
  Unreachable;
  Check.Check(~Fl.CanOpenDisplay(), "FALSE where FLTK would end the program");
  RestoreAll;
  Check.Check(Fl.CanOpenDisplay(), "TRUE again");
  Check.Check(Fl.Has(Fl.Wayland) # Fl.Has(Fl.X11), "a display opened");
  Unreachable;
  Check.Check(Fl.CanOpenDisplay(), "TRUE once one is open, whatever the environment");
  RestoreAll;
  Check.Summary
END TestDisplay.
