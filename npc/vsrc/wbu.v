module wbu (
  input  [31:0] pc_i,
  input  [31:0] alu_res_i,
  input  [31:0] load_data_i,
  input  [4:0]  rd_idx_i,

  input         wb_en_i,
  input         wb_from_load_i,
  input         wb_from_pc4_i,

  input         is_jalr_i,
  input  [31:0] jalr_target_i,

  output        rf_we_o,
  output [4:0]  rf_waddr_o,
  output [31:0] rf_wdata_o,

  output [31:0] pc_next_o
);

  assign rf_we_o    = wb_en_i;
  assign rf_waddr_o = rd_idx_i;
  assign rf_wdata_o = wb_from_load_i ? load_data_i :
                      wb_from_pc4_i  ? (pc_i + 32'd4) :
                                        alu_res_i;

  assign pc_next_o = is_jalr_i ? jalr_target_i : (pc_i + 32'd4);

endmodule
