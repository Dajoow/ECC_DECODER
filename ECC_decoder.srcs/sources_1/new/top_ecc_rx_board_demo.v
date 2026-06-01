`timescale 1ns / 1ps
// =============================================================================
// 文件名称  : top_ecc_rx_board_demo.v
// 模块功能  : 单板验证顶层
// 说明      :
//   1. FPGA 内部自动产生 3 组 SECDED 码字：无错误、单比特错误、双比特错误。
//   2. 码字送入 top_ecc_rx，板上观察 LED 与数码管显示。
//   3. 顶层只保留真实板级 IO，避免 ecc_data_in/data_out 等内部信号引发
//      NSTD-1/UCIO-1 管脚约束关键警告。
//
// 显示节奏：
//   约每 3 秒切换一次状态：
//     GOOD：无错误，LED1
//     FIX1：单比特错误已纠正，LED3
//     ERR2：双比特错误检测到，LED2
//
// LED 映射说明：
//   开发板实际是 4 个独立绿灯，而不是三色灯。
//   led[0] -> LED1，表示 no_error
//   led[1] -> LED2，表示 single_error_corrected
//   led[2] -> LED3，表示 double_error_detected
//   led[3] -> LED4，固定熄灭，避免和状态灯混淆
// =============================================================================

module top_ecc_rx_board_demo (
    input  wire       clk,
    input  wire       rst_n,

    output wire [3:0] led,
    output wire [7:0] sel,
    output wire [7:0] dig
);

    parameter integer CLK_FREQ_HZ     = 50000000;
    parameter integer CASE_PERIOD_SEC = 3;
    localparam [31:0] CASE_DIV_MAX = (CLK_FREQ_HZ * CASE_PERIOD_SEC) - 1;

    reg [31:0] case_cnt;
    reg [1:0]  case_sel;
    reg        valid_in;
    reg [12:0] ecc_data_in;

    wire        valid_out;
    wire [7:0]  data_out;
    wire        no_error;
    wire        single_error_corrected;
    wire        double_error_detected;
    wire        led_no_error;
    wire        led_single_error;
    wire        led_double_error;
    reg  [2:0]  demo_led_state;

    // 板载 LED 低电平点亮。demo_led_state 内部为高有效独热：
    // 3'b001=GOOD/LED1，3'b010=ERR2/LED2，3'b100=FIX1/LED3。
    assign led[3] = 1'b0;
    assign led[2] = demo_led_state[2];
    assign led[1] = demo_led_state[1];
    assign led[0] = demo_led_state[0]; 

    // 演示用 SECDED 编码函数，与 ecc_decoder.v 中的位分配完全一致。
    function [12:0] encode_secded;
        input [7:0] data;
        reg [11:0] h;
        reg overall;
        begin
            h = 12'd0;
            h[2]  = data[0];
            h[4]  = data[1];
            h[5]  = data[2];
            h[6]  = data[3];
            h[8]  = data[4];
            h[9]  = data[5];
            h[10] = data[6];
            h[11] = data[7];

            h[0] = h[2] ^ h[4] ^ h[6] ^ h[8] ^ h[10];
            h[1] = h[2] ^ h[5] ^ h[6] ^ h[9] ^ h[10];
            h[3] = h[4] ^ h[5] ^ h[6] ^ h[11];
            h[7] = h[8] ^ h[9] ^ h[10] ^ h[11];

            overall = ^h;
            encode_secded = {overall, h};
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            case_cnt    <= 32'd0;
            case_sel    <= 2'd0;
            valid_in    <= 1'b0;
            ecc_data_in <= 13'd0;
            demo_led_state <= 3'b001;
        end else begin
            if (case_cnt == CASE_DIV_MAX) begin
                case_cnt <= 32'd0;
                case_sel <= (case_sel == 2'd2) ? 2'd0 : (case_sel + 2'd1);
                valid_in <= 1'b1;

                case (case_sel)
                    2'd0: begin
                        // 无错误：下一状态显示 GOOD。
                        ecc_data_in <= encode_secded(8'hA5);
                        demo_led_state <= 3'b001;
                    end
                    2'd1: begin
                        // 单比特错误：翻转 hamming 位置 6，即 ecc_data_in[5]。
                        ecc_data_in <= encode_secded(8'h3C) ^ 13'b0_000000100000;
                        demo_led_state <= 3'b010;
                    end
                    default: begin
                        // 双比特错误：同时翻转 hamming 位置 3 和 6。
                        ecc_data_in <= encode_secded(8'h5A) ^ 13'b0_000000100100;
                        demo_led_state <= 3'b100;
                    end
                endcase
            end else begin
                case_cnt <= case_cnt + 32'd1;
                valid_in <= 1'b0;
            end
        end
    end

    top_ecc_rx u_top_ecc_rx (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .valid_in               (valid_in),
        .ecc_data_in            (ecc_data_in),
        .valid_out              (valid_out),
        .data_out               (data_out),
        .no_error               (no_error),
        .single_error_corrected (single_error_corrected),
        .double_error_detected  (double_error_detected),
        .led_1                  (led_no_error),
        .led_2                  (led_single_error),
        .led_3                  (led_double_error),
        .sel                    (sel),
        .dig                    (dig)
    );

endmodule
