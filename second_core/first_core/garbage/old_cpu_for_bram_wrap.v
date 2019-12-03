`default_nettype none

`include "common_params.h"
/*
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

`define NUM_INST_TYPE 5

parameter r_type = `NUM_INST_TYPE'b00001;
parameter i_type = `NUM_INST_TYPE'b00010;
parameter j_type = `NUM_INST_TYPE'b00100;
parameter f_type = `NUM_INST_TYPE'b01000;
parameter s_type = `NUM_INST_TYPE'b10000;

parameter opcode_lw   = `OPCODE_W'b100011;
parameter opcode_sw   = `OPCODE_W'b101011;
parameter opcode_in   = `OPCODE_W'b111110;
parameter opcode_out  = `OPCODE_W'b111111;
parameter opcode_addi = `OPCODE_W'b001000;
parameter opcode_slti = `OPCODE_W'b001010;
parameter opcode_andi = `OPCODE_W'b001100;
parameter opcode_ori  = `OPCODE_W'b001101;
parameter opcode_lui  = `OPCODE_W'b001111;
parameter opcode_beq  = `OPCODE_W'b000100;
parameter opcode_bne  = `OPCODE_W'b000101;
parameter opcode_j    = `OPCODE_W'b000010;
parameter opcode_jal  = `OPCODE_W'b000011;

parameter funct_sll   = `FUNCT_W'b000000;
parameter funct_srl   = `FUNCT_W'b000010;
parameter funct_sra   = `FUNCT_W'b000011;
parameter funct_sllv  = `FUNCT_W'b000100;
parameter funct_add   = `FUNCT_W'b100000;
parameter funct_addu  = `FUNCT_W'b100001;
parameter funct_sub   = `FUNCT_W'b100010;
parameter funct_subu  = `FUNCT_W'b100011;
parameter funct_and   = `FUNCT_W'b100100;
parameter funct_or    = `FUNCT_W'b100101;
parameter funct_xor   = `FUNCT_W'b100110;
parameter funct_slt   = `FUNCT_W'b101010;
parameter funct_jr    = `FUNCT_W'b001000;
parameter funct_div10 = `FUNCT_W'b011100;
parameter funct_div2  = `FUNCT_W'b001100;
*/

module cpu_for_bram_wrapper
  #(
    parameter ACTUAL_ADDR_W=32)// 外部のメモリが実際に使っているアドレスの幅
   (
     // BRAM_PORTA
     output wire [ACTUAL_ADDR_W-1:0]  bram_addr_a,
     output wire                      bram_clk_a,
     input  wire [`WORD_W-1:0]        bram_rddata_a,
     output wire [`WORD_W-1:0]        bram_wrdata_a,
     output wire                      bram_en_a,
     output wire                      bram_rst_a,
     output wire                      bram_regce_a,
     output wire                      bram_we_a,

     // BRAM PORT B
     output wire [ACTUAL_ADDR_W-1:0]  bram_addr_b,
     output wire                      bram_clk_b,
     input  wire [`WORD_W-1:0]        bram_rddata_b,
     output wire [`WORD_W-1:0]        bram_wrdata_b,
     output wire                      bram_en_b,
     output wire                      bram_we_b,
     output wire                      bram_rst_b,
     output wire                      bram_regce_b,

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

   cpu_for_bram
   #(ACTUAL_ADDR_W) u1 (
      .bram_clk_a(bram_clk_a),
      .bram_addr_a(bram_addr_a),
      .bram_wrdata_a(bram_wrdata_a),
      .bram_rddata_a(bram_rddata_a),
      .bram_en_a(bram_en_a),
      .bram_we_a(bram_we_a),
      .bram_rst_a(bram_rst_a),
      .bram_regce_a(bram_regce_a),
      .bram_clk_b(bram_clk_b),
      .bram_addr_b(bram_addr_b),
      .bram_wrdata_b(bram_wrdata_b),
      .bram_rddata_b(bram_rddata_b),
      .bram_en_b(bram_en_b),
      .bram_we_b(bram_we_b),
      .bram_rst_b(bram_rst_b),
      .bram_regce_b(bram_regce_b),
      .axi_awvalid(axi_awvalid),
      .axi_awready(axi_awready),
      .axi_awaddr(axi_awaddr),
      .axi_awprot(axi_awprot),
      .axi_wvalid(axi_wvalid),
      .axi_wready(axi_wready),
      .axi_wdata(axi_wdata),
      .axi_wstrb(axi_wstrb),
      .axi_bvalid(axi_bvalid),
      .axi_bready(axi_bready),
      .axi_bresp(axi_bresp),
      .axi_arvalid(axi_arvalid),
      .axi_arready(axi_arready),
      .axi_araddr(axi_araddr),
      .axi_arprot(axi_arprot),
      .axi_rvalid(axi_rvalid),
      .axi_rready(axi_rready),
      .axi_rdata(axi_rdata),
      .axi_rresp(axi_rresp),
      .clk(clk),
      .rstn(rstn));

endmodule

`default_nettype wire
