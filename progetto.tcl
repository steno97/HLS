
#prima analisi
proc prima_analisi {} {
	set lista_risorse [list]
	foreach node [get_sorted_nodes] {
		set node_op [get_attribute $node operation]
		set fu [get_lib_fu_from_op $node_op]
		set var [lsearch $lista_risorse "$fu 1"]
		if {$var==-1} {
			lappend lista_risorse "$fu 1" ;#$node_op"
		}
	}	
	return $lista_risorse
}
#serve per assegnare il minimo di risorse iniziali per la partenza (questo permette di non considerare risorse per le quali non c'è necessità)

#si potrebbe ottimizzare in questo modo, creando alla prima analisi due liste, una con una sola unità funzionale per operazione e una con tante unità funzionali quante sono le 
#operazioni da svolgere, successivamente vedere il constraint dell'area a qualle delle due liste è più vicino e scegliere quest'ultima come punto di partenza per la nostra analisi


#calcolo latency
proc latency {lista_risorse} {
	set lista[list]
	set da_incrementare [list]
	set hu [list]   		;#lista con nodo e start time
	set node_fu [list]		;#lista con nodo e unità funzionale
	set in_corso [list]		;#lista con nodo che stanno in scheduling e start_time
	set l 1
	set list_node [get_sorted_nodes]
	while {$list_node != []} { 
		foreach elem $in_corso {	
			set node [lindex $elem 0]
			set start_time [lindex $elem 1]
			set fu_indx [lsearch -index 0 -all $node_fu $node]
			set fu [lindex [lindex $node_fu $fu_indx] 1]
			set delay [get_attribute $fu delay]							
			if { expr {$start_time+$delay} == $l} {					    
				lappend hu "$nodo $start_time"								
				set in_corso [lreplace $in_corso $fu_indx $fu_indx]				;#rimuovo nodo da in corso
				
				set fu_indx [lsearch -index 0 -all $lista_risorse $fu]
				if {fu_indx != -1 } {
					set quantity [ expr {[lindex [lindex $lista_risorse fu_indx] 1] + 1}]
					lreplace $lista_risorse op_idx op_idx "$risorsa $quantity"
				}
				else{
					lappend lista_risorse $fu
					lsort -dictionary $lista_risorse				;#è una lista contenente non tutte le risorse ma quelle attualmente disponibili
				}
			}
		}																;#da scrivere bene		
		foreach node lista_node{	
			#set start_time 1
			set boolean 0
			foreach parent [get_attribute $node parents] {		;#da scrivere bene
							
						#se i parenti sono in hu						;#da scrivere bene	
						#altrimenti uscire
						#calcolare lo start_time maggiore
					}
			if {boolean == 1} {
				foreach elem $lista_risorse {									;#da scrivere bene  #impotizzare switch dei cicli 
					set risorsa [lindex $elem 0]
					set op_node [get_attribute $node operation]
					set op_fu [get_attribute $risorsa operation]
					if {$op_node == $op_fu}{
						set node_indx [lindex $list_node $node]
						set list_node [lreplace $list_node $node_indx $node_indx]
						lappend in_corso "$node $l"
						lappend node_fu "$node $risorsa"
						set op_idx [lsearch $lista_risorse $elem]
						if {[lindex $elem 1] > 1}
							set quantity [ expr {[lindex $elem 1]-1}]
							lreplace $lista_risorse op_idx op_idx "$risorsa $quantity" 
						}				#rimuovo la risorsa dalla lista risorse
						else {
							set $lista_risorse [lreplace $lista_risorse op_idx op_idx]
						}
					}
					else {
						lappend da_incrementare $op_node
					}
				}
			}
		}
		
		#foreach risorsa $lista_risorse									;#da scrivere bene  #impotizzare switch dei cicli 
		#	foreach node lista_node										;#da scrivere bene
		#		if risorsa==node										;#da scrivere bene
		#			set start_time 1									;#da scrivere bene	
		#			foreach parent [get_attribute $node parents] {		;#da scrivere bene
							
						#se i parenti sono in hu						;#da scrivere bene	
						#altrimenti uscire
						#calcolare lo start_time maggiore
					}
		#		if se i parenti non erano in hu uscire					;#da scrivere bene
		#		#assegnare alla variabile risorsa_necessaria l'operazione del nodo figlio (quella che andremo ad aggiungere)
		#		lappend node in corso 									;#da scrivere bene
		#		lappend node node_fu											;#da scrivere bene
		#		rimuovi la risorsa dalla lista risorse					;#è una lista contenente non tutte le risorse ma quelle attualmente disponibili
				
		incr l
	}	
	while {$in_corso != []} {
		foreach elem $in_corso {	
			set node [lindex $elem 0]
			set start_time [lindex $elem 1]
			set fu_indx [lsearch -index 0 -all $node_fu $node]
			set fu [lindex [lindex $node_fu $fu_indx] 1]
			set delay [get_attribute $fu delay]											;#da scrivere bene
			if { expr {$start_time+$delay} == $l} {					   
				lappend hu "$nodo $start_time"							
				set in_corso [lreplace $in_corso $fu_indx $fu_indx]				;#rimuovo nodo da in corso
				set fu_indx [lsearch -index 0 -all $lista_risorse $fu]
				if {fu_indx != -1 } {
					set quantity [ expr {[lindex [lindex $lista_risorse fu_indx] 1] + 1}]
					lreplace $lista_risorse op_idx op_idx "$risorsa $quantity"
				}
				else{
					lappend lista_risorse $fu
					lsort -dictionary $lista_risorse				;#è una lista contenente non tutte le risorse ma quelle attualmente disponibili
				}				
			}
		}
		incr l																;#
	}
	lappend lista $hu 			;#"nodo start_time"
	lappend lista $node_fu		;#"nodo fu"
	lappend lista $risorse		;#"risorse n"
	lappend da_incrementare
	lappend l
	return lista	
}			

