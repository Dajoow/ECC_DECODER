`timescale 1ns / 1ps
// =============================================================================
// 文件名称  : ecc_decoder.v
// 模块功能  : Hamming(13,8) SECDED 接收解码、单错纠正、双错检测
// 目标器件  : XC7A75T / Artix-7
// 语言标准  : Verilog-2001
//
// SECDED 码字格式：
//   ecc_data_in[12]   : overall parity，覆盖 hamming[11:0] 与自身
//   ecc_data_in[11:0] : Hamming(12,8) 码字
//
// Hamming 位分配说明（位置号从 1 开始，数组下标从 0 开始）：
//   位置  1 -> hamming[0]  -> P1
//   位置  2 -> hamming[1]  -> P2
//   位置  3 -> hamming[2]  -> D0 -> data_out[0]
//   位置  4 -> hamming[3]  -> P4
//   位置  5 -> hamming[4]  -> D1 -> data_out[1]
//   位置  6 -> hamming[5]  -> D2 -> data_out[2]
//   位置  7 -> hamming[6]  -> D3 -> data_out[3]
//   位置  8 -> hamming[7]  -> P8
//   位置  9 -> hamming[8]  -> D4 -> data_out[4]
//   位置 10 -> hamming[9]  -> D5 -> data_out[5]
//   位置 11 -> hamming[10] -> D6 -> data_out[6]
//   位置 12 -> hamming[11] -> D7 -> data_out[7]
//
// syndrome 与错误位映射表：
//   syndrome = 4'd0  : 无 Hamming 定位错误
//   syndrome = 4'd1  : hamming[0]  / P1 错误
//   syndrome = 4'd2  : hamming[1]  / P2 错误
//   syndrome = 4'd3  : hamming[2]  / D0 错误
//   syndrome = 4'd4  : hamming[3]  / P4 错误
//   syndrome = 4'd5  : hamming[4]  / D1 错误
//   syndrome = 4'd6  : hamming[5]  / D2 错误
//   syndrome = 4'd7  : hamming[6]  / D3 错误
//   syndrome = 4'd8  : hamming[7]  / P8 错误
//   syndrome = 4'd9  : hamming[8]  / D4 错误
//   syndrome = 4'd10 : hamming[9]  / D5 错误
//   syndrome = 4'd11 : hamming[10] / D6 错误
//   syndrome = 4'd12 : hamming[11] / D7 错误
// =============================================================================

module ecc_decoder (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid_in,
    input  wire [12:0] ecc_data_in,

    output reg         valid_out,
    output reg  [7:0]  data_out,
    output reg         no_error,
    output reg         single_error_corrected,
    output reg         double_error_detected
);

    wire [11:0] hamming_in;
    wire        overall_in;

    wire s1;
    wire s2;
    wire s4;
    wire s8;
    wire [3:0] syndrome;
    wire overall_check;

    reg [11:0] corrected_hamming;

    assign hamming_in = ecc_data_in[11:0];
    assign overall_in = ecc_data_in[12];

    // 偶校验 syndrome 计算。每个校验组包含对应校验位自身。
    assign s1 = hamming_in[0] ^ hamming_in[2] ^ hamming_in[4] ^
                hamming_in[6] ^ hamming_in[8] ^ hamming_in[10];

    assign s2 = hamming_in[1] ^ hamming_in[2] ^ hamming_in[5] ^
                hamming_in[6] ^ hamming_in[9] ^ hamming_in[10];

    assign s4 = hamming_in[3] ^ hamming_in[4] ^ hamming_in[5] ^
                hamming_in[6] ^ hamming_in[11];

    assign s8 = hamming_in[7] ^ hamming_in[8] ^ hamming_in[9] ^
                hamming_in[10] ^ hamming_in[11];

    assign syndrome = {s8, s4, s2, s1};

    // overall_check=1 表示收到的 13 位整体偶校验不成立。
    assign overall_check = ^ecc_data_in;

    always @(*) begin
        corrected_hamming = hamming_in;

        // syndrome 非 0 且 overall_check 为 1 时，定位到 hamming[11:0] 内的单比特错误。
        // syndrome 范围理论上为 1..12；保留 <=12 判断，便于综合且避免越界。
        if ((syndrome != 4'd0) && (overall_check == 1'b1) && (syndrome <= 4'd12)) begin
            corrected_hamming[syndrome - 4'd1] = ~hamming_in[syndrome - 4'd1];
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out              <= 1'b0;
            data_out               <= 8'd0;
            no_error               <= 1'b0;
            single_error_corrected <= 1'b0;
            double_error_detected  <= 1'b0;
        end else begin
            valid_out <= valid_in;

            if (valid_in) begin
                // 从纠错后的 Hamming 码字中提取 8 位原始数据。
                data_out[0] <= corrected_hamming[2];
                data_out[1] <= corrected_hamming[4];
                data_out[2] <= corrected_hamming[5];
                data_out[3] <= corrected_hamming[6];
                data_out[4] <= corrected_hamming[8];
                data_out[5] <= corrected_hamming[9];
                data_out[6] <= corrected_hamming[10];
                data_out[7] <= corrected_hamming[11];

                no_error               <= (syndrome == 4'd0) && (overall_check == 1'b0);
                single_error_corrected <= ((syndrome != 4'd0) && (overall_check == 1'b1)) ||
                                          ((syndrome == 4'd0) && (overall_check == 1'b1));
                double_error_detected  <= (syndrome != 4'd0) && (overall_check == 1'b0);
            end
        end
    end

endmodule
