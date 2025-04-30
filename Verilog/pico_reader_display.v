//-----------------------------------------------------------------------------
// Top‑level: pico_reader_vga_display
//
// Reads 6‑bit humidity from ARDUINO_IO[10,8,6,4,2,0] and 3‑bit moisture from
// ARDUINO_IO[12,13,14], converts to BCD, and draws both on VGA as 7‑segment
// digits: humidity pair followed by '%' at (100,100), moisture single at (100,280).
//-----------------------------------------------------------------------------
module pico_reader_display (
    input  wire        MAX10_CLK1_50,
    input  wire  [0:0] KEY,
    input  wire [16:0] ARDUINO_IO,
    output wire        VGA_HS,
    output wire        VGA_VS,
    output wire [3:0]  VGA_R,
    output wire [3:0]  VGA_G,
    output wire [3:0]  VGA_B
);
    wire reset_n = KEY[0];

    // sync & sample
    reg [16:0] sync1, sync2;
    always @(posedge MAX10_CLK1_50 or negedge reset_n) begin
        if (!reset_n) begin sync1<=0; sync2<=0; end
        else begin sync1<=ARDUINO_IO; sync2<=sync1; end
    end
    wire [5:0] humidity = {
        sync2[10],sync2[8],sync2[6],
        sync2[4], sync2[2],sync2[0]
    };
    wire [2:0] moisture = {sync2[14],sync2[13],sync2[12]};

    // BCD conversion
    reg [3:0] tens, ones, m_digit;
    always @(*) begin
        tens   = humidity/10;
        ones   = humidity%10;
        m_digit= {1'b0, moisture};
    end

    // pixel clock
    reg pix_clk;
    always @(posedge MAX10_CLK1_50 or negedge reset_n)
        if (!reset_n) pix_clk<=0; else pix_clk<=~pix_clk;

    // VGA controller
    wire [9:0] px, py;
    wire       active;
    vga_640x480 vga_inst (
        .clk25   (pix_clk),
        .reset_n (reset_n),
        .hs      (VGA_HS),
        .vs      (VGA_VS),
        .active  (active),
        .x       (px),
        .y       (py)
    );

    // segment patterns
    wire [6:0] segT, segO, segM, segP;
    seven_seg_decoder decT(.digit(tens),   .segments(segT));
    seven_seg_decoder decO(.digit(ones),   .segments(segO));
    seven_seg_decoder decM(.digit(m_digit),.segments(segM));
    // Use code 15 for the '%' symbol (looks like 'P')
    localparam PERCENT_CODE = 4'd15;
    seven_seg_decoder decP(.digit(PERCENT_CODE), .segments(segP));

    wire [6:0] onT = ~segT, onO = ~segO, onM = ~segM, onP = ~segP;

    // geometry
    localparam X0=100, Y0=100, DX=80, TH=4, L=20;
    localparam XP = X0 + 2*DX; // X position for '%' sign
    localparam YM = Y0 + 3*TH + 2*L + 40; // Y position for moisture digit

    // draw
    reg pix_on;
    always @(*) begin
        pix_on = 0;
        if (active) begin
            // humidity tens (X0, Y0)
            if (onT[0]&&px>=X0+TH    &&px<X0+TH+L &&py>=Y0    &&py<Y0+TH)        pix_on=1; // a
            if (onT[1]&&px>=X0+TH+L  &&px<X0+TH+L+TH&&py>=Y0+TH&&py<Y0+TH+L)    pix_on=1; // b
            if (onT[2]&&px>=X0+TH+L  &&px<X0+TH+L+TH&&py>=Y0+2*TH+L&&py<Y0+2*TH+2*L) pix_on=1; // c
            if (onT[3]&&px>=X0+TH    &&px<X0+TH+L &&py>=Y0+2*TH+2*L&&py<Y0+3*TH+2*L)    pix_on=1; // d
            if (onT[4]&&px>=X0       &&px<X0+TH    &&py>=Y0+2*TH+L&&py<Y0+2*TH+2*L)    pix_on=1; // e
            if (onT[5]&&px>=X0       &&px<X0+TH    &&py>=Y0+TH    &&py<Y0+TH+L)         pix_on=1; // f
            if (onT[6]&&px>=X0+TH    &&px<X0+TH+L &&py>=Y0+TH+L&&py<Y0+2*TH+L)        pix_on=1; // g
            // humidity ones (X0+DX, Y0)
            if (onO[0]&&px>=X0+DX+TH    &&px<X0+DX+TH+L &&py>=Y0    &&py<Y0+TH)        pix_on=1; // a
            if (onO[1]&&px>=X0+DX+TH+L  &&px<X0+DX+TH+L+TH&&py>=Y0+TH&&py<Y0+TH+L)    pix_on=1; // b
            if (onO[2]&&px>=X0+DX+TH+L  &&px<X0+DX+TH+L+TH&&py>=Y0+2*TH+L&&py<Y0+2*TH+2*L) pix_on=1; // c
            if (onO[3]&&px>=X0+DX+TH    &&px<X0+DX+TH+L &&py>=Y0+2*TH+2*L&&py<Y0+3*TH+2*L)    pix_on=1; // d
            if (onO[4]&&px>=X0+DX       &&px<X0+DX+TH    &&py>=Y0+2*TH+L&&py<Y0+2*TH+2*L)    pix_on=1; // e
            if (onO[5]&&px>=X0+DX       &&px<X0+DX+TH    &&py>=Y0+TH    &&py<Y0+TH+L)         pix_on=1; // f
            if (onO[6]&&px>=X0+DX+TH    &&px<X0+DX+TH+L &&py>=Y0+TH+L&&py<Y0+2*TH+L)        pix_on=1; // g
            // percent sign (XP, Y0)
            if (onP[0]&&px>=XP+TH    &&px<XP+TH+L &&py>=Y0    &&py<Y0+TH)        pix_on=1; // a
            if (onP[1]&&px>=XP+TH+L  &&px<XP+TH+L+TH&&py>=Y0+TH&&py<Y0+TH+L)    pix_on=1; // b
            if (onP[2]&&px>=XP+TH+L  &&px<XP+TH+L+TH&&py>=Y0+2*TH+L&&py<Y0+2*TH+2*L) pix_on=1; // c
            if (onP[3]&&px>=XP+TH    &&px<XP+TH+L &&py>=Y0+2*TH+2*L&&py<Y0+3*TH+2*L)    pix_on=1; // d
            if (onP[4]&&px>=XP       &&px<XP+TH    &&py>=Y0+2*TH+L&&py<Y0+2*TH+2*L)    pix_on=1; // e
            if (onP[5]&&px>=XP       &&px<XP+TH    &&py>=Y0+TH    &&py<Y0+TH+L)         pix_on=1; // f
            if (onP[6]&&px>=XP+TH    &&px<XP+TH+L &&py>=Y0+TH+L&&py<Y0+2*TH+L)        pix_on=1; // g
            // moisture single (X0, YM)
            if (onM[0]&&px>=X0+TH    &&px<X0+TH+L &&py>=YM    &&py<YM+TH)        pix_on=1; // a
            if (onM[1]&&px>=X0+TH+L  &&px<X0+TH+L+TH&&py>=YM+TH&&py<YM+TH+L)    pix_on=1; // b
            if (onM[2]&&px>=X0+TH+L  &&px<X0+TH+L+TH&&py>=YM+2*TH+L&&py<YM+2*TH+2*L) pix_on=1; // c
            if (onM[3]&&px>=X0+TH    &&px<X0+TH+L &&py>=YM+2*TH+2*L&&py<YM+3*TH+2*L)    pix_on=1; // d
            if (onM[4]&&px>=X0       &&px<X0+TH    &&py>=YM+2*TH+L&&py<YM+2*TH+2*L)    pix_on=1; // e
            if (onM[5]&&px>=X0       &&px<X0+TH    &&py>=YM+TH    &&py<YM+TH+L)         pix_on=1; // f
            if (onM[6]&&px>=X0+TH    &&px<X0+TH+L &&py>=YM+TH+L&&py<YM+2*TH+L)        pix_on=1; // g
        end
    end

    wire [3:0] color = pix_on ? 4'hF : 4'h0; // White on Black
    assign VGA_R = color;
    assign VGA_G = color;
    assign VGA_B = color;
endmodule

//-----------------------------------------------------------------------------
// VGA 640×480 @60 Hz, 25 MHz pixel clock
//-----------------------------------------------------------------------------
module vga_640x480 (
    input  wire      clk25,
    input  wire      reset_n,
    output reg       hs,
    output reg       vs,
    output      [9:0] x,
    output      [9:0] y,
    output      active
);
    localparam H_VISIBLE=640, H_F=16, H_S=96, H_B=48, H_T=800;
    localparam V_VISIBLE=480, V_F=10, V_S=2,  V_B=33, V_T=525;
    reg [9:0] hcnt, vcnt;
    always @(posedge clk25 or negedge reset_n) begin
        if (!reset_n) begin hcnt<=0; vcnt<=0; end
        else begin
            if (hcnt==H_T-1) begin
                hcnt<=0;
                if (vcnt==V_T-1) vcnt<=0; else vcnt<=vcnt+1;
            end else hcnt<=hcnt+1;
        end
    end
    always @(*) begin
        hs = ~((hcnt>=H_VISIBLE+H_F)&&(hcnt<H_VISIBLE+H_F+H_S));
        vs = ~((vcnt>=V_VISIBLE+V_F)&&(vcnt<V_VISIBLE+V_F+V_S));
    end
    assign x = (hcnt<H_VISIBLE)?hcnt:10'd0;
    assign y = (vcnt<V_VISIBLE)?vcnt:10'd0;
    assign active = (hcnt<H_VISIBLE)&&(vcnt<V_VISIBLE);
endmodule

//-----------------------------------------------------------------------------
// seven_seg_decoder: 4‑bit digit → active‑low gfedcba
//-----------------------------------------------------------------------------
module seven_seg_decoder (
    input  wire [3:0] digit,
    output reg  [6:0] segments // gfedcba
);
    localparam ZERO=7'b1000000, ONE=7'b1111001, TWO=7'b0100100,
               THREE=7'b0110000, FOUR=7'b0011001, FIVE=7'b0010010,
               SIX=7'b0000010, SEVEN=7'b1111000, EIGHT=7'b0000000,
               NINE=7'b0010000, H_=7'b0001001, M_=7'b1010101,
               E_=7'b0000110, DASH=7'b0111111, P_=7'b0001100, // 'P' for Percent
               BLANK=7'b1111111;
    always @(*) begin
        case(digit)
            4'd0:  segments=ZERO;
            4'd1:  segments=ONE;
            4'd2:  segments=TWO;
            4'd3:  segments=THREE;
            4'd4:  segments=FOUR;
            4'd5:  segments=FIVE;
            4'd6:  segments=SIX;
            4'd7:  segments=SEVEN;
            4'd8:  segments=EIGHT;
            4'd9:  segments=NINE;
            4'd10: segments=H_;    // Hex A
            4'd11: segments=M_;    // Hex B (using 'M')
            4'd12: segments=E_;    // Hex C (using 'E')
            4'd13: segments=DASH; // Hex D
            4'd14: segments=DASH; // Hex E (using Dash)
            4'd15: segments=P_;    // Hex F (using 'P' for '%')
            default:segments=BLANK;
        endcase
    end
endmodule
