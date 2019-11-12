module fadd (
    input wire [31:0] x1,
    input wire [31:0] x2,
    output wire [31:0] y,
    input wire ready,
    output wire valid,
    input wire clk,
    input wire rstn );

    assign valid = ready; // とりあえず

    // 1
    wire s1 = x1[31];
    wire s2 = x2[31];
    wire [7:0] e1 = x1[30:23];
    wire [7:0] e2 = x2[30:23];
    wire [22:0] m1 = x1[22:0];
    wire [22:0] m2 = x2[22:0];

    // 2
    wire [24:0] m1a = (e1 == 8'b0) ? {2'b0, m1} : {2'b1, m1};
    wire [24:0] m2a = (e2 == 8'b0) ? {2'b0, m2} : {2'b1, m2};

    // 3
    wire [7:0] e1a = (e1 == 8'b0) ? 8'b1 : e1;
    wire [7:0] e2a = (e2 == 8'b0) ? 8'b1 : e2;

    // 4 -
    wire [7:0] e2ai = ~e2a;

    // 5 -
    wire [8:0] te = {1'b0, e1a} + {1'b0, e2ai};

    // 6 -
    wire ce = ~(te[8]);
    wire [9:0] tdetmp = (ce == 1'b0) ? ({1'b0, te} + 1) : {1'b0, ~te};
    wire [7:0] tde = tdetmp[7:0];

    // 7 -
    wire [4:0] de = (tde > 8'd31) ? 5'd31 : tde[4:0];

    // 8 -
    wire sel = (de == 5'b0) ? (m1a > m2a ? 1'b0 : 1'b1) : ce;

    // 9 -
    wire [24:0] ms = (sel == 1'b0) ? m1a : m2a;
    wire [24:0] mi = (sel == 1'b0) ? m2a : m1a;
    wire [7:0] es = (sel == 1'b0) ? e1a : e2a;
    wire [7:0] ei = (sel == 1'b0) ? e2a : e1a;
    wire ss = (sel == 1'b0) ? s1 : s2;

    // 10 -
    wire [55:0] mie = {mi, 31'b0};

    // 11 -
    wire [55:0] mia = (mie >> de);

    // 12 -
    wire tstck = |(mia[28:0]);

    // 13 -
    wire [26:0] mye = (s1 == s2) ? ({ms, 2'b0} + mia[55:29]) : ({ms, 2'b0} - mia[55:29]);

    // 14 -
    wire [7:0] esi = es + 1;

    // 15 -
    wire [7:0] eyd = (mye[26] == 1'b1) ? ((esi == 8'd255) ? 8'd255 : esi) : es;
    wire [26:0] myd = (mye[26] == 1'b1) ? ((esi == 8'd255) ? {2'b01, 25'b0} : (mye >> 1)) : mye;
    wire stck = (mye[26] == 1'b1) ? ((esi == 8'd255) ? 1'b0 : (tstck | mye[0])) : tstck;

    // 16 -
    wire [4:0] se = myd[25] == 1'b1 ? 5'd0:
        (myd[24] == 1'b1 ? 5'd1 :
        (myd[23] == 1'b1 ? 5'd2 :
        (myd[22] == 1'b1 ? 5'd3 :
        (myd[21] == 1'b1 ? 5'd4 :
        (myd[20] == 1'b1 ? 5'd5 :
        (myd[19] == 1'b1 ? 5'd6 :
        (myd[18] == 1'b1 ? 5'd7 :
        (myd[17] == 1'b1 ? 5'd8 :
        (myd[16] == 1'b1 ? 5'd9 :
        (myd[15] == 1'b1 ? 5'd10 :
        (myd[14] == 1'b1 ? 5'd11 :
        (myd[13] == 1'b1 ? 5'd12 :
        (myd[12] == 1'b1 ? 5'd13 :
        (myd[11] == 1'b1 ? 5'd14 :
        (myd[10] == 1'b1 ? 5'd15 :
        (myd[9] == 1'b1 ? 5'd16 :
        (myd[8] == 1'b1 ? 5'd17 :
        (myd[7] == 1'b1 ? 5'd18 :
        (myd[6] == 1'b1 ? 5'd19 :
        (myd[5] == 1'b1 ? 5'd20 :
        (myd[4] == 1'b1 ? 5'd21 :
        (myd[3] == 1'b1 ? 5'd22 :
        (myd[2] == 1'b1 ? 5'd23 :
        (myd[1] == 1'b1 ? 5'd24 :
        (myd[0] == 1'b1 ? 5'd25 :
        5'd26)))))))))))))))))))))))));

    // 17 -
    wire [8:0] eyf = {1'b0, eyd} < {4'b0, se} ? 0 : {1'b0, eyd} - {4'b0, se};

    // 18 -
    wire [7:0] eyr = (eyf > 9'b0) ? eyf[7:0] : 8'b0;
    wire [26:0] myf = (eyf > 9'b0) ? (myd << se) : (myd << (eyd[4:0] - 1));

    // 19 -
    wire [24:0] myr = (myf[1] == 1'b1 && myf[0] == 1'b0 && stck == 1'b0 && myf[2] == 1'b1)
        || (myf[1] == 1'b1 && myf[0] == 1'b0 && s1 == s2 && stck == 1'b1)
        || (myf[1] == 1'b1 && myf[0] == 1'b1) ? (myf[26:2] + 25'b1) : myf[26:2];
    
    // 20 -
    wire [7:0] eyri = eyr + 8'b1;

    // 21 -
    wire [7:0] ey = (myr[24] == 1'b1) ? eyri : ((myr[23:0] == 24'b0) ? 8'b0 : eyr);
    wire [22:0] my = (myr[24] == 1'b1) ? 23'b0 : ((myr[23:0] == 24'b0) ? 23'b0 : myr[22:0]);

    // 22 -
    wire sy = (ey == 8'b0 && my == 23'b0) ? (s1 & s2) : ss;

    // 23 -
    wire nzm1 = |(m1[22:0]);
    wire nzm2 = |(m2[22:0]);
    assign y = (e1 == 8'd255 && e2 != 8'd255) ? {s1, 8'd255, nzm1, m1[21:0]}
        : ((e2 == 8'd255 && e1 != 8'd255) ? {s2, 8'd255, nzm2, m2[21:0]}
        : ((e1 == 8'd255 && e2 == 8'd255 && nzm2) ? {s2, 8'd255, 1'b1, m2[21:0]}
        : ((e1 == 8'd255 && e1 == 8'd255 && nzm1) ? {s1, 8'd255, 1'b1, m1[21:0]}
        : ((e1 == 8'd255 && e2 == 8'd255 && s1 == s2) ? {s1, 8'd255, 23'b0}
        : ((e1 == 8'd255 && e2 == 8'd255) ? {1'b1, 8'd255, 1'b1, 22'b0}
        : {sy, ey, my})))));

endmodule
