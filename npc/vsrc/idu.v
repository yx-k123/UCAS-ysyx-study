module idu (
  input  [31:0] inst_i,

  output [4:0] rs1_idx_o,
  output [4:0] rs2_idx_o,
  output [4:0] rd_idx_o,

  output [31:0] imm_o,
  output        op1_is_pc_o,
  output        op2_is_rs2_o,
  output [3:0]  alu_op_o,
  output [11:0] csr_addr_o,
  output        is_csrrw_o,
  output        is_csrrs_o,
  output        is_ecall_o,
  output        is_mret_o,

  output        is_load_o,
  output        is_store_o,
  output [2:0]  lsu_funct3_o,
  output        is_branch_o,
  output [2:0]  br_type_o,
  output        is_jal_o,
  output        is_jalr_o,
  output        is_ebreak_o,

  output        wb_en_o,
  output        wb_from_load_o,
  output        wb_from_pc4_o,
  output        wb_from_csr_o
);

  wire [6:0] opcode = inst_i[6:0];
  wire [2:0] funct3 = inst_i[14:12];
  wire [6:0] funct7 = inst_i[31:25];

  assign rs1_idx_o = inst_i[19:15];
  assign rs2_idx_o = inst_i[24:20];
  assign rd_idx_o  = inst_i[11:7];

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

  assign csr_addr_o = inst_i[31:20];
  assign is_csrrw_o = is_csrrw;
  assign is_csrrs_o = is_csrrs;
  assign is_ecall_o = is_ecall;
  assign is_mret_o = is_mret;

  assign op1_is_pc_o = is_auipc;
  assign op2_is_rs2_o = is_add || is_sub || is_sll || is_slt || is_sltu || is_xor || is_srl || is_sra || is_or || is_and
                     || is_beq || is_bne || is_blt || is_bge || is_bltu || is_bgeu;

  assign imm_o = (is_lui || is_auipc) ? imm_u :
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

  assign alu_op_o =
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

  assign is_load_o  = is_lb || is_lh || is_lw || is_lbu || is_lhu;
  assign is_store_o = is_sb || is_sh || is_sw;
  assign lsu_funct3_o = funct3;
  assign is_branch_o = is_beq || is_bne || is_blt || is_bge || is_bltu || is_bgeu;
  assign br_type_o = is_beq  ? 3'd0 :
                     is_bne  ? 3'd1 :
                     is_blt  ? 3'd2 :
                     is_bge  ? 3'd3 :
                     is_bltu ? 3'd4 :
                     is_bgeu ? 3'd5 : 3'd0;
  assign is_jal_o  = is_jal;
  assign is_jalr_o  = is_jalr;
  assign is_ebreak_o = is_ebreak;

  assign wb_en_o        = is_add || is_sub || is_sll || is_slt || is_sltu || is_xor || is_srl || is_sra || is_or || is_and
                       || is_addi || is_slli || is_slti || is_sltiu || is_xori || is_srli || is_srai || is_ori || is_andi
                       || is_lui || is_auipc || is_lb || is_lh || is_lw || is_lbu || is_lhu || is_jal || is_jalr
                       || is_csrrw || is_csrrs;
  assign wb_from_load_o = is_lb || is_lh || is_lw || is_lbu || is_lhu;
  assign wb_from_pc4_o  = is_jal || is_jalr;
  assign wb_from_csr_o  = is_csrrw || is_csrrs;

endmodule
