#include <am.h>
#include <klib.h>
#include <klib-macros.h>

int main(const char *args);

extern char _heap_start;
extern char _heap_end;
extern char _data_load_start;
extern char _data_start;
extern char _data_end;
extern char _bss_start;
extern char _bss_end;

Area heap = RANGE(&_heap_start, &_heap_end);
static const char mainargs[MAINARGS_MAX_LEN] = TOSTRING(MAINARGS_PLACEHOLDER);

#define UART_ADDR 0x10000000u

static inline void mmio_write8(uintptr_t addr, uint8_t data) {
  *(volatile uint8_t *)addr = data;
}

static void init_ram_sections(void) {
  uint8_t *src = (uint8_t *)&_data_load_start;
  uint8_t *dst = (uint8_t *)&_data_start;
  while (dst < (uint8_t *)&_data_end) {
    *dst++ = *src++;
  }

  for (uint8_t *p = (uint8_t *)&_bss_start; p < (uint8_t *)&_bss_end; p++) {
    *p = 0;
  }
}

void putch(char ch) {
  mmio_write8(UART_ADDR, (uint8_t)ch);
}

__attribute__((noreturn)) void halt(int code) {
  register int a0 asm("a0") = code;
  asm volatile("ebreak" : : "r"(a0));
  while (1) { }
}

void _trm_init() {
  init_ram_sections();
  int ret = main(mainargs);
  halt(ret);
}
