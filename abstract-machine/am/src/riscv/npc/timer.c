#include <am.h>

#define TIME_ADDR 0x10000010u

static inline uint32_t mmio_read32(uintptr_t addr) {
  return *(volatile uint32_t *)addr;
}

static uint64_t read_time_us() {
  uint32_t lo = mmio_read32(TIME_ADDR);
  uint32_t hi = mmio_read32(TIME_ADDR + 4);
  return ((uint64_t)hi << 32) | lo;
}

static bool is_leap(int year) {
  if (year % 400 == 0) return true;
  if (year % 100 == 0) return false;
  return (year % 4 == 0);
}

void __am_timer_init() {
}

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
  uptime->us = read_time_us();
}

void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
  uint64_t us = read_time_us();
  uint64_t sec = us / 1000000ull;

  int year = 1970;
  uint64_t days = sec / 86400ull;
  uint64_t rem = sec % 86400ull;

  rtc->hour = (int)(rem / 3600ull);
  rem %= 3600ull;
  rtc->minute = (int)(rem / 60ull);
  rtc->second = (int)(rem % 60ull);

  while (1) {
    int ydays = is_leap(year) ? 366 : 365;
    if (days < (uint64_t)ydays) break;
    days -= ydays;
    year++;
  }

  static const int mdays[12] = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
  int month = 0;
  for (month = 0; month < 12; month++) {
    int dim = mdays[month];
    if (month == 1 && is_leap(year)) dim = 29;
    if (days < (uint64_t)dim) break;
    days -= dim;
  }

  rtc->year = year;
  rtc->month = month + 1;
  rtc->day = (int)days + 1;
}
