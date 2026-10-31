// The C++ part of FlUtf8: FLTK's UTF-8 functions, on Oberon's strings.
// See pofltk.h for the conventions.
//
// Many of FLTK's functions walk past the end they are given, on text
// that stops in a character (doc/fltk-issues.md, 115), and an Oberon
// string may fill its array, with no 0X. So each is given a copy with
// zeros on both sides (Text), and what it returns is kept within the
// text.

#include <FL/fl_utf8.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

namespace {

// Longer than any step of FLTK's, which is 2 of 6 bytes each.
const int pad = 16;

struct Text {
  char *block;
  char *s;
  int n;
  Text(intptr_t a, int32_t len)
      : block(static_cast<char *>(calloc(size_t(len) + 2 * pad, 1))),
        s(block ? block + pad : 0), n(block ? len : 0) {
    if (block) memcpy(s, reinterpret_cast<const char *>(a), size_t(len));
  }
  ~Text() { free(block); }
  bool ok() const { return block != 0; }
  int32_t within(const char *p) const {
    return p < s ? 0 : p > s + n ? n : int32_t(p - s);
  }

 private:
  Text(const Text &);
  Text &operator=(const Text &);
};

// Copies what fits of `from`, n bytes, to the `size` bytes at `to`, with a
// 0X, cutting a character short only if asked. Returns n, what the whole
// is.
int32_t give(const char *from, int32_t n, intptr_t to, int32_t size,
             bool utf8) {
  char *d = reinterpret_cast<char *>(to);
  int32_t cut = n < size ? n : size - 1;
  if (utf8 && cut < n) cut = int32_t(fl_utf8back(from + cut, from, from + n) - from);
  memcpy(d, from, size_t(cut));
  d[cut] = 0;
  return n;
}

// A buffer of n bytes, for what a function writes.
struct Out {
  char *s;
  explicit Out(size_t n) : s(static_cast<char *>(calloc(n + 1, 1))) {}
  ~Out() { free(s); }

 private:
  Out(const Out &);
  Out &operator=(const Out &);
};

}  // namespace

