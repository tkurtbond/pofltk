# pofltk design plan

pofltk is an Oberon-2 binding to FLTK, the Fast Light Toolkit, compiled
with poc, the Peaseblossom Oberon Compiler. `doc/design.md` is the
feasibility analysis that started it (2026-10-06): what was tested, what
broke, and why the binding is worth writing. This file is the design and
roadmap. AGENTS.md has the operational notes: tool paths, build commands,
and the confirmed poc and FLTK facts this plan relies on.

Organize additions by section: append to the relevant section rather than
starting a new document, mark a finished phase `[done]`, and strike
through an open question once it's decided, saying what was decided.

## Prior art

- **FLTKAda** (`/usr/local/sw/src/tkb/fltkada`), a thick Ada binding to
  FLTK, public domain (Unlicense). Its C++ shim (`body/c_fl_*.cpp`, about
  180 classes, 17k lines) flattens FLTK to `extern "C"`, and its
  `doc/binding_architecture.md` explains the `My_X` subclasses that send
  FLTK's virtual `draw()`/`handle()` back into Ada. Its pitfalls (§8) and
  1.4.5 gap analysis (§7) apply to any FLTK binding. Its `test/` has Ada
  ports of FLTK's test programs, a ready list of examples to port.
- **polibfyaml** (`~/Repos/Oberon/polibfyaml`), an Oberon-2 binding to a C
  library with poc. Its build, test layout, halt tests, valgrind setup and
  conventions are this repo's model; its AGENTS.md lists poc facts that
  still apply (AGENTS.md here repeats the ones that matter).
- **The prototype** (`prototype/`, retired in Phase 3; in git up to
  f57262b) and **probes** (`probes/`): the code behind `doc/design.md`.
  Throwaway, but the starting point for Phase 0.

## Scope

In scope: an Oberon-2-idiomatic binding to the parts of FLTK 1.4 an
application uses:
- widgets, groups and windows;
- the event loop, timeouts, idle and file-descriptor callbacks;
- custom widgets (overriding draw, handle and resize);
- the drawing API, menus, dialogs, text editing, browsers, images, and
  the clipboard.

Out of scope, at least at first:
- **Threads** (`Fl::lock`, `Fl::awake`): poc's collector scans one stack.
- **The platform graphics drivers and the FLTK 1.3 API.**

OpenGL and GLUT, printing and the file surfaces, and `Fl_Terminal` were
out of scope until 2026-10-30. Phases 14 to 22 bring them in.

Later, if wanted: a FLUID back end that writes Oberon-2 instead of C++.

## Target versions

- FLTK **1.4.5** (Fedora `fltk-devel-1.4.5`; source in
  `/usr/local/sw/src/lang/C++/fltk`). 1.4 is required: `Fl_Flex`,
  `Fl_Grid`, and `AUTO_DELETE_USER_DATA` (the deletion hook below) are
  new in 1.4.
- poc **0.4.0** or later (installed 2026-10-06). pofltk relies on its two
  changes, made for this binding:
  - **a module's C++ part**, `<Module>.cpp`, compiled by clang++, with
    programs that use one linked by clang++;
  - **libraries that record their `-link` flags**, so a program using
    pofltk needs no FLTK or C++ flags.

  The makefile refuses an older poc.
- Platforms: x86_64 Fedora first, under Wayland and X11. The BSDs poc runs
  on come later; FLTKAda's readme has NetBSD notes.

## Architecture

```
application modules           (Oberon-2; extend Fl types, override methods)
        |
pofltk modules  Fl, FlDraw, ...      (Oberon-2: objects, registry, policy)
        |      ["C"] procedures, unexported
C++ parts      Fl.cpp, FlDraw.cpp, ...  (extern "C" shim, ofl::W<B>)
        |
FLTK 1.4 (C++)
```

### Modules

Oberon modules are flat, and a type-bound procedure must be declared in
its receiver type's module, so each module holds a family of widget types
together with their methods and their part of the shim:

| Module | Contents |
|---|---|
| `Fl` | `Widget`, `Group`, `Window`, `DoubleWindow`, `Box`; the registry; the event loop, timeouts, idle and fd callbacks; colors, fonts, box and label types; event queries (`Fl::event_x` and friends); schemes |
| `FlDraw` | the `fl_draw.H` API: colors, lines, shapes, paths and transformations, text, fonts, clipping, measuring, boxes and symbols; offscreen drawing with images (Phase 7) |
| `FlButtons` | `Button`, `CheckButton`, `LightButton`, `RoundButton`, `RadioButton`, `ReturnButton`, `RepeatButton`, `ToggleButton` |
| `FlInputs` | `Input`, `IntInput`, `FloatInput`, `MultilineInput`, `SecretInput`, `Output`, `MultilineOutput` |
| `FlValuators` | `Slider` (and its kinds), `Counter`, `Dial`, `Roller`, `Spinner`, `Adjuster`, `ValueInput`, `ValueOutput`, `Scrollbar`, `Progress` |
| `FlLayout` | `Flex`, `Grid`, `Pack`, `Scroll`, `Tabs`, `Tile`, `Wizard` |
| `FlMenus` | `MenuBar`, `MenuButton`, `Choice`, menu items |
| `FlDialogs` | `fl_message`/`fl_alert`/`fl_choice`/`fl_input`/`fl_password`, `fl_color_chooser`, `fl_show_colormap`, `fl_file_chooser`/`fl_dir_chooser`; `NativeFileChooser` (Phase 7) |
| `FlText` | `TextBuffer`, `TextDisplay`, `TextEditor`, style tables |
| `FlBrowsers` | `Browser`, `HoldBrowser`, `MultiBrowser`, `SelectBrowser`, `CheckBrowser`, `FileBrowser`, `Tree` |
| `FlImages` | `Image`, `RGBImage`, PNG, JPEG, GIF, SVG, BMP, XPM loading (`-lfltk_images`) |
| `FlPreferences` | `Preferences`: `Fl_Preferences` databases and their groups |
| `FlTable` | `Table`, `TableRow`: `Fl_Table` and `Fl_Table_Row`, their cells drawn by the program |
| `FlHelp` (Phase 17) | `HelpView`, `HelpDialog` |
| `FlUtf8` (Phase 23) | `fl_utf8.h`'s text functions |
| `FlTerminal` (Phase 18) | `Terminal`: `Fl_Terminal` |
| `FlPrint` (Phase 19) | `Printer`, `PostScriptFile`, `PDFFile`, `EPSFile`, `SVGFile` and their bases |
| `FlForms` (Phase 20) | `Timer`, `Free`, `FormsBitmap`, `FormsPixmap`, `FormsText` (`-lfltk_forms`), its own library |
| `FlGl`, `FlGlut` (Phase 21) | `GlWindow`, `gl_draw`, a subset of `gl.h`; `glut.H` (`-lfltk_gl`), their own library |
| `FlCairo` (Phase 22) | `CairoWindow`, a subset of cairo (`-lcairo`), its own library |

`Fl` exports a few procedures that only the other pofltk modules should
use (attaching a new widget's handle, registering it), as polibfyaml's
`Fyaml` exports its "For FyamlStreams" hooks: Oberon has no friend
modules. Mark them so in their comments, and keep application code off
them.

### Object model

- `Widget* = POINTER TO WidgetDesc`. The record holds the C++ handle as a
  read-only `SYSTEM.ADDRESS`, plus a registry link. Each FLTK class is an
  extension; an application extends those in turn.
- **Construction**: `NEW(w); FlButtons.OpenButton(w, x, y, w, h, label)`
  style, so an application's own extension can be allocated by its own
  `NEW` and still be opened as the FLTK class it extends. The prototype
  already works this way. FLTKAda's `Forge` packages solve the same
  problem in Ada.
- **Groups**: FLTK's implicit `begin()`/`end()` "current group" is kept,
  because FLTK's own docs and examples assume it. Explicit `Add`/`Insert`
  are bound too.
- **Overridable behaviour** is type-bound procedures:
  - `Draw`, `Handle(event): BOOLEAN` and `Resize(x, y, w, h)` are called
    by FLTK through a `My_X` C++ subclass. Each shim class also gives the
    base class's own `draw`/`handle` (qualified, so not virtual) for the
    default method to call, FLTKAda's `fl_box_draw` pattern.
  - `Callback` is FLTK's "when" callback. The default `Callback` calls
    the widget's `action` field, a procedure value, if it is set. So
    simple programs need no extension, and extending programs override
    `Callback`.
- **Dispatch from C++ to Oberon**: one dispatcher per hook kind (draw,
  handle, resize, callback, deleted, ...), each an Oberon procedure that
  C++ calls with the widget's `user_data()`. Prefer registering their
  addresses from `Fl`'s body (the prototype's way, which uses only
  documented poc behaviour) over naming poc's symbols from C++ (AGENTS.md:
  it works in 0.3.1 and 0.4.0, but isn't promised).

### Lifetime and the collector

This is the hard part; `doc/design.md` has the failures that motivate it.

- **FLTK owns widgets.** A widget lives until it is deleted: explicitly,
  or with its parent group. An Oberon `Widget` lives at least as long as
  its C++ widget. This is the reverse of FLTKAda, where an Ada controlled
  object owns and frees its C++ widget, because a garbage collector's
  finalizer runs at no predictable time and must not delete a visible
  widget.
- **The registry.** Every opened widget is reachable from a module-level
  root in `Fl` until its C++ widget is destroyed, since poc's collector
  never sees pointers that only C++ memory holds. It is a doubly linked
  list (the prototype's singly linked one was O(n) to remove from).
- **The deletion hook.** `user_data()` points at a small C++ object,
  derived from `Fl_Callback_User_Data`, that holds the Oberon widget's
  address. With `AUTO_DELETE_USER_DATA`, FLTK deletes it when the widget
  is destroyed, for every class and however the widget died (explicitly,
  with its parent, or by `Fl::delete_widget` after a callback). Its
  destructor tells `Fl` to unregister the widget and zero its handle. The
  `My_X` subclasses then need no destructors of their own.
  - Confirmed in Phase 0 for all of these, and for a shown window.
    Replacing the user data also deletes the old one, so it is set once.
  - **For each class bound**, check in the FLTK source that the class
    doesn't set its own `user_data()` or callback. If it does, the
    deletion hook would be lost.
- **Dead handles.** A method of a widget that isn't open (never opened,
  or deleted) is a programmer error, `ASSERT` code 70 (see "Halt codes").
  `IsOpen()` lets a program ask first. This replaces the prototype's
  silent no-op `Redraw`.
- **Deleting during a dispatch** goes through `Fl::delete_widget`
  (deferred), as FLTKAda's `fl_inside_callback` guard does. A dispatch is
  a `Callback`, `Draw`, `Handle` or `Fire`, counted in `ofl::depth`. At
  any other time `Delete` deletes at once, after running the queue, so
  a widget queued and still in its group isn't deleted twice
  ("Deleting twice", below; `doc/fltk-issues.md`, 72).
- **Resources Oberon owns** (`TextBuffer`, `Image`, `Preferences`) follow
  polibfyaml's `Document` rule:
  - explicit `Close` as the primary cleanup, idempotent, setting the
    handle to 0;
  - a finalizer as a backstop;
  - every widget using one keeps an Oberon reference to it, so it can't
    be collected while attached. For example, a `TextDisplay` keeps its
    `TextBuffer`.

### Strings and memory handed to FLTK

- **Labels, tooltips and window titles are always copied**
  (`copy_label`, `copy_tooltip`). FLTK's `label()` keeps the pointer, and
  an Oberon string may be a value parameter copied into a frame that dies
  on return. Valgrind can't see that bug (polibfyaml, "Buffer lifetime").
- **Any other pointer FLTK keeps is either copied by FLTK or owned by an
  Oberon object that outlives the FLTK object.** Before binding a call
  that takes a pointer, find out from the FLTK source which it is.
  Examples:
  - `Fl_RGB_Image`'s pixel data is not copied unless `alloc_array` is set;
  - `Fl_Menu_::add` copies its text.
