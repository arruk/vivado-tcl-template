# Uso: vivado -mode batch -source scripts/program.tcl
# Configura a PL via JTAG. Nao grava QSPI/SD/eMMC nem inicia software no ARM.
source [file join [file dirname [info script]] .. project.tcl]

proc main {} {
    global bitstream_file hw_server_url hw_target_pattern hw_device_pattern
    foreach {variable override} {
        hw_server_url HW_SERVER
        hw_target_pattern HW_TARGET
        hw_device_pattern HW_DEVICE
    } {
        if {[info exists ::env($override)] && $::env($override) ne ""} {
            set $variable $::env($override)
        }
    }
    if {![file isfile $bitstream_file]} {
        error "Bitstream inexistente: $bitstream_file. Execute make bitstream."
    }
    open_hw_manager
    connect_hw_server -url $hw_server_url
    set targets [get_hw_targets $hw_target_pattern]
    if {[llength $targets] != 1} {
        error "Esperado um cabo JTAG; encontrados: $targets. Ajuste HW_TARGET. Disponiveis: [get_hw_targets]"
    }
    open_hw_target [lindex $targets 0]
    set devices [get_hw_devices $hw_device_pattern]
    if {[llength $devices] != 1} {
        error "Esperado um FPGA; encontrados: $devices. Ajuste HW_DEVICE. Disponiveis: [get_hw_devices]"
    }
    set device [lindex $devices 0]
    current_hw_device $device
    refresh_hw_device -update_hw_probes false $device
    set_property PROGRAM.FILE $bitstream_file $device
    program_hw_devices $device
    refresh_hw_device -update_hw_probes false $device
    puts "PROGRAMADO: $device com $bitstream_file"
}

set failed [catch {main} message options]
# Fecha conexoes tambem em falhas, sem esconder o erro original.
catch {close_hw_target}
catch {disconnect_hw_server}
catch {close_hw_manager}
if {$failed} {
    puts stderr "ERRO: $message"
    puts stderr [dict get $options -errorinfo]
    exit 1
}
