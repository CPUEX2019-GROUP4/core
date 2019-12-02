`default_nettype none
`include "common_params.h"

module write_back_phase (
  input  wire [`ADDR_W       -1:0] pc,
  input  wire [`OPCODE_W     -1:0] opcode,
  input  wire [`FUNCT_W      -1:0] funct,
  input  wire [`ADDR_W       -1:0] bd,
  input  wire                      be,
  input  wire [`REG_W        -1:0] ld_data,
  input  wire [`REG_W        -1:0] op_d,
  input  wire [`NUM_INST_TYPE-1:0] inst_type,
  output wire [`REG_W        -1:0] new_pc,
  output wire [`REG_W        -1:0] new_op_d,
  output wire                      gpr_update,
  output wire                      fpr_update
);

  assign new_pc   = (be) ? bd : (pc+1);
  assign new_op_d =
    (opcode==`OPCODE_LW   ) ? ld_data :
    (opcode==`OPCODE_LWCZ ) ? ld_data :
    (opcode==`OPCODE_ININT) ? ld_data :
    (opcode==`OPCODE_INFLT) ? ld_data : op_d;

  register_usage_table rut1 (
    .opcode   (opcode),
    .funct    (funct),
    .d_to_gpr (gpr_update),
    .d_to_fpr (fpr_update)
  );

endmodule
`default_nettype wire
