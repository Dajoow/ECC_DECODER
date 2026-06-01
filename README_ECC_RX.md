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
│  │     ├─ top_ecc_rx.v
│  │     ├─ top_ecc_rx_board_demo.v
│  │     └─ ecc_board_top.v
│  ├─ sim_1/
│  │  └─ new/
│  │     └─ tb_ecc_decoder.v
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
led[3:0]
sel[7:0]
dig[7:0]
```

该顶层内部每约 3 秒循环产生三种 SECDED 输入：

```text
GOOD：无错误，绿色 LED
FIX1：单比特错误已纠正，黄色 LED
ERR2：双比特错误检测到，红色 LED
```

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
当前只使用 SEL0~SEL3 显示 4 位字符，SEL4~SEL7 保持关闭
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
