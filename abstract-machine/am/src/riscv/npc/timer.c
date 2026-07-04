#include <am.h>

static uint64_t boot_mtime = 0;

static const uintptr_t MTIME_ADDR = 0x10000010ul;
static const uint64_t NPC_CLINT_FREQ_HZ = 1000000ull;

static inline uint32_t mmio_read32(uintptr_t addr) {
  return *(volatile uint32_t *)addr;
}

static uint64_t read_mtime64(void) {
  uint32_t hi0 = 0;
  uint32_t hi1 = 0;
  uint32_t lo = 0;

  do {
    hi0 = mmio_read32(MTIME_ADDR + 4);
    lo = mmio_read32(MTIME_ADDR + 0);
    hi1 = mmio_read32(MTIME_ADDR + 4);
  } while (hi0 != hi1);

  return ((uint64_t)hi1 << 32) | lo;
}

static inline uint64_t mtime_to_us(uint64_t ticks) {
  return ticks * 1000000ull / NPC_CLINT_FREQ_HZ;
}

void __am_timer_init() {
  boot_mtime = read_mtime64();
}

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
  uptime->us = mtime_to_us(read_mtime64() - boot_mtime);
}

void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
  rtc->second = 0;
  rtc->minute = 0;
  rtc->hour   = 0;
  rtc->day    = 0;
  rtc->month  = 0;
  rtc->year   = 1900;
}
