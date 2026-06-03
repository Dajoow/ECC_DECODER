# ECC 接收与纠错显示模块工程说明

## 工程目录结构

```text
ECC_decoder/
├─ ECC_decoder.xpr
├─ ECC_decoder.srcs/
│  ├─ sources_1/
│  │  └─ new/
│  │     ├─ ecc_decoder.v
│  │     ├─ led_status.v
│  │     ├─ display_controller.v
│  │     ├─ seg_driver.v
│  │     ├─ team_a_tx.v
│  │     ├─ top_ecc_rx.v
│  │     ├─ top_ecc_rx_board_demo.v
│  │     └─ ecc_board_top.v
│  ├─ sim_1/
│  │  └─ new/
│  │     ├─ tb_ecc_decoder.v
│  │     └─ tb_team_a_tx.v
│  └─ constrs_1/
│     └─ new/
│        └─ top_ecc_rx.xdc
```

## 单板验证方式

`top_ecc_rx.v` 保留完整接收接口，供 testbench 和后续系统集成使用。

`top_ecc_rx_board_demo.v` 是当前 Vivado 工程的板级顶层，只暴露真实板级 IO：

```text
clk
rst_n
key1_n
sw[3:0]
led[3:0]
sel[7:0]
dig[7:0]
```

当前板级链路为：

```text
TeamA 数据源 -> TeamA SECDED 编码器 -> TeamA 错误注入 -> top_ecc_rx 解码显示
```

`team_a_tx.v` 内部数据源每 2 秒自动递增 1 字节；按下 KEY1 时锁存当前数据、编码、注错并向解码侧发送 1 拍 `valid_in`。

## TeamA 开关与按键

KEY1 为手动编码/发送触发键，硬件按下为低电平：

```text
KEY1 / key1_n / E3 : 按下沿触发发送
```

4 个拨码开关用于选择和使能错误注入：

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

注意：按板上实测，SW3/SW4 拨上时 FPGA 读到高电平，不注错；拨下时 FPGA 读到低电平，注错。因此代码中注入使能为 `~sw_sync[2]` 和 `~sw_sync[3]`。

开发板实际为 4 个独立绿灯，板级 demo 中状态映射如下：

```text
led[0] -> LED1 / AA6  ：无错误
led[1] -> LED2 / V7   ：单比特错误已纠正
led[2] -> LED3 / W7   ：双比特错误
led[3] -> LED4 / AB7  ：固定熄灭，避免和状态灯混淆
```

这样可以在板上观察数码管和 LED 状态，同时避免把 `ecc_data_in`、`data_out` 等内部总线暴露成顶层 IO。

数码管按用户提供的 2 组 4 位一体八段共阳硬件修改：

```text
dig[7:0] = {h/dp,g,f,e,d,c,b,a}
dig 段选低电平点亮
sel[7:0] 位选高电平有效
当前使用 SEL0~SEL7 显示 8 位字符
前 4 位显示 GOOD / FIX1 / ERR2 状态
后 4 位显示 raw_data 和 decoded_data 的 HEX：原始高位、原始低位、解码高位、解码低位
```

## SECDED 位分配

13 位码字格式如下：

```text
ecc_data_in[12]   : overall parity
ecc_data_in[11:0] : hamming code
```

Hamming(12,8) 位置编号从 1 开始，Verilog 数组下标从 0 开始：

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

## syndrome 与错误位映射表

```text
syndrome = 4'd0  : 无 Hamming 定位错误
syndrome = 4'd1  : hamming[0]  / P1 错误
syndrome = 4'd2  : hamming[1]  / P2 错误
syndrome = 4'd3  : hamming[2]  / D0 错误
syndrome = 4'd4  : hamming[3]  / P4 错误
syndrome = 4'd5  : hamming[4]  / D1 错误
syndrome = 4'd6  : hamming[5]  / D2 错误
syndrome = 4'd7  : hamming[6]  / D3 错误
syndrome = 4'd8  : hamming[7]  / P8 错误
syndrome = 4'd9  : hamming[8]  / D4 错误
syndrome = 4'd10 : hamming[9]  / D5 错误
syndrome = 4'd11 : hamming[10] / D6 错误
syndrome = 4'd12 : hamming[11] / D7 错误
```

判断规则：

```text
syndrome = 0 且 overall_check = 0 : 无错误
syndrome != 0 且 overall_check = 1: hamming 区单比特错误，可纠正
syndrome != 0 且 overall_check = 0: 双比特错误，不可纠正
syndrome = 0 且 overall_check = 1 : overall parity 位错误，视为单比特错误
```

## 仿真验证

原有接收侧回归：

```text
tb_ecc_decoder
通过标志：ALL TESTS PASSED
```

TeamA 闭环回归：

```text
tb_team_a_tx
通过标志：TEAM_A_TX TEST PASSED
```

`tb_team_a_tx` 覆盖无注错、单 bit 注错和双 bit 注错，验证 TeamA 数据源、编码器、低有效错误注入和现有解码显示接口可以闭环工作。
