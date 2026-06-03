module exu (
  input  [31:0] pc_i,
  input  [31:0] rs1_data_i,
  input  [31:0] rs2_data_i,
  input  [31:0] imm_i,
  input         op1_is_pc_i,
  input         op2_is_rs2_i,
  input  [3:0]  alu_op_i,
  input  [2:0]  br_type_i,

  output [31:0] alu_res_o,
  output [31:0] jalr_target_o,
  output [31:0] br_target_o,
  output        br_taken_o
);

  wire [31:0] op1 = op1_is_pc_i ? pc_i : rs1_data_i;
  wire [31:0] op2 = op2_is_rs2_i ? rs2_data_i : imm_i;
  wire [31:0] alu_res;
  wire [31:0] sub_res = op1 - op2;
  wire signed_lt = ($signed(op1) < $signed(op2));
  wire unsigned_lt = (op1 < op2);

  alu u_alu (
    .op1_i(op1),
    .op2_i(op2),
    .alu_op_i(alu_op_i),
    .res_o(alu_res)
  );

  assign alu_res_o = alu_res;

  wire eq = (sub_res == 32'b0);
  assign br_taken_o =
    (br_type_i == 3'd0) ? eq :
    (br_type_i == 3'd1) ? (~eq) :
    (br_type_i == 3'd2) ? signed_lt :
    (br_type_i == 3'd3) ? (~signed_lt) :
    (br_type_i == 3'd4) ? unsigned_lt :
    (br_type_i == 3'd5) ? (~unsigned_lt) :
    1'b0;

  assign br_target_o = pc_i + imm_i;
  assign jalr_target_o = (rs1_data_i + imm_i) & 32'hffff_fffe;

endmodule
