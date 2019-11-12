`default_nettype none
`include "common_params.h"

module decode_phase (
  input wire [`INST_W       -1:0] inst,
  output reg [`NUM_INST_TYPE-1:0] inst_type,
  output reg [`OPCODE_W     -1:0] opcode,
  output reg [`REG_ADDR_W   -1:0] rd_addr,
  output reg [`REG_ADDR_W   -1:0] rs_addr,
  output reg [`REG_ADDR_W   -1:0] rt_addr,
  output reg [`SHIFT_W      -1:0] shift,
  output reg [`FUNCT_W      -1:0] funct,
  output reg [`IMMEDIATE_W  -1:0] immediate,
  output reg [`INDEX_W      -1:0] index,
  output reg                      d_from_gpr,
  output reg                      d_from_fpr,
  output reg                      d_to_gpr,
  output reg                      d_to_fpr,
  output reg                      s_from_gpr,
  output reg                      s_from_fpr,
  output reg                      t_from_gpr,
  output reg                      t_from_fpr
);

  // 命令形式を決定するための関数.
  function [`NUM_INST_TYPE:0] instruction_type (
    input [`OPCODE_W-1:0] opcode
  );
  begin
    case (opcode)
      // R形式
      `OPCODE_R   : instruction_type = `R_TYPE;
      // FPU R形式
      `OPCODE_FR  : instruction_type = `FR_TYPE;
      // J形式
      `OPCODE_J   : instruction_type = `J_TYPE;
      `OPCODE_JAL : instruction_type = `J_TYPE;
      // FPU I形式
      `OPCODE_FTOI: instruction_type = `FI_TYPE;
      `OPCODE_ITOF: instruction_type = `FI_TYPE;
      `OPCODE_LWCZ: instruction_type = `FI_TYPE;
      `OPCODE_SWCZ: instruction_type = `FI_TYPE;
      `OPCODE_BC1T: instruction_type = `FI_TYPE;
      `OPCODE_BC1F: instruction_type = `FI_TYPE;
      `OPCODE_FLUI: instruction_type = `FI_TYPE;
      `OPCODE_FORI: instruction_type = `FI_TYPE;
      // I形式
      default     : instruction_type = `I_TYPE;
    endcase
  end
  endfunction

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

  assign inst_type = instruction_type (opcode);

  /************************************
  * d,s,tレジスタについて
  *   - gpr, fprどちらを読み込むか.
  *   - そもそも読み込む必要があるのか.
  * を決定するよ.
  ************************************/

  // dレジスタについて.
  // destinationである場合がほとんどだが,
  // 一部ソースレジスタ的に扱う必要がある.
  assign d_from_gpr =
    (inst_type==`R_TYPE) ? (
          funct ==`FUNCT_JR   || funct ==`FUNCT_JALR    ) :
    (inst_type==`I_TYPE) ? (
          opcode==`OPCODE_SW  || opcode==`OPCODE_BEQ ||
          opcode==`OPCODE_BNE || opcode==`OPCODE_OUT    ) : 0;
  assign d_from_fpr =
    (inst_type==`FI_TYPE) ? (
          opcode==`OPCODE_SWCZ                          ) : 0;

  assign d_to_gpr = (~d_from_gpr)&&(inst_type== `R_TYPE||inst_type== `I_TYPE);
  assign d_to_fpr = (~d_from_fpr)&&(inst_type==`FR_TYPE||inst_type==`FI_TYPE);

  // sレジスタについて.
  // 基本的にR, I形式で必要.
  assign s_from_gpr =
    (inst_type==`R_TYPE ) ? (
          funct !=`FUNCT_JR   &&
          funct !=`FUNCT_JALR    ) :
    (inst_type==`I_TYPE ) ? (
          opcode!=`OPCODE_LUI    ) :
    (inst_type==`FI_TYPE) ? (
          opcode==`OPCODE_ITOF ||
          opcode==`OPCODE_LWCZ   ) : 0;
  assign s_from_fpr =
    (inst_type==`FR_TYPE) ? 1 :
    (inst_type==`FI_TYPE) ? (
          opcode==`OPCODE_FTOI ||
          opcode==`OPCODE_FORI   ) : 0;

  // tレジスタについて.
  // 基本的にR形式で必要.
  assign t_from_gpr =
    (inst_type==`R_TYPE ) ? (
          funct !=`FUNCT_JR   &&
          funct !=`FUNCT_JALR    ) : 0;
  assign t_from_fpr =
    (inst_type==`FR_TYPE) ? (
          funct !=`FUNCT_FCZ     ) : 0;

endmodule

`default_nettype wire
