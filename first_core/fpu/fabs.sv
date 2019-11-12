module fabs (
    input wire [31:0] x,
    output wire [31:0] y,
    input wire ready,
    output wire valid,
    input wire clk,
    input wire rstn );

    assign valid = ready;
    assign y = {1'b0, x[30:0]};

endmodule
