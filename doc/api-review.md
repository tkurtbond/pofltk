# What two applications showed about pofltk's API

On 2026-11-14 two programs written with pofltk 0.1.0 were read to see where
the binding made them harder to write than they need be:

- `~/Repos/RPG/Tools/ova_cg_po` (ova), its GUI in `OvaWindow`,
  `OvaWidgets`, `OvaLinkedDialog`, `OvaAttackDialog`, `OvaBackground`,
  `OvaTraitPanel`, `OvaInline`, `OvaMarkdownTab` and `OvaSettings`;
- `~/Repos/RPG/Tools/besm2_cg_po` (besm2), its GUI in `Besm2Window`,
  `Besm2Widgets`, `Besm2ItemPanel`, `Besm2MechaPanel`,
  `Besm2WeaponDialog`, `Besm2Background`, `Besm2Preview` and
  `Besm2Creation`.

They were read, not changed, built or run. Line numbers are of their
`src/` and `test/` then, and of pofltk's `src/` at 51558b7. The pofltk
claims below were checked against its source.

Neither program needs `SYSTEM` or C for its GUI (`SYSTEM` appears only in
modules that don't touch FLTK), and both extend widgets and override
their methods, as the README intends. The trouble is in how some calls
are shaped, and in conveniences missing. Nothing here is decided: these
are proposals, ranked by how much they would help.

## Proposed API changes

### 1. Calls whose result nobody wants `[done]`

Since poc 0.11.0 a function can't be called as a statement, so both
programs write `IF x THEN END`, about 40 times between them:

- `Menu.Add` and `Insert` return an `INTEGER` (`FlMenus.Mod:227`, `:218`);
- `Menu.SetValue` returns a `BOOLEAN` (`FlMenus.Mod:276`);
- `Browser.Select` returns a `BOOLEAN` (`FlBrowsers.Mod:418`);
- `Fl.Check` returns a `BOOLEAN` (`Fl.Mod:2565`), mostly in their tests.

For example ova's `OvaWidgets.Mod:222` `IF p.choice.SetValue(n) THEN
END`, `:235` `IF p.choice.Add(label, 0, {}, NIL, flags) >= 0 THEN END`,
`:260` `IF p.browser.Select(line, TRUE) THEN END`, and
`OvaWindow.Mod:1100`, `:1104`, `:847`.

Proposal: proper procedures for the common case, such as
`Menu.AddItem(label)` (most calls pass `0, {}, NIL, {}`), `Menu.Choose(i)`
and `Browser.SelectLine(line)`.

### 2. No way to add a menu label literally `[done]`

`Add` reads `/` as a submenu path and `&` as a shortcut's mark. besm2
adds a placeholder `"-"` and relabels it with `SetItemLabel`
(`FlMenus.Mod:298`), and doubles each `&` itself (`Besm2Text.MenuText`).
`Besm2Widgets.Mod:281` `FillChoice` still has a latent bug with `/`.

Proposal: `Menu.AddText(label, flags)`, taking the label as it is.

### 3. Text of unknown length `[done]`

Getting text needs `Length` and then `Value`, or a buffer of 4096 bytes
that silently cuts longer text:

- `Input.Value(VAR s)` and `Input.Length` (`FlInputs.Mod:185`, `:213`):
  besm2 has an `InputText` helper in 4 modules, ova the same at
  `OvaWindow.Mod:161-166`;
- `Preferences.TextLength` and `GetText` (`FlPreferences.Mod:320`,
  `:314`): ova at `OvaWindow.Mod:267-272`;
- `FlDialogs.Input(label, VAR value)` (`FlDialogs.Mod:241`) and
  `NativeFileChooser.FileName(i, VAR name)` (`FlDialogs.Mod:561`) cut the
  text with no way to learn its length: ova uses `ARRAY 4096 OF CHAR`
  (`OvaWindow.Mod:180-249`).

`FlDialogs.Name` (`FlDialogs.Mod:125`), a `POINTER TO ARRAY OF CHAR`,
already exists, for `ListDirectory` only.

Proposal: getters returning such a pointer: `Input.Text()`,
`NativeFileChooser.Name(i)`, `Preferences.Text(name)`, and an `Input`
dialog giving the text or NIL.

### 4. Rebuilding a group from one of its own buttons

A widget deleted in a callback stays a child of its group, and shown,
until FLTK runs its queue (`pofltk.h:284-303`, `ofl::delete_widget`, by
design: `doc/fltk-issues.md`, 72). `Group.Clear` (`Fl.Mod:1336`,
`ofl_group_clear`, `Fl.cpp:1051-1064`) does the same. So ova's
`RemoveAction` (`OvaWindow.Mod:635-646`) rebuilds its rows from a
zero-length timer (`rebuild` and `fit`, `OvaWindow.Mod:118-119`; its
PLAN.md:1082: "since FLTK can't delete the button whose callback is
running").

Proposal: in a dispatch, `Delete` and `Clear` remove and hide the widget
first, and delete it later, so a group can be rebuilt from its own
child's callback. At least, document it, and add `Fl.Later(proc)`, a
one-shot idle call, so a zero timeout isn't the idiom. Needs care, and
valgrind, given issue 72.

### 5. The file chooser's filter needs a tab `[done]`

`SetFilter` (`FlDialogs.Mod:517`) takes FLTK's `name<TAB>pattern`, so
the programs poke a tab in: `OvaWindow.Mod:220`, `:233` (`filter :=
"YAML *.{yaml,yml}"; filter[4] := 9X`), `OvaBackground.Mod:180`,
`OvaMarkdownTab.Mod:51`, and besm2 likewise.

Proposal: `AddFilter(name, pattern)`, adding the tab, and the newline
between filters.

### 6. Menu item state by set arithmetic `[done]`

`ItemFlags` and `SetItemFlags` (`FlMenus.Mod:347`, `:351`) are the only
per-item state calls, so both programs write `f := bar.ItemFlags(i); f
:= f + FlMenus.MenuInactive; bar.SetItemFlags(i, f)` (ova
`OvaWindow.Mod:794`, `:802-804`, `:831-833`; its tests' `Active(i)`,
`TestWindow:298`).

Proposal: `SetItemActive(i, on)`, `ItemActive(i)`, `SetItemChecked(i,
on)` and `ItemChecked(i)`.

### 7. Browsers: column widths and format characters

Column widths are worked out from `browser.W()` and refitted after each
resize (ova `OvaTraitPanel.Mod:73-85`, `OvaWidgets.Mod:316-317` `widths[0]
:= w - 70`, from a `fit` timer started in `MainWindow.Resize`,
`OvaWindow.Mod:717-723`; besm2 likewise).

besm2 calls `SetFormatChar(0X)` (`FlBrowsers.Mod:482`) on every browser,
7 times, so that a line's `@` is text.

Proposal: a width of -1 in `SetColumnWidths` (`FlBrowsers.Mod:497`)
meaning the rest of the width, kept by the shim on resize; and a way to
add a line literally, or a setting for it, made prominent in the README.

### 8. Small helpers

- `Spinner.IntValue`: `Value` (`FlValuators.Mod:579`) is a `LONGREAL`,
  and besm2 writes `ENTIER(x + 0.5)` 5 times.
- `Browser.Find(text, from): INTEGER`: there is no search by a line's
  text; both programs' tests have `LineWith` (ova `TestWindow:181`,
  `TestLinked:55`).
- `Fl.CanOpenDisplay()`: besm2 reads `DISPLAY` and `WAYLAND_DISPLAY`
  itself (`Besm2Cg.Mod:97-120`).
- A box's image scaled to the box: ova does `image.Scale(portrait.W() -
  6, ...)` after each resize (`OvaBackground.Mod:149-152`).
- Setting a text buffer without calling `Modified`, which runs on
  `SetText` too (`FlText.Mod:263`, `:271`): ova keeps a `filling` flag.
- A label box (`OpenBox` with `AlignLeft + AlignInside`), about 10 times
  in besm2.
- A recipe or option for a Scroll's child filling its width: a Scroll
  doesn't size its child, so ova's `ShowRows` (`OvaWindow.Mod:667-707`)
  sizes a Flex in one by hand.

### 9. A test-support module for programs `[done]`

`test/Probe` isn't installed, so both programs make their dialogs
replaceable procedure variables, and drive everything by `DoCallback`.
Their tests repeat helpers:

- set-then-`DoCallback`: `Type` (ova `TestWindow:161`, `TestLinked:94`),
  `Pick` (`TestWindow:166`, `TestLinked:73`, `TestLimits:89`), `Click` or
  `SelectLine` (`TestWindow:176`, `TestLinked:68`), `Turn` and `Spin`
  (`TestLimits:79-87`);
- `Settle`, `FOR i := 1 TO 5 DO Fl.Wait(0.01D0) END` (`TestWindow:72`,
  `TestResize:48`), and `ShowIt`, `Show; WaitForExpose; IF Fl.Check()
  THEN END`;
- `LineWith` (8, above).

besm2 exports test-only hooks where `DoCallback` (`Fl.Mod:977`) and
`Menu.Pick` (`FlMenus.Mod:286`) would do.

Proposal: an installed `FlTest`, with `Probe`'s events and its answering
of dialogs, and these helpers.

Done 2026-11-14, in pofltk 0.3.0 (PLAN.md, "FlTest: testing a
program"), with the helpers named `Type`, `Fill`, `Choose`, `Click`,
`SelectLine`, `Turn`, `Change`, `Settle`, `Expose` and `LineWith`, and
the README's "Testing your program".

## What the rewrite to 0.2.0 showed

On 2026-11-14 both programs were rewritten to use 1, 2, 3, 5 and 6
(uncommitted in their repositories then). Four things in the new calls
were awkward:

- **`AddText` and `InsertText` always take an action and flags**
  (`FlMenus.Mod:251`, `:241`). 15 of the two programs' 17 `AddText`
  calls end in `NIL, {}`, since a choice's items have neither. A
  one-argument form, or `AddText(text)` with `AddTextWith` for the rest,
  would shorten them.
- **`ItemLabel` gives back what FLTK holds** (`FlMenus.Mod:321`): for an
  item added by `AddText`, `SetItemText` or `InsertText`, the text with
  `&` and `@` doubled (PLAN.md, "What two applications asked for"). So
  a test of an item's label compares with the doubled text, as ova's
  name check with "Imp & Co @2/3" does. An `ItemText` undoing the
  doubling for such items would give back what was put in.
- **`Fl.String` is a type of its own** (`Fl.Mod:435`). Both programs
  already had a `String = POINTER TO ARRAY OF CHAR` (`Besm2Text.Mod:25`,
  `OvaText.Mod:22`), and Oberon-2 doesn't let two such pointer types be
  assigned to each other, so each program either uses `Fl.String` where
  the text comes from pofltk or copies it. Documenting `Fl.String` as
  the type for a program to use too would avoid the second type.
- **Every native chooser is shown, then asked `Name(0)`, then NIL is
  checked** (`FlDialogs.Mod:590`, `:612`): 4 times in ova, and in besm2
  once in `Besm2Preview.Mod:58` and once in `Chosen`
  (`Besm2Window.Mod:182`), a helper its window's choosers share. A `NativeFileChooser.Choose(): Fl.String`,
  showing it and giving the first name or NIL on cancel or failure,
  would replace the three steps.

## What moving the tests onto FlTest showed

On 2026-11-14 both programs' GUI tests were moved onto `FlTest` (9;
ova_cg_po 543686a, besm2_cg_po 2e7b5b7), dropping their own `ShowIt`,
`Settle`, `Type`, `SelectLine`, `LineWith`, `PickAbility`, `Turn`,
`Spin`, `SetStat` and `Select`. Every check passed as before, on
`test-headless`, `test-sway` and `valgrind-headless`, with no check
added or changed. ova's tests now call `Fill` 30 times, `Turn` 25,
`LineWith` 9, `Change` 7, `Choose` 4 and `SelectLine`, `Settle` and
`Expose` 5 each; besm2's `SelectLine` 24 times, `Fill` 16, `Change` 8
and `Choose` once. What didn't fit:

- **`LineWith` gives the first line holding the text** (`FlTest.Mod:299`);
  ova's own gave the last. No test depended on which, but a browser
  with the text on two lines would pick another.
- **`Choose` wants the item's label, not the program's name for it**
  (`FlTest.Mod:266`). Both programs label their choices from their
  rules (`OvaRules.LabelOf`, `Besm2Rules.Label`: "Attack (p. 50)"), so
  each test file keeps a three-line `Pick` (ova, four files) or
  `ChooseItem` (besm2) that makes the label and halts if `Choose`
  fails. That is the program's own mapping, and belongs in its tests.
- **A choice picked by its index** still uses `Menu.Pick` (besm2's
  `Pick(item)`, `entityChoice`): `FlTest` has no `Choose` by index, and
  `Menu.Pick` already is one.
- **Buttons and tabs are still driven by `DoCallback`** (78 calls left
  in ova, 55 in besm2). `FlTest.Click` (`FlTest.Mod:177`) sends a push
  through the window's routing, which can't reach a button on a tab not
  shown, and on X11 with no window manager a click shows the window
  (`doc/fltk-issues.md`, 176). So a tab is chosen with `SetValue` and
  `DoCallback`, and its buttons pressed with `DoCallback`, as before.
- **`Turn` and `Change` call back only on a change**, where the old
  helpers always did. No test needed the callback for an unchanged value.
- **The programs need pofltk 0.2.0, and only their tests 0.3.0**: each
  AGENTS.md now says so.

None of these asks for a change to `FlTest`.

## Documentation

For the README:

- **A widget carrying its owner.** Both programs search a list for a
  widget's owner in a callback (ova `PanelOf`, `OvaWidgets.Mod:265-273`,
  and `RowOf`, `OvaWindow.Mod:617-623`; besm2 `PanelOf`), since an
  `action` gets only the widget (`Fl.WidgetDesc`, `Fl.Mod:433-439`).
  Show an extended button holding a pointer to its owner. (Or add a
  `data` field to `Fl.Widget`.)
- **Globals aren't needed to keep widgets.** besm2 keeps them in globals
  and sets them to NIL, though pofltk's registry keeps them reachable
  (README.md:276-286); `Hide` before `Delete` adds nothing
  (`Fl.Mod:933`).
- **An application's own modal dialog**: ova opens each by hand
  (`SetModal`, `Show`, `Hide`, `Delete`: `OvaAttackDialog.Mod:273`,
  `343-361`; `OvaLinkedDialog.Mod:434`, `560-562`; `OvaSettings.Mod:86`,
  `161-163`). A recipe, including closing it from its own button (4).
- **Testing your program**, with `DoCallback` and `Menu.Pick` (and
  `FlTest`, 9).
- **Pitfalls**: browser lines count from 1, menu and choice items from
  0 (FLTK's); an extension's method can clash with a widget's own, so
  ova named one `Display`, `Show` being taken.

## Suggested order

Done 2026-11-14, in pofltk 0.2.0: 1, 2, 3, 5 and 6 (PLAN.md, "What two
applications asked for"), with `Menu.Choose`, `Browser.SetSelected`,
`Fl.HandlePending` and `Menu.AddText` for 1, not `AddItem` and
`SelectLine`.

1, 2, 3, 5 and 6 first: small, only additions, and they remove the most
repeated workarounds. Then 9 and the README's testing section, then 4,
which needs tests of its own. All are additions, so `PofltkApiVersion`
goes up without breaking either program.
