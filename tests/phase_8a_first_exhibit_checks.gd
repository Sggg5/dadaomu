extends RefCounted
## 正式空馆→真实夜间E拾唯一古董/F撤离→Day2唯一展品/E开馆，不注入馆藏。
var test: SceneTree


func _init(context: SceneTree) -> void: test = context


func run() -> void:
	var flow := preload("res://scenes/main/game_flow.tscn").instantiate() as GameFlow
	var config := MuseumConfig.new()
	config.open_duration = 5
	config.visitor_speed = 1200
	config.view_duration = 2
	flow.museum_config = config
	test.root.add_child(flow)
	await test.frames(3)
	var state := flow.museum_state
	var daytime = preload("res://tests/phase_8a_flow_checks.gd").new(test,flow)
	test.check(not flow.initial_test_collection and flow.current_day == 1 and state.collection.all_items().is_empty() and state.display_assignments.is_empty() and flow.museum.cases.all(func(exhibit: DisplayCase) -> bool: return exhibit.state.definition_for(exhibit.case_id) == null) and state.cash == 0,"Official first Run begins Day1 with no gifted antique, three empty cases and zero cash")
	await daytime.walk_to(Vector2(1080,540))
	test.check(flow.museum.player.prompt_label.text == "暂无展品，无法开馆","Actual nearby ticket hint explains empty opening failure")
	test.key(KEY_E)
	await test.frames(180)
	var business := flow.museum.business
	test.check(flow.museum.message.text == "暂无展品，无法开馆" and flow.current_phase == MuseumState.Phase.MORNING and business.target == 0 and not business.running and business.active.is_empty() and business.spawned == 0,"Actual empty ticket E refuses OPEN and never generates visitors")
	test.check(state.cash == 0 and business.visitors_today == 0 and business.income_today == 0 and state.last_day_visitors == 0 and state.last_day_ticket_income == 0,"Failed empty ticket E cannot mutate cash or any business totals")
	test.capture("first_empty_ticket")
	await daytime.night()
	test.check(flow.current_day == 1 and state.collection.all_items().is_empty(),"Empty official Day1 can directly go down without opening")
	var run_driver = preload("res://tests/phase_7b_run_driver.gd").new(test)
	var world: RoomController = test.session.world
	var offers := preload("res://tests/phase_7b_plan_checks.gd").offers(test.session.run_seed,1,world.layout)
	var offer: Dictionary
	for candidate in offers:
		if candidate.source == &"antique_room": offer = candidate; break
	await run_driver.driver.visit(offer.room)
	await run_driver.take_current(offer)
	test.check(world.player.antiques.items().size() == 1 and run_driver.cache_pickups == 0,"Real antique-room E picks exactly one official antique")
	await run_driver.defeat_warlord()
	test.check(world.player.antiques.items().size() == 1,"Boss route never injects extra antiques")
	var exit := world.current_room.get_node("ExpeditionExit") as ExpeditionExit
	world.player.position = exit.position+Vector2(24,0)
	test.key(KEY_F)
	await test.frames(3)
	var result: RunResult = test.session.complete_screen.result
	test.check(result.outcome == RunResult.Outcome.EXTRACTED and result.antique_ids.size() == 1,"Actual weapon Boss victory/F extraction safely snapshots exactly one antique")
	test.key(KEY_E)
	await test.frames(5)
	test.check(flow.current_day == 2 and state.collection.all_items().size() == 1 and state.collection.all_items()[0].definition_id == result.antique_ids[0] and state.collection.all_items()[0].acquired_day == 1 and state.cash == 0,"Day2 contains the first real OwnedAntique, correct day and no gift/cash conversion")
	var first := state.collection.all_items()[0]
	await daytime.place(1,first.instance_id)
	test.check(state.display_assignments.size() == 1 and flow.museum.business.can_open(),"Unique first owned antique alone qualifies for first exhibition")
	test.capture("first_real_exhibit")
	await daytime.open_and_close(true)
	test.check(flow.museum.business.target == flow.museum.business.visitor_target(state.total_appeal(),1) and state.last_day_visitors > 0 and state.last_day_ticket_income == state.last_day_visitors*5 and state.cash == state.last_day_ticket_income and flow.current_day == 2,"One real exhibit produces visitor viewing/tickets, closes to EVENING without day advance")
	print("[First exhibit] Seed=%d antique=%s target=%d visitors=%d income=%d" % [result.run_seed,first.definition_id,flow.museum.business.target,state.last_day_visitors,state.last_day_ticket_income])
	test.capture("first_exhibition_income")
	flow.queue_free()
	await test.frames(3)
