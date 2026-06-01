
module ecc_board_top (
    input  wire       sys_clk,
    input  wire       sys_rst_n,
    input  wire [3:0] sw,
    output wire       led_green,
    output wire       led_red,
    output wire [1:0] led_dbg
);

    wire [1:0] error_mode  = sw[1:0];
    wire       send_key    = sw[2];
    wire       status_read = sw[3];

    wire [11:0] error_pos0 = 12'd100;
    wire [11:0] error_pos1 = 12'd900;

    wire [7:0] status_led_unused;

    ecc_team_b_selftest_top u_top (
        .clk(sys_clk),
        .rst_n(sys_rst_n),
        .send_key_i(send_key),
        .error_mode_i(error_mode),
        .error_pos0_i(error_pos0),
        .error_pos1_i(error_pos1),
        .status_read_i(status_read),
        .green_led_o(led_green),
        .red_led_o(led_red),
        .status_led_o(status_led_unused)
    );

    assign led_dbg = sw[1:0];

endmodule

