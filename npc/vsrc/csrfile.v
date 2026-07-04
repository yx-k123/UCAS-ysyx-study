module csrfile (
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
  output [31:0] mtvec_o,
  output [31:0] mepc_o
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
  assign mtvec_o = mtvec_r;
  assign mepc_o = mepc_r;

endmodule
