module alu (
  input  [31:0] op1_i,
  input  [31:0] op2_i,
  input  [3:0]  alu_op_i,
  output [31:0] res_o
);

  localparam ALU_ADD   = 4'd0;
  localparam ALU_SUB   = 4'd1;
  localparam ALU_AND   = 4'd2;
  localparam ALU_OR    = 4'd3;
  localparam ALU_XOR   = 4'd4;
  localparam ALU_SLL   = 4'd5;
  localparam ALU_SRL   = 4'd6;
  localparam ALU_SRA   = 4'd7;
  localparam ALU_SLT   = 4'd8;
  localparam ALU_SLTU  = 4'd9;
  localparam ALU_COPY2 = 4'd10;

  wire [31:0] add_res = op1_i + op2_i;
  wire [31:0] sub_res = op1_i - op2_i;
  wire [4:0] shamt = op2_i[4:0];
  wire [5:0] shamt6 = {1'b0, shamt};
  wire [31:0] sra_fill_mask = (shamt6 == 0) ? 32'b0 : (32'hffff_ffff << (6'd32 - shamt6));
  wire [31:0] sra_res = (op1_i >> shamt) | (op1_i[31] ? sra_fill_mask : 32'b0);
  wire signed_lt = ($signed(op1_i) < $signed(op2_i));
  wire unsigned_lt = (op1_i < op2_i);

  assign res_o =
    (alu_op_i == ALU_ADD  ) ? add_res :
    (alu_op_i == ALU_SUB  ) ? sub_res :
    (alu_op_i == ALU_AND  ) ? (op1_i & op2_i) :
    (alu_op_i == ALU_OR   ) ? (op1_i | op2_i) :
    (alu_op_i == ALU_XOR  ) ? (op1_i ^ op2_i) :
    (alu_op_i == ALU_SLL  ) ? (op1_i << shamt) :
    (alu_op_i == ALU_SRL  ) ? (op1_i >> shamt) :
    (alu_op_i == ALU_SRA  ) ? sra_res :
    (alu_op_i == ALU_SLT  ) ? {31'b0, signed_lt} :
    (alu_op_i == ALU_SLTU ) ? {31'b0, unsigned_lt} :
    (alu_op_i == ALU_COPY2) ? op2_i :
    add_res;

endmodule
