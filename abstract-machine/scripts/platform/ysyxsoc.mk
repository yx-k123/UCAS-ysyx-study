AM_SRCS := riscv/ysyxsoc/start.S         riscv/ysyxsoc/trm.c          riscv/npc/ioe.c               riscv/npc/timer.c             riscv/npc/input.c             riscv/npc/cte.c               riscv/npc/trap.S              platform/dummy/vme.c          platform/dummy/mpe.c

CFLAGS    += -fdata-sections -ffunction-sections
LDSCRIPTS += $(AM_HOME)/scripts/linker-ysyxsoc.ld
LDFLAGS   += --defsym=_flash_start=0x30000000 --defsym=_flash_size=0x00fff000
LDFLAGS   += --defsym=_sram_start=0x0f000000 --defsym=_sram_size=0x2000
LDFLAGS   += --defsym=_stack_size=0x1000
LDFLAGS   += --gc-sections -e _start

MAINARGS_MAX_LEN = 64
MAINARGS_PLACEHOLDER = the_insert-arg_rule_in_Makefile_will_insert_mainargs_here
CFLAGS += -DMAINARGS_MAX_LEN=$(MAINARGS_MAX_LEN) -DMAINARGS_PLACEHOLDER=$(MAINARGS_PLACEHOLDER)

NPC_HOME ?= $(abspath $(AM_HOME)/../npc)
NEMU_HOME ?= $(abspath $(AM_HOME)/../nemu)
DIFF_SO ?= $(NEMU_HOME)/build/riscv32-nemu-interpreter-so
NPC_BUILD_CXX ?= g++
NPC_HOST_OPT ?= -O0
TRACE ?= 0
WAVE ?= 0
MAX_CYCLES ?= 200000
NPC_ARGS ?=

RUN_ARGS := --trace=$(TRACE) --wave=$(WAVE) --max-cycles=$(MAX_CYCLES) $(NPC_ARGS)
ifeq ($(DIFF),1)
RUN_ARGS += --diff="$(DIFF_SO)"
endif

insert-arg: image
	@python3 $(AM_HOME)/tools/insert-arg.py $(IMAGE).bin $(MAINARGS_MAX_LEN) $(MAINARGS_PLACEHOLDER) "$(mainargs)"

image: image-dep
	@$(OBJDUMP) -d $(IMAGE).elf > $(IMAGE).txt
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
	@$(OBJCOPY) -S -O binary $(IMAGE).elf $(IMAGE).bin

run: insert-arg
	@if [ "$(DIFF)" = "1" ] && [ ! -f "$(DIFF_SO)" ]; then echo "DIFF_SO not found: $(DIFF_SO)"; exit 1; fi
	@if [ ! -d "$(NPC_HOME)" ]; then echo "NPC_HOME is invalid: $(NPC_HOME)"; exit 1; fi
	@$(MAKE) -s -C "$(NPC_HOME)" sim CXX="$(NPC_BUILD_CXX)" HOST_OPT="$(NPC_HOST_OPT)"
	@"$(NPC_HOME)/build/obj_dir/npc-sim" "$(IMAGE).bin" "$(IMAGE).elf" $(RUN_ARGS)

.PHONY: insert-arg run
