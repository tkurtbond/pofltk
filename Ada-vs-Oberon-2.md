# FLTKAda and pofltk compared

A comparison of FLTKAda (`/usr/local/sw/src/tkb/fltkada`), the Ada
binding to FLTK, with pofltk, made 2026-11-06 after FLTKAda's Phase 14.
It asks three things: what each binding has that the other lacks, which
of FLTKAda's findings are bugs in pofltk, and why FLTKAda has so many
more lines.

## 1. What each binding has that the other lacks

The two bind nearly the same set of FLTK classes. Each gap below was
checked against both codebases, at the level of the API, not only by
FLTK call names (the shims name things differently).

### Only in pofltk

The first three are FLTKAda's own Phase 16, not yet started.

- **Forms**: `Fl_Free`, `Fl_Timer`, `Fl_FormsBitmap`, `Fl_FormsPixmap`,
  `Fl_FormsText` (`src/forms/`).
- **Plugins**: `Fl_Plugin` and `Fl_Plugin_Manager` (`FlPreferences`).
- **Cairo**: `FlCairo` binds about 75 cairo calls and has a window that
  works on any FLTK. FLTKAda has only `Fl_Cairo_Window`, which needs an
  FLTK built with Cairo, and no cairo calls.
- **`Fl.Rect`** as a type for users.
- **The UTF-8 byte functions** (`fl_utf8fwd`, `fl_utf8back`,
  `fl_utf8toa` and the rest): FLTKAda leaves most of this to Ada's own
  library.
- **Example programs**: CairoTest, Forms, FreeForm, GlutCube, Plugins,
  Rects.

### Only in FLTKAda

- **Threads** (`Fl::lock`, `unlock`, `awake`): pofltk leaves these out on
  purpose, since poc has no threads.
- **`Fl_Text_Editor` key bindings** (`add_key_binding`, the `kf_*`
  functions): pofltk's PLAN.md lists this as "Not done".
- **`Fl::add_system_handler`** and `remove_system_handler`.
- **`Fl_Menu_Item::pulldown`**: pofltk has only `Popup`.
- **Subclassing `Fl_Browser_`** with one's own items (`item_first`,
  `item_next`, `item_draw`).
- **`Fl_Text_Display` extras**: `wrapped_row`, `wrapped_column`,
  `redisplay_range`, `skip_displayed_characters`,
  `count_displayed_characters`, `findchar_forward`/`backward`,
  `linenumber_format`/`align`.
- **Window extras**: `iconize`, `default_icon`, `icons`,
  `fullscreen_screens`.
- **Smaller ones**: `measure_label`, `redraw_label`,
  `Fl::has_timeout`/`has_idle`/`has_check`, and the GLUT calls
  `glutWarpPointer`, `glutPushWindow`, `glutGetProcAddress`, plus
  `gl_texture_pile_height`.
- **Ports of FLTK test programs**: adjuster, animated, arc, ask, button,
  buttons, curve, pixmap, preferences and tree.

FLTKAda's `Fl_Widget_Tracker` is not a real gap: `Fl.Tracker` does the
same job.

## 2. FLTKAda's findings that are bugs in pofltk

FLTKAda's `FLTK-issues.md` (F1 to F34) and `FLTKAda-BUGS.md` were read
against pofltk's code.

### Confirmed by scratch programs, run on Xvfb

