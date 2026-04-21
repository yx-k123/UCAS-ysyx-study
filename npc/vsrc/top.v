module top (
  input         clk,
  input         rst,

  input  [31:0] imem_rdata,
  output [31:0] imem_addr,

  input  [31:0] dmem_rdata,
  output        dmem_valid,
  output        dmem_wen,
  output [31:0] dmem_addr,
  output [31:0] dmem_wdata,
  output [3:0]  dmem_wmask,

  output [31:0] debug_pc,
  output [31:0] debug_inst
);

  reg [31:0] pc_r;
  wire [31:0] pc_next;

  wire [31:0] inst;

  wire [4:0] rs1_idx;
  wire [4:0] rs2_idx;
  wire [4:0] rd_idx;

  wire [31:0] imm;
  wire op2_is_rs2;
  wire use_u_imm;

  wire is_load;
  wire is_store;
  wire is_lbu;
  wire is_sb;
  wire is_jalr;

  wire wb_en;
  wire wb_from_load;
  wire wb_from_pc4;

  wire [31:0] rs1_data;
  wire [31:0] rs2_data;

  wire [31:0] alu_res;
  wire [31:0] jalr_target;

  wire [31:0] load_data;

  wire rf_we;
  wire [4:0] rf_waddr;
  wire [31:0] rf_wdata;

  ifu u_ifu (
    .pc_i(pc_r),
    .imem_rdata_i(imem_rdata),
    .imem_addr_o(imem_addr),
    .inst_o(inst)
  );

  idu u_idu (
    .inst_i(inst),
    .rs1_idx_o(rs1_idx),
    .rs2_idx_o(rs2_idx),
    .rd_idx_o(rd_idx),
    .imm_o(imm),
    .op2_is_rs2_o(op2_is_rs2),
    .use_u_imm_o(use_u_imm),
    .is_load_o(is_load),
    .is_store_o(is_store),
    .is_lbu_o(is_lbu),
    .is_sb_o(is_sb),
    .is_jalr_o(is_jalr),
    .wb_en_o(wb_en),
    .wb_from_load_o(wb_from_load),
    .wb_from_pc4_o(wb_from_pc4)
  );

  regfile u_regfile (
    .clk(clk),
    .rst(rst),
    .we_i(rf_we),
    .waddr_i(rf_waddr),
    .wdata_i(rf_wdata),
    .raddr1_i(rs1_idx),
    .raddr2_i(rs2_idx),
    .rdata1_o(rs1_data),
    .rdata2_o(rs2_data)
  );

  exu u_exu (
    .rs1_data_i(rs1_data),
    .rs2_data_i(rs2_data),
    .imm_i(imm),
    .op2_is_rs2_i(op2_is_rs2),
    .use_u_imm_i(use_u_imm),
    .alu_res_o(alu_res),
    .jalr_target_o(jalr_target)
  );

  lsu u_lsu (
    .is_load_i(is_load),
    .is_store_i(is_store),
    .is_lbu_i(is_lbu),
    .is_sb_i(is_sb),
    .addr_i(alu_res),
    .store_data_i(rs2_data),
    .dmem_rdata_i(dmem_rdata),
    .dmem_valid_o(dmem_valid),
    .dmem_wen_o(dmem_wen),
    .dmem_addr_o(dmem_addr),
    .dmem_wdata_o(dmem_wdata),
    .dmem_wmask_o(dmem_wmask),
    .load_data_o(load_data)
  );

  wbu u_wbu (
    .pc_i(pc_r),
    .alu_res_i(alu_res),
    .load_data_i(load_data),
    .rd_idx_i(rd_idx),
    .wb_en_i(wb_en),
    .wb_from_load_i(wb_from_load),
    .wb_from_pc4_i(wb_from_pc4),
    .is_jalr_i(is_jalr),
    .jalr_target_i(jalr_target),
    .rf_we_o(rf_we),
    .rf_waddr_o(rf_waddr),
    .rf_wdata_o(rf_wdata),
    .pc_next_o(pc_next)
  );

  always @(posedge clk) begin
    if (rst) begin
      pc_r <= 32'h0000_0000;
    end else begin
      pc_r <= pc_next;
    end
  end

  assign debug_pc = pc_r;
  assign debug_inst = inst;

endmodule
