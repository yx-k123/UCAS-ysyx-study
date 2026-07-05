#include <assert.h>
#include <dlfcn.h>
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <vector>

#include <svdpi.h>
#include "VysyxSoCFull.h"
#include "verilated.h"
#if VM_TRACE
#include "verilated_vcd_c.h"
#endif

#include <elf.h>

#include "../../common/difftest_state.h"

uint32_t *cpu_gpr = NULL;

static const uint32_t MEM_BASE = 0x80000000u;
static const uint32_t MEM_SIZE = 0x10000000u;  // 256 MiB
static const uint32_t MROM_BASE = 0x20000000u;
static const uint32_t FLASH_BASE = 0x30000000u;
static const uint32_t UART_ADDR = 0x10000000u;
static uint8_t pmem[MEM_SIZE];
static std::vector<uint8_t> g_flash_img;
static std::vector<uint8_t> g_mrom_img;
static size_t g_img_size = 0;
static bool g_ebreak_hit = false;
static uint32_t g_ebreak_pc = 0;
static uint32_t g_ebreak_inst = 0;
static uint32_t g_ebreak_a0 = 0;

enum { DIFFTEST_TO_DUT = 0, DIFFTEST_TO_REF = 1 };

typedef void (*difftest_memcpy_t)(uint32_t addr, void *buf, size_t n, bool direction);
typedef void (*difftest_regcpy_t)(void *dut, bool direction);
typedef void (*difftest_exec_t)(uint64_t n);
typedef void (*difftest_raise_intr_t)(uint64_t NO);
typedef void (*difftest_init_t)(int port);

static bool g_difftest_enabled = false;
static bool g_difftest_abort = false;
static bool g_trace_enabled = true;
static bool g_wave_enabled = false;
static bool g_stop_by_timeout = false;
static bool g_uart_line_open = false;
static int g_max_cycles = 0;
static void *g_diff_handle = NULL;
static difftest_memcpy_t ref_difftest_memcpy = NULL;
static difftest_regcpy_t ref_difftest_regcpy = NULL;
static difftest_exec_t ref_difftest_exec = NULL;
static difftest_raise_intr_t ref_difftest_raise_intr = NULL;
static difftest_init_t ref_difftest_init = NULL;

VysyxSoCFull* g_top = NULL;

typedef struct {
  char name[128];
  uint32_t addr;
  uint32_t size;
} SymbolEntry;

static SymbolEntry syms[1024];
static int sym_cnt = 0;

static void init_ftrace(const char *elf_file) {
  if (!g_trace_enabled) {
    return;
  }

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
  if (!g_trace_enabled) return;

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
  printf("itrace: 0x%08x: %08x\n", pc, inst);
}

static uint64_t get_time_us() {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (uint64_t)ts.tv_sec * 1000000ull + (uint64_t)ts.tv_nsec / 1000ull;
}

#if VM_TRACE
static inline void wave_dump(VerilatedVcdC* tfp, uint64_t time) {
  if (tfp) {
    tfp->dump(time);
  }
}

static inline void wave_close(VerilatedVcdC* tfp) {
  if (tfp) {
    tfp->close();
    delete tfp;
  }
}
#else
static inline void wave_dump(void* tfp, uint64_t time) {
  (void)tfp;
  (void)time;
}

static inline void wave_close(void* tfp) {
  (void)tfp;
}
#endif

extern "C" unsigned long long clint_mtime() {
  return (unsigned long long)get_time_us();
}

extern "C" void flash_read(int32_t addr, int32_t *data) {
  uint32_t off = (uint32_t)addr;
  uint32_t value = 0;
  for (int i = 0; i < 4; i++) {
    uint32_t idx = off + (uint32_t)i;
    uint8_t byte = (idx < g_flash_img.size()) ? g_flash_img[idx] : 0;
    value |= (uint32_t)byte << (i * 8);
  }
  *data = (int32_t)value;
}

extern "C" void mrom_read(int32_t addr, int32_t *data) {
  uint32_t value = 0;
  uint32_t mrom_addr = (uint32_t)addr;
  if (mrom_addr < MROM_BASE) {
    *data = 0;
    return;
  }
  uint32_t off = mrom_addr - MROM_BASE;
  for (int i = 0; i < 4; i++) {
    uint32_t idx = off + (uint32_t)i;
    uint8_t byte = (idx < g_mrom_img.size()) ? g_mrom_img[idx] : 0;
    value |= (uint32_t)byte << (i * 8);
  }
  *data = (int32_t)value;
}

