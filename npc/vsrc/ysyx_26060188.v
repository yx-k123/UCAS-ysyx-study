`define ysyx_26060188_IFU_IDU_BUS_W 64
`define ysyx_26060188_IFU_IDU_PC    63:32
`define ysyx_26060188_IFU_IDU_INST  31:0
`define ysyx_26060188_IDU_EXU_PC            31:0
`define ysyx_26060188_IDU_EXU_IMM           63:32
`define ysyx_26060188_IDU_EXU_RS1_IDX       68:64
`define ysyx_26060188_IDU_EXU_RS2_IDX       73:69
`define ysyx_26060188_IDU_EXU_RD_IDX        78:74
`define ysyx_26060188_IDU_EXU_CSR_ADDR      90:79
`define ysyx_26060188_IDU_EXU_ALU_OP        94:91
`define ysyx_26060188_IDU_EXU_LSU_FUNCT3    97:95

`define ysyx_26060188_IDU_EXU_BR_TYPE      100:98
`define ysyx_26060188_IDU_EXU_OP1_IS_PC       101
`define ysyx_26060188_IDU_EXU_OP2_IS_RS2      102
`define ysyx_26060188_IDU_EXU_IS_CSRRW        103
`define ysyx_26060188_IDU_EXU_IS_CSRRS        104
`define ysyx_26060188_IDU_EXU_IS_ECALL        105
`define ysyx_26060188_IDU_EXU_IS_MRET         106
`define ysyx_26060188_IDU_EXU_IS_LOAD         107
`define ysyx_26060188_IDU_EXU_IS_STORE        108
`define ysyx_26060188_IDU_EXU_IS_BRANCH       109
`define ysyx_26060188_IDU_EXU_IS_JAL          110
`define ysyx_26060188_IDU_EXU_IS_JALR         111
`define ysyx_26060188_IDU_EXU_IS_EBREAK       112
`define ysyx_26060188_IDU_EXU_WB_EN           113
`define ysyx_26060188_IDU_EXU_WB_FROM_LOAD    114
`define ysyx_26060188_IDU_EXU_WB_FROM_PC4     115
`define ysyx_26060188_IDU_EXU_WB_FROM_CSR     116
`define ysyx_26060188_IDU_EXU_BUS_W           117
`define ysyx_26060188_EXU_WBU_PC            31:0
`define ysyx_26060188_EXU_WBU_RD_IDX        36:32
`define ysyx_26060188_EXU_WBU_CSR_ADDR      48:37
`define ysyx_26060188_EXU_WBU_LSU_FUNCT3    51:49
`define ysyx_26060188_EXU_WBU_RS1_DATA      83:52
`define ysyx_26060188_EXU_WBU_RS2_DATA     115:84
`define ysyx_26060188_EXU_WBU_ALU_RES      147:116
`define ysyx_26060188_EXU_WBU_JALR_TARGET  179:148
`define ysyx_26060188_EXU_WBU_BR_TARGET    211:180
`define ysyx_26060188_EXU_WBU_BR_TAKEN        212
`define ysyx_26060188_EXU_WBU_IS_CSRRW        213
`define ysyx_26060188_EXU_WBU_IS_CSRRS        214
`define ysyx_26060188_EXU_WBU_IS_ECALL        215
`define ysyx_26060188_EXU_WBU_IS_MRET         216
`define ysyx_26060188_EXU_WBU_IS_LOAD         217
`define ysyx_26060188_EXU_WBU_IS_STORE        218
`define ysyx_26060188_EXU_WBU_IS_BRANCH       219
`define ysyx_26060188_EXU_WBU_IS_JAL          220
`define ysyx_26060188_EXU_WBU_IS_JALR         221
`define ysyx_26060188_EXU_WBU_IS_EBREAK       222
`define ysyx_26060188_EXU_WBU_WB_EN           223
`define ysyx_26060188_EXU_WBU_WB_FROM_LOAD    224
`define ysyx_26060188_EXU_WBU_WB_FROM_PC4     225
`define ysyx_26060188_EXU_WBU_WB_FROM_CSR     226
`define ysyx_26060188_EXU_WBU_BUS_W           227