extern "C" {

int32_t ofl_utf8_len(int32_t c) { return fl_utf8len(char(c)); }
int32_t ofl_utf8_len1(int32_t c) { return fl_utf8len1(char(c)); }
int32_t ofl_utf8_bytes(int32_t ucs) { return fl_utf8bytes(uint32_t(ucs)); }

// fl_utf8encode writes no 0X, and 4 bytes at most.
int32_t ofl_utf8_encode(int32_t ucs, intptr_t to, int32_t size) {
  char b[4];
  int32_t n = fl_utf8encode(uint32_t(ucs), b);
  if (n >= size) n = 0;
  memcpy(reinterpret_cast<char *>(to), b, size_t(n));
  reinterpret_cast<char *>(to)[n] = 0;
  return n;
}

int32_t ofl_utf8_decode(intptr_t a, int32_t n, int32_t at, int32_t *size) {
  Text t(a, n);
  int len = 0;
  if (!t.ok()) {
    *size = 1;
    return 0xFFFD;
  }
  unsigned ucs = fl_utf8decode(t.s + at, t.s + n, &len);
  *size = len;
  return int32_t(ucs);
}

int32_t ofl_utf8_fwd(intptr_t a, int32_t n, int32_t at) {
  Text t(a, n);
  return t.ok() ? t.within(fl_utf8fwd(t.s + at, t.s, t.s + n)) : at;
}

int32_t ofl_utf8_back(intptr_t a, int32_t n, int32_t at) {
  Text t(a, n);
  return t.ok() ? t.within(fl_utf8back(t.s + at, t.s, t.s + n)) : at;
}

int32_t ofl_utf8_strlen(intptr_t a, int32_t n, int32_t chars) {
  Text t(a, n);
  if (!t.ok()) return 0;
  int32_t got = fl_utf8strlen(t.s, chars);
  return got > n ? n : got;
}

int32_t ofl_utf8_nb_char(intptr_t a, int32_t n) {
  return fl_utf_nb_char(reinterpret_cast<const unsigned char *>(a), n);
}

int32_t ofl_utf8_test(intptr_t a, int32_t n) {
  return fl_utf8test(reinterpret_cast<const char *>(a), uint32_t(n));
}

int32_t ofl_utf8_next_composed(intptr_t a, int32_t n, int32_t at) {
  Text t(a, n);
  return t.ok() ? t.within(fl_utf8_next_composed_char(t.s + at, t.s + n)) : n;
}

int32_t ofl_utf8_previous_composed(intptr_t a, int32_t n, int32_t at) {
  Text t(a, n);
  return t.ok() ? t.within(fl_utf8_previous_composed_char(t.s + at, t.s)) : 0;
}

int32_t ofl_utf8_nonspacing(int32_t ucs) {
  return fl_nonspacing(uint32_t(ucs)) != 0;
}

int32_t ofl_utf8_wcwidth_(int32_t ucs) { return fl_wcwidth_(uint32_t(ucs)); }

int32_t ofl_utf8_wcwidth(intptr_t a, int32_t n, int32_t at) {
  Text t(a, n);
  return t.ok() ? fl_wcwidth(t.s + at) : 1;
}

int32_t ofl_utf8_tolower(int32_t ucs) { return fl_tolower(uint32_t(ucs)); }
int32_t ofl_utf8_toupper(int32_t ucs) { return fl_toupper(uint32_t(ucs)); }

// fl_utf_tolower and fl_utf_toupper take no size and write no 0X. A bad
// byte can come out as 3 bytes, and a 4 byte character stays 4
// (doc/fltk-issues.md, 116).
int32_t ofl_utf8_case(intptr_t a, int32_t n, intptr_t to, int32_t size,
                      int32_t upper) {
  Text t(a, n);
  Out out(size_t(n) * 4);
  if (!t.ok() || !out.s) return give("", 0, to, size, false);
  const unsigned char *p = reinterpret_cast<const unsigned char *>(t.s);
  int32_t got = upper ? fl_utf_toupper(p, n, out.s) : fl_utf_tolower(p, n, out.s);
  return give(out.s, got, to, size, true);
}

int32_t ofl_utf8_strcasecmp(intptr_t a, int32_t na, intptr_t b, int32_t nb) {
  Text s(a, na), t(b, nb);
  return s.ok() && t.ok() ? fl_utf_strcasecmp(s.s, t.s) : 0;
}

int32_t ofl_utf8_strncasecmp(intptr_t a, int32_t na, intptr_t b, int32_t nb,
                             int32_t n) {
  Text s(a, na), t(b, nb);
  return s.ok() && t.ok() ? fl_utf_strncasecmp(s.s, t.s, n) : 0;
}

// fl_utf8toa's count, past a buffer too short, reads bad text as
// fl_utf8len1 does, not as it reads it filling one, so it is not the
// length (doc/fltk-issues.md, 117). A byte of UTF-8 gives a Latin-1 byte
// at most, so this buffer is never too short.
int32_t ofl_utf8_toa(intptr_t a, int32_t n, intptr_t to, int32_t size) {
  Text t(a, n);
  Out out((size_t(n)));
  if (!t.ok() || !out.s) return give("", 0, to, size, false);
  int32_t got = int32_t(fl_utf8toa(t.s, uint32_t(n), out.s, uint32_t(n) + 1));
  return give(out.s, got, to, size, false);
}

int32_t ofl_utf8_froma(intptr_t a, int32_t n, intptr_t to, int32_t size) {
  Text t(a, n);
  Out out(size_t(n) * 2);
  if (!t.ok() || !out.s) return give("", 0, to, size, false);
  int32_t got = int32_t(fl_utf8froma(out.s, uint32_t(n) * 2 + 1, t.s, uint32_t(n)));
  return give(out.s, got, to, size, true);
}

int32_t ofl_utf8_locale() { return fl_utf8locale() != 0; }

// In a UTF-8 locale these write nothing, not even a 0X, to a buffer too
// short (doc/fltk-issues.md, 118). So they are asked the size first.
// fl_utf8from_mb in another locale counts the 0X of a text of 1024 bytes
// or more, so its count isn't used.
int32_t ofl_utf8_to_mb(intptr_t a, int32_t n, intptr_t to, int32_t size) {
  Text t(a, n);
  if (!t.ok()) return give("", 0, to, size, false);
  uint32_t need = fl_utf8to_mb(t.s, uint32_t(n), 0, 0);
  Out out(need);
  if (!out.s) return give("", 0, to, size, false);
  need = fl_utf8to_mb(t.s, uint32_t(n), out.s, need + 1);
  return give(out.s, int32_t(need), to, size, fl_utf8locale() != 0);
}

int32_t ofl_utf8_from_mb(intptr_t a, int32_t n, intptr_t to, int32_t size) {
  Text t(a, n);
  if (!t.ok()) return give("", 0, to, size, false);
  uint32_t need = fl_utf8from_mb(0, 0, t.s, uint32_t(n));
  Out out(need);
  if (!out.s) return give("", 0, to, size, false);
  fl_utf8from_mb(out.s, need + 1, t.s, uint32_t(n));
  return give(out.s, int32_t(strlen(out.s)), to, size, true);
}

}  // extern "C"
