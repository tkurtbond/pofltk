// The C++ part of FlPreferences: Fl_Preferences. See pofltk.h for the
// conventions.
//
// Only a database's root is an Fl_Preferences kept here. Deleting it
// deletes every group's node, and delete_group and clear delete nodes,
// so an Fl_Preferences kept for a group could outlive its node
// (Fl_Preferences::~Fl_Preferences, Node::remove). A group is instead
// its root and its path from the root ("" the root itself, "a/b" a
// group b in a); FlPreferences checks it with ofl_prefs_exists before
// every other call, and each call makes it a short-lived Fl_Preferences.
// So is a plugin class's Fl_Plugin_Manager, which holds nothing of its
// own: the plugins are groups of a database in memory that lasts the
// program's life.

#include "pofltk.h"

#include <FL/Fl_Plugin.H>
#include <FL/Fl_Preferences.H>
#include <FL/filename.H>
#include <string.h>
#include <sys/stat.h>

#include <new>
#include <string>

namespace {

Fl_Preferences *root(intptr_t r) { return reinterpret_cast<Fl_Preferences *>(r); }

// Calls f with the group path of root r: the root itself, or a group
// object made for the call. The group exists (ofl_prefs_exists), so
// Fl_Preferences(parent, path) finds it rather than making it.
template <typename F>
auto in(intptr_t r, const char *path, F f) -> decltype(f(*root(r))) {
  if (!*path) return f(*root(r));
  Fl_Preferences g(root(r), path);
  return f(g);
}

// A plugin an Oberon object stands for. Fl_Plugin adds itself to its
// class, and its destructor removes it.
class Pin : public Fl_Plugin {
public:
  Pin(const char *cls, const char *name) : Fl_Plugin(cls, name) {}
};

}  // namespace

