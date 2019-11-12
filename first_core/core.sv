`default_nettype none
`include "common_params.h"

module core
  #(parameter ACTUAL_ADDR_W         = 32,
    parameter INIT_PROGRAM_COUNTER  =  0,
    parameter INIT_POINTER          =  0,
    parameter HIGH_POINTER          = 10)
   (
    output reg  [ACTUAL_ADDR_W-1:0]  mem_addr_for_output,
    output reg  [`WORD_W-1:0]        st_data,
    input  wire [`WORD_W-1:0]        ld_data,
    output reg                       write_enable,

    output reg  [ACTUAL_ADDR_W-1:0]  pc_for_output,
    input  wire [`WORD_W-1:0]        inst,

    output reg                       out_req,
    output reg [`REG_W-1:0]          out_data,

    input wire                       in_busy,
    input wire                       out_busy,

    output reg [`ADDR_W-1:0]         file_pointer,

    input wire clk,
    input wire rstn);

  /*********************************************
  *                                            
  *     ワイヤとかレジスタとか宣言するとこ
  *
  *********************************************/
  // ステートを表現するための変数
  reg [2:0] state;
  localparam s_wait       = 4'd1;
  localparam s_fetch      = 4'd2;
  localparam s_decode     = 4'd3;
  localparam s_execute    = 4'd4;
  localparam s_mem_access = 4'd5;
  localparam s_write_back = 4'd6;

  reg  [`ADDR_W       -1:0] pc;
  reg  [`ADDR_W       -1:0] mem_addr;

  // FDレジスタ
  reg  [`ADDR_W       -1:0] fd_pc;
  reg  [`INST_W       -1:0] fd_inst;

  // Decode phaseのモジュールと接続するためのワイヤ
  wire [`OPCODE_W-1     :0] dec_opcode;
  wire [`REG_ADDR_W-1   :0] dec_rd_addr;
  wire [`REG_ADDR_W-1   :0] dec_rs_addr;
  wire [`REG_ADDR_W-1   :0] dec_rt_addr;
  wire [`SHIFT_W-1      :0] dec_shift;
  wire [`FUNCT_W-1      :0] dec_funct;
  wire [`IMMEDIATE_W-1  :0] dec_immediate;
  wire [`INDEX_W-1      :0] dec_index;
  wire [`NUM_INST_TYPE-1:0] dec_inst_type;
  wire                      dec_d_from_gpr;
  wire                      dec_d_from_fpr;
  wire                      dec_d_to_gpr;
  wire                      dec_d_to_fpr;
  wire                      dec_s_from_gpr;
  wire                      dec_s_from_fpr;
  wire                      dec_t_from_gpr;
  wire                      dec_t_from_fpr;

  // DEレジスタ
  reg  [`ADDR_W       -1:0] de_pc;
  reg  [`OPCODE_W     -1:0] de_opcode;
  reg  [`REG_ADDR_W   -1:0] de_rs_addr;
  reg  [`REG_ADDR_W   -1:0] de_rt_addr;
  reg  [`REG_ADDR_W   -1:0] de_rd_addr;
  reg  [`REG_W        -1:0] de_op_s;
  reg  [`REG_W        -1:0] de_op_t;
  reg  [`REG_W        -1:0] de_op_d;
  reg  [`SHIFT_W      -1:0] de_shift;
  reg  [`FUNCT_W      -1:0] de_funct;
  reg  [`IMMEDIATE_W  -1:0] de_immediate;
  reg  [`INDEX_W      -1:0] de_index;
  reg  [`ADDR_W       -1:0] de_mem_addr;
  reg  [`NUM_INST_TYPE-1:0] de_inst_type;

  // Execute phaseのモジュールと接続するためのワイヤ
  wire [`REG_W        -1:0] exec_d;
  wire [`ADDR_W       -1:0] exec_bd;
  wire                      exec_link_update;
  wire                      exec_fp_update;
  wire                      exec_be;
  wire [`ADDR_W       -1:0] exec_mem_addr;
  wire [`ADDR_W       -1:0] exec_st_data;
  wire                      exec_we;
  wire                      exec_out_req;
  wire [`REG_W        -1:0] exec_out_data;
  wire                      exec_fcond;
  wire                      exec_fcond_update;

  // EMレジスタ
  reg  [`ADDR_W       -1:0] em_pc;
  reg  [`OPCODE_W-1     :0] em_opcode;
  reg  [`FUNCT_W-1      :0] em_funct;
  reg  [`REG_ADDR_W-1   :0] em_rs_addr;
  reg  [`REG_ADDR_W-1   :0] em_rt_addr;
  reg  [`REG_ADDR_W-1   :0] em_rd_addr;
  reg  [`REG_W-1        :0] em_op_d;
  reg  [`ADDR_W-1       :0] em_bd;
  reg                       em_be;
  reg  [`NUM_INST_TYPE-1:0] em_inst_type;

  // MWレジスタ
  reg  [`ADDR_W       -1:0] mw_pc;
  reg  [`OPCODE_W-1     :0] mw_opcode;
  reg  [`FUNCT_W-1      :0] mw_funct;
  reg  [`REG_ADDR_W-1   :0] mw_rs_addr;
  reg  [`REG_ADDR_W-1   :0] mw_rt_addr;
  reg  [`REG_ADDR_W-1   :0] mw_rd_addr;
  reg  [`REG_W-1        :0] mw_op_d;
  reg  [`ADDR_W-1       :0] mw_bd;
  reg                       mw_be;
  reg  [`NUM_INST_TYPE-1:0] mw_inst_type;

  // Write back phaseのモジュールと接続するためのワイヤ
  reg  [`ADDR_W       -1:0] wb_pc;
  reg  [`REG_W        -1:0] wb_op_d;
  reg                       wb_gpr_update;
  reg                       wb_fpr_update;

  // レジスタファイル
  reg [`REG_W-1:0] gpr [(2**`REG_ADDR_W)-1:0];
  reg [`REG_W-1:0] fpr [(2**`REG_ADDR_W)-1:0];
  reg              fpu_cond_reg;
  reg [(2**`REG_ADDR_W)-1:0] gpr_read, gpr_write;
  reg [(2**`REG_ADDR_W)-1:0] fpr_read, fpr_write;

  integer i; // for文を回すための変数

  /*********************************************
  *                                            
  *       下位モジュールを呼び出すとこ
  *
  *********************************************/

  decode_phase dec1
  (.inst      (fd_inst),
   .inst_type (dec_inst_type),
   .opcode    (dec_opcode),
   .rd_addr   (dec_rd_addr),
   .rs_addr   (dec_rs_addr),
   .rt_addr   (dec_rt_addr),
   .shift     (dec_shift),
   .funct     (dec_funct),
   .immediate (dec_immediate),
   .index     (dec_index),
   .d_from_gpr(dec_d_from_gpr),
   .d_from_fpr(dec_d_from_fpr),
   .d_to_gpr  (dec_d_to_gpr),
   .d_to_fpr  (dec_d_to_fpr),
   .s_from_gpr(dec_s_from_gpr),
   .s_from_fpr(dec_s_from_fpr),
   .t_from_gpr(dec_t_from_gpr),
   .t_from_fpr(dec_t_from_fpr));

  execute_phase exec1
  (.pc          (pc),
   .in_busy     (in_busy),
   .file_pointer(file_pointer),
   .fcond_as_src(fpu_cond_reg),
   .inst_type   (de_inst_type),
   .opcode      (de_opcode),
   .shift       (de_shift),
   .funct       (de_funct),
   .immediate   (de_immediate),
   .index       (de_index),
   .op_d_as_src (de_op_d),
   .op_s        (de_op_s),
   .op_t        (de_op_t),
   .op_d        (exec_d),
   .be          (exec_be),
   .bd          (exec_bd),
   .link_update (exec_link_update),
   .fp_update   (exec_fp_update),
   .mem_addr    (exec_mem_addr),
   .st_data     (exec_st_data),
   .we          (exec_we),
   .out_req     (exec_out_req),
   .out_data    (exec_out_data),
   .fcond       (exec_fcond),
   .fcond_update(exec_fcond_update));
 
  write_back_phase write_back1
  (.pc          (pc),
   .ld_data     (ld_data),
   .opcode      (mw_opcode),
   .funct       (mw_funct),
   .bd          (mw_bd),
   .be          (mw_be),
   .op_d        (mw_op_d),
   .inst_type   (mw_inst_type),
   .new_pc      (wb_pc),
   .new_op_d    (wb_op_d),
   .gpr_update  (wb_gpr_update),
   .fpr_update  (wb_fpr_update));

  /*********************************************
  *                                            
  *             assignするとこ
  *
  *********************************************/

  assign pc_for_output = pc[ACTUAL_ADDR_W-1:0];
  assign mem_addr_for_output = mem_addr[ACTUAL_ADDR_W-1:0];

  /*********************************************
  *                                            
  *         順序回路を記述するとこ
  *
  *********************************************/
  always @(posedge clk) begin

    if (~rstn) begin // リセット
      state           <= s_wait;
      pc              <= 0;

      st_data         <= 0;
      mem_addr        <= 0;
      write_enable    <= 0;

      out_req         <= 0;
      out_data        <= 0;

      de_rs_addr      <= 0;
      de_rt_addr      <= 0;
      de_rd_addr      <= 0;
      de_op_s         <= 0;
      de_op_t         <= 0;
      de_op_d         <= 0;
      de_opcode       <= 0;
      de_shift        <= 0;
      de_funct        <= 0;
      de_immediate    <= 0;
      de_index        <= 0;
      de_inst_type    <= 0;

      em_opcode       <= 0;
      em_funct        <= 0;
      em_rs_addr      <= 0;
      em_rt_addr      <= 0;
      em_rd_addr      <= 0;
      em_op_d         <= 0;
      em_be           <= 0;
      em_bd           <= 0;
      em_inst_type    <= 0;

      mw_opcode       <= 0;
      mw_funct        <= 0;
      mw_rs_addr      <= 0;
      mw_rt_addr      <= 0;
      mw_rd_addr      <= 0;
      mw_op_d         <= 0;
      mw_be           <= 0;
      mw_bd           <= 0;
      mw_inst_type    <= 0;

      file_pointer    <= INIT_POINTER;

      for(i = 0; i < (2**`REG_ADDR_W); i = i+1) begin
        gpr[i] <= 0;
        fpr[i] <= 0;
      end
      fpu_cond_reg    <= 0;

      gpr_read        <= 0;
      gpr_write       <= 0;
      fpr_read        <= 0;
      fpr_write       <= 0;
    end else begin 
      /****************************************************
      *
      *        ここからステートマシンの動き
      *
      ****************************************************/
      (* full_case *)
      case ( state )
        /*******************
        *   WAIT PHASE     *
        *******************/
        // fetch phase まで1クロック待たないと、bramが追い付かない.
        s_wait:
        begin
          state <= s_fetch;
        end
        /*******************
        *   FETCH PHASE    *
        *******************/
        s_fetch:
        begin
          // fetchした命令をFDレジスタに入れておく.
          fd_inst <= inst;
          state   <= s_decode;
        end
        /******************
        *  DECODE PHASE   *
        ******************/
        s_decode:
        begin
          // decodeした結果をDEレジスタにぶち込む.
          de_rd_addr    <= dec_rd_addr;
          de_rs_addr    <= dec_rs_addr;
          de_rt_addr    <= dec_rt_addr;
          de_opcode     <= dec_opcode;
          de_shift      <= dec_shift;
          de_funct      <= dec_funct;
          de_immediate  <= dec_immediate;
          de_index      <= dec_index;
          de_inst_type  <= dec_inst_type;
          de_op_d       <=(dec_d_from_gpr) ? gpr[dec_rd_addr] :
                          (dec_d_from_fpr) ? fpr[dec_rd_addr] : 0;
          de_op_s       <=(dec_s_from_gpr) ? gpr[dec_rs_addr] :
                          (dec_s_from_fpr) ? fpr[dec_rs_addr] : 0;
          de_op_t       <=(dec_t_from_gpr) ? gpr[dec_rt_addr] :
                          (dec_t_from_fpr) ? fpr[dec_rt_addr] : 0;

          state         <= s_execute;
        end
        /*******************
        *  EXECUTE PHASE   *
        *******************/
        s_execute:
        begin
          // Executeで計算した結果をEMレジスタにぶち込む.
          em_op_d     <= exec_d;
          em_be       <= exec_be;
          em_bd       <= exec_bd;

          // Executeで計算した結果をメモリ関係のワイヤにぶち込む.
          st_data     <= exec_st_data;
          write_enable<= exec_we;
          mem_addr    <= exec_mem_addr;
          out_req     <= exec_out_req;
          out_data    <= exec_out_data;

          // リンクレジスタ, コンディションレジスタ, ファイルポインタの更新
          gpr[31]     <=(exec_link_update) ? pc+1          :gpr[31];
          fpu_cond_reg<=(exec_fcond_update)? exec_fcond    :fpu_cond_reg;
          file_pointer<=(exec_fp_update)   ? file_pointer+1:file_pointer;

          // 後ろのフェーズで使う値をそのまま受け渡す.
          em_opcode   <= de_opcode;
          em_funct    <= de_funct;
          em_rs_addr  <= de_rs_addr;
          em_rt_addr  <= de_rt_addr;
          em_rd_addr  <= de_rd_addr;
          em_inst_type<= de_inst_type;

          // [{(opcode=IN)⇒(~in_busy)}∧{(opcode=OUT)⇒(~out_busy)}]
          // と同値であることに注意.
          if ((de_opcode!=`OPCODE_ININT ||(~ in_busy)) &&
              (de_opcode!=`OPCODE_INFLT ||(~ in_busy)) &&
              (de_opcode!=`OPCODE_OUT   ||(~out_busy)))
          begin
            state     <= s_mem_access;
          end
        end
        /**********************
        * MEMORY ACCESS PHASE *
        **********************/
        s_mem_access:
        begin
          write_enable  <= 0;
          out_req       <= 0;

          // 後ろのフェーズで使う値をそのまま受け渡す.
          mw_opcode     <= em_opcode;
          mw_funct      <= em_funct;
          mw_op_d       <= em_op_d;
          mw_rs_addr    <= em_rs_addr;
          mw_rt_addr    <= em_rt_addr;
          mw_rd_addr    <= em_rd_addr;
          mw_be         <= em_be;
          mw_bd         <= em_bd;
          mw_inst_type  <= em_inst_type;
          
          state         <= s_write_back;
        end
        /*******************
        * WRITE BACK PHASE *
        *******************/
        s_write_back:
        begin
          pc              <= wb_pc;
          gpr[mw_rd_addr] <=(wb_gpr_update) ? wb_op_d : gpr[mw_rd_addr];
          fpr[mw_rd_addr] <=(wb_fpr_update) ? wb_op_d : fpr[mw_rd_addr];

          state           <= s_wait;
        end
      endcase
    end
  end
endmodule

`default_nettype wire