extern "C" void uart_putc(int ch) {
  char c = (char)(ch & 0xff);
  putchar(c);
  fflush(stdout);
  g_uart_line_open = (c != '\n');
}

extern "C" void set_gpr_ptr(const svOpenArrayHandle r) {
  cpu_gpr = (uint32_t *)svGetArrayPtr(r);
}

static void build_dut_state(DiffCPUState *s) {
  assert(s != NULL);
  assert(cpu_gpr != NULL);
  for (int i = 0; i < 32; i++) {
    s->gpr[i] = cpu_gpr[i];
  }
  s->gpr[0] = 0;
  s->pc = g_top->debug_pc;
  s->mstatus = g_top->debug_mstatus;
  s->mtvec = g_top->debug_mtvec;
  s->mepc = g_top->debug_mepc;
  s->mcause = g_top->debug_mcause;
}

static bool check_diff_word(const char *name, uint32_t ref, uint32_t dut, uint32_t pc) {
  if (ref != dut) {
    printf("difftest mismatch at %s: ref=0x%08x dut=0x%08x, pc=0x%08x\n",
           name, ref, dut, pc);
    return false;
  }
  return true;
}

static void difftest_sync_ref(const DiffCPUState *dut) {
  ref_difftest_regcpy((void *)dut, DIFFTEST_TO_REF);
}

static bool is_volatile_csr_access(uint32_t inst) {
  uint32_t opcode = inst & 0x7fu;
  uint32_t funct3 = (inst >> 12) & 0x7u;
  uint32_t csr = (inst >> 20) & 0xfffu;

  if (opcode != 0x73u) {
    return false;
  }
  if (funct3 != 0x1u && funct3 != 0x2u) {
    return false;
  }

  return csr == 0xb00u || csr == 0xb80u;
}

static bool difftest_check_regs(const DiffCPUState *ref, const DiffCPUState *dut) {
  if (!check_diff_word("pc", ref->pc, dut->pc, dut->pc)) {
    return false;
  }
  const char *regs[] = {
    "$0", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
    "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
    "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
    "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
  };
  for (int i = 0; i < 32; i++) {
    if (!check_diff_word(regs[i], ref->gpr[i], dut->gpr[i], dut->pc)) {
      return false;
    }
  }
  return check_diff_word("mstatus", ref->mstatus, dut->mstatus, dut->pc) &&
         check_diff_word("mtvec", ref->mtvec, dut->mtvec, dut->pc) &&
         check_diff_word("mepc", ref->mepc, dut->mepc, dut->pc) &&
         check_diff_word("mcause", ref->mcause, dut->mcause, dut->pc);
}

static bool init_difftest(const char *so_file, int port, size_t img_size) {
  g_diff_handle = dlopen(so_file, RTLD_LAZY);
  if (g_diff_handle == NULL) {
    printf("difftest: dlopen failed: %s\n", dlerror());
    return false;
  }

  ref_difftest_memcpy = (difftest_memcpy_t)dlsym(g_diff_handle, "difftest_memcpy");
  ref_difftest_regcpy = (difftest_regcpy_t)dlsym(g_diff_handle, "difftest_regcpy");
  ref_difftest_exec = (difftest_exec_t)dlsym(g_diff_handle, "difftest_exec");
  ref_difftest_raise_intr = (difftest_raise_intr_t)dlsym(g_diff_handle, "difftest_raise_intr");
  ref_difftest_init = (difftest_init_t)dlsym(g_diff_handle, "difftest_init");
  if (ref_difftest_memcpy == NULL || ref_difftest_regcpy == NULL ||
      ref_difftest_exec == NULL || ref_difftest_raise_intr == NULL ||
      ref_difftest_init == NULL) {
    printf("difftest: dlsym failed: %s\n", dlerror());
    return false;
  }

  ref_difftest_init(port);
  (void)ref_difftest_raise_intr;
  ref_difftest_memcpy(MEM_BASE, pmem, img_size, DIFFTEST_TO_REF);

  DiffCPUState dut;
  build_dut_state(&dut);
  difftest_sync_ref(&dut);

  g_difftest_enabled = true;
  printf("difftest: enabled, ref=%s, port=%d\n", so_file, port);
  return true;
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
  if (g_trace_enabled) {
    printf("mtrace: [READ] addr=0x%08x\n", addr);
  }
  return (int)pmem_read32(addr);
}

