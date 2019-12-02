`default_nettype none
`include "common_params.h"

module decode_phase (
  input wire [`INST_W       -1:0] inst,
  output wire [`NUM_INST_TYPE-1:0] inst_type,
  output wire [`OPCODE_W     -1:0] opcode,
  output wire [`REG_ADDR_W   -1:0] rd_addr,
  output wire [`REG_ADDR_W   -1:0] rs_addr,
  output wire [`REG_ADDR_W   -1:0] rt_addr,
  output wire [`SHIFT_W      -1:0] shift,
  output wire [`FUNCT_W      -1:0] funct,
  output wire [`IMMEDIATE_W  -1:0] immediate,
  output wire [`INDEX_W      -1:0] index,
  output wire                      d_from_gpr,
  output wire                      d_from_fpr,
  output wire                      d_to_gpr,
  output wire                      d_to_fpr,
  output wire                      s_from_gpr,
  output wire                      s_from_fpr,
  output wire                      t_from_gpr,
  output wire                      t_from_fpr
);

  /************************************
  *   命令を各成分に分解していくよ.
  ************************************/
  assign opcode =
    inst[`INST_W-1:
         `INST_W-`OPCODE_W];
  assign rd_addr =
    inst[`INST_W-`OPCODE_W-1:
         `INST_W-`OPCODE_W-`REG_ADDR_W];
  assign rs_addr =
    inst[`INST_W-`OPCODE_W-`REG_ADDR_W-1:
         `INST_W-`OPCODE_W-`REG_ADDR_W-`REG_ADDR_W];
  assign rt_addr =
    inst[`INST_W-`OPCODE_W-`REG_ADDR_W-`REG_ADDR_W-1:
         `INST_W-`OPCODE_W-`REG_ADDR_W-`REG_ADDR_W-`REG_ADDR_W];
  assign shift =
    inst[`INST_W-`OPCODE_W-`REG_ADDR_W-`REG_ADDR_W-`REG_ADDR_W-1:
         `INST_W-`OPCODE_W-`REG_ADDR_W-`REG_ADDR_W-`REG_ADDR_W-`SHIFT_W];
  assign funct =
    inst[`INST_W-`OPCODE_W-`REG_ADDR_W-`REG_ADDR_W-`REG_ADDR_W-`SHIFT_W-1:
         `INST_W-`OPCODE_W-`REG_ADDR_W-`REG_ADDR_W-`REG_ADDR_W-`SHIFT_W-`FUNCT_W];
  assign immediate =
    inst[`INST_W-`OPCODE_W-`REG_ADDR_W-`REG_ADDR_W-1:
         `INST_W-`OPCODE_W-`REG_ADDR_W-`REG_ADDR_W-`IMMEDIATE_W];
  assign index =
    inst[`INST_W-`OPCODE_W-1:
         `INST_W-`OPCODE_W-`INDEX_W];

  instruction_type_table itt1 (
    .opcode   (opcode),
    .inst_type(inst_type)
  );

  register_usage_table rut1 (
    .opcode     (opcode),
    .funct      (funct),
    .d_from_gpr (d_from_gpr),
    .d_from_fpr (d_from_fpr),
    .d_to_gpr   (d_to_gpr),
    .d_to_fpr   (d_to_fpr),
    .s_from_gpr (s_from_gpr),
    .s_from_fpr (s_from_fpr),
    .t_from_gpr (t_from_gpr),
    .t_from_fpr (t_from_fpr)
  );

endmodule

`default_nettype wire
