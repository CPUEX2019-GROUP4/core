`default_nettype none

module fdiv (
  input  wire [31:0] x1,
  input  wire [31:0] x2,
  output wire [31:0]  y
);

  wire        s1 = x1[31:31];
  wire        s2 = x2[31:31];
  wire [ 7:0] e1 = x1[30:23];
  wire [ 7:0] e2 = x2[30:23];
  wire [23:0] m1 =(e1==0) ? {1'b0,x1[22:0]} : {1'b1,x1[22:0]};
  wire [23:0] m2 =(e2==0) ? {1'b0,x2[22:0]} : {1'b1,x2[22:0]};

  wire [47:0] dividend = {m1,24'b0}; // 筆算の被除数
  wire [23:0] divisor  =  m2       ; // 筆算の除数
  
  wire [47:0] q        ; // quotient
  wire [47:0] q_rounded; // quotient を丸めたもの.
  wire [47:0] r [48]   ; // remainder. 筆算の過程に出てくる48個すべて.

 
  wire signed [ 7:0] e_offset;  // 指数部をどれくらいズラすか.
  wire signed [ 8:0] e_crude ;  // inf,nan,denormalizeなど無考慮の指数部.
  wire               inf;       // infになったら立てる.
  wire               dnm;       // denormalizeが必要なら立てる.
  wire        [ 8:0] dnm_rshift;// denormalizeするとき必要なシフト量.

  assign y[31:31] = s1 ^ s2;
  assign y[30:23] =
    (dnm) ?   0 :
    (inf) ? 255 : e_crude[7:0];
  assign y[22: 0] =
    (inf)            ? 0 :
    (dnm)            ? 0 :
    (e_offset == 23) ? q_rounded[46:24]:
    (e_offset == 22) ? q_rounded[45:23]:
    (e_offset == 21) ? q_rounded[44:22]:
    (e_offset == 20) ? q_rounded[43:21]:
    (e_offset == 19) ? q_rounded[42:20]:
    (e_offset == 18) ? q_rounded[41:19]:
    (e_offset == 17) ? q_rounded[40:18]:
    (e_offset == 16) ? q_rounded[39:17]:
    (e_offset == 15) ? q_rounded[38:16]:
    (e_offset == 14) ? q_rounded[37:15]:
    (e_offset == 13) ? q_rounded[36:14]:
    (e_offset == 12) ? q_rounded[35:13]:
    (e_offset == 11) ? q_rounded[34:12]:
    (e_offset == 10) ? q_rounded[33:11]:
    (e_offset ==  9) ? q_rounded[32:10]:
    (e_offset ==  8) ? q_rounded[31: 9]:
    (e_offset ==  7) ? q_rounded[30: 8]:
    (e_offset ==  6) ? q_rounded[29: 7]:
    (e_offset ==  5) ? q_rounded[28: 6]:
    (e_offset ==  4) ? q_rounded[27: 5]:
    (e_offset ==  3) ? q_rounded[26: 4]:
    (e_offset ==  2) ? q_rounded[25: 3]:
    (e_offset ==  1) ? q_rounded[24: 2]:
    (e_offset ==  0) ? q_rounded[23: 1]:
    (e_offset == -1) ? q_rounded[22: 0]:
    (e_offset == -2) ?{q_rounded[21: 0], 1'b0}:
    (e_offset == -3) ?{q_rounded[20: 0], 2'b0}:
    (e_offset == -4) ?{q_rounded[19: 0], 3'b0}:
    (e_offset == -5) ?{q_rounded[18: 0], 4'b0}:
    (e_offset == -6) ?{q_rounded[17: 0], 5'b0}:
    (e_offset == -7) ?{q_rounded[16: 0], 6'b0}:
    (e_offset == -8) ?{q_rounded[15: 0], 7'b0}:
    (e_offset == -9) ?{q_rounded[14: 0], 8'b0}:
    (e_offset ==-10) ?{q_rounded[13: 0], 9'b0}:
    (e_offset ==-11) ?{q_rounded[12: 0],10'b0}:
    (e_offset ==-12) ?{q_rounded[11: 0],11'b0}:
    (e_offset ==-13) ?{q_rounded[10: 0],12'b0}:
    (e_offset ==-14) ?{q_rounded[ 9: 0],13'b0}:
    (e_offset ==-15) ?{q_rounded[ 8: 0],14'b0}:
    (e_offset ==-16) ?{q_rounded[ 7: 0],15'b0}:
    (e_offset ==-17) ?{q_rounded[ 6: 0],16'b0}:
    (e_offset ==-18) ?{q_rounded[ 5: 0],17'b0}:
    (e_offset ==-19) ?{q_rounded[ 4: 0],18'b0}:
    (e_offset ==-20) ?{q_rounded[ 3: 0],19'b0}:
    (e_offset ==-21) ?{q_rounded[ 2: 0],20'b0}:
    (e_offset ==-22) ?{q_rounded[ 1: 0],21'b0}:
    (e_offset ==-23) ?{q_rounded[ 0: 0],22'b0}: 0;

  assign e_offset =
    (q_rounded[47:47])? 23:
    (q_rounded[46:46])? 22:
    (q_rounded[45:45])? 21:
    (q_rounded[44:44])? 20:
    (q_rounded[43:43])? 19:
    (q_rounded[42:42])? 18:
    (q_rounded[41:41])? 17:
    (q_rounded[40:40])? 16:
    (q_rounded[39:39])? 15:
    (q_rounded[38:38])? 14:
    (q_rounded[37:37])? 13:
    (q_rounded[36:36])? 12:
    (q_rounded[35:35])? 11:
    (q_rounded[34:34])? 10:
    (q_rounded[33:33])?  9:
    (q_rounded[32:32])?  8:
    (q_rounded[31:31])?  7:
    (q_rounded[30:30])?  6:
    (q_rounded[29:29])?  5:
    (q_rounded[28:28])?  4:
    (q_rounded[27:27])?  3:
    (q_rounded[26:26])?  2:
    (q_rounded[25:25])?  1:
    (q_rounded[24:24])?  0:
    (q_rounded[23:23])? -1:
    (q_rounded[22:22])? -2:
    (q_rounded[21:21])? -3:
    (q_rounded[20:20])? -4:
    (q_rounded[19:19])? -5:
    (q_rounded[18:18])? -6:
    (q_rounded[17:17])? -7:
    (q_rounded[16:16])? -8:
    (q_rounded[15:15])? -9:
    (q_rounded[14:14])?-10:
    (q_rounded[13:13])?-11:
    (q_rounded[12:12])?-12:
    (q_rounded[11:11])?-13:
    (q_rounded[10:10])?-14:
    (q_rounded[ 9: 9])?-15:
    (q_rounded[ 8: 8])?-16:
    (q_rounded[ 7: 7])?-17:
    (q_rounded[ 6: 6])?-18:
    (q_rounded[ 5: 5])?-19:
    (q_rounded[ 4: 4])?-20:
    (q_rounded[ 3: 3])?-21:
    (q_rounded[ 2: 2])?-22:
    (q_rounded[ 1: 1])?-23: -24;
  
  assign e_crude    = signed'({1'b0,e1})-signed'({1'b0,e2})+9'(e_offset)+9'(signed'(127));
  assign inf        = (e_crude >= 255);
  assign dnm        = (e_crude <=   0);
  assign dnm_rshift = (dnm) ? ~(e_crude) : 0; // (-1)*e_crude+1 と同じ.

  // 以下, 割り算の筆算を頑張るパート.
  // あとあとクリティカルパスの分割をするかも.
  assign r[47]    = (71'(dividend) >= {divisor,47'b0}) ? dividend-{divisor[0:0],47'b0}:dividend;
  assign r[46]    = (70'(r[47]) >= {divisor,46'b0}) ? r[47]-{divisor[ 1:0],46'b0}:r[47];
  assign r[45]    = (69'(r[46]) >= {divisor,45'b0}) ? r[46]-{divisor[ 2:0],45'b0}:r[46];
  assign r[44]    = (68'(r[45]) >= {divisor,44'b0}) ? r[45]-{divisor[ 3:0],44'b0}:r[45];
  assign r[43]    = (67'(r[44]) >= {divisor,43'b0}) ? r[44]-{divisor[ 4:0],43'b0}:r[44];
  assign r[42]    = (66'(r[43]) >= {divisor,42'b0}) ? r[43]-{divisor[ 5:0],42'b0}:r[43];
  assign r[41]    = (65'(r[42]) >= {divisor,41'b0}) ? r[42]-{divisor[ 6:0],41'b0}:r[42];
  assign r[40]    = (64'(r[41]) >= {divisor,40'b0}) ? r[41]-{divisor[ 7:0],40'b0}:r[41];
  assign r[39]    = (63'(r[40]) >= {divisor,39'b0}) ? r[40]-{divisor[ 8:0],39'b0}:r[40];
  assign r[38]    = (62'(r[39]) >= {divisor,38'b0}) ? r[39]-{divisor[ 9:0],38'b0}:r[39];
  assign r[37]    = (61'(r[38]) >= {divisor,37'b0}) ? r[38]-{divisor[10:0],37'b0}:r[38];
  assign r[36]    = (60'(r[37]) >= {divisor,36'b0}) ? r[37]-{divisor[11:0],36'b0}:r[37];
  assign r[35]    = (59'(r[36]) >= {divisor,35'b0}) ? r[36]-{divisor[12:0],35'b0}:r[36];
  assign r[34]    = (58'(r[35]) >= {divisor,34'b0}) ? r[35]-{divisor[13:0],34'b0}:r[35];
  assign r[33]    = (57'(r[34]) >= {divisor,33'b0}) ? r[34]-{divisor[14:0],33'b0}:r[34];
  assign r[32]    = (56'(r[33]) >= {divisor,32'b0}) ? r[33]-{divisor[15:0],32'b0}:r[33];
  assign r[31]    = (55'(r[32]) >= {divisor,31'b0}) ? r[32]-{divisor[16:0],31'b0}:r[32];
  assign r[30]    = (54'(r[31]) >= {divisor,30'b0}) ? r[31]-{divisor[17:0],30'b0}:r[31];
  assign r[29]    = (53'(r[30]) >= {divisor,29'b0}) ? r[30]-{divisor[18:0],29'b0}:r[30];
  assign r[28]    = (52'(r[29]) >= {divisor,28'b0}) ? r[29]-{divisor[19:0],28'b0}:r[29];
  assign r[27]    = (51'(r[28]) >= {divisor,27'b0}) ? r[28]-{divisor[20:0],27'b0}:r[28];
  assign r[26]    = (50'(r[27]) >= {divisor,26'b0}) ? r[27]-{divisor[21:0],26'b0}:r[27];
  assign r[25]    = (49'(r[26]) >= {divisor,25'b0}) ? r[26]-{divisor[22:0],25'b0}:r[26];
  assign r[24]    = (    r[25]  >= {divisor,24'b0}) ? r[25]-{divisor[23:0],24'b0}:r[25];
  assign r[23]    = (r[24] >= 48'({divisor,23'b0})) ? r[24]-48'({divisor,23'b0}):r[24];
  assign r[22]    = (r[23] >= 48'({divisor,22'b0})) ? r[23]-48'({divisor,22'b0}):r[23];
  assign r[21]    = (r[22] >= 48'({divisor,21'b0})) ? r[22]-48'({divisor,21'b0}):r[22];
  assign r[20]    = (r[21] >= 48'({divisor,20'b0})) ? r[21]-48'({divisor,20'b0}):r[21];
  assign r[19]    = (r[20] >= 48'({divisor,19'b0})) ? r[20]-48'({divisor,19'b0}):r[20];
  assign r[18]    = (r[19] >= 48'({divisor,18'b0})) ? r[19]-48'({divisor,18'b0}):r[19];
  assign r[17]    = (r[18] >= 48'({divisor,17'b0})) ? r[18]-48'({divisor,17'b0}):r[18];
  assign r[16]    = (r[17] >= 48'({divisor,16'b0})) ? r[17]-48'({divisor,16'b0}):r[17];
  assign r[15]    = (r[16] >= 48'({divisor,15'b0})) ? r[16]-48'({divisor,15'b0}):r[16];
  assign r[14]    = (r[15] >= 48'({divisor,14'b0})) ? r[15]-48'({divisor,14'b0}):r[15];
  assign r[13]    = (r[14] >= 48'({divisor,13'b0})) ? r[14]-48'({divisor,13'b0}):r[14];
  assign r[12]    = (r[13] >= 48'({divisor,12'b0})) ? r[13]-48'({divisor,12'b0}):r[13];
  assign r[11]    = (r[12] >= 48'({divisor,11'b0})) ? r[12]-48'({divisor,11'b0}):r[12];
  assign r[10]    = (r[11] >= 48'({divisor,10'b0})) ? r[11]-48'({divisor,10'b0}):r[11];
  assign r[ 9]    = (r[10] >= 48'({divisor, 9'b0})) ? r[10]-48'({divisor, 9'b0}):r[10];
  assign r[ 8]    = (r[ 9] >= 48'({divisor, 8'b0})) ? r[ 9]-48'({divisor, 8'b0}):r[ 9];
  assign r[ 7]    = (r[ 8] >= 48'({divisor, 7'b0})) ? r[ 8]-48'({divisor, 7'b0}):r[ 8];
  assign r[ 6]    = (r[ 7] >= 48'({divisor, 6'b0})) ? r[ 7]-48'({divisor, 6'b0}):r[ 7];
  assign r[ 5]    = (r[ 6] >= 48'({divisor, 5'b0})) ? r[ 6]-48'({divisor, 5'b0}):r[ 6];
  assign r[ 4]    = (r[ 5] >= 48'({divisor, 4'b0})) ? r[ 5]-48'({divisor, 4'b0}):r[ 5];
  assign r[ 3]    = (r[ 4] >= 48'({divisor, 3'b0})) ? r[ 4]-48'({divisor, 3'b0}):r[ 4];
  assign r[ 2]    = (r[ 3] >= 48'({divisor, 2'b0})) ? r[ 3]-48'({divisor, 2'b0}):r[ 3];
  assign r[ 1]    = (r[ 2] >= 48'({divisor, 1'b0})) ? r[ 2]-48'({divisor, 1'b0}):r[ 2];
  assign r[ 0]    = (r[ 1] >= 48'( divisor       )) ? r[ 1]-48'( divisor       ):r[ 1];
  
  assign q[47] = (71'(dividend) >= 71'({divisor,47'b0}));
  assign q[46] = (70'(r[47]) >= 70'({divisor,46'b0}));
  assign q[45] = (69'(r[46]) >= 69'({divisor,45'b0}));
  assign q[44] = (68'(r[45]) >= 68'({divisor,44'b0}));
  assign q[43] = (67'(r[44]) >= {divisor,43'b0});
  assign q[42] = (66'(r[43]) >= {divisor,42'b0});
  assign q[41] = (65'(r[42]) >= {divisor,41'b0});
  assign q[40] = (64'(r[41]) >= {divisor,40'b0});
  assign q[39] = (63'(r[40]) >= {divisor,39'b0});
  assign q[38] = (62'(r[39]) >= {divisor,38'b0});
  assign q[37] = (61'(r[38]) >= {divisor,37'b0});
  assign q[36] = (60'(r[37]) >= {divisor,36'b0});
  assign q[35] = (59'(r[36]) >= {divisor,35'b0});
  assign q[34] = (58'(r[35]) >= {divisor,34'b0});
  assign q[33] = (57'(r[34]) >= {divisor,33'b0});
  assign q[32] = (56'(r[33]) >= {divisor,32'b0});
  assign q[31] = (55'(r[32]) >= {divisor,31'b0});
  assign q[30] = (54'(r[31]) >= {divisor,30'b0});
  assign q[29] = (53'(r[30]) >= {divisor,29'b0});
  assign q[28] = (52'(r[29]) >= {divisor,28'b0});
  assign q[27] = (51'(r[28]) >= {divisor,27'b0});
  assign q[26] = (50'(r[27]) >= {divisor,26'b0});
  assign q[25] = (49'(r[26]) >= {divisor,25'b0});
  assign q[24] = (    r[25] >= {divisor,24'b0});
  assign q[23] = (    r[24] >= 48'({divisor,23'b0}));
  assign q[22] = (    r[23] >= 48'({divisor,22'b0}));
  assign q[21] = (    r[22] >= 48'({divisor,21'b0}));
  assign q[20] = (    r[21] >= 48'({divisor,20'b0}));
  assign q[19] = (    r[20] >= 48'({divisor,19'b0}));
  assign q[18] = (    r[19] >= 48'({divisor,18'b0}));
  assign q[17] = (    r[18] >= 48'({divisor,17'b0}));
  assign q[16] = (    r[17] >= 48'({divisor,16'b0}));
  assign q[15] = (    r[16] >= 48'({divisor,15'b0}));
  assign q[14] = (    r[15] >= 48'({divisor,14'b0}));
  assign q[13] = (    r[14] >= 48'({divisor,13'b0}));
  assign q[12] = (    r[13] >= 48'({divisor,12'b0}));
  assign q[11] = (    r[12] >= 48'({divisor,11'b0}));
  assign q[10] = (    r[11] >= 48'({divisor,10'b0}));
  assign q[ 9] = (    r[10] >= 48'({divisor, 9'b0}));
  assign q[ 8] = (    r[ 9] >= 48'({divisor, 8'b0}));
  assign q[ 7] = (    r[ 8] >= 48'({divisor, 7'b0}));
  assign q[ 6] = (    r[ 7] >= 48'({divisor, 6'b0}));
  assign q[ 5] = (    r[ 6] >= 48'({divisor, 5'b0}));
  assign q[ 4] = (    r[ 5] >= 48'({divisor, 4'b0}));
  assign q[ 3] = (    r[ 4] >= 48'({divisor, 3'b0}));
  assign q[ 2] = (    r[ 3] >= 48'({divisor, 2'b0}));
  assign q[ 1] = (    r[ 2] >= 48'({divisor, 1'b0}));
  assign q[ 0] = (    r[ 1] >= 48'( divisor       ));
  assign q_rounded=({r[0],1'b0} >= divisor) ? q+1:q; // 四捨五入.
endmodule
`default_nettype wire
