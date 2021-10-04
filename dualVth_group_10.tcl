;#IMPROVEMENTS : Cambiare i nomi in inglese 
;#CAN BE DEFINED SOME OPERATORS THAT DO EACH FUNCTION JOB 



global initial_area 
global initial_leakage
global initial_dynamic
global allowed_slack 
global final_area
global final_leakage
global final_dynamic
global start_time 

#################################################################################################################
proc dualVth {args} {
	parse_proc_arguments -args $args results
	global allowed_slack 
	set allowed_slack $results(-allowed_slack)
	
	#################################
	### INSERT YOUR COMMANDS HERE
	suppress_message PWR-604
	suppress_message LNK-016
	suppress_message PWR-246
	suppress_message PWR-601
	suppress_message PWR-602
	suppress_message PTE-139
	suppress_message LNK-041
	suppress_message NED-045
	suppress_message PTE-139        
	global initial_area 
	global initial_dynamic 
	global initial_leakage
	global start_time  
	set initial_area [get_attribute [get_design] area ]
	set initial_dynamic [get_attribute [get_design] dynamic_power ]
	set initial_leakage [get_attribute [get_design] leakage_power ]
	set initial_score 3
	#puts "Initial score is $initial_score" 
	set start_time [ clock seconds ] ; #timestamp at the start of the proc
	optimize 
	set final_score [score_design]
	set time_elapsed [expr { [clock seconds ] - $start_time } ]
	#puts "Final score is $final_score, operation last $time_elapsed"
	#################################
}

define_proc_attributes dualVth \
-info "Post-Synthesis Dual-Vth Cell Assignment and Gate Re-Sizing" \
-define_args \
{
	{-allowed_slack "allowed slack after the optimization (valid range [-OO, 0])" value float required}
}

###############################################################################################################

proc optimize { } { 
	#valori iniziali:
	global initial_area 
	global initial_dynamic
	global initial_leakage 
	global allowed_slack
	global start_time
	;# FIRST STEP: Covert LVT cells to HVT withouth violating the allowed slack  
	set LVT_cells [list]
	set HVT_initial_cells [list]
	foreach_in_collection point_cell [get_cells] {
		set lib_cell [get_lib_cell -of_object $point_cell]
		set type [get_attribute $lib_cell threshold_voltage_group]
		if { $type != "HVT"} {
			lappend LVT_cells $point_cell
		} else {
			lappend HVT_initial_cells $point_cell
		}
	}
	set LVT_cells_to_resize [list]
	set LVT_cells_to_resize [change_cells_to_HVT $LVT_cells]	
	;# SECOND STEP: Resize the reamaing  LVT cells withouth violating the allowed slack
	foreach cell $LVT_cells_to_resize {
		set time_elapsed [expr { [clock seconds ] - $start_time } ]
		if { $time_elapsed < 780 } {
			resize_cell $cell
		}
	}
	;#THIRD STEP: Resize the inital HVT cells withouth violating the allowed slack
	foreach cell $HVT_initial_cells {
		set time_elapsed [expr { [clock seconds ] - $start_time } ]
		if { $time_elapsed < 780 } {
			resize_cell $cell
		}
	}	
}

####################################################################################################

