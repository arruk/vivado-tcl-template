# Configuracao do projeto. Caminhos relativos a este arquivo, nao ao terminal.
set root_dir [file dirname [file normalize [info script]]]
set project_name ax7350b
set part xc7z035ffg676-2
set top top
set project_dir [file join $root_dir build vivado]
set project_file [file join $project_dir ${project_name}.xpr]
set report_dir [file join $root_dir build reports]
set bitstream_file [file join $root_dir build bitstream ${top}.bit]

# Adicione aqui os arquivos do seu projeto, incluindo fontes externas.
# add_files mantem referencias aos originais; nao copia o RTL para build/.
set rtl_files [list [file join $root_dir rtl top.v]]
set xdc_files [list [file join $root_dir constraints ax7350b.xdc]]
set include_dirs [list [file join $root_dir rtl]]
set verilog_defines {}

# Se houver mais de um cabo/FPGA, restrinja os padroes abaixo.
# O ARM DAP do Zynq nao corresponde a xc7z035_*.
set hw_server_url localhost:3121
set hw_target_pattern *
set hw_device_pattern xc7z035_*
