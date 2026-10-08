extends RefCounted
## 真实门票攒到1000后通过建设牌E升级；不向主经营流程注入现金或馆藏。
var test: SceneTree
var flow: GameFlow
var daytime: RefCounted
var path: String
var config: MuseumConfig


func _init(context: SceneTree) -> void: test = context


func create_flow() -> void:
	flow = preload("res://scenes/main/game_flow.tscn").instantiate() as GameFlow
	flow.progressive_relics = false
	flow.tomb = preload("res://tests/fixtures/legacy_two_floor_tomb.tres")
	# 旧功能固定Run夹具；正式派生Seed由9A专项另外覆盖。
	flow.forced_night_seed = 192034
	flow.campaign_seed_override = 52
	# 历史回归使用原主图夹具；Phase9A单独覆盖正式探索入口。
	flow.tomb_exploration_enabled = false
	flow.profile_store = MuseumProfileStore.new()
	flow.profile_store.save_path = path
	flow.museum_config = config
	test.root.add_child(flow)
	test.current_scene = flow
	await test.frames(3)
	daytime = preload("res://tests/phase_8a_flow_checks.gd").new(test,flow)


func night() -> void:
	# 升级后东侧展柜占据旧直线路径，沿中间通道绕行到情报板。
	await daytime.walk_to(Vector2(940,450))
	await daytime.walk_to(Vector2(940,210))
	await daytime.walk_to(flow.museum.board.position+Vector2(-40,20))
	var before := flow.profile_store.save_count
	test.key(KEY_E)
	await test.frames(5)
	test.session = flow.dungeon
	test.check(flow.current_phase == MuseumState.Phase.NIGHT and flow.profile_store.save_count > before,"Actual board E saves ground before entering unchanged Dungeon")


func next_business_day() -> void:
	await night()
	# 经营日历辅助：中间空背包夜晚直接死亡边界，不靠这条路径赚现金/古董。
	test.session.world.player.health.take_damage(1000)
	await test.frames(2)
	test.key(KEY_E)
	await test.frames(5)
	daytime = preload("res://tests/phase_8a_flow_checks.gd").new(test,flow)


func construction() -> void:
	await daytime.walk_to(Vector2(940,450))
	await daytime.walk_to(Vector2(940,210))
	await daytime.walk_to(flow.museum.construction.position+Vector2(40,0))
	test.key(KEY_E)
	await test.frames(2)
	test.check(flow.museum.construction_panel.panel.visible,"Actual construction sign E opens expansion choice")


func place_new_case(item: OwnedAntique) -> void:
	if not item.identified: await daytime.appraise(item.instance_id)
	await daytime.walk_to(flow.museum.hall_guide.position+Vector2(0,40))
	test.key(KEY_E)
	await test.frames(2)
	var hall_panel:=flow.museum.hall_panel
	hall_panel.list.select(hall_panel.ids.find(&"EAST"))
	hall_panel.panel.get_child(0).get_child(2).pressed.emit()
	await test.frames(3)
	var view:DisplayCase
	for candidate in flow.museum.cases:
		if candidate.case_id==&"CASE_4":view=candidate
	await daytime.walk_to(Vector2(view.position.x,450))
	await daytime.walk_to(view.position+Vector2(0,48))
	test.key(KEY_E)
	await test.frames(1)
	var panel := flow.museum.collection_panel
	var index := flow.museum_state.collection.all_items().find(item)
	panel.list.select(index)
	panel.panel.get_node("VBoxContainer/Choose").pressed.emit()
	await test.frames(3)
	test.check(flow.museum_state.display_assignments.get(&"CASE_4") == item.instance_id and view.label.text.contains(MuseumState.POOL.find_by_id(item.definition_id).display_name),"Actual new case4 E/UI displays remaining real night loot")


