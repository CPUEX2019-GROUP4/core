`default_nettype none
`include "common_params.h"

module cpu_for_bram
  #(
     parameter ACTUAL_ADDR_W=32)// 外部のメモリが実際に使っているアドレスの幅
   (
     // BRAM PORT A
     output wire                      bram_clk_a,
     output reg  [ACTUAL_ADDR_W-1:0]  bram_addr_a,
     output reg  [`WORD_W-1:0]        bram_wrdata_a,
     input  wire [`WORD_W-1:0]        bram_rddata_a,
     output reg                       bram_en_a,
     output reg                       bram_we_a,
     output reg                       bram_rst_a,
     output reg                       bram_regce_a,

     // BRAM PORT B
     output wire                      bram_clk_b,
     output reg  [ACTUAL_ADDR_W-1:0]  bram_addr_b,
     output reg  [`WORD_W-1:0]        bram_wrdata_b,
     input  wire [`WORD_W-1:0]        bram_rddata_b,
     output reg                       bram_en_b,
     output reg                       bram_we_b,
     output reg                       bram_rst_b,
     output reg                       bram_regce_b,

     // I/O via AXI4
     // AXI4-lite master memory interface
     // address write channel
     output reg             axi_awvalid,
     input wire             axi_awready,
     output reg [31:0]      axi_awaddr,
     output reg [2:0]       axi_awprot,
     // data write channel
     output reg             axi_wvalid,
     input wire             axi_wready,
     output reg [31:0]      axi_wdata,
     output reg [3:0]       axi_wstrb,
     // response channel
     input wire             axi_bvalid,
     output reg             axi_bready,
     input wire [1:0]       axi_bresp,
     // address read channel
     output reg             axi_arvalid,
     input wire             axi_arready,
     output reg [31:0]      axi_araddr,
     output reg [2:0]       axi_arprot,
     // read data channel
     input wire             axi_rvalid,
     output reg             axi_rready,
     input wire [31:0]      axi_rdata,
     input wire [1:0]       axi_rresp,

     input wire clk,
     input wire rstn);

  /*********************************************
  *                                            
  *     ワイヤとかレジスタとか宣言するとこ
  *
  *********************************************/
  // ステートを表現するための変数
  reg [3:0] state;
  localparam s_wait       = 4'b0001;
  localparam s_fetch      = 4'b0010;
  localparam s_decode     = 4'b0011;
  localparam s_execute    = 4'b0100;
  localparam s_mem_access = 4'b0101;
  localparam s_write_back = 4'b0110;
  localparam s_io_begin   = 4'b0111;
  localparam s_io_end     = 4'b1000;

  // 命令. BRAMのワイヤに assign される.
  wire[`INST_W-1:0] inst;

  // プログラムカウンタ. BRAMのワイヤに assign される.
  reg [`ADDR_W-1:0] pc;

  // ファイルポインタ
  // IN命令を標準入力に見立てる.
  reg [`ADDR_W-1:0] file_pointer;
  localparam stdin_offset_addr = `ADDR_W'd100;

  // メモリアクセス用. BRAMのワイヤにassign.
  wire [`WORD_W-1:0] ld_data;
  reg  [`WORD_W-1:0] st_data;
  reg  [`ADDR_W-1:0] mem_addr;
  reg                write_enable;

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
  wire                      exec_be;

  // EMレジスタ
  reg  [`ADDR_W       -1:0] em_pc;
  reg  [`OPCODE_W-1     :0] em_opcode;
  reg  [`REG_ADDR_W-1   :0] em_rs_addr;
  reg  [`REG_ADDR_W-1   :0] em_rt_addr;
  reg  [`REG_ADDR_W-1   :0] em_rd_addr;
  reg  [`REG_W-1        :0] em_op_d;
  reg  [`ADDR_W-1       :0] em_bd;
  reg                       em_be;

  // MWレジスタ
  reg  [`ADDR_W       -1:0] mw_pc;
  reg  [`OPCODE_W-1     :0] mw_opcode;
  reg  [`REG_ADDR_W-1   :0] mw_rs_addr;
  reg  [`REG_ADDR_W-1   :0] mw_rt_addr;
  reg  [`REG_ADDR_W-1   :0] mw_rd_addr;
  reg  [`REG_W-1        :0] mw_op_d;
  reg  [`ADDR_W-1       :0] mw_bd;
  reg                       mw_be;

  // I/O phaseのモジュールと接続するためのワイヤ
  reg                 io_out_req;
  reg  [`REG_W-1:0]   io_out_data;
  wire                io_out_busy;
  reg                 io_in_req;
  wire [`REG_W-1:0]   io_in_data;
  wire                io_in_ready;
  wire                io_in_busy;

  // レジスタファイル
  reg [`REG_W-1:0]  register [(2**`REG_ADDR_W)-1:0];
  reg [`REG_W-1:0] fregister [(2**`REG_ADDR_W)-1:0];

  integer i; // for文を回すための変数

  /*********************************************
  *                                            
  *       下位モジュールを呼び出すとこ
  *
  *********************************************/
  decode_phase dec1
     (fd_inst,dec_inst_type,dec_opcode,dec_rd_addr,dec_rs_addr,dec_rt_addr,
      dec_shift,dec_funct,dec_immediate,dec_index);

  execute_phase exec1
     (pc,de_inst_type,de_opcode,de_shift,de_funct,de_immediate,de_index,
      exec_d, de_op_d, de_op_s, de_op_t,exec_be,exec_bd,exec_link_update);

  io_controller io_cont1
     (io_out_req,io_out_data,io_out_busy,
      io_in_req,io_in_data,io_in_ready,io_in_busy,
      axi_awvalid,axi_awready,axi_awaddr,axi_awprot,
      axi_wvalid,axi_wready,axi_wdata,axi_wstrb,
      axi_bvalid,axi_bready,axi_bresp,
      axi_arvalid,axi_arready,axi_araddr,axi_arprot,
      axi_rvalid,axi_rready,axi_rdata,axi_rresp,
      clk,rstn);

  /*********************************************
  *                                            
  *             assignするとこ
  *
  *********************************************/
  // PORT A is used to access data
  assign bram_clk_a     = clk;
  assign bram_addr_a    = mem_addr;
  assign bram_wrdata_a  = st_data;
  assign ld_data        = bram_rddata_a;
  assign bram_en_a      = 1;
  assign bram_we_a      = write_enable;
  assign bram_rst_a     = 0;
  assign bram_regce_a   = 0;

  // PORT B is used to fetch instructions
  assign bram_clk_b     = clk;
  assign bram_addr_b    = pc[ACTUAL_ADDR_W-1:0];
  assign bram_wrdata_b  = 0;
  assign inst           = bram_rddata_b;
  assign bram_en_b      = 1;
  assign bram_we_b      = 0;
  assign bram_rst_b     = 0;
  assign bram_regce_b   = 0;


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
      de_mem_addr     <= 0;

      em_opcode       <= 0;
      em_rs_addr      <= 0;
      em_rt_addr      <= 0;
      em_rd_addr      <= 0;
      em_op_d         <= 0;
      em_be           <= 0;
      em_bd           <= 0;

      mw_opcode       <= 0;
      mw_rs_addr      <= 0;
      mw_rt_addr      <= 0;
      mw_rd_addr      <= 0;
      mw_op_d         <= 0;
      mw_be           <= 0;
      mw_bd           <= 0;

      for(i = 0; i < (2**`REG_ADDR_W); i = i + 1) begin
        register[i]   <= 0;
        fregister[i]  <= 0;
      end
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
        // write-back phase でpcを更新した後、
        // fetch phase まで1クロック待たないと、
        // bramが追い付かない.
        s_wait: state <= s_fetch;

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
          de_op_s       <= register[dec_rs_addr];
          de_op_t       <= register[dec_rt_addr];
          de_op_d       <= register[dec_rd_addr];
          de_opcode     <= dec_opcode;
          de_shift      <= dec_shift;
          de_funct      <= dec_funct;
          de_immediate  <= dec_immediate;
          de_index      <= dec_index;
          de_inst_type  <= dec_inst_type;
          de_mem_addr   <= $signed(register[dec_rs_addr]) + $signed(dec_immediate);

          state         <= (dec_inst_type==s_type) ? s_io_begin : s_execute;
        end

        /*******************
        *  EXECUTE PHASE   *
        *******************/
        s_execute:
        begin
          // Execute moduleが提供する値を代入.
          em_op_d     <= exec_d;
          em_be       <= exec_be;
          em_bd       <= exec_bd;

          // 後ろのフェーズで使う値をそのまま受け渡す.
          em_opcode   <= de_opcode;
          em_rs_addr  <= de_rs_addr;
          em_rt_addr  <= de_rt_addr;
          em_rd_addr  <= de_rd_addr;

          // ロード命令, ストア命令
          // execute phaseのうちにaddressをセットしないと間に合わない.
          mem_addr      <= de_mem_addr;
          st_data       <= de_op_d;
          write_enable  <= (de_opcode==opcode_sw);

          state       <= s_mem_access;

          if (exec_link_update) begin
            register[31]    <= pc+1;
          end
        end

        /**********************
        * MEMORY ACCESS PHASE *
        **********************/
        s_mem_access:
        begin
          // ロード命令, ストア命令
          // execute phaseでセットしておいた値が
          // ロードされるまでの時間稼ぎフェーズ

          // 1クロックあれば書き込みは終わっているはず.
          write_enable  <= 0;

          // ここでは使わないけど後で必要な情報を受け渡し.
          mw_opcode     <= em_opcode;
          mw_op_d       <= em_op_d;
          mw_rs_addr    <= em_rs_addr;
          mw_rt_addr    <= em_rt_addr;
          mw_rd_addr    <= em_rd_addr;
          mw_be         <= em_be;
          mw_bd         <= em_bd;
          
          state         <= s_write_back;
        end

        /*******************
        * WRITE BACK PHASE *
        *******************/
        s_write_back:
        begin
          register[mw_rd_addr]  <= (mw_opcode==opcode_lw) ? ld_data : mw_op_d;
          pc                    <= (mw_be) ? mw_bd : (pc+1);

          state                 <= s_wait;
        end

        s_io_begin:
        begin
          mw_be <= 0;
          case (de_opcode)
            opcode_in: begin
              if (~io_in_busy) begin
                io_in_req <= 1;
                state     <= s_io_end;
              end
            end
            opcode_out: begin
              if (~io_out_busy) begin
                io_out_req  <= 1;
                io_out_data <= $signed(de_op_d)+$signed(de_immediate);
                state       <= s_io_end;
              end
            end
            default  : begin
              state       <= s_wait;
            end
          endcase
        end

        s_io_end:
        begin
          io_in_req  <= 0;
          io_out_req <= 0;
          case (de_opcode)
            opcode_in: begin
              if (io_in_ready) begin
                mw_op_d   <= io_in_data;
                state     <= s_write_back;
              end
            end
            opcode_out: begin
              state       <= s_write_back;
            end
            default  : begin
              state       <= s_wait;
            end
          endcase
        end
      endcase
    end
  end
endmodule

`default_nettype wire
