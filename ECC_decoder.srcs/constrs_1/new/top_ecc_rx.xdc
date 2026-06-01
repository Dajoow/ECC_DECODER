## ============================================================================
## top_ecc_rx_board_demo.xdc
## 板级单板验证约束
##
## 数码管/双色 LED 引脚来自用户提供的原理图表：
##   DIG[7:0] 属于数码管段控制：{h(dp),g,f,e,d,c,b,a}
##   SEL[7:0] 属于数码管位选信号，代码按板上实测低电平有效处理
##   共阳极数码管：DIG 段选低电平点亮
## ============================================================================

## Clock: 50MHz
create_clock -period 20.000 -name clk [get_ports clk]
set_property PACKAGE_PIN Y18 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

## Reset
set_property PACKAGE_PIN P19 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

## Board LEDs: four independent green LEDs
## 当前板上验证按高电平点亮处理。
## led[0] -> LED1: no_error
## led[1] -> LED2: single_error_corrected
## led[2] -> LED3: double_error_detected
## led[3] -> LED4: off
set_property PACKAGE_PIN AA6 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]

set_property PACKAGE_PIN V7 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]

set_property PACKAGE_PIN W7 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]

set_property PACKAGE_PIN AB7 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]

## Seven-segment digit select: SEL0~SEL7, high active
set_property PACKAGE_PIN Y19  [get_ports {sel[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sel[0]}]

set_property PACKAGE_PIN V18  [get_ports {sel[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sel[1]}]

set_property PACKAGE_PIN V19  [get_ports {sel[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sel[2]}]

set_property PACKAGE_PIN AA19 [get_ports {sel[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sel[3]}]

set_property PACKAGE_PIN AB20 [get_ports {sel[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sel[4]}]

set_property PACKAGE_PIN V17  [get_ports {sel[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sel[5]}]

set_property PACKAGE_PIN W17  [get_ports {sel[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sel[6]}]

set_property PACKAGE_PIN AA18 [get_ports {sel[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sel[7]}]

## Seven-segment segments:
## dig[0]=a, dig[1]=b, dig[2]=c, dig[3]=d,
## dig[4]=e, dig[5]=f, dig[6]=g, dig[7]=h/dp
set_property PACKAGE_PIN AB18 [get_ports {dig[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dig[0]}]

set_property PACKAGE_PIN U17  [get_ports {dig[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dig[1]}]

set_property PACKAGE_PIN U18  [get_ports {dig[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dig[2]}]

set_property PACKAGE_PIN P14  [get_ports {dig[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dig[3]}]

set_property PACKAGE_PIN R14  [get_ports {dig[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dig[4]}]

set_property PACKAGE_PIN R18  [get_ports {dig[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dig[5]}]

set_property PACKAGE_PIN T18  [get_ports {dig[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dig[6]}]

set_property PACKAGE_PIN N17  [get_ports {dig[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {dig[7]}]

## Configuration bank voltage.
## 如果你的原理图配置 Bank 不是 3.3V，请按实际配置电压修改。
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
