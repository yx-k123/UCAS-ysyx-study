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
NPC_VERILOG_OUT := $(BUILD_DIR)/ysyx_26060188.v
NPC_IVERILOG_IMAGE := $(BUILD_DIR)/icarus-image.hex
NPC_IVERILOG_VSRC := $(NPC_VERILOG_OUT) vsrc/ysyx_26060188_icarus_mem.v vsrc/ysyx_26060188_icarus_tb.v
NPC_NETLIST_DESIGN := ysyx_26060188
NPC_NETLIST_CLK_FREQ_MHZ ?= 100
NPC_NETLIST_OUT_ROOT := $(abspath ../yosys-sta/result-npc-26060188-nangate45)
NPC_NETLIST_RESULT_DIR := $(NPC_NETLIST_OUT_ROOT)/$(NPC_NETLIST_DESIGN)-$(NPC_NETLIST_CLK_FREQ_MHZ)MHz
NPC_NETLIST_SIM_V := $(NPC_NETLIST_RESULT_DIR)/$(NPC_NETLIST_DESIGN).netlist.v.sim
NPC_NETLIST_CELL_V := ../yosys-sta/pdk/nangate45/sim/cells.v
YSYXSOC_VSRC := ../ysyxSoC/build/ysyxSoCFull.v $(shell find ../ysyxSoC/perip -type f -name '*.v' | sort)
CSRCS := csrc/main.cpp
NVBOARD_HOME ?= $(abspath ../nvboard)
NVBOARD_READY := $(shell if [ -d "$(NVBOARD_HOME)" ] && [ -f "$(NVBOARD_HOME)/scripts/nvboard.mk" ] && command -v sdl2-config >/dev/null 2>&1 && command -v pkg-config >/dev/null 2>&1 && pkg-config --exists SDL2_image SDL2_ttf; then echo 1; else echo 0; fi)
USE_NVBOARD ?= $(NVBOARD_READY)
NPC_NVBOARD_NXDC := constr/ysyxSoCFull.nxdc
NPC_NVBOARD_AUTO_BIND := $(BUILD_DIR)/auto_bind.cpp
IVERILOG_BUILD_DIR := $(BUILD_DIR)/iverilog
IVERILOG_SIM := $(IVERILOG_BUILD_DIR)/npc-icarus.vvp
IVERILOG_NETLIST_SIM := $(IVERILOG_BUILD_DIR)/npc-icarus-netlist.vvp
IMG ?=
MAX_CYCLES ?= 5000000
TIMEOUT_OK ?= 0
WAVE ?= 0

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

IVERILOG_NETLIST_FLAGS := \
	$(IVERILOG_FLAGS) \
	-DNETLIST_SIM

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

SIM_CSRCS := $(CSRCS)
SIM_CFLAGS := $(HOST_OPT) -std=c++17
SIM_LDFLAGS := -ldl
SIM_DEPS :=

ifeq ($(USE_NVBOARD),1)
ifneq ($(NVBOARD_READY),1)
$(error USE_NVBOARD=1 but NVBoard dependencies are unavailable; install libsdl2-dev libsdl2-image-dev libsdl2-ttf-dev first)
endif
include $(NVBOARD_HOME)/scripts/nvboard.mk
SIM_CSRCS += $(NPC_NVBOARD_AUTO_BIND)
SIM_CFLAGS += $(CXXFLAGS) $(addprefix -I, $(INC_PATH)) -DUSE_NVBOARD
SIM_LDFLAGS += $(LDFLAGS)
SIM_DEPS += $(NVBOARD_ARCHIVE) $(NPC_NVBOARD_AUTO_BIND)

$(NPC_NVBOARD_AUTO_BIND): $(NPC_NVBOARD_NXDC)
	mkdir -p $(BUILD_DIR)
	NVBOARD_HOME="$(NVBOARD_HOME)" python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $< $@
endif

all: sim

verilog: $(NPC_VERILOG_OUT)

$(NPC_VERILOG_OUT): $(NPC_VSRC)
	mkdir -p $(BUILD_DIR)
	cp $< $@

lint:
	$(VERILATOR) $(LINT_FLAGS) $(NPC_VSRC)

prepare-iverilog-image:
	@if [ -z "$(IMG)" ]; then echo "IMG is required, e.g. make -C npc sim-iverilog IMG=/abs/path/to/image.bin"; exit 1; fi
	mkdir -p $(BUILD_DIR)
	case "$(IMG)" in \
	  *.hex) cp "$(IMG)" "$(NPC_IVERILOG_IMAGE)" ;; \
	  *) $(RISCV_OBJCOPY) -I binary -O verilog "$(IMG)" "$(NPC_IVERILOG_IMAGE)" ;; \
	esac

iverilog: verilog
	mkdir -p $(IVERILOG_BUILD_DIR)
	$(IVERILOG) $(IVERILOG_FLAGS) -o $(IVERILOG_SIM) $(NPC_IVERILOG_VSRC)

iverilog-run: sim-iverilog

sim-iverilog: prepare-iverilog-image iverilog
	$(VVP) $(IVERILOG_SIM) +image=$(abspath $(NPC_IVERILOG_IMAGE)) +max-cycles=$(MAX_CYCLES) +timeout-ok=$(TIMEOUT_OK) +wave=$(WAVE)

netlist-syn: verilog
	VERILOG_DEFINES=__ICARUS__ $(MAKE) -C ../yosys-sta syn \
		DESIGN=$(NPC_NETLIST_DESIGN) \
		PDK=nangate45 \
		CLK_FREQ_MHZ=$(NPC_NETLIST_CLK_FREQ_MHZ) \
		CLK_PORT_NAME=clock \
		O=$(NPC_NETLIST_OUT_ROOT) \
		RTL_FILES="$(abspath $(NPC_VERILOG_OUT))"

iverilog-netlist: $(if $(strip $(NETLIST)),,netlist-syn)
	mkdir -p $(IVERILOG_BUILD_DIR)
	@if [ -n "$(NETLIST)" ] && [ -z "$(CELLS)" ]; then echo "CELLS is required when NETLIST is specified"; exit 1; fi
	$(IVERILOG) $(IVERILOG_NETLIST_FLAGS) -o $(IVERILOG_NETLIST_SIM) \
		$(if $(strip $(NETLIST)),$(CELLS) $(NETLIST),$(NPC_NETLIST_CELL_V) $(NPC_NETLIST_SIM_V)) \
		vsrc/ysyx_26060188_icarus_mem.v \
		vsrc/ysyx_26060188_icarus_tb.v

iverilog-netlist-run: prepare-iverilog-image iverilog-netlist
	$(VVP) $(IVERILOG_NETLIST_SIM) +image=$(abspath $(NPC_IVERILOG_IMAGE)) +max-cycles=$(MAX_CYCLES) +timeout-ok=$(TIMEOUT_OK) +wave=$(WAVE)

sim-iverilog-netlist: prepare-iverilog-image
	@if [ -z "$(NETLIST)" ]; then echo "NETLIST is required, e.g. make -C npc sim-iverilog-netlist IMG=/abs/path/to/image.bin NETLIST=/abs/path/to/netlist.v CELLS=/abs/path/to/cells.v"; exit 1; fi
	@if [ -z "$(CELLS)" ]; then echo "CELLS is required, e.g. make -C npc sim-iverilog-netlist IMG=/abs/path/to/image.bin NETLIST=/abs/path/to/netlist.v CELLS=/abs/path/to/cells.v"; exit 1; fi
	mkdir -p $(IVERILOG_BUILD_DIR)
	$(IVERILOG) $(IVERILOG_NETLIST_FLAGS) -o $(IVERILOG_NETLIST_SIM) \
		$(CELLS) \
		$(NETLIST) \
		vsrc/ysyx_26060188_icarus_mem.v \
		vsrc/ysyx_26060188_icarus_tb.v
	$(VVP) $(IVERILOG_NETLIST_SIM) +image=$(abspath $(NPC_IVERILOG_IMAGE)) +max-cycles=$(MAX_CYCLES) +timeout-ok=$(TIMEOUT_OK) +wave=$(WAVE)

sim: $(SIM_DEPS)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	mkdir -p $(BUILD_DIR)
	CXX=$(CXX) $(VERILATOR) \
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
		-CFLAGS "$(SIM_CFLAGS)" \
		-LDFLAGS "$(SIM_LDFLAGS)" \
		$(VERILATOR_INCLUDES) \
		$(NPC_VSRC) $(YSYXSOC_VSRC) $(SIM_CSRCS) $(if $(USE_NVBOARD),$(NVBOARD_ARCHIVE),)

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
