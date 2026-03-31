#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

int printf(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  char buf[4096];
  int ret = vsnprintf(buf, sizeof(buf), fmt, ap);
  va_end(ap);
  for (int i = 0; i < ret && buf[i]; i++) {
    putch(buf[i]);
  }
  return ret;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  return vsnprintf(out, 0x3fffffff, fmt, ap);
}

int sprintf(char *out, const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int ret = vsnprintf(out, 0x3fffffff, fmt, ap);
  va_end(ap);
  return ret;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int ret = vsnprintf(out, n, fmt, ap);
  va_end(ap);
  return ret;
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  int written = 0;
  out = (out == NULL) ? (char *)0 : out;
  n = (out == NULL) ? 0x3fffffff : n;
  
  for (const char *p = fmt; *p; p++) {
    if (*p != '%') {
      if (written < (int)n - 1) {
        if (out) out[written] = *p;
      }
      written++;
    } else {
      p++;
      if (*p == '%') {
        if (written < (int)n - 1) {
          if (out) out[written] = '%';
        }
        written++;
      } else if (*p == 'd' || *p == 'i') {
        int val = va_arg(ap, int);
        int len = 0;
        char buf[20];
        if (val < 0) {
          if (written < (int)n - 1) {
            if (out) out[written] = '-';
          }
          written++;
          val = -val;
        }
        if (val == 0) {
          buf[len++] = '0';
        } else {
          int tmp = val;
          while (tmp > 0) {
            buf[len++] = '0' + (tmp % 10);
            tmp /= 10;
          }
        }
        for (int i = len - 1; i >= 0; i--) {
          if (written < (int)n - 1) {
            if (out) out[written] = buf[i];
          }
          written++;
        }
      } else if (*p == 'u') {
        unsigned int val = va_arg(ap, unsigned int);
        int len = 0;
        char buf[20];
        if (val == 0) {
          buf[len++] = '0';
        } else {
          unsigned int tmp = val;
          while (tmp > 0) {
            buf[len++] = '0' + (tmp % 10);
            tmp /= 10;
          }
        }
        for (int i = len - 1; i >= 0; i--) {
          if (written < (int)n - 1) {
            if (out) out[written] = buf[i];
          }
          written++;
        }
      } else if (*p == 'x' || *p == 'X') {
        unsigned int val = va_arg(ap, unsigned int);
        int len = 0;
        char buf[20];
        char base = (*p == 'x') ? 'a' : 'A';
        if (val == 0) {
          buf[len++] = '0';
        } else {
          unsigned int tmp = val;
          while (tmp > 0) {
            int digit = tmp % 16;
            buf[len++] = (digit < 10) ? ('0' + digit) : (base - 10 + digit);
            tmp /= 16;
          }
        }
        for (int i = len - 1; i >= 0; i--) {
          if (written < (int)n - 1) {
            if (out) out[written] = buf[i];
          }
          written++;
        }
      } else if (*p == 's') {
        const char *str = va_arg(ap, const char *);
        while (*str) {
          if (written < (int)n - 1) {
            if (out) out[written] = *str;
          }
          written++;
          str++;
        }
      } else if (*p == 'c') {
        char c = (char)va_arg(ap, int);
        if (written < (int)n - 1) {
          if (out) out[written] = c;
        }
        written++;
      } else {
        if (written < (int)n - 1) {
          if (out) out[written] = *p;
        }
        written++;
      }
    }
  }
  
  if (out && written < (int)n) {
    out[written] = '\0';
  } else if (out && (int)n > 0) {
    out[n - 1] = '\0';
  }
  
  return written;
}

#endif
