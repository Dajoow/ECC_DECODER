`timescale 1ns / 1ps
// =============================================================================
// 文件名称  : seg_driver.v
// 模块功能  : 2 组 4 位一体八段共阳极数码管动态扫描与字符显示
// 时钟参数  : 默认 50MHz 输入时钟，产生约 1kHz 位扫描节拍
//
// 接口说明：
//   display_chars is eight 5-bit characters from left to right.
//   TeamA mode uses the first 4 digits for status and the last 4 digits for
//   raw_data/decoded_data HEX display.
//
// 共阳极硬件说明：
//   dig[7:0] = {h(dp),g,f,e,d,c,b,a}
//   段码低电平点亮，高电平熄灭。
//   sel[7:0] 位选高电平有效。
// =============================================================================

module seg_driver (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [39:0] display_chars,

    output reg  [7:0] sel,
    output reg  [7:0] dig
);

    parameter integer CLK_FREQ_HZ  = 50000000;
    parameter integer SCAN_FREQ_HZ = 1000;
    localparam [15:0] DIV_MAX = (CLK_FREQ_HZ / SCAN_FREQ_HZ) - 1;

    localparam [4:0] CHAR_0     = 5'h00;
    localparam [4:0] CHAR_1     = 5'h01;
    localparam [4:0] CHAR_2     = 5'h02;
    localparam [4:0] CHAR_3     = 5'h03;
    localparam [4:0] CHAR_4     = 5'h04;
    localparam [4:0] CHAR_5     = 5'h05;
    localparam [4:0] CHAR_6     = 5'h06;
    localparam [4:0] CHAR_7     = 5'h07;
    localparam [4:0] CHAR_8     = 5'h08;
    localparam [4:0] CHAR_9     = 5'h09;
    localparam [4:0] CHAR_A     = 5'h0A;
    localparam [4:0] CHAR_B     = 5'h0B;
    localparam [4:0] CHAR_C     = 5'h0C;
    localparam [4:0] CHAR_D     = 5'h0D;
    localparam [4:0] CHAR_E     = 5'h0E;
    localparam [4:0] CHAR_F     = 5'h0F;
    localparam [4:0] CHAR_BLANK = 5'h10;
    localparam [4:0] CHAR_G     = 5'h11;
    localparam [4:0] CHAR_O     = 5'h12;
    localparam [4:0] CHAR_I     = 5'h13;
    localparam [4:0] CHAR_X     = 5'h14;
    localparam [4:0] CHAR_R     = 5'h15;

    reg [15:0] div_cnt;
    reg [2:0] scan_sel;
    reg [4:0] active_char;
    reg [7:0] dig_on_high;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_cnt  <= 16'd0;
            scan_sel <= 3'd0;
        end else begin
            if (div_cnt == DIV_MAX) begin
                div_cnt  <= 16'd0;
                scan_sel <= scan_sel + 3'd1;
            end else begin
                div_cnt <= div_cnt + 16'd1;
            end
        end
    end

    always @(*) begin
        case (scan_sel)
            3'd0: begin
                sel         = 8'b1111_1110;
                active_char = display_chars[39:35];
            end
            3'd1: begin
                sel         = 8'b1111_1101;
                active_char = display_chars[34:30];
            end
            3'd2: begin
                sel         = 8'b1111_1011;
                active_char = display_chars[29:25];
            end
            3'd3: begin
                sel         = 8'b1111_0111;
                active_char = display_chars[24:20];
            end
            3'd4: begin
                sel         = 8'b1110_1111;
                active_char = display_chars[19:15];
            end
            3'd5: begin
                sel         = 8'b1101_1111;
                active_char = display_chars[14:10];
            end
            3'd6: begin
                sel         = 8'b1011_1111;
                active_char = display_chars[9:5];
            end
            default: begin
                sel         = 8'b0111_1111;
                active_char = display_chars[4:0];
            end
        endcase
    end

    always @(*) begin
        case (active_char)
            // dig_on_high[7:0] = {dp,g,f,e,d,c,b,a}.
            CHAR_0:     dig_on_high = 8'b0_0_1_1_1_1_1_1; // 0
            CHAR_1:     dig_on_high = 8'b0_0_0_0_0_1_1_0; // 1
            CHAR_2:     dig_on_high = 8'b0_1_0_1_1_0_1_1; // 2
            CHAR_3:     dig_on_high = 8'b0_1_0_0_1_1_1_1; // 3
            CHAR_4:     dig_on_high = 8'b0_1_1_0_0_1_1_0; // 4
            CHAR_5:     dig_on_high = 8'b0_1_1_0_1_1_0_1; // 5
            CHAR_6:     dig_on_high = 8'b0_1_1_1_1_1_0_1; // 6
            CHAR_7:     dig_on_high = 8'b0_0_0_0_0_1_1_1; // 7
            CHAR_8:     dig_on_high = 8'b0_1_1_1_1_1_1_1; // 8
            CHAR_9:     dig_on_high = 8'b0_1_1_0_1_1_1_1; // 9
            CHAR_A:     dig_on_high = 8'b0_1_1_1_0_1_1_1; // A
            CHAR_B:     dig_on_high = 8'b0_1_1_1_1_1_0_0; // b
            CHAR_C:     dig_on_high = 8'b0_0_1_1_1_0_0_1; // C
            CHAR_D:     dig_on_high = 8'b0_1_0_1_1_1_1_0; // d
            CHAR_E:     dig_on_high = 8'b0_1_1_1_1_0_0_1; // E
            CHAR_F:     dig_on_high = 8'b0_1_1_1_0_0_0_1; // F
            CHAR_G:     dig_on_high = 8'b0_0_1_1_1_1_0_1; // G
            CHAR_O:     dig_on_high = 8'b0_1_0_1_1_1_0_0; // o
            CHAR_I:     dig_on_high = 8'b0_0_0_0_0_1_1_0; // I/1
            CHAR_X:     dig_on_high = 8'b0_1_1_1_0_1_1_0; // X approximate
            CHAR_R:     dig_on_high = 8'b0_1_0_1_0_0_0_0; // r
            CHAR_BLANK: dig_on_high = 8'b0_0_0_0_0_0_0_0;
            default:    dig_on_high = 8'b0_0_0_0_0_0_0_0;
        endcase

        // 共阳极段选低有效，故对“应点亮”段码取反输出。
        dig = ~dig_on_high;
    end

endmodule
