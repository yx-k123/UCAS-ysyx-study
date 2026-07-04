`include "npc_bus.vh"

module idu (
  input  [`IFU_IDU_BUS_W-1:0] if_bus_i,
  input         if_valid_i,
  output        if_ready_o,
  output [`IDU_EXU_BUS_W-1:0] id_bus_o,
  output        id_valid_o,
  input         id_ready_i
);

  wire [31:0] pc_i = if_bus_i[`IFU_IDU_PC];
  wire [31:0] inst_i = if_bus_i[`IFU_IDU_INST];

  wire [6:0] opcode = inst_i[6:0];
  wire [2:0] funct3 = inst_i[14:12];
  wire [6:0] funct7 = inst_i[31:25];

  wire [4:0] rs1_idx = inst_i[19:15];
  wire [4:0] rs2_idx = inst_i[24:20];
  wire [4:0] rd_idx  = inst_i[11:7];

  wire [31:0] imm_i = {{20{inst_i[31]}}, inst_i[31:20]};
  wire [31:0] imm_s = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
  wire [31:0] imm_b = {{19{inst_i[31]}}, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
  wire [31:0] imm_u = {inst_i[31:12], 12'b0};
  wire [31:0] imm_j = {{11{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};

  wire is_add  = (opcode == 7'b0110011) && (funct3 == 3'b000) && (funct7 == 7'b0000000);
  wire is_sub  = (opcode == 7'b0110011) && (funct3 == 3'b000) && (funct7 == 7'b0100000);
  wire is_sll  = (opcode == 7'b0110011) && (funct3 == 3'b001) && (funct7 == 7'b0000000);
  wire is_slt  = (opcode == 7'b0110011) && (funct3 == 3'b010) && (funct7 == 7'b0000000);
  wire is_sltu = (opcode == 7'b0110011) && (funct3 == 3'b011) && (funct7 == 7'b0000000);
  wire is_xor  = (opcode == 7'b0110011) && (funct3 == 3'b100) && (funct7 == 7'b0000000);
  wire is_srl  = (opcode == 7'b0110011) && (funct3 == 3'b101) && (funct7 == 7'b0000000);
  wire is_sra  = (opcode == 7'b0110011) && (funct3 == 3'b101) && (funct7 == 7'b0100000);
  wire is_or   = (opcode == 7'b0110011) && (funct3 == 3'b110) && (funct7 == 7'b0000000);
  wire is_and  = (opcode == 7'b0110011) && (funct3 == 3'b111) && (funct7 == 7'b0000000);

  wire is_addi = (opcode == 7'b0010011) && (funct3 == 3'b000);
  wire is_slli = (opcode == 7'b0010011) && (funct3 == 3'b001) && (funct7 == 7'b0000000);
  wire is_slti = (opcode == 7'b0010011) && (funct3 == 3'b010);
  wire is_sltiu= (opcode == 7'b0010011) && (funct3 == 3'b011);
  wire is_xori = (opcode == 7'b0010011) && (funct3 == 3'b100);
  wire is_srli = (opcode == 7'b0010011) && (funct3 == 3'b101) && (funct7 == 7'b0000000);
  wire is_srai = (opcode == 7'b0010011) && (funct3 == 3'b101) && (funct7 == 7'b0100000);
  wire is_ori  = (opcode == 7'b0010011) && (funct3 == 3'b110);
  wire is_andi = (opcode == 7'b0010011) && (funct3 == 3'b111);

  wire is_lui  = (opcode == 7'b0110111);
  wire is_auipc= (opcode == 7'b0010111);
  wire is_jal  = (opcode == 7'b1101111);
  wire is_lb   = (opcode == 7'b0000011) && (funct3 == 3'b000);
  wire is_lh   = (opcode == 7'b0000011) && (funct3 == 3'b001);
  wire is_lw   = (opcode == 7'b0000011) && (funct3 == 3'b010);
  wire is_lbu  = (opcode == 7'b0000011) && (funct3 == 3'b100);
  wire is_lhu  = (opcode == 7'b0000011) && (funct3 == 3'b101);
  wire is_sw   = (opcode == 7'b0100011) && (funct3 == 3'b010);
  wire is_sb   = (opcode == 7'b0100011) && (funct3 == 3'b000);
  wire is_sh   = (opcode == 7'b0100011) && (funct3 == 3'b001);
  wire is_beq  = (opcode == 7'b1100011) && (funct3 == 3'b000);
  wire is_bne  = (opcode == 7'b1100011) && (funct3 == 3'b001);
  wire is_blt  = (opcode == 7'b1100011) && (funct3 == 3'b100);
  wire is_bge  = (opcode == 7'b1100011) && (funct3 == 3'b101);
  wire is_bltu = (opcode == 7'b1100011) && (funct3 == 3'b110);
  wire is_bgeu = (opcode == 7'b1100011) && (funct3 == 3'b111);
  wire is_jalr = (opcode == 7'b1100111) && (funct3 == 3'b000);
  wire is_csrrw = (opcode == 7'b1110011) && (funct3 == 3'b001);
  wire is_csrrs = (opcode == 7'b1110011) && (funct3 == 3'b010);
  wire is_ecall = (inst_i == 32'h0000_0073);
  wire is_mret = (inst_i == 32'h3020_0073);
  wire is_ebreak = (inst_i == 32'h0010_0073);

  wire [11:0] csr_addr = inst_i[31:20];

  wire op1_is_pc = is_auipc;
  wire op2_is_rs2 = is_add || is_sub || is_sll || is_slt || is_sltu || is_xor || is_srl || is_sra || is_or || is_and
                 || is_beq || is_bne || is_blt || is_bge || is_bltu || is_bgeu;

  wire [31:0] imm = (is_lui || is_auipc) ? imm_u :
                    (is_jal) ? imm_j :
                    (is_beq || is_bne || is_blt || is_bge || is_bltu || is_bgeu) ? imm_b :
                    (is_sw || is_sb || is_sh) ? imm_s :
                    imm_i;

  localparam ALU_ADD  = 4'd0;
  localparam ALU_SUB  = 4'd1;
  localparam ALU_AND  = 4'd2;
  localparam ALU_OR   = 4'd3;
  localparam ALU_XOR  = 4'd4;
  localparam ALU_SLL  = 4'd5;
  localparam ALU_SRL  = 4'd6;
  localparam ALU_SRA  = 4'd7;
  localparam ALU_SLT  = 4'd8;
  localparam ALU_SLTU = 4'd9;
  localparam ALU_COPY2= 4'd10;

  wire [3:0] alu_op =
    (is_sub || is_beq || is_bne || is_blt || is_bge || is_bltu || is_bgeu) ? ALU_SUB :
    (is_and || is_andi) ? ALU_AND :
    (is_or  || is_ori ) ? ALU_OR  :
    (is_xor || is_xori) ? ALU_XOR :
    (is_sll || is_slli) ? ALU_SLL :
    (is_srl || is_srli) ? ALU_SRL :
    (is_sra || is_srai) ? ALU_SRA :
    (is_slt || is_slti) ? ALU_SLT :
    (is_sltu|| is_sltiu)? ALU_SLTU:
    (is_lui) ? ALU_COPY2 :
    ALU_ADD;

  wire is_load  = is_lb || is_lh || is_lw || is_lbu || is_lhu;
  wire is_store = is_sb || is_sh || is_sw;
  wire is_branch = is_beq || is_bne || is_blt || is_bge || is_bltu || is_bgeu;
  wire [2:0] br_type = is_beq  ? 3'd0 :
                       is_bne  ? 3'd1 :
                       is_blt  ? 3'd2 :
                       is_bge  ? 3'd3 :
                       is_bltu ? 3'd4 :
                       is_bgeu ? 3'd5 : 3'd0;
  wire wb_en = is_add || is_sub || is_sll || is_slt || is_sltu || is_xor || is_srl || is_sra || is_or || is_and
            || is_addi || is_slli || is_slti || is_sltiu || is_xori || is_srli || is_srai || is_ori || is_andi
            || is_lui || is_auipc || is_lb || is_lh || is_lw || is_lbu || is_lhu || is_jal || is_jalr
            || is_csrrw || is_csrrs;
  wire wb_from_load = is_load;
  wire wb_from_pc4  = is_jal || is_jalr;
  wire wb_from_csr  = is_csrrw || is_csrrs;

  assign if_ready_o = id_ready_i;
  assign id_valid_o = if_valid_i;
  assign id_bus_o[`IDU_EXU_PC] = pc_i;
  assign id_bus_o[`IDU_EXU_IMM] = imm;
  assign id_bus_o[`IDU_EXU_RS1_IDX] = rs1_idx;
  assign id_bus_o[`IDU_EXU_RS2_IDX] = rs2_idx;
  assign id_bus_o[`IDU_EXU_RD_IDX] = rd_idx;
  assign id_bus_o[`IDU_EXU_CSR_ADDR] = csr_addr;
  assign id_bus_o[`IDU_EXU_ALU_OP] = alu_op;
  assign id_bus_o[`IDU_EXU_LSU_FUNCT3] = funct3;
  assign id_bus_o[`IDU_EXU_BR_TYPE] = br_type;
  assign id_bus_o[`IDU_EXU_OP1_IS_PC] = op1_is_pc;
  assign id_bus_o[`IDU_EXU_OP2_IS_RS2] = op2_is_rs2;
  assign id_bus_o[`IDU_EXU_IS_CSRRW] = is_csrrw;
  assign id_bus_o[`IDU_EXU_IS_CSRRS] = is_csrrs;
  assign id_bus_o[`IDU_EXU_IS_ECALL] = is_ecall;
  assign id_bus_o[`IDU_EXU_IS_MRET] = is_mret;
  assign id_bus_o[`IDU_EXU_IS_LOAD] = is_load;
  assign id_bus_o[`IDU_EXU_IS_STORE] = is_store;
  assign id_bus_o[`IDU_EXU_IS_BRANCH] = is_branch;
  assign id_bus_o[`IDU_EXU_IS_JAL] = is_jal;
  assign id_bus_o[`IDU_EXU_IS_JALR] = is_jalr;
  assign id_bus_o[`IDU_EXU_IS_EBREAK] = is_ebreak;
  assign id_bus_o[`IDU_EXU_WB_EN] = wb_en;
  assign id_bus_o[`IDU_EXU_WB_FROM_LOAD] = wb_from_load;
  assign id_bus_o[`IDU_EXU_WB_FROM_PC4] = wb_from_pc4;
  assign id_bus_o[`IDU_EXU_WB_FROM_CSR] = wb_from_csr;

endmodule
