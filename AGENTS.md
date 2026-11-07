# AGENTS.md

pofltk is an Oberon-2 binding to FLTK 1.4, the Fast Light Toolkit, compiled
with poc, the Peaseblossom Oberon Compiler. PLAN.md is the design and
roadmap; `doc/design.md` is the feasibility analysis that started it;
`doc/fltk-issues.md` lists the FLTK bugs and pitfalls found so far. This
file is operational notes for an agent working in this repo, not a design
doc.

Two existing projects shape this one; read their notes before redesigning
anything:

- **FLTKAda** (`/usr/local/sw/src/tkb/fltkada`): the user's fork of a thick
  Ada binding to FLTK. Its `doc/binding_architecture.md` explains how FLTK's
  virtual `draw()`/`handle()` are sent back into the host language, and
  lists FLTK pitfalls. Its C++ shim (`body/c_fl_*.cpp`, public domain) is
  the reference for binding any class.
- **polibfyaml** (`~/Repos/Oberon/polibfyaml`): an Oberon-2 binding to a C
  library with poc. Its build, tests, valgrind setup and conventions are
  this repo's model, and its AGENTS.md holds hard-won poc facts.

## Status

As of 2026-11-07, Phases 0 to 25 of PLAN.md are done, and `README.md`
is the user's guide. Phases 9 to 13 (planned 2026-10-07) ported the rest
of FLTK's `examples/` and bound what they needed; Phases 25 to 32
(planned 2026-11-07) port FLTK's `test/` programs. `src/` has the `Fl`, `FlDraw`, `FlButtons`,
`FlInputs`, `FlValuators`, `FlLayout`, `FlMenus`, `FlDialogs`, `FlText`,
`FlBrowsers`, `FlImages`, `FlPreferences`, `FlTable`, `FlHelp`, `FlUtf8`,
`FlTerminal` and `FlPrint` modules, `src/forms/` has `FlForms`, `src/gl/`
has `FlGl` and `FlGlut`, `src/cairo/` has `FlCairo`, and the tests pass. Also kept:

- `doc/design.md`: the feasibility analysis.
- `doc/fltk-issues.md`: every FLTK bug and pitfall found, with its
  cause in FLTK's source and pofltk's workaround.
- `prototype/` was retired in Phase 3, when `src/` had all it had; it
  is in git up to commit f57262b. Its demo is `examples/Swatch.Mod`.
- `probes/callback/`: C calling an Oberon procedure value.
- `probes/gc-hazard/`: a flat binding (`Fltk.Mod`, `Fltk.cpp`). `Hazard.Mod`
  shows a callback's `user_data` being collected; `Hello.Mod` is a
  one-button window that waits for real clicks.

The project was called ofltk until 2026-10-07, when it was renamed
pofltk (PLAN.md, "Rename to pofltk"). PLAN.md's phases, its open
questions and `doc/design.md` keep the old name, as history. The `ofl`
prefix of the C++ parts (`ofl::`, `ofl_`) was kept.

## Layout

