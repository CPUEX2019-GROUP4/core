`default_nettype none

module fcz (
  input  wire [31:0] x,
  output wire        y
);
  wire [7:0] e = x[30:23];
  assign y = e == 8'b0;
endmodule

`default_nettype wire
