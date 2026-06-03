`timescale 1ns / 1ps
// =============================================================================
// File name : team_a_tx.v
// Function  : TeamA data source, SECDED encoder, and switch-controlled injector.
//
// Switch map:
//   key1_n  : falling edge captures current source byte and sends one codeword
//   sw[1:0] : selects one adjacent pair among the 8 payload bits
//             00=D0/D1, 01=D2/D3, 10=D4/D5, 11=D6/D7
//   sw[2]   : injects the first selected payload bit when low
//   sw[3]   : injects the second selected payload bit when low
//
// This supports no-error, single-error, and double-error cases.
// =============================================================================

module team_a_tx #(
    parameter integer CLK_FREQ_HZ        = 50000000,
    parameter integer SOURCE_PERIOD_SEC  = 2
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       key1_n,
    input  wire [3:0] sw,

    output reg        valid_o,
    output reg [12:0] ecc_data_o,
    output reg [7:0]  raw_data_o,
    output wire [7:0] source_data_o,
    output wire [12:0] encoded_data_o,
    output wire [12:0] error_mask_o
);

    wire [7:0]  source_data;
    wire [12:0] encoded_data;
    wire [12:0] error_mask;
    wire [12:0] injected_data;

    reg [3:0] sw_meta;
    reg [3:0] sw_sync;
    reg       key1_meta;
    reg       key1_sync;
    reg       key1_d;

    wire send_rise;

    assign source_data_o  = source_data;
    assign encoded_data_o = encoded_data;
    assign error_mask_o   = error_mask;
    assign injected_data  = encoded_data ^ error_mask;
    assign send_rise      = ~key1_sync & key1_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sw_meta   <= 4'd0;
            sw_sync   <= 4'd0;
            key1_meta <= 1'b1;
            key1_sync <= 1'b1;
            key1_d    <= 1'b1;
        end else begin
            sw_meta   <= sw;
            sw_sync   <= sw_meta;
            key1_meta <= key1_n;
            key1_sync <= key1_meta;
            key1_d    <= key1_sync;
        end
    end

    team_a_data_source #(
        .CLK_FREQ_HZ       (CLK_FREQ_HZ),
        .SOURCE_PERIOD_SEC (SOURCE_PERIOD_SEC)
    ) u_data_source (
        .clk        (clk),
        .rst_n      (rst_n),
        .data_out   (source_data)
    );

    ecc_encoder_8b u_encoder (
        .data_in      (source_data),
        .ecc_data_out (encoded_data)
    );

    team_a_error_injector u_error_injector (
        .data_pair_sel_i (sw_sync[1:0]),
        .inject0_en_i    (~sw_sync[2]),
        .inject1_en_i    (~sw_sync[3]),
        .error_mask_o (error_mask)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_o    <= 1'b0;
            ecc_data_o <= 13'd0;
            raw_data_o <= 8'd0;
        end else begin
            valid_o <= send_rise;

            if (send_rise) begin
                raw_data_o <= source_data;
                ecc_data_o <= injected_data;
            end
        end
    end

endmodule


module team_a_data_source #(
    parameter integer CLK_FREQ_HZ        = 50000000,
    parameter integer SOURCE_PERIOD_SEC  = 2
) (
    input  wire      clk,
    input  wire      rst_n,
    output reg [7:0] data_out
);

    localparam integer PERIOD_TICKS = CLK_FREQ_HZ * SOURCE_PERIOD_SEC;
    localparam [31:0] PERIOD_MAX = PERIOD_TICKS - 1;

    reg [31:0] tick_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tick_cnt <= 32'd0;
            data_out <= 8'h00;
        end else begin
            if (tick_cnt == PERIOD_MAX) begin
                tick_cnt <= 32'd0;
                data_out <= data_out + 8'h1;
            end else begin
                tick_cnt <= tick_cnt + 32'd1;
            end
        end
    end

endmodule


module ecc_encoder_8b (
    input  wire [7:0]  data_in,
    output wire [12:0] ecc_data_out
);

    reg [11:0] hamming;
    reg        overall;

    always @(*) begin
        hamming = 12'd0;

        hamming[2]  = data_in[0];
        hamming[4]  = data_in[1];
        hamming[5]  = data_in[2];
        hamming[6]  = data_in[3];
        hamming[8]  = data_in[4];
        hamming[9]  = data_in[5];
        hamming[10] = data_in[6];
        hamming[11] = data_in[7];

        hamming[0] = hamming[2] ^ hamming[4] ^ hamming[6] ^ hamming[8] ^ hamming[10];
        hamming[1] = hamming[2] ^ hamming[5] ^ hamming[6] ^ hamming[9] ^ hamming[10];
        hamming[3] = hamming[4] ^ hamming[5] ^ hamming[6] ^ hamming[11];
        hamming[7] = hamming[8] ^ hamming[9] ^ hamming[10] ^ hamming[11];

        overall = ^hamming;
    end

    assign ecc_data_out = {overall, hamming};

endmodule


module team_a_error_injector (
    input  wire [1:0]  data_pair_sel_i,
    input  wire        inject0_en_i,
    input  wire        inject1_en_i,
    output wire [12:0] error_mask_o
);

    reg [12:0] selected_mask0;
    reg [12:0] selected_mask1;

    always @(*) begin
        case (data_pair_sel_i)
            2'd0: begin
                selected_mask0 = 13'b0_0000_0000_0100; // ecc_data[2]  / D0
                selected_mask1 = 13'b0_0000_0001_0000; // ecc_data[4]  / D1
            end
            2'd1: begin
                selected_mask0 = 13'b0_0000_0010_0000; // ecc_data[5]  / D2
                selected_mask1 = 13'b0_0000_0100_0000; // ecc_data[6]  / D3
            end
            2'd2: begin
                selected_mask0 = 13'b0_0001_0000_0000; // ecc_data[8]  / D4
                selected_mask1 = 13'b0_0010_0000_0000; // ecc_data[9]  / D5
            end
            default: begin
                selected_mask0 = 13'b0_0100_0000_0000; // ecc_data[10] / D6
                selected_mask1 = 13'b0_1000_0000_0000; // ecc_data[11] / D7
            end
        endcase
    end

    assign error_mask_o = ({13{inject0_en_i}} & selected_mask0) |
                          ({13{inject1_en_i}} & selected_mask1);

endmodule
