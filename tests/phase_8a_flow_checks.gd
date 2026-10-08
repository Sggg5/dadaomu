extends RefCounted
## 白天全流程通过实际WASD/E和UI按钮；夜间复用真实武器/敌人/门驾驶。
var test: SceneTree
var flow: GameFlow


func _init(context: SceneTree, game: GameFlow) -> void:
	test = context
	flow = game


func walk_to(target: Vector2) -> void:
	var player := flow.museum.player
	for frame in range(600):
		var difference := target-player.position
		for action in [&"move_up",&"move_right",&"move_down",&"move_left"]: Input.action_release(action)
		if difference.length() <= 4: break
		if absf(difference.x) > 2: Input.action_press("move_right" if difference.x > 0 else "move_left", minf(1,maxf(.25,absf(difference.x)/80)))
		if absf(difference.y) > 2: Input.action_press("move_down" if difference.y > 0 else "move_up", minf(1,maxf(.25,absf(difference.y)/80)))
		await test.frames(1)
	for action in [&"move_up",&"move_right",&"move_down",&"move_left"]: Input.action_release(action)
	await test.frames(5)
	test.check(player.position.distance_to(target) < 24,"Actual WASD reaches museum point "+str(target))


func place(case_index: int, owned_id: StringName) -> void:
	if not flow.museum_state.collection.find(owned_id).identified: await appraise(owned_id)
	var museum := flow.museum
	await walk_to(Vector2(museum.cases[case_index].position.x,380))
	await walk_to(museum.cases[case_index].position+Vector2(0,48))
	test.key(KEY_E)
	await test.frames(1)
	test.check(museum.collection_panel.panel.visible,"Actual E opens display collection choice")
	var index: int = 0
	for item in flow.museum_state.collection.all_items():
		if item.instance_id == owned_id: break
		index += 1
	museum.collection_panel.list.select(index)
	museum.collection_panel.panel.get_node("VBoxContainer/Choose").pressed.emit()
	await test.frames(2)
	test.check(flow.museum_state.display_assignments.get(museum.cases[case_index].case_id) == owned_id and museum.cases[case_index].label.text.contains(MuseumState.POOL.find_by_id(flow.museum_state.collection.find(owned_id).definition_id).display_name),"UI choice updates actual scene exhibit and instance assignment")


func appraise(owned_id: StringName) -> void:
	var museum := flow.museum
	await walk_to(Vector2(920,450))
	await walk_to(Vector2(920,230))
	await walk_to(museum.appraisal.position+Vector2(0,40))
	test.key(KEY_E)
	await test.frames(2)
	var index := museum.appraisal_panel._ids.find(owned_id)
	test.check(museum.appraisal_panel.panel.visible and index >= 0,"Actual appraisal station E lists unidentified owned instance")
	if index >= 0: museum.appraisal_panel.list.select(index)
	test.key(KEY_E)
	await test.frames(2)
	test.check(flow.museum_state.collection.find(owned_id).identified and museum.appraisal_panel.label.text.contains("鉴定完成"),"Actual appraisal confirmation E registers antique for exhibition")
	test.capture("appraisal_result")
	test.key(KEY_TAB)
	await test.frames(2)
	await walk_to(Vector2(920,230))
	await walk_to(Vector2(920,380))


