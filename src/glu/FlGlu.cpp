// The C++ part of FlGlu: GLU's view matrices and quadrics (FlGlu.Mod).

#include <FL/glu.h>
#include <stdint.h>

namespace {
GLUquadric *quad(intptr_t q) { return reinterpret_cast<GLUquadric *>(q); }
}  // namespace

extern "C" {

void ofl_glu_perspective(double fovy, double aspect, double n, double f) {
  gluPerspective(fovy, aspect, n, f);
}

void ofl_glu_look_at(double ex, double ey, double ez, double cx, double cy,
                     double cz, double ux, double uy, double uz) {
  gluLookAt(ex, ey, ez, cx, cy, cz, ux, uy, uz);
}

void ofl_glu_ortho2d(double l, double r, double b, double t) {
  gluOrtho2D(l, r, b, t);
}

void ofl_glu_pick_matrix(double x, double y, double w, double h,
                         const int32_t *viewport) {
  GLint v[4] = {viewport[0], viewport[1], viewport[2], viewport[3]};
  gluPickMatrix(x, y, w, h, v);
}

intptr_t ofl_glu_new_quadric(void) {
  return reinterpret_cast<intptr_t>(gluNewQuadric());
}

void ofl_glu_delete_quadric(intptr_t q) { gluDeleteQuadric(quad(q)); }

void ofl_glu_quadric_draw_style(intptr_t q, int32_t style) {
  gluQuadricDrawStyle(quad(q), style);
}

void ofl_glu_quadric_normals(intptr_t q, int32_t normals) {
  gluQuadricNormals(quad(q), normals);
}

void ofl_glu_quadric_orientation(intptr_t q, int32_t o) {
  gluQuadricOrientation(quad(q), o);
}

void ofl_glu_quadric_texture(intptr_t q, int32_t on) {
  gluQuadricTexture(quad(q), on ? GL_TRUE : GL_FALSE);
}

void ofl_glu_cylinder(intptr_t q, double base, double top, double height,
                      int32_t slices, int32_t stacks) {
  gluCylinder(quad(q), base, top, height, slices, stacks);
}

void ofl_glu_sphere(intptr_t q, double r, int32_t slices, int32_t stacks) {
  gluSphere(quad(q), r, slices, stacks);
}

void ofl_glu_disk(intptr_t q, double inner, double outer, int32_t slices,
                  int32_t loops) {
  gluDisk(quad(q), inner, outer, slices, loops);
}

void ofl_glu_partial_disk(intptr_t q, double inner, double outer,
                          int32_t slices, int32_t loops, double start,
                          double sweep) {
  gluPartialDisk(quad(q), inner, outer, slices, loops, start, sweep);
}

}  // extern "C"
