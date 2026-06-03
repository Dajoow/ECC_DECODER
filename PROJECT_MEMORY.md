# ECC 解码与显示模块项目记忆

## 当前目标

本工程实现基于 XC7A75T / Artix-7 开发板的 ECC 接收、SECDED 解码纠错、LED 状态指示和八段数码管显示。系统采用 FPGA 内部闭环验证，不依赖 UART、网口等外部通信。

当前 Vivado 工程板级顶层为：

```text
top_ecc_rx_board_demo
```

当前板级顶层集成 TeamA 发送侧和现有接收解码侧：

```text
TeamA 数据源 -> TeamA SECDED 编码器 -> TeamA 错误注入 -> top_ecc_rx 解码显示
```

TeamA 数据源每 2 秒自动递增 1 字节。按下 KEY1 时，TeamA 锁存当前原始数据、编码、按拨码配置注入错误，并向 `top_ecc_rx` 发送 1 拍 `valid_in`。

## 主要文件

```text
ECC_decoder.srcs/sources_1/new/ecc_decoder.v
  Hamming(13,8) SECDED 解码器，计算 syndrome 和 overall_check。

ECC_decoder.srcs/sources_1/new/led_status.v
  解码状态到 3 路语义 LED 的映射：led_1/led_2/led_3。

ECC_decoder.srcs/sources_1/new/display_controller.v
  根据 no_error / single_error_corrected / double_error_detected 选择 GOOD / FIX1 / ERR2。

ECC_decoder.srcs/sources_1/new/seg_driver.v
  八段共阳数码管动态扫描驱动，输出 sel[7:0] 和 dig[7:0]，当前扫描 8 位字符。

ECC_decoder.srcs/sources_1/new/team_a_tx.v
  TeamA 发送侧：2 秒自动数据源、8bit SECDED 编码器、拨码控制错误注入、KEY1 手动发送触发。

ECC_decoder.srcs/sources_1/new/top_ecc_rx.v
  接收解码显示模块顶层，保留 valid_in 和 ecc_data_in 接口，支持状态显示和 raw/decoded 数据 HEX 显示。

ECC_decoder.srcs/sources_1/new/top_ecc_rx_board_demo.v
  单板演示顶层，只暴露真实板级 IO，连接 TeamA 发送侧和现有接收解码显示侧。

ECC_decoder.srcs/sim_1/new/tb_ecc_decoder.v
  ECC 解码功能仿真，覆盖无错误、单比特错误、双比特错误三种场景。

ECC_decoder.srcs/sim_1/new/tb_team_a_tx.v
  TeamA 闭环仿真，覆盖无注错、单 bit 注错和双 bit 注错。

ECC_decoder.srcs/constrs_1/new/top_ecc_rx.xdc
  当前板级顶层的时钟、KEY1、SW1~SW4、LED、数码管管脚约束。
```

## TeamA 板级控制

KEY1 用作手动编码/发送触发，按键按下为低电平：

```text
KEY1 / key1_n / E3 : 按下沿触发发送
```

拨码开关管脚：

```text
SW1 / sw[0] / N14
SW2 / sw[1] / P16
SW3 / sw[2] / R17
SW4 / sw[3] / N15
```

拨码语义：

```text
sw[1:0] 选择 8 位原始数据中的一对相邻数据位：
  00 -> D0 / D1
  01 -> D2 / D3
  10 -> D4 / D5
  11 -> D6 / D7

sw[2] 低电平时注入所选数据位对中的第 1 位错误
sw[3] 低电平时注入所选数据位对中的第 2 位错误
```

板上实测 SW3/SW4 拨上时不注错，拨下时注错，因此 `team_a_tx.v` 中使用 `~sw_sync[2]` 和 `~sw_sync[3]` 作为注入使能。

## SECDED 位分配

码字格式：

```text
ecc_data_in[12]   : overall parity
ecc_data_in[11:0] : hamming code
```

Hamming 位置从 1 开始，Verilog 下标从 0 开始：

```text
位置  1 -> hamming[0]  -> P1
位置  2 -> hamming[1]  -> P2
位置  3 -> hamming[2]  -> D0 -> data_out[0]
位置  4 -> hamming[3]  -> P4
位置  5 -> hamming[4]  -> D1 -> data_out[1]
位置  6 -> hamming[5]  -> D2 -> data_out[2]
位置  7 -> hamming[6]  -> D3 -> data_out[3]
位置  8 -> hamming[7]  -> P8
位置  9 -> hamming[8]  -> D4 -> data_out[4]
位置 10 -> hamming[9]  -> D5 -> data_out[5]
位置 11 -> hamming[10] -> D6 -> data_out[6]
位置 12 -> hamming[11] -> D7 -> data_out[7]
```

判断规则：

