module itof (
    input wire [31:0] x,
    output wire [31:0] y,
    input wire ready,
    output wire valid,
    input wire clk,
    input wire rstn );

    assign valid = ready; // とりあえず

    wire [31:0] abs_x = x[31] ? (~x + 32'b1) : x;

    wire [4:0] m_shift;
    msb32 msb32_0 (
        .x(abs_x),
        .y(m_shift)
    );

    wire [32:0] m_unround = {1'b0, abs_x << m_shift};
    wire [24:0] m_rounded = m_unround[32:8] + {24'b0, m_unround[7]};
    wire [22:0] m = abs_x == 32'b0 ? 23'b0 : (m_rounded[24] ? m_rounded[23:1] : m_rounded[22:0]);

    wire [7:0] e = abs_x == 32'b0 ? 8'b0 : (8'd158 - {3'b0, m_shift} + {7'b0, m_rounded[24]});

    wire s = x[31];

    assign y = {s, e, m};

endmodule
