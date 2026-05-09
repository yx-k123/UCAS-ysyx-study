module lsu (
  input         clk,

  input         is_load_i,
  input         is_store_i,
  input         is_lbu_i,
  input         is_sb_i,

  input  [31:0] addr_i,
  input  [31:0] store_data_i,

  output [31:0] load_data_o
);

  import "DPI-C" function int pmem_read(input int raddr);
  import "DPI-C" function void pmem_write(input int waddr, input int wdata, input [7:0] wmask);

  wire [1:0] byte_off = addr_i[1:0];
  wire valid = is_load_i || is_store_i;
  wire [31:0] aligned_addr = {addr_i[31:2], 2'b00};

  reg [31:0] dmem_rdata;

  wire [7:0] load_byte =
    (byte_off == 2'b00) ? dmem_rdata[7:0] :
    (byte_off == 2'b01) ? dmem_rdata[15:8] :
    (byte_off == 2'b10) ? dmem_rdata[23:16] :
                          dmem_rdata[31:24];

  wire [31:0] sb_wdata =
    (byte_off == 2'b00) ? {24'b0, store_data_i[7:0]} :
    (byte_off == 2'b01) ? {16'b0, store_data_i[7:0], 8'b0} :
    (byte_off == 2'b10) ? {8'b0, store_data_i[7:0], 16'b0} :
                          {store_data_i[7:0], 24'b0};

  wire [3:0] sb_wmask =
    (byte_off == 2'b00) ? 4'b0001 :
    (byte_off == 2'b01) ? 4'b0010 :
    (byte_off == 2'b10) ? 4'b0100 :
                          4'b1000;

  wire [31:0] dmem_wdata = is_sb_i ? sb_wdata : store_data_i;
  wire [3:0] dmem_wmask = is_store_i ? (is_sb_i ? sb_wmask : 4'b1111) : 4'b0000;

  always @(*) begin
    if (valid) begin
      dmem_rdata = pmem_read(aligned_addr);
    end else begin
      dmem_rdata = 32'b0;
    end
  end

  always @(posedge clk) begin
    if (is_store_i) begin
      pmem_write(aligned_addr, dmem_wdata, {4'b0, dmem_wmask});
    end
  end

  assign load_data_o = is_lbu_i ? {24'b0, load_byte} : dmem_rdata;

endmodule
