`include "fpu_params.h"

module fpau (
    input wire [31:0] x1,
    input wire [31:0] x2,
    output wire [31:0] y32,
    output wire y1,
    input wire [`FPU_OP_WIDTH-1:0] operation,
    input wire ready,
    output wire valid,
    input wire clk,
    input wire rstn );

    wire res1_fclt;
    wire res1_fcz;
    wire [31:0] res32_fneg;
    wire [31:0] res32_fabs;
    wire [31:0] res32_fadd;
    wire [31:0] res32_fsub;
    wire [31:0] res32_fmul;
    wire [31:0] res32_finv;
    wire [31:0] res32_ftoi;
    wire [31:0] res32_itof;
    wire [31:0] res32_sqrt_init;
    wire [31:0] res32_finv_init;
    wire [31:0] res32_sqrt_inv_init;
    wire [31:0] res32_for;
    wire [31:0] res32_fmv;

    reg [4:0] state;
    always @(posedge clk) begin
        if (~rstn) begin
            state <= 5'b00001;
        end else if (valid) begin
            state <= 5'b00001;
        end else if (state == 5'b00001) begin
            if (ready) begin
                state <= (state << 1);
            end
        end else begin
            state <= (state << 1);
        end
    end

    wire op_clk1 = ~(op_clk2 || op_clk3 || op_clk4 || op_clk5);
    wire op_clk2 = 1'b0;
    wire op_clk3 = 1'b0;
    wire op_clk4 = 1'b0;
    wire op_clk5 = 1'b0;

    assign valid = ready && (
           (state == 5'b00001 && op_clk1)
        || (state == 5'b00010 && op_clk2)
        || (state == 5'b00100 && op_clk3)
        || (state == 5'b01000 && op_clk4)
        || (state == 5'b10000 && op_clk5));

    assign y32 =
        operation == `FPU_OPFNEG ? res32_fneg :
        operation == `FPU_OPFABS ? res32_fabs :
        operation == `FPU_OPFADD ? res32_fadd :
        operation == `FPU_OPFSUB ? res32_fsub :
        operation == `FPU_OPFMUL ? res32_fmul :
        operation == `FPU_OPFINV ? res32_finv :
        operation == `FPU_OPFTOI ? res32_ftoi :
        operation == `FPU_OPITOF ? res32_itof :
        operation == `FPU_OPSQRT_INIT ? res32_sqrt_init :
        operation == `FPU_OPFINV_INIT ? res32_finv_init :
        operation == `FPU_OPSQRT_INV_INIT ? res32_sqrt_inv_init :
        operation == `FPU_OPFOR ? res32_for :
        operation == `FPU_OPFMV ? res32_fmv : 'x;
    assign y1 =
        operation == `FPU_OPFCLT ? res1_fclt :
        operation == `FPU_OPFCZ ? res1_fcz : 'x;

    fneg fneg0 (
        .x(x1),
        .y(res32_fneg),
        .clk(clk)
    );

    fabs fabs0 (
        .x(x1),
        .y(res32_fabs),
        .clk(clk)
    );

    fadd fadd0 (
        .x1(x1),
        .x2(x2),
        .y(res32_fadd),
        .clk(clk)
    );

    fsub fsub0 (
        .x1(x1),
        .x2(x2),
        .y(res32_fsub),
        .clk(clk)
    );

    fmul fmul0 (
        .x1(x1),
        .x2(x2),
        .y(res32_fmul),
        .clk(clk)
    );

    finv finv0 (
        .x(x1),
        .y(res32_finv),
        .clk(clk)
    );

    fclt fclt0 (
        .x1(x1),
        .x2(x2),
        .y(res1_fclt),
        .clk(clk)
    );

    fcz fcz0 (
        .x(x1),
        .y(res1_fcz),
        .clk(clk)
    );

    ftoi ftoi0 (
        .x(x1),
        .y(res32_ftoi),
        .clk(clk)
    );

    itof itof0 (
        .x(x1),
        .y(res32_itof),
        .clk(clk)
    );

    sqrt_init sqrt_init0 (
        .x(x1),
        .y(res32_sqrt_init),
        .clk(clk)
    );

    finv_init finv_init0 (
        .x(x1),
        .y(res32_finv_init),
        .clk(clk)
    );

    sqrt_inv_init sqrt_inv_init0 (
        .x(x1),
        .y(res32_sqrt_inv_init),
        .clk(clk)
    );

    assign res32_for = x1 | x2;
    assign res32_fmv = x1;

endmodule
