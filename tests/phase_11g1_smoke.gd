extends "res://tests/phase_5b_smoke.gd"
func run()->void:
	var state:=MuseumState.new()
	var a:=state.collection.add(&"ly_attendant",1,60,true)
	var b:=state.collection.add(&"ly_attendant",1,80,true)
	check(a.instance_id!=b.instance_id and state.collection.archives.size()==2,"Same definition owns independent dossiers")
	state.collection.archives[a.instance_id].record(1,"TEST","QA")
	check(state.collection.archives[b.instance_id].events.is_empty(),"Histories never overwrite another accession")
	check(state.collection.archives[a.instance_id].source.is_empty(),"Missing discovery stays unknown")
	state.collection.remove(a.instance_id)
	check(state.collection.archives.has(a.instance_id) and not state.collection.contains(a.instance_id),"Removed artifact retains unowned archive")
	print("[11G1] %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
