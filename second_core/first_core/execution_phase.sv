`default_nettype none
`include "common_params.h"

/*******************
*  execute phase   *
*******************/

// execute phase のメインモジュール.
// execute_r, i, jを統括する.
module execute_phase (
  input  wire [`ADDR_W       -1:0] pc,
  input  wire [`NUM_INST_TYPE-1:0] inst_type,
  input  wire [`OPCODE_W     -1:0] opcode,
  input  wire [`SHIFT_W      -1:0] shift,
  input  wire [`FUNCT_W      -1:0] funct,
  input  wire [`IMMEDIATE_W  -1:0] immediate,
  input  wire [`INDEX_W      -1:0] index,
  output wire [`REG_W        -1:0] op_d,
  input  wire [`REG_W        -1:0] op_d_as_src,
  input  wire [`REG_W        -1:0] op_s,
  input  wire [`REG_W        -1:0] op_t,
  output wire                      be,
  output wire [`ADDR_W       -1:0] bd,
  output wire                      link_update,
  input  wire [`ADDR_W       -1:0] file_pointer,
  output wire                      fp_update,
  output wire [`ADDR_W       -1:0] mem_addr,
  output wire [`WORD_W       -1:0] st_data,
  output wire                      we,
  input  wire                      in_busy,
  output wire                      out_req,
  output wire [`REG_W        -1:0] out_data,
  output wire                      fcond,
  input  wire                      fcond_as_src,
  output wire                      fcond_update
);
  memory_access_control mac1 (
    .opcode       (opcode),
    .op_d_as_src  (op_d_as_src),
    .op_s         (op_s),
    .immediate    (immediate),
    .file_pointer (file_pointer),

    .mem_addr     (mem_addr),
    .st_data      (st_data),
    .we           (we)
  );
  branch_control bc1 (
    .opcode       (opcode),
    .funct        (funct),
    .op_d_as_src  (op_d_as_src),
    .op_s         (op_s),
    .immediate    (immediate),
    .index        (index),
    .fcond_as_src (fcond_as_src),
    .pc           (pc),

    .be           (be),
    .bd           (bd)
  );
  regular_calculation_control rcc1 (
    .inst_type    (inst_type),
    .opcode       (opcode),
    .funct        (funct),
    .op_s         (op_s),
    .op_t         (op_t),
    .immediate    (immediate),
    .shift        (shift),
    
    .op_d         (op_d),
    .fcond        (fcond)
  );
  other_trivial_signals_control otsc1 (
    .opcode       (opcode),
    .funct        (funct),
    .op_d_as_src  (op_d_as_src),
    .immediate    (immediate),
    .in_busy      (in_busy),

    .link_update  (link_update),
    .fcond_update (fcond_update),
    .fp_update    (fp_update),
    .out_req      (out_req),
    .out_data     (out_data)
  );
endmodule

