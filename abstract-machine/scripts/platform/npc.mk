AM_SRCS := riscv/npc/start.S            riscv/npc/trm.c            riscv/npc/ioe.c            riscv/npc/timer.c            riscv/npc/input.c            riscv/npc/cte.c            riscv/npc/trap.S            platform/dummy/vme.c            platform/dummy/mpe.c

CFLAGS    += -fdata-sections -ffunction-sections
LDSCRIPTS += $(AM_HOME)/scripts/linker.ld
LDFLAGS   += --defsym=_pmem_start=0x80000000 --defsym=_entry_offset=0x0
LDFLAGS   += --gc-sections -e _start

MAINARGS_MAX_LEN = 64
MAINARGS_PLACEHOLDER = the_insert-arg_rule_in_Makefile_will_insert_mainargs_here
CFLAGS += -DMAINARGS_MAX_LEN=$(MAINARGS_MAX_LEN) -DMAINARGS_PLACEHOLDER=$(MAINARGS_PLACEHOLDER)
NPC_HOME ?= $(abspath $(AM_HOME)/../npc)
NEMU_HOME ?= $(abspath $(AM_HOME)/../nemu)
INC_CAPSTONE := -I$(NEMU_HOME)/tools/capstone/repo/include
LIB_CAPSTONE := $(NEMU_HOME)/tools/capstone/repo/libcapstone.so.5
DIFF_SO ?= $(NEMU_HOME)/build/riscv32-nemu-interpreter-so
TRACE ?= 1
WAVE ?= 0
NPC_ARGS ?=
NPC_SIM ?= verilator
NPC_MAX_CYCLES ?= 5000000
NPC_TIMEOUT_OK ?= 0
NPC_OPT := -O3
VERILATOR_TRACE_FLAG :=
HEX_IMAGE := $(IMAGE).hex

RUN_ARGS := --trace=$(TRACE) --wave=$(WAVE) $(NPC_ARGS)
ifeq ($(DIFF),1)
NPC_OPT := -O0
RUN_ARGS += --diff="$(DIFF_SO)"
endif
ifeq ($(WAVE),1)
VERILATOR_TRACE_FLAG := --trace
endif

insert-arg: image
	@python3 $(AM_HOME)/tools/insert-arg.py $(IMAGE).bin $(MAINARGS_MAX_LEN) $(MAINARGS_PLACEHOLDER) "$(mainargs)"

image: image-dep
	@$(OBJDUMP) -d $(IMAGE).elf > $(IMAGE).txt
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
	@$(OBJCOPY) -S --set-section-flags .bss=alloc,contents -O binary $(IMAGE).elf $(IMAGE).bin

$(HEX_IMAGE): insert-arg
	@echo + OBJCOPY "->" $(IMAGE_REL).hex
	@$(OBJCOPY) -I binary -O verilog $(IMAGE).bin $(HEX_IMAGE)

ifeq ($(NPC_SIM),iverilog)
run: insert-arg $(HEX_IMAGE)
	@if [ ! -d "$(NPC_HOME)" ]; then echo "NPC_HOME is invalid: $(NPC_HOME)"; exit 1; fi
	@if ! command -v iverilog >/dev/null 2>&1; then echo "iverilog not found"; exit 1; fi
	@if ! command -v vvp >/dev/null 2>&1; then echo "vvp not found"; exit 1; fi
	@$(MAKE) -C "$(NPC_HOME)" iverilog-run IMG="$(abspath $(HEX_IMAGE))" MAX_CYCLES="$(NPC_MAX_CYCLES)" TIMEOUT_OK="$(NPC_TIMEOUT_OK)" WAVE="$(WAVE)"
else
run: insert-arg
	@if [ "$(DIFF)" = "1" ] && [ ! -f "$(DIFF_SO)" ]; then echo "DIFF_SO not found: $(DIFF_SO)"; exit 1; fi
	@if [ ! -d "$(NPC_HOME)" ]; then echo "NPC_HOME is invalid: $(NPC_HOME)"; exit 1; fi
	@if ! command -v verilator >/dev/null 2>&1; then echo "verilator not found"; exit 1; fi
	@verilator $(VERILATOR_TRACE_FLAG) --cc --exe --build --top-module top -I"$(NPC_HOME)/vsrc" -CFLAGS "$(NPC_OPT) $(INC_CAPSTONE)" -LDFLAGS "$(LIB_CAPSTONE) -ldl -Wl,-rpath,$(NEMU_HOME)/tools/capstone/repo" -Mdir "$(NPC_HOME)/build/obj_dir" "$(NPC_HOME)/csrc/main.cpp" "$(NPC_HOME)"/vsrc/*.v
	@"$(NPC_HOME)/build/obj_dir/Vtop" "$(IMAGE).bin" "$(IMAGE).elf" $(RUN_ARGS)
endif

.PHONY: insert-arg run