func run() -> void:
	path = preload("res://tests/phase_8b_profile_checks.gd").temporary_path("progression")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	config = MuseumConfig.new()
	config.open_duration = 20
	config.visitor_speed = 1800
	config.view_duration = .1
	await create_flow()
	var state := flow.museum_state
	test.check(state.cash == 0 and state.museum_level == 0 and flow.museum.cases.size() == 3 and state.collection.all_items().is_empty(),"Official disk-profile progression starts empty Level0 without donated antiques/cash")
	test.capture("level0_locked_wings")
	await construction()
	test.key(KEY_E)
	test.key(KEY_E)
	test.check(flow.museum.construction_panel.label.text.contains("资金不足") and state.cash == 0 and state.museum_level == 0,"Actual construction E at0 cash reports insufficient money without side effects")
	test.capture("insufficient_upgrade")
	test.key(KEY_TAB)
	await test.frames(2)
	await night()
	var run_driver = preload("res://tests/phase_7b_run_driver.gd").new(test)
	await run_driver.collect_floor()
	await run_driver.defeat_warlord()
	var exit := test.session.world.current_room.get_node("ExpeditionExit") as ExpeditionExit
	test.session.world.player.position = exit.position+Vector2(24,0)
	test.key(KEY_F)
	await test.frames(3)
	test.key(KEY_E)
	await test.frames(5)
	daytime = preload("res://tests/phase_8a_flow_checks.gd").new(test,flow)
	var held := state.collection.all_items()
	test.check(held.size() == 4 and state.cash == 0 and state.day_number == 2,"Actual weapon/loot/F Run contributes4 owned antiques but no economic cash")
	var exhibits: Array[OwnedAntique] = []
	for item in held:
		if item.definition_id == &"tang_sancai_horse" or item.definition_id == &"gold_thread_jade": exhibits.append(item)
	for index in range(3): await daytime.place(index,exhibits[index].instance_id)
	var total_income: int = 0
	var business_days: int = 0
	while state.cash < MuseumState.LEVELS.at(0).upgrade_cost and business_days < 8:
		await daytime.open_and_close(false)
		total_income += state.last_day_ticket_income
		business_days += 1
		test.check(state.cash == total_income and state.last_day_visitors == 30 and state.last_day_ticket_income == 150,"Every upgrade yuan comes from30 real ticket-paying visitors at day%d" % state.day_number)
		var saved_business := flow.profile_store.load_profile()
		test.check(saved_business.cash == state.cash and saved_business.phase == MuseumState.Phase.EVENING,"Closing automatically persists each day's ticket income")
		if state.cash < MuseumState.LEVELS.at(0).upgrade_cost: await next_business_day()
	test.check(state.cash >= 1000 and business_days == 7 and total_income == 1050,"Seven actual business days generate1050, no cash injection")
	var old_collection := state.collection
	var old_ids := held.map(func(item: OwnedAntique) -> StringName: return item.instance_id)
	var assignments := state.display_assignments.duplicate()
	var old_cases := flow.museum.cases.map(func(exhibit: DisplayCase) -> int: return exhibit.get_instance_id())
	await construction()
	var before := state.cash
	test.key(KEY_E)
	test.key(KEY_E)
	test.key(KEY_E)
	await test.frames(3)
	test.check(state.museum_level == 1 and state.cash == before-1000 and state.collection == old_collection and state.display_assignments == assignments,"Real construction E atomically buys Level1 and rapid repeats preserve original owned exhibits")
	test.check(flow.museum.cases.size() == 3 and state.case_ids().size()==5 and flow.museum.cases.slice(0,3).map(func(exhibit: DisplayCase) -> int: return exhibit.get_instance_id()) == old_cases and state.total_appeal()==77 and flow.museum.business.visitor_target(state.total_appeal(),3) == 31,"Model unlocks east CASE4/5 while MAIN node count remains3; appeal target respects upgraded capacity")
	test.capture("level1_unlocked")
	var saved_upgrade := flow.profile_store.load_profile()
	test.check(saved_upgrade.museum_level == 1 and saved_upgrade.cash == state.cash,"Upgrade is persisted immediately before any later display change")
	test.key(KEY_TAB)
	await test.frames(2)
	var stored: OwnedAntique
	for item in held:
		if state.case_for(item.instance_id) == &"": stored = item; break
	await place_new_case(stored)
	var expected := flow.profile_store.encode(state)
	flow.queue_free()
	await test.frames(4)
	await create_flow()
	state = flow.museum_state
	test.check(flow.profile_store.encode(state) == expected and flow.museum.cases.size() == 3 and state.case_ids().size()==5 and state.phase == MuseumState.Phase.EVENING,"New GameFlow automatically reloads date/cash/Level1/owned IDs/all assignments and closed phase")
	test.check(not flow.museum.business.start(),"Reloading finished business does not allow another same-day opening")
	var next := state.collection.add(&"republic_silver_coin",state.day_number)
	test.check(next.instance_id not in old_ids and next.instance_id == &"A000005","Post-restart collection boundary continues unique next ID")
	state.collection.remove(next.instance_id)
	await night()
	var ground := flow.profile_store.encode(flow.profile_store.load_profile())
	flow.queue_free()
	await test.frames(4)
	await create_flow()
	test.check(flow.dungeon == null and flow.profile_store.encode(flow.museum_state) == ground,"Quitting mid-Night restores latest saved ground, not an unfinished Run")
	await night()
	run_driver = preload("res://tests/phase_7b_run_driver.gd").new(test)
	await run_driver.collect_floor()
	test.check(not test.session.world.player.antiques.items().is_empty(),"Death persistence route really carries night antiques")
	await run_driver.die_to_enemy()
	await test.frames(3)
	var result: RunResult = test.session.complete_screen.result
	test.key(KEY_E)
	await test.frames(5)
	state = flow.museum_state
	test.check(result.outcome == RunResult.Outcome.DEAD and state.cash == ground.cash and state.museum_level == 1 and flow.profile_store.encode(state).display_assignments == expected.display_assignments and state.collection.all_items().size() == held.size(),"Real enemy fatal loss does not alter owned collection/Level1/cash/display")
	var death_snapshot := flow.profile_store.encode(state)
	test.capture("death_preserves_museum")
	flow.queue_free()
	await test.frames(4)
	await create_flow()
	test.check(flow.profile_store.encode(flow.museum_state) == death_snapshot and flow.current_phase == MuseumState.Phase.MORNING,"Death return autosaves and new GameFlow reloads preserved next morning exactly")
	print("[Progression] ticket_days=%d earned=%d level=%d cash=%d owned=%d" % [business_days,total_income,flow.museum_state.museum_level,flow.museum_state.cash,flow.museum_state.collection.all_items().size()])
	flow.queue_free()
	await test.frames(3)
