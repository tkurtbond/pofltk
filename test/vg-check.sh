#!/bin/sh
# vg-check.sh LOG: succeed unless a loss record in the valgrind log LOG
# (from --leak-check=full --show-leak-kinds=all) is memory that pofltk
# allocated: a record whose allocator is pofltk's C++ part (ofl_
# functions, the ofl namespace, and the anonymous namespaces and statics
# of its .cpp files) or one of its Oberon modules (Fl, FlDraw, ...). Each
# one found is printed.
#
# The allocator is the first frame that is neither an allocation function
# (malloc, calloc, realloc, operator new or new[], demangled or mangled) nor
# a library function that allocates for its caller: strdup, strndup,
# asprintf and their kin, and the C++ standard library's templates
# (std::string, std::deque and the rest). Without that second rule an
# ofl_ function that leaked a strdup or a std::string was taken for libc's
# or libstdc++'s, and passed (2026-11-06, a scratch program leaking each
# way, at -O0 and -O2).
#
# A C++ part's own helpers have no prefix to know them by, so a frame in a
# program or library under build/ that isn't Oberon's Module.Proc is taken
# as one: C++ linked into the program is pofltk's, or a test's (Probe,
# CConstants), since FLTK is a shared library outside build/. poc's
# runtime (GarbageCollectedHeap and the rest) is Oberon, and allocates by
# design, so it passes. Where FLTK is static (cymoril and the others) there
# is no valgrind.
#
# FLTK's display stack leaks by design: a program that deletes every
# widget it made still shows about 390 KB "definitely lost" and thousands
# of records, all allocated by fontconfig and Pango's font cache, and under
# Wayland by GTK's window decorations (libdecor). Confirmed live,
# 2026-10-06, on a C++ program, both backends: PLAN.md, Phase 0. Their
# allocators are in those libraries or in libfltk, so they pass; a widget
# that pofltk made and never deleted is allocated by an ofl_ function, so it
# doesn't. (polibfyaml's test/vg-reachable.sh checks by allocator too.)
awk '
  / bytes in [0-9,]+ blocks are .* in loss record / { inrec = 1; seen = 0; rec = $0; next }
  inrec && /(at|by) 0x/ {
    if ($0 ~ /: (malloc|calloc|realloc|memalign|posix_memalign|aligned_alloc) \(/ ||
        $0 ~ /: (operator new|_Zn[wa][jmy])/) next
    if ($0 ~ /: (__)?(strn?dup|wcsdup|v?asprintf|getline|getdelim)[ (]/ ||
        $0 ~ /: __vasprintf_internal / ||
        $0 ~ /: (std::|__gnu_cxx::)/) next
    if (!seen) {
      seen = 1
      if ($0 ~ /: (ofl_|ofl::|Fl[A-Za-z]*\.)/ ||
          ($0 ~ /\(in [^)]*\/build\// && $0 !~ /: [A-Za-z][A-Za-z0-9]*\.[A-Za-z]/)) {
        print rec; print; bad = 1
      }
    }
    next
  }
  inrec && /^==[0-9]+== *$/ { inrec = 0 }
  END { exit bad }
' "$1"
