module itof (
    input wire [31:0] x,
    output wire [31:0] y,
    input wire clk );

    wire [31:0] abs_x = x[31] ? (~x + 32'b1) : x;

    wire [4:0] m_shift;
    msb32 msb32_0 (
        .x(abs_x),
        .y(m_shift)
    );

    wire [31:0] m_unround = (abs_x << m_shift);
    wire [22:0] m = abs_x == 32'b0 ? 23'b0 : m_unround[30:8];

    wire [7:0] e = abs_x == 32'b0 ? 8'b0 : (8'd158 - {3'b0, m_shift});

    wire s = x[31];

    assign y = {s, e, m};

endmodule
