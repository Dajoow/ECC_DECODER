`timescale 1ns / 1ps
// =============================================================================
// 文件名称  : led_status.v
// 模块功能  : ECC 状态 LED 三选一显示
// 说明      : 任意时刻仅允许 GREEN/YELLOW/RED 中一个点亮。
// =============================================================================

module led_status (
    input  wire clk,
    input  wire rst_n,
    input  wire valid_in,
    input  wire no_error,
    input  wire single_error_corrected,
    input  wire double_error_detected,

    output reg  led_1,
    output reg  led_2,
    output reg  led_3
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
                led_1   <= 1'b1;
                led_2   <= 1'b0;
                led_3   <= 1'b0;
        end else if (valid_in) begin
            if (double_error_detected) begin
                led_1   <= 1'b0;
                led_2   <= 1'b0;
                led_3   <= 1'b1;
            end else if (single_error_corrected) begin
                led_1   <= 1'b0;
                led_2   <= 1'b1;
                led_3   <= 1'b0;
            end else if (no_error) begin
                led_1   <= 1'b1;
                led_2   <= 1'b0;
                led_3   <= 1'b0;
            end else begin
                // 非法或空状态时保持绿色，保证三选一输出。
                led_1   <= 1'b1;
                led_2   <= 1'b0;
                led_3   <= 1'b0;
            end
        end
    end

endmodule
