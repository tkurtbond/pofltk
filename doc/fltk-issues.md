# FLTK issues found while writing pofltk

Problems in FLTK 1.4 found while building pofltk: bugs, which crash or
contradict FLTK's documentation, and pitfalls, which are FLTK working as
intended in a way a binding must allow for. Each was seen in a program
that ran, and where possible traced in FLTK's source
(`/usr/local/sw/src/lang/C++/fltk/fltk-1.4.5/`).

Record each new one here as it is found, in the same form:

- **What happens**, with the FLTK version and back end (Wayland, X11)
  it was seen on, and the date.
- **Cause**, with the source file and function, if found.
- **Effect on pofltk**, and the workaround, with where it lives.
- **How it was confirmed**: the test or scratch program.

Entries keep their numbers, since comments in the code cite them; a
new one takes the next number, in whichever section it belongs.

Unless an entry says otherwise, the version is FLTK 1.4.5 (Fedora's
`fltk-1.4.5`), on Fedora 44, x86_64.

## Bugs

### 1. Drawing text before any `fl_font()` crashes (Cairo)

- **What happens**: `fl_draw(text, ...)` with no font set yet crashes
  under Wayland, where FLTK draws with Cairo. Found 2026-10-06 in the
  prototype (`doc/design.md`, "Problems found").
- **Cause**: `Fl_Cairo_Graphics_Driver::draw(const char *, int, float,
  float)` and `descent()` use `font_descriptor()` without checking it,
  and it is 0 until a font is set. `height()` and `width()` check it,
  and set a font or return -1, so the driver is inconsistent with
  itself.
- **Effect on pofltk**: every `FlDraw` text procedure sets FLTK's normal
  font first if none is set (`ensure_font` in `src/FlDraw.cpp`).
- **Confirmed**: the prototype's crash; source read 2026-10-06.

### 2. `fl_clip_box` returns the reverse of its documentation (Cairo)

- **What happens**: `fl_clip_box(x, y, w, h, X, Y, W, H)` is documented
  to return non-zero "if the resulting rectangle is different to the
  original". It returns 0 for a box that was clipped, and 1 for one
  wholly inside the clip, on both back ends: the image surface draws
  with Cairo on X11 too. For a box wholly outside the clip it sets `W`
  to 0 and leaves `H` (and possibly `X`, `Y`) unset. Found 2026-10-06.
- **Cause**: `Fl_Cairo_Graphics_Driver::clip_box`
  (`src/drivers/Cairo/Fl_Cairo_Graphics_Driver.cxx`) sets its result by
  comparing the box with the clip rectangle, not the result with the
  box. It returns as soon as `W < 0`, before setting `H`.
- **Effect on pofltk**: `FlDraw.ClipBox` is a proper procedure, giving
  only the rectangle; `ofl_draw_clip_box` drops FLTK's result and zeroes
  its outputs before the call.
- **Confirmed**: a C++ program in the scratchpad (on Wayland and on
  Xvfb), and `TestDraw`'s `ClipBox` checks.

### 3. A key no widget uses crashes when no window is shown

- **What happens**: `Fl::handle(FL_KEYBOARD, window)` for a key the
  focus widget and its parents don't use segfaults in `send_event`, when
  no window is shown and `Fl::belowmouse()` is set. Found 2026-10-06,
  sending synthesized events to a window never shown, on Wayland and
  on X11.
- **Cause**: `Fl::handle_` (`src/Fl.cxx`) then tries the key as a
  shortcut. In `case FL_SHORTCUT`, if the below-mouse widget's window
  isn't `first_window()`, it calls `send_event(FL_SHORTCUT,
  first_window(), first_window())`. With no window shown,
  `first_window()` is 0, and `send_event` calls `handle()` through it.
- **Effect on pofltk**: none on programs, since a real key can't arrive
  while no window is shown. The tests' `Probe.Key` (`test/Probe.cpp`)
  sends a key to the focus widget alone, as `Fl::handle_` does first,
  not through `Fl::handle`.
- **Confirmed**: `TestEvents` crashed this way (backtrace:
  `send_event` from `Fl::handle_` from `Fl::handle_`); source read.

### 4. A text input taking the focus before the display is open crashes (Wayland)

- **What happens**: under Wayland, `take_focus()` on an `Fl_Input`, or
  `Fl::focus()` of one, before any window is shown (so before the
  display is open) segfaults. A plain C++ program that does this before
  `show()`, a common way to choose the first field, crashes; on X11 it
  works. Found 2026-10-06.
- **Cause**: the input's `FL_FOCUS` handling (`Fl_Input_::handletext`)
  calls `Fl_Wayland_Screen_Driver::insertion_point_location`, which uses
  the screen driver's `seat` without checking it, and the seat is only
  set up when the display is opened.
- **Effect on pofltk**: `Widget.TakeFocus` and `Fl.SetFocus` call
  `fl_open_display()` first (`src/Fl.cpp`), which does nothing if the
  display is open.
- **Confirmed**: the C++ program (Wayland crash, X11 fine), and
  `TestInputs`, which gives inputs the focus in a window never shown:
  it crashed this way before the workaround, passes with it, and
  crashes again with it taken out.

### 21. `Fl_Grid::widget` writes past its rows for a row or column just out of range

- **What happens**: `widget(w, row, col, ...)` documents that it returns
  NULL if `row` or `col` is out of bounds. For `row == rows()` (or
  `col == cols()`) it returns a cell instead, made by reading and
  writing one past the end of the grid's row array. Found 2026-10-06.
- **Cause**: `Fl_Grid::widget(Fl_Widget *, int, int, int, int,
  Fl_Grid_Align)` (`src/Fl_Grid.cxx`) checks `row > rows_` and
  `col > cols_` where `cell()` checks `>=`, then `add_cell(row, col)`
  indexes `Rows_[row]`.
- **Effect on pofltk**: `Grid.PlaceSpan` and `Grid.Place` halt with
  `IndexOutOfRange` unless the whole span is inside the grid, before
  calling FLTK.
- **Confirmed**: a C++ program placing a box at row 2 of a 2 by 2 grid,
  under valgrind: an invalid read and an invalid write of 8 bytes just
  after the block `layout(2, 2)` allocated, and a non-NULL result.
  `test/HaltGridRange.Mod` checks the halt.

### 28. A menu popped up over a window not yet on the screen is fatal (Wayland)

- **What happens**: `Fl_Menu_Button::popup()` just after the window's
  `show()`, before the compositor has put the window on the screen,
  ends the program: FLTK prints "Fatal error no 1 in Wayland protocol:
  xdg_surface" and exits 1. Found 2026-10-06.
- **Cause**: the pop-up's `xdg_popup` is made against a parent surface
  not yet configured, a protocol error the compositor answers by
  disconnecting. FLTK waits for the menu window itself to be exposed
  (`Fl_Wayland_Window_Driver::makeWindow`), but not for its parent.
- **Effect on pofltk**: `MenuButton.Popup` calls `wait_for_expose()` on
  the button's window first, which returns at once once the window is
  there, and on X11; `Window.WaitForExpose` binds it for programs.
- **Confirmed**: a C++ program that shows a window and pops up a menu
  died this way every time; with `wait_for_expose()` between them, three
  runs of three worked. On X11 it works either way. `TestMenus` can't
  check it, since under Wayland the pop-up is closed at once (29).
  A tooltip shown over a window not yet exposed dies the same way:
  `TestTooltips` did, three runs of three on sway, until it called
  `WaitForExpose` after `Show` (2026-11-06).

### 36. `Fl_Text_Buffer::search_forward` and `search_backward` read past the text when matching case

- **What happens**: with `matchCase` set, a search for a string not in
  the buffer, or found only near its end, compares the string with
  bytes after the end of the text. Found 2026-10-06.
- **Cause**: `Fl_Text_Buffer::search_forward` (`src/Fl_Text_Buffer.cxx`)
  loops while `startPos < length()`, but compares the whole needle with
  `memcmp(sp, address(bp), l)`, `bp` running on past `length()`;
  `search_backward` does the same. The case-insensitive path reads
  through `char_at`, which checks.
- **Effect on pofltk**: `ofl_buffer_search` (`src/FlText.cpp`) does its
  own byte search, through `byte_at`, when matching case, and calls
  FLTK's otherwise.
- **Confirmed**: valgrind reported invalid reads in `TestText`'s search
  checks, and in a plain C++ program searching with `matchCase` set;
  none with the shim's search.

### 45. A binary PNM with a maxval under 255 is read unscaled

- **What happens**: a PNM in a binary form (P5, P6) whose maxval is
  under 255, such as ImageMagick writes for an image of pure colors
  (maxval 1), is read with its samples as they are: red is 1, 0, 0, not
  255, 0, 0. The text forms (P2, P3) are scaled. Found 2026-10-06.
- **Cause**: `Fl_PNM_Image::Fl_PNM_Image` (`src/Fl_PNM_Image.cxx`)
  reads P5 and P6 samples with `fread` when maxval is under 256, without
  the `255 * val / maxval` it uses elsewhere.
- **Effect on pofltk**: `ofl_image_load` (`src/FlImages.cpp`) reads the
  maxval from the header itself, and scales the samples after FLTK.
- **Confirmed**: `test/images/rb.ppm` (P6, maxval 1) read as 1, 0, 0;
  `TestImages` fails without the scaling.

### 48. Under Wayland a pasted image of the program's own is never deleted

- **What happens**: `Fl::paste(receiver, 1, Fl::clipboard_image)` of an
  image the program itself copied gives the receiver an `FL_PASTE` whose
  `Fl::event_clipboard()` is a new `Fl_RGB_Image`. When `handle()`
  returns 0, FLTK deletes it under X11, and for another program's image
  under Wayland, but not for the program's own under Wayland: it leaks.
  Found 2026-10-06.
- **Cause**: `Fl_Wayland_Screen_Driver::paste`
  (`src/drivers/Wayland/fl_wayland_clipboard_dnd.cxx`): the branch for
  `fl_i_own_selection[1]` calls `receiver.handle(FL_PASTE)` and returns,
  without the `delete` its other branch and the X11 driver's have.
- **Effect on pofltk**: `W<B>::handle` (`src/pofltk.h`,
  `drop_pasted_image`) deletes the image after the Oberon `Handle`,
  whatever it returned, unless `FlImages.TakePastedImage` took it (it
  sets `Fl::e_clipboard_data` to 0). FLTK then finds none to delete.
- **Confirmed**: `TestClipboard` under valgrind, with `W<B>::handle` not
  calling `drop_pasted_image`. Under X11 one image, accepted and not
  taken, was lost (as FLTK intends: the receiver owns it). Under Wayland
  the one refused was lost as well, made in
  `Fl_Wayland_Screen_Driver::paste` by `own_bmp_to_RGB`. With the call,
  none. `test/vg-check.sh` doesn't flag these, since FLTK allocates
  them: read the log.

### 49. Under X11, `Fl::copy` before the display is open crashes

- **What happens**: `Fl::copy` (and `Fl::copy_image`, which
  `Fl_Copy_Surface` calls) crashes in `XSetSelectionOwner` when no
  window has been shown yet. Under Wayland it works. Found 2026-10-06.
- **Cause**: `Fl_X11_Screen_Driver::copy` and `copy_image`
  (`src/Fl_x.cxx`) call `XSetSelectionOwner(fl_display, ...)` without
  `fl_open_display()`, and making a window doesn't open the display, so
  `fl_display` is still NULL. In the same way, `paste` of another
  program's data asks the X server with `fl_xid(Fl::first_window())`,
  which is 0 with no window shown, and the server's `BadWindow` error is
  printed.
- **Effect on pofltk**: `ofl_copy`, `ofl_paste`, `ofl_clipboard_contains`
  (`src/Fl.cpp`) and `ofl_image_copy_to_clipboard` (`src/FlImages.cpp`)
  call `fl_open_display()` first. Under X11 with no window shown,
  `ofl_paste` asks only for what the program owns (FLTK's exported
  `fl_i_own_selection`), so nothing is pasted and nothing printed.
- **Confirmed**: `TestClipboard` under Xvfb segfaulted in
  `XSetSelectionOwner` (gdb) at its first `Fl.Copy`; without the paste
  check, its first check printed `X_ConvertSelection: BadWindow` twice.

### 53. `FL_DND_LEAVE` crashes an input when no window is shown

- **What happens**: `Fl::handle(FL_DND_LEAVE, window)` segfaults in
  `Fl_Widget::window()`, from `Fl_Window::cursor`, from
  `Fl_Input::handle`, when the window holds an `Fl_Input` and no window
  is shown. Found 2026-10-07, sending synthesized drag and drop events
  to a window never shown, on X11 and on Wayland.
- **Cause**: `Fl_Input::handle` (`src/Fl_Input.cxx`), `case
  FL_DND_LEAVE`, calls `Fl::first_window()->cursor(FL_CURSOR_MOVE)`,
  and `first_window()` is 0 with no window shown. The input gets the
  event though the drag never entered it: `Fl::handle_` sends
  `FL_DND_LEAVE` to the below-mouse widget, the window, and
  `Fl_Group::handle`'s default case passes it to every child that takes
  events.
- **Effect on pofltk**: none on programs, since a real drag only
  reaches a window that is shown. `TestClipboard` tests drag and drop
  in a window of its own, with no input.
- **Confirmed**: `TestClipboard` crashed this way (backtrace above); a
  scratch C++ program with an `Fl_Input` and an `Fl_Box` in a window
  crashed on the `FL_DND_LEAVE`, unshown, on Xvfb and on headless sway,
  and didn't with the window shown.

### 54. A menu item's image or multi-label is read and freed as its text

- **What happens**: an `Fl_Menu_Item` showing an image or a multi-label
  (`image()`, `multi_label()`) holds the `Fl_Image *` or
  `Fl_Multi_Label *` in its `text`. `Fl_Menu_::remove` and `replace`
  `free()` that pointer, of an object made with `new` or static;
  `item_pathname` and `find_index` copy its bytes into the path as if
  they were text, so the item's path isn't found. Found 2026-10-07.
- **Cause**: `Fl_Menu_::remove` and `replace` (`src/Fl_Menu_add.cxx`)
  free every `text` of a menu made by `add()` (`alloc > 1`), whatever
  its `labeltype_`; `Fl_Menu_::clear` (`src/Fl_Menu_.cxx`, GitHub issue
  875) skips `_FL_IMAGE_LABEL` and `_FL_MULTI_LABEL`. `item_pathname_`
  and `find_index` use `label()`, which is `text`. `Fl_Menu_::insert`
  finds a path's submenus by their titles' `text` too.
- **Effect on pofltk**: a menu item showing an image or a multi-label
  (`FlImages.SetItemImage`, `SetItemMultiLabel`) points at an
  `ofl::ItemLabel` of its own (`src/pofltk.h`), which keeps the item's
  text as its name. Before `remove`, `clear_submenu` and `replace`,
  `FlMenus.cpp` gives each such item its name again (`plain`), and
  while `insert`, `item_pathname` and `find_index` run, the names stand
  in for the labels (`Names`). So paths, `ItemLabel` and `FindIndex`
  see the item's text.
- **Confirmed**: a scratch C++ program giving an item an image, as
  FLTK's `examples/howto-menu-with-images.cxx` does: valgrind's invalid
  free in `remove`, and in `replace`; `item_pathname` gave 9 bytes, not
  "File/New", and `find_index("File/New")` -1. `TestImages`.

### 55. `Fl_Multi_Label::label(Fl_Widget *)` frees nothing, and the widget later frees it

- **What happens**: a multi-label given to a widget whose label was
  set with `copy_label` doesn't free the copied text, as its
  documentation says it does: the text leaks, and the widget later
  `free()`s the `Fl_Multi_Label` as its copied label. Found 2026-10-07.
- **Cause**: `Fl_Multi_Label::label(Fl_Widget *)`
  (`src/Fl_Multi_Label.cxx`) calls `Fl_Widget::label(Fl_Labeltype,
  const char *)`, which (`FL/Fl_Widget.H`) assigns the type and the
  pointer and leaves the `COPIED_LABEL` flag set; `~Fl_Widget` and
  `Fl_Widget::label(const char *)` then free the pointer.
- **Effect on pofltk**: `ofl_widget_multi_label` (`src/FlImages.cpp`)
  calls `label(0)` first, which frees a copied label and clears the
  flag. Text set on a widget showing a multi-label (`ofl_widget_copy_label`,
  `src/Fl.cpp`) sets the type back to `FL_NORMAL_LABEL`, since
  `copy_label` keeps the type, and FLTK would draw the text as a
  multi-label.
- **Confirmed**: a scratch C++ program, a box with `copy_label` and
  then a multi-label, deleted: valgrind's invalid free in
  `~Fl_Widget`, and the copied text definitely lost.

### 57. `Fl::args` forgets an unknown option after once stopping at a word

- **What happens**: `Fl::args` returns 0 when it stops at an option
  that neither the program's handler nor FLTK knows, as documented,
  but only until a call has stopped at a word that isn't an option
  (`rest`, `-`, `--x`). After that, every call returns the index of
  the unknown option instead, as if it were such a word. Found
  2026-10-07.
- **Cause**: `Fl::arg` (`src/Fl_arg.cxx`) sets the file-static
  `return_i` when it meets a word that isn't an option, and `Fl::args`
  returns `return_i ? i : 0` for an argument nothing took; nothing
  clears `return_i`.
- **Effect on pofltk**: `ofl_args` (`src/Fl.cpp`) ignores `Fl::args`'
  result and looks at the word where it stopped: an option (a word
  starting with `-`, not `-` alone, not `--`) is unknown, and
  `ParseArgs` returns `FALSE`.
- **Confirmed**: a scratch C++ program calling `Fl::args` on
  `-bogus`, then on `-kbd rest`, then on `-bogus` again: 0, then 2,
  then 1. `TestArgs` parses its command line twice, the second time
  without the handler that takes `-o`.

### 59. An item removed in `Fl_Tree`'s callback as it is pushed is dragged after it is freed

- **What happens**: in a tree whose select mode is
  `FL_TREE_SELECT_SINGLE_DRAGGABLE`, an item removed (or replaced) in
  the tree's callback, which a push on it calls, becomes the tree's
  last item clicked after it is deleted; the drag that follows reads
  it, and moves it, from freed memory. Found 2026-10-07, on X11.
- **Cause**: `Fl_Tree::handle` (`src/Fl_Tree.cxx`), on `FL_PUSH`,
  calls `select_only(item, when())`, which calls back, and then sets
  `_lastselect = item` whatever the callback did; `FL_DRAG` then calls
  `_lastselect->move_into` and the rest. `Fl_Tree::remove` clears
  `_lastselect` only for the item it is given, and `~Fl_Tree_Item`
  clears the focus item but not `_lastselect` (41).
  `Fl_Tree_Item::replace` deletes the old item without either.
- **Effect on pofltk**: `Tr` (`src/FlBrowsers.cpp`) counts the items
  pofltk removes, and after an event in which any were removed, clears
  `_lastselect` unless it is still in the tree. `_lastselect` is
  private, so it is reached through an explicit instantiation
  (`Reach`). `TreeItem.Replace` adds the new item beside the old one
  (`Fl_Tree_Item::reparent`), and removes the old one as `Remove` does.
- **Confirmed**: a scratch C++ program (a draggable tree a, b, c; the
  callback replacing b as it is pushed, by `replace`, or by
  `reparent` and `Fl_Tree::remove`; then a drag to c and a release):
  valgrind showed two invalid reads, at `Fl_Tree.cxx:531` and in
  `Fl_Tree_Item::move`, either way. `TestTree` removes an item in its
  callback as it is pushed and drags: valgrind finds 4 errors without
  the clearing, none with it.

### 60. `Fl_Chart::maxsize(0)` drops every entry

- **What happens**: a chart starts with a maximum of 0 entries, which
  is no limit; setting the maximum back to 0, after another, drops
  every entry. Found 2026-10-07.
- **Cause**: `Fl_Chart::maxsize` (`src/Fl_Chart.cxx`) sets `maxnumb`,
  then keeps the last `maxnumb` entries if there are more: none, for
  0. `add` and `insert` treat 0 as no limit.
- **Effect on pofltk**: `Chart.SetMaxCount(0)` sets the private
  `maxnumb` alone, reached through an explicit instantiation (`Reach`,
  `src/FlValuators.cpp`); any other maximum goes through `maxsize`.
- **Confirmed**: in the source. `TestChart` sets the maximum to 3 and
  then back to 0, and inserts a fourth entry, which halts if the three
  are gone.

### 61. X11's window shape reads past an image drawn larger than its data

- **What happens**: `Fl_Window::shape` of an RGB image scaled larger
  than its data (`scale()`) reads past the data's end, on X11. Found
  2026-10-07.
- **Cause**: `Fl_X11_Window_Driver::shape_alpha_`
  (`src/drivers/X11/Fl_X11_Window_Driver.cxx`) reads `w()` by `h()`
  pixels of `data()`, which hold `data_w()` by `data_h()`. It also
  keeps the image's pointer as the shape. Wayland's
  (`Fl_Wayland_Window_Driver::shape_alpha_`) reads `data_w()` by
  `data_h()`.
- **Effect on pofltk**: `FlImages.SetShape` (`ofl_window_shape`,
  `src/FlImages.cpp`) gives FLTK a copy of the image at its drawn size,
  which the window holds.
- **Confirmed**: `TestImages` shapes a window with a 4 by 2 image
  scaled to 40 by 40: valgrind shows invalid reads in `shape_alpha_`
  when the shim passes the image itself.

### 63. `fl_numericsort` skips the character after a number, and reads past a name's end

- **What happens**: `fl_numericsort` and `fl_casenumericsort` never
  compare the character after a run of digits, so "a1za" comes before
  "a1yb", and after a run of digits that ends a name they read past
  its end: "ab12z" came before "ab12", and valgrind shows an invalid
  read. FLTK's file chooser and `Fl_File_Browser::load` sort with
  `fl_numericsort` by default. Found 2026-10-07, under valgrind, in
  FLTK's file chooser as a path was typed into it.
- **Cause**: `numericsort` (`src/numericsort.c`): after the digit runs,
  `UTF_A` and `UTF_B` hold the next characters, but the loop decodes
  the ones after them; and it checks for the end of a name only on the
  branch for characters other than digits.
- **Effect on pofltk**: `ofl::numericsort` and `ofl::casenumericsort`
  (`src/pofltk.h`) sort as FLTK documents: runs of digits as numbers,
  leading zeros aside, then what follows them; a name before a longer
  one it starts. `FlDialogs.ListDirectory`, `FileBrowser.LoadDirectory`,
  and FLTK's file chooser (`Fl_File_Chooser::sort`, set before each
  chooser is shown) use them.
- **Confirmed**: a scratch program listing a directory of "ab12" and
  "ab12z" (a name filling its `dirent` exactly) with `fl_numericsort`:
  valgrind's invalid read in `fl_utf8decode`, and "ab12z" first.
  `TestDialogs` and `TestBrowsers` list `test/names/`; with FLTK's
  sort, `TestDialogs` fails its check of the order, and valgrind finds
  the read.

### 64. A copy of an animation plays if the original has a frame shown

- **What happens**: `Fl_Anim_GIF_Image::copy` starts the copy playing
  whenever the original has a frame shown, playing or not; the source
  says "start if original also was started". Found 2026-10-07.
- **Cause**: `Fl_Anim_GIF_Image::copy` (`src/Fl_Anim_GIF_Image.cxx`)
  tests `frame_ >= 0`, which a stopped animation's frame also is,
  rather than whether its timer is pending.
- **Effect on pofltk**: none; `Image.Copy` says so, and `TestAnimGIF`
  checks that a copy of a stopped animation plays, so a fix in FLTK
  will show.
- **Confirmed**: `TestAnimGIF`.

### 66. `fltk-config` leaves out X11's directories on OpenBSD

- On OpenBSD 7.9 (i386, FLTK 1.4.5 built from source with CMake, X11
  only), `fltk-config --cxxflags` gives FLTK's include directory alone,
  and `--ldflags` gives `-lX11` and the other X libraries without
  `-L/usr/X11R6/lib`. OpenBSD keeps X11 in `/usr/X11R6`, off the
  compiler's paths, so `FL/platform.H`'s `#include <X11/Xlib.h>` fails,
  and so would the link. Found 2026-10-08 on cymoril.
