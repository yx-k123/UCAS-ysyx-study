#include <assert.h>
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h"


static const uint32_t MEM_BASE = 0x80000000u;
static const uint32_t MEM_SIZE = 0x10000000u;  // 256 MiB
static uint8_t pmem[MEM_SIZE];
static bool g_ebreak_hit = false;
static uint32_t g_ebreak_pc = 0;
static uint32_t g_ebreak_inst = 0;
static uint32_t g_ebreak_a0 = 0;

extern "C" void npc_ebreak(unsigned int pc, unsigned int inst, unsigned int a0) {
  g_ebreak_hit = true;
  g_ebreak_pc = (uint32_t)pc;
  g_ebreak_inst = (uint32_t)inst;
  g_ebreak_a0 = (uint32_t)a0;
}

static inline bool in_pmem(uint32_t addr) {
  return addr >= MEM_BASE && addr + 3 < MEM_BASE + MEM_SIZE;
}

static uint32_t pmem_read32(uint32_t addr) {
  if (!in_pmem(addr)) {
    printf("read out of range: 0x%08x\n", addr);
    return 0;
  }
  uint32_t off = addr - MEM_BASE;
  return (uint32_t)pmem[off + 0] |
         ((uint32_t)pmem[off + 1] << 8) |
         ((uint32_t)pmem[off + 2] << 16) |
         ((uint32_t)pmem[off + 3] << 24);
}

static void pmem_write_masked(uint32_t addr, uint32_t data, uint8_t wmask) {
  if (!in_pmem(addr)) {
    printf("write out of range: 0x%08x\n", addr);
    return;
  }
  uint32_t off = addr - MEM_BASE;
  if (wmask & 0x1) pmem[off + 0] = (data >> 0) & 0xff;
  if (wmask & 0x2) pmem[off + 1] = (data >> 8) & 0xff;
  if (wmask & 0x4) pmem[off + 2] = (data >> 16) & 0xff;
  if (wmask & 0x8) pmem[off + 3] = (data >> 24) & 0xff;
}

extern "C" int pmem_read(int raddr) {
  uint32_t addr = ((uint32_t)raddr) & ~0x3u;
  return (int)pmem_read32(addr);
}

extern "C" void pmem_write(int waddr, int wdata, char wmask) {
  uint32_t addr = ((uint32_t)waddr) & ~0x3u;
  pmem_write_masked(addr, (uint32_t)wdata, (uint8_t)wmask);
}

static bool load_img(const char* img_path) {
  FILE* fp = fopen(img_path, "rb");
  if (fp == NULL) {
    printf("failed to open %s: %s\n", img_path, strerror(errno));
    return false;
  }

  if (fseek(fp, 0, SEEK_END) != 0) {
    fclose(fp);
    return false;
  }
  long size = ftell(fp);
  if (size < 0 || (uint32_t)size > MEM_SIZE) {
    printf("image too large: %ld bytes\n", size);
    fclose(fp);
    return false;
  }
  rewind(fp);

  memset(pmem, 0, sizeof(pmem));
  size_t n = fread(pmem, 1, (size_t)size, fp);
  fclose(fp);
  if (n != (size_t)size) {
    printf("failed to read full image, got %zu bytes\n", n);
    return false;
  }

  printf("loaded image %s (%ld bytes)\n", img_path, size);
  return true;
}

static bool parse_u32_hex(const char* s, uint32_t* out) {
  char* endp = NULL;
  unsigned long v = strtoul(s, &endp, 0);
  if (endp == s || *endp != '\0' || v > 0xfffffffful) {
    return false;
  }
  *out = (uint32_t)v;
  return true;
}

int main(int argc, char** argv) {
  if (argc < 2) {
    printf("usage: %s <image.bin> [halt_addr]\n", argv[0]);
    printf("example: %s /path/to/sum-riscv32e-npc.bin 0x100\n", argv[0]);
    return 1;
  }

  if (!load_img(argv[1])) {
    return 1;
  }

  if (argc >= 3) {
    uint32_t halt_addr = 0;
    if (!parse_u32_hex(argv[2], &halt_addr)) {
      printf("invalid halt_addr: %s\n", argv[2]);
      return 1;
    }
    pmem_write_masked(halt_addr, 0x00100073u, 0x0f);
    printf("patched ebreak at 0x%08x\n", halt_addr);
  }

  VerilatedContext* contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  Vtop* top = new Vtop{contextp};

  Verilated::traceEverOn(true);
  VerilatedVcdC* tfp = new VerilatedVcdC;
  top->trace(tfp, 99);
  const char* wave_path = "wave.vcd";
  tfp->open(wave_path);
  printf("wave dump: %s\n", wave_path);

  top->clk = 0;
  top->rst = 1;

  // Reset for one cycle.
  top->eval();
  tfp->dump(contextp->time());
  contextp->timeInc(1);
  top->clk = 1;
  top->eval();
  tfp->dump(contextp->time());
  contextp->timeInc(1);
  top->clk = 0;
  top->rst = 0;
  top->eval();
  tfp->dump(contextp->time());
  contextp->timeInc(1);

  int cycle = 0;
  int exit_code = 1;
  while (!contextp->gotFinish() && !g_ebreak_hit) {
    top->eval();
    tfp->dump(contextp->time());
    contextp->timeInc(1);

    top->clk = 1;
    top->eval();
    tfp->dump(contextp->time());
    contextp->timeInc(1);
    top->clk = 0;
    top->eval();
    tfp->dump(contextp->time());
    contextp->timeInc(1);

    cycle++;
    if (cycle > 1000000) {
      printf("timeout: no ebreak observed\n");
      break;
    }
  }

  if (g_ebreak_hit) {
    printf("ebreak at pc=0x%08x inst=0x%08x a0=%u\n", g_ebreak_pc, g_ebreak_inst, g_ebreak_a0);
    if (g_ebreak_a0 == 0) {
      printf("HIT GOOD TRAP\n");
      exit_code = 0;
    } else {
      printf("HIT BAD TRAP with exit code %u\n", g_ebreak_a0);
      exit_code = (int)g_ebreak_a0;
    }
  } else {
    printf("simulation stopped without ebreak\n");
    assert(0);
  }

  tfp->close();
  delete tfp;
  delete top;
  delete contextp;
  return exit_code;
}