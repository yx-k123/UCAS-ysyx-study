module axi4lite_clint (
  input         clk,
  input         rst,

  input  [31:0] axi_awaddr_i,
  input         axi_awvalid_i,
  output        axi_awready_o,
  input  [31:0] axi_wdata_i,
  input  [3:0]  axi_wstrb_i,
  input         axi_wvalid_i,
  output        axi_wready_o,
  output [1:0]  axi_bresp_o,
  output        axi_bvalid_o,
  input         axi_bready_i,
  input  [31:0] axi_araddr_i,
  input         axi_arvalid_i,
  output        axi_arready_o,
  output [31:0] axi_rdata_o,
  output [1:0]  axi_rresp_o,
  output        axi_rvalid_o,
  input         axi_rready_i
);

  import "DPI-C" function longint unsigned clint_mtime();

  localparam [1:0] ST_IDLE    = 2'd0;
  localparam [1:0] ST_RD_RESP = 2'd1;
  localparam [1:0] ST_WR_RESP = 2'd2;

  localparam [31:0] MTIME_LO_ADDR = 32'h1000_0010;
  localparam [31:0] MTIME_HI_ADDR = 32'h1000_0014;

  localparam [1:0] AXI_RESP_OKAY   = 2'b00;
  localparam [1:0] AXI_RESP_SLVERR = 2'b10;

  reg [1:0]  state_r;
  reg [31:0] read_addr_r;
  reg [63:0] mtime_snapshot_r;
  reg [1:0]  rresp_r;
  reg [1:0]  bresp_r;
  reg        aw_seen_r;
  reg        w_seen_r;

  wire ar_fire = axi_arvalid_i && axi_arready_o;
  wire r_fire = axi_rvalid_o && axi_rready_i;
  wire aw_fire = axi_awvalid_i && axi_awready_o;
  wire w_fire = axi_wvalid_i && axi_wready_o;
  wire b_fire = axi_bvalid_o && axi_bready_i;

  wire [31:0] aligned_araddr = {axi_araddr_i[31:2], 2'b00};
  wire ar_is_lo = (aligned_araddr == MTIME_LO_ADDR);
  wire ar_is_hi = (aligned_araddr == MTIME_HI_ADDR);

  always @(posedge clk) begin
    if (rst) begin
      state_r <= ST_IDLE;
      read_addr_r <= 32'b0;
      mtime_snapshot_r <= 64'b0;
      rresp_r <= AXI_RESP_OKAY;
      bresp_r <= AXI_RESP_OKAY;
      aw_seen_r <= 1'b0;
      w_seen_r <= 1'b0;
    end else begin
      case (state_r)
        ST_IDLE: begin
          if (ar_fire) begin
            read_addr_r <= aligned_araddr;
            mtime_snapshot_r <= clint_mtime();
            if (ar_is_lo) begin
              rresp_r <= AXI_RESP_OKAY;
            end else if (ar_is_hi) begin
              rresp_r <= AXI_RESP_OKAY;
            end else begin
              rresp_r <= AXI_RESP_SLVERR;
            end
            state_r <= ST_RD_RESP;
          end else begin
            if (aw_fire) begin
              aw_seen_r <= 1'b1;
              bresp_r <= AXI_RESP_SLVERR;
            end

            if (w_fire) begin
              w_seen_r <= 1'b1;
            end

            if ((aw_seen_r || aw_fire) && (w_seen_r || w_fire)) begin
              aw_seen_r <= 1'b0;
              w_seen_r <= 1'b0;
              state_r <= ST_WR_RESP;
            end
          end
        end

        ST_RD_RESP: begin
          if (r_fire) begin
            state_r <= ST_IDLE;
          end
        end

        ST_WR_RESP: begin
          if (b_fire) begin
            state_r <= ST_IDLE;
          end
        end

        default: begin
          state_r <= ST_IDLE;
          aw_seen_r <= 1'b0;
          w_seen_r <= 1'b0;
        end
      endcase
    end
  end

  assign axi_awready_o = !rst && (state_r == ST_IDLE) && !aw_seen_r;
  assign axi_wready_o = !rst && (state_r == ST_IDLE) && !w_seen_r;
  assign axi_bresp_o = bresp_r;
  assign axi_bvalid_o = (state_r == ST_WR_RESP);
  assign axi_arready_o = !rst && (state_r == ST_IDLE) && !aw_seen_r && !w_seen_r;
  assign axi_rdata_o = (read_addr_r == MTIME_LO_ADDR) ? mtime_snapshot_r[31:0] :
                       (read_addr_r == MTIME_HI_ADDR) ? mtime_snapshot_r[63:32] :
                       32'b0;
  assign axi_rresp_o = rresp_r;
  assign axi_rvalid_o = (state_r == ST_RD_RESP);

endmodule
