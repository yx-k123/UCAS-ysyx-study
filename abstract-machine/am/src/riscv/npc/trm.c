#include <am.h>
#include <klib-macros.h>

extern char _heap_start;
int main(const char *args);

extern char _pmem_start;
#define PMEM_SIZE (128 * 1024 * 1024)
#define PMEM_END  ((uintptr_t)&_pmem_start + PMEM_SIZE)

Area heap = RANGE(&_heap_start, PMEM_END);
static const char mainargs[MAINARGS_MAX_LEN] = TOSTRING(MAINARGS_PLACEHOLDER); // defined in CFLAGS

#define UART_ADDR 0x10000000u

static inline void mmio_write8(uintptr_t addr, uint8_t data) {
  *(volatile uint8_t *)addr = data;
}

void putch(char ch) {
  mmio_write8(UART_ADDR, (uint8_t)ch);
}

__attribute__((noreturn)) void halt(int code) {
  // NPC captures `a0` when `ebreak` is executed:
  //   a0 == 0  -> HIT GOOD TRAP
  //   a0 != 0  -> HIT BAD TRAP
  register int a0 asm("a0") = code;
  asm volatile("ebreak" : : "r"(a0));
  while (1) { }
}

void _trm_init() {
  int ret = main(mainargs);
  halt(ret);
}
