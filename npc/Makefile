VERILATOR ?= verilator
CXX := g++-12
RISCV_CC ?= riscv64-linux-gnu-gcc
RISCV_OBJCOPY ?= riscv64-linux-gnu-objcopy
BUILD_DIR := build
OBJ_DIR := $(BUILD_DIR)/obj_dir
SIM_BIN := npc-sim
TEST_DIR := tests
CHAR_TEST_SRC := $(TEST_DIR)/char-test.c
CHAR_TEST_ELF := $(BUILD_DIR)/char-test.elf
CHAR_TEST_BIN := $(BUILD_DIR)/char-test.bin
MROM_BASE := 0x20000000

NPC_VSRC := $(filter-out vsrc/top.v,$(sort $(wildcard vsrc/*.v)))
YSYXSOC_VSRC := ../ysyxSoC/build/ysyxSoCFull.v $(shell find ../ysyxSoC/perip -type f -name '*.v' | sort)
CSRCS := csrc/main.cpp

VERILATOR_INCLUDES := \
	-Ivsrc \
	-I../ysyxSoC/perip/uart16550/rtl \
	-I../ysyxSoC/perip/spi/rtl

VERILATOR_FLAGS := \
	--cc \
	--exe \
	--build \
	--top-module ysyxSoCFull \
	--timescale 1ns/1ns \
	--no-timing \
	-Mdir $(OBJ_DIR) \
	-o $(SIM_BIN) \
	-CFLAGS "-O2 -std=c++17" \
	-LDFLAGS "-ldl"

all: sim

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	mkdir -p $(BUILD_DIR)
	CXX=$(CXX) $(VERILATOR) $(VERILATOR_FLAGS) $(VERILATOR_INCLUDES) $(NPC_VSRC) $(YSYXSOC_VSRC) $(CSRCS)

$(CHAR_TEST_ELF): $(CHAR_TEST_SRC)
	mkdir -p $(BUILD_DIR)
	$(RISCV_CC) -O2 -ffreestanding -fno-pic -fno-pie -nostdlib -nostartfiles \
		-march=rv32i_zicsr -mabi=ilp32 -Wl,--build-id=none -Wl,-e,_start \
		-Wl,-Ttext=$(MROM_BASE) -o $@ $<

$(CHAR_TEST_BIN): $(CHAR_TEST_ELF)
	$(RISCV_OBJCOPY) -O binary --only-section=.text $< $@

char-test: $(CHAR_TEST_BIN)

run-char-test: sim char-test
	./$(OBJ_DIR)/$(SIM_BIN) $(CHAR_TEST_BIN) --trace=0 --max-cycles=2000

include ../Makefile
