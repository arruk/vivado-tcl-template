# Pinagem e niveis: tutorial ALINX AX7350B, experimento PL LED.
# https://ax7350b-20231-v101.readthedocs.io/zh-cn/latest/7350B_S1_RSTdocument_CN/04_PL%E7%9A%84LED%E5%AE%9E%E9%AA%8C_CN.html

# Oscilador PL de 50 MHz (BANK35, 1,8 V).
set_property -dict {PACKAGE_PIN J14 IOSTANDARD LVCMOS18} [get_ports sys_clk]
create_clock -name sys_clk -period 20.000 [get_ports sys_clk]

# PL_LED1 a PL_LED4 (BANK34, 1,5 V), ativos em nivel alto.
set_property IOSTANDARD LVCMOS15 [get_ports {led[*]}]
set_property PACKAGE_PIN F5 [get_ports {led[0]}]
set_property PACKAGE_PIN E5 [get_ports {led[1]}]
set_property PACKAGE_PIN G5 [get_ports {led[2]}]
set_property PACKAGE_PIN G6 [get_ports {led[3]}]

# LEDs sao indicadores sem interface sincrona externa.
# O caminho ate os registradores dos LEDs continua sujeito ao clock acima.
set_false_path -to [get_ports {led[*]}]