- `src/pofltk.h`: what every module's C++ part shares:
  - `ofl::W<B>`, the FLTK class `B` with `draw()`, `handle()` and
    `resize()` sent to Oberon;
  - `ofl::Hooks`, through which Oberon reaches `B`'s own `draw()`,
    `handle()` and `resize()`, and `Fl_Widget`'s protected `draw_box()`,
    `draw_label()` and `draw_focus()`;
  - `ofl::open`, which attaches a widget to its Oberon object;
  - the `Ref` user data, whose destructor is the deletion hook, and
    which holds the images and multi-label a widget shows (its slots),
    and any number of things beside (`keep`, for a browser's line
    icons and a menu's item labels), let go by `drop_unused`;
  - `ofl::Shared`, a reference count for what widgets share (images,
    multi-labels);
  - `ofl::ItemLabel`, a menu item's image or multi-label, which keeps
    the item's text (`doc/fltk-issues.md`, 54);
  - `ofl::label_text`, which every label goes through ("" is none);
  - `ofl::Overlaid<B>`, `ofl::W<B>` with `draw_overlay()` sent to
    Oberon too;
  - the dispatch depth.
- `src/Fl.Mod`, `src/Fl.cpp`: the core module. Its "For pofltk's modules
  only" procedures (`BeginOpen`, `EndOpen`) are how another module
  opens a widget of its own class. Keep application code off them.
- `src/FlDraw.Mod`, `src/FlDraw.cpp`: `fl_draw.H`, for `Draw` methods.
- `Fl.Has` says what this FLTK has (`Svg`, `Wayland`, `X11`), decided by `#if` in the C++ parts, since poc has no conditional
  compilation. A test of something missing calls `Check.Skip`.
- `src/FlButtons`, `src/FlInputs`, `src/FlValuators`, `src/FlLayout`,
  `src/FlMenus`, `src/FlText`, `src/FlBrowsers` (`.Mod` and `.cpp`):
  the widget families of PLAN.md's module table. Each C++ part
  has one `ofl_<family>_new(kind, ...)` that makes the class `kind`
  numbers as `ofl::W<class>`, copies the label and calls `ofl::open`;
  each Oberon `Open<Type>` passes it `Fl.BeginOpen(w)` and gives the
  result to `Fl.EndOpen`. Methods get the handle with `Fl.Live(w)`.
- `src/FlDialogs.Mod`, `src/FlDialogs.cpp`: FLTK's common dialogs,
  procedures with no widget of their own, `NativeFileChooser` and
  `FileChooser` (`Fl_File_Chooser`, whose `Close` deletes it later if
  its callback is running; `doc/fltk-issues.md`, 91, 92). A
  test turns zenity, kdialog and GTK off (`Fl.SetOption`), so the
  chooser is FLTK's and keys can answer it.
- `src/FlImages.Mod`, `src/FlImages.cpp`: images (loaded by their
  contents, not their names, or from RGB pixels, which are copied),
  widgets' images, image surfaces, images on the clipboard, FLTK's
  pool of shared images (`Shared`, the shim's `Pool`) and file icons
  (`FileIcon`), and the program's image handlers (`AddHandler`,
  `ask_handlers`, `load_shared`). `WidgetSurface` is `Surface`'s and
  `CopySurface`'s base. It links `-lfltk_images`. Outside data goes through the
  shim's checks before FLTK's decoders: `parse_xbm`, `dib_ok`, `gif_ok`
  and `lzw_ok`, since FLTK's overrun on crafted files
  (`doc/fltk-issues.md`, 81, 87, 88).
- `src/FlBrowsers.cpp`'s tree: `Tr` is the tree's class, which hears
  a widget leave it (`on_remove`) and forgets a removed last-clicked
  item after each event (`handle`); `Mine` is an item the program
  made, whose `draw_item_content` is sent to Oberon through a
  dispatcher FlBrowsers' body registers (`ofl_tree_register`), and
  whose destructor drops the Oberon object from FlBrowsers' `made`
  list. A private member is reached, where nothing else will do, by an
  explicit instantiation (`Reach`, for `Fl_Tree::_lastselect`).
- `src/FlHelp.Mod`, `src/FlHelp.cpp`: `Fl_Help_View` and
  `Fl_Help_Dialog`. `View` asks Oberon's `Link` about links and images
  (`help_link`), remembers each image's answer, and counts layout
  changes between a push and its release (`doc/fltk-issues.md`, 89, 90).
- `src/FlUtf8.Mod`, `src/FlUtf8.cpp`: `fl_utf8.h`'s text functions, in
  bytes. Each C++ function works on a copy with zeros on both sides
  (`Text`), keeps results within the text, and `give`s what fits
  (`doc/fltk-issues.md`, 115 to 118).
- `src/FlPreferences.Mod`, `src/FlPreferences.cpp`: `Fl_Preferences`. A
  group is its database and a path, not an `Fl_Preferences` kept.
- `src/FlTable.Mod`, `src/FlTable.cpp`: `Fl_Table` and `Fl_Table_Row`.
  `draw_cell` is a fourth virtual sent to Oberon, through a dispatcher
  FlTable's body registers (`ofl_table_register`), as Fl's body
  registers `Draw`'s.
- `src/FlTerminal.Mod`, `src/FlTerminal.cpp`: `Fl_Terminal`. `Term::fit`
  keeps the cursor on the screen after anything that can shrink it
  (`doc/fltk-issues.md`, 96).
- `src/FlPrint.Mod`, `src/FlPrint.cpp`: `Fl_Printer` and the file
  surfaces. Cairo writes through the shim's `Sink`, not a file FLTK can
  close twice (`doc/fltk-issues.md`, 101); a timer closes the alert a
  failed PDF raises (102); each begin sets a font (100). `/dev/full`
  isn't on OpenBSD, so `TestPrint` skips those checks there. FLTK can
  be built with no printing, which only a weak symbol shows
  (`FlPrint.Available`, 104); a `HaltPrint` test then ends with
  `HALT(99)`, which `make test` counts as a skip.
- `src/forms/FlForms.Mod`, `src/forms/FlForms.cpp`: `Fl_Timer`, `Fl_Free`,
  `Fl_FormsBitmap`, `Fl_FormsPixmap` and `Fl_FormsText`, the first
  optional part: `pofltk` is unchanged, and `make install` writes a
  library of its own, `pofltk-forms`, importing `pofltk` and recording
  `-lfltk_forms`, so a program not using it isn't linked with it. An
  optional part has a directory in `src/`, is built when `fl_config.h`
  says FLTK has it (`HAVE_FORMS`), and is skipped otherwise, with its
  tests and examples: `make test` names it in its "Not built" line
  (`MISSING`). Its programs are built with `FORMSLINK`.
- `src/gl/FlGl.Mod`, `src/gl/FlGl.cpp`: `Fl_Gl_Window`, `FL/gl.h` and the
  part of GL FLTK's programs use, and `src/gl/FlGlut.Mod`,
  `src/gl/FlGlut.cpp`: `glut.H`. The second optional part, library
  `pofltk-gl`, as Forms is; `HAVE_GL` is whether `libfltk_gl` is there
  (`doc/fltk-issues.md`, 113), and `GLLINK` links its programs.
  `FlGlut` wraps display procedures (`run_display`), so it knows when it
  is in `Fl::flush`, where a hide waits (112). `GLEW` is an optional
  part of an optional part: `HAVE_GLEW`, for the OpenGL 3 ports, and
  their `examples/GlThree.cpp`, which is outside `EXAMPLECXX`.
- `src/cairo/FlCairo.Mod`, `src/cairo/FlCairo.cpp`: a window drawn with
  cairo, and part of cairo. The third optional part, library
  `pofltk-cairo`; `HAVE_CAIRO` is `pkg-config`'s, of `cairo`, and
  `cairo-xlib` where FLTK has X11, and `CAIROLINK` links its programs.
  It doesn't use `Fl_Cairo_Window` or need `FLTK_HAVE_CAIRO`: `Cw` makes
  a context for each draw, by back end (`doc/fltk-issues.md`, 114).
- `FlPreferences`' plugins: `Plugin` and `PluginManager`, with a
  `Pin : Fl_Plugin` in the C++ part holding the Oberon object. A
  plugin library is `dlopen`ed; `test/CPlugin.cpp` is one, in C++, built
  by the makefile into `build/plugins/`. An Oberon plugin library needs `-library`,
  and a `.cpp` with a static initializer calling `<Module>_init`, which
  poc doesn't document; the program must share its modules
  (`-shared-libraries`, or `-link -rdynamic`), or `PluginAt` gives NIL
  (`FlPreferences`' module comment; `doc/fltk-issues.md`, 108).
- **What a widget's C++ part keeps beside FLTK's object** goes in a base
  class listed before `ofl::W<B>`, so it is destroyed after FLTK's
  object, and is reached by `dynamic_cast`: `Holds` (`FlText`: the
  buffers a display shows), `Keeps` (`FlBrowsers`: copies of pointers
  FLTK keeps), `Items` (`FlBrowsers`: a tree's live items, and which
  item shows each widget). Never
  `static_cast` an `ofl::widget` to a template class: the kind decides
  which instance it is.
- `test/`:
  - one main module per concern, `Test*.Mod`, using `Check.Mod`;
  - halt tests, `Halt*.Mod`, one per code;
  - `poc-gc.supp`, and `vg-check.sh` (Valgrind, below);
  - `TestConstants.Mod`, `CConstants.Mod` and `CConstants.cpp`, written
    by `tools/gen-constants.py`. `CConstants` is a test module with a C++
    part. `TestFormsConstants.Mod` and `CFormsConstants` are the same
    for `FlForms` (`OPTIONAL` in the script), apart so that they go
    when it does;
  - `Probe.Mod` and `Probe.cpp`, a test module with a C++ part: a
    widget's pixels, captured into an `Fl_Image_Surface`; mouse, wheel
    and key events sent as the window system would; the modal window (a
    dialog) and keys sent to it; whether FLTK uses Wayland; and how
    many things a widget keeps (`Kept`, `Ref::keep`); pipes
    (`Pipe`, `Write`, `Read`, `Close`), for `TestLoop`'s fd watches;
    what a shown window shows (`ShownPixel`), on either back end; and
    where the grab is (`Grab`), a pop-up menu's window.
  - `images/`: one 4x2 image, red left and blue right, in each format
    `TestImages` reads; `anim.gif`, three frames of it, for
    `TestAnimGIF`; and for `TestImageFiles` and `TestFileIcons`, `rb.xbm`,
    `rb.ico` (two sizes), `rbpng.ico`, `box.fti`, and files that must
    fail to load: `not-xbm.h`, `short.xbm`, `huge.xbm`, `bad.fti`,
    `colors.bmp`, `size.bmp`, `depth.bmp`, `colors.ico`, `loop.gif`,
    `zero.gif`, `code.gif` and `beyond.gif`; `rb.rbx` and `long.rbx`,
    a format of `TestImageHandlers`' own;
  - `help.html`, `help2.html`: pages for `TestHelp` and `HelpDialog`;
  - `names/`: empty files whose names each directory sort orders
    differently (`TestDialogs`, `TestBrowsers`).
- `tools/gen-constants.py`: writes each module's constants and their
  test, from FLTK's headers (constants, below).
- `tools/with-sway.sh`: runs a command on a headless sway (`make
  test-sway`, below).
- `examples/`: example programs (`Hello`, FLTK's hello; `Scribble`,
  drawing with the mouse; `Swatch`, the prototype's demo; `Menus`, a
  menu bar, a choice and the dialogs; and ports of FLTK's `examples/`,
  named for FLTK's file in CamelCase without `howto-`, and of its
  `test/`, from Phase 25; their data, `browser.cxx` and `rgb.txt`, is
  copied beside them). A port is
  checked against FLTK's own build of it (in FLTK's `examples/` or
  `test/`): both
  run under Xvfb, driven by the same `xdotool` input, and their screens
  compared (`magick compare -metric AE -fuzz 1%`, then with no fuzz:
  the fuzz hid a port's `Show` where FLTK's program has
  `show(argc, argv)`, which is `ShowArgs`; `doc/fltk-issues.md`, 154).
  On Xvfb with no
  window manager a window sits 20 pixels below its y, so add 20 to a
  click's y. `make` builds them. They wait for the user, so
  `make test` runs each for `EXAMPLETIME` seconds and checks it is still
  running then. `Pipe.Mod` and `Pipe.cpp` are an example module with a
  C++ part (`popen`), listed in `EXAMPLECXX`; examples are built with
  `-import-path examples` to find it.
- `GNUmakefile`: build and test (Build, below).
- `build/`: poc and clang output (ignored by git).
- `PLAN.md`: design, decisions and findings, by section and phase.
- `README.md`: for the binding's users: building, installing, the
  modules and concepts. Keep its example the same as `examples/Hello.Mod`.

## Reference material

| What | Where |
|---|---|
| FLTK headers (1.4.5) | `/usr/include/FL/` (`fltk-devel-1.4.5`); flags from `fltk-config --cxxflags`/`--ldflags` (`-lfltk`) |
| FLTK source (1.4.5) | `/usr/local/sw/src/lang/C++/fltk/fltk-1.4.5/` (`src/`, `FL/`, `test/`, `examples/`) |
| FLTK docs (HTML) | `/usr/share/doc/fltk-devel/html/` |
| FLTK 1.3 | also installed (`fltk1.3`, runtime only); never build against it |
| FLUID | `fltk-fluid-1.4.5` |
| poc | `/usr/bin/poc` (Peaseblossom RPM 0.11.2); `poc(1)`; `/usr/share/doc/peaseblossom/users-guide.md` (§9, "Calling C") and `reference-guide.md` |
| poc source | `~/Repos/Oberon/Peaseblossom` |
| FLTKAda | `/usr/local/sw/src/tkb/fltkada` (`AGENTS.md`, `doc/binding_architecture.md`, `progress.txt`, `test/`) |
| polibfyaml | `~/Repos/Oberon/polibfyaml` (`AGENTS.md`, `GNUmakefile`, `test/Check.Mod`, `test/poc-gc.supp`) |
| Oberon-2 report | `~/Reference/Computer/Languages/Oberon/Oberon2.pdf` |
| Installed poc libraries | `~/.local/lib/poc` (`POCLIBDIR` in the makefiles here and in polibfyaml) |

Before assuming an FLTK function is missing or behaves as its header
comment says, check the source: FLTKAda's notes record several header
comments that are wrong.

## Build

```sh
make            # the test programs, into build/
make test       # every test, halt test and example; needs a display
make valgrind   # the tests under valgrind, then test/vg-check.sh on each log
make test-headless      # make test on Xvfb, not the desktop
make valgrind-headless  # make valgrind on Xvfb
make test-sway          # make test on Wayland, on a headless sway
make valgrind-sway      # make valgrind on a headless sway
make clean      # rm -rf build
```

- `make POC=/path/to/poc` uses another poc.
- **A new test** needs its name added to `TESTS`, a halt test to
  `HALTTESTS` (as `name:code`). `TestArgs` alone is given a command
  line, `TESTARGS`, by both test loops.
- **A new optional part** follows Forms in the makefile: `HAVE_<PART>`,
  a library, tests, halts and examples of its own, and `MISSING`.
- **A new module** needs its name added to `MODULES`, and a new header to
  `HEADERS`. A test module with a C++ part goes in `TESTCXX`, an example
  in `EXAMPLES`, and an example's module with a C++ part in
  `EXAMPLECXX`. `EXAMPLES` is one long line: edit it by matching its
  text, as `sed 's/^\(EXAMPLES := .*Last\)$/\1 New/'`, not by line
  number. An example that needs a command line under `make test` gets
  one in `EXAMPLEARGS`, as `name=argument`. One that ends by itself
  goes in `EXAMPLEONCE`, and must exit 0.
- **Constants**: never edit the block of a module between
  `BEGIN generated constants` and `END generated constants`. Add the
  name and C expression to `SPEC` in `tools/gen-constants.py`, after
  the `module(...)` line naming the module (whose source must already
  have the empty block), then run
  `python3 tools/gen-constants.py` from the repository root (it needs
  `clang++` and `fltk-config`). After an FLTK upgrade, run it again, and
  read the diff: `TestConstants` fails until you do if a value moved.
- **C++ parts are `src/<Module>.cpp`**, compiled by clang++, which also
  links any program that has one. That needs poc 0.4.0, and `ORD` of a
  `SET` needs 0.4.1, which the makefile requires.
- The C++ parts are compiled `-std=c++11 -Wall -Wextra -Werror`, as
  FLTKAda's shim is, so code can move between them.
- `-verbose` on a poc command shows the clang commands it runs.

```sh
make install    # the poc library pofltk, -OC, with and without -g, into POCLIBDIR
make uninstall  # remove exactly what make install wrote
```

`pofltk-forms`, where FLTK has Forms, `pofltk-gl`, where it has GL, and
`pofltk-cairo`, where there is cairo, go beside it in `POCLIBDIR`, so
one `-library-path` finds them all.

The tests and examples are built on the libraries in `build/lib*`, not
from `src/`, so they test what `make install` installs, and the makefile
unexports `POC_LIBRARY_PATH`, so an installed `pofltk` is never tested in
place of this checkout. `install` builds the libraries and doesn't run
the tests.

`poc -library` links a shared object too, which an FLTK of static
libraries can't go into, as on cymoril, jherek, alerik and rackhir
(2026-10-31). The makefile gives poc `-no-shared-library` (poc 0.11.0)
where `FLTK_LIBDIR` has no `libfltk.so*`, on all four libraries, since a
library with a shared object can't need one without.
pkgsrc's FLTK, on yishana and artos, has both. `fltk-config` is found on
`PATH`, then in `/usr/local/sw/versions/fltk/*/bin`.

`POCLIBDIR` defaults to `$(PREFIX)/lib/poc`, with `PREFIX` default
`~/.local`. Try it elsewhere first with `make install
POCLIBDIR=<scratch dir>`. The manifest records `c++`, `-lfltk_images` and
`-lfltk`, so a program using the installed library needs only:

```sh
poc -OC -library-path $POCLIBDIR Main.Mod
```

A library records the poc that built it, and another poc refuses it, so
install again after upgrading poc. The libraries, and so every program,
are rebuilt when `poc -version` changes (`build/poc-version`), not just
poc's file: a package keeps its build's date, and Fedora's 0.11.2 was
dated before the libraries 0.11.1 had built, so nothing was rebuilt
(2026-11-07).

By hand, as for an experiment in the scratchpad:

```sh
poc -OC -output-dir out -o out/Demo -link -lfltk Demo.Mod
```

`-output-dir` and `-o` keep poc's `.sym`, `.ll`, `.o` and `.cpp.o` files
out of the source directory.

### Tests and the display

Tests and demos need a display (`DISPLAY` or `WAYLAND_DISPLAY`), even for
widgets never shown; `make test` stops with a message without one.

- The user's desktop is Wayland, and FLTK 1.4 uses its Wayland back end
  there. `FLTK_BACKEND=x11 make test` runs the tests on X11 (XWayland).
- **An agent never opens windows on the user's desktop**: not
  `make test`, not `FLTK_BACKEND=x11 make test` (XWayland is the
  desktop too), not a scratch program run directly. Use
  `make test-sway`/`valgrind-sway` (Wayland) and
  `make test-headless`/`valgrind-headless` (X11), and
  `tools/with-sway.sh` or `env -u WAYLAND_DISPLAY xvfb-run -a` for a
  single program (the user's instruction, 2026-10-06).
- Under Wayland a test's windows and dialogs appear on the real
  desktop, where the user's typing or clicking can reach them: a
  `TestDialogs` run failed its `Choice` checks this way once
  (2026-10-06), and passed when run again.
- **`make test-headless`** runs them on Xvfb instead, so no windows
  appear on the desktop. It unsets `WAYLAND_DISPLAY`: a plain `xvfb-run`
  in a Wayland session leaves it set, and FLTK then uses the real desktop
  (confirmed).
- **`make test-sway`** runs them on Wayland without the desktop: on a
  headless sway, through `tools/with-sway.sh` (2026-10-06). sway's
  headless back end (`WLR_BACKENDS=headless`, software rendering with
  `WLR_RENDERER=pixman`, no input devices) has an output but no screen.
  sway runs the command itself, from an `exec` in its own config, so the
  command gets sway's `WAYLAND_DISPLAY`, and finding the socket can't
  race another compositor; `DISPLAY` is unset, so FLTK can't fall back
  to X11. The kernel's VKMS driver would need root and a seat for no
  gain here.
  - Pop-up menus are closed at once there too (three runs of three), as
    on the desktop, so `TestMenus` still tests them on X11 alone.
  - So the four runs that leave the desktop alone are `test-headless`
    and `valgrind-headless` (X11) and `test-sway` and `valgrind-sway`
    (Wayland).
- A test drives itself, with no input tool:
  - `DoCallback`;
  - events from `test/Probe`, sent to a window never shown;
  - `Fl.AddTimeout`, or `Fl.Wait`/`Fl.Check` in a loop;
  - deleting its windows before it ends.

  `make test` runs each test under `timeout`.
- **`Probe` drives FLTK's own routing, so mind what FLTK does**:
  - a mouse event goes through `Fl::handle`, to the widget under the
    mouse, then to `Fl::pushed()`;
  - a push no widget uses shows the window (FLTK raises it), so put
    such a check last;
  - a key goes to the focus widget alone. Through `Fl::handle`, a key no
    widget uses crashes FLTK 1.4.5 when no window is shown and
    `BelowMouse` is set (`doc/fltk-issues.md`, 3);
  - drag and drop events go through `Probe.Mouse`. A window passes
    `EvDndLeave` to every child, and with no window shown an `Fl_Input`
    crashes on it (`doc/fltk-issues.md`, 53): test in a window with
    no input;
  - a key must carry the text the window system would give it
    (BackSpace `08X`, Enter `0DX`): under Wayland, FLTK takes a key with
    no text as composed text;
  - `Probe.Shortcut` offers a key to a window's widgets as a shortcut,
    for return buttons and shortcuts;
  - waits on timers allow for valgrind's slowness: loop until the
    condition holds, up to a generous limit;
  - `Probe.HandleKey` sends a key through `Fl::handle`: to a pop-up
    menu's grab, or as a shortcut to a window's widgets and then the
    event handlers (a global menu);
  - a dialog is answered by a timer that waits for `Probe.Modal`, then
    sends keys with `Probe.ModalKey`, then fires once more: FLTK runs
    timers and then waits for an event, and under Xvfb none comes to end
    the dialog's loop (`doc/fltk-issues.md`, 32);
  - under Wayland the compositor closes a pop-up menu of a window no
    user clicked, so `Popup` is tested on X11 alone (`Probe.Wayland`).
- **`xdotool` is installed** (2026-10-06), for trying an example by hand
  under Xvfb: run it in `xvfb-run -a -s '-screen 0 640x480x24' sh -c
  '...'` with `WAYLAND_DISPLAY` unset, move and click with `xdotool`, and
  look with `import -window root shot.png` (ImageMagick). Tests use
  `Probe`, not `xdotool`, so they need no window manager or timing.

### Testing on OpenBSD i386 (cymoril)

cymoril runs OpenBSD 7.9 on i386, so it tests a 32-bit build and fonts
other than Fedora's (2026-10-08). Until 2026-10-30 it also tested X11
without Cairo, but its FLTK now has Cairo and Pango (`FLTK_HAVE_CAIRO`,
`FLTK_USE_CAIRO`, `FLTK_HAVE_CAIROEXT`), and no host here tests FLTK's
plain X11 drawing. The agent can ssh to it as the user and as root.

- **FLTK**: OpenBSD's package is too old, so FLTK 1.4.5 is built from
  source in `/usr/local/sw/versions/fltk/1.4.5`, for X11 alone. Pass
  `FLTK_CONFIG=/usr/local/sw/versions/fltk/1.4.5/bin/fltk-config` to
  `gmake` (GNU make; OpenBSD's `make` is BSD make).
- **Its `fltk-config` leaves out `/usr/X11R6`**, so the makefile adds
  `pkg-config`'s directories for `x11` (`doc/fltk-issues.md`, 66). The
  runtime linker's cache must include `/usr/X11R6/lib`
  (`ldconfig -m /usr/X11R6/lib` as root), or the tests can't find
  `libX11`.
- **The display**: no sway and no valgrind there, and no `xvfb-run`.
  Start Xvfb by hand and run `make test` on it:

  ```sh
  ulimit -d 3000000   # a higher data limit, as the runs so far used
  /usr/X11R6/bin/Xvfb :99 -screen 0 1280x1024x24 -nolisten tcp &
  DISPLAY=:99 gmake FLTK_CONFIG=... test
  pkill -f 'Xvfb :99'
  ```

- **Fonts**: its `/etc/fonts/conf.d` was empty, so "sans", "serif" and
  "mono" were all DejaVu Math TeX Gyre, and text tests failed. The
  links xenocara installs (`lib/fontconfig/conf.d/Makefile`,
  `CONF_LINKS`) were made by hand on 2026-10-08, and the three now
  match DejaVu Sans, Serif and Sans Mono. `fc-match sans` checks it.
- Tested there 2026-10-08: `make test` passes, with the poc 0.4.1
  package (`/usr/local/bin/poc`); 2026-10-15 with poc 0.6.0, all 823
  `ok` lines; 2026-10-30 with poc 0.10.1, all 823; and 2026-11-07
  with poc 0.11.2, 2450, 2 skipped.

### Testing on NetBSD i386 (yishana)

yishana runs NetBSD 11.0 on i386 (2026-10-08): a second 32-bit build,
with pkgsrc's FLTK 1.4.5, which draws with Cairo and Pango, and
DejaVu fonts since 2026-10-30 (X11's Luxi before). The agent can ssh
to it as the user and as root.

- **FLTK** is pkgsrc's: `FLTK_CONFIG=/usr/pkg/bin/fltk-config`. Its
  image libraries name a `-lpng` pkgsrc doesn't install, which the
  makefile drops (`doc/fltk-issues.md`, 71).
- **poc** is 0.11.2 in `/usr/pkg/bin` (2026-11-07); put `/usr/pkg/bin`
  first on `PATH` (ssh doesn't).
- **The display**: Xvfb is X11's, `/usr/X11R7/bin/Xvfb`; start it by
  hand as on cymoril. No sway, and no valgrind on NetBSD.
- Tested there 2026-10-08: `make test` passes, all 814 checks;
  2026-10-15 with poc 0.6.0, all 823 `ok` lines; 2026-10-30 with
  poc 0.10.1, all 823; and 2026-11-07 with poc 0.11.2, 2458, 1 skipped.

### The other BSD hosts

Surveyed 2026-10-30; each has poc 0.11.2 (2026-11-07), and the agent can
ssh to each as the user.

- **artos**: NetBSD 11.0 on amd64, set up as yishana is: pkgsrc's FLTK
  1.4.5 with Pango, Xvfb, no sway or valgrind. `make test` passed
  there 2026-10-30, all 823 `ok` lines.
- **jherek**: OpenBSD 7.9 on amd64: FLTK 1.4.5 in
  `/usr/local/sw/versions/fltk/1.4.5` (2026-10-30), with
  `FLTK_HAVE_CAIRO` and `FLTK_USE_CAIRO`, and cairo, Pango, GL, GLEW
  and `/usr/X11R6/bin/Xvfb`. Set up as cymoril is, on amd64. `make test`
  passed there 2026-10-30, all 823 `ok` lines.
- **alerik** (FreeBSD 15.1, amd64) and **rackhir** (FreeBSD 15.1,
  arm64): FLTK 1.4.5 in `/usr/local/sw/versions/fltk/1.4.5` (2026-10-30),
  with `FLTK_HAVE_CAIRO` and `FLTK_USE_CAIRO`, and cairo, Pango, GL,
  GLEW and `/usr/local/bin/Xvfb`. DejaVu is their only font.
  `make test` passed on both 2026-10-30, all 823 `ok` lines.

**So that a test passes on every system**, it must not depend on the
font, the drawing back end, or the FPU:

- store a `LONGREAL` FLTK returns before comparing it exactly
  (`doc/fltk-issues.md`, 68);
- where a position depends on text widths, use a monospaced font
  (`Fl.Courier`; `doc/fltk-issues.md`, 70);
- compare a widget's drawing with its own earlier drawing, not with
  another widget's (`doc/fltk-issues.md`, 69).

### Valgrind

- **Memory errors fail a test.** The flags are `--error-exitcode`, plus
  `test/poc-gc.supp` for the collector's conservative stack scan.
- **FLTK's display stack leaks by design**: fontconfig and Pango's font
  cache, and GTK's decorations under Wayland. That is hundreds of KB and
  thousands of records, from programs that free everything they made
  (PLAN.md, Phase 0). So leaks don't count as valgrind errors
  (`--errors-for-leak-kinds=none`).
- **`test/vg-check.sh` fails on any leak record whose allocator is
  pofltk's**: the first frame after `malloc`/`calloc`/`realloc`/
  `operator new`, and after `strdup`, `asprintf` and the like and the
  standard library's templates (`std::`), is an `ofl_` function, the
  `ofl` namespace, an `Fl*` module, or C++ in a `build/` program (a C++
  part's anonymous namespace or statics). The `strdup` and `std::`
  skips and the `build/` rule were added 2026-11-06, when a leak of each kind in `FlText.cpp` (a `strdup`, a
  `std::string`'s buffer, a `malloc` in `insert_file`) passed the old
  script; 26 of its records failed the new, and only 6 the old.
  - So **a test must delete every widget it opens**, or it fails
    `make valgrind`.
  - A box never deleted was caught this way. Before the
    `operator new(unsigned long)` pattern was fixed, it wasn't: check
    that the script still catches a deliberate leak whenever you change
    it.

## Confirmed facts (poc 0.3.1 to 0.11.2, FLTK 1.4.5)

Each was confirmed by a program that ran, in the session of 2026-10-06
unless it says otherwise.

### Calling between Oberon and C++

- **A top-level Oberon procedure is a plain C-ABI function** with no hidden
  parameters. Its address, passed as a procedure value, works as an FLTK
  callback or timeout handler.
- **C can call an Oberon procedure by its symbol**, `Module.Proc`,
  exported or not, through an `__asm__` label:
  `extern void hook(int32_t) __asm__("Hk.DrawHook");`. This works with
  `-lto` too. The Reference Guide doesn't promise these names, so prefer
  passing procedure values to the C++ side from a module body.
- **Exported `["C"]` procedures can be called from other modules** in
  0.3.1. In 0.1.0 they couldn't (polibfyaml's "poc 0.1.0 problems").
- **`poc -check` uses the right word size** in 0.3.1: `poc -OC -check`
  accepts `ADDRESS := LONGINT`, which 0.1.0 rejected.
- **An open array argument to a `["C"]` procedure** is passed as its
  first element's address alone. An Oberon `ARRAY OF CHAR` therefore
  arrives as a `const char *`, and must contain a `0X`.
- **The prototype builds and runs under both `-O2` and `-OC`**, because
  its C boundary uses only `SYSTEM.INT32` and `SYSTEM.ADDRESS`.

### The collector

poc's `GarbageCollectedHeap` doesn't move objects. It scans module
globals precisely and the stack conservatively, and **never sees pointers
held only in C++ memory**.

- An object passed to FLTK as `user_data`, with no Oberon reference, was
  freed by a forced `Collect` (`IsAllocated` false), and the callback
  then ran on reused memory.
- Every Oberon object FLTK can call back into must be reachable from a
  module-level root: PLAN.md's registry.
- **The stack scan can keep a lost object alive.** A check that the
  collector frees something can fail where an earlier call left its
  address in stack memory not yet overwritten: `TestText`'s first check
  failed this way on i386 (2026-10-08). `TestText.Scrub` overwrites a
  stretch of the stack with zeros before `Churn`.
- **At `-opt 0`**, poc's default for 32-bit x86, each value in a module
  body has its own stack slot for the whole body, so a reference read
  there stays visible to the scan until the program ends. Read a
  collectable object into a local of a procedure instead
  (`TestText.CheckShown`), so its slot is gone when the procedure
  returns.

### FLTK's behaviour

- **FLTK deletes a group's children with it.** An Oberon handle to a
  child is then stale, and using it crashes in C++.
- **Text drawing needs a font set first.** `fl_draw` of text before any
  `fl_font()` call crashed under Wayland/Cairo.
- **`Fl_Widget::label()` keeps the pointer it is given.** Use
  `copy_label()`, since Oberon strings may die with a stack frame.
- **The `AUTO_DELETE_USER_DATA` user data is deleted however a widget
  dies.** That includes:
  - explicit `delete`;
  - with its parent group, at any depth;
  - `Fl::delete_widget` inside its own callback, at the next
    `Fl::check`;
  - a shown window with its children.

  This is pofltk's deletion hook (`src/pofltk.h`, `Ref`).
- **Replacing a widget's user data deletes the old one**, so pofltk sets
  it once (`ofl::open`), and nothing may set it or the callback again.
  This applies to C++ code for a new class too.
- **FLTK's own default callbacks**:
  - `Fl_Widget::default_callback` queues the widget for `Fl::readqueue`;
  - `Fl_Window::default_callback` calls `Fl::atclose`, which hides the
    window.

  pofltk's callback replaces them on every widget, so the Oberon
  `Callback` defaults call them.
- **`FLTK_BACKEND=x11`** puts FLTK 1.4.5 on X11 (XWayland here). With no
  display, FLTK prints "Can't open display" and exits 1.
- **FLTK prefers Wayland whenever `WAYLAND_DISPLAY` is set**, even when
  `DISPLAY` names an Xvfb server. With it unset, FLTK uses X11 by itself.
- **`Fl_Image_Surface` draws a widget that was never shown**, and its
  pixels read back exactly (`FL_RED` is 255,0,0), on both back ends.
  `Fl_Widget_Surface::draw(w, 0, 0)` puts a child widget's top left at
  0, 0, although it draws in its window's coordinates.
- **`fl_clip_box`'s result is backwards** (0 if clipped, 1 if not),
  against its documentation, and for a box wholly clipped it leaves `H`
  unset (source: `Fl_Cairo_Graphics_Driver::clip_box`). `FlDraw.ClipBox`
  drops the result.
- **A push no widget uses makes the window `Fl::pushed()` and shows
  it** (`Fl::handle_`, "raise windows that are clicked on").
- **Synthesized events work in a window never shown**: set `Fl::e_x`
  and the rest (public statics), then call `Fl::handle(event, window)`.
  Except keys no widget uses, and `FL_DND_LEAVE` to a window with an
  input (above).
- **Non-virtual methods hidden by a subclass** (`Fl_Window::copy_label`,
  `Fl_Slider::bounds`, `Fl_Spinner::color`, `Fl_Flex::end`,
  `Fl_Scroll::clear`, `Fl_Table`'s child methods and others): calling
  through an `Fl_Widget *` or `Fl_Group *` reaches the base's. Before
  binding a method, check the class's header for one that hides a
  base's, and call the class as itself in the shim
  (`doc/fltk-issues.md`).
- **`Fl_Grid::widget` overruns its rows** for a row equal to `rows()`
  or a column equal to `cols()` (it checks `>`, not `>=`): valgrind
  shows an invalid read and write. `Grid.PlaceSpan` checks first
  (`doc/fltk-issues.md`, 21). `layout(rows, cols)` keeps spans past the
  new size, read at the next `layout()`: the shim cuts them first (143).
- **`Fl_Tile` without size ranges doesn't save the sizes a move gives**,
  so a range set later makes the next move put the children back.
  `Tile.SizeRange` saves them first (`doc/fltk-issues.md`, 24).
- **`Fl_Pack` resizes itself as it draws**, to fit its children.
- **Menus** (`doc/fltk-issues.md`, 26 to 29, 33):
  - inserting or removing items moves `value()` to another item, so
    `FlMenus` finds it again by its text pointer;
  - a deleted `global()` menu is used by the next shortcut, so `FlMenus`
    keeps its own;
  - under Wayland a menu popped up over a window not yet exposed kills
    the program (`Popup` waits with `wait_for_expose`), and a pop-up of
    a window without the focus is closed at once;
  - `Fl_Choice::value(int)` hides `Fl_Menu_`'s;
  - clearing a menu in its own callback is safe in 1.4.5, despite
    FLTK's documentation;
  - an item showing an image or a multi-label holds it in its `text`,
    which `remove` and `replace` free and paths read as text (a bug,
    54): each such item has an `ofl::ItemLabel` of its own, and
    `FlMenus.cpp` swaps the item's text in around FLTK's calls;
  - `find_index` takes a path with its labels' `&`s;
  - `add` of a label already in that (sub)menu replaces the item, and
    can't see a hidden item, so a hidden submenu is hidden after it is
    filled (79);
  - `Fl_Menu_::menu` sets the value to the first item; items added
    leave none, and a menu button shows its value under the mouse;
  - a pop-up or pull-down of a menu in no window, with no window shown,
    segfaults, and `Fl_Menu_Item::popup` and `pulldown` do no callback
    (150): `FlMenus` halts 73, and calls `picked`.
- **Dialogs**: `fl_message` and the rest take a printf format, so pass
  text as `"%s"`; `fl_file_chooser`, and `Fl_Native_File_Chooser` using
  FLTK's chooser, keep their title pointer (`doc/fltk-issues.md`, 30,
  31).
- **Text** (`doc/fltk-issues.md`, 34 to 36, 147, 148, 151, 153):
  - a text buffer and its displays don't detach from each other, so a
    buffer deleted first is used after it is freed: `FlText` reference
    counts buffers;
  - a style buffer with no styles makes FLTK read before the style
    table;
  - `search_forward` and `search_backward` with `matchCase` read past
    the end of the text (a bug): the shim searches itself;
    `search_backward` from past the end never returns (139): the shim
    clamps the start;
  - `insertfile`, and so `loadfile`, cut the text at a Latin-1 or
    CP1252 byte in the file's last bytes, with no warning (141): the
    shim reads files itself, decoding as FLTK does;
  - a key that types text never reaches an editor's key binding (147);
    `tab_nav(0)` removes whatever Tab alone is bound to (148);
  - `wrapped_row` and `wrapped_column` read one past the rows for a row
    equal to their count (151), and a display lays its rows out only when
    drawn itself, not its window drawn into a surface;
  - the line number format is copied and used as a printf format, and
    line numbers are drawn only in a shown window (153).
- **Browsers** (`doc/fltk-issues.md`, 37 to 40):
  - `column_widths`, `Fl_File_Browser::filter` and `load` keep their
    pointers: the shim keeps copies;
  - a browser finds its top line only as it draws, so `topline()` and
    `displayed()` are stale until then, and a browser never drawn takes
    no click: draw it first in a test (`Probe.Capture`);
  - `Fl_Browser::textsize` and `Fl_File_Browser::textsize` hide
    `Fl_Browser_`'s;
  - `Fl_Browser::icon` keeps the image, and a line removed drops it
    unseen (56): the browser keeps the images its lines show;
  - `Fl_Browser::load` adds an empty last line after a final newline;
    `Fl_File_Browser::load` returns the directory's entries;
  - a browser calls back on every release, changed or not, and a check
    browser not at all, to start with.
- **Trees** (`doc/fltk-issues.md`, 41 to 43, 58, 59):
  - FLTK makes and deletes items itself, so a `TreeItem` is checked
    against the tree's map of live items before every use;
  - `Fl_Tree::remove` leaves a descendant of the item as the last one
    clicked, and the callback item after removal: the shim removes
    descendants one by one, and clears the callback item;
  - `clear()` deletes the root;
  - `Fl_Tree_Item::is_visible()` is the item's own flag;
    `is_visible_r()` is whether its parents are open;
  - an item's widget is the tree's child, which FLTK leaves in the tree
    when the item goes, still taking clicks (58): the shim deletes it
    with the item;
  - an item removed in the tree's callback as it is pushed becomes the
    last one clicked after it is freed, and a drag moves it (a bug,
    59): the tree clears that after an event with removals;
  - a tree and its items keep their icons' pointers, and the tree
    makes inactive copies, an item not (78): the tree's `Ref` keeps
    them;
  - `Fl_Tree::add`, `insert`, `remove` and `clear` hide `Fl_Group`'s;
    `Fl_Group::on_remove` is virtual in 1.4.
- **Images** (`doc/fltk-issues.md`, 44 to 47):
  - a widget keeps the image it is given, so `Ref` holds it, counted,
    until the widget dies;
  - an empty label is laid out as a line of text, which moves a label
    image: every label goes through `ofl::label_text`;
  - a binary PNM with a maxval under 255 is read unscaled (a bug): the
    shim scales it;
  - XPM color names are read only on X11; Wayland has no window icons;
  - `Fl_Multi_Label::label(Fl_Widget *)` leaves a copied label marked
    to be freed, so the widget frees the multi-label (a bug, 55): the
    shim clears the label first;
  - `copy_label` keeps the label type, so text set on a widget showing
    a multi-label sets the type back to `FL_NORMAL_LABEL`.
- **The clipboard** (`doc/fltk-issues.md`, 48 to 50):
  - X11's `Fl::copy` before the display is open crashes (a bug): the
    shim opens it first;
  - a pasted image FLTK makes must be deleted by the program unless it
    keeps it, and Wayland leaks the program's own (a bug): `W<B>::handle`
    deletes any not taken;
  - Wayland has no selection buffer.
- **Preferences** (`doc/fltk-issues.md`, 51): a group's `Fl_Preferences`
  outlives its node, deleted with the group or the database.
- **Bitmaps, XBM and ICO** (`doc/fltk-issues.md`, 80 to 82): a bitmap's
  `fail()` is always -1, so judge it by its data and size.
  `Fl_XBM_Image` takes almost any text with two `#define`s, leaves
  missing bits unset, and leaks its array: the shim parses XBM itself,
  from a file or memory. `Fl_ICO_Image` in memory calls `fopen(NULL)`
  for a PNG resource: the shim decodes that.
- **Shared images** (`doc/fltk-issues.md`, 83, 84): `reload()` of a
  scaled entry changes its data size, the pool's sort key.
  `Fl_Shared_Image::copy` is the pool's own entry, and a tree or a
  tiled image would gray or delete it, so they show a private copy. A
  scaled entry holds a reference to its original.
- **File icons** (`doc/fltk-issues.md`, 85, 86): `Fl_File_Icon::label`
  sets no measure, so the icon is measured as text. `load_image`
  crashes on an SVG or `notxbm.h`, `load` returns nothing, and
  `load_fti` returns 0 on bad data: `FileIcon.Load` decodes through
  `load_file`, and catches `Fl::error`.
- **Crafted image files** (`doc/fltk-issues.md`, 87, 88):
  `Fl_BMP_Image` trusts its color count, and `Fl_GIF_Image` follows a
  cycle in its code table and writes past an empty image, overrunning
  the stack and heap with a file's bytes. The shim refuses such files;
  what FLTK loads by itself (the chooser's previews) stays exposed.
  An animation's frames must fit its screen; such a GIF still `Load`s.
- **File choosers** (`doc/fltk-issues.md`, 91 to 93): deleted in its
  own callback it is used after, and an extra widget deleted first is
  read at the next `add_extra`. `filter()` is the pattern in use.
  `count()` and `value()` with nothing chosen give its field, its first
  directory. `preview(e)` writes the user's preferences, so a test puts
  it back.
- **`fl_filename_relative`** (`doc/fltk-issues.md`, 94) returns 0, "no
  change", for `.`, clears `to` before reading `from`, and goes by the
  text alone: `/a//b` against `/a/b` is `..//b`.
- **Image handlers** (`doc/fltk-issues.md`, 95): FLTK owns what a
  handler returns, so `FlImages` gives it a copy; `GetShared` and
  `Reload` don't reach FLTK's handlers, so `load_shared` asks the
  Oberon ones itself.
- **Help views** (`doc/fltk-issues.md`, 89, 90, 93): a link held down
  while the page changes reads freed memory, and a link function
  returning NULL for an image crashes: `FlHelp.cpp` covers both. `load`
  opens web and mail addresses in the user's browser before asking the
  link function, so no test may load one. Each page laid out calls
  back. A `<title>` counts only in `<head>`. `Fl_Help_Dialog`'s
  constructor leaves no current group.
- **Terminals** (`doc/fltk-issues.md`, 96 to 99): a screen made smaller
  leaves the cursor, and the place `ESC[s` saved, off the grid, and the
  next character is written outside the row: `Term::fit`. `restore_cursor`
  tests `col != 1`, so column 1 isn't restored. `error_char` keeps its
  pointer, overruns a cell past 4 bytes, and a control character there
  recurses without end. `textsize` below 1 divides by zero. `cursor_tab_right` and
  `cursor_tab_left` ignore their count (140). `PER_WRITE` redraws only
  the first write, and a write waiting for `RATE_LIMITED`'s timer is
  lost when the style changes (142): `Term` clears FLTK's flag. `print_char`,
  `plot_char`, the cursor's moves and the clears don't redraw. A byte
  like `FF` waits for a long form's rest, and shows nothing.
- **Forms** (`doc/fltk-issues.md`, 105 to 107): `Fl_Free`'s timer sends
  event 0, not `FL_STEP`; its header's event numbers aren't its
  documentation's; its handler is called from its destructor, and takes
  the key as a `char`. `set` of `Fl_FormsBitmap` and `Fl_FormsPixmap`
  leaks, keeps its pointer and deletes the image it had. An image is
  drawn at the widget's top left. `Fl_Timer`'s direction is the opposite
  of its header's. FLTK's `configure --disable-forms` builds, but its
  `make install` fails on an empty library name; CMake's
  `FLTK_BUILD_FORMS=OFF` works.
- **Plugins** (`doc/fltk-issues.md`, 108): one name twice in a class is a
  use after free; `plugin(i)` out of range makes a group; a `/` in a
  name makes nested groups; `loadAll` sorts with `fl_numericsort` (63).
  A manager's index is oldest first.
- **OpenGL** (`doc/fltk-issues.md`, 109 to 111, 113): `gl_start` always
  crashes under Wayland. `can_do` with no display open crashes.
  `make_current` of a window not shown, and `gl_font` or `gl_draw` with no
  context, crash; `Fl_Window::current()` stays after a hide and dangles
  after a delete. `Fl_Gl_Window::init` calls `end()`, so its widgets need
  `Begin` and `End`, and `Draw` must call the base's to show them. Wayland
  adds `FL_DOUBLE` to every mode. FLTK without GL still installs GL's
  headers.
- **GL text's texture pile** (`doc/fltk-issues.md`, 152): a height of 0
  divides by zero, and a negative one segfaults, at the next text drawn
  with textures (GL 3 or later, or a texture rectangle extension).
- **GLUT** (`doc/fltk-issues.md`, 112): numbers unchecked, strings kept,
  and hiding or destroying a window in its display function is a use after
  free in `Fl::flush`. Any event makes its window current. Windows past
  the 31st share number 32. `glutSwapBuffers` in a display function does
  nothing. `glutMainLoop` is `Fl::run`, and returns. The display and
  overlay procedures are called unchecked, so a NULL one crashes (145): the
  shim always gives FLTK its own. The overlay takes a window hidden or never
  shown: it is `glDrawBuffer(GL_FRONT)` on the current context (145), and
  once made it is drawn at every flush, after a hide too.
- **The vector font** (`doc/fltk-issues.md`, 146): a dot is column * 8 +
  row, so the top left one is a 0, ending its letter; `Fonts.Mod` stores
  each command plus 1, and its saved table leaves that dot out.
- **GL text** (`doc/fltk-issues.md`, 134, 135): `gl_draw` of text with no
  width crashes in making its texture: a line feed, `0X`, U+200B, and so
  `glutBitmapCharacter` of them, on both back ends, so the shim draws only
  what has a width. `glutBitmapCharacter` moves the raster position by the
  texture's width, a multiple of 4, not the character's, and it takes a
  raw byte where `glutBitmapWidth` takes a character: the shim
  encodes the character in UTF-8 (135). GLUT font numbers
  are cut to a byte. A stroke capital is 100 units tall, and the stroke
  measures need no window.
- **Cairo** (`doc/fltk-issues.md`, 114): `Fl_Cairo_Window` is only in
  an FLTK built for it, and under Wayland its context is FLTK's own, so
  one `cairo_restore` too many stops the window for good. `fl_wl_gc()` is
  there without the option. It is valid only with the display current.
  `has_feature(NATIVE)` is 0 on Cairo drivers, so test the surface. Cairo
  doesn't check an enumeration, clamps a negative radius, and refuses a
  scale of 0. `make_current` and `fl_read_image` read a shown window on
  X11 and Wayland.
- **UTF-8** (`doc/fltk-issues.md`, 115 to 118): the composed-character
  walks and `fl_utf8strlen` go past either end of the text, on a bad or
  cut-short lead. `fl_utf_tolower` has no size and no `0X`; a
  bad byte decodes as CP1252 (80 to 9F) or Latin-1, not U+FFFD, at most
  3 bytes (116). `fl_utf8toa`'s
  count past a short buffer isn't its count in a long one. In a UTF-8
  locale `fl_utf8to_mb` writes nothing to a short buffer. There is no
  `fl_utf8_to_locale` off Windows.
- **Filenames** (`doc/fltk-issues.md`, 119 to 122): `fl_filename_absolute`
  cuts the base to `tolen`, then reads before its copy. `fl_filename_expand`
  aborts on a value too long and never ends on `SELF='$SELF'`.
  `fl_filename_isdir` overruns on 4096 bytes and a `/`.
  `fl_filename_match` reads past an open `[` or `{`.
- **Drawing's free functions** (`doc/fltk-issues.md`, 123 to 128, 133): a
  symbol name outside ASCII hashes negative on x86, and the table holds
  105. With no current window, `fl_overlay_rect`, `fl_scroll` and
  `fl_antialias()` crash. `fl_expand_text` loses a buffer it makes, and
  stops at `@x`. `fl_local_to_mac_roman`'s first call writes to NULL
  unless `n` is 0. `fl_capture_window` and Wayland's `fl_read_image`
  don't clip. `fl_restore_clip` on Cairo drops a pushed clip.
  `fl_chord` is declared and defined nowhere. Always pass
  `fl_draw_image` an explicit line size. On Xlib, an image drawn in
  `fl_draw_image`'s line callback spoils the outer one, or writes to
  freed memory (133): `FlDraw` halts.
- **`Fl`'s statics** (`doc/fltk-issues.md`, 129 to 132): `grab` and
  `selection_owner` aren't cleared when their widget dies: `W<B>`'s
  destructor does. Font numbers have no bounds: `Fl` tracks the end
  (`font_end`), and a name is at most 126 bytes, kept. `Fl::ready`,
  `selection`, `enable_im`, `disable_im` and `set_box_color` need the
  display open. `FL_SELECTIONCLEAR` is never sent. `Fl.SetScheme` can't
  pass NULL, which reads the system's scheme. `set_abort`'s handler must
  not return: the shim exits 1 if it does.
- **Smaller things found binding the free functions** (2026-10-31):
  - `Fl::get_mouse` works with no display. `screen_dpi` of a bad number
    gives 0 0, and `screen_scale` 1. `visual(FL_DOUBLE|FL_INDEX)` is 0 on
    X11 and 1 on Wayland, and `compose` with no event likewise.
  - `fl_parse_color` knows names on X11 alone. `fl_lightness` is L\*, 0
    to 100; `fl_luminance` is 0 to 1.
  - `fl_decode_uri`: a bad `%` stops it, `%00` cuts the text, `%4z` is
    byte 4 and `%-1` is `FF`.
  - `fl_filename_ext` is never NULL, and `.bashrc`'s extension is all of it.
  - `fl_message_icon_label` keeps its pointer until the next dialog;
    `fl_file_chooser_ok_label` and `ok_label` keep theirs.
  - `fl_frame` and `fl_frame2` read four characters per loop.
  - `fl_draw_pixmap` and `fl_measure_pixmap` trust their data.
  - `fl_create_offscreen(0, 0)` is an X error. `fl_set_spot`'s window is
    ignored. `fl_draw_box_focus` draws no box. `fl_draw_symbol` doesn't
    set the color.
  - `reload_scheme` overrides boxtypes, the scrollbar size and every
    window's label type, align and image.
  - `Fl::handle(FL_CLOSE, NULL)` calls through NULL, and `set_boxtype`
    and `get_boxtype` don't check their index (the source).
  - A window's image cursor: X11 refuses a hot spot outside it and
    copies at its size; Wayland keeps a copy and doesn't check; both do
    nothing for a window not shown.
  - A program's own copies don't trigger a clipboard notice.
- **Dashes, masks and copies** (`doc/fltk-issues.md`, 136 to 138): a
  dash pattern of 256 lengths overruns on Cairo and PostScript, and a
  negative one or one past 127 draws nothing; lengths are pixels, and
  OpenGL ignores them. `Fl_Image_Surface::mask` reads 3 bytes a pixel
  whatever the depth, and a second one with no `image()` leaks. Deleting
  an `Fl_Copy_Surface` writes the clipboard, with no way to abandon it.
- **Printing** (`doc/fltk-issues.md`, 100 to 103): text with no font
  set crashes on PostScript, PDF and EPS. A Cairo error makes
  `Fl_PostScript_File_Device::end_job` write to a closed file and close
  it twice; `FlPrint`'s `Sink` covers files and its own calls, but
  drawing through `FlDraw` that breaks Cairo still reaches it. PDF's
  `end_job` reports only by an alert. An SVG surface has no font
  descriptor, so test `fl_size()` too. The print panel is built once,
  keeping its texts' pointers, so `FlPrint` keeps every text (144). A window never shown isn't
  visible, so no surface draws it.
- **Tables** (`doc/fltk-issues.md`, 52): `Fl_Table` hides `Fl_Group`'s
  `begin`, `end`, `children`, `child`, `add` and the rest, which reach
  the inner group holding the cells' widgets: Fl.cpp calls a table as
  an `Fl_Table`.
- **Command-line options** (`doc/fltk-issues.md`, 57): FLTK keeps
  pointers into `argv`, and poc's `Args.argv` is C's own, which lasts
  the program's life. `Fl::args` returns 0 for an unknown option only
  until it has once stopped at a word that isn't an option: the shim
  decides from the word.
- **Charts** (`doc/fltk-issues.md`, 60, 65): `maxsize(0)` drops every
  entry, though 0 is no limit; an entry's label is cut to 18 bytes
  in the middle of a UTF-8 character.
- **Window shapes** (`doc/fltk-issues.md`, 61): X11's driver reads an
  RGB image's drawn size from its data, past their end if it is drawn
  larger, and keeps the image: FlImages gives it a copy. Wayland
  supports shapes too.
- **Animated GIFs** (`doc/fltk-issues.md`, 62, 64): an animation's
  timer redraws its canvas, deleted or not, so FlImages' animation
  watches the canvas; a copy plays whenever the original has a frame
  shown.
- **`fl_numericsort` is wrong** (`doc/fltk-issues.md`, 63): it skips
  the character after a run of digits, and reads past a name's end
  after one. pofltk sorts with its own (`ofl::numericsort`), and sets
  it as FLTK's file chooser's.
- **Clocks** (`doc/fltk-issues.md`, 74, 76): `value(ulong)` crashes on
  a time `localtime` can't convert, and writes over what it was given
  once the hands move, so the shim calls it twice; a running `Fl_Clock`
  reads as seconds past midnight. `Fl_Round_Clock` is also `FL_NO_BOX`,
  not just a type.
- **Tooltips** (`doc/fltk-issues.md`, 75): `enter_area` keeps its text,
  and knows it by its pointer, and can still read it after a later ""
  (its timer, armed after hiding the last tip) or a text given while
  tooltips are off: the shim frees a copy only when FLTK has taken
  another; `Fl_Tooltip::current` leaves none
  current for a widget with no tooltip, nor a group around it with one.
- **`Fl_File_Input`'s bar** takes a click in a shown window alone under
  Wayland: `make_current` of one not shown is an alert, then a fatal
  error (`doc/fltk-issues.md`, 77). `Probe` tests show the window first.
- **`Fl_Shortcut_Button`** takes keys until it loses the focus, and by
  default calls back only then (`FL_WHEN_RELEASE`). A nice slider has
  `FL_FLAT_BOX`. `Fl_Positioner` has `FL_DOWN_BOX`, against its header.
- **Full screen and iconize** (`doc/fltk-issues.md`, 149): a window shown
  with no resizable widget gets a fixed size range for good, so
  `fullscreen()` does nothing; `fullscreen_screens` is unchecked, and
  Wayland ignores it; `iconize` of a window not shown shows it minimized,
  and of a shown one needs a window manager on X11. Window icons and
  default icons are copied, and Wayland ignores them.
- **`show(argc, argv)`** (`ShowArgs`) loads the system's colours, which
  even at the default background moves `FL_DARK3` and `FL_DARK1` off
  `show()`'s, on X11 and Wayland (`doc/fltk-issues.md`, 154).
- **Schemes** (`doc/fltk-issues.md`, 156): every `Fl::scheme()` writes
  `FLTK_SCHEME`, which `scheme(NULL)` (`SetSystemScheme`) reads before
  X11's `fltk.scheme` resource, so after a `SetScheme` it gives that
  scheme back.
- **`Fl_Input_::index`** doesn't check its position (155): `Index`
  halts 74 outside 0 to the text's length.
- **A scroll's scrollbar align** starts as `FL_ALIGN_BOTTOM`, a
  valuator's label align; without `Left` and `Top` the bars are right
  and bottom.
- **An output widget** (`set_output`) is passed over by its group's
  routing, but its window still reports a push on it used.
- **Screens**: `Fl::screen_num` is 0 for a point on no screen.
  xvfb-run's default screen is 640x480; `tools/with-sway.sh`'s output
  is 1280x800.
- **Name clashes with FLTK's keys**: the key constants take the prefix
  `Key`, since `FL_End` would be the keyword `END`. So `Fl::get_key` is
  `GetKey`, because `KeyDown` is the down arrow.
- **`fltk-config --cxxflags`** includes `-I/usr/include` and Fedora's
  build flags (`-specs=...`). Pass only its `-I`/`-D` flags, without
  `-I/usr/include`.
- **No memory errors under valgrind** in FLTK's display stack, on either
  back end, only leaks (Valgrind, above).

### poc problems

Worked around here. Check whether each new poc fixes them, then remove the
workaround.

None at present.

- **poc 0.11.2** (2026-11-07): pofltk builds with it unchanged, and
  `make test-headless`, `test-sway`, `valgrind-headless` and
  `valgrind-sway` pass here (2458, 2437, 2249 and 2229 `ok` lines, 1, 8,
  1 and 7 skipped; every valgrind error summary 0), as `make test` does
  on all six BSDs (2458, 1 skipped, on NetBSD and FreeBSD; 2450, 2
  skipped, on OpenBSD). The changes since 0.10.1 that could touch pofltk
  all fail at compile time, none silently: 0.11.0 refuses a function
  called as a statement and adds predeclared unsigned types and `VAL`;
  0.11.1 emits a string literal in an array index, which before failed
  to build (poc's ongoing bug 18).
- **poc 0.10.1** (2026-10-30): pofltk builds with it unchanged, before
  Phase 14: `make test-headless`, `test-sway`, `valgrind-headless` and
  `valgrind-sway` pass here (823, 819, 753 and 749 `ok` lines; every
  valgrind error summary 0), as `make test` does on all six BSDs (823).
  After Phase 14, the same runs give 932, 928, 849 and 845 here, and
  932 on all six BSDs, on an FLTK with neither Cairo nor Pango (932),
  and on one without SVG (932, 2 skipped). After Phase 20, the same
  runs give 1664, 1660, 1521 and 1517 here, with `ok` lines of the
  halt tests and examples counted; 1664 on NetBSD and FreeBSD and 1656,
  1 skipped, on OpenBSD; 1654, 3 skipped, with neither Cairo nor Pango;
  1562, 19 skipped, with no SVG or printing; and 1592, 3 skipped, and
  Forms not built, with no Forms. After Phase 21, 1780, 1770 (3 skipped),
  1621 and 1612 (2 skipped) here; 1780 on NetBSD and FreeBSD and 1772,
  1 skipped, on OpenBSD; 1770, 3 skipped, with neither Cairo nor Pango;
  1562, 19 skipped, with no SVG, printing or GL; 1718 with no Forms;
  1664 with no GL; 1778 with no GLEW. After Phase 22, 1823, 1813 (3
  skipped), 1656 and 1647 (2 skipped) here; 1823 on NetBSD and FreeBSD
  and 1815, 1 skipped, on OpenBSD; 1813, 3 skipped, with neither Cairo nor
  Pango; 1605, 19 skipped, with no SVG, printing or GL; 1761 with no
  Forms; 1707 with no GL; 1821 with no GLEW; 1779 with no cairo; and on
  a Wayland FLTK without `FLTK_HAVE_CAIRO`, 1823 on Xvfb and 1813 on sway.
  After Phase 23, 2274, 2264 (3 skipped), 2078 and 2069 (2 skipped) here;
  2274 on NetBSD and FreeBSD and 2266, 1 skipped, on OpenBSD; 2264, 3
  skipped, with neither Cairo nor Pango; 2056, 19 skipped, with no SVG,
  printing or GL; 2212 with no Forms; 2158 with no GL; 2272 with no GLEW;
  2230 with no cairo; and on a Wayland FLTK without `FLTK_HAVE_CAIRO`,
  2274 on Xvfb and 2264 on sway. After GLUT's fonts, 2333, 2323 (3
  skipped), 2133 and 2124 (2 skipped) here; and 2323, 3 skipped, with
  neither Cairo nor Pango. The other runs, made with one more check, which
  that FLTK showed depended on the back end: 2334 on NetBSD and FreeBSD
  and 2326, 1 skipped, on OpenBSD; 2056, 19 skipped, with no SVG, printing
  or GL; 2272 with no Forms; 2158 with no GL; 2332 with no GLEW; 2290 with
  no cairo; and on a Wayland FLTK without `FLTK_HAVE_CAIRO`, 2334 on Xvfb
  and 2324 on sway. After copy surfaces, masks and dashes, 2356, 2346 (3
  skipped), 2151 and 2142 (2 skipped) here; 2356 on NetBSD and FreeBSD and
  2348, 1 skipped, on OpenBSD; 2346, 3 skipped, with neither Cairo nor
  Pango; 2078, 19 skipped, with no SVG, printing or GL; 2294 with no
  Forms; 2181 with no GL; 2354 with no GLEW; 2312 with no cairo; and on a
  Wayland FLTK without `FLTK_HAVE_CAIRO`, 2356 on Xvfb and 2346 on sway.
  After FLTKAda's findings (2026-11-06), 2380, 2370 (3 skipped), 2175
  and 2166 (2 skipped) here; 2380 on NetBSD and FreeBSD and 2372, 1
  skipped, on OpenBSD. After the three to-do items (2026-11-06), 2383, 2373 (3
  skipped), 2178 and 2169 (2 skipped) here, the valgrind runs with the
  stricter `vg-check.sh`; 2383 on NetBSD and FreeBSD and 2375, 1
  skipped, on OpenBSD. After Phase 24 (2026-11-07), 2458 (1 skipped:
  `Iconize` needs a window manager on X11), 2437 (8 skipped; 2400 was
  first recorded, a miscount: the commit gave 2437 when rerun), 2249 (1
  skipped) and 2229 (7 skipped) here; 2458, 1 skipped, on NetBSD and
  FreeBSD and 2450, 2 skipped, on OpenBSD. One `test-headless` log
  showed 2462, with TestGlut's last four checks and its "All checks
  passed." twice, after a stray line; three reruns of TestGlut printed
  them once. After `ShowArgs` in the ports (2026-11-07), the same: 2458,
  2437, 2249 and 2229 here, and 2458 on NetBSD and FreeBSD and 2450 on
  OpenBSD, with the same skips. After Phase 25 (2026-11-07), 2517 (1 skipped), 2496 (8
  skipped), 2281 (1 skipped) and 2261 (7 skipped) here; 2517, 1
  skipped, on NetBSD and FreeBSD and 2509, 2 skipped, on OpenBSD; 2507,
  4 skipped, with neither Cairo nor Pango; 2227, 20 skipped, with no
  SVG, printing or GL; 2455 with no Forms; 2331 with no GL; 2515 with no
  GLEW; 2473 with no cairo; and on a Wayland FLTK without
  `FLTK_HAVE_CAIRO`, 2517 on Xvfb and 2496 on sway.
- **poc 0.6.0** (2026-10-15): pofltk builds with it unchanged, and
  `make test-headless`, `test-sway`, `valgrind-headless` and
  `valgrind-sway` all pass here (823, 819, 753 and 749 `ok` lines; every
  valgrind error summary 0, and `vg-check.sh` finds no leak of
  pofltk's), as `make test` does on cymoril and yishana (below). Its
  changes that could affect pofltk:
  - **`FOR` ends at its last value**: after `FOR i := 1 TO 3`, `i` is 3,
    not 4. A search of `src/`, `test/` and `examples/` found no `FOR`
    variable read after its loop.
  - **`REAL` constant expressions fold in single precision**, as `REAL`
    variables compute.
  - **Unsigned types** (`SYSTEM.CARD8` to `CARD64`, `CARD`) are not
    used. They don't mix with signed integers without `SYSTEM.VAL`, so
    a colour as a `CARD32` (an `Fl_Color` is unsigned, and an RGB colour
    is a negative `INTEGER`) would put `SYSTEM.VAL` into every colour
    computation, users' too; `-strict` rejects them; and `int32_t` and
    `uint32_t` cross the C boundary alike.
  - The makefile still requires only 0.4.1, the oldest that works.
- **Fixed in 0.4.1: `ORD` of a `SET` under `-OC`** (2026-10-06). In
  0.3.1 and 0.4.0 any use failed to compile, poc emitting
  `trunc i32 %x to i32`, which clang rejects. 0.4.1 compiles
  `ORD({0, 2, 31})` into an `INTEGER`, a `SYSTEM.INT32` and a `HUGEINT`
  with the right value, and the `SYSTEM.VAL(SYSTEM.INT32, s)`
  workarounds are gone.

### Carried from polibfyaml, re-checked or documented for 0.3.1

- **`ASSERT(x, n)` exits with status 10**, printing
  `assertion failed (n)`, not with `n`. A NIL dereference, including a
  method call on NIL, exits 4. A constant-FALSE `ASSERT` is a compile
  error. (Reference Guide §6.)
- **String literals have no length limit** in 0.3.1, per the Reference
  Guide. 0.1.0's limit was 255.

### Carried from polibfyaml, not yet re-checked

- **No call chaining**: a function result isn't a designator, so
  `a.Parent().Label()` doesn't compile.
- **Comments nest, and `*)` ends a comment anywhere**: don't write C
  wildcards like `fl_*)` in comments, and quote text like `("*name")`.
- **`ORD` takes a `CHAR` or a `SET`, not a `BOOLEAN`.** Never pass a
  `BOOLEAN` across the C boundary; use an `int32_t` 0 or 1.
- **Real literals are `REAL` unless written with `D`.** Write `0.5D0`
  for a `LONGREAL` such as a timeout.
- **`Out` writes at once** (no buffering).
- **Finalizers run when the program ends**, by any path (return from
  the main module, `HALT`, `ASSERT`, a trap, `Platform.Exit`), so a
  valgrind leak report is meaningful.

## Conventions

- **Claim only what has been verified.** When a comment or decision
  depends on how FLTK or poc actually behaves, write a throwaway program
  in the scratchpad, run it, and only then record the result: here under
  "Confirmed facts", and in PLAN.md. Check actual values, not just the
  absence of a crash: valgrind can't see a pointer into a dead stack
  frame.
- **Before binding anything that takes a pointer**, find out from the
  FLTK source whether FLTK copies it or keeps it. If it keeps it, the
  memory must belong to an Oberon object that outlives the FLTK object
  (PLAN.md, "Strings and memory handed to FLTK").
- **The C++ parts** take and return only `int32_t`, `uint32_t`,
  `intptr_t` and `double`, inside `extern "C"`. They mirror no C++ struct
  as an Oberon record, and let no C++ exception escape. Copy FLTKAda's
  shim code where it fits (public domain), noting the source in a
  comment.
- **Keep `["C"]` procedures unexported.** Wrap each in an exported Oberon
  procedure, so the handle stays hidden and the wrapper can check for a
  dead widget.
- **Cleanup is idempotent.** Set a handle to 0 when its object is freed
  or found dead, and make every method check for 0.
- **Programmer errors halt** with the codes in PLAN.md, "Halt codes".
  Bad outside data never halts; it comes back as a `BOOLEAN` result.
- **Comments explain why.** Match the surrounding code's comment density
  and naming.
- **Record every FLTK problem in `doc/fltk-issues.md`** as it is found:
  a bug (a crash, or behaviour against FLTK's documentation) or a
  pitfall a binding must allow for. Use the form the file gives: what
  happens, the cause in FLTK's source, the effect on pofltk and its
  workaround, and how it was confirmed. Keep the shorter note under
  "FLTK's behaviour" below too.
- **Record decisions and findings in PLAN.md as they happen**: append to
  the relevant section, mark finished phases `[done]`, and strike through
  decided open questions.
- **Commit only when asked.** Commit messages are short and say why, as
  in polibfyaml and FLTKAda.
