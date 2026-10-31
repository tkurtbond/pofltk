// A shared library for TestPlugins: a plugin of class "loaded", named
// PLUGIN, which is made as the library loads and which no Oberon object
// stands for.

#include <FL/Fl_Plugin.H>

namespace {

class Loaded : public Fl_Plugin {
public:
  Loaded() : Fl_Plugin("loaded", PLUGIN) {}
};

Loaded loaded;

}  // namespace