```text
syndrome = 0 且 overall_check = 0 : 无错误
syndrome != 0 且 overall_check = 1: 单比特错误，可纠正
syndrome != 0 且 overall_check = 0: 双比特错误，只检测不纠正
syndrome = 0 且 overall_check = 1 : overall parity 位错误，视为单比特错误
```

## 板级 LED 映射

开发板实际是 4 个独立绿灯，当前 demo 只用前三个状态灯，LED4 固定熄灭：

```text
led[0] -> LED1 / AA6  -> GOOD / no_error
led[1] -> LED2 / V7   -> FIX1 / single_error_corrected
led[2] -> LED3 / W7   -> ERR2 / double_error_detected
led[3] -> LED4 / AB7  -> off
```

当前 `top_ecc_rx_board_demo.v` 中的板级 LED 赋值为：

```verilog
assign led[3] = 1'b0;
assign led[2] = led_double_error;
assign led[1] = led_single_error;
assign led[0] = led_no_error;
```

板上已验证这种映射显示正常。不要再按早期“红黄绿三色灯”理解该开发板。

## 数码管硬件结论

板载为 2 组 4 位一体八段共阳数码管。当前代码按以下方式处理：

```text
dig[7:0] = {h/dp,g,f,e,d,c,b,a}
DIG 段选低电平点亮
SEL 位选按板上实测低电平有效处理
```

`seg_driver.v` 当前扫描 8 位字符，`scan_sel` 为 3 位：

```text
scan_sel = 0 -> 第 1 位
scan_sel = 1 -> 第 2 位
scan_sel = 2 -> 第 3 位
scan_sel = 3 -> 第 4 位
scan_sel = 4 -> 第 5 位
scan_sel = 5 -> 第 6 位
scan_sel = 6 -> 第 7 位
scan_sel = 7 -> 第 8 位
```

前 4 位显示状态 `GOOD/FIX1/ERR2`，后 4 位显示 `raw_data` 和 `decoded_data` 的 HEX。

## 仿真验证方式

在 Vivado 中运行：

```text
Run Simulation -> Run Behavioral Simulation
```

仿真顶层：

```text
tb_ecc_decoder
```

通过标志：

```text
ALL TESTS PASSED
```

当前 testbench 覆盖：

```text
Case1: encode_secded(8'hA5)
  期望 data_out = A5，no_error = 1

Case2: encode_secded(8'h3C) ^ 13'b0_000000100000
  翻转一个 Hamming 数据位
  期望 data_out = 3C，single_error_corrected = 1

Case3: encode_secded(8'h5A) ^ 13'b0_000000100100
  翻转两个 Hamming 数据位
  期望 double_error_detected = 1
  data_out 不要求等于 5A
```

双错场景里 `5A` 可能变成 `5F`，这是正确现象：SECDED 对双比特错误只能检测，不能纠正。

TeamA 闭环仿真顶层：

```text
tb_team_a_tx
```

通过标志：

```text
TEAM_A_TX TEST PASSED
```

该 testbench 覆盖：

```text
NO_INJECT_D0_D1
  SW3/SW4 为高电平，不注错，期望 no_error = 1

INJECT_D2_ONLY
  选择 D2/D3，只注入 D2，期望 single_error_corrected = 1

INJECT_D6_AND_D7
  选择 D6/D7，同时注入 D6 和 D7，期望 double_error_detected = 1
```

## Vivado 操作记录

生成 bitstream 的正常流程：

```text
Run Synthesis
Run Implementation
Generate Bitstream
Open Hardware Manager
Open Target -> Auto Connect
Program Device
```

如果提示：

```text
Re-running synthesis will result in resetting implementation...
```

说明修改 RTL 或 XDC 后需要重跑后续实现结果，点 OK 是正常流程。

如果出现：

```text
[Synth 8-6895] reference checkpoint ... not suitable for incremental synthesis
```

这是 Vivado 增量综合 checkpoint 旧了，不是 RTL 错误。可以在 Synthesis 设置里关闭 incremental synthesis，或 reset run 后重新生成。

## 已踩过的问题

1. 顶层不能直接暴露 `ecc_data_in/data_out/valid/status` 等内部总线做板级 IO，否则会出现 NSTD-1 / UCIO-1 管脚约束关键警告。
2. 板上不是三色 LED，而是 4 个独立绿灯。
3. 数码管不是简单 4 位共阴极，而是 2 组 4 位八段共阳结构，DIG 低电平点亮。
4. `tb_ecc_decoder.v` 必须和 `top_ecc_rx.v` 的端口名一致；当前为 `led_1/led_2/led_3`，不是旧的 `led_green/led_yellow/led_red`。
5. KEY3 的 FPGA 管脚是 P19，但当前工程 P19 已用于 `rst_n`，TeamA 触发只使用 KEY1/E3。
6. SW3/SW4 的注错使能按板上实测为低有效；不要按“拨上一定读 1 且注错”理解当前逻辑。
