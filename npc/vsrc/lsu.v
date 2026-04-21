module lsu (
  input         is_load_i,
  input         is_store_i,
  input         is_lbu_i,
  input         is_sb_i,

  input  [31:0] addr_i,
  input  [31:0] store_data_i,
  input  [31:0] dmem_rdata_i,

  output        dmem_valid_o,
  output        dmem_wen_o,
  output [31:0] dmem_addr_o,
  output [31:0] dmem_wdata_o,
  output [3:0]  dmem_wmask_o,

  output [31:0] load_data_o
);

  wire [1:0] byte_off = addr_i[1:0];

  wire [7:0] load_byte =
    (byte_off == 2'b00) ? dmem_rdata_i[7:0] :
    (byte_off == 2'b01) ? dmem_rdata_i[15:8] :
    (byte_off == 2'b10) ? dmem_rdata_i[23:16] :
                          dmem_rdata_i[31:24];

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

  assign dmem_valid_o = is_load_i || is_store_i;
  assign dmem_wen_o   = is_store_i;
  assign dmem_addr_o  = {addr_i[31:2], 2'b00};
  assign dmem_wdata_o = is_sb_i ? sb_wdata : store_data_i;
  assign dmem_wmask_o = is_store_i ? (is_sb_i ? sb_wmask : 4'b1111) : 4'b0000;

  assign load_data_o = is_lbu_i ? {24'b0, load_byte} : dmem_rdata_i;

endmodule
