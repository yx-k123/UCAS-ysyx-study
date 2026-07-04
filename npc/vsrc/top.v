`include "npc_bus.vh"

module top (
  input         clk,
  input         rst,

  output        debug_commit,
  output [31:0] debug_pc,
  output [31:0] debug_inst,
  output [31:0] debug_mstatus,
  output [31:0] debug_mtvec,
  output [31:0] debug_mepc,
  output [31:0] debug_mcause
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
  wire [31:0] mstatus;
  wire [31:0] mtvec;
  wire [31:0] mepc;
  wire [31:0] mcause;

  wire rf_we;
  wire [4:0] rf_waddr;
  wire [31:0] rf_wdata;

  wire [31:0] ifu_axi_araddr;
  wire        ifu_axi_arvalid;
  wire        ifu_axi_arready;
  wire [31:0] ifu_axi_rdata;
  wire [1:0]  ifu_axi_rresp;
  wire        ifu_axi_rvalid;
  wire        ifu_axi_rready;

  wire [31:0] lsu_axi_awaddr;
  wire        lsu_axi_awvalid;
  wire        lsu_axi_awready;
  wire [31:0] lsu_axi_wdata;
  wire [3:0]  lsu_axi_wstrb;
  wire        lsu_axi_wvalid;
  wire        lsu_axi_wready;
  wire [1:0]  lsu_axi_bresp;
  wire        lsu_axi_bvalid;
  wire        lsu_axi_bready;
  wire [31:0] lsu_axi_araddr;
  wire        lsu_axi_arvalid;
  wire        lsu_axi_arready;
  wire [31:0] lsu_axi_rdata;
  wire [1:0]  lsu_axi_rresp;
  wire        lsu_axi_rvalid;
  wire        lsu_axi_rready;

  wire [31:0] mem_axi_awaddr;
  wire        mem_axi_awvalid;
  wire        mem_axi_awready;
  wire [31:0] mem_axi_wdata;
  wire [3:0]  mem_axi_wstrb;
  wire        mem_axi_wvalid;
  wire        mem_axi_wready;
  wire [1:0]  mem_axi_bresp;
  wire        mem_axi_bvalid;
  wire        mem_axi_bready;
  wire [31:0] mem_axi_araddr;
  wire        mem_axi_arvalid;
  wire        mem_axi_arready;
  wire [31:0] mem_axi_rdata;
  wire [1:0]  mem_axi_rresp;
  wire        mem_axi_rvalid;
  wire        mem_axi_rready;

  wire [31:0] sram_axi_awaddr;
  wire        sram_axi_awvalid;
  wire        sram_axi_awready;
  wire [31:0] sram_axi_wdata;
  wire [3:0]  sram_axi_wstrb;
  wire        sram_axi_wvalid;
  wire        sram_axi_wready;
  wire [1:0]  sram_axi_bresp;
  wire        sram_axi_bvalid;
  wire        sram_axi_bready;
  wire [31:0] sram_axi_araddr;
  wire        sram_axi_arvalid;
  wire        sram_axi_arready;
  wire [31:0] sram_axi_rdata;
  wire [1:0]  sram_axi_rresp;
  wire        sram_axi_rvalid;
  wire        sram_axi_rready;

  wire [31:0] uart_axi_awaddr;
  wire        uart_axi_awvalid;
  wire        uart_axi_awready;
  wire [31:0] uart_axi_wdata;
  wire [3:0]  uart_axi_wstrb;
  wire        uart_axi_wvalid;
  wire        uart_axi_wready;
  wire [1:0]  uart_axi_bresp;
  wire        uart_axi_bvalid;
  wire        uart_axi_bready;
  wire [31:0] uart_axi_araddr;
  wire        uart_axi_arvalid;
  wire        uart_axi_arready;
  wire [31:0] uart_axi_rdata;
  wire [1:0]  uart_axi_rresp;
  wire        uart_axi_rvalid;
  wire        uart_axi_rready;

  reg         debug_commit_r;

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
    .clk(clk),
    .rst(rst),
    .pc_i(pc_r),
    .pc_valid_i(pc_valid),
    .pc_ready_o(pc_ready),
    .if_bus_o(ifu_idu_bus),
    .if_valid_o(if_valid),
    .if_ready_i(if_ready),
    .axi_araddr_o(ifu_axi_araddr),
    .axi_arvalid_o(ifu_axi_arvalid),
    .axi_arready_i(ifu_axi_arready),
    .axi_rdata_i(ifu_axi_rdata),
    .axi_rvalid_i(ifu_axi_rvalid),
    .axi_rready_o(ifu_axi_rready)
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
    .rst(rst),
    .clk(clk),
    .ex_bus_i(exu_wbu_bus),
    .ex_valid_i(ex_valid),
    .ex_ready_o(ex_ready),
    .mem_bus_o(mem_wbu_bus),
    .load_data_o(load_data),
    .mem_valid_o(mem_valid),
    .mem_ready_i(mem_ready),
    .axi_awaddr_o(lsu_axi_awaddr),
    .axi_awvalid_o(lsu_axi_awvalid),
    .axi_awready_i(lsu_axi_awready),
    .axi_wdata_o(lsu_axi_wdata),
    .axi_wstrb_o(lsu_axi_wstrb),
    .axi_wvalid_o(lsu_axi_wvalid),
    .axi_wready_i(lsu_axi_wready),
    .axi_bresp_i(lsu_axi_bresp),
    .axi_bvalid_i(lsu_axi_bvalid),
    .axi_bready_o(lsu_axi_bready),
    .axi_araddr_o(lsu_axi_araddr),
    .axi_arvalid_o(lsu_axi_arvalid),
    .axi_arready_i(lsu_axi_arready),
    .axi_rdata_i(lsu_axi_rdata),
    .axi_rresp_i(lsu_axi_rresp),
    .axi_rvalid_i(lsu_axi_rvalid),
    .axi_rready_o(lsu_axi_rready)
  );

  axi4lite_arbiter u_axi4lite_arbiter (
    .clk(clk),
    .rst(rst),
    .ifu_araddr_i(ifu_axi_araddr),
    .ifu_arvalid_i(ifu_axi_arvalid),
    .ifu_arready_o(ifu_axi_arready),
    .ifu_rdata_o(ifu_axi_rdata),
    .ifu_rresp_o(ifu_axi_rresp),
    .ifu_rvalid_o(ifu_axi_rvalid),
    .ifu_rready_i(ifu_axi_rready),
    .ifu_awvalid_i(1'b0),
    .ifu_wvalid_i(1'b0),
    .ifu_bready_i(1'b0),
    .ifu_awready_o(),
    .ifu_wready_o(),
    .ifu_bvalid_o(),
    .ifu_bresp_o(),
    .lsu_awaddr_i(lsu_axi_awaddr),
    .lsu_awvalid_i(lsu_axi_awvalid),
    .lsu_awready_o(lsu_axi_awready),
    .lsu_wdata_i(lsu_axi_wdata),
    .lsu_wstrb_i(lsu_axi_wstrb),
    .lsu_wvalid_i(lsu_axi_wvalid),
    .lsu_wready_o(lsu_axi_wready),
    .lsu_bresp_o(lsu_axi_bresp),
    .lsu_bvalid_o(lsu_axi_bvalid),
    .lsu_bready_i(lsu_axi_bready),
    .lsu_araddr_i(lsu_axi_araddr),
    .lsu_arvalid_i(lsu_axi_arvalid),
    .lsu_arready_o(lsu_axi_arready),
    .lsu_rdata_o(lsu_axi_rdata),
    .lsu_rresp_o(lsu_axi_rresp),
    .lsu_rvalid_o(lsu_axi_rvalid),
    .lsu_rready_i(lsu_axi_rready),
    .mem_awaddr_o(mem_axi_awaddr),
    .mem_awvalid_o(mem_axi_awvalid),
    .mem_awready_i(mem_axi_awready),
    .mem_wdata_o(mem_axi_wdata),
    .mem_wstrb_o(mem_axi_wstrb),
    .mem_wvalid_o(mem_axi_wvalid),
    .mem_wready_i(mem_axi_wready),
    .mem_bresp_i(mem_axi_bresp),
    .mem_bvalid_i(mem_axi_bvalid),
    .mem_bready_o(mem_axi_bready),
    .mem_araddr_o(mem_axi_araddr),
    .mem_arvalid_o(mem_axi_arvalid),
    .mem_arready_i(mem_axi_arready),
    .mem_rdata_i(mem_axi_rdata),
    .mem_rresp_i(mem_axi_rresp),
    .mem_rvalid_i(mem_axi_rvalid),
    .mem_rready_o(mem_axi_rready)
  );

  axi4lite_xbar u_axi4lite_xbar (
    .clk(clk),
    .rst(rst),
    .axi_awaddr_i(mem_axi_awaddr),
    .axi_awvalid_i(mem_axi_awvalid),
    .axi_awready_o(mem_axi_awready),
    .axi_wdata_i(mem_axi_wdata),
    .axi_wstrb_i(mem_axi_wstrb),
    .axi_wvalid_i(mem_axi_wvalid),
    .axi_wready_o(mem_axi_wready),
    .axi_bresp_o(mem_axi_bresp),
    .axi_bvalid_o(mem_axi_bvalid),
    .axi_bready_i(mem_axi_bready),
    .axi_araddr_i(mem_axi_araddr),
    .axi_arvalid_i(mem_axi_arvalid),
    .axi_arready_o(mem_axi_arready),
    .axi_rdata_o(mem_axi_rdata),
    .axi_rresp_o(mem_axi_rresp),
    .axi_rvalid_o(mem_axi_rvalid),
    .axi_rready_i(mem_axi_rready),
    .sram_awaddr_o(sram_axi_awaddr),
    .sram_awvalid_o(sram_axi_awvalid),
    .sram_awready_i(sram_axi_awready),
    .sram_wdata_o(sram_axi_wdata),
    .sram_wstrb_o(sram_axi_wstrb),
    .sram_wvalid_o(sram_axi_wvalid),
    .sram_wready_i(sram_axi_wready),
    .sram_bresp_i(sram_axi_bresp),
    .sram_bvalid_i(sram_axi_bvalid),
    .sram_bready_o(sram_axi_bready),
    .sram_araddr_o(sram_axi_araddr),
    .sram_arvalid_o(sram_axi_arvalid),
    .sram_arready_i(sram_axi_arready),
    .sram_rdata_i(sram_axi_rdata),
    .sram_rresp_i(sram_axi_rresp),
    .sram_rvalid_i(sram_axi_rvalid),
    .sram_rready_o(sram_axi_rready),
    .uart_awaddr_o(uart_axi_awaddr),
    .uart_awvalid_o(uart_axi_awvalid),
    .uart_awready_i(uart_axi_awready),
    .uart_wdata_o(uart_axi_wdata),
    .uart_wstrb_o(uart_axi_wstrb),
    .uart_wvalid_o(uart_axi_wvalid),
    .uart_wready_i(uart_axi_wready),
    .uart_bresp_i(uart_axi_bresp),
    .uart_bvalid_i(uart_axi_bvalid),
    .uart_bready_o(uart_axi_bready),
    .uart_araddr_o(uart_axi_araddr),
    .uart_arvalid_o(uart_axi_arvalid),
    .uart_arready_i(uart_axi_arready),
    .uart_rdata_i(uart_axi_rdata),
    .uart_rresp_i(uart_axi_rresp),
    .uart_rvalid_i(uart_axi_rvalid),
    .uart_rready_o(uart_axi_rready)
  );

  axi4lite_mem u_axi4lite_mem (
    .clk(clk),
    .rst(rst),
    .axi_awaddr_i(sram_axi_awaddr),
    .axi_awvalid_i(sram_axi_awvalid),
    .axi_awready_o(sram_axi_awready),
    .axi_wdata_i(sram_axi_wdata),
    .axi_wstrb_i(sram_axi_wstrb),
    .axi_wvalid_i(sram_axi_wvalid),
    .axi_wready_o(sram_axi_wready),
    .axi_bresp_o(sram_axi_bresp),
    .axi_bvalid_o(sram_axi_bvalid),
    .axi_bready_i(sram_axi_bready),
    .axi_araddr_i(sram_axi_araddr),
    .axi_arvalid_i(sram_axi_arvalid),
    .axi_arready_o(sram_axi_arready),
    .axi_rdata_o(sram_axi_rdata),
    .axi_rresp_o(sram_axi_rresp),
    .axi_rvalid_o(sram_axi_rvalid),
    .axi_rready_i(sram_axi_rready)
  );

  axi4lite_uart u_axi4lite_uart (
    .clk(clk),
    .rst(rst),
    .axi_awaddr_i(uart_axi_awaddr),
    .axi_awvalid_i(uart_axi_awvalid),
    .axi_awready_o(uart_axi_awready),
    .axi_wdata_i(uart_axi_wdata),
    .axi_wstrb_i(uart_axi_wstrb),
    .axi_wvalid_i(uart_axi_wvalid),
    .axi_wready_o(uart_axi_wready),
    .axi_bresp_o(uart_axi_bresp),
    .axi_bvalid_o(uart_axi_bvalid),
    .axi_bready_i(uart_axi_bready),
    .axi_araddr_i(uart_axi_araddr),
    .axi_arvalid_i(uart_axi_arvalid),
    .axi_arready_o(uart_axi_arready),
    .axi_rdata_o(uart_axi_rdata),
    .axi_rresp_o(uart_axi_rresp),
    .axi_rvalid_o(uart_axi_rvalid),
    .axi_rready_i(uart_axi_rready)
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
    .mstatus_o(mstatus),
    .mtvec_o(mtvec),
    .mepc_o(mepc),
    .mcause_o(mcause)
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
      debug_commit_r <= 1'b0;
    end else begin
      debug_commit_r <= wb_fire;
      if (wb_fire) begin
        trace_inst(pc_r, inst);
      end
      if (wb_fire && is_ebreak) begin
        npc_ebreak(pc_r, inst, a0_data);
      end
      if (wb_fire) begin
        pc_r <= pc_next;
      end
    end
  end

  assign debug_commit = debug_commit_r;
  assign debug_pc = pc_r;
  assign debug_inst = inst;
  assign debug_mstatus = mstatus;
  assign debug_mtvec = mtvec;
  assign debug_mepc = mepc;
  assign debug_mcause = mcause;

endmodule
