`default_nettype none
`include "common_params.h"

module register_usage_table (
  input  wire [`OPCODE_W-1:0] opcode,
  input  wire [`FUNCT_W -1:0] funct,

  output wire d_from_gpr,
  output wire d_from_fpr,
  output wire d_to_gpr,
  output wire d_to_fpr,
  output wire s_from_gpr,
  output wire s_from_fpr,
  output wire t_from_gpr,
  output wire t_from_fpr,
  output wire from_fcond,
  output wire   to_fcond
);
  localparam from_gd = 10'b1000000000;
  localparam from_fd = 10'b0100000000;
  localparam   to_gd = 10'b0010000000;
  localparam   to_fd = 10'b0001000000;
  localparam      gs = 10'b0000100000;
  localparam      fs = 10'b0000010000;
  localparam      gt = 10'b0000001000;
  localparam      ft = 10'b0000000100;
  localparam from_fc = 10'b0000000010;
  localparam   to_fc = 10'b0000000001;
  localparam nothing = 10'b0000000000;

  wire [9:0] select =
    // R形式
    (opcode==`OPCODE_R       ) ? (
    (funct ==`FUNCT_ADD      ) ?   to_gd | gs | gt           :
    (funct ==`FUNCT_SUB      ) ?   to_gd | gs | gt           :
    (funct ==`FUNCT_OR       ) ?   to_gd | gs | gt           :
    (funct ==`FUNCT_SLT      ) ?   to_gd | gs | gt           :
    (funct ==`FUNCT_SLLV     ) ?   to_gd | gs | gt           :
    (funct ==`FUNCT_SLL      ) ?   to_gd | gs                :
    (funct ==`FUNCT_DIV2     ) ?   to_gd | gs                :
    (funct ==`FUNCT_DIV10    ) ?   to_gd | gs                :
    (funct ==`FUNCT_JR       ) ? from_gd                     :
    (funct ==`FUNCT_JALR     ) ? from_gd                     : nothing ) :
    // I形式命令
    (opcode==`OPCODE_ADDI    ) ?   to_gd | gs                :
    (opcode==`OPCODE_LW      ) ?   to_gd | gs                :
    (opcode==`OPCODE_ORI     ) ?   to_gd | gs                :
    (opcode==`OPCODE_SLTI    ) ?   to_gd | gs                :
    (opcode==`OPCODE_SW      ) ? from_gd | gs                :
    (opcode==`OPCODE_BEQ     ) ? from_gd | gs                :
    (opcode==`OPCODE_BNE     ) ? from_gd | gs                :
    (opcode==`OPCODE_OUT     ) ? from_gd                     :
    (opcode==`OPCODE_LUI     ) ?   to_gd                     :
    (opcode==`OPCODE_ININT   ) ?   to_gd                     :
    // J形式命令
    (opcode==`OPCODE_J       ) ? nothing                     :
    (opcode==`OPCODE_JAL     ) ? nothing                     :
    // FPU R形式
    (opcode==`OPCODE_FR      ) ? (
    (funct ==`FUNCT_FNEG     ) ?   to_fd | fs                :
    (funct ==`FUNCT_FADD     ) ?   to_fd | fs | ft           :
    (funct ==`FUNCT_FSUB     ) ?   to_fd | fs | ft           :
    (funct ==`FUNCT_FMUL     ) ?   to_fd | fs | ft           :
    (funct ==`FUNCT_FDIV     ) ?   to_fd | fs | ft           :
    (funct ==`FUNCT_FCLT     ) ?           fs | ft |   to_fc :
    (funct ==`FUNCT_FCZ      ) ?           fs |        to_fc :
    (funct ==`FUNCT_FMV      ) ?   to_fd | fs                :
    (funct ==`FUNCT_SQRT_INIT) ?   to_fd | fs                :
    (funct ==`FUNCT_FINV_INIT) ?   to_fd | fs                : nothing ) :
    // FPU I形式
    (opcode==`OPCODE_FTOI    ) ?   to_gd | fs                :
    (opcode==`OPCODE_ITOF    ) ?   to_fd | gs                :
    (opcode==`OPCODE_LWCZ    ) ?   to_fd | gs                :
    (opcode==`OPCODE_FORI    ) ?   to_fd | fs                :
    (opcode==`OPCODE_SWCZ    ) ? from_fd | gs                :
    (opcode==`OPCODE_BC1T    ) ?                   | from_fc :
    (opcode==`OPCODE_BC1F    ) ?                   | from_fc :
    (opcode==`OPCODE_FLUI    ) ?   to_fd                     :
    (opcode==`OPCODE_INFLT   ) ?   to_fd                     : nothing ;

  assign {
    d_from_gpr,
    d_from_fpr,
    d_to_gpr,
    d_to_fpr,
    s_from_gpr,
    s_from_fpr,
    t_from_gpr,
    t_from_fpr,
    from_fcond,
    to_fcond   } = select;
endmodule

module instruction_type_table (
  input  wire [`OPCODE_W     -1:0] opcode,
  output wire [`NUM_INST_TYPE-1:0] inst_type
);
  assign inst_type =
    (opcode==`OPCODE_R    ) ?  `R_TYPE :
    (opcode==`OPCODE_FR   ) ? `FR_TYPE :
    (opcode==`OPCODE_J    ) ?  `J_TYPE :
    (opcode==`OPCODE_JAL  ) ?  `J_TYPE :
    (opcode==`OPCODE_FTOI ) ? `FI_TYPE :
    (opcode==`OPCODE_ITOF ) ? `FI_TYPE :
    (opcode==`OPCODE_LWCZ ) ? `FI_TYPE :
    (opcode==`OPCODE_SWCZ ) ? `FI_TYPE :
    (opcode==`OPCODE_BC1T ) ? `FI_TYPE :
    (opcode==`OPCODE_BC1F ) ? `FI_TYPE :
    (opcode==`OPCODE_FLUI ) ? `FI_TYPE :
    (opcode==`OPCODE_FORI ) ? `FI_TYPE :
    (opcode==`OPCODE_INFLT) ? `FI_TYPE : `I_TYPE;
endmodule
`default_nettype wire
