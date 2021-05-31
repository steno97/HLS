proc asap {} {
  set lista [list]
  set node_start_time [list]
  set lista_risorse [list]
  foreach node [get_sorted_nodes] {
    set start_time 1
    foreach parent [get_attribute $node parents] {
      set parent_op [get_attribute $parent operation]
      set fu [get_lib_fu_from_op $parent_op]
      set parent_delay [get_attribute $fu delay]
      set idx_parent_start [lsearch -index 0 $node_start_time $parent]
      set parent_start_time [lindex [lindex $node_start_time $idx_parent_start] 1]
      set parent_end_time [expr $parent_start_time + $parent_delay]
      if { $parent_end_time > $start_time } {
        set start_time $parent_end_time
      }
      set fu_indx [lsearch -index 0 -all $lista_risorse $fu]
      if {$fu_indx != "" } {
	set quantity [lindex [lindex $lista_risorse $fu_indx] 1] 
	set quantity [ expr { $quantity + 1 }]
	lreplace $lista_risorse $fu_indx $fu_indx "$fu $quantity"
	} else {
		lappend lista_risorse "$fu 1"
		lsort -dictionary $lista_risorse				;#è una lista contenente non tutte le risorse ma quelle attualmente disponibili
	}
    }
    lappend node_start_time "$node $start_time"
  }
  lappend lista $lista_risorse
  lappend lista $node_start_time
  return $lista

}

proc analisi_area {lista_risorse} {
	set area 0
	set bolean 0
	foreach elem $lista_risorse {
		set fu [lindex $elem 0]
		set var [get_attribute $fu area]
		set quantity [lindex $elem 1]
		set area [expr {$var*$quantity+$area}]
	}
	return $area
}




