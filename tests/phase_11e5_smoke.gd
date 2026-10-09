extends "res://tests/phase_11a_smoke.gd"
func run()->void:
	flow=preload("res://scenes/main/game_flow.tscn").instantiate()
	flow.profile_store=MuseumProfileStore.in_memory()
	var state:=preload("res://tests/fixtures/museum_management_fixture.gd").state_with_displays(50)
	state.cash=0
	flow.profile_store._memory=flow.profile_store.encode(state)
	flow.museum_config=MuseumConfig.new();flow.museum_config.open_duration=8;flow.museum_config.visitor_speed=1000;flow.museum_config.view_duration=.05
	root.add_child(flow);await frames(3)
	state=flow.museum_state
	var driver=preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
	await driver.walk_to(Vector2(1080,540));key(KEY_E);await frames(700)
	check(state.cash==state.daily_reports[1].ticket_income and state.cash>=80,"Real ticket earnings from zero cash fund facility investment")
	await driver.walk_to(Vector2(340,450));await driver.walk_to(Vector2(340,230));await driver.walk_to(flow.museum.construction.position+Vector2(0,40))
	key(KEY_E);await frames(3)
	check(flow.museum.construction_panel.panel.visible,"Actual building E opens existing hall construction")
	var facility_button:=flow.museum.construction_panel.panel.get_child(1) as Button
	await click(facility_button.get_global_rect().get_center());await frames(3)
	var view:=flow.museum.facility_panel.view
	check(flow.museum.facility_panel.panel.visible,"Actual building button opens facility blueprint")
	var index:=view.ids.find(&"CASE_2:LIGHT")
	await click(view.list.get_global_rect().position+view.list.get_item_rect(index).get_center())
	var cash:=state.cash
	await click(view.buy.get_global_rect().get_center());await frames(3)
	check(state.facilities.level(&"CASE_2:LIGHT")==1 and state.cash==cash-80,"Actual blueprint mouse purchase spends earned ticket cash exactly once")
	var restored:=flow.profile_store.load_profile()
	check(not flow.profile_store.write_blocked and restored.facilities.level(&"CASE_2:LIGHT")==1 and restored.cash==state.cash,"GameFlow safely persists purchased facility and earned cash")
	check(MuseumConstructionService.unit_interest(state,&"CASE_2")>state.unit_appeal(&"CASE_2"),"Investment measurably improves exhibited artifact interest")
	flow.queue_free();flow=null;driver=null;await frames(5)
	print("[11E5] %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
