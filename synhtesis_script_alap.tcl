source ./tcl_scripts/setenv.tcl
source ../EXERCISES/alap.tcl

read_design ../data/DFGs/fir.dot
read_library ./data/RTL_libraries/RTL_lib_1.txt

set latency 60
set alap_result [alap 60]
foreach pair $alap_result {
	set node_id  [lindex $pair 0]
	set start_time[lindex $pair 1]
	puts"Node : $node_id start  @ $start_time
}

printf_dfg ./data/out/fit_alap.dot
print_scheduled_dfg $alap_schedule ./data/out/fir_alap.dot
exit

