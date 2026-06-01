## Clock / Reset
## 顶层模块：top_ecc_rx
## 时钟为 50MHz，因此周期约 20ns。
create_clock -period 20.000 -name clk [get_ports clk]
set_property PACKAGE_PIN Y18 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

set_property PACKAGE_PIN P19 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

## Independent LEDs
## 以下 LED 引脚沿用原工程已知管脚；黄色 LED、数码管和 ECC 输入管脚
## 需要根据实际开发板原理图补充分配。
set_property PACKAGE_PIN AA6 [get_ports led_green]
set_property IOSTANDARD LVCMOS33 [get_ports led_green]

set_property PACKAGE_PIN W7 [get_ports led_yellow]
set_property IOSTANDARD LVCMOS33 [get_ports led_yellow]

set_property PACKAGE_PIN V7 [get_ports led_red]
set_property IOSTANDARD LVCMOS33 [get_ports led_red]
