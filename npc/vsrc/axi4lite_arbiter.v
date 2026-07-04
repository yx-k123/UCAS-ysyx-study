module axi4lite_arbiter (
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
  input         lsu_rready_i,

  output [31:0] mem_awaddr_o,
  output        mem_awvalid_o,
  input         mem_awready_i,
  output [31:0] mem_wdata_o,
  output [3:0]  mem_wstrb_o,
  output        mem_wvalid_o,
  input         mem_wready_i,
  input  [1:0]  mem_bresp_i,
  input         mem_bvalid_i,
  output        mem_bready_o,
  output [31:0] mem_araddr_o,
  output        mem_arvalid_o,
  input         mem_arready_i,
  input  [31:0] mem_rdata_i,
  input  [1:0]  mem_rresp_i,
  input         mem_rvalid_i,
  output        mem_rready_o
);

  localparam [2:0] ST_IDLE        = 3'd0;
  localparam [2:0] ST_IFU_RD_ADDR = 3'd1;
  localparam [2:0] ST_IFU_RD_RESP = 3'd2;
  localparam [2:0] ST_LSU_RD_ADDR = 3'd3;
  localparam [2:0] ST_LSU_RD_RESP = 3'd4;
  localparam [2:0] ST_LSU_WR_REQ  = 3'd5;
  localparam [2:0] ST_LSU_WR_RESP = 3'd6;

  reg [2:0] state_r;
  reg       aw_done_r;
  reg       w_done_r;

  wire ifu_ar_fire = ifu_arvalid_i && ifu_arready_o;
  wire ifu_r_fire = ifu_rvalid_o && ifu_rready_i;
  wire lsu_ar_fire = lsu_arvalid_i && lsu_arready_o;
  wire lsu_r_fire = lsu_rvalid_o && lsu_rready_i;
  wire lsu_aw_fire = lsu_awvalid_i && lsu_awready_o;
  wire lsu_w_fire = lsu_wvalid_i && lsu_wready_o;
  wire lsu_b_fire = lsu_bvalid_o && lsu_bready_i;

  always @(*) begin
    if (ifu_awvalid_i || ifu_wvalid_i || ifu_bready_i) begin
      $fatal(1, "IFU must not drive AXI write channels");
    end
  end

  always @(posedge clk) begin
    if (rst) begin
      state_r <= ST_IDLE;
      aw_done_r <= 1'b0;
      w_done_r <= 1'b0;
    end else begin
      case (state_r)
        ST_IDLE: begin
          aw_done_r <= 1'b0;
          w_done_r <= 1'b0;
          if (lsu_awvalid_i || lsu_wvalid_i) begin
            state_r <= ST_LSU_WR_REQ;
          end else if (lsu_arvalid_i) begin
            state_r <= ST_LSU_RD_ADDR;
          end else if (ifu_arvalid_i) begin
            state_r <= ST_IFU_RD_ADDR;
          end
        end

        ST_IFU_RD_ADDR: begin
          if (ifu_ar_fire) begin
            state_r <= ST_IFU_RD_RESP;
          end
        end

        ST_IFU_RD_RESP: begin
          if (ifu_r_fire) begin
            state_r <= ST_IDLE;
          end
        end

        ST_LSU_RD_ADDR: begin
          if (lsu_ar_fire) begin
            state_r <= ST_LSU_RD_RESP;
          end
        end

        ST_LSU_RD_RESP: begin
          if (lsu_r_fire) begin
            state_r <= ST_IDLE;
          end
        end

        ST_LSU_WR_REQ: begin
          if (lsu_aw_fire) begin
            aw_done_r <= 1'b1;
          end
          if (lsu_w_fire) begin
            w_done_r <= 1'b1;
          end
          if ((aw_done_r || lsu_aw_fire) && (w_done_r || lsu_w_fire)) begin
            state_r <= ST_LSU_WR_RESP;
          end
        end

        ST_LSU_WR_RESP: begin
          if (lsu_b_fire) begin
            state_r <= ST_IDLE;
          end
        end

        default: begin
          state_r <= ST_IDLE;
          aw_done_r <= 1'b0;
          w_done_r <= 1'b0;
        end
      endcase
    end
  end

  assign ifu_arready_o = (state_r == ST_IFU_RD_ADDR) ? mem_arready_i : 1'b0;
  assign ifu_rdata_o = mem_rdata_i;
  assign ifu_rresp_o = mem_rresp_i;
  assign ifu_rvalid_o = (state_r == ST_IFU_RD_RESP) ? mem_rvalid_i : 1'b0;
  assign ifu_awready_o = 1'b0;
  assign ifu_wready_o = 1'b0;
  assign ifu_bvalid_o = 1'b0;
  assign ifu_bresp_o = 2'b00;

  assign lsu_awready_o = (state_r == ST_LSU_WR_REQ && !aw_done_r) ? mem_awready_i : 1'b0;
  assign lsu_wready_o = (state_r == ST_LSU_WR_REQ && !w_done_r) ? mem_wready_i : 1'b0;
  assign lsu_bresp_o = mem_bresp_i;
  assign lsu_bvalid_o = (state_r == ST_LSU_WR_RESP) ? mem_bvalid_i : 1'b0;
  assign lsu_arready_o = (state_r == ST_LSU_RD_ADDR) ? mem_arready_i : 1'b0;
  assign lsu_rdata_o = mem_rdata_i;
  assign lsu_rresp_o = mem_rresp_i;
  assign lsu_rvalid_o = (state_r == ST_LSU_RD_RESP) ? mem_rvalid_i : 1'b0;

  assign mem_awaddr_o = lsu_awaddr_i;
  assign mem_awvalid_o = (state_r == ST_LSU_WR_REQ) && !aw_done_r && lsu_awvalid_i;
  assign mem_wdata_o = lsu_wdata_i;
  assign mem_wstrb_o = lsu_wstrb_i;
  assign mem_wvalid_o = (state_r == ST_LSU_WR_REQ) && !w_done_r && lsu_wvalid_i;
  assign mem_bready_o = (state_r == ST_LSU_WR_RESP) ? lsu_bready_i : 1'b0;
  assign mem_araddr_o = (state_r == ST_LSU_RD_ADDR) ? lsu_araddr_i : ifu_araddr_i;
  assign mem_arvalid_o = ((state_r == ST_LSU_RD_ADDR) && lsu_arvalid_i) ||
                         ((state_r == ST_IFU_RD_ADDR) && ifu_arvalid_i);
  assign mem_rready_o = (state_r == ST_LSU_RD_RESP) ? lsu_rready_i :
                        (state_r == ST_IFU_RD_RESP) ? ifu_rready_i : 1'b0;

endmodule
