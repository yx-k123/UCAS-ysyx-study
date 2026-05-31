module regfile (
  input         clk,
  input         we_i,
  input  [4:0]  waddr_i,
  input  [31:0] wdata_i,
  input  [4:0]  raddr1_i,
  input  [4:0]  raddr2_i,
  output [31:0] rdata1_o,
  output [31:0] rdata2_o,
  output [31:0] a0_o
);

  reg [31:0] gpr [31:0]; 

  always @(posedge clk) begin
    if (we_i) begin
      gpr[waddr_i] <= wdata_i;
    end
  end

  assign rdata1_o = (raddr1_i == 5'd0) ? 32'b0 : gpr[raddr1_i];
  assign rdata2_o = (raddr2_i == 5'd0) ? 32'b0 : gpr[raddr2_i];

  assign a0_o = gpr[10];

  import "DPI-C" function void set_gpr_ptr(input logic [31:0] a []);
  
  initial begin
    set_gpr_ptr(gpr);
  end

endmodule