# Base: UG892 (2026.1), pp. 72-73, RTL Project Tcl Script.
# Uso: vivado -mode batch -source scripts/build.tcl -tclargs bitstream 4
source [file join [file dirname [info script]] .. project.tcl]

proc set_if_changed {property value object} {
    if {[get_property $property $object] ne $value} {
        set_property $property $value $object
    }
}

# Sincroniza inclusoes e remocoes na lista de fontes do projeto persistente.
proc sync_files {fileset desired} {
    set existing [get_files -quiet -of_objects [get_filesets $fileset]]
    foreach path $existing {
        if {[lsearch -exact $desired $path] < 0} {
            remove_files -fileset $fileset [list $path]
        }
    }
    foreach path $desired {
        if {[lsearch -exact $existing $path] < 0} {
            add_files -norecurse -fileset $fileset [list $path]
        }
    }
}

proc run_complete {name step} {
    set run [get_runs $name]
    return [expr {![get_property NEEDS_REFRESH $run] &&
        [get_property PROGRESS $run] eq "100%" &&
        [get_property STATUS $run] eq "$step Complete!"}]
}

proc launch_and_check {name step jobs} {
    puts "EXECUTANDO: $name ate $step"
    launch_runs $name -to_step $step -jobs $jobs
    wait_on_run $name
    # wait_on_run aguarda o termino, mas nao comprova sucesso.
    if {![run_complete $name $step]} {
        error "$name falhou: [get_property STATUS [get_runs $name]]. Consulte build/vivado/*.runs/$name/runme.log."
    }
}

proc main {} {
    global argv part top project_name project_dir project_file
    global rtl_files xdc_files include_dirs verilog_defines report_dir bitstream_file
    set stage [lindex $argv 0]
    if {$stage eq ""} { set stage bitstream }
    set jobs [lindex $argv 1]
    if {$jobs eq ""} { set jobs 4 }
    if {[llength $argv] > 2 || $stage ni {project synth impl bitstream gui} ||
        ![string is integer -strict $jobs] || $jobs < 1} {
        error "Uso: -tclargs project|synth|impl|bitstream|gui ?jobs>0?"
    }
    if {![llength $rtl_files]} { error "Defina rtl_files em project.tcl." }
    if {![llength $xdc_files]} { error "Defina xdc_files em project.tcl." }
    foreach path [concat $rtl_files $xdc_files] {
        if {![file isfile $path]} { error "Arquivo inexistente: $path" }
    }
    if {[file exists $project_file]} {
        open_project $project_file
        if {[get_property PART [current_project]] ne $part} {
            error "O part do projeto mudou. Execute make clean antes de recompilar."
        }
    } else {
        create_project $project_name $project_dir -part $part
    }
    sync_files sources_1 $rtl_files
    sync_files constrs_1 $xdc_files
    set_if_changed top $top [get_filesets sources_1]
    set_if_changed include_dirs $include_dirs [get_filesets sources_1]
    set_if_changed verilog_define $verilog_defines [get_filesets sources_1]
    update_compile_order -fileset sources_1

    if {$stage eq "gui"} { return }
    if {$stage eq "project"} { close_project; return }

    if {![run_complete synth_1 synth_design]} {
        # Invalidar tambem a implementacao quando a sintese precisar ser refeita.
        reset_runs impl_1
        reset_runs synth_1
        launch_and_check synth_1 synth_design $jobs
    } else {
        puts "ATUALIZADO: synth_1"
    }
    file mkdir $report_dir
    open_run synth_1
    report_timing_summary -report_unconstrained -file [file join $report_dir synth_timing.rpt]
    report_utilization -file [file join $report_dir synth_utilization.rpt]
    close_design
    if {$stage eq "synth"} { close_project; return }

    set routed [run_complete impl_1 route_design]
    set written [run_complete impl_1 write_bitstream]
    if {!$routed && !$written} {
        reset_runs impl_1
        launch_and_check impl_1 route_design $jobs
    } else {
        puts "ATUALIZADO: impl_1 (posicionamento e roteamento)"
    }

    if {$stage eq "bitstream"} {
        set generated_bit [file join [get_property DIRECTORY [get_runs impl_1]] ${top}.bit]
        if {[run_complete impl_1 write_bitstream] && ![file isfile $generated_bit]} {
            # Recupera tambem a exclusao manual do produto de uma run concluida.
            reset_runs -from_step write_bitstream impl_1
        }
        if {![run_complete impl_1 write_bitstream]} {
            launch_and_check impl_1 write_bitstream $jobs
        }
        if {![file isfile $generated_bit]} { error "Bitstream nao encontrado: $generated_bit" }
        file mkdir [file dirname $bitstream_file]
        file copy -force $generated_bit $bitstream_file
        puts "BITSTREAM: $bitstream_file"
    }

    open_run impl_1
    report_timing_summary -report_unconstrained -file [file join $report_dir impl_timing.rpt]
    report_utilization -file [file join $report_dir impl_utilization.rpt]
    report_drc -file [file join $report_dir impl_drc.rpt]
    close_project
}

if {[catch {main} message options]} {
    puts stderr "ERRO: $message"
    puts stderr [dict get $options -errorinfo]
    exit 1
}