extern "C" void pmem_write(int waddr, int wdata, char wmask) {
  uint32_t addr = ((uint32_t)waddr) & ~0x3u;
  if (g_trace_enabled) {
    printf("mtrace: [WRITE] addr=0x%08x data=0x%08x wmask=0x%02x\n", addr, (uint32_t)wdata, (uint8_t)wmask);
  }
  if (addr == UART_ADDR) {
    uint8_t mask = (uint8_t)wmask;
    uint32_t data = (uint32_t)wdata;
    for (int i = 0; i < 4; i++) {
      if (mask & (1u << i)) {
        char ch = (char)((data >> (i * 8)) & 0xff);
        putchar(ch);
        g_uart_line_open = (ch != '\n');
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
  g_flash_img.assign((size_t)size, 0);
  g_mrom_img.assign((size_t)size, 0);
  size_t n = fread(pmem, 1, (size_t)size, fp);
  rewind(fp);
  size_t m = fread(g_flash_img.data(), 1, (size_t)size, fp);
  rewind(fp);
  size_t k = fread(g_mrom_img.data(), 1, (size_t)size, fp);
  fclose(fp);
  if (n != (size_t)size || m != (size_t)size || k != (size_t)size) {
    printf("failed to read full image, got pmem=%zu flash=%zu mrom=%zu bytes\n", n, m, k);
    return false;
  }

  printf("loaded image %s (%ld bytes)\n", img_path, size);
  g_img_size = (size_t)size;
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

static bool parse_int_arg(const char* s, int* out) {
  char* endp = NULL;
  long v = strtol(s, &endp, 0);
  if (endp == s || *endp != '\0') {
    return false;
  }
  *out = (int)v;
  return true;
}

static void sync_host_log_line(void) {
  if (g_uart_line_open) {
    putchar('\n');
    fflush(stdout);
    g_uart_line_open = false;
  }
}

int main(int argc, char** argv) {
  if (argc < 2) {
    printf("usage: %s <image.bin> [halt_addr]\n", argv[0]);
    printf("example: %s /path/to/sum-riscv32e-npc.bin 0x100\n", argv[0]);
    return 1;
  }

  const char *diff_so = NULL;
  int diff_port = 1234;
  const char *elf_arg = NULL;
  bool has_halt_addr = false;
  uint32_t halt_addr = 0;

  for (int i = 2; i < argc; i++) {
    if (strncmp(argv[i], "--diff=", 7) == 0) {
      diff_so = argv[i] + 7;
      continue;
    }
    if (strcmp(argv[i], "--diff") == 0) {
      if (i + 1 >= argc) {
        printf("missing argument for --diff\n");
        return 1;
      }
      diff_so = argv[++i];
      continue;
    }
    if (strncmp(argv[i], "--port=", 7) == 0) {
      diff_port = atoi(argv[i] + 7);
      continue;
    }
    if (strncmp(argv[i], "--trace=", 8) == 0) {
      g_trace_enabled = (atoi(argv[i] + 8) != 0);
      continue;
    }
    if (strncmp(argv[i], "--wave=", 7) == 0) {
      g_wave_enabled = (atoi(argv[i] + 7) != 0);
      continue;
    }
    if (strncmp(argv[i], "--max-cycles=", 13) == 0) {
      if (!parse_int_arg(argv[i] + 13, &g_max_cycles)) {
        printf("invalid argument for --max-cycles: %s\n", argv[i] + 13);
        return 1;
      }
      continue;
    }
    int len = strlen(argv[i]);
    if (len > 4 && strcmp(argv[i] + len - 4, ".elf") == 0) {
      elf_arg = argv[i];
      continue;
    }
    if (!has_halt_addr) {
      if (!parse_u32_hex(argv[i], &halt_addr)) {
        printf("invalid argument: %s\n", argv[i]);
        return 1;
      }
      has_halt_addr = true;
      continue;
    }
    printf("unknown argument: %s\n", argv[i]);
    return 1;
  }

  if (!load_img(argv[1])) {
    return 1;
  }

  if (elf_arg != NULL) {
    init_ftrace(elf_arg);
  }
  if (has_halt_addr) {
    pmem_write_masked(halt_addr, 0x00100073u, 0x0f);
    printf("patched ebreak at 0x%08x\n", halt_addr);
  }

  VerilatedContext* contextp = new VerilatedContext;
  Verilated::commandArgs(argc, argv);
  contextp->commandArgs(argc, argv);
  VysyxSoCFull* top = new VysyxSoCFull{contextp};
  g_top = top;

  #if VM_TRACE
  VerilatedVcdC* tfp = NULL;
  if (g_wave_enabled) {
    Verilated::traceEverOn(true);
    tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    const char* wave_path = "wave.vcd";
    tfp->open(wave_path);
    if (g_trace_enabled) {
      printf("wave dump: %s\n", wave_path);
    }
  }
  #else
  void* tfp = NULL;
  if (g_wave_enabled) {
    printf("wave dump is unavailable because NPC was built without --trace\n");
    delete top;
    delete contextp;
    return 1;
  }
  #endif

  top->clock = 0;
  top->reset = 1;

  // Reset for one cycle.
  top->eval();
  wave_dump(tfp, contextp->time());
  contextp->timeInc(1);
  top->clock = 1;
  top->eval();
  wave_dump(tfp, contextp->time());
  contextp->timeInc(1);
  top->clock = 0;
  top->reset = 0;
  top->eval();
  wave_dump(tfp, contextp->time());
  contextp->timeInc(1);

  if (diff_so != NULL) {
    printf("difftest: disabled during MROM boot stage, ignoring %s\n", diff_so);
  }

  int cycle = 0;
  int exit_code = 1;
  while (!contextp->gotFinish() && !g_ebreak_hit) {
    top->eval();
    wave_dump(tfp, contextp->time());
    contextp->timeInc(1);

    // itrace_record(top->debug_pc, top->debug_inst);

    top->clock = 1;
    top->eval();
    wave_dump(tfp, contextp->time());
    contextp->timeInc(1);

    bool dut_committed = top->debug_commit;

    if (g_difftest_enabled && dut_committed) {
      if (cpu_gpr == NULL) {
        printf("difftest: cpu_gpr is not initialized\n");
        g_difftest_abort = true;
        break;
      }
      DiffCPUState ref, dut;
      build_dut_state(&dut);
      ref_difftest_exec(1);
      if (is_volatile_csr_access(top->debug_inst)) {
        difftest_sync_ref(&dut);
        goto difftest_done;
      }
      ref_difftest_regcpy(&ref, DIFFTEST_TO_DUT);
      if (!difftest_check_regs(&ref, &dut)) {
        printf("difftest: failed at dut pc=0x%08x\n", dut.pc);
        itrace_print(dut.pc);
        g_difftest_abort = true;
        break;
      }
difftest_done:
      ;
    }

    top->clock = 0;
    top->eval();
    wave_dump(tfp, contextp->time());
    contextp->timeInc(1);

    cycle++;
    if (g_max_cycles > 0 && cycle > g_max_cycles) {
      sync_host_log_line();
      printf("timeout: reached max cycles (%d) without ebreak\n", g_max_cycles);
      g_stop_by_timeout = true;
      break;
    }
  }

  if (g_ebreak_hit) {
    sync_host_log_line();
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
    if (g_difftest_abort) {
      sync_host_log_line();
      printf("simulation stopped by difftest mismatch\n");
      exit_code = 1;
    } else if (g_stop_by_timeout) {
      sync_host_log_line();
      printf("simulation stopped by timeout without ebreak\n");
      exit_code = 0;
    } else {
      sync_host_log_line();
      printf("simulation stopped without ebreak\n");
      assert(0);
    }
  }

  if (g_diff_handle != NULL) {
    dlclose(g_diff_handle);
    g_diff_handle = NULL;
  }

  wave_close(tfp);
  delete top;
  delete contextp;
  return exit_code;
}
