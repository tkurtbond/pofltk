// The C++ part of the examples' GlThree module: GLEW, and what FLTK's two
// OpenGL 3 examples draw with. The shaders and data are theirs.

#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include <FL/Fl.H>
#include <FL/platform.H>
#include <GL/glew.h>
#include <FL/gl.h>

namespace {

GLuint quad_program, quad_array, quad_buffer;
GLint position_uniform;
float factor = 1.1f;

GLuint triangle_arrays[2];
GLuint triangle_buffers[3];

const GLfloat vertices[] = {-1.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f, 0.0f, 0.0f};
const GLfloat colours[] = {1.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f, 0.0f, 1.0f};
const GLfloat vertices2[] = {0.0f, 0.0f, 0.0f, 0.0f, -1.0f, 0.0f, 1.0f, 0.0f, 0.0f};

void add(char *log, int32_t n, const char *name, const char *text) {
  size_t used = strlen(log);
  snprintf(log + used, n - used, "%s%s\n", name, text);
}

void compile(GLuint shader, const char *source, char *log, int32_t n, const char *name) {
  GLint ok;
  GLchar text[1000];
  glShaderSource(shader, 1, &source, NULL);
  glCompileShader(shader);
  glGetShaderiv(shader, GL_COMPILE_STATUS, &ok);
  if (ok != GL_TRUE) {
    glGetShaderInfoLog(shader, sizeof(text), NULL, text);
    add(log, n, name, text);
  }
}

// FLTK's example, whose lines stay at -0.5 to -0.88.
void stretch(int offset) {
  GLfloat data[4];
  glGetBufferSubData(GL_ARRAY_BUFFER, offset * sizeof(GLfloat), sizeof(data), data);
  data[0] *= factor;
  glBufferSubData(GL_ARRAY_BUFFER, offset * sizeof(GLfloat), sizeof(data), data);
}

void compile_triangle(GLuint shader, const char *source, const char *name) {
  GLint compiled;
  glShaderSource(shader, 1, &source, NULL);
  glCompileShader(shader);
  glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
  if (!compiled) {
    GLchar text[1000];
    fprintf(stderr, "%s shader not compiled.\n", name);
    glGetShaderInfoLog(shader, sizeof(text), NULL, text);
    fprintf(stderr, "InfoLog:\n%s\n", text);
  }
}

void fill(GLuint buffer, const GLfloat *data, GLuint attribute) {
  glBindBuffer(GL_ARRAY_BUFFER, buffer);
  glBufferData(GL_ARRAY_BUFFER, 9 * sizeof(GLfloat), data, GL_STATIC_DRAW);
  glVertexAttribPointer(attribute, 3, GL_FLOAT, GL_FALSE, 0, 0);
  glEnableVertexAttribArray(attribute);
}

}  // namespace

extern "C" {

// 1 if GLEW has GL's functions. It takes a current context.
int32_t ofl_gl3_glew_init(void) {
  GLenum err = glewInit();
#ifdef FLTK_USE_WAYLAND
  // glewInit returns GLEW_ERROR_NO_GLX_DISPLAY with Wayland: see
  // https://github.com/nigels-com/glew/issues/273
  if (fl_wl_display() && err == GLEW_ERROR_NO_GLX_DISPLAY) err = GLEW_OK;
#endif
  if (err != GLEW_OK) Fl::warning("glewInit() failed returning %u", err);
  return err == GLEW_OK;
}

void ofl_gl3_glew_version(char *s, int32_t n) {
  snprintf(s, n, "%s", reinterpret_cast<const char *>(glewGetString(GLEW_VERSION)));
}

void ofl_gl3_err(const char *s) {
  fputs(s, stderr);
}

int32_t ofl_gl3_has_quad(void) { return quad_program != 0; }

// Makes the quad of OpenGL3test.cxx, whose messages go in log.
void ofl_gl3_make_quad(char *log, int32_t n) {
  int major = 0, minor = 0;
  char line[64];
  log[0] = 0;
  sscanf(reinterpret_cast<const char *>(glGetString(GL_SHADING_LANGUAGE_VERSION)), "%d.%d", &major, &minor);
  snprintf(line, sizeof(line), "%d.%d", major, minor);
  add(log, n, "Shading Language Version=", line);
  char vss[300], fss[200];
  snprintf(vss, sizeof(vss), "#version %d%d\n\
      uniform vec2 p;\
      in vec4 position;\
      in vec4 colour;\
      out vec4 colourV;\
      void main (void)\
      {\
      colourV = colour;\
      gl_Position = vec4(p, 0.0, 0.0) + position;\
      }", major, minor);
  snprintf(fss, sizeof(fss), "#version %d%d\n\
      in vec4 colourV;\
      out vec4 fragColour;\
      void main(void)\
      {\
      fragColour = colourV;\
      }", major, minor);
  GLuint vs = glCreateShader(GL_VERTEX_SHADER);
  compile(vs, vss, log, n, "vs ShaderInfoLog=");
  GLuint fs = glCreateShader(GL_FRAGMENT_SHADER);
  compile(fs, fss, log, n, "fs ShaderInfoLog=");
  quad_program = glCreateProgram();
  glAttachShader(quad_program, vs);
  glAttachShader(quad_program, fs);
  glBindFragDataLocation(quad_program, 0, "fragColour");
  glLinkProgram(quad_program);
  GLint ok;
  glGetProgramiv(quad_program, GL_LINK_STATUS, &ok);
  if (ok != GL_TRUE) {
    GLchar text[1000];
    glGetProgramInfoLog(quad_program, sizeof(text), NULL, text);
    add(log, n, "link log=", text);
  }
  position_uniform = glGetUniformLocation(quad_program, "p");
  GLint colour = glGetAttribLocation(quad_program, "colour");
  GLint position = glGetAttribLocation(quad_program, "position");
  glDeleteShader(vs);
  glDeleteShader(fs);
  // vertices, the first four values of a row, and colours, the other four
  static const GLfloat data[] = {
    -0.5, -0.5, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0,
    -0.5, 0.5, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0,
    0.5, 0.5, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
    0.5, -0.5, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0};
  glGenVertexArrays(1, &quad_array);
  glBindVertexArray(quad_array);
  glGenBuffers(1, &quad_buffer);
  glBindBuffer(GL_ARRAY_BUFFER, quad_buffer);
  glBufferData(GL_ARRAY_BUFFER, sizeof(data), data, GL_STATIC_DRAW);
  glEnableVertexAttribArray(static_cast<GLuint>(position));
  glEnableVertexAttribArray(static_cast<GLuint>(colour));
  glVertexAttribPointer(static_cast<GLuint>(position), 4, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), 0);
  glVertexAttribPointer(static_cast<GLuint>(colour), 4, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat),
                        reinterpret_cast<const void *>(4 * sizeof(GLfloat)));
  glUseProgram(quad_program);
}

