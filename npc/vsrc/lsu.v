`include "npc_bus.vh"

module lsu (
  input         rst,
  input         clk,
  input  [`EXU_WBU_BUS_W-1:0] ex_bus_i,
  input         ex_valid_i,
  output        ex_ready_o,
  output [`EXU_WBU_BUS_W-1:0] mem_bus_o,
  output [31:0] load_data_o,
  output        mem_valid_o,
  input         mem_ready_i,

  output [31:0] axi_awaddr_o,
  output        axi_awvalid_o,
  input         axi_awready_i,
  output [31:0] axi_wdata_o,
  output [3:0]  axi_wstrb_o,
  output        axi_wvalid_o,
  input         axi_wready_i,
  input  [1:0]  axi_bresp_i,
  input         axi_bvalid_i,
  output        axi_bready_o,
  output [31:0] axi_araddr_o,
  output        axi_arvalid_o,
  input         axi_arready_i,
  input  [31:0] axi_rdata_i,
  input  [1:0]  axi_rresp_i,
  input         axi_rvalid_i,
  output        axi_rready_o
);

  localparam [2:0] ST_IDLE    = 3'd0;
  localparam [2:0] ST_RD_REQ  = 3'd1;
  localparam [2:0] ST_RD_RESP = 3'd2;
  localparam [2:0] ST_WR_REQ  = 3'd3;
  localparam [2:0] ST_WR_RESP = 3'd4;
  localparam [2:0] ST_FINISH  = 3'd5;

  localparam [4:0] VALID_FIXED_DELAY = 5'd0;
  localparam       VALID_USE_LFSR = 1'b1;

  wire is_load_i = ex_bus_i[`EXU_WBU_IS_LOAD];
  wire is_store_i = ex_bus_i[`EXU_WBU_IS_STORE];
  wire [2:0] funct3_i = ex_bus_i[`EXU_WBU_LSU_FUNCT3];
  wire [31:0] addr_i = ex_bus_i[`EXU_WBU_ALU_RES];
  wire [31:0] store_data_i = ex_bus_i[`EXU_WBU_RS2_DATA];

  wire [1:0] byte_off = addr_i[1:0];
  wire valid = is_load_i || is_store_i;
  wire [31:0] aligned_addr = {addr_i[31:2], 2'b00};

  reg [`EXU_WBU_BUS_W-1:0] ex_bus_r;
  reg [31:0] dmem_rdata_r;
  reg [31:0] aligned_addr_r;
  reg [1:0]  byte_off_r;
  reg [31:0] dmem_wdata_r;
  reg [3:0]  dmem_wmask_r;
  reg [4:0]  req_delay_r;
  reg [7:0]  lfsr_r;
  reg [2:0]  state_r;
  reg        aw_done_r;
  reg        w_done_r;

  wire state_is_mem = (state_r != ST_IDLE);
  wire [2:0] funct3_r = ex_bus_r[`EXU_WBU_LSU_FUNCT3];

  wire [7:0] load_byte =
    (byte_off_r == 2'b00) ? dmem_rdata_r[7:0] :
    (byte_off_r == 2'b01) ? dmem_rdata_r[15:8] :
    (byte_off_r == 2'b10) ? dmem_rdata_r[23:16] :
                            dmem_rdata_r[31:24];
  wire [15:0] load_half = byte_off_r[1] ? dmem_rdata_r[31:16] : dmem_rdata_r[15:0];

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
  wire is_lb_r  = ex_bus_r[`EXU_WBU_IS_LOAD] && (funct3_r == 3'b000);
  wire is_lh_r  = ex_bus_r[`EXU_WBU_IS_LOAD] && (funct3_r == 3'b001);
  wire is_lw_r  = ex_bus_r[`EXU_WBU_IS_LOAD] && (funct3_r == 3'b010);
  wire is_lbu_r = ex_bus_r[`EXU_WBU_IS_LOAD] && (funct3_r == 3'b100);
  wire is_lhu_r = ex_bus_r[`EXU_WBU_IS_LOAD] && (funct3_r == 3'b101);

  wire req_done = (req_delay_r == 5'd0);
  wire ar_fire = axi_arvalid_o && axi_arready_i;
  wire r_fire = axi_rvalid_i && axi_rready_o;
  wire aw_fire = axi_awvalid_o && axi_awready_i;
  wire w_fire = axi_wvalid_o && axi_wready_i;
  wire b_fire = axi_bvalid_i && axi_bready_o;
  wire mem_fire = mem_valid_o && mem_ready_i;

  function [7:0] lfsr_next;
    input [7:0] lfsr;
    begin
      lfsr_next = {lfsr[6:0], lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]};
    end
  endfunction

  function [4:0] choose_delay;
    input [7:0] lfsr;
    begin
      choose_delay = VALID_USE_LFSR ? {1'b0, lfsr[3:0]} : VALID_FIXED_DELAY;
    end
  endfunction

  always @(posedge clk) begin
    if (rst) begin
      ex_bus_r <= {`EXU_WBU_BUS_W{1'b0}};
      dmem_rdata_r <= 32'b0;
      aligned_addr_r <= 32'b0;
      byte_off_r <= 2'b0;
      dmem_wdata_r <= 32'b0;
      dmem_wmask_r <= 4'b0;
      req_delay_r <= 5'b0;
      lfsr_r <= 8'ha5;
      state_r <= ST_IDLE;
      aw_done_r <= 1'b0;
      w_done_r <= 1'b0;
    end else begin
      if ((state_r == ST_RD_REQ || state_r == ST_WR_REQ) && (req_delay_r != 5'd0)) begin
        req_delay_r <= req_delay_r - 5'd1;
      end

      case (state_r)
        ST_IDLE: begin
          aw_done_r <= 1'b0;
          w_done_r <= 1'b0;
          if (ex_valid_i && valid) begin
            ex_bus_r <= ex_bus_i;
            aligned_addr_r <= aligned_addr;
            byte_off_r <= byte_off;
            dmem_wdata_r <= dmem_wdata;
            dmem_wmask_r <= dmem_wmask;
            req_delay_r <= choose_delay(lfsr_r);
            lfsr_r <= lfsr_next(lfsr_r);
            state_r <= is_load_i ? ST_RD_REQ : ST_WR_REQ;
          end
        end

        ST_RD_REQ: begin
          if (ar_fire) begin
            state_r <= ST_RD_RESP;
          end
        end

        ST_RD_RESP: begin
          if (r_fire) begin
            dmem_rdata_r <= axi_rdata_i;
            state_r <= ST_FINISH;
          end
        end

        ST_WR_REQ: begin
          if (aw_fire) begin
            aw_done_r <= 1'b1;
          end
          if (w_fire) begin
            w_done_r <= 1'b1;
          end
          if ((aw_done_r || aw_fire) && (w_done_r || w_fire)) begin
            state_r <= ST_WR_RESP;
          end
        end

        ST_WR_RESP: begin
          if (b_fire) begin
            state_r <= ST_FINISH;
          end
        end

        ST_FINISH: begin
          if (mem_fire) begin
            state_r <= ST_IDLE;
          end
        end

        default: begin
          state_r <= ST_IDLE;
        end
      endcase
    end
  end

  assign axi_awaddr_o = aligned_addr_r;
  assign axi_awvalid_o = (state_r == ST_WR_REQ) && req_done && !aw_done_r;
  assign axi_wdata_o = dmem_wdata_r;
  assign axi_wstrb_o = dmem_wmask_r;
  assign axi_wvalid_o = (state_r == ST_WR_REQ) && req_done && !w_done_r;
  assign axi_bready_o = (state_r == ST_WR_RESP);
  assign axi_araddr_o = aligned_addr_r;
  assign axi_arvalid_o = (state_r == ST_RD_REQ) && req_done;
  assign axi_rready_o = (state_r == ST_RD_RESP);

  assign mem_bus_o = state_is_mem ? ex_bus_r : ex_bus_i;
  assign mem_valid_o = ex_valid_i && (!valid || (state_r == ST_FINISH));
  assign ex_ready_o = mem_ready_i && (!valid || (state_r == ST_FINISH));
  assign load_data_o = is_lb_r  ? {{24{load_byte[7]}}, load_byte} :
                       is_lbu_r ? {24'b0, load_byte} :
                       is_lh_r  ? {{16{load_half[15]}}, load_half} :
                       is_lhu_r ? {16'b0, load_half} :
                       is_lw_r  ? dmem_rdata_r :
                                  32'b0;

endmodule