extern "C" {

// kind: 0 the user's, 1 the system's, 2 in memory alone, 3 in the
// directory dir. Floating point is always written in the C locale.
// 0 if out of memory.
intptr_t ofl_prefs_open(int32_t kind, const char *dir, const char *vendor,
                        const char *application) {
  Fl_Preferences *p;
  switch (kind) {
    case 0:
      p = new (std::nothrow)
          Fl_Preferences(Fl_Preferences::USER_L, vendor, application);
      break;
    case 1:
      p = new (std::nothrow)
          Fl_Preferences(Fl_Preferences::SYSTEM_L, vendor, application);
      break;
    case 2:
      p = new (std::nothrow)
          Fl_Preferences(Fl_Preferences::MEMORY, vendor, application);
      break;
    default:
      p = new (std::nothrow) Fl_Preferences(
          dir, vendor, application, Fl_Preferences::C_LOCALE);
  }
  return reinterpret_cast<intptr_t>(p);
}

// Writes the database if it changed, and frees it with every group.
void ofl_prefs_close(intptr_t r) { delete root(r); }

int32_t ofl_prefs_exists(intptr_t r, const char *path) {
  return !*path || root(r)->group_exists(path);
}

// Makes group name in path's group; 0 if FLTK can't.
int32_t ofl_prefs_add_group(intptr_t r, const char *path, const char *name) {
  return in(r, path, [name](Fl_Preferences &p) -> int32_t {
    Fl_Preferences g(p, name);
    return p.group_exists(name);
  });
}

// what: 0 groups, 1 entries.
int32_t ofl_prefs_count(intptr_t r, const char *path, int32_t what) {
  return in(r, path, [what](Fl_Preferences &p) -> int32_t {
    return what ? p.entries() : p.groups();
  });
}

// The name of group or entry i; the node's own copy, valid until it
// changes.
intptr_t ofl_prefs_name(intptr_t r, const char *path, int32_t what,
                        int32_t i) {
  return in(r, path, [what, i](Fl_Preferences &p) -> intptr_t {
    return reinterpret_cast<intptr_t>(what ? p.entry(i) : p.group(i));
  });
}

int32_t ofl_prefs_has(intptr_t r, const char *path, int32_t what,
                      const char *name) {
  return in(r, path, [what, name](Fl_Preferences &p) -> int32_t {
    return what ? p.entry_exists(name) : p.group_exists(name);
  });
}

// what: 0 group name, 1 entry name, 2 every group, 3 every entry, 4
// both. 1 if something was deleted, or (2 to 4) always.
int32_t ofl_prefs_delete(intptr_t r, const char *path, int32_t what,
                         const char *name) {
  return in(r, path, [what, name](Fl_Preferences &p) -> int32_t {
    switch (what) {
      case 0: return p.delete_group(name);
      case 1: return p.delete_entry(name);
      case 2: return p.delete_all_groups();
      case 3: return p.delete_all_entries();
      default: return p.clear();
    }
  });
}

int32_t ofl_prefs_set_int(intptr_t r, const char *path, const char *name,
                          int32_t v) {
  return in(r, path, [name, v](Fl_Preferences &p) -> int32_t {
    return p.set(name, static_cast<int>(v));
  });
}

int32_t ofl_prefs_set_real(intptr_t r, const char *path, const char *name,
                           double v) {
  return in(r, path, [name, v](Fl_Preferences &p) -> int32_t {
    return p.set(name, v);
  });
}

int32_t ofl_prefs_set_text(intptr_t r, const char *path, const char *name,
                           const char *v) {
  return in(r, path, [name, v](Fl_Preferences &p) -> int32_t {
    return p.set(name, v);
  });
}

// The get functions give the default when the entry is missing, and
// return whether it was found.
int32_t ofl_prefs_get_int(intptr_t r, const char *path, const char *name,
                          int32_t def, int32_t *v) {
  return in(r, path, [name, def, v](Fl_Preferences &p) -> int32_t {
    int x;
    int32_t found = p.get(name, x, static_cast<int>(def));
    *v = x;
    return found;
  });
}

int32_t ofl_prefs_get_real(intptr_t r, const char *path, const char *name,
                           double def, double *v) {
  return in(r, path, [name, def, v](Fl_Preferences &p) -> int32_t {
    return p.get(name, *v, def);
  });
}

// Copies at most n - 1 bytes into text, and a 0.
int32_t ofl_prefs_get_text(intptr_t r, const char *path, const char *name,
                           const char *def, char *text, int32_t n) {
  return in(r, path, [name, def, text, n](Fl_Preferences &p) -> int32_t {
    return p.get(name, text, def, n);
  });
}

// The length of the entry's text; 0 if missing.
int32_t ofl_prefs_size(intptr_t r, const char *path, const char *name) {
  return in(r, path, [name](Fl_Preferences &p) -> int32_t {
    return p.size(name);
  });
}

// 0 written or unchanged, -1 if the file can't be written.
int32_t ofl_prefs_flush(intptr_t r) { return root(r)->flush(); }

// The file's name, cut to n - 1 bytes; "" in memory.
void ofl_prefs_filename(intptr_t r, char *buf, int32_t n) {
  buf[0] = 0;
  if (root(r)->filename(buf, n) == Fl_Preferences::MEMORY) buf[0] = 0;
}

// The directory for the database's own files, made if it isn't there, with
// a final "/"; 0 and "" in memory, if it can't be made, or if it is n bytes
// or more. FLTK's getUserdataPath makes the directory a short buffer cuts
// its name to, and says it did; in memory it gives "data/"
// (doc/fltk-issues.md, 157).
int32_t ofl_prefs_userdata(intptr_t r, char *buf, int32_t n) {
  buf[0] = 0;
  std::string name(256, '\0');
  for (;;) {
    if (root(r)->filename(&name[0], name.size()) == Fl_Preferences::MEMORY)
      return 0;
    if (strlen(name.c_str()) + 1 < name.size()) break;
    name.resize(name.size() * 2);
  }
  if (!name[0]) return 0;
  std::string path(strlen(name.c_str()) + 8, '\0');
  root(r)->getUserdataPath(&path[0], (int)path.size());
  // Not fl_filename_isdir, which overruns on a long name (doc/fltk-issues.md,
  // 121).
  struct stat st;
  if (stat(path.c_str(), &st) != 0 || !S_ISDIR(st.st_mode)) return 0;
  size_t len = strlen(path.c_str());
  if (len >= (size_t)n) return 0;
  memcpy(buf, path.c_str(), len + 1);
  return 1;
}

// A plugin. The class has none of that name: two would remove one node
// twice as they go (doc/fltk-issues.md, 108).
intptr_t ofl_plugin_new(const char *cls, const char *name) {
  return reinterpret_cast<intptr_t>(static_cast<Fl_Plugin *>(new Pin(cls, name)));
}

void ofl_plugin_close(intptr_t p) {
  delete reinterpret_cast<Fl_Plugin *>(p);
}

int32_t ofl_plugins(const char *cls) {
  Fl_Plugin_Manager m(cls);
  return m.plugins();
}

// i must be in range: plugin(i) makes a group otherwise (108).
intptr_t ofl_plugin_at(const char *cls, int32_t i) {
  Fl_Plugin_Manager m(cls);
  return reinterpret_cast<intptr_t>(m.plugin(i));
}

// 0 if the class has none of that name.
intptr_t ofl_plugin_named(const char *cls, const char *name) {
  Fl_Plugin_Manager m(cls);
  return reinterpret_cast<intptr_t>(m.plugin(name));
}

// Plugin i's name, cut to n - 1 bytes.
void ofl_plugin_name(const char *cls, int32_t i, char *buf, int32_t n) {
  Fl_Plugin_Manager m(cls);
  strncpy(buf, m.group(i), n - 1);
  buf[n - 1] = 0;
}

// 0 loaded, -1 not.
int32_t ofl_plugin_load(const char *file) {
  return Fl_Plugin_Manager::load(file);
}

// Fl_Plugin_Manager::loadAll, with the directory's final / added if it
// has none, and sorted with a sort that stays inside the names
// (doc/fltk-issues.md, 63). pattern "" is every file.
void ofl_plugin_load_all(const char *dir, const char *pattern) {
  std::string d(dir);
  if (d.empty() || d[d.size() - 1] != '/') d += '/';
  dirent **list;
  int n = fl_filename_list(d.c_str(), &list, ofl::numericsort);
  for (int i = 0; i < n; i++) {
    const char *name = list[i]->d_name;
    if (!*pattern || fl_filename_match(name, pattern)) {
      Fl_Plugin_Manager::load((d + name).c_str());
    }
  }
  fl_filename_free_list(&list, n);
}

}  // extern "C"
