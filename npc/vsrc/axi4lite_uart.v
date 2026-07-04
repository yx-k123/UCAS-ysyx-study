module axi4lite_uart (
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

  localparam [1:0] ST_IDLE    = 2'd0;
  localparam [1:0] ST_RD_RESP = 2'd1;
  localparam [1:0] ST_WR_RESP = 2'd2;

  localparam [1:0] AXI_RESP_OKAY = 2'b00;

  reg [1:0]  state_r;
  reg [31:0] uart_reg_r;
  reg [31:0] rdata_r;
  reg [31:0] write_addr_r;
  reg [31:0] write_data_r;
  reg [3:0]  write_strb_r;
  reg        aw_seen_r;
  reg        w_seen_r;

  wire ar_fire = axi_arvalid_i && axi_arready_o;
  wire r_fire = axi_rvalid_o && axi_rready_i;
  wire aw_fire = axi_awvalid_i && axi_awready_o;
  wire w_fire = axi_wvalid_i && axi_wready_o;
  wire b_fire = axi_bvalid_o && axi_bready_i;

  wire [31:0] write_data_next = w_fire ? axi_wdata_i : write_data_r;
  wire [3:0]  write_strb_next = w_fire ? axi_wstrb_i : write_strb_r;

  function [31:0] apply_wstrb;
    input [31:0] old_data;
    input [31:0] new_data;
    input [3:0]  wstrb;
    begin
      apply_wstrb = old_data;
      if (wstrb[0]) apply_wstrb[7:0]   = new_data[7:0];
      if (wstrb[1]) apply_wstrb[15:8]  = new_data[15:8];
      if (wstrb[2]) apply_wstrb[23:16] = new_data[23:16];
      if (wstrb[3]) apply_wstrb[31:24] = new_data[31:24];
    end
  endfunction

  always @(posedge clk) begin
    if (rst) begin
      state_r <= ST_IDLE;
      uart_reg_r <= 32'b0;
      rdata_r <= 32'b0;
      write_addr_r <= 32'b0;
      write_data_r <= 32'b0;
      write_strb_r <= 4'b0;
      aw_seen_r <= 1'b0;
      w_seen_r <= 1'b0;
    end else begin
      case (state_r)
        ST_IDLE: begin
          if (ar_fire) begin
            rdata_r <= uart_reg_r;
            state_r <= ST_RD_RESP;
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
              uart_reg_r <= apply_wstrb(uart_reg_r, write_data_next, write_strb_next);
              if (write_strb_next[0]) $write("%c", write_data_next[7:0]);
              if (write_strb_next[1]) $write("%c", write_data_next[15:8]);
              if (write_strb_next[2]) $write("%c", write_data_next[23:16]);
              if (write_strb_next[3]) $write("%c", write_data_next[31:24]);
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
  assign axi_bresp_o = AXI_RESP_OKAY;
  assign axi_bvalid_o = (state_r == ST_WR_RESP);
  assign axi_arready_o = !rst && (state_r == ST_IDLE) && !aw_seen_r && !w_seen_r;
  assign axi_rdata_o = rdata_r;
  assign axi_rresp_o = AXI_RESP_OKAY;
  assign axi_rvalid_o = (state_r == ST_RD_RESP);

endmodule
