`timescale 1ns / 1ps
// =============================================================================
// 文件名称  : top_ecc_rx_board_demo.v
// 模块功能  : TeamA 单板验证顶层
// 说明      :
//   1. TeamA 数据源每 2 秒自动更新 1 字节原始数据。
//   2. KEY1 按下沿手动触发编码发送，按键按下为低电平。
//   3. sw[1:0] 选择八位数据中的一对相邻数据位。
//   4. sw[2] / sw[3] 分别控制这两个数据位是否注入错误。
//   5. 解码侧自动接收 TeamA 码字，板上观察 LED 与数码管显示。
//   6. 顶层只保留真实板级 IO，避免 ecc_data_in/data_out 等内部信号引发
//      NSTD-1/UCIO-1 管脚约束关键警告。
//   7. 数码管前 4 位显示状态，后 4 位显示 raw_data/decoded_data 的 HEX。
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
    input  wire       key1_n,
    input  wire [3:0] sw,

    output wire [3:0] led,
    output wire [7:0] sel,
    output wire [7:0] dig
);

    parameter integer CLK_FREQ_HZ     = 50000000;
    parameter integer SOURCE_PERIOD_SEC = 2;

    wire        valid_in;
    wire [12:0] ecc_data_in;
    wire [7:0]  raw_data;
    wire        valid_out;
    wire [7:0]  data_out;
    wire        no_error;
    wire        single_error_corrected;
    wire        double_error_detected;
    wire        led_no_error;
    wire        led_single_error;
    wire        led_double_error;

    assign led[3] = 1'b0;
    assign led[2] = led_double_error;
    assign led[1] = led_single_error;
    assign led[0] = led_no_error;

    team_a_tx #(
        .CLK_FREQ_HZ       (CLK_FREQ_HZ),
        .SOURCE_PERIOD_SEC (SOURCE_PERIOD_SEC)
    ) u_team_a_tx (
        .clk            (clk),
        .rst_n          (rst_n),
        .key1_n         (key1_n),
        .sw             (sw),
        .valid_o        (valid_in),
        .ecc_data_o     (ecc_data_in),
        .raw_data_o     (raw_data),
        .source_data_o  (),
        .encoded_data_o (),
        .error_mask_o   ()
    );

    top_ecc_rx u_top_ecc_rx (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .valid_in               (valid_in),
        .ecc_data_in            (ecc_data_in),
        .display_data_mode      (1'b1),
        .raw_data_in            (raw_data),
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
