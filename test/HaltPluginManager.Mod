MODULE HaltPluginManager; (* A manager not opened halts with Fl.NotOpen, 70 *)
IMPORT FlPreferences;
VAR m: FlPreferences.PluginManager; n: INTEGER;
BEGIN
  NEW(m); n := m.Plugins()
END HaltPluginManager.
