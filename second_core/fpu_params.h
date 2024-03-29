`ifndef FPU_PARAMS_H
`define FPU_PARAMS_H

`define FPU_OP_WIDTH 6

`define FPU_OPFNEG      (`FPU_OP_WIDTH'b010000)
`define FPU_OPFABS      (`FPU_OP_WIDTH'b000101)
`define FPU_OPFADD      (`FPU_OP_WIDTH'b000000)
`define FPU_OPFSUB      (`FPU_OP_WIDTH'b000001)
`define FPU_OPFMUL      (`FPU_OP_WIDTH'b000010)
`define FPU_OPFINV      (`FPU_OP_WIDTH'b000100)
`define FPU_OPFCLT      (`FPU_OP_WIDTH'b100000)
`define FPU_OPFCZ       (`FPU_OP_WIDTH'b101000)
`define FPU_OPFTOI      (`FPU_OP_WIDTH'b111000)
`define FPU_OPITOF      (`FPU_OP_WIDTH'b111001)
`define FPU_OPSQRT_INIT (`FPU_OP_WIDTH'b110000)
`define FPU_OPFINV_INIT (`FPU_OP_WIDTH'b110001)
`define FPU_OPSQRT_INV_INIT (`FPU_OP_WIDTH'b110010)
`define FPU_OPFMV       (`FPU_OP_WIDTH'b000110)
`define FPU_OPFORI      (`FPU_OP_WIDTH'b111101)
`define FPU_OPFOR       (`FPU_OP_WIDTH'b111101)
`define FPU_OPSET       (`FPU_OP_WIDTH'b111110)
`define FPU_OPGET       (`FPU_OP_WIDTH'b111111)

`define FPU_REG_ADDR_WIDTH 5
`define FPU_REG_COUNT (2 ** `FPU_REG_ADDR_WIDTH)

`endif
