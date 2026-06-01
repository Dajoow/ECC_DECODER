`timescale 1ns / 1ps
// =============================================================================
// 文件名称  : top_ecc_rx.v
// 模块功能  : ECC 接收与纠错显示模块顶层
// 说明      : 接收前级 SECDED 码字，输出纠错数据、状态 LED 与 4 位数码管。
// =============================================================================

module top_ecc_rx (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_in,
    input  wire [12:0] ecc_data_in,

    output wire        valid_out,
    output wire [7:0]  data_out,
    output wire        no_error,
    output wire        single_error_corrected,
    output wire        double_error_detected,
    output wire        led_1,
    output wire        led_2,
    output wire        led_3,
    output wire [7:0]  sel,
    output wire [7:0]  dig
);

    wire [15:0] display_chars;

    ecc_decoder u_ecc_decoder (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .valid_in               (valid_in),
        .ecc_data_in            (ecc_data_in),
        .valid_out              (valid_out),
        .data_out               (data_out),
        .no_error               (no_error),
        .single_error_corrected (single_error_corrected),
        .double_error_detected  (double_error_detected)
    );

    led_status u_led_status (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .valid_in               (valid_out),
        .no_error               (no_error),
        .single_error_corrected (single_error_corrected),
        .double_error_detected  (double_error_detected),
        .led_1                  (led_1),
        .led_2                  (led_2),
        .led_3                  (led_3)
    );

    display_controller u_display_controller (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .valid_in               (valid_out),
        .no_error               (no_error),
        .single_error_corrected (single_error_corrected),
        .double_error_detected  (double_error_detected),
        .display_chars          (display_chars)
    );

    seg_driver u_seg_driver (
        .clk           (clk),
        .rst_n         (rst_n),
        .display_chars (display_chars),
        .sel           (sel),
        .dig           (dig)
    );

endmodule