proc change_cells_to_HVT { LVT_cells } {
	global allowed_slack 
	global start_time 
	set swap 1
	set cells_swapped 0 
	set time_elapsed [expr { [clock seconds ] - $start_time }]
	while { $swap && ($time_elapsed < 780) } {
		set LVT_cells [ lsort -command compare_priority $LVT_cells ]
		set to_swap [lindex $LVT_cells 0 ]
		set full_name [ get_attribute $to_swap full_name ]
		set max_slack [ get_attribute [ get_timing_paths -nworst 1 -through $full_name ] slack ]
		set lib_cell [get_lib_cell -of_object $to_swap]
		set type [get_attribute $lib_cell threshold_voltage_group]
		set tried 0
		set stop 0 
		while { !$stop && [ llength $LVT_cells] > 0 } {
			foreach tested $LVT_cells {
					set full_name [ get_attribute $tested full_name ]
					set max_slack [ get_attribute [ get_timing_paths -nworst 1 -through $full_name ] slack ]
					if { $max_slack < $allowed_slack } {
						;#Meaning that there is an error since the global worst slack should be higher than allowed_slack
						;#puts "Error with global slack value!"
					} 
			}
			if { ![ change_cell_Vth $to_swap HVT ] } {
				if { ($tried < 10) && ($time_elapsed < 780) } {
					#trying to leave a local minimum 	
					incr tried
					#puts "Attempt number $tried"	
					set to_swap [lindex $LVT_cells $tried]
					set full_name [ get_attribute $to_swap full_name ]
					set max_slack [ get_attribute [ get_timing_paths -nworst 1 -through $full_name ] slack ]
					if { $max_slack < $allowed_slack } {
						;#Meaning that there is an error since the global worst slack should be higher than allowed_slack 
						;#puts "There is an error! found slack is $max_slack"
					} else {
					#puts "Anlazyng cell $to_swap in local min with slack $max_slack"
					}
				} else {
					set stop 1
					set swap 0 
					#set LVT_cells [ lreplace $LVT_cells 0 0 ]
					#puts "Stopped trying to leave local minimum"	
				}
				set time_elapsed  [expr { [ clock seconds] - $start_time } ]
			} else {
				set LVT_cells [ lreplace $LVT_cells $tried $tried ]
				set tried 0
				incr cells_swapped
				set stop 1 
			}
		}
           	set time_elapsed [expr { [clock seconds ] - $start_time }]
	}
	#puts "The operation last $time_elapsed, numb of cells swapped $cells_swapped" 
	return $LVT_cells
}

####################################################################################################
 
proc resize_cell { to_resize } {
	global allowed_slack
	set c_leakage_init [get_attribute $to_resize leakage_power ]
	set c_dynamic_init [get_attribute $to_resize dynamic_power ]
	set c_area_init [get_attribute $to_resize leakage_power ]
	set ref_name [get_attribute $to_resize ref_name]
	set full_name [get_attribute $to_resize full_name]
	if { [regexp {_LL_|_LLS_} $ref_name ] } {
		set ref_name "CORE65LPLVT/$ref_name"
		set lib_cell "CORE65LPLVT_nom_1.20V_25C.db:"	
	}  elseif { [regexp {_LH_|_LHS_} $ref_name ] } {
		set ref_name "CORE65LPHVT/$ref_name"
		set lib_cell "CORE65LPHVT_nom_1.20V_25C.db:"
	}	
	regexp {.+\/(.+X)\d+} $ref_name reference header
	#reference is the one between {..}, while  header ( .. )
	#puts "Resizing cell $ref_name"	
	#Get other sizes of the same cell
	foreach_in_collection lib [get_alternative_lib_cells $to_resize] {
		if { [regexp ".+$header.+" [get_attribute $lib full_name] match] } {
			lappend alternatives $match
		}
	}
	set alternatives [lsort -dictionary $alternatives]
	regexp {\d+$} $ref_name size
	#puts "Initial size $size of cell $full_name"
	set score_cell 3
	foreach alt $alternatives {
		#Get the size of the alternative cell 
		regexp {\d+$} $alt alt_size
		#If the size retrieved from the library is smaller than the current one resize, since lower size cell has lower power consumption
		if { $alt_size < $size } {
			size_cell $full_name $lib_cell$alt
			#puts "new cell sized is [get_attribute $to_resize ref_name]"
			set c_area_changed [get_attribute $to_resize area ]
			set c_dynamic_changed [get_attribute $to_resize dynamic_power ]
			set c_leakage_changed [get_attribute $to_resize leakage_power ]
			set score_cell_i [ expr { ($c_area_init/$c_area_changed) + ($c_leakage_init/$c_leakage_changed) + ($c_dynamic_init/$c_dynamic_changed) } ]
			set slack [get_attribute [get_timing_paths] slack]
			#puts "The new cell score is $score_cell_i with slack $slack"
			#If global slack is lower than allowed slack or score is worse, undo
			if { $slack < $allowed_slack || $score_cell_i < $score_cell} {
				#puts "Indeed resized" 
				size_cell $full_name $lib_cell$ref_name
				#Otherwise cell was succesfully reduced to the minimum size and exit the loop
			} else  {
				set ref_name $alt
				set score_cell $score_cell_i
			}
		}
	}
}

