// The C++ part of BreakCairo: cairo_pdf_surface_create_for_stream made to
// fail, which it does only out of memory, and the next file descriptor.
//
// The program's own cairo_pdf_surface_create_for_stream comes before
// cairo's, for FLTK's calls too, and passes on to cairo's (RTLD_NEXT)
// unless broken. cairo's headers aren't needed, nor -lcairo: the types are
// opaque here, and cairo's functions are found as FLTK has loaded them.

#include <dlfcn.h>
#include <fcntl.h>
#include <stdint.h>
#include <unistd.h>

typedef struct _cairo_surface cairo_surface_t;
typedef int (*cairo_write)(void *, const unsigned char *, unsigned int);

namespace {
bool broken = false;
}  // namespace

extern "C" {

cairo_surface_t *cairo_pdf_surface_create_for_stream(cairo_write write,
                                                     void *closure, double w,
                                                     double h) {
  if (broken) {
    // An image of no valid format is one of cairo's surfaces in error.
    typedef cairo_surface_t *(*image)(int, int, int);
    image make = reinterpret_cast<image>(
        dlsym(RTLD_DEFAULT, "cairo_image_surface_create"));
    return make(-2, 1, 1);
  }
  typedef cairo_surface_t *(*pdf)(cairo_write, void *, double, double);
  pdf real = reinterpret_cast<pdf>(
      dlsym(RTLD_NEXT, "cairo_pdf_surface_create_for_stream"));
  return real(write, closure, w, h);
}

void ofltest_break_pdf(int32_t on) { broken = on != 0; }

// The lowest file descriptor free: higher after a leak.
int32_t ofltest_next_fd() {
  int fd = open("/dev/null", O_RDONLY);
  if (fd >= 0) close(fd);
  return fd;
}

}  // extern "C"
