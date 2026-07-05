/***************************************************************************************
* Copyright (c) 2014-2024 Zihao Yu, Nanjing University
*
* NEMU is licensed under Mulan PSL v2.
* You can use this software according to the terms and conditions of the Mulan PSL v2.
* You may obtain a copy of Mulan PSL v2 at:
*          http://license.coscl.org.cn/MulanPSL2
*
* THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
* EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
* MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
*
* See the Mulan PSL v2 for more details.
***************************************************************************************/

#include <memory/host.h>
#include <memory/paddr.h>
#include <device/mmio.h>
#include <isa.h>

#if   defined(CONFIG_PMEM_MALLOC)
static uint8_t *pmem = NULL;
#else // CONFIG_PMEM_GARRAY
static uint8_t pmem[CONFIG_MSIZE] PG_ALIGN = {};
#endif
static uint8_t mrom[MROM_SIZE] = {};
static uint8_t sram[SRAM_SIZE] = {};

uint8_t* guest_to_host(paddr_t paddr) { return pmem + paddr - CONFIG_MBASE; }
paddr_t host_to_guest(uint8_t *haddr) { return haddr - pmem + CONFIG_MBASE; }

static word_t pmem_read(paddr_t addr, int len) {
  word_t ret = host_read(guest_to_host(addr), len);
  return ret;
}

static void pmem_write(paddr_t addr, int len, word_t data) {
  host_write(guest_to_host(addr), len, data);
}

static inline uint8_t *mrom_guest_to_host(paddr_t addr) {
  return mrom + addr - MROM_LEFT;
}

static inline uint8_t *sram_guest_to_host(paddr_t addr) {
  return sram + addr - SRAM_LEFT;
}

static word_t mrom_read(paddr_t addr, int len) {
  return host_read(mrom_guest_to_host(addr), len);
}

static void mrom_write(paddr_t addr, int len, word_t data) {
  host_write(mrom_guest_to_host(addr), len, data);
}

static word_t sram_read(paddr_t addr, int len) {
  return host_read(sram_guest_to_host(addr), len);
}

static void sram_write(paddr_t addr, int len, word_t data) {
  host_write(sram_guest_to_host(addr), len, data);
}

static void __attribute__((unused)) out_of_bound(paddr_t addr) {
  panic("address = " FMT_PADDR " is out of bound of memory regions: "
      "pmem[" FMT_PADDR ", " FMT_PADDR "], "
      "mrom[" FMT_PADDR ", " FMT_PADDR "], "
      "sram[" FMT_PADDR ", " FMT_PADDR "] at pc = " FMT_WORD,
      addr, PMEM_LEFT, PMEM_RIGHT, MROM_LEFT, MROM_RIGHT, SRAM_LEFT, SRAM_RIGHT, cpu.pc);
}

void init_mem() {
#if   defined(CONFIG_PMEM_MALLOC)
  pmem = malloc(CONFIG_MSIZE);
  assert(pmem);
#endif
  IFDEF(CONFIG_MEM_RANDOM, memset(pmem, rand(), CONFIG_MSIZE));
  memset(mrom, 0, sizeof(mrom));
  memset(sram, 0, sizeof(sram));
  Log("physical memory area [" FMT_PADDR ", " FMT_PADDR "]", PMEM_LEFT, PMEM_RIGHT);
  Log("mrom area [" FMT_PADDR ", " FMT_PADDR "]", MROM_LEFT, MROM_RIGHT);
  Log("sram area [" FMT_PADDR ", " FMT_PADDR "]", SRAM_LEFT, SRAM_RIGHT);
}

word_t paddr_read(paddr_t addr, int len) {
  word_t ret;
  if (likely(in_pmem(addr))) {
    ret = pmem_read(addr, len);
  } else if (in_mrom(addr)) {
    ret = mrom_read(addr, len);
  } else if (in_sram(addr)) {
    ret = sram_read(addr, len);
  } else {
#ifdef CONFIG_DEVICE
    ret = mmio_read(addr, len);
#else
    out_of_bound(addr);
    ret = 0;
#endif
  }
#ifdef CONFIG_MTRACE
  if (MTRACE_COND) {
    log_write("MTRACE: [READ] pc = " FMT_WORD ", addr = " FMT_PADDR ", len = %d, data = " FMT_WORD "\n", cpu.pc, addr, len, ret);
  }
#endif
  return ret;
}

void paddr_write(paddr_t addr, int len, word_t data) {
  if (likely(in_pmem(addr))) { 
    pmem_write(addr, len, data); 
  } else if (in_mrom(addr)) {
    mrom_write(addr, len, data);
  } else if (in_sram(addr)) {
    sram_write(addr, len, data);
  } else {
#ifdef CONFIG_DEVICE
    mmio_write(addr, len, data);
#else
    out_of_bound(addr);
#endif
  }
#ifdef CONFIG_MTRACE
  if (MTRACE_COND) {
    log_write("MTRACE: [WRITE] pc = " FMT_WORD ", addr = " FMT_PADDR ", len = %d, data = " FMT_WORD "\n", cpu.pc, addr, len, data);
  }
#endif
}
