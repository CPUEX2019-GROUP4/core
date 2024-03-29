`ifndef COMMON_PARAMS_H
`define COMMON_PARAMS_H

`define      INST_W 32
`define      ADDR_W 32
`define    OPCODE_W  6
`define       REG_W 32
`define  REG_ADDR_W  5
`define     SHIFT_W  5
`define     FUNCT_W  6
`define IMMEDIATE_W 16
`define     INDEX_W 26
`define      WORD_W 32

`define NUM_INST_TYPE 6

`define INST_NAME_LENGTH 9

`define R_TYPE    (`NUM_INST_TYPE'b000001)
`define I_TYPE    (`NUM_INST_TYPE'b000010)
`define J_TYPE    (`NUM_INST_TYPE'b000100)
`define FR_TYPE   (`NUM_INST_TYPE'b001000)
`define FI_TYPE   (`NUM_INST_TYPE'b010000)
`define S_TYPE    (`NUM_INST_TYPE'b100000)

`define OPCODE_R    (`OPCODE_W'b000000)
`define OPCODE_FR   (`OPCODE_W'b010001)


`define OPCODE_ININT (`OPCODE_W'b011000)
`define OPCODE_INFLT (`OPCODE_W'b011001)
`define OPCODE_OUT  (`OPCODE_W'b111111)

`define OPCODE_ADDI (`OPCODE_W'b001000)
`define OPCODE_SLTI (`OPCODE_W'b001010)
`define OPCODE_ORI  (`OPCODE_W'b001101)
`define OPCODE_LUI  (`OPCODE_W'b001111)
`define OPCODE_BEQ  (`OPCODE_W'b000100)
`define OPCODE_BNE  (`OPCODE_W'b000101)
`define OPCODE_LW   (`OPCODE_W'b100011)
`define OPCODE_SW   (`OPCODE_W'b101011)

`define OPCODE_J    (`OPCODE_W'b000010)
`define OPCODE_JAL  (`OPCODE_W'b000011)

`define OPCODE_FTOI (`OPCODE_W'b011100)
`define OPCODE_ITOF (`OPCODE_W'b011101)
`define OPCODE_LWCZ (`OPCODE_W'b110000)
`define OPCODE_SWCZ (`OPCODE_W'b111000)
`define OPCODE_BC1T (`OPCODE_W'b010011)
`define OPCODE_BC1F (`OPCODE_W'b010101)
`define OPCODE_FLUI (`OPCODE_W'b111100)
`define OPCODE_FORI (`OPCODE_W'b111101)

`define FUNCT_SLL   (`FUNCT_W'b000000)
`define FUNCT_SLLV  (`FUNCT_W'b000100)
`define FUNCT_ADD   (`FUNCT_W'b100000)
`define FUNCT_SUB   (`FUNCT_W'b100010)
`define FUNCT_OR    (`FUNCT_W'b100101)
`define FUNCT_SLT   (`FUNCT_W'b101010)
`define FUNCT_JR    (`FUNCT_W'b001000)
`define FUNCT_JALR  (`FUNCT_W'b001111)
`define FUNCT_DIV10 (`FUNCT_W'b011100)
`define FUNCT_DIV2  (`FUNCT_W'b001100)

`define FUNCT_FNEG  (`FUNCT_W'b010000)
`define FUNCT_FADD  (`FUNCT_W'b000000)
`define FUNCT_FSUB  (`FUNCT_W'b000001)
`define FUNCT_FMUL  (`FUNCT_W'b000010)
`define FUNCT_FDIV  (`FUNCT_W'b000011)
`define FUNCT_FCLT  (`FUNCT_W'b100000)
`define FUNCT_FCZ   (`FUNCT_W'b101000)
`define FUNCT_FMV   (`FUNCT_W'b000110)
`define FUNCT_SQRT_INIT (`FUNCT_W'b110000)
`define FUNCT_FINV_INIT (`FUNCT_W'b111000)

`define FUNCT_WC (`FUNCT_W'b??????) // WILD CARD
`endif
