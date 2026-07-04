module axi4lite_mem (
  input         clk,
  input         rst,

  input  [31:0] ifu_araddr_i,
  input         ifu_arvalid_i,
  output        ifu_arready_o,
  output [31:0] ifu_rdata_o,
  output [1:0]  ifu_rresp_o,
  output        ifu_rvalid_o,
  input         ifu_rready_i,
  input         ifu_awvalid_i,
  input         ifu_wvalid_i,
  input         ifu_bready_i,
  output        ifu_awready_o,
  output        ifu_wready_o,
  output        ifu_bvalid_o,
  output [1:0]  ifu_bresp_o,

  input  [31:0] lsu_awaddr_i,
  input         lsu_awvalid_i,
  output        lsu_awready_o,
  input  [31:0] lsu_wdata_i,
  input  [3:0]  lsu_wstrb_i,
  input         lsu_wvalid_i,
  output        lsu_wready_o,
  output [1:0]  lsu_bresp_o,
  output        lsu_bvalid_o,
  input         lsu_bready_i,
  input  [31:0] lsu_araddr_i,
  input         lsu_arvalid_i,
  output        lsu_arready_o,
  output [31:0] lsu_rdata_o,
  output [1:0]  lsu_rresp_o,
  output        lsu_rvalid_o,
  input         lsu_rready_i
);

  import "DPI-C" function int pmem_read(input int raddr);
  import "DPI-C" function void pmem_write(input int waddr, input int wdata, input int wmask);

  localparam [4:0] MEM_FIXED_DELAY = 5'd5;
  localparam       MEM_USE_LFSR = 1'b1;
  localparam [1:0] AXI_RESP_OKAY = 2'b00;

  reg [31:0] ifu_addr_r;
  reg [31:0] ifu_rdata_r;
  reg [4:0]  ifu_delay_r;
  reg [7:0]  ifu_lfsr_r;
  reg        ifu_wait_r;
  reg        ifu_rvalid_r;

  reg [31:0] lsu_read_addr_r;
  reg [31:0] lsu_rdata_r;
  reg [31:0] lsu_write_addr_r;
  reg [31:0] lsu_write_data_r;
  reg [3:0]  lsu_write_strb_r;
  reg [4:0]  lsu_delay_r;
  reg [7:0]  lsu_lfsr_r;
  reg        lsu_ar_wait_r;
  reg        lsu_rvalid_r;
  reg        lsu_aw_seen_r;
  reg        lsu_w_seen_r;
  reg        lsu_write_wait_r;
  reg        lsu_bvalid_r;

  wire ifu_ar_fire = ifu_arvalid_i && ifu_arready_o;
  wire ifu_r_fire = ifu_rvalid_r && ifu_rready_i;

  wire lsu_ar_fire = lsu_arvalid_i && lsu_arready_o;
  wire lsu_r_fire = lsu_rvalid_r && lsu_rready_i;
  wire lsu_aw_fire = lsu_awvalid_i && lsu_awready_o;
  wire lsu_w_fire = lsu_wvalid_i && lsu_wready_o;
  wire lsu_b_fire = lsu_bvalid_r && lsu_bready_i;

  function [7:0] lfsr_next;
    input [7:0] lfsr;
    begin
      lfsr_next = {lfsr[6:0], lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]};
    end
  endfunction

  function [4:0] choose_delay;
    input [7:0] lfsr;
    begin
      choose_delay = MEM_USE_LFSR ? {1'b0, lfsr[3:0]} : MEM_FIXED_DELAY;
    end
  endfunction

  always @(*) begin
    if (ifu_awvalid_i || ifu_wvalid_i || ifu_bready_i) begin
      $fatal(1, "IFU must not drive AXI write channels");
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      ifu_addr_r <= 32'b0;
      ifu_rdata_r <= 32'b0;
      ifu_delay_r <= 5'b0;
      ifu_lfsr_r <= 8'h1;
      ifu_wait_r <= 1'b0;
      ifu_rvalid_r <= 1'b0;
    end else begin
      if (ifu_ar_fire) begin
        ifu_addr_r <= ifu_araddr_i;
        ifu_delay_r <= choose_delay(ifu_lfsr_r);
        ifu_lfsr_r <= lfsr_next(ifu_lfsr_r);
        ifu_wait_r <= 1'b1;
      end

      if (ifu_wait_r && (ifu_delay_r != 5'd0)) begin
        ifu_delay_r <= ifu_delay_r - 5'd1;
      end else if (ifu_wait_r && (ifu_delay_r == 5'd0) && !ifu_rvalid_r) begin
        ifu_rdata_r <= pmem_read(ifu_addr_r);
        ifu_rvalid_r <= 1'b1;
        ifu_wait_r <= 1'b0;
      end

      if (ifu_r_fire) begin
        ifu_rvalid_r <= 1'b0;
      end
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      lsu_read_addr_r <= 32'b0;
      lsu_rdata_r <= 32'b0;
      lsu_write_addr_r <= 32'b0;
      lsu_write_data_r <= 32'b0;
      lsu_write_strb_r <= 4'b0;
      lsu_delay_r <= 5'b0;
      lsu_lfsr_r <= 8'h5a;
      lsu_ar_wait_r <= 1'b0;
      lsu_rvalid_r <= 1'b0;
      lsu_aw_seen_r <= 1'b0;
      lsu_w_seen_r <= 1'b0;
      lsu_write_wait_r <= 1'b0;
      lsu_bvalid_r <= 1'b0;
    end else begin
      if (lsu_ar_fire) begin
        lsu_read_addr_r <= lsu_araddr_i;
        lsu_delay_r <= choose_delay(lsu_lfsr_r);
        lsu_lfsr_r <= lfsr_next(lsu_lfsr_r);
        lsu_ar_wait_r <= 1'b1;
      end

      if (lsu_aw_fire) begin
        lsu_write_addr_r <= lsu_awaddr_i;
        lsu_aw_seen_r <= 1'b1;
      end

      if (lsu_w_fire) begin
        lsu_write_data_r <= lsu_wdata_i;
        lsu_write_strb_r <= lsu_wstrb_i;
        lsu_w_seen_r <= 1'b1;
      end

      if (!lsu_write_wait_r && (lsu_aw_seen_r || lsu_aw_fire) && (lsu_w_seen_r || lsu_w_fire)) begin
        lsu_delay_r <= choose_delay(lsu_lfsr_r);
        lsu_lfsr_r <= lfsr_next(lsu_lfsr_r);
        lsu_write_wait_r <= 1'b1;
        lsu_aw_seen_r <= 1'b0;
        lsu_w_seen_r <= 1'b0;
      end

      if (lsu_ar_wait_r && (lsu_delay_r != 5'd0)) begin
        lsu_delay_r <= lsu_delay_r - 5'd1;
      end else if (lsu_ar_wait_r && (lsu_delay_r == 5'd0) && !lsu_rvalid_r) begin
        lsu_rdata_r <= pmem_read(lsu_read_addr_r);
        lsu_rvalid_r <= 1'b1;
        lsu_ar_wait_r <= 1'b0;
      end

      if (lsu_write_wait_r && (lsu_delay_r != 5'd0)) begin
        lsu_delay_r <= lsu_delay_r - 5'd1;
      end else if (lsu_write_wait_r && (lsu_delay_r == 5'd0) && !lsu_bvalid_r) begin
        pmem_write(lsu_write_addr_r, lsu_write_data_r, {28'b0, lsu_write_strb_r});
        lsu_bvalid_r <= 1'b1;
        lsu_write_wait_r <= 1'b0;
      end

      if (lsu_r_fire) begin
        lsu_rvalid_r <= 1'b0;
      end

      if (lsu_b_fire) begin
        lsu_bvalid_r <= 1'b0;
      end
    end
  end

  assign ifu_arready_o = !rst && !ifu_wait_r && !ifu_rvalid_r;
  assign ifu_rdata_o = ifu_rdata_r;
  assign ifu_rresp_o = AXI_RESP_OKAY;
  assign ifu_rvalid_o = ifu_rvalid_r;
  assign ifu_awready_o = 1'b0;
  assign ifu_wready_o = 1'b0;
  assign ifu_bvalid_o = 1'b0;
  assign ifu_bresp_o = AXI_RESP_OKAY;

  assign lsu_arready_o = !rst && !lsu_ar_wait_r && !lsu_rvalid_r &&
                         !lsu_aw_seen_r && !lsu_w_seen_r && !lsu_write_wait_r && !lsu_bvalid_r;
  assign lsu_rdata_o = lsu_rdata_r;
  assign lsu_rresp_o = AXI_RESP_OKAY;
  assign lsu_rvalid_o = lsu_rvalid_r;

  assign lsu_awready_o = !rst && !lsu_ar_wait_r && !lsu_rvalid_r &&
                         !lsu_write_wait_r && !lsu_bvalid_r && !lsu_aw_seen_r;
  assign lsu_wready_o = !rst && !lsu_ar_wait_r && !lsu_rvalid_r &&
                        !lsu_write_wait_r && !lsu_bvalid_r && !lsu_w_seen_r;
  assign lsu_bresp_o = AXI_RESP_OKAY;
  assign lsu_bvalid_o = lsu_bvalid_r;

endmodule
