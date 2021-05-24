source ./tcl_scripts/setenv.tcl 
read_design ./data/DFGs/fir.dot 
read_library ./data/RTL_libraries/RTL_library_multi-resources.txt 

#GLOBAL VARIABLES : 
set da_incrementare [list]
set hu [list]
set nod_fu [list]
#####################################################################################################################################
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

######################################################################################################################################
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
	#return $lista	
	return $l 			;#returned the latency 
}

#######################################################################################################################################

#analisi area : takes as input the resources_used in the DFG implementation and returns the remaing area 

proc analisi_area {lista_risorse max} {
	set area 0
	set bolean 0
	foreach elem $lista_risorse {
		set fu [lindex $elem 0]
		set var [get_attribute $fu area]
		set quantity [lindex $elem 1]
		set area [expr {$var*$quantity+$area}]
	}
	set unused_area [expr {$max-$area}]
	return $unused_area
}





########################################################################################################################################
#This function takes as parameter 'max' that is the area constraint and uses the functions "prima_analisi{}, "latency{lista_risorse}","analisi_area{lista_risorse max}" that are in the file Stef_funcs.tcl
#to evaluate the best number of resources such that the resultant implementation got best latency within the area constraint 

#MODIFICHE : lista_da_incrementare data da me alla latency,quindi globale per me 


