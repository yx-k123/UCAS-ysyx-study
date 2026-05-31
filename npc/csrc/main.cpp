#include <assert.h>
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include <svdpi.h>
#include "Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <capstone/capstone.h>
#include <elf.h>

uint32_t *cpu_gpr = NULL;

static const uint32_t MEM_BASE = 0x80000000u;
static const uint32_t MEM_SIZE = 0x10000000u;  // 256 MiB
static const uint32_t UART_ADDR = 0x10000000u;
static const uint32_t TIME_ADDR = 0x10000010u;
static uint8_t pmem[MEM_SIZE];
static bool g_ebreak_hit = false;
static uint32_t g_ebreak_pc = 0;
static uint32_t g_ebreak_inst = 0;
static uint32_t g_ebreak_a0 = 0;

Vtop* g_top = NULL;

typedef struct {
  char name[128];
  uint32_t addr;
  uint32_t size;
} SymbolEntry;

static SymbolEntry syms[1024];
static int sym_cnt = 0;

static void init_ftrace(const char *elf_file) {
  FILE *fp = fopen(elf_file, "rb");
  if (!fp) {
    printf("ftrace: failed to open %s\n", elf_file);
    return;
  }

  Elf32_Ehdr ehdr;
  if (fread(&ehdr, 1, sizeof(Elf32_Ehdr), fp) != sizeof(Elf32_Ehdr)) {
    fclose(fp); return;
  }
  if (ehdr.e_ident[EI_MAG0] != ELFMAG0 || ehdr.e_ident[EI_MAG1] != ELFMAG1 || 
      ehdr.e_ident[EI_MAG2] != ELFMAG2 || ehdr.e_ident[EI_MAG3] != ELFMAG3) {
      fclose(fp); return;
  }

  Elf32_Shdr *shdrs = (Elf32_Shdr*)malloc(ehdr.e_shentsize * ehdr.e_shnum);
  fseek(fp, ehdr.e_shoff, SEEK_SET);
  if (fread(shdrs, ehdr.e_shentsize, ehdr.e_shnum, fp) != ehdr.e_shnum) {
    free(shdrs); fclose(fp); return;
  }

  Elf32_Shdr *symtab = NULL;
  Elf32_Shdr *strtab = NULL;
  for (int i = 0; i < ehdr.e_shnum; i++) {
    if (shdrs[i].sh_type == SHT_SYMTAB) {
      symtab = &shdrs[i];
      strtab = &shdrs[symtab->sh_link];
      break;
    }
  }

  if (symtab && strtab) {
    Elf32_Sym *syms_data = (Elf32_Sym*)malloc(symtab->sh_size);
    fseek(fp, symtab->sh_offset, SEEK_SET);
    if (fread(syms_data, 1, symtab->sh_size, fp) == symtab->sh_size) {
      char *strs = (char*)malloc(strtab->sh_size);
      fseek(fp, strtab->sh_offset, SEEK_SET);
      if (fread(strs, 1, strtab->sh_size, fp) == strtab->sh_size) {
        int num_syms = symtab->sh_size / symtab->sh_entsize;
        for (int i = 0; i < num_syms; i++) {
          if (ELF32_ST_TYPE(syms_data[i].st_info) == STT_FUNC) {
            if (sym_cnt < 1024) {
              strncpy(syms[sym_cnt].name, strs + syms_data[i].st_name, 127);
              syms[sym_cnt].addr = syms_data[i].st_value;
              syms[sym_cnt].size = syms_data[i].st_size;
              sym_cnt++;
            }
          }
        }
      }
      free(strs);
    }
    free(syms_data);
  }
  free(shdrs);
  fclose(fp);
  printf("ftrace: loaded %d functions from %s\n", sym_cnt, elf_file);
}

static const char* find_func_name(uint32_t pc) {
  for (int i = 0; i < sym_cnt; i++) {
    if (pc >= syms[i].addr && pc < syms[i].addr + syms[i].size) {
      return syms[i].name;
    }
  }
  return "???";
}

static int call_depth = 0;
static void print_indent() {
  for (int i = 0; i < call_depth; i++) printf("  ");
}

static csh handle;
static bool capstone_initialized = false;

#define ITRACE_BUF_SIZE 16
typedef struct {
  uint32_t pc;
  uint32_t inst;
} ItraceNode;

static ItraceNode itrace_buf[ITRACE_BUF_SIZE];
static int itrace_idx = 0;
static bool itrace_full = false;

static void itrace_record(uint32_t pc, uint32_t inst) {
  itrace_buf[itrace_idx].pc = pc;
  itrace_buf[itrace_idx].inst = inst;
  itrace_idx++;
  if (itrace_idx >= ITRACE_BUF_SIZE) {
    itrace_idx = 0;
    itrace_full = true;
  }
}

static void itrace_print(uint32_t error_pc) {
  printf("--- Instruction Trace ---\n");
  int count = itrace_full ? ITRACE_BUF_SIZE : itrace_idx;
  int start = itrace_full ? itrace_idx : 0;
  for (int i = 0; i < count; i++) {
    int idx = (start + i) % ITRACE_BUF_SIZE;
    uint32_t pc = itrace_buf[idx].pc;
    uint32_t inst = itrace_buf[idx].inst;
    if (pc == error_pc) {
      printf("--> pc: 0x%08x, inst: 0x%08x\n", pc, inst);
    } else {
      printf("    pc: 0x%08x, inst: 0x%08x\n", pc, inst);
    }
  }
  printf("-------------------------\n");
}