- **Strings coming back** (`Input::value`, a text buffer's text) are
  copied into a `VAR ARRAY OF CHAR`, or returned as a
  `POINTER TO ARRAY OF CHAR`. Anything FLTK returns that the caller must
  free is freed in the shim.
- Text is UTF-8 bytes in `CHAR` arrays; FLTK's `fl_utf8*` helpers can be
  bound as needed.

### Types at the C boundary

- **Size model: `-OC`** (as polibfyaml chose): `INTEGER` is C's
  `int`, which is what every FLTK coordinate, size and enum is, and
  `LONGINT` is 64 bits. Code using pofltk must be built `-OC` too.
- The shim's `extern "C"` functions use only `int32_t`, `uint32_t`,
  `intptr_t` and `double`. On the Oberon side they are `SYSTEM.INT32`,
  `SYSTEM.ADDRESS` and `LONGREAL`, whatever the model.
  - **No `BOOLEAN` crosses**: use `int32_t` 0 or 1.
  - **No C struct is mirrored as an Oberon record**: read fields in the
    shim.
- `Fl_Color` is an unsigned 32-bit `RGBI` value: an `INTEGER` (or
  `SYSTEM.INT32`) in Oberon, with `Fl.RGB(r, g, b)` building one.
- Enum and flag values are exported Oberon constants, written by
  `tools/gen-constants.py`, which takes each value from the installed
  FLTK's headers. The same script writes `TestConstants`, which checks
  each Oberon constant against a table compiled against the current
  headers. So a changed FLTK value fails `make test`, a removed one fails
  the build, and running the script again picks up the change. A constant
  FLTK adds appears only once it is added to the script's list.
- Bit-flag enums (`when`, damage, menu flags, alignment) are `SET`s where
  every bit is below 32; otherwise integers with documented constants. A
  `SET` crosses to C as `SYSTEM.VAL(SYSTEM.INT32, s)`, not `ORD(s)`
  (AGENTS.md, "poc problems").
- **Names.** FLTK's names in Oberon case, without `FL_`: `UpBox`,
  `AlignTopLeft`, `HelveticaBold`, `DarkRed`, `WhenRelease`. Two
  exceptions avoid clashes:
  - events take the prefix `Ev` (`EvPush`, `EvFocus`), because
    `Fl::focus()` and `Fl::paste()` will be procedures `Focus` and
    `Paste`;
  - a widget's `box()` is `BoxType`/`SetBoxType`, since `Box` is a type,
    and `Fl::set_color` is `SetIndexColor`, so it doesn't read as a
    widget's `SetColor`.
- **Box and label types that FLTK defines on first use** (the macro
  `FL_ROUND_UP_BOX` is a call of `fl_define_FL_ROUND_UP_BOX()`) are all
  defined when Fl starts, so their constants are plain values.

### Halt codes

Programmer errors halt, as in polibfyaml. poc's `ASSERT(x, n)` prints
`assertion failed (n)` and exits with status 10. Codes:

| Code | Meaning |
|---|---|
| 70 | a method of a widget that isn't open: never opened, or deleted (`Fl.NotOpen`) |
| 71 | a widget opened twice, or a tree item added twice (`Fl.OpenedTwice`) |
| 72 | a NIL argument where a widget or timer is required (`Fl.NilArgument`) |
| 73 | a closed resource used, or one missing where it is needed: a closed `TextBuffer`, a display with no buffer, a removed `TreeItem`, a closed `Image` or `Surface`, a closed or deleted `Preferences`, a closed `FileChooser` or `HelpDialog` (`Fl.ClosedResource`) |
| 74 | an index out of range: group child, grid row or column, browser line, menu item, chart entry, a file chooser's filter, a terminal's xterm color, attributes, styles, flags or plotted cell (`Fl.IndexOutOfRange`) |
| 75 | `RepeatTimeout` outside its own timer's `Fire`, `HandleDefault` outside the event dispatch (`Fl.NotFiring`) |
| 76 | a widget that must be a group's child isn't: a grid's cell, a flex's fixed size, a tab or wizard page, a tile's size range (`Fl.NotAChild`) |
| 77 | a `Begin` and `End` out of order: an image surface's `End` that doesn't match the last `Begin`; a help view's page set in `Link` about an image (`Fl.OutOfOrder`) |
| 78 | an argument a call can't take: a multi-label for a window, a multi-label put in itself, a label type that needs an image, a file descriptor's conditions empty or unknown; a tree's root replaced; a window shaped by an image with no pixels to read (a tiled one); an `AnimGIF` opened as another image, or another image as one; an animation's frame set while it plays; a terminal's size, text size or error character it can't take (`Fl.Unsupported`) |

Bad data from outside the program is never a halt: an image that fails
to load, a file chooser cancelled. Those come back as `BOOLEAN` results.

## Build and test

`GNUmakefile`, modelled on polibfyaml's:
- `make`, `make test`, `make valgrind`, `make clean`; later
  `make install`/`uninstall` (the poc library `pofltk`, `-OC`);
- output in `build/`, `.NOTPARALLEL`;
- `fltk-config`'s `-I`/`-D` flags and `--ldflags`, passed as
  `-c-flag`/`-link`;
- C++ parts are `src/<Module>.cpp`, which poc 0.4.0 compiles with
  clang++.
- `make install` builds the poc library `pofltk` with FLTK's `-link`
  flags, which its manifest records. A program then needs only
  `-library-path`.

Tests need a display. FLTK 1.4 opens one even to draw offscreen.

- **Where tests run.** `make test` needs `DISPLAY` or `WAYLAND_DISPLAY`
  and stops with a message if neither is set. `make test-headless` and
  `make valgrind-headless` run them on Xvfb: `xvfb-run` (package
  `xorg-x11-server-Xvfb`) with `WAYLAND_DISPLAY` unset. FLTK prefers
  Wayland whenever `WAYLAND_DISPLAY` is set, even under `xvfb-run`, which
  sets only `DISPLAY`. Unset, FLTK uses X11 by itself; `FLTK_BACKEND=x11`
  forces X11 regardless.
- **Wayland without the desktop**: `make test-sway` and
  `make valgrind-sway` run them on a headless sway (`tools/with-sway.sh`,
  added 2026-10-06 after a `TestDialogs` run on the desktop was
  disturbed, probably by the user's own input reaching its dialog). All
  the tests pass there; pop-up menus are closed at once, as on the
  desktop, so they are still tested on X11 alone.
- **Behaviour tests** need no clicks. They drive the program the way the
  prototype's `Demo` does:
  - `do_callback`, and `Fl::handle` with synthesized events;
  - `Fl::add_timeout` to sequence steps;
  - `Fl::check`/`Fl::wait(0)` to let FLTK process;
  - each test hides its windows and exits, under a timeout.
- **Drawing tests** render a widget into an `Fl_Image_Surface` and check
  pixels, so `Draw` overrides are tested by value, not by eye.
- **Liveness tests** force `GarbageCollectedHeap.Collect` between steps.
  They check that widgets held only by FLTK survive, and that deleted
  ones leave the registry (`Fl.OpenWidgets`).
- **Halt tests**: one small program per code, as `test/Halt*.Mod`.
- **Valgrind**: polibfyaml's `poc-gc.supp`, and no suppressions for
  FLTK, whose display stack leaks too much to list (Phase 0). Memory
  errors fail a test. Leaks don't count as valgrind errors; instead
  `test/vg-check.sh` fails on any leaked block whose allocator is
  pofltk's own code.
- **Examples**: ports of FLTK's `test/` and `examples/` programs, taking
  FLTKAda's ports as a checklist. `make test` runs each, and checks that
  it is still running after a few seconds, since all wait for the user
  (Phase 8).

## Phased roadmap

Each phase ends with every test passing, `make valgrind` clean, and its
findings written into this file and AGENTS.md.

### Phase 0: Skeleton and the deciding experiments `[done]`

Done 2026-10-06, with poc 0.3.1 and FLTK 1.4.5, on Fedora 44 under
Wayland.

- `GNUmakefile` (see "Build and test"), `build/` in `.gitignore`,
  `test/Check.Mod` and `test/poc-gc.supp` from polibfyaml, and
  `test/vg-check.sh`.
- `src/Fl.Mod`, `src/Fl.cpp` and `src/ofltk.h`: the core of Phase 1,
  enough to test the object model. It has:
  - `Widget`, `Group`, `Window`, `DoubleWindow`, `Box`;
  - the registry, a doubly linked list, and the deletion hook;
  - `Callback` and `action`, `Draw`, `Handle`;
  - `Child`, which finds a child's Oberon object through FLTK;
  - labels (copied), geometry, show, hide;
  - `Run`, `Check`, `Wait`, and `Timer` with add, repeat and remove.
- Tests: `TestLiveness` (5 checks), `TestDelete` (12), `TestTimer`
  (8), and 6 halt tests, one per code 70, 71, 72, 74 and 75 (70
  twice). All pass under Wayland and under `FLTK_BACKEND=x11`, and
  `make valgrind` is clean: 0 errors.
- **The tests catch what they're for.** In a scratch copy:
  - with the registry no longer a root, `TestLiveness` failed and then
    crashed calling a freed object's callback, the original bug;
  - with `AUTO_DELETE_USER_DATA` off, 9 checks failed;
  - a program that never deletes its box failed `make valgrind`.

Findings, confirmed live (C++ programs in the scratchpad, then the
tests above):
- **The deletion hook covers every way a widget dies**:
  - explicit `delete`;
  - with its parent group, at any depth;
  - `Fl::delete_widget` from inside its own callback, at the next
    `Fl::check`;
  - a shown top-level window, with its children.
- **Replacing a widget's user data deletes the old one** (FLTK frees
  the previous `Fl_Callback_User_Data`), which would unregister a live
  widget. So `ofl::open` sets it once, and nothing sets it again.
- **The callback must be ofltk's for every widget**, so FLTK's own
  defaults are bound for the Oberon defaults to call:
  `Fl_Widget::default_callback` queues the widget for
  `Fl::readqueue`, and `Fl_Window::default_callback` calls
  `Fl::atclose`, which hides the window.
- **`FLTK_BACKEND=x11` switches FLTK 1.4.5 to X11**, checked with
  `fl_x11_display()`/`fl_wl_display()`; here it goes through XWayland.
  With no display at all, FLTK prints "Can't open display" and exits
  1.
- **Headless runs work on Xvfb**, and the tests pass there, including
  under valgrind. But a plain `xvfb-run` in a Wayland session leaves
  `WAYLAND_DISPLAY` set, and FLTK then quietly uses the real desktop.
  Hence `make test-headless`, which unsets it.
- **Pixel checks work**: a widget never shown, drawn into an
  `Fl_Image_Surface`, reads back exactly (`FL_RED` is 255,0,0), under
  both back ends. Binding it is Phase 2's.
- **FLTK's display stack leaks by design.** A C++ program that deletes
  everything it makes shows about 390 KB "definitely lost" and 1,225
  (X11) or 8,559 (Wayland) loss records, all allocated by fontconfig
  and Pango's font cache, and under Wayland by GTK's window
  decorations. It shows **no memory errors** on either back end. Hence
  `vg-check.sh`'s rule above, rather than suppressions.
- `fltk-config --cxxflags` includes `-I/usr/include` and Fedora's
  build flags, so the makefile passes only its `-I`/`-D` flags, without
  `-I/usr/include`.

Not done, and why:
- `prototype/` stays. Its custom drawing (Phase 2's `FlDraw`) and
  buttons (Phase 3's `FlButtons`) are not in `src/` yet. Retire it
  when they are.

### Phase 1: Core object model `[done]`

Module `Fl`. Done 2026-10-06, with poc 0.3.1. On top of Phase 0's core:

- **Constants**: 188 of them (events, when, box types, label types,
  alignment, fonts, colors), from `tools/gen-constants.py`.
- **Widget**:
  - label font, size, color and type; box type;
  - color and selection color; alignment; `when`;
  - activate, deactivate, `Active`, `ActiveR`, `VisibleR`;
  - tooltips (copied); position and size; `Parent`.
- **Group**: `Add`, `Insert`, `Remove`, `Find`, `Clear` (deferred
  inside a dispatch, like `Delete`), resizable.
- **Window**: `Shown`, `SizeRange`, modal and non-modal, fullscreen.
  The title is the label, set through `Fl_Window::copy_label`.
- **Colors**: `RGB`, `GrayRamp`, `ColorCube` (in Oberon, checked
  against C), `SetIndexColor`, `GetRGB`, background, background2 and
  foreground, `ColorAverage`, `Lighter`, `Darker`, `Contrast`,
  `Inactive`.
- **Other globals**: `NormalSize`, schemes.
- **Tests**:
  - `TestConstants` (196 values; a deliberately wrong constant fails
    it and is named);
  - `TestWidget` (33 checks).

  All pass on Wayland, on Xvfb, and under valgrind (0 errors).
- **Example**: `examples/Hello.Mod`, FLTK's `test/hello.cxx`, built by
  `make`. A screenshot under Xvfb showed it as FLTK draws it: an up
  box, and a bold italic shadow label of size 36.
- **Found**: poc 0.3.1 can't compile `ORD` of a `SET` under `-OC`. Any
  use emits LLVM `trunc i32 to i32`, which clang rejects; `-O2` is
  fine. `SYSTEM.VAL(SYSTEM.INT32, s)` gives the same bits, and is used
  instead (AGENTS.md, "poc problems"). poc 0.4.0 still has it; 0.4.1 fixed it ("poc 0.4.1" below).
- **Left for later**:
  - `Fl_Window` icons, `xclass`, and border control;
  - `Fl::readqueue`;
  - multi, icon and image labels, which come with images in Phase 7;
  - the prototype's demo, which needs Phase 2's drawing and Phase 3's
    buttons.

### Phase 2: Custom widgets and drawing `[done]`

Modules `Fl` and `FlDraw`. Done 2026-10-06, with poc 0.4.0 and FLTK
1.4.5.

- **`Resize` is overridable**, like `Draw` and `Handle`: `ofl::W<B>`
  overrides `resize()` too. The default `Resize` calls `B::resize`
  directly, not the virtual one, so an override's `Resize^` doesn't
  recurse. `Position` and `Size` go through the virtual `resize()`, so
  they reach an override, as FLTK's group resizing does.
- **Widget**, for an override's `Draw`: `DrawBox`, `DrawLabel` and
  `DrawFocus`, FLTK's protected `draw_box()` and friends, reached
  through `ofl::Hooks`. Also `Damage`/`SetDamage` (a `SET`),
  `TakeFocus`, `VisibleFocus`/`SetVisibleFocus`, `EventInside`; and
  `Window.SetCursor`.
- **Event queries** in `Fl`: `Event`, `EventX`/`Y`, `EventXRoot`/
  `YRoot`, `EventDx`/`Dy`, `EventButton`, `EventClicks` (and
  `SetEventClicks`), `EventIsClick` (and `EventIsClickOff`),
  `EventKey`, `EventOriginalKey`, `EventKeyDown(key)`, `GetKey(key)`,
  `EventState` (a `SET`), `EventText`, `EventLength`, `EventInside`;
  `Focus`/`SetFocus`, `BelowMouse`, `Pushed`.
- **Constants**, 116 more: keys (prefix `Key`, so `FL_End` isn't the
  keyword `END`, and `KeyF + n` is F*n*), mouse buttons, event state
  bits (`SET`s), damage bits (`SET`s), cursors; and in `FlDraw`, line
  styles. `tools/gen-constants.py` now writes a block into each
  module it names, and `TestConstants` checks all 312 values.
- **`FlDraw`**, the common calls of `fl_draw.H` (the open question
  below, decided):
  - colors and line styles;
  - integer shapes: `Point`, `Line`, `Rect`, `RectF`, `Loop3`/`4`,
    `Polygon3`/`4`, `XYLine`, `YXLine`, `Arc`, `Pie`;
  - the transformation and paths: `PushMatrix`, `Translate`, `Scale`,
    `Rotate`, the `Begin`/`End` pairs, `Vertex`, `Curve`, `ArcPath`,
    `Circle`, `Gap`;
  - text: `SetFont`, `Font`, `Size`, `Height`, `Descent`, `Width`,
    `Text`, `TextAligned`, `Measure`. Each sets FLTK's normal font
    first if no font is set, the crash `doc/design.md` records;
  - clipping: `PushClip`, `PushNoClip`, `PopClip`, `NotClipped`,
    `ClipBox`;
  - `DrawBox`, `FocusRect`, `DrawSymbol`.
- **Tests**:
  - `test/Probe` (Oberon and C++), for tests only: captures a widget
    into an `Fl_Image_Surface` and reads its pixels, and sends mouse,
    wheel and key events as the window system would, by setting
    `Fl::e_x` and the rest and calling `Fl::handle`;
  - `TestDraw` (24 checks): pixels of `Draw` overrides (fills, lines,
    clipping, a transformed path, text, `DrawBox`/`DrawLabel`) and of
    a box's own `Draw`;
  - `TestEvents` (23 checks): pushes, drags, releases, a shifted
    double click, the wheel, keys and focus reaching `Handle` with the
    right event queries; `Resize` overrides through `Size`,
    `Position` and a window's resizing, and one that refuses.

  All pass on Wayland and on Xvfb, `make valgrind` and
  `make valgrind-headless` show 0 errors and no ofltk leak, and
  `make install` (tried in a scratch directory) installs both
  modules, with a client built from `-library-path` alone.
- **The tests catch what they're for**: with `resize()` not sent to
  Oberon, 4 `TestEvents` checks failed; with `ofl_draw_rectf` drawing
  nothing, 5 `TestDraw` checks did.
- **Example**: `examples/Scribble.Mod`, drawing with the mouse: a
  custom widget's `Handle` keeps the strokes, and its `Draw` draws
  them as paths. Run under Xvfb and driven by `xdotool` (installed
  later that day): a drag drew a stroke, a right click cleared it, and
  Escape ended the program with status 0, each seen in a screenshot.

Findings, confirmed live:
- **`fl_clip_box` returns the reverse of what its documentation
  says**: 0 when the box was clipped, 1 when it wasn't, on both back
  ends. The Cairo driver (`Fl_Cairo_Graphics_Driver::clip_box`, which
  the image surface uses) compares the result with the clip, not with
  the box. For a box wholly clipped it sets `W` to 0 and returns
  without setting `H`. So `FlDraw.ClipBox` is a proper procedure, and
  the shim zeroes its outputs first.
- **A push no widget uses shows the window**: `Fl::handle_` makes the
  window `Fl::pushed()` before offering the push to its widgets, and
  if none uses it, raises the window with `show()`. So a never-shown
  window is shown, and its widgets get `EvShow`.
- **A key no widget uses, sent by `Fl::handle` to a window never
  shown, crashes FLTK 1.4.5** in `send_event`, as it tries the key as
  a shortcut: with `belowmouse()` set and no window shown, it sends
  the shortcut to `first_window()`, which is 0
  (`doc/fltk-issues.md`, 3). Real keys can't reach such a window, so this binds only
  tests: `Probe.Key` sends a key to the focus widget, as FLTK does
  first.
- **Synthesized mouse events reach widgets of a window never shown**:
  `Fl::handle` routes them to the widget under the mouse, then to
  `Fl::pushed()`, as for real ones, so `Pushed`, `BelowMouse` and
  `Focus` can be tested without a window on the screen.
- **`KeyDown` is FLTK's down arrow**, so `Fl::get_key` is `GetKey`,
  its own name.

Not done, and why:
- Offscreen drawing (`Fl_Offscreen`), images, and `fl_read_image`
  come with images in Phase 7.
- `fl_line_style`'s dash arrays, `fl_frame` strings, the 3-point
  `fl_line`, and `fl_text_extents` wait until a program needs them.
- `prototype/` stays until Phase 3 gives it buttons (done there).

### Phase 3: Buttons, inputs and valuators `[done]`

Modules `FlButtons`, `FlInputs` and `FlValuators`. Done 2026-10-06,
with poc 0.4.0 and FLTK 1.4.5.

- **`FlButtons`**: `Button`, `LightButton`, `CheckButton`,
  `RoundButton`, `RadioButton`, `RadioLightButton`,
  `RadioRoundButton`, `ReturnButton`, `RepeatButton`,
  `ToggleButton`, each extending what FLTK's extends. `Value`,
  `SetValue`, `SetOnly`, `Kind`/`SetKind` (`Normal`, `Toggle`,
  `Radio`, `Hidden`: the type names `ToggleButton` and `RadioButton`
  are taken, so the kinds drop "Button"), `Shortcut`/`SetShortcut` as
  a key and a `SET` of shift keys, `DownBox`.
- **`FlInputs`**: `Input`, `IntInput`, `FloatInput`,
  `MultilineInput`, `SecretInput`, `Output`, `MultilineOutput`. The
  text in and out (`Value` truncates to its argument; `Length`), as
  numbers too, the cursor and selection (`Select`, since `Position`
  is the widget's), undoable edits returning whether anything
  changed, the maximum size, read-only, wrap, tab navigation,
  shortcut, and the text's look.
- **`FlValuators`**: `Valuator` (FLTK's base, never opened),
  `Slider`, `ValueSlider`, `Scrollbar`, `Counter`, `Dial`, `Roller`,
  `Adjuster`, `ValueInput`, `ValueOutput`; and `Spinner` (an FLTK
  group) and `Progress` (a plain widget) with values of their own.
  Value, bounds, step, precision, `Round`/`Clamp`/`Increment`,
  `Format`, and `Kind`/`SetKind` with FLTK's names (`HorSlider`,
  `LineDial`, `Vertical`, ...), plus each class's own settings.
- **`Fl`**: `Live` is exported, for the other modules' methods;
  `Changed`/`SetChanged`; `ClearDamage`. Every module's C++ part
  opens a widget with its label copied, through `ofl::open`; Fl's
  `BeginOpen`/`EndOpen` attach it.
- **Constants**, 19 more (button, valuator and spinner kinds), for 331
  values in `TestConstants`.
- **Tests**: `TestButtons` (24 checks: clicks, toggles, a radio
  group with a check button made radio, shortcuts and Enter, repeat
  and its stopping), `TestInputs` (38: typing, BackSpace, Enter and
  `when`, maximum size, editing and undo, number inputs, multiline,
  secret and output), `TestValuators` (32: numbers and rounding,
  kinds, dragging a slider, a slider's own bounds, scrollbar,
  counter arrows, settings, typing into a value input, spinner,
  progress). `Probe.Shortcut` offers a key as a shortcut. All pass
  on Wayland and on Xvfb, and under valgrind on both with 0 errors
  and no ofltk leak.
- **The tests catch what they're for**: with a slider's bounds set
  as a valuator's, `TestValuators` failed; without the display
  opened before focusing, `TestInputs` crashed on Wayland.
- **`prototype/` is retired** (in git up to f57262b): `src/` does all
  it did. Its demo is `examples/Swatch.Mod`, a custom-drawn box and a
  button; driven under Xvfb by `xdotool`, two clicks took the swatch
  from red to green.

Findings, confirmed live and in FLTK's source (`doc/fltk-issues.md`
has each in full):
- **A text input taking the focus before the display is open
  crashes FLTK 1.4.5 under Wayland**, also in plain C++, where giving
  the first field the focus before `show()` is common. `TakeFocus`
  and `SetFocus` open the display first.
- **`changed()` is cleared after every callback but FLTK's default**,
  so `Changed` is TRUE only inside a `Callback`. **A push button is
  off again before its callback.**
- **Non-virtual methods hidden by subclasses**: `Fl_Slider::bounds`
  (adds a redraw), `Fl_Spinner`'s `color`, `selection_color` and
  `type` (its field's). The shim calls each class as itself.
  `Fl_Repeat_Button::deactivate` hides `Fl_Widget`'s too, but needs
  no help: `Fl_Widget::deactivate` sends `FL_DEACTIVATE`, which stops
  the repeating (a mutation test showed the override was redundant,
  so it was removed).
- **`Fl_Spinner::format` keeps its pointer and uses it as a printf
  format**, so it isn't bound.
- **Enter in an input calls back (`WhenEnterKey`) only if the text
  changed, and selects all the text.** `Valuator.Increment` rounds
  but doesn't clamp.
- **Synthesized keys need the text the window system gives**:
  BackSpace with `08X`, since under Wayland a key with no text is
  taken as composed text.

Not done, and why:
- `Fl_Spinner::format` (above); `Fl_Input_::copy` and `copy_cuts`
  wait for the clipboard (Phase 7).
- `Fl::callback_reason()`, which says why a `Callback` runs, waits
  until a program needs it.

### Phase 4: Layout `[done]`

Module `FlLayout`. Done 2026-10-06, with poc 0.4.0 and FLTK 1.4.5.

- **`FlLayout`**: `Flex`, `Grid`, `Pack`, `Scroll`, `Tabs`, `Tile`
  and `Wizard`, each an `Fl.Group`.
  - `Flex`: `Kind` (`Column`, `Row`), `SetFixed`/`Fixed`, margins,
    gap, `Layout`.
  - `Grid`: `SetLayout`, `Place` and `PlaceSpan` with an alignment
    `SET`, margins and gaps, each row's and column's size, weight,
    gap and computed size, `ShowGrid`.
  - `Pack`: kind and spacing. `Scroll`: kind, position, `ScrollTo`,
    scrollbar size. `Tabs`: `Value` (the page shown), `TabAlign`,
    `HandleOverflow`, `ClientArea`. `Wizard`: `Value`, `Next`,
    `Prev`. `Tile`: `SizeRange`, `InitSizeRange`,
    `MoveIntersection`.
  - `resizable` was already `Fl.Group`'s (Phase 1).
- **Halts**: a grid cell or span outside the grid, and a row or
  column index, are `IndexOutOfRange` (74). A widget that must be
  the group's child and isn't (a grid's cell, a flex's fixed size, a
  tab or wizard page, a tile's size range) is the new `NotAChild`
  (76).
- **`Fl`**: `Group.End` calls a flex as a flex, and `Group.Clear`
  deletes only the children ofltk opened, so it can clear a scroll or
  a spinner (findings, below).
- **Constants**, 28 more (flex, pack and scroll kinds, grid
  alignments, tab overflow), for 359 values in `TestConstants`.
- **Tests**: `TestLayout` (31 checks: a flex column and row, fixed
  sizes, gap and margins; a grid's cells, spans, weights, sizes and
  gaps; a pack's stacking and `Clear`; a scroll's position and
  `Clear`; tabs and a wizard's pages; a tile's border and size range;
  clearing a spinner). Halt tests `HaltGridRange` and
  `HaltNotAChild`. All pass on Wayland and on Xvfb, and under
  valgrind on both with 0 errors and no ofltk leak.
- **The tests catch what they're for**: `TestLayout` failed with a
  flex ended as a group, with a pack's `resizable()` left after
  `Clear`, and without the tile's saved sizes reset (each tried).
- Defaults the comments state were checked: a grid's weights 50, its
  gaps -1 (the grid's), widths 0; a flex's gap and margins 0; a
  scroll's scrollbar size 0 (`Fl::scrollbar_size()`).

Findings, confirmed live and in FLTK's source (`doc/fltk-issues.md`,
21 to 25):
- **`Fl_Grid::widget` writes past its rows** for a row equal to
  `rows()` (or a column equal to `cols()`), where it documents NULL:
  valgrind shows an invalid read and write. `PlaceSpan` checks the
  range first.
- **More hidden non-virtual methods**: `Fl_Flex::end` (asks for a
  layout), `Fl_Scroll::clear` and `Fl_Pack::clear`. `Fl_Group::clear`
  on a scroll or spinner would `delete` its member parts.
- **`Fl_Tile` size ranges set after a move put the children back**,
  since without ranges `move_intersection` doesn't save the new
  sizes. `SizeRange` and `InitSizeRange` save them first.
- **`Fl_Pack` resizes itself as it draws**, to fit its children.

Not done, and why:
- `Fl_Grid`'s `Cell` objects (per-cell size and alignment after
  placing) and `Fl_Flex`'s `spacing` alias: `Place` again does the
  first, `Gap` is the second.
- `Fl_Scroll`'s scrollbars are FLTK's, not ofltk widgets, so they
  aren't reachable from Oberon; `Scroll.ScrollbarSize` and `Kind`
  cover what programs set on them.

### Phase 5: Menus and dialogs `[done]`

Modules `FlMenus` and `FlDialogs`. Done 2026-10-06, with poc 0.4.0 and
FLTK 1.4.5.

- **`FlMenus`**: `Menu` (FLTK's `Fl_Menu_`, never opened), `MenuBar`,
  `MenuButton` (`Popup`, `Kind` for the pop-up kinds) and `Choice`.
  - Items are indexes into FLTK's array, as in FLTK: `Add`, `Insert`
    (a label is a path, "File/Open"), `Remove`, `Clear`,
    `ClearSubmenu`, `Length` (`size()`, ends included; `Size` is
    `Fl.Widget`'s), `IsItem`, `FindIndex`, `ItemPath`.
  - `Value`, `SetValue`, `Pick` (as if picked), `SetOnly`; each
    item's label, flags (a `SET`), shortcut (key and `SET`, as
    `Button`'s) and action; the items' font, size, color and boxes;
    `Global`.
  - **Item actions** are procedures, `Action = PROCEDURE (w:
    Fl.Widget)`, so one procedure serves a button and a menu item.
    Each is stored as the item's `user_data`, with no FLTK callback on
    the item, so FLTK calls the menu's callback for every pick
    (`Fl_Menu_::picked`). `Menu.Callback` then calls the action of
    `Value`, or the menu's own. A procedure is code, so the collector
    needs no root for it, and an extension can override `Callback`.
  - `FL_SUBMENU_POINTER` is never set (it would make the action a
    menu array), and `SetItemFlags` keeps an item's submenu bits,
    which describe the array's shape.
  - Halts: an index that is outside the array or names the end of a
    menu is `IndexOutOfRange` (74), as is `ClearSubmenu` of an item
    that isn't a submenu.
- **`FlDialogs`**: `Message`, `Alert`, `Choice` (FLTK's
  `fl_choice_n`, so Escape and the close button are told apart),
  `Input`, `Password`, `SetTitle`, `SetDefaultTitle`, hotspot, font,
  `Beep`; `ChooseColor`, `ChooseFromColormap`; `ChooseFile`,
  `ChooseDirectory` (FLTK's own chooser). A cancel is `FALSE` or a
  negative `Choice`, never a halt.
- **`Fl`**: `Window.WaitForExpose`.
- **Constants**, 20 more (item flags, pop-up kinds, beeps), for 379
  values in `TestConstants`.
- **Tests**:
  - `TestMenus` (40 checks): the array and paths, picking by `Pick`
    and by shortcut, toggle and radio items, changing items, removing
    and the value, a menu cleared in its own callback, a choice, a
    global menu and its deletion, and on X11 a pop-up answered by
    keys.
  - `TestDialogs` (25): every dialog, answered by keys sent from a
    timer to the modal window (`Probe.ModalKey`), titles read back
    (`Probe.Modal`).
  - `HaltMenuItem`. All pass on Wayland and on Xvfb, `TestDialogs`
    on X11 (XWayland) too, and under valgrind on both with 0 errors
    and no ofltk leak.
- **The tests catch what they're for**: `TestMenus` failed without
  the value kept across insert and remove, with a choice's value set
  as a menu's, and with `SetItemFlags` setting the submenu bits; it
  crashed without the global menu forgotten on deletion. The Wayland
  wait in `Popup` is checked by a C++ program only (findings).
- **`examples/Menus.Mod`**: a menu bar with shortcuts, a choice, and
  the file, color and question dialogs. Driven under Xvfb by
  `xdotool`, its File menu and its Quit question looked right.

Findings, confirmed live or in FLTK's source (`doc/fltk-issues.md`,
26 to 33):
- **Inserting or removing items moves `value()` to another item**:
  FLTK keeps it as a pointer into the array. ofltk finds the item
  again by its text pointer.
- **A deleted `global()` menu is used by the next shortcut**
  (valgrind, in plain C++). ofltk keeps its own pointer, cleared by
  the menu's destructor.
- **Under Wayland, a menu popped up over a window not yet on the
  screen kills the program** (a protocol error), and **a pop-up of a
  window without the focus is closed at once** by the compositor.
  `Popup` waits for the window; the second needs a real user, so the
  test pops up only on X11.
- **`fl_file_chooser` keeps its title pointer** in its one window;
  **the common dialogs take printf formats**. The shim copies the
  title, and passes text as `"%s"`.
- **`Fl_Choice::value(int)` hides `Fl_Menu_::value(int)`**.
- **A menu cleared in its own callback is safe in 1.4.5**, although
  FLTK's documentation forbids it: nothing reads the item after the
  callback (valgrind, in plain C++, through both a menu bar's and a
  choice's shortcut). So ofltk doesn't forbid it.
- **A key a timer sends to a dialog ends its loop only at the next
  event**, which never comes under Xvfb; the tests fire once more.

Not done, and why:
- `Fl_Native_File_Chooser` stays in Phase 7, as planned: it runs the
  desktop's own chooser, which keys from a test can't answer.
- `Fl_Sys_Menu_Bar` is an `Fl_Menu_Bar` except on macOS; menu item
  images and multi-labels come with images (Phase 7).
- `fl_yes`, `fl_no` and the other button labels are pointers FLTK
  keeps; `fl_message_icon` returns an FLTK-made widget. Not bound
  until a program needs them.

### Phase 6: Text and browsers `[done]`

Modules `FlText` and `FlBrowsers`. Done 2026-10-06, with poc 0.4.1 and
FLTK 1.4.5.

- **`FlText`**: `TextBuffer`, a resource the program owns, as planned
  ("Lifetime and the collector"): `OpenBuffer`, `Close` (idempotent),
  a collector finalizer as the backstop, `IsOpen`, and `openBuffers`,
  the count made and not closed, for tests.
  - Text by byte position from 0: `SetText`, `GetText`, `TextRange`,
    `CharAt`, `ByteAt`, `Insert`, `Append`, `Remove`, `Replace`;
    undo and redo; files (load, append, insert, save, save a range);
    the selection; lines and words (`LineStart`, `WordEnd`,
    `CountLines`, `SkipLines` and the rest); `SearchForward`,
    `SearchBackward`.
  - `Modified`, a method an extension overrides, runs after every
    change, from FLTK's modify callback.
  - `TextDisplay` and `TextEditor`: `SetBuffer`, `SetStyleBuffer`,
    `AddStyle` (returns the style's character, "A" on), the cursor,
    moving and scrolling, wrapping, line numbers, fonts and colors,
    the editor's insert mode and tab navigation.
  - **A buffer lives while a display shows it**, whatever the
    program does: the C++ buffer is reference counted, `Close` gives
    up the program's hold only, and a display lets go only after
    FLTK's display is destroyed (`Holds`, a base class destroyed
    after it). The display also keeps the Oberon buffer, so the
    collector leaves it.
  - Halts: a closed buffer used, and a display's text methods with
    no buffer, are `ClosedResource` (73).
- **`FlBrowsers`**: `BrowserBase` (`Fl_Browser_`, never opened),
  `Browser`, `HoldBrowser`, `MultiBrowser`, `SelectBrowser`,
  `FileBrowser`, `CheckBrowser`, `Tree`.
  - Lines from 1, as FLTK numbers them: `Add`, `Insert`, `Remove`,
    `Move`, `Swap`, `Clear`, `Load`, `GetText`, `SetText`, `Select`,
    `Selected`, `Value`, `Deselect`, `Sort`; hiding, showing and
    scrolling to lines; the format and column characters, and column
    widths. `Count`, not `Size`, which is `Fl.Widget`'s.
  - `FileBrowser`: `LoadDirectory`, `SetFilter`, `SetFileType`,
    the icon size. `CheckBrowser`: items checked and unchecked, and
    their counts.
  - Halts: a line or item outside 1 to the count (`Insert`, to the
    count plus 1) is `IndexOutOfRange` (74).
- **`Tree`**, about FLTKAda's scope (its `progress.txt`): items added
    by path or under an item, inserted at a position or above an
    item, removed, cleared; finding, paths, walking (`Next`, `Prev`,
    `Parent`, `Child`, the visible and selected items); open and
    close; selection; activation; each item's label font, size and
    colors; the tree's modes, spacing and colors; `CallbackItem` and
    `CallbackReason`. Not bound: embedded widgets and icons, which
    wait for images (Phase 7), moving items, and items made outside
    a tree.
  - **A `TreeItem` is a reference the program can't misuse.** FLTK
    makes and deletes items itself, some without ofltk seeing (a
    path's parents). So a `TreeItem` holds the item's pointer and a
    serial; the C++ tree maps the items it has handed out to their
    serials, and drops an item and its descendants from the map
    before it removes them. Only the program removes items, so an
    item is live exactly when its pointer is in the map with its
    serial. A pointer the allocator reuses gets a new serial: the
    test sees this happen. A dead item halts, `ClosedResource` (73).
  - What the program does never calls back (`docallback` 0), as
    elsewhere.
- **Constants**, 39 more (text wrap and cursor, style attributes,
  scrollbars, sorting, file types, tree modes and reasons), for 418
  in `TestConstants`.
- **Tests**:
  - `TestText` (45 checks): the buffer's operations, files, undo,
    search, a display's buffer and styles (a styled pixel read
    back), the buffer kept alive by its display, and a lost buffer
    finalized.
  - `TestBrowsers` (53): lines and selection by the program, clicks
    on a hold and a multi browser, column widths read back as
    pixels, loading a file, a file browser's directory and filter,
    a check browser's items and clicks.
  - `TestTree` (33): items and paths, removal and liveness, open and
    close, selection by the program and by clicks, Shift-click after
    a removal, an item removed in its own callback, `Clear`.
  - `HaltClosedBuffer`, `HaltNoBuffer`, `HaltBrowserLine`,
    `HaltTreeItem`. All pass on Wayland, X11 (XWayland) and Xvfb,
    and under valgrind on Wayland and Xvfb with 0 errors and no
    ofltk leak.
- **The tests catch what they're for**, each checked by breaking the
  shim:
  - `FlText`: `Holds` as the last base class, `Close` deleting a
    buffer still shown, and no style guard: valgrind errors.
  - `FlBrowsers`: the column widths or the filter passed to FLTK
    uncopied (the test sets them from a frame since written over),
    `textsize` called as `Fl_Browser_`'s, no top-line update, the
    tree removing as FLTK does, the callback item kept, and no
    serial: each fails a check.

Findings, confirmed live or in FLTK's source (`doc/fltk-issues.md`,
34 to 43):
- **A text buffer deleted before its displays is used after it is
  freed**: neither detaches from the other.
- **A style buffer with no styles** makes FLTK read before the style
  table.
- **`search_forward` and `search_backward` read past the text when
  matching case** (a bug; valgrind, in plain C++). The shim
  searches itself.
- **Browsers keep the column widths, filter and directory pointers**
  they are given; the shim keeps copies.
- **A browser finds its top line only when it draws**, so `TopLine`
  and `Displayed` read stale values and a browser never drawn takes
  no click; the shim updates it through the protected `find_item`.
- **`Fl_Browser::textsize` and `Fl_File_Browser::textsize` hide
  `Fl_Browser_`'s.**
- **`Fl_Browser::load` adds an empty last line** after a final
  newline, and **`Fl_File_Browser::load` returns the directory's
  entries**, not the lines listed.
- **`Fl_Tree` keeps a removed item's descendant as the last one
  clicked**, and **its callback item after removal**; **`clear`
  deletes the root**.
- **A check browser starts with `FL_WHEN_NEVER`**, and a browser
  calls back on every release (`FL_WHEN_RELEASE_ALWAYS`), changed
  or not: documented in `FlBrowsers`.

Not done, and why:
- No editor example yet; `examples/Menus.Mod` shows the dialogs a
  text editor would use. It can come with Phase 8's examples.
- `Fl_Text_Editor` key bindings, and the buffer's
  `Fl_Text_Selection` beyond the primary selection: not needed by
  anything yet.

### Phase 7: Images and the rest `[done]`

Modules `FlImages`, `FlPreferences` and `FlTable`, with additions to `Fl`
and `FlDialogs`. Done 2026-10-06, with poc 0.4.1 and FLTK 1.4.5.

- shared and RGB images (data copied); offscreen drawing and
  `fl_read_image`;
- the clipboard, drag and drop, `Preferences`, `NativeFileChooser`,
  `Table`.

Done:
- `FlImages` (`-lfltk_images`, from `fltk-config --use-images`):
  - `Image`: `Load` (the format told by the file's contents, not its
    name), `LoadData`, `OpenRGB` (the pixels copied), `Copy`, `Scale`,
    `ColorAverage`, `Desaturate`, `Inactive`, `Draw`, `DrawPart`,
    `Pixel`, `Alpha`, `SavePNG`;
  - `SetImage`, `SetInactiveImage`, `SetIcon`: a widget holds its
    images (`ofl::Shared`, counted, in `Ref`), so closing an image a
    widget shows is safe;
  - `Surface` (`Fl_Image_Surface`): `Begin` and `End` nest, and an
    `End` out of order halts with the new code 77; `DrawWidget`,
    `GetImage`; and `ReadImage`.
- The clipboard, in `Fl`: `Copy`, `Paste`, `PasteImage`,
  `ClipboardHasText`, `ClipboardHasImage`, `EventIsImage`; and
  `FlImages`' `CopyToClipboard` and `TakePastedImage`. A pasted image
  not taken is deleted by ofltk (`doc/fltk-issues.md`, 48).
- Drag and drop: `Dnd`, `DndTextOps`, `SetDndTextOps`, bound but not
  tested: a drag needs a real pointer, and `Fl::dnd` returns at once
  under Wayland.
- `FlPreferences`: `Preferences`, a database (`Open`: `User`,
  `System`, `Memory`; `OpenFile`) or a group in one (`Group`, which
  takes a path), with entries (`SetInt`, `SetReal`, `SetText`, `Int`,
  `Real`, `GetText`, `TextLength`, `Entries`, `EntryName`,
  `HasEntry`, `DeleteEntry`, `DeleteEntries`), groups (`Groups`,
  `GroupName`, `HasGroup`, `DeleteGroup`, `DeleteGroups`, `Clear`),
  `Flush`, `FileName` and `Close`. Reals are written in the C locale.
  A group is its database and its path, never an `Fl_Preferences`
  kept (`doc/fltk-issues.md`, 51). Binary entries and
  `get_userdata_path` aren't bound. Tested by `TestPreferences` and
  `HaltClosedGroup` (73); mutations caught: no existence check (the
  halt test exits 0), no `delete` in `Close` (`vg-check.sh`).
- `Fl.Option` and `Fl.SetOption` (`Fl::option`), and
  `FlDialogs.NativeFileChooser` (`Fl_Native_File_Chooser`):
  `OpenNativeFileChooser`, `SetKind`, `SetTitle` (copied: FLTK's
  driver keeps it, `doc/fltk-issues.md`, 30), `SetFilter`,
  `SetFilterValue`, `SetDirectory`, `SetPresetFile`, `SetOptions`,
  `Show` (`Chosen`, `Cancelled`, `Failed`), `Count`, `FileName`,
  `ErrorMessage`, `Close`. `TestDialogs` turns zenity, kdialog and GTK
  off with `SetOption`, so FLTK's own chooser is shown and answered by
  keys, on X11 and Wayland. The desktop's choosers are untested: they
  are other programs, or GTK's windows, out of `Probe`'s reach.
- `FlTable`: `Table` (`Fl_Table`) and `TableRow` (`Fl_Table_Row`),
  whose `draw_cell` reaches the Oberon `DrawCell` (a new dispatcher,
  `ofl_table_register`); rows, columns, headers, sizes, resizing,
  scrolling, `FindCell`, `VisibleCells`, cell selection, row
  selection, and the callback's row, column and context. A table is a
  `Group` of the widgets in its cells: Fl.cpp calls it as an
  `Fl_Table` (`doc/fltk-issues.md`, 52). Tested by `TestTable` (cells'
  pixels, a click, selection, widgets in cells) and `HaltTableRow`
  (74).
- Every label goes through `ofl::label_text`: FLTK lays out an empty
  label as a line of text, which moved label images
  (`doc/fltk-issues.md`, 46).
- Tests: `TestImages`, `TestClipboard`, and the halt tests
  `HaltClosedImage` (73) and `HaltSurfaceOrder` (77). They pass under
  headless sway and Xvfb, and both valgrind runs are clean.
- FLTK issues 44 to 50: no window icons and no selection buffer under
  Wayland; binary PNM unscaled; XPM color names only on X11; X11's
  `Fl::copy` before the display is open crashes; Wayland leaks the
  program's own pasted image.
- Mutations caught: no image held by its widget (valgrind invalid
  reads); "" labels (`TestImages`); pixels not copied; PNM unscaled; no
  release in `~Ref` (`vg-check.sh`); no `drop_pasted_image` (leaks in
  the valgrind log).

Not done, and why:
- Multi, icon and image labels, images in menu items and tree items'
  icons: images are in place, and these can come when something needs
  them.
- Drag and drop is bound but untested (above).
- `Fl_Preferences`' binary entries and `get_userdata_path`.

### Phase 8: Release `[done]`

Done 2026-10-06, with poc 0.4.1 and FLTK 1.4.5. `make install` as a poc
library, and poc 0.4.0's C++ parts and recorded link flags, were done
early, once 0.4.0 was installed ("poc 0.4.0" below).

- `README.md`: what ofltk is, requirements, building and testing,
  installing and using the library, the modules, the concepts
  (opening, overriding, lifetime, resources, strings, halt codes),
  and FLTK's problems.
- Examples: ports of FLTK's `examples/` programs, one for each module
  the first four examples left out: `TableSimple`, `TreeSimple`,
  `TextEditorSimple`, `BrowserSimple`, `GridSimple`, `FlexSimple`,
  `TabsSimple`, `WizardSimple`, `ProgressSimple`,
  `NativeFileChooserSimple`, `SvgSimple` (the SVG decoded from
  memory). Each was looked at under Xvfb against what FLTK's draws,
  and `ProgressSimple`, `WizardSimple`, `TreeSimple` and
  `BrowserSimple` were driven with `xdotool`.
- `make test` runs every example too: none ends by itself, so each
  must still be running after `EXAMPLETIME` seconds (3), when
  `timeout` ends it (status 124). An example that halted at once
  failed this (checked with a throwaway one).
- The README's install instructions were followed in the scratchpad:
  `poc -OC -library-path <lib>/ofltk` built `TableSimple` alone, and
  it ran.

Not done, and why:
- The examples aren't run under valgrind: killed by `timeout`, a
  program frees nothing, so its leak report means nothing.
- No larger demo (an editor with files, a spreadsheet): the ports
  show each module, and `Menus` the dialogs.

### Phases 9 to 13: every example FLTK ships

Planned 2026-10-07. FLTK 1.4.5's `examples/` has 46 programs. Phase 8
ported 11. Four use what "Scope" leaves out (OpenGL3test,
OpenGL3-glut-test, simple-terminal, cairo-draw-x). These phases port the
other 31, and bind what they need. The list came from comparing each
example's classes, `Fl::` and `fl_` functions and methods with what the
C++ parts call, so a port may still find a small gap. A gap goes into
the phase that finds it.

Each phase, as before, ends with every test passing, on
`make test-headless` and `make test-sway`, and with
`make valgrind-headless` and `make valgrind-sway` clean. Each binding
gets its own test. `doc/fltk-issues.md` records each FLTK problem the
phase finds. Each port:
- is named for FLTK's file in CamelCase, without `howto-`
  (`TableAsContainer`, `DrawAnX`), as `FlexSimple` was;
- goes in `EXAMPLES`, so `make test` runs it;
- is looked at under Xvfb against FLTK's own build of it (`examples/`
  has the binaries).

Order: the ports that need nothing come first, because writing them
finds the small gaps cheaply. The bindings with new lifetime problems
(trees, animated images) come last.

Not in these phases: FLTK's classes no example uses (`Fl_Clock`,
`Fl_Positioner`, `Fl_Input_Choice`, `Fl_File_Input`, `Fl_Help_View`,
`Fl_Overlay_Window` and others). Each is a small widget binding, for
when a program needs it. Phases 14 to 22 bind them.

### Phase 9: Ports that needed little new `[done]`

Done 2026-10-07, with poc 0.4.1 and FLTK 1.4.5. Planned as needing
nothing new; writing them found three small gaps, bound here.

- Ported: `Callbacks`, `DrawAnX`, `TextOverImageButton`,
  `DragAndDrop`, `TableAsContainer`, `TableWithKeynav`,
  `TableWithRightClickMenu`, `TableWithRightColumnStretchFit`,
  `TableSpreadsheetWithKeyboardNav`, `TextDisplayWithColors`,
  `TextEditorWithDynamicColors`, `NativeFileChooserSimpleApp`.
- **How a port was checked**: it and FLTK's own build (FLTK's
  `examples/` has the binaries) were run under Xvfb, given the same
  clicks, drags and keys with `xdotool`, and their screens compared
  pixel by pixel (`magick compare -metric AE`). Every port matched
  exactly, or within faint antialiasing (no pixel 1% off): as drawn,
  and after each interaction tried, such as a dialog from each kind of
  callback, a drag between windows, a column resized, cells selected
  by mouse and keys, a cell edited, rows added until the scrollbar
  shows, the window resized, text typed and deleted. What they print
  matched too (FLTK's run with `stdbuf -oL`, since it is killed).
  `NativeFileChooserSimpleApp` saved with Ctrl+S and Return wrote the
  same file as FLTK's, and both showed an error for an unwritable
  directory.
- **New: `FlImages.OpenXPM`**, for `TextOverImageButton`'s gradient:
  an XPM's strings as an Oberon `ARRAY OF ARRAY OF CHAR`. A 2-D open
  array reaches C as its first element's address, its rows `LEN(a,
  1)` bytes apart (the test sees each row). `Fl_Pixmap` keeps the
  lines and trusts the first line's numbers, so the shim checks the
  line count, each row's length and its 0X against them, then copies
  the pixmap (`copy_data`). Tested in `TestImages`, with each bad form
  refused.
- **New: `Group.InitSizes`** (`Fl_Group::init_sizes`), for
  `TableAsContainer`, which moves its cells' widgets as columns are
  resized. `Fl_Table::init_sizes` hides `Fl_Group`'s (52), so a table
  is called as one. Tested in `TestWidget`: a child moved goes back on
  the group's next resize, and stays after `InitSizes`.
- **New: `Table.Area`**, for `TableWithRightColumnStretchFit`:
  `Fl_Table`'s protected `wix`, `tox` and `tix` rectangles, reached
  through pointers to members named in a subclass, as `find_cell` is.
  Tested in `TestTable` against `recalc_dimensions`' arithmetic.
- **Drag and drop is tested** (`TestClipboard`), with events sent
  by `Probe.Mouse` through FLTK's routing: enter, drag, release, and
  leave both by dragging off and from the window system. A real drag
  between two windows was tried in `DragAndDrop` under Xvfb.
  - Sending `FL_DND_LEAVE` to a window never shown crashed the test in
    an `Fl_Input`, which calls `Fl::first_window()->cursor()`
    (`doc/fltk-issues.md`, 53), so the test uses a window with no
    input.
  - `Fl::handle` returns 0 for a drag off a widget the window has no
    use for, though the widget gets `FL_DND_LEAVE`; a window passes
    `FL_DND_LEAVE` to each child again.
- **Found writing them**:
  - An extension of a widget can't have a field named `h`: the base's
    read-only handle `h-` is visible, and poc reports the clash.
  - poc has no string concatenation, so a label with line breaks is
    built with `OutStr.Ln`.
  - poc's `Files` halts when it can't create a file (`Fail`), so
    `NativeFileChooserSimpleApp` writes through a text buffer's
    `SaveFile`, which returns `FALSE`; its message can't say why.
  - `exit(0)` in FLTK's examples (Escape) is `win.Hide` here, which
    ends `Fl.Run`.
  - On Xvfb with no window manager, a window sits 20 pixels below
    its y.
- `EventXRoot` and `EventYRoot` were bound already (Phase 2), so
  Phase 10 needn't add them.

### Phase 10: Small additions `[done]`

Done 2026-10-07, with poc 0.4.1 and FLTK 1.4.5: seven ports, and the
small bindings they need. Each port was checked as Phase 9's were,
against FLTK's own build under Xvfb, and matched pixel for pixel in
every interaction tried; what they print matched too.

- Ported: `DraggableGroup`, `TableSpreadsheet`, `TreeCustomSort`,
  `BrowserWithIcons`, `MenuWithImages`, `MenubarAdd`, `ParseArgs`.
  `TreeCustomSort` makes its numbers with a generator of its own, with
  a fixed seed (poc has no `rand`), so it is compared with FLTK's by
  its layout after sorting.
- **`Fl.BoxDX`, `BoxDY`, `BoxDW`, `BoxDH`** (`Fl::box_dx` and the
  rest), for `DraggableGroup`. A box type outside 0 to 255 halts
  (`IndexOutOfRange`, `HaltBoxType`).
- **`Table.TabCellNav`/`SetTabCellNav`**, for `TableSpreadsheet`.
  `TestTable`: Tab is refused without it, and moves a cell with it,
  Shift-Tab back.
- **`TreeItem.SwapChildren`**, for `TreeCustomSort`. The tree's map
  of live items is unchanged by a swap; `TestTree` checks the order
  and that the items are the same items, with their children.
- **`FlImages.SetLineIcon`** (`Fl_Browser::icon`), for
  `BrowserWithIcons`. FLTK keeps the image and never deletes it, and a
  line removed drops it unseen (`doc/fltk-issues.md`, 56). So `Ref`
  gained a list of what a widget keeps beside its slots
  (`Ref::keep`), each held once, and a browser lets go of the images
  no line shows after each change to its lines (`ofl::drop_icons`).
  `Probe.Kept` counts them, and `TestImages` checks the count as icons
  are set and lines removed or cleared; with the release after
  `clear` taken out, it fails. (Valgrind alone couldn't tell: the
  browser lets go of everything when it is deleted.)
- **Multi-labels** (`FlImages.MultiLabel`, `Fl_Multi_Label`), for
  `MenuWithImages`: a resource like `Image`, of two parts, each
  nothing, text (copied), an image or another multi-label, which it
  holds. A widget shows one with `SetMultiLabel` (held in `Ref`'s new
  `label` slot), a menu item with `SetItemMultiLabel`, and a menu item
  an image with `SetItemImage`.
  - FLTK reads a menu item's label as its text whatever its type, and
    `remove` and `replace` `free()` it (`doc/fltk-issues.md`, 54). So
    each such item points at an `ofl::ItemLabel` of its own, which
    keeps the item's text: `ItemLabel`, `ItemPath`, `FindIndex` and
    `Insert` see the text (`Names` swaps it in while they run), and
    `Remove`, `ClearSubmenu` and `SetItemLabel` give the item its text
    back first (`plain`). Each item's text pointer stays its own, so
    `KeepValue` still finds the chosen item. An image item's label is
    a multi-label of the image and nothing, which FLTK draws as it
    draws the image (the port matched).
  - `Fl_Multi_Label::label(Fl_Widget *)` doesn't free a copied label,
    and leaves it marked to be freed, so the widget later frees the
    multi-label (`doc/fltk-issues.md`, 55): the shim clears the label
    first. `Widget.SetLabel` gives a widget text again;
    `SetLabelType` keeps a multi-label; `GetLabel` of one is "".
  - A multi-label put in itself, one for a window (whose label is its
    title), and `SetLabelType` of 5 to 7 halt with the new code 78,
    `Fl.Unsupported` (`HaltMultiLabel`).
- **`Fl.OpenURI`** (`fl_open_uri`), for `MenubarAdd`: `FALSE`, with
  FLTK's message, for a scheme FLTK doesn't open or no program to open
  it. `TestWidget` tests only that path, which starts no program.
- **Command-line options**: `Fl.ParseArgs` (`Fl::args`, with the
  program's handler, an Oberon procedure given each argument's
  number), `Arg`, `ArgsHelp` and `Window.ShowArgs`
  (`show(argc, argv)`), for `ParseArgs`.
  - FLTK keeps pointers into `argv`; poc's `Args.argv` is C's own,
    which lasts the program's life, so the shim needs no copy (the
    plan expected one).
  - `Fl::args` returns 0 for an option no one knows only until it has
    once stopped at a word that isn't an option: its flag for that is
    static and never cleared (`doc/fltk-issues.md`, 57). The shim
    decides from the word where parsing stopped.
  - `TestArgs` is run by `make test` with a command line of its own
    (`TESTARGS`): the program's options and FLTK's, `-s` and `-nokbd`
    taking effect, `-g` and `-ti` on the window `ShowArgs` shows, and
    a second parse finding an unknown option.
  - `FindIndex` takes the `&`s of the labels, as FLTK's `find_index`
    does; FlMenus' comment said otherwise, and is corrected.
- **Screens**: `Fl.ScreenX`, `ScreenY`, `ScreenW`, `ScreenH` (the main
  screen's work area), `ScreenCount`, `ScreenXYWH`, `ScreenWorkArea`
  and `ScreenAt` (`screen_num`, 0 for a point on no screen).
  `TestWidget` checks they agree, and prints screen 0: 640x480 on
  xvfb-run's default screen, 1280x800 on `tools/with-sway.sh`'s
  output, each its own work area. `EventState` already covers
  `event_shift`.

### Phase 11: The event loop `[done]`

Three ports, and what they need of the event loop:

- **Idle callbacks** (`Fl::add_idle`, `remove_idle`): an `Idle`
  object, kept reachable while added as a pending `Timer` is
  ("Lifetime and the collector"), with a `Run` method.
- **File descriptors** (`Fl::add_fd`, `remove_fd`, with `FL_READ`,
  `FL_WRITE`, `FL_EXCEPT`): an `FdWatch` object, kept the same way,
  with a `Ready(fd, when)` method. The test writes to a pipe
  `Probe` makes, and waits for `Ready`.
- **The event dispatch** (`Fl::event_dispatch`): one Oberon
  procedure that sees every event first, and `Fl.HandleDefault`
  (`Fl::handle_`) to pass an event on. To remap a key the dispatch
  sets the event's key and text, so `Fl` gains setters for the
  event fields `Probe` already sets (`Fl::e_keysym`, `e_text`,
  `e_length`). Check first that `Fl::handle_` inside a dispatch is
  safe with pofltk's dispatch depth and deferred deletes.
- Running a command is not FLTK's (`popen`), so it isn't pofltk's:
  `examples/Pipe.Mod` and `Pipe.cpp`, an example module with a C++
  part (`popen`, `fileno`, `read`, `pclose`), as `test/Probe` is a
  test module with one.
- Ports: `howto-add_fd-and-popen` (it runs `ping`, so the port runs
  something slow that needs no network), `howto-remap-numpad-keyboard-keys`,
  `table-sort` (its table is `ls -l`, through `Pipe`).

Done 2026-10-07, with poc 0.4.1 and FLTK 1.4.5: three ports, and the
event loop they need. Each port was checked as Phase 9's were, against
FLTK's own build under Xvfb.

- Ported: `AddFdAndPopen`, `RemapNumpadKeyboardKeys`, `TableSort`.
  - `AddFdAndPopen` runs `ping -i 2 -c 10 localhost`, as FLTK's does:
    it needs only the loopback, so the plan's other slow command was
    not needed. Its screens differ from FLTK's only in ping's times,
    and both end with `<<DONE>>`.
  - `RemapNumpadKeyboardKeys` matched pixel for pixel, remapping on
    and off.
  - `TableSort` matched pixel for pixel as drawn, sorted by file name,
    reversed, and sorted by size, both run in `examples/`. FLTK sorts
    with `std::sort`, which isn't stable, and the port with an
    insertion sort, which is, so they are compared on columns whose
    values differ.
- **Idle callbacks**: `Fl.Idle` (`Run`, whose default calls its
  `action`), `AddIdle` (a second time does nothing), `RemoveIdle` and
  `Idle.Added`. An idle added is in `Fl`'s list, so kept from the
  collector, until removed. `remove_idle` inside the idle's own
  callback is safe (`call_idle` in `Fl_add_idle.cxx` moves on before calling it),
  and `TestLoop` removes one there.
- **File descriptors**: `Fl.FdWatch` (`Ready`, whose default calls its
  `action`; `fd` and `when` read-only), `WatchFd`, `UnwatchFd` and
  `FdWatch.Watching`, with the generated constants `FdRead`, `FdWrite`
  and `FdExcept`. Kept in `Fl`'s list as idles are.
  - `Fl::add_fd` for an fd already watched takes the conditions given
    from the other entry for that fd (`Fl_Unix_System_Driver::add_fd`, the
    system driver of both back ends). So `WatchFd` does the same to the
    Oberon watches: the conditions are taken from any other watch of
    that fd, and one left with none stops watching. `TestLoop` checks
    a second watch of a pipe taking over from the first.
  - FLTK's fd list is walked by index, and `select` is level-triggered,
    so a watch may unwatch itself in `Ready`: `AddFdAndPopen` does at
    the end of ping's output.
  - A negative fd halts with `IndexOutOfRange`; conditions empty or
    outside the three, with `Unsupported`.
  - `Probe.Pipe`, `Write`, `Read` and `Close` give the test a pipe.
- **The event dispatch**: `Fl.SetEventDispatch` (NIL for FLTK's own),
  an `EventDispatch` procedure given the event and its window (NIL for
  none, or a window not pofltk's), and `Fl.HandleDefault`
  (`Fl::handle_`), which hands the event on. The trampoline runs under
  `ofl::Dispatch`, so a widget deleted in the dispatch is deleted
  after it (`TestLoop`), and `HandleDefault` outside a dispatch halts
  with 75, `NotFiring` (`HaltHandleDefault`), which now covers it as
  well as `RepeatTimeout`.
  - `Fl.SetEventKey` and `SetEventText` (`Fl::e_keysym`, and `e_text`
    and `e_length`, the text copied into the shim's buffer) let a
    dispatch remap a key; `TestLoop` makes a keypad key type its digit
    into an input.
  - Under Wayland the dispatch also sees FLTK's own events such as
    `FL_SCREEN_CONFIGURATION_CHANGED` (24), so `TestLoop` counts only
    the events it sends.
- **`Fl.ScrollbarSize`/`SetScrollbarSize`** (`Fl::scrollbar_size`, 16
  by default), for `TableSort`, whose window is sized for its columns
  and the scrollbar.
- **`Pipe`** (`examples/Pipe.Mod`, `Pipe.cpp`): `popen` and `pclose`,
  read a line at a time (`fgets`). The makefile's `EXAMPLECXX` lists
  examples' modules with a C++ part, and examples are built with
  `-import-path examples`, since poc doesn't search the main module's
  directory.
- `gen-constants.py` rewrote `FlTable`'s generated block, which held
  the hand-written `Area` constants: they are now after its end.

### Phase 12: Trees `[done]`

Three ports, and what they need of trees:

- **Widgets in items** (`Fl_Tree_Item::widget`, the tree's
  `item_draw_mode` and `widgetmarginleft`), for `tree-as-container`
  and `tree-of-tables`. The widget is the tree's child, deleted with
  the tree, and `~Fl_Tree_Item` leaves it alone ("Fl_Group will
  handle destruction", `Fl_Tree_Item.cxx`). So removing an item
  leaves its widget in the tree. Find out what FLTK then draws, and
  whether `Item.Remove` should delete the widget, or halt while it
  has one.
- **Items that draw themselves**, for `tree-custom-draw-items`: an
  Oberon extension of `TreeItem` with a `DrawContent(render)` method,
  FLTK's virtual `draw_item_content`. The C++ part's item class sends
  it to Oberon through a dispatcher `FlBrowsers`' body registers, as
  `FlTable` does for `draw_cell`. `Tree.AddItem(path, item)` adds it
  (`Fl_Tree::add(path, newitem)`).
  - Today the program can't make items. An Oberon item would be
    reachable from FLTK alone, so it goes in the registry while its
    C++ item lives. The C++ item's destructor drops it there, and
    from the tree's map of live items, as `Ref` does for a widget.
  - The example's `show_self` prints the tree to standard output for
    debugging: the port walks the items itself.

Done 2026-10-07, with poc 0.4.1 and FLTK 1.4.5: three ports, and the
tree's widgets and items of the program's own. Each port was checked
against FLTK's own build under Xvfb, as Phase 9's were.

- Ported: `TreeAsContainer`, `TreeOfTables`, `TreeCustomDrawItems`.
  - `TreeAsContainer` (20000 items, each showing a group of five
    inputs: 120000 widgets) matched pixel for pixel as drawn, scrolled,
    typed into, and with the items' parent closed. It shows its window
    in 1.6 s; FLTK's in 1.1 s.
  - `TreeOfTables` matched pixel for pixel as drawn and scrolled. Its
    cells are written as printf writes them (`%d`, `%.2f`, `%g`), from
    `RealDigits`' exact digits, which round ties to even as glibc
    does: all 363 numbers its tables can show were compared with
    printf's, and matched, ties and `-0.00` included. A cell divides in
    `REAL`, as C's `float`, and a power is exact in `LONGREAL`, rounded
    once to `REAL`, as `powf` gives it.
  - `TreeCustomDrawItems`: run with `TZ=UTC`, its screens differed from
    FLTK's only in the seconds of the time, as drawn, with items
    selected, and with a scheme chosen. Its local time is
    `Platform.GetClock`'s; GMT is worked out from `GetTimeOfDay`'s
    seconds (checked in New York time: four hours apart). The tree it
    prints matches FLTK's `show_self` without the addresses.
- **Widgets in items**: `TreeItem.SetWidget` and `Widget`,
  `Tree.SetItemDrawMode` and `ItemDrawMode` (the generated
  `ItemDrawLabelAndWidget` and `ItemHeightFromWidget`; `{}` draws the
  widget alone) and `SetWidgetMarginLeft`. The open questions, answered:
  - FLTK leaves a removed item's widget in the tree, where it is no
    longer drawn but still takes clicks (`doc/fltk-issues.md`, 58). So
    an item's widget is deleted with it, by `Remove`, `ClearChildren`
    and `Clear`, as a group's children are, later inside a dispatch;
    `TestTreeItems` removes one in its widget's own callback.
  - The widget becomes the tree's child (`Fl_Group::add`, which
    `Fl_Tree::add` hides). A widget the item had leaves the tree, still
    open, as `Group.Remove` leaves one; a widget given to another item
    leaves the first.
  - The other way round, a widget deleted, or added to another group,
    leaves its item: the tree's class overrides `Fl_Group::on_remove`
    (virtual in 1.4), with a map from widgets to items.
  - `Widget.Parent` of an item's widget is NIL: the tree isn't a
    `Group` in Oberon.
- **Items the program makes**: `Tree.AddItem(path, item, label)` and
  `TreeItem.Replace(item, label)`, of the program's own extension of
  `TreeItem`, whose `DrawContent(render): INTEGER` is FLTK's
  `draw_item_content`, with `LabelXYWH`, `DrawFgColor` and
  `DrawBgColor` (protected in FLTK) for it. The C++ item (`Mine`)
  sends `draw_item_content` to Oberon through a dispatcher FlBrowsers'
  body registers, and its destructor tells Oberon it is gone; until
  then the object is in FlBrowsers' list (`made`), so kept from the
  collector (`TestTreeItems` collects with one only the tree holds).
  - Every `TreeItem` the tree hands out for such an item is the
    object itself (`ofl_tree_self`), so `CallbackItem` returns it, and
    a type test finds the program's type.
  - An item is added once (`Fl.OpenedTwice`); the root can't be
    replaced (`Fl.Unsupported`). `AddItem` returns `FALSE` for an empty
    path. `Fl_Tree::add(path, item)` keeps the item's own label, and
    puts it under the whole path if that is there already, as
    `TestTreeItems` checks.
  - `Fl_Tree_Item::replace` deletes the old item without the tree
    forgetting it, so `Replace` adds the new item at the old one's
    place (`Fl_Tree_Item::reparent`) and removes the old one as
    `Remove` does.
- **An item removed in the tree's callback as it is pushed** became
  the tree's last item clicked after it was freed, and a drag then
  moved it (`doc/fltk-issues.md`, 59): a bug pofltk's `Remove` had
  since Phase 6, now fixed. The tree counts the items pofltk removes,
  and after an event in which any were, clears the private
  `_lastselect` (reached through an explicit instantiation) unless it
  is still in the tree. `TestTree` drags after such a removal: 4
  valgrind errors without the fix, none with it.
- **`FlMenus.SchemeChoice`** (`Fl_Scheme_Choice`), for
  `TreeCustomDrawItems`, which the plan didn't list. FLTK's choice sets
  the scheme in its own callback, which pofltk's replaces, so its
  `Callback` calls FLTK's (protected) unless an action is set.
  `TestMenus` checks its items, its value, and the scheme it sets.

### Phase 13: New widgets and images `[done]`

Six ports, and the widgets and images they need:

- `Fl_Chart`, for `chart-simple`, in a new module `FlCharts` (or
  `FlValuators`, if it stays alone). Each entry's label is copied
  into the entry (`str[FL_CHART_LABEL_MAX + 1]`, `Fl_Chart.H`).
- Window shapes (`Fl_Window::shape`) and `Fl_Tiled_Image`, for
  `shapedwindow`. X11 keeps a pixmap's pointer as the shape
  (`Fl_X11_Window_Driver::shape`), so the window's `Ref` holds the
  image. Find out whether the Wayland back end supports shapes at
  all.
- Animated GIFs (`Fl_Anim_GIF_Image`), for the four `animgifimage`
  examples, loaded from contents as `FlImages` loads every image.
  The image redraws its canvas widget from FLTK timers, so a canvas
  deleted first, or an image deleted while its timer is pending,
  must be safe: test both under valgrind.
- `animgifimage` lists a directory (`fl_filename_list`,
  `fl_alphasort`), which `FlDialogs` can bind, with the names copied
  and FLTK's list freed (`fl_filename_free_list`).

Done 2026-10-07, with poc 0.4.1 and FLTK 1.4.5: six ports, charts,
window shapes, tiled and animated images, global event handlers, and
directory listings. Each port was checked against FLTK's own build
under Xvfb, as Phase 9's were.

- Ported: `ChartSimple`, `ShapedWindow`, `AnimGifImageSimple`,
  `AnimGifImageResize`, `AnimGifImagePlay` and `AnimGifImage`; each
  matched pixel for pixel as drawn.
  - The animgifimage ports were given FLTK's own
    `test/images/fltk_animated*.gif`, and pofltk's
    `test/images/anim.gif` (three frames of 4 by 2, made for
    `TestAnimGIF`), which is `AnimGifImageSimple`'s default, FLTK's
    file not being in this repository. `AnimGifImage` matched in each
    of its modes (`-T` tiled, `-f` a second canvas, `-r1.5`, `-D`,
    `-A`, `-m`, `-ddd` a window per frame, `-t` a directory, and the
    file chooser), with the same titles and output as FLTK's; its
    chooser loop, a window deleted and the chooser shown again, ran
    under valgrind. `AnimGifImagePlay`'s titles matched FLTK's after
    each of its keys; `AnimGifImageResize` matched before and after
    the window was resized.
  - FLTK's examples keep an animation in a window's user data, or
    find it as a widget's `image()`; the ports keep it in the window's
    or canvas's record. `AnimGifImagePlay` opens an `AnimGIF` for each
    file, where FLTK's loads each into one.
  - **`EXAMPLEARGS`** in the makefile gives an example its command
    line under `make test`: `AnimGifImagePlay` and
    `AnimGifImageResize` need a file.
- **`FlValuators.Chart`** (`Fl_Chart`), in `FlValuators` as it
  stays alone. `SetMaxCount(0)` sets no limit, where FLTK's
  `maxsize(0)` drops every entry (`doc/fltk-issues.md`, 60); a label
  is cut before a UTF-8 character crossing its 18th byte, where FLTK
  cuts in the middle (65).
- **`FlImages.SetShape`** and **`OpenTiled`**. The Wayland back end
  supports shapes (a Cairo mask, `Fl_Wayland_Window_Driver::shape`).
  X11's reads past an image drawn larger than its data (61), so FLTK is
  given a copy at the drawn size, which the window holds. A tiled image
  can't shape a window (`Fl.Unsupported`, `HaltShapeTiled`).
- **`FlImages.AnimGIF`** (`Fl_Anim_GIF_Image`), opened from a file or
  from contents, with `AnimMinDelay`, `ScalingAlgorithm` and
  `SetAnimateGIFs`. Its timer redraws its canvas, so it watches the
  canvas and forgets it as it dies (62); `TestAnimGIF` deletes a
  playing animation's canvas, and closes one with its timer pending,
  under valgrind. `SetFrame` while it plays halts (`Fl.Unsupported`,
  `HaltAnimFrame`). FLTK's copy plays whenever the original has a
  frame shown (64).
- **`Fl.AddHandler`, `RemoveHandler`, `Redraw`** (`Fl::redraw`) and
  **`WindowShown`** (`Fl::first_window`), for the ports' keys and
  forced redraws; tested in `TestLoop` and `TestWidget`.
- **`FlDialogs.ListDirectory`** (`fl_filename_list`), the names
  copied and FLTK's list freed. **`fl_numericsort` is wrong**: it
  never compares the character after a run of digits, and reads past
  a name's end after one (63), found by valgrind in FLTK's file
  chooser as `AnimGifImage` ran. pofltk's own sort (`src/pofltk.h`)
  serves `ListDirectory`, `FileBrowser.LoadDirectory` and FLTK's file
  chooser (`Fl_File_Chooser::sort`). `test/names/` holds empty files
  whose names each sort orders differently, which `TestDialogs` and
  `TestBrowsers` list.

### Phases 14 to 22: the rest of FLTK's classes

Planned 2026-10-30, with poc 0.10.1 and FLTK 1.4.5. These phases bind
every public FLTK class still unbound, and port the four examples
"Scope" used to leave out, so that all 46 of `examples/` are ported.
The list came from comparing FLTK's headers with what the C++ parts
call. As in Phases 9 to 13, a gap goes into the phase that finds it.

Left out: FLTK's internal classes, which a program doesn't use
directly, and threads.

Each phase ends as Phases 9 to 13 did:
- every test passes on `make test-headless` and `make test-sway`, and
  `make valgrind-headless` and `make valgrind-sway` are clean; and also
  `make test` on all six BSDs, since these phases add conditional
  builds;
- each binding has its own test, and each new halt its `Halt*` test;
- `doc/fltk-issues.md` records each FLTK problem found, with the short
  note in AGENTS.md;
- the phase is marked `[done]`, with what it found.

Each example:
- goes in `EXAMPLES`, so `make test` runs it;
- is a **port**, if an FLTK program uses the class, named for FLTK's
  file in CamelCase (`InputChoice` for `test/input_choice.cxx`), with
  the same first comment as other ports, naming the FLTK file. FLTK's
  `test/` has built binaries, as `examples/` has, so a port from `test/`
  is compared with FLTK's own build as before;
- is **new**, if no FLTK program uses the class. A new example is named
  for what it shows, as `Swatch` and `Menus` are, is small, and has a
  first comment saying what it shows. It has no FLTK build to compare
  with, so it is looked at under Xvfb, with `xdotool` driving it.

Order: as before, the cheap bindings come first. Those with new
lifetime problems follow, and those needing more libraries come last.

Facts behind the plan, each from a program run on 2026-10-30:
- `Fl_Gl_Window` draws on Xvfb and on the headless sway, with llvmpipe,
  and `glReadPixels` reads 255 0 0 back on both. It does the same under
  Xvfb on cymoril, yishana and artos, so GL tests can check pixels on
  all of them.
- `Fl_Overlay_Window`'s `can_do_overlay` is 0 on both, and its
  `draw_overlay` still runs after `redraw_overlay`: FLTK emulates it.
- `<FL/forms.H>` compiles under `-Wall -Wextra -Werror`, with
  `Fl_Free`, `Fl_Timer` and `Fl_FormsText`.
- `Fl_PDF_File_Surface::begin_document` writes a one-page PDF here, and
  `Fl_PostScript_File_Device` a PostScript file. Without Pango,
  `Fl_PDF_File_Surface` returns 2 and the message "requires PANGO to be
  usable" (source: `drivers/PostScript/Fl_PostScript.cxx`).
- cairo, Pango and GLEW are on Fedora and all six BSDs.
  FLTK on Fedora and on cymoril (rebuilt 2026-10-30) has
  `FLTK_HAVE_CAIRO`, and `Fl_Cairo_Window` draws on cymoril, read back
  as 255 0 0 under Xvfb. The NetBSD FLTKs link cairo for Pango, but
  don't have `FLTK_HAVE_CAIRO`, so `Fl_Cairo_Window` and
  `Fl::cairo_make_current` don't exist there. An `Fl_Double_Window`
  whose `draw()` makes its own context from
  `cairo_xlib_surface_create(fl_display, fl_window, fl_visual->visual,
  w, h)` draws on yishana and artos, read back the same way. It also
  did on cymoril, before its rebuild.
- jherek (OpenBSD amd64), alerik (FreeBSD amd64) and rackhir (FreeBSD
  arm64) have FLTK 1.4.5 with `FLTK_HAVE_CAIRO`, and Xvfb, so they can
  build pofltk and run its tests, which have not been run there yet.
- `fltk-config --use-gl --use-forms --use-images --ldflags` gives what
  each needs. libfltk_forms and libfltk_gl exist on all six BSDs.

### Phase 14: Small widgets and types `[done]`

Widgets with no new lifetime problem, and FLTK's plain small types.

- **First, a baseline**: every host now has poc 0.10.1, and the last
  full runs were with 0.6.0. Run the four Linux targets and `make test`
  on the six BSDs before binding anything, so that a failure in this
  phase isn't blamed on the wrong change, and follow the usual steps
  for a new poc.
- **Missing features**: FLTK's builds differ (Cairo on NetBSD, Wayland
  on the BSDs), and poc has no conditional compilation, so an Oberon
  module compiles the same everywhere. What FLTK was built without is
  decided in the C++ parts, with `#if` on `fl_config.h`, as `ofl_paste`
  does for Wayland. Every `["C"]` procedure must exist at link time, so
  an absent feature gets a stub, not a missing function; a generated
  Oberon constant wouldn't remove that need. The later phases use what
  follows, so it comes first:
  - **`Fl.Has(feature)`**, one run-time question answered by the shim:
    `Svg`, `CairoWindow`, `Wayland`, `X11`. The last two open the
    display first, as `ofl_paste` does.
  - **`Probe.Wayland` moves into `Fl`**, as `Fl.Has(Fl.Wayland)`, and
    `TestMenus` and the rest use it.
  - **A program that uses a missing feature without asking halts**
    with `Fl.Unsupported`, since it could have asked. Its comment is
    widened to say so, and 79 stays free. Failures that depend on
    outside data still come back as a `BOOLEAN`, so PDF without Pango
    returns FALSE (Phase 19).
  - **The SVG guard**: `src/FlImages.cpp` used `Fl_SVG_Image` whatever
    FLTK said, and now tests `#if defined(FLTK_USE_SVG)`, as FLTK's
    source does (`doc/fltk-issues.md`, 73). SVG is reached only by
    content, through `Load` and `LoadData`, so it is outside data: an
    FLTK without it returns FALSE, like any file it can't read, and
    nothing halts.
  - **`Check.Skip(label)`** prints `skip - <label>`, for a check of a
    feature that is missing, and `Summary` counts them. `make test`
    totals the skips, so a host that tests less says so.
  - **`TestFeatures`**: `Fl.Has` against `fl_config.h`, read by a test
    module's C++ part, as `TestConstants` checks values. It catches a
    wrong case in the shim.
- **Valuator presets**, in `FlValuators`: `OpenFillSlider`,
  `OpenHorSlider`, `OpenHorFillSlider`, `OpenHorValueSlider`,
  `OpenNiceSlider`, `OpenHorNiceSlider`, `OpenFillDial`, `OpenLineDial`,
  `OpenSimpleCounter`. Each is a `kind` of `ofl_valuator_new`, making
  FLTK's class. Most only set the type, but the nice sliders also set
  `FL_FLAT_BOX`, which a test checks.
- **`Fl.OpenSingleWindow`** (`Fl_Single_Window`) and
  **`Fl.OpenMenuWindow`** (`Fl_Menu_Window`). `set_overlay` and
  `clear_overlay` are not in 1.4.5, so neither is bound.
- **`Window.SetXClass`, `XClass`** (FLTK copies the name) and
  **`Group.DrawChild`** were not listed: the `Clock` and `DoubleBuffer`
  ports need them. `DrawChild` halts with `Fl.NotAChild` for a widget
  that isn't the group's.
- **`FlButtons.ShortcutButton`** (`Fl_Shortcut_Button`): `Value` and
  `SetValue`, as a key and a state. FLTK's `default_value` and
  `default_clear` are inside `#if 0`, so neither is bound. It is not a
  `Button`: `Button.Value` is a `BOOLEAN`. The test sends it keys with
  `Probe`.
- **`FlInputs.FileInput`** (`Fl_File_Input`): `value` hides
  `Fl_Input_`'s, so call the class as itself. `errorcolor` does
  nothing and is deprecated, so it isn't bound.
- **`FlValuators.Positioner`** (`Fl_Positioner`): two values, bounds
  and steps.
- **`FlValuators.Clock`** (`Fl_Clock_Output`, `Fl_Clock`,
  `Fl_Round_Clock`): `value` takes an `unsigned long`, 32 bits on i386,
  so check what happens past 2038 and how it crosses the boundary.
  `Fl_Clock` runs on an FLTK timer: delete one with it pending under
  valgrind. Found: `SetTime` takes 0 to 2^32-1, as a `HUGEINT`, and
  halts past that (`doc/fltk-issues.md`, 74); `value(ulong)` writes
  over what it was given, so the shim calls it twice (76).
- **Tooltips**, in `Fl`: `Fl_Tooltip`'s statics (`SetTooltipDelay` and
  the rest, `EnableTooltips`, `TooltipCurrent`, `EnterArea`). Find
  whether `current` or `enter_area` keep a widget that may die. Found:
  `~Fl_Widget` clears the widget, and `enter_area` keeps its text, so
  the shim keeps a copy (75).
- **`Fl.Rect`**: `Fl_Rect` as a plain Oberon record, with `Right`,
  `Bottom`, `Inset`, `InsetBox` and `Equal`. FLTK's type doesn't cross
  the boundary.
- **Schemes**, in `Fl`: `SchemeCount`, `SchemeName`, `AddSchemeName`
  (`Fl_Scheme`). `add_scheme_name` copies its name.
- **`Fl.Tracker`** (`Fl_Widget_Tracker`): pofltk's handles already know
  a dead widget, so an Oberon `Tracker` holds the widget and asks the
  registry, with `Widget`, `Deleted` and `Exists`. FLTK's class lives on
  a C++ stack, so nothing of it is kept. The test deletes the widget in
  its own callback.
- Ports: `Clock` (`test/clock.cxx`), `DoubleBuffer`
  (`test/doublebuffer.cxx`).
- New examples: `Presets`, every preset valuator, tied together;
  `Positions`, a positioner setting a clock's hands; `Shortcuts`, a
  shortcut button that sets a button's key; `FileInputs`, a file input
  with its path bar; `Tooltips`, the settings, and a tooltip for each
  half of a box; `Rects`, drawing with `Rect`'s insets; `Trackers`, a
  button that deletes itself in its callback, and handles events there,
  so only a tracker can say it has gone.
- `make test-sway` found that a click on `Fl_File_Input`'s bar in a
  window not shown stops the program under Wayland (77): `TestInputs`
  shows its window first.
- Tested 2026-10-30: `test-headless` 932 `ok` lines, `test-sway` 928,
  `valgrind-headless` 849, `valgrind-sway` 845 (every error summary 0);
  `make test` on all six BSDs 932; on an FLTK with neither Cairo nor
  Pango 932, and on one without SVG 932, with 2 skipped.
- Both ports match FLTK's builds exactly, every window of each, under
  Xvfb (`magick compare -metric AE -fuzz 1%`, 2026-10-30).

### Phase 15: Composite widgets and audits `[done]`

- **`FlInputs.InputChoice`** (`Fl_Input_Choice`), with `Fl.BeginOpen`
  and a `kind`, though it is a group: its constructor calls `end()`, and
  its input and menu button are FLTK's, so `Group.Child` gives NIL for
  them. Its `Add`, `Clear`, `Value`, `SetValue`, `SetValueIndex`,
  `Changed`, `ClearChanged`, text and box settings. Its menu is
  an `Fl_Menu_Button` of FLTK's: its items are reached through the
  class, and `add` parses `/`, `&` and `|` as `Fl_Menu_::add` does.
  `value(int)` and `value(const char *)` set the input differently:
  test both.
- **`FlMenus.SysMenuBar`** (`Fl_Sys_Menu_Bar`), a `kind` of
  `ofl_menu_new`. It hides `menu`, `add`, `insert`, `remove`, `replace`,
  `clear`, `clear_submenu`, `mode`, `shortcut` and `setonly`, so call
  it as itself: `FlMenus.cpp`'s calls go through a small dispatch on
  `kind`. Also `About` and `CreateWindowMenu`. On X11 and Wayland it
  acts as a menu bar.
- **`FlDialogs.ColorChooser`** (`Fl_Color_Chooser`), a widget, beside
  the `fl_color_chooser` procedure: `Hue`, `Saturation`, `Value`, `R`,
  `G`, `B`, `SetHSV`, `SetRGB`, `SetMode`.
- **`Fl.OverlayWindow`** (`Fl_Overlay_Window`): a pure virtual
  `draw_overlay`, sent to Oberon as a method `DrawOverlay`, by a
  dispatcher `Fl`'s body registers, as `Draw`'s is; `RedrawOverlay`,
  `CanDoOverlay`. `Fl_Gl_Window` has the same virtual (Phase 21), so
  the dispatcher is written to serve both.
- **`Fl_Tree_Prefs`**: `Fl_Tree::prefs()` is const and `_prefs` private,
  so settings go through `Fl_Tree`'s own methods. Audit them: a rough
  search of `FlBrowsers.cpp` found no call of `openicon`, `closeicon`,
  `usericon` and their deactivated forms, `labelmarginleft`,
  `marginbottom`, `openchild_marginbottom`, `usericonmarginleft` or
  `item_draw_callback`. Bind what `Fl_Tree` exposes, and record what it
  doesn't. Find out whether FLTK keeps the icons' pointers: if so, the
  tree holds them through `Keeps`.
- **`Fl_Text_Selection`**, in `FlText`: an Oberon `Selection` view of
  the primary, secondary and highlight selections (`Selected`, `Start`,
  `End`, `Rectangular`, `Includes`, `Length`), with
  `SecondarySelect`, `SecondaryText`, `RemoveSecondary`,
  `ReplaceSecondary` and the same for highlights. The view holds the
  buffer and asks each time, since FLTK's objects live in the buffer.
- Ports: `InputChoice` (`test/input_choice.cxx`), `MenuBar`
  (`test/menubar.cxx`), `ColorChooser` (`test/color_chooser.cxx`),
  `Overlay` (`test/overlay.cxx`).
- New examples: `TreeIcons`, a tree with its own icons and margins;
  `Selections`, an editor showing all three selections.
- `InputChoice` is a `Widget`, not a `Group`: `Group.Clear` and `Remove`
  would delete the input and menu button FLTK's methods go on using.
- `SysMenuBar` is tested on X11 and Wayland, where it is a menu bar and
  `About` does nothing. Its macOS system menu is untested: no host here
  has macOS.
- `Fl_Tree_Prefs`: `item_draw_callback` is on `Fl_Tree_Prefs` alone,
  which `Fl_Tree` doesn't expose, so it can't be reached. The rest is
  bound as `Fl_Tree`'s: `SetOpenIcon`, `SetCloseIcon` and `SetUserIcon`
  in `FlImages` (FLTK keeps the pointers, 78), and the margins in
  `FlBrowsers`. `SetItemIcon` and `SetItemInactiveIcon` were added,
  since an item's icon goes the same way.
- `Selection` is a read-only view. `Fl_Text_Selection` in 1.4.5 has no
  rectangular selections, so there is no `Rectangular`; and its `set`
  and `update` don't redisplay, so a selection is set through the
  buffer.
- `MenuBar` needed what the plan left out, now bound: an item's look
  (`ItemLabelType`, `ItemLabelFont`, `ItemLabelSize`, `ItemLabelColor`
  and setters), `Fl.MenuLinespacing` and `Fl.ShortcutLabel`.
  `FL_SUBMENU_POINTER` isn't bound, so `&Huge`'s items are added.
- `InputChoice` and `MenuBar` write to `Err` what FLTK's write to an
  `Fl_Terminal`, and keep the window's size. Phase 18 finishes them.
  `ColorChooser` leaves out FLTK's argument naming an X11 visual, since
  `Fl::visual` and `Fl::own_colormap` aren't bound.
- The ports match FLTK's builds under Xvfb: `Overlay` and `ColorChooser`
  exactly, every shot, and `InputChoice` and `MenuBar` above the terminal,
  through every menu of `MenuBar` and its pop-up. `MenuBar` found 79.
- Tested 2026-10-30: `test-headless` 1005 `ok` lines, `test-sway` 1001,
  `valgrind-headless` 914, `valgrind-sway` 910 (every error summary 0);
  `make test` on all six BSDs 1005; on an FLTK with neither Cairo nor
  Pango 1005, and on one without SVG 1005, with 2 skipped.

### Phase 16: Images `[done]`

- **`FlImages.Bitmap`** (`Fl_Bitmap`) from bits: FLTK keeps the pointer
  unless `alloc_array` is set, so the shim copies and sets it.
- **XBM and ICO**: `Fl_XBM_Image`, `Fl_ICO_Image`. `format()` gains
  `#define` and `00 00 01 00`, by contents, as every format is. XBM's
  magic number is weak, so test a text file that merely starts
  with `#define`: it must come back as a failed load, not a crash.
  `Fl_XBM_Image` takes only a file name, so `LoadData` of XBM returns
  FALSE, unless the phase finds a better way. `test/images/` gains a
  4x2 file of each, and an ICO with two sizes, for its `id`.
- **`FlImages.Shared`** (`Fl_Shared_Image`): `Get`, `Find`, `Release`,
  `Reload`, `Count`, `RefCount`, `Original`. It has its own reference
  count, and `release` deletes at 0, where `ofl::Shared` already counts
  what widgets hold. So one `ofl::Shared` holds one FLTK reference, and
  lets it go at its own 0. Test a `Shared` shown by two widgets, deleted
  in each order, under valgrind. `Fl_Shared_Image::copy` makes another
  entry: check its count. `add_handler` takes a C function, so it is
  bound only as `RegisterImages`, unless a port needs more.
- **`FlImages.FileIcon`** (`Fl_File_Icon`): `Open`, `Add`, `AddColor`,
  `AddVertex`, `Load`, `LoadImage`, `LoadSystemIcons`, `Find`, `First`,
  `Next`, `Draw`, `Label`, and `SetIcon` on a `FileBrowser`. FLTK keeps
  a global list of icons, and their `pattern` pointer: check both, with
  what happens to a widget showing an icon that is deleted. Icons FLTK
  made have no Oberon object until asked for, as a `TreeItem` hasn't.
- Ports: `Bitmap` (`test/bitmap.cxx`).
- New example: `Icons`, an XBM, a generated bitmap, the sizes in an ICO,
  and a shared image on several buttons.

Findings and decisions, 2026-10-30:

- `doc/fltk-issues.md` 80 to 88. The two that matter beyond this binding
  are 87 and 88: `Fl_BMP_Image` and `Fl_GIF_Image` overrun the stack and
  heap on crafted files, in 1.4.5, and are worth reporting to FLTK.
- **Outside data never halts, so it mustn't crash either.** The phase
  found that only when a fuzz of the new formats crashed the old ones.
  So the shim checks BMP and ICO headers (`dib_ok`), and walks a GIF's
  blocks and LZW codes (`gif_ok`, `lzw_ok`), before FLTK's decoders see
  them, and a header's claimed size can't throw through `extern "C"`.
  The fuzz, 694 corrupted files through every loader under valgrind,
  ends with no invalid read or write; what valgrind still reports is
  uninitialised values, a truncated GIF's pixels used as table indexes,
  and `Fl_XPM_Image` reading inside its own buffer. Only decoding the
  files ourselves would stop those. The fuzz wasn't kept: crafted files
  (`test/images/`) keep each case it found. A fuzz is no proof, and FLTK's own loading (the file chooser's
  previews, `load_system_icons`) doesn't pass through the shim.
- **`LoadData` of XBM works**, against the plan: `Fl_XBM_Image` was too
  unreliable to use at all (81), so the shim parses XBM itself.
- `Bitmap` is a `Kind` of its own. `OpenBitmap` copies its bits, and
  `SetShape` or `ShareImage` of one halts (`Fl.Unsupported`): each wants
  pixels.
- `Shared`: one `Shared` holds one FLTK reference, `Close` is FLTK's
  release, and `Copy` of one must be a `Shared` and is the pool's entry
  (84). A `Shared` is always of the pool, so the `Open` procedures of
  other images, and `Load`, don't take one. `GetShared` never animates.
  `Scale` and the color changes reach every holder, and that is the
  point of sharing, except where FLTK would change or delete what it
  thinks is its copy, a tree's icons and a tile, which get a private
  one.
- `Reload`, `Find` and the rest stayed as planned, as `GetShared`,
  `FindShared` and `ShareImage`, and the pool's `add_handler` as
  `RegisterImages`, for FLTK's own loading alone: nothing here needed
  more. `FileBrowser`'s `SetIcon` is `SetFileIcon`. (2026-10-30: the
  program's handlers came after all, below Phase 17.)
- `FileIcon`: an icon lasts the program, as on FLTK's list, so there is
  no `Close`, and a widget showing one is safe. `Clear` empties it.
  `Label` sets a label type, so text set on the widget replaces it, and
  it halts for a window, whose label is its title.
  `load_system_icons` has a static guard; a test making icons changes
  how an `Fl_File_Browser` lays out in that process, so they have a
  test module of their own.
- Tests: `TestImageFiles`, `TestShared`, `TestFileIcons`; five halt
  tests. `Bitmap` matches FLTK's build exactly in all eight states of
  its buttons.
- `Icons` shows its bitmaps in their boxes, not behind their labels:
  `FL_ALIGN_IMAGE_BACKDROP` draws an image straight in `draw_backdrop`
  with no color set, so a bitmap comes out in the box's color, unseen.
- Tested 2026-10-30: `test-headless` 1158 `ok` lines, `test-sway` 1154,
  `valgrind-headless` 1059, `valgrind-sway` 1055 (every error summary 0);
  `make test` on all six BSDs 1158; on an FLTK with neither Cairo nor
  Pango 1158, and on one without SVG 1156, with 4 skipped.

### Phase 17: Choosers and help `[done]`

- **`FlDialogs.FileChooser`** (`Fl_File_Chooser`), not a widget, owning
  its windows, handled as `NativeFileChooser` is: `Open`, `Close`,
  `Show`, `Hide`, `Shown`, `Count`, `Value`, `SetValue`, `Directory`,
  `Filter`, `FilterValue`, `Rescan`, `Preview`, `ShowHidden`,
  `SetCallback`, `SetType`, `SetLabel`, `SetOkLabel`, text settings,
  position and size.
  - `label` passes straight to `window->label(l)`, which keeps it (30):
    the shim keeps a copy, as for `directory`, `filter` and `ok_label`,
    each checked in `src/Fl_File_Chooser.fl`.
  - The static label strings (`all_files_label` and the rest) are kept
    pointers: `SetChooserLabels` copies them for the program's life.
  - Its callback holds an Oberon object, so it is in the registry until
    `Close`. It may delete the chooser from within: test that.
  - `add_extra` takes a widget FLTK's chooser then holds: return the
    old one, and test deleting the chooser first.
  - `Fl_File_Chooser::sort` stays `ofl::numericsort`.
- **`FlHelp`**, a new module: `HelpView` (`Fl_Help_View`, a group):
  `Load`, `SetValue`, `Value`, `Find`, `SetTopLine`, `TopLine`,
  `SetTopLineName`, `LeftLine`, `Directory`, `FileName`, `Title`,
  `ClearSelection`, `SelectAll`, text settings. Its scrollbars are
  FLTK's. `Fl_Help_Func` returns a `const char *` from Oberon for FLTK
  to use: the view's method `Link(uri): BOOLEAN` fills a buffer the
  shim keeps until the next. `value` copies (`fl_strdup`).
- **`FlHelp.HelpDialog`** (`Fl_Help_Dialog`), not a widget, in
  libfltk_images, which every program links.
- Ports: `FileChooser` (`test/file_chooser.cxx`), `HelpDialog`
  (`test/help_dialog.cxx`).
- New example: `HelpPages`, a help view with its pages in the program,
  from its link method. `test/` gains a small HTML page.
- Done as planned, but: `FileChooser` has a `Callback` method, as a
  widget has, not `SetCallback`; `SetChooserLabel(which, s)` sets one
  text, not all; and `HelpView.Copy`, `Preview`, `SetExtra` and the rest
  of FLTK's public API came with them. `SetExtra` returns the old widget,
  NIL if it has been deleted. `Link` is one method, for links and
  images: a link's FALSE stays on the page, an image's shows FLTK's
  broken image; `SetValue` in `Link` makes `Load` a success, so pages
  can live in the program (`HelpPages`), but halts for an image.
- New issues: `doc/fltk-issues.md`, 89 to 93.
- `FileChooser`'s port uses a browser for its log until Phase 18 binds
  `Fl_Terminal`. It left out the PDF and PostScript previews
  (`Fl_Shared_Image::add_handler`, which runs Ghostscript), and each
  file's icon and relative name (`Fl_File_Browser::add`,
  `fl_filename_relative`), none of them bound then.
