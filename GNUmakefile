# pofltk -- Oberon-2 binding to FLTK 1.4 for poc, the Peaseblossom Oberon
# Compiler.  See AGENTS.md and PLAN.md.
#
# The binding is built as the poc library pofltk (-OC), in $(BUILD)/lib,
# recording -lfltk_images -lfltk in its manifest; a module's C++ part,
# src/<Module>.cpp, is compiled by clang++ and goes in it. Each optional
# part of FLTK that needs a library of its own has a poc library of its
# own, importing pofltk, as pofltk-forms does, so only a program using it
# is linked with FLTK's. The tests and examples are built on those
# libraries, so they test what make install installs. A program with a
# C++ part is linked by clang++. What poc writes for a program - each
# module's .sym, .ll and .o, and the program - goes into $(BUILD), so make
# must not build two at once.
#
# make install copies the libraries FLTK has into $(POCLIBDIR),
# ~/.local/lib/poc by default, with and without debug information. poc
# puts each in <triple>/<variant>/ there. A program using them needs only
# -library-path $(POCLIBDIR): no FLTK or C++ flags.
# All this needs poc 0.4.1: C++ parts, libraries that record link flags,
# and ORD of a SET under -OC.

POC      ?= poc
PREFIX ?= $(HOME)/.local
POCLIBDIR ?= $(PREFIX)/lib/poc
# The size model: decided in PLAN.md; never mix models.
POCFLAGS := -OC
MODELS := OC
VARIANTS := $(MODELS) $(addsuffix -g,$(MODELS))

# An installed library on POC_LIBRARY_PATH would be taken in place of this
# checkout's source, or would stop the build if another poc wrote it.
unexport POC_LIBRARY_PATH

VALGRIND ?= valgrind --leak-check=full --show-leak-kinds=all --errors-for-leak-kinds=none --error-exitcode=99 --suppressions=$(CURDIR)/test/poc-gc.supp --suppressions=$(CURDIR)/test/display.supp
# Seconds a test may run before it counts as hung.
TIMEOUT  ?= 60
EXAMPLETIME ?= 3

BUILD := build

