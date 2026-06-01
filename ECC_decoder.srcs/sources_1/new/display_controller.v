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

    output reg [15:0] display_chars
);

    parameter integer CLK_FREQ_HZ    = 50000000;
    parameter integer SCROLL_FREQ_HZ = 1;
    localparam [31:0] SCROLL_DIV_MAX = (CLK_FREQ_HZ / SCROLL_FREQ_HZ) - 1;

    // 字符编码由 seg_driver 解释。
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
        case (display_state)
            STATE_GOOD: begin
//                case (good_step)
//                    2'd0: display_chars = {CHAR_G, CHAR_BLANK, CHAR_BLANK, CHAR_BLANK};
//                    2'd1: display_chars = {CHAR_G, CHAR_O,     CHAR_BLANK, CHAR_BLANK};
 //                   2'd2: display_chars = {CHAR_G, CHAR_O,     CHAR_O,     CHAR_BLANK};
 //                   default: display_chars = {CHAR_G, CHAR_O,   CHAR_O,     CHAR_D};
 //               endcase
                display_chars = {CHAR_G, CHAR_O, CHAR_O, CHAR_D};
            end
            STATE_FIX1: begin
                display_chars = {CHAR_F, CHAR_I, CHAR_X, CHAR_1};
            end
            STATE_ERR2: begin
                display_chars = {CHAR_E, CHAR_R, CHAR_R, CHAR_2};
            end
            default: begin
                display_chars = {CHAR_BLANK, CHAR_BLANK, CHAR_BLANK, CHAR_BLANK};
            end
        endcase
    end

endmodule
