module cfneg (
    input wire [31:0] x,
    output wire [31:0] y );

    assign y = {~x[31], x[30:0]};

endmodule

module fneg (
    input wire [31:0] x,
    output wire [31:0] y,
    input wire ready,
    output wire valid,
    input wire clk,
    input wire rstn );

    cfneg cfneg0 (
        .x(x),
        .y(y)
    );
    assign valid = ready;

endmodule