- **Those three, bound 2026-10-30**, and the port finished:
  - `FlImages.AddHandler` and `RemoveHandler`: an Oberon list behind one
    C++ handler; an `ImageHandler` gets the file's name, first
    `MaxHeader` bytes and their number, and returns an `Image` or NIL.
    FLTK owns what it is given, so it gets a copy. `GetShared` and
    `Reload` read through the shim, not FLTK, so they ask the list
    themselves, for what `Load` can't read: going through FLTK's `get`
    would run its decoders on files the shim refuses (issue 95).
  - `FlImages.AddFile`, `Fl_Browser::add` with an icon, in `FlImages`
    with `SetFileIcon`, since `FlBrowsers` doesn't know `FileIcon`.
  - `FlDialogs.FilenameRelative` and `FilenameRelativeTo`. The `BOOLEAN`
    is whether the result differs from `from`, not FLTK's return (94).
  - Previews in `FileChooser`: 0 pixels differ from FLTK's on a PDF and
    a PostScript file; on `it's.pdf` FLTK's Ghostscript command breaks
    on the quote, and this port's shows it, its quoting being the shell's.
- Checked against FLTK's builds under Xvfb: `HelpDialog` on FLTK's
  `help_dialog.html`, 0 pixels differ; `FileChooser`, with the same
  clicks (extra group, MULTI, a directory, Enter), 0 outside the log and
  file list.
