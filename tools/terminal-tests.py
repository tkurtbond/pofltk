#!/usr/bin/env python3
"""Writes examples/terminal-tests.txt: the escape sequence tests of FLTK's
test/terminal.cxx, for examples/Terminal.Mod.

Each test is a line "=== name", then one line per element of its test[]
array: the element's string literals joined, their C escapes kept as
written (Terminal.Mod decodes them), so the file shows the tests as
FLTK's source does. The first page, test_firstpage, is one element.

Run it from the repository root, with FLTK's source:

    python3 tools/terminal-tests.py [path/to/fltk/test/terminal.cxx]
"""

import re
import sys

SOURCE = "/usr/local/sw/src/lang/C++/fltk/fltk-1.4.5/test/terminal.cxx"
OUTPUT = "examples/terminal-tests.txt"


def tokens(text):
    """The string literals, commas, parentheses and NULLs of text, with
    comments skipped."""
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if text.startswith("//", i):
            i = text.index("\n", i)
        elif text.startswith("/*", i):
            i = text.index("*/", i) + 2
        elif c == '"':
            j = i + 1
            while text[j] != '"':
                j += 2 if text[j] == "\\" else 1
            yield ("str", text[i + 1:j])
            i = j + 1
        elif c in ",();{}":
            yield (c, c)
            i += 1
        elif text.startswith("NULL", i):
            yield ("NULL", "NULL")
            i += 4
        else:
            i += 1


def elements(body):
    """The elements of a list of joined string literals, ending at NULL or
    the list's close."""
    out, cur = [], None
    for kind, val in tokens(body):
        if kind == "str":
            cur = (cur or "") + val
        elif kind in (",", ")", "NULL", "}"):
            if cur is not None:
                out.append(cur)
                cur = None
            if kind != ",":
                break
    return out


def main():
    src = open(sys.argv[1] if len(sys.argv) > 1 else SOURCE,
               encoding="utf-8").read()
    order = re.search(r"static TestFunc \*tests\[\] = \{(.*?)\};", src, re.S)
    names = re.findall(r"\b(test_\w+)", re.sub(r"//.*", "", order.group(1)))
    out = []
    for name in names:
        m = re.search(r"int Application::%s\(bool reset\) \{" % name, src)
        rest = src[m.end():]
        if name == "test_firstpage":
            body = rest[rest.index("AppendTty(") + len("AppendTty("):]
        else:
            body = rest[rest.index("test[] = {") + len("test[] = {"):]
        els = elements(body)
        for e in els:
            if "\n" in e:
                sys.exit("%s: a raw line feed in an element" % name)
        out.append("=== " + name)
        out.extend(els)
    with open(OUTPUT, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
    print("%s: %d tests, %d lines" % (OUTPUT, len(names), len(out)))


if __name__ == "__main__":
    main()