####################################################################################################
proc compare_priority { a b } {
	set full_name_a [ get_attribute $a full_name ]
	set full_name_b [ get_attribute $b full_name ]
	set max_slack_a [ get_attribute [ get_timing_paths -nworst 1 -through $full_name_a ] slack ]
        set max_slack_b [ get_attribute [ get_timing_paths -nworst 1 -through $full_name_b ] slack ]
	set c_leakage_a [get_attribute $a leakage_power] 
	set c_leakage_b [get_attribute $b leakage_power]
	set priority_a [expr { $c_leakage_a * $max_slack_a }]
	set priority_b [expr { $c_leakage_b * $max_slack_b }]
	if { $priority_a >= $priority_b } {
		return -1 
	} else {
		return 1
	}	
} 

####################################################################################################
proc change_cell_Vth { cell Vth_type } {
	;#expected that the Vth_type given as parameter is different from the initial one of the cell 
	;# will chose the version of Vth_type such that the slack allowed is not violated and the score is maximum 
	global allowed_slack 
	set done 0 
	set initial_type [ get_attribute [get_lib_cell -of_object $cell] full_name ]
	set initial_Vth_type [get_attribute [get_lib_cell -of_object $cell] threshold_voltage_group]
	if { $initial_Vth_type eq "HVT" } {
		set initial_lib_cell "CORE65LPHVT_nom_1.20V_25C.db:"
	} else {
		set initial_lib_cell "CORE65LPLVT_nom_1.20V_25C.db:"
	}
	set ref_lib $initial_lib_cell$initial_type
	#puts "$ref_lib "
	set lib_cell "CORE65LP$Vth_type\_nom_1.20V_25C.db:"
	set reference_name [get_attribute $cell ref_name]
	#puts "Analyzing cell $reference_name"
	set c_leakage_init [get_attribute $cell leakage_power ]
	set c_dynamic_init [get_attribute $cell dynamic_power ]
	set c_area_init [get_attribute $cell area ]
	;#Retrieved all the cells variation (Vth and size) :
	set alt_lib [get_alternative_lib_cells $cell]	
	set score_cell 3
	set first_time 1
	foreach_in_collection t $alt_lib { 
		;#In this case we are interested only in versions that has Vth_type
		set name_lib [get_attribute $t full_name]
		;#Took the Vth version, done for all the sizes 
		;#matchVar is the ref_name of the new cell 
		set res [ regexp "CORE65LP$Vth_type\/.+" $name_lib matchVar ]
		if { $res == 1 } {
			set new_lib $lib_cell$matchVar
			swap_cell $cell $new_lib   
			set c_area_changed [get_attribute $cell area ]
			set c_dynamic_changed [get_attribute $cell dynamic_power ]
			set c_leakage_changed [get_attribute $cell leakage_power ]
			set score_cell_i [ expr { ($c_area_init/$c_area_changed) + ($c_leakage_init/$c_leakage_changed) + ($c_dynamic_init/$c_dynamic_changed) } ]
			set full_name [ get_attribute $cell full_name ]
			set max_slack [get_attribute [get_timing_paths] slack]  
			if { $max_slack > $allowed_slack } {
				set done 1  
				if { $first_time } {  
					set first_time 0 
 					set ref_lib $new_lib
					set score_cell $score_cell_i
				} else { 
					if { $score_cell > $score_cell_i } {
					;#swapped back to the version that gived score_cell	
					swap_cell $cell $ref_lib
					} else {
						set ref_lib $new_lib
						set score_cell $score_cell_i
					}	
				}
			} else {
				;#swapped back to the version that was within the allowed_slack
				swap_cell $cell $ref_lib
			}
		} 
	}
	if { $done } {
		#puts "$score_cell"
		return 1
	} else {
		;#Returned the original cell
		#puts "slack allowed is not sufficient "  
		return 0 
	}			 	
;#At the end the cell will be swap with the Vth_type version that gives best score 
}

###################################################################################
proc score_design { } {
	global initial_area 
	global initial_leakage 
	global initial_dynamic
	global final_area
	global final_dynamic
	global final_leakage
	set new_design [get_design]
	set final_area [get_attribute $new_design area ]
	set final_dynamic [get_attribute $new_design dynamic_power ]
	set final_leakage [get_attribute $new_design leakage_power ]	
	set score [ expr { ($initial_area/$final_area) + ($initial_leakage/$final_leakage) + ($initial_dynamic/$final_dynamic) }] 
	return $score
}

