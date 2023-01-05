//Copyright (C)2014-2022 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.8.03 Education
//Created Time: 2022-08-08 02:28:07
create_clock -name clock27M -period 37.037 -waveform {0 18.519} [get_ports {clock}]
create_clock -name rxclk -period 18.519 -waveform {0 9.259} [get_pins {UART_0/i4/u_baudset/rxclk_s1/Q}]
create_generated_clock -name clk54M -source [get_ports {clock}] -master_clock clock27M -multiply_by 2 [get_pins {PLL_U0/rpll_inst/CLKOUTD}]
set_clock_groups -exclusive -group [get_clocks {clock27M clk54M rxclk}]
