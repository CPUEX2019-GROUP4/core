module fpu (
    input wire [4:0] x1,
    input wire [4:0] x2,
    input wire [4:0] y,
    input wire [5:0] operation,
    input wire [31:0] in_data,
    output wire cond,
    output wire [31:0] out_data,
    input wire ready,
    output wire valid,
    input wire clk,
    input wire rstn );

    integer i;

    localparam [5:0] OPFNEG = 6'b010000;
    localparam [5:0] OPFABS = 6'b000101;
    localparam [5:0] OPFADD = 6'b000000;
    localparam [5:0] OPFSUB = 6'b000001;
    localparam [5:0] OPFMUL = 6'b000010;
    localparam [5:0] OPFCLT = 6'b100000;
    localparam [5:0] OPFCZ  = 6'b101000;
    localparam [5:0] OPFTOI = 6'b111000;
    localparam [5:0] OPITOF = 6'b111001;
    localparam [5:0] OPSQRT_INIT = 6'b110000;
    localparam [5:0] OPFINV_INIT = 6'b110001;
    localparam [5:0] OPFMV  = 6'b000110;
    localparam [5:0] OPFORI = 6'b111101;
    localparam [5:0] OPSET  = 6'b111110;
    localparam [5:0] OPGET  = 6'b111111;

    localparam IDXFNEG  = 0;
    localparam IDXFABS  = 1;
    localparam IDXFADD  = 2;
    localparam IDXFSUB  = 3;
    localparam IDXFMUL  = 4;
    localparam IDXFCLT  = 5;
    localparam IDXFCZ   = 6;
    localparam IDXFTOI  = 7;
    localparam IDXITOF  = 8;
    localparam IDXSQRT_INIT = 9;
    localparam IDXFINV_INIT = 10;
    localparam IDXCOUNT = 11;

    localparam [2:0] STWAIT = 3'b100;
    localparam [2:0] STEXEC = 3'b010;
    localparam [2:0] STWRITE = 3'b001;

    reg [31:0] register [0:31];
    reg cond_reg;

    reg [2:0] state;

    wire [31:0] arg1 = register[x1];
    wire [31:0] arg2 = register[x2];

    wire res1_fclt;
    wire res1_fcz;
    wire [31:0] res32_fneg;
    wire [31:0] res32_fabs;
    wire [31:0] res32_fadd;
    wire [31:0] res32_fsub;
    wire [31:0] res32_fmul;
    wire [31:0] res32_ftoi;
    wire [31:0] res32_itof;
    wire [31:0] res32_sqrt_init;
    wire [31:0] res32_finv_init;

    reg [31:0] rres32_fneg;
    reg [31:0] rres32_fabs;
    reg [31:0] rres32_fadd;
    reg [31:0] rres32_fsub;
    reg [31:0] rres32_fmul;
    reg [31:0] rres32_itof;
    reg [31:0] rres32_sqrt_init;
    reg [31:0] rres32_finv_init;

    wire ready_fneg = (state == STWAIT || state == STEXEC) && ready && operation == OPFNEG;
    wire ready_fabs = (state == STWAIT || state == STEXEC) && ready && operation == OPFABS;
    wire ready_fadd = (state == STWAIT || state == STEXEC) && ready && operation == OPFADD;
    wire ready_fsub = (state == STWAIT || state == STEXEC) && ready && operation == OPFSUB;
    wire ready_fmul = (state == STWAIT || state == STEXEC) && ready && operation == OPFMUL;
    wire ready_fclt = (state == STWAIT || state == STEXEC) && ready && operation == OPFCLT;
    wire ready_fcz  = (state == STWAIT || state == STEXEC) && ready && operation == OPFCZ;
    wire ready_ftoi = (state == STWAIT || state == STEXEC) && ready && operation == OPFTOI;
    wire ready_itof = (state == STWAIT || state == STEXEC) && ready && operation == OPITOF;
    wire ready_sqrt_init = (state == STWAIT || state == STEXEC) && ready && operation == OPSQRT_INIT;
    wire ready_finv_init = (state == STWAIT || state == STEXEC) && ready && operation == OPFINV_INIT;

    wire [0:IDXCOUNT - 1] valids;
    wire mod_valid = |valids;

    assign valid = ready && (state == STWRITE
        || operation == OPFMV || operation == OPSET || operation == OPGET || operation == OPFORI
        || (mod_valid && (operation == OPFCLT || operation == OPFCZ || operation == OPFTOI)));
    assign cond = cond_reg;
    assign out_data = operation == OPGET ? arg1
        : (operation == OPFTOI ? res32_ftoi : 'x);

    fneg fneg0 (
        .x(arg1),
        .y(res32_fneg),
        .ready(ready_fneg),
        .valid(valids[IDXFNEG]),
        .clk(clk),
        .rstn(rstn)
    );

    fabs fabs0 (
        .x(arg1),
        .y(res32_fabs),
        .ready(ready_fabs),
        .valid(valids[IDXFABS]),
        .clk(clk),
        .rstn(rstn)
    );

    fadd fadd0 (
        .x1(arg1),
        .x2(arg2),
        .y(res32_fadd),
        .ready(ready_fadd),
        .valid(valids[IDXFADD]),
        .clk(clk),
        .rstn(rstn)
    );

    fsub fsub0 (
        .x1(arg1),
        .x2(arg2),
        .y(res32_fsub),
        .ready(ready_fsub),
        .valid(valids[IDXFSUB]),
        .clk(clk),
        .rstn(rstn)
    );

    fmul fmul0 (
        .x1(arg1),
        .x2(arg2),
        .y(res32_fmul),
        .ready(ready_fmul),
        .valid(valids[IDXFMUL]),
        .clk(clk),
        .rstn(rstn)
    );

    fclt fclt0 (
        .x1(arg1),
        .x2(arg2),
        .y(res1_fclt),
        .ready(ready_fclt),
        .valid(valids[IDXFCLT]),
        .clk(clk),
        .rstn(rstn)
    );

    fcz fcz0 (
        .x(arg1),
        .y(res1_fcz),
        .ready(ready_fcz),
        .valid(valids[IDXFCZ]),
        .clk(clk),
        .rstn(rstn)
    );

    ftoi ftoi0 (
        .x(arg1),
        .y(res32_ftoi),
        .ready(ready_ftoi),
        .valid(valids[IDXFTOI]),
        .clk(clk),
        .rstn(rstn)
    );

    itof itof0 (
        .x(in_data),
        .y(res32_itof),
        .ready(ready_itof),
        .valid(valids[IDXITOF]),
        .clk(clk),
        .rstn(rstn)
    );

    sqrt_init sqrt_init0 (
        .x(arg1),
        .y(res32_sqrt_init),
        .ready(ready_sqrt_init),
        .valid(valids[IDXSQRT_INIT]),
        .clk(clk),
        .rstn(rstn)
    );

    finv_init finv_init0 (
        .x(arg1),
        .y(res32_finv_init),
        .ready(ready_finv_init),
        .valid(valids[IDXFINV_INIT]),
        .clk(clk),
        .rstn(rstn)
    );

    always @(posedge clk) begin
        if (~rstn) begin
            state <= STWAIT;
        end else begin
            if (state == STWAIT) begin 
                if (ready) begin
                    if (~(operation == OPFMV || operation == OPFORI
                        || operation == OPSET || operation == OPGET)) begin
                        state <= mod_valid ? STWRITE : STEXEC;
                    end
                end
            end else if (state == STEXEC) begin
                if (mod_valid) begin
                    state <= STWRITE;
                end
            end else if (state == STWRITE) begin
                state <= STWAIT;
            end
        end
    end

    always @(posedge clk) begin
        rres32_fneg <= res32_fneg;
        rres32_fabs <= res32_fabs;
        rres32_fadd <= res32_fadd;
        rres32_fsub <= res32_fsub;
        rres32_fmul <= res32_fmul;
        rres32_itof <= res32_itof;
        rres32_sqrt_init <= res32_sqrt_init;
        rres32_finv_init <= res32_finv_init;
    end

    always @(posedge clk) begin
        if (mod_valid) begin
            if (operation == OPFCLT) begin
                cond_reg <= res1_fclt;
            end else if (operation == OPFCZ) begin
                cond_reg <= res1_fcz;
            end
        end
    end

    always @(posedge clk) begin
        if (~rstn) begin
            for (i = 0; i < 32; i = i + 1) begin
                register[i] <= 32'b0;
            end
        end else if (state == STWAIT) begin
            if (operation == OPFMV) begin
                register[y] <= arg1;
            end else if (operation == OPFORI) begin
                register[y] <= arg1 | in_data;
            end else if (operation == OPSET) begin
                register[y] <= in_data;
            end 
            // nothing to do for get
        end else if (state == STWRITE) begin
            if (operation == OPFNEG) begin
                register[y] <= rres32_fneg;
            end else if (operation == OPFABS) begin
                register[y] <= rres32_fabs;
            end else if (operation == OPFADD) begin
                register[y] <= rres32_fadd;
            end else if (operation == OPFSUB) begin
                register[y] <= rres32_fsub;
            end else if (operation == OPFMUL) begin
                register[y] <= rres32_fmul;
            end else if (operation == OPITOF) begin
                register[y] <= rres32_itof;
            end else if (operation == OPSQRT_INIT) begin
                register[y] <= rres32_sqrt_init;
            end else if (operation == OPFINV_INIT) begin
                register[y] <= rres32_finv_init;
            end
            // nothing to do for fclt, fcz, ftoi
        end
    end

endmodule
