`timescale 1ns / 1ps

module ysyx_26060188_icarus_tb;

  reg clock;
  reg reset;

  wire        io_master_awvalid;
  wire [31:0] io_master_awaddr;
  wire [3:0]  io_master_awid;
  wire [7:0]  io_master_awlen;
  wire [2:0]  io_master_awsize;
  wire [1:0]  io_master_awburst;
  wire        io_master_wvalid;
  wire [31:0] io_master_wdata;
  wire [3:0]  io_master_wstrb;
  wire        io_master_wlast;
  wire        io_master_bready;
  wire        io_master_arvalid;
  wire [31:0] io_master_araddr;
  wire [3:0]  io_master_arid;
  wire [7:0]  io_master_arlen;
  wire [2:0]  io_master_arsize;
  wire [1:0]  io_master_arburst;
  wire        io_master_rready;

  wire        io_master_awready;
  wire        io_master_wready;
  wire        io_master_bvalid;
  wire [1:0]  io_master_bresp;
  wire [3:0]  io_master_bid;
  wire        io_master_arready;
  wire        io_master_rvalid;
  wire [1:0]  io_master_rresp;
  wire [31:0] io_master_rdata;
  wire        io_master_rlast;
  wire [3:0]  io_master_rid;

`ifdef NETLIST_SIM
  wire        dut_debug_commit_r = dut.debug_commit_r;
  wire        dut_debug_ebreak_r = dut.debug_ebreak_r;
  wire [31:0] dut_pc_r = {
    dut.pc_r_31_, dut.pc_r_30_, dut.pc_r_29_, dut.pc_r_28_,
    dut.pc_r_27_, dut.pc_r_26_, dut.pc_r_25_, dut.pc_r_24_,
    dut.pc_r_23_, dut.pc_r_22_, dut.pc_r_21_, dut.pc_r_20_,
    dut.pc_r_19_, dut.pc_r_18_, dut.pc_r_17_, dut.pc_r_16_,
    dut.pc_r_15_, dut.pc_r_14_, dut.pc_r_13_, dut.pc_r_12_,
    dut.pc_r_11_, dut.pc_r_10_, dut.pc_r_9_,  dut.pc_r_8_,
    dut.pc_r_7_,  dut.pc_r_6_,  dut.pc_r_5_,  dut.pc_r_4_,
    dut.pc_r_3_,  dut.pc_r_2_,  dut.pc_r_1_,  dut.pc_r_0_
  };
  wire [31:0] dut_debug_pc_r = {
    dut.debug_pc_r_31_, dut.debug_pc_r_30_, dut.debug_pc_r_29_, dut.debug_pc_r_28_,
    dut.debug_pc_r_27_, dut.debug_pc_r_26_, dut.debug_pc_r_25_, dut.debug_pc_r_24_,
    dut.debug_pc_r_23_, dut.debug_pc_r_22_, dut.debug_pc_r_21_, dut.debug_pc_r_20_,
    dut.debug_pc_r_19_, dut.debug_pc_r_18_, dut.debug_pc_r_17_, dut.debug_pc_r_16_,
    dut.debug_pc_r_15_, dut.debug_pc_r_14_, dut.debug_pc_r_13_, dut.debug_pc_r_12_,
    dut.debug_pc_r_11_, dut.debug_pc_r_10_, dut.debug_pc_r_9_,  dut.debug_pc_r_8_,
    dut.debug_pc_r_7_,  dut.debug_pc_r_6_,  dut.debug_pc_r_5_,  dut.debug_pc_r_4_,
    dut.debug_pc_r_3_,  dut.debug_pc_r_2_,  dut.debug_pc_r_1_,  dut.debug_pc_r_0_
  };
  wire [31:0] dut_debug_inst_r = {
    dut.debug_inst_r_31_, dut.debug_inst_r_30_, dut.debug_inst_r_29_, dut.debug_inst_r_28_,
    dut.debug_inst_r_27_, dut.debug_inst_r_26_, dut.debug_inst_r_25_, dut.debug_inst_r_24_,
    dut.debug_inst_r_23_, dut.debug_inst_r_22_, dut.debug_inst_r_21_, dut.debug_inst_r_20_,
    dut.debug_inst_r_19_, dut.debug_inst_r_18_, dut.debug_inst_r_17_, dut.debug_inst_r_16_,
    dut.debug_inst_r_15_, dut.debug_inst_r_14_, dut.debug_inst_r_13_, dut.debug_inst_r_12_,
    dut.debug_inst_r_11_, dut.debug_inst_r_10_, dut.debug_inst_r_9_,  dut.debug_inst_r_8_,
    dut.debug_inst_r_7_,  dut.debug_inst_r_6_,  dut.debug_inst_r_5_,  dut.debug_inst_r_4_,
    dut.debug_inst_r_3_,  dut.debug_inst_r_2_,  dut.debug_inst_r_1_,  dut.debug_inst_r_0_
  };
  wire [31:0] dut_debug_a0_r = {
    dut.debug_a0_r_31_, dut.debug_a0_r_30_, dut.debug_a0_r_29_, dut.debug_a0_r_28_,
    dut.debug_a0_r_27_, dut.debug_a0_r_26_, dut.debug_a0_r_25_, dut.debug_a0_r_24_,
    dut.debug_a0_r_23_, dut.debug_a0_r_22_, dut.debug_a0_r_21_, dut.debug_a0_r_20_,
    dut.debug_a0_r_19_, dut.debug_a0_r_18_, dut.debug_a0_r_17_, dut.debug_a0_r_16_,
    dut.debug_a0_r_15_, dut.debug_a0_r_14_, dut.debug_a0_r_13_, dut.debug_a0_r_12_,
    dut.debug_a0_r_11_, dut.debug_a0_r_10_, dut.debug_a0_r_9_,  dut.debug_a0_r_8_,
    dut.debug_a0_r_7_,  dut.debug_a0_r_6_,  dut.debug_a0_r_5_,  dut.debug_a0_r_4_,
    dut.debug_a0_r_3_,  dut.debug_a0_r_2_,  dut.debug_a0_r_1_,  dut.debug_a0_r_0_
  };
  wire [31:0] dut_inst = dut_debug_inst_r;
