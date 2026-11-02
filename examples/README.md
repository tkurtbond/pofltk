# pofltk's examples

Most of these are ports of the programs in FLTK's `examples/` and `test/`
directories, and the comment on a module's first line names the file it
came from. The rest were written for pofltk. `make` builds them into
`build/`. A program that reads files from `test/` is run from this
directory, as `../build/Icons`.

## First programs

**Hello** is the smallest pofltk program: a window with a label in it, FLTK's
`hello`.

**Swatch** shows how to extend a widget: a box with its own `Draw`, and a
button whose callback changes it.

**Scribble** shows a custom widget that uses both `Handle` and `Draw`:
you draw on it with the mouse, and the strokes are kept in Oberon so they can
be redrawn.

**DrawAnX** shows a widget that draws an X filling whatever space it has.

**Callbacks** shows how to give a callback arguments of its own. A widget is a
record, so its arguments are fields, and the callback is a procedure or a
method.

**ParseArgs** shows a program's own command-line options working beside
FLTK's.

**Trackers** shows `Fl.Tracker`, with which a callback can tell whether it has
deleted its own widget.

## Buttons and valuators

**TextOverImageButton** shows buttons with an image behind their text.

**Shortcuts** shows a shortcut button, used to choose another button's
shortcut.

**Tooltips** shows the tooltip settings, and a widget with a different tooltip
on each half.

**Presets** shows each class of slider, dial and counter, moving together.

**Positions** shows a positioner, whose two values set a clock.

**Clock** shows the two clock widgets, square and round, in two windows.

**ProgressSimple** shows a progress bar during a long job in a callback,
letting FLTK redraw as it goes.

**ChartSimple** shows a sine wave as a chart, of a kind you choose.

## Layout

**GridSimple** shows a 3x3 grid of buttons, laid out by `Fl_Grid`.

**FlexSimple** shows a row of buttons laid out by `Fl_Flex`.

**TabsSimple** shows two tabs of colored buttons.

**WizardSimple** shows `Fl_Wizard`: three pages, with Back, Next and Finish.

**DraggableGroup** shows a group extended so that the right mouse button drags
its children, keeping their order.

## Menus

**Menus** shows a menu bar, a choice and FLTK's common dialogs together.

**MenubarAdd** shows a menu bar's items added one by one, each with an action
that reports what was picked.

**MenuBar** shows every kind of menu item, in a menu bar, a menu button, a
choice and a pop-up, with what is picked written to a terminal.

**MenuWithImages** shows menu items with images, alone or beside their text.

**InputChoice** shows an input choice beside a plain choice, with what they do
written to a terminal.

## Text

**TextEditorSimple** shows the smallest text editor: an editor and its buffer.

**TextDisplayWithColors** shows a text display with a color for each line,
using a style buffer.

**TextEditorWithDynamicColors** shows styles kept up as text changes: digits
are colored as they are typed.

**Selections** shows a text buffer's three selections, primary, secondary and
highlight, and how a buffer tells the program of changes through `Modified`.

**FileInputs** shows a file input, which shows a path's directories as buttons
that cut it back.

**RemapNumpadKeyboardKeys** shows the event dispatch seeing every key first,
here to make the keypad type digits whatever NumLock says.

**Utf8Test** shows Unicode in inputs and labels, and the first 65536
characters in a scrolling window.

**SimpleTerminal** shows `Fl_Terminal` used for a program's status messages.

**Console** shows `Fl_Terminal` holding the output of commands typed in a line
below it, with their colors.

**AddFdAndPopen** shows `Fl.WatchFd`: a slow command's output comes into a
browser as it arrives, and the window takes events meanwhile.

## Browsers

**BrowserSimple** shows a hold browser and a multi browser, and reading what
was picked.

**BrowserWithIcons** shows icons on a browser's lines.

## Trees

**TreeSimple** shows a tree and its callback, which reports selections.

**TreeIcons** shows a tree's icons, for the whole tree and for one item, and
the margins around them.

**TreeCustomSort** shows a tree's items sorted by number, using
`SwapChildren`.

**TreeCustomDrawItems** shows a `TreeItem` extended to draw itself, with a
timer keeping it up to date.

**TreeAsContainer** shows widgets held in a tree's items.

**TreeOfTables** shows tables held in a tree's items.

## Tables

**TableSimple** shows the smallest table: numbers, drawn cell by cell.

**TableAsContainer** shows a table whose cells are widgets.

**TableWithKeynav** shows cells selected with the mouse or the keys, and the
sum of those selected.

**TableWithRightClickMenu** shows a menu popped up over a table's cells.

**TableWithRightColumnStretchFit** shows a table whose last column fills the
space left.

