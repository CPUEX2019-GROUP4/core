// x[31] == 1 -> y == 0
// x[30] == 1 -> y == 1
// x[0] == 1 -> y == 31
// x[0] == 0 -> y == 31
module msb32 (
    input wire [31:0] x,
    output wire [4:0] y );

    function msb2 (input [1:0] in);
    begin
        msb2 = ~in[1];
    end
    endfunction

    function [1:0] msb4 (input [3:0] in);
    begin
        msb4 = |(in[3:2]) ? {1'b0, msb2(in[3:2])} : {1'b1, msb2(in[1:0])};
    end
    endfunction

    function [2:0] msb8 (input [7:0] in);
    begin
        msb8 = |(in[7:4]) ? {1'b0, msb4(in[7:4])} : {1'b1, msb4(in[3:0])};
    end
    endfunction

    function [3:0] msb16 (input [15:0] in);
    begin
        msb16 = |(in[15:8]) ? {1'b0, msb8(in[15:8])} : {1'b1, msb8(in[7:0])};
    end
    endfunction

    assign y = |(x[31:16]) ? {1'b0, msb16(x[31:16])} : {1'b1, msb16(x[15:0])};
endmodule
