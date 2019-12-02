`default_nettype none
`include "common_params.h"

module io_controller
  #(parameter ACTUAL_ADDR_W= 32,
    parameter INIT_POINTER =  0,
    parameter HIGH_POINTER = 10)
   (
    input wire                out_req,
    input wire [`WORD_W-1:0]  out_data,
    input wire [`ADDR_W-1:0]  consumer_pointer,
    output reg                 in_busy,
    output reg                out_busy,
    
    // BRAM PORT A
    output reg  [ACTUAL_ADDR_W-1:0]  mem_addr_for_output,
    output reg  [`WORD_W-1:0]        mem_data,
    output reg                       mem_we,

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

  // データメモリアクセス用
  reg [`ADDR_W-1:0] producer_pointer;
  reg [`ADDR_W-1:0] mem_addr;

  wire in_module_busy, out_module_busy;

  reg         in_axi_arvalid, out_axi_arvalid;
  reg         in_axi_rready,  out_axi_rready;
  reg [31:0]  in_axi_araddr,  out_axi_araddr;

  in_module
  #(INIT_POINTER,HIGH_POINTER) in_mod1
  (.in_module_busy  (in_module_busy),
   .interrupt       (out_module_busy | out_req),
   .producer_pointer(producer_pointer),
   .mem_data        (mem_data),
   .mem_addr        (mem_addr),
   .mem_we          (mem_we),
   .axi_arready     (axi_arready),
   .axi_rvalid      (axi_rvalid),
   .axi_rdata       (axi_rdata),
   .in_axi_arvalid  (in_axi_arvalid),
   .in_axi_rready   (in_axi_rready),
   .in_axi_araddr   (in_axi_araddr),
   .clk             (clk),
   .rstn            (rstn));

  out_module out_mod1
  (.out_module_busy (out_module_busy),
   .interrupt       (in_module_busy),
   .out_req         (out_req),
   .out_data        (out_data),
   .axi_arready     (axi_arready),
   .axi_rvalid      (axi_rvalid),
   .axi_rdata       (axi_rdata),
   .out_axi_arvalid (out_axi_arvalid),
   .out_axi_rready  (out_axi_rready),
   .out_axi_araddr  (out_axi_araddr),
   .axi_awready     (axi_awready),
   .axi_awvalid     (axi_awvalid),
   .axi_awaddr      (axi_awaddr),
   .axi_wready      (axi_wready),
   .axi_wvalid      (axi_wvalid),
   .axi_wdata       (axi_wdata),
   .axi_bvalid      (axi_bvalid),
   .axi_bready      (axi_bready),
   .clk             (clk),
   .rstn            (rstn));

  assign mem_addr_for_output = mem_addr;
  assign  in_busy =  (consumer_pointer==producer_pointer);
  assign out_busy = out_module_busy;

  assign axi_rready  = in_axi_rready  ^ out_axi_rready;
  assign axi_arvalid = in_axi_arvalid ^ out_axi_arvalid;
  assign axi_araddr  =(in_module_busy) ? in_axi_araddr:out_axi_araddr;

  assign axi_arprot  = 0;
  assign axi_awprot  = 0;
  assign axi_wstrb   = 0;
  
endmodule

module out_module
   (
    output reg  out_module_busy,
    input wire  interrupt,

    input wire               out_req,
    input wire [`WORD_W-1:0] out_data,

    input wire        axi_arready,
    input wire        axi_rvalid,
    input wire [31:0] axi_rdata,

    output reg        out_axi_arvalid,
    output reg        out_axi_rready,
    output reg [31:0] out_axi_araddr,

    input wire        axi_awready,
    output reg        axi_awvalid,
    output reg [31:0] axi_awaddr,
    input wire        axi_wready,
    output reg        axi_wvalid,
    output reg [31:0] axi_wdata,
    input wire        axi_bvalid,
    output reg        axi_bready,

    input wire clk,
    input wire rstn);
  
  reg [3:0]  out_state;
  localparam out_wait           = 4'd1;
  localparam out_read_status_a  = 4'd2;
  localparam out_read_status_b  = 4'd3;
  localparam out_read_status_c  = 4'd4;
  localparam out_check_status   = 4'd5;
  localparam out_write_data_a   = 4'd6;
  localparam out_write_data_b   = 4'd7;
  localparam out_write_data_c1  = 4'd8;
  localparam out_write_data_c2  = 4'd9;
  localparam out_write_data_d   = 4'd10;
  
  reg tx_fifo_empty;
  reg [`WORD_W-1:0] out_data_reg;

  assign out_module_busy = ~(out_state==out_wait);

  always @(posedge clk)
  begin
    if (~rstn) begin
      out_state       <= out_wait;
      axi_awvalid     <= 0;
      axi_awaddr      <= 0;
      axi_wvalid      <= 0;
      axi_wdata       <= 0;
      axi_bready      <= 0;
      out_axi_rready  <= 0;
      out_axi_arvalid <= 0;
      out_axi_araddr  <= 0;
    end else begin
      (* full_case *)
      case (out_state)
        /**************************
        *        WAIT PHASE       *
        **************************/
        out_wait:
        begin
          if (out_req) begin
            out_data_reg  <= out_data;
            out_state     <= out_read_status_a;
          end
        end
        /**************************
        *    READ STATUS PHASE    *
        **************************/
        out_read_status_a:
        begin
          if (~interrupt) begin
            out_axi_arvalid <= 1;
            out_axi_araddr  <= 8;
            out_state       <= out_read_status_b;
          end
        end
        out_read_status_b:
        begin
          if (axi_arready) begin
            out_axi_arvalid <= 0;
            out_axi_rready  <= 1;
            out_state       <= out_read_status_c;
          end
        end
        out_read_status_c:
        begin
          if (axi_rvalid) begin
            out_axi_rready  <= 0;
            tx_fifo_empty   <= axi_rdata[2:2];
            out_state       <= out_check_status;
          end
        end
        /**************************
        *   CHECK STATUS PHASE    *
        **************************/
        out_check_status:
        begin
          out_state   <= (~(axi_rdata[0:0])&tx_fifo_empty) ? out_write_data_a : out_read_status_a;
        end
        /**************************
        *    WRITE DATA PHASE     *
        **************************/
        out_write_data_a:
        begin
          axi_wvalid  <= 1;
          axi_awvalid <= 1;
          axi_wdata   <= out_data_reg;
          axi_awaddr  <= 4;
          out_state   <= out_write_data_b;
        end
        out_write_data_b:
        begin
          if (axi_wready&axi_awready) begin
            axi_wvalid  <= 0;
            axi_awvalid <= 0;
            axi_bready  <= 1;
            out_state   <= out_write_data_d;
          end else if (axi_wready) begin
            axi_wvalid  <= 0;
            out_state   <= out_write_data_c1;
          end else if (axi_awready) begin
            axi_awvalid <= 0;
            out_state   <= out_write_data_c2;
          end
        end
        out_write_data_c1:
        begin
          if (axi_awready) begin
            axi_awvalid <= 0;
            axi_bready  <= 1;
            out_state   <= out_write_data_d;
          end
        end
        out_write_data_c2:
        begin
          if (axi_wready) begin
            axi_wvalid  <= 0;
            axi_bready  <= 1;
            out_state   <= out_write_data_d;
          end
        end
        out_write_data_d:
        begin
          if (axi_bvalid) begin
            axi_bready  <= 0;
            out_state     <= out_wait;
          end
        end
      endcase
    end
  end
endmodule


module in_module
  #(parameter INIT_POINTER=0,
    parameter HIGH_POINTER=10)
   (
    output reg  in_module_busy,
    input wire  interrupt,

    output reg  [`ADDR_W-1:0] producer_pointer,
    output reg  [`WORD_W-1:0] mem_data,
    output reg  [`ADDR_W-1:0] mem_addr,
    output reg                mem_we,

    input wire        axi_arready,
    input wire        axi_rvalid,
    input wire [31:0] axi_rdata,

    output reg        in_axi_arvalid,
    output reg        in_axi_rready,
    output reg [31:0] in_axi_araddr,

    input wire clk,
    input wire rstn);

  reg [3:0]  in_state;
  localparam in_wait           = 4'd1;
  localparam in_read_status_a  = 4'd2;
  localparam in_read_status_b  = 4'd3;
  localparam in_read_status_c  = 4'd4;
  localparam in_check_status   = 4'd5;
  localparam in_read_data_a    = 4'd6;
  localparam in_read_data_b    = 4'd7;
  localparam in_mem_access     = 4'd8;
  localparam in_pointer_update = 4'd9;

  reg rx_data_valid;

  reg [1:0] data_offset;

  assign in_module_busy =
    (in_state==in_wait          ) ? 0 :
    (in_state==in_pointer_update) ? 0 : 1;

  always @(posedge clk)
  begin
    if (~rstn) begin
      in_state         <= in_wait;
      in_axi_arvalid   <= 0;
      in_axi_rready    <= 0;
      in_axi_araddr    <= 0;
      mem_data         <= 0;
      mem_addr         <= 0;
      mem_we           <= 0;
      producer_pointer <= INIT_POINTER;
      data_offset      <= 0;
      rx_data_valid    <= 0;
    end else begin
      case (in_state)
        /**************************
        *        WAIT PHASE       *
        **************************/
        in_wait:
        begin
          in_state <=(interrupt)                      ? in_wait :
                     (producer_pointer==HIGH_POINTER) ? in_wait : in_read_status_a;
        end
        /**************************
        *    READ STATUS PHASE    *
        **************************/
        in_read_status_a:
        begin
          in_axi_arvalid <= 1;
          in_axi_araddr  <= 8;
          in_state       <= in_read_status_b;
        end
        in_read_status_b:
        begin
          if (axi_arready) begin
            in_axi_arvalid <= 0;
            in_axi_rready  <= 1;
            in_state       <= in_read_status_c;
          end
        end
        in_read_status_c:
        begin
          if (axi_rvalid) begin
            in_axi_rready <= 0;
            rx_data_valid <= axi_rdata[0:0];
            in_state      <= in_check_status;
          end
        end
        /**************************
        *   CHECK STATUS PHASE    *
        **************************/
        in_check_status:
        begin
          in_state      <=(rx_data_valid) ? in_read_data_a : in_wait;
          rx_data_valid <= 0;
        end
        /**************************
        *     READ DATA PHASE     *
        **************************/
        in_read_data_a:
        begin
          in_axi_arvalid <= 1;
          in_axi_araddr  <= 0;
          in_state       <= in_read_data_b;
        end
        in_read_data_b:
        begin
          if (axi_arready) begin
            in_axi_arvalid <= 0;
            in_axi_rready  <= 1;
            in_state       <= in_mem_access;
          end
        end
        /**************************
        *   MEMORY ACCESS PHASE   *
        **************************/
        in_mem_access:
        begin
          if (axi_rvalid) begin
            in_axi_rready <= 0;
            data_offset   <= data_offset + 1;
            mem_addr      <= producer_pointer;
            mem_we        <=(data_offset==2'b11) ? 1 : 0;
            in_state      <= in_pointer_update;
            (* full_case *)
            case (data_offset)
              2'b00: mem_data[ 7: 0] = axi_rdata[7:0];
              2'b01: mem_data[15: 8] = axi_rdata[7:0];
              2'b10: mem_data[23:16] = axi_rdata[7:0];
              2'b11: mem_data[31:24] = axi_rdata[7:0];
            endcase
          end
        end
        /**************************
        *  POINTER UPDATE PHASE   *
        **************************/
        in_pointer_update:
        begin
          producer_pointer<=(data_offset==2'b00) ? producer_pointer+1 : producer_pointer;
          mem_we          <= 0;
          in_state        <= in_wait;
        end
      endcase
    end
  end
endmodule

`default_nettype wire
