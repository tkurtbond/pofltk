// The C++ part of the examples' Pipe module: popen, and reading from it,
// and fopen, for a file read as a command's output is.

#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

namespace {
int last_error = 0;  // errno of the last open that failed
}

extern "C" {

intptr_t ofl_pipe_open(const char *cmd) {
  FILE *f = popen(cmd, "r");
  if (f == 0) { last_error = errno; return 0; }
  // stdio would read lines ahead, which Fl.WatchFd can't see: they would
  // wait for the command's next output.
  setvbuf(f, 0, _IONBF, 0);
  return reinterpret_cast<intptr_t>(f);
}

intptr_t ofl_pipe_open_file(const char *name) {
  FILE *f = fopen(name, "r");
  if (f == 0) last_error = errno;
  return reinterpret_cast<intptr_t>(f);
}

// strerror of the last open that failed, cut to n bytes.
void ofl_pipe_error(char *s, int32_t n) {
  if (n <= 0) return;
  snprintf(s, n, "%s", strerror(last_error));
}

int32_t ofl_pipe_fd(intptr_t f) {
  return fileno(reinterpret_cast<FILE *>(f));
}

void ofl_pipe_set_nonblocking(intptr_t f) {
  int fd = fileno(reinterpret_cast<FILE *>(f));
  fcntl(fd, F_SETFL, fcntl(fd, F_GETFL) | O_NONBLOCK);
}

// 1 if a line was read into s, n bytes.
int32_t ofl_pipe_read_line(intptr_t f, char *s, int32_t n) {
  if (fgets(s, n, reinterpret_cast<FILE *>(f)) != 0) return 1;
  s[0] = 0;
  return 0;
}

// Reads what is there, up to n - 1 bytes, into s, ended by a 0: the
// count, 0 at the end, -1 on an error, -2 if nothing is there yet.
int32_t ofl_pipe_read(intptr_t f, char *s, int32_t n) {
  if (n <= 0) return -1;
  ssize_t r = read(fileno(reinterpret_cast<FILE *>(f)), s, n - 1);
  if (r < 0) { s[0] = 0; return errno == EAGAIN || errno == EWOULDBLOCK ? -2 : -1; }
  s[r] = 0;
  return static_cast<int32_t>(r);
}

int32_t ofl_pipe_close(intptr_t f) {
  int r = pclose(reinterpret_cast<FILE *>(f));
  return r != -1 && WIFEXITED(r) ? WEXITSTATUS(r) : -1;
}

int32_t ofl_pipe_close_file(intptr_t f) {
  return fclose(reinterpret_cast<FILE *>(f)) == 0 ? 0 : -1;
}

}  // extern "C"
