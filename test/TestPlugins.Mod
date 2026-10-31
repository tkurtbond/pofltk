MODULE TestPlugins; (* FlPreferences.Plugin and PluginManager: finding objects by class, and loading shared libraries *)

(* ../build/plugins holds one.so and two.so, each a C++ plugin of class
   "loaded" (CPlugin.cpp). *)

IMPORT FlPreferences, Check;

TYPE
  Effect = POINTER TO RECORD (FlPreferences.PluginDesc)
    strength: INTEGER
  END;

VAR
  m, n, l: FlPreferences.PluginManager;
  a, b, c: Effect;
  p: FlPreferences.Plugin;
  name: ARRAY 32 OF CHAR;
  cut: ARRAY 3 OF CHAR;

BEGIN
  NEW(m); FlPreferences.OpenPluginManager(m, "effect");
  Check.Check(m.Plugins() = 0, "a class starts with no plugins");
  Check.Check(m.PluginNamed("blur") = NIL, "a name not there gives NIL");
  Check.Check(~m.HasPlugin("blur"), "and isn't had");

  NEW(a); a.strength := 1; FlPreferences.OpenPlugin(a, "effect", "blur");
  NEW(b); b.strength := 2; FlPreferences.OpenPlugin(b, "effect", "sharpen");
  Check.Check(a.IsOpen(), "an opened plugin is open");
  Check.Check(m.Plugins() = 2, "the manager counts what was opened after it");
  Check.Check(m.HasPlugin("blur"), "and has it");
  p := m.PluginNamed("sharpen");
  Check.Check(p = b, "a name gives the object");
  Check.Check(p(Effect).strength = 2, "of the program's own type");

  m.PluginName(0, name);
  Check.Check(name = "blur", "a plugin's name is its own, not a path");
  m.PluginName(1, name);
  Check.Check(name = "sharpen", "and they are in the order they were opened");
  p := m.PluginAt(0);
  Check.Check(p = a, "an index gives the object of that name");
  NEW(c); FlPreferences.OpenPlugin(c, "effect", "alpha");
  p := m.PluginAt(2);
  Check.Check(p = c, "the newest is last, whatever its name");
  c.Close;

  m.PluginName(0, cut);
  Check.Check((cut[2] = 0X) & (cut[1] # 0X), "a long name is cut to fit");

  NEW(n); FlPreferences.OpenPluginManager(n, "effect");
  Check.Check(n.PluginNamed("blur") = a, "a second manager sees the same plugins");
  NEW(n); FlPreferences.OpenPluginManager(n, "other");
  Check.Check(n.Plugins() = 0, "another class doesn't");

  a.Close;
  Check.Check(~a.IsOpen(), "a closed plugin isn't open");
  Check.Check(m.Plugins() = 1, "and is gone from its class");
  Check.Check(m.PluginNamed("blur") = NIL, "and from its name");
  Check.Check(m.PluginAt(0) = b, "the other stays");
  a.Close;
  Check.Check(m.Plugins() = 1, "closing twice does nothing");
  FlPreferences.OpenPlugin(a, "effect", "blur");
  Check.Check(m.PluginNamed("blur") = a, "a closed plugin can be opened again");
  a.Close; b.Close;

  NEW(l); FlPreferences.OpenPluginManager(l, "loaded");
  Check.Check(~FlPreferences.Load("../build/plugins/missing.so"), "a missing library doesn't load");
  Check.Check(~FlPreferences.Load("images/rb.ppm"), "nor does a file that isn't one");
  Check.Check(l.Plugins() = 0, "and adds nothing");
  FlPreferences.LoadAll("images", "rb.*");
  Check.Check(l.Plugins() = 0, "LoadAll passes over what isn't a library");
  FlPreferences.LoadAll("../build/plugins", "no*");
  Check.Check(l.Plugins() = 0, "and what doesn't match");
  Check.Check(FlPreferences.Load("../build/plugins/one.so"), "a library loads");
  Check.Check(l.Plugins() = 1, "and its C++ plugin joins the class");
  Check.Check(l.HasPlugin("one"), "under its name");
  Check.Check(l.PluginNamed("one") = NIL, "a C++ plugin has no object");
  Check.Check(l.PluginAt(0) = NIL, "by index either");
  l.PluginName(0, name);
  Check.Check(name = "one", "but it has a name");
  FlPreferences.LoadAll("../build/plugins", "t*.so");
  Check.Check(l.HasPlugin("two"), "LoadAll loads what matches, given no final /");
  FlPreferences.LoadAll("../build/plugins/", "");
  Check.Check(l.Plugins() = 2, "and everything for no pattern, each once");

  Check.Summary
END TestPlugins.
