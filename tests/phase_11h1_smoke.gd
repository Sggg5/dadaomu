extends "res://tests/phase_5b_smoke.gd"
func run()->void:
	var state:=MuseumState.new();var zero:=MuseumReputationService.evaluate(state)
	check(zero.score==0 and zero.rank==0,"Empty museum starts with zero reputation/private title")
	state.cash=100000;state.museum_level=2
	check(MuseumReputationService.evaluate(state).rank==0,"Cash and expanded building cannot purchase operating rank")
	for index in range(20):state.collection.add(&"ly_attendant",1,100,true)
	check(MuseumReputationService.evaluate(state).metrics.identified==1,"20 duplicates count as one definition")
	var score:=MuseumReputationService.evaluate(state).score
	check(MuseumReputationService.evaluate(state).score==score,"Read only evaluation cannot award points")
	for item in state.collection.all_items():state.collection.remove(item.instance_id)
	check(MuseumReputationService.evaluate(state).score==0,"Selling collection reduces current strength")
	print("[11H1] %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