void ofl_gl3_draw_quad(void) {
  if (quad_program) {
    GLfloat p[] = {0, 0};
    glUniform2fv(position_uniform, 1, p);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
  }
}

// A click: moves two corners of the quad, in and out between two sizes.
void ofl_gl3_push_quad(void) {
  if (!quad_program) return;
  GLfloat first;
  glGetBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(first), &first);
  if (first < -0.88 || first > -0.5) factor = 1 / factor;
  stretch(0);
  stretch(24);
}

// For a new context: what the old one held went with it.
void ofl_gl3_reset_quad(void) { quad_program = 0; }

// The two triangles of OpenGL3-glut-test.cxx.
void ofl_gl3_make_triangles(void) {
  glClearColor(1.0, 1.0, 1.0, 0.0);
  GLuint v = glCreateShader(GL_VERTEX_SHADER);
  GLuint f = glCreateShader(GL_FRAGMENT_SHADER);
  compile_triangle(v, "#version 130\n\
  in  vec3 in_Position;\
  in  vec3 in_Color;\
  out vec3 ex_Color;\
  void main(void)\
  {\
    ex_Color = in_Color;\
    gl_Position = vec4(in_Position, 1.0);\
  }", "Vertex");
  compile_triangle(f, "#version 130\n\
  precision highp float;\
  in  vec3 ex_Color;\
  out vec4 out_Color;\
  void main(void)\
  {\
    out_Color = vec4(ex_Color,1.0);\
  }", "Fragment");
  GLuint p = glCreateProgram();
  glAttachShader(p, v);
  glAttachShader(p, f);
  glBindAttribLocation(p, 0, "in_Position");
  glBindAttribLocation(p, 1, "in_Color");
  glLinkProgram(p);
  GLint linked;
  glGetProgramiv(p, GL_LINK_STATUS, &linked);
  if (linked != GL_TRUE) {
    GLchar text[1000];
    glGetProgramInfoLog(p, sizeof(text), NULL, text);
    fprintf(stderr, "Link log=%s\n", text);
  }
  glUseProgram(p);

  glGenVertexArrays(2, triangle_arrays);
  glBindVertexArray(triangle_arrays[0]);
  glGenBuffers(3, triangle_buffers);
  fill(triangle_buffers[0], vertices, 0);
  fill(triangle_buffers[1], colours, 1);
  glBindVertexArray(triangle_arrays[1]);
  fill(triangle_buffers[2], vertices2, 0);
  glBindVertexArray(0);
}

void ofl_gl3_draw_triangles(void) {
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  glBindVertexArray(triangle_arrays[0]);
  glDrawArrays(GL_TRIANGLES, 0, 3);
  glBindVertexArray(triangle_arrays[1]);
  glVertexAttrib3f(1, 1.0, 0.0, 0.0);  // one color for the second
  glDrawArrays(GL_TRIANGLES, 0, 3);
}

}  // extern "C"
