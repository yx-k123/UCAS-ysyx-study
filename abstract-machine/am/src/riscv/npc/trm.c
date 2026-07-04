#include <am.h>
#include <klib.h>
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

static inline uint32_t read_mvendorid(void) {
  uint32_t value;
  asm volatile("csrr %0, mvendorid" : "=r"(value));
  return value;
}

static inline uint32_t read_marchid(void) {
  uint32_t value;
  asm volatile("csrr %0, marchid" : "=r"(value));
  return value;
}

static inline uint32_t read_mcycle(void) {
  uint32_t value;
  asm volatile("csrr %0, mcycle" : "=r"(value));
  return value;
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
  // uint32_t mvendorid = read_mvendorid();
  // uint32_t marchid = read_marchid();
  // uint32_t cycle0 = read_mcycle();
  // uint32_t cycle1 = read_mcycle();
  // uint32_t cycle2 = read_mcycle();
  // printf("boot csr: mvendorid=0x%x marchid=0x%x mcycle=%u,%u,%u\n",
  //     mvendorid, marchid, cycle0, cycle1, cycle2);

  int ret = main(mainargs);
  halt(ret);
}
