module exu (
  input  [31:0] rs1_data_i,
  input  [31:0] rs2_data_i,
  input  [31:0] imm_i,
  input         op2_is_rs2_i,
  input         use_u_imm_i,

  output [31:0] alu_res_o,
  output [31:0] jalr_target_o
);

  wire [31:0] op2 = op2_is_rs2_i ? rs2_data_i : imm_i;
  wire [31:0] add_res = rs1_data_i + op2;

  assign alu_res_o = use_u_imm_i ? imm_i : add_res;
  assign jalr_target_o = (rs1_data_i + imm_i) & 32'hffff_fffe;

endmodule