# Where it isn't on PATH, a system with its own FLTK has it under
# /usr/local/sw/versions/fltk.
FLTK_CONFIG ?= $(firstword $(shell command -v fltk-config 2>/dev/null) \
                 $(wildcard /usr/local/sw/versions/fltk/*/bin/fltk-config))
ifeq ($(strip $(FLTK_CONFIG)),)
  $(error no fltk-config on PATH or in /usr/local/sw/versions/fltk; give FLTK_CONFIG=...)
endif
# Only the -I and -D flags: the rest of --cxxflags is the distribution's
# own build flags (Fedora's -specs=... hardening files among them). Not
# -I/usr/include, which is searched anyway, and which ahead of the C++
# library's own directories breaks its #include_next.
FLTK_CXXFLAGS := $(filter-out -I/usr/include,$(filter -I% -D%,$(shell $(FLTK_CONFIG) --cxxflags)))
FLTK_LIBS_ALL := $(shell $(FLTK_CONFIG) --use-images --ldflags)
# Without a plain -lpng beside a versioned one (-lpng16): pkgsrc's
# fltk-config names both, and pkgsrc installs only libpng16
# (doc/fltk-issues.md, 71).
FLTK_LIBS     := $(if $(filter -lpng1%,$(FLTK_LIBS_ALL)),$(filter-out -lpng,$(FLTK_LIBS_ALL)),$(FLTK_LIBS_ALL))
# What FLTK has that needs a library of its own makes an optional part,
# with sources in src/<part>/. fl_config.h says so for Forms. For OpenGL
# it says nothing, and FLTK installs GL's headers without GL, and
# fltk-config names libfltk_gl, so that library's being there decides.
FLTK_CONFIG_H := $(shell $(FLTK_CONFIG) --includedir)/FL/fl_config.h
HAVE_FORMS    := $(shell grep -q 'define FLTK_HAVE_FORMS 1' $(FLTK_CONFIG_H) && echo yes)
FLTK_LIBDIR   := $(dir $(firstword $(shell $(FLTK_CONFIG) --libs)))
HAVE_GL       := $(if $(wildcard $(FLTK_LIBDIR)libfltk_gl.*),yes)
# A library's shared object can't hold an FLTK of static libraries, and a
# library with one can't need a library without, so this goes to all four.
# POC_LIBRARY_FLAGS= tries the shared link regardless.
POC_LIBRARY_FLAGS ?= $(if $(wildcard $(FLTK_LIBDIR)libfltk.so*),,-no-shared-library)
# X11's own directories, which fltk-config leaves out: needed where X11
# is outside the compiler's search path (OpenBSD's /usr/X11R6), empty
# where it is not or pkg-config isn't there.
X11_CXXFLAGS  := $(shell pkg-config --cflags-only-I x11 2>/dev/null)
X11_LIBS      := $(shell pkg-config --libs-only-L x11 2>/dev/null)
# C++11, as FLTKAda's shim is, so code can move between them.
CXXFLAGS      := -std=c++11 -Wall -Wextra -Werror

POC_VERSION := $(shell $(POC) -version | sed -n 's/^poc \([0-9.]*\).*/\1/p')
# The case patterns are written (pattern) so make sees balanced parentheses.
ifeq ($(shell case "$(POC_VERSION)" in (0.[0-3].*|0.4.0) echo old;; esac),old)
  $(error pofltk needs poc 0.4.1 or later (C++ parts, libraries' link flags, ORD of a SET); $(POC) is $(POC_VERSION))
endif
ifneq ($(filter -no-shared-library,$(POC_LIBRARY_FLAGS)),)
  ifeq ($(shell case "$(POC_VERSION)" in (0.[0-9].*|0.10.*) echo old;; esac),old)
    $(error this FLTK is static, which needs poc 0.11.0 or later (-no-shared-library); $(POC) is $(POC_VERSION))
  endif
endif

MODULES := Fl FlDraw FlButtons FlInputs FlValuators FlLayout FlMenus FlDialogs FlText FlBrowsers FlImages FlPreferences FlTable FlHelp FlTerminal FlPrint FlUtf8
HEADERS := src/pofltk.h
LIBSRC  := $(MODULES:%=src/%.Mod) $(MODULES:%=src/%.cpp) $(HEADERS)
# Test modules with a C++ part (test/<Module>.cpp).
TESTCXX := BreakCairo CCairoConstants CConstants CFormsConstants CGlConstants CGluConstants CGlutConstants Probe
TESTSRC := $(TESTCXX:%=test/%.Mod) $(TESTCXX:%=test/%.cpp)
# Example modules, not programs, with a C++ part (examples/<Module>.cpp).
EXAMPLECXX := Pipe
# Example modules without a C++ part, imported by examples.
EXAMPLEMODS := ResizeArrows BlocksPixmaps CheckersPieces
EXAMPLESRC := $(EXAMPLECXX:%=examples/%.Mod) $(EXAMPLECXX:%=examples/%.cpp) $(EXAMPLEMODS:%=examples/%.Mod)

CFLAGS := $(foreach f,$(FLTK_CXXFLAGS) $(X11_CXXFLAGS) $(CXXFLAGS),-c-flag $(f))
LINK   := $(CFLAGS) $(foreach f,$(X11_LIBS) $(FLTK_LIBS),-link $(f))

# Each library is built in a directory of its own, and all are installed
# in one, $(POCLIBDIR).
LIBRARY := pofltk
LIBDIR  := $(BUILD)/lib
FORMSLIBRARY := pofltk-forms
FORMSLIBDIR  := $(BUILD)/lib-forms
GLLIBRARY := pofltk-gl
GLLIBDIR  := $(BUILD)/lib-gl
CAIROLIBRARY := pofltk-cairo
GLULIBRARY := pofltk-glu
GLULIBDIR  := $(BUILD)/lib-glu
CAIROLIBDIR  := $(BUILD)/lib-cairo

# $(call variant-flags,<variant>) gives poc's flags for a variant: OC-g gives
# -OC -g.
variant-flags = -$(firstword $(subst -, ,$(1))) $(if $(filter %-g,$(1)),-g)

# A library records the poc that built it, and another poc refuses it, so
# each library depends on poc itself: its file, for a poc rebuilt in place,
# and POCID, the version poc gives, since a package keeps its build's date
# (Fedora's 0.11.2 was dated before the libraries 0.11.1 had built, so
# make built nothing again, 2026-11-07). POCID is written only when the
# version changes.
POCBIN := $(shell command -v $(POC))
POCID  := $(BUILD)/poc-version
POC_ID := $(shell $(POC) -version | sed -n 1p)

# Test programs (test/<name>.Mod, each a main module).
TESTS := TestLiveness TestDelete TestTimer TestConstants TestWidget TestDraw TestDrawMore TestStatics TestEvents TestButtons TestInputs TestValuators TestLayout TestMenus TestDialogs TestText TestBrowsers TestTree TestImages TestClipboard TestPreferences TestTable TestArgs TestLoop TestTreeItems TestChart TestAnimGIF TestFeatures TestRect TestTracker TestTooltips TestOverlay TestImageFiles TestShared TestFileIcons TestFileChooser TestHelp TestImageHandlers TestTerminal TestPrint TestPlugins TestUtf8 TestKeys
# TestArgs's command line: options of its own and FLTK's, and words that
# aren't options.
TESTARGS := -o hello --help -g 120x80 -ti Title -s plastic -nokbd rest more
# Programs that must halt (test/<name>.Mod), as name:ASSERT-code. poc's
# ASSERT(x, n) prints "assertion failed (n)" on standard error and exits
# with status 10, so `make test` requires both.
HALTTESTS := HaltCursorTiled:78 HaltCursorHot:74 HaltFrame:74 HaltArrow:74 HaltDrawImage:74 HaltOverlay:77 HaltScroll:77 HaltAntialias:77 HaltMakeCurrent:77 HaltOffscreenCopy:77 HaltAbort:42 HaltFontNumber:74 HaltFontGap:74 HaltFontFrom:74 HaltGetBoxtype:74 HaltContrastMode:74 HaltGrabHidden:77 HaltHandleEvent:77 HaltScreenDPI:74 HaltScreenNum:74 HaltReleaseColor:74 HaltNotOpen:70 HaltDeleted:70 HaltOpenTwice:71 HaltNil:72 HaltIndex:74 HaltRepeat:75 HaltGridRange:74 HaltNotAChild:76 HaltMenuItem:74 HaltClosedBuffer:73 HaltNoBuffer:73 HaltBrowserLine:74 HaltTreeItem:73 HaltClosedImage:73 HaltSurfaceOrder:77 HaltClosedGroup:73 HaltTableRow:74 HaltBoxType:74 HaltMultiLabel:78 HaltHandleDefault:75 HaltAddItem:71 HaltChartEntry:74 HaltShapeTiled:78 HaltAnimFrame:78 HaltClockTime:78 HaltSchemeName:74 HaltTrackNil:72 HaltDrawChild:76 HaltChoiceItem:74 HaltColorMode:74 HaltBitmapBits:74 HaltBitmapShape:78 HaltSharedCopy:78 HaltShareBitmap:78 HaltIconWindow:78 HaltChooserClosed:73 HaltChooserFilter:74 HaltHelpImage:77 HaltHelpDialogClosed:73 HaltHandlerNil:72 HaltHandlerClosed:73 HaltTerminalSize:78 HaltTerminalCells:78 HaltTerminalTextSize:78 HaltTerminalErrorChar:78 HaltTerminalPlot:74 HaltTerminalStyle:74 HaltTerminalCell:74 HaltPrintOrder:77 HaltPrintPage:77 HaltPrintUntranslate:77 HaltPrintShift:77 HaltPrintNesting:77 HaltPrintImage:77 HaltPrintUnderImage:77 HaltPrintScale:78 HaltPrintFormat:78 HaltPrintClosed:73 HaltPrintTwice:71 HaltPrintSize:74 HaltPrintText:74 HaltPluginTwice:71 HaltPluginName:74 HaltPluginAt:74 HaltPluginManager:70 HaltUtf8Offset:74 HaltImageInLine:77 HaltDashLong:74 HaltDashValue:74 HaltMaskBegun:77 HaltMaskTwice:77 HaltMaskDepth:78 HaltKeyFunction:74 HaltPopup:73 HaltLineNumberFormat:78 HaltInputIndex:74 HaltLabelMargin:74
ASSERTSTATUS := 10

# Example programs (examples/<name>.Mod). They wait for the user, so make
# builds them and make test doesn't run them.
EXAMPLES := Hello Scribble Swatch Menus TableSimple TreeSimple TextEditorSimple BrowserSimple GridSimple FlexSimple TabsSimple WizardSimple ProgressSimple NativeFileChooserSimple SvgSimple Callbacks DrawAnX TextOverImageButton DragAndDrop TableAsContainer TableWithKeynav TableWithRightClickMenu TableWithRightColumnStretchFit TableSpreadsheetWithKeyboardNav TextDisplayWithColors TextEditorWithDynamicColors NativeFileChooserSimpleApp DraggableGroup TableSpreadsheet TreeCustomSort BrowserWithIcons MenuWithImages MenubarAdd ParseArgs AddFdAndPopen RemapNumpadKeyboardKeys TableSort TreeAsContainer TreeOfTables TreeCustomDrawItems ChartSimple ShapedWindow AnimGifImageSimple AnimGifImageResize AnimGifImagePlay AnimGifImage Clock DoubleBuffer Presets Positions Shortcuts FileInputs Tooltips Rects Trackers Overlay ColorChooser InputChoice MenuBar TreeIcons Selections Bitmap Icons FileChooser HelpDialog HelpPages SimpleTerminal Console Device PixmapBrowser SaveAs Plugins Boxtype Symbols CursorTest Offscreen Fonts Mandelbrot Utf8Test Adjuster Ask Browser Button Buttons ColBrowser FastSlow Iconize Inactive Input Message Minimum NativeFileChooser Navigation Output Pack Radio Resize ResizeBox Scroll Tabs Tile TwoWin Valuators WindowFocus Wizard ResizeExample1 ResizeExample2 ResizeExample3a ResizeExample3b ResizeExample3c ResizeExample4a ResizeExample4b ResizeExample5a ResizeExample5b ResizeExample5c FlexDemo FlexLogin GridAlignment GridButtons GridDialog GridLogin FltkVersions Animated Arc Clipboard Contrast Coordinates Curve Icon Image Label LineStyle LineStyleDocs Pixmap RotatedText TiledImage HandleKeys Keyboard Subwindow Editor Preferences Table Tree HandleEvents Blocks Checkers Sudoku Unittests Terminal Demo
# The command line an example is given by make test, as name=argument,
# from examples/: those that need a file.
EXAMPLEARGS := AnimGifImagePlay=../test/images/anim.gif AnimGifImageResize=../test/images/anim.gif Demo=Demo.menu
# The examples that write FLTK's preferences: make test gives them
# XDG_CONFIG_HOME in build/, with fltk.org made there, so they never write
# the user's own (FLTK goes to ~/.fltk when that directory isn't there).
EXAMPLEPREFS := Preferences Blocks Sudoku
# Examples that wait for no one, and end by themselves.
EXAMPLEONCE := GlutTest

# FlForms needs libfltk_forms: these programs are linked with it, and are
# left out without it (PLAN.md, Phase 20). A program can't adapt to the
# library as it runs: using FlForms where it is missing fails as it builds.
FORMSTESTS := TestForms TestFormsConstants
FORMSHALTS := HaltFormsTimerKind:74 HaltFormsFreeKind:74 HaltFormsBitmap:78 HaltFormsPixmap:78
FORMSEXAMPLES := Forms FreeForm
FORMSSRC := src/forms/FlForms.Mod src/forms/FlForms.cpp
FORMSUSE := -library-path $(FORMSLIBDIR)
ifeq ($(HAVE_FORMS),yes)
  OPTIONAL += $(FORMSLIBRARY)
  TESTS += $(FORMSTESTS)
  HALTTESTS += $(FORMSHALTS)
  EXAMPLES += $(FORMSEXAMPLES)
else
  MISSING += Forms
endif

# FlGl and FlGlut need libfltk_gl and GL, likewise (PLAN.md, Phase 21).
GLTESTS := TestGl TestGlConstants TestGlut TestGlutConstants
GLHALTS := HaltGlutBitmapFont:74 HaltGlutStrokeFont:74 HaltGlutBitmapText:77 HaltGlutStrokeText:77 HaltGlMakeCurrent:77 HaltGlFont:77 HaltGlStart:77 HaltGlSetMode:77 HaltGlutWindow:74 HaltGlutWindows:78 HaltGlutMenu:74 HaltGlutSubMenu:77 HaltGlutEmptyMenu:77 HaltGlutMenuNil:72 HaltGlTexturePile:78 HaltGlSelectBuffer:77 HaltGlutShape:74 HaltGlDrawBegin:77
GLEXAMPLES := Cube GlOverlay GlutTest GlutCube Shape Fullscreen CubeView
GLSRC := src/gl/FlGl.Mod src/gl/FlGl.cpp src/gl/FlGlut.Mod src/gl/FlGlut.cpp
# fltk-config says which GL libraries, on some systems. A static FLTK with
# Wayland needs EGL's too.
GL_LIBS := $(or $(filter -lGL% -lOpenGL -lEGL -lwayland-egl,$(shell $(FLTK_CONFIG) --use-gl --ldflags)),-lGL)
GLUSE := -library-path $(GLLIBDIR)
# FLTK's OpenGL 3 examples load GL's functions with GLEW, which isn't FLTK's.
GL3EXAMPLES := OpenGL3Test OpenGL3GlutTest
HAVE_GLEW := $(shell pkg-config --exists glew 2>/dev/null && echo yes)
GLEW_FLAGS := $(addprefix -c-flag ,$(shell pkg-config --cflags glew 2>/dev/null)) $(addprefix -link ,$(shell pkg-config --libs glew 2>/dev/null))
ifeq ($(HAVE_GL),yes)
  ifeq ($(HAVE_GLEW),yes)
    EXAMPLES += $(GL3EXAMPLES)
    EXAMPLESRC += examples/GlThree.Mod examples/GlThree.cpp
  else
    MISSING += GLEW
  endif
  OPTIONAL += $(GLLIBRARY)
  TESTS += $(GLTESTS)
  HALTTESTS += $(GLHALTS)
  EXAMPLES += $(GLEXAMPLES)
else
  MISSING += OpenGL
endif
# FlGlu needs GLU, which is neither FLTK's nor GL's, and FlGl to be any use.
GLUTESTS := TestGlu TestGluConstants
GLUHALTS := HaltGluClosed:73 HaltGluPickMatrix:74
GLUEXAMPLES := Fractals GlPuzzle
GLUSRC := src/glu/FlGlu.Mod src/glu/FlGlu.cpp
HAVE_GLU := $(if $(HAVE_GL),$(shell pkg-config --exists glu 2>/dev/null && echo yes))
GLU_CFLAGS := $(addprefix -c-flag ,$(shell pkg-config --cflags glu 2>/dev/null))
GLU_LIBS := $(shell pkg-config --libs glu 2>/dev/null)
GLUUSE := $(GLUSE) -library-path $(GLULIBDIR) $(GLU_CFLAGS)
ifeq ($(HAVE_GLU),yes)
  OPTIONAL += $(GLULIBRARY)
  TESTS += $(GLUTESTS)
  HALTTESTS += $(GLUHALTS)
  EXAMPLES += $(GLUEXAMPLES)
else
  MISSING += GLU
endif
# FlCairo needs cairo, with X11's surface where FLTK has X11, not an FLTK
# built for it (PLAN.md, Phase 22).
CAIROTESTS := TestCairo TestCairoConstants
CAIROHALTS := HaltCairoStale:77 HaltCairoClosed:73 HaltCairoNil:72 HaltCairoExtend:74 HaltCairoAntialias:74 HaltCairoSlant:74
CAIROEXAMPLES := CairoDrawX CairoTest
CAIROSRC := src/cairo/FlCairo.Mod src/cairo/FlCairo.cpp
CAIRO_PKGS := cairo $(shell grep -q 'define FLTK_USE_X11 1' $(FLTK_CONFIG_H) && echo cairo-xlib)
HAVE_CAIRO := $(shell pkg-config --exists $(CAIRO_PKGS) 2>/dev/null && echo yes)
CAIRO_CFLAGS := $(addprefix -c-flag ,$(shell pkg-config --cflags $(CAIRO_PKGS) 2>/dev/null))
CAIRO_LIBS := $(shell pkg-config --libs $(CAIRO_PKGS) 2>/dev/null)
CAIROUSE := -library-path $(CAIROLIBDIR) $(CAIRO_CFLAGS)
ifeq ($(HAVE_CAIRO),yes)
  OPTIONAL += $(CAIROLIBRARY)
  TESTS += $(CAIROTESTS)
  HALTTESTS += $(CAIROHALTS)
  EXAMPLES += $(CAIROEXAMPLES)
else
  MISSING += Cairo
endif

TESTBINS := $(TESTS:%=$(BUILD)/%)
HALTBINS := $(foreach h,$(HALTTESTS),$(BUILD)/$(firstword $(subst :, ,$(h))))
EXAMPLEBINS := $(EXAMPLES:%=$(BUILD)/%)

.PHONY: all tests test valgrind test-headless valgrind-headless test-sway valgrind-sway install uninstall clean display FORCE
.NOTPARALLEL:

all: tests

tests: $(TESTBINS) $(HALTBINS) $(EXAMPLEBINS)

$(BUILD):
	mkdir -p $@

$(POCID): FORCE | $(BUILD)
	@echo '$(POC_ID)' | cmp -s - $@ || echo '$(POC_ID)' > $@

FORCE:

# TestPlugins loads shared libraries, which find FLTK in the program.
$(BUILD)/plugins:
	mkdir -p $@

$(BUILD)/TestPlugins: MORE := -link -rdynamic
$(BUILD)/TestPlugins: $(BUILD)/plugins/one.so $(BUILD)/plugins/two.so
$(BUILD)/plugins/%.so: test/CPlugin.cpp | $(BUILD)/plugins
	clang++ $(FLTK_CXXFLAGS) $(X11_CXXFLAGS) $(CXXFLAGS) -DPLUGIN='"$*"' -fPIC -shared -o $@ $<

FORMSPROGRAMS := $(FORMSTESTS:%=$(BUILD)/%) $(FORMSEXAMPLES:%=$(BUILD)/%) $(foreach h,$(FORMSHALTS),$(BUILD)/$(firstword $(subst :, ,$(h))))
$(FORMSPROGRAMS): MORE := $(FORMSUSE)
$(FORMSPROGRAMS): $(FORMSLIBDIR)/$(FORMSLIBRARY)-OC.stamp
GLPROGRAMS := $(GLTESTS:%=$(BUILD)/%) $(GLEXAMPLES:%=$(BUILD)/%) $(foreach h,$(GLHALTS),$(BUILD)/$(firstword $(subst :, ,$(h))))
$(GLPROGRAMS): MORE := $(GLUSE)
$(GLPROGRAMS): $(GLLIBDIR)/$(GLLIBRARY)-OC.stamp
$(GL3EXAMPLES:%=$(BUILD)/%): MORE := $(GLUSE) $(GLEW_FLAGS)
$(GL3EXAMPLES:%=$(BUILD)/%): $(GLLIBDIR)/$(GLLIBRARY)-OC.stamp
CAIROPROGRAMS := $(CAIROTESTS:%=$(BUILD)/%) $(CAIROEXAMPLES:%=$(BUILD)/%) $(foreach h,$(CAIROHALTS),$(BUILD)/$(firstword $(subst :, ,$(h))))
$(CAIROPROGRAMS): MORE := $(CAIROUSE)
$(CAIROPROGRAMS): $(CAIROLIBDIR)/$(CAIROLIBRARY)-OC.stamp
GLUPROGRAMS := $(GLUTESTS:%=$(BUILD)/%) $(GLUEXAMPLES:%=$(BUILD)/%) $(foreach h,$(GLUHALTS),$(BUILD)/$(firstword $(subst :, ,$(h))))
$(GLUPROGRAMS): MORE := $(GLUUSE)
$(GLUPROGRAMS): $(GLLIBDIR)/$(GLLIBRARY)-OC.stamp $(GLULIBDIR)/$(GLULIBRARY)-OC.stamp

# Unittests' pages are modules of examples/unittests, and its OpenGL
# windows are UtGl's: unittests/gl's where FLTK has GL, unittests/nogl's,
# which has none, where it hasn't.
UTGL := $(if $(HAVE_GL),gl,nogl)
$(BUILD)/Unittests: MORE += -import-path examples/unittests -import-path examples/unittests/$(UTGL) $(if $(HAVE_GL),$(GLUSE))
$(BUILD)/Unittests: $(wildcard examples/unittests/*.Mod) examples/unittests/$(UTGL)/UtGl.Mod $(if $(HAVE_GL),$(GLLIBDIR)/$(GLLIBRARY)-OC.stamp)

# The libraries, one stamp for each variant. FLTK's -link flags go in the
# manifest. An optional part imports pofltk, so it is built again with it.
PARTLINK := $(foreach f,$(X11_LIBS) $(filter -L%,$(FLTK_LIBS)),-link $(f))

$(LIBDIR)/$(LIBRARY)-%.stamp: $(LIBSRC) $(POCBIN) $(POCID) | $(BUILD)
	mkdir -p $(LIBDIR)
	cd src && $(POC) $(call variant-flags,$*) $(POC_LIBRARY_FLAGS) -output-dir $(abspath $(LIBDIR)) $(LINK) \
	  -library $(LIBRARY) $(MODULES:%=%.Mod)
	touch $@

$(FORMSLIBDIR)/$(FORMSLIBRARY)-%.stamp: $(FORMSSRC) $(LIBDIR)/$(LIBRARY)-%.stamp
	mkdir -p $(FORMSLIBDIR)
	cd src/forms && $(POC) $(call variant-flags,$*) $(POC_LIBRARY_FLAGS) -library-path $(abspath $(LIBDIR)) -output-dir $(abspath $(FORMSLIBDIR)) \
	  $(CFLAGS) $(PARTLINK) -link -lfltk_forms -library $(FORMSLIBRARY) FlForms.Mod
	touch $@

$(GLLIBDIR)/$(GLLIBRARY)-%.stamp: $(GLSRC) $(LIBDIR)/$(LIBRARY)-%.stamp
	mkdir -p $(GLLIBDIR)
	cd src/gl && $(POC) $(call variant-flags,$*) $(POC_LIBRARY_FLAGS) -library-path $(abspath $(LIBDIR)) -output-dir $(abspath $(GLLIBDIR)) \
	  $(CFLAGS) $(PARTLINK) $(foreach f,-lfltk_gl $(GL_LIBS),-link $(f)) -library $(GLLIBRARY) FlGl.Mod FlGlut.Mod
	touch $@

$(CAIROLIBDIR)/$(CAIROLIBRARY)-%.stamp: $(CAIROSRC) $(LIBDIR)/$(LIBRARY)-%.stamp
	mkdir -p $(CAIROLIBDIR)
	cd src/cairo && $(POC) $(call variant-flags,$*) $(POC_LIBRARY_FLAGS) -library-path $(abspath $(LIBDIR)) -output-dir $(abspath $(CAIROLIBDIR)) \
	  $(CFLAGS) $(CAIRO_CFLAGS) $(PARTLINK) $(CAIRO_LIBS:%=-link %) -library $(CAIROLIBRARY) FlCairo.Mod
	touch $@

$(GLULIBDIR)/$(GLULIBRARY)-%.stamp: $(GLUSRC) $(LIBDIR)/$(LIBRARY)-%.stamp
	mkdir -p $(GLULIBDIR)
	cd src/glu && $(POC) $(call variant-flags,$*) $(POC_LIBRARY_FLAGS) -library-path $(abspath $(LIBDIR)) -output-dir $(abspath $(GLULIBDIR)) \
	  $(CFLAGS) $(GLU_CFLAGS) $(PARTLINK) $(foreach f,$(GLU_LIBS) $(GL_LIBS),-link $(f)) -library $(GLULIBRARY) FlGlu.Mod
	touch $@

# The -I and -D flags go on for the C++ parts of test and example modules.
USELIB = -library-path $(LIBDIR) $(MORE) $(CFLAGS)

$(BUILD)/Test%: test/Test%.Mod test/Check.Mod $(LIBDIR)/$(LIBRARY)-OC.stamp $(TESTSRC) | $(BUILD)
	$(POC) $(POCFLAGS) -import-path test -output-dir $(BUILD) $(USELIB) -o $@ $<

$(EXAMPLEBINS): $(BUILD)/%: examples/%.Mod $(LIBDIR)/$(LIBRARY)-OC.stamp $(EXAMPLESRC) | $(BUILD)
	$(POC) $(POCFLAGS) -import-path examples -output-dir $(BUILD) $(USELIB) -o $@ $<

$(BUILD)/Halt%: test/Halt%.Mod $(LIBDIR)/$(LIBRARY)-OC.stamp | $(BUILD)
	$(POC) $(POCFLAGS) -output-dir $(BUILD) $(USELIB) -o $@ $<

# FLTK needs a display even for widgets never shown (PLAN.md, "Build and
# test"): run under X11 or Wayland, or headless (test-headless and
# test-sway below).
display:
	@if [ -z "$$DISPLAY$$WAYLAND_DISPLAY" ]; then \
	  echo "pofltk's tests need a display: set DISPLAY or WAYLAND_DISPLAY, or use make test-headless or make test-sway"; exit 1; \
	fi

# Run every test from test/; report all, fail at the end if any failed.
# A halt test that can't run here says so with HALT(99).
# Each halt test must exit with poc's ASSERT status and name its code on
# standard error. Each example waits for the user, so it must still be
# running after EXAMPLETIME seconds, when timeout ends it (status 124):
# it started, drew, and didn't crash. One of EXAMPLEONCE waits for no one,
# and must end by itself, with status 0. Unittests also runs its own
# checks, with no window (--core, as FLTK's), which must pass.
test: tests display
	@status=0; skips=0; for t in $(TESTS); do \
	  echo "== $$t"; (cd test && timeout $(TIMEOUT) ../$(BUILD)/$$t $$(test $$t = TestArgs && echo $(TESTARGS))) > $(BUILD)/$$t.out 2>&1 || status=1; \
	  cat $(BUILD)/$$t.out; skips=$$((skips + $$(grep -c '^skip - ' $(BUILD)/$$t.out))); \
	done; \
	for h in $(HALTTESTS); do \
	  t=$${h%%:*}; code=$${h##*:}; echo "== $$t (must fail ASSERT code $$code)"; \
	  (cd test && timeout $(TIMEOUT) ../$(BUILD)/$$t) 2> $(BUILD)/$$t.err; got=$$?; \
	  if [ $$got -eq $(ASSERTSTATUS) ] && grep -q "assertion failed ($$code)" $(BUILD)/$$t.err; then \
	    echo "ok   - $$t: $$(cat $(BUILD)/$$t.err)"; \
	  elif [ $$got -eq 99 ]; then echo "skip - $$t: this FLTK lacks what it tests"; skips=$$((skips + 1)); \
	  else echo "FAIL - $$t exited with $$got: $$(cat $(BUILD)/$$t.err)"; status=1; fi; \
	done; \
	for e in $(filter $(EXAMPLEONCE),$(EXAMPLES)); do \
	  echo "== $$e (example: must end by itself)"; \
	  (cd examples && timeout $(TIMEOUT) ../$(BUILD)/$$e) > $(BUILD)/$$e.out 2>&1; got=$$?; \
	  if [ $$got -eq 0 ]; then echo "ok   - $$e"; \
	  else echo "FAIL - $$e exited with $$got: $$(cat $(BUILD)/$$e.out)"; status=1; fi; \
	done; \
	echo "== Unittests --core (example's own checks: must exit 0)"; \
	(cd examples && timeout $(TIMEOUT) ../$(BUILD)/Unittests --core) > $(BUILD)/Unittests-core.out 2>&1; got=$$?; \
	if [ $$got -eq 0 ]; then echo "ok   - Unittests --core"; \
	else echo "FAIL - Unittests --core exited with $$got: $$(cat $(BUILD)/Unittests-core.out)"; status=1; fi; \
	for e in $(filter-out $(EXAMPLEONCE),$(EXAMPLES)); do \
	  echo "== $$e (example: must still be running after $(EXAMPLETIME) s)"; \
	  args=$$(for a in $(EXAMPLEARGS); do test "$${a%%=*}" = $$e && echo "$${a#*=}"; done); \
	  envs=; case " $(EXAMPLEPREFS) " in *" $$e "*) \
	    mkdir -p $(CURDIR)/$(BUILD)/config/fltk.org; envs=XDG_CONFIG_HOME=$(CURDIR)/$(BUILD)/config;; esac; \
	  (cd examples && env $$envs timeout $(EXAMPLETIME) ../$(BUILD)/$$e $$args) > $(BUILD)/$$e.out 2>&1; got=$$?; \
	  if [ $$got -eq 124 ]; then echo "ok   - $$e"; \
	  else echo "FAIL - $$e exited with $$got: $$(cat $(BUILD)/$$e.out)"; status=1; fi; \
	done; \
	if [ $$skips -gt 0 ]; then echo "$$skips check(s) skipped: this FLTK lacks what they test."; fi; \
	$(if $(MISSING),echo "Not built (this system lacks them): $(MISSING)."; )\
	exit $$status

# Memory errors fail a test (--error-exitcode); leaks don't count as
# errors (--errors-for-leak-kinds=none), because FLTK's font cache and
# window decorations leak by design. test/vg-check.sh fails instead on any
# leaked block that pofltk allocated.
valgrind: tests display
	@status=0; for t in $(TESTS); do \
	  echo "== valgrind $$t"; \
	  (cd test && $(VALGRIND) --log-file=../$(BUILD)/$$t.vg ../$(BUILD)/$$t $$(test $$t = TestArgs && echo $(TESTARGS))) || status=1; \
	  grep -E 'ERROR SUMMARY' $(BUILD)/$$t.vg; \
	  test/vg-check.sh $(BUILD)/$$t.vg || { echo "FAIL - $$t: memory pofltk allocated was not freed"; status=1; }; \
	done; exit $$status

# The same, on a virtual X server (Xvfb), not the desktop. WAYLAND_DISPLAY
# is unset because FLTK prefers Wayland when it is set, even under
# xvfb-run, which sets only DISPLAY; without it FLTK uses X11 (confirmed,
# PLAN.md Phase 0).
test-headless: tests
	env -u WAYLAND_DISPLAY xvfb-run -a $(MAKE) test

valgrind-headless: tests
	env -u WAYLAND_DISPLAY xvfb-run -a $(MAKE) valgrind

# The same on Wayland, on a headless sway (tools/with-sway.sh): a compositor
# with no screen, so no window appears on the desktop, where the user's
# input could reach it.
test-sway: tests
	tools/with-sway.sh $(MAKE) test

valgrind-sway: tests
	tools/with-sway.sh $(MAKE) valgrind

# install copies each library, in each variant, into $(POCLIBDIR) with poc
# -install-library: the archive (with the C++ parts' objects), the shared
# object, the manifest, and each module's .sym and .owner. A library
# records the poc that built it, and another poc refuses it: install again
# after upgrading poc.
define newline


endef

# $(call install-library,<library>,<its build directory>,<variant>)
install-library = $(POC) $(call variant-flags,$(3)) -library-path $(LIBDIR) -library-path $(2) \
  -install-library $(1) -output-dir $(POCLIBDIR)$(newline)

INSTALLS := $(LIBDIR)/$(LIBRARY) \
  $(if $(filter $(FORMSLIBRARY),$(OPTIONAL)),$(FORMSLIBDIR)/$(FORMSLIBRARY)) \
  $(if $(filter $(GLLIBRARY),$(OPTIONAL)),$(GLLIBDIR)/$(GLLIBRARY)) \
  $(if $(filter $(CAIROLIBRARY),$(OPTIONAL)),$(CAIROLIBDIR)/$(CAIROLIBRARY)) \
  $(if $(filter $(GLULIBRARY),$(OPTIONAL)),$(GLULIBDIR)/$(GLULIBRARY))

install: $(foreach v,$(VARIANTS),$(INSTALLS:%=%-$(v).stamp))
	$(foreach v,$(VARIANTS),$(foreach i,$(INSTALLS),$(call install-library,$(notdir $(i)),$(dir $(i)),$(v))))

# uninstall removes from $(POCLIBDIR)/<triple>/<variant> what install put
# there, whichever parts this FLTK has. It leaves other libraries' files
# alone, and removes a directory only when nothing is left in it. The
# triple is poc's target.
library-files = $(1).library lib$(1).a lib$(1).so lib$(1).so.0.0
INSTALLED_FILES := $(foreach l,$(LIBRARY) $(FORMSLIBRARY) $(GLLIBRARY) $(CAIROLIBRARY) $(GLULIBRARY),$(call library-files,$(l))) \
  $(foreach m,$(MODULES) FlForms FlGl FlGlut FlCairo FlGlu,$(m).sym $(m).owner)

uninstall:
	@triple=$$($(POC) -version | sed -n 's/^target \([^ ]*\).*/\1/p'); \
	if [ -z "$$triple" ]; then echo "uninstall: cannot get the target from $(POC) -version" >&2; exit 1; fi; \
	for v in $(VARIANTS); do \
	  dir=$(POCLIBDIR)/$$triple/$$v; \
	  if [ -d "$$dir" ]; then \
	    echo "cd $$dir && rm -f $(INSTALLED_FILES)"; \
	    (cd "$$dir" && rm -f $(INSTALLED_FILES)) || exit 1; \
	    rmdir "$$dir" 2>/dev/null || :; \
	  fi; \
	done; \
	rmdir $(POCLIBDIR)/$$triple 2>/dev/null || :; \
	rmdir $(POCLIBDIR) 2>/dev/null || :

clean:
	rm -rf $(BUILD)
