// The C++ part of FlImages: images, loaded or made from pixels, drawn, and
// shown as widget labels; animated GIFs; image surfaces, offscreen
// drawing. See pofltk.h for the conventions.

#include "pofltk.h"

#include <new>

#include <FL/Fl_Anim_GIF_Image.H>
#include <FL/Fl_BMP_Image.H>
#include <FL/Fl_Bitmap.H>
#include <FL/Fl_Browser.H>
#include <FL/Fl_Copy_Surface.H>
#include <FL/Fl_Device.H>
#include <FL/Fl_File_Icon.H>
#include <FL/Fl_GIF_Image.H>
#include <FL/Fl_ICO_Image.H>
#include <FL/Fl_Image.H>
#include <FL/Fl_Image_Surface.H>
#include <FL/Fl_JPEG_Image.H>
#include <FL/Fl_Menu_.H>
#include <FL/Fl_Multi_Label.H>
#include <FL/Fl_PNG_Image.H>
#include <FL/Fl_PNM_Image.H>
#include <FL/Fl_Pixmap.H>
#include <FL/Fl_Shared_Image.H>
#if defined(FLTK_USE_SVG)
#include <FL/Fl_SVG_Image.H>
#endif
#include <FL/Fl_Tiled_Image.H>
#include <FL/filename.H>
#include <FL/Fl_Tree.H>
#include <FL/Fl_Tree_Item.H>
#include <FL/Fl_Window.H>
#include <FL/Fl_XPM_Image.H>
#include <FL/fl_draw.H>
#include <FL/platform.H>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <new>
#include <vector>

