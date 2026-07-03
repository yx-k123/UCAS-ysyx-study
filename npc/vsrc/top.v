`include "npc_bus.vh"

module top (
  input         clk,
  input         rst,

  output [31:0] debug_pc,
  output [31:0] debug_inst
);

  import "DPI-C" function void npc_ebreak(input int unsigned pc, input int unsigned inst, input int unsigned a0);
  import "DPI-C" function void trace_inst(input int pc, input int inst);

  reg [31:0] pc_r;
  wire [31:0] pc_next;
  wire        pc_valid;
  wire        pc_ready;

  wire [`IFU_IDU_BUS_W-1:0] ifu_idu_bus;
  wire [`IDU_EXU_BUS_W-1:0] idu_exu_bus;
  wire [`EXU_WBU_BUS_W-1:0] exu_wbu_bus;
  wire [`EXU_WBU_BUS_W-1:0] mem_wbu_bus;

  wire if_valid;
  wire if_ready;
  wire id_valid;
  wire id_ready;
  wire ex_valid;
  wire ex_ready;
  wire mem_valid;
  wire mem_ready;
  wire wb_fire;

  wire [31:0] inst;
  wire [4:0] rs1_idx;
  wire [4:0] rs2_idx;
  wire [11:0] csr_addr;
  wire is_csrrw;
  wire is_csrrs;
  wire is_ecall;
  wire is_ebreak;

  wire [31:0] rs1_data;
  wire [31:0] rs2_data;
  wire [31:0] a0_data;

  wire [31:0] load_data;
  wire [31:0] csr_rdata;
  wire [31:0] mtvec;
  wire [31:0] mepc;

  wire rf_we;
  wire [4:0] rf_waddr;
  wire [31:0] rf_wdata;

  assign pc_valid = ~rst;
  assign wb_fire = mem_valid && mem_ready;
  assign inst = ifu_idu_bus[`IFU_IDU_INST];
  assign rs1_idx = idu_exu_bus[`IDU_EXU_RS1_IDX];
  assign rs2_idx = idu_exu_bus[`IDU_EXU_RS2_IDX];
  assign csr_addr = mem_wbu_bus[`EXU_WBU_CSR_ADDR];
  assign is_csrrw = mem_wbu_bus[`EXU_WBU_IS_CSRRW];
  assign is_csrrs = mem_wbu_bus[`EXU_WBU_IS_CSRRS];
  assign is_ecall = mem_wbu_bus[`EXU_WBU_IS_ECALL];
  assign is_ebreak = mem_wbu_bus[`EXU_WBU_IS_EBREAK];

  ifu u_ifu (
    .pc_i(pc_r),
    .pc_valid_i(pc_valid),
    .pc_ready_o(pc_ready),
    .if_bus_o(ifu_idu_bus),
    .if_valid_o(if_valid),
    .if_ready_i(if_ready)
  );

  idu u_idu (
    .if_bus_i(ifu_idu_bus),
    .if_valid_i(if_valid),
    .if_ready_o(if_ready),
    .id_bus_o(idu_exu_bus),
    .id_valid_o(id_valid),
    .id_ready_i(id_ready)
  );

  regfile u_regfile (
    .clk(clk),
    .we_i(wb_fire && rf_we),
    .waddr_i(rf_waddr),
    .wdata_i(rf_wdata),
    .raddr1_i(rs1_idx),
    .raddr2_i(rs2_idx),
    .rdata1_o(rs1_data),
    .rdata2_o(rs2_data),
    .a0_o(a0_data)
  );

  exu u_exu (
    .id_bus_i(idu_exu_bus),
    .id_valid_i(id_valid),
    .id_ready_o(id_ready),
    .rs1_data_i(rs1_data),
    .rs2_data_i(rs2_data),
    .ex_bus_o(exu_wbu_bus),
    .ex_valid_o(ex_valid),
    .ex_ready_i(ex_ready)
  );

  lsu u_lsu (
    .clk(clk),
    .ex_bus_i(exu_wbu_bus),
    .ex_valid_i(ex_valid),
    .ex_ready_o(ex_ready),
    .mem_bus_o(mem_wbu_bus),
    .load_data_o(load_data),
    .mem_valid_o(mem_valid),
    .mem_ready_i(mem_ready)
  );

  csrfile u_csrfile (
    .clk(clk),
    .rst(rst),
    .csr_we_i(wb_fire && (is_csrrw || (is_csrrs && (rs1_idx != 5'd0)))),
    .csr_set_i(is_csrrs),
    .csr_addr_i(csr_addr),
    .csr_wdata_i(mem_wbu_bus[`EXU_WBU_RS1_DATA]),
    .trap_we_i(wb_fire && is_ecall),
    .trap_epc_i(pc_r),
    .trap_cause_i(32'd11),
    .csr_rdata_o(csr_rdata),
    .mtvec_o(mtvec),
    .mepc_o(mepc)
  );

  wbu u_wbu (
    .mem_bus_i(mem_wbu_bus),
    .load_data_i(load_data),
    .mem_valid_i(mem_valid),
    .mem_ready_o(mem_ready),
    .csr_rdata_i(csr_rdata),
    .trap_target_i(mtvec),
    .mret_target_i(mepc),
    .rf_we_o(rf_we),
    .rf_waddr_o(rf_waddr),
    .rf_wdata_o(rf_wdata),
    .pc_next_o(pc_next)
  );

  always @(posedge clk) begin
    if (rst) begin
      pc_r <= 32'h8000_0000;
    end else begin
      if (wb_fire) begin
        trace_inst(pc_r, inst);
      end
      if (wb_fire && is_ebreak) begin
        npc_ebreak(pc_r, inst, a0_data);
      end
      if (wb_fire && pc_ready) begin
        pc_r <= pc_next;
      end
    end
  end

  assign debug_pc = pc_r;
  assign debug_inst = inst;

endmodule