| FLTKAda issue | pofltk | What happens |
|---|---|---|
| F6 | `FlText.cpp` `ofl_buffer_search` | `SearchBackward(20, "a", FALSE, f)` on "abc" hangs. The case-insensitive path passes an unclamped start to FLTK; the match-case path clamps it. |
| F24 | `FlTerminal.cpp` | The count is ignored: `CursorTabRight(2)` from column 0 gives 8, not 16, and `CursorTabLeft(2)` from 24 gives 16, not 8. |
| F26 | `FlText.cpp` (FLTK's `loadfile`) | `LoadFile` of `caf\xE9\n` gives length 3 and no warning: the text is cut at the Latin-1 byte. |
| F5 | `FlLayout.cpp` `ofl_grid_set_layout` | In a 3×3 grid with a 3×3 span, `SetLayout(1,1)` then `Layout` gives invalid reads under valgrind (`Fl_Grid.cxx:471–477`). Spans aren't cut to the new size. |

### Likely, found by reading the code

- **F4, tooltips**: `ofl_tooltip_enter_area` frees its kept copy when
  given empty text, but FLTK still reads it afterwards.
- **Printer dialog labels** (FLTKAda-BUGS 36): `FlPrint.cpp` reassigns a
  `std::string` whose `c_str()` FLTK keeps. FLTK builds the print panel
  once and keeps `dialog_title`'s pointer (`print_panel.cxx:249`). The
  file chooser's labels are safe: `FlDialogs` keeps them in a deque.
- **F23, `Fl_Terminal` redraw per write**: `modified()` is
  `append_ascii("")`.
- **F27, grid cell setters** that don't call `need_layout`.
- **F29**: `FlGlut.BitmapCharacter` passes `ORD(c)` as it is for
  characters past 7FX, so bytes 80–9F give a CP1252 width mismatch.

### Wrong documentation

- **Issue 116** said a bad byte becomes U+FFFD. FLTK's default build
  decodes 80–9F as CP1252 and other bad bytes as Latin-1.
- **The FlGlut overlay guard** rests on a wrong claim (FLTKAda-BUGS 91);
  already in `000-todo.org`.

### Fixed, 2026-11-06

All nine were fixed the same day, each with a test that fails without
its fix, and recorded in `doc/fltk-issues.md` (139 to 144, and 75, 116
and 135 amended) and PLAN.md ("FLTKAda's findings"):

- F6, F24, F26 and F5, as above.
- F4 was real: on a tip shown recently, FLTK arms its timer after
  clearing the current widget, so a later "" doesn't stop it, and it
  reads the freed copy.
- The printer's texts were real: the check of the panel's title fails
  with the old shim, though valgrind sees nothing (the text sat inside
  its `std::string`).
- F23 was real, and worse: under `PerWrite` only the first write after
  the style was set redrew.
- F27 doesn't apply: pofltk binds no `Fl_Grid::Cell` setter.
- F29 was real for 80X to 9FX: `BitmapCharacter` now encodes UTF-8.
- Issue 116 is corrected.

### Already handled in pofltk

- F7: huge PNG and JPEG files are refused cleanly.
- F8: images loaded from memory get name 0.
- F13: pasted images are checked (`drop_pasted_image`,
  `ofl_event_is_image`).
- F14, F15, F16, F34: assertions in `FlDraw`.

F10 and F11 (bytes dropped on long lines) can't be fixed in a binding.

The `vg-check.sh` `operator new` gap in `000-todo.org` probably doesn't
apply: pofltk's valgrind logs write it demangled, "operator new(unsigned
long)", which the pattern matches; FLTKAda's write it mangled (`_Znwm`).

## 3. Why FLTKAda has so many more lines

| | FLTKAda | pofltk |
|---|---|---|
| Binding source | 100,041 (spec 28,382 + body 71,659) | 14,992 |
| C++ shim | 33,260 (.cpp + a .h per class) | 10,849 |
| Tests | 43,198 | 12,015 |
| Examples | 10,108 | 11,578 |
| Docs | 56,290 (mostly per-class HTML) | 6,534 |

The examples are about the same size; the difference is in the binding
layers:

1. **How C functions are declared**: FLTKAda has 2,973 `pragma Import`
   declarations of about 6 lines each, roughly 18k lines. pofltk has
   1,201 one-line `["C"]` imports.
2. **Layout style**: FLTKAda has 27,813 blank lines (gnatpp style),
   against 2,587 in pofltk.
3. **Ada writes everything twice**: 3,231 subprograms each appear in
   both spec and body. pofltk's 1,813 exported procedures each appear
   once.
4. **One C function per method**: FLTKAda's shim has a .cpp and a .h for
   each class, with one function per method. pofltk's shim is grouped by
   family and picks the method by a number (`case 9: cursor_tab_right`).
5. **One package per FLTK class**, even trivial subclasses, plus
   exception-safety wrappers around every callback from FLTK into Ada.

For example, `Fl_Terminal` takes 3,357 lines in FLTKAda and 952 in
pofltk, binding roughly the same methods.
