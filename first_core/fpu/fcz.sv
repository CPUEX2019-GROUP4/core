module fcz (
    input wire [31:0] x,
    output wire y,
    input wire ready,
    output wire valid,
    input wire clk,
    input wire rstn );

    assign valid = ready;

    wire [7:0] e = x[30:23];

    assign y = e == 8'b0;

endmodule