`else
  wire        dut_debug_commit_r = dut.debug_commit_r;
  wire        dut_debug_ebreak_r = dut.debug_ebreak_r;
  wire [31:0] dut_pc_r = dut.pc_r;
  wire [31:0] dut_debug_pc_r = dut.debug_pc_r;
  wire [31:0] dut_debug_inst_r = dut.debug_inst_r;
  wire [31:0] dut_debug_a0_r = dut.debug_a0_r;
  wire [31:0] dut_inst = dut.inst;
`endif

  integer max_cycles;
  integer wave_enable;
  integer timeout_ok;
  integer cycle_count;
  reg [63:0] commit_count;

  ysyx_26060188 dut (
    .clock(clock),
    .reset(reset),
    .io_interrupt(1'b0),

    .io_master_awready(io_master_awready),
    .io_master_awvalid(io_master_awvalid),
    .io_master_awaddr(io_master_awaddr),
    .io_master_awid(io_master_awid),
    .io_master_awlen(io_master_awlen),
    .io_master_awsize(io_master_awsize),
    .io_master_awburst(io_master_awburst),
    .io_master_wready(io_master_wready),
    .io_master_wvalid(io_master_wvalid),
    .io_master_wdata(io_master_wdata),
    .io_master_wstrb(io_master_wstrb),
    .io_master_wlast(io_master_wlast),
    .io_master_bready(io_master_bready),
    .io_master_bvalid(io_master_bvalid),
    .io_master_bresp(io_master_bresp),
    .io_master_bid(io_master_bid),
    .io_master_arready(io_master_arready),
    .io_master_arvalid(io_master_arvalid),
    .io_master_araddr(io_master_araddr),
    .io_master_arid(io_master_arid),
    .io_master_arlen(io_master_arlen),
    .io_master_arsize(io_master_arsize),
    .io_master_arburst(io_master_arburst),
    .io_master_rready(io_master_rready),
    .io_master_rvalid(io_master_rvalid),
    .io_master_rresp(io_master_rresp),
    .io_master_rdata(io_master_rdata),
    .io_master_rlast(io_master_rlast),
    .io_master_rid(io_master_rid),

    .io_slave_awready(),
    .io_slave_awvalid(1'b0),
    .io_slave_awaddr(32'b0),
    .io_slave_awid(4'b0),
    .io_slave_awlen(8'b0),
    .io_slave_awsize(3'b0),
    .io_slave_awburst(2'b0),
    .io_slave_wready(),
    .io_slave_wvalid(1'b0),
    .io_slave_wdata(32'b0),
    .io_slave_wstrb(4'b0),
    .io_slave_wlast(1'b0),
    .io_slave_bready(1'b0),
    .io_slave_bvalid(),
    .io_slave_bresp(),
    .io_slave_bid(),
    .io_slave_arready(),
    .io_slave_arvalid(1'b0),
    .io_slave_araddr(32'b0),
    .io_slave_arid(4'b0),
    .io_slave_arlen(8'b0),
    .io_slave_arsize(3'b0),
    .io_slave_arburst(2'b0),
    .io_slave_rready(1'b0),
    .io_slave_rvalid(),
    .io_slave_rresp(),
    .io_slave_rdata(),
    .io_slave_rlast(),
    .io_slave_rid()
  );

  ysyx_26060188_icarus_mem mem (
    .clock(clock),
    .reset(reset),
    .awvalid(io_master_awvalid),
    .awready(io_master_awready),
    .awaddr(io_master_awaddr),
    .awid(io_master_awid),
    .awlen(io_master_awlen),
    .awsize(io_master_awsize),
    .awburst(io_master_awburst),
    .wvalid(io_master_wvalid),
    .wready(io_master_wready),
    .wdata(io_master_wdata),
    .wstrb(io_master_wstrb),
    .wlast(io_master_wlast),
    .bvalid(io_master_bvalid),
    .bready(io_master_bready),
    .bresp(io_master_bresp),
    .bid(io_master_bid),
    .arvalid(io_master_arvalid),
    .arready(io_master_arready),
    .araddr(io_master_araddr),
    .arid(io_master_arid),
    .arlen(io_master_arlen),
    .arsize(io_master_arsize),
    .arburst(io_master_arburst),
    .rvalid(io_master_rvalid),
    .rready(io_master_rready),
    .rdata(io_master_rdata),
    .rresp(io_master_rresp),
    .rlast(io_master_rlast),
    .rid(io_master_rid)
  );

  initial begin
    clock = 1'b0;
    reset = 1'b1;
    cycle_count = 0;
    commit_count = 64'b0;
    max_cycles = 5000000;
    wave_enable = 0;
    timeout_ok = 0;

    if ($value$plusargs("max-cycles=%d", max_cycles)) begin
      $display("icarus-tb: max-cycles=%0d", max_cycles);
    end
    if ($value$plusargs("timeout-ok=%d", timeout_ok)) begin
      $display("icarus-tb: timeout-ok=%0d", timeout_ok);
    end
    if ($value$plusargs("wave=%d", wave_enable) && (wave_enable != 0)) begin
      $dumpfile("npc-icarus.vcd");
      $dumpvars(0, ysyx_26060188_icarus_tb);
      $display("icarus-tb: wave dump enabled at npc-icarus.vcd");
    end

    repeat (16) @(negedge clock);
    reset = 1'b0;
  end

  always #5 clock = ~clock;

  always @(negedge clock) begin
    if (!reset) begin
      cycle_count = cycle_count + 1;

      if ($isunknown(dut_pc_r)) begin
        $display("");
        $display("x-propagation detected on dut_pc_r: 0x%08x", dut_pc_r);
        $fatal(1);
      end
      if (io_master_arvalid && $isunknown(io_master_araddr)) begin
        $display("");
        $display("x-propagation detected on io_master_araddr: 0x%08x", io_master_araddr);
        $fatal(1);
      end
      if (io_master_awvalid && $isunknown(io_master_awaddr)) begin
        $display("");
        $display("x-propagation detected on io_master_awaddr: 0x%08x", io_master_awaddr);
        $fatal(1);
      end
      if (io_master_wvalid && $isunknown(io_master_wdata)) begin
        $display("");
        $display("x-propagation detected on io_master_wdata: 0x%08x", io_master_wdata);
        $fatal(1);
      end
      if (io_master_wvalid && $isunknown({28'b0, io_master_wstrb})) begin
        $display("");
        $display("x-propagation detected on io_master_wstrb: 0x%01x", io_master_wstrb);
        $fatal(1);
      end
      if (io_master_rvalid && $isunknown(io_master_rdata)) begin
        $display("");
        $display("x-propagation detected on io_master_rdata: 0x%08x", io_master_rdata);
        $fatal(1);
      end
      if (io_master_rvalid && $isunknown({30'b0, io_master_rresp})) begin
        $display("");
        $display("x-propagation detected on io_master_rresp: 0x%01x", io_master_rresp);
        $fatal(1);
      end
      if (io_master_bvalid && $isunknown({30'b0, io_master_bresp})) begin
        $display("");
        $display("x-propagation detected on io_master_bresp: 0x%01x", io_master_bresp);
        $fatal(1);
      end

      if (dut_debug_commit_r) begin
        commit_count = commit_count + 1;
        if ($isunknown(dut_debug_pc_r)) begin
          $display("");
          $display("x-propagation detected on dut_debug_pc_r: 0x%08x", dut_debug_pc_r);
          $fatal(1);
        end
        if ($isunknown(dut_debug_inst_r)) begin
          $display("");
          $display("x-propagation detected on dut_debug_inst_r: 0x%08x", dut_debug_inst_r);
          $fatal(1);
        end
        if ($isunknown(dut_debug_a0_r)) begin
          $display("");
          $display("x-propagation detected on dut_debug_a0_r: 0x%08x", dut_debug_a0_r);
          $fatal(1);
        end
      end

      if (dut_debug_commit_r && dut_debug_ebreak_r) begin
        $display("");
        $display("ebreak at pc=0x%08x inst=0x%08x a0=%0d",
                 dut_debug_pc_r, dut_debug_inst_r, dut_debug_a0_r);
        if (dut_debug_a0_r == 0) begin
          $display("HIT GOOD TRAP");
          $finish;
        end else begin
          $display("HIT BAD TRAP with exit code %0d", dut_debug_a0_r);
          $fatal(1);
        end
      end

      if ((max_cycles > 0) && (cycle_count >= max_cycles)) begin
        $display("");
        $display("timeout: reached max cycles (%0d) without ebreak, pc=0x%08x inst=0x%08x commits=%0d",
                 max_cycles, dut_pc_r, dut_inst, commit_count);
        if (timeout_ok != 0) begin
          $display("simulation stopped by timeout without ebreak");
          $finish;
        end else begin
          $fatal(1);
        end
      end
    end
  end

endmodule
