module fabs (
    input wire [31:0] x,
    output wire [31:0] y,
    input wire clk );

    assign y = {1'b0, x[30:0]};

endmodule