/*************************************************
* Regular Caluculation Control
*
* 主にDestination Registerを書き換える命令を統括
*
*************************************************/
module regular_calculation_control (
  input  wire [`NUM_INST_TYPE  -1:0] inst_type,
  input  wire [`OPCODE_W       -1:0] opcode,
  input  wire [`FUNCT_W        -1:0] funct,
  output wire [`REG_W          -1:0] op_d,
  input  wire [`REG_W          -1:0] op_s,
  input  wire [`REG_W          -1:0] op_t,
  input  wire [`SHIFT_W        -1:0] shift,
  input  wire [`IMMEDIATE_W    -1:0] immediate,
  output wire                        fcond
);

  wire [`REG_W-1:0]  alu_op_d;
  wire [`REG_W-1:0] falu_op_d;
  wire              falu_fcond;
  
  wire [`FUNCT_W-1:0] funct_reformed =
    (opcode==`OPCODE_ADDI) ? `FUNCT_ADD  :
    (opcode==`OPCODE_SLTI) ? `FUNCT_SLT  :
    (opcode==`OPCODE_ORI ) ? `FUNCT_OR   :
    (opcode==`OPCODE_LUI ) ? `FUNCT_SLLV : funct;

  wire [`REG_W-1:0] op_s_reformed =
    (opcode==`OPCODE_LUI ) ? (`REG_W)'(unsigned'(immediate)) :
                             (`REG_W)'(unsigned'(op_s     )) ;

  wire [`REG_W-1:0] op_t_reformed =
    (opcode==`OPCODE_R   ) ? (`REG_W)'(unsigned'(op_t     ))           :
    (opcode==`OPCODE_ADDI) ? (`REG_W)'(  signed'(immediate))           :
    (opcode==`OPCODE_SLTI) ? (`REG_W)'(  signed'(immediate))           :
    (opcode==`OPCODE_LUI ) ? (`REG_W)'(unsigned'(`REG_W-`IMMEDIATE_W)) :
                             (`REG_W)'(unsigned'(immediate))           ;

  /************************
  * ADDI, SLTI, ORI:
  *                       op_t := immediate
  * LUI:
  *     funct := SLLV
  *     op_s  := immediate
  *     op_t  := 16
  *
  ************************/


  alu alu1 (
    .shift(shift),
    .op_d (alu_op_d),
    .op_s ( op_s_reformed),
    .op_t ( op_t_reformed),
    .funct(funct_reformed)
  );
  falu falu1 (
    .opcode   (opcode),
    .funct    (funct),
    .op_d     (falu_op_d),
    .fcond    (falu_fcond),
    .op_s     (op_s),
    .op_t     (op_t),
    .immediate(immediate)
  );
  assign op_d = (inst_type== `R_TYPE) ?  alu_op_d :
                (inst_type== `I_TYPE) ?  alu_op_d :
                (inst_type==`FR_TYPE) ? falu_op_d :
                (inst_type==`FI_TYPE) ? falu_op_d : 0;

  assign fcond= falu_fcond;
endmodule

module falu (
  input  wire [`OPCODE_W   -1:0] opcode,
  input  wire [`FUNCT_W    -1:0] funct,
  output wire [`REG_W      -1:0] op_d,
  output wire                    fcond,
  input  wire [`REG_W      -1:0] op_s,
  input  wire [`REG_W      -1:0] op_t,
  input  wire [`IMMEDIATE_W-1:0] immediate
);
  wire [`REG_W-1:0] fneg_d;
  wire [`REG_W-1:0] fadd_d;
  wire [`REG_W-1:0] fsub_d;
  wire [`REG_W-1:0] fmul_d;
  wire [`REG_W-1:0] fdiv_d;
  wire [`REG_W-1:0] sqrt_init_d;
  wire [`REG_W-1:0] finv_init_d;
  wire [`REG_W-1:0] ftoi_d;
  wire [`REG_W-1:0] itof_d;

  wire fclt_cond, fcz_cond;

  fneg fneg1 (.x (op_s),          .y(fneg_d));
  fadd fadd1 (.x1(op_s),.x2(op_t),.y(fadd_d));
  fsub fsub1 (.x1(op_s),.x2(op_t),.y(fsub_d));
  fmul fmul1 (.x1(op_s),.x2(op_t),.y(fmul_d));
  fdiv fdiv1 (.x1(op_s),.x2(op_t),.y(fdiv_d));
  fclt fclt1 (.x1(op_s),.x2(op_t),.y(fclt_cond));
  fcz  fcz1  (.x (op_s),          .y( fcz_cond));
  sqrt_init sqrt_init1 (.x (op_s),.y(sqrt_init_d));
  finv_init finv_init1 (.x (op_s),.y(finv_init_d));  
  ftoi ftoi1 (.x(op_s), .y(ftoi_d));
  itof itof1 (.x(op_s), .y(itof_d));

  assign op_d =
    (opcode==`OPCODE_FTOI) ? ftoi_d            :
    (opcode==`OPCODE_ITOF) ? itof_d            :
    (opcode==`OPCODE_FLUI) ? {immediate,16'b0}    :
    (opcode==`OPCODE_FORI) ? op_s | {16'b0,immediate}  :
    (opcode==`OPCODE_FR  ) ?((funct==`FUNCT_FNEG)      ? fneg_d      :
                             (funct==`FUNCT_FADD)      ? fadd_d      :
                             (funct==`FUNCT_FSUB)      ? fsub_d      :
                             (funct==`FUNCT_FMUL)      ? fmul_d      :
                             (funct==`FUNCT_FDIV)      ? fdiv_d      :
                             (funct==`FUNCT_FMV )      ?   op_s      :
                             (funct==`FUNCT_SQRT_INIT) ? sqrt_init_d :
                             (funct==`FUNCT_FINV_INIT) ? finv_init_d : 0) : 0;

  assign fcond =(funct==`FUNCT_FCLT) ? fclt_cond : fcz_cond;
endmodule

module alu (
  input  wire [`FUNCT_W-1:0] funct,
  input  wire [`SHIFT_W-1:0] shift,
  output wire [`REG_W  -1:0] op_d,
  input  wire [`REG_W  -1:0] op_s,
  input  wire [`REG_W  -1:0] op_t
);
  assign op_d =
    (funct==`FUNCT_SLL  ) ? unsigned'(op_s) << unsigned'(shift) :
    (funct==`FUNCT_SLLV ) ? unsigned'(op_s) << unsigned'(op_t)  :
    (funct==`FUNCT_ADD  ) ?   signed'(op_s) +    signed'(op_t)  :
    (funct==`FUNCT_SUB  ) ?   signed'(op_s) -    signed'(op_t)  :
    (funct==`FUNCT_OR   ) ? unsigned'(op_s) |  unsigned'(op_t)  :
    (funct==`FUNCT_SLT  ) ?   signed'(op_s) <    signed'(op_t)  :
    (funct==`FUNCT_DIV10) ?   signed'(op_s) /    signed'(  10)  :
    (funct==`FUNCT_DIV2 ) ?   signed'(op_s) /    signed'(   2)  : 0;
endmodule

module memory_access_control (
  input  wire [`OPCODE_W   -1:0] opcode,
  input  wire [`REG_W      -1:0] op_d_as_src,
  input  wire [`REG_W      -1:0] op_s,
  input  wire [`IMMEDIATE_W-1:0] immediate,
  input  wire [`ADDR_W     -1:0] file_pointer,
  output wire [`ADDR_W     -1:0] mem_addr,
  output wire [`WORD_W     -1:0] st_data,
  output wire                    we
);

  wire [`ADDR_W:0] maex = signed'({1'b0,op_s})+(`ADDR_W+1)'(signed'(immediate));

  assign st_data   = op_d_as_src;
  assign mem_addr  =
    (opcode==`OPCODE_ININT) ? file_pointer      :
    (opcode==`OPCODE_INFLT) ? file_pointer      : {1'b0,maex[`ADDR_W:2]} ;
  assign we        =
    (opcode==`OPCODE_SW  ) ? 1 :
    (opcode==`OPCODE_SWCZ) ? 1 :
                             0 ;
endmodule

module branch_control (
  input  wire [`OPCODE_W   -1:0] opcode,
  input  wire [`FUNCT_W    -1:0] funct,
  input  wire [`REG_W      -1:0] op_d_as_src,
  input  wire [`REG_W      -1:0] op_s,
  input  wire [`IMMEDIATE_W-1:0] immediate,
  input  wire [`INDEX_W    -1:0] index,
  input  wire                    fcond_as_src,
  input  wire [`ADDR_W     -1:0] pc,
  output wire                    be,
  output wire [`ADDR_W     -1:0] bd
);
  assign be =
    (opcode==`OPCODE_BEQ ) ? (op_d_as_src==op_s) :
    (opcode==`OPCODE_BNE ) ? (op_d_as_src!=op_s) :
    (opcode==`OPCODE_J   ) ?                  1  :
    (opcode==`OPCODE_JAL ) ?                  1  :
    (opcode==`OPCODE_BC1T) ?        fcond_as_src :
    (opcode==`OPCODE_BC1F) ?       ~fcond_as_src :
    (opcode==`OPCODE_R   ) ?((funct==`FUNCT_JR  ) ? 1 :
                             (funct==`FUNCT_JALR) ? 1 : 0 ) : 0;

  wire [`ADDR_W-1:0] succ_pc = pc + 1;
  wire [`ADDR_W  :0] bdex    = signed'({1'b0,succ_pc})+(`ADDR_W+1)'(signed'(immediate));

  assign bd =
    (opcode==`OPCODE_BEQ ) ? bdex[`ADDR_W-1:0] :
    (opcode==`OPCODE_BNE ) ? bdex[`ADDR_W-1:0] :
    (opcode==`OPCODE_BC1T) ? bdex[`ADDR_W-1:0] :
    (opcode==`OPCODE_BC1F) ? bdex[`ADDR_W-1:0] :
    (opcode==`OPCODE_J   ) ? {succ_pc[`ADDR_W-1:`INDEX_W],index} :
    (opcode==`OPCODE_JAL ) ? {succ_pc[`ADDR_W-1:`INDEX_W],index} :
    (opcode==`OPCODE_R   ) ?((funct==`FUNCT_JR  ) ? op_d_as_src :
                             (funct==`FUNCT_JALR) ? op_d_as_src : 0 ) : 0;
endmodule

module other_trivial_signals_control (
  input  wire [`OPCODE_W   -1:0] opcode,
  input  wire [`FUNCT_W    -1:0] funct,
  input  wire [`REG_W      -1:0] op_d_as_src,
  input  wire [`IMMEDIATE_W-1:0] immediate,
  input  wire                    in_busy,
  output wire                    link_update,
  output wire                    fcond_update,
  output wire                    fp_update,
  output wire                    out_req,
  output wire [`REG_W     -1:0]  out_data
);
  assign link_update =
    (opcode==`OPCODE_R&&funct==`FUNCT_JALR)||(opcode==`OPCODE_JAL);

  assign fcond_update =
    (opcode==`OPCODE_FR&&(funct==`FUNCT_FCLT||funct==`FUNCT_FCZ));

  assign fp_update =
    (opcode==`OPCODE_ININT&&(~in_busy)) ||
    (opcode==`OPCODE_INFLT&&(~in_busy))   ;
  
  assign out_req  =(opcode==`OPCODE_OUT);
  assign out_data = odex[`REG_W-1:0];
  wire [`REG_W:0] odex = signed'({1'b0,op_d_as_src})+(`REG_W+1)'(signed'(immediate));
endmodule

`default_nettype wire
