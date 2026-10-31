MODULE HaltPluginAt; (* A plugin past the class's last halts with Fl.IndexOutOfRange, 74 *)
IMPORT FlPreferences;
VAR m: FlPreferences.PluginManager; p: FlPreferences.Plugin;
BEGIN
  NEW(m); FlPreferences.OpenPluginManager(m, "halt");
  p := m.PluginAt(0)
END HaltPluginAt.
