`default_nettype none

module io_controller
  #(parameter DWIDTH=32)
   (
    input wire              out_req,
    input wire [DWIDTH-1:0] out_data,
    output reg              out_busy,

    input wire              in_req,
    output reg [DWIDTH-1:0] in_data,
    output reg              in_ready,
    output reg              in_busy,

    // I/O via AXI4
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

  reg [3:0]  o_state;
  localparam o_wait           = 4'b0000;
  localparam o_read_status_a  = 4'b0001;
  localparam o_read_status_b  = 4'b0010;
  localparam o_read_status_c  = 4'b0011;
  localparam o_check_status   = 4'b0100;
  localparam o_write_data_a   = 4'b0101;
  localparam o_write_data_b   = 4'b0110;
  localparam o_write_data_c1  = 4'b0111;
  localparam o_write_data_c2  = 4'b1001;
  localparam o_write_data_d   = 4'b1010;

  reg [3:0]  i_state;
  localparam i_wait           = 4'b0001;
  localparam i_read_status_a  = 4'b0010;
  localparam i_read_status_b  = 4'b0011;
  localparam i_read_status_c  = 4'b0100;
  localparam i_check_status   = 4'b0101;
  localparam i_read_data_a    = 4'b0110;
  localparam i_read_data_b    = 4'b0111;
  localparam i_read_data_c    = 4'b1000;

  reg i_in_busy;
  reg o_in_busy;
  reg [31:0] out_data_reg;
  reg rx_data_valid;
  reg tx_fifo_empty;

  reg o_axi_rready;
  reg i_axi_rready;
  reg o_axi_arvalid;
  reg i_axi_arvalid;
  reg [31:0] i_axi_araddr;
  reg [31:0] o_axi_araddr;

  localparam rx_fifo_addr   = 32'd0;
  localparam tx_fifo_addr   = 32'd4;
  localparam stat_reg_addr  = 32'd8;

  assign in_busy      = i_in_busy     ^ o_in_busy;
  assign axi_rready   = i_axi_rready  ^ o_axi_rready;
  assign axi_arvalid  = i_axi_arvalid ^ o_axi_arvalid;
  assign axi_araddr   =
    (i_in_busy) ? i_axi_araddr :
    (o_in_busy) ? o_axi_araddr : 0;

  /********************
  *     IN命令実行    *
  ********************/ 
  always @(posedge clk)
  /*こっちのalways文で操作するreg
   *- i_state
   *- in_ready
   *- axi_arprot
   */
  begin
    if (~rstn) begin
      i_state       <= i_wait;
      in_ready      <= 0;
      i_in_busy     <= 0;
      i_axi_arvalid <= 0;
      i_axi_rready  <= 0;
      i_axi_araddr  <= 0;
      axi_arprot    <= 0;
    end else begin
      case (i_state)
        i_wait:
        begin
          in_ready        <= 0;
          if (in_req&(~in_busy)) begin
            i_state       <= i_read_status_a;
            i_in_busy     <= 1;
          end else begin
            i_in_busy <= 0;
          end
        end
        i_read_status_a:
        begin
          i_axi_arvalid <= 1;
          i_axi_rready  <= 1;
          i_axi_araddr  <= stat_reg_addr;
          i_state       <= i_read_status_b;
        end
        i_read_status_b:
        begin
          if (axi_arready) begin
            i_axi_arvalid <= 0;
            i_axi_rready  <= 1;
            i_state       <= i_read_status_c;
          end
        end
        i_read_status_c:
        begin
          if (axi_rvalid) begin
            i_axi_rready  <= 0;
            rx_data_valid <= axi_rdata[0:0];
            i_state       <= i_check_status;
          end
        end
        i_check_status:
        begin
          i_state <= (rx_data_valid) ? i_read_data_a : i_read_status_a;
        end
        i_read_data_a:
        begin
          i_axi_arvalid <= 1;
          i_axi_rready  <= 1;
          i_axi_araddr  <= rx_fifo_addr;
          i_state       <= i_read_data_b;
        end
        i_read_data_b:
        begin
          if (axi_arready) begin
            i_axi_arvalid <= 0;
            i_axi_rready  <= 1;
            i_state       <= i_read_data_c;
          end
        end
        i_read_data_c:
        begin
          if (axi_rvalid) begin
            i_axi_rready  <= 0;
            in_data       <= axi_rdata;
            in_ready      <= 1;
            i_in_busy     <= 0;
            i_state       <= i_wait;
          end
        end
        default:
        begin
          i_state <= i_wait;
        end
      endcase
    end
  end

  /********************
  *    OUT命令実行    *
  ********************/ 
  always @(posedge clk)
  /*こっちのalways文で操作するreg
   *- o_state
   *- out_busy
   *- axi_awvalid
   *- axi_awaddr
   *- axi_awprot
   *- axi_wvalid
   *- axi_wdata
   *- axi_wstrb
   *- axi_bready
   */
  begin
    if (~rstn) begin
      o_state       <= o_wait;
      out_busy      <= 0;
      axi_awvalid   <= 0;
      axi_awaddr    <= 0;
      axi_awprot    <= 0;
      axi_wvalid    <= 0;
      axi_wdata     <= 0;
      axi_wstrb     <= 0; // AXI UARTLite はこれを無視する.
      axi_bready    <= 0;
      o_axi_rready  <= 0;
      o_axi_arvalid <= 0;
      o_axi_araddr  <= 0;
    end else begin
      case (o_state)
        o_wait:
        begin
          /*
          *  out_req(OUT require)が来たら始める.
          *  out_busyを立てているのに要求が来たら無視.
          */
          if (out_req&(~out_busy)) begin
            out_busy      <= 1;
            out_data_reg  <= out_data;
            o_state       <= o_read_status_a;
          end else begin
            out_busy      <= 0;
          end
        end
        o_read_status_a:
        begin
          /*
          * まずはAXI UARTLiteのstatus registerを確認しに行く.
          * IN命令との同期が必要になる.
          *
          * in_busy が立っている: 当然ダメ
          * in_req が立っている : 次クロックでINとconflictしてしまうのでダメ
          */
          if (~(in_busy|in_req)) begin
            o_axi_arvalid   <= 1;
            o_axi_rready    <= 1;
            o_axi_araddr    <= stat_reg_addr;
            o_in_busy       <= 1;
            o_state         <= o_read_status_b;
          end
        end
        o_read_status_b:
        begin
          /*
          * このステートにおいて
          *   in_busy     == 1
          *   axi_arvalid == 1
          * となっているはず…
          */
          if (axi_arready) begin
            o_axi_arvalid <= 0;
            o_axi_rready  <= 1;
            o_state       <= o_read_status_c;
          end
        end
        o_read_status_c:
        begin
          if (axi_rvalid) begin
            o_axi_rready  <= 0;
            o_in_busy     <= 0;
            tx_fifo_empty <= axi_rdata[2:2];
            o_state       <= o_check_status;
          end
        end
        o_check_status:
        begin
          // TX FIFO がいっぱいだったら
          // もう一度status registerの読み取りからやり直し.
          // 無限ループの心配はない…？
          o_state <= (tx_fifo_empty) ? o_write_data_a : o_read_status_a;
        end
        o_write_data_a:
        begin
          axi_wvalid  <= 1;
          axi_awvalid <= 1;
          axi_wdata   <= out_data_reg;
          axi_awaddr  <= tx_fifo_addr;
          o_state     <= o_write_data_b;
        end
        o_write_data_b:
        begin
          if (axi_wready&axi_awready) begin
            axi_wvalid  <= 0;
            axi_awvalid <= 0;
            axi_bready  <= 1;
            o_state     <= o_write_data_d;
          end else if (axi_wready) begin
            axi_wvalid  <= 0;
            o_state     <= o_write_data_c1;
          end else if (axi_awready) begin
            axi_awvalid <= 0;
            o_state     <= o_write_data_c2;
          end
        end
        o_write_data_c1:
        begin
          if (axi_awready) begin
            o_axi_arvalid <= 0;
            axi_bready    <= 1;
            o_state       <= o_write_data_d;
          end
        end
        o_write_data_c2:
        begin
          if (axi_wready) begin
            axi_awvalid <= 0;
            axi_bready  <= 1;
            o_state     <= o_write_data_d;
          end
        end
        o_write_data_d:
        begin
          if (axi_bvalid) begin
            axi_bready  <= 0;
            o_state     <= o_wait;
          end
        end
        default:
        begin
          o_state <= o_wait;
        end
      endcase
    end
  end

endmodule

`default_nettype wire