- **Cause**: not traced. FLTK's own build finds X11 there, but the
  directories don't reach `fltk-config`.
- **Effect on pofltk**: the makefile adds `pkg-config`'s directories
  for `x11` (`X11_CXXFLAGS` and `X11_LIBS` in `GNUmakefile`), which are
  empty where X11 is on the usual paths. At run time OpenBSD's linker
  must also know `/usr/X11R6/lib` (`ldconfig -m /usr/X11R6/lib`, as
  root, if the cache lacks it).
- **Confirmed**: `make tests` on cymoril, failing before the change and
  building after.

### 71. pkgsrc's `fltk-config` names a `-lpng` that pkgsrc doesn't install

- On NetBSD 11.0 (i386, pkgsrc's `fltk-1.4.5nb1`), `fltk-config
  --use-images --ldflags` gives `-lpng -lz ... -lpng16 -ljpeg`, but
  pkgsrc's libpng installs only `libpng16` (no `libpng.so`), so every
  link with the image library fails: "cannot find -lpng". `-lpng16`, in
  the same list, is the library meant. Found 2026-10-08 on yishana.
- **Cause**: the `IMAGELIBS` line of the installed `fltk-config`. Not
  traced further.
- **Effect on pofltk**: the makefile drops a plain `-lpng` when the list
  also has a versioned one (`-lpng1...`) (`FLTK_LIBS` in `GNUmakefile`).
  Elsewhere the list is unchanged: Fedora's names no png library, and
  OpenBSD's FLTK built from source names `libpng.so` by its path.
- **Confirmed**: `make tests` on yishana, failing before the change and
  building after; `make test` there passes.

## Pitfalls

### 5. FLTK keeps the label pointer it is given

- `Fl_Widget::label(const char *)` (and `tooltip()`, and menu item text)
  stores the pointer, not a copy. An Oberon string may live on the stack
  or the collected heap.
- **pofltk** always uses `copy_label()` and `copy_tooltip()`.

### 6. `Fl_Window::copy_label` hides `Fl_Widget::copy_label`

- It is not virtual. `Fl_Window`'s version also sets a shown window's
  title, but calling a window through an `Fl_Widget *` reaches
  `Fl_Widget`'s, and the title doesn't change.
- **pofltk**: `ofl_widget_copy_label` (`src/Fl.cpp`) calls a window as a
  window, through `as_window()`.

### 7. Replacing auto-deleted user data deletes the old data

- With `AUTO_DELETE_USER_DATA`, FLTK deletes a widget's
  `Fl_Callback_User_Data` when the widget dies (in every way: explicitly,
  with its parent, by `Fl::delete_widget`, a shown window with its
  children), but also when the user data or callback is replaced.
- **pofltk** uses that deletion as its hook (`Ref` in `src/pofltk.h`), so
  replacing the data would unregister a live widget. `ofl::open` sets it
  once, and no C++ code may set the user data or callback again.

### 8. Some box and label types are defined only on first use

- `FL_ROUND_UP_BOX`, `FL_SHADOW_LABEL` and others are macros that call
  `fl_define_FL_ROUND_UP_BOX()` and so on, which register the type's
  drawing code. Their plain values, as an Oberon constant holds them,
  draw nothing until that has been called.
- **pofltk**: `ofl_register` (`src/Fl.cpp`) calls every `fl_define_FL_*`
  function when `Fl` starts.

### 9. A click no widget uses shows the window and becomes `pushed()`

- `Fl::handle_`, `case FL_PUSH` (`src/Fl.cxx`), sets `pushed_` to the
  window before offering the push to its widgets. If none uses it, it
  calls `window->show()` ("raise windows that are clicked on"). A window
  never shown is then shown, and its widgets get `FL_SHOW`.
- **pofltk**: nothing to change; `TestEvents` checks it, last, since it
  shows the window.

### 10. `changed()` is cleared after every callback but FLTK's default

- `Fl_Widget::do_callback` (`src/Fl_Widget.cxx`) calls
  `clear_changed()` after the callback returns, unless the callback is
  `Fl_Widget::default_callback`. A program with its own callbacks sees
  `changed()` only inside them.
- **pofltk** sets its own callback on every widget, so `Widget.Changed`
  is TRUE only inside a `Callback`; its comment says so. Confirmed
  2026-10-06 by `TestButtons`.

### 11. A push button is turned off before its callback

- `Fl_Button::handle`, `case FL_RELEASE` (`src/Fl_Button.cxx`), sets a
  normal button's value back to 0 before calling back, so a `Callback`
  never sees a push button on. Toggle and radio buttons keep their new
  value. Confirmed by `TestButtons`.

### 12. Fl_Slider::bounds hides Fl_Valuator::bounds

- It is not virtual. `Fl_Slider`'s version also asks for a redraw
  (`damage(FL_DAMAGE_EXPOSE)`); called through an `Fl_Valuator *`, a
  slider's new bounds aren't drawn until something else redraws it.
- **pofltk**: `ofl_valuator_bounds` (`src/FlValuators.cpp`) calls a
  slider as a slider. `TestValuators` checks the damage, and fails
  without it.

### 13. Fl_Spinner's color, selection_color and type hide Fl_Widget's

- They are its input field's, and not virtual, so through an
  `Fl_Widget *` they set the group behind the field instead. Its
  `format(const char *)` keeps the pointer, and passes the string to
  `snprintf` as a format, so the string must outlive the spinner and be
  a safe format.
- **pofltk**: `FlValuators.Spinner` overrides `Color`, `SetColor`,
  `SelectionColor` and `SetSelectionColor`, and its `Kind` calls the
  spinner's `type()`. The format is not bound.

### 14. A key event with no text is composed text under Wayland

- `Fl_Wayland_Screen_Driver::compose` returns 1 (text to insert, here
  none) for a key whose `Fl::e_text` is empty, unless the key is a
  modifier, function or cursor key. The window system gives BackSpace
  the text `"\b"`, so a real one works, but a synthesized BackSpace
  with no text deletes nothing. On X11 it works either way.
- **pofltk**: only tests synthesize keys; `TestInputs` sends BackSpace
  with `08X`, as the window system does.

### 15. Enter in an `Fl_Input` calls back only if changed, and selects all

- With `FL_WHEN_ENTER_KEY`, Enter calls back only if the text changed
  since the last callback (`FL_WHEN_ENTER_KEY_ALWAYS` always does), and
  either way puts the cursor at the end and the mark at the start
  (`insert_position(size(), 0)`), so the next key typed replaces all
  the text.
- **pofltk**: nothing to change; `TestInputs` checks both.

### 16. Fl_Value_Input gives the focus to a field FLTK made

- Its `Fl_Input` is a member, not an pofltk widget, so after
  `TakeFocus`, `Fl.Focus()` is NIL (pofltk returns NIL for a widget FLTK
  made). Keys typed go to the field, and set the value.
- **pofltk**: nothing to change; `TestValuators` checks it.

### 17. FLTK needs a display even for widgets never shown

- FLTK opens the display even to draw a widget never shown into an
  `Fl_Image_Surface` (PLAN.md, Phase 0). With none, FLTK prints "Can't
  open display" and exits 1.
- **pofltk**: `make test` refuses to run without `DISPLAY` or
  `WAYLAND_DISPLAY`; `make test-headless` uses Xvfb.

### 18. FLTK prefers Wayland whenever `WAYLAND_DISPLAY` is set

- Even when `DISPLAY` names an Xvfb server, as under a plain `xvfb-run`
  in a Wayland session, FLTK uses the Wayland desktop. With
  `WAYLAND_DISPLAY` unset it uses X11 by itself; `FLTK_BACKEND=x11`
  forces X11.
- **pofltk**: `make test-headless` and `make valgrind-headless` unset it.

### 19. The display stack leaks by design

- A C++ program that deletes all it makes shows about 390 KB "definitely
  lost" under valgrind, in 1,225 (X11) or 8,559 (Wayland) loss records.
  All are allocated by fontconfig and Pango's font cache, and under
  Wayland by GTK's window decorations (libdecor). There are no memory
  errors, on either back end.
- **pofltk**: leaks aren't valgrind errors in `make valgrind`;
  `test/vg-check.sh` fails instead on any leak allocated by pofltk's own
  code.

### 20. `fltk-config --cxxflags` gives more than FLTK's flags

- It includes `-I/usr/include`, which, searched ahead of the C++
  library's own directories, breaks its `#include_next`. It also
  includes Fedora's own build flags (`-specs=...` hardening files).
- **pofltk**: the makefile and `tools/gen-constants.py` pass only its
  `-I` and `-D` flags, without `-I/usr/include`.

### 22. `Fl_Flex::end` hides `Fl_Group::end`

- It isn't virtual, and it asks for a layout (`need_layout(1)`), so a
  flex ended through an `Fl_Group *` doesn't lay its children out when
  first drawn.
- **pofltk**: `ofl_group_end` (`src/Fl.cpp`) calls a flex as a flex.
  `TestLayout` draws a flex row after `End`, and fails without it.

### 23. `Fl_Group::clear` deletes the parts some groups are made of

- An `Fl_Scroll`'s scrollbars and an `Fl_Spinner`'s field and buttons
  are its children, and members of it, not allocated by themselves;
  `Fl_Group::clear` would `delete` them. `Fl_Scroll::clear` takes the
  scrollbars out first, and `Fl_Pack::clear` also clears the pack's
  `resizable()`, but neither is virtual, so through an `Fl_Group *`
  `Fl_Group::clear` runs instead.
- **pofltk**: `Group.Clear` (`ofl_group_clear` in `src/Fl.cpp`) deletes
  only the children pofltk opened, and clears a pack's `resizable()`.
  `TestLayout` clears a scroll, a spinner and a pack, and checks what
  is left; it fails without the pack's case.

### 24. `Fl_Tile` size ranges set after a move put the children back

- Without size ranges, `move_intersection` moves the children but
  leaves the sizes saved by `init_sizes()` as they were. Once a size
  range is set, `move_intersection` starts from those saved sizes
  (`drag_intersection`), so the next move puts the children back where
  they were first. A plain C++ program: after moving the border from
  150 to 100, setting a range and moving it from 100 to 20 left it at
  150. With the range set first, it stopped at the range, 80.
- **pofltk**: `Tile.SizeRange` and `Tile.InitSizeRange` call
  `init_sizes()` first (`src/FlLayout.cpp`). With ranges, FLTK saves
  the sizes after every move anyway, so that changes nothing else.
  `TestLayout` moves a border, sets a range, and moves it again; it
  fails without the fix.

### 25. `Fl_Pack` sets its own size as it draws

- `Fl_Pack::draw` places the children and then resizes the pack to fit
  them (`Fl_Widget::resize`, `src/Fl_Pack.cxx`): a vertical pack's
  height becomes theirs, plus the spacing. So its size before it is
  first drawn isn't the size it will have, and an image of it made at
  its old size doesn't match it.
- **pofltk**: nothing to change; `TestLayout` allows for it.

### 26. Inserting or removing menu items moves the item chosen

- `Fl_Menu_` keeps the item chosen (`value()`, `mvalue()`) as a pointer
  into its array, and `insert` and `remove` move the items after the
  change along the array without moving it. So inserting an item before
  it makes another item the one chosen, which a choice then shows, and
  removing it leaves it naming the item that took its place. A C++
  program: a choice with "A" and "B", "B" chosen, then "Z" inserted at
  0, had value 1, "A".
- **pofltk**: `ofl_menu_insert`, `ofl_menu_remove` and
  `ofl_menu_clear_submenu` (`src/FlMenus.cpp`) find the item chosen
  again afterwards by its text pointer, each item's own copy, which
  neither moves nor is freed by the change unless it is the item
  removed; then the menu has none chosen. `TestMenus` inserts and
  removes around a choice's value, and fails without it.

### 27. A deleted `global()` menu is used by the next shortcut

- `Fl_Menu_::global()` keeps the menu in a static pointer that nothing
  clears, and adds a handler that uses it for every shortcut no window
  takes. FLTK's documentation says not to destroy the menu. Deleted, it
  is used anyway: valgrind showed invalid reads in the handler
  (`src/Fl_Menu_global.cxx`), in a C++ program.
- **pofltk**: `Menu.Global` uses pofltk's own handler and pointer
  (`src/FlMenus.cpp`), which the menu's class clears in its destructor.
  `TestMenus` deletes a global menu and types its shortcut; without the
  clearing it crashes.

### 29. Under Wayland a pop-up menu of a window without the focus closes at once

- A menu popped up in a window the user hasn't clicked or typed in (so
  without the keyboard focus) is closed by the compositor
  (`popup_done`, in `Fl_Wayland_Window_Driver.cxx`) before it can be
  used, and `popup()` returns NULL. FLTK's own comment there notes that
  sway does the same when an application loses the focus.
- **pofltk**: nothing to change; a real program pops up a menu in answer
  to the user. `TestMenus` checks `Popup` only on X11 (`Probe.Wayland`),
  where `make test-headless` runs it.
- **Confirmed**: a C++ program, after `wait_for_expose()`: under
  Wayland the pop-up returned at once, before the timer that would have
  answered it; on X11 the timer's keys picked an item.

### 30. `fl_file_chooser` keeps its title pointer

- `fl_file_chooser` and `fl_dir_chooser` make one `Fl_File_Chooser` for
  the program, and set its title with `Fl_File_Chooser::label`, which is
  `Fl_Window::label`: it keeps the pointer, so the title outlives the
  call in the hidden window (`src/fl_file_dir.cxx`,
  `src/Fl_File_Chooser.cxx`). The pattern and file name are copied.
- **pofltk**: `ofl_file_chooser` (`src/FlDialogs.cpp`) copies the title
  into a static buffer first. Found in the source; no failure seen.
- `Fl_Native_File_Chooser` does the same when it uses FLTK's chooser
  (zenity, kdialog and GTK off or missing):
  `Fl_Native_File_Chooser_FLTK_Driver::title` is
  `_file_chooser->label(val)` (`src/Fl_Native_File_Chooser_FLTK.cxx`).
  The other drivers copy it, and every driver copies the filter,
  directory and preset file. `ofl_fnfc_set_text` keeps a copy beside
  the chooser. Confirmed 2026-10-06: with the copy, `TestDialogs` sees
  the title as set; passing the caller's string instead, it sees the
  text the program later wrote there.

### 31. The common dialogs take a printf format

- `fl_message`, `fl_alert`, `fl_choice`, `fl_input` and `fl_password`
  take a printf format and arguments, so a message holding a `%` would
  be read as one.
- **pofltk**: `src/FlDialogs.cpp` passes every text as the argument of
  `"%s"`. Found in the header (`__printf__` attributes); `TestDialogs`
  shows "100% done", but doesn't read the text back.

### 32. A key sent from a timer doesn't end a dialog until another event

- `Fl::wait` runs the timers due, then waits for an event. A key sent
  to a dialog from a timer (as the tests answer them) ends its loop only
  when the next event comes, and under Xvfb, with no window manager, none
  does: `fl_show_colormap` handled the Escape but never returned.
  Wayland's compositor sends events that wake it, and a real key is an
  event, so only programs answering their own dialogs meet this.
- **pofltk**: nothing to change. `TestDialogs` fires its timer once more
  after its keys.

### 33. `Fl_Choice::value(int)` hides `Fl_Menu_::value(int)`

- It isn't virtual, and the choice's also redraws, since a choice shows
  its value. Through an `Fl_Menu_ *` a choice shows its old value until
  something else redraws it.
- **pofltk**: `set_value` (`src/FlMenus.cpp`) calls a choice as a
  choice. `TestMenus` checks the damage, and fails without it.

### 34. A text buffer deleted before its displays is used after it is freed

- `~Fl_Text_Buffer` doesn't tell the displays using it, and
  `~Fl_Text_Display` removes its callbacks from its buffer, so a
  display destroyed after its buffer writes to freed memory, as does a
  display drawn after it.
- **Cause**: `Fl_Text_Buffer::~Fl_Text_Buffer` frees its callback
  arrays without calling them (`src/Fl_Text_Buffer.cxx`);
  `Fl_Text_Display::~Fl_Text_Display` calls `mBuffer->remove_modify_callback`
  (`src/Fl_Text_Display.cxx`).
- **Effect on pofltk**: a buffer is reference counted
  (`src/FlText.cpp`): `TextBuffer.Close` (or its finalizer) only marks
  it, and it is deleted when the last display holding it lets it go.
  A display lets go in the destructor of `Holds`, a base class
  destroyed after FLTK's display.
- **Confirmed**: in the source; and by mutation: with `Holds` as the
  last base class, or `close` deleting a buffer still held, valgrind
  reports invalid reads and writes in `TestText`.

### 35. A style buffer with no styles makes FLTK read before its style table

- A display given a style buffer by `highlight_data` with an empty
  style table reads entry -1 of the table as it draws or measures text.
- **Cause**: `Fl_Text_Display` indexes `mStyleTable[style - 'A']` after
  clamping the style to `mNStyles - 1`, which is -1
  (`src/Fl_Text_Display.cxx`, near lines 2373, 2528 and 2687).
- **Effect on pofltk**: `set_highlight` (`src/FlText.cpp`) gives FLTK
  the style buffer only once there is at least one style.
- **Confirmed**: by mutation: without the guard, valgrind reports
  invalid reads in `TestText`.

### 37. Browsers keep the column widths, filter and directory they are given

- `Fl_Browser::column_widths`, `Fl_File_Browser::filter` and
  `Fl_File_Browser::load` keep the pointer, not a copy, and read it as
  they draw or load again.
- **Cause**: they assign the pointer to `column_widths_`, `pattern_` and
  `directory_` (`FL/Fl_Browser.H`, `src/Fl_File_Browser.cxx`).
- **Effect on pofltk**: every browser keeps its own copies, in the base
  class `Keeps` (`src/FlBrowsers.cpp`), freed after FLTK's browser.
  `Fl_File_Browser` has no `directory()` accessor in 1.4.5, so FlBrowsers
  has none either.
- **Confirmed**: in the source; `TestBrowsers` sets the widths and the
  filter from arrays in a frame since written over, and fails when the
  shim passes FLTK the Oberon array.

### 38. A browser finds its top line only when it draws

- `Fl_Browser_` turns its scroll position into its top line in
  `update_top` (private), which only `draw` and `find_item` call. Until
  then `topline()` and `displayed()` read the old top line, and a browser
  never drawn has none, so a push on it selects nothing (`handle`
  checks `top_`).
- **Cause**: `src/Fl_Browser_.cxx`, `update_top`, `handle` (`FL_PUSH`).
- **Effect on pofltk**: `ofl_browser_topline` and the `displayed` case of
  `ofl_browser_line` (`src/FlBrowsers.cpp`) call the protected
  `find_item` first, which updates it. Clicks need nothing: a user can
  only click a browser that has been drawn. A test sending clicks draws
  the browser first (`Probe.Capture`).
- **Confirmed**: `TestBrowsers`: without the update, its checks of
  `TopLine` after `SetTopLine`, and of `Displayed` after `MakeVisible`,
  fail; and a click on a hold browser never drawn selects nothing.

### 39. `Fl_Browser::textsize` and `Fl_File_Browser::textsize` hide `Fl_Browser_`'s

- None is virtual. `Fl_Browser`'s also measures its lines again;
  `Fl_File_Browser`'s also sets the icon size to one and a half times
  the text size. Through an `Fl_Browser_ *`, neither happens.
- **Effect on pofltk**: `ofl_browser_set` (`src/FlBrowsers.cpp`) calls a
  file browser, then any `Fl_Browser`, as itself.
- **Confirmed**: `TestBrowsers` checks the icon size after
  `SetTextSize`, and fails when the shim calls `Fl_Browser_`'s.

### 40. What `Fl_Browser::load` and `Fl_File_Browser::load` return

- `Fl_Browser::load` adds a line for each newline and one after the
  last, so a file ending with a newline ends with an empty line, and
  splits lines longer than 1023 bytes; given "" it clears the browser
  and returns 1. `Fl_File_Browser::load` returns the number of the
  directory's entries (with `./` and the files the filter hides), not of
  the lines it lists.
- **Cause**: `src/Fl_Browser_load.cxx`, `src/Fl_File_Browser.cxx`.
- **Effect on pofltk**: `Browser.Load` returns FALSE for "", and
  documents the empty last line; `FileBrowser.LoadDirectory` returns a
  `BOOLEAN`, the lines being `Count()`.
- **Confirmed**: `TestBrowsers` loads `test/Check.Mod` (35 lines, 36 in
  the browser).
- **The byte after each split is lost** (found by FLTKAda, its F10,
  2026-11-04): a line of 1030 bytes loads as lines of 1023 and 6. The
  loop reads a byte with `getc`, and when the buffer is full ends the
  line without storing it (`Fl_Browser_load.cxx:43-50`). `Browser.Load`
  calls `Fl_Browser::load` (`src/FlBrowsers.cpp:329`), so it loses the
  byte too, and its comment doesn't say so. Confirmed in FLTKAda
  (`test_browser_load`); in pofltk from reading the code, not run.

### 41. `Fl_Tree` keeps a removed item as the last one clicked

- `Fl_Tree::remove(item)` forgets `item` as the last item clicked
  (`_lastselect`), but not its descendants. When the last item clicked
  is removed with its parent, a Shift-click in a multi-select tree then
  extends the selection from an item no longer there: from the item
  clicked to the end of the tree.
- **Cause**: `Fl_Tree::remove` (`src/Fl_Tree.cxx`) compares only `item`
  with `_lastselect`; `Fl_Tree_Item::~Fl_Tree_Item` clears the tree's
  focus item, but not `_lastselect`. `extend_selection` only compares
  the pointer, so it reads no freed memory, unless the pointer is
  reused.
- **Effect on pofltk**: `remove` (`src/FlBrowsers.cpp`) removes an
  item's descendants one by one through `Fl_Tree::remove`, last first,
  before the item.
- **Confirmed**: a C++ program (a multi-select tree a/b, c, d, e; click
  b, remove a, Shift-click c) selected c, d and e; with b removed before
  a, c alone. `TestTree` checks it, and fails when the shim removes as
  FLTK does.

### 42. `Fl_Tree::callback_item()` outlives the item

- An item removed in the tree's callback stays `callback_item()`, a
  pointer to a deleted item.
- **Cause**: nothing in `Fl_Tree::remove` or `~Fl_Tree_Item` clears
  `_callback_item` (`src/Fl_Tree.cxx`, `src/Fl_Tree_Item.cxx`).
- **Effect on pofltk**: `remove` clears it when it removes that item, so
  `CallbackItem` returns NIL.
- **Confirmed**: in the source; `TestTree` removes the item in its
  callback, and fails without the clearing.

### 43. `Fl_Tree::clear` deletes the root

- A tree starts with a root item, "ROOT"; `clear()` deletes it with the
  rest, and `root()` is then NULL until `add(path)` makes a new one.
- **Cause**: `Fl_Tree::clear` (`src/Fl_Tree.cxx`); `remove(root())`
  calls it.
