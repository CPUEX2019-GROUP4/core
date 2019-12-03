`include "fpu_params.h"

module fpu (
    input wire [`FPU_REG_ADDR_WIDTH-1:0] x1,
    input wire [`FPU_REG_ADDR_WIDTH-1:0] x2,
    input wire [`FPU_REG_ADDR_WIDTH-1:0] y,
    input wire [`FPU_OP_WIDTH-1:0] operation,
    input wire [31:0] in_data,
    output wire cond,
    output wire [31:0] out_data,
    input wire ready,
    output wire valid,
    input wire clk,
    input wire rstn );

    reg [31:0] register [0:`FPU_REG_COUNT-1];
    reg cond_reg;

    reg prev_ready;
    wire new_op = ready && (~prev_ready || wb_fpau_valid);

    reg wb_op_needs_wb32;
    reg [`FPU_REG_ADDR_WIDTH-1:0] wb_y;

    wire [31:0] regval_arg1 = register[x1];
    wire [31:0] regval_arg2 = register[x2];
    wire [31:0] imm_arg1 =
        operation == `FPU_OPITOF || operation == `FPU_OPSET ? in_data : 'x;
    wire [31:0] imm_arg2 =
        operation == `FPU_OPFORI ? in_data :
        operation == `FPU_OPSET || operation == `FPU_OPGET ? '0 : 'x;

    wire use_imm_arg1 = operation == `FPU_OPITOF || operation == `FPU_OPSET;
    wire use_imm_arg2 = operation == `FPU_OPFORI
        || operation == `FPU_OPSET || operation == `FPU_OPGET;

    reg [31:0] rarg1;
    reg [31:0] rarg2;
    wire [31:0] arg1 = new_op ? (use_imm_arg1 ? imm_arg1 :
        write_enable32 && wb_y == x1 ? wb_res32 : regval_arg1) : rarg1;
    wire [31:0] arg2 = new_op ? (use_imm_arg2 ? imm_arg2 :
        write_enable32 && wb_y == x2 ? wb_res32 : regval_arg2) : rarg2;

    wire [31:0] res32;
    wire res1;

    reg [31:0] wb_res32;

    wire fpau_valid;
    reg wb_fpau_valid;

    wire [`FPU_OP_WIDTH-1:0] fpau_op =
        operation == `FPU_OPFORI || operation == `FPU_OPSET
        || operation == `FPU_OPGET ? `FPU_OPFOR : operation;

    wire write_enable32 = wb_fpau_valid && wb_op_needs_wb32;
    wire write_enable1 = fpau_valid && 
        (operation == `FPU_OPFCLT || operation == `FPU_OPFCZ);

    assign valid = fpau_valid;
    assign cond = cond_reg;
    assign out_data = res32;

    fpau fpau0 (
        .x1(arg1),
        .x2(arg2),
        .y32(res32),
        .y1(res1),
        .operation(fpau_op),
        .ready(ready),
        .valid(fpau_valid),
        .clk(clk),
        .rstn(rstn)
    );

    always @(posedge clk) begin
        if (~rstn) begin
            wb_fpau_valid <= 1'b0;
            prev_ready <= 1'b0;
        end else begin
            wb_fpau_valid <= fpau_valid;
            wb_y <= y;
            prev_ready <= ready;
            rarg1 <= arg1;
            rarg2 <= arg2;
            wb_res32 <= res32;
            wb_op_needs_wb32 <=
                operation == `FPU_OPFNEG || operation == `FPU_OPFABS
                || operation == `FPU_OPFADD || operation == `FPU_OPFSUB
                || operation == `FPU_OPFMUL || operation == `FPU_OPFINV
                || operation == `FPU_OPITOF || operation == `FPU_OPSQRT_INIT
                || operation == `FPU_OPFINV_INIT || operation == `FPU_OPSQRT_INV_INIT
                || operation == `FPU_OPFMV || operation == `FPU_OPFORI
                || operation == `FPU_OPSET;
            if (write_enable1) begin
                cond_reg <= res1;
            end
        end
    end

    always @(posedge clk) begin
        if (~rstn) begin
        end else if (write_enable32) begin
            register[wb_y] <= wb_res32;
        end
    end

endmodule
