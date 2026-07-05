`include "npc_bus.vh"

module ysyx_09922004 (
  input         clock,
  input         reset,
  input         io_interrupt,

  input         io_master_awready,
  output        io_master_awvalid,
  output [31:0] io_master_awaddr,
  output [3:0]  io_master_awid,
  output [7:0]  io_master_awlen,
  output [2:0]  io_master_awsize,
  output [1:0]  io_master_awburst,
  input         io_master_wready,
  output        io_master_wvalid,
  output [31:0] io_master_wdata,
  output [3:0]  io_master_wstrb,
  output        io_master_wlast,
  output        io_master_bready,
  input         io_master_bvalid,
  input  [1:0]  io_master_bresp,
  input  [3:0]  io_master_bid,
  input         io_master_arready,
  output        io_master_arvalid,
  output [31:0] io_master_araddr,
  output [3:0]  io_master_arid,
  output [7:0]  io_master_arlen,
  output [2:0]  io_master_arsize,
  output [1:0]  io_master_arburst,
  output        io_master_rready,
  input         io_master_rvalid,
  input  [1:0]  io_master_rresp,
  input  [31:0] io_master_rdata,
  input         io_master_rlast,
  input  [3:0]  io_master_rid,

  output        io_slave_awready,
  input         io_slave_awvalid,
  input  [31:0] io_slave_awaddr,
  input  [3:0]  io_slave_awid,
  input  [7:0]  io_slave_awlen,
  input  [2:0]  io_slave_awsize,
  input  [1:0]  io_slave_awburst,
  output        io_slave_wready,
  input         io_slave_wvalid,
  input  [31:0] io_slave_wdata,
  input  [3:0]  io_slave_wstrb,
  input         io_slave_wlast,
  input         io_slave_bready,
  output        io_slave_bvalid,
  output [1:0]  io_slave_bresp,
  output [3:0]  io_slave_bid,
  output        io_slave_arready,
  input         io_slave_arvalid,
  input  [31:0] io_slave_araddr,
  input  [3:0]  io_slave_arid,
  input  [7:0]  io_slave_arlen,
  input  [2:0]  io_slave_arsize,
  input  [1:0]  io_slave_arburst,
  input         io_slave_rready,
  output        io_slave_rvalid,
  output [1:0]  io_slave_rresp,
  output [31:0] io_slave_rdata,
  output        io_slave_rlast,
  output [3:0]  io_slave_rid
);

  import "DPI-C" function void npc_ebreak(input int unsigned pc, input int unsigned inst, input int unsigned a0);
  import "DPI-C" function void trace_inst(input int pc, input int inst);

  wire _unused_ok = &{1'b0,
                      io_interrupt,
                      io_slave_awvalid,
                      io_slave_awaddr,
                      io_slave_awid,
                      io_slave_awlen,
                      io_slave_awsize,
                      io_slave_awburst,
                      io_slave_wvalid,
                      io_slave_wdata,
                      io_slave_wstrb,
                      io_slave_wlast,
                      io_slave_bready,
                      io_slave_arvalid,
                      io_slave_araddr,
                      io_slave_arid,
                      io_slave_arlen,
                      io_slave_arsize,
                      io_slave_arburst,
                      io_slave_rready,
                      io_master_bid,
                      io_master_rid,
                      io_master_rlast};

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

  wire [31:0] clint_axi_awaddr;
  wire        clint_axi_awvalid;
  wire        clint_axi_awready;
  wire [31:0] clint_axi_wdata;
  wire [3:0]  clint_axi_wstrb;
  wire        clint_axi_wvalid;
  wire        clint_axi_wready;
  wire [1:0]  clint_axi_bresp;
  wire        clint_axi_bvalid;
  wire        clint_axi_bready;
  wire [31:0] clint_axi_araddr;
  wire        clint_axi_arvalid;
  wire        clint_axi_arready;
  wire [31:0] clint_axi_rdata;
  wire [1:0]  clint_axi_rresp;
  wire        clint_axi_rvalid;
  wire        clint_axi_rready;

  reg         debug_commit_r;

  assign pc_valid = ~reset;
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
    .clk(clock),
    .rst(reset),
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
    .clk(clock),
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
    .rst(reset),
    .clk(clock),
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
    .clk(clock),
    .rst(reset),
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

  axi4lite_clint_xbar u_axi4lite_clint_xbar (
    .clk(clock),
    .rst(reset),
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
    .ext_awaddr_o(io_master_awaddr),
    .ext_awvalid_o(io_master_awvalid),
    .ext_awready_i(io_master_awready),
    .ext_wdata_o(io_master_wdata),
    .ext_wstrb_o(io_master_wstrb),
    .ext_wvalid_o(io_master_wvalid),
    .ext_wready_i(io_master_wready),
    .ext_bresp_i(io_master_bresp),
    .ext_bvalid_i(io_master_bvalid),
    .ext_bready_o(io_master_bready),
    .ext_araddr_o(io_master_araddr),
    .ext_arvalid_o(io_master_arvalid),
    .ext_arready_i(io_master_arready),
    .ext_rdata_i(io_master_rdata),
    .ext_rresp_i(io_master_rresp),
    .ext_rvalid_i(io_master_rvalid),
    .ext_rready_o(io_master_rready),
    .clint_awaddr_o(clint_axi_awaddr),
    .clint_awvalid_o(clint_axi_awvalid),
    .clint_awready_i(clint_axi_awready),
    .clint_wdata_o(clint_axi_wdata),
    .clint_wstrb_o(clint_axi_wstrb),
    .clint_wvalid_o(clint_axi_wvalid),
    .clint_wready_i(clint_axi_wready),
    .clint_bresp_i(clint_axi_bresp),
    .clint_bvalid_i(clint_axi_bvalid),
    .clint_bready_o(clint_axi_bready),
    .clint_araddr_o(clint_axi_araddr),
    .clint_arvalid_o(clint_axi_arvalid),
    .clint_arready_i(clint_axi_arready),
    .clint_rdata_i(clint_axi_rdata),
    .clint_rresp_i(clint_axi_rresp),
    .clint_rvalid_i(clint_axi_rvalid),
    .clint_rready_o(clint_axi_rready)
  );

  axi4lite_clint u_axi4lite_clint (
    .clk(clock),
    .rst(reset),
    .axi_awaddr_i(clint_axi_awaddr),
    .axi_awvalid_i(clint_axi_awvalid),
    .axi_awready_o(clint_axi_awready),
    .axi_wdata_i(clint_axi_wdata),
    .axi_wstrb_i(clint_axi_wstrb),
    .axi_wvalid_i(clint_axi_wvalid),
    .axi_wready_o(clint_axi_wready),
    .axi_bresp_o(clint_axi_bresp),
    .axi_bvalid_o(clint_axi_bvalid),
    .axi_bready_i(clint_axi_bready),
    .axi_araddr_i(clint_axi_araddr),
    .axi_arvalid_i(clint_axi_arvalid),
    .axi_arready_o(clint_axi_arready),
    .axi_rdata_o(clint_axi_rdata),
    .axi_rresp_o(clint_axi_rresp),
    .axi_rvalid_o(clint_axi_rvalid),
    .axi_rready_i(clint_axi_rready)
  );

  csrfile u_csrfile (
    .clk(clock),
    .rst(reset),
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

  always @(posedge clock) begin
    if (reset) begin
      pc_r <= 32'h2000_0000;
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

  assign io_master_awid = 4'd1;
  assign io_master_awlen = 8'd0;
  assign io_master_awsize = 3'b010;
  assign io_master_awburst = 2'b01;
  assign io_master_wlast = 1'b1;
  assign io_master_arid = 4'd0;
  assign io_master_arlen = 8'd0;
  assign io_master_arsize = 3'b010;
  assign io_master_arburst = 2'b01;

  assign io_slave_awready = 1'b0;
  assign io_slave_wready = 1'b0;
  assign io_slave_bvalid = 1'b0;
  assign io_slave_bresp = 2'b00;
  assign io_slave_bid = 4'b0000;
  assign io_slave_arready = 1'b0;
  assign io_slave_rvalid = 1'b0;
  assign io_slave_rresp = 2'b00;
  assign io_slave_rdata = 32'b0;
  assign io_slave_rlast = 1'b0;
  assign io_slave_rid = 4'b0000;

endmodule