- **Effect on pofltk**: `Tree.Root` may return NIL, as documented; an
  old root's `TreeItem` is no longer live.
- **Confirmed**: `TestTree`.

### 44. Wayland has no window icons

- `Fl_Window::icon` and `icons` do nothing under Wayland.
- **Cause**: `Fl_Window_Driver::icons` is empty, and only the X11,
  Windows and macOS drivers override it (`src/Fl_Window_Driver.H`,
  `src/drivers/`).
- **Effect on pofltk**: `FlImages.SetIcon` says so.
- **Confirmed**: in the source.

### 46. An empty label is laid out as a line of text

- A widget whose label is `""`, not NULL, with an image, draws the image
  above an empty line of text, so near the top of the widget, not in the
  middle: in a 20 by 20 box, a 4 by 2 image is drawn at its top edge,
  half outside it.
- **Cause**: `fl_draw` (`src/fl_draw.cxx`) counts the lines of any
  non-NULL text, and `""` is one line.
- **Effect on pofltk**: Oberon has no NULL string, so every module's C++
  part sets a label `""` as NULL (`ofl::label_text`, `src/pofltk.h`).
- **Confirmed**: under Wayland and X11, a box with label `""` and an
  image; `TestImages` fails when `""` reaches FLTK.

### 47. XPM color names are read only on X11

- An XPM image whose colors are names ("red") gets FLTK's gray for each
  under Wayland; `#rrggbb` colors work on both.
- **Cause**: `Fl_Pixmap` reads colors with `fl_parse_color`. The X11
  driver asks the X server, which knows the names; the Wayland driver
  uses `Fl_Screen_Driver::parse_color` (`src/Fl_Screen_Driver.cxx`),
  which reads hexadecimal alone.
- **Effect on pofltk**: none possible short of a color table of its own;
  `FlImages` says to use `#rrggbb` in XPM files. `test/images/rb.xpm`
  does.
- **Confirmed**: an XPM of "red" and "blue" read back `C0C0C0` for both
  under Wayland, and red and blue under X11.

### 50. Wayland has no selection buffer

- `Fl::copy` to the selection buffer (0) under Wayland keeps the text
  but offers it to no one, and `Fl::paste` from it does nothing; to both
  (2), it copies to the clipboard alone. X11 has both.
- **Cause**: `Fl_Wayland_Screen_Driver::copy` and `paste`
  (`src/drivers/Wayland/fl_wayland_clipboard_dnd.cxx`): `paste` returns
  at once for a source other than 1.
- **Effect on pofltk**: none; `Fl.Copy` and `Fl.Paste` say so.
  `TestClipboard` tests the selection buffer under X11 alone.
- **Confirmed**: `TestClipboard` under headless sway: text copied to the
  selection buffer and pasted from it gives no `FL_PASTE`.

### 51. An `Fl_Preferences` group outlives its node

- An `Fl_Preferences` made for a group points to the group's node, which
  `delete_group`, `delete_all_groups` and `clear` of a group above it
  free, and deleting the database's root `Fl_Preferences` frees with
  every node. The group object is then left pointing to freed memory.
- **Cause**: `Fl_Preferences::~Fl_Preferences` (`src/Fl_Preferences.cxx`)
  deletes the `RootNode` for a root, which deletes the node tree;
  `Node::remove` deletes a node. A group object keeps a plain `Node *`.
- **Effect on pofltk**: `FlPreferences` keeps no `Fl_Preferences` for a
  group: a group is its database and its path, checked with
  `group_exists` before each call and made a short-lived
  `Fl_Preferences` for it (`src/FlPreferences.cpp`). A group deleted, or
  of a closed database, halts with `Fl.ClosedResource`.
- **Confirmed**: a scratch program reading `entries()` of a group after
  `delete_group`, and after deleting the root: valgrind's invalid read
  in `Fl_Preferences::entries`. `HaltClosedGroup`.

### 52. `Fl_Table` hides `Fl_Group`'s child methods

- A table's own children are its two scrollbars and an inner
  `Fl_Scroll`; the widgets of its cells are the inner group's.
  `Fl_Table`'s `begin`, `end`, `add`, `insert`, `remove`, `children`,
  `child`, `find`, `array` and `init_sizes` reach the inner group, but
  hide `Fl_Group`'s rather than overriding them, so through an
  `Fl_Group *` they reach the scrollbars and the inner group instead.
  `Fl_Table::end` also shows the inner group if it has widgets.
- **Cause**: `FL/Fl_Table.H`: the methods are plain inline members,
  forwarding to `table`, the protected `Fl_Scroll *`. The constructor
  (`src/Fl_Table.cxx`) leaves `table->begin()` current.
- **Effect on pofltk**: Fl.cpp's group functions call a table as an
  `Fl_Table` (`dynamic_cast`), as they call a flex as an `Fl_Flex` (22),
  so `Group`'s methods reach the widgets in its cells.
- **Confirmed**: `TestTable`; with Fl.cpp calling a table as an
  `Fl_Group`, its checks of `Children`, `Add`, `Remove`, `Insert` and
  `Clear` fail.

### 56. `Fl_Browser::icon` keeps the image, and a line removed drops it unseen

- An `Fl_Browser` line's icon is an `Fl_Image *` FLTK keeps and never
  deletes; the line can go by `remove`, `clear` or `load`, with
  nothing to say the image is no longer used. FLTK documents it: the
  caller keeps the icon allocated.
- **Cause**: `FL_BLINE::icon` (`src/Fl_Browser.cxx`) is a plain
  pointer, set by `Fl_Browser::icon` and freed with the line.
- **Effect on pofltk**: the browser holds each image a line shows
  (`ofl::Ref::keep`), and after each change to its lines or icons lets
  go of those no line shows (`ofl::drop_icons`, `src/pofltk.h`).
  `FlImages.SetLineIcon` sets one.
- **Confirmed**: `TestImages` counts the images a browser holds
  (`Probe.Kept`) as icons are set, lines removed and the browser
  cleared; with the release after `clear` taken out, its check fails.

### 58. An item's widget stays in the tree when the item goes

- An `Fl_Tree_Item`'s `widget()` is a child of the tree, which FLTK
  draws only through its item, but which `Fl_Group::handle` still
  sends events to. Removing the item leaves the widget in the tree,
  where it was last drawn: no longer drawn, but visible to FLTK, and
  taking clicks there. Found 2026-10-07, on X11.
- **Cause**: `~Fl_Tree_Item` (`src/Fl_Tree_Item.cxx`) sets `_widget`
  to 0, "Fl_Group will handle destruction": the tree's children are
  deleted with the tree. `Fl_Tree::handle` passes every event to
  `Fl_Group::handle` first.
- **Effect on pofltk**: an item's widget goes with the item, as a
  group's children go with the group: `drop_widget`
  (`src/FlBrowsers.cpp`) deletes it when pofltk removes the item, or
  clears the tree, later inside a dispatch. And the other way round: a
  widget deleted, or added to another group, leaves its item (`Tr`'s
  `on_remove`), since FLTK would otherwise draw a widget no longer
  there.
- **Confirmed**: a scratch C++ program (an item showing a button,
  drawn; the item removed with `Fl_Tree::remove`; a push where the
  button was) called the button's callback, its parent still the tree
  and `visible()` 1. `TestTreeItems` clicks where a removed item's
  button was, and checks it is deleted and calls nothing back.

### 62. An animation's timer redraws a canvas deleted first

- `Fl_Anim_GIF_Image` keeps its canvas widget's pointer, and while it
  plays redraws the canvas, and sets its image, from an FLTK timer.
  Nothing tells it the canvas is deleted, so the next frame uses freed
  memory. FLTK's `examples/animgifimage.cxx` notes that the animation
  must be deleted before its canvas. Found 2026-10-07.
- **Cause**: `Fl_Anim_GIF_Image::cb_animate` and `set_frame`
  (`src/Fl_Anim_GIF_Image.cxx`) use `canvas_`, which only `canvas()`
  sets.
- **Effect on pofltk**: an animation watches its canvas (`Anim`, an
  `ofl::Watcher`, `src/FlImages.cpp`), and forgets it as it dies; an
  animation deleted removes its timer (FLTK's destructor). So either
  may go first.
- **Confirmed**: `TestAnimGIF` deletes a playing animation's canvas,
  then runs its timer, under valgrind; and closes an animation whose
  timer is pending.

### 65. `Fl_Chart` cuts a label in the middle of a UTF-8 character

- An entry keeps its label in `str[FL_CHART_LABEL_MAX + 1]`, 18 bytes,
  copied with `strlcpy`, which can leave the first bytes of a character
  whose last cross the 18th: the label ends in invalid UTF-8. Found
  2026-10-07.
- **Cause**: `Fl_Chart::add`, `insert` and `replace`
  (`src/Fl_Chart.cxx`).
- **Effect on pofltk**: `entry_label` (`src/FlValuators.cpp`) cuts a
  label before such a character.
- **Confirmed**: in the source. `TestChart` draws 17 a's then an e
  acute, and checks it is drawn as 17 a's.

### 67. `fl_wl_display` is declared only in an FLTK with Wayland

- `FL/platform.H` declares `fl_wl_display()` only when FLTK was built
  with Wayland (`FLTK_USE_WAYLAND`, from `FL/fl_config.h`), so code
  calling it doesn't compile against an FLTK for X11 alone, such as
  the one built on OpenBSD. Found 2026-10-08 on cymoril.
- **Cause**: `FL/platform.H` includes `wayland.H` only under
  `FLTK_USE_WAYLAND`.
- **Effect on pofltk**: `ofl_paste` (`src/Fl.cpp`) and
  `ofltest_wayland` (`test/Probe.cpp`) call it inside
  `#if defined(FLTK_USE_WAYLAND)`; without it, FLTK is on X11.
- **Confirmed**: `make tests` on cymoril, failing before the change and
  building after; the Wayland tests pass on Fedora.

### 68. `Fl_Valuator::step()` returns extended precision on 32-bit x86

- `step()` is inline, `return A/B;`. On i386 a `double` comes back in
  an x87 register, at 80-bit precision, so `step()` after
  `precision(2)` (A = 1, B = 100) is not equal to the double `0.01`
  until it is stored. Found 2026-10-08 on cymoril (OpenBSD 7.9 i386).
- **Cause**: `FL/Fl_Valuator.H`; the i386 C ABI. Not FLTK's fault, but
  any double it computes and returns can do this.
- **Effect on pofltk**: none in the binding; a test stores a
  `LONGREAL` FLTK returns in a variable before comparing it exactly
  (`TestValuators`, SetPrecision).
- **Confirmed**: `TestValuators` on cymoril, failing before the change
  and passing after.

### 69. Two charts at different places draw differently on X11 without Cairo

- Two `Fl_Chart`s of the same size, entries and labels, at x = 0 and
  x = 200 in one window, captured with `Fl_Image_Surface` (as
  `Probe.Capture` does), differ by a pixel of the frame on OpenBSD's
  X11 (FLTK drawing through Xlib and Xft, without Cairo). On Fedora,
  with Cairo, they are the same. Found 2026-10-08 on cymoril.
- **Cause**: not found.
- **Effect on pofltk**: none in the binding. A test compares a widget's
  drawing with its own earlier drawing, not with another widget's
  (`TestChart`, the label check).
- **Confirmed**: `TestChart` on cymoril with two charts, failing, and
  with one, passing; a chart with label cutting disabled in
  `entry_label` still fails the one-chart check.

### 70. Moving the cursor up or down in text keeps its x, not its column

- `Fl_Text_Display::move_down` and `move_up` keep the cursor's
  horizontal position in pixels, so where it lands on a line of
  different text depends on the font's widths: from "heXX" the cursor
  lands nearer "worl" in Noto Sans (Fedora) and nearer "world" in
  DejaVu Sans (OpenBSD). Found 2026-10-08 on cymoril.
- **Cause**: FLTK working as intended (`src/Fl_Text_Display.cxx`,
  `move_up` and `move_down`, which keep `mCursorPreferredXPos`, in
  pixels).
- **Effect on pofltk**: none in the binding. A test that checks where
  the cursor lands uses a monospaced font (`TestText`, Courier).
- **Confirmed**: `TestText` on cymoril failing, and passing with
  Courier, on Fedora and cymoril.

### 72. A widget queued by `Fl::delete_widget` stays in its group

- `Fl::delete_widget` only hides the widget and adds it to a list,
  which `Fl::do_widget_deletion` deletes when the event loop next runs.
  Until then the widget is still its group's child. If the group is
  deleted or cleared at once before that (outside a callback), it
  deletes the child, and the list then deletes it again: a double free,
  a segfault in `Fl::do_widget_deletion`. So too inside a callback, if
  a group is queued before its own child: the list deletes the group,
  and with it the child, and then the child. Found 2026-10-09 by
  ova_cg_po, whose test picked File > New from the menu (a callback
  clearing a group of rows) and then loaded a file directly (clearing
  it again).
- **Cause**: `Fl::delete_widget` and `Fl::do_widget_deletion`
  (`src/Fl.cxx`) keep a plain list, and `~Fl_Group` deletes its
  children; neither knows of the other. FLTK expects a program to
  delete through `Fl::delete_widget` alone, or to run the event loop
  first.
- **Effect on pofltk**: before, `Delete` and `Clear` deleted at once
  outside a dispatch and queued inside one, so a program that did both
  to the same widgets could free one twice. Now every deletion goes
  through `ofl::delete_widget` (`src/pofltk.h`): a widget's `Ref` marks
  it queued, and `ofl::pending` counts them. Inside a dispatch, a
  widget that is queued, or in a queued group, isn't queued again.
  Outside one, the queue runs first (`ofl::flush`), so queued children
  leave their group before it is deleted; a widget already queued is
  deleted by that, not again. Taking a queued widget out of its group
  instead was rejected: FLTK may be iterating the group's children
  when the callback returns (`Fl_Group::handle`, `resize`).
- **Confirmed**: `TestDelete`'s queued cases (a group cleared inside a
  callback and then deleted or cleared outside one; a widget deleted
  inside and then outside; a group deleted inside a callback before
  its child, and before being cleared) segfaulted before the change,
  and pass after it, valgrind clean. Each part of the change, taken
  out, fails one of them.

### 73. FLTK built without SVG still has `Fl_SVG_Image`, if CMake built it

- **What happens**: FLTK has an option to leave SVG out, and whether
  the class is there depends on which build system left it out.
  `FLTK_USE_SVG` is the macro to test, and it can be defined as 0.
- **Cause**: CMake's `FLTK_OPTION_SVG=OFF` writes `#define FLTK_USE_SVG 0`
  (`#cmakedefine01`). `src/Fl_SVG_Image.cxx:19`, `src/nanosvg.cxx:23`,
  `src/fl_images_core.cxx:127` and
  `src/drivers/SVG/Fl_SVG_File_Surface.cxx:21` test `defined` or
  `#ifdef`, so with CMake the class stays, whatever the option says
  (`nm` on `libfltk_images.a`). `./configure --disable-svg` leaves the
  macro undefined (`fl_config.in:107`, `configure.ac:136-138`), and the
  class really goes.
- **Effect on pofltk**: FlImages must not name the class without it. An
  `#if FLTK_USE_SVG` would wrongly call a CMake build with the option
  off SVG-less, though harmlessly; an `#ifdef` matches what FLTK's own
  sources do, so pofltk tests `defined(FLTK_USE_SVG)`, in `FlImages.cpp`
  and for `Fl.Has(Fl.Svg)`. Without SVG, `FlImages` halts with
  `Fl.Unsupported` and `Fl.Has` says so first.
- **Confirmed**: with an FLTK from `./configure --disable-svg`, `make
  test` passes, 2 checks skipped, and `examples/SvgSimple.Mod` says it
  has no SVG (2026-10-30).

### 74. `Fl_Clock_Output::value(ulong)` crashes on a time `localtime` can't convert

- **What happens**: `value(1UL << 60)` segfaults.
- **Cause**: `src/Fl_Clock.cxx:139-146` dereferences what `localtime`
  returns. `localtime` returns NULL for a year that doesn't fit its
  `int`.
- **Effect on pofltk**: `ClockOutput.SetTime` halts with
  `Fl.Unsupported` for a time below 0 or above 2^32-1, the most an
  `unsigned long` holds on the 32-bit systems, so a program behaves
  alike on all of them.
- **Confirmed**: a scratch program exited 139 on that call (2026-10-30);
  `HaltClockTime`.

### 75. `Fl_Tooltip::enter_area` keeps its text

- **What happens**: the tooltip shown after `enter_area(w, x, y, W, H,
  text)` reads `text` when its delay ends, after the call has returned.
- **Cause**: `src/Fl_Tooltip.cxx:301` stores the pointer in the static
  `tip`, and compares pointers, not text, to see whether the tip has
  changed (`:297`).
- **Effect on pofltk**: `Fl.EnterArea` would pass a string that may die
  with a stack frame. The shim keeps one copy, until the next text. The
  same text keeps the same pointer, or the tip would restart each time
  the mouse moved in the area. The widget can't dangle: `~Fl_Widget`
  calls `fl_throw_focus`, which clears the current widget
  (`src/Fl.cxx:1215`).
- **"" didn't end it** (found by FLTKAda, its F4, and traced here
  2026-11-06): the shim freed its copy on "", but FLTK can still read
  it. On a tip shown recently, `enter_area` sets `tip`, then hides the
  tooltip window, which (`hide_common`, `fl_throw_focus`) calls
  `Fl_Tooltip::exit_` and clears the current widget, and only then arms
  `tooltip_timeout`. An `enter_area` with "" next goes to `exit_(0)`,
  which returns at once with no current widget (`:251`), leaving the
  timer armed: it reads `tip` (`:165`), and the window's label as it
  measures it (`Fl_TooltipBox::layout`). Text given while tooltips are
  off isn't taken. So the shim now keeps a copy until FLTK has taken
  another (tooltips on), passes "" as NULL, keeping the copy, and frees
  the last copy at exit.
- **Confirmed**: by the source; `TestTooltips` runs it clean under
  valgrind (2026-10-30). Since 2026-11-06 it shows the window, sets the
  delay to 0, and gives "other tip" then "" at once, and text while
  tooltips are off: the old shim gives invalid reads in
  `tooltip_timeout` and `fl_measure`, the new one none, on Xvfb.

### 76. `Fl_Clock_Output::value()` isn't what `value(ulong)` set

- **What happens**: `value(t)` then `value()` gives `t` only if the
  hands didn't move. If they did, it gives seconds past midnight in
  local time. The header says it returns seconds since the epoch, and
  it does for the same `t` set twice.
- **Cause**: `src/Fl_Clock.cxx:139-146` stores `value_ = v`, then calls
  `value(h, m, s)`, which stores `value_ = (H * 60 + m) * 60 + s` when
  they changed (`:125-131`). `tick` (`:209`) sets a running `Fl_Clock`
  the same way, once a second.
- **Effect on pofltk**: `ofl_clock_set_value` calls `value(t)` twice, so
  `ClockOutput.Time` gives back what `SetTime` set. A running `Clock`
  can't be helped, and `Time`'s comment says so.
- **Confirmed**: `TestValuators`, which failed with one call and passes
  with two (2026-10-30).

### 77. A click on `Fl_File_Input`'s bar in a window not shown stops the program under Wayland

**What happens:** a push on the directory bar of an `Fl_File_Input` in a
window never shown puts up an alert, "Fl_Window::make_current(), but
window is not shown().", and the call never returns unless it is
answered; then FLTK ends the program. On X11 the same click works.

**Cause:** `Fl_File_Input::handle_button` calls
`window()->make_current()` to measure the path's directories, and
`Fl_Wayland_Window_Driver::make_current` calls `fl_alert` and
`Fl::fatal` if the window isn't shown.

**Effect on pofltk:** none on a program, whose clicks come to shown
windows. It matters only to a test, which sends events to a window
never shown: `TestInputs` shows its window first.

**Confirmed:** `TestInputs` hung on a headless sway, and gdb showed it
in `fl_alert` under `make_current` under `handle_button` (2026-10-30).

### 78. A tree keeps its icons' pointers, and copies some of them

**What happens:** `Fl_Tree::openicon`, `closeicon` and `usericon` and
`Fl_Tree_Item::usericon` and `userdeicon` keep the image they are given,
and a tree draws it for as long as it is set. An image deleted first
is read after it is freed. `Fl_Tree_Prefs` also makes an inactive form
of each of the tree's three icons, as a copy it owns, but an item's
inactive icon is the program's to make.

**Cause:** `Fl_Tree_Prefs::openicon`, `closeicon` and `usericon` store
the pointer and call `copy()` and `inactive()` on it for `_opendeimage`,
`_closedeimage` and `_userdeimage`, which its destructor deletes.
`Fl_Tree_Item::usericon` and `userdeicon` store their pointer alone.

**Effect on pofltk:** `FlImages.SetOpenIcon`, `SetCloseIcon`,
`SetUserIcon`, `SetItemIcon` and `SetItemInactiveIcon` keep the image
in the tree's `Ref`, counted, and let go of one nothing shows any more
(`drop_tree_icons`). The deactivated copies are FLTK's: they die with
the prefs, before the `Ref` lets go of what they copied.

**Confirmed:** from FLTK's source, and `TestImages`' tree icons under
valgrind (2026-10-30).

### 79. `Fl_Menu_::add` can't see a hidden item, and matches a label it can

**What happens:** two things about how `add` finds an item already
there:
- a label added again in the same (sub)menu is the same item: its
  shortcut, callback and flags are replaced, and no item is added. So
  two items with one label can't both be added by `add`;
- a hidden item isn't found. A path through a hidden submenu makes
  another submenu of that name, not hidden, and the first stays empty.
  A hidden item added again is added twice.

**Cause:** `Fl_Menu_Item::insert` looks for a title or an item with
`m = m->next()`, and `next` skips what isn't `visible()`; and it fills
in the item it finds, which `compare` matched ignoring `&`.

**Effect on pofltk:** none in the binding, whose `Add` is FLTK's. A
table in C++ doesn't meet this, since it isn't searched, but a program
adding the same table one item at a time does. `examples/MenuBar.Mod`
adds such an item under a label of its own and sets the label after
(`SetItemLabel`), and hides a submenu after filling it (`SetItemFlags`).
Also, `Fl_Menu_::menu` sets the value to the first item, and items
added leave none, so a port sets it: a menu button shows its value
under the mouse.

**Confirmed:** `MenuBar` showed an `Invisible` submenu FLTK's build
doesn't, until it hid it last, and then its menus matched FLTK's
(2026-10-30).

### 80. An `Fl_Bitmap`'s `fail()` is always -1, and `release()` deletes an ordinary image

**What happens:** a good `Fl_Bitmap` and each copy of it have
`fail()` -1, the same as an image that failed to load. And
`Fl_Image::release()`, called on an image that isn't shared, deletes it.

**Cause:** `Fl_Image::fail()` returns `ERR_NO_IMAGE` when `d()` is 0,
and a bitmap's depth is 0. `release()` is virtual, and `delete this` in
`Fl_Image`.

**Effect on pofltk:** a loaded image is judged by `fail()` only where it
has pixels: the shim (`good`) takes a bitmap's success from its data and
size. `release()` lets the shim free an image one way, shared or not.

**Confirmed:** a program printing `fail()` of a good bitmap and its
copy; `TestImageFiles` (2026-10-30).

### 81. `Fl_XBM_Image` can't say it failed, and takes almost anything

**What happens:**
- a good file has `fail()` -1 (80), as a missing one does;
- a file with fewer bytes than its header says leaves the rest of the
  bits uninitialized, and valgrind reports them as they are drawn;