proc optimize {max} {
     
    # The list resources_to_incr  is used to keep track of operations required but that could not been executed during scheduling 
    # It's a list of pairs, meaning that each element of the list is composed of the informations {operation} {used}
    # "used" is a bool type that says if it is the first time analyzing the operation 
    
    set lista_risorse [prima_analisi]

    # In the first iteration the list resources_to_incr is composed of all the slowest fus of the resources needed to implement the DFG operations
    # In the first step so will be analyzed if by substituing them with their faster versions, area allowing, the overall latency improve
    set resources_to_incr [list]
    foreach elem $lista_risorse {           ;#lista_risorse is a list of pairs of the type "{fu} {numb_fu}" that are the resources used by the actual implementation of the DFG             
            set op [get_attribute [lindex $elem 0] operation]      ;#got the operation from the fu               
            set used 0                      ;#Used to distinguish the first iteration from the following  
            lappend resources_to_incr "$op $used"
    }
    
    # Parameters needed to implement the algorithm :
    set l [latency $lista_risorse]                      ;#called the function "latency" that returns the latency of the DFG using the resources in lista_risorse           
    set unused_area [analisi_area $lista_risorse $max]        ;#evaluated the area used 
    set latency_optimized [list]
    set index 0
    foreach elem $resources_to_incr { 
        lappend latency_optimized "[lindex $lista_risorse $index 0] $l"                 
        ;#latency_optimized is a list that contains in the beginning alla the slowest fus associated to the operations needed by the DFG
	;#and the initial latency l obtained by using the least number and least performance resources                                             
	;#from the second iteration and so on the latency_optimized list is like a mirror of resources_to_incr, since it keeps track of how the latency change 
	;#by adding a fu associated to the operation needed 
        set index [expr {$index+1}]
    }                                                 
    
    set end_opt 0                                    ;#when end_opt = 1 then the optimal solution using this alogorithm has been found 

    while {$end_opt eq 0} {   
        #set elem_indx 0                      ;#Keeps track of the index of the operation in the list resources_to_incr       
	;#updated the list resources_to_incr based on asked_resources 
        foreach elem $resources_to_incr {
            set lista_risorse_to_test $lista_risorse               ;#lista_risorse_to_test is a list that is used to evaluate the latency by changing the resources 
                                                                   ;#of lista_risorse, at each iteration is initialized with the values in lista_risorse
            set op [lindex $elem 0]
            set used [lindex $elem 1]        
            set op_fus [get_lib_fu_from_op $op]       ;#returns the ids of the fus that can execute the operation
            set op_indx [lsearch -index 0 -all $resources_to_incr $op]
            if {$used eq 0} {                  ;#meaning that it is the first time analyzing this operation and so we check which of the fus associated to the operation
                                             ;#is able to give better latancy with less area                        
                ;#Searched the fu associated to the operation in order to got information about the used area 
		set fu_indx 0 
                foreach fu_j $lista_risorse {            
                    if { [get_attribute [lindex $fu_j 0] operation] eq $op } {  
                         set fu [lindex $fu_j 0] 
			 break
                    } else {
                        set fu_indx [expr {$fu_indx + 1}]
                    } 
                }
		set initial_fu $fu   
                set latency_fu $l                           ;#intial latency with the fu already used in lista_risorse is l--> Ma mica è valido sempre, solo nella prima iterazione |!!!!! O meglio mi vale se updato l di continuo 
                set area_fu [get_attribute $fu area]
                set remaining_area [expr { $unused_area + $area_fu}] 
                # In the first step is analyzed which version of the fus of the operation gives the better latency with less area   
                # Simply tested all of them up to when is found the one that gives less latency with less area 
                set impl_check 0                                  ;#boolean variable, set to 1 if there's enough area to implement one of the fu associated to the op
		foreach fu_i $op_fus {                      ;#fu_i indicate the i-esim fu that can perform this operation    
                   if { $fu_i != $initial_fu } {    
                       set area_fu_i [get_attribute $fu_i area] 
                        if {$area_fu_i < $remaining_area} {                ;# Meaning that the fu_i can be implemented 
                            set impl_check 1                             ;#impl_check 1 if exist at least one fu that can be implemented with remaing area --> Che poi sarà sempre vero perchè fatto il check anche su quella usata  
                            #Is evaluated the latency by substituing the fu with the tested one (fu_i)
                            set lista_risorse_to_test [lreplace $lista_risorse_to_test $fu_indx "$fu_i 1"]           
                            set latency_fu_i [ latency $lista_risorse_to_test ] 
                            #if the latency obtained using fu_i is lower  OR if it is equal but use less area than fu then the fu is replaced with fu_i
                            if { [expr { [latency_fu_i < latency_fu] || [latency_fu_i == latency_fu && area_fu_i < area_fu] }] == 1 } {     
                                # substituing the old fu with the tested one 
                                set fu $fu_i
                                set latency_fu $latency_fu_i 
                                #updating the latency list
                                lreplace $latency_optimized $op_indx "$fu_i $latency_fu_i"
                            }
                        }
		   }	 
                }
                if {$impl_check eq 0} {
                    ;#meaning that do no exist a fu associated to the operation that can be implemented 
                     set resources_to_incr [lreplace $resources_to_incr $op_indx $op_indx]           ;#removed the operation from resources_to_incr
                     set latency_optimized [lreplace $latency_optimized $op_indx $op_indx ]          ;#removed the correspondent cell in the list latency_optimized
                }            
            } else {            ;#meaning that in this case we have to increment a resource and so found fu associated to the operation required that gives the best latency 
                   set impl_check 0                                  ;#boolean variable, set to 1 if there's enough area to implement one of the fu associated to the op
                   #Simply searched for them all up to when is found the one that gives less latency with less area 
                    foreach fu_i $op_fus {                      ;#fu_i indicate the i-esim fu that can perform this operation    
                        set area_fu_i [get_attribute $fu_i area]
                        if { [expr { $unused_area - $area_fu}] > 0} {                 ;#Meaning that the fu can be implemented
                            ;#added the fu in the list lista_risorse_to_test and evaluated the latency
                            set impl_check 1                             ;#impl_check 1 if exist at least one fu that can be implemented with remaing area
                            set fu_indx [lsearch -index 0 -all $lista_risorse $fu_i]
			    if {fu_indx != -1} {        ;#so if already used this fu then is simply incremented the number 
                                set incr_number_fu [ expr { [lindex $lista_risorse $fu_indx 1] + 1}]
                                set lista_risorse_to_test $lista_risorse                                            ;#reset of the list lista_risorse_to_test
                                set lista_risorse_to_test [lreplace $lista_risorse_to_test $fu_indx "$fu_i $incr_number_fu"]
                            } else {      ;#added the fu 
                                lappend lista_risorse_to_test "$fu_i 1"                     
                            }
                            set latency_fu_i [ latency $lista_risorse_to_test ];
                            if { [expr { [latency_fu_i < latency_fu] || [latency_fu_i == latency_fu && area_fu_i < area_fu] }] == 1} {     
                                # substituing the old fu with the tested one 
                                set fu $fu_i
                                set latency_fu $latency_fu_i 
                                #updating the latency list
                                lreplace $latency_optimized $op_indx "$fu_i $latency_fu_i"
                            }
                        }
                    }
                 if {$impl_check eq 0} {
                    ;#meaning that do no exist a fu associated to the operation that can be implemented 
                     set resources_to_incr [lreplace $resources_to_incr $op_indx $op_indx]           ;#removed the operation from resources_to_incr
                     set latency_optimized [lreplace $latency_optimized $op_indx $op_indx ]          ;#removed the correspondent cell in the list latency_optimized
                }     
            }
	;#incresed the index of the elem
	;#set elem_indx [expr {$elem_indx +1}]
        }
	
        ;#At the end of this loop in the list "latency_optimized" is contained a list of latency due to changing/adding a fu of an operation.
        ;#Then is parse the list "latency_optimized" and found the configuration that give the better latency
        ;#When found then it is added to lista_risorse, if no improvent due to changing/adding of a fu then the optimization finisheds
        set success 0 
        foreach elem $latency_optimized {
            if { [lindex[$elem 1]] < $l}  {
		set success 1
                #updated the latency
                set $l [lindex [$elem 1]]
                #updated the fu to add
                set fu_to_add [lindex [$elem 0]]
            }     
        } 
        if {$success eq 0} {       ;#so if no change determines an optimization of the delay, then has been reached the optimal solution
            set end_opt 1
        } else {
            ;#retrieved the operation associated to the fu 
            set op [get_attribute $fu_to_add operation]      ;#got the operation from the fu
            set op_indx [lsearch -index 0 -all $resources_to_incr $op] 
            set fu_indx [lsearch -index 0 -all $lista_risorse $fu_to_add] 
            if {$fu_indx != -1} {        ;#so if already used this fu then is simply incremented the number
                set incr_number_fu [ expr { [lindex $lista_risorse $fu_indx 1] + 1}]
                set lista_risorse [lreplace $lista_risorse $fu_indx "$fu_to_add $incr_number_fu"]		;#CONTROLLARE !!
            	} else {                     ;#if never used this fu then it is added in lista_risorse
                ;#added the fu
                lappend lista_risorse "$fu_to_add 1"
                ;#checked the "used" value associated to the operation 
                if { [lindex $resources_to_incr $op_indx 1] eq 0} {
                     lreplace $resources_to_incr $op_indx "$op 1"               ;#set used to 1 since now the operation has been analyzed
                }
            }
            ;#lunched the scheduling with the new lista_risorse and evaluated the operations required (that are in the list da_incrementare) 
            latency $lista_risorse
            set remove 1
            foreach op_required $da_incrementare{		;#Ma sta lista da_incrementare dove minchia la prendo ??
                if {$op_required eq $op} {
                    set remove 0
		    break                                
                }
            }
            if {$remove eq 1} {          ;#meaning that the operation associated to the added fu is no more required by the scheduler
                    set resources_to_incr [lreplace $resources_to_incr $op_indx $op_indx]           ;#removed the operation from resources_to_incr
                    set latency_optimized [lreplace $latency_optimized $op_indx $op_indx ]          ;#removed the correspondent cell in the list latency_optimized
  }
	    ;#reset of the latency in the list latency_optimized 
    	     set index 0
	     foreach elem $latency_optimized { 
        	lreplace $latency_optimized "[lindex $latency_optimized $index 0] $l"                 
		;#by adding a fu associated to the operation needed 
        	set index [expr {$index+1}]
   	      }		                                                 
        }    
    }
 foreach elem $lista_risorse {
	puts "$elem"
	}

}

