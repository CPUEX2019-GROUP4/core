`default_nettype none
`include "common_params.h"

module write_back_phase
  (
   input wire [`ADDR_W       -1:0] pc,
   input wire [`OPCODE_W     -1:0] opcode,
   input wire [`FUNCT_W      -1:0] funct,
   input wire [`ADDR_W       -1:0] bd,
   input wire                      be,
   input wire [`REG_W        -1:0] ld_data,
   input wire [`REG_W        -1:0] op_d,
   input wire [`NUM_INST_TYPE-1:0] inst_type,
   output reg [`REG_W        -1:0] new_pc,
   output reg [`REG_W        -1:0] new_op_d,
   output reg                      gpr_update,
   output reg                      fpr_update
  );

  assign new_pc   = (be) ? bd : (pc+1);
  assign new_op_d =
    (opcode==`OPCODE_LW   ) ? ld_data :
    (opcode==`OPCODE_LWCZ ) ? ld_data :
    (opcode==`OPCODE_ININT) ? ld_data :
    (opcode==`OPCODE_INFLT) ? ld_data : op_d;

  assign gpr_update =
    (inst_type==`R_TYPE)  ? (
        funct !=`FUNCT_JR     ) :
    (inst_type==`I_TYPE)  ? (
        opcode!=`OPCODE_SW  &&
        opcode!=`OPCODE_BEQ &&
        opcode!=`OPCODE_BNE &&
        opcode!=`OPCODE_OUT   ) :
    (inst_type==`FI_TYPE) ? (
        opcode==`OPCODE_FTOI  ) : 0;

  assign fpr_update =
    (inst_type==`FR_TYPE) ? (
        funct !=`FUNCT_FCLT   ) :
    (inst_type==`FI_TYPE) ? (
        opcode!=`OPCODE_SWCZ &&
        opcode!=`OPCODE_BC1T &&
        opcode!=`OPCODE_BC1F &&
        opcode!=`OPCODE_FTOI  ) : 0;

endmodule
`default_nettype wire