static bool expecting_call_dest = false;
static bool expecting_ret_dest = false;
static uint32_t caller_pc = 0;

extern "C" void trace_inst(int pc, int inst) {
  if (!capstone_initialized) {
    cs_open(CS_ARCH_RISCV, CS_MODE_RISCV32, &handle);
    capstone_initialized = true;
  }
  
  itrace_record(pc, inst);

  if (expecting_call_dest) {
     printf("ftrace: 0x%08x: ", caller_pc);
     print_indent();
     printf("--> %s\n", find_func_name(pc));
     call_depth++;
     expecting_call_dest = false;
  }
  if (expecting_ret_dest) {
     call_depth--;
     if (call_depth < 0) call_depth = 0;
     printf("ftrace: 0x%08x: ", caller_pc);
     print_indent();
     printf("<-- %s\n", find_func_name(caller_pc));
     expecting_ret_dest = false;
  }

  uint32_t opcode = inst & 0x7F;
  uint32_t rd = (inst >> 7) & 0x1F;
  uint32_t rs1 = (inst >> 15) & 0x1F;
  
  if (opcode == 0x6f || opcode == 0x67) {   // jal or jalr
     if (opcode == 0x67 && rd == 0 && rs1 == 1 && (uint32_t)inst == 0x00008067) {  // ret: jalr x0, x1, 0
         expecting_ret_dest = true;
         caller_pc = pc;
         // Actually, NEMU prints the returning func name. Let's fix this up later if needed.
     } else if (rd == 1) { // call
         expecting_call_dest = true;
         caller_pc = pc;
     }
  }

  cs_insn *insn;
  uint8_t *code = (uint8_t *)&inst;
  size_t size = 4;
  uint64_t address = pc;

  // 使用 Capstone 反汇编一条指令
  if (cs_disasm(handle, code, size, address, 1, &insn) > 0) {
    // 打印到环形缓冲区，或直接打印屏幕
    printf("itrace: 0x%08x: %08x    %s\t%s\n", pc, inst, insn[0].mnemonic, insn[0].op_str);
    cs_free(insn, 1);
  }
}

static uint64_t get_time_us() {
  struct timespec ts;
  clock_gettime(CLOCK_REALTIME, &ts);
  return (uint64_t)ts.tv_sec * 1000000ull + (uint64_t)ts.tv_nsec / 1000ull;
}

extern "C" void set_gpr_ptr(const svOpenArrayHandle r) {
  cpu_gpr = (uint32_t *)svGetArrayPtr(r);
}

void isa_reg_display() {
  const char *regs[] = {
    "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
    "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
    "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
    "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
  };
  
  if (cpu_gpr == NULL) return;

  for (int i = 0; i < 32; i++) {
    printf("%-4s: 0x%08x\n", regs[i], cpu_gpr[i]);
  }
}

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
    if (g_top) {
      itrace_print(g_top->debug_pc);
    }
    assert(0);
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
  printf("mtrace: [READ] addr=0x%08x\n", addr);
  if (addr == TIME_ADDR || addr == TIME_ADDR + 4) {
    uint64_t us = get_time_us();
    if (addr == TIME_ADDR) return (int)(us & 0xffffffffu);
    return (int)(us >> 32);
  }
  return (int)pmem_read32(addr);
}

extern "C" void pmem_write(int waddr, int wdata, char wmask) {
  uint32_t addr = ((uint32_t)waddr) & ~0x3u;
  printf("mtrace: [WRITE] addr=0x%08x data=0x%08x wmask=0x%02x\n", addr, (uint32_t)wdata, (uint8_t)wmask);
  if (addr == UART_ADDR) {
    uint8_t mask = (uint8_t)wmask;
    uint32_t data = (uint32_t)wdata;
    for (int i = 0; i < 4; i++) {
      if (mask & (1u << i)) {
        putchar((data >> (i * 8)) & 0xff);
      }
    }
    fflush(stdout);
    return;
  }
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
    int len = strlen(argv[2]);
    if (len > 4 && strcmp(argv[2] + len - 4, ".elf") == 0) {
      init_ftrace(argv[2]);
      if (argc >= 4) {
        uint32_t halt_addr = 0;
        if (parse_u32_hex(argv[3], &halt_addr)) {
          pmem_write_masked(halt_addr, 0x00100073u, 0x0f);
          printf("patched ebreak at 0x%08x\n", halt_addr);
        }
      }
    } else {
      uint32_t halt_addr = 0;
      if (!parse_u32_hex(argv[2], &halt_addr)) {
        printf("invalid halt_addr or elf: %s\n", argv[2]);
        return 1;
      }
      pmem_write_masked(halt_addr, 0x00100073u, 0x0f);
      printf("patched ebreak at 0x%08x\n", halt_addr);
    }
  }

  VerilatedContext* contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);
  Vtop* top = new Vtop{contextp};
  g_top = top;

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
      itrace_print(g_ebreak_pc);
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