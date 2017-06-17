transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/Users/Carol/Documents/quartusworkspace/CanBus {C:/Users/Carol/Documents/quartusworkspace/CanBus/can_form_error.v}
vlog -vlog01compat -work work +incdir+C:/Users/Carol/Documents/quartusworkspace/CanBus {C:/Users/Carol/Documents/quartusworkspace/CanBus/can_crc_checker.v}
vlog -vlog01compat -work work +incdir+C:/Users/Carol/Documents/quartusworkspace/CanBus {C:/Users/Carol/Documents/quartusworkspace/CanBus/can_decoder.v}

vlog -vlog01compat -work work +incdir+C:/Users/Carol/Documents/quartusworkspace/CanBus {C:/Users/Carol/Documents/quartusworkspace/CanBus/can_testbench.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc"  can_testbench

add wave *
view structure
view signals
run -all
