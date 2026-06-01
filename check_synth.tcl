read_verilog ECC_decoder.srcs/sources_1/new/ecc_decoder.v
read_verilog ECC_decoder.srcs/sources_1/new/led_status.v
read_verilog ECC_decoder.srcs/sources_1/new/display_controller.v
read_verilog ECC_decoder.srcs/sources_1/new/seg_driver.v
read_verilog ECC_decoder.srcs/sources_1/new/top_ecc_rx.v
read_verilog ECC_decoder.srcs/sources_1/new/top_ecc_rx_board_demo.v
read_xdc ECC_decoder.srcs/constrs_1/new/top_ecc_rx.xdc
synth_design -top top_ecc_rx_board_demo -part xc7a75tfgg484-2
report_utilization
exit