**TableSort** shows a directory listing sorted by the column heading clicked.

**TableSpreadsheet** shows a spreadsheet with totals, in which Tab moves
between cells.

**TableSpreadsheetWithKeyboardNav** shows a spreadsheet edited with the mouse
or the keys.

## Dialogs and file choosers

**NativeFileChooserSimple** shows the desktop's file chooser, opened from a
pop-up menu.

**NativeFileChooserSimpleApp** shows the native file chooser in a small
application, for File/Open, Save and Save As.

**FileChooser** shows every way of asking FLTK's file chooser for files, with
its previews and its callback.

**ColorChooser** shows the two ways of asking for a color, and drawing with
colors.

**HelpDialog** shows a help file in FLTK's own help window.

**HelpPages** shows a help view whose pages are kept in the program, followed
by its `Link` method.

## Drawing

**Rects** shows `Fl.Rect`, laying out a `Draw` by arithmetic on rectangles.

**Boxtype** shows every box and frame type, under each scheme.

**Symbols** shows every symbol a label can show, turned and sized by sliders.

**Fonts** shows every font the system has, at its sizes, and an editor of
FLTK's vector fonts.

**CursorTest** shows FLTK's standard cursors, and one made by the program.

**DoubleBuffer** shows why double buffering matters: one star drawn in a
single-buffered window and in a double-buffered one.

**Offscreen** shows drawing on an offscreen picture bigger than the window,
which the mouse drags.

**Overlay** shows a window's overlay: a red box resized by four buttons.

**ShapedWindow** shows a round window with a hole in it, moved by dragging.

**DragAndDrop** shows text dragged from one window to another, and the events
the receiver gets.

**Mandelbrot** shows slow drawing done while the program is idle: the
Mandelbrot set and its Julia sets, a line at a time.

## Images

**Bitmap** shows a bitmap on a button, placed by its label's alignment.

**Icons** shows images FLTK reads and shares: an XBM file, a bitmap made in
the program, each size in an ICO, and one image on many buttons.

**SvgSimple** shows an SVG image, decoded from memory, as a box's image.

**PixmapBrowser** shows image files chosen with a preview, and prints the
window or saves it as SVG.

**AnimGifImageSimple** shows an animated GIF played in a box.

**AnimGifImageResize** shows an animated GIF copied to its canvas's size as
the window is resized.

**AnimGifImagePlay** shows a program playing an animated GIF itself, frame by
frame, with keys for its speed and direction.

**AnimGifImage** shows animated GIFs each in a window, with the variations
`Fl_Anim_GIF_Image` allows, chosen by flags, and is FLTK's test of them.

## Printing and saving

**SaveAs** shows one procedure drawing a picture in the window and in a
PostScript, EPS, PDF or SVG file.

**Device** shows a window of drawings copied to an image surface, the clipboard,
a printer or a file, captured from the screen, or shown through a mask, as the
user chooses.

## Plugins

**Plugins** shows plugins found by their class, so that the program knows only
the class and not the plugins.

## Forms

These need `pofltk-forms`, and aren't built on an FLTK without Forms.

**Forms** shows every kind of widget the Forms library has, and a choice of box
types.

**FreeForm** shows a Forms free object, which hears mouse, drawing and step
events through one method: it traces the mouse with a line that shortens by
itself.

## OpenGL

These need `pofltk-gl`, and aren't built on an FLTK without GL. The last two
also need GLEW.

**Cube** shows two spinning cubes in GL windows, a wire one and a flat one,
beside FLTK's widgets.

**GlOverlay** shows a polygon drawn with GL, and another drawn over it in the
overlay.

**GlutCube** shows `FlGlut`: a GLUT window that sits beside FLTK's widgets, with
GLUT's timer, mouse, menu and key callbacks.

**GlutTest** shows nothing on the screen. It calls GLUT's functions with a
current window and without one, and ends by itself.

**OpenGL3Test** shows a quad drawn by OpenGL 3 shaders under FLTK's buttons.

**OpenGL3GlutTest** shows two triangles drawn by OpenGL 3 shaders, through
GLUT.

## Cairo

These need `pofltk-cairo`, and aren't built without cairo.

**CairoDrawX** shows the smallest cairo window: an X across it.

**CairoTest** shows cairo drawing three shiny buttons and a title.

## Modules that aren't programs

`Pipe.Mod` and `Pipe.cpp` are a module the examples share, for reading a
command's output as it comes (`popen`). Running a command isn't FLTK's, so it
isn't part of pofltk. `GlThree.Mod` and `GlThree.cpp` hold GLEW and the OpenGL 3
code of the last two OpenGL examples.
