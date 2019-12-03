module cfneg (
    input wire [31:0] x,
    output wire [31:0] y );

    assign y = {~x[31], x[30:0]};

endmodule

module fneg (
    input wire [31:0] x,
    output wire [31:0] y,
    input wire clk );

    cfneg cfneg0 (
        .x(x),
        .y(y)
    );

endmodule