- `notxbm.h`, any text with two `#define`s and a `static` line, loads
  as a 1 by 2 "image";
- a huge size "loads";
- the array is allocated with `new uchar[n]` and `alloc_array` is left
  0, so it is never freed: a leak of each image.

**Cause:** the parser takes the first two lines matching
`#define %s %d`, any line starting `static `, and then every ` 0x%x`,
and stops at the end of the file with no check of the count. The
constructor doesn't set `alloc_array`.

**Effect on pofltk:** the shim parses the file itself first:
`<name>_width` and `<name>_height`, other `#define`s allowed, a sane
size, and the bytes all there. `Load` of anything else is FALSE. It
decodes to an `Fl_Bitmap` of its own, so `LoadData` reads XBM too, which
the plan had thought impossible, and nothing leaks.

**Confirmed:** `test/images/not-xbm.h`, `short.xbm`, `huge.xbm` and
`rb.xbm`, through FLTK's class and then `TestImageFiles`, under
valgrind (2026-10-30).

### 82. `Fl_ICO_Image` in memory calls `fopen(NULL)` for a PNG resource

**What happens:** an ICO image holding a PNG, read from memory, fails
(`fail()` -2), and valgrind reports `fopen` called with a null name.
The same data in a file loads. `id` -1 is the highest resolution, -2
loads nothing and gives the entry count in `idcount()`, with `w()` 0 and
`fail()` -1, and an `id` at or past the count gives `fail()` -3.

**Cause:** `Fl_ICO_Image::load_ico_` hands a PNG resource to
`Fl_PNG_Image` by the reader's file name, which is null for memory.

**Effect on pofltk:** the shim always reads the file whole and takes the
memory path, and decodes a PNG resource itself, from its offset in the
data, so file and memory act alike. `ICOCount` is the -2 call.

**Confirmed:** `test/images/rbpng.ico` under valgrind; `TestImageFiles`
(2026-10-30).

### 83. `Fl_Shared_Image::reload()` changes a scaled entry's place in the pool

**What happens:** `reload()` of an entry scaled from its file replaces
its image with the full size data, and sets the drawn size again. Its
`data_w()`, which the pool is sorted by, is now the file's, so the pool
is out of order, and a search can miss the entry or find the wrong one.

**Cause:** `Fl_Shared_Image::compare` orders by `name`, `data_w()` and
`data_h()`, and `reload` changes the data without sorting the pool.

**Effect on pofltk:** `Shared.Reload` reads the file through `load_file`
(so 81, 87 and 88 don't apply) and copies a scaled entry's image at the
entry's data size before putting it in, so the pool's order holds.

**Confirmed:** `TestShared`, finding a scaled entry after `Reload`
(2026-10-30).

### 84. A shared image's `copy()` is the pool's own entry

**What happens:** `Fl_Shared_Image::copy(W, H)` isn't a copy: it is
`get(name, W, H)`, and for the same size that is the very entry, with
one more reference. FLTK itself assumes `copy()` gives a private image:
- `Fl_Tree_Prefs` does `_opendeimage = _openimage->copy()`, then
  `inactive()`, and later `delete _opendeimage`. A shared image as a
  tree's icon therefore grays every user's pixels, and the `delete`
  leaves a freed entry in the pool;
- `Fl_Tiled_Image::color_average` and `desaturate` change the tile they
  copied, the same way.

Also, a scaled entry holds a reference to its original, so the original
stays in the pool until that entry goes. That is by design.

**Cause:** `copy(W, H)` and `copy() const` call `get`; plain `copy()`
adds a reference and returns `this`.

**Effect on pofltk:** `Copy` of a `Shared` must be a `Shared`
(`Fl.Unsupported` otherwise), and is documented as the pool's entry.
What FLTK would copy and change, a tree's icons and a tile, gets a
private image (`Img::unpooled`), so `SetOpenIcon` and `OpenTiled` leave
the pool alone.

**Confirmed:** from FLTK's source, and `TestShared`'s tree and tile
checks, under valgrind (2026-10-30).

### 85. `Fl_File_Icon::label` sets no measure

**What happens:** a widget showing a file icon as its label, when
measured (`measure_label`), is measured as text: the icon's own bytes
are read as a string. And a widget whose label was copied is left
marked so, and frees the icon's address.

**Cause:** `fl_define_FL_ICON_LABEL` calls
`Fl::set_labeltype(_FL_ICON_LABEL, Fl_File_Icon::labeltype, 0)`, and a
null measure means `fl_normal_measure`. `Fl_File_Icon::label` is
`w->label(FL_ICON_LABEL, (const char*)this)`, which keeps the icon's
address as the label's value, and clears no copied label.

**Effect on pofltk:** `FileIcon.Label` sets a measure of its own, and
clears the label first, and `Fl.cpp`'s label functions treat
`_FL_ICON_LABEL` as they do `_FL_MULTI_LABEL`: text set on the widget
replaces it.

**Confirmed:** from FLTK's source, and `TestFileIcons` under valgrind
(2026-10-30).

### 86. `Fl_File_Icon::load_image` crashes on images it can't convert, and `load` can't fail

**What happens:**
- `load_image` of an XBM reads past its data (valgrind), and of an SVG
  or `notxbm.h` crashes;
- `load` of a file it can't read warns and returns nothing;
- `load_fti` of bad data calls `Fl::error`, which by default prints,
  and returns 0, the same as success (only a file that can't be opened
  gives -1); a bad `vertex` just stops the reading, also returning 0,
  with a partial icon.

**Cause:** `load_image` takes `Fl_Shared_Image::get`'s image with
`count()` 1 to hold rows of pixels, with no case for a bitmap's depth of
0, and `load_fti` keeps no failure status.

**Effect on pofltk:** `FileIcon.Load` of an `.fti` catches `Fl::error`
for the call, and of anything else decodes through `load_file`, then
does on the RGB pixels what `load_image` does. Bad data gives FALSE,
and an icon left empty. An image of no RGB pixels, a bitmap, is FALSE.
The runs differ slightly from `load_image`'s, whose count for an XPM is
half ours: 68 here, 34 there, for `rb.xpm`. A partial `.fti` with a bad
`vertex` isn't caught, since FLTK says nothing: it is TRUE, with what
was read.

**Confirmed:** programs calling FLTK's, under valgrind; `TestFileIcons`
(2026-10-30).

### 87. `Fl_BMP_Image` overruns the stack with a file's bytes

**What happens:** a crafted BMP, or ICO, overruns a stack array with
bytes from the file. A corrupted ICO crashed under valgrind. **This is a
memory-safety bug in reading outside data**, worth reporting to FLTK.
Also, an unknown depth leaves the array unwritten, the array's size
overflows `int`, and a negative width isn't refused.

**Cause:** `Fl_BMP_Image::load_bmp_` reads `colors_used` from the header
and then that many entries into `uchar colormap[256][3]`, on its stack,
with no check. `new uchar[width*height*bDepth]` is an `int` product.

**Effect on pofltk:** every load in the shim (`Load`, `LoadData`, the
ICO paths, `GetShared`, `FileIcon.Load`) passes `dib_ok` first, which
checks the header's size, depth and color count. A bad header is FALSE.
And since a size that passes can still fail to allocate, and
`std::bad_alloc` must not cross `extern "C"`, the load calls catch it.
What FLTK loads by itself, the file chooser's previews and
`load_system_icons`' icons, doesn't come through the shim, and remains
exposed.

**Confirmed:** `test/images/colors.bmp`, `colors.ico`, `size.bmp` and
`depth.bmp`; a fuzz of corrupted files under valgrind, with no invalid
read or write once `dib_ok` was in (2026-10-30). A fuzz is not a proof.

### 88. `Fl_GIF_Image` overruns its stack and heap on crafted files

**What happens:** three ways, shown by crafted files under valgrind.
**These are memory-safety bugs in reading outside data**, worth
reporting to FLTK:
- `loop.gif`: a first code after a clear equal to the free code makes a
  cycle in the code table, and decoding overruns `OutCode` on the stack
  until it crashes;
- `zero.gif`: an image of width or height 0 gets `new uchar[0]`, and
  `lzw_decode` writes past it on the heap;
- `code.gif`: a code size byte over 8 is only warned about, and the
  decoder reads uninitialized memory.

In `Fl_Anim_GIF_Image`, a frame reaching outside the screen makes
`memcpy(dst, src, xmax-xstart)` take a negative size, and
`data(new_data, Height+2)` uses the image's height for the lines of the
screen.

**Cause:** `lzw_decode` starts with no old code, and when
`CurCode == FreeCode` uses it regardless: `Prefix[F] = F`, and
`while (i >= ColorMapSize)` follows that forever, writing
`OutCode[4097]`. `Prefix` and `Suffix` aren't initialized. No check for
a zero size or for a bad code size stops the load.

**Effect on pofltk:** `gif_ok` and `lzw_ok` in the shim walk the file's
blocks and codes before FLTK does, and refuse these. An animation's
frames must fit its screen; such a GIF still `Load`s, as a still. What
remains is a truncated GIF's pixels, which FLTK leaves uninitialized
and uses as indexes of 256-entry tables: valgrind reports the
uninitialized values, but no read or write out of bounds. pofltk can't
prevent that without decoding the image itself. `Fl_XPM_Image` also
reads past a line's end, inside its stack buffer, with its writes
bounded. And as in 87, what FLTK loads by itself remains exposed.

**Confirmed:** `test/images/loop.gif`, `zero.gif`, `code.gif` and
`beyond.gif` before and after the fix; a fuzz of 694 corrupted files
through every loader, under valgrind, with no invalid read or write
(2026-10-30). A fuzz is not a proof.

## 89. A link held down while the page changes reads freed memory

**What happens:** press the mouse on a link in an `Fl_Help_View`, change
the document with `value()` (from a timer or another widget), and
release: `Fl_Help_View::handle` follows the link pointer it saved at the
push, which has been freed.

**Cause:** `handle` keeps `linkp` from `FL_PUSH` to `FL_RELEASE`
(`find_link`), and `format()` frees `links_` without clearing it;
`follow_link` then reads it (`Fl_Help_View.cxx`, line 2860). Any
reformat does this, and a resize is a reformat too.

**Effect on pofltk:** the shim's view counts layout changes (`value`,
`load`, a resize). If any happened since the push, the release is no
longer a click (`Fl::event_is_click(0)`), and FLTK drops the link.

**Confirmed:** a scratch program under valgrind (invalid read); and
`TestHelp`, under valgrind, with the fix (2026-10-30).

## 90. A help view's link function can't refuse an image

**What happens:** `Fl_Help_View`'s link function returning NULL refuses
a link. Returning NULL for an image crashes the view.

**Cause:** `get_image` passes the result on, and `format()`
(`Fl_Help_View.cxx`, line 1869) and `free_data` use it unchecked.

