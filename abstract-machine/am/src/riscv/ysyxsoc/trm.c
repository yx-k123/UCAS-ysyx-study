#include <am.h>
#include <klib.h>
#include <klib-macros.h>

int main(const char *args);

extern char _heap_start;
extern char _heap_end;
extern char _ram_image_load_start;
extern char _ram_image_start;
extern char _ram_image_end;
extern char _data_load_start;
extern char _data_start;
extern char _data_end;
extern char _bss_start;
extern char _bss_end;

Area heap = RANGE(&_heap_start, &_heap_end);
static const char mainargs[MAINARGS_MAX_LEN] = TOSTRING(MAINARGS_PLACEHOLDER);

#define UART_ADDR 0x10000000u
#define UART_REG_THR 0x0u
#define UART_REG_DLL 0x0u
#define UART_REG_DLM 0x1u
#define UART_REG_FCR 0x2u
#define UART_REG_LCR 0x3u
#define UART_REG_LSR 0x5u

#define UART_LCR_8N1 0x03u
#define UART_LCR_DLAB 0x80u
#define UART_FCR_CLEAR_FIFO 0x06u
#define UART_LSR_THRE 0x20u
#define UART_DIVISOR 0x0001u

static inline void mmio_write8(uintptr_t addr, uint8_t data) {
  *(volatile uint8_t *)addr = data;
}

static inline uint8_t mmio_read8(uintptr_t addr) {
  return *(volatile uint8_t *)addr;
}

static void init_ram_sections(void) {
  uint8_t *src = (uint8_t *)&_ram_image_load_start;
  uint8_t *dst = (uint8_t *)&_ram_image_start;
  while (dst < (uint8_t *)&_ram_image_end) {
    *dst++ = *src++;
  }

  for (uint8_t *p = (uint8_t *)&_bss_start; p < (uint8_t *)&_bss_end; p++) {
    *p = 0;
  }
}

static void uart_init(void) {
  mmio_write8(UART_ADDR + UART_REG_LCR, UART_LCR_DLAB);
  mmio_write8(UART_ADDR + UART_REG_DLL, (uint8_t)(UART_DIVISOR & 0xffu));
  mmio_write8(UART_ADDR + UART_REG_DLM, (uint8_t)(UART_DIVISOR >> 8));
  mmio_write8(UART_ADDR + UART_REG_LCR, UART_LCR_8N1);
  mmio_write8(UART_ADDR + UART_REG_FCR, UART_FCR_CLEAR_FIFO);
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

static void print_npc_identity(void) {
  printf("mvendorid=0x%x marchid=%u\n", read_mvendorid(), read_marchid());
}

void putch(char ch) {
  while ((mmio_read8(UART_ADDR + UART_REG_LSR) & UART_LSR_THRE) == 0) {
  }
  mmio_write8(UART_ADDR + UART_REG_THR, (uint8_t)ch);
}

__attribute__((noreturn)) void halt(int code) {
  register int a0 asm("a0") = code;
  asm volatile("ebreak" : : "r"(a0));
  while (1) { }
}

void _trm_init() {
  init_ram_sections();
  uart_init();
  print_npc_identity();
  int ret = main(mainargs);
  halt(ret);
}
