`timescale 1ns / 1ps
// =============================================================================
// 文件名称  : display_controller.v
// 模块功能  : 根据 ECC 状态选择 4 位字符内容
// 显示内容  : 无错误按 G -> GO -> GOO -> GOOD 滚动；
//             单错纠正显示 FIX1；双错检测显示 ERR2。
// =============================================================================

module display_controller (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       valid_in,
    input  wire       no_error,
    input  wire       single_error_corrected,
    input  wire       double_error_detected,
    input  wire       display_data_mode,
    input  wire [7:0] raw_data_in,
    input  wire [7:0] decoded_data_in,

    output reg [39:0] display_chars
);

    parameter integer CLK_FREQ_HZ    = 50000000;
    parameter integer SCROLL_FREQ_HZ = 1;
    localparam [31:0] SCROLL_DIV_MAX = (CLK_FREQ_HZ / SCROLL_FREQ_HZ) - 1;

    // 字符编码由 seg_driver 解释。
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

    localparam [1:0] STATE_GOOD  = 2'd0;
    localparam [1:0] STATE_FIX1  = 2'd1;
    localparam [1:0] STATE_ERR2  = 2'd2;
    localparam [1:0] STATE_BLANK = 2'd3;

    reg [1:0]  display_state;
    reg [1:0]  good_step;
    reg [31:0] scroll_cnt;
    reg [1:0]  next_state;
    reg        scroll_tick;

    always @(*) begin
        if (double_error_detected) begin
            next_state = STATE_ERR2;
        end else if (single_error_corrected) begin
            next_state = STATE_FIX1;
        end else if (no_error) begin
            next_state = STATE_GOOD;
        end else begin
            next_state = STATE_BLANK;
        end
    end

    always @(*) begin
        scroll_tick = (scroll_cnt >= SCROLL_DIV_MAX);
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            display_state <= STATE_GOOD;
            good_step     <= 2'd0;
            scroll_cnt    <= 32'd0;
        end else if (valid_in) begin
            display_state <= next_state;
            good_step     <= 2'd0;
            scroll_cnt    <= 32'd0;
        end else if (display_state == STATE_GOOD) begin
            if (scroll_tick) begin
                scroll_cnt <= 32'd0;
                good_step  <= good_step + 2'd1;
            end else begin
                scroll_cnt <= scroll_cnt + 32'd1;
            end
        end else begin
            scroll_cnt <= 32'd0;
            good_step  <= 2'd0;
        end
    end

    always @(*) begin
        display_chars[19:0] = {
            {1'b0, raw_data_in[7:4]},
            {1'b0, raw_data_in[3:0]},
            {1'b0, decoded_data_in[7:4]},
            {1'b0, decoded_data_in[3:0]}
        };

        if (display_data_mode) begin
            case (display_state)
                STATE_GOOD: display_chars[39:20] = {CHAR_G, CHAR_O, CHAR_O, CHAR_D};
                STATE_FIX1: display_chars[39:20] = {CHAR_F, CHAR_I, CHAR_X, CHAR_1};
                STATE_ERR2: display_chars[39:20] = {CHAR_E, CHAR_R, CHAR_R, CHAR_2};
                default:    display_chars[39:20] = {CHAR_BLANK, CHAR_BLANK, CHAR_BLANK, CHAR_BLANK};
            endcase
        end else begin
            case (display_state)
                STATE_GOOD: begin
                    display_chars[39:20] = {CHAR_G, CHAR_O, CHAR_O, CHAR_D};
                end
                STATE_FIX1: display_chars[39:20] = {CHAR_F, CHAR_I, CHAR_X, CHAR_1};
                STATE_ERR2: display_chars[39:20] = {CHAR_E, CHAR_R, CHAR_R, CHAR_2};
                default:    display_chars[39:20] = {CHAR_BLANK, CHAR_BLANK, CHAR_BLANK, CHAR_BLANK};
            endcase
            display_chars[19:0] = {CHAR_BLANK, CHAR_BLANK, CHAR_BLANK, CHAR_BLANK};
        end
    end

endmodule