**Effect on pofltk:** FLTK asks the same function about links and
images, and only the view's own state tells them apart. The shim sets
`in_image` around `get_image`, answers "" for a refused image (no such
file: FLTK's broken image), and remembers each answer, so `Link` is
asked once about each image. Setting the view's page there is a
programmer's error and halts (`Fl.OutOfOrder`), since FLTK is in the
middle of `format()`.

**Confirmed:** a scratch program (SIGSEGV); `TestHelp`, under valgrind,
with the fix (2026-10-30).

## 91. A file chooser deleted in its own callback is used afterwards

**What happens:** deleting an `Fl_File_Chooser` in its callback gives
invalid reads, when the callback came from pressing Enter in the file
name.

**Cause:** `fileNameCB` calls `window->hide()` after `do_callback`
(`Fl_File_Chooser2.cxx`, line 823), and other callers go on using
members.

**Effect on pofltk:** `Close` hides the chooser and marks it closed at
once; if the chooser's callback or any dispatch is running, the shim
deletes it from a timeout, after them (`close_later`).

**Confirmed:** a scratch program under valgrind; `TestFileChooser`'s
Close in the callback, and in a callback of its extra widget, under
valgrind (2026-10-30).

## 92. A file chooser's extra widget deleted first is read afterwards

**What happens:** delete the widget given to `add_extra`, then call
`add_extra` again: invalid read.

**Cause:** the chooser keeps `ext_group` and reads its `h()` to shrink
the window (`Fl_File_Chooser.cxx`, line 488), and has no way to hear it
go. The destructor only compares the pointer, so it is safe.

**Effect on pofltk:** the shim keeps the height, and when the extra
widget has been deleted clears the private `ext_group` (`Reach`) and
shrinks the window by the height kept plus 4. `SetExtra` returns NIL
for it.

**Confirmed:** a scratch program under valgrind; `TestFileChooser`
under valgrind (2026-10-30).

## 93. Smaller pitfalls of the chooser and the help classes

- `Fl_Help_Dialog`'s constructor leaves no current group
  (`Fl_File_Chooser`'s restores it): the shim restores it.
- `Fl_File_Chooser::filter()` returns the pattern in use, not what
  `filter(p)` was given. `count()` and `value()` of a chooser with no
  file chosen give what is in its field, its first directory, so 1 and
  a directory; `count()` is 0 only with the field empty.
- `Fl_File_Chooser::preview(e)` writes the user's preferences
  (`~/.fltk/fltk.org/filechooser.prefs`): a test puts it back.
- `Fl_File_Chooser::save_label` is the favorites window's Save button,
  and `hide()` releases a previewed image where the destructor doesn't.
- `Fl_Help_View::load` opens ftp, http, https, ipp, mailto and news
  addresses in the user's browser (`fl_open_uri`) before asking the
  link function. So `Load` of one does, and a test must not use one.
- `Fl_Help_View::format()` ends in `topline()`, which calls back, so
  every page laid out calls `Callback`. A `<title>` is read only inside
  `<head>`; a page with none is "Untitled", as is a view with no page,
  once laid out. `topline(int)` does nothing with no page. `find`
  ignores case, and returns the match's start or -1.
- `Fl_Help_View::copy` needs the display open, as `Fl::copy` does (49).

## 94. `fl_filename_relative` says "no change" of what it changed

**What happens:** `fl_filename_relative(to, n, "/a/b", "/a/b")` sets
`to` to `.` and returns 0, which its documentation says means no
change. Its text is all it looks at: `/a//b` against `/a/b` is `..//b`,
and `/a/./b` is `.././b`. A `to` too short is cut with no sign. `to` may
not be `from`.

**Cause:** `Fl_System_Driver::filename_relative`
(`src/filename_absolute.cxx`) returns 0 from its test for the same
directory, and sets `to[0]` before it reads the rest of `from`. "Well
formed" paths are a comment there, not checked.

**Effect on pofltk:** `FlDialogs.FilenameRelative` and
`FilenameRelativeTo` copy their arguments first, and say whether the
result differs from `from`, so TRUE for `.`. Their comments say `from`
must have no `.` or `..` in it.

**Confirmed:** a scratch program of 14 cases; `TestDialogs` (2026-10-30).

## 95. `Fl_Shared_Image`'s handlers: no way to remove one, and FLTK owns the answer

**What happens:** `Fl_Shared_Image::add_handler` takes a plain function
with no user data, and FLTK deletes the image it returns with the pool's
entry. `remove_handler` exists but is of no use to a list kept
elsewhere. FLTK asks handlers about every file but XBM and XPM, whether
it can read them or not, so the first handler to know a file wins, and
they see only its first 64 bytes.

**Cause:** `Fl_Shared_Image::reload` (`src/Fl_Shared_Image.cxx`).

**Effect on pofltk:** FLTK has one handler, `ask_handlers` in
`FlImages.cpp`, for good, which asks the Oberon list, and gives FLTK a
copy of the `Image` the handler returns, so that stays the program's.
pofltk's own `GetShared` and `Reload` don't go through FLTK's loading
(it would run FLTK's decoders on files the shim refuses), so `load_shared`
asks the same handlers after `load_file` fails, with the same header.
A handler is therefore not asked about a file FlImages reads itself,
unless FLTK's own loading is what wanted it.

**Confirmed:** `TestImageHandlers`, through both ways in (2026-10-30);
`FileChooser`'s PDF and PostScript previews, 0 pixels different from
FLTK's own program.

## 96. An `Fl_Terminal` made smaller leaves its cursor off the grid, and writes there

**What happens:** `display_rows()`, `display_columns()`, the margins, a
font or a resize can make the screen smaller, and the cursor stays
where it was. `display_rows(3)` with the cursor at row 13 left it at
row 24 of a 14-row grid; `display_columns(20)` left it at column 45;
`ESC[s`, a shrink and `ESC[u` restored row 9, column 39 on a grid of 3
by 15. The next character is written outside the row. A fuzz of random
setters and output gave invalid writes in `Utf8Char::text_utf8_`, through
`print_char`, or killed valgrind outright, depending on the seed.

**Cause:** the setters and `resize` change the ring and don't clamp
`cursor_`. Only `cursor_row(int)` and `cursor_col(int)` clamp, and
nothing touches the place in `EscapeSeq` an escape sequence saved.
`print_char` doesn't check.

**Effect on pofltk:** `Term::fit` in `FlTerminal.cpp` puts the cursor,
and the saved place, back on the screen after every setter and resize.
It reaches `Fl_Terminal::escseq`, which is private, by an explicit
instantiation, as `FlBrowsers.cpp` does for `Fl_Tree::_lastselect`.

**Confirmed:** eight seeds of one fuzz, and six of a wider one (1500
steps, with selection by mouse, margins, fonts and scrollbars), all 0
invalid under valgrind with `fit`, on Xvfb (2026-10-30); `TestShrink`.

## 97. `Fl_Terminal`'s saved cursor isn't restored from column 1

**What happens:** a position saved at column 1 isn't restored, by
`restore_cursor` or by `ESC[u`.

**Cause:** `EscapeSeq::restore_cursor` tests `col != 1`, a slip for -1
(`src/Fl_Terminal.cxx`).

**Effect on pofltk:** `Term::restore`, for `RestoreCursor`, reads the
saved place through the same function and sets the cursor itself.
`ESC[u` in a program's text can't be helped.

**Confirmed:** a scratch program; `TestCursor` (2026-10-30).

## 98. `Fl_Terminal::error_char` overruns a cell, or recurses without end

**What happens:** `error_char` keeps its pointer. Given more than 4
bytes, it overruns the cell it is written to: into the next cells,
inside the ring's block, which is why valgrind says nothing, and past
the block at the last cell. Given a control character, with
`show_unknown(true)`, an unknown byte is a stack overflow:
`error_char("\x01")` and an append of `\x02` died with SIGSEGV.

**Cause:** `handle_unknown_char(row, col)` calls `text_utf8(error_char_,
strlen(error_char_), ...)`, which `memcpy`s into `text_[4]` unchecked.
`handle_unknown_char()` calls `print_char`, which sends a control
character to `handle_ctrl`, which calls `handle_unknown_char`.

**Effect on pofltk:** the shim keeps a copy, and refuses anything but
one printable UTF-8 character of 1 to 4 bytes: `SetErrorChar` halts 78.

**Confirmed:** scratch programs (rc 139 for the recursion); `TestUtf8`,
`HaltTerminalErrorChar` (2026-10-30).

## 99. Smaller pitfalls of `Fl_Terminal`

- **`print_char(text)` with no length** takes it from the first byte,
  and reads past the end of a cut character (valgrind is silent:
  partial loads). The shim passes `strlen`.
- **`print_char`, `plot_char`, the cursor's moves and the clears don't
  redraw**: `display_modified` is private. The shim calls
  `append_ascii("")` after them, which obeys `redraw_style`.
- **`cursor_up` and the others with a count** make a count of 0 into 1.
  `Move` in `FlTerminal.Mod` does nothing below 1.
- **Sizes aren't checked**: `textsize(-5)` is a division by zero
  (SIGFPE), `display_columns(0)` is taken, `history_rows(-1)` gives a
  history of -1. `display_rows(0)` and below snap back. `FlTerminal`
  halts 78 on all of these, and on more cells than `MaxCells`, since
  a failed allocation would throw through Oberon.
- **`display_rows(n)` never sticks**: the height decides.
  `display_columns(n)` sticks if it is larger than the width allows.
- **`clear()`, `clear(color)` and `clear_screen_home()` push the screen
  into the history**, as `ESC[2J` does; `clear_screen(false)` doesn't.
  `clear(FL_RED)` leaves `color()`.
- **A cut UTF-8 character** waits for its rest through anything else
  written: `C3`, `x`, `A9` gives "x" then "é". A byte that starts a
  long form, as `FF` does, waits too, and shows nothing, whatever
  `show_unknown` says; only a stray continuation byte is unknown.
- **The constructor with a font** defers it to the first draw. The one
  with 8 arguments drops its history size; it isn't bound.

**Confirmed:** scratch programs on Xvfb, and `TestTerminal` (2026-10-30).

## 100. Text with no font set crashes on a PostScript, PDF or EPS surface

**What happens:** `fl_draw` of text on a PostScript, PDF or EPS surface
before any `fl_font` on it is a SIGSEGV in `pango_font_description`. An
SVG surface doesn't crash.

**Cause:** `Fl_Cairo_Graphics_Driver.H:180`: these surfaces have a
graphics driver of their own, with no Pango font description until
`font()` makes one, and drawing text uses it unchecked.

**Effect on pofltk:** a font set on the screen doesn't carry over, so
any program could reach this. The shim sets FLTK's normal font at each
begin of a surface (`set_font`, `FlPrint.cpp`).

**A related bug of pofltk's:** `FlDraw`'s `ensure_font` decided
whether a font was set by `font_descriptor()`, and the SVG driver never
has one, so every text call on an SVG surface put the font back to
Helvetica 14. It now also asks `fl_size()`: 0 or -1, by driver, with no
font. `examples/SaveAs.Mod` showed this; `TestPrint` checks the font in
the file.

**Confirmed:** scratch programs on Xvfb, and `TestPrint` (2026-10-31).

## 101. `Fl_PostScript_File_Device::end_job` uses its file after closing it

**What happens:** under Pango, on any Cairo error, `end_job` does
`fclose(ps->output); fputs("\n", ps->output);`, then closes it again
through the close command or `fclose`. That is a use after free and a
double close. With `begin_job(FILE *)`, FLTK's `fclose` and the
caller's abort the program (status 134).

**Cause:** `src/drivers/PostScript/Fl_PostScript.cxx:1956`. A Cairo error is sticky, and can
come from a write that fails (`/dev/full`) or from the drawing: an
`untranslate` with no `translate`, `scale(0)`, `fl_scale(0)`, a NaN
matrix, or a negative font size.

Not triggered by invalid UTF-8, huge coordinates, unbalanced clips,
font size 0, bad dashes, a negative line width, a huge origin,
translate, scale and rotate undone by `untranslate`, a negative scale,
or a rotation of 1e30.

**Effect on pofltk:** Cairo writes through a stream of the shim's, a
`Sink` (`fopencookie` on Linux, `funopen` elsewhere), which records a
failed write and lets a close be harmless. `FlPrint` halts on an
`Untranslate` too many, and on a scale of 0.

Not covered: drawing that breaks Cairo through `FlDraw` (`FlDraw.Scale`
by 0, NaN, a negative font size) still reaches the `fputs` on a freed
`FILE`. `FlDraw` isn't guarded, because it can't tell a surface's
drawing from a window's, where `examples/DoubleBuffer.Mod:32` scales by
`w DIV 2`.

`Fl_Printer` under Pango takes the same path (`popen`, `pclose`).

**Confirmed:** scratch programs under valgrind (2026-10-31).

## 102. A PDF surface's `end_job` reports an error only by an alert

**What happens:** on a Cairo error, `end_job` calls `fl_alert`, and
returns nothing. A program can't tell, and a program with no user to
answer the alert hangs in it.

**Cause:** `Fl_PDF_Pango_File_Surface::end_job`,
`src/drivers/PostScript/Fl_PostScript.cxx:1792`. An
`Fl_EPS_File_Surface` does the same in its destructor (line 2054),
unless `close()` was called, which returns the status.

**Effect on pofltk:** while `end_job` runs, the shim watches for the
alert with a timer, and closes it; `EndJob` returns FALSE and `Error`
gives the reason. `EPSFile.Finish` calls `close()`.

**Confirmed:** writing a large PDF to `/dev/full` hung without the watch
(2026-10-31). `TestPrint` checks it; `/dev/full` isn't on OpenBSD, so
the check is skipped there.

## 103. Smaller pitfalls of FLTK's printing

- **`perr_message` is allocated two ways**: `new char[]` by Pango's PDF
  and GTK's code, `strdup` without Pango. FLTK built without print
  support returns 2 with no message.
- **`Fl_PostScript_File_Device`'s `scale`, `rotate` and `origin` outside
  a page break Cairo**: `FlPrint` halts 77 there.
- **`scale(sx, 0)` means `sy = sx`**, not 0.
- **`begin_page` pushes the current surface, `end_page` pops it.**
- **The `MEDIA` format overruns `page_formats`**: `FlPrint` halts 78 on it.
- **`close_command`** stores a function pointer, and nothing else.
- **`Fl_Widget_Surface::draw` skips what isn't visible**, silently, and
  a window never shown isn't: `draw_decorated_window` draws nothing of
  one either. `print_window_part` needs a shown window, and runs
  `Fl::check`.
- **`Fl_Printer::begin_job`** returns 1 for cancel, 2 and above for
  errors. Cancelling GTK's dialog with Escape prints `Gtk-CRITICAL`
  assertions on `gtk_widget_hide` and `gtk_widget_destroy`; FLTK's own
  `test/device` does the same.
- **The PDF chooser** reads the printers' preferences; cancelling it
  writes no file.
- **An unended job** deleted is clean, and leaves an empty file. Zero
  pages are fine, and a second job on one object worked.

**Confirmed:** scratch programs on Xvfb, `TestPrint`, and the examples
(2026-10-31).

## 104. FLTK built with `--disable-print` hides that from programs

**What happens:** `FL_NO_PRINT_SUPPORT` is set in `config.h`, which isn't
installed, so a program compiles against the usual headers.
`Fl_Printer.cxx` then gives stubs: `begin_job` returns 1 or 2, and
`Fl_EPS_File_Surface`'s constructor succeeds with a null driver. The four
`Fl_PDF_File_Surface::format_dialog_*` strings don't exist, so a program
naming one doesn't link.

**Cause:** `src/Fl_Printer.cxx:21`, and `src/Fl_Device.cxx:169`, which
guards the strings. `fl_config.h` doesn't carry the setting.

**Effect on pofltk:** `FlPrint.cpp` refers to the strings weakly, and a
null address says this FLTK can't print. `FlPrint.Available` reports
that; PostScript, PDF and EPS then fail to open, with a reason, and
`BeginJob` gives `JobFailed`. SVG doesn't depend on it. The symbols are
named by their mangled names, as a class's static can't be declared weak
without defining it.

`Fl_Printer::dialog_title` is null in the stubs too, but
`SetPrinterText` sets it, so it can't be the test.

**Confirmed:** `make test-headless` on an FLTK configured with
`--disable-print` and without SVG, where the link failed before
(2026-10-31).

## 105. `Fl_Free` passes a comparison as its event, and its numbers aren't what it says

**What happens:** a `FL_CONTINUOUS_FREE` or `FL_ALL_FREE` widget's
handler gets event 0 from its timer, never `FL_STEP`. `FL_DRAW`,
`FL_STEP` and `FL_FREEMEM` are 100, 101 and 102, not the 0, 9 and 12 the
constructor's documentation gives. The destructor calls the handler
with `FL_FREEMEM`, from inside `~Fl_Free`. The key given is a `char`,
which cuts `Fl::event_key()` down, and the mouse button is given as
`4 - event_button()`.

**Cause:** `src/forms_free.cxx:28`, `f->handle(Fl::e_number == FL_STEP)`,
which is `handle(0)`, as `e_number` is never `FL_STEP`.
`FL/Fl_Free.H:68`, and the comment at `src/forms_free.cxx:57`.

**Effect on pofltk:** `FlForms.cpp` turns event 0 into `FL_STEP`, gives
`HandleFree` the whole key from `Fl::event_key()` and the button from
`Fl::event_button()`, and drops `FL_FREEMEM`, since the widget is half
gone by then. `FlForms` exports the right numbers, as `FreeDraw` and
`FreeStep`.

**Confirmed:** `TestForms`, under valgrind too (2026-10-31).

## 106. `Fl_FormsBitmap::set` and `Fl_FormsPixmap::set` leak, and keep what they're given

**What happens:** neither class has a destructor, so the image `set`
makes outlives the widget. `set` keeps the pointer to the bits, and
deletes whatever image the widget had, including one the program gave
with `bitmap(B)` and still owns.

**Cause:** `src/forms_bitmap.cxx:28`, `src/forms_pixmap.cxx:39`.

**Effect on pofltk:** `set` isn't bound. `FlForms.SetBitmap` and
`SetPixmap` take a `FlImages.Image`, which the widget's `Ref` holds in
its `content` slot until the widget dies, and the C++ part sets the
pointer alone. A shared image is refused, with `Fl.Unsupported`, as for
trees and tiled images (83, 84).

**Confirmed:** `TestForms` under valgrind, and `HaltFormsBitmap` and
`HaltFormsPixmap` (2026-10-31).

## 107. `Fl_Timer`'s direction is the opposite of its header

**What happens:** a value timer with direction 0 shows the time left,
and with any other direction the time gone. The header says 0 counts
up, and non-zero counts down.

**Cause:** `src/forms_timer.cxx:50`, `direction_ ? total-delay : delay`;
`FL/Fl_Timer.H:55`.

**Effect on pofltk:** `Timer.CountsUp` and `SetCountsUp` say what the
timer shows, with no direction number to get backwards.

Also: a hidden timer clears its visibility with its `FL_HIDDEN_TIMER`
type, a value timer aligns its label left, and a shown one that has run
out blinks until a mouse release. Its destructor removes its timeout, so
one deleted running is safe.

**Confirmed:** `TestForms` (2026-10-31).

## 108. Plugins: a name used twice, and an index out of range

**What happens:** two `Fl_Plugin`s of one class and name share a node
in the manager's group, and deleting the second removes a node the first
removal freed: valgrind shows a use after free, and the program can
crash. `Fl_Plugin_Manager::plugin(i)` of an index out of range makes a
new group. A name with a `/` makes nested groups. `loadAll`'s default
sort is `fl_numericsort`, which reads past names (63).

**Cause:** `src/Fl_Preferences.cxx:2070` (`addPlugin`), `:2087`
(`removePlugin`), `:2030` (`plugin`, through the `Fl_Preferences(parent,
index)` constructor), `:2114` (`loadAll`).

**Effect on pofltk:** `OpenPlugin` halts with `Fl.OpenedTwice` on a
name already open in its class, and with `Fl.IndexOutOfRange` on a name
with a `/`. `PluginAt` checks its index.
`LoadAll` sorts the directory itself. Each is a halt test
(`HaltPluginTwice`, `HaltPluginName`, `HaltPluginAt`).

A plugin in a library opened by `dlopen` is an object of that library:
for an Oberon plugin to be seen as such, the program and the library
must share one copy of the modules, which a program built with
`-shared-libraries`, or linked `-rdynamic`, does. A plain program has a
second copy, `Plugins()` counts it, and `PluginAt` gives NIL.

**Confirmed:** `TestPlugins`, the halt tests, and scratch programs
loading a poc library with `Load` (2026-10-31).

## 109. gl_start always crashes under Wayland

**What happens:** `gl_start()`, FLTK's way of drawing with GL in a plain
window's `draw()`, is a segmentation fault on every call under Wayland.

**Cause:** `src/gl_start.cxx:64` calls `set_gl_context` on
`Fl_Gl_Window_Driver::global()`, a driver with no window, whose `pWindow`
is NULL, and `Fl_Wayland_Gl_Window_Driver::set_gl_context` reads it. The
driver headers aren't installed, so a binding can't step around it.

**Effect on pofltk:** `FlGl.CanStart` is FALSE under Wayland, where
`FlGl.Start` halts with `Fl.Unsupported`. `TestGl` tests `Start` on X11
and skips it on Wayland. A `GlWindow` is the way to draw on both.

**Confirmed:** a scratch program on a headless sway, and `TestGl`, on both
back ends (2026-10-31).

## 110. Asking about GL with no display open

**What happens:** `Fl_Gl_Window::can_do` as a program's first call, with
no display open, is a segmentation fault.

**Cause:** `Fl_Gl_Window_Driver::global()->find` (`src/Fl_Gl_Window.cxx:66`)
uses the display's connection and doesn't open it, as a plain window's
`show()` does.

**Effect on pofltk:** `FlGl.cpp` and `FlGlut.cpp` call `fl_open_display()`
first, on each path to it, so `FlGl.CanDoMode` and `FlGlut.Get`'s
answers about the display are safe as first calls.

**Confirmed:** a scratch program, and `TestGl` (2026-10-31).

## 111. GL calls with no context, and the current window

**What happens:** `Fl_Gl_Window::make_current` on a window not shown
crashes on X11, where there is no window for the context. `gl_font` and
`gl_draw` with no GL context crash in the driver. `Fl_Window::current()`
stays set after that window is hidden, and dangles after it is deleted,
so `gl_start` then uses a freed window. `mode()` inside a draw replaces
the context the draw is using.

**Cause:** `src/Fl_Gl_Window.cxx:117` (`make_current`) checks nothing, as
`gl_start.cxx` (109) and `gl_draw.cxx` check nothing, and hiding or
deleting a window leaves `Fl_Window::current_`.

**Effect on pofltk:** `FlGl.cpp` checks that the current window is a
live, shown one (`is_shown`), and these halt with `Fl.OutOfOrder`:
`HaltGlMakeCurrent`, `HaltGlFont`, `HaltGlStart`, `HaltGlSetMode`.

**Confirmed:** scratch programs, and the halt tests (2026-10-31).

## 112. GLUT trusts what it is given

`glut_compatibility.cxx` and `FL/glut.H` are a thin layer, for C programs
that are right. pofltk's `FlGlut` covers each of these.

**What happens, and its effect on pofltk:**

- **Numbers**: `glutSetWindow`, `glutDestroyWindow`, `glutSetMenu` and the
  rest index `windows[]` and `menus[]` unchecked (`:263`, `:279`, `:283`,
  `:287`): `FlGlut` halts with `Fl.IndexOutOfRange`. There are 31 windows;
  the 32nd and later share number 32 (`:168`) and `FlGlut` halts with
  `Fl.Unsupported`. Menus likewise. So that it knows these, `FlGlut` keeps
  its own map of live windows and menus.
- **Strings**: titles, icon titles and menu labels are kept by pointer:
  `FlGlut` copies them.
- **Hiding or destroying a window in its display function** frees the
  `Fl_X` that `Fl::flush` is walking, a use after free on valgrind.
  `DestroyWindow` always waits for the next wait, and `HideWindow` does
  while a display function or a window's `Draw` is running. A window so
  deferred is still shown, so
  `glutFullScreen` on it under Wayland would wait for an expose that the
  hiding itself, run by that wait, prevents: it does nothing then. A window
  going can be drawn again before it has gone (seen on a headless sway):
  its display function isn't called, since it has no number left to use.
- **`GLUT_WINDOW_PARENT`** casts `parent()` to `Fl_Glut_Window`, which a
  plain `Fl_Window` around an `Fl_Glut_Window` isn't. `FlGlut` looks the
  parent up among its live windows.
- **A submenu's items are held by pointer** (`glutAddSubMenu`), and the
  array moves as the submenu grows or goes with it, so `FlGlut` halts with
  `Fl.OutOfOrder` on changing a menu in use as a submenu: fill it first.
- **An empty menu popped up crashes**, and **the array's terminator** has
  only its text set: a pop-up reads its `flags`, which valgrind reports.
  `FlGlut` halts on attaching an empty menu (`Fl.OutOfOrder`) and sets the
  terminator (`seal`).
- **`glutRemoveMenuItem`** reads past the array's end (`:382`): `FlGlut`
  checks the index.
- **`GLUT_WINDOW_RGBA` is `GL_RGBA`** in `glut.H`, so `glutGet` passes it
  on to `glGetIntegerv`, which needs a GL context; `FlGlut` sends such
  queries (`type >= 100`) through its own `gl_int`.
- **`glutExtensionSupported`** is declared `char *` in `glut.H` and
  defined `const char *`, so a C++ caller doesn't link: `FlGlut.cpp`
  declares it as defined.
- **Any event makes its window current** (`Fl_Glut_Window::handle` calls
  `make_current`, and `draw` sets `glut_window`), which GLUT documents for
  callbacks but is easily forgotten after a wait: `TestGlut` sets the
  window again after waiting.
- **`glutTimerFunc`** (`glut.H:302`, inline) casts a `void (*)(int)` to
  `Fl_Timeout_Handler`, which clang 19 and later reject under `-Wextra
  -Werror`, unless the header is a system one. So it builds on Fedora, in
  `/usr/include`, and not on the BSDs or with any FLTK elsewhere: first
  found by the BSD runs. `FlGlut.cpp` and `CGlutConstants.cpp` turn that
  one warning off around the include.
- **`glutSwapBuffers` in a display function does nothing** (`indraw`,
  `:65`), since `Fl_Gl_Window::flush` swaps afterwards.

**Confirmed:** `TestGlut`, the `HaltGlut` tests, valgrind, and `GlutTest`
against FLTK's `glut_test`, whose output is the same under Xvfb
(2026-10-31). `glut_test` with an `Fl::check()` after a `glutHideWindow`
shows an X error, `BadDrawable` on request 130 (MIT-SHM, Mesa's software
renderer's own), as `FlGlut` does: neither binding's.

## 113. GL windows: closed groups, and one display mode under Wayland

**What happens:** a widget opened after an `Fl_Gl_Window` isn't its child,
although its window was the last one opened. A window's mode reads back
with `FL_DOUBLE` under Wayland whatever was asked for.

**Cause:** `Fl_Gl_Window::init` calls `end()` (`src/Fl_Gl_Window.cxx:343`).
`src/drivers/Wayland/Fl_Wayland_Gl_Window_Driver.cxx:301` (`mode_`) and
`:113` (`find`) add `FL_DOUBLE`, since Wayland's EGL has no single-buffer
drawing (the note at `:37`).

**Effect on pofltk:** a program adding widgets to a `GlWindow` calls `Begin`
and `End` around them, and its `Draw` calls `w.Draw^` to show them
(`Cube`). `FlGl`'s `SetMode` comment says so, and `TestGl` asks for
`Double`.

FLTK installs `FL/gl.h` and the rest with GL turned off, and `fltk-config`
names `libfltk_gl` then too, so only the library's being there says FLTK
has GL (`HAVE_GL` in the makefile).

**Confirmed:** `Fl_Gl_Window.cxx`, `Cube`, and a build of FLTK with GL
turned off (2026-10-31).

## 114. `Fl_Cairo_Window`: a class of some FLTKs, and FLTK's own context under Wayland

**What happens:** `Fl_Cairo_Window` exists only in an FLTK built with
`FLTK_OPTION_CAIRO_WINDOW`, and pkgsrc's isn't. In one that has it, under
Wayland, one `cairo_restore` too many in the draw callback stops the
window for good: the next draw's context is already in error
(`CAIRO_STATUS_INVALID_RESTORE`), and FLTK's own drawing is lost with
the program's. A box's color changed after that doesn't show. On X11 the
same call only ends that draw, whose context is the window's alone.

**Cause:** `Fl::cairo_make_current` (`src/Fl_Cairo.cxx:100`) gives
under Wayland `fl_wl_gc()`, the context FLTK itself draws the window with,
which has one `cairo_save` of FLTK's on its stack from the start
(`src/drivers/Wayland/Fl_Wayland_Graphics_Driver.cxx:219`). The extra
restore takes that one, FLTK's own next `cairo_restore` then fails, and a
cairo context stays in error. X11 makes a context from the window.

Also, `Fl_Graphics_Driver::has_feature(NATIVE)` is 0 on a Cairo driver,
which doesn't override it as the Xlib and GDI ones do, so it can't say
whether a draw is for the display.

**Effect on pofltk:** `FlCairo` doesn't use `Fl_Cairo_Window`. Its window
is a `Fl_Double_Window` of the shim's that makes a context of its own for
each draw, by the back end in use: from `fl_wl_gc()`'s surface and
matrix under Wayland, from `fl_window` with `cairo_xlib_surface_create` on
X11. So it needs no option of FLTK's, one way serves every FLTK, and an
error stays in its context. It draws only when the current surface is
the display (`Fl_Surface_Device::surface()`), since `fl_window` and
`fl_wl_gc()` aren't another surface's; there the window shows its
widgets alone.

**Confirmed:** a program with `Fl_Cairo_Window` under Xvfb and on a headless
sway, reading pixels back: under Wayland the context pointer was the same
at each draw, its status 2 from the second draw on, and a box's new
color didn't appear; on X11 the pointer differed and the color did
(2026-10-31). `TestCairo` checks `FlCairo`'s window for the same.

## 115. Composed characters and `fl_utf8strlen` at the ends of the text

**What happens:** `fl_utf8_previous_composed_char` at the start of the
text returns a pointer before it, and on a variation selector at the
start `fl_utf8back` reads before the text. `fl_utf8_next_composed_char`
goes past the end: a lone lead byte `F0`, one byte long, gave 4, and "a"
with a zero-width joiner at the end, 4 bytes, gave 5.
`fl_utf8strlen(text, len)` turns characters into bytes, not bytes into
characters, and steps past the NUL on a lead byte cut short.

**Cause:** `from += fl_utf8len(*from)`, in `fl_utf8.cxx`, trusts the
lead byte, and `fl_utf8len` can be -1. The backward walk doesn't test
for the start (`fl_utf8back`, line 852, is where valgrind stops).

**Effect on pofltk:** `FlUtf8` passes a copy with zeros on both sides
(`Text`), and keeps what comes back within the text.

**Confirmed:** programs under valgrind, 2026-10-31; `TestUtf8`.

## 116. `fl_utf_tolower` and `fl_utf_toupper` have no size and no terminator

**What happens:** each writes to a buffer of no stated size and doesn't
end it with `0X`. A bad byte isn't U+FFFD, as this entry said until
2026-11-06 (FLTKAda found it): FLTK's default build (`ERRORS_TO_CP1252`)
decodes a byte from 80 to 9F as CP1252's character, as 80X is the euro
sign, E2 82 AC, and any other bad byte as Latin-1's, 2 bytes, except
the five CP1252 leaves out (81, 8D, 8F, 90, 9D), which stay themselves,
2 bytes. So a bad byte still takes at most 3.

**Cause:** the destination has no length parameter, and the result is
only a count.

**Effect on pofltk:** `FlUtf8` gives each a buffer of its own, larger
than the `3 * n` a bad text needs, and copies out what fits.

**Confirmed:** by a program, and `TestUtf8`, 2026-10-31; the bytes of
bad text by a program (80 to U+20AC, 9F to U+0178, 81 to U+0081, E9 to
U+00E9), and `TestUtf8`'s checks of `ToUpper` and `ToLower`, 2026-11-06.

## 117. `fl_utf8toa`'s count past a short buffer

**What happens:** the result is meant to be the length needed, but
differs with the buffer: `"xx\xC3a"` counts 4 in a buffer big enough, and
3 in one of 2 bytes. So does `"xx\xC0\xC0"`.

**Cause:** past the end of the buffer, the rest is measured with
`fl_utf8len1`, which takes a bad lead byte's word for its length; filling
the buffer uses `fl_utf8decode`, which takes one byte of it.

**Effect on pofltk:** the shim always gives it a buffer as long as the
text, which can't be too short, and copies out what fits.

**Confirmed:** by a program, 2026-10-31.

## 118. `fl_utf8to_mb` and `fl_utf8from_mb`, buffers and locales

**What happens:** in a UTF-8 locale, with `srclen >= dstlen`, both
return the length and write nothing, not even a `0X`. `fl_utf8from_mb`
in Latin-1 returns one too many for 1024 bytes or more.
`fl_utf8locale` reads the environment once and caches it.

`fl_utf8_to_locale` and `fl_locale_to_utf8` are declared in no header
for this system: they exist only in the WinAPI driver.

**Cause:** the UTF-8 case is a plain copy that only tests the size.

**Effect on pofltk:** `FlUtf8` asks each for the size first and gives it
a buffer of that, measures `fl_utf8from_mb`'s result itself, and leaves
the two Windows functions out.

**Confirmed:** by a program in each locale, 2026-10-31.

## 119. `fl_filename_absolute`

**What happens:** it works in a temporary as long as `tolen`, so a short
buffer cuts the *base* directory, and it then reads before the temporary
as it removes `..`. An empty base does too (from the source). Only a
leading `.` or `..` is removed. It returns 0 for a name already absolute
or starting with `|`.

**Cause:** `Fl_System_Driver::filename_absolute`, in
`Fl_System_Driver.cxx`.

**Effect on pofltk:** the shim gives it a buffer of its own, big enough,
and `/` for an empty base.

**Confirmed:** under valgrind, 2026-10-31; `TestDialogs`.

## 120. `fl_filename_expand`

**What happens:** it aborts (status 134) when a variable's value doesn't
fit, and loops for ever with `SELF='$SELF'` in the environment. An empty
value reads `value[-1]` (from the source).

**Cause:** the driver's `filename_expand` copies in place and rescans
what it has copied.

**Effect on pofltk:** `FlDialogs.cpp` has its own `expand`.

**Confirmed:** by a program, 2026-10-31; `TestDialogs`, with `Probe.SetEnv`.

## 121. `fl_filename_isdir`

**What happens:** a name of 4096 bytes or more ending in `/` overruns a
stack buffer.

**Cause:** `fn[FL_PATH_MAX]` in `filename_isdir`.

**Effect on pofltk:** the shim calls `stat` itself.

**Confirmed:** by a program, 2026-10-31.

## 122. `fl_filename_match`

**What happens:** a pattern with an open `[` or `{` reads past its NUL.

**Cause:** the matcher's loops for a set test for the closing character,
not for the end.

**Effect on pofltk:** the shim matches copies with 16 zeros after them.

**Confirmed:** under valgrind, 2026-10-31; `TestDialogs`.

## 123. Symbols: names outside ASCII, and a table that fills

**What happens:** a symbol name with a byte above 7F gives a negative
hash index, on a system where `char` is signed: x86, and not arm64.
That is reachable from a label like `"@é"`. The table is full when
`symbnumb > MAXSYMBOL / 2`, 105 symbols, of which FLTK's own are about 41.
`fl_add_symbol` keeps the name, takes no user data, and an empty name
replaces the default symbol.

**Cause:** `find` in `fl_symbols.cxx` hashes `char`s without a cast.

**Effect on pofltk:** `FlDraw.AddSymbol` copies the name, checks it, and
says whether it was added. Labels are the program's to keep ASCII after
`@`.

**Confirmed:** under valgrind, 2026-10-31; `TestDrawMore`.

## 124. Drawing that needs a current window

**What happens:** with no current window, `fl_overlay_rect`, `fl_scroll`
and `fl_antialias()` crash.

**Cause:** each goes to the window's or the driver's state unchecked.

**Effect on pofltk:** `FlDraw` halts (`Fl.OutOfOrder`): `HaltOverlay`,
`HaltScroll`, `HaltAntialias`.

**Confirmed:** by a program, 2026-10-31.

## 125. `fl_expand_text`

**What happens:** with `maxbuf` 0, FLTK allocates a buffer the caller
can't get, since `buf` is by value. With a size, the text stops at
`buf + maxbuf - 4`. With `draw_symbols`, it stops at `@x` without moving
on, so a caller's loop never ends.

**Cause:** `fl_expand_text` in `fl_draw.cxx`.

**Effect on pofltk:** the shim always gives a buffer big enough, and
`FlDraw`'s result says where it stopped; a program looping on lines must
allow for no progress there.

**Confirmed:** by a program, 2026-10-31; `TestDrawMore`.

## 126. `fl_local_to_mac_roman` writes to NULL

**What happens:** `fl_local_to_mac_roman("abc", 3)` as the first call
writes to NULL; only a first call with `n = 0` allocates.
`fl_mac_roman_to_local` has the same test.

**Cause:** `if (n <= n_buf)` is inverted, so the buffer grows only when
it needn't.

**Effect on pofltk:** the shim calls each with `n = 0` first, then a byte
at a time, since the one to Mac Roman writes only its first byte.

**Confirmed:** by a program, 2026-10-31; `TestDrawMore`.

## 127. Reading a window back, partly or wholly outside it

**What happens:** X11's `fl_capture_window` writes out of bounds for a
width of 0 or below, or a rectangle partly off the window. Wayland's
`read_win_rectangle` reads past the draw buffer, from `fl_capture_window`
and `fl_read_image`.

**Cause:** neither clips to the window.

**Effect on pofltk:** both shims clip first.

**Confirmed:** under valgrind, on X11 and sway, 2026-10-31; `TestImages`,
`TestDrawMore`.

## 128. `fl_restore_clip` on Cairo

**What happens:** on Cairo it drops a pushed clip, so what follows is
drawn outside it.

**Cause:** `Fl_Cairo_Graphics_Driver::push_clip` keeps its clip in
`clip_` and cairo's saved state, not in `rstack`, and `restore_clip` calls
`cairo_reset_clip` and applies only `rstack`.

**Effect on pofltk:** `FlDraw` leaves `fl_restore_clip` out, with
`fl_clip_region`: `PushClip` and `PopClip` are what programs need.

**Confirmed:** by a program, 2026-10-31.

## 129. `Fl::grab` and `Fl::selection_owner` of a deleted widget

**What happens:** `Fl::grab_` isn't cleared when the grabbed window is
deleted, and the next event reads freed memory in `send_event`
(`Fl.cxx`, 1267), on both back ends. `Fl::selection_owner_` isn't
cleared either. On X11, `Fl::grab(win)` with no window shown crashes in
`XGrabPointer`.

**Cause:** `~Fl_Widget` calls `fl_throw_focus`, which clears `pushed`,
`belowmouse`, `focus` and the selection's requestor, not these two.

**Effect on pofltk:** `ofl::W<B>`'s destructor clears both, and
`Fl.SetGrab` halts if the window isn't shown (`HaltGrabHidden`).

**Confirmed:** under valgrind, on X11 and sway, 2026-10-31; `TestStatics`.

## 130. Fonts: the table has no bounds

**What happens:**

- `Fl::get_font(5000)` returns garbage, and `get_font_name(20)` crashes,
  past the table;
- on Cairo, `get_font_name` of a gap crashes;
- a name of 128 bytes or more overruns `fontname[128]`, and
  `fontname[127]` holds the type, so 126 is the limit;
- `Fl::set_font(n, name)` keeps the pointer; `set_font(to, from)` shares
  it;
- `Fl::set_fonts` is cached on Cairo, and overwrites the table from
  `FL_FREE_FONT` on;
- `Fl::get_font_sizes` on Cairo gives one entry, 0;
- a widget's label font past the table crashes when drawn (a segmentation
  fault in `Fl_Cairo_Graphics_Driver::font`); a gap draws.

**Cause:** `fl_fonts` has a private `table_size`, and nothing tests a
number against it. `Fl_Cairo_Graphics_Driver.cxx`, 1176, does
`strcpy(f->fontname, f->name)` before its test for NULL;
`drivers/Xlib/Fl_Font.H`, 60, declares the array.

**Effect on pofltk:** `Fl` keeps `font_end` itself and halts on a number
past it (`HaltFontNumber`, `HaltFontFrom`), or past `MaxFont`
(`HaltFontGap`). The shim keeps each name (`font_names`) and cuts it to
126 bytes at a character's boundary; replacing a name is safe, as
`Fl::set_font` sets the pointer even if the text is equal. A widget's
font isn't checked, in every setter, against the table: a program
keeps to `Fl.FontEnd()`.

**Confirmed:** by programs, 2026-10-31; `TestStatics`.

## 131. Statics that crash with no display open

**What happens:** `Fl::ready()` and `Fl::selection` crash on X11 (in
`XQLength`, `XSetSelectionOwner`); `Fl::disable_im` and `enable_im`
crash under Wayland (`Fl_Wayland_Screen_Driver.cxx`, 103);
`Fl::set_box_color` with nothing drawn crashes on both (`fl_color` with
no driver, `fl_draw.H`, 51).

**Cause:** none opens the display, as `fl_open_display` would.

**Effect on pofltk:** each shim opens it first. `Fl.SetBoxColor` as the
first thing a program does works on X11 and Wayland.

**Confirmed:** by programs on both back ends, 2026-10-31.

## 132. `FL_SELECTIONCLEAR` is never sent

**What happens:** a widget set with `Fl::selection_owner` hears nothing
when another takes the selection.

**Cause:** nothing in FLTK 1.4.5 sends it: its one mention is a comment
(`Fl.cxx`, 1630), and `Fl::selection_owner(Fl_Widget *)` only sets the
static.

**Effect on pofltk:** none, but `Fl.EvSelectionClear` is not to be relied
on, and no test waits for it.

**Confirmed:** from the source, and `TestStatics` looking at
`SelectionOwner`, 2026-10-31.

## 133. `fl_draw_image` inside a line callback, on Xlib

**What happens:** an image drawn from the callback of `fl_draw_image(cb,
...)` spoils the outer one, and if it is larger the outer one writes to
freed memory.

**Cause:** `innards` in `Fl_Xlib_Graphics_Driver_image.cxx` keeps its
`XImage` `xi` and its `buffer` in statics. The inner call sets `xi`'s
size, and a larger one does `delete[] buffer` while the outer loop's `to`
points into it. FLTK's documentation doesn't mention it.

**Effect on pofltk:** `DrawImage`, `DrawImageMono`, `DrawImageLines` and
`DrawImageMonoLines` halt with `Fl.OutOfOrder` in a `Line`, on every back
end, so that a program tried on Cairo doesn't go wrong on Xlib
(`HaltImageInLine`). The other ways into it, such as `FlImages`'
drawing, aren't checked, and `Line`'s comment forbids them.

**Confirmed:** the outer image was wrong on NetBSD's FLTK and on one
built for plain X11 with neither Cairo nor Pango, not on Cairo's, and
valgrind shows the invalid write there, 2026-10-31.

## 134. `gl_draw` of text with no width

**What happens:** `gl_draw` of text that measures 0 wide crashes: a
segmentation fault on X11, a division by zero (`SIGFPE`) under Wayland.
That is `0X`, U+200B, and in most fonts a line feed, a carriage return
and a soft hyphen, as a string or through `glutBitmapCharacter`, and a
line of such text in a box with `gl_draw(s, x, y, w, h, align)`. A
combining mark, 7 wide, and `01X`, 15 wide, are fine, and so is a box
with a line feed alone. On plain Xlib, with neither Cairo nor Pango, `0X`
has a width, and draws.

**Cause:** `gl_texture_fifo::compute_texture` in `gl_draw.cxx` takes the
texture's width as `ceil(fl_width(...))`, which is 0, and
`alpha_mask_for_string` then makes an `Fl_Image_Surface(0, h)`, whose
`image()` crashes.

**Effect on pofltk:** `FlGl.cpp`'s `draw_some` draws text only if
`gl_width` gives it a width, and `draw_line` does that for each line of
`DrawTextIn`, in place of `gl_draw`'s own `gl_draw_invert`. `FlGlut.cpp`
asks the same before `glutBitmapCharacter` and `glutBitmapString`
(`drawable`). So `FlGl.DrawText`, `DrawTextAt` and `DrawTextIn`, which
all had this crash, are covered too (`TestGlut`).

**Confirmed:** by a C++ program on Xvfb and sway, and by `TestGlut` with
the checks removed, which segfaults on Xvfb, 2026-10-31.

## 135. `glutBitmapCharacter` moves by its texture, and takes a byte

**What happens:** each `glutBitmapCharacter` moves the raster position
by the width of the texture `gl_draw` made, a multiple of 4, not by the
character's. Two `A`s 17 wide moved it from 50 to 90, where the string
`"AA"` moved it to 86, so characters drawn one at a time sit further
apart than `glutBitmapWidth` says. It also takes its number as a raw
byte, cut from the `int`, so 321 and -191 draw `A`, and `E9X` is one
byte of bad UTF-8, where `glutBitmapWidth` takes the same number as a
Unicode character (`gl_width(uchar)`) and gives 13.

**Cause:** `gl_draw.cxx`: `gl_texture_fifo::display_texture` adds the
texture's width to the raster position, and `glutBitmapCharacter` in
`glut_font.cxx` passes `gl_draw` a one-byte string.

**Effect on pofltk:** `BitmapCharacter` takes a `CHAR`, so nothing is
cut, and its comment sends text with spacing that matters to
`BitmapString`. Since 2026-11-06 (FLTKAda's F29) the shim encodes the
character in UTF-8 before drawing it, so `BitmapCharacter(c)` draws the
character `BitmapWidth(c)` measures: before, 80X to 9FX were drawn as
CP1252's, and other bytes past 7FX as Latin-1's (116).

**Confirmed:** by a C++ program that read `GL_CURRENT_RASTER_POSITION`,
and `TestGlut`, on Xvfb and sway, 2026-10-31. `TestGlut` compares
`BitmapCharacter(80X)` and `(0E9X)` with `BitmapString` of their UTF-8,
which the old shim fails for 80X, 2026-11-06.

## 136. `fl_line_style`'s dash patterns

**What happens:** a pattern of 256 or more lengths overruns: 300 aborts
with `*** strcpy_chk: buffer overflow detected ***` where the C library
is fortified, and elsewhere writes past the driver's array. On Cairo a
negative length, or 200 where `char` is signed, draws no line at all,
with no error. The lengths are pixels, not multiples of the width, as
the `FL_DASH` styles' are. FLTK's OpenGL drawing ignores a pattern.

**Cause:** `Fl_Cairo_Graphics_Driver::line_style` and
`Fl_PostScript_Graphics_Driver::line_style` `strcpy` the pattern into
`linedash_[256]`, unchecked. The pattern is a `char *`, ended by 0, of
signed lengths on x86. Xlib's `XSetDashes` copies, and SVG `fl_strdup`s,
with no limit. `Fl_OpenGL_Graphics_Driver_line_style.cxx` says it "does
not support custom patterns". A pattern of one value acts as that value
twice.

**Effect on pofltk:** `FlDraw.LineStyleDashes` takes an `ARRAY OF
INTEGER`, ended by 0 or by the array's end, and halts with
`Fl.IndexOutOfRange` on a length outside 1 to 127 or on more than
`MaxDashes`, 255, of them (`HaltDashValue`, `HaltDashLong`). No lengths
is a plain `LineStyle`. Its comment gives the pixels and OpenGL.

**Confirmed:** by a C++ program on Xvfb and sway, under valgrind, and
`TestDrawMore` and `TestPrint`, which reads SVG's `stroke-dasharray`,
2026-11-02. An FLTK with neither Cairo nor Pango draws the same rows.

## 137. `Fl_Image_Surface::mask`

**What happens:** a mask of depth 1 is read past its end, and a mask
that isn't depth 3 is against FLTK's documentation, though depth 4 works
on Cairo. A second `mask` with no `image()` between loses the first's
state: valgrind finds 872 bytes definitely lost on X11, and a cairo
surface on Wayland. FLTK's documentation forbids a `mask` while the
surface is current, which runs, unchecked.

**Cause:** `calc_cairo_mask` in `Fl_Cairo_Graphics_Driver.cxx` and
`Fl_Image_Surface_Driver::RGB3_to_RGB1` read 3 bytes a pixel whatever
the depth. `mask()` in each driver makes a new `shape_data_` without
looking at the one there, and only `image()` or the destructor frees
it, the latter just the current one. On Xlib without Cairo `image()`
mixes the two through `copy_with_mask`, by the mean of a mask pixel's
red, green and blue. FLTK keeps no pointer to the mask; a mask of
another size is scaled, into a copy.

**Effect on pofltk:** `Surface.Mask` halts with `Fl.Unsupported` on a
mask not of 3 bytes a pixel (`HaltMaskDepth`), and with `Fl.OutOfOrder`
on a surface begun (`HaltMaskBegun`) or masked with no `GetImage` since
(`HaltMaskTwice`), the surface remembering which. `Close` with no
`GetImage` is safe. On Cairo the edge is soft by a pixel or so.

**Confirmed:** by a C++ program on Xvfb and sway, under valgrind,
`TestImages`, and `Device` against FLTK's own `device`, 2026-11-02, and
on an FLTK with neither Cairo nor Pango, where `TestImages` under
valgrind has no errors.

## 138. `Fl_Copy_Surface` has no way to abandon a copy

**What happens:** deleting the surface writes the clipboard, whatever
was drawn, or nothing. There is no way to leave the clipboard as it was
once a surface is made.

**Cause:** the destructors of `Fl_Xlib_Copy_Surface_Driver` and
`Fl_Wayland_Copy_Surface_Driver` do the copy; `Fl_Copy_Surface` has no
other method to send it, or to cancel it. On X11 the copy needs the
display open, as `Fl::copy` does (49).

**Effect on pofltk:** `FlImages.CopySurface`'s `Close` is when the copy
happens, its comment says so, and a surface lost and finalized writes
the clipboard too. `OpenCopySurface` opens the display first.

**Confirmed:** by a C++ program, and `TestClipboard`, which pastes the
pixels back, on Xvfb and sway, 2026-11-02.

## 139. `Fl_Text_Buffer::search_backward` from past the end never returns

**What happens:** `search_backward(pos, s, &found, 0)`, not matching
case, with `pos` past `length()` loops for ever: `SearchBackward(20,
"a", FALSE, f)` on "abc" hangs. Found by FLTKAda (its F6), and
confirmed in pofltk 2026-11-06.

**Cause:** `Fl_Text_Buffer::search_backward` (`src/Fl_Text_Buffer.cxx`)
loops `while (startPos >= 0)`, stepping with `prev_char(startPos)`,
which calls `prev_char_clipped`; that returns a position past the end
unchanged, so `startPos` never falls. The case-matching path has the
same loop.

**Effect on pofltk:** `ofl_buffer_search` (`src/FlText.cpp`) clamps the
start to `length()` before calling FLTK. Its own search, for matching
case (36), clamped it already.

**Confirmed:** by a scratch program, which hung, and `TestText` ("not
matching case, from past the end"), which hangs without the clamp, on
Xvfb, 2026-11-06.

## 140. `Fl_Terminal::cursor_tab_right` and `cursor_tab_left` ignore the count

**What happens:** each moves to the next tab stop whatever its count:
`cursor_tab_right(2)` from column 0 goes to 8, not 16, and
`cursor_tab_left(2)` from 24 to 16, not 8. Found by FLTKAda (its F24),
confirmed in pofltk 2026-11-06.

**Cause:** `src/Fl_Terminal.cxx`, `cursor_tab_right` and
`cursor_tab_left`: inside `while (count-- > 0)`, the inner loop over
columns `return`s at the first tab stop it finds, ending the outer loop
too.

**Effect on pofltk:** `FlTerminal.cpp` calls each with a count of 1, as
many times as the count, and stops when the column doesn't change (at
either end of the line).

**Confirmed:** `TestTerminal` ("two tab stops", "and two back", and a
count of 10000 each way), which fails without the loop, 2026-11-06.

## 141. `Fl_Text_Buffer::insertfile` stops at a Latin-1 or CP1252 byte near the end of the file

**What happens:** `loadfile`, `insertfile` and `appendfile` of a file
that ends with a byte that isn't UTF-8, such as `caf\xE9\n`, cut the
text before it, and don't set `input_file_was_transcoded`: the buffer
holds "caf", with no warning. The same byte earlier in the file is
transcoded, as documented. Found by FLTKAda (its F26), confirmed in
pofltk 2026-11-06.

**Cause:** `utf8_input_filter` (`src/Fl_Text_Buffer.cxx`) takes the
sequence's length from its lead byte (`fl_utf8len1`, 2 for `E9`). When
that runs past the bytes read, it reads more, and if there are still
too few, `break`s and returns what it has, dropping the rest of the
file: the bad byte is never decoded as CP1252 or Latin-1.

**Effect on pofltk:** `ofl_buffer_file` (`src/FlText.cpp`) loads,
inserts and appends through its own `insert_file`, which reads the file
whole and decodes it as FLTK's filter does (UTF-8, or a byte from 80 to
9F as CP1252 and any other bad byte as Latin-1, as `fl_utf8decode`
does), to the end; it sets `input_file_was_transcoded` and calls
`transcoding_warning_action` as FLTK does.

**Confirmed:** by a scratch program, and `TestText`: `caf\xE9\n` loads
as 6 bytes with C3 A9 and FLTK's warning, and `caf\x80` as the euro
sign; FLTK's own `loadfile` gives 3 bytes, 2026-11-06.

## 142. `Fl_Terminal`'s `PER_WRITE` redraws only the first write

**What happens:** with `redraw_style(PER_WRITE)`, the first write after
the style is set calls `redraw()`, and no later one does, however often
the terminal is drawn. And a write waiting for `RATE_LIMITED`'s timer
when the style changes is never drawn. Found by FLTKAda (its F23),
which found `modified()` to be `append_ascii("")`; confirmed in pofltk
2026-11-06.

**Cause:** `Fl_Terminal::display_modified` (`src/Fl_Terminal.cxx`)
redraws under `PER_WRITE` only if `redraw_modified_` is false, and sets
it. Only `RATE_LIMITED`'s timer (`redraw_timer_cb2`) and
`display_modified_clear` clear it, and nothing in FLTK calls
`display_modified_clear`. `redraw_style()` removes the timer and leaves
the flag set.

**Effect on pofltk:** `Term`'s `draw()` (`src/FlTerminal.cpp`) clears
the flag under `PER_WRITE`, reached through an explicit instantiation
(`Reach`), and `SetRedrawStyle` clears it too, and redraws if it was
set.

**Confirmed:** `TestTerminal`'s `TestRedraw`, whose five checks of the
damage after a write fail without the shim's clearing, 2026-11-06.

## 143. `Fl_Grid::layout(rows, cols)` keeps spans past the new size

**What happens:** a grid made smaller by `layout(rows, cols)` keeps
each cell's spans, so the next `layout()` reads rows and columns that
are gone: a 3 by 3 grid with a 3 by 3 span, laid out 1 by 1, then laid
out, reads freed memory under valgrind (`Fl_Grid.cxx:471` to `477`),
and a grid made larger again shows the old span. Found by FLTKAda (its
F5), confirmed in pofltk 2026-11-06.

**Cause:** `Fl_Grid::layout(int, int)` (`src/Fl_Grid.cxx`) deletes the
cells of rows removed and reallocates the column and row arrays, but
leaves `rowspan_` and `colspan_` of the cells kept; `layout()` adds up
the widths and heights of every column and row a span covers.

**Effect on pofltk:** `ofl_grid_set_layout` (`src/FlLayout.cpp`) cuts
each child's spans to the new size first, and a cell left outside it
(which FLTK's layout skips) spans one, so a larger grid shows it in its
cell alone. `Grid.PlaceSpan` checks the span when it is placed (21).
FLTKAda's F27, cell setters that don't ask for a layout, doesn't apply:
pofltk binds no `Fl_Grid::Cell` setter, and places through `widget()`.

**Confirmed:** `TestLayout` ("a span is cut to a grid made smaller",
"and stays cut when the grid grows again"): invalid reads, and the
second check failing, without the cutting, 2026-11-06.

## 144. The Print dialog's panel keeps its texts

**What happens:** `Fl_Printer`'s texts (`Fl_Printer::dialog_title` and
the rest) are pointers that FLTK's print panel takes as its widgets'
labels when it is built, once, and keeps. A text changed after the
first dialog is never shown, and the old one must stay valid. Found by
FLTKAda (its FLTKAda-BUGS 36), confirmed in pofltk 2026-11-06.

**Cause:** `Fl_Posix_Printer_Driver::begin_job`
(`src/drivers/Posix/Fl_Posix_Printer_Driver.cxx`) calls
`make_print_panel()` only `if (!print_panel)`, and `print_panel.cxx`
sets labels from the static pointers (`:249`, `dialog_title`), without
copying.

**Effect on pofltk:** `ofl_print_text` (`src/FlPrint.cpp`) kept one
`std::string` per text and reassigned it, overwriting or freeing the
buffer the panel showed. It now keeps every text it is given, in a `std::deque`, for the
program's life, and the same text again adds nothing.
`FlPrint.SetPrinterText`'s comment says a text set after the first
dialog isn't shown.

**Confirmed:** `TestPrint` ("the panel keeps its texts"), which sets a
longer title after the first dialog, and fails with the old shim: a
short text sits inside its `std::string`, so the panel's label was
overwritten in place, not freed, and valgrind saw nothing. Passes with
the new, on Xvfb, 2026-11-06.

## 145. GLUT's display and overlay procedures are called unchecked

**What happens:** `glutDisplayFunc(NULL)` or `glutOverlayDisplayFunc(NULL)`
is taken, and the window's next draw, or overlay draw, calls through
NULL and crashes. Real GLUT takes a NULL overlay display procedure as
none. Found 2026-11-06, checking FLTKAda-BUGS 91 (below).

**Cause:** `Fl_Glut_Window::draw` and `draw_overlay`
(`src/glut_compatibility.cxx:53`, `:69`) call `display()` and
`overlaydisplay()` without a test; `FL/glut.H` stores what it is given.
Once a window has an overlay (`make_overlay` sets `overlay` to the window
itself, and nothing clears it, not even `hide()`), every flush calls
`draw_overlay` (`Fl_Gl_Window::flush`).

**Effect on pofltk:** `FlGlut.DisplayFunc(NIL)` and
`OverlayDisplayFunc(NIL)` passed NULL. The shim now always gives FLTK
`run_display` and `run_overlay`, and `run` does nothing for a window whose
procedure is NIL.

FLTKAda-BUGS 91 was about pofltk's own claim, not FLTK's: `FlGlut.cpp`
said `make_overlay_current` crashes on a window not shown, and skipped
`glutEstablishOverlay` and `glutUseLayer(GLUT_OVERLAY)` on one. It is
`make_overlay` and then the driver's `glDrawBuffer(GL_FRONT)` on whatever
context is current (`Fl_Gl_Overlay.cxx:69`,
`Fl_X11_Gl_Window_Driver.cxx:230`, `Fl_Wayland_Gl_Window_Driver.cxx:255`),
and doesn't crash. The guard is gone, so an overlay established while a
window is hidden is drawn when it is shown, as FLTK's is.

**Confirmed:** scratch programs on Xvfb and headless sway, under
valgrind with no errors: the overlay calls on a window never shown, on
one hidden, and on each while another window's context is current; and
a NIL procedure on a shown window, which crashed with the old shim.
`TestGlut` ("an overlay established while hidden is drawn when shown",
"NIL display procedures draw nothing") fails, then segfaults, with the
old shim, and passes with the new, on both back ends, 2026-11-06.

## 146. The vector font table can't hold its top left dot

**What happens:** FLTK's OpenGL vector font (`font_data`) stores each
letter as a C string of commands, a dot being column * 8 + row, so the
dot at column 0, row 0 is a 0 byte, which ends the letter. FLTK's
editor of that table, `test/fonts.cxx`, therefore never records a click
on that dot: a stroke begun there starts at the next dot. Found by
FLTKAda (its FLTK-issues.md F30), confirmed in pofltk 2026-11-06.

**Cause:** `add_point_cb` (`test/fonts.cxx:151`) writes the dot over the
letter's ending 0; the decoder
(`src/drivers/OpenGL/Fl_OpenGL_Graphics_Driver_font.cxx:122`) stops at 0.

**Effect on pofltk:** `examples/Fonts.Mod`, a port of the editor, had
the same bug. It now stores each command plus 1, so the dot is
recorded and drawn. Its saved table is FLTK's encoding, for
`font_data`, which has no way to write that dot, so `Save` leaves it out
and says so in an alert.

**Confirmed:** on Xvfb with `xdotool`, 2026-11-06: a stroke begun at the
top left dot starts there with the new `Fonts`, and at the second dot
with the old; both save the same table, and the new one shows the alert.

## 147. A key that types text never reaches a key binding

**What happens:** an `Fl_Text_Editor` binding of a key that types text,
such as `q` with no modifier or with Shift, is never called, and neither
is the default key function for it: the editor types the character. Its
documentation says the default key function gets the keys bound to
nothing. Found 2026-11-06, binding the key bindings (Phase 24).

**Cause:** `Fl_Text_Editor::handle_key` (`src/Fl_Text_Editor.cxx:639`)
calls `Fl::compose` first, which takes any key with text and no Ctrl,
Alt or Meta as text to insert, and returns before the bindings are
searched. Only keys `compose` refuses, the function keys and those with
Ctrl, Alt or Meta, reach `bound_key_function` and
`default_key_function_`.

**Effect on pofltk:** none to work around: a binding is the program's
choice. `FlText`'s module comment says which keys can be bound.

**Confirmed:** `TestKeys` ("a key that types text is typed, not given the
default (147)"), on Xvfb and headless sway, 2026-11-06.

## 148. `tab_nav(0)` removes whatever Tab is bound to

**What happens:** `Fl_Text_Editor::tab_nav(0)` removes the newest
binding of Tab with no modifier, whatever it is: a program's own binding
of Tab, which then uncovers an older one, and not the `kf_ignore` that
`tab_nav(1)` added, if a binding of the program's is newer.

**Cause:** `tab_nav` (`src/Fl_Text_Editor.cxx:824`) is
`add_key_binding(FL_Tab, 0, kf_ignore)` or `remove_key_binding(FL_Tab,
0)`, which removes the first exact match, and `tab_nav()` is whether that
match is `kf_ignore`.

**Effect on pofltk:** `TextEditor.SetTabNav(FALSE)` does what FLTK does,
as its comment says, and keeps the Oberon list of bindings in step
through the same removal as `RemoveKeyBinding`.

**Confirmed:** by the source; `TestKeys` checks `SetTabNav` both ways.

## 149. Full screen, a window's fixed size, and iconize

**What happens:**

- A window shown with no resizable widget and no size range gets a size
  range of its own size, for good, and `fullscreen()` of it then does
  nothing: setting a resizable widget afterwards doesn't help.
- `fullscreen_screens` checks no screen number but for a negative one,
  which means the window's own screen. Wayland ignores the numbers.
- `iconize()` of a window not shown shows it, minimized; of a shown one,
  it needs a window manager on X11, and does nothing on a bare Xvfb.

**Cause:** `Fl_Window::default_size_range` (`src/Fl_Window.cxx:797`),
called as the window is shown, sets `size_range(w(), h(), w(), h())` and
marks the range set; `fullscreen()` (`src/Fl_Window_fullscreen.cxx:39`)
returns unless `is_resizable()`. `fullscreen_screens`
(`src/Fl_Window_fullscreen.cxx:72`); X11 passes the numbers to the window
manager (`src/Fl_x.cxx:2458`), and `Fl_Wayland_Window_Driver::fullscreen_on`
reads none. `Fl_Window::iconize` (`src/Fl_Window_iconize.cxx:20`) uses
`show_next_window_iconic` for a window not shown; X11's driver asks the
window manager (`XIconifyWindow`).

**Effect on pofltk:** `Window.Fullscreen`'s comment says a window of
fixed size can't go full screen, and that `SizeRange` fixes it;
`FullscreenScreens` and `Iconize` say what FLTK does.

**Confirmed:** `TestWidget`, on Xvfb and headless sway, 2026-11-06:
`Fullscreen` of a window shown without a resizable widget does nothing,
and does after `SizeRange`; `Iconize` of a window not shown shows it;
`Iconize` of a shown one is skipped on X11 with no window manager.

## 150. A menu popped up in no window, with none shown, crashes

**What happens:** `Fl_Menu_Item::popup` or `pulldown` of a menu, or
`Fl_Menu_Button::popup` of a button in no window, with no window shown,
is a segmentation fault. And neither `Fl_Menu_Item::popup` nor
`pulldown` calls the picked item's callback: they return the item.

**Cause:** `Fl_Menu_Item::pulldown` (`src/Fl_Menu.cxx:995`), which
`popup` calls too, takes the window from the widget, or, in none,
`Fl::first_window()`, and calls its `screen_num()` without a test
(`:1000`). `Fl_Menu_Button::popup` calls
`picked`, which does the callback; the item's own popup doesn't.

**Effect on pofltk:** `Menu.Popup`, `PopupAt` and `Pulldown` halt with
`Fl.ClosedResource` (73) when there is no window to pop up over
(`HaltPopup`); the shim calls the menu's `picked` for the item chosen, so
its `Callback` is done, as `Popup`'s is.

**Confirmed:** a scratch program segfaulted, on Xvfb, 2026-11-06;
`HaltPopup` halts 73 on Xvfb and headless sway; `TestMenus` checks
`PopupAt` and `Pulldown`, on X11 alone (issue 28).

## 151. `wrapped_row` and `wrapped_column` read one past the rows

**What happens:** `Fl_Text_Display::wrapped_row(row)` and
`wrapped_column(row, column)`, with `row` equal to the number of rows the
display shows, read past the end of the display's line starts. Valgrind
shows an invalid read of 4 bytes after a block of `mNVisibleLines * 4`.

**Cause:** both (`src/Fl_Text_Display.cxx:1217`, `:1245`) test
`row > mNVisibleLines`, not `>=`, then read `mLineStarts[row]`, an array
of `mNVisibleLines`.

**Effect on pofltk:** the shim returns what FLTK returns for a row
outside (the row or the column it is given) for `row >= mNVisibleLines`,
reaching the protected count through a class derived from
`Fl_Text_Display`. A display lays out its rows only when it is drawn
itself, not when its window is drawn into an image surface, so
`TextDisplay.WrappedRow` is right only after a draw of the display.

**Confirmed:** a scratch program under valgrind, on Xvfb, 2026-11-06;
`TestText` checks rows past the end under `make valgrind-headless`.

## 152. A texture pile of 0 or less crashes GL text

**What happens:** after `gl_texture_pile_height(0)`, the next text
`gl_draw` draws with textures is a division by zero (SIGFPE); after a
negative height, a segmentation fault. FLTK takes both.

**Cause:** the setter (`src/gl_draw.cxx:491`) makes a
`gl_texture_fifo(max)`, which `calloc`s `max` entries, NULL for a
negative one, and `compute_texture` (`:415`) does
`current = (current + 1) % size_`. Textures are used for text where GL
is version 3 or later, or has a texture rectangle extension (`:79`), as
Mesa's does.

**Effect on pofltk:** `FlGl.SetTexturePileHeight` halts with
`Fl.Unsupported` (78) for less than 1 (`HaltGlTexturePile`).

**Confirmed:** a scratch program drawing text in an `Fl_Gl_Window` on
Xvfb (Mesa, GL 4.6 compatibility), 2026-11-06: a pile of 1 draws, 0 is
SIGFPE and -3 a segmentation fault. A first try, with no `ortho()`,
crashed with neither: its text's raster position was invalid, and
`draw_string_with_texture` returns before the pile then.

## 153. Line numbers: a printf format, and shown windows alone

**What happens:**

- `Fl_Text_Display::linenumber_format` is used as a printf format, with
  each line's number as its one argument, so a format with another
  conversion, a `%s` or a `%n`, or two, reads or writes arguments that
  aren't there.
- A display's line numbers are drawn only in a shown window, not when its
  window, never shown, is drawn into an image surface.

**Cause:** `draw_line_numbers` (`src/Fl_Text_Display.cxx`) does
`snprintf(lineNumString, sizeof(lineNumString), linenumber_format(),
lineNum)`, into 16 bytes, and returns first if `!visible_r()` (`:3190`).
The format is copied (`fl_strdup`, `:349`).

**Effect on pofltk:** `TextDisplay.SetLineNumberFormat` takes `%%` and at
most one `d`, `i`, `o`, `u`, `x` or `X` conversion, with flags, a width
and a precision, and halts with `Fl.Unsupported` (78) for anything else
(`HaltLineNumberFormat`). `TestText` checks line numbers in a shown
window.

**Confirmed:** by the source, and `TestText` on Xvfb and headless sway,
2026-11-06: in a capture of a window never shown, no line number was
drawn.

## 154. `show(argc, argv)` changes two greys, even at the default background

**What happens:** a window shown with `show(argc, argv)` is drawn with
`FL_DARK3` at 0x535353 and `FL_DARK1` at 0xababab, where one shown with
`show()` has FLTK's built-in 0x555555 and 0xaaaaaa, on X11 and Wayland,
with no X resources or options: the system's background is FLTK's own
default, `#c0c0c0`. A port of an FLTK program that uses one where the
program uses the other differs in every box edge drawn with those greys,
by too little for `magick compare -fuzz 1%` to see.

**Cause:** `Fl_Window::show(int, char **)` calls `Fl::get_system_colors()`
(`src/Fl_arg.cxx:290`), and each driver's `get_system_colors` calls
`Fl::background` with the system's background, `#c0c0c0` by default
(`src/drivers/X11/Fl_X11_Screen_Driver.cxx:562`). `Fl::background`
(`src/Fl_get_system_colors.cxx:42`) recomputes the whole grey ramp as a
power curve through that colour, rounded, which isn't the table in
`fl_cmap.h` at two places.

**Effect on pofltk:** none in the binding: `Window.Show` is `show()` and
`Window.ShowArgs` is `show(argc, argv)`, as FLTK's are. Nineteen of the
examples' ports used `Show` where FLTK's program uses `show(argc, argv)`;
they now use `ShowArgs` (`Clock`'s second window is shown plainly, as in
FLTK). README's example, `Hello`, is one of them.

**Confirmed:** a C++ program printing the colours `get_system_colors`
changes, under Xvfb and headless sway, 2026-11-07: 39 and 47, as above,
and no others. Under Xvfb with no fuzz, `Hello` against FLTK's
`test/hello` gave an AE of 8.6 with `Show` and none with `ShowArgs`;
`Forms` against `test/forms` differed in box edges across the window with
`Show`, and with `ShowArgs` only at its clock and timer, which show the
time. Found by FLTKAda, porting `test/forms.cxx`.

## 155. `Fl_Input_::index` doesn't check its position

**What happens:** `index(i)` decodes the character at byte `i` of the
text with no bounds check, so a position before the text or past its
end reads outside the value's buffer. At the text's length it reads the
terminating `0`, and gives 0. A byte inside a character, not its
first, is decoded alone, as CP1252 or Latin-1: the second byte of "é"
gives `0A9H`.

**Cause:** `src/Fl_Input_.cxx:1560` is
`fl_utf8decode(value_+i, value_+size_, &len)`, and `fl_utf8decode`
(`src/fl_utf8.cxx:724`) reads `*p` before it compares `p` with `end`.

**Effect on pofltk:** `Input.Index` halts 74 (`IndexOutOfRange`) for a
position outside 0 to the text's length: the shim returns -1 for one.

**Confirmed:** from the source; `TestInputs` reads "aé" at 0 to 3
(`97`, `0E9H`, `0A9H`, 0), and `HaltInputIndex` halts at 3 of "ab",
2026-11-07.

## 156. Every `Fl::scheme()` writes `FLTK_SCHEME`

**What happens:** `Fl::scheme(name)` sets the environment variable
`FLTK_SCHEME` to the scheme it chose, or to "" for none, so that child
processes inherit it. `Fl::scheme(NULL)`, the system's scheme, reads
`FLTK_SCHEME` first, and on X11 only without it the X resource
`<class>.scheme` (`fltk.scheme` by default). So once a program has set
a scheme, `scheme(NULL)` gives that scheme back, and the X resource is
never read again. Names are case-insensitive, and an unknown one is
none.

**Cause:** `src/Fl_get_system_colors.cxx:196` (`Fl::scheme`, its
`putenv` of a static buffer), and the screen drivers'
`get_system_scheme` (`src/drivers/X11/Fl_X11_Screen_Driver.cxx:567`,
which opens the display; `src/Fl_Screen_Driver.cxx:215` elsewhere).

**Effect on pofltk:** `Fl.SetSystemScheme` is `scheme(NULL)`, and its
comment says so; a program that wants the user's scheme calls it before
any `SetScheme`. A program it starts inherits its scheme.

**Confirmed:** `TestWidget`, 2026-11-07, under Xvfb and headless sway:
`SetSystemScheme` after `SetScheme("gtk+")` gives "gtk+"; with
`FLTK_SCHEME` set to "Plastic" it gives "plastic"; "nonesuch" gives
none. `Message` matches FLTK's build with `FLTK_SCHEME=plastic` too.

## 157. `getUserdataPath` makes a cut-short directory, and says it worked

**What happens:** `Fl_Preferences::getUserdataPath(path, pathlen)`
copies the database's file name into `path`, cut to `pathlen`, replaces
its extension with `/`, and makes that directory. With a `pathlen` too
short for the whole name, it makes a directory at the cut-short name (a
file `~/.config/vend/app.prefs` with 48 bytes gave `~/.config/ve`, made
beside `vend`), leaves the final `/` off, and returns 1, success. It
also returns 1 when the directory can't be made: `fl_make_path` returns
1 whether `fl_mkdir` worked or not. A database in memory gives `data/`
and 0.

**Cause:** `src/Fl_Preferences.cxx:1508` (`RootNode::getPath`: the
`strlcpy` to `pathlen`, then `fl_make_path` and `strlcat` of the `/`,
with no check that the name fitted), and `src/fl_utf8.cxx:618`
(`fl_make_path`, which ignores `fl_mkdir`'s result).

**Effect on pofltk:** `Preferences.UserdataPath` gives FLTK a buffer
sized from the file's name, so it is never cut, then checks the
directory with `stat` (not `fl_filename_isdir`, 121), and gives FALSE
and "" in memory, for a directory not made, or a name that doesn't fit
the array.

**Confirmed:** a scratch C++ program, 2026-11-08 (the 48-byte case
above, and memory's `data/`); `TestPreferences`.

## 158. `XDG_CONFIG_HOME` without the vendor's directory is passed over

**What happens:** a user database (`Fl_Preferences::USER_L`) is
`$XDG_CONFIG_HOME/{vendor}/{application}.prefs` only if
`$XDG_CONFIG_HOME/{vendor}` already exists. If it doesn't, and
FLTK 1.3's `~/.fltk/{vendor}` does, FLTK uses that, in the user's home,
whatever `XDG_CONFIG_HOME` says. So setting `XDG_CONFIG_HOME` to an
empty directory doesn't keep a program off the user's preferences.

**Cause:** `src/drivers/Unix/Fl_Unix_System_Driver.cxx:567`
(`preference_rootnode`: "If this base path does not exist, try the 1.3
path").

**Effect on pofltk:** `make test` makes `build/config/fltk.org` before
running an `EXAMPLEPREFS` example. A port compared by hand must have
`fltk.org` in its `XDG_CONFIG_HOME` too: comparing `Blocks` with an
empty one wrote `~/.fltk/fltk.org/blocks.prefs` (2026-11-08).

**Confirmed:** `Blocks` and FLTK's `blocks`, 2026-11-08: with an empty
`XDG_CONFIG_HOME` the high score went to `~/.fltk/fltk.org`; with
`fltk.org` made in it, it went there.

## 159. `Fl_Browser::linespacing` doesn't measure the lines again

**What happens:** a browser's full height is counted as lines are
added and removed, each with the line spacing of that moment.
`linespacing(n)` changes the spacing and not the count, so lines added
before it keep their old height: ten 20-pixel lines at spacing 0 are
200 pixels after `linespacing(5)`, not 250. The scrollbar and
`bottomline`/`middleline` then stop short of the last lines, and once
those lines are removed with the new spacing the height goes negative
(-50 for the ten).

**Cause:** `FL/Fl_Browser_.H`'s `linespacing(int)` is inline and sets
the field alone; `src/Fl_Browser.cxx:267` (`insert`) adds
`item_height(t) + linespacing()` to `full_height_`, and `:211`
(`remove`) subtracts it with the spacing then in force.

**Effect on pofltk:** `BrowserBase.SetLineSpacing` of a `Browser`
counts the full height again (`FlBrowsers.cpp`'s `Remeasure`, which
reaches the private `full_height_` by explicit instantiation). Setting
the text size again counts it too, but resets the position and a file
browser's icon size, so it isn't used.

**Confirmed:** a scratch C++ program, 2026-11-08 (the figures above,
and 250 with the spacing set before the lines); `TestBrowsers`, whose
two checks fail without `Remeasure`.

The entries from 160 were found by FLTKAda and recorded here on
2026-11-12 (FLTKAda's `FLTK-issues.md`, whose F-numbers they give).
Each was confirmed in FLTKAda, by the test or program named there. In
pofltk each was checked only by reading its code, not by running
anything, and none is worked around yet.

## 160. The PNG, JPEG and PNM loaders size the image as an `int`

**What happens:** a PNG or JPEG whose header claims more than
`INT_MAX` bytes of image passes FLTK's size check, and the size of
the buffer it allocates overflows. A size that turns negative makes
`new` throw; one that wraps to a small number (65536 by 65536 by 1 is
0) gets a buffer the decoder then writes past. (FLTKAda's F7.)

**Cause:** each loader checks the size against `max_size()` as a
`size_t` (`Fl_PNG_Image.cxx:217`, `Fl_JPEG_Image.cxx:323`,
`Fl_PNM_Image.cxx:133`), then allocates `new uchar[w() * h() * d()]`, an
`int` product (`:218`, `:324`, `:139`). `max_size` is unlimited by
default (`Fl_Image.cxx:335`). `Fl_BMP_Image.cxx:280-285` and
`Fl_ICO_Image.cxx:193` have the same shape.

**Effect on pofltk:** the loads catch `std::bad_alloc`
(`src/FlImages.cpp:733`, `753`, `925`, `943`), which covers a size that
turns negative, but nothing sets `Fl_Image::max_size`, so a size that
wraps gets through. FLTKAda sets `max_size` to `INT_MAX` at start-up,
so the check refuses such a file. On a 32-bit system that isn't enough:
FLTK's `size_t` product wraps too, so 65536 by 65536 by 1 is 0 there
as well, and passes any `max_size`.

**Workaround** (2026-11-13): Fl's body sets `Fl_RGB_Image::max_size`
to `INT_MAX` (`ofl_register_statics`, `src/Fl.cpp`), which covers what
FLTK loads itself, such as a help view's images, on a 64-bit system.
And `FlImages.cpp` checks each PNG, JPEG and PNM it loads, and the PNG in
an ICO, before FLTK sees it, as `dib_ok` checks BMPs: an image of more
than `INT_MAX / 4` pixels (4 bytes a pixel, the most a loaded image has)
doesn't load. It reads the size as each decoder does: a PNG's from its
`IHDR`, a JPEG's from its first frame header, with the markers found as
libjpeg finds them, and a PNM's by Fl_PNM_Image's own code, `fgets` and
`strtol` into an `int`. What FLTK loads itself on a 32-bit system stays
exposed, as with 87 and 88.

**Confirmed:** in FLTKAda, `test_image_crafted` with a 65535 by 65535
PNG and a JPEG whose header says 65500 by 65500. In pofltk, under valgrind
(2026-11-13), `TestImageFiles` loading `test/images/wrap.png` (65536 by
65536, gray) wrote past a buffer of 0 bytes, in `png_combine_row`, then
crashed; a scratch program loading `wrap.jpg` (`rb.jpg` said to be 37838
by 37838, RGB, which wraps to 175436 bytes), `wrap.pgm` (65536 by 65536)
and `wrap.ico` (holding `wrap.png`) each wrote past FLTK's buffer. A help
view showing `big.png` (46341 by 46341, gray, just over `INT_MAX`
bytes) had `Fl_PNG_Image` allocate -2147479015 bytes, which throws,
uncaught, through `Fl_Help_View::value`. After the fix none of them
loads, with no error under valgrind.

## 161. `Fl_Menu_::add(const char *)` drops a byte where it cuts a long part

**What happens:** a part of the text, between `|`s, longer than 1022
bytes is cut into items of 1022 bytes, and the byte after each 1022 is
lost: a part of 1030 bytes adds items of 1022 and 7. (FLTKAda's F11.)

**Cause:** the copy into the 1024-byte `buf` stops at 1022 bytes, and
after adding the item `if (*str) str++` skips the next byte as if it
were a `|` (`Fl_Menu_add.cxx:451-457`).

**Effect on pofltk:** `InputChoice.Add` (`src/FlInputs.Mod:380`) calls
`ofl_input_choice_add` (`src/FlInputs.cpp:184`), which calls
`Fl_Input_Choice::add`, that is `menu_->add(s)`, so it loses the byte.
Its comment doesn't say so. `FlMenus` adds items with `insert`
(`src/FlMenus.cpp:155-157`), which doesn't have this fault.

**Workaround** (2026-11-13): `ofl_input_choice_add` splits the text at
`|`s itself, and adds each part with `Fl_Menu_::add(label, shortcut, ...)`,
which goes to `insert`, its label cut to 1023 bytes as `FlMenus` cuts
them (172) and its shortcut read from after the tab (173). A long part
is one item, losing no byte within it.

**Confirmed:** FLTKAda's `test_menu_add_items`, on X11 and on sway. In
pofltk, before the fix, `TestInputs`' `Add` of 1030 bytes gave items of
1022 and 7 bytes, the second starting with the 1024th byte, not the
1023rd; after it, one item of the first 1023.

## 162. `FL_CONTRAST_CUSTOM` with no function uses CIELAB at level 0

**What happens:** in Custom mode with no contrast function set,
`fl_contrast` returns the foreground colour unchanged, even white on
white. FLTK's documentation says it falls back to CIELAB, but it
doesn't contrast as CIELAB mode does. (FLTKAda's F12.)

**Cause:** the fallback calls `fl_contrast_cielab`
(`fl_contrast.cxx:513-519`), which reads its threshold from
`fl_contrast_level()`, the current mode's level (400, 202). Custom's
level is 0 to start (37-43), and every pair of colours passes a
threshold of 0 (410).

**Effect on pofltk:** the shim passes the calls through
(`src/Fl.cpp:1434-1440`). The comment on `Fl.SetContrastMode`
(`src/Fl.Mod:2850`) says "ContrastCustom is ContrastCielab until
SetContrastFunction", which is wrong in this way: it should say to set
a level in Custom mode, such as CIELAB's 39, to get CIELAB's
behaviour.

**Confirmed:** FLTKAda's `test_statics_core`, on X11 and on sway:
white on white gives white at Custom's level 0, and black after
setting the level to 39 in Custom mode.

**Workaround** (2026-11-13): none needed; the comment on
`Fl.SetContrastMode` now says Custom with no function changes no colour
until a level is set in Custom mode.

## 163. The PDF surface's `begin_job` leaks the page size it reads

**What happens:** each `Fl_PDF_File_Surface::begin_job` under X11 or
Wayland loses a few bytes, the page size's name. Valgrind reports them
definitely lost, from `Fl_Preferences::get`. (FLTKAda's F19.)

**Cause:** `Fl_PDF_Pango_File_Surface::begin_job` reads
`PDF/page_size` with the `char *&` form of `Fl_Preferences::get`, which
returns a `strdup`ed copy for the caller to free, and never frees it
(`Fl_PostScript.cxx:1683`).

**Effect on pofltk:** none it can fix, since the string is FLTK's
local. Printing a PDF with the chooser (`ofl_print_pdf`,
`src/FlPrint.cpp:284`) loses the bytes once a call. FLTK allocates
them, so `test/vg-check.sh` doesn't count them.

**Workaround** (2026-11-13): none; the string never leaves FLTK's
function. `FlPrint.OpenPDFChooser`'s comment says each call loses the
bytes, whatever the user answers (they are read before the chooser is
shown, `Fl_PostScript.cxx:1683`), and that `OpenPDF`, which calls
`begin_document`, doesn't.

**Confirmed:** FLTKAda's `test_pdf_surface` under valgrind.

## 164. `Fl_PDF_File_Surface::begin_document` keeps its `FILE` when Cairo fails

**What happens:** `begin_document` opens the file, and if
`cairo_pdf_surface_create_for_stream` then fails it returns 2 without
closing it. (FLTKAda's F21, which also lists two pitfalls that don't
apply here: `pdf_filename()` without Pango dereferences null, and
pofltk doesn't bind it; and the dialog's texts in a `--disable-print`
FLTK, which is 104.)

**Cause:** `Fl_PostScript.cxx:1721-1737`.

**Effect on pofltk:** `ofl_print_pdf` calls `begin_document`, or
`begin_job`, which calls it (`src/FlPrint.cpp:284`), and on a failure
the `FILE` and its descriptor were lost. It needs Cairo to fail, so it
is rare.

**Workaround** (2026-11-13): on 2, `ofl_print_pdf` closes the file
(`close_failed`). The surface's private `platform_surface_`, reached by
an explicit instantiation, is with Pango FLTK's own class derived from
`Fl_PostScript_File_Device`, whose `file()` is the driver's `output`,
NULL until opened. Without Pango it is an `Fl_PostScript_File_Device`
itself, which returns 2 before opening anything, and whose driver never
sets `output` (`Fl_PostScript_Graphics_Driver`'s constructor,
`Fl_PostScript.cxx:149`), so that exact class is left alone.

**Confirmed:** from FLTK's source, in both bindings; and in pofltk by
`TestPrint`, whose `BreakCairo` module replaces
`cairo_pdf_surface_create_for_stream` in the program with one that
gives a surface in error: `OpenPDF` failed, and the lowest free file
descriptor was one higher after it ("and its file is closed" failed).
It passes with the workaround, under valgrind too.

## 165. On Wayland a GL window's swap interval is one setting for all

**What happens:** on Wayland, `Fl_Gl_Window::swap_interval()` reads
the last interval set on any GL window, or 1 if none was, even for a
window that isn't shown. On X11 a window not shown reads -1, and a
shown one its own interval, if the driver can say. (FLTKAda's F22.)

**Cause:** the Wayland driver keeps the interval in one static,
`swap_interval_`
(`src/drivers/Wayland/Fl_Wayland_Gl_Window_Driver.cxx:66`), sets it
whenever `eglSwapInterval` succeeds, and returns it (`:461-472`). The
X11 driver asks GLX about the window's own drawable, and returns -1
before the window has one
(`src/drivers/X11/Fl_X11_Gl_Window_Driver.cxx:374-376`).

**Effect on pofltk:** nothing to work around, but the comment on
`GlWindow.SwapInterval` (`src/gl/FlGl.Mod:367`), "-1 if it can't be
told", doesn't say that on Wayland it is one value for all windows.

**Confirmed:** FLTKAda's `test_widget_methods`: an unshown window reads
1 under headless sway and -1 under Xvfb.

**Workaround** (2026-11-13): none needed; the comment on
`GlWindow.SwapInterval` now says that on Wayland it is one value for
every GL window.

## 166. `Fl_Scheme_Choice`'s callback reads before its menu when nothing is chosen

**What happens:** `do_callback()` on a scheme choice whose `value()`
is -1 reads the menu item before the first. (FLTKAda's F28.)

**Cause:** `Fl_Scheme_Choice::scheme_cb_` takes
`c->text(c->value())` (`src/Fl_Scheme_Choice.cxx:90`), and
`Fl_Menu_::text(i)` is `menu_[i].text`, unchecked (`FL/Fl_Menu_.H:214`).
A pick always sets a value first, so FLTK itself only gets there when
a program calls the callback with nothing chosen.

**Effect on pofltk:** `SchemeChoice.Callback` (`src/FlMenus.Mod:390-393`)
calls `scheme_cb_` (through `src/FlMenus.cpp:198`) without looking at
the value, and `Menu.SetValue(-1)` is allowed (`src/FlMenus.Mod:276`),
so `SetValue(-1)` and then `Callback` or `DoCallback` reads
`menu_[-1]`. FLTKAda calls `scheme_cb_` only when the value is an
item; pofltk could do the same.

**Workaround** (2026-11-12): the shim's `Scheme::chosen`
(`src/FlMenus.cpp`) calls `scheme_cb_` only when the value is 0 or more,
so with nothing chosen `SchemeChoice.Callback` leaves the scheme alone.

**Confirmed:** in FLTKAda, a C++ program under Xvfb and valgrind:
`value(-1)` then `do_callback()` gave an invalid read of 8 bytes at
`Fl_Scheme_Choice.cxx:90`. In pofltk, `TestMenus`' `SetValue(-1)` and
`DoCallback` under valgrind gave the same invalid read, through
`ofl::callback_trampoline`, before the fix, and none after; without
valgrind the check passed either way.

## 167. A shortcut's label depends on the backend

**What happens:** `fl_shortcut_label` gives a different label for the
same shortcut under X11 and under Wayland. `FL_COMMAND+0x20ac` is
"Ctrl+EuroSign" under X11 and "Ctrl+€" under Wayland; `'\r'` is
"Enter" under X11, and under Wayland a carriage return, which shows as
nothing. (FLTKAda's F32.)

**Cause:** `Fl_X11_Screen_Driver::shortcut_add_key_name` writes "Enter"
for `FL_Enter` and `'\r'`, the character itself for 33 to 0xff, and
otherwise `XKeysymToString(key)`
(`src/drivers/X11/Fl_X11_Screen_Driver.cxx:137-155`). The default,
which the Wayland driver doesn't override, looks the key up in
`key_table` and otherwise encodes `fl_toupper(key)` as UTF-8
(`src/fl_shortcut.cxx:381-416`), and the table has `FL_Enter` but not
`'\r'`.

**Effect on pofltk:** none on the binding: `Fl.ShortcutLabel`
(`src/Fl.Mod:2266-2270`) gives what FLTK gives. Its comment doesn't say
the label depends on the backend. `TestMenus` checks only "Ctrl+S",
which is the same on both.

**Confirmed:** FLTKAda, a C++ program printing `fl_shortcut_label` for
`menubar.cxx`'s international shortcuts under Xvfb and headless sway.

**Workaround** (2026-11-13): none needed; the comment on
`Fl.ShortcutLabel` now says the label depends on the back end.

## 168. `fl_color_chooser` shows a zero component as "0" unless given a mode

**What happens:** `fl_color_chooser` with no mode (-1), for a colour
such as `FL_SELECTION_COLOR` (0, 0, 128), shows its R and G fields as
"0" and its B field as "0.502". Given a mode, even RGB, all three have
three decimals: "0.000". (FLTKAda's F37.)

**Cause:** the `Fl_Color_Chooser` constructor calls `set_valuators`
(`src/Fl_Color_Chooser.cxx:571`) while every value is 0, so each
`Fl_Value_Input` keeps the text it was made with. `rgb(r, g, b)` calls
`set_valuators` again (:143), but `Fl_Valuator::value` redraws the text
only when the value changes, so a component still 0 keeps "0".
`mode(m)` runs `mode_cb` (:451-458), which first sets every value to -1
to force the redraw.

**Effect on pofltk:** cosmetic. `FlDialogs.ChooseColor`
(`src/FlDialogs.Mod:340-345`) passes `ColorDefault` (-1) through, and
`examples/Input.Mod:105` and `examples/Tree.Mod:329` use it, so their
zero fields show "0", as the C++ originals do.

**Workaround** (2026-11-13): none. Forcing a mode would fix the text,
but would lose what `ColorDefault` means, the mode the user last chose,
and the ports would no longer match FLTK's programs. `ChooseColor`'s
comment says a zero shows as "0" with `ColorDefault`.

**Confirmed:** FLTKAda, its `test/input.adb` against FLTK's
`test/input` on Xvfb.

## 169. `Fl_Table` with a filled table box paints over cells it doesn't redraw

**What happens:** a table whose `table_box` is a filled box, such as
`FL_UP_BOX`, and which has no child widgets, sometimes shows the box
over every cell except a few rows. In FLTK's `test/table` with Table
Box set to Up Box and Type to SelectSingle, a drag down the rows left
only rows 12 to 17 drawn. (FLTKAda's F38.)

**Cause:** with no children, the table's inner `Fl_Scroll` is hidden
(`src/Fl_Table.cxx:181`, `FL/Fl_Table.H:775-781`). `Fl_Table::draw`
then draws `table->box()` over the whole table area whenever the
damage includes `FL_DAMAGE_CHILD` (`src/Fl_Table.cxx:1327-1331`), but
without `FL_DAMAGE_ALL` it redraws only the cells from
`_redraw_toprow` to `_redraw_botrow` (:1336-1344). Which damage bits a
redraw gets depends on how events and redraws fall.

**Effect on pofltk:** `Table.SetTableBox` (`src/FlTable.Mod:228-230`)
passes it through, and its comment doesn't warn. `examples/Table.Mod`
offers filled boxes, as the C++ demo does, so it draws the same partial
table (confirmed below).

**Confirmed:** FLTKAda, FLTK's `test/table` and the Ada port under Xvfb
with `xdotool`; the cause is from reading the source.

**Workaround** (2026-11-13): none in the binding, since what FLTK
draws is right for its damage; the comment on `Table.SetTableBox` now
warns.

**Confirmed in pofltk** (2026-11-13): a copy of `examples/Table.Mod`
with Up Box and SelectSingle set at start, under Xvfb: a drag with
`xdotool` down the first column, from row 0 to row 17, left rows 18 to
20 showing the box, not their cells; a click then redrew them.

## 170. `gl_draw_image` reads past its data

**What happens:** `gl_draw_image` with depth 1 or 2, or with rows whose
length in bytes isn't a multiple of 4, reads past the end of data that
holds exactly `w * h * d` bytes, and draws the wrong colours: grey is
drawn as RGB, and such rows are drawn askew. FLTK's manual says nothing
of either. (FLTKAda's F40; `000-todo.org` has FLTKAda's report.)

**Cause:** `gl_draw_image` (`src/gl_draw.cxx:236-244`) passes
`d < 4 ? GL_RGB : GL_RGBA` to `glDrawPixels`, so depths 1 and 2 are
read at three bytes a pixel. It sets `GL_UNPACK_ROW_LENGTH` but not
`GL_UNPACK_ALIGNMENT`, whose default of 4 makes GL take each row as
padded to a multiple of 4 bytes.

**Effect on pofltk:** `FlGl.DrawImage` (`src/gl/FlGl.Mod:514-520`)
checks `w * h * d <= LEN(data)`, allows depths 1 and 2, and documents
depth 1 as grey, then calls `ofl_gl_draw_image`
(`src/gl/FlGl.cpp:281-284`), which calls `gl_draw_image`, so it has the
same over-read. FLTKAda's shim draws the image itself, with a format
for each depth (`GL_LUMINANCE`, `GL_LUMINANCE_ALPHA`, `GL_RGB`,
`GL_RGBA`) and an alignment of 1, and restores the unpack state it
changes.

**Workaround** (2026-11-12): `ofl_gl_draw_image` does as FLTKAda's
shim does. `TestGl` draws a 3 by 2 image at each depth, rows of 3, 6, 9
and 12 bytes, and reads back every pixel: with `gl_draw_image` depths 1,
2 and 3 fail, and with the shim's own drawing all four pass. The same
check showed that the first row is drawn at `y`, going up, as GL draws
pixels; `DrawImage`'s comment had said from the top.

**Confirmed:** in FLTKAda, a scratch C++ program under Xvfb and
valgrind: depths 1 and 2 at width 8 had 107 invalid reads each, and
depth 3 at width 10 had 12, all in Mesa's `glDrawPixels`.

## 171. While a pop-up menu is up, the grab is a window FLTK made

**What happens:** `Fl::grab()` while a pop-up or pull-down menu is up
is the menu's own window, which FLTK made. A binding that gives NIL
for a window FLTK made then can't tell an open menu from no grab at
all. The same holds for `Fl::pushed()`, `Fl::belowmouse()` and
`Fl::focus()`, which can be parts of widgets FLTK made. (FLTKAda's
FLTKAda-BUGS.md 44.)

**Cause:** `Fl_Menu_Item::pulldown` grabs its own `menuwindow`
(`Fl_Menu.cxx:1002`), which FLTK constructs.

**Effect on pofltk:** safe: `Fl.Grab`, `Fl.Focus`, `Fl.BelowMouse` and
`Fl.Pushed` give NIL for one FLTK made (`src/Fl.Mod:2135`, `2146-2148`,
`3086`, through `ofl::object_of`). But nothing says whether there is
one. FLTKAda added `Has_Grab`, `Has_Pushed`, `Has_Below_Mouse` and
`Has_Focus`, which compare FLTK's pointer with null; pofltk could add
the same.

**Workaround** (2026-11-13): `Fl.HasFocus`, `HasBelowMouse`,
`HasPushed` and `HasGrab` say whether FLTK has one at all, the
program's or its own (`ofl_any`).

**Confirmed:** FLTKAda's `test_foreign_widgets`, which on X11 opens a
pop-up menu: `Has_Grab` is true and `Get_Grab` gives null. In pofltk,
`TestMenus` on X11: while a pop-up is up, `HasGrab` and `Grab() = NIL`;
and `TestValuators`: a value input's field has the focus, `HasFocus`
with `Focus() = NIL`.

## 172. `Fl_Menu_Item::insert` overruns its stack buffer on a long part

**What happens:** a part of an item's path, between `/`s, longer than
1023 bytes (after its `\` escapes are undone) is copied past the end of
a 1024-byte buffer on the stack: a label of 3000 bytes aborts the
program with "stack smashing detected", or worse where there is no
stack protector.

**Cause:** `Fl_Menu_Item::insert` copies each part into `char buf[1024]`
with `for (p=mytext; *p && *p != '/'; *q++ = *p++)`, which has no bound
(`Fl_Menu_add.cxx:147,163`). `Fl_Menu_::insert` and `add(label, ...)`
come here, and so does `add(const char *)`, whose own copy stops at 1022
bytes (161). A part starting with `/` is taken whole, unbounded but
uncopied, as a file name.

**Effect on pofltk:** `Menu.Insert` and `Menu.Add` (`src/FlMenus.Mod`)
call `insert` with the program's label, so any label part over 1023
bytes overran.

**Workaround** (2026-11-13): `ofl::menu_path` (`src/pofltk.h`) cuts each
part to 1023 bytes, counting an escape as the one byte it becomes,
where a UTF-8 character starts, and keeps a part starting with `/`
whole. `FlMenus.cpp`'s `insert_item` and `InputChoice.Add` give FLTK
its result.

**Confirmed:** a C++ program under Xvfb, and `TestMenus`, adding a
3000-byte label through `FlMenus.Menu.Add`: "*** stack smashing
detected ***" and SIGABRT before the fix; after it, an item of 1023
bytes, and a submenu's title of 1500 bytes cut the same.

## 173. `Fl_Menu_::add(const char *)` misreads a shortcut after a tab

**What happens:** in the text `add(const char *)` takes, a tab ends an
item's label and starts its shortcut, but only a number is read: "^a",
which `fl_old_shortcut` reads as Ctrl+A, gives no shortcut.

**Cause:** `add` calls `fl_old_shortcut(str)` with `str` at the tab
itself, not after it (`Fl_Menu_add.cxx:452`). `fl_old_shortcut`
(`fl_shortcut.cxx:275`) looks for `#`, `+`, `^` and `!` at the start,
finds the tab, and passes it to `strtol`, which skips the tab and reads
a number, or 0.

**Effect on pofltk:** `InputChoice.Add` called `add(const char *)`, so a
shortcut after a tab worked only as a number.

**Workaround** (2026-11-13): `ofl_input_choice_add` (161) reads the
shortcut with `fl_old_shortcut` from after the last tab, and the label
ends at the first.

**Confirmed:** a C++ program: `add("A\t^a|B\tx|C\t0x62|D\t^a|E")` gave
shortcuts 0, 0, 0x62, 0 and 0, while `fl_old_shortcut("^a")` is
0x40061. `TestInputs` adds "five", a tab and "^f", and Ctrl+F picks the
item, which it didn't before the fix.

## 174. `FL_OPENGL3` gives no core profile on X11 or Wayland

**What happens:** a window with `FL_OPENGL3` in its mode, an
`Fl_Gl_Window` or GLUT's (`glutInitDisplayMode`), gets the same context
as without it: on Mesa, "4.6 (Compatibility Profile)", on both back ends.
So GL's legacy calls, and FLTK's GL text and GLUT's fonts, which use
them, keep working there. On a core-profile context those fonts draw
nothing, with no crash.

**Cause:** the X11 driver makes every context with `glXCreateContext`
(`src/drivers/X11/Fl_X11_Gl_Window_Driver.cxx:203`), and the Wayland
driver asks EGL for version 2 (`EGL_CONTEXT_CLIENT_VERSION`,
`src/drivers/Wayland/Fl_Wayland_Gl_Window_Driver.cxx:161`), and Mesa
gives both its highest compatibility version. Only the Cocoa and WinAPI
drivers read `FL_OPENGL3` (core 3.2 on macOS), where `draw_begin`
switches to a GL 1 context for FLTK's own drawing
(`Fl_Gl_Window.cxx:383`). On a core context `gl_draw` draws with
`glRasterPos` and `glCallLists`, the stroke fonts with `glBegin`, and
`glOrtho` and the matrix stack are gone: each is
`GL_INVALID_OPERATION`. The measures (`gl_width`, `glutBitmapWidth`,
`glutBitmapLength`) use no GL and still work.

**Effect on pofltk:** none to work around. pofltk runs on X11 and
Wayland, where a program can't get a core context through FLTK, and it
doesn't bind `Fl_Gl_Window::context`, the one way to set another.
`FlGl.OpenGL3`'s comment says so.

**Confirmed:** a C++ program, 2026-11-13, printing `GL_VERSION` and
`GL_CONTEXT_PROFILE_MASK` (2, compatibility) for both kinds of window,
on Xvfb and headless sway. A second, on Xvfb, made a 3.3 core context
(`glXCreateContextAttribsARB`, the window's own `GLX_FBCONFIG_ID`), set
it with `context(ctx, 1)`, and got "4.6 (Core Profile)": `gl_draw` (at a
point, a float point and in a box), `glutBitmapString`,
`glutBitmapCharacter`, `glutStrokeString` and `glutStrokeCharacter` each
gave `GL_INVALID_OPERATION` and lit no pixel (`glReadPixels`), where the
same program on the compatibility context lit 150 to 1473 bytes per
step; `gl_width("Hello")` was 34 and `glutBitmapWidth` of `A` 8 on both.
No valgrind error on any step.

## 175. `glutGetProcAddress` gives an address for any name

**What happens:** on Linux, `glutGetProcAddress` returns an address for
every name: a GL function, but also "xyzzy", "", a GL name that doesn't
exist (`glNoSuchFunction`) and GLUT's own (`glutSolidCube`), with no
display open or context current; for GLUT's it gives a stub, not the
function. Calling a stub does nothing. freeglut's returns NULL for a
name it doesn't know, and GLUT's own functions. FLTK doesn't document
it.

**Cause:** `glutGetProcAddress` (`src/glut_compatibility.cxx:457`) is
`Fl_Gl_Window_Driver::GetProcAddress` (`src/Fl_Gl_Window.cxx:558`),
which X11 and Wayland don't override: with `HAVE_GLXGETPROCADDRESSARB`,
which CMake sets from `glx.h`, it is `glXGetProcAddressARB`, and GLVND's
libGL makes a dispatch stub for any name it is asked, to be filled in if
a vendor library later has the function. Without it, it falls back to
`dlsym` of `"_"` and the name, which is how Mach-O names a symbol; an ELF
symbol has no `_`, so there it always gives NULL.

**Effect on pofltk:** `FlGlut.GetProcAddress` passes the answer on, and
its comment says to check `FlGl.Version` or `ExtensionSupported` before
calling a function it gives. No C++ part is needed to call one: poc
calls an address converted with `SYSTEM.VAL` to a procedure type as C
would (the module comment).

**Confirmed:** a C++ program, 2026-11-13, on Xvfb, headless sway and
with no display, printing the address of each name above, and calling
two made-up ones, under valgrind with no error. `TestGlut` calls
`glClearColor`, `glGetFloatv` and `glGetString` through the addresses it
gives, on both back ends.

## 176. Giving the focus shows the window, on X11 with no window manager

**What happens:** `Fl::focus(w)` of a widget in a window never shown
shows the window, on X11 when no window manager supporting EWMH is
running (Xvfb, as the tests run). So does a push on a button, which
takes the focus (`Fl::visible_focus()`), and so `FlTest.Click` and
`Type`. With an EWMH window manager, and under Wayland, the window stays
unshown. FLTK doesn't document it.

**Cause:** `Fl::focus` (`src/Fl.cxx`) calls the window driver's
`take_focus()`; `Fl_X11_Window_Driver::take_focus`
(`src/drivers/X11/Fl_X11_Window_Driver.cxx:126`) calls
`pWindow->show()` for "old WMs" whenever `ewmh_supported()` is 0, shown
or not. Wayland's (`Fl_Wayland_Window_Driver::take_focus`) does nothing
for a window with no surface.

**Effect on pofltk:** none to work around: a used push never shows a
window itself (`Fl::handle_` shows it only for a push no widget uses).
FlTest's module comment says a click or typing may show the window, and
`TestFlTest` checks a click leaves it unshown on a button with
`SetVisibleFocus(FALSE)`.

**Confirmed:** a program, 2026-11-14, pushing a button in a window never
shown: shown after the push on Xvfb, with the backtrace `Fl_Window::show`
from `Fl_X11_Window_Driver::take_focus` from `Fl::focus` from
`Fl_Button::handle`; still unshown on headless sway.