#abbiamo bisogno di una lista che tiene conto delle risorse disponibili al momento
#sarebbe comodo creare una variabile che indica che tipo di risorsa si necessita aumentare (iquadrando quale operazione non si riesce ad eseguire)




#aumentare risorse

#1)aumento le risorse
#2)chiamo analisi_area
#3)se sforo torno indietro e aumento un'altra cosa
#4)se non sforo provo a calcolare la latency 
#(tenere una lista con i vecchi dati di letency e di risorse)


#per chiarezza io ti passo una lista contenente queste 5 cose: 
		#-lista_nodi "nodo start_time"
		#-lista_nodi_unità "nodo unita_funzionale"
		#-lista_risorse "unita_funzionale numero_unita" -----questa è quella che mi dovrai poi ripassare a me
		#-tempo scheduling totale
		#-lista_da_incrementare "operazione" (lista_con_le_operazioni_che_si_desidera_incrementare)						

proc aumentare_risorse { lista lista_risorse_da_incrementare} {
	var globale1=1
	var globale2=delay

	if globale 2<attuale delay 
		tornare vecchia soluzione

		if constraint area non raggiunto
			scansione lista risorse da incrementare
	else 
		for lista_risorsa
	
		lista_risorse rimuovo due per una più rapida.
		
		
		#se devi aggiungere un'unità funzionale alla lista risorse
		set fu_indx [lsearch -index 0 -all $lista_risorse $fu]
		if {fu_indx != -1 } {
			set quantity [ expr {[lindex [lindex $lista_risorse fu_indx] 1] + 1}]
			lreplace $lista_risorse op_idx op_idx "$risorsa $quantity"
		}
		else{
			lappend lista_risorse $fu
			lsort -dictionary $lista_risorse				
		}	
		#se devi rimuovere un'unità funzionale alla lista risorse
		set op_idx [lsearch $lista_risorse $elem]
		if {[lindex $elem 1] > 1}   #elem è: "unità_funzionale quantità"
			set quantity [ expr {[lindex $elem 1]-1}]
			lreplace $lista_risorse op_idx op_idx "$risorsa $quantity" 
		}				#rimuovo la risorsa dalla lista risorse
		else {
			set $lista_risorse [lreplace $lista_risorse op_idx op_idx]
		}
	
	4 add lenta, 3 mul lenta, 1 shift

	-opzione ridurre un tipo per un altro

	-levare due elementi di un tipo in favore di uno più veloce
	
	latency {lista_risorse}
}



#analisi area

#un'implementazione fattibile sarebbe usare al posto di analisi area una 
#variabile che mantiene di volta in volta il valore dell'area occupata
#ciò richiederebbe un ciclo in meno
proc analisi_area {lista_risorse max} {
	set area 0
	set bolean 0
	foreach elem $lista_risorse {
		set fu [lindex $elem 0]
		set var [get_attribute $fu area]
		set quantity [lindex $elem 1]
		set area [expr {$var*$quantity+$area}]
	}
	if ($area<=$max){
		set bolean 1
	}
	return bolean 
}


proc main { }
	prima_analisi
	set lista_da_incrementare [list]
