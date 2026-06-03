# TeamA 编码器接口说明

本文档用于约定 TeamA 编码器输出到当前 ECC decoder 工程的接口格式。

## 对接信号

TeamA 编码器需要在与 decoder 相同的 `clk` 时钟域内输出 13 bit SECDED 码字：

```verilog
// TeamA encoder -> TeamB decoder
output wire        valid_out;  // 对接 decoder.valid_in
output wire [12:0] ecc_code;   // 对接 decoder.ecc_data_in
```

decoder 侧当前接收接口为：

```verilog
input  wire        valid_in;
input  wire [12:0] ecc_data_in;
```

时序要求：

- `ecc_code` 在 `valid_out = 1'b1` 的那个 `clk` 上升沿保持稳定。
- `valid_out` 拉高 1 个 `clk` 周期即可。
- `rst_n` 为低有效复位，编码器和 decoder 建议使用同一复位域。

## 码字格式

当前 decoder 使用 Hamming(13,8) SECDED 格式：

```text
ecc_code[12]   : overall parity，覆盖 ecc_code[11:0]，整体偶校验
ecc_code[11:0] : Hamming(12,8) 码字 hamming[11:0]
```

Hamming 位分配如下，位置号从 1 开始，Verilog 下标从 0 开始：

```text
位置  1 -> hamming[0]  -> P1
位置  2 -> hamming[1]  -> P2
位置  3 -> hamming[2]  -> D0 -> 原始数据 data_in[0]
位置  4 -> hamming[3]  -> P4
位置  5 -> hamming[4]  -> D1 -> 原始数据 data_in[1]
位置  6 -> hamming[5]  -> D2 -> 原始数据 data_in[2]
位置  7 -> hamming[6]  -> D3 -> 原始数据 data_in[3]
位置  8 -> hamming[7]  -> P8
位置  9 -> hamming[8]  -> D4 -> 原始数据 data_in[4]
位置 10 -> hamming[9]  -> D5 -> 原始数据 data_in[5]
位置 11 -> hamming[10] -> D6 -> 原始数据 data_in[6]
位置 12 -> hamming[11] -> D7 -> 原始数据 data_in[7]
```

## 编码参考实现

TeamA 可以直接按下面函数生成 `ecc_code`：

```verilog
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
```

## 最小发送示例

```verilog
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_out <= 1'b0;
        ecc_code  <= 13'd0;
    end else begin
        if (data_valid) begin
            ecc_code  <= encode_secded(data_in);
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end
end
```

## 对接自测向量

当前工程 testbench 使用以下场景验证 decoder：

```text
无错误输入:
  ecc_code = encode_secded(8'hA5)
  decoder 应输出 data_out = 8'hA5, no_error = 1

单比特错误:
  ecc_code = encode_secded(8'h3C) ^ 13'b0_000000100000
  翻转 hamming 位置 6，即 ecc_code[5]
  decoder 应输出 data_out = 8'h3C, single_error_corrected = 1

双比特错误:
  ecc_code = encode_secded(8'h5A) ^ 13'b0_000000100100
  同时翻转 hamming 位置 3 和 6
  decoder 应输出 double_error_detected = 1
```

## 工程依据

- `ECC_decoder.srcs/sources_1/new/top_ecc_rx.v`
- `ECC_decoder.srcs/sources_1/new/ecc_decoder.v`
- `ECC_decoder.srcs/sim_1/new/tb_ecc_decoder.v`