- Tested 2026-10-30: `test-headless` 1281 `ok` lines, `test-sway` 1277,
  `valgrind-headless` 1175, `valgrind-sway` 1171 (every error summary 0);
  `make test` on all six BSDs 1281; on an FLTK with neither Cairo nor
  Pango 1281, and on one without SVG 1279, with 4 skipped.

### Phase 18: The terminal `[done]`

**`FlTerminal`**, a new module, with one `Terminal` type for
`Fl_Terminal`, a group whose scrollbars are FLTK's. Its header has
around 400 methods, most of them protected. The public ones are:
- size: `DisplayRows`, `DisplayColumns`, `HistoryRows`, `HistoryUse`,
  `ScrollbarSize`, `HScrollbarStyle`, the margins;
- text: `TextFont`, `TextSize`, the foreground and background colors
  (with `_default` and `_xterm`), selection colors, `TextAttrib`;
- behaviour: `RedrawStyle`, `RedrawRate`, `ShowUnknown`, `ErrorChar`,
  `Ansi`, `OutputTranslate`;
- output: `Append`, `AppendAscii`, `AppendUtf8`, `PrintChar`,
  `PlotChar`, `Clear`, `ClearScreen`, `ClearScreenHome`, `ClearHistory`,
  `ResetTerminal`, the cursor's movements, `Text`.

