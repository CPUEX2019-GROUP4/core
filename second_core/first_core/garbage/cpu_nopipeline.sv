`default_nettype none

// 1モジュールに全てを詰め込む
// pipelineなし
// state machine
module cpu_nopipeline
  #( parameter  IWIDTH = 32, // 命令語調
     parameter  AWIDTH = 32, // アドレスの長さ
     parameter OPWIDTH =  6, // オペコードの長さ
     parameter RGWIDTH = 32, // レジスタの幅
     parameter RAWIDTH =  5, // レジスタアドレスの長さ
     parameter SHWIDTH =  5, // シフト量の長さ
     parameter FNWIDTH =  6, // 機能の長さ
     parameter IMWIDTH = 16, // 即値の長さ
     parameter IDWIDTH = 26, // instr_indexの長さ
     parameter WDWIDTH = 32, // メモリ上の語の長さ
     parameter STATE   =  4, // 状態の桁数(伝われ)
     parameter PHYS_AWIDTH=16)// 外部のメモリが実際に使っているアドレスの幅
   ( input wire [IWIDTH-1:0]           inst,
     output wire[PHYS_AWIDTH-1:0] inst_addr,
  
     input wire [WDWIDTH-1:0]     ld_data,
     output reg [WDWIDTH-1:0]     st_data,
     output reg [PHYS_AWIDTH-1:0]mem_addr, // dual memoryの都合で幅が短い
     output reg              write_enable,

     input wire clk,
     input wire rstn);

// ステートを表現するための変数
reg [STATE-1:0] state;
localparam s_fetch      = 4'b0001;
localparam s_decode     = 4'b0010;
localparam s_execute    = 4'b0100;
localparam s_write_back = 4'b1000;

// プログラムカウンタ
reg [AWIDTH-1:0] pc;
wire[AWIDTH-1:0] pc_plus_4  = pc + 4;

// 命令を分割するための変数
reg [OPWIDTH-1:0] opcode;     // R,I,J
reg [RAWIDTH-1:0] rd;         // R,I
reg [RAWIDTH-1:0] rs;         // R,I
reg [RAWIDTH-1:0] rt;         // R
reg [SHWIDTH-1:0] shift;      // R
reg [FNWIDTH-1:0] funct;      // R
reg [IMWIDTH-1:0] immediate;  // I
reg [IDWIDTH-1:0] index;      // J

// 命令の形式を明らかにするための変数
reg [3:0] inst_type;
localparam r_type = 3'b0001;
localparam i_type = 3'b0010;
localparam j_type = 3'b0100;
localparam f_type = 4'b1000;

// オペランド
reg [RGWIDTH-1:0] op_s; // rsの中身
reg [RGWIDTH-1:0] op_t; // rtの中身
reg [RGWIDTH-1:0] op_d; // rdの中身

// メモリアドレスレジスタ
reg [AWIDTH-1:0] mem_addr_reg;

// 分岐に関するレジスタ
reg [AWIDTH-1:0] branch_direction; // 分岐先
reg branch_enable;

// レジスタファイルを宣言するドン！！
reg [RGWIDTH-1:0]  register [31:0]; // 32bitの汎用レジスタが32個あります
reg [RGWIDTH-1:0] fregister [31:0]; // 32bitの浮動小数点レジスタ32個
localparam r_zero =  0; // $0はゼロレジスタ 
localparam r_link = 31; // $31はリンクレジスタ

integer i; // for文を回すための変数

assign inst_addr = pc[15:0];

always @(posedge clk) begin

  if (~rstn) begin // リセット
    state           <= s_fetch;
    pc              <= 0;
    opcode          <= 0;
    rs              <= 0;
    rt              <= 0;
    rd              <= 0;
    shift           <= 0;
    funct           <= 0;
    immediate       <= 0;
    index           <= 0;
    inst_type       <= 0;
    op_s            <= 0;
    op_t            <= 0;
    op_d            <= 0;
    mem_addr_reg    <= 0;
    branch_direction<= 0;
    branch_enable   <= 0;
    for(i = 0; i < 32; i = i + 1) begin
      register[i]   <= 0;
      fregister[i]  <= 0;
    end
  end else begin 
    // 一応ゼロにしておいたほうがいいものをゼロにしておく
    write_enable   <= 0;

    /****************************************************
     *
     *        ここからステートマシンの動き
     *
     ****************************************************/
    case ( state )
      /*******************
      *   FETCH PHASE    *
      *******************/
      s_fetch:
      begin
        opcode    <= inst[32-1:32-6]; // R,I,J
        rd        <= inst[26-1:26-5]; // R,I
        rs        <= inst[21-1:21-5]; // R,I
        rt        <= inst[16-1:16-5]; // R
        shift     <= inst[11-1:11-5]; // R
        funct     <= inst[ 6-1:   0]; // R
        immediate <= inst[16-1:   0]; // I
        index     <= inst[26-1:   0]; // J
        state     <= s_decode;
      end

      /*******************
       *  DECODE PHASE   *
       *******************/
      s_decode:
      begin
        case ( opcode )
          6'b000000: inst_type <= r_type; // R
          6'b000010: inst_type <= j_type; // J, Jump
          6'b000011: inst_type <= j_type; // J, Jump and Link
          default  : inst_type <= i_type; // I
        endcase
        op_s          <= register[rs];
        op_t          <= register[rt];
        op_d          <= register[rd];
        mem_addr_reg  <= register[rs][15:0] + immediate[15:0];
        state         <= s_execute;
      end

      /*******************
      *  EXECUTE PHASE   *
      *******************/
      s_execute:
      begin
        // ゼロにしておいたほうがいいものをゼロにしておく
        branch_enable <= 0;

        // 命令形式に応じて挙動を変える
        case ( inst_type )
          r_type:
          begin
            case ( funct )
              6'b000000:op_d<=        op_s <<        funct ;   // sll
              6'b000010:op_d<=        op_s >>        funct ;   // srl
              6'b000011:op_d<=        op_s >>>       funct ;   // sra
              6'b000100:op_d<=        op_s <<         op_t ;   // sllv
              6'b001000:                                       // jr
              begin
                branch_enable    <= 1;
                branch_direction <= op_d;
              end
              6'b100000:op_d<=$signed(op_s) + $signed(op_t);   // add
              6'b100001:op_d<=        op_s  +         op_t ;   // addu
              6'b100010:op_d<=$signed(op_s) - $signed(op_t);   // sub
              6'b100011:op_d<=        op_s  -         op_t ;   // subu
              6'b100100:op_d<=        op_s  &         op_t ;   // and
              6'b100101:op_d<=        op_s  |         op_t ;   // or
              6'b100110:op_d<=        op_s  ^         op_t ;   // xor
              6'b100111:op_d<=~(      op_s  |         op_t);   // nor
              6'b101010:op_d<=$signed(op_s)<$signed(op_t)? 1:0;// slt
              default:
              begin
                // do nothing
              end
            endcase
          end
          i_type:
          begin
            case ( opcode )
              6'b000100: // beq
              begin
                branch_enable    <= (op_d == op_s) ? 1:0;
                branch_direction <= $signed({1'b0,pc})+$signed({immediate,2'b00})+4;
                // pcが正の値であることを明示するため、pcにbit 0を加えている
              end
              6'b000101: // bne
              begin
                branch_enable    <= (op_d == op_s) ? 0:1;
                branch_direction <= $signed({1'b0,pc})+$signed({immediate,2'b00})+4;
                // pcが正の値であることを明示するため、pcにbit 0を加えている
              end

              6'b001000:op_d<=$signed(op_s) + $signed(immediate);   // addi $d $s C
              6'b011000:op_d<=$signed(op_s) - $signed(immediate);   // subi オリジナル
              6'b001111:op_d<={immediate, 16'd0};                   // lui  $d C
              6'b001100:op_d<=op_s & {16'd0, immediate};            // andi $d $s C
              6'b001101:op_d<=op_s | {16'd0, immediate};            // ori  $d $s C
              6'b001010:op_d<=$signed(op_s)<$signed(immediate)? 1:0;// slti
              6'b100011: // load word
              begin
                mem_addr     <= mem_addr_reg;
                op_d         <= ld_data;
              end
              6'b101011: // store word
              begin
                mem_addr     <= mem_addr_reg;
                st_data      <= op_d;
                write_enable <= 1;
              end 

              default:
              begin
                // do nothing
              end
            endcase
          end
          j_type:
          begin
            case ( opcode )
              6'b000010: // j C
              begin
                branch_enable    <= 1;
                branch_direction <= {pc_plus_4[31:28],28'd0}+{index,2'b00};
              end
              6'b000011: // jal C
              begin
                branch_enable    <= 1;
                branch_direction <= {pc_plus_4[31:28],28'd0}+{index,2'b00};
                register[r_link]   <= pc + 4;
              end
              default:
              begin
                // do nothing
              end
            endcase
          end
          default:
          begin
            // do nothing
          end
        endcase
        state <= s_write_back;
      end

      /*******************
      * WRITE BACK PHASE *
      *******************/
      s_write_back:
      begin
        register[rd] <= op_d;
        state        <= s_fetch;
        pc           <= branch_enable == 1 ? branch_direction : (pc + 1);
      end

      // 一応defaultも用意
      default:
      begin
        state <= s_fetch;
      end
    endcase
  end
end
endmodule

`default_nettype wire
