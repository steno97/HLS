source ./tcl_scripts/setenv.tcl
source ./tcl_scripts/scheduling/asap.tcl

read_design ./data/DFGs/fir.dot            				;# to load the design 
read_library ./data/RTL_libraries/RTL_lib_1.txt 			;# to load the library

set asap_schedule [asap] 

foreach time_pair $asap_schedule {
	
	set node_id [lindex $time_pair 0]
	set start_time [lindex $time_pair 1]
	
	puts "Node $node_id starts @ $start_time"
}

print_dfg ./data/out/fir.dot
print_scheduled_dfg $asap_schedule ./data/out/fir_asap.dot


exit
