`default_nettype none
`include "common_params.h"

module bram_initializer
  #(
    parameter ACTUAL_ADDR_W=32,
    parameter OFFSET_ADDR=0,
    parameter HIGH_ADDR=100)
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

    // AXI4-lite master memory interface
    // address write channel
    output reg            axi_awvalid,
    input wire            axi_awready,
    output reg [31:0]     axi_awaddr,
    output reg [2:0]      axi_awprot,
    // data write channel
    output reg            axi_wvalid,
    input wire            axi_wready,
    output reg [31:0]     axi_wdata,
    output reg [3:0]      axi_wstrb,
    // response channel
    input wire            axi_bvalid,
    output reg            axi_bready,
    input wire [1:0]      axi_bresp,
    // address read channel
    output reg            axi_arvalid,
    input wire            axi_arready,
    output reg [31:0]     axi_araddr,
    output reg [2:0]      axi_arprot,
    // read data channel
    input wire            axi_rvalid,
    output reg            axi_rready,
    input wire [31:0]     axi_rdata,
    input wire [1:0]      axi_rresp,

    input wire clk,
    input wire rstn);

  reg [`ADDR_W-1:0] pc;
  reg [`WORD_W-1:0] rdata;

  reg [3:0]  r_state;
  localparam r_wait           = 0;
  localparam r_read_status_a  = 1;
  localparam r_read_status_b  = 2;
  localparam r_read_status_c  = 3;
  localparam r_check_status   = 4;
  localparam r_read_data_a    = 5;
  localparam r_read_data_b    = 6;
  localparam r_read_data_c    = 7;
  localparam r_terminate      = 8;

  reg [1:0]  w_state;
  localparam w_wait         = 0;
  localparam w_store_data_a = 1;
  localparam w_store_data_b = 2;
  localparam w_terminate    = 3;

  reg rx_data_valid;

  localparam rx_fifo_addr   = 32'd0;
  localparam stat_reg_addr  = 32'd8;

  always @(posedge clk)
  begin
    if (~rstn) begin
      r_state     <= r_wait;
      axi_arvalid <= 0;
      axi_rready  <= 0;
      axi_araddr  <= 0;
      axi_arprot  <= 0;
    end else begin

      (* full_case *)
      case (r_state)
        r_wait:
        begin
          if (pc < HIGH_ADDR) begin
            r_state <= r_read_status_a;
          end else
            r_state <= r_terminate;
          end
        end
        r_read_status_a:
        begin
          axi_arvalid <= 1;
          axi_rready  <= 1;
          axi_araddr  <= stat_reg_addr;
          r_state     <= r_read_status_b;
        end
        r_read_status_b:
        begin
          if (axi_arready) begin
            axi_arvalid <= 0;
            axi_rready  <= 1;
            r_state     <= r_read_status_c;
          end
        end
        r_read_status_c:
        begin
          if (axi_rvalid) begin
            axi_rready    <= 0;
            rx_data_valid <= axi_rdata[0:0];
            r_state       <= r_check_status;
          end
        end
        r_check_status:
        begin
          r_state <= (rx_data_valid) ? r_read_data_a : r_read_status_a;
        end
        r_read_data_a:
        begin
          r_axi_arvalid <= 1;
          r_axi_rready  <= 1;
          r_axi_araddr  <= rx_fifo_addr;
          r_state       <= r_read_data_b;
        end
        r_read_data_b:
        begin
          if (axi_arready) begin
            r_axi_arvalid <= 0;
            r_axi_rready  <= 1;
            r_state       <= r_read_data_c;
          end
        end
        r_read_data_c:
        begin
          if (axi_rvalid) begin
            axi_rready  <= 0;
            rdata       <= axi_rdata;
            r_state     <= r_wait;
          end
        end
        r_terminate:
        begin
        end
      endcase
    end
  end



  always @(posedge clk)
  begin
    if (~rstn) begin
    end else begin
      
    end
  end

`default_nettype wire
