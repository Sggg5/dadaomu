extends "res://tests/phase_5b_smoke.gd"
func run()->void:
	var state:=MuseumState.new()
	state.museum_level=2
	state.cash=1000000
	var before:=state.cash
	var spent:=0
	var catalog:=MuseumConstructionService.definitions(state)
	check(catalog.size()==47,"44 stable unit facilities and three public facilities")
	for id in catalog:
		for level in range(3):
			var request:=MuseumConstructionService.quote(state,id)
			spent+=request.price
			check(MuseumConstructionService.purchase(state,request) and state.facilities.level(id)==level+1,"Real atomic purchase "+str(id)+" level"+str(level+1))
			var paid:=state.cash
			check(not MuseumConstructionService.purchase(state,request) and state.cash==paid,"Same quoted request never pays twice")
		check(MuseumConstructionService.quote(state,id)==null,"Max level capped")
	check(state.cash==before-spent and state.facilities.expenses.size()==141,"Cash exactly matches unique upgrade ledger")
	var poor:=MuseumState.new()
	check(not MuseumConstructionService.purchase(poor,MuseumConstructionService.quote(poor,&"CASE_2:LIGHT")),"Insufficient funds denied")
	poor.cash=10000
	check(not MuseumConstructionService.purchase(poor,MuseumConstructionService.quote(poor,&"CASE_6:LIGHT")),"Locked western hall cannot buy")
	poor.phase=MuseumState.Phase.OPEN
	check(not MuseumConstructionService.purchase(poor,MuseumConstructionService.quote(poor,&"CASE_2:LIGHT")),"OPEN denies construction")
	poor.phase=MuseumState.Phase.MORNING
	var stale:=MuseumConstructionService.quote(poor,&"CASE_2:LIGHT")
	stale.price=1
	check(not MuseumConstructionService.purchase(poor,stale),"Forged quote cannot underpay")
	print("[11E1] %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
