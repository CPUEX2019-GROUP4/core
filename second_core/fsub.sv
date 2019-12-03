module fsub (
    input wire [31:0] x1,
    input wire [31:0] x2,
    output wire [31:0] y,
    input wire clk );

    wire [31:0] negx2;

    cfneg cfneg0(
        .x(x2),
        .y(negx2)
    );

    fadd fadd0 (
        .x1(x1),
        .x2(negx2),
        .y(y),
        .clk(clk)
    );

endmodule
