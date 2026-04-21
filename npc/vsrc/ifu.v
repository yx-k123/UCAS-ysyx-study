module ifu (
  input  [31:0] pc_i,
  input  [31:0] imem_rdata_i,
  output [31:0] imem_addr_o,
  output [31:0] inst_o
);

  assign imem_addr_o = pc_i;
  assign inst_o = imem_rdata_i;

endmodule
