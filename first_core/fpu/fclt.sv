module fclt (
    input wire [31:0] x1,
    input wire [31:0] x2,
    output wire y,
    input wire ready,
    output wire valid,
    input wire clk,
    input wire rstn );

    assign valid = ready;

    wire s1 = x1[31];
    wire s2 = x2[31];
    wire [30:0] em1 = x1[30:0];
    wire [30:0] em2 = x2[30:0];
    wire [7:0] e1 = x1[30:23];
    wire [7:0] e2 = x2[30:23];

    assign y = ~(e1 == '0 && e2 == '0)
        && ((s1 && ~s2) || (s1 && s2 && em1 > em2) || (~s1 && ~s2 && em1 < em2));

endmodule
