module fsub (
  input wire [31:0] x1,
  input wire [31:0] x2,
  output reg [31:0] y
);

  fadd fadd0 (
    .x1(x1),
    .x2({~x2[31],x2[30:0]}),
    .y(y)
  );

endmodule
