`timescale 1ns / 1ps
// =============================================================================
// 文件名称  : seg_driver.v
// 模块功能  : 2 组 4 位一体八段共阳极数码管动态扫描与字符显示
// 时钟参数  : 默认 50MHz 输入时钟，产生约 1kHz 位扫描节拍
//
// 接口说明：
//   display_chars[15:12] -> 左起第 1 个数码管，SEL0
//   display_chars[11:8]  -> 左起第 2 个数码管，SEL1
//   display_chars[7:4]   -> 左起第 3 个数码管，SEL2
//   display_chars[3:0]   -> 左起第 4 个数码管，SEL3
//   本工程只使用左侧 4 位，SEL4~SEL7 保持关闭。
//
// 共阳极硬件说明：
//   dig[7:0] = {h(dp),g,f,e,d,c,b,a}
//   段码低电平点亮，高电平熄灭。
//   sel[7:0] 位选高电平有效。
// =============================================================================

module seg_driver (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [15:0] display_chars,

    output reg  [7:0] sel,
    output reg  [7:0] dig
);

    parameter integer CLK_FREQ_HZ  = 50000000;
    parameter integer SCAN_FREQ_HZ = 1000;
    localparam [15:0] DIV_MAX = (CLK_FREQ_HZ / SCAN_FREQ_HZ) - 1;

    localparam [3:0] CHAR_BLANK = 4'h0;
    localparam [3:0] CHAR_G     = 4'h1;
    localparam [3:0] CHAR_O     = 4'h2;
    localparam [3:0] CHAR_D     = 4'h3;
    localparam [3:0] CHAR_F     = 4'h4;
    localparam [3:0] CHAR_I     = 4'h5;
    localparam [3:0] CHAR_X     = 4'h6;
    localparam [3:0] CHAR_1     = 4'h7;
    localparam [3:0] CHAR_E     = 4'h8;
    localparam [3:0] CHAR_R     = 4'h9;
    localparam [3:0] CHAR_2     = 4'hA;

    reg [15:0] div_cnt;
    reg [1:0] scan_sel;
    reg [3:0] active_char;
    reg [7:0] dig_on_high;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_cnt  <= 16'd0;
            scan_sel <= 2'd0;
        end else begin
            if (div_cnt == DIV_MAX) begin
                div_cnt  <= 16'd0;
                scan_sel <= scan_sel + 2'd1;
            end else begin
                div_cnt <= div_cnt + 16'd1;
            end
        end
    end

    always @(*) begin
            case (scan_sel)
                2'd0: begin
                    sel         = 8'b1111_1110;
                    active_char = display_chars[15:12];
                end
                2'd1: begin
                    sel         = 8'b1111_1101;
                    active_char = display_chars[11:8];
                end
                2'd2: begin
                    sel         = 8'b1111_1011;
                    active_char = display_chars[7:4];
                end
                default: begin
                    sel         = 8'b1111_0111;
                    active_char = display_chars[3:0];
                end
            endcase 
    end

    always @(*) begin
        case (active_char)
            // dig_on_high[7:0] = {dp,g,f,e,d,c,b,a}，这里先用高电平表示“应点亮”。
            CHAR_G:     dig_on_high = 8'b0_0_1_1_1_1_0_1; // G: a,c,d,e,f
            CHAR_O:     dig_on_high = 8'b0_1_0_1_1_1_0_0; // o: c,d,e,g
            CHAR_D:     dig_on_high = 8'b0_1_0_1_1_1_1_0; // d: b,c,d,e,g
            CHAR_F:     dig_on_high = 8'b0_1_1_1_0_0_0_1; // F: a,e,f,g
            CHAR_I:     dig_on_high = 8'b0_0_0_0_0_1_1_0; // I/1: b,c
            CHAR_X:     dig_on_high = 8'b0_1_1_1_0_1_1_0; // X 近似: b,c,e,f,g
            CHAR_1:     dig_on_high = 8'b0_0_0_0_0_1_1_0; // 1: b,c
            CHAR_E:     dig_on_high = 8'b0_1_1_1_1_0_0_1; // E: a,d,e,f,g
            CHAR_R:     dig_on_high = 8'b0_1_0_1_0_0_0_0; // r: e,g
            CHAR_2:     dig_on_high = 8'b0_1_0_1_1_0_1_1; // 2: a,b,d,e,g
            CHAR_BLANK: dig_on_high = 8'b0_0_0_0_0_0_0_0;
            default:    dig_on_high = 8'b0_0_0_0_0_0_0_0;
        endcase

        // 共阳极段选低有效，故对“应点亮”段码取反输出。
        dig = ~dig_on_high;
    end

endmodule
