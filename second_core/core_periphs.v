`default_nettype none

`include "common_params.h"

module core_periphs
  #(parameter ACTUAL_ADDR_W        =32,
    parameter INIT_PROGRAM_COUNTER = 0,
    parameter INIT_POINTER         = 0,
    parameter HIGH_POINTER         =10,
    parameter DEBUG_IGNORE_IN_BUSY =1'b0)
   (
    // BRAM_PORTA
    // データメモリ用
    output wire [ACTUAL_ADDR_W-1:0]  bram_addr_a,
    output wire                      bram_clk_a,
    input  wire [`WORD_W-1:0]        bram_rddata_a,
    output wire [`WORD_W-1:0]        bram_wrdata_a,
    output wire                      bram_en_a,
    output wire                      bram_rst_a,
    output wire                      bram_regce_a,
    output wire                      bram_we_a,

    // BRAM PORT B
    // 命令メモリ用
    output wire [ACTUAL_ADDR_W-1:0]  bram_addr_b,
    output wire                      bram_clk_b,
    input  wire [`WORD_W-1:0]        bram_rddata_b,
    output wire [`WORD_W-1:0]        bram_wrdata_b,
    output wire                      bram_en_b,
    output wire                      bram_we_b,
    output wire                      bram_rst_b,
    output wire                      bram_regce_b,
     
    // BRAM PORT C
    // AXIから入ってきたデータをデータメモリに転送する用
    output wire [ACTUAL_ADDR_W-1:0]  bram_addr_c,
    output wire                      bram_clk_c,
    input  wire [`WORD_W-1:0]        bram_rddata_c,
    output wire [`WORD_W-1:0]        bram_wrdata_c,
    output wire                      bram_en_c,
    output wire                      bram_we_c,
    output wire                      bram_rst_c,
    output wire                      bram_regce_c,

    // AXI4-lite master memory interface
    // address write channel
    output wire                    axi_awvalid,
    input wire                     axi_awready,
    output wire [31:0]             axi_awaddr,
    output wire [2:0]              axi_awprot,
    // data write channel
    output wire                    axi_wvalid,
    input wire                     axi_wready,
    output wire [31:0]             axi_wdata,
    output wire [3:0]              axi_wstrb,
    // response channel
    input wire                     axi_bvalid,
    output wire                    axi_bready,
    input wire [1:0]               axi_bresp,
    // address read channel
    output wire                    axi_arvalid,
    input wire                     axi_arready,
    output wire [31:0]             axi_araddr,
    output wire [2:0]              axi_arprot,
    // read data channel
    input wire                     axi_rvalid,
    output wire                    axi_rready,
    input wire [31:0]              axi_rdata,
    input wire [1:0]               axi_rresp,

    input wire clk,
    input wire rstn);

  wire               out_req;
  wire [`REG_W -1:0] out_data;
  wire               in_busy;
  wire               out_busy;
  wire [`ADDR_W-1:0] pointer;
  wire [`ADDR_W-1:0] pc;
  wire [`ADDR_W-1:0] mem_addr_core;
  wire [`ADDR_W-1:0] mem_addr_io;

  // BRAMに関して.
  // 下位モジュールで操作しないワイヤはここで済ます. 
  assign bram_clk_a     = clk;
  assign bram_clk_b     = clk;
  assign bram_clk_c     = clk;
  assign bram_wrdata_b  =   0;
  assign bram_en_a      =   1;
  assign bram_en_b      =   1;
  assign bram_en_c      =   1;
  assign bram_we_b      =   0;
  assign bram_rst_a     =   0;
  assign bram_rst_b     =   0;
  assign bram_rst_c     =   0;
  assign bram_regce_a   =   0;
  assign bram_regce_b   =   0;
  assign bram_regce_c   =   0;
  assign bram_addr_a    = mem_addr_core[ACTUAL_ADDR_W-1:0];
  assign bram_addr_b    =            pc[ACTUAL_ADDR_W-1:0];
  assign bram_addr_c    = mem_addr_io  [ACTUAL_ADDR_W-1:0];

  core
  #(ACTUAL_ADDR_W,INIT_PROGRAM_COUNTER,INIT_POINTER,HIGH_POINTER) cpu1 (
    .mem_addr     (mem_addr_core),
    .st_data      (bram_wrdata_a),
    .ld_data      (bram_rddata_a),
    .write_enable (bram_we_a),
    .pc           (pc),
    .inst         (bram_rddata_b),

    .out_req      (out_req),
    .out_data     (out_data),
    .in_busy      (in_busy),
    .out_busy     (out_busy),
    .file_pointer (pointer),

    .clk          (clk),
    .rstn         (rstn)
  );

  io_controller
  #(ACTUAL_ADDR_W,INIT_POINTER,HIGH_POINTER,DEBUG_IGNORE_IN_BUSY) io_cont1 (
    .out_req  (out_req),
    .out_data (out_data),
    .out_busy (out_busy),
    .in_busy  ( in_busy),
    .consumer_pointer(pointer),

    .mem_addr     (mem_addr_io),
    .mem_data     (bram_wrdata_c),
    .mem_we       (bram_we_c),

    .axi_awvalid  (axi_awvalid),
    .axi_awready  (axi_awready),
    .axi_awaddr   (axi_awaddr),
    .axi_awprot   (axi_awprot),
    .axi_wvalid   (axi_wvalid),
    .axi_wready   (axi_wready),
    .axi_wdata    (axi_wdata),
    .axi_wstrb    (axi_wstrb),
    .axi_bvalid   (axi_bvalid),
    .axi_bready   (axi_bready),
    .axi_bresp    (axi_bresp),
    .axi_arvalid  (axi_arvalid),
    .axi_arready  (axi_arready),
    .axi_araddr   (axi_araddr),
    .axi_arprot   (axi_arprot),
    .axi_rvalid   (axi_rvalid),
    .axi_rready   (axi_rready),
    .axi_rdata    (axi_rdata),
    .axi_rresp    (axi_rresp),

    .clk          (clk),
    .rstn         (rstn)
  );

endmodule

`default_nettype wire
