module axi4lite_mem (
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

  import "DPI-C" function int pmem_read(input int raddr);
  import "DPI-C" function void pmem_write(input int waddr, input int wdata, input int wmask);

  localparam [2:0] ST_IDLE     = 3'd0;
  localparam [2:0] ST_RD_WAIT  = 3'd1;
  localparam [2:0] ST_RD_RESP  = 3'd2;
  localparam [2:0] ST_WR_WAIT  = 3'd3;
  localparam [2:0] ST_WR_RESP  = 3'd4;

  localparam [4:0] MEM_FIXED_DELAY = 5'd5;
  localparam       MEM_USE_LFSR = 1'b1;
  localparam [1:0] AXI_RESP_OKAY = 2'b00;

  reg [2:0]  state_r;
  reg [31:0] read_addr_r;
  reg [31:0] rdata_r;
  reg [31:0] write_addr_r;
  reg [31:0] write_data_r;
  reg [3:0]  write_strb_r;
  reg [4:0]  delay_r;
  reg [7:0]  lfsr_r;
  reg        aw_seen_r;
  reg        w_seen_r;

  wire ar_fire = axi_arvalid_i && axi_arready_o;
  wire r_fire = axi_rvalid_o && axi_rready_i;
  wire aw_fire = axi_awvalid_i && axi_awready_o;
  wire w_fire = axi_wvalid_i && axi_wready_o;
  wire b_fire = axi_bvalid_o && axi_bready_i;

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

  always @(posedge clk) begin
    if (rst) begin
      state_r <= ST_IDLE;
      read_addr_r <= 32'b0;
      rdata_r <= 32'b0;
      write_addr_r <= 32'b0;
      write_data_r <= 32'b0;
      write_strb_r <= 4'b0;
      delay_r <= 5'b0;
      lfsr_r <= 8'h1;
      aw_seen_r <= 1'b0;
      w_seen_r <= 1'b0;
    end else begin
      case (state_r)
        ST_IDLE: begin
          if (ar_fire) begin
            read_addr_r <= axi_araddr_i;
            delay_r <= choose_delay(lfsr_r);
            lfsr_r <= lfsr_next(lfsr_r);
            state_r <= ST_RD_WAIT;
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
              delay_r <= choose_delay(lfsr_r);
              lfsr_r <= lfsr_next(lfsr_r);
              aw_seen_r <= 1'b0;
              w_seen_r <= 1'b0;
              state_r <= ST_WR_WAIT;
            end
          end
        end

        ST_RD_WAIT: begin
          if (delay_r != 5'd0) begin
            delay_r <= delay_r - 5'd1;
          end else begin
            rdata_r <= pmem_read(read_addr_r);
            state_r <= ST_RD_RESP;
          end
        end

        ST_RD_RESP: begin
          if (r_fire) begin
            state_r <= ST_IDLE;
          end
        end

        ST_WR_WAIT: begin
          if (delay_r != 5'd0) begin
            delay_r <= delay_r - 5'd1;
          end else begin
            pmem_write(write_addr_r, write_data_r, {28'b0, write_strb_r});
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
