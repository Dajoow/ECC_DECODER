`timescale 1ns / 1ps
// =============================================================================
// 文件名称  : tb_ecc_decoder.v
// 模块功能  : ECC 接收与纠错显示模块仿真
// 覆盖场景  : 无错误、单比特错误、双比特错误
// =============================================================================

module tb_ecc_decoder;

    reg         clk;
    reg         rst_n;
    reg         valid_in;
    reg  [12:0] ecc_data_in;

    wire        valid_out;
    wire [7:0]  data_out;
    wire        no_error;
    wire        single_error_corrected;
    wire        double_error_detected;
    wire        led_1;
    wire        led_2;
    wire        led_3;
    wire [7:0]  sel;
    wire [7:0]  dig;

    integer error_count;

    top_ecc_rx dut (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .valid_in               (valid_in),
        .ecc_data_in            (ecc_data_in),
        .display_data_mode      (1'b0),
        .raw_data_in            (8'd0),
        .valid_out              (valid_out),
        .data_out               (data_out),
        .no_error               (no_error),
        .single_error_corrected (single_error_corrected),
        .double_error_detected  (double_error_detected),
        .led_1                  (led_1),
        .led_2                  (led_2),
        .led_3                  (led_3),
        .sel                    (sel),
        .dig                    (dig)
    );

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk; // 50MHz
    end

    // 测试用 SECDED 编码函数，与 DUT 位分配保持一致。
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

    task send_codeword;
        input [12:0] codeword;
        begin
            @(posedge clk);
            ecc_data_in <= codeword;
            valid_in    <= 1'b1;
            @(posedge clk);
            valid_in    <= 1'b0;
            ecc_data_in <= 13'd0;
            // 解码器在该拍给出 valid_out/data/status，LED/显示下一拍锁存该状态。
            @(posedge clk);
            @(posedge clk);
        end
    endtask

    task expect_result;
        input [127:0] case_name;
        input [7:0] expected_data;
        input check_data;
        input expected_no_error;
        input expected_single;
        input expected_double;
        input expected_led_1;
        input expected_led_2;
        input expected_led_3;
        begin
            if (check_data && (data_out !== expected_data)) begin
                $display("[%0s] FAIL: data_out expected 0x%02h, got 0x%02h", case_name, expected_data, data_out);
                error_count = error_count + 1;
            end
            if (no_error !== expected_no_error) begin
                $display("[%0s] FAIL: no_error expected %b, got %b", case_name, expected_no_error, no_error);
                error_count = error_count + 1;
            end
            if (single_error_corrected !== expected_single) begin
                $display("[%0s] FAIL: single_error_corrected expected %b, got %b", case_name, expected_single, single_error_corrected);
                error_count = error_count + 1;
            end
            if (double_error_detected !== expected_double) begin
                $display("[%0s] FAIL: double_error_detected expected %b, got %b", case_name, expected_double, double_error_detected);
                error_count = error_count + 1;
            end
            if ({led_1, led_2, led_3} !== {expected_led_1, expected_led_2, expected_led_3}) begin
                $display("[%0s] FAIL: LED expected %b%b%b, got %b%b%b",
                         case_name, expected_led_1, expected_led_2, expected_led_3,
                         led_1, led_2, led_3);
                error_count = error_count + 1;
            end
        end
    endtask

    initial begin
        error_count = 0;
        rst_n       = 1'b0;
        valid_in    = 1'b0;
        ecc_data_in = 13'd0;

        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        // Case1：无错误，数据正确，LED1 亮。
        send_codeword(encode_secded(8'hA5));
        expect_result("CASE1_NO_ERROR", 8'hA5, 1'b1, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0);

        // Case2：hamming 位置 6，即 ecc_data_in[5] 单比特错误，可自动纠正，LED2 亮。
        send_codeword(encode_secded(8'h3C) ^ 13'b0_000000100000);
        expect_result("CASE2_SINGLE_ERROR", 8'h3C, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1, 1'b0);

        // Case3：两个 hamming 位同时错误，不可纠正，LED3 亮。
        send_codeword(encode_secded(8'h5A) ^ 13'b0_000000100100);
        expect_result("CASE3_DOUBLE_ERROR", 8'h00, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b1);

        if (error_count == 0) begin
            $display("ALL TESTS PASSED");
        end else begin
            $display("TEST FAILED, error_count=%0d", error_count);
        end

        #100;
        $finish;
    end

endmodule
