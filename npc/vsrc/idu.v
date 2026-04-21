module idu (
  input  [31:0] inst_i,

  output [4:0] rs1_idx_o,
  output [4:0] rs2_idx_o,
  output [4:0] rd_idx_o,

  output [31:0] imm_o,
  output        op2_is_rs2_o,
  output        use_u_imm_o,

  output        is_load_o,
  output        is_store_o,
  output        is_lbu_o,
  output        is_sb_o,
  output        is_jalr_o,

  output        wb_en_o,
  output        wb_from_load_o,
  output        wb_from_pc4_o
);

  wire [6:0] opcode = inst_i[6:0];
  wire [2:0] funct3 = inst_i[14:12];
  wire [6:0] funct7 = inst_i[31:25];

  assign rs1_idx_o = inst_i[19:15];
  assign rs2_idx_o = inst_i[24:20];
  assign rd_idx_o  = inst_i[11:7];

  wire [31:0] imm_i = {{20{inst_i[31]}}, inst_i[31:20]};
  wire [31:0] imm_s = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
  wire [31:0] imm_u = {inst_i[31:12], 12'b0};

  wire is_add  = (opcode == 7'b0110011) && (funct3 == 3'b000) && (funct7 == 7'b0000000);
  wire is_addi = (opcode == 7'b0010011) && (funct3 == 3'b000);
  wire is_lui  = (opcode == 7'b0110111);
  wire is_lw   = (opcode == 7'b0000011) && (funct3 == 3'b010);
  wire is_lbu  = (opcode == 7'b0000011) && (funct3 == 3'b100);
  wire is_sw   = (opcode == 7'b0100011) && (funct3 == 3'b010);
  wire is_sb   = (opcode == 7'b0100011) && (funct3 == 3'b000);
  wire is_jalr = (opcode == 7'b1100111) && (funct3 == 3'b000);

  assign op2_is_rs2_o = is_add;
  assign use_u_imm_o  = is_lui;

  assign imm_o = is_lui ? imm_u :
                 (is_sw || is_sb) ? imm_s :
                 imm_i;

  assign is_load_o  = is_lw || is_lbu;
  assign is_store_o = is_sw || is_sb;
  assign is_lbu_o   = is_lbu;
  assign is_sb_o    = is_sb;
  assign is_jalr_o  = is_jalr;

  assign wb_en_o        = is_add || is_addi || is_lui || is_lw || is_lbu || is_jalr;
  assign wb_from_load_o = is_lw || is_lbu;
  assign wb_from_pc4_o  = is_jalr;

endmodule
