#include <common.h>
#include <elf.h>
#include <debug.h>

typedef struct {
  char name[64];
  vaddr_t addr;
  size_t size;
} Symbol;

static Symbol *symbols = NULL;
static int num_symbols = 0;
static int call_depth = 0;
static char indent_buf[256];

static bool read_exact(FILE *fp, void *buf, size_t size, size_t n) {
  return fread(buf, size, n, fp) == n;
}

void init_ftrace(const char *elf_file) {
  if (elf_file == NULL) {
    Log("No ELF file given for ftrace.");
    return;
  }
  
  FILE *fp = fopen(elf_file, "rb");
  if (fp == NULL) {
    Log("Can not open '%s' for ftrace", elf_file);
    return;
  }
  
  Elf32_Ehdr ehdr;
  if (!read_exact(fp, &ehdr, sizeof(Elf32_Ehdr), 1)) {
    Log("Ftrace: Failed to read ELF header");
    fclose(fp);
    return;
  }
  
  // Check magic
  if (ehdr.e_ident[EI_MAG0] != ELFMAG0 || ehdr.e_ident[EI_MAG1] != ELFMAG1 || 
      ehdr.e_ident[EI_MAG2] != ELFMAG2 || ehdr.e_ident[EI_MAG3] != ELFMAG3) {
    Log("Ftrace: Invalid ELF file");
    fclose(fp);
    return;
  }

  if (ehdr.e_ident[EI_CLASS] != ELFCLASS32) {
    Log("Ftrace: Only ELF32 is supported in this build");
    fclose(fp);
    return;
  }

  if (ehdr.e_shentsize != sizeof(Elf32_Shdr) || ehdr.e_shnum == 0) {
    Log("Ftrace: Invalid section header table");
    fclose(fp);
    return;
  }
  
  Elf32_Shdr *shdrs = malloc(sizeof(Elf32_Shdr) * ehdr.e_shnum);
  Assert(shdrs != NULL, "Ftrace: out of memory");
  fseek(fp, ehdr.e_shoff, SEEK_SET);
  if (!read_exact(fp, shdrs, sizeof(Elf32_Shdr), ehdr.e_shnum)) {
    Log("Ftrace: Failed to read section headers");
    free(shdrs);
    fclose(fp);
    return;
  }
  
  Elf32_Shdr *symtab = NULL;
  Elf32_Shdr *strtab = NULL;
  
  for (int i = 0; i < ehdr.e_shnum; i++) {
    if (shdrs[i].sh_type == SHT_SYMTAB) {
      symtab = &shdrs[i];
      if (symtab->sh_link < ehdr.e_shnum) {
        strtab = &shdrs[symtab->sh_link];
      }
      break;
    }
  }
  
  if (symtab == NULL || strtab == NULL) {
    Log("Ftrace: No symbol table found");
    free(shdrs);
    fclose(fp);
    return;
  }
  
  char *strbuf = malloc(strtab->sh_size);
  Assert(strbuf != NULL, "Ftrace: out of memory");
  fseek(fp, strtab->sh_offset, SEEK_SET);
  if (!read_exact(fp, strbuf, strtab->sh_size, 1)) {
    Log("Ftrace: Failed to read string table");
    free(strbuf);
    free(shdrs);
    fclose(fp);
    return;
  }
  
  int sym_num = symtab->sh_size / sizeof(Elf32_Sym);
  Elf32_Sym *syms = malloc(symtab->sh_size);
  Assert(syms != NULL, "Ftrace: out of memory");
  fseek(fp, symtab->sh_offset, SEEK_SET);
  if (!read_exact(fp, syms, symtab->sh_size, 1)) {
    Log("Ftrace: Failed to read symbol table");
    free(syms);
    free(strbuf);
    free(shdrs);
    fclose(fp);
    return;
  }
  
  num_symbols = 0;
  for (int i = 0; i < sym_num; i++) {
    if (ELF32_ST_TYPE(syms[i].st_info) == STT_FUNC && syms[i].st_shndx != SHN_UNDEF) {
      num_symbols++;
    }
  }
  
  symbols = num_symbols > 0 ? malloc(sizeof(Symbol) * num_symbols) : NULL;
  if (num_symbols > 0) {
    Assert(symbols != NULL, "Ftrace: out of memory");
  }
  int idx = 0;
  for (int i = 0; i < sym_num; i++) {
    if (ELF32_ST_TYPE(syms[i].st_info) == STT_FUNC && syms[i].st_shndx != SHN_UNDEF) {
      const char *name = (syms[i].st_name < strtab->sh_size) ? (strbuf + syms[i].st_name) : "<?>"; 
      strncpy(symbols[idx].name, name, 63);
      symbols[idx].name[63] = '\0';
      symbols[idx].addr = syms[i].st_value;
      symbols[idx].size = syms[i].st_size;
      idx++;
    }
  }
  
  free(syms);
  free(strbuf);
  free(shdrs);
  fclose(fp);
  
  Log("Ftrace initialized, %d functions found", num_symbols);
}

static const char *get_func_name(vaddr_t addr) {
  for (int i = 0; i < num_symbols; i++) {
    if (symbols[i].size > 0 && addr >= symbols[i].addr && addr < symbols[i].addr + symbols[i].size) {
      return symbols[i].name;
    }
    if (symbols[i].size == 0 && addr == symbols[i].addr) return symbols[i].name;
  }
  return "???";
}

static const char *get_indent(void) {
  int max_depth = (int)(sizeof(indent_buf) / 2) - 1;
  int depth = call_depth;
  if (depth < 0) depth = 0;
  if (depth > max_depth) depth = max_depth;
  for (int i = 0; i < depth; i++) {
    indent_buf[i * 2] = ' ';
    indent_buf[i * 2 + 1] = ' ';
  }
  indent_buf[depth * 2] = '\0';
  return indent_buf;
}

void ftrace_call(vaddr_t pc, vaddr_t target) {
  const char *indent = get_indent();
  const char *name = get_func_name(target);
  (void)indent;
  (void)name;
  log_write("0x%08x: %scall [%s@0x%08x]\n", pc, indent, name, target);
  call_depth++;
}

void ftrace_ret(vaddr_t pc) {
  call_depth--;
  if (call_depth < 0) call_depth = 0;
  const char *indent = get_indent();
  const char *name = get_func_name(pc);
  (void)indent;
  (void)name;
  log_write("0x%08x: %sret [%s]\n", pc, indent, name);
}
