`default_nettype none

module itof (
  input  wire [31:0] x,
  output wire [31:0] y
);

  wire [31:0] abs_x = x[31] ? (~x + 32'b1) : x;

  wire [4:0] m_shift =
    abs_x[31] ?  0 :
    abs_x[30] ?  1 :
    abs_x[29] ?  2 :
    abs_x[28] ?  3 :
    abs_x[27] ?  4 :
    abs_x[26] ?  5 :
    abs_x[25] ?  6 :
    abs_x[24] ?  7 :
    abs_x[23] ?  8 :
    abs_x[22] ?  9 :
    abs_x[21] ? 10 :
    abs_x[20] ? 11 :
    abs_x[19] ? 12 :
    abs_x[18] ? 13 :
    abs_x[17] ? 14 :
    abs_x[16] ? 15 :
    abs_x[15] ? 16 :
    abs_x[14] ? 17 :
    abs_x[13] ? 18 :
    abs_x[12] ? 19 :
    abs_x[11] ? 20 :
    abs_x[10] ? 21 :
    abs_x[ 9] ? 22 :
    abs_x[ 8] ? 23 :
    abs_x[ 7] ? 24 :
    abs_x[ 6] ? 25 :
    abs_x[ 5] ? 26 :
    abs_x[ 4] ? 27 :
    abs_x[ 3] ? 28 :
    abs_x[ 2] ? 29 :
    abs_x[ 1] ? 30 : 31;
  
  wire [32:0] m_unround = {1'b0, abs_x << m_shift};
  wire [24:0] m_rounded = m_unround[32:8] + {24'b0, m_unround[7]};
  wire [22:0] m = abs_x == 32'b0 ? 23'b0 : (m_rounded[24] ? m_rounded[23:1] : m_rounded[22:0]);

  wire [7:0] e = abs_x == 32'b0 ? 8'b0 : (8'd158 - {3'b0, m_shift} + {7'b0, m_rounded[24]});

  wire s = x[31];

  assign y = {s, e, m};

endmodule

`default_nettype wire
