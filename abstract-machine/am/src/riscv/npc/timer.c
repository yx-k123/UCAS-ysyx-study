#include <am.h>

static uint64_t boot_cycle = 0;
static const uint64_t NPC_CLOCK_FREQ_HZ = 1000000ull;

static inline uint32_t read_mcycle(void) {
  uint32_t value;
  asm volatile("csrr %0, mcycle" : "=r"(value));
  return value;
}

static inline uint32_t read_mcycleh(void) {
  uint32_t value;
  asm volatile("csrr %0, mcycleh" : "=r"(value));
  return value;
}

static uint64_t read_cycle64(void) {
  uint32_t hi0 = 0;
  uint32_t hi1 = 0;
  uint32_t lo = 0;

  do {
    hi0 = read_mcycleh();
    lo = read_mcycle();
    hi1 = read_mcycleh();
  } while (hi0 != hi1);

  return ((uint64_t)hi1 << 32) | lo;
}

void __am_timer_init() {
  boot_cycle = read_cycle64();
}

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
  uint64_t cycles = read_cycle64() - boot_cycle;
  uptime->us = cycles / (NPC_CLOCK_FREQ_HZ / 1000000ull);
}

void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
  rtc->second = 0;
  rtc->minute = 0;
  rtc->hour   = 0;
  rtc->day    = 0;
  rtc->month  = 0;
  rtc->year   = 1900;
}
