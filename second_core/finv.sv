// a lot of bugs!!

module finv (
    input wire [31:0] x,
    output wire [31:0] y,
    input wire clk );

    wire s = x[31];
    wire [7:0] e = x[30:23];
    wire [22:0] m = x[22:0];

    wire [22:0] init_m;

    finv_init_m finv_init_m0 (m[22:17], init_m[22:17]);
    assign init_m[16:0] = '0;

    function [24:0] round25 (input [25:0] in);
        begin
            round25 = in[25:1] + {24'b0, in[1] & in[0]};
        end
    endfunction

    wire [23:0] m_x = {1'b1, m};

    wire [24:0] m_phase1_t = {m[22:17] == '0 ? 2'b10 : 2'b01, init_m};
    wire [48:0] m_phase1_xt = $unsigned(m_x) * $unsigned(m_phase1_t); // m_phase1_xt[48] == 0
    wire [24:0] m_phase1_xt_rnd = round25(m_phase1_xt[48:23]);
    wire [24:0] m_phase1_2mxt = {1'b1, 24'b0} - m_phase1_xt_rnd; // m_phase1_2mxt[24] == 0
    wire [48:0] m_phase1_t2mxt = $unsigned(m_phase1_t) * $unsigned(m_phase1_2mxt[23:0]);
    wire [24:0] m_phase1_t2mxt_rnd = round25(m_phase1_t2mxt[48:23]);

    wire [24:0] m_phase2_t = m_phase1_t2mxt_rnd;
    wire [48:0] m_phase2_xt = $unsigned(m_x) * $unsigned(m_phase2_t); // m_phase2_xt[48] == 0
    wire [24:0] m_phase2_xt_rnd = round25(m_phase2_xt[48:23]);
    wire [24:0] m_phase2_2mxt = {1'b1, 24'b0} - m_phase2_xt_rnd; // m_phase2_2mxt[24] == 0
    wire [48:0] m_phase2_t2mxt = $unsigned(m_phase2_t) * $unsigned(m_phase2_2mxt[23:0]);
    wire [24:0] m_phase2_t2mxt_rnd = round25(m_phase2_t2mxt[48:23]);

    wire carry = m_phase2_t2mxt_rnd[24];
    wire [22:0] mlast = carry ? m_phase2_t2mxt_rnd[23:1] : m_phase2_t2mxt_rnd[22:0];

    wire [7:0] elast = 8'd253 - e + {7'b0, carry};

    assign y[31] = s;
    assign y[30:0] = e == 8'b0 ? {31'b0} : {elast, mlast};

endmodule