func open_and_close(interact_visitor: bool) -> void:
	var museum := flow.museum
	var before_day := flow.current_day
	await walk_to(Vector2(1080,540))
	test.key(KEY_E)
	await test.frames(3)
	test.check(flow.current_phase == MuseumState.Phase.OPEN and flow.current_day == before_day,"Actual ticket E opens without advancing day")
	var reached_view: bool = false
	var peak: int = 0
	if interact_visitor:
		for frame in range(250):
			peak = maxi(peak,museum.business.active.size())
			var chosen: MuseumVisitor
			for visitor in museum.business.active:
				if visitor.activity == MuseumVisitor.Activity.VIEW and visitor.visible:
					chosen = visitor
					break
			if chosen != null:
				reached_view = true
				await walk_to(chosen.position+Vector2(25,0))
				await test.frames(2)
				if museum.player.focused is MuseumVisitor:
					test.key(KEY_E)
					test.check(museum.message.text.contains("“"),"Actual E visitor conversation displays exhibit reaction")
				break
			await test.frames(1)
			if frame == 0: test.check(flow.current_phase == MuseumState.Phase.OPEN,"Open remains active until compressed duration")
		test.check(reached_view,"At least one visitor physically reaches and views exhibit")
		test.capture("visitor_view")
	var paid_visitor: MuseumVisitor
	for visitor in museum.business.active:
		if visitor.ticket_paid: paid_visitor = visitor; break
	if paid_visitor != null:
		var before := flow.museum_state.cash
		paid_visitor.pay_ticket()
		museum.business._on_paid(paid_visitor.visitor_index)
		test.check(flow.museum_state.cash == before,"Paid visitor cannot charge twice even with repeat boundary notification")
	for frame in range(1200):
		peak = maxi(peak,museum.business.active.size())
		if flow.current_phase == MuseumState.Phase.EVENING: break
		await test.frames(1)
	test.check(peak <= 8 and flow.current_phase == MuseumState.Phase.EVENING and museum.business.active.is_empty(),"Business caps active visitors and drains them before evening")
	var spawned := museum.business.spawned
	await test.frames(30)
	test.check(museum.business.spawned == spawned and flow.museum_state.last_day_ticket_income == flow.museum_state.last_day_visitors*5 and flow.museum_state.cash > 0,"Closing stops arrivals, exact once ticket income recorded")
	test.capture("evening")


func night() -> void:
	await walk_to(Vector2(1000,450))
	await walk_to(flow.museum.board.position+Vector2(-40,20))
	test.key(KEY_E)
	await test.frames(5)
	test.session = flow.dungeon
	test.session.child_entered_tree.connect(test.watch)
	test.check(flow.current_phase == MuseumState.Phase.NIGHT and flow.museum == null and test.session.hub_mode,"Board E loads existing DungeonSession in hub mode")


