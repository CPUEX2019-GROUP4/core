module fadd (
    input wire [31:0] x1,
    input wire [31:0] x2,
    output wire [31:0] y,
    input wire clk );

    // 1
    wire s1 = x1[31];
    wire s2 = x2[31];
    wire [7:0] e1 = x1[30:23];
    wire [7:0] e2 = x2[30:23];
    wire [22:0] m1 = x1[22:0];
    wire [22:0] m2 = x2[22:0];

    // 2
    wire [24:0] m1a = {2'b1, m1};
    wire [24:0] m2a = {2'b1, m2};

    // 3
    wire [7:0] e1a = e1;
    wire [7:0] e2a = e2;

    // 4 -
    wire [7:0] e2ai = ~e2a;

    // 5 -
    wire [8:0] te = {1'b0, e1a} + {1'b0, e2ai};

    // 6 -
    wire ce = ~(te[8]);
    wire [9:0] tdetmp = ce ? {1'b0, ~te} : ({1'b0, te} + 1);
    wire [7:0] tde = tdetmp[7:0];

    // 7 -
    wire [4:0] de = tde > 8'd31 ? 5'd31 : tde[4:0];

    // 8 -
    wire sel = de == 5'b0 ? (m1a > m2a ? 1'b0 : 1'b1) : ce;

    // 9 -
    wire [24:0] mi = sel ? m1a : m2a;
    wire [24:0] ms = sel ? m2a : m1a;
    wire [7:0] ei = sel ? e1a : e2a;
    wire [7:0] es = sel ? e2a : e1a;
    wire ss = sel ? s2 : s1;

    // 10 -
    wire [55:0] mie = {mi, 31'b0};

    // 11 -
    wire [55:0] mia = (mie >> de);

    wire [31:0] y_if_add0 = e2 == 8'b0 ? x1 : x2;
    wire if_add0 = e1 == 8'b0 || e2 == 8'b0;

    // reg div

    // 12 -
    wire tstck = |(mia[28:0]);

    // 13 -
    wire [26:0] mye = s1 == s2 ? ({ms, 2'b0} + mia[55:29]) : ({ms, 2'b0} - mia[55:29]);

    // 14 -
    wire [7:0] esi = es + 1;

    // 15 -
    wire [7:0] eyd = mye[26] ? esi : es;
    wire [26:0] myd = mye[26] ? (mye >> 1) : mye;
    wire stck = mye[26] ? (tstck | mye[0]) : tstck;

    // 16 -
    wire [4:0] se;
    msb32 msb32_0 (
        .x({myd[25:0], 1'b1, 5'b0}),
        .y(se)
    );

    // 17 -
    wire [8:0] eyf = {1'b0, eyd} <= {4'b0, se} ? 0 : {1'b0, eyd} - {4'b0, se};

    // reg div

    // 18 -
    wire [7:0] eyr = eyf[7:0];
    wire [26:0] myf = eyf == 9'b0 ? (myd << (eyd[4:0] - 1)) : (myd << se);

    // 19 -
    wire [24:0] myr = (myf[1] && ~myf[0] && ~stck && myf[2])
        || (myf[1] && ~myf[0] && s1 == s2 && stck)
        || (myf[1] && myf[0]) ? (myf[26:2] + 25'b1) : myf[26:2];
    
    // 20 -
    wire [7:0] eyri = eyr + 8'b1;

    // 21 -
    wire [7:0] ey = myr[24] ? eyri : (myr[23:0] == 24'b0 ? 8'b0 : eyr);
    wire [22:0] my = myr[24] ? 23'b0 : myr[22:0];

    // 22 -
    wire sy = ss;

    assign y = if_add0 ? y_if_add0 : {sy, ey, my};

endmodule