Hazards to check:
- `printf` is C varargs, so it isn't bound: a program formats in
  Oberon, and calls `Append`.
- `error_char` keeps its pointer: the shim keeps a copy.
- `Fl_Terminal` redraws on a timer (`RATE_LIMITED`): test deleting one
  with a redraw pending, under valgrind.
- `text()` returns a copy made by `strdup`: copy it to Oberon, and
  free it.
- Each method: check for one hiding `Fl_Group`'s, as `Fl_Table`'s do.
- A UTF-8 character split across two `Append`s must not be corrupted:
  test it.

Its test reads the grid back through `Text`: output, escape sequences,
scrolling into history, resizing. Pixels are compared only with the
widget's own earlier drawing (`doc/fltk-issues.md`, 69).

- Ports: `SimpleTerminal` (`examples/simple-terminal.cxx`).
  `test/terminal.cxx` is 2521 lines, mostly a FLUID panel, so it is not
  ported.
- New example: `Console`, a terminal with colored ANSI output from an
  input line, using `Pipe`.

Done 2026-10-30:

- `FlTerminal`, with `Terminal`, and the shim's `Term`. The cursor's
  protected moves are public through `using`, and `display_modified`,
  private, is reached by `append_ascii("")`.
- Found (`doc/fltk-issues.md`, 96 to 99): the worst is a real heap write,
  a cursor left off a smaller grid, which a fuzz under valgrind found
  and `Term::fit` stops. `error_char` past a cell, or a control
  character there, is refused (98).
