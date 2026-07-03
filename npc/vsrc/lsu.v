`include "npc_bus.vh"

module lsu (
  input         clk,
  input  [`EXU_WBU_BUS_W-1:0] ex_bus_i,
  input         ex_valid_i,
  output        ex_ready_o,
  output [`EXU_WBU_BUS_W-1:0] mem_bus_o,
  output [31:0] load_data_o,
  output        mem_valid_o,
  input         mem_ready_i
);

  import "DPI-C" function int pmem_read(input int raddr);
  import "DPI-C" function void pmem_write(input int waddr, input int wdata, input int wmask);

  wire is_load_i = ex_bus_i[`EXU_WBU_IS_LOAD];
  wire is_store_i = ex_bus_i[`EXU_WBU_IS_STORE];
  wire [2:0] funct3_i = ex_bus_i[`EXU_WBU_LSU_FUNCT3];
  wire [31:0] addr_i = ex_bus_i[`EXU_WBU_ALU_RES];
  wire [31:0] store_data_i = ex_bus_i[`EXU_WBU_RS2_DATA];

  wire [1:0] byte_off = addr_i[1:0];
  wire valid = is_load_i || is_store_i;
  wire [31:0] aligned_addr = {addr_i[31:2], 2'b00};

  reg [31:0] dmem_rdata;

  wire [7:0] load_byte =
    (byte_off == 2'b00) ? dmem_rdata[7:0] :
    (byte_off == 2'b01) ? dmem_rdata[15:8] :
    (byte_off == 2'b10) ? dmem_rdata[23:16] :
                          dmem_rdata[31:24];
  wire [15:0] load_half = byte_off[1] ? dmem_rdata[31:16] : dmem_rdata[15:0];

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

  wire is_lb  = is_load_i && (funct3_i == 3'b000);
  wire is_lh  = is_load_i && (funct3_i == 3'b001);
  wire is_lw  = is_load_i && (funct3_i == 3'b010);
  wire is_lbu = is_load_i && (funct3_i == 3'b100);
  wire is_lhu = is_load_i && (funct3_i == 3'b101);

  wire is_sb = is_store_i && (funct3_i == 3'b000);
  wire is_sh = is_store_i && (funct3_i == 3'b001);
  wire is_sw = is_store_i && (funct3_i == 3'b010);

  wire [31:0] sh_wdata = byte_off[1] ? {store_data_i[15:0], 16'b0} : {16'b0, store_data_i[15:0]};
  wire [3:0] sh_wmask  = byte_off[1] ? 4'b1100 : 4'b0011;

  wire [31:0] dmem_wdata = is_sb ? sb_wdata :
                           is_sh ? sh_wdata :
                           store_data_i;
  wire [3:0] dmem_wmask = is_sb ? sb_wmask :
                          is_sh ? sh_wmask :
                          is_sw ? 4'b1111 : 4'b0000;
  wire mem_fire = ex_valid_i && mem_ready_i;

  always @(*) begin
    if (valid) begin
      dmem_rdata = pmem_read(aligned_addr);
    end else begin
      dmem_rdata = 32'b0;
    end
  end

  always @(posedge clk) begin
    if (mem_fire && is_store_i) begin
      pmem_write(aligned_addr, dmem_wdata, {28'b0, dmem_wmask});
    end
  end

  assign ex_ready_o = mem_ready_i;
  assign mem_bus_o = ex_bus_i;
  assign mem_valid_o = ex_valid_i;
  assign load_data_o = is_lb  ? {{24{load_byte[7]}}, load_byte} :
                       is_lbu ? {24'b0, load_byte} :
                       is_lh  ? {{16{load_half[15]}}, load_half} :
                       is_lhu ? {16'b0, load_half} :
                       is_lw  ? dmem_rdata :
                                32'b0;

endmodule
