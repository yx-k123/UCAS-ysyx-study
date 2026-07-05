VERILATOR ?= verilator
IVERILOG ?= iverilog
VVP ?= vvp
CXX ?= g++-12
RISCV_CC ?= riscv64-linux-gnu-gcc
RISCV_OBJCOPY ?= riscv64-linux-gnu-objcopy
HOST_OPT ?= -O2
BUILD_DIR := build
OBJ_DIR := $(BUILD_DIR)/obj_dir
SIM_BIN := npc-sim
TEST_DIR := tests
CHAR_TEST_SRC := $(TEST_DIR)/char-test.c
CHAR_TEST_ELF := $(BUILD_DIR)/char-test.elf
CHAR_TEST_BIN := $(BUILD_DIR)/char-test.bin
FLASH_BASE := 0x30000000

NPC_VSRC := vsrc/ysyx_26060188.v
NPC_IVERILOG_VSRC := $(NPC_VSRC) vsrc/ysyx_26060188_icarus_mem.v vsrc/ysyx_26060188_icarus_tb.v
YSYXSOC_VSRC := ../ysyxSoC/build/ysyxSoCFull.v $(shell find ../ysyxSoC/perip -type f -name '*.v' | sort)
CSRCS := csrc/main.cpp
IVERILOG_BUILD_DIR := $(BUILD_DIR)/iverilog
IVERILOG_SIM := $(IVERILOG_BUILD_DIR)/npc-icarus.vvp
IMG ?=
MAX_CYCLES ?= 5000000
TIMEOUT_OK ?= 0

VERILATOR_INCLUDES := \
	-Ivsrc \
	-I../ysyxSoC/perip/uart16550/rtl \
	-I../ysyxSoC/perip/spi/rtl

LINT_TOP := ysyx_26060188
LINT_FLAGS := \
	--lint-only \
	-Wall \
	-Wno-DECLFILENAME \
	--top-module $(LINT_TOP)

IVERILOG_FLAGS := \
	-g2012 \
	-s ysyx_26060188_icarus_tb

VERILATOR_FLAGS := \
	--cc \
	--exe \
	--build \
	--top-module ysyxSoCFull \
	--autoflush \
	--timescale 1ns/1ns \
	--no-timing \
	-MAKEFLAGS "CXX=$(CXX) LINK=$(CXX) OPT_FAST=$(HOST_OPT) OPT_GLOBAL=$(HOST_OPT) OPT_SLOW=$(HOST_OPT)" \
	-Mdir $(OBJ_DIR) \
	-o $(SIM_BIN) \
	-CFLAGS "$(HOST_OPT) -std=c++17" \
	-LDFLAGS "-ldl"

all: sim

lint:
	$(VERILATOR) $(LINT_FLAGS) $(NPC_VSRC)

iverilog:
	mkdir -p $(IVERILOG_BUILD_DIR)
	$(IVERILOG) $(IVERILOG_FLAGS) -o $(IVERILOG_SIM) $(NPC_IVERILOG_VSRC)

iverilog-run: iverilog
	@if [ -z "$(IMG)" ]; then echo "IMG is required, e.g. make -C npc iverilog-run IMG=/abs/path/to/image.hex"; exit 1; fi
	$(VVP) $(IVERILOG_SIM) +image=$(abspath $(IMG)) +max-cycles=$(MAX_CYCLES) +timeout-ok=$(TIMEOUT_OK) +wave=$(WAVE)

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	mkdir -p $(BUILD_DIR)
	CXX=$(CXX) $(VERILATOR) $(VERILATOR_FLAGS) $(VERILATOR_INCLUDES) $(NPC_VSRC) $(YSYXSOC_VSRC) $(CSRCS)

$(CHAR_TEST_ELF): $(CHAR_TEST_SRC)
	mkdir -p $(BUILD_DIR)
	$(RISCV_CC) -O2 -ffreestanding -fno-pic -fno-pie -nostdlib -nostartfiles \
		-march=rv32i_zicsr -mabi=ilp32 -Wl,--build-id=none -Wl,-e,_start \
		-Wl,-Ttext=$(FLASH_BASE) -o $@ $<

$(CHAR_TEST_BIN): $(CHAR_TEST_ELF)
	$(RISCV_OBJCOPY) -O binary --only-section=.text $< $@

char-test: $(CHAR_TEST_BIN)

run-char-test: sim char-test
	./$(OBJ_DIR)/$(SIM_BIN) $(CHAR_TEST_BIN) --trace=0 --max-cycles=2000

include ../Makefile