- The sizes halt 78 rather than being clamped: each is a programmer's
  error, and FLTK's answers to them are a SIGFPE or a broken history.
  `MaxCells` bounds rows and history by columns, so a size can't throw
  `bad_alloc` through Oberon.
- `Text` with `below` returns every row of history and screen; without
  it, up to the cursor's row. Each row ends in a line feed. An empty
  terminal is one empty line.
- `examples/Pipe.cpp` no longer buffers: `Console` showed one line of
  three until the command wrote again, because stdio had read the rest
  and `Fl.WatchFd` can't see that. `AddFdAndPopen` was exposed to it too.
- `FileChooser`'s log is now a terminal, as FLTK's is.
- Checked against FLTK's builds under Xvfb: `FileChooser`, 0 pixels
  differ, before and after picking a file, log included; `SimpleTerminal`,
  16, all in the clock's seconds digit. `Console` was driven with
  `xdotool`: colors, errors, a failing command, output as it comes.
- Tested 2026-10-30: `test-headless` 1449 `ok` lines, `test-sway` 1445,
  `valgrind-headless` 1333, `valgrind-sway` 1329 (every error summary 0);
  `make test` on all six BSDs 1449; on an FLTK with neither Cairo nor
  Pango 1449, and on one without SVG 1447, with 4 skipped.

