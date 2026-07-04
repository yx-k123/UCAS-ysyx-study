module axi4lite_xbar (
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

  output [31:0] sram_awaddr_o,
  output        sram_awvalid_o,
  input         sram_awready_i,
  output [31:0] sram_wdata_o,
  output [3:0]  sram_wstrb_o,
  output        sram_wvalid_o,
  input         sram_wready_i,
  input  [1:0]  sram_bresp_i,
  input         sram_bvalid_i,
  output        sram_bready_o,
  output [31:0] sram_araddr_o,
  output        sram_arvalid_o,
  input         sram_arready_i,
  input  [31:0] sram_rdata_i,
  input  [1:0]  sram_rresp_i,
  input         sram_rvalid_i,
  output        sram_rready_o,

  output [31:0] uart_awaddr_o,
  output        uart_awvalid_o,
  input         uart_awready_i,
  output [31:0] uart_wdata_o,
  output [3:0]  uart_wstrb_o,
  output        uart_wvalid_o,
  input         uart_wready_i,
  input  [1:0]  uart_bresp_i,
  input         uart_bvalid_i,
  output        uart_bready_o,
  output [31:0] uart_araddr_o,
  output        uart_arvalid_o,
  input         uart_arready_i,
  input  [31:0] uart_rdata_i,
  input  [1:0]  uart_rresp_i,
  input         uart_rvalid_i,
  output        uart_rready_o
);

  localparam [2:0] ST_IDLE    = 3'd0;
  localparam [2:0] ST_RD_REQ  = 3'd1;
  localparam [2:0] ST_RD_RESP = 3'd2;
  localparam [2:0] ST_RD_ERR  = 3'd3;
  localparam [2:0] ST_WR_REQ  = 3'd4;
  localparam [2:0] ST_WR_RESP = 3'd5;
  localparam [2:0] ST_WR_ERR  = 3'd6;

  localparam [1:0] TARGET_NONE = 2'd0;
  localparam [1:0] TARGET_SRAM = 2'd1;
  localparam [1:0] TARGET_UART = 2'd2;

  localparam [1:0] AXI_RESP_OKAY   = 2'b00;
  localparam [1:0] AXI_RESP_DECERR = 2'b11;

  reg [2:0]  state_r;
  reg [1:0]  target_r;
  reg [31:0] read_addr_r;
  reg [31:0] write_addr_r;
  reg [31:0] write_data_r;
  reg [3:0]  write_strb_r;
  reg [31:0] err_rdata_r;
  reg        aw_seen_r;
  reg        w_seen_r;
  reg        wr_aw_sent_r;
  reg        wr_w_sent_r;

  wire ar_fire = axi_arvalid_i && axi_arready_o;
  wire r_fire = axi_rvalid_o && axi_rready_i;
  wire aw_fire = axi_awvalid_i && axi_awready_o;
  wire w_fire = axi_wvalid_i && axi_wready_o;
  wire b_fire = axi_bvalid_o && axi_bready_i;

  wire sram_ar_fire = sram_arvalid_o && sram_arready_i;
  wire uart_ar_fire = uart_arvalid_o && uart_arready_i;
  wire sram_aw_fire = sram_awvalid_o && sram_awready_i;
  wire uart_aw_fire = uart_awvalid_o && uart_awready_i;
  wire sram_w_fire = sram_wvalid_o && sram_wready_i;
  wire uart_w_fire = uart_wvalid_o && uart_wready_i;

  wire [31:0] write_data_next = w_fire ? axi_wdata_i : write_data_r;
  wire [3:0]  write_strb_next = w_fire ? axi_wstrb_i : write_strb_r;
  wire [31:0] write_addr_next = aw_fire ? axi_awaddr_i : write_addr_r;

  function is_sram_addr;
    input [31:0] addr;
    begin
      is_sram_addr = (addr >= 32'h8000_0000) && (addr < 32'h9000_0000);
    end
  endfunction

  function is_uart_addr;
    input [31:0] addr;
    begin
      is_uart_addr = ({addr[31:2], 2'b00} == 32'h1000_0000);
    end
  endfunction

  function [1:0] decode_target;
    input [31:0] addr;
    begin
      if (is_sram_addr(addr)) begin
        decode_target = TARGET_SRAM;
      end else if (is_uart_addr(addr)) begin
        decode_target = TARGET_UART;
      end else begin
        decode_target = TARGET_NONE;
      end
    end
  endfunction

  always @(posedge clk) begin
    if (rst) begin
      state_r <= ST_IDLE;
      target_r <= TARGET_NONE;
      read_addr_r <= 32'b0;
      write_addr_r <= 32'b0;
      write_data_r <= 32'b0;
      write_strb_r <= 4'b0;
      err_rdata_r <= 32'b0;
      aw_seen_r <= 1'b0;
      w_seen_r <= 1'b0;
      wr_aw_sent_r <= 1'b0;
      wr_w_sent_r <= 1'b0;
    end else begin
      case (state_r)
        ST_IDLE: begin
          target_r <= TARGET_NONE;
          wr_aw_sent_r <= 1'b0;
          wr_w_sent_r <= 1'b0;
          if (ar_fire) begin
            read_addr_r <= axi_araddr_i;
            target_r <= decode_target(axi_araddr_i);
            if (decode_target(axi_araddr_i) == TARGET_NONE) begin
              err_rdata_r <= 32'b0;
              state_r <= ST_RD_ERR;
            end else begin
              state_r <= ST_RD_REQ;
            end
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
              target_r <= decode_target(write_addr_next);
              write_addr_r <= write_addr_next;
              write_data_r <= write_data_next;
              write_strb_r <= write_strb_next;
              aw_seen_r <= 1'b0;
              w_seen_r <= 1'b0;
              if (decode_target(write_addr_next) == TARGET_NONE) begin
                state_r <= ST_WR_ERR;
              end else begin
                state_r <= ST_WR_REQ;
              end
            end
          end
        end

        ST_RD_REQ: begin
          if ((target_r == TARGET_SRAM && sram_ar_fire) ||
              (target_r == TARGET_UART && uart_ar_fire)) begin
            state_r <= ST_RD_RESP;
          end
        end

        ST_RD_RESP: begin
          if (r_fire) begin
            state_r <= ST_IDLE;
          end
        end

        ST_RD_ERR: begin
          if (r_fire) begin
            state_r <= ST_IDLE;
          end
        end

        ST_WR_REQ: begin
          if (target_r == TARGET_SRAM) begin
            if (sram_aw_fire) begin
              wr_aw_sent_r <= 1'b1;
            end
            if (sram_w_fire) begin
              wr_w_sent_r <= 1'b1;
            end
          end else if (target_r == TARGET_UART) begin
            if (uart_aw_fire) begin
              wr_aw_sent_r <= 1'b1;
            end
            if (uart_w_fire) begin
              wr_w_sent_r <= 1'b1;
            end
          end

          if ((wr_aw_sent_r || sram_aw_fire || uart_aw_fire) &&
              (wr_w_sent_r || sram_w_fire || uart_w_fire)) begin
            state_r <= ST_WR_RESP;
          end
        end

        ST_WR_RESP: begin
          if (b_fire) begin
            state_r <= ST_IDLE;
          end
        end

        ST_WR_ERR: begin
          if (b_fire) begin
            state_r <= ST_IDLE;
          end
        end

        default: begin
          state_r <= ST_IDLE;
          target_r <= TARGET_NONE;
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
  assign axi_bresp_o = (state_r == ST_WR_ERR) ? AXI_RESP_DECERR :
                       (target_r == TARGET_UART) ? uart_bresp_i : sram_bresp_i;
  assign axi_bvalid_o = (state_r == ST_WR_ERR) ? 1'b1 :
                        (state_r == ST_WR_RESP && target_r == TARGET_UART) ? uart_bvalid_i :
                        (state_r == ST_WR_RESP && target_r == TARGET_SRAM) ? sram_bvalid_i : 1'b0;
  assign axi_arready_o = !rst && (state_r == ST_IDLE) && !aw_seen_r && !w_seen_r;
  assign axi_rdata_o = (state_r == ST_RD_ERR) ? err_rdata_r :
                       (target_r == TARGET_UART) ? uart_rdata_i : sram_rdata_i;
  assign axi_rresp_o = (state_r == ST_RD_ERR) ? AXI_RESP_DECERR :
                       (target_r == TARGET_UART) ? uart_rresp_i : sram_rresp_i;
  assign axi_rvalid_o = (state_r == ST_RD_ERR) ? 1'b1 :
                        (state_r == ST_RD_RESP && target_r == TARGET_UART) ? uart_rvalid_i :
                        (state_r == ST_RD_RESP && target_r == TARGET_SRAM) ? sram_rvalid_i : 1'b0;

  assign sram_awaddr_o = write_addr_r;
  assign sram_awvalid_o = (state_r == ST_WR_REQ) && (target_r == TARGET_SRAM) && !wr_aw_sent_r;
  assign sram_wdata_o = write_data_r;
  assign sram_wstrb_o = write_strb_r;
  assign sram_wvalid_o = (state_r == ST_WR_REQ) && (target_r == TARGET_SRAM) && !wr_w_sent_r;
  assign sram_bready_o = (state_r == ST_WR_RESP) && (target_r == TARGET_SRAM) ? axi_bready_i : 1'b0;
  assign sram_araddr_o = read_addr_r;
  assign sram_arvalid_o = (state_r == ST_RD_REQ) && (target_r == TARGET_SRAM);
  assign sram_rready_o = (state_r == ST_RD_RESP) && (target_r == TARGET_SRAM) ? axi_rready_i : 1'b0;

  assign uart_awaddr_o = write_addr_r;
  assign uart_awvalid_o = (state_r == ST_WR_REQ) && (target_r == TARGET_UART) && !wr_aw_sent_r;
  assign uart_wdata_o = write_data_r;
  assign uart_wstrb_o = write_strb_r;
  assign uart_wvalid_o = (state_r == ST_WR_REQ) && (target_r == TARGET_UART) && !wr_w_sent_r;
  assign uart_bready_o = (state_r == ST_WR_RESP) && (target_r == TARGET_UART) ? axi_bready_i : 1'b0;
  assign uart_araddr_o = read_addr_r;
  assign uart_arvalid_o = (state_r == ST_RD_REQ) && (target_r == TARGET_UART);
  assign uart_rready_o = (state_r == ST_RD_RESP) && (target_r == TARGET_UART) ? axi_rready_i : 1'b0;

endmodule