namespace {

// Rasterizes image, if it is an SVG, so that it has pixels to read.
void normalize(Fl_Image *image) {
#if defined(FLTK_USE_SVG)
  if (Fl_SVG_Image *s = dynamic_cast<Fl_SVG_Image *>(image)) s->normalize();
#else
  (void)image;
#endif
}

// Counts changes to any image's pixels. An Img keeps a pixmap's pixels as
// RGB, and a change through another Img of the same shared image must
// reach it.
long generation = 0;

// An image, shared by the program's Image and the widgets showing it
// (ofl::Shared): FLTK keeps a label image's pointer, and doesn't own it.
// An Fl_Shared_Image counts its own references: an Img holds one, and
// lets it go with release(), which deletes any other image.
class Img : public ofl::Shared {
public:
  // under is an image i uses and doesn't own, which it holds: the image a
  // tiled image tiles.
  explicit Img(Fl_Image *i, ofl::Shared *under = 0)
      : image(i), rgb_(0), seen_(0), under_(under) {
    if (under_) under_->hold();
  }
  ~Img() {
    delete rgb_;
    image->release();
    if (under_) under_->release();
  }
  // The image that has the pixels: a shared image's, or itself.
  Fl_Image *inner() const {
    Fl_Shared_Image *s = dynamic_cast<Fl_Shared_Image *>(image);
    return s ? const_cast<Fl_Image *>(s->image()) : image;
  }
  // The image as RGB pixels, for reading: itself, or a copy of a pixmap
  // made once, until the image changes, or an animation's frame shown,
  // unless it is smaller than the animation (OPTIMIZE_MEMORY); 0 for a
  // bitmap or a tiled image. A shared image's are those of what it shares.
  Fl_RGB_Image *rgb() {
    Fl_Image *m = inner();
    if (Fl_Anim_GIF_Image *a = dynamic_cast<Fl_Anim_GIF_Image *>(m)) {
      Fl_RGB_Image *f = dynamic_cast<Fl_RGB_Image *>(a->image());
      if (f && f->data_w() == a->data_w() && f->data_h() == a->data_h()) {
        return f;
      }
      return 0;
    }
    normalize(m);
    if (Fl_RGB_Image *r = dynamic_cast<Fl_RGB_Image *>(m)) return r;
    if (rgb_ && seen_ != generation) {
      delete rgb_;
      rgb_ = 0;
    }
    if (!rgb_) {
      if (Fl_Pixmap *p = dynamic_cast<Fl_Pixmap *>(m)) {
        rgb_ = new Fl_RGB_Image(p);
        seen_ = generation;
      }
    }
    return rgb_;
  }
  // This image, or for a shared image, a new Img of a copy of its pixels,
  // for the FLTK classes that copy an image they are given, change the
  // copy and delete it: a shared image's copy is the pool's own entry
  // (doc/fltk-issues.md, 84). The caller closes a new one.
  Img *unpooled() {
    if (!dynamic_cast<Fl_Shared_Image *>(image)) return this;
    Fl_Image *c = inner()->copy();
    c->scale(image->w(), image->h(), 0, 1);
    return new Img(c);
  }
  void changed() { ++generation; }
  Fl_Image *const image;

private:
  Fl_RGB_Image *rgb_;
  long seen_;  // the generation rgb_ was made in
  ofl::Shared *const under_;
};

Img *img(intptr_t i) { return reinterpret_cast<Img *>(i); }

// Fl_Anim_GIF_Image's private canvas_, reached as FlBrowsers.cpp reaches
// Fl_Tree's _lastselect, through an explicit instantiation, which may
// name a private member ([temp.explicit]).
template <class Tag, typename Tag::type M> struct Reach {
  friend typename Tag::type member(Tag) { return M; }
};
struct CanvasOf {
  typedef Fl_Widget *Fl_Anim_GIF_Image::*type;
  friend type member(CanvasOf);
};
template struct Reach<CanvasOf, &Fl_Anim_GIF_Image::canvas_>;

// An animated GIF. FLTK's animation keeps its canvas widget's pointer, and
// redraws it from a timer, so a canvas deleted first would be used after
// it is freed (doc/fltk-issues.md, 62): the animation watches the canvas,
// and forgets it as it dies.
class Anim : public Img, public ofl::Watcher {
public:
  explicit Anim(Fl_Anim_GIF_Image *a) : Img(a), canvas_(0) {}
  ~Anim() {
    if (canvas_) canvas_->unwatch(this);
  }
  Fl_Anim_GIF_Image *gif() const {
    return static_cast<Fl_Anim_GIF_Image *>(image);
  }
  // Watches widget w, the canvas; 0 for none.
  void watch(Fl_Widget *w) {
    if (canvas_) canvas_->unwatch(this);
    canvas_ = w ? ofl::ref_of(w) : 0;
    if (canvas_) canvas_->watch(this);
  }
  void widget_gone() override {
    gif()->*member(CanvasOf()) = 0;
    canvas_ = 0;
  }

private:
  ofl::Ref *canvas_;  // the canvas's
};

Anim *anim(intptr_t a) { return reinterpret_cast<Anim *>(a); }

// Makes widget w (0 for none) a's canvas, as Fl_Anim_GIF_Image::canvas
// does with flags. FLTK takes the old canvas's image away, and shows the
// animation in the new one unless DONT_SET_AS_IMAGE: the widgets' holds
// follow.
void set_canvas(Anim *a, intptr_t w, int32_t flags) {
  Fl_Anim_GIF_Image *g = a->gif();
  Fl_Widget *old = g->canvas();
  Fl_Widget *c = w ? ofl::widget(w) : 0;
  g->canvas(c, static_cast<unsigned short>(flags));
  if (old) ofl::ref_of(old)->hold(ofl::Ref::image, 0);
  if (c && !(flags & Fl_Anim_GIF_Image::DONT_SET_AS_IMAGE)) {
    ofl::ref_of(c)->hold(ofl::Ref::image, a);
  }
  a->watch(c);
}

// g, loaded, as an Anim, with canvas w and flags; 0 (and g deleted) if it
// failed. g was made with DONT_START and no canvas, so a failure leaves
// no widget showing it; the canvas is set, and the animation started,
// as FLTK's constructor would.
intptr_t open_anim(Fl_Anim_GIF_Image *g, intptr_t w, int32_t flags) {
  if (!g->valid() || g->frames() <= 0 || g->w() <= 0 || g->h() <= 0) {
    delete g;
    return 0;
  }
  Anim *a = new Anim(g);
  set_canvas(a, w, flags);
  if (!(flags & Fl_Anim_GIF_Image::DONT_START)) g->start();
  return reinterpret_cast<intptr_t>(a);
}

// A multi-label: two parts, drawn side by side, each nothing, text (its
// own copy), an image or another multi-label, which it holds. FLTK keeps
// the pointers to it and its parts, and owns none of them.
class Multi : public ofl::Shared {
public:
  Multi() {
    for (int i = 0; i < 2; i++) {
      text_[i] = 0;
      part_[i] = 0;
    }
    ml.labela = ml.labelb = 0;
    ml.typea = ml.typeb = FL_NO_LABEL;
  }
  ~Multi() {
    for (int i = 0; i < 2; i++) set(i, FL_NO_LABEL, 0, 0, 0);
  }
  // Part i becomes value, of label type t: text, copied, or the label of
  // what part holds (an image or a multi-label).
  void set(int i, Fl_Labeltype t, const char *value, char *text,
           ofl::Shared *part) {
    if (part) part->hold();
    char *old_text = text_[i];
    ofl::Shared *old_part = part_[i];
    (i == 0 ? ml.labela : ml.labelb) = value;
    (i == 0 ? ml.typea : ml.typeb) = static_cast<uchar>(t);
    text_[i] = text;
    part_[i] = part;
    free(old_text);
    if (old_part) old_part->release();
  }
  // Whether this is m, or holds it, however deeply.
  bool contains(const Multi *m) const {
    if (m == this) return true;
    for (int i = 0; i < 2; i++) {
      const Multi *p = dynamic_cast<const Multi *>(part_[i]);
      if (p && p->contains(m)) return true;
    }
    return false;
  }
  Fl_Multi_Label ml;

private:
  char *text_[2];
  ofl::Shared *part_[2];
};

Multi *multi(intptr_t m) { return reinterpret_cast<Multi *>(m); }

// i, made by FLTK, if it worked; 0 (and i gone) if it failed. fail() says
// a depth of 0 is a failure, and a bitmap has that depth (doc/fltk-issues.md,
// 80), as a shared image of one has.
Fl_Image *good(Fl_Image *i) {
  if (i == 0) return 0;
  Fl_Bitmap *b = dynamic_cast<Fl_Bitmap *>(i);
  bool failed = i->w() <= 0 || i->h() <= 0;
  if (b) {
    failed = failed || b->array == 0;
  } else if (!dynamic_cast<Fl_Shared_Image *>(i)) {
    failed = failed || i->fail();
  }
  if (failed) {
    i->release();
    return 0;
  }
  return i;
}

intptr_t wrap(Fl_Image *i) {
  return i ? reinterpret_cast<intptr_t>(new Img(i)) : 0;
}

// i, made by FLTK, as an Img; 0 (and i gone) if it failed.
intptr_t make(Fl_Image *i) { return wrap(good(i)); }

bool starts(const unsigned char *p, size_t n, const char *magic) {
  size_t m = strlen(magic);
  return n >= m && memcmp(p, magic, m) == 0;
}

// Whether the n bytes at p begin an SVG document: "<svg" within them,
// after an XML declaration or comments.
bool svg(const unsigned char *p, size_t n) {
  for (size_t i = 0; i + 4 <= n; i++) {
    if (memcmp(p + i, "<svg", 4) == 0) return true;
  }
  return n >= 2 && p[0] == 0x1f && p[1] == 0x8b;  // svgz, gzipped
}

enum Format { unknown, png, jpeg, gif, bmp, xpm, pnm, svgf, xbm, ico };

// The format of an image beginning with the n bytes at p, by its magic
// number, as Fl_Shared_Image's handlers decide it.
Format format(const unsigned char *p, size_t n) {
  if (starts(p, n, "\x89PNG")) return png;
  if (starts(p, n, "\xff\xd8\xff")) return jpeg;
  if (starts(p, n, "GIF87a") || starts(p, n, "GIF89a")) return gif;
  if (starts(p, n, "BM")) return bmp;
  if (starts(p, n, "/* XPM */")) return xpm;
  if (starts(p, n, "#define")) return xbm;
  if (n >= 6 && memcmp(p, "\0\0\1\0", 4) == 0 && p[5] == 0) return ico;
  if (n >= 2 && p[0] == 'P' && p[1] >= '1' && p[1] <= '7') return pnm;
  if (svg(p, n)) return svgf;
  return unknown;
}

// The maxval of the binary PNM (P5, P6) beginning with the n bytes at p:
// its fourth number, after the magic, width and height, with comments;
// 0 for another form, or a header it can't read.
int pnm_maxval(const unsigned char *p, size_t n) {
  if (n < 2 || p[0] != 'P' || (p[1] != '5' && p[1] != '6')) return 0;
  size_t i = 2;
  int v = 0;
  for (int field = 0; field < 3; field++) {
    for (;;) {  // white space and comments
      while (i < n && (p[i] == ' ' || p[i] == '\t' || p[i] == '\r' ||
                       p[i] == '\n')) {
        i++;
      }
      if (i < n && p[i] == '#') {
        while (i < n && p[i] != '\n') i++;
      } else {
        break;
      }
    }
    if (i >= n || p[i] < '0' || p[i] > '9') return 0;
    for (v = 0; i < n && p[i] >= '0' && p[i] <= '9'; i++) {
      v = v * 10 + (p[i] - '0');
      if (v > 65535) return 0;
    }
  }
  return v;
}

// Fl_PNM_Image reads the samples of a binary PNM with a maxval under 255
// as they are, not scaled to 0 to 255 as it scales the text forms
// (doc/fltk-issues.md, 45); this scales them.
void scale_pnm(Fl_Image *i, int maxval) {
  Fl_RGB_Image *r = dynamic_cast<Fl_RGB_Image *>(i);
  if (r == 0 || maxval <= 0 || maxval >= 255 || r->fail()) return;
  unsigned char *a = const_cast<unsigned char *>(r->array);
  int ld = r->ld() ? r->ld() : r->data_w() * r->d();
  for (int y = 0; y < r->data_h(); y++) {
    for (int x = 0; x < r->data_w() * r->d(); x++) {
      unsigned char *p = a + y * ld + x;
      *p = static_cast<unsigned char>(*p * 255 / maxval);
    }
  }
  r->uncache();
}

// The whole of file name, from malloc, and its size in *n; 0 if it can't
// be read.
unsigned char *read_file(const char *name, size_t *n) {
  FILE *f = fopen(name, "rb");
  if (!f) return 0;
  unsigned char *p = 0;
  long size = fseek(f, 0, SEEK_END) == 0 ? ftell(f) : -1;
  if (size >= 0 && fseek(f, 0, SEEK_SET) == 0) {
    p = static_cast<unsigned char *>(malloc(size > 0 ? size : 1));
    if (p && fread(p, 1, size, f) != static_cast<size_t>(size)) {
      free(p);
      p = 0;
    }
  }
  fclose(f);
  *n = p ? static_cast<size_t>(size) : 0;
  return p;
}

// The format of file name, by its first bytes; into head, of n bytes, and
// *got of them read, for a caller that wants them.
Format file_format(const char *name, unsigned char *head, size_t n,
                   size_t *got) {
  FILE *f = fopen(name, "rb");
  if (!f) return unknown;
  *got = fread(head, 1, n, f);
  fclose(f);
  return format(head, *got);
}

// A bitmap of w by h pixels, from bits, ((w + 7) / 8) * h bytes, copied:
// Fl_Bitmap keeps the pointer it is given.
Fl_Bitmap *new_bitmap(const unsigned char *bits, int w, int h) {
  size_t n = static_cast<size_t>((w + 7) / 8) * h;
  unsigned char *copy = new (std::nothrow) unsigned char[n];
  if (copy == 0) return 0;
  memcpy(copy, bits, n);
  Fl_Bitmap *b = new Fl_Bitmap(copy, w, h);
  b->alloc_array = 1;
  return b;
}

const size_t xbm_max_size = 1 << 20;  // a side, past which a number is wrong

bool xbm_space(unsigned char c) {
  return c == ' ' || c == '\t' || c == '\r' || c == '\n';
}

// The number at p[*i], of the n bytes at p, into *v: decimal, or
// hexadecimal after 0x. false if there is none, or it is over max.
bool xbm_number(const unsigned char *p, size_t n, size_t *i, size_t max,
                size_t *v) {
  size_t k = *i, base = 10;
  if (k + 1 < n && p[k] == '0' && (p[k + 1] == 'x' || p[k + 1] == 'X')) {
    k += 2;
    base = 16;
  }
  size_t start = k, r = 0;
  for (; k < n; k++) {
    size_t d = p[k] >= '0' && p[k] <= '9'   ? p[k] - '0'
               : p[k] >= 'a' && p[k] <= 'f' ? p[k] - 'a' + 10
               : p[k] >= 'A' && p[k] <= 'F' ? p[k] - 'A' + 10
                                            : 16;
    if (d >= base) break;
    r = r * base + d;
    if (r > max) return false;
  }
  if (k == start) return false;
  *i = k;
  *v = r;
  return true;
}

// The bitmap in the n bytes of XBM text at p, or 0 if they aren't one.
// Fl_XBM_Image takes a file name alone, and takes any two "#define"s for the
// size, leaves bits it can't find unset, and can't say it failed
// (doc/fltk-issues.md, 81): this reads <name>_width and <name>_height, other
// "#define"s, and then every byte of the bits, or fails.
Fl_Bitmap *parse_xbm(const unsigned char *p, size_t n) {
  size_t i = 0, w = 0, h = 0;
  for (;;) {
    while (i < n && xbm_space(p[i])) i++;
    if (n - i < 7 || memcmp(p + i, "#define", 7) != 0) break;
    i += 7;
    while (i < n && xbm_space(p[i])) i++;
    size_t name = i;
    while (i < n && !xbm_space(p[i])) i++;
    size_t len = i - name, v;
    while (i < n && xbm_space(p[i])) i++;
    if (!xbm_number(p, n, &i, xbm_max_size, &v)) return 0;
    if (len >= 5 && memcmp(p + name + len - 5, "width", 5) == 0) w = v;
    if (len >= 6 && memcmp(p + name + len - 6, "height", 6) == 0) h = v;
  }
  if (w == 0 || h == 0 || n - i < 6 || memcmp(p + i, "static", 6) != 0) return 0;
  size_t open = i;
  while (open < n && p[open] != '{' && p[open] != ';') open++;
  if (open >= n || p[open] != '{') return 0;
  const char *c = "char";  // X10's form holds shorts
  size_t k = i;
  while (k + 4 <= open && memcmp(p + k, c, 4) != 0) k++;
  if (k + 4 > open) return 0;
  i = open + 1;
  unsigned long long need = static_cast<unsigned long long>((w + 7) / 8) * h;
  if (need * 2 > n) return 0;  // each is two characters at the least
  std::vector<unsigned char> bits(static_cast<size_t>(need));
  for (size_t b = 0; b < bits.size(); b++) {
    size_t v;
    while (i < n && xbm_space(p[i])) i++;
    if (!xbm_number(p, n, &i, 255, &v)) return 0;
    bits[b] = static_cast<unsigned char>(v);
    while (i < n && xbm_space(p[i])) i++;
    if (i < n && p[i] == ',') {
      i++;
    } else if (b + 1 < bits.size()) {
      return 0;
    }
    while (i < n && xbm_space(p[i])) i++;
  }
  if (i >= n || p[i] != '}') return 0;
  return new_bitmap(bits.data(), static_cast<int>(w), static_cast<int>(h));
}

unsigned le16(const unsigned char *p) { return p[0] | (p[1] << 8); }

uint32_t le32(const unsigned char *p) {
  return static_cast<uint32_t>(le16(p)) |
         (static_cast<uint32_t>(le16(p + 2)) << 16);
}

// Whether Fl_BMP_Image can safely read the BMP information header in the n
// bytes at p (doc/fltk-issues.md, 87). It trusts the count of colors, of a
// table of 256 on the stack, and the size, whose product it takes as an
// int. An ICO's size is in its directory, a byte each way.
bool dib_ok(const unsigned char *p, size_t n, bool in_ico) {
  if (n < 12) return false;
  int64_t w, h;
  unsigned depth;
  uint32_t colors = 0;
  if (static_cast<int32_t>(le32(p)) < 40) {
    w = le16(p + 4);
    h = le16(p + 6);
    depth = le16(p + 10);
  } else {
    if (n < 40) return false;
    w = static_cast<int32_t>(le32(p + 4));
    h = static_cast<int32_t>(le32(p + 8));
    if (h < 0) h = -h;
    if (in_ico) w = h = 256;
    depth = le16(p + 14);
    colors = le32(p + 32);
  }
  if (depth != 1 && depth != 4 && depth != 8 && depth != 16 && depth != 24 &&
      depth != 32) {
    return false;
  }
  return colors <= 256 && w > 0 && h > 0 && w * h <= 0x7fffffff / 4;
}

// Whether an image of w by h pixels fits an int at 4 bytes a pixel, the
// most a loaded image has. FLTK's PNG, JPEG and PNM loaders check the size
// as a size_t, then allocate it as an int product, so a size that wraps
// an int gets a buffer they write past; on a 32-bit system the size_t
// product wraps too, past FLTK's max_size (doc/fltk-issues.md, 160).
bool size_ok(int64_t w, int64_t h) {
  return w > 0 && h > 0 && w * h <= 0x7fffffff / 4;
}

uint32_t be32(const unsigned char *p) {
  return (static_cast<uint32_t>(p[0]) << 24) | (p[1] << 16) | (p[2] << 8) |
         p[3];
}

// Whether the PNG beginning with the n bytes at p has a size FLTK can
// load: its first chunk is IHDR, which libpng requires.
bool png_ok(const unsigned char *p, size_t n) {
  return n >= 24 && memcmp(p + 12, "IHDR", 4) == 0 &&
         size_ok(be32(p + 16), be32(p + 20));
}

// Whether the JPEG in the n bytes at p has a size FLTK can load. Its
// markers are found as libjpeg finds them (jdmarker.c, next_marker): bytes
// up to an FF, any more FFs, and a 0 after them is data. Its first frame
// header, an SOF marker, has the size; libjpeg fails on an image with none
// before its scan, or an unknown marker.
bool jpeg_ok(const unsigned char *p, size_t n) {
  if (n < 2 || p[0] != 0xff || p[1] != 0xd8) return false;
  size_t i = 2;
  for (;;) {
    while (i < n && p[i] != 0xff) i++;
    while (i < n && p[i] == 0xff) i++;
    if (i >= n) return false;
    unsigned m = p[i++];
    if (m == 0) continue;
    if (m == 0x01 || (m >= 0xd0 && m <= 0xd7)) continue;  // no parameters
    if (m == 0xd8 || m == 0xd9 || m == 0xda) return false;  // SOI, EOI, SOS
    if (m < 0xc0 || (m >= 0xf0 && m != 0xfe)) return false;  // unknown
    if (i + 2 > n) return false;
    size_t length = (p[i] << 8) | p[i + 1];
    if (m >= 0xc0 && m <= 0xcf && m != 0xc4 && m != 0xc8 && m != 0xcc) {
      if (length < 8 || i + 7 > n) return false;
      return size_ok((p[i + 5] << 8) | p[i + 6], (p[i + 3] << 8) | p[i + 4]);
    }
    if (length < 2) return false;
    i += length;
  }
}

// Whether the PNM file name has a size FLTK can load. Its width and height
// are read as Fl_PNM_Image reads them, by the same code
// (Fl_PNM_Image.cxx:82-107): any byte but a digit separates numbers, a "#"
// ends a line of 1023 bytes or less, and a number past an int's range
// isn't the one written.
bool pnm_ok(const char *name) {
  FILE *f = fl_fopen(name, "rb");
  if (f == 0) return false;
  char line[1024];
  char *p = fgets(line, sizeof line, f);
  int wh[2] = {0, 0};
  if (p != 0) {
    p++;
    int format = atoi(p);
    while (isdigit(static_cast<unsigned char>(*p))) p++;
    if (format == 7) p = line + strlen(line);
    for (int k = 0; k < 2; k++) {
      while (p != 0 && wh[k] == 0) {
        if (*p == '\0' || *p == '#') {
          p = fgets(line, sizeof line, f);
        } else if (isdigit(static_cast<unsigned char>(*p))) {
          wh[k] = static_cast<int>(strtol(p, &p, 10));
        } else {
          p++;
        }
      }
    }
  }
  fclose(f);
  return size_ok(wh[0], wh[1]);
}

// A BMP's header follows its 14 byte file header.
Fl_Image *new_bmp(const char *name, const unsigned char *head, size_t n,
                  bool in_memory) {
  if (n < 14 || !dib_ok(head + 14, n - 14, false)) return 0;
  return good(in_memory ? new Fl_BMP_Image(0, head, static_cast<long>(n))
                        : new Fl_BMP_Image(name));
}

// The bytes of a file or a block, as Fl_Image_Reader gives them.
struct Bytes {
  const unsigned char *p;
  size_t n, at;
  bool end() const { return at >= n; }
  int byte() { return at < n ? p[at++] : 0; }
  int word() {
    int low = byte();
    return low | (byte() << 8);
  }
  void skip(size_t k) { at = k < n - at ? at + k : n; }
};

// Whether the LZW codes at r leave Fl_GIF_Image's tables sound, read as
// lzw_decode reads them. A code equal to the first free one, with no code
// before it, makes an entry its own prefix, and lzw_decode then follows
// it off its stack (doc/fltk-issues.md, 88).
bool lzw_ok(Bytes &r, int bits) {
  int size = bits + 1;
  const int clear = 1 << bits, eof = clear + 1, first = clear + 2;
  int mask = (1 << size) - 1, free_code = first;
  bool has_old = false;
  int blocklen = r.byte();
  int thisbyte = r.byte();
  blocklen--;
  int frombit = 0;
  while (!r.end()) {
    int code = thisbyte;
    for (int reach = 7; reach <= 15; reach += 8) {
      if (frombit + size <= reach) break;
      if (blocklen <= 0) {
        blocklen = r.byte();
        if (blocklen <= 0) return true;
      }
      thisbyte = r.byte();
      blocklen--;
      code |= thisbyte << (reach + 1);
    }
    code = (code >> frombit) & mask;
    frombit = (frombit + size) % 8;
    if (code == clear) {
      size = bits + 1;
      mask = (1 << size) - 1;
      free_code = first;
      has_old = false;
      continue;
    }
    if (code == eof) {
      r.skip(static_cast<size_t>(blocklen > 0 ? blocklen : 0));
      r.byte();
      return true;
    }
    if (code > free_code) return true;  // where lzw_decode gives up
    if (code == free_code && !has_old) return false;
    if (has_old) {
      if (free_code < 4096) free_code++;
      if (free_code > mask && size < 12) {
        size++;
        mask = (1 << size) - 1;
      }
    }
    has_old = true;
  }
  return true;
}

// Whether Fl_GIF_Image, or an animation (anim), can safely read the n
// bytes at p (doc/fltk-issues.md, 88). What it reads past the first image
// matters only to an animation, which it reads to the end.
bool gif_ok(const unsigned char *p, size_t n, bool anim) {
  Bytes r = {p, n, 6};
  const int screen_w = r.word(), screen_h = r.word();
  int flags = r.byte();
  r.skip(2);
  if (flags & 0x80) r.skip(static_cast<size_t>(3) * (2 << (flags & 7)));
  if (anim && (screen_w == 0 || screen_h == 0 ||
               static_cast<int64_t>(screen_w) * screen_h > 0x7fffffff / 4)) {
    return false;
  }
  while (!r.end()) {
    int kind = r.byte();
    if (kind == 0x21) {
      int type = r.byte(), blocklen = r.byte();
      if (type == 0xF9 && blocklen == 4) {
        r.skip(4);
        blocklen = r.byte();
      } else if (type == 0xFF) {
        r.skip(static_cast<size_t>(blocklen));
        blocklen = r.byte();
        if (blocklen) {
          r.skip(static_cast<size_t>(blocklen));
          blocklen = r.byte();
        }
      }
      while (blocklen > 0) {
        r.skip(static_cast<size_t>(blocklen));
        blocklen = r.byte();
      }
    } else if (kind == 0x2c) {
      int x = r.word(), y = r.word(), w = r.word(), h = r.word();
      flags = r.byte();
      if (flags & 0x80) r.skip(static_cast<size_t>(3) * (2 << (flags & 7)));
      int bits = r.byte();
      if (r.end()) return true;
      // FLTK's warning says it goes on, with tables too small for the codes.
      if (w == 0 || h == 0 || bits > 8 ||
          static_cast<int64_t>(w) * h > 0x7fffffff) {
        return false;
      }
      if (anim && (x + w > screen_w || y + h > screen_h)) return false;
      if (!lzw_ok(r, bits)) return false;
      if (!anim) return true;
    } else {
      return true;  // the end of the image, or where FLTK stops
    }
  }
  return true;
}

// The image in file name, read whole for its check.
Fl_Image *load_gif_file(const char *name) {
  size_t n;
  unsigned char *p = read_file(name, &n);
  if (p == 0) return 0;
  bool ok = gif_ok(p, n, false);
  free(p);
  return ok ? good(new Fl_GIF_Image(name)) : 0;
}

// Which of an ICO's entries FLTK shows for id, -1 for the largest; -1 if
// there is none.
int ico_pick(const Fl_ICO_Image &dir, int id) {
  const Fl_ICO_Image::IconDirEntry *e = dir.icondirentry();
  if (e == 0 || id >= dir.idcount()) return -1;
  if (id >= 0) return id;
  int picked = -1, largest = 0, bits = 0;
  for (int i = 0; i < dir.idcount(); i++) {
    int res = e[i].bWidth * e[i].bHeight;
    if (res > largest || (res == largest && e[i].wBitCount > bits)) {
      largest = res;
      bits = e[i].wBitCount;
      picked = i;
    }
  }
  return picked;
}

// Image id of an ICO, in the n bytes at data, read from file name if it
// isn't 0. Fl_ICO_Image reads a PNG resource by the name of its file, and
// calls fopen with none for one in memory (doc/fltk-issues.md, 82), so
// that is decoded here; and a bitmap resource's header is checked.
Fl_Image *load_ico(const char *name, const unsigned char *data, size_t n,
                   int id) {
  if (id < -1) return 0;
  Fl_ICO_Image dir(name, -2, data, n);
  int k = ico_pick(dir, id);
  if (k < 0) return 0;
  size_t at = static_cast<size_t>(dir.icondirentry()[k].dwImageOffset);
  size_t size = static_cast<size_t>(dir.icondirentry()[k].dwBytesInRes);
  if (at == 0 || at >= n || size == 0) return 0;
  if (n - at >= 8 && memcmp(data + at, "\x89PNG\r\n\x1a\n", 8) == 0) {
    if (size > n - at) size = n - at;
    if (!png_ok(data + at, size)) return 0;
    return good(new Fl_PNG_Image(0, data + at, static_cast<int>(size)));
  }
  if (!dib_ok(data + at, n - at, true)) return 0;
  return good(new Fl_ICO_Image(name, id, data, n));
}

Fl_Image *load_ico_file(const char *name, int id) {
  size_t n;
  unsigned char *p = read_file(name, &n);
  if (p == 0) return 0;
  Fl_Image *i = load_ico(name, p, n, id);
  free(p);
  return i;
}

// The image in file name, of a format told by its contents.
Fl_Image *decode_file(const char *name) {
  unsigned char head[1024];
  size_t n = 0;
  switch (file_format(name, head, sizeof head, &n)) {
    case png:
      if (!png_ok(head, n)) return 0;
      return good(new Fl_PNG_Image(name));
    case jpeg: {
      size_t size;
      unsigned char *p = read_file(name, &size);
      if (p == 0) return 0;
      bool ok = jpeg_ok(p, size);
      free(p);
      return ok ? good(new Fl_JPEG_Image(name)) : 0;
    }
    case gif: return load_gif_file(name);
    case bmp: return new_bmp(name, head, n, false);
    case xpm: return good(new Fl_XPM_Image(name));
    case ico: return load_ico_file(name, -1);
    case pnm: {
      if (!pnm_ok(name)) return 0;
      Fl_Image *i = new Fl_PNM_Image(name);
      scale_pnm(i, pnm_maxval(head, n));
      return good(i);
    }
    case xbm: {
      size_t size;
      unsigned char *p = read_file(name, &size);
      if (p == 0) return 0;
      Fl_Bitmap *b = parse_xbm(p, size);
      free(p);
      return good(b);
    }
#if defined(FLTK_USE_SVG)
    case svgf: return good(new Fl_SVG_Image(name));
#endif
    default: return 0;
  }
}

// The image in file name; 0 if it can't be read or decoded, or what its
// header claims is too large.
Fl_Image *load_file(const char *name) {
  try {
    return decode_file(name);
  } catch (const std::bad_alloc &) {
    return 0;
  }
}

// The program's handlers (FlImages.AddHandler) are one handler to FLTK,
// which goes to Oberon. It answers with an Image, or 0.
intptr_t (*ask_oberon)(const char *, const char *, int32_t) = 0;

// A copy of the image the program's handlers make of file name, whose
// first n bytes are header, for FLTK to own: the Image stays the
// program's. 0 if none of them knows it.
Fl_Image *ask_handlers(const char *name, uchar *header, int n) {
  if (ask_oberon == 0) return 0;
  intptr_t h = ask_oberon(name, reinterpret_cast<const char *>(header), n);
  if (h == 0) return 0;
  try {
    Fl_Image *c = img(h)->inner()->copy();
    c->scale(img(h)->image->w(), img(h)->image->h(), 0, 1);
    return c;
  } catch (const std::bad_alloc &) {
    return 0;
  }
}

// File name's image, for the pool: what load_file can't read goes to the
// program's handlers, with the header Fl_Shared_Image::reload reads.
Fl_Image *load_shared(const char *name) {
  Fl_Image *i = load_file(name);
  if (i != 0 || ask_oberon == 0) return i;
  uchar header[64];
  FILE *f = fl_fopen(name, "rb");
  if (f == 0) return 0;
  int n = static_cast<int>(fread(header, 1, sizeof header, f));
  fclose(f);
  return n > 0 ? ask_handlers(name, header, n) : 0;
}

// The way to Fl_Shared_Image's pool for an image pofltk loaded itself:
// FLTK's get() loads files with handlers of its own, which don't correct
// what load_file corrects (doc/fltk-issues.md, 45, 81). Its protected
// members are reached as pointers to members of this class, which is
// allowed for another object as "s->image_" is not.
class Pool : public Fl_Shared_Image {
public:
  // A new original entry, named name, with one reference, owning i.
  static Fl_Shared_Image *put(const char *name, Fl_Image *i) {
    Pool *p = new Pool(name, i);
    p->alloc_image_ = 1;
    p->add();
    return p;
  }
  // s shows i, which it now owns, in place of what it shared.
  static void replace(Fl_Shared_Image *s, Fl_Image *i) {
    Fl_Image *&held = s->*(&Pool::image_);
    int &owned = s->*(&Pool::alloc_image_);
    if (owned) delete held;
    held = i;
    owned = 1;
    (s->*(&Pool::update))();
  }

private:
  Pool(const char *name, Fl_Image *i) : Fl_Shared_Image(name, i) {}
};

// The pool's original entry for name, with a reference for the caller; 0
// if it isn't there and file name can't be loaded. FLTK's own loading
// may have left one with no image.
Fl_Shared_Image *original(const char *name) {
  if (Fl_Shared_Image *o = Fl_Shared_Image::find(name)) {
    if (o->w() > 0 && o->h() > 0) return o;
    o->release();
    return 0;
  }
  Fl_Image *i = load_shared(name);
  return i ? Pool::put(name, i) : 0;
}

Fl_Shared_Image *shared(intptr_t i) {
  return static_cast<Fl_Shared_Image *>(img(i)->image);
}

// A file icon

Fl_File_Icon *file_icon(intptr_t i) { return reinterpret_cast<Fl_File_Icon *>(i); }

int icon_errors = 0;

void count_error(const char *, ...) { ++icon_errors; }

// Fl_File_Icon::labeltype draws an icon; FLTK sets no measure for it, and
// its default reads the icon as text (doc/fltk-issues.md, 85).
void measure_icon(const Fl_Label *, int &w, int &h) { w = h = 0; }

// Adds the polygon for the pixels x0 to x1 of row y of an image w by h, as
// Fl_File_Icon::load_image does, in color c.
void add_run(Fl_File_Icon *f, Fl_Color c, int x0, int x1, int y, int w, int h) {
  f->add_color(c);
  f->add(Fl_File_Icon::POLYGON);
  f->add_vertex(x0 * 9000 / w + 1000, 9500 - y * 9000 / h);
  f->add_vertex(x1 * 9000 / w + 1000, 9500 - y * 9000 / h);
  f->add_vertex(x1 * 9000 / w + 1000, 9500 - (y + 1) * 9000 / h);
  f->add_vertex(x0 * 9000 / w + 1000, 9500 - (y + 1) * 9000 / h);
  f->add(Fl_File_Icon::END);
}

// Adds r's rows to f, each a polygon a run of one color: what
// Fl_File_Icon::load_image does for a plain RGB image. A pixel with alpha
// 127 or under is not drawn.
void add_rows(Fl_File_Icon *f, Fl_RGB_Image *r) {
  const Fl_Color none = static_cast<Fl_Color>(-1);
  int w = r->data_w(), h = r->data_h(), d = r->d();
  int ld = r->ld() ? r->ld() : w * d;
  for (int y = 0; y < h; y++) {
    const unsigned char *row = r->array + y * ld;
    int start = 0;
    Fl_Color c = none;
    for (int x = 0; x <= w; x++) {
      Fl_Color t = none;
      if (x < w) {
        const unsigned char *p = row + x * d;
        int alpha = d == 2 ? p[1] : d == 4 ? p[3] : 255;
        if (alpha > 127) {
          t = d <= 2 ? fl_rgb_color(p[0], p[0], p[0])
                     : fl_rgb_color(p[0], p[1], p[2]);
        }
      }
      if (t != c || x == w) {
        if (x > start && c != none) add_run(f, c, start, x, y, w, h);
        c = t;
        start = x;
      }
    }
  }
}

// The n lines at lines, stride bytes apart, in p, if they are an XPM's:
// Fl_Pixmap, fl_draw_pixmap and fl_measure_pixmap trust an XPM's values,
// so a short line or array would be read past its end. false if they don't
// match, or FLTK's own form (fewer than 1 color) is used.
bool xpm_lines(const char *lines, int32_t n, int32_t stride,
               std::vector<const char *> &p) {
  if (n < 1 || stride < 1) return false;
  for (int32_t i = 0; i < n; i++) {
    if (!memchr(lines + static_cast<size_t>(i) * stride, 0, stride)) return false;
  }
  int w, h, colors, cpp;
  if (sscanf(lines, "%d %d %d %d", &w, &h, &colors, &cpp) != 4) return false;
  if (w < 1 || h < 1 || colors < 1 || cpp < 1 || cpp > 2) return false;
  if (static_cast<long>(n) != 1L + colors + h) return false;
  p.resize(n);
  for (int32_t i = 0; i < n; i++) {
    p[i] = lines + static_cast<size_t>(i) * stride;
    size_t need = i == 0 ? 0 : i <= colors ? static_cast<size_t>(cpp)
                                           : static_cast<size_t>(w) * cpp;
    if (strlen(p[i]) < need) return false;
  }
  return true;
}

}  // namespace

