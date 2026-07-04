`include "npc_bus.vh"

module exu (
  input  [`IDU_EXU_BUS_W-1:0] id_bus_i,
  input         id_valid_i,
  output        id_ready_o,
  input  [31:0] rs1_data_i,
  input  [31:0] rs2_data_i,
  output [`EXU_WBU_BUS_W-1:0] ex_bus_o,
  output        ex_valid_o,
  input         ex_ready_i
);

  wire [31:0] pc_i = id_bus_i[`IDU_EXU_PC];
  wire [31:0] imm_i = id_bus_i[`IDU_EXU_IMM];
  wire [3:0] alu_op_i = id_bus_i[`IDU_EXU_ALU_OP];
  wire [2:0] br_type_i = id_bus_i[`IDU_EXU_BR_TYPE];
  wire op1_is_pc_i = id_bus_i[`IDU_EXU_OP1_IS_PC];
  wire op2_is_rs2_i = id_bus_i[`IDU_EXU_OP2_IS_RS2];

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

  wire eq = (sub_res == 32'b0);
  wire br_taken =
    (br_type_i == 3'd0) ? eq :
    (br_type_i == 3'd1) ? (~eq) :
    (br_type_i == 3'd2) ? signed_lt :
    (br_type_i == 3'd3) ? (~signed_lt) :
    (br_type_i == 3'd4) ? unsigned_lt :
    (br_type_i == 3'd5) ? (~unsigned_lt) :
    1'b0;

  wire [31:0] br_target = pc_i + imm_i;
  wire [31:0] jalr_target = (rs1_data_i + imm_i) & 32'hffff_fffe;

  assign id_ready_o = ex_ready_i;
  assign ex_valid_o = id_valid_i;
  assign ex_bus_o[`EXU_WBU_PC] = pc_i;
  assign ex_bus_o[`EXU_WBU_RD_IDX] = id_bus_i[`IDU_EXU_RD_IDX];
  assign ex_bus_o[`EXU_WBU_CSR_ADDR] = id_bus_i[`IDU_EXU_CSR_ADDR];
  assign ex_bus_o[`EXU_WBU_LSU_FUNCT3] = id_bus_i[`IDU_EXU_LSU_FUNCT3];
  assign ex_bus_o[`EXU_WBU_RS1_DATA] = rs1_data_i;
  assign ex_bus_o[`EXU_WBU_RS2_DATA] = rs2_data_i;
  assign ex_bus_o[`EXU_WBU_ALU_RES] = alu_res;
  assign ex_bus_o[`EXU_WBU_JALR_TARGET] = jalr_target;
  assign ex_bus_o[`EXU_WBU_BR_TARGET] = br_target;
  assign ex_bus_o[`EXU_WBU_BR_TAKEN] = br_taken;
  assign ex_bus_o[`EXU_WBU_IS_CSRRW] = id_bus_i[`IDU_EXU_IS_CSRRW];
  assign ex_bus_o[`EXU_WBU_IS_CSRRS] = id_bus_i[`IDU_EXU_IS_CSRRS];
  assign ex_bus_o[`EXU_WBU_IS_ECALL] = id_bus_i[`IDU_EXU_IS_ECALL];
  assign ex_bus_o[`EXU_WBU_IS_MRET] = id_bus_i[`IDU_EXU_IS_MRET];
  assign ex_bus_o[`EXU_WBU_IS_LOAD] = id_bus_i[`IDU_EXU_IS_LOAD];
  assign ex_bus_o[`EXU_WBU_IS_STORE] = id_bus_i[`IDU_EXU_IS_STORE];
  assign ex_bus_o[`EXU_WBU_IS_BRANCH] = id_bus_i[`IDU_EXU_IS_BRANCH];
  assign ex_bus_o[`EXU_WBU_IS_JAL] = id_bus_i[`IDU_EXU_IS_JAL];
  assign ex_bus_o[`EXU_WBU_IS_JALR] = id_bus_i[`IDU_EXU_IS_JALR];
  assign ex_bus_o[`EXU_WBU_IS_EBREAK] = id_bus_i[`IDU_EXU_IS_EBREAK];
  assign ex_bus_o[`EXU_WBU_WB_EN] = id_bus_i[`IDU_EXU_WB_EN];
  assign ex_bus_o[`EXU_WBU_WB_FROM_LOAD] = id_bus_i[`IDU_EXU_WB_FROM_LOAD];
  assign ex_bus_o[`EXU_WBU_WB_FROM_PC4] = id_bus_i[`IDU_EXU_WB_FROM_PC4];
  assign ex_bus_o[`EXU_WBU_WB_FROM_CSR] = id_bus_i[`IDU_EXU_WB_FROM_CSR];

endmodule
