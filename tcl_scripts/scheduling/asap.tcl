proc asap {} {
#Output is a pairs, each pair with node id and relative start time
# Output : { {NO 1} {N1 1} {N2 10} ...}
  set node_start_time [list]

#start time of node i :  S(Ni) = max( end_time(Nj)) with parents(Ni)
#if N has no parents then S(Mi) = 1
  foreach node [get_sorted_nodes] {
    set start_time 1
    #
    #compute the end_time of the parent
    #end_time_parent = start_time(parent) + delay(parent)

    #step to get the delay for the parent
    foreach parent [get_attribute $node parents] {
      set parent_op [get_attribute $parent operation]
      set fu [get_lib_fu_from_op $parent_op]
      set parent_delay [get_attribute $fu delay]
	#NOTE : SINCE ITERATING IN TOPOLOGICAL ORDER we are sure that the parent has already been scheduled
    #step to get the start time of the parent
      set idx_parent_start [lsearch -index 0 $node_start_time $parent]
      set parent_start_time [lindex [lindex $node_start_time $idx_parent_start] 1]
      set parent_end_time [expr $parent_start_time + $parent_delay]
      if { $parent_end_time > $start_time } {
        set start_time $parent_end_time
      }
    }
	#lappend the list of the scheduled time 
    lappend node_start_time "$node $start_time"
  }

  return $node_start_time

}
