#include <am.h>
#include <nemu.h>

#define SYNC_ADDR (VGACTL_ADDR + 4)

void __am_gpu_init() {
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  uint32_t info = inl(VGACTL_ADDR);
  int w = info >> 16;
  int h = info & 0xffff;
  *cfg = (AM_GPU_CONFIG_T) {
    .present = true, .has_accel = false,
    .width = w, .height = h,
    .vmemsz = w * h * sizeof(uint32_t)
  };
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
  uint32_t info = inl(VGACTL_ADDR);
  int screen_w = info >> 16;
  int screen_h = info & 0xffff;
  int x = ctl->x;
  int y = ctl->y;
  int w = ctl->w;
  int h = ctl->h;

  if (ctl->pixels != NULL && w > 0 && h > 0 && x < screen_w && y < screen_h) {
    int copy_w = w;
    int copy_h = h;
    if (x + copy_w > screen_w) copy_w = screen_w - x;
    if (y + copy_h > screen_h) copy_h = screen_h - y;

    if (copy_w > 0 && copy_h > 0) {
      uint32_t *fb = (uint32_t *)(uintptr_t)FB_ADDR;
      uint32_t *src = (uint32_t *)ctl->pixels;
      for (int j = 0; j < copy_h; j ++) {
        uint32_t *dst = fb + (y + j) * screen_w + x;
        uint32_t *row = src + j * w;
        for (int i = 0; i < copy_w; i ++) {
          dst[i] = row[i];
        }
      }
    }
  }
  if (ctl->sync) {
    outl(SYNC_ADDR, 1);
  }
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}