extern "C" {

// Images

// The image in file name; 0 if it can't be read or decoded.
intptr_t ofl_image_load(const char *name) { return wrap(load_file(name)); }

// The image in the n bytes at data, which FLTK decodes into its own
// memory (SVG copies the text); 0 for a format FLTK reads only from files
// (XPM, PNM), data it can't decode, or SVG in an FLTK without it. An ICO
// gives its largest image.
intptr_t ofl_image_load_data(const unsigned char *data, int32_t n) {
  if (n <= 0) return 0;
  size_t size = static_cast<size_t>(n);
  try {
    switch (format(data, size)) {
      case png:
        if (!png_ok(data, size)) return 0;
        return make(new Fl_PNG_Image(0, data, n));
      case jpeg:
        if (!jpeg_ok(data, size)) return 0;
        return make(new Fl_JPEG_Image(0, data, n));
      case gif:
        if (!gif_ok(data, size, false)) return 0;
        return make(new Fl_GIF_Image(0, data, size));
      case bmp: return wrap(new_bmp(0, data, size, true));
      case xbm: return make(parse_xbm(data, size));
      case ico: return wrap(load_ico(0, data, size, -1));
#if defined(FLTK_USE_SVG)
      case svgf: return make(new Fl_SVG_Image(0, data, size));
#endif
      default: return 0;
    }
  } catch (const std::bad_alloc &) {
    return 0;
  }
}

// Image id of an ICO, from file name, or if it is 0, the n bytes at data;
// id -1 for its largest. 0 if there is no such image.
intptr_t ofl_image_ico(const char *name, const unsigned char *data, int32_t n,
                       int32_t id) {
  unsigned char head[16];
  size_t got = 0;
  try {
    if (name) {
      if (file_format(name, head, sizeof head, &got) != ico) return 0;
      return wrap(load_ico_file(name, id));
    }
    if (n <= 0 || format(data, static_cast<size_t>(n)) != ico) return 0;
    return wrap(load_ico(0, data, static_cast<size_t>(n), id));
  } catch (const std::bad_alloc &) {
    return 0;
  }
}

// How many images the ICO has, as ofl_image_ico takes it; 0 if it isn't
// one.
int32_t ofl_image_ico_count(const char *name, const unsigned char *data,
                            int32_t n) {
  unsigned char head[16];
  size_t got = 0;
  if (name) {
    if (file_format(name, head, sizeof head, &got) != ico) return 0;
  } else if (n <= 0 || format(data, static_cast<size_t>(n)) != ico) {
    return 0;
  }
  Fl_ICO_Image dir(name, -2, data, name ? 0 : static_cast<size_t>(n));
  return dir.idcount();
}

// The pixmap in the n XPM lines at lines, each in stride bytes ending in
// a 0: the values, the colors, then the rows of pixels, as the strings of
// an XPM file. Fl_Pixmap keeps the lines, so the pixmap copies them
// (copy_data). 0 if they aren't an XPM's (xpm_lines).
intptr_t ofl_image_xpm(const char *lines, int32_t n, int32_t stride) {
  std::vector<const char *> p;
  if (!xpm_lines(lines, n, stride, p)) return 0;
  Fl_Pixmap given(p.data());
  return make(given.copy());
}

int32_t ofl_image_draw_pixmap(const char *lines, int32_t n, int32_t stride,
                              int32_t x, int32_t y, int32_t bg) {
  std::vector<const char *> p;
  if (!xpm_lines(lines, n, stride, p)) return 0;
  return fl_draw_pixmap(p.data(), x, y, static_cast<Fl_Color>(bg));
}

int32_t ofl_image_measure_pixmap(const char *lines, int32_t n, int32_t stride,
                                 int32_t *w, int32_t *h) {
  std::vector<const char *> p;
  int a = 0, b = 0;
  if (!xpm_lines(lines, n, stride, p)) return 0;
  if (!fl_measure_pixmap(p.data(), a, b)) return 0;
  *w = a;
  *h = b;
  return 1;
}

// What window win shows of x, y, w, h, or 0 if it isn't shown. With a size
// under 1 FLTK writes past the array it makes (doc/fltk-issues.md, 127).
intptr_t ofl_image_capture(intptr_t win, int32_t x, int32_t y, int32_t w,
                           int32_t h) {
  Fl_Window *window = ofl::as<Fl_Window>(win);
  if (!window->shown()) return 0;
  // FLTK's drivers read outside their buffers for a rectangle of no size
  // or partly off the window (doc/fltk-issues.md, 127).
  int r = x < window->w() - w ? x + w : window->w();
  int b = y < window->h() - h ? y + h : window->h();
  if (x < 0) x = 0;
  if (y < 0) y = 0;
  if (r <= x || b <= y) return 0;
  Fl_RGB_Image *i = fl_capture_window(window, x, y, r - x, b - y);
  return i ? make(i) : 0;
}

// An RGB image of w by h pixels of d bytes each (1 gray, 2 gray and alpha,
// 3 RGB, 4 RGBA), from bits, rows ld bytes apart (0 for w * d); copied,
// since Fl_RGB_Image keeps the pointer it is given.
intptr_t ofl_image_rgb(const unsigned char *bits, int32_t w, int32_t h,
                       int32_t d, int32_t ld) {
  int row = ld ? ld : w * d;
  unsigned char *copy = new (std::nothrow) unsigned char[row * h];
  if (copy == 0) return 0;
  memcpy(copy, bits, static_cast<size_t>(row) * h);
  Fl_RGB_Image *i = new Fl_RGB_Image(copy, w, h, d, ld);
  i->alloc_array = 1;
  return make(i);
}

// A bitmap of w by h pixels, from bits, copied: rows of (w + 7) / 8 bytes,
// the lowest bit of a byte leftmost.
intptr_t ofl_image_bitmap(const unsigned char *bits, int32_t w, int32_t h) {
  return make(new_bitmap(bits, w, h));
}

// For FlForms, a library of its own: image i's FLTK object, and what holds
// it.
Fl_Image *ofl_image_fltk(intptr_t i) { return img(i)->image; }
ofl::Shared *ofl_image_shared(intptr_t i) { return img(i); }

// The program lets go of its image; widgets showing it keep it.
void ofl_image_close(intptr_t i) { img(i)->close(); }

// what: 0 w, 1 h, 2 d, 3 data_w, 4 data_h, 5 kind (0 RGB, 1 pixmap, 2
// other, 3 animation, 4 bitmap).
int32_t ofl_image_get(intptr_t i, int32_t what) {
  Fl_Image *m = img(i)->image;
  switch (what) {
    case 1: return m->h();
    case 2:
      if (Fl_RGB_Image *r = img(i)->rgb()) return r->d();
      return m->d();
    case 3: return m->data_w();
    case 4: return m->data_h();
    case 5:
      m = img(i)->inner();
      if (dynamic_cast<Fl_RGB_Image *>(m)) return 0;
      if (dynamic_cast<Fl_Anim_GIF_Image *>(m)) return 3;
      if (dynamic_cast<Fl_Pixmap *>(m)) return 1;
      if (dynamic_cast<Fl_Bitmap *>(m)) return 4;
      return 2;
    default: return m->w();
  }
}

// A copy of the image's data, w by h pixels; 0 if FLTK couldn't make it.
// A tiled image's copy tiles the same image, which the original may own
// (after color_average), so the copy holds the original. An animation's
// copy has no canvas, and plays if the original does. A shared image's is
// the pool's entry of that size.
intptr_t ofl_image_copy(intptr_t i, int32_t w, int32_t h) {
  Fl_Image *m = img(i)->image;
  // FLTK's copy is the pool's entry of that size: a reference, not a copy.
  if (dynamic_cast<Fl_Shared_Image *>(m)) return wrap(m->copy(w, h));
  if (dynamic_cast<Fl_Tiled_Image *>(m)) {
    return reinterpret_cast<intptr_t>(new Img(m->copy(w, h), img(i)));
  }
  if (dynamic_cast<Fl_Anim_GIF_Image *>(m)) {
    Fl_Anim_GIF_Image *c = static_cast<Fl_Anim_GIF_Image *>(m->copy(w, h));
    if (!c->valid()) {
      delete c;
      return 0;
    }
    return reinterpret_cast<intptr_t>(new Anim(c));
  }
  return make(m->copy(w, h));
}

// Image t, repeated to fill w by h pixels, or the window it is drawn in
// if both are 0. Fl_Tiled_Image keeps t's pointer, so the new image holds
// t.
intptr_t ofl_image_tiled(intptr_t t, int32_t w, int32_t h) {
  Img *p = img(t)->unpooled();
  Img *m = new Img(new Fl_Tiled_Image(p->image, w, h), p);
  if (p != img(t)) p->close();
  return reinterpret_cast<intptr_t>(m);
}

// The size it is drawn at, its data unchanged.
void ofl_image_scale(intptr_t i, int32_t w, int32_t h, int32_t proportional,
                     int32_t expand) {
  img(i)->image->scale(w, h, proportional, expand);
}

// what: 0 color_average(c, weight), 1 desaturate.
void ofl_image_change(intptr_t i, int32_t what, int32_t c, double weight) {
  if (what == 1) {
    img(i)->image->desaturate();
  } else {
    img(i)->image->color_average(static_cast<Fl_Color>(c),
                                 static_cast<float>(weight));
  }
  img(i)->changed();
}

void ofl_image_draw(intptr_t i, int32_t x, int32_t y, int32_t w, int32_t h,
                    int32_t cx, int32_t cy) {
  img(i)->image->draw(x, y, w, h, cx, cy);
}

// Pixel x, y of the image's data as r, g, b, a; 0 if it has no pixels to
// read (a bitmap). A gray pixel has r = g = b; alpha is 255 without an
// alpha channel.
int32_t ofl_image_pixel(intptr_t i, int32_t x, int32_t y, int32_t *r,
                        int32_t *g, int32_t *b, int32_t *a) {
  Fl_RGB_Image *m = img(i)->rgb();
  if (m == 0 || m->count() == 0 || m->array == 0) return 0;
  int d = m->d();
  int ld = m->ld() ? m->ld() : m->data_w() * d;
  const unsigned char *p = m->array + y * ld + x * d;
  *a = 255;
  if (d <= 2) {
    *r = *g = *b = p[0];
    if (d == 2) *a = p[1];
  } else {
    *r = p[0];
    *g = p[1];
    *b = p[2];
    if (d == 4) *a = p[3];
  }
  return 1;
}

// 1 if the image was written to file name as PNG.
int32_t ofl_image_save_png(intptr_t i, const char *name) {
  Fl_RGB_Image *m = img(i)->rgb();
  return m != 0 && fl_write_png(name, m) == 0;
}

// The clipboard

// Puts the image on the clipboard, by drawing it on an Fl_Copy_Surface,
// which FLTK sends to the clipboard as it is deleted.
void ofl_image_copy_to_clipboard(intptr_t i) {
  Fl_Image *m = img(i)->image;
  fl_open_display();  // as Fl.cpp's ofl_copy (doc/fltk-issues.md, 49)
  Fl_Copy_Surface *s = new Fl_Copy_Surface(m->w(), m->h());
  Fl_Surface_Device::push_current(s);
  m->draw(0, 0);
  Fl_Surface_Device::pop_current();
  delete s;
}

// In an FL_PASTE, the image pasted, now the program's (Fl::e_clipboard_data
// set to 0, so neither FLTK nor ofl::drop_pasted_image deletes it); 0 if
// the event carries none.
intptr_t ofl_take_pasted_image(void) {
  if (Fl::event_clipboard_type() != Fl::clipboard_image) return 0;
  Fl_Image *m = static_cast<Fl_RGB_Image *>(Fl::event_clipboard());
  Fl::e_clipboard_data = 0;
  return make(m);
}

// Widget labels

// slot: 0 the label image, 1 the inactive one. i 0 for none.
void ofl_widget_image(intptr_t w, int32_t slot, intptr_t i) {
  Fl_Widget *wd = ofl::widget(w);
  Fl_Image *m = i ? img(i)->image : 0;
  if (slot) {
    wd->deimage(m);
  } else {
    wd->image(m);
  }
  ofl::ref_of(wd)->hold(slot ? ofl::Ref::deimage : ofl::Ref::image, img(i));
  wd->redraw();
}

// The window system's icon for window w, i 0 for none. FLTK's X11 driver
// copies it; Wayland's has no icons, and ignores it (doc/fltk-issues.md,
// 44).
void ofl_window_icon(intptr_t w, intptr_t i) {
  Fl_Window *win = ofl::as<Fl_Window>(w);
  win->icon(i ? img(i)->rgb() : 0);
}

// Window w's icons, the n images in is, n 0 for none, or, w 0, every
// window's that has none of its own when it is shown. FLTK's X11 drivers
// copy them, the window's as images and the default as their pixels;
// Wayland's ignore them. An image with no pixels to read (a bitmap, a
// tiled one) is left out, since FLTK takes each to be an Fl_RGB_Image.
void ofl_window_icons(intptr_t w, const intptr_t *is, int32_t n) {
  std::vector<const Fl_RGB_Image *> v;
  for (int32_t k = 0; k < n; k++) {
    if (Fl_RGB_Image *r = img(is[k])->rgb()) v.push_back(r);
  }
  const Fl_RGB_Image **a = v.empty() ? 0 : &v[0];
  int c = static_cast<int>(v.size());
  if (w) {
    ofl::as<Fl_Window>(w)->icons(a, c);
  } else {
    Fl_Window::default_icons(a, c);
  }
}

// Window w's shape, from image i: its pixels that aren't black or
// transparent. 0 if i has no pixels to read (a bitmap, a tiled image).
// FLTK keeps the image's pointer, and X11's driver reads w() by h()
// pixels of its data, past their end if the image is drawn larger than
// they are (doc/fltk-issues.md, 61): FLTK is given a copy, w() by h(),
// which the window holds.
int32_t ofl_window_image_cursor(intptr_t w, intptr_t i, int32_t hotx, int32_t hoty) {
  Fl_RGB_Image *r = img(i)->rgb();
  if (r == 0) return 0;
  ofl::as<Fl_Window>(w)->cursor(r, hotx, hoty);
  return 1;
}

int32_t ofl_window_shape(intptr_t w, intptr_t i) {
  Fl_RGB_Image *r = img(i)->rgb();
  if (r == 0) return 0;
  Fl_Image *c = r->copy(r->w(), r->h());
  normalize(c);
  if (c == 0 || c->fail() || c->w() <= 0 || c->h() <= 0) {
    delete c;
    return 0;
  }
  Img *m = new Img(c);
  Fl_Window *win = ofl::as<Fl_Window>(w);
  win->shape(c);
  ofl::ref_of(win)->hold(ofl::Ref::shape, m);
  m->close();  // the window's hold is its only one
  return 1;
}

// The icon of browser b's line, i 0 for none. The browser holds the
// image while a line shows it (ofl::drop_icons).
void ofl_browser_icon(intptr_t b, int32_t line, intptr_t i) {
  Fl_Browser *br = ofl::as<Fl_Browser>(b);
  Fl_Image *m = i ? img(i)->image : 0;
  br->icon(line, m);
  if (i) ofl::ref_of(br)->keep(img(i), m);
  ofl::drop_icons(br);
}

// Releases the icons tree t no longer shows. Like Fl_Browser::icon, Fl_Tree
// and Fl_Tree_Item keep the images' pointers (doc/fltk-issues.md, 78). An
// item removed keeps its icon held until an icon is next replaced, or the
// tree dies.
static void drop_tree_icons(Fl_Tree *t) {
  ofl::ref_of(t)->drop_unused([t](const void *key) {
    if (t->openicon() == key || t->closeicon() == key || t->usericon() == key) {
      return true;
    }
    for (Fl_Tree_Item *it = t->first(); it; it = it->next()) {
      if (it->usericon() == key || it->userdeicon() == key) return true;
    }
    return false;
  });
}

// Tree t's own icons, i 0 for none. what: 0 open, 1 close, 2 user. FLTK
// makes the deactivated forms, and deletes them with the tree, before the
// tree's Ref lets go of the images they were copied from. It deletes them
// with delete, so a shared image is shown through a copy.
void ofl_tree_icon(intptr_t t, int32_t what, intptr_t i) {
  Fl_Tree *tr = ofl::as<Fl_Tree>(t);
  Img *p = i ? img(i)->unpooled() : 0;
  Fl_Image *m = p ? p->image : 0;
  Fl_Image *old = what == 0   ? tr->openicon()
                  : what == 1 ? tr->closeicon()
                              : tr->usericon();
  if (p) ofl::ref_of(tr)->keep(p, m);
  switch (what) {
    case 0: tr->openicon(m); break;
    case 1: tr->closeicon(m); break;
    default: tr->usericon(m); break;
  }
  if (old && old != m) drop_tree_icons(tr);
  if (p && p != img(i)) p->close();
}

// An item's user icon, what 0, or the one it shows while inactive, what 1,
// which FLTK doesn't make.
void ofl_tree_item_icon(intptr_t t, intptr_t p, int32_t what, intptr_t i) {
  Fl_Tree *tr = ofl::as<Fl_Tree>(t);
  Fl_Tree_Item *it = reinterpret_cast<Fl_Tree_Item *>(p);
  Fl_Image *m = i ? img(i)->image : 0;
  Fl_Image *old = what == 0 ? it->usericon() : it->userdeicon();
  if (i) ofl::ref_of(tr)->keep(img(i), m);
  if (what == 0) {
    it->usericon(m);
  } else {
    it->userdeicon(m);
  }
  if (old && old != m) drop_tree_icons(tr);
  tr->recalc_tree();
  tr->redraw();
}

// Animated GIFs

// The animation in file name, or in the n bytes at data if name is 0, as
// open_anim makes it; 0 unless it is a GIF FLTK can decode.
intptr_t ofl_anim_load(const char *name, const unsigned char *data,
                       int32_t n, intptr_t canvas, int32_t flags) {
  unsigned short f =
      static_cast<unsigned short>(flags | Fl_Anim_GIF_Image::DONT_START);
  try {
    if (name) {
      size_t size;
      unsigned char *p = read_file(name, &size);
      if (p == 0) return 0;
      bool ok = format(p, size) == gif && gif_ok(p, size, true);
      free(p);
      if (!ok) return 0;
      return open_anim(new Fl_Anim_GIF_Image(name, 0, f), canvas, flags);
    }
    size_t size = static_cast<size_t>(n);
    if (n <= 0 || format(data, size) != gif || !gif_ok(data, size, true)) {
      return 0;
    }
    return open_anim(new Fl_Anim_GIF_Image(0, data, size, 0, f), canvas,
                     flags);
  } catch (const std::bad_alloc &) {
    return 0;
  }
}

void ofl_anim_canvas(intptr_t a, intptr_t w, int32_t flags) {
  set_canvas(anim(a), w, flags);
}

// The canvas's Oberon object, or 0.
intptr_t ofl_anim_canvas_object(intptr_t a) {
  Fl_Widget *c = anim(a)->gif()->canvas();
  return c ? ofl::object_of(c) : 0;
}

// what: 0 frames, 1 frame, 2 canvas_w, 3 canvas_h, 4 playing, 5
// frame_uncache, 6 is_animated.
int32_t ofl_anim_get(intptr_t a, int32_t what) {
  Fl_Anim_GIF_Image *g = anim(a)->gif();
  switch (what) {
    case 1: return g->frame();
    case 2: return g->canvas_w();
    case 3: return g->canvas_h();
    case 4: return g->playing();
    case 5: return g->frame_uncache();
    case 6: return g->is_animated();
    default: return g->frames();
  }
}

// Frame n's x, y, w or h, by what (0 to 3).
int32_t ofl_anim_frame_get(intptr_t a, int32_t what, int32_t n) {
  Fl_Anim_GIF_Image *g = anim(a)->gif();
  switch (what) {
    case 1: return g->frame_y(n);
    case 2: return g->frame_w(n);
    case 3: return g->frame_h(n);
    default: return g->frame_x(n);
  }
}

// what: 0 start, 1 stop, 2 next, 3 frame_uncache(true), 4
// frame_uncache(false).
void ofl_anim_do(intptr_t a, int32_t what) {
  Fl_Anim_GIF_Image *g = anim(a)->gif();
  switch (what) {
    case 1: g->stop(); break;
    case 2: g->next(); break;
    case 3: g->frame_uncache(true); break;
    case 4: g->frame_uncache(false); break;
    default: g->start(); break;
  }
}

void ofl_anim_set_frame(intptr_t a, int32_t n) { anim(a)->gif()->frame(n); }

double ofl_anim_delay(intptr_t a, int32_t n) {
  return anim(a)->gif()->delay(n);
}

void ofl_anim_set_delay(intptr_t a, int32_t n, double d) {
  anim(a)->gif()->delay(n, d);
}

double ofl_anim_speed(intptr_t a) { return anim(a)->gif()->speed(); }

void ofl_anim_set_speed(intptr_t a, double s) { anim(a)->gif()->speed(s); }

// Resizes the frames to w by h, or to the canvas if both are 0; by
// scale if w is -1.
void ofl_anim_resize(intptr_t a, int32_t w, int32_t h, double scale) {
  if (w == -1) {
    anim(a)->gif()->resize(scale);
  } else {
    anim(a)->gif()->resize(w, h);
  }
}

// The name it was loaded from, into buf of n characters, truncated; ""
// for one loaded from memory.
void ofl_anim_name(intptr_t a, char *buf, int32_t n) {
  const char *s = anim(a)->gif()->name();
  ofl::copy_out(s ? s : "", buf, n);
}

// A copy of frame n's image, as the animation draws it; 0 if it has none.
intptr_t ofl_anim_frame_image(intptr_t a, int32_t n) {
  Fl_Image *f = anim(a)->gif()->image(n);
  return f ? make(f->copy()) : 0;
}

// FLTK's settings for every animation and RGB image: which = 0 the least
// delay between frames, 1 the scaling algorithm, 2 whether GIFs FLTK
// loads itself (a file chooser's preview) are animated.
double ofl_image_setting(int32_t which) {
  switch (which) {
    case 1: return Fl_Image::scaling_algorithm();
    case 2: return Fl_GIF_Image::animate;
    default: return Fl_Anim_GIF_Image::min_delay;
  }
}

void ofl_image_set_setting(int32_t which, double v) {
  switch (which) {
    case 1:
      Fl_Image::scaling_algorithm(static_cast<Fl_RGB_Scaling>(v));
      break;
    case 2: Fl_GIF_Image::animate = v != 0; break;
    default: Fl_Anim_GIF_Image::min_delay = v; break;
  }
}

// Multi-labels

intptr_t ofl_multi_new() { return reinterpret_cast<intptr_t>(new Multi); }

void ofl_multi_close(intptr_t m) { multi(m)->close(); }

// Part i of m becomes, by kind: 0 nothing, 1 text s of label type t, 2
// the image p, 3 the multi-label p.
void ofl_multi_set(intptr_t m, int32_t i, int32_t kind, const char *s,
                   int32_t t, intptr_t p) {
  switch (kind) {
    case 1: {
      char *copy = strdup(s);
      if (copy == 0) return;
      multi(m)->set(i, static_cast<Fl_Labeltype>(t), copy, copy, 0);
      break;
    }
    case 2:
      multi(m)->set(i, FL_IMAGE_LABEL,
                    reinterpret_cast<const char *>(img(p)->image), 0, img(p));
      break;
    case 3:
      multi(m)->set(i, FL_MULTI_LABEL,
                    reinterpret_cast<const char *>(&multi(p)->ml), 0,
                    multi(p));
      break;
    default: multi(m)->set(i, FL_NO_LABEL, 0, 0, 0);
  }
}

int32_t ofl_multi_contains(intptr_t m, intptr_t n) {
  return multi(m)->contains(multi(n));
}

// Widget w shows multi-label m as its label, or no label if m is 0.
// Fl_Widget::label(type, value) doesn't free a label copy_label made, and
// leaves it marked to be freed (doc/fltk-issues.md, 55), so label(0)
// frees it first.
void ofl_widget_multi_label(intptr_t w, intptr_t m) {
  Fl_Widget *wd = ofl::widget(w);
  wd->label(static_cast<const char *>(0));
  if (m) {
    wd->label(FL_MULTI_LABEL, reinterpret_cast<const char *>(&multi(m)->ml));
  } else {
    wd->labeltype(FL_NORMAL_LABEL);
  }
  ofl::ref_of(wd)->hold(ofl::Ref::label, m ? multi(m) : 0);
  wd->redraw();
}

// Item i of menu mn shows, by kind: 0 its text, 1 the image p, 2 the
// multi-label p. The item gets an ofl::ItemLabel, which takes its text
// (Fl_Menu_::insert's own copy) as its name.
void ofl_menu_item_label(intptr_t mn, int32_t i, int32_t kind, intptr_t p) {
  Fl_Menu_ *m = ofl::as<Fl_Menu_>(mn);
  Fl_Menu_Item *it = const_cast<Fl_Menu_Item *>(m->menu()) + i;
  char *name;
  if (ofl::ItemLabel *old = ofl::item_label(m, it)) {
    name = strdup(old->name);
    if (name == 0) return;
  } else {
    name = const_cast<char *>(it->text);
  }
  if (kind == 0) {
    it->label(FL_NORMAL_LABEL, name);
  } else {
    ofl::ItemLabel *l;
    if (kind == 1) {
      l = new ofl::ItemLabel(name, img(p));
      l->ml.typea = FL_IMAGE_LABEL;
      l->ml.labela = reinterpret_cast<const char *>(img(p)->image);
    } else {
      l = new ofl::ItemLabel(name, multi(p));
      l->ml.typea = FL_MULTI_LABEL;
      l->ml.labela = reinterpret_cast<const char *>(&multi(p)->ml);
    }
    ofl::ref_of(m)->keep(l, &l->ml);
    l->close();  // the menu's hold is its only one
    it->label(FL_MULTI_LABEL, reinterpret_cast<const char *>(&l->ml));
  }
  ofl::drop_item_labels(m);
  m->redraw();
}

// Surfaces: drawing into an image, offscreen, or for the clipboard. A
// handle is the Fl_Widget_Surface of either; FlImages' Surface always
// holds an Fl_Image_Surface.

static Fl_Widget_Surface *surface(intptr_t s) {
  return reinterpret_cast<Fl_Widget_Surface *>(s);
}

static Fl_Image_Surface *image_surface(intptr_t s) {
  return static_cast<Fl_Image_Surface *>(surface(s));
}

intptr_t ofl_surface_new(int32_t w, int32_t h) {
  return reinterpret_cast<intptr_t>(
      static_cast<Fl_Widget_Surface *>(new Fl_Image_Surface(w, h)));
}

// The display must be open: X11's clipboard is written with it
// (doc/fltk-issues.md, 49).
intptr_t ofl_copy_new(int32_t w, int32_t h) {
  fl_open_display();
  return reinterpret_cast<intptr_t>(
      static_cast<Fl_Widget_Surface *>(new Fl_Copy_Surface(w, h)));
}

// An Fl_Copy_Surface writes the clipboard as it is deleted.
void ofl_surface_close(intptr_t s) { delete surface(s); }

// Makes the surface where drawing goes, or the one before it again.
void ofl_surface_begin(intptr_t s) {
  Fl_Surface_Device::push_current(surface(s));
}

void ofl_surface_end() { Fl_Surface_Device::pop_current(); }

// Whether drawing goes to it now: FlPrint's surfaces nest with these.
int32_t ofl_surface_current(intptr_t s) {
  return surface(s)->is_current() ? 1 : 0;
}

// Draws widget w with its top left at x, y.
void ofl_surface_draw(intptr_t s, intptr_t w, int32_t x, int32_t y) {
  surface(s)->draw(ofl::widget(w), x, y);
}

void ofl_surface_decorated(intptr_t s, intptr_t w, int32_t x, int32_t y) {
  surface(s)->draw_decorated_window(ofl::widget(w)->as_window(), x, y);
}

// What has been drawn, as a new image.
intptr_t ofl_surface_image(intptr_t s) {
  return make(image_surface(s)->image());
}

// 0 if i isn't 3 bytes a pixel, which FLTK takes as such and overruns
// (doc/fltk-issues.md, 137).
int32_t ofl_surface_mask(intptr_t s, intptr_t i) {
  Fl_RGB_Image *m = img(i)->rgb();
  if (!m || m->d() != 3) return 0;
  image_surface(s)->mask(m);
  return 1;
}

// The size of what is drawn on; 0 if nothing is, or it can't be told.
bool drawn_on(int &w, int &h) {
  Fl_Surface_Device *d = Fl_Surface_Device::surface();
  if (d != Fl_Display_Device::display_device()) {
    Fl_Widget_Surface *s = dynamic_cast<Fl_Widget_Surface *>(d);
    return s != 0 && s->printable_rect(&w, &h) == 0;
  }
  Fl_Window *c = Fl_Window::current();
  for (Fl_Window *o = Fl::first_window(); c && o; o = Fl::next_window(o)) {
    if (o == c) {
      w = c->w();
      h = c->h();
      return true;
    }
  }
  return false;
}

// As much as is there of the w by h pixels at x, y of the surface drawn
// on, as a new RGB image (RGBA if alpha); 0 if none is, or FLTK couldn't
// read them. Past the edge FLTK reads outside its buffer
// (doc/fltk-issues.md, 127).
intptr_t ofl_read_image(int32_t x, int32_t y, int32_t w, int32_t h,
                        int32_t alpha) {
  int sw, sh;
  if (!drawn_on(sw, sh)) return 0;
  int r = x < sw - w ? x + w : sw;
  int b = y < sh - h ? y + h : sh;
  if (x < 0) x = 0;
  if (y < 0) y = 0;
  if (r <= x || b <= y) return 0;
  w = r - x;
  h = b - y;
  unsigned char *p = fl_read_image(0, x, y, w, h, alpha ? 255 : 0);
  if (p == 0) return 0;
  Fl_RGB_Image *i = new Fl_RGB_Image(p, w, h, alpha ? 4 : 3);
  i->alloc_array = 1;
  return make(i);
}

// Shared images

// Name's image from the pool, loaded if it isn't there: at its own size if
// w is 0, or else w by h, an entry of its own. 0 if it can't be loaded.
// Get's reference to the original is the caller's until an entry of
// another size holds its own.
intptr_t ofl_shared_get(const char *name, int32_t w, int32_t h) {
  Fl_Shared_Image *o = original(name);
  if (o == 0) return 0;
  if (w == 0) return wrap(o);
  Fl_Shared_Image *s = Fl_Shared_Image::get(name, w, h);
  o->release();
  return wrap(s);
}

// Name's image if the pool has it, at that size if w isn't 0, else 0.
intptr_t ofl_shared_find(const char *name, int32_t w, int32_t h) {
  return wrap(Fl_Shared_Image::find(name, w, h));
}

// A new entry, with a name FLTK makes up, holding a copy of RGB image i: the
// pool keeps what it is given, and i may close first. 0 if it isn't RGB.
intptr_t ofl_shared_of_image(intptr_t i) {
  Fl_RGB_Image *r = dynamic_cast<Fl_RGB_Image *>(img(i)->inner());
  if (r == 0) return 0;
  return wrap(Fl_Shared_Image::get(static_cast<Fl_RGB_Image *>(r->copy()), 1));
}

int32_t ofl_shared_count() { return Fl_Shared_Image::num_images(); }

int32_t ofl_shared_refcount(intptr_t s) { return shared(s)->refcount(); }

int32_t ofl_shared_original(intptr_t s) { return shared(s)->original(); }

void ofl_shared_name(intptr_t s, char *buf, int32_t n) {
  ofl::copy_out(shared(s)->name(), buf, n);
}

// Reads s's file again. An entry of another size keeps that size, by which
// the pool finds it (doc/fltk-issues.md, 83). 0 if it can't be read, and s
// is as it was.
int32_t ofl_shared_reload(intptr_t s) {
  Fl_Shared_Image *m = shared(s);
  Fl_Image *i = load_shared(m->name());
  if (i == 0) return 0;
  if (!m->original()) {
    Fl_Image *c = i->copy(m->data_w(), m->data_h());
    i->release();
    i = c;
  }
  Pool::replace(m, i);
  ++generation;
  return 1;
}

void ofl_register_images() { fl_register_images(); }

// FLTK ignores a handler it has, so this can be called for each one.
void ofl_add_image_handler(intptr_t (*f)(const char *, const char *, int32_t)) {
  ask_oberon = f;
  Fl_Shared_Image::add_handler(ask_handlers);
}

// File icons

// A new icon for files matching pattern, first on FLTK's list. FLTK keeps
// the pattern's pointer, and never frees it.
intptr_t ofl_file_icon_new(const char *pattern, int32_t type) {
  return reinterpret_cast<intptr_t>(new Fl_File_Icon(strdup(pattern), type));
}

void ofl_file_icon_free(intptr_t i) {
  char *p = const_cast<char *>(file_icon(i)->pattern());
  delete file_icon(i);
  free(p);
}

// Adds to the icon. what: 0 the code a, 1 the color a, 2 the vertex a, b,
// 3 an outlined polygon of color a.
void ofl_file_icon_add(intptr_t i, int32_t what, int32_t a, int32_t b) {
  Fl_File_Icon *f = file_icon(i);
  switch (what) {
    case 0: f->add(static_cast<short>(a)); break;
    case 1: f->add_color(static_cast<Fl_Color>(a)); break;
    case 2: f->add_vertex(a, b); break;
    default:
      f->add(Fl_File_Icon::OUTLINEPOLYGON);
      f->add(static_cast<short>(a >> 16));
      f->add(static_cast<short>(a));
  }
}

void ofl_file_icon_clear(intptr_t i) { file_icon(i)->clear(); }

// Adds file name's picture to the icon: an SGI .fti, or else an image of a
// kind ofl_image_load reads, not a bitmap. load_fti reports through
// Fl::error, and load_image reads past what it can't convert or crashes
// (doc/fltk-issues.md, 86), so this does what load_image does on RGB pixels.
int32_t ofl_file_icon_load(intptr_t i, const char *name) {
  Fl_File_Icon *f = file_icon(i);
  const char *ext = fl_filename_ext(name);
  if (strcmp(ext, ".fti") == 0) {
    FILE *check = fopen(name, "rb");
    if (check == 0) return 0;
    fclose(check);
    void (*saved)(const char *, ...) = Fl::error;
    Fl::error = count_error;
    icon_errors = 0;
    int bad = f->load_fti(name);
    Fl::error = saved;
    if (bad == 0 && icon_errors == 0) return 1;
    f->clear();
    return 0;
  }
  Fl_Image *m = load_file(name);
  if (m == 0) return 0;
  Img *p = new Img(m);
  Fl_RGB_Image *r = p->rgb();
  if (r) add_rows(f, r);
  p->close();
  return r != 0;
}

void ofl_file_icon_load_system() { Fl_File_Icon::load_system_icons(); }

intptr_t ofl_file_icon_find(const char *name, int32_t type) {
  return reinterpret_cast<intptr_t>(Fl_File_Icon::find(name, type));
}

intptr_t ofl_file_icon_first() {
  return reinterpret_cast<intptr_t>(Fl_File_Icon::first());
}

intptr_t ofl_file_icon_next(intptr_t i) {
  return reinterpret_cast<intptr_t>(file_icon(i)->next());
}

void ofl_file_icon_draw(intptr_t i, int32_t x, int32_t y, int32_t w, int32_t h,
                        uint32_t color, int32_t active) {
  file_icon(i)->draw(x, y, w, h, color, active);
}

// Widget w shows icon i as its label. Fl_File_Icon::label sets no measure
// (doc/fltk-issues.md, 85), and leaves a copied label to be freed with
// the icon's address.
void ofl_file_icon_label(intptr_t i, intptr_t w) {
  Fl_Widget *wd = ofl::widget(w);
  Fl::set_labeltype(_FL_ICON_LABEL, Fl_File_Icon::labeltype, measure_icon);
  wd->label(static_cast<const char *>(0));
  wd->label(_FL_ICON_LABEL, reinterpret_cast<const char *>(file_icon(i)));
  ofl::ref_of(wd)->hold(ofl::Ref::label, 0);
  wd->redraw();
}

int32_t ofl_file_icon_size(intptr_t i) { return file_icon(i)->size(); }

int32_t ofl_file_icon_type(intptr_t i) { return file_icon(i)->type(); }

void ofl_file_icon_pattern(intptr_t i, char *buf, int32_t n) {
  ofl::copy_out(file_icon(i)->pattern(), buf, n);
}

// Adds a line to file browser b, showing icon i, or none if i is 0.
void ofl_file_browser_add(intptr_t b, const char *s, intptr_t i) {
  ofl::as<Fl_Browser>(b)->add(s, reinterpret_cast<void *>(i));
}

// Line of file browser b shows icon i, or none if i is 0.
void ofl_file_browser_icon(intptr_t b, int32_t line, intptr_t i) {
  Fl_Browser *br = ofl::as<Fl_Browser>(b);
  br->data(line, reinterpret_cast<void *>(i));
  br->redraw();
}

}  // extern "C"