### Phase 19: Printing and the file surfaces `[done]`

**`FlPrint`**, a new module.

- A base type `WidgetSurface` (`Fl_Widget_Surface`): `Translate`,
  `Untranslate`, `Draw`, `DrawDecoratedWindow`, `PrintWindowPart`,
  `PrintableRect`, `Origin`. `FlImages.Surface` stays as it is, with
  this procedure list shared through the C++ parts where it costs
  nothing.
- `PagedDevice` (`Fl_Paged_Device`): `BeginPage`, `EndPage`, `EndJob`,
  `Margins`, `Scale`, `Rotate`, `PrintWidget`, `PrintWindow`.
- `Printer` (`Fl_Printer`), `PostScriptFile`
  (`Fl_PostScript_File_Device`), `PDFFile` (`Fl_PDF_File_Surface`),
  `EPSFile` (`Fl_EPS_File_Surface`), `SVGFile`
  (`Fl_SVG_File_Surface`).
- Each is `Open`ed, and made current between `Begin` and `End`, with
  order checked (`Fl.OutOfOrder`, 77), as `Surface` does. A surface
  left current when closed halts.
- `FILE *` stays in the shim, opened with `fl_fopen`. A file that can't
  be opened comes back as FALSE.
- `begin_job` and `begin_document` return an allocated message
  (`perr_message`): copy it to an Oberon string, and free it.
- `PDFFile.Begin` returns FALSE without Pango (above): bad outside data,
  so no halt. Its test accepts that only with FLTK's message. Every host
  here has Pango now, so that path is seen only by building FLTK without
  it.
- Find out what `Fl_Printer`'s dialog returns when cancelled, and
  whether `close_command` keeps its pointer.

`TestPrint` writes each file and reads back its first bytes (`%!PS`,
`%!PS-Adobe-3.0 EPSF`, `%PDF`, `<svg`). `Printer` is tested only by
cancelling its dialog with `Probe.Modal`: no test prints.

- Ports: `Device`, a subset of `test/device.cxx` (786 lines);
  `PixmapBrowser` (`test/pixmap_browser.cxx`).
- New example: `SaveAs`, a drawing saved as PostScript, EPS, PDF or SVG.

Done 2026-10-31:

- `FlPrint`, as above, with these changes. `PrintWidget` and `PrintWindow`
  are dropped: they would be `DrawWidget` and `DrawDecoratedWindow` under
  other names. A file surface ends with `Finish`, which says if it was
  written, and is separate from `End`, which only stops it being current.
  `FlImages.Surface` gained `DrawDecoratedWindow`, for `Device`.
- Answers to the questions above: `Fl_Printer`'s dialog cancelled returns
  1, errors 2 or more, `Printer.BeginJob` gives `JobCancelled` and
  `JobFailed`; `close_command` keeps only a function pointer, and isn't
  bound.
- `Fl_PostScript_File_Device`'s `begin_job` with its own file dialog is
  not bound: `FlDialogs.NativeFileChooser` and `OpenPostScript` do it.
- An SVG file starts `<?xml`, not `<svg`, so `TestPrint` searches for
  `<svg` rather than reading the first bytes.
- Found (`doc/fltk-issues.md`, 100 to 103): the worst is `end_job` on a
  closed file (101), covered by the shim's `Sink`. Drawing through
  `FlDraw` that breaks Cairo isn't covered: `FlDraw` can't tell a surface
  from a window, and scaling by 0 is legal on a window.
- An FLTK configured with `--disable-print` wouldn't link, and nothing a
  compiler sees says so (`doc/fltk-issues.md`, 104): `FlPrint.Available`
  finds out from a weak symbol. `make test` gained a skip for halt tests,
  `HALT(99)`.
- Tests, as `ok` lines (with the examples and halt tests): 1563 on
  `test-headless`, 1559 on `test-sway`, 1431 and 1427 on the valgrind runs,
  every error summary 0; `make test` passes on all six BSDs (1563, or 1555
  and a skip on OpenBSD, which has no `/dev/full`), so `funopen` works there.
  An FLTK with neither Cairo nor Pango has 1553 and 3 skips; one with no
  SVG and no printing has 1461.
- `SaveAs` found a bug of pofltk's: `FlDraw`'s `ensure_font` put every SVG
  text back to Helvetica 14. Fixed, and tested.
- `fl_file_chooser_callback`, listed in Phase 23, is done here:
  `FlDialogs.SetFilePicked`, for `PixmapBrowser`.
- `Device` leaves out what isn't bound: `Fl_Copy_Surface`,
  `fl_capture_window`, `Fl_Image_Surface::mask`, custom dash patterns and
  `fl_mult_matrix`'s shear. `PixmapBrowser` shows a directory as a
  document until `fl_filename_isdir` is bound.
- Checked against FLTK's builds under Xvfb: `PixmapBrowser` 0 pixels differ,
  with an image and with a missing file. `Device` differs only in the
  choices and drawings left out, and the clock's hands. Its image surface,
  PDF of the window, sub-window and group, and the print dialog (Escape
  cancels it) were driven with `xdotool`; `SaveAs`'s
  `Write` wrote all four formats, read back with `pdftoppm` and
  Ghostscript. Its file choosers weren't driven: GTK's opened behind the
  window, with no window manager, so a scratch copy called `Write`.

### Phase 20: Optional libraries and forms

Forms, GL and Cairo each need another library, and a program using only
widgets must not be linked with them.

- **Probe first**: poc's guide says a library's flags reach a program
  using it "directly or through another library", so a library should
  be able to import one. Build `pofltk` and a small library using `Fl`
  from it, run a program using both, and try it in a scratch install.
- **Design, if the probe passes**: `pofltk` stays as it is. Each of
  `FlForms`, `FlGl` with `FlGlut`, and `FlCairo` is a library of its
  own, importing `pofltk`, in its own directory, as the makefile's
  comment on `POC_OBERON_LIBRARIES` intends. The library names are
  settled by what `poc -library` accepts. If the probe fails, `make
  install` takes a list of optional modules, and the library's flags
  follow the list.
- **The makefile**:
  - `MODULES` splits into `MODULES`, and optional lists with their
    flags (`fltk-config --use-forms`, `--use-gl`, `pkg-config cairo`).
    `install` and `uninstall` handle each.
  - `LINK` becomes per program: a list like `EXAMPLEARGS`, as
    `name=flags`.
  - An optional part with no library is skipped, with a message, not
    an error: `HAVE_FORMS`, `HAVE_GL`, `HAVE_GLEW`, `HAVE_CAIRO` come
    from `fl_config.h` and `pkg-config`. Its tests and examples then
    aren't in `TESTS` or `EXAMPLES`, and `make test` says so.
  - A program can't adapt to a missing library at run time: importing
    `FlCairo` where it wasn't installed fails as the program is built,
    which is early and clear. Anything meant to be optional at run
    time has to live in `pofltk` itself.
  - A library records what FLTK offered as it was built, so rebuilding
    FLTK with other options means `make install` again, as a new poc
    does. README.md says so.
- **`FlForms`**, a new module:
  - `Timer` (`Fl_Timer`): `Value`, `SetValue`, `Direction`, `Suspended`.
    It has an FLTK timer: delete one running, under valgrind.
  - `Free` (`Fl_Free`): a `Handle(event, x, y, key)` method through a
    dispatcher the module's body registers, as `ofl_table_register`. The
    C function takes the widget, so it finds its object in the
    registry. `FL_CONTINUOUS_FREE` and `FL_ALL_FREE` run on timers:
    delete one with it pending.
  - `FormsBitmap`, `FormsPixmap`, `FormsText`: check whether `set` and
    `bitmap` keep pointers.
  - `fl_add_*` and the rest of `forms.H` are a C API for old programs,
    and aren't bound; the classes are.
- **`FlPreferences.Plugin`** and **`PluginManager`** (`Fl_Plugin`,
  `Fl_Plugin_Manager`), which need no library. A manager is
  `Fl_Preferences(0, "plugins/<class>")`, a runtime group, and a plugin
  is stored there as an address. So `Plugin`s stay in the registry
  until closed. `Plugins`, `PluginAt`, `PluginNamed`. `Load` and
  `LoadAll` are `dlopen`: whether a poc shared library can be a plugin
  is unknown. Probe it, and if not, bind them for C++ plugins and say so
  in the module's comment.
- Ports: `Forms`, the same window as `test/forms.cxx` but made with
  `FlForms`' classes.
- New examples: `FreeForm`, a `Free` tracing the mouse; `Plugins`, two
  plugins found by class and run.

### Phase 21: OpenGL and GLUT

- **`FlGl`**, a new module:
  - `GlWindow` (`Fl_Gl_Window`), with `Draw` sent to Oberon as for any
    window, and `DrawOverlay` through Phase 15's dispatcher: `Mode`,
    `SetMode`, `CanDo`, `Valid`, `ContextValid`, `Invalidate`,
    `MakeCurrent`, `SwapBuffers`, `SwapInterval`, `Ortho`, `PixelW`,
    `PixelH`, `RedrawOverlay`, `HideOverlay`.
  - `Fl_Gl_Window::mode` takes an `int` or an `int *`: the `int` alone.
  - `gl_draw`, `gl_font`, `gl_height`, `gl_color`, `gl_rect`,
    `gl_start`, `gl_finish`.
  - A subset of `gl.h`, as `FlDraw` is for `fl_draw.H`: what
    `test/cube.cxx` uses (`glBegin`, `glClear`, `glClearColor`,
    `glColor3f`, `glColor4f`, `glEnable`, `glDisable`, `glEnd`,
    `glFrustum`, `glLoadIdentity`, `glOrtho`, `glPushMatrix`,
    `glPopMatrix`, `glRotatef`, `glScalef`, `glShadeModel`,
    `glTranslatef`, `glVertex3f`, `glViewport`, `glBlendFunc`), plus
    `glReadPixels` for tests, through `ofl_gl_` functions. GL's `float`
    crosses as `double`, by the Conventions.
  - Constants through `gen-constants.py`, with `SPEC` gaining the GL
    header and `FL_RGB` and the rest.
