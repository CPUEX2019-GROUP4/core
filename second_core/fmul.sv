module fmul (
    input wire [31:0] x1,
    input wire [31:0] x2,
    output wire [31:0] y,
    input wire clk );

    wire s1 = x1[31];
    wire s2 = x2[31];
    wire [7:0] e1 = x1[30:23];
    wire [7:0] e2 = x2[30:23];
    wire [22:0] m1 = x1[22:0];
    wire [22:0] m2 = x2[22:0];

    wire [23:0] m1_ext = {1'b1, m1};
    wire [23:0] m2_ext = {1'b1, m2};

    wire [17:0] m2_low = m2_ext[17:0];
    wire [5:0] m2_high = m2_ext[23:18];

    wire [8:0] emuled = {1'b0, e1} + {1'b0, e2};
    wire [8:0] emuled_plus1 = emuled + 9'b1;

    wire [8:0] emuled_biased_ext = emuled <= 9'd127 ? 9'd0 : emuled - 9'd127;
    wire [8:0] emuled_plus1_biased_ext =
        emuled_plus1 <= 9'd127 ? 9'd0 : emuled_plus1 - 9'd127;

    wire [7:0] emuled_biased = emuled_biased_ext[7:0];
    wire [7:0] emuled_plus1_biased = emuled_plus1_biased_ext[7:0];

    wire is_y_neg = s1 != s2;
    wire is_y_0 = e1 == 8'b0 || e2 == 8'b0;

    // reg div

    // mmuled[47] || mmuled[46]
    wire [47:0] mmuled = {mul_h, 18'b0} + {6'b0, mul_l};

    // mmuled_aligned[48] = 0, mmuled_aligned[47] = 1
    wire [48:0] mmuled_aligned =
        mmuled[47] ? {1'b0, mmuled} : {1'b0, mmuled << 1};

    wire least_bit = mmuled_aligned[24];
    wire guard_bit = mmuled_aligned[23];
    wire round_bit = mmuled_aligned[22];
    wire sticky_bit = |(mmuled_aligned[21:0]);

    wire if_round_up =
        (least_bit && guard_bit && ~round_bit && ~sticky_bit)
        || (guard_bit && ~round_bit && sticky_bit)
        || (guard_bit && round_bit);

    wire [24:0] mrounded =
        if_round_up ? mmuled_aligned[48:24] + 25'b1 : mmuled_aligned[48:24];

    wire carry = mmuled[47] || mrounded[24];

    wire [22:0] mlast = mrounded[24] ? 23'b0 : mrounded[22:0];

    wire [7:0] elast = carry ? emuled_plus1_biased : emuled_biased;

    assign y[31] = is_y_neg;
    assign y[30:0] = is_y_0 ? 31'b0 : {elast, mlast};

    wire [29:0] mul_h = $unsigned(m1_ext) * $unsigned(m2_high);
    wire [41:0] mul_l = $unsigned(m1_ext) * $unsigned(m2_low);

endmodule
