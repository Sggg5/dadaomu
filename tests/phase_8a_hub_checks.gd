extends RefCounted
## 结果转移与空馆营业边界；完整战斗流程另由flow_checks驾驶。
var test: SceneTree


func _init(context: SceneTree) -> void: test = context


func run() -> void:
	var flow := preload("res://scenes/main/game_flow.tscn").instantiate() as GameFlow
	test.check(not flow.initial_test_collection,"Official entry defaults to no test collection")
	var config := MuseumConfig.new()
	config.open_duration = 2
	config.visitor_speed = 1200
	flow.museum_config = config
	test.root.add_child(flow)
	await test.frames(3)
	test.check(flow.museum_state.collection.all_items().is_empty() and flow.museum_state.display_assignments.is_empty() and flow.museum_state.cash == 0,"Unmodified official entry begins with empty collection/displays/zero cash")
	test.check(not flow.museum.message.text.contains("唐三彩马"),"Official morning notice does not advertise gifted test antique")
	var business := flow.museum.business
	test.check(business.active.is_empty() and business.spawned == 0,"Empty morning never generates visitors")
	test.check(not business.can_open() and not business.start(),"Empty exhibition cannot open even through direct Business.start")
	await test.frames(180)
	test.check(flow.current_phase == MuseumState.Phase.MORNING and business.target == 0 and not business.running and business.spawned == 0 and business.active.is_empty(),"Rejected empty opening leaves MORNING/zero target/no visitors")
	test.check(business.visitors_today == 0 and business.income_today == 0 and flow.museum_state.cash == 0 and flow.museum_state.last_day_visitors == 0 and flow.museum_state.last_day_ticket_income == 0,"Empty exhibition earns no ticket income and preserves all cash/day statistics")
	test.check(flow.museum.ticket.prompt.call() == "暂无展品，无法开馆","Empty ticket prompt explains exhibit requirement")
	flow.museum_state.last_day_visitors = 9
	flow.museum_state.last_day_ticket_income = 45
	test.check(not business.start() and flow.museum_state.last_day_visitors == 9 and flow.museum_state.last_day_ticket_income == 45,"Rejected opening also preserves nonzero previous-day totals")
	var cash_before := flow.museum_state.cash
	flow.start_night()
	await test.frames(5)
	var session := flow.dungeon
	var state := flow.museum_state
	var fake := RunResult.new()
	test.check(not flow.return_from_night(fake),"Hub refuses foreign result before its night ends")
	# 单项COMPLETED转移验证可直接装库存/结束；真实两Boss战斗覆盖保留在7B。
	session.world.player.antiques.add(MuseumState.POOL.find_by_id(&"gold_thread_jade"))
	session.world.player.antiques.add(MuseumState.POOL.find_by_id(&"gold_thread_jade"))
	session._finish_run(RunResult.Outcome.COMPLETED)
	test.check(flow.current_dungeon_result == session.complete_screen.result and state.collection.all_items().is_empty(),"Result-ready reports snapshot but does not silently import before return")
	test.key(KEY_R)
	await test.frames(5)
	test.check(flow.current_day == 1 and flow.current_dungeon_result == null and state.collection.all_items().is_empty(),"Hub R retries ended night, clears stale result and never increments/imports")
	session.world.player.antiques.add(MuseumState.POOL.find_by_id(&"gold_thread_jade"))
	session.world.player.antiques.add(MuseumState.POOL.find_by_id(&"gold_thread_jade"))
	session._finish_run(RunResult.Outcome.COMPLETED)
	var result := session.complete_screen.result
	test.check(result.antique_ids == [&"gold_thread_jade",&"gold_thread_jade"],"COMPLETED preserves duplicate stable ID snapshots")
	session._return_to_hub()
	session._return_to_hub()
	await test.frames(5)
	var items := state.collection.all_items()
	test.check(items.size() == 2 and items[0].instance_id != items[1].instance_id and items[0].acquired_day == 1 and flow.current_day == 2,"COMPLETED return creates two independent owned antiques exactly once")
	test.check(state.cash == cash_before and state.collection is MuseumCollection,"Night cargo creates collection only, never converted to ticket cash")
	test.check(not flow.return_from_night(result),"Duplicate old result cannot advance morning or import again")
	state.assign(&"CASE_1",items[0].instance_id)
	state.assign(&"CASE_2",items[1].instance_id)
	state.phase = MuseumState.Phase.OPEN
	flow.museum.player.position = flow.museum.cases[0].position+Vector2(0,50)
	await test.frames(3)
	test.key(KEY_E)
	await test.frames(1)
	test.check(flow.museum.collection_panel.panel.visible and not flow.museum.collection_panel.panel.get_node("VBoxContainer/Choose").visible,"Open-stage exhibit E is read-only UI with no assign button")
	test.key(KEY_TAB)
	await test.frames(2)
	test.key(KEY_R)
	test.check(state.display_assignments.size() == 2 and flow.museum.message.text.contains("营业中不能调整"),"Real R cannot withdraw during OPEN")
	state.phase = MuseumState.Phase.EVENING
	test.key(KEY_R)
	test.check(state.display_assignments.size() == 1 and state.collection.all_items().size() == 2,"Real withdrawal after closing leaves collection intact")
	flow.queue_free()
	await test.frames(3)
