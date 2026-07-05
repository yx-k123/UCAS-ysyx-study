VERILATOR ?= verilator
CXX := g++-12
BUILD_DIR := build
OBJ_DIR := $(BUILD_DIR)/obj_dir
SIM_BIN := npc-sim

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
	-DFAST_FLASH \
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

include ../Makefile