func run() -> void:
	var state := flow.museum_state
	test.check(flow.current_day == 1 and flow.current_phase == MuseumState.Phase.MORNING and flow.museum.cases.size() == 3 and flow.museum.business.active.is_empty(),"Day1 morning has3 cases/no visitors")
	test.check(flow.museum.player.get_node_or_null("Weapon") == null and flow.museum.player.get_node_or_null("Relics") == null,"MuseumPlayer has no combat weapon or relic runtime")
	var initial := state.collection.all_items()[0]
	await place(0,initial.instance_id)
	test.capture("morning_exhibit")
	await open_and_close(true)
	await night()
	var run_driver = preload("res://tests/phase_7b_run_driver.gd").new(test)
	await run_driver.collect_floor()
	await run_driver.defeat_warlord()
	var exit := test.session.world.current_room.get_node("ExpeditionExit") as ExpeditionExit
	test.session.world.player.position = exit.position+Vector2(24,0)
	test.key(KEY_F)
	await test.frames(3)
	var result: RunResult = test.session.complete_screen.result
	test.check(result.antique_ids.size() == result.antique_names.size() and result.outcome == RunResult.Outcome.EXTRACTED,"Actual extraction snapshots stable IDs matching cargo")
	test.capture("hub_extracted")
	var before_collection := state.collection.all_items().size()
	test.key(KEY_E)
	test.key(KEY_E)
	await test.frames(5)
	test.check(flow.current_day == 2 and flow.current_phase == MuseumState.Phase.MORNING and state.collection.all_items().size() == before_collection+result.antique_ids.size(),"Return E imports successful loot once and increments only next morning")
	test.check(state.collection.all_items().back().acquired_day == 1 and state.display_assignments[&"CASE_1"] == initial.instance_id,"Acquired night day recorded; existing exhibit preserved")
	await walk_to(Vector2(250,500))
	await walk_to(flow.museum.storage.position+Vector2(40,0))
	test.key(KEY_E)
	await test.frames(1)
	test.check(flow.museum.collection_panel.list.item_count == state.collection.all_items().size() and flow.museum.message.text.contains("昨夜新入藏"),"Day2 warehouse really shows all new owned instances with obvious arrival notice")
	test.capture("day2_storage")
	test.key(KEY_TAB)
	await test.frames(1)
	var new_item: OwnedAntique = state.collection.all_items().back()
	await place(0,new_item.instance_id)
	test.check(state.case_for(initial.instance_id) == &"" and state.case_for(new_item.instance_id) == &"CASE_1","Player personally replaces initial display with last night's loot")
	test.capture("day2_new_exhibit")
	await open_and_close(false)
	var cash_before_death := state.cash
	var collection_before_death := state.collection.all_items().size()
	await night()
	# R重试夜间不加日期、不重复转移馆藏。
	test.key(KEY_R)
	await test.frames(5)
	test.check(flow.current_day == 2 and state.collection.all_items().size() == collection_before_death,"Night R retry never advances museum day or imports anything")
	run_driver = preload("res://tests/phase_7b_run_driver.gd").new(test)
	await run_driver.collect_floor()
	test.check(not test.session.world.player.antiques.items().is_empty(),"Real night2 loot acquired before risk death")
	await run_driver.die_to_enemy()
	await test.frames(3)
	result = test.session.complete_screen.result
	test.check(result.outcome == RunResult.Outcome.DEAD and not result.antique_ids.is_empty(),"Real enemy death preserves lost-ID snapshot but no safe loot")
	test.key(KEY_E)
	await test.frames(5)
	test.check(flow.current_day == 3 and state.cash == cash_before_death and state.collection.all_items().size() == collection_before_death and state.display_assignments[&"CASE_1"] == new_item.instance_id,"Death morning preserves collection/cash/display and advances exactly one day")
	test.check(flow.museum.message.text.contains("没有新藏品") and flow.museum.message.text.contains(AntiqueDefinition.money(result.antique_value)),"Death return clearly reports loss and no acquisitions")
	test.capture("death_morning")
	# 用户反馈：不必强制营业或等满60秒才能下墓。
	var skip_day := flow.current_day
	var skip_cash := state.cash
	await night()
	test.check(flow.current_day == skip_day and state.cash == skip_cash and state.last_day_visitors == 0 and state.last_day_ticket_income == 0,"Morning board E skips optional business without income or day advance")
	test.session.world.player.health.take_damage(1000)
	await test.frames(2)
	test.key(KEY_E)
	await test.frames(5)
	test.check(flow.current_day == skip_day+1 and state.cash == skip_cash,"Skipped business still returns next morning only after night")
	flow.museum_config.open_duration = 60
	await walk_to(Vector2(1080,540))
	test.key(KEY_E)
	await test.frames(3)
	await walk_to(Vector2(1000,450))
	await walk_to(flow.museum.board.position+Vector2(-40,20))
	var business := flow.museum.business
	var museum := flow.museum
	test.check(flow.current_phase == MuseumState.Phase.OPEN and business.elapsed < 60,"Early departure request happens during actual60s business")
	test.key(KEY_E)
	var frozen_spawned := business.spawned
	var no_new_visitors: bool = true
	test.check(business.closing and museum._night_after_close and museum.message.text.contains("提前闭馆"),"Actual board E closes early and queues night after visitor exit")
	for frame in range(600):
		if flow.current_phase == MuseumState.Phase.NIGHT: break
		no_new_visitors = no_new_visitors and business.spawned == frozen_spawned
		await test.frames(1)
	await test.frames(4)
	test.session = flow.dungeon
	test.check(no_new_visitors and flow.current_phase == MuseumState.Phase.NIGHT and flow.museum == null and not is_instance_valid(museum),"Early close stops arrivals, drains visitors then loads night without60s wait")
	test.check(state.last_day_ticket_income == state.last_day_visitors*5 and state.cash >= skip_cash,"Early close records actual paid visitors once")