module ysyx_26060188_alu (
  input  [31:0] op1_i,
  input  [31:0] op2_i,
  input  [3:0]  alu_op_i,
  output [31:0] res_o
);

  localparam ALU_ADD   = 4'd0;
  localparam ALU_SUB   = 4'd1;
  localparam ALU_AND   = 4'd2;
  localparam ALU_OR    = 4'd3;
  localparam ALU_XOR   = 4'd4;
  localparam ALU_SLL   = 4'd5;
  localparam ALU_SRL   = 4'd6;
  localparam ALU_SRA   = 4'd7;
  localparam ALU_SLT   = 4'd8;
  localparam ALU_SLTU  = 4'd9;
  localparam ALU_COPY2 = 4'd10;

  wire [31:0] add_res = op1_i + op2_i;
  wire [31:0] sub_res = op1_i - op2_i;
  wire [4:0] shamt = op2_i[4:0];
  wire [5:0] shamt6 = {1'b0, shamt};
  wire [31:0] sra_fill_mask = (shamt6 == 0) ? 32'b0 : (32'hffff_ffff << (6'd32 - shamt6));
  wire [31:0] sra_res = (op1_i >> shamt) | (op1_i[31] ? sra_fill_mask : 32'b0);
  wire signed_lt = ($signed(op1_i) < $signed(op2_i));
  wire unsigned_lt = (op1_i < op2_i);

  assign res_o =
    (alu_op_i == ALU_ADD  ) ? add_res :
    (alu_op_i == ALU_SUB  ) ? sub_res :
    (alu_op_i == ALU_AND  ) ? (op1_i & op2_i) :
    (alu_op_i == ALU_OR   ) ? (op1_i | op2_i) :
    (alu_op_i == ALU_XOR  ) ? (op1_i ^ op2_i) :
    (alu_op_i == ALU_SLL  ) ? (op1_i << shamt) :
    (alu_op_i == ALU_SRL  ) ? (op1_i >> shamt) :
    (alu_op_i == ALU_SRA  ) ? sra_res :
    (alu_op_i == ALU_SLT  ) ? {31'b0, signed_lt} :
    (alu_op_i == ALU_SLTU ) ? {31'b0, unsigned_lt} :
    (alu_op_i == ALU_COPY2) ? op2_i :
    add_res;

endmodule


module ysyx_26060188_axi4lite_arbiter (
  input         clk,
  input         rst,

  input  [31:0] ifu_araddr_i,
  input         ifu_arvalid_i,
  output        ifu_arready_o,
  output [31:0] ifu_rdata_o,
  output [1:0]  ifu_rresp_o,
  output        ifu_rvalid_o,
  input         ifu_rready_i,
  input         ifu_awvalid_i,
  input         ifu_wvalid_i,
  input         ifu_bready_i,
  output        ifu_awready_o,
  output        ifu_wready_o,
  output        ifu_bvalid_o,
  output [1:0]  ifu_bresp_o,

  input  [31:0] lsu_awaddr_i,
  input  [2:0]  lsu_awsize_i,
  input         lsu_awvalid_i,
  output        lsu_awready_o,
  input  [31:0] lsu_wdata_i,
  input  [3:0]  lsu_wstrb_i,
  input         lsu_wvalid_i,
  output        lsu_wready_o,
  output [1:0]  lsu_bresp_o,
  output        lsu_bvalid_o,
  input         lsu_bready_i,
  input  [31:0] lsu_araddr_i,
  input  [2:0]  lsu_arsize_i,
  input         lsu_arvalid_i,
  output        lsu_arready_o,
  output [31:0] lsu_rdata_o,
  output [1:0]  lsu_rresp_o,
  output        lsu_rvalid_o,
  input         lsu_rready_i,

  output [31:0] mem_awaddr_o,
  output [2:0]  mem_awsize_o,
  output        mem_awvalid_o,
  input         mem_awready_i,
  output [31:0] mem_wdata_o,
  output [3:0]  mem_wstrb_o,
  output        mem_wvalid_o,
  input         mem_wready_i,
  input  [1:0]  mem_bresp_i,
  input         mem_bvalid_i,
  output        mem_bready_o,
  output [31:0] mem_araddr_o,
  output [2:0]  mem_arsize_o,
  output        mem_arvalid_o,
  input         mem_arready_i,
  input  [31:0] mem_rdata_i,
  input  [1:0]  mem_rresp_i,
  input         mem_rvalid_i,
  output        mem_rready_o
);

  localparam [2:0] ST_IDLE        = 3'd0;
  localparam [2:0] ST_IFU_RD_ADDR = 3'd1;
  localparam [2:0] ST_IFU_RD_RESP = 3'd2;
  localparam [2:0] ST_LSU_RD_ADDR = 3'd3;
  localparam [2:0] ST_LSU_RD_RESP = 3'd4;
  localparam [2:0] ST_LSU_WR_REQ  = 3'd5;
  localparam [2:0] ST_LSU_WR_RESP = 3'd6;

  reg [2:0] state_r;
  reg       aw_done_r;
  reg       w_done_r;

  wire ifu_ar_fire = ifu_arvalid_i && ifu_arready_o;
  wire ifu_r_fire = ifu_rvalid_o && ifu_rready_i;
  wire lsu_ar_fire = lsu_arvalid_i && lsu_arready_o;
  wire lsu_r_fire = lsu_rvalid_o && lsu_rready_i;
  wire lsu_aw_fire = lsu_awvalid_i && lsu_awready_o;
  wire lsu_w_fire = lsu_wvalid_i && lsu_wready_o;
  wire lsu_b_fire = lsu_bvalid_o && lsu_bready_i;
  wire _unused_ok = &{1'b0, ifu_awvalid_i, ifu_wvalid_i, ifu_bready_i};

  always @(posedge clk) begin
    if (rst) begin
      state_r <= ST_IDLE;
      aw_done_r <= 1'b0;
      w_done_r <= 1'b0;
    end else begin
      case (state_r)
        ST_IDLE: begin
          aw_done_r <= 1'b0;
          w_done_r <= 1'b0;
          if (lsu_awvalid_i || lsu_wvalid_i) begin
            state_r <= ST_LSU_WR_REQ;
          end else if (lsu_arvalid_i) begin
            state_r <= ST_LSU_RD_ADDR;
          end else if (ifu_arvalid_i) begin
            state_r <= ST_IFU_RD_ADDR;
          end
        end

        ST_IFU_RD_ADDR: begin
          if (ifu_ar_fire) begin
            state_r <= ST_IFU_RD_RESP;
          end
        end

        ST_IFU_RD_RESP: begin
          if (ifu_r_fire) begin
            state_r <= ST_IDLE;
          end
        end

        ST_LSU_RD_ADDR: begin
          if (lsu_ar_fire) begin
            state_r <= ST_LSU_RD_RESP;
          end
        end

        ST_LSU_RD_RESP: begin
          if (lsu_r_fire) begin
            state_r <= ST_IDLE;
          end
        end

        ST_LSU_WR_REQ: begin
          if (lsu_aw_fire) begin
            aw_done_r <= 1'b1;
          end
          if (lsu_w_fire) begin
            w_done_r <= 1'b1;
          end
          if ((aw_done_r || lsu_aw_fire) && (w_done_r || lsu_w_fire)) begin
            state_r <= ST_LSU_WR_RESP;
          end
        end

        ST_LSU_WR_RESP: begin
          if (lsu_b_fire) begin
            state_r <= ST_IDLE;
          end
        end

        default: begin
          state_r <= ST_IDLE;
          aw_done_r <= 1'b0;
          w_done_r <= 1'b0;
        end
      endcase
    end
  end

  assign ifu_arready_o = (state_r == ST_IFU_RD_ADDR) ? mem_arready_i : 1'b0;
  assign ifu_rdata_o = mem_rdata_i;
  assign ifu_rresp_o = mem_rresp_i;
  assign ifu_rvalid_o = (state_r == ST_IFU_RD_RESP) ? mem_rvalid_i : 1'b0;
  assign ifu_awready_o = 1'b0;
  assign ifu_wready_o = 1'b0;
  assign ifu_bvalid_o = 1'b0;
  assign ifu_bresp_o = 2'b00;

  assign lsu_awready_o = (state_r == ST_LSU_WR_REQ && !aw_done_r) ? mem_awready_i : 1'b0;
  assign lsu_wready_o = (state_r == ST_LSU_WR_REQ && !w_done_r) ? mem_wready_i : 1'b0;
  assign lsu_bresp_o = mem_bresp_i;
  assign lsu_bvalid_o = (state_r == ST_LSU_WR_RESP) ? mem_bvalid_i : 1'b0;
  assign lsu_arready_o = (state_r == ST_LSU_RD_ADDR) ? mem_arready_i : 1'b0;
  assign lsu_rdata_o = mem_rdata_i;
  assign lsu_rresp_o = mem_rresp_i;
  assign lsu_rvalid_o = (state_r == ST_LSU_RD_RESP) ? mem_rvalid_i : 1'b0;

  assign mem_awaddr_o = lsu_awaddr_i;
  assign mem_awsize_o = lsu_awsize_i;
  assign mem_awvalid_o = (state_r == ST_LSU_WR_REQ) && !aw_done_r && lsu_awvalid_i;
  assign mem_wdata_o = lsu_wdata_i;
  assign mem_wstrb_o = lsu_wstrb_i;
  assign mem_wvalid_o = (state_r == ST_LSU_WR_REQ) && !w_done_r && lsu_wvalid_i;
  assign mem_bready_o = (state_r == ST_LSU_WR_RESP) ? lsu_bready_i : 1'b0;
  assign mem_araddr_o = (state_r == ST_LSU_RD_ADDR) ? lsu_araddr_i : ifu_araddr_i;
  assign mem_arsize_o = (state_r == ST_LSU_RD_ADDR) ? lsu_arsize_i : 3'b010;
  assign mem_arvalid_o = ((state_r == ST_LSU_RD_ADDR) && lsu_arvalid_i) ||
                         ((state_r == ST_IFU_RD_ADDR) && ifu_arvalid_i);
  assign mem_rready_o = (state_r == ST_LSU_RD_RESP) ? lsu_rready_i :
                        (state_r == ST_IFU_RD_RESP) ? ifu_rready_i : 1'b0;

endmodule


module ysyx_26060188_axi4lite_clint (
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

  localparam [31:0] MTIME_LO_ADDR = 32'h1000_0010;
  localparam [31:0] MTIME_HI_ADDR = 32'h1000_0014;

  localparam [1:0] AXI_RESP_OKAY   = 2'b00;
  localparam [1:0] AXI_RESP_SLVERR = 2'b10;

  reg [1:0]  state_r;
  reg [31:0] read_addr_r;
  reg [63:0] mtime_r;
  reg [63:0] mtime_snapshot_r;
  reg [1:0]  rresp_r;
  reg [1:0]  bresp_r;
  reg        aw_seen_r;
  reg        w_seen_r;

  wire ar_fire = axi_arvalid_i && axi_arready_o;
  wire r_fire = axi_rvalid_o && axi_rready_i;
  wire aw_fire = axi_awvalid_i && axi_awready_o;
  wire w_fire = axi_wvalid_i && axi_wready_o;
  wire b_fire = axi_bvalid_o && axi_bready_i;
  wire _unused_ok = &{1'b0, axi_awaddr_i, axi_wdata_i, axi_wstrb_i};

  wire [31:0] aligned_araddr = axi_araddr_i & 32'hffff_fffc;
  wire ar_is_lo = (aligned_araddr == MTIME_LO_ADDR);
  wire ar_is_hi = (aligned_araddr == MTIME_HI_ADDR);

  always @(posedge clk) begin
    if (rst) begin
      state_r <= ST_IDLE;
      read_addr_r <= 32'b0;
      mtime_r <= 64'b0;
      mtime_snapshot_r <= 64'b0;
      rresp_r <= AXI_RESP_OKAY;
      bresp_r <= AXI_RESP_OKAY;
      aw_seen_r <= 1'b0;
      w_seen_r <= 1'b0;
    end else begin
      mtime_r <= mtime_r + 64'd1;
      case (state_r)
        ST_IDLE: begin
          if (ar_fire) begin
            read_addr_r <= aligned_araddr;
            mtime_snapshot_r <= mtime_r;
            if (ar_is_lo) begin
              rresp_r <= AXI_RESP_OKAY;
            end else if (ar_is_hi) begin
              rresp_r <= AXI_RESP_OKAY;
            end else begin
              rresp_r <= AXI_RESP_SLVERR;
            end
            state_r <= ST_RD_RESP;
          end else begin
            if (aw_fire) begin
              aw_seen_r <= 1'b1;
              bresp_r <= AXI_RESP_SLVERR;
            end

            if (w_fire) begin
              w_seen_r <= 1'b1;
            end

            if ((aw_seen_r || aw_fire) && (w_seen_r || w_fire)) begin
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
  assign axi_bresp_o = bresp_r;
  assign axi_bvalid_o = (state_r == ST_WR_RESP);
  assign axi_arready_o = !rst && (state_r == ST_IDLE) && !aw_seen_r && !w_seen_r;
  assign axi_rdata_o = (read_addr_r == MTIME_LO_ADDR) ? mtime_snapshot_r[31:0] :
                       (read_addr_r == MTIME_HI_ADDR) ? mtime_snapshot_r[63:32] :
                       32'b0;
  assign axi_rresp_o = rresp_r;
  assign axi_rvalid_o = (state_r == ST_RD_RESP);

endmodule


module ysyx_26060188_axi4lite_clint_xbar (
  input         clk,
  input         rst,

  input  [31:0] axi_awaddr_i,
  input  [2:0]  axi_awsize_i,
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
  input  [2:0]  axi_arsize_i,
  input         axi_arvalid_i,
  output        axi_arready_o,
  output [31:0] axi_rdata_o,
  output [1:0]  axi_rresp_o,
  output        axi_rvalid_o,
  input         axi_rready_i,

  output [31:0] ext_awaddr_o,
  output [2:0]  ext_awsize_o,
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
  output [2:0]  ext_arsize_o,
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

  reg [2:0]  state_r;
  reg        target_r;
  reg [31:0] read_addr_r;
  reg [2:0]  read_size_r;
  reg [31:0] write_addr_r;
  reg [2:0]  write_size_r;
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
  wire [2:0]  write_size_next = aw_fire ? axi_awsize_i : write_size_r;

  function is_clint_addr;
    input [31:0] addr;
    begin
      is_clint_addr = ((addr & 32'hffff_fffc) == 32'h1000_0010) ||
                      ((addr & 32'hffff_fffc) == 32'h1000_0014);
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
      target_r <= TARGET_EXT;
      read_addr_r <= 32'b0;
      read_size_r <= 3'b010;
      write_addr_r <= 32'b0;
      write_size_r <= 3'b010;
      write_data_r <= 32'b0;
      write_strb_r <= 4'b0;
      aw_seen_r <= 1'b0;
      w_seen_r <= 1'b0;
      wr_aw_sent_r <= 1'b0;
      wr_w_sent_r <= 1'b0;
    end else begin
      case (state_r)
        ST_IDLE: begin
          wr_aw_sent_r <= 1'b0;
          wr_w_sent_r <= 1'b0;
          if (ar_fire) begin
            state_r <= ST_RD_REQ;
            read_addr_r <= axi_araddr_i;
            read_size_r <= axi_arsize_i;
            target_r <= decode_target(axi_araddr_i);
          end else begin
            if (aw_fire) begin
              write_addr_r <= axi_awaddr_i;
              write_size_r <= axi_awsize_i;
              aw_seen_r <= 1'b1;
            end

            if (w_fire) begin
              write_data_r <= axi_wdata_i;
              write_strb_r <= axi_wstrb_i;
              w_seen_r <= 1'b1;
            end

            if ((aw_seen_r || aw_fire) && (w_seen_r || w_fire)) begin
              state_r <= ST_WR_REQ;
              target_r <= decode_target(write_addr_next);
              write_addr_r <= write_addr_next;
              write_size_r <= write_size_next;
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
  assign ext_awsize_o = write_size_r;
  assign ext_awvalid_o = (state_r == ST_WR_REQ) && (target_r == TARGET_EXT) && !wr_aw_sent_r;
  assign ext_wdata_o = write_data_r;
  assign ext_wstrb_o = write_strb_r;
  assign ext_wvalid_o = (state_r == ST_WR_REQ) && (target_r == TARGET_EXT) && !wr_w_sent_r;
  assign ext_bready_o = (state_r == ST_WR_RESP) && (target_r == TARGET_EXT) ? axi_bready_i : 1'b0;
  assign ext_araddr_o = read_addr_r;
  assign ext_arsize_o = read_size_r;
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


module ysyx_26060188_csrfile (
  input         clk,
  input         rst,
  input         csr_we_i,
  input         csr_set_i,
  input  [11:0] csr_addr_i,
  input  [31:0] csr_wdata_i,
  input         trap_we_i,
  input  [31:0] trap_epc_i,
  input  [31:0] trap_cause_i,
  output [31:0] csr_rdata_o,
  output [31:0] mstatus_o,
  output [31:0] mtvec_o,
  output [31:0] mepc_o,
  output [31:0] mcause_o
);

  localparam [11:0] CSR_MSTATUS   = 12'h300;
  localparam [11:0] CSR_MTVEC     = 12'h305;
  localparam [11:0] CSR_MEPC      = 12'h341;
  localparam [11:0] CSR_MCAUSE    = 12'h342;
  localparam [11:0] CSR_MCYCLE    = 12'hb00;
  localparam [11:0] CSR_MCYCLEH   = 12'hb80;
  localparam [11:0] CSR_MVENDORID = 12'hf11;
  localparam [11:0] CSR_MARCHID   = 12'hf12;

  localparam [31:0] MVENDORID_VALUE = 32'h7973_7978;
  localparam [31:0] MARCHID_VALUE   = 32'd26060188;

  reg [31:0] mstatus_r;
  reg [31:0] mtvec_r;
  reg [31:0] mepc_r;
  reg [31:0] mcause_r;
  reg [63:0] mcycle_r;

  reg [31:0] mstatus_next;
  reg [31:0] mtvec_next;
  reg [31:0] mepc_next;
  reg [31:0] mcause_next;
  reg [63:0] mcycle_next;

  always @(*) begin
    mstatus_next = mstatus_r;
    mtvec_next = mtvec_r;
    mepc_next = mepc_r;
    mcause_next = mcause_r;
    mcycle_next = mcycle_r;

    if (csr_we_i) begin
      case (csr_addr_i)
        CSR_MSTATUS: mstatus_next = csr_set_i ? (mstatus_r | csr_wdata_i) : csr_wdata_i;
        CSR_MTVEC:   mtvec_next   = csr_set_i ? (mtvec_r   | csr_wdata_i) : csr_wdata_i;
        CSR_MEPC:    mepc_next    = csr_set_i ? (mepc_r    | csr_wdata_i) : csr_wdata_i;
        CSR_MCAUSE:  mcause_next  = csr_set_i ? (mcause_r  | csr_wdata_i) : csr_wdata_i;
        CSR_MCYCLE:  mcycle_next[31:0]  = csr_set_i ? (mcycle_r[31:0]  | csr_wdata_i) : csr_wdata_i;
        CSR_MCYCLEH: mcycle_next[63:32] = csr_set_i ? (mcycle_r[63:32] | csr_wdata_i) : csr_wdata_i;
        default: ;
      endcase
    end

    if (trap_we_i) begin
      mepc_next = trap_epc_i;
      mcause_next = trap_cause_i;
    end

    mcycle_next = mcycle_next + 64'd1;
  end

  always @(posedge clk) begin
    if (rst) begin
      mstatus_r <= 32'h0000_1800;
      mtvec_r <= 32'b0;
      mepc_r <= 32'b0;
      mcause_r <= 32'b0;
      mcycle_r <= 64'd0;
    end else begin
      mstatus_r <= mstatus_next;
      mtvec_r <= mtvec_next;
      mepc_r <= mepc_next;
      mcause_r <= mcause_next;
      mcycle_r <= mcycle_next;
    end
  end

  assign csr_rdata_o = (csr_addr_i == CSR_MSTATUS  ) ? mstatus_r        :
                       (csr_addr_i == CSR_MTVEC    ) ? mtvec_r          :
                       (csr_addr_i == CSR_MEPC     ) ? mepc_r           :
                       (csr_addr_i == CSR_MCAUSE   ) ? mcause_r         :
                       (csr_addr_i == CSR_MCYCLE   ) ? mcycle_r[31:0]   :
                       (csr_addr_i == CSR_MCYCLEH  ) ? mcycle_r[63:32]  :
                       (csr_addr_i == CSR_MVENDORID) ? MVENDORID_VALUE  :
                       (csr_addr_i == CSR_MARCHID  ) ? MARCHID_VALUE    :
                                                        32'b0;
  assign mstatus_o = mstatus_r;
  assign mtvec_o = mtvec_r;
  assign mepc_o = mepc_r;
  assign mcause_o = mcause_r;

endmodule


module ysyx_26060188_exu (
  input  [`ysyx_26060188_IDU_EXU_BUS_W-1:0] id_bus_i,
  input         id_valid_i,
  output        id_ready_o,
  input  [31:0] rs1_data_i,
  input  [31:0] rs2_data_i,
  output [`ysyx_26060188_EXU_WBU_BUS_W-1:0] ex_bus_o,
  output        ex_valid_o,
  input         ex_ready_i
);

  wire [31:0] pc_i = id_bus_i[`ysyx_26060188_IDU_EXU_PC];
  wire [31:0] imm_i = id_bus_i[`ysyx_26060188_IDU_EXU_IMM];
  wire [3:0] alu_op_i = id_bus_i[`ysyx_26060188_IDU_EXU_ALU_OP];
  wire [2:0] br_type_i = id_bus_i[`ysyx_26060188_IDU_EXU_BR_TYPE];
  wire op1_is_pc_i = id_bus_i[`ysyx_26060188_IDU_EXU_OP1_IS_PC];
  wire op2_is_rs2_i = id_bus_i[`ysyx_26060188_IDU_EXU_OP2_IS_RS2];

  wire [31:0] op1 = op1_is_pc_i ? pc_i : rs1_data_i;
  wire [31:0] op2 = op2_is_rs2_i ? rs2_data_i : imm_i;
  wire [31:0] alu_res;
  wire [31:0] sub_res = op1 - op2;
  wire signed_lt = ($signed(op1) < $signed(op2));
  wire unsigned_lt = (op1 < op2);
  wire _unused_ok = &{1'b0,
                      id_bus_i[`ysyx_26060188_IDU_EXU_RS1_IDX],
                      id_bus_i[`ysyx_26060188_IDU_EXU_RS2_IDX]};

  ysyx_26060188_alu u_alu (
    .op1_i(op1),
    .op2_i(op2),
    .alu_op_i(alu_op_i),
    .res_o(alu_res)
  );

  wire eq = (sub_res == 32'b0);
  wire br_taken =
    (br_type_i == 3'd0) ? eq :
    (br_type_i == 3'd1) ? (~eq) :
    (br_type_i == 3'd2) ? signed_lt :
    (br_type_i == 3'd3) ? (~signed_lt) :
    (br_type_i == 3'd4) ? unsigned_lt :
    (br_type_i == 3'd5) ? (~unsigned_lt) :
    1'b0;

  wire [31:0] br_target = pc_i + imm_i;
  wire [31:0] jalr_target = (rs1_data_i + imm_i) & 32'hffff_fffe;

  assign id_ready_o = ex_ready_i;
  assign ex_valid_o = id_valid_i;
  assign ex_bus_o[`ysyx_26060188_EXU_WBU_PC] = pc_i;
  assign ex_bus_o[`ysyx_26060188_EXU_WBU_RD_IDX] = id_bus_i[`ysyx_26060188_IDU_EXU_RD_IDX];
  assign ex_bus_o[`ysyx_26060188_EXU_WBU_CSR_ADDR] = id_bus_i[`ysyx_26060188_IDU_EXU_CSR_ADDR];
  assign ex_bus_o[`ysyx_26060188_EXU_WBU_LSU_FUNCT3] = id_bus_i[`ysyx_26060188_IDU_EXU_LSU_FUNCT3];
  assign ex_bus_o[`ysyx_26060188_EXU_WBU_RS1_DATA] = rs1_data_i;
  assign ex_bus_o[`ysyx_26060188_EXU_WBU_RS2_DATA] = rs2_data_i;
  assign ex_bus_o[`ysyx_26060188_EXU_WBU_ALU_RES] = alu_res;
  assign ex_bus_o[`ysyx_26060188_EXU_WBU_JALR_TARGET] = jalr_target;
  assign ex_bus_o[`ysyx_26060188_EXU_WBU_BR_TARGET] = br_target;
  assign ex_bus_o[`ysyx_26060188_EXU_WBU_BR_TAKEN] = br_taken;
  assign ex_bus_o[`ysyx_26060188_EXU_WBU_IS_CSRRW] = id_bus_i[`ysyx_26060188_IDU_EXU_IS_CSRRW];
  assign ex_bus_o[`ysyx_26060188_EXU_WBU_IS_CSRRS] = id_bus_i[`ysyx_26060188_IDU_EXU_IS_CSRRS];
  assign ex_bus_o[`ysyx_26060188_EXU_WBU_IS_ECALL] = id_bus_i[`ysyx_26060188_IDU_EXU_IS_ECALL];
  assign ex_bus_o[`ysyx_26060188_EXU_WBU_IS_MRET] = id_bus_i[`ysyx_26060188_IDU_EXU_IS_MRET];
  assign ex_bus_o[`ysyx_26060188_EXU_WBU_IS_LOAD] = id_bus_i[`ysyx_26060188_IDU_EXU_IS_LOAD];
  assign ex_bus_o[`ysyx_26060188_EXU_WBU_IS_STORE] = id_bus_i[`ysyx_26060188_IDU_EXU_IS_STORE];
  assign ex_bus_o[`ysyx_26060188_EXU_WBU_IS_BRANCH] = id_bus_i[`ysyx_26060188_IDU_EXU_IS_BRANCH];
  assign ex_bus_o[`ysyx_26060188_EXU_WBU_IS_JAL] = id_bus_i[`ysyx_26060188_IDU_EXU_IS_JAL];
  assign ex_bus_o[`ysyx_26060188_EXU_WBU_IS_JALR] = id_bus_i[`ysyx_26060188_IDU_EXU_IS_JALR];
  assign ex_bus_o[`ysyx_26060188_EXU_WBU_IS_EBREAK] = id_bus_i[`ysyx_26060188_IDU_EXU_IS_EBREAK];
  assign ex_bus_o[`ysyx_26060188_EXU_WBU_WB_EN] = id_bus_i[`ysyx_26060188_IDU_EXU_WB_EN];
  assign ex_bus_o[`ysyx_26060188_EXU_WBU_WB_FROM_LOAD] = id_bus_i[`ysyx_26060188_IDU_EXU_WB_FROM_LOAD];
  assign ex_bus_o[`ysyx_26060188_EXU_WBU_WB_FROM_PC4] = id_bus_i[`ysyx_26060188_IDU_EXU_WB_FROM_PC4];
  assign ex_bus_o[`ysyx_26060188_EXU_WBU_WB_FROM_CSR] = id_bus_i[`ysyx_26060188_IDU_EXU_WB_FROM_CSR];

endmodule


module ysyx_26060188_idu (
  input  [`ysyx_26060188_IFU_IDU_BUS_W-1:0] if_bus_i,
  input         if_valid_i,
  output        if_ready_o,
  output [`ysyx_26060188_IDU_EXU_BUS_W-1:0] id_bus_o,
  output        id_valid_o,
  input         id_ready_i
);

  wire [31:0] pc_i = if_bus_i[`ysyx_26060188_IFU_IDU_PC];
  wire [31:0] inst_i = if_bus_i[`ysyx_26060188_IFU_IDU_INST];

  wire [6:0] opcode = inst_i[6:0];
  wire [2:0] funct3 = inst_i[14:12];
  wire [6:0] funct7 = inst_i[31:25];

  wire [4:0] rs1_idx = inst_i[19:15];
  wire [4:0] rs2_idx = inst_i[24:20];
  wire [4:0] rd_idx  = inst_i[11:7];

  wire [31:0] imm_i = {{20{inst_i[31]}}, inst_i[31:20]};
  wire [31:0] imm_s = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
  wire [31:0] imm_b = {{19{inst_i[31]}}, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
  wire [31:0] imm_u = {inst_i[31:12], 12'b0};
  wire [31:0] imm_j = {{11{inst_i[31]}}, inst_i[31], inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};

  wire is_add  = (opcode == 7'b0110011) && (funct3 == 3'b000) && (funct7 == 7'b0000000);
  wire is_sub  = (opcode == 7'b0110011) && (funct3 == 3'b000) && (funct7 == 7'b0100000);
  wire is_sll  = (opcode == 7'b0110011) && (funct3 == 3'b001) && (funct7 == 7'b0000000);
  wire is_slt  = (opcode == 7'b0110011) && (funct3 == 3'b010) && (funct7 == 7'b0000000);
  wire is_sltu = (opcode == 7'b0110011) && (funct3 == 3'b011) && (funct7 == 7'b0000000);
  wire is_xor  = (opcode == 7'b0110011) && (funct3 == 3'b100) && (funct7 == 7'b0000000);
  wire is_srl  = (opcode == 7'b0110011) && (funct3 == 3'b101) && (funct7 == 7'b0000000);
  wire is_sra  = (opcode == 7'b0110011) && (funct3 == 3'b101) && (funct7 == 7'b0100000);
  wire is_or   = (opcode == 7'b0110011) && (funct3 == 3'b110) && (funct7 == 7'b0000000);
  wire is_and  = (opcode == 7'b0110011) && (funct3 == 3'b111) && (funct7 == 7'b0000000);

  wire is_addi = (opcode == 7'b0010011) && (funct3 == 3'b000);
  wire is_slli = (opcode == 7'b0010011) && (funct3 == 3'b001) && (funct7 == 7'b0000000);
  wire is_slti = (opcode == 7'b0010011) && (funct3 == 3'b010);
  wire is_sltiu= (opcode == 7'b0010011) && (funct3 == 3'b011);
  wire is_xori = (opcode == 7'b0010011) && (funct3 == 3'b100);
  wire is_srli = (opcode == 7'b0010011) && (funct3 == 3'b101) && (funct7 == 7'b0000000);
  wire is_srai = (opcode == 7'b0010011) && (funct3 == 3'b101) && (funct7 == 7'b0100000);
  wire is_ori  = (opcode == 7'b0010011) && (funct3 == 3'b110);
  wire is_andi = (opcode == 7'b0010011) && (funct3 == 3'b111);

  wire is_lui  = (opcode == 7'b0110111);
  wire is_auipc= (opcode == 7'b0010111);
  wire is_jal  = (opcode == 7'b1101111);
  wire is_lb   = (opcode == 7'b0000011) && (funct3 == 3'b000);
  wire is_lh   = (opcode == 7'b0000011) && (funct3 == 3'b001);
  wire is_lw   = (opcode == 7'b0000011) && (funct3 == 3'b010);
  wire is_lbu  = (opcode == 7'b0000011) && (funct3 == 3'b100);
  wire is_lhu  = (opcode == 7'b0000011) && (funct3 == 3'b101);
  wire is_sw   = (opcode == 7'b0100011) && (funct3 == 3'b010);
  wire is_sb   = (opcode == 7'b0100011) && (funct3 == 3'b000);
  wire is_sh   = (opcode == 7'b0100011) && (funct3 == 3'b001);
  wire is_beq  = (opcode == 7'b1100011) && (funct3 == 3'b000);
  wire is_bne  = (opcode == 7'b1100011) && (funct3 == 3'b001);
  wire is_blt  = (opcode == 7'b1100011) && (funct3 == 3'b100);
  wire is_bge  = (opcode == 7'b1100011) && (funct3 == 3'b101);
  wire is_bltu = (opcode == 7'b1100011) && (funct3 == 3'b110);
  wire is_bgeu = (opcode == 7'b1100011) && (funct3 == 3'b111);
  wire is_jalr = (opcode == 7'b1100111) && (funct3 == 3'b000);
  wire is_csrrw = (opcode == 7'b1110011) && (funct3 == 3'b001);
  wire is_csrrs = (opcode == 7'b1110011) && (funct3 == 3'b010);
  wire is_ecall = (inst_i == 32'h0000_0073);
  wire is_mret = (inst_i == 32'h3020_0073);
  wire is_ebreak = (inst_i == 32'h0010_0073);

  wire [11:0] csr_addr = inst_i[31:20];

  wire op1_is_pc = is_auipc;
  wire op2_is_rs2 = is_add || is_sub || is_sll || is_slt || is_sltu || is_xor || is_srl || is_sra || is_or || is_and
                 || is_beq || is_bne || is_blt || is_bge || is_bltu || is_bgeu;

  wire [31:0] imm = (is_lui || is_auipc) ? imm_u :
                    (is_jal) ? imm_j :
                    (is_beq || is_bne || is_blt || is_bge || is_bltu || is_bgeu) ? imm_b :
                    (is_sw || is_sb || is_sh) ? imm_s :
                    imm_i;

  localparam ALU_ADD  = 4'd0;
  localparam ALU_SUB  = 4'd1;
  localparam ALU_AND  = 4'd2;
  localparam ALU_OR   = 4'd3;
  localparam ALU_XOR  = 4'd4;
  localparam ALU_SLL  = 4'd5;
  localparam ALU_SRL  = 4'd6;
  localparam ALU_SRA  = 4'd7;
  localparam ALU_SLT  = 4'd8;
  localparam ALU_SLTU = 4'd9;
  localparam ALU_COPY2= 4'd10;

  wire [3:0] alu_op =
    (is_sub || is_beq || is_bne || is_blt || is_bge || is_bltu || is_bgeu) ? ALU_SUB :
    (is_and || is_andi) ? ALU_AND :
    (is_or  || is_ori ) ? ALU_OR  :
    (is_xor || is_xori) ? ALU_XOR :
    (is_sll || is_slli) ? ALU_SLL :
    (is_srl || is_srli) ? ALU_SRL :
    (is_sra || is_srai) ? ALU_SRA :
    (is_slt || is_slti) ? ALU_SLT :
    (is_sltu|| is_sltiu)? ALU_SLTU:
    (is_lui) ? ALU_COPY2 :
    ALU_ADD;

  wire is_load  = is_lb || is_lh || is_lw || is_lbu || is_lhu;
  wire is_store = is_sb || is_sh || is_sw;
  wire is_branch = is_beq || is_bne || is_blt || is_bge || is_bltu || is_bgeu;
  wire [2:0] br_type = is_beq  ? 3'd0 :
                       is_bne  ? 3'd1 :
                       is_blt  ? 3'd2 :
                       is_bge  ? 3'd3 :
                       is_bltu ? 3'd4 :
                       is_bgeu ? 3'd5 : 3'd0;
  wire wb_en = is_add || is_sub || is_sll || is_slt || is_sltu || is_xor || is_srl || is_sra || is_or || is_and
            || is_addi || is_slli || is_slti || is_sltiu || is_xori || is_srli || is_srai || is_ori || is_andi
            || is_lui || is_auipc || is_lb || is_lh || is_lw || is_lbu || is_lhu || is_jal || is_jalr
            || is_csrrw || is_csrrs;
  wire wb_from_load = is_load;
  wire wb_from_pc4  = is_jal || is_jalr;
  wire wb_from_csr  = is_csrrw || is_csrrs;

  assign if_ready_o = id_ready_i;
  assign id_valid_o = if_valid_i;
  assign id_bus_o[`ysyx_26060188_IDU_EXU_PC] = pc_i;
  assign id_bus_o[`ysyx_26060188_IDU_EXU_IMM] = imm;
  assign id_bus_o[`ysyx_26060188_IDU_EXU_RS1_IDX] = rs1_idx;
  assign id_bus_o[`ysyx_26060188_IDU_EXU_RS2_IDX] = rs2_idx;
  assign id_bus_o[`ysyx_26060188_IDU_EXU_RD_IDX] = rd_idx;
  assign id_bus_o[`ysyx_26060188_IDU_EXU_CSR_ADDR] = csr_addr;
  assign id_bus_o[`ysyx_26060188_IDU_EXU_ALU_OP] = alu_op;
  assign id_bus_o[`ysyx_26060188_IDU_EXU_LSU_FUNCT3] = funct3;
  assign id_bus_o[`ysyx_26060188_IDU_EXU_BR_TYPE] = br_type;
  assign id_bus_o[`ysyx_26060188_IDU_EXU_OP1_IS_PC] = op1_is_pc;
  assign id_bus_o[`ysyx_26060188_IDU_EXU_OP2_IS_RS2] = op2_is_rs2;
  assign id_bus_o[`ysyx_26060188_IDU_EXU_IS_CSRRW] = is_csrrw;
  assign id_bus_o[`ysyx_26060188_IDU_EXU_IS_CSRRS] = is_csrrs;
  assign id_bus_o[`ysyx_26060188_IDU_EXU_IS_ECALL] = is_ecall;
  assign id_bus_o[`ysyx_26060188_IDU_EXU_IS_MRET] = is_mret;
  assign id_bus_o[`ysyx_26060188_IDU_EXU_IS_LOAD] = is_load;
  assign id_bus_o[`ysyx_26060188_IDU_EXU_IS_STORE] = is_store;
  assign id_bus_o[`ysyx_26060188_IDU_EXU_IS_BRANCH] = is_branch;
  assign id_bus_o[`ysyx_26060188_IDU_EXU_IS_JAL] = is_jal;
  assign id_bus_o[`ysyx_26060188_IDU_EXU_IS_JALR] = is_jalr;
  assign id_bus_o[`ysyx_26060188_IDU_EXU_IS_EBREAK] = is_ebreak;
  assign id_bus_o[`ysyx_26060188_IDU_EXU_WB_EN] = wb_en;
  assign id_bus_o[`ysyx_26060188_IDU_EXU_WB_FROM_LOAD] = wb_from_load;
  assign id_bus_o[`ysyx_26060188_IDU_EXU_WB_FROM_PC4] = wb_from_pc4;
  assign id_bus_o[`ysyx_26060188_IDU_EXU_WB_FROM_CSR] = wb_from_csr;

endmodule


module ysyx_26060188_ifu (
  input         clk,
  input         rst,
  input  [31:0] pc_i,
  input         pc_valid_i,
  output        pc_ready_o,
  output [`ysyx_26060188_IFU_IDU_BUS_W-1:0] if_bus_o,
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
    input [3:0] lfsr;
    begin
      choose_delay = VALID_USE_LFSR ? {1'b0, lfsr} : VALID_FIXED_DELAY;
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
        req_delay_r <= choose_delay(lfsr_r[3:0]);
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
  assign if_bus_o[`ysyx_26060188_IFU_IDU_PC] = pc_r;
  assign if_bus_o[`ysyx_26060188_IFU_IDU_INST] = inst_r;

endmodule


module ysyx_26060188_lsu (
  input         rst,
  input         clk,
  input  [`ysyx_26060188_EXU_WBU_BUS_W-1:0] ex_bus_i,
  input         ex_valid_i,
  output        ex_ready_o,
  output [`ysyx_26060188_EXU_WBU_BUS_W-1:0] mem_bus_o,
  output [31:0] load_data_o,
  output        mem_valid_o,
  input         mem_ready_i,

  output [31:0] axi_awaddr_o,
  output [2:0]  axi_awsize_o,
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
  output [2:0]  axi_arsize_o,
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

  wire is_load_i = ex_bus_i[`ysyx_26060188_EXU_WBU_IS_LOAD];
  wire is_store_i = ex_bus_i[`ysyx_26060188_EXU_WBU_IS_STORE];
  wire [2:0] funct3_i = ex_bus_i[`ysyx_26060188_EXU_WBU_LSU_FUNCT3];
  wire [31:0] addr_i = ex_bus_i[`ysyx_26060188_EXU_WBU_ALU_RES];
  wire [31:0] store_data_i = ex_bus_i[`ysyx_26060188_EXU_WBU_RS2_DATA];

  wire [1:0] byte_off = addr_i[1:0];
  wire valid = is_load_i || is_store_i;
  wire [31:0] bus_addr = addr_i;

  reg [`ysyx_26060188_EXU_WBU_BUS_W-1:0] ex_bus_r;
  reg [31:0] dmem_rdata_r;
  reg [31:0] bus_addr_r;
  reg [1:0]  byte_off_r;
  reg [2:0]  bus_size_r;
  reg [31:0] dmem_wdata_r;
  reg [3:0]  dmem_wmask_r;
  reg [4:0]  req_delay_r;
  reg [7:0]  lfsr_r;
  reg [2:0]  state_r;
  reg        aw_done_r;
  reg        w_done_r;

  wire state_is_mem = (state_r != ST_IDLE);
  wire [2:0] funct3_r = ex_bus_r[`ysyx_26060188_EXU_WBU_LSU_FUNCT3];

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
  wire [2:0] bus_size = (is_sb || is_lb || is_lbu) ? 3'b000 :
                        (is_sh || is_lh || is_lhu) ? 3'b001 :
                                                     3'b010;
  wire is_lb_r  = ex_bus_r[`ysyx_26060188_EXU_WBU_IS_LOAD] && (funct3_r == 3'b000);
  wire is_lh_r  = ex_bus_r[`ysyx_26060188_EXU_WBU_IS_LOAD] && (funct3_r == 3'b001);
  wire is_lw_r  = ex_bus_r[`ysyx_26060188_EXU_WBU_IS_LOAD] && (funct3_r == 3'b010);
  wire is_lbu_r = ex_bus_r[`ysyx_26060188_EXU_WBU_IS_LOAD] && (funct3_r == 3'b100);
  wire is_lhu_r = ex_bus_r[`ysyx_26060188_EXU_WBU_IS_LOAD] && (funct3_r == 3'b101);

  wire req_done = (req_delay_r == 5'd0);
  wire ar_fire = axi_arvalid_o && axi_arready_i;
  wire r_fire = axi_rvalid_i && axi_rready_o;
  wire aw_fire = axi_awvalid_o && axi_awready_i;
  wire w_fire = axi_wvalid_o && axi_wready_i;
  wire b_fire = axi_bvalid_i && axi_bready_o;
  wire mem_fire = mem_valid_o && mem_ready_i;
  wire _unused_ok = &{1'b0, axi_bresp_i, axi_rresp_i};

  function [7:0] lfsr_next;
    input [7:0] lfsr;
    begin
      lfsr_next = {lfsr[6:0], lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]};
    end
  endfunction

  function [4:0] choose_delay;
    input [3:0] lfsr;
    begin
      choose_delay = VALID_USE_LFSR ? {1'b0, lfsr} : VALID_FIXED_DELAY;
    end
  endfunction

  always @(posedge clk) begin
    if (rst) begin
      ex_bus_r <= {`ysyx_26060188_EXU_WBU_BUS_W{1'b0}};
      dmem_rdata_r <= 32'b0;
      bus_addr_r <= 32'b0;
      byte_off_r <= 2'b0;
      bus_size_r <= 3'b010;
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
            bus_addr_r <= bus_addr;
            byte_off_r <= byte_off;
            bus_size_r <= bus_size;
            dmem_wdata_r <= dmem_wdata;
            dmem_wmask_r <= dmem_wmask;
            req_delay_r <= choose_delay(lfsr_r[3:0]);
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

  assign axi_awaddr_o = bus_addr_r;
  assign axi_awsize_o = bus_size_r;
  assign axi_awvalid_o = (state_r == ST_WR_REQ) && req_done && !aw_done_r;
  assign axi_wdata_o = dmem_wdata_r;
  assign axi_wstrb_o = dmem_wmask_r;
  assign axi_wvalid_o = (state_r == ST_WR_REQ) && req_done && !w_done_r;
  assign axi_bready_o = (state_r == ST_WR_RESP);
  assign axi_araddr_o = bus_addr_r;
  assign axi_arsize_o = bus_size_r;
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


module ysyx_26060188_regfile (
  input         clk,
  input         rst,
  input         we_i,
  input  [4:0]  waddr_i,
  input  [31:0] wdata_i,
  input  [4:0]  raddr1_i,
  input  [4:0]  raddr2_i,
  output [31:0] rdata1_o,
  output [31:0] rdata2_o,
  output [31:0] a0_o
);

  reg [31:0] gpr [0:31];
  integer i;

  always @(posedge clk) begin
    if (rst) begin
      for (i = 0; i < 32; i = i + 1) begin
        gpr[i] <= 32'b0;
      end
    end else if (we_i && (waddr_i != 5'd0)) begin
      gpr[waddr_i] <= wdata_i;
    end
  end

  assign rdata1_o = (raddr1_i == 5'd0) ? 32'b0 : gpr[raddr1_i];
  assign rdata2_o = (raddr2_i == 5'd0) ? 32'b0 : gpr[raddr2_i];

  assign a0_o = gpr[10];

`ifdef VERILATOR
  import "DPI-C" function void set_gpr_ptr(input logic [31:0] a []);

  initial begin
    set_gpr_ptr(gpr);
  end
`endif

endmodule


module ysyx_26060188_wbu (
  input  [`ysyx_26060188_EXU_WBU_BUS_W-1:0] mem_bus_i,
  input  [31:0] load_data_i,
  input         mem_valid_i,
  output        mem_ready_o,
  input  [31:0] csr_rdata_i,
  input  [31:0] trap_target_i,
  input  [31:0] mret_target_i,

  output        rf_we_o,
  output [4:0]  rf_waddr_o,
  output [31:0] rf_wdata_o,

  output [31:0] pc_next_o
);

  wire [31:0] pc_i = mem_bus_i[`ysyx_26060188_EXU_WBU_PC];
  wire [31:0] alu_res_i = mem_bus_i[`ysyx_26060188_EXU_WBU_ALU_RES];
  wire [31:0] jalr_target_i = mem_bus_i[`ysyx_26060188_EXU_WBU_JALR_TARGET];
  wire [31:0] br_target_i = mem_bus_i[`ysyx_26060188_EXU_WBU_BR_TARGET];
  wire [4:0] rd_idx_i = mem_bus_i[`ysyx_26060188_EXU_WBU_RD_IDX];
  wire wb_en_i = mem_bus_i[`ysyx_26060188_EXU_WBU_WB_EN];
  wire wb_from_load_i = mem_bus_i[`ysyx_26060188_EXU_WBU_WB_FROM_LOAD];
  wire wb_from_pc4_i = mem_bus_i[`ysyx_26060188_EXU_WBU_WB_FROM_PC4];
  wire wb_from_csr_i = mem_bus_i[`ysyx_26060188_EXU_WBU_WB_FROM_CSR];
  wire is_ecall_i = mem_bus_i[`ysyx_26060188_EXU_WBU_IS_ECALL];
  wire is_mret_i = mem_bus_i[`ysyx_26060188_EXU_WBU_IS_MRET];
  wire is_branch_i = mem_bus_i[`ysyx_26060188_EXU_WBU_IS_BRANCH];
  wire br_taken_i = mem_bus_i[`ysyx_26060188_EXU_WBU_BR_TAKEN];
  wire is_jal_i = mem_bus_i[`ysyx_26060188_EXU_WBU_IS_JAL];
  wire is_jalr_i = mem_bus_i[`ysyx_26060188_EXU_WBU_IS_JALR];
  wire _unused_ok = &{1'b0,
                      mem_valid_i,
                      mem_bus_i[`ysyx_26060188_EXU_WBU_IS_EBREAK],
                      mem_bus_i[`ysyx_26060188_EXU_WBU_IS_LOAD],
                      mem_bus_i[`ysyx_26060188_EXU_WBU_IS_STORE],
                      mem_bus_i[`ysyx_26060188_EXU_WBU_IS_CSRRW],
                      mem_bus_i[`ysyx_26060188_EXU_WBU_IS_CSRRS],
                      mem_bus_i[`ysyx_26060188_EXU_WBU_CSR_ADDR],
                      mem_bus_i[`ysyx_26060188_EXU_WBU_LSU_FUNCT3],
                      mem_bus_i[`ysyx_26060188_EXU_WBU_RS1_DATA],
                      mem_bus_i[`ysyx_26060188_EXU_WBU_RS2_DATA]};

  assign mem_ready_o = 1'b1;
  assign rf_we_o    = wb_en_i;
  assign rf_waddr_o = rd_idx_i;
  assign rf_wdata_o = wb_from_load_i ? load_data_i :
                      wb_from_pc4_i  ? (pc_i + 32'd4) :
                      wb_from_csr_i  ? csr_rdata_i :
                                        alu_res_i;

  assign pc_next_o = is_ecall_i ? trap_target_i :
                     is_mret_i ? mret_target_i :
                     (is_jal_i || (is_branch_i && br_taken_i)) ? br_target_i :
                     is_jalr_i ? jalr_target_i :
                     (pc_i + 32'd4);

endmodule


module ysyx_26060188 (
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

`ifdef __ICARUS__
  localparam [31:0] RESET_PC = 32'h8000_0000;
`else
  localparam [31:0] RESET_PC = 32'h3000_0000;
`endif

`ifdef VERILATOR
  import "DPI-C" function void npc_ebreak(input int unsigned pc, input int unsigned inst, input int unsigned a0);
  import "DPI-C" function void trace_inst(input int pc, input int inst);
`endif

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

  wire [`ysyx_26060188_IFU_IDU_BUS_W-1:0] ifu_idu_bus;
  wire [`ysyx_26060188_IDU_EXU_BUS_W-1:0] idu_exu_bus;
  wire [`ysyx_26060188_EXU_WBU_BUS_W-1:0] exu_wbu_bus;
  wire [`ysyx_26060188_EXU_WBU_BUS_W-1:0] mem_wbu_bus;

  wire if_valid;
  wire if_ready;
  wire if_ready_raw;
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

  reg        last_wb_valid_r;
  reg [4:0]  last_wb_rd_r;

  wire [31:0] ifu_axi_araddr;
  wire        ifu_axi_arvalid;
  wire        ifu_axi_arready;
  wire [31:0] ifu_axi_rdata;
  wire [1:0]  ifu_axi_rresp;
  wire        ifu_axi_rvalid;
  wire        ifu_axi_rready;

  wire [31:0] lsu_axi_awaddr;
  wire [2:0]  lsu_axi_awsize;
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
  wire [2:0]  lsu_axi_arsize;
  wire        lsu_axi_arvalid;
  wire        lsu_axi_arready;
  wire [31:0] lsu_axi_rdata;
  wire [1:0]  lsu_axi_rresp;
  wire        lsu_axi_rvalid;
  wire        lsu_axi_rready;

  wire [31:0] mem_axi_awaddr;
  wire [2:0]  mem_axi_awsize;
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
  wire [2:0]  mem_axi_arsize;
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
  wire        ifu_axi_awready_unused;
  wire        ifu_axi_wready_unused;
  wire        ifu_axi_bvalid_unused;
  wire [1:0]  ifu_axi_bresp_unused;
  reg         debug_commit_r;
  reg [31:0]  debug_pc_r;
  reg [31:0]  debug_inst_r;
  reg [31:0]  debug_a0_r;
  reg         debug_ebreak_r;
  wire        _unused_top_ok = &{1'b0,
                                 pc_ready,
                                 mstatus,
                                 mcause,
                                 ifu_axi_rresp,
                                 ifu_axi_awready_unused,
                                 ifu_axi_wready_unused,
                                 ifu_axi_bvalid_unused,
                                 ifu_axi_bresp_unused,
                                 debug_commit_r,
                                 debug_pc_r,
                                 debug_inst_r,
                                 debug_a0_r,
                                 debug_ebreak_r};

  wire [6:0] hazard_opcode = inst[6:0];
  wire [2:0] hazard_funct3 = inst[14:12];
  wire [4:0] hazard_rs1_idx = inst[19:15];
  wire [4:0] hazard_rs2_idx = inst[24:20];
  wire       hazard_use_rs1 = (hazard_opcode == 7'b0110011) ||
                              (hazard_opcode == 7'b0010011) ||
                              (hazard_opcode == 7'b0000011) ||
                              (hazard_opcode == 7'b0100011) ||
                              (hazard_opcode == 7'b1100011) ||
                              (hazard_opcode == 7'b1100111) ||
                              ((hazard_opcode == 7'b1110011) &&
                               ((hazard_funct3 == 3'b001) || (hazard_funct3 == 3'b010)));
  wire       hazard_use_rs2 = (hazard_opcode == 7'b0110011) ||
                              (hazard_opcode == 7'b0100011) ||
                              (hazard_opcode == 7'b1100011);
  wire       data_hazard = if_valid && last_wb_valid_r &&
                           ((hazard_use_rs1 && (hazard_rs1_idx != 5'd0) && (hazard_rs1_idx == last_wb_rd_r)) ||
                            (hazard_use_rs2 && (hazard_rs2_idx != 5'd0) && (hazard_rs2_idx == last_wb_rd_r)));
  assign pc_valid = ~reset;
  assign wb_fire = mem_valid && mem_ready;
  assign inst = ifu_idu_bus[`ysyx_26060188_IFU_IDU_INST];
  assign rs1_idx = idu_exu_bus[`ysyx_26060188_IDU_EXU_RS1_IDX];
  assign rs2_idx = idu_exu_bus[`ysyx_26060188_IDU_EXU_RS2_IDX];
  assign csr_addr = mem_wbu_bus[`ysyx_26060188_EXU_WBU_CSR_ADDR];
  assign is_csrrw = mem_wbu_bus[`ysyx_26060188_EXU_WBU_IS_CSRRW];
  assign is_csrrs = mem_wbu_bus[`ysyx_26060188_EXU_WBU_IS_CSRRS];
  assign is_ecall = mem_wbu_bus[`ysyx_26060188_EXU_WBU_IS_ECALL];
  assign is_ebreak = mem_wbu_bus[`ysyx_26060188_EXU_WBU_IS_EBREAK];

  ysyx_26060188_ifu u_ifu (
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

  ysyx_26060188_idu u_idu (
    .if_bus_i(ifu_idu_bus),
    .if_valid_i(if_valid && !data_hazard),
    .if_ready_o(if_ready_raw),
    .id_bus_o(idu_exu_bus),
    .id_valid_o(id_valid),
    .id_ready_i(id_ready)
  );

  assign if_ready = if_ready_raw && !data_hazard;

  ysyx_26060188_regfile u_regfile (
    .clk(clock),
    .rst(reset),
    .we_i(wb_fire && rf_we),
    .waddr_i(rf_waddr),
    .wdata_i(rf_wdata),
    .raddr1_i(rs1_idx),
    .raddr2_i(rs2_idx),
    .rdata1_o(rs1_data),
    .rdata2_o(rs2_data),
    .a0_o(a0_data)
  );

  ysyx_26060188_exu u_exu (
    .id_bus_i(idu_exu_bus),
    .id_valid_i(id_valid),
    .id_ready_o(id_ready),
    .rs1_data_i(rs1_data),
    .rs2_data_i(rs2_data),
    .ex_bus_o(exu_wbu_bus),
    .ex_valid_o(ex_valid),
    .ex_ready_i(ex_ready)
  );

  ysyx_26060188_lsu u_lsu (
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
    .axi_awsize_o(lsu_axi_awsize),
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
    .axi_arsize_o(lsu_axi_arsize),
    .axi_arvalid_o(lsu_axi_arvalid),
    .axi_arready_i(lsu_axi_arready),
    .axi_rdata_i(lsu_axi_rdata),
    .axi_rresp_i(lsu_axi_rresp),
    .axi_rvalid_i(lsu_axi_rvalid),
    .axi_rready_o(lsu_axi_rready)
  );

  ysyx_26060188_axi4lite_arbiter u_axi4lite_arbiter (
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
    .ifu_awready_o(ifu_axi_awready_unused),
    .ifu_wready_o(ifu_axi_wready_unused),
    .ifu_bvalid_o(ifu_axi_bvalid_unused),
    .ifu_bresp_o(ifu_axi_bresp_unused),
    .lsu_awaddr_i(lsu_axi_awaddr),
    .lsu_awsize_i(lsu_axi_awsize),
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
    .lsu_arsize_i(lsu_axi_arsize),
    .lsu_arvalid_i(lsu_axi_arvalid),
    .lsu_arready_o(lsu_axi_arready),
    .lsu_rdata_o(lsu_axi_rdata),
    .lsu_rresp_o(lsu_axi_rresp),
    .lsu_rvalid_o(lsu_axi_rvalid),
    .lsu_rready_i(lsu_axi_rready),
    .mem_awaddr_o(mem_axi_awaddr),
    .mem_awsize_o(mem_axi_awsize),
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
    .mem_arsize_o(mem_axi_arsize),
    .mem_arvalid_o(mem_axi_arvalid),
    .mem_arready_i(mem_axi_arready),
    .mem_rdata_i(mem_axi_rdata),
    .mem_rresp_i(mem_axi_rresp),
    .mem_rvalid_i(mem_axi_rvalid),
    .mem_rready_o(mem_axi_rready)
  );

  ysyx_26060188_axi4lite_clint_xbar u_axi4lite_clint_xbar (
    .clk(clock),
    .rst(reset),
    .axi_awaddr_i(mem_axi_awaddr),
    .axi_awsize_i(mem_axi_awsize),
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
    .axi_arsize_i(mem_axi_arsize),
    .axi_arvalid_i(mem_axi_arvalid),
    .axi_arready_o(mem_axi_arready),
    .axi_rdata_o(mem_axi_rdata),
    .axi_rresp_o(mem_axi_rresp),
    .axi_rvalid_o(mem_axi_rvalid),
    .axi_rready_i(mem_axi_rready),
    .ext_awaddr_o(io_master_awaddr),
    .ext_awsize_o(io_master_awsize),
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
    .ext_arsize_o(io_master_arsize),
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

  ysyx_26060188_axi4lite_clint u_axi4lite_clint (
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

  ysyx_26060188_csrfile u_csrfile (
    .clk(clock),
    .rst(reset),
    .csr_we_i(wb_fire && (is_csrrw || (is_csrrs && (rs1_idx != 5'd0)))),
    .csr_set_i(is_csrrs),
    .csr_addr_i(csr_addr),
    .csr_wdata_i(mem_wbu_bus[`ysyx_26060188_EXU_WBU_RS1_DATA]),
    .trap_we_i(wb_fire && is_ecall),
    .trap_epc_i(pc_r),
    .trap_cause_i(32'd11),
    .csr_rdata_o(csr_rdata),
    .mstatus_o(mstatus),
    .mtvec_o(mtvec),
    .mepc_o(mepc),
    .mcause_o(mcause)
  );

  ysyx_26060188_wbu u_wbu (
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
      pc_r <= RESET_PC;
      last_wb_valid_r <= 1'b0;
      last_wb_rd_r <= 5'd0;
      debug_commit_r <= 1'b0;
      debug_pc_r <= 32'b0;
      debug_inst_r <= 32'b0;
      debug_a0_r <= 32'b0;
      debug_ebreak_r <= 1'b0;
    end else begin
      last_wb_valid_r <= wb_fire && rf_we && (rf_waddr != 5'd0);
      if (wb_fire && rf_we && (rf_waddr != 5'd0)) begin
        last_wb_rd_r <= rf_waddr;
      end
      debug_commit_r <= wb_fire;
      debug_ebreak_r <= wb_fire && is_ebreak;
      if (wb_fire) begin
        debug_pc_r <= pc_r;
        debug_inst_r <= inst;
        debug_a0_r <= a0_data;
      end
`ifdef VERILATOR
      if (wb_fire) begin
        trace_inst(pc_r, inst);
      end
      if (wb_fire && is_ebreak) begin
        npc_ebreak(pc_r, inst, a0_data);
      end
`endif
      if (wb_fire) begin
        pc_r <= pc_next;
      end
    end
  end

  assign io_master_awid = 4'd1;
  assign io_master_awlen = 8'd0;
  assign io_master_awburst = 2'b01;
  assign io_master_wlast = 1'b1;
  assign io_master_arid = 4'd0;
  assign io_master_arlen = 8'd0;
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
