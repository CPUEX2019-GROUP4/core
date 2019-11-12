module fneg (
  input wire [31:0] x,
  output reg [31:0] y
);

  assign y = {~x[31],x[30:0]};

endmodule
