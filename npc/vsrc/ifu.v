`include "npc_bus.vh"

module ifu (
  input  [31:0] pc_i,
  input         pc_valid_i,
  output        pc_ready_o,
  output [`IFU_IDU_BUS_W-1:0] if_bus_o,
  output        if_valid_o,
  input         if_ready_i
);

  import "DPI-C" function int pmem_read(input int raddr);

  wire [31:0] inst = pmem_read(pc_i);

  assign pc_ready_o = if_ready_i;
  assign if_valid_o = pc_valid_i;
  assign if_bus_o[`IFU_IDU_PC] = pc_i;
  assign if_bus_o[`IFU_IDU_INST] = inst;

endmodule
