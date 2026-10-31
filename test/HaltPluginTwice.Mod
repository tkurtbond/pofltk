MODULE HaltPluginTwice; (* A name its class has already halts with Fl.OpenedTwice, 71 *)
IMPORT FlPreferences;
VAR a, b: FlPreferences.Plugin;
BEGIN
  NEW(a); FlPreferences.OpenPlugin(a, "halt", "one");
  NEW(b); FlPreferences.OpenPlugin(b, "halt", "one")
END HaltPluginTwice.
