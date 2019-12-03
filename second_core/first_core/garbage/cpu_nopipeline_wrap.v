`default_nettype none

module cpu_nopipeline_wrapper
  #( parameter  IWIDTH = 32, // 命令語調
     parameter  AWIDTH = 32, // 命令アドレスの長さ
     parameter OPWIDTH =  6, // オペコードの長さ
     parameter RGWIDTH = 32, // レジスタの幅
     parameter RAWIDTH =  5, // レジスタアドレスの長さ
     parameter SHWIDTH =  5, // シフト量の長さ
     parameter FNWIDTH =  6, // 機能の長さ
     parameter IMWIDTH = 16, // 即値の長さ
     parameter IDWIDTH = 26, // instr indexの長さ
     parameter WDWIDTH = 32, // メモリ上の語の長さ
     parameter STATE   =  4  // ステートの数
   )
   ( 
     input wire [IWIDTH-1:0]  inst_wrap,
     output wire[16-1:0] inst_addr,

     input wire [WDWIDTH-1:0] ld_data,
     output wire[WDWIDTH-1:0] st_data,
     output wire[16-1:0]     mem_addr,
     output wire         write_enable,

     input wire clk,
     input wire rstn);

cpu_nopipeline u1 (inst_wrap,inst_addr,ld_data,st_data,mem_addr,write_enable,clk,rstn);

endmodule

`default_nettype wire