- **`FlGlut`**, a new module: `glut.H`'s window-creating and callback
  functions (`Init`, `InitDisplayMode`, `InitWindowSize`,
  `CreateWindow`, `DisplayFunc`, `ReshapeFunc`, `KeyboardFunc`,
  `MouseFunc`, `IdleFunc`, `MainLoop`, `PostRedisplay`, `SwapBuffers`),
  and `Fl_Glut_Window`. GLUT's callbacks are global, per window, and
  plain C: top-level Oberon procedures pass as they are, so no registry
  is needed, but check that for each. `glutInit` takes `argc`, `argv`:
  use `Args.argv`, as `Fl.Args` does. `glutMainLoop` never returns,
  so a test must use `Fl.Check` instead.
- **OpenGL 3**: the two ports call GL's 3.0 functions, loaded by GLEW.
  Their shader code stays in a C++ part, `examples/GlThree.cpp`, in
  `EXAMPLECXX`, with `FlGl` for the window. They need `HAVE_GLEW`,
  which Fedora, cymoril, yishana and artos all have. Whether GL 3.0
  runs under the BSDs' Xvfb is not yet tried.
  Keep FLTK's exception for `GLEW_ERROR_NO_GLX_DISPLAY` under Wayland.
- `TestGl` draws in a window on both back ends, and reads pixels with
  `glReadPixels`. It deletes a window with a context, and tests `Valid`
  after a resize.
- Ports: `Cube` (`test/cube.cxx`), `GlOverlay` (`test/gl_overlay.cxx`),
  `GlutTest` (`test/glut_test.cxx`), `OpenGL3Test`
  (`examples/OpenGL3test.cxx`), `OpenGL3GlutTest`
  (`examples/OpenGL3-glut-test.cxx`).
- New example: `GlutCube`, the cube through `FlGlut` with its own
  `Fl_Glut_Window` beside FLTK widgets.

### Phase 22: Cairo, and finishing

- **`FlCairo`**, a new module: one `CairoWindow` type, and two ways
  under it:
  - with `FLTK_HAVE_CAIRO`, `Fl_Cairo_Window`, through `set_draw_cb`,
    on X11 and Wayland;
  - without, a `Fl_Double_Window` of the shim's whose `draw` makes a
    context with `cairo_xlib_surface_create`, on X11 alone. So the
    module works on every system here, though FLTK's class is missing
    on NetBSD (above).

  A Wayland FLTK without `FLTK_HAVE_CAIRO` has neither way, so
  `Fl.Has(Fl.CairoWindow)` is whether one of the two works on this
  display, and an `Open` where neither does halts with `Fl.Unsupported`
  (Phase 14).

  The program's `DrawCairo(c)` method gets an opaque `Context`, good
  only during the call: using one later halts with `Fl.OutOfOrder`.
- A subset of cairo: what `cairo-draw-x` and `cairo_test` use, as
  `FlDraw` is for `fl_draw.H` (`SetLineWidth`, `SetSourceRGB`,
  `SetSourceRGBA`, `MoveTo`, `LineTo`, `Rectangle`, `Arc`, `Stroke`,
  `Fill`, `Save`, `Restore`, `Translate`, `Scale`, and text).
- `TestCairo` reads pixels back: on X11 with `fl_read_image` from a
  shown window, as the probe did. Wayland needs a way of its own: find
  it. `FLTK_HAVE_CAIROEXT` isn't used.
- Ports: `CairoDrawX` (`examples/cairo-draw-x.cxx`), `CairoTest`
  (`test/cairo_test.cxx`). `cairo-draw-x` was the 46th example.
- **Finishing**:
  - README.md: the new modules, and the optional libraries;
  - AGENTS.md: Layout, Build, the facts found; "Status" to Phase 22;
  - `make install` of each library into a scratch directory, and a
    program built against each, following the README as Phase 8 did;
  - `doc/design.md` is history, and isn't changed.

### Phase 23: Free functions

The classes are bound by Phase 22; this phase is the functions outside
them. Surveyed 2026-10-30 by listing every function in FLTK's public
headers and looking for its name in `src/`; the `Fl::` statics are
listed too, as they are free functions in all but spelling. Do this
phase after Phase 22, and do its finishing again (AGENTS.md "Status",
README.md).

- **`FlUtf8`**, a new module, for `fl_utf8.h` (nothing of it is bound
  yet), on Oberon's `ARRAY OF CHAR`, so lengths and offsets are bytes:
  - decoding and walking: `fl_utf8len`, `fl_utf8len1`, `fl_utf8fwd`,
    `fl_utf8back`, `fl_utf8bytes`, `fl_utf8encode`, `fl_utf8decode`
    if unbound, `fl_utf8strlen`, `fl_utf_nb_char`, `fl_utf8test`,
    `fl_utf8_next_composed_char`, `fl_utf8_previous_composed_char`;
  - characters: `fl_nonspacing`, `fl_wcwidth`, `fl_wcwidth_`,
    `fl_toupper`, `fl_tolower` if unbound, `fl_utf_tolower`,
    `fl_utf_toupper`, `fl_utf_strcasecmp`, `fl_utf_strncasecmp`;
  - conversions: `fl_utf8toa`, `fl_utf8froma`, `fl_utf8to_mb`,
    `fl_utf8from_mb`, `fl_utf8locale`, `fl_locale_to_utf8`,
    `fl_utf8_to_locale`. Each writes to a buffer of a given size: check
    what each does with a buffer too short. The UTF-16 and `wchar_t`
    ones (`fl_utf8toUtf16`, `fl_utf8towc`, `fl_utf8fromwc`,
    `fl_ucs_to_Utf16`, `fl_utf2mbcs`) take an array of integers or
    Windows' code pages: bind them only if a port wants one.
- **`FlDialogs`, the rest of `filename.H`**: `FilenameAbsolute`,
  `FilenameExpand`, `FilenameIsDir`, `FilenameMatch`, `FilenameName`,
  `FilenameExt`, `FilenameSetExt`, `DecodeURI`. Like `FilenameRelative`,
  each copies what it reads first, and is tried on names that aren't
  well formed, and buffers too short.
- **`FlDialogs`, the rest of `fl_ask.H`**: `fl_message_icon`,
  `fl_message_icon_label`, `fl_message_position` (the three forms), and
  whether `fl_input_str`, `fl_password_str` and the plain `fl_choice`
  add anything to what is bound. `Fl_File_Chooser.H`:
  `fl_file_chooser_ok_label` (`fl_file_chooser_callback` came with
  Phase 19).
- **`FlDraw`, the rest of `fl_draw.H`**:
  - images: `fl_draw_image`, `fl_draw_image_mono` (from memory, and
    their callback forms, one more dispatcher), `fl_draw_pixmap`,
    `fl_measure_pixmap`, `fl_capture_window`,
    `fl_can_do_alpha_blending`;
  - offscreens: `fl_create_offscreen`, `fl_delete_offscreen`,
    `fl_begin_offscreen`, `fl_end_offscreen`, `fl_copy_offscreen`,
    `fl_rescale_offscreen`: an `Offscreen` object, with its handle
    checked and freed as a `Surface`'s is;
  - transformations: `fl_load_identity`, `fl_load_matrix`,
    `fl_mult_matrix`, `fl_transform_x`, `fl_transform_y`,
    `fl_transform_dx`, `fl_transform_dy`, `fl_transformed_vertex`,
    `fl_override_scale`, `fl_restore_scale`;
  - shapes and marks: `fl_chord`, `fl_rounded_rect`, `fl_rounded_rectf`,
    `fl_draw_circle`, `fl_draw_arrow`, `fl_draw_check`, `fl_draw_radio`,
    `fl_draw_box_focus`, `fl_frame`, `fl_frame2`, `fl_overlay_rect`,
    `fl_overlay_clear`, `fl_scroll` (with its callback), `fl_antialias`,
    `fl_cursor`;
  - text: `fl_text_extents`, `fl_expand_text`, `fl_rtl_draw`,
    `fl_add_symbol` (a drawing procedure kept for the program's life,
    one more dispatcher), `fl_set_spot`, `fl_reset_spot`,
    `fl_set_status`;
  - clipping: `fl_clip_region`, `fl_restore_clip`;
  - encodings: `fl_latin1_to_local`, `fl_local_to_latin1`,
    `fl_mac_roman_to_local`, `fl_local_to_mac_roman`: their static
    buffers are read at once into the caller's.
- **`Fl`, colors and boxes**: `fl_contrast_function`,
  `fl_contrast_level`, `fl_contrast_mode`, `fl_lightness`,
  `fl_luminance`, `fl_box`, `fl_down`, `fl_frame` of a box type (unless
  Oberon has them already, as `Fl.Darker` has `fl_darker`), and from
  `platform.H` `fl_parse_color`, `fl_command_modifier` and
  `fl_control_modifier`.
- **`Fl`, the statics no shim reaches**. Check each against what `Fl`
  has first (`EventState` covers `event_alt` and its fellows, so they
  are small wrappers or not needed):
  - events: `event_alt`, `event_ctrl`, `event_shift`, `event_command`,
    `event_buttons`, `event_button1` to `event_button5`,
    `callback_reason`, `compose`, `compose_reset`, `test_shortcut`,
    `get_mouse`, `grab`, `handle`, `add_system_handler`,
    `remove_system_handler`, `last_handler`;
  - loop: `flush`, `ready`, `add_check`, `remove_check`, `has_check`,
    `run_checks`, `has_idle`, `run_idle`, `has_timeout`,
    `remove_next_timeout`, `program_should_quit`, `hide_all_windows`,
    `next_window`, `damage`, `set_atclose`, `set_abort`, `default_atclose`;
  - time: `now`, `seconds_since`, `seconds_between`, `ticks_since`,
    `ticks_between`, whose `Fl_Timestamp` is a struct, so the shim keeps
    it behind a handle or two numbers;
  - fonts: `get_font`, `get_font_name`, `get_font_sizes`, `set_font`,
    `set_fonts`;
  - boxes and colors: `set_boxtype`, `get_boxtype`, `box_color`,
    `set_box_color`, `box_border_radius_max`, `box_shadow_width`,
    `draw_box_active`, `free_color`, `get_system_colors`,
    `own_colormap`, `visual`, `visible_focus`, `is_scheme`,
    `reload_scheme`;
  - the clipboard: `selection`, `selection_owner`,
    `selection_to_clipboard`, `add_clipboard_notify`,
    `remove_clipboard_notify`;
  - screens and input: `screen_dpi`, `screen_scale`,
    `screen_scaling_supported`, `keyboard_screen_scaling`,
    `insertion_point_location`, `reset_marked_text`, `enable_im`,
    `disable_im`;
  - version: `abi_version`, `api_version`, `version`, `abi_check`;
  - widget pointers: `watch_widget_pointer`, `release_widget_pointer`,
    `clear_widget_pointer`: Oberon has `Fl.Widget`'s dead handles, so
    probably not needed; say why if so.
- **Left out, and why**:
  - `forms.H`, `gl.h`, `gl_draw.H`, `glut.H` and the Cairo functions:
    Phases 20 to 22;
  - `Fl::lock`, `unlock`, `awake` and `thread_message`: poc has no
    threads, and FLTK's other thread would need to be Oberon's;
  - what a platform alone has: `mac.H`, `win32.H`, `x11.H`, `wayland.H`,
    `fl_xid`, `fl_find`, `fl_open_callback` and `fl_close_display`,
    unless a port shows a need; `gl_visual`, `use_high_res_GL` and
    `draw_GL_text_with_textures` go with Phase 21;
  - `fl_utf8.h`'s system calls (`fl_fopen`, `fl_open`, `fl_stat`,
    `fl_access`, `fl_chmod`, `fl_mkdir`, `fl_rmdir`, `fl_rename`,
    `fl_unlink`, `fl_getcwd`, `fl_getenv`, `fl_putenv`, `fl_system`,
    `fl_execvp`, `fl_chdir`, `fl_close_fd`, `fl_make_path`,
    `fl_make_path_for_file`): on POSIX, the systems poc has, they are
    the C calls, for which poc has `Files` and `Platform`;
  - `fl_strdup`, `fl_strlcpy`, `fl_old_shortcut`, `fl_casts.H`: for C
    programs, or deprecated;
  - FLTK's internals, spelled with a trailing `_` or in `*_driver`.
- **Tests**: a module per family, as before, with every buffer-writing
  function tried with a buffer too short, and under valgrind; a test of
  a function with a Wayland or X11 difference tests each.
- **Ports**, checked against FLTK's builds: `Utf8Test`
  (`test/utf8.cxx`, in part), `Fonts` (`test/fonts.cxx`), `Boxtype`
  (`test/boxtype.cxx`), `CursorTest` (`test/cursor.cxx`), `Offscreen`
  (`test/offscreen.cxx`), `Mandelbrot` (`test/mandelbrot.cxx`),
  `Symbols` (`test/symbols.cxx`).

### poc 0.4.0 `[done]`

When poc 0.4.0 was installed (2026-10-06), the 0.3.1 workarounds came out:
- **The makefile's staging is gone.** It copied `src/` to `build/src/`
  with each `.cpp` renamed `.c`, compiled them `-xc++` and linked
  `-lstdc++`. The makefile now refuses a poc older than 0.4.0.
  - It had a bug of its own, never exercised under 0.3.1: with a native
    poc, its `mkdir` rule for `test/` replaced the `test` target's
    recipe.
- **`make install`/`uninstall`** build and install the poc library
  `ofltk` in `$(POC_OBERON_LIBRARIES)/ofltk`, as polibfyaml's do.
  - Its manifest records `c++` and `link -lfltk`.
  - Tried in a scratch directory: `TestDelete` and `Hello`, built with
    only `poc -OC -library-path <dir>`, linked (by clang++, with
    `-lfltk`). `TestDelete` passed linked statically, and with
    `-shared-libraries`, where `libofltk.so` brings `libfltk` and
    `libstdc++` itself.
  - `make uninstall` removes exactly what was installed.
- **The prototype's and probes' C++ parts are `.cpp` now**
  (`prototype/FL.cpp`, `probes/gc-hazard/Fltk.cpp`). They build with
  `-link -lfltk` alone, and still behave as recorded.
- **Still worked around**: `ORD` of a `SET` under `-OC` fails in 0.4.0 as
  in 0.3.1.

### poc 0.4.1 `[done]`

poc 0.4.1 was installed during Phase 6 (2026-10-06):
- **`ORD` of a `SET` compiles under `-OC`**, and gives the right value
  (`ORD({0, 2, 31})` assigned to an `INTEGER`, a `SYSTEM.INT32` and a
  `HUGEINT`). The 16 `SYSTEM.VAL(SYSTEM.INT32, s)` workarounds became
  `ORD(s)`; `tools/gen-constants.py` checks set constants with `ORD`.
- **The makefile now requires poc 0.4.1 or later.**

### Rename to pofltk `[done]`

On 2026-10-07 the repository was renamed pofltk, and the project with it:
- `make install` writes the poc library `pofltk`, in
  `$(POC_OBERON_LIBRARIES)/pofltk` (`libpofltk.a`, `libpofltk.so`,
  `pofltk.library`, and `pofltk` in each module's `.owner`), so a
  program now passes `-library-path <lib>/pofltk`.
- `src/ofltk.h` became `src/pofltk.h`.
- The sections above the roadmap, AGENTS.md, README.md,
  `doc/fltk-issues.md`, the comments and the tests' names use the new
  name. The phases above this one, the open questions below and
  `doc/design.md` keep the old one, as the record of what was done.
- Kept: the `ofl` prefix of the C++ parts (`ofl::`, `ofl_`), which
  `test/vg-check.sh` matches, and the module names.

### Deleting twice `[done]`

On 2026-10-10, at the user's go-ahead, from a crash ova_cg_po's tests
found (`doc/fltk-issues.md`, 72): a widget queued inside a dispatch
stays in its group, so deleting or clearing the group outside one
before the queue ran freed it twice, and so did queuing a group before
its own child. `ofl::delete_widget` (`src/pofltk.h`) now does every
deletion `Delete`, `Clear` and a tree item's widget make: it marks what
it queues in the widget's `Ref`, queues nothing a queued group will
delete, and outside a dispatch runs the queue (`Fl::do_widget_deletion`)
before deleting. `TestDelete` has the four cases.

## Open questions

Decided 2026-10-06, with the user, as recommended when this plan was
written:

- ~~**Vendor FLTKAda's shim, or write ofltk's own?**~~ Decided: ofltk's
  own shim, using FLTKAda's as the reference for each class and copying
  its code where it fits (it is public domain).
  - Vendoring would have given about 180 bound classes at once, with
    ofltk defining the 33 `*_hook` symbols in one C++ file. But its
    lifecycle is shaped for Ada controlled types: the
    `*_extra_init_hook` calls, per-type `Draw_Ptr`, and Ada owning and
    freeing the C++ widget. It also has gaps against FLTK 1.4.
  - An own shim follows this plan's ownership model and is smaller per
    class through a `My_X` template.
- ~~**Module split.**~~ Decided: the table under "Modules", with one C++
  part per module, beside it.
- ~~**Size model.**~~ Decided: `-OC` (see "Types at the C boundary").
- ~~**Callbacks as methods only, or `action` too?**~~ Decided: both. The
  default `Callback` method calls `action` when it is set.
- ~~**Constructor naming.**~~ Decided: a plain procedure per class,
  `OpenButton(b, ...)`. A type-bound `Open` can't be redefined with
  different parameters in an extension.
- ~~**Halt code range.**~~ Decided: 70–79 (see "Halt codes"), clear of
  polibfyaml's 61–64 so a program using both can tell them apart.

- ~~**How much of `fl_draw.H` to bind before it's needed**~~. Decided
  in Phase 2: all of the common calls, so a custom widget seldom has to
  wait for one; offscreen drawing comes with images.
