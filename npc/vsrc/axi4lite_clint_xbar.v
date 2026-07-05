module axi4lite_clint_xbar (
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
  input         axi_rready_i,

  output [31:0] ext_awaddr_o,
  output        ext_awvalid_o,
  input         ext_awready_i,
  output [31:0] ext_wdata_o,
  output [3:0]  ext_wstrb_o,
  output        ext_wvalid_o,
  input         ext_wready_i,
  input  [1:0]  ext_bresp_i,
  input         ext_bvalid_i,
  output        ext_bready_o,
  output [31:0] ext_araddr_o,
  output        ext_arvalid_o,
  input         ext_arready_i,
  input  [31:0] ext_rdata_i,
  input  [1:0]  ext_rresp_i,
  input         ext_rvalid_i,
  output        ext_rready_o,

  output [31:0] clint_awaddr_o,
  output        clint_awvalid_o,
  input         clint_awready_i,
  output [31:0] clint_wdata_o,
  output [3:0]  clint_wstrb_o,
  output        clint_wvalid_o,
  input         clint_wready_i,
  input  [1:0]  clint_bresp_i,
  input         clint_bvalid_i,
  output        clint_bready_o,
  output [31:0] clint_araddr_o,
  output        clint_arvalid_o,
  input         clint_arready_i,
  input  [31:0] clint_rdata_i,
  input  [1:0]  clint_rresp_i,
  input         clint_rvalid_i,
  output        clint_rready_o
);

  localparam [2:0] ST_IDLE    = 3'd0;
  localparam [2:0] ST_RD_REQ  = 3'd1;
  localparam [2:0] ST_RD_RESP = 3'd2;
  localparam [2:0] ST_WR_REQ  = 3'd3;
  localparam [2:0] ST_WR_RESP = 3'd4;

  localparam       TARGET_EXT   = 1'b0;
  localparam       TARGET_CLINT = 1'b1;

  reg        state_is_write_r;
  reg [2:0]  state_r;
  reg        target_r;
  reg [31:0] read_addr_r;
  reg [31:0] write_addr_r;
  reg [31:0] write_data_r;
  reg [3:0]  write_strb_r;
  reg        aw_seen_r;
  reg        w_seen_r;
  reg        wr_aw_sent_r;
  reg        wr_w_sent_r;

  wire ar_fire = axi_arvalid_i && axi_arready_o;
  wire r_fire = axi_rvalid_o && axi_rready_i;
  wire aw_fire = axi_awvalid_i && axi_awready_o;
  wire w_fire = axi_wvalid_i && axi_wready_o;
  wire b_fire = axi_bvalid_o && axi_bready_i;

  wire ext_ar_fire = ext_arvalid_o && ext_arready_i;
  wire clint_ar_fire = clint_arvalid_o && clint_arready_i;
  wire ext_aw_fire = ext_awvalid_o && ext_awready_i;
  wire clint_aw_fire = clint_awvalid_o && clint_awready_i;
  wire ext_w_fire = ext_wvalid_o && ext_wready_i;
  wire clint_w_fire = clint_wvalid_o && clint_wready_i;

  wire [31:0] write_data_next = w_fire ? axi_wdata_i : write_data_r;
  wire [3:0]  write_strb_next = w_fire ? axi_wstrb_i : write_strb_r;
  wire [31:0] write_addr_next = aw_fire ? axi_awaddr_i : write_addr_r;

  function is_clint_addr;
    input [31:0] addr;
    begin
      is_clint_addr = ({addr[31:2], 2'b00} == 32'h1000_0010) ||
                      ({addr[31:2], 2'b00} == 32'h1000_0014);
    end
  endfunction

  function decode_target;
    input [31:0] addr;
    begin
      decode_target = is_clint_addr(addr) ? TARGET_CLINT : TARGET_EXT;
    end
  endfunction

  always @(posedge clk) begin
    if (rst) begin
      state_r <= ST_IDLE;
      state_is_write_r <= 1'b0;
      target_r <= TARGET_EXT;
      read_addr_r <= 32'b0;
      write_addr_r <= 32'b0;
      write_data_r <= 32'b0;
      write_strb_r <= 4'b0;
      aw_seen_r <= 1'b0;
      w_seen_r <= 1'b0;
      wr_aw_sent_r <= 1'b0;
      wr_w_sent_r <= 1'b0;
    end else begin
      case (state_r)
        ST_IDLE: begin
          state_is_write_r <= 1'b0;
          wr_aw_sent_r <= 1'b0;
          wr_w_sent_r <= 1'b0;
          if (ar_fire) begin
            state_r <= ST_RD_REQ;
            read_addr_r <= axi_araddr_i;
            target_r <= decode_target(axi_araddr_i);
          end else begin
            if (aw_fire) begin
              write_addr_r <= axi_awaddr_i;
              aw_seen_r <= 1'b1;
            end

            if (w_fire) begin
              write_data_r <= axi_wdata_i;
              write_strb_r <= axi_wstrb_i;
              w_seen_r <= 1'b1;
            end

            if ((aw_seen_r || aw_fire) && (w_seen_r || w_fire)) begin
              state_r <= ST_WR_REQ;
              state_is_write_r <= 1'b1;
              target_r <= decode_target(write_addr_next);
              write_addr_r <= write_addr_next;
              write_data_r <= write_data_next;
              write_strb_r <= write_strb_next;
              aw_seen_r <= 1'b0;
              w_seen_r <= 1'b0;
            end
          end
        end

        ST_RD_REQ: begin
          if ((target_r == TARGET_EXT && ext_ar_fire) ||
              (target_r == TARGET_CLINT && clint_ar_fire)) begin
            state_r <= ST_RD_RESP;
          end
        end

        ST_RD_RESP: begin
          if (r_fire) begin
            state_r <= ST_IDLE;
          end
        end

        ST_WR_REQ: begin
          if (target_r == TARGET_EXT) begin
            if (ext_aw_fire) begin
              wr_aw_sent_r <= 1'b1;
            end
            if (ext_w_fire) begin
              wr_w_sent_r <= 1'b1;
            end
          end else begin
            if (clint_aw_fire) begin
              wr_aw_sent_r <= 1'b1;
            end
            if (clint_w_fire) begin
              wr_w_sent_r <= 1'b1;
            end
          end

          if ((wr_aw_sent_r || ext_aw_fire || clint_aw_fire) &&
              (wr_w_sent_r || ext_w_fire || clint_w_fire)) begin
            state_r <= ST_WR_RESP;
          end
        end

        ST_WR_RESP: begin
          if (b_fire) begin
            state_r <= ST_IDLE;
          end
        end

        default: begin
          state_r <= ST_IDLE;
          state_is_write_r <= 1'b0;
          target_r <= TARGET_EXT;
          aw_seen_r <= 1'b0;
          w_seen_r <= 1'b0;
          wr_aw_sent_r <= 1'b0;
          wr_w_sent_r <= 1'b0;
        end
      endcase
    end
  end

  assign axi_awready_o = !rst && (state_r == ST_IDLE) && !aw_seen_r;
  assign axi_wready_o = !rst && (state_r == ST_IDLE) && !w_seen_r;
  assign axi_arready_o = !rst && (state_r == ST_IDLE) && !aw_seen_r && !w_seen_r;

  assign axi_bresp_o = (target_r == TARGET_CLINT) ? clint_bresp_i : ext_bresp_i;
  assign axi_bvalid_o = (state_r == ST_WR_RESP && target_r == TARGET_CLINT) ? clint_bvalid_i :
                        (state_r == ST_WR_RESP && target_r == TARGET_EXT) ? ext_bvalid_i : 1'b0;
  assign axi_rdata_o = (target_r == TARGET_CLINT) ? clint_rdata_i : ext_rdata_i;
  assign axi_rresp_o = (target_r == TARGET_CLINT) ? clint_rresp_i : ext_rresp_i;
  assign axi_rvalid_o = (state_r == ST_RD_RESP && target_r == TARGET_CLINT) ? clint_rvalid_i :
                        (state_r == ST_RD_RESP && target_r == TARGET_EXT) ? ext_rvalid_i : 1'b0;

  assign ext_awaddr_o = write_addr_r;
  assign ext_awvalid_o = (state_r == ST_WR_REQ) && (target_r == TARGET_EXT) && !wr_aw_sent_r;
  assign ext_wdata_o = write_data_r;
  assign ext_wstrb_o = write_strb_r;
  assign ext_wvalid_o = (state_r == ST_WR_REQ) && (target_r == TARGET_EXT) && !wr_w_sent_r;
  assign ext_bready_o = (state_r == ST_WR_RESP) && (target_r == TARGET_EXT) ? axi_bready_i : 1'b0;
  assign ext_araddr_o = read_addr_r;
  assign ext_arvalid_o = (state_r == ST_RD_REQ) && (target_r == TARGET_EXT);
  assign ext_rready_o = (state_r == ST_RD_RESP) && (target_r == TARGET_EXT) ? axi_rready_i : 1'b0;

  assign clint_awaddr_o = write_addr_r;
  assign clint_awvalid_o = (state_r == ST_WR_REQ) && (target_r == TARGET_CLINT) && !wr_aw_sent_r;
  assign clint_wdata_o = write_data_r;
  assign clint_wstrb_o = write_strb_r;
  assign clint_wvalid_o = (state_r == ST_WR_REQ) && (target_r == TARGET_CLINT) && !wr_w_sent_r;
  assign clint_bready_o = (state_r == ST_WR_RESP) && (target_r == TARGET_CLINT) ? axi_bready_i : 1'b0;
  assign clint_araddr_o = read_addr_r;
  assign clint_arvalid_o = (state_r == ST_RD_REQ) && (target_r == TARGET_CLINT);
  assign clint_rready_o = (state_r == ST_RD_RESP) && (target_r == TARGET_CLINT) ? axi_rready_i : 1'b0;

endmodule
