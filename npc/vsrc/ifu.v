`include "npc_bus.vh"

module ifu (
  input         clk,
  input         rst,
  input  [31:0] pc_i,
  input         pc_valid_i,
  output        pc_ready_o,
  output [`IFU_IDU_BUS_W-1:0] if_bus_o,
  output        if_valid_o,
  input         if_ready_i,

  output [31:0] axi_araddr_o,
  output        axi_arvalid_o,
  input         axi_arready_i,
  input  [31:0] axi_rdata_i,
  input         axi_rvalid_i,
  output        axi_rready_o
);

  localparam [4:0] VALID_FIXED_DELAY = 5'd0;
  localparam       VALID_USE_LFSR = 1'b1;

  reg [31:0] pc_r;
  reg [31:0] inst_r;
  reg [4:0] req_delay_r;
  reg [7:0] lfsr_r;
  reg       req_pending_r;
  reg       resp_pending_r;
  reg       inst_valid_r;

  wire ar_fire = axi_arvalid_o && axi_arready_i;
  wire r_fire = axi_rvalid_i && axi_rready_o;
  wire if_fire = if_valid_o && if_ready_i;
  wire can_start = pc_valid_i && !req_pending_r && !resp_pending_r && !inst_valid_r;

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
      pc_r <= 32'b0;
      inst_r <= 32'b0;
      req_delay_r <= 5'b0;
      lfsr_r <= 8'h1;
      req_pending_r <= 1'b0;
      resp_pending_r <= 1'b0;
      inst_valid_r <= 1'b0;
    end else begin
      if (req_pending_r && (req_delay_r != 5'd0)) begin
        req_delay_r <= req_delay_r - 5'd1;
      end

      if (can_start) begin
        pc_r <= pc_i;
        req_delay_r <= choose_delay(lfsr_r);
        lfsr_r <= lfsr_next(lfsr_r);
        req_pending_r <= 1'b1;
      end

      if (ar_fire) begin
        req_pending_r <= 1'b0;
        resp_pending_r <= 1'b1;
      end

      if (r_fire) begin
        inst_r <= axi_rdata_i;
        resp_pending_r <= 1'b0;
        inst_valid_r <= 1'b1;
      end

      if (if_fire) begin
        inst_valid_r <= 1'b0;
      end
    end
  end

  assign axi_araddr_o = pc_r;
  assign axi_arvalid_o = req_pending_r && (req_delay_r == 5'd0);
  assign axi_rready_o = resp_pending_r;

  assign pc_ready_o = inst_valid_r && if_ready_i;
  assign if_valid_o = inst_valid_r;
  assign if_bus_o[`IFU_IDU_PC] = pc_r;
  assign if_bus_o[`IFU_IDU_INST] = inst_r;

endmodule
