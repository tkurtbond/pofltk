MODULE HaltPluginName; (* A plugin name holding a / halts with Fl.IndexOutOfRange, 74 *)
IMPORT FlPreferences;
VAR a: FlPreferences.Plugin;
BEGIN
  NEW(a); FlPreferences.OpenPlugin(a, "halt", "one/two")
END HaltPluginName.
