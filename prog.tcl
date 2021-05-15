source ./tcl_scripts/setenv.tcl 
read_design ./data/DFGs/fir.dot 
read_library ./data/RTL_libraries/RTL_library_multi-resources.txt 


proc prima_analisi { } {
	set lista_risorse [list]
	foreach node [get_sorted_nodes] {
		set node_op [get_attribute $node operation]
		set fu [get_lib_fu_from_op $node_op]
		set var [lsearch $lista_risorse "$fu 1"]
		if {$var == -1} {
			lappend lista_risorse "$fu 1" ;#$node_op"
		}
	}	
	return $lista_risorse
}

proc latency {lista_risorse} {
	set lista [list]
	set da_incrementare [list]
	set hu [list]   		;#lista con nodo e start time
	set node_fu [list]		;#lista con nodo e unità funzionale
	set in_corso [list]		;#lista con nodo che stanno in scheduling e start_time
	set l 1
	set list_node [get_sorted_nodes]
	while {$list_node != []} { 
		foreach elem $in_corso {				
			set node [lindex $elem 0]				;#prendo il nodo
			set start_time [lindex $elem 1]				;#prendo lo start_time
			set fu_indx [lsearch -index 0 -all $node_fu $node]	
			set fu [lindex [lindex $node_fu $fu_indx] 1]		;#prendo l'unità funzionale
			set delay [get_attribute $fu delay]							
			if { [expr {$start_time+$delay}] == $l} {					    
				lappend hu "$node $start_time"								
				set o_indx [lsearch $in_corso $elem]
				set in_corso [lreplace $in_corso $o_indx $o_indx]		;#rimuovo nodo da in corso
				set fu_indx [lsearch -index 0 -all $lista_risorse $fu]
				if {$fu_indx != "" } {
					set quantity [lindex [lindex $lista_risorse $fu_indx] 1] 
					set quantity [ expr { $quantity + 1 }]
					lreplace $lista_risorse $op_idx $op_idx "$risorsa $quantity"
				} else {
					lappend lista_risorse "$fu 1"
					lsort -dictionary $lista_risorse				;#è una lista contenente non tutte le risorse ma quelle attualmente disponibili
				}
			}
		}									;#da scrivere bene		
		foreach node $list_node {	
			set boolean 1
			foreach parent [get_attribute $node parents] {		;#da scrivere bene
				if {[lsearch -index 0 $hu $parent] == -1} {
					set boolean 0			
						#se i parenti sono in hu
				}
			}
			if {$boolean == 1} {
				foreach elem $lista_risorse {									;#da scrivere bene  #impotizzare switch dei cicli 
					set risorsa [lindex $elem 0]
					set op_node [get_attribute $node operation]
					set op_fu [get_attribute $risorsa operation]
					if {$op_node == $op_fu} {
						set node_indx [lsearch $list_node $node]
						set list_node [lreplace $list_node $node_indx $node_indx]
						lappend in_corso "$node $l"
						lappend node_fu "$node $risorsa"
						set op_idx [lsearch  $lista_risorse $elem]
						if {[lindex $elem 1] > 1} {
							set quantity [ expr {[lindex $elem 1]-1}]
							lreplace $lista_risorse $op_idx $op_idx "$risorsa $quantity" 
						} else {
							set lista_risorse [lreplace $lista_risorse $op_idx $op_idx]
						
						}
					} else {
						lappend da_incrementare $op_node
					}
				}
			}
		}
		incr l
	}	
	while {$in_corso != []} {
		foreach elem $in_corso {	
			set node [lindex $elem 0]
			set start_time [lindex $elem 1]
			set fu_indx [lsearch -index 0 -all $node_fu $node]
			set fu [lindex [lindex $node_fu $fu_indx] 1]
			set delay [get_attribute $fu delay]
			set cond [expr {$start_time + $delay}] 						;#da scrivere bene
			if { $cond == $l} {					   
				lappend hu "$node $start_time"		
				set o_idx [lsearch $in_corso $elem]					
				set in_corso [lreplace $in_corso $o_idx $o_idx]		;#rimuovo nodo da in corso
				set fu_indx [lsearch -index 0 -all $lista_risorse $fu]
				if {$fu_indx != "" } {
					set quantity [ expr {[lindex [lindex $lista_risorse $fu_indx] 1] + 1}]
					lreplace $lista_risorse $op_idx  $op_idx "$risorsa $quantity"
				} else {
					lappend lista_risorse "$fu 1"
					lsort -dictionary $lista_risorse				;#è una lista contenente non tutte le risorse ma quelle attualmente disponibili
				}				
			}
		}
		incr l													
	}
	lappend lista $hu 			;#"nodo start_time"
	lappend lista $node_fu		;#"nodo fu"
	lappend lista $lista_risorse		;#"risorse n"
	lappend lista $da_incrementare
	lappend lista $l
	return $lista	
}	
