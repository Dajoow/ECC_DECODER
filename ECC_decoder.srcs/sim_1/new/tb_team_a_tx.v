`timescale 1ns / 1ps
// =============================================================================
// File name : tb_team_a_tx.v
// Function  : TeamA TX smoke test with the existing ECC receiver.
// =============================================================================

module tb_team_a_tx;

    reg        clk;
    reg        rst_n;
    reg        key1_n;
    reg  [3:0] sw;

    wire        valid_in;
    wire [12:0] ecc_data_in;
    wire [7:0]  raw_data;
    wire [7:0]  source_data;
    wire [12:0] encoded_data;
    wire [12:0] error_mask;

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
    reg     seen_valid_out;
    reg     clear_seen_valid_out;

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    team_a_tx #(
        .CLK_FREQ_HZ       (50),
        .SOURCE_PERIOD_SEC (2)
    ) u_team_a_tx (
        .clk            (clk),
        .rst_n          (rst_n),
        .key1_n         (key1_n),
        .sw             (sw),
        .valid_o        (valid_in),
        .ecc_data_o     (ecc_data_in),
        .raw_data_o     (raw_data),
        .source_data_o  (source_data),
        .encoded_data_o (encoded_data),
        .error_mask_o   (error_mask)
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
        .led_1                  (led_1),
        .led_2                  (led_2),
        .led_3                  (led_3),
        .sel                    (sel),
        .dig                    (dig)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            seen_valid_out <= 1'b0;
        end else if (clear_seen_valid_out) begin
            seen_valid_out <= 1'b0;
        end else if (valid_out) begin
            seen_valid_out <= 1'b1;
        end
    end

    task pulse_send;
        begin
            @(posedge clk);
            key1_n <= 1'b0;
            repeat (6) @(posedge clk);
            key1_n <= 1'b1;
            repeat (4) @(posedge clk);
        end
    endtask

    task run_case;
        input [127:0] case_name;
        input [3:0] sw_value;
        input       expected_no_error;
        input       expected_single;
        input       expected_double;
        input       check_data;
        begin
            sw <= sw_value;
            clear_seen_valid_out <= 1'b1;
            @(posedge clk);
            clear_seen_valid_out <= 1'b0;
            pulse_send();

            if (!seen_valid_out) begin
                $display("[%0s] FAIL: valid_out was not asserted after TeamA send", case_name);
                error_count = error_count + 1;
            end

            if (no_error !== expected_no_error) begin
                $display("[%0s] FAIL: no_error expected %b, got %b", case_name, expected_no_error, no_error);
                error_count = error_count + 1;
            end

            if (single_error_corrected !== expected_single) begin
                $display("[%0s] FAIL: single_error_corrected expected %b, got %b",
                         case_name, expected_single, single_error_corrected);
                error_count = error_count + 1;
            end

            if (double_error_detected !== expected_double) begin
                $display("[%0s] FAIL: double_error_detected expected %b, got %b",
                         case_name, expected_double, double_error_detected);
                error_count = error_count + 1;
            end

            if (check_data && (data_out !== raw_data)) begin
                $display("[%0s] FAIL: data_out expected raw_data 0x%02h, got 0x%02h",
                         case_name, raw_data, data_out);
                error_count = error_count + 1;
            end

            if (ecc_data_in !== (encoded_data ^ error_mask)) begin
                $display("[%0s] FAIL: ecc_data_in does not match encoded_data ^ error_mask", case_name);
                error_count = error_count + 1;
            end
        end
    endtask

    initial begin
        error_count = 0;
        clear_seen_valid_out = 1'b0;
        rst_n = 1'b0;
        key1_n = 1'b1;
        sw    = 4'b11_00;

        repeat (5) @(posedge clk);
        rst_n = 1'b1;

        repeat (130) @(posedge clk);

        run_case("NO_INJECT_D0_D1",     4'b1100, 1'b1, 1'b0, 1'b0, 1'b1);
        run_case("INJECT_D2_ONLY",      4'b1001, 1'b0, 1'b1, 1'b0, 1'b1);
        run_case("INJECT_D6_AND_D7",    4'b0011, 1'b0, 1'b0, 1'b1, 1'b0);

        if (error_count == 0) begin
            $display("TEAM_A_TX TEST PASSED");
        end else begin
            $display("TEAM_A_TX TEST FAILED, error_count=%0d", error_count);
        end

        #100;
        $finish;
    end

endmodule
