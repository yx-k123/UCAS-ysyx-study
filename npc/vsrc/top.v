module top (
  input         clk,
  input         rst,

  output [31:0] debug_pc,
  output [31:0] debug_inst
);

  import "DPI-C" function void npc_ebreak(input int unsigned pc, input int unsigned inst, input int unsigned a0);
  import "DPI-C" function void trace_inst(input int pc, input int inst);

  reg [31:0] pc_r;
  wire [31:0] pc_next;

  wire [31:0] inst;

  wire [4:0] rs1_idx;
  wire [4:0] rs2_idx;
  wire [4:0] rd_idx;

  wire [31:0] imm;
  wire op1_is_pc;
  wire op2_is_rs2;
  wire [3:0] alu_op;
  wire [11:0] csr_addr;
  wire is_csrrw;
  wire is_csrrs;
  wire is_ecall;
  wire is_mret;

  wire is_load;
  wire is_store;
  wire [2:0] lsu_funct3;
  wire is_branch;
  wire [2:0] br_type;
  wire is_jal;
  wire is_jalr;
  wire is_ebreak;

  wire wb_en;
  wire wb_from_load;
  wire wb_from_pc4;
  wire wb_from_csr;

  wire [31:0] rs1_data;
  wire [31:0] rs2_data;
  wire [31:0] a0_data;

  wire [31:0] alu_res;
  wire [31:0] jalr_target;
  wire [31:0] br_target;
  wire br_taken;

  wire [31:0] load_data;
  wire [31:0] csr_rdata;
  wire [31:0] mtvec;
  wire [31:0] mepc;

  wire rf_we;
  wire [4:0] rf_waddr;
  wire [31:0] rf_wdata;

  ifu u_ifu (
    .pc_i(pc_r),
    .inst_o(inst)
  );

  idu u_idu (
    .inst_i(inst),
    .rs1_idx_o(rs1_idx),
    .rs2_idx_o(rs2_idx),
    .rd_idx_o(rd_idx),
    .imm_o(imm),
    .op1_is_pc_o(op1_is_pc),
    .op2_is_rs2_o(op2_is_rs2),
    .alu_op_o(alu_op),
    .csr_addr_o(csr_addr),
    .is_csrrw_o(is_csrrw),
    .is_csrrs_o(is_csrrs),
    .is_ecall_o(is_ecall),
    .is_mret_o(is_mret),
    .is_load_o(is_load),
    .is_store_o(is_store),
    .lsu_funct3_o(lsu_funct3),
    .is_branch_o(is_branch),
    .br_type_o(br_type),
    .is_jal_o(is_jal),
    .is_jalr_o(is_jalr),
    .is_ebreak_o(is_ebreak),
    .wb_en_o(wb_en),
    .wb_from_load_o(wb_from_load),
    .wb_from_pc4_o(wb_from_pc4),
    .wb_from_csr_o(wb_from_csr)
  );

  regfile u_regfile (
    .clk(clk),
    .we_i(rf_we),
    .waddr_i(rf_waddr),
    .wdata_i(rf_wdata),
    .raddr1_i(rs1_idx),
    .raddr2_i(rs2_idx),
    .rdata1_o(rs1_data),
    .rdata2_o(rs2_data),
    .a0_o(a0_data)
  );

  exu u_exu (
    .pc_i(pc_r),
    .rs1_data_i(rs1_data),
    .rs2_data_i(rs2_data),
    .imm_i(imm),
    .op1_is_pc_i(op1_is_pc),
    .op2_is_rs2_i(op2_is_rs2),
    .alu_op_i(alu_op),
    .br_type_i(br_type),
    .alu_res_o(alu_res),
    .jalr_target_o(jalr_target),
    .br_target_o(br_target),
    .br_taken_o(br_taken)
  );

  lsu u_lsu (
    .clk(clk),
    .is_load_i(is_load),
    .is_store_i(is_store),
    .funct3_i(lsu_funct3),
    .addr_i(alu_res),
    .store_data_i(rs2_data),
    .load_data_o(load_data)
  );

  csrfile u_csrfile (
    .clk(clk),
    .rst(rst),
    .csr_we_i(is_csrrw || (is_csrrs && (rs1_idx != 5'd0))),
    .csr_set_i(is_csrrs),
    .csr_addr_i(csr_addr),
    .csr_wdata_i(rs1_data),
    .trap_we_i(is_ecall),
    .trap_epc_i(pc_r),
    .trap_cause_i(32'd11),
    .csr_rdata_o(csr_rdata),
    .mtvec_o(mtvec),
    .mepc_o(mepc)
  );

  wbu u_wbu (
    .pc_i(pc_r),
    .alu_res_i(alu_res),
    .load_data_i(load_data),
    .csr_rdata_i(csr_rdata),
    .rd_idx_i(rd_idx),
    .wb_en_i(wb_en),
    .wb_from_load_i(wb_from_load),
    .wb_from_pc4_i(wb_from_pc4),
    .wb_from_csr_i(wb_from_csr),
    .is_ecall_i(is_ecall),
    .is_mret_i(is_mret),
    .is_branch_i(is_branch),
    .br_taken_i(br_taken),
    .br_target_i(br_target),
    .is_jal_i(is_jal),
    .is_jalr_i(is_jalr),
    .jalr_target_i(jalr_target),
    .trap_target_i(mtvec),
    .mret_target_i(mepc),
    .rf_we_o(rf_we),
    .rf_waddr_o(rf_waddr),
    .rf_wdata_o(rf_wdata),
    .pc_next_o(pc_next)
  );

  always @(posedge clk) begin
    if (rst) begin
      pc_r <= 32'h8000_0000;
    end else begin
      trace_inst(pc_r, inst);
      if (is_ebreak) begin
        npc_ebreak(pc_r, inst, a0_data);
      end
      pc_r <= pc_next;
    end
  end

  assign debug_pc = pc_r;
  assign debug_inst = inst;

endmodule
