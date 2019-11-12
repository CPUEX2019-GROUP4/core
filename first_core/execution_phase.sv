`default_nettype none
`include "common_params.h"

/*******************
*  execute phase   *
*******************/

// execute phase のメインモジュール.
// execute_r, i, jを統括する.
module execute_phase
   (
    input wire [`ADDR_W       -1:0] pc,
    input wire [`NUM_INST_TYPE-1:0] inst_type,
    input wire [`OPCODE_W     -1:0] opcode,
    input wire [`SHIFT_W      -1:0] shift,
    input wire [`FUNCT_W      -1:0] funct,
    input wire [`IMMEDIATE_W  -1:0] immediate,
    input wire [`INDEX_W      -1:0] index,
    output reg [`REG_W        -1:0] op_d,
    input wire [`REG_W        -1:0] op_d_as_src,
    input wire [`REG_W        -1:0] op_s,
    input wire [`REG_W        -1:0] op_t,
    output reg                      be, // branch enable
    output reg [`ADDR_W       -1:0] bd, // branch direction
    output reg                      link_update,
    input wire [`ADDR_W       -1:0] file_pointer,
    output reg                      fp_update,
    output reg [`ADDR_W       -1:0] mem_addr,
    output reg [`WORD_W       -1:0] st_data,
    output reg                      we,
    input wire                      in_busy,
    output reg                      out_req,
    output reg [`REG_W        -1:0] out_data,
    output reg                      fcond,
    input wire                      fcond_as_src,
    output reg                      fcond_update
   );

  wire [`REG_W -1:0]  r_op_d;
  wire [`REG_W -1:0]  i_op_d;
  wire [`REG_W -1:0] fr_op_d;
  wire [`REG_W -1:0] fi_op_d;
  wire [`ADDR_W-1:0]  r_bd;
  wire [`ADDR_W-1:0]  i_bd;
  wire [`ADDR_W-1:0]  j_bd;
  wire [`ADDR_W-1:0] fi_bd;
  wire                r_be;
  wire                i_be;
  wire                j_be;
  wire               fi_be;
  wire [`ADDR_W-1:0]  i_mem_addr;
  wire [`ADDR_W-1:0] fi_mem_addr;
  wire [`REG_W -1:0]  i_st_data;
  wire [`REG_W -1:0] fi_st_data;
  wire                i_fp_update;
  wire               fi_fp_update;
  wire                i_we;
  wire               fi_we;
  wire                r_link_update;
  wire                j_link_update;

  execute_r exec_r1 (
    .shift      (shift),
    .funct      (funct),
    .op_d_as_src(op_d_as_src),
    .op_s       (op_s),
    .op_t       (op_t),
    .op_d       (r_op_d),
    .be         (r_be),
    .bd         (r_bd),
    .link_update(r_link_update)
  );
  execute_i exec_i1 (
    .opcode     (opcode),
    .immediate  (immediate),
    .op_d_as_src(op_d_as_src),
    .op_s       (op_s),
    .pc         (pc),
    .fp         (file_pointer),
    .in_busy    (in_busy),
    .op_d       (i_op_d),
    .be         (i_be),
    .bd         (i_bd),
    .fp_update  (i_fp_update),
    .mem_addr   (i_mem_addr),
    .st_data    (i_st_data),
    .we         (i_we),
    .out_req    (out_req),
    .out_data   (out_data)
  );
  execute_j exec_j1 (
    .opcode     (opcode),
    .index      (index),
    .pc         (pc),
    .be         (j_be),
    .bd         (j_bd),
    .link_update(j_link_update)
  );
  execute_fr exec_fr1 (
    .funct      (funct),
    .op_d_as_src(op_d_as_src),
    .op_s       (op_s),
    .op_t       (op_t),
    .op_d       (fr_op_d),
    .fcond      (fcond)
  );
  execute_fi exec_fi1 (
    .pc           (pc),
    .opcode       (opcode),
    .op_d_as_src  (op_d_as_src),
    .op_s         (op_s),
    .immediate    (immediate),
    .fcond_as_src (fcond_as_src),
    .fp           (file_pointer),
    .in_busy      (in_busy),
    .op_d         (fi_op_d),
    .be           (fi_be),
    .bd           (fi_bd),
    .fp_update    (fi_fp_update),
    .mem_addr     (fi_mem_addr),
    .st_data      (fi_st_data),
    .we           (fi_we)
  );

  assign op_d = (inst_type== `R_TYPE) ?  r_op_d :
                (inst_type== `I_TYPE) ?  i_op_d :
                (inst_type==`FR_TYPE) ? fr_op_d :
                (inst_type==`FI_TYPE) ? fi_op_d : op_d_as_src;

  // branch enable
  assign be = (inst_type== `R_TYPE) ?  r_be :
              (inst_type== `I_TYPE) ?  i_be :
              (inst_type== `J_TYPE) ?  j_be :
              (inst_type==`FI_TYPE) ? fi_be : 0;
  
  // branch direction
  assign bd = (inst_type==`R_TYPE) ? r_bd :
              (inst_type==`I_TYPE) ? i_bd :
              (inst_type==`J_TYPE) ? j_bd : fi_bd;

  // メモリアクセス関係でI形式とFI形式の選択が必要
  assign mem_addr  =(inst_type==`I_TYPE) ? i_mem_addr : fi_mem_addr;
  assign we        =(inst_type==`I_TYPE) ? i_we       : fi_we;
  assign st_data   =(inst_type==`I_TYPE) ? i_st_data  : fi_st_data;
  assign fp_update =(inst_type==`I_TYPE) ? i_fp_update: fi_fp_update;

  assign fcond_update =
    (inst_type==`FR_TYPE&&
     (funct==`FUNCT_FCLT||funct==`FUNCT_FCZ));

  assign link_update =
    (inst_type==`R_TYPE) ? r_link_update : j_link_update;

endmodule

module execute_r (
  input  wire [`SHIFT_W-1:0] shift,
  input  wire [`FUNCT_W-1:0] funct,
  output wire [`REG_W  -1:0] op_d,
  input  wire [`REG_W  -1:0] op_d_as_src,
  input  wire [`REG_W  -1:0] op_s,
  input  wire [`REG_W  -1:0] op_t,
  output wire                be,
  output wire [`ADDR_W -1:0] bd,
  output reg                 link_update);


  function [`REG_W-1:0] d (
    input [`FUNCT_W-1:0] f,
    input [`SHIFT_W-1:0] sft,
    input [`REG_W  -1:0] s,
    input [`REG_W  -1:0] t
  );
  begin
    case (f)
      `FUNCT_SLL   : d = s << sft;
      `FUNCT_SRL   : d = s >> sft;
      `FUNCT_SRA   : d = s >>>sft;
      `FUNCT_SLLV  : d = s <<   t;
      `FUNCT_ADD   : d = $signed(s)+$signed(t);
      `FUNCT_SUB   : d = $signed(s)-$signed(t);
      `FUNCT_AND   : d = s & t;
      `FUNCT_OR    : d = s | t;
      `FUNCT_SLT   : d = $signed(s)<$signed(t);
      `FUNCT_DIV10 : d = s / 10;
      `FUNCT_DIV2  : d = s >>>1;
      default      : d = op_d_as_src;
    endcase
  end
  endfunction

  assign op_d = d(funct,shift,op_s,op_t);

  assign be =(funct==`FUNCT_JR)|(funct==`FUNCT_JALR);
  assign bd = op_d_as_src;

  assign link_update = (funct==`FUNCT_JALR);

endmodule

module execute_i (
  input wire [`OPCODE_W    -1:0] opcode,
  input wire [`IMMEDIATE_W -1:0] immediate,
  output reg [`REG_W       -1:0] op_d,
  input wire [`REG_W       -1:0] op_d_as_src,
  input wire [`REG_W       -1:0] op_s,
  input wire [`ADDR_W      -1:0] pc,
  output reg                     be,
  output reg [`ADDR_W      -1:0] bd,
  input wire [`ADDR_W      -1:0] fp,
  output reg                     fp_update,
  output reg [`ADDR_W      -1:0] mem_addr,
  output reg [`WORD_W      -1:0] st_data,
  output reg                     we,
  input wire                     in_busy,
  output reg                     out_req,
  output reg [`REG_W       -1:0] out_data
);

  function [`REG_W-1:0] d (
    input [`OPCODE_W   -1:0] op,
    input [`IMMEDIATE_W-1:0] im,
    input [`REG_W      -1:0] s
  );
  begin
    case (op)
      `OPCODE_ADDI:d = $signed(s) + $signed(im);
      `OPCODE_SUBI:d = $signed(s) - $signed(im);
      `OPCODE_SLTI:d = $signed(s) < $signed(im);
      `OPCODE_ANDI:d = s & {16'd0, im};
      `OPCODE_ORI :d = s | {16'd0, im};
      `OPCODE_LUI :d =     {im, 16'd0};
      default     :d = op_d_as_src;
    endcase
  end
  endfunction

  wire [`ADDR_W-1+1:0] extended_bd;
  wire [`ADDR_W-1+1:0] extended_mem_addr;

  // destination registerに入れる値の決定.
  assign op_d = d (opcode,immediate,op_s);

  // branch enableのセット.
  assign be   = ((opcode==`OPCODE_BEQ) & (op_d_as_src==op_s)) |
                ((opcode==`OPCODE_BNE) & (op_d_as_src!=op_s)) ;
  // branch directionのセット.
  assign          bd = extended_bd[`ADDR_W-1:0];
  assign extended_bd = $signed({1'b0,pc})  +$signed(immediate) + 1;

  // mem addrのセット.
  assign          mem_addr = extended_mem_addr[`ADDR_W-1:0];
  assign extended_mem_addr =
    (opcode==`OPCODE_ININT) ?
      {1'b0,fp} : $signed({1'b0,op_s})+$signed(immediate);

  // store dataのセット.
  assign st_data   = op_d_as_src;
  assign      we   =(opcode==`OPCODE_SW);

  assign out_req   =(opcode==`OPCODE_OUT);
  assign out_data  = $signed(op_d_as_src)+$signed(immediate);
  
  assign fp_update =(opcode==`OPCODE_ININT)&(~in_busy);

endmodule

module execute_j (
  input  wire [`OPCODE_W-1:0] opcode,
  input  wire [`INDEX_W -1:0] index,
  input  wire [ `ADDR_W -1:0] pc,
  output reg                  be,
  output reg  [ `ADDR_W -1:0] bd,
  output reg                  link_update);

  wire [`ADDR_W-1:0] addr_next_to_pc = pc + 1;

  assign be = (opcode==`OPCODE_J)|(opcode==`OPCODE_JAL);
  assign bd = {addr_next_to_pc[31:26],index};
  assign link_update = (opcode==`OPCODE_JAL);

endmodule

module execute_fr (
  input wire [`FUNCT_W-1:0] funct,
  output reg [`REG_W  -1:0] op_d,
  input wire [`REG_W  -1:0] op_d_as_src,
  input wire [`REG_W  -1:0] op_s,
  input wire [`REG_W  -1:0] op_t,
  output reg                fcond
);
  
  wire [`REG_W-1:0] fneg_d;
  wire [`REG_W-1:0] fadd_d;
  wire [`REG_W-1:0] fsub_d;
  wire [`REG_W-1:0] fmul_d;
  wire [`REG_W-1:0] fdiv_d;

  wire fclt_cond;
  wire  fcz_cond;

  fneg fneg1 (.x (op_s),          .y(fneg_d));
  fadd fadd1 (.x1(op_s),.x2(op_t),.y(fadd_d));
  fsub fsub1 (.x1(op_s),.x2(op_t),.y(fsub_d));
  fmul fmul1 (.x1(op_s),.x2(op_t),.y(fmul_d));
  fdiv fdiv1 (.x1(op_s),.x2(op_t),.y(fdiv_d));
  fclt fclt1 (.x1(op_s),.x2(op_t),.y(fclt_cond));
  fcz  fcz1  (.x (op_s),          .y( fcz_cond));

  assign op_d =
    (funct==`FUNCT_FNEG) ? fneg_d :
    (funct==`FUNCT_FADD) ? fadd_d :
    (funct==`FUNCT_FSUB) ? fsub_d :
    (funct==`FUNCT_FMUL) ? fmul_d :
    (funct==`FUNCT_FDIV) ? fdiv_d :
    (funct==`FUNCT_FMV)  ? op_s   : op_d_as_src;

  assign fcond = (funct==`FUNCT_FCLT) ? fclt_cond : fcz_cond;

endmodule


module execute_fi (
  input wire [`ADDR_W     -1:0] pc,
  input wire [`OPCODE_W   -1:0] opcode,
  output reg [`REG_W      -1:0] op_d,
  input wire [`REG_W      -1:0] op_d_as_src,
  input wire [`REG_W      -1:0] op_s,
  input wire [`IMMEDIATE_W-1:0] immediate,
  input wire                    fcond_as_src,
  output reg                    be,
  output reg [`ADDR_W     -1:0] bd,
  input wire [`ADDR_W     -1:0] fp,
  output reg                    fp_update,
  output reg [`ADDR_W     -1:0] mem_addr,
  output reg [`WORD_W     -1:0] st_data,
  output reg                    we,
  input wire                    in_busy
);

  wire [`REG_W-1:0] ftoi_d;
  wire [`REG_W-1:0] itof_d;
  
  wire [`ADDR_W-1+1:0] extended_bd;
  wire [`ADDR_W-1+1:0] extended_mem_addr;

  ftoi ftoi1 (.x(op_s), .y(ftoi_d));
  itof itof1 (.x(op_s), .y(itof_d));

  assign op_d =
    (opcode==`OPCODE_FTOI) ? ftoi_d :
    (opcode==`OPCODE_ITOF) ? itof_d :
    (opcode==`OPCODE_FLUI) ? {immediate,16'b0} :
    (opcode==`OPCODE_FORI) ? op_s | immediate     : op_d_as_src;

  assign be =
    (opcode==`OPCODE_BC1T&&fcond_as_src==1) ||
    (opcode==`OPCODE_BC1F&&fcond_as_src==0);

  assign bd          = extended_bd[`ADDR_W-1:0];
  assign extended_bd = $signed({1'b0,pc})+$signed(immediate)+1;

  assign mem_addr          = extended_mem_addr[`ADDR_W-1:0];
  assign extended_mem_addr =
    (opcode==`OPCODE_INFLT) ?
      {1'b0,fp} : $signed({1'b0,op_s})+$signed(immediate);
  
  assign st_data = op_d_as_src;
  assign      we =(opcode==`OPCODE_SWCZ);
  
  assign fp_update =(opcode==`OPCODE_INFLT)&(~in_busy);

endmodule


`default_nettype wire
