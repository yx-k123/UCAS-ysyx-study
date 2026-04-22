module ifu (
  input  [31:0] pc_i,
  output [31:0] inst_o
);

  import "DPI-C" function int pmem_read(input int raddr);

  assign inst_o = pmem_read(pc_i);

endmodule
