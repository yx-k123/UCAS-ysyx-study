`timescale 1ns / 1ps

`ifndef NPC_IVERILOG_IMAGE
`define NPC_IVERILOG_IMAGE "npc/build/icarus-image.hex"
`endif

module ysyx_26060188_icarus_mem #(
  parameter [31:0] MEM_BASE  = 32'h8000_0000,
  parameter integer MEM_BYTES = 128 * 1024 * 1024,
  parameter [31:0] UART_ADDR = 32'h1000_0000
) (
  input         clock,
  input         reset,

  input         awvalid,
  output        awready,
  input  [31:0] awaddr,
  input  [3:0]  awid,
  input  [7:0]  awlen,
  input  [2:0]  awsize,
  input  [1:0]  awburst,

  input         wvalid,
  output        wready,
  input  [31:0] wdata,
  input  [3:0]  wstrb,
  input         wlast,

  output reg        bvalid,
  input             bready,
  output reg [1:0]  bresp,
  output reg [3:0]  bid,

  input         arvalid,
  output        arready,
  input  [31:0] araddr,
  input  [3:0]  arid,
  input  [7:0]  arlen,
  input  [2:0]  arsize,
  input  [1:0]  arburst,

  output reg        rvalid,
  input             rready,
  output reg [31:0] rdata,
  output reg [1:0]  rresp,
  output reg        rlast,
  output reg [3:0]  rid
);

  localparam [1:0] AXI_RESP_OKAY   = 2'b00;
  localparam [1:0] AXI_RESP_SLVERR = 2'b10;

  reg [7:0] mem [0:MEM_BYTES - 1];

  reg        aw_seen_r;
  reg        w_seen_r;
  reg [31:0] awaddr_r;
  reg [3:0]  awid_r;
  reg [31:0] wdata_r;
  reg [3:0]  wstrb_r;
  reg [8*512-1:0] image_file;

  integer i;

  wire idle = !rvalid && !bvalid;
  wire aw_fire = awvalid && awready;
  wire w_fire = wvalid && wready;
  wire ar_fire = arvalid && arready;
  wire b_fire = bvalid && bready;
  wire r_fire = rvalid && rready;
  wire [31:0] write_addr_next = aw_fire ? awaddr : awaddr_r;
  wire [3:0]  write_id_next = aw_fire ? awid : awid_r;
  wire [31:0] write_data_next = w_fire ? wdata : wdata_r;
  wire [3:0]  write_strb_next = w_fire ? wstrb : wstrb_r;
  wire        write_issue = (aw_seen_r || aw_fire) && (w_seen_r || w_fire);
  wire _unused_ok = &{1'b0, awlen, awsize, awburst, wlast, arlen, arsize, arburst};

  function is_mem_addr;
    input [31:0] addr;
    reg [31:0] aligned_addr;
    begin
      aligned_addr = {addr[31:2], 2'b00};
      is_mem_addr = (aligned_addr >= MEM_BASE) &&
                    ((aligned_addr - MEM_BASE) <= (MEM_BYTES - 4));
    end
  endfunction

  function [31:0] read_word;
    input [31:0] addr;
    reg [31:0] aligned_addr;
    integer off;
    reg [7:0] b0;
    reg [7:0] b1;
    reg [7:0] b2;
    reg [7:0] b3;
    begin
      aligned_addr = {addr[31:2], 2'b00};
      if (is_mem_addr(aligned_addr)) begin
        off = aligned_addr - MEM_BASE;
        b0 = (^mem[off + 0] === 1'bx) ? 8'h00 : mem[off + 0];
        b1 = (^mem[off + 1] === 1'bx) ? 8'h00 : mem[off + 1];
        b2 = (^mem[off + 2] === 1'bx) ? 8'h00 : mem[off + 2];
        b3 = (^mem[off + 3] === 1'bx) ? 8'h00 : mem[off + 3];
        read_word = {b3, b2, b1, b0};
      end else if (aligned_addr == UART_ADDR) begin
        read_word = 32'b0;
      end else begin
        $display("icarus-mem: invalid read at 0x%08x", addr);
        read_word = 32'b0;
      end
    end
  endfunction

  task do_write;
    input [31:0] addr;
    input [31:0] data;
    input [3:0]  strb;
    reg [31:0] aligned_addr;
    integer off;
    begin
      aligned_addr = {addr[31:2], 2'b00};
      if (is_mem_addr(aligned_addr)) begin
        off = aligned_addr - MEM_BASE;
        if (strb[0]) mem[off + 0] = data[7:0];
        if (strb[1]) mem[off + 1] = data[15:8];
        if (strb[2]) mem[off + 2] = data[23:16];
        if (strb[3]) mem[off + 3] = data[31:24];
      end else if (aligned_addr == UART_ADDR) begin
        if (strb[0]) begin
          $write("%c", data[7:0]);
        end
      end else begin
        $display("icarus-mem: invalid write at 0x%08x data=0x%08x strb=0x%x", addr, data, strb);
        $fatal(1);
      end
    end
  endtask

  initial begin
    image_file = `NPC_IVERILOG_IMAGE;
    if (!$value$plusargs("image=%s", image_file)) begin
      $display("icarus-mem: no +image specified, using default %0s", image_file);
    end
    $readmemh(image_file, mem);
    $display("icarus-mem: loaded image %0s", image_file);
  end

  always @(posedge clock) begin
    if (reset) begin
      aw_seen_r <= 1'b0;
      w_seen_r <= 1'b0;
      awaddr_r <= 32'b0;
      awid_r <= 4'b0;
      wdata_r <= 32'b0;
      wstrb_r <= 4'b0;
      bvalid <= 1'b0;
      bresp <= AXI_RESP_OKAY;
      bid <= 4'b0;
      rvalid <= 1'b0;
      rdata <= 32'b0;
      rresp <= AXI_RESP_OKAY;
      rlast <= 1'b0;
      rid <= 4'b0;
    end else begin
      if (aw_fire) begin
        aw_seen_r <= 1'b1;
        awaddr_r <= awaddr;
        awid_r <= awid;
      end

      if (w_fire) begin
        w_seen_r <= 1'b1;
        wdata_r <= wdata;
        wstrb_r <= wstrb;
      end

      if (write_issue) begin
        do_write(write_addr_next, write_data_next, write_strb_next);
        aw_seen_r <= 1'b0;
        w_seen_r <= 1'b0;
        bvalid <= 1'b1;
        bresp <= AXI_RESP_OKAY;
        bid <= write_id_next;
      end else if (b_fire) begin
        bvalid <= 1'b0;
      end

      if (ar_fire) begin
        rvalid <= 1'b1;
        rdata <= read_word(araddr);
        rresp <= AXI_RESP_OKAY;
        rlast <= 1'b1;
        rid <= arid;
      end else if (r_fire) begin
        rvalid <= 1'b0;
        rlast <= 1'b0;
      end
    end
  end

  assign awready = idle && !aw_seen_r;
  assign wready = idle && !w_seen_r;
  assign arready = idle && !aw_seen_r && !w_seen_r;

endmodule
