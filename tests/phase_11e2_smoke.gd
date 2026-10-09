extends "res://tests/phase_5b_smoke.gd"
func run()->void:
	var state:=preload("res://tests/fixtures/museum_management_fixture.gd").state_with_displays(50)
	state.cash=10000
	var placements:=state.display_assignments.duplicate()
	var original:=state.unit_appeal(&"CASE_2")
	check(MuseumConstructionService.unit_interest(state,&"CASE_2")==original and MuseumConstructionService.bonus_appeal(state)==0,"Level0 facilities preserve exact original appeal")
	for kind in [&"LIGHT",&"BASE",&"LABEL",&"PROTECT"]:
		for level in range(3):check(MuseumConstructionService.purchase(state,MuseumConstructionService.quote(state,StringName("CASE_2:"+str(kind)))),"Case actual upgrade "+str(kind)+str(level+1))
	check(state.display_assignments==placements and state.unit_items(&"CASE_2").size()==3,"Upgrade preserves actual instances and slot ownership")
	check(MuseumConstructionService.unit_interest(state,&"CASE_2")>original and MuseumConstructionService.unit_bonus(state,&"CASE_2")<=.18,"Finite upgraded case interest")
	check(MuseumConstructionService.bonus_appeal(state)<=floori(state.total_appeal()*.15),"Museum facility bonus capped15percent")
	var feedback:=VisitorViewResult.snapshot(state,&"CASE_2",{})
	check(feedback.feedback.contains("说明牌") and feedback.effective_appeal>original,"Completed-view projection reflects real label and interest")
	var museum:=Museum.new()
	museum.state=state;museum.config=MuseumConfig.new()
	root.add_child(museum)
	await frames(3)
	museum.facility_panel.open()
	var view:=museum.facility_panel.view
	var index:=view.ids.find(&"CASE_3:LIGHT")
	view.list.select(index);view.list.item_selected.emit(index)
	view.buy.pressed.emit()
	var cash:=state.cash
	view.buy.pressed.emit()
	check(state.facilities.level(&"CASE_3:LIGHT")==1 and state.cash==cash,"Same UI confirmation cannot purchase next level on repeated signal")
	view.next_quote.pressed.emit();view.buy.pressed.emit()
	check(state.facilities.level(&"CASE_3:LIGHT")==2,"Explicit next quote permits next real upgrade")
	museum.facility_panel.close()
	museum.queue_free();await frames(3)
	print("[11E2] %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
