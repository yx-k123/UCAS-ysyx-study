module regfile (
  input         clk,
  input         rst,
  input         we_i,
  input  [4:0]  waddr_i,
  input  [31:0] wdata_i,
  input  [4:0]  raddr1_i,
  input  [4:0]  raddr2_i,
  output [31:0] rdata1_o,
  output [31:0] rdata2_o
);

  reg [31:0] gpr [1:31]; 
  integer i;

  always @(posedge clk) begin
    if (rst) begin
      for (i = 1; i < 32; i = i + 1) begin
        gpr[i] <= 32'b0;
      end
    end else if (we_i && (waddr_i != 5'd0)) begin
      gpr[waddr_i] <= wdata_i;
    end
  end

  assign rdata1_o = (raddr1_i == 5'd0) ? 32'b0 : gpr[raddr1_i];
  assign rdata2_o = (raddr2_i == 5'd0) ? 32'b0 : gpr[raddr2_i];

endmodule
