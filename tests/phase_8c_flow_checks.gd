extends "res://tests/phase_8b_progression_checks.gd"
## 主流程所有藏品来自真实夜间E拾取，修复现金全部来自实际游客门票。


func work_at(point: MuseumInteractable) -> void:
	await daytime.walk_to(Vector2(920,450))
	await daytime.walk_to(Vector2(920,230))
	await daytime.walk_to(point.position+Vector2(0,40))
	test.key(KEY_E)
	await test.frames(2)


func run() -> void:
	path = "user://tests/phase_8c/%d_flow.json" % OS.get_process_id()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	config = MuseumConfig.new()
	config.open_duration = 20
	config.visitor_speed = 1800
	config.view_duration = 1
	await create_flow()
	var state := flow.museum_state
	test.check(state.day_number == 1 and state.collection.all_items().is_empty() and state.cash == 0,"Official8C Day1 starts empty with zero cash")
	await daytime.walk_to(Vector2(1080,540))
	test.key(KEY_E)
	await test.frames(2)
	test.check(flow.museum.message.text.contains("暂无展品") and flow.current_phase == MuseumState.Phase.MORNING,"Empty Day1 ticket E explains blocked business")
	await night()
	var run_driver = preload("res://tests/phase_7b_run_driver.gd").new(test)
	var offers := preload("res://tests/phase_7b_plan_checks.gd").offers(test.session.run_seed,1,test.session.world.layout)
	var offer: Dictionary
	for candidate in offers:
		if candidate.source == &"antique_room": offer = candidate; break
	await run_driver.driver.visit(offer.room)
	await run_driver.take_current(offer)
	await run_driver.defeat_warlord()
	var exit := test.session.world.current_room.get_node("ExpeditionExit") as ExpeditionExit
	test.session.world.player.position = exit.position+Vector2(24,0)
	test.key(KEY_F)
	await test.frames(3)
	var result: RunResult = test.session.complete_screen.result
	test.check(result.outcome == RunResult.Outcome.EXTRACTED and result.antique_ids.size() == 1 and result.antique_conditions.size() == 1 and result.antique_conditions[0] == AntiqueCondition.generate(result.run_seed,result.antique_ids[0],0,1),"Real weapon/Boss/F extraction snapshots one stable condition before museum return")
	test.key(KEY_E)
	await test.frames(5)
	var item := state.collection.all_items()[0]
	test.check(state.day_number == 2 and item.definition_id == &"tang_sancai_horse" and not item.identified and item.condition == result.antique_conditions[0] and item.condition >= 55 and item.condition <= 90,"Day2 first real horse arrives unidentified with exact RunResult condition")
	await daytime.walk_to(Vector2(220,500))
	test.key(KEY_E)
	await test.frames(2)
	var collection_panel := flow.museum.collection_panel
	test.check(collection_panel.panel.visible and collection_panel.list.get_item_text(0).contains("待正式鉴定") and not collection_panel.list.get_item_text(0).contains("品相"),"Actual warehouse displays waiting registration without exact condition")
	test.capture("waiting_storage")
	test.key(KEY_TAB)
	await daytime.walk_to(Vector2(640,380))
	await daytime.walk_to(Vector2(640,348))
	test.key(KEY_E)
	await test.frames(1)
	collection_panel.list.select(0)
	collection_panel.panel.get_node("VBoxContainer/Choose").pressed.emit()
	test.check(collection_panel.heading.text == "该古董尚未鉴定" and state.display_assignments.is_empty() and not state.assign(&"CASE_2",item.instance_id),"Actual case UI and direct data-layer both refuse unidentified exhibit")
	test.key(KEY_TAB)
	await daytime.appraise(item.instance_id)
	var saved := flow.profile_store.load_profile().collection.find(item.instance_id)
	test.check(state.cash == 0 and saved.identified and saved.condition == item.condition,"Real free E appraisal persists exact snapshot immediately with0 cash")
	await daytime.place(1,item.instance_id)
	var exhibit := flow.museum.cases[1]
	var base := MuseumState.POOL.find_by_id(item.definition_id).exhibit_appeal
	var initial_appeal := state.total_appeal()
	var initial_target := flow.museum.business.visitor_target(initial_appeal,1)
	var cost := state.restoration_cost(item.instance_id)
	test.check(initial_appeal == maxi(1,roundi(base*item.condition/100.0)) and exhibit.label.text.contains("品相%d" % item.condition) and flow.museum.business.can_open(),"Single appraised imperfect exhibit can open without mandatory repair")
	test.capture("imperfect_exhibit")
	await work_at(flow.museum.restoration)
	var repair_panel := flow.museum.restoration_panel
	test.check(repair_panel.panel.visible and repair_panel._ids == [item.instance_id],"Actual repair station E lists only identified damaged antiques")
	var before := item.condition
	test.key(KEY_E)
	test.check(repair_panel.label.text == "资金不足" and state.cash == 0 and item.condition == before,"Actual0 cash repair fails atomically")
	test.capture("insufficient_repair")
	test.key(KEY_TAB)
	var earned: int = 0
	var days: int = 0
	while state.cash < cost and days < 6:
		await daytime.walk_to(Vector2(920,230))
		await daytime.walk_to(Vector2(920,450))
		await daytime.open_and_close(days == 0)
		earned += state.last_day_ticket_income
		days += 1
		test.check(state.cash == earned and state.last_day_ticket_income == state.last_day_visitors*5 and flow.museum.business.target == initial_target,"Real visitors earn repair funds at unchanged imperfect appeal day%d" % days)
		if state.cash < cost: await next_business_day()
	test.check(state.cash >= cost and earned > 0,"Repair cash entirely earned through actual exhibition, no injection")
	await work_at(flow.museum.restoration)
	var cash_before := state.cash
	var original_assignment := state.display_assignments.duplicate()
	var old_case := flow.museum.cases[1].get_instance_id()
	test.key(KEY_E)
	test.key(KEY_E)
	test.key(KEY_E)
	await test.frames(2)
	test.check(item.condition == 100 and state.cash == cash_before-cost and state.display_assignments == original_assignment and state.total_appeal() == base,"Real repair E spends exactly cost once, updates existing exhibit without reassignment")
	test.check(flow.museum.cases[1].label.text.contains("品相100") and flow.museum.cases[1].label.text.contains("吸引力50"),"Scene display refreshes immediately after repair")
	test.check(flow.museum.cases[1].get_instance_id() == old_case,"Repair retains current display node")
	test.capture("repair_complete")
	saved = flow.profile_store.load_profile().collection.find(item.instance_id)
	test.check(saved.identified and saved.condition == 100 and flow.profile_store.load_profile().cash == state.cash,"Repair autosaves complete transaction")
	test.key(KEY_TAB)
	await work_at(flow.museum.restoration)
	test.check(flow.museum.restoration_panel._ids.is_empty() and not flow.museum.restoration_panel.confirm() and state.cash == cash_before-cost,"Full condition removed from repair list, cannot charge again")
	test.key(KEY_TAB)
	await next_business_day()
	await daytime.open_and_close(false)
	test.check(flow.museum.business.target == flow.museum.business.visitor_target(base,1) and flow.museum.business.target > initial_target,"Next actual business uses repaired appeal and higher visitor target")
	var expected := flow.profile_store.encode(state)
	flow.queue_free()
	await test.frames(4)
	await create_flow()
	test.check(flow.profile_store.encode(flow.museum_state) == expected,"Actual restart retains repaired/appraised owned item and cash/exhibit state")
	print("[8C flow] condition=%d appeal=%d→%d target=%d→%d repair=%d earned=%d ticket_days=%d" % [before,initial_appeal,base,initial_target,flow.museum.business.visitor_target(base,1),cost,earned,days])
	flow.queue_free()
	await test.frames(3)
