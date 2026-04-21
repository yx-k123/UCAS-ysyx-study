#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "Vtop.h"
#include "verilated.h"

static const uint32_t MEM_BASE = 0x00000000u;
static const uint32_t MEM_SIZE = 0x00010000u;
static uint8_t pmem[MEM_SIZE];

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

static void pmem_write(uint32_t addr, uint32_t data, uint8_t wmask) {
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

static void pmem_write_inst(uint32_t addr, uint32_t inst) {
  pmem_write(addr, inst, 0x0f);
}

static void load_demo_program() {
  memset(pmem, 0, sizeof(pmem));

  // addi x1, x0, 0x80
  pmem_write_inst(0x00, 0x08000093u);
  // addi x2, x0, 0x2a
  pmem_write_inst(0x04, 0x02a00113u);
  // sw x2, 0(x1)
  pmem_write_inst(0x08, 0x0020a023u);
  // lbu x3, 0(x1)
  pmem_write_inst(0x0c, 0x0000c183u);
  // add x4, x2, x3
  pmem_write_inst(0x10, 0x00310233u);
  // jalr x0, x0, 0x14 (jump to self)
  pmem_write_inst(0x14, 0x01400067u);
}

static void feed_memory_inputs(Vtop* top) {
  top->imem_rdata = pmem_read32(top->imem_addr);
  if (top->dmem_valid && !top->dmem_wen) {
    top->dmem_rdata = pmem_read32(top->dmem_addr);
  } else {
    top->dmem_rdata = 0;
  }
}

int main(int argc, char** argv) {
  VerilatedContext* contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  Vtop* top = new Vtop{contextp};

  load_demo_program();

  top->clk = 0;
  top->rst = 1;
  top->imem_rdata = 0;
  top->dmem_rdata = 0;

  // Reset for one cycle.
  top->eval();
  top->clk = 1;
  top->eval();
  top->clk = 0;
  top->rst = 0;

  for (int cycle = 0; cycle < 20; cycle++) {
    // 1) let RTL expose memory request address/control.
    top->eval();
    // 2) C++ memory returns read data combinationally.
    feed_memory_inputs(top);
    top->eval();

    if (top->dmem_valid && top->dmem_wen) {
      pmem_write(top->dmem_addr, top->dmem_wdata, (uint8_t)top->dmem_wmask);
    }

    printf("cycle=%02d pc=0x%08x inst=0x%08x dvalid=%d dwen=%d daddr=0x%08x\n",
           cycle,
           (uint32_t)top->debug_pc,
           (uint32_t)top->debug_inst,
           (int)top->dmem_valid,
           (int)top->dmem_wen,
           (uint32_t)top->dmem_addr);

    top->clk = 1;
    top->eval();
    top->clk = 0;
  }

  uint32_t mem_word = pmem_read32(0x80);
  printf("mem[0x80]=0x%08x (expect 0x0000002a)\n", mem_word);
  assert(mem_word == 0x0000002au);

  delete top;
  delete contextp;
  return 0;
}