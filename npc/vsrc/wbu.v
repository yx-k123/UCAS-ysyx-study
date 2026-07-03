`include "npc_bus.vh"

module wbu (
  input  [`EXU_WBU_BUS_W-1:0] mem_bus_i,
  input  [31:0] load_data_i,
  input         mem_valid_i,
  output        mem_ready_o,
  input  [31:0] csr_rdata_i,
  input  [31:0] trap_target_i,
  input  [31:0] mret_target_i,

  output        rf_we_o,
  output [4:0]  rf_waddr_o,
  output [31:0] rf_wdata_o,

  output [31:0] pc_next_o
);

  wire [31:0] pc_i = mem_bus_i[`EXU_WBU_PC];
  wire [31:0] alu_res_i = mem_bus_i[`EXU_WBU_ALU_RES];
  wire [31:0] jalr_target_i = mem_bus_i[`EXU_WBU_JALR_TARGET];
  wire [31:0] br_target_i = mem_bus_i[`EXU_WBU_BR_TARGET];
  wire [4:0] rd_idx_i = mem_bus_i[`EXU_WBU_RD_IDX];
  wire wb_en_i = mem_bus_i[`EXU_WBU_WB_EN];
  wire wb_from_load_i = mem_bus_i[`EXU_WBU_WB_FROM_LOAD];
  wire wb_from_pc4_i = mem_bus_i[`EXU_WBU_WB_FROM_PC4];
  wire wb_from_csr_i = mem_bus_i[`EXU_WBU_WB_FROM_CSR];
  wire is_ecall_i = mem_bus_i[`EXU_WBU_IS_ECALL];
  wire is_mret_i = mem_bus_i[`EXU_WBU_IS_MRET];
  wire is_branch_i = mem_bus_i[`EXU_WBU_IS_BRANCH];
  wire br_taken_i = mem_bus_i[`EXU_WBU_BR_TAKEN];
  wire is_jal_i = mem_bus_i[`EXU_WBU_IS_JAL];
  wire is_jalr_i = mem_bus_i[`EXU_WBU_IS_JALR];

  assign mem_ready_o = 1'b1;
  assign rf_we_o    = wb_en_i;
  assign rf_waddr_o = rd_idx_i;
  assign rf_wdata_o = wb_from_load_i ? load_data_i :
                      wb_from_pc4_i  ? (pc_i + 32'd4) :
                      wb_from_csr_i  ? csr_rdata_i :
                                        alu_res_i;

  assign pc_next_o = is_ecall_i ? trap_target_i :
                     is_mret_i ? mret_target_i :
                     (is_jal_i || (is_branch_i && br_taken_i)) ? br_target_i :
                     is_jalr_i ? jalr_target_i :
                     (pc_i + 32'd4);

endmodule
