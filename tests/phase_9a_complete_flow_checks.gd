extends RefCounted
## 正式入口两层真Boss/真RunExit/E回館；不伪造COMPLETED，不注入库存/HP。
var test: SceneTree
func _init(context: SceneTree) -> void: test = context

func run() -> void:
	var flow := preload("res://scenes/main/game_flow.tscn").instantiate() as GameFlow
	flow.tomb = preload("res://tests/fixtures/legacy_two_floor_tomb.tres")
	# 旧功能固定Run夹具；正式派生Seed由9A专项另外覆盖。
	flow.forced_night_seed = 192034
	flow.campaign_seed_override = 52
	flow.profile_store = MuseumProfileStore.in_memory()
	flow.forced_night_seed = 33
	test.root.add_child(flow)
	test.current_scene = flow
	await test.frames(3)
	var state := flow.museum_state
	test.check(state.day_number == 1 and state.collection.all_items().is_empty() and state.cash == 0, "Official complete-run fixture starts empty Day1 museum")
	var daytime = preload("res://tests/phase_8a_flow_checks.gd").new(test, flow)
	await daytime.night()
	var session := flow.dungeon
	var driver = preload("res://tests/phase_7b_run_driver.gd").new(test)
	driver.driver.shot_attempts = 128
	driver.driver.avoid_optional_rooms = true
	test.check(session.hub_mode and session.exploration_enabled, "Official GameFlow gives exploration Dungeon a real museum return target")
	await driver.collect_floor()
	await driver.defeat_warlord()
	test.check(session.world.risk_service.results.is_empty() and not session.world.exploration.secret_discovered, "Floor1 also reaches Boss on main route without resolving optional risks")
	for id in session.world.layout.rooms:
		if session.world.layout.rooms[id].room_type in [RoomDefinition.Type.TRAP, RoomDefinition.Type.SECRET]:
			test.check(session.world.states[id].status == RoomState.Status.UNVISITED, "Floor1 optional chamber may remain entirely unvisited " + str(id))
	test.check(session.floor_number == 1 and session.bosses_defeated == 1 and not session.run_ended, "Real Boss1 victory awaits player choice instead of completing")
	var hp := session.world.player.health.current_hp
	var relic_ids := session.world.player.relics.inventory.ids()
	var cargo := session.world.player.antiques.items()
	await driver.descend()
	test.check(session.world.hud.get_node("Root/Seed").text.contains(str(session.run_seed)) and session.world.hud.get_node("Root/Seed").tooltip_text.contains(str(session.current_floor_seed)), "Floor2 HUD preserves actual expedition Run Seed and exposes floor Seed in tooltip")
	test.check(session.floor_number == 2 and session.world.player.health.current_hp == hp and session.world.player.relics.inventory.ids() == relic_ids and session.world.player.antiques.items() == cargo, "Actual E deepen keeps HP/earned relics/cargo under GameFlow")
	var first_clears := session.rewards.combat_clears
	await driver.collect_floor()
	test.check(session.rewards.combat_clears > first_clears and session.world.player.antiques.used_slots() > 0, "Floor2 genuinely clears active ordinary encounters and picks cargo")
	await driver.driver.visit(session.world.layout.boss_id)
	var beast = preload("res://tests/beast_fight_driver.gd").new(test)
	await beast.run()
	test.check(beast.completed and session.bosses_defeated == 2 and not session.run_ended, "True Boss2 projectile kill waits for final RunExit interaction")
	var world := session.world
	var exit := world.current_room.get_node("RunExit") as RunExit
	world.player.position = exit.position + Vector2(100, 0)
	test.key(KEY_E)
	test.check(not session.run_ended and not exit.used, "Final exit cannot complete outside64px")
	world.player.position = exit.position + Vector2(24, 0)
	test.key(KEY_E)
	await test.frames(3)
	var result := session.complete_screen.result
	test.check(result.outcome == RunResult.Outcome.COMPLETED and result.floor_reached == 2 and result.bosses_defeated == 2 and result.floors_cleared == 2, "Real RunExit E produces COMPLETED/two floors/two Bosses")
	test.check(session.complete_screen.hub_mode and session.complete_screen.get_node("Actions").text.contains("[E] 返回地面"), "Official completed screen visibly offers real E return")
	test.check(world.risk_service.results.is_empty() and not world.exploration.secret_discovered, "Full two-floor victory remains possible without resolving any risk event/secret")
	test.capture("official_complete_screen")
	var count := result.antique_ids.size()
	test.key(KEY_E)
	test.key(KEY_E)
	test.key(KEY_E)
	await test.frames(5)
	test.check(not is_instance_valid(session) and flow.dungeon == null and is_instance_valid(flow.museum) and flow.current_phase == MuseumState.Phase.MORNING and state.day_number == 2, "Real rapid E return releases Dungeon and creates Day2 morning Museum once")
	test.check(state.collection.all_items().size() == count and count > 0 and state.cash == 0, "Complete-run cargo imports once without arbitrary cash")
	for index in range(count):
		var owned := state.collection.all_items()[index]
		test.check(owned.definition_id == result.antique_ids[index] and not owned.identified and owned.condition == result.antique_conditions[index] and owned.acquired_day == 1, "Two-floor return preserves ID/unidentified/condition/acquisition day item%d" % index)
	test.key(KEY_E)
	await test.frames(2)
	test.check(state.collection.all_items().size() == count and state.day_number == 2 and not flow.return_from_night(result), "Extra E and stale completed result cannot duplicate import/day advance")
	test.capture("official_return_museum")
	print("[9A.1 official two-floor] seed=33 outcome=COMPLETED bosses=2 cargo=%s value=%d Day2=%d cash=%d" % [result.antique_ids, result.antique_value, state.collection.all_items().size(), state.cash])
	flow.queue_free()
	await test.frames(4)
	await independent_footer(result)

func independent_footer(result: RunResult) -> void:
	# 只展示上方真实两层结果的独立模式；旧6.5套件另跑独立两层真实战斗。
	var screen := RunCompleteScreen.new()
	screen.result = result
	screen.hub_mode = false
	var returned := {"count": 0}
	screen.return_requested.connect(func() -> void: returned.count += 1)
	test.root.add_child(screen)
	await test.frames(2)
	var actions: String = screen.get_node("Actions").text
	test.check(actions.contains("独立地宫测试模式") and actions.contains("[R]") and actions.contains("[N]") and not actions.contains("[E]"), "Independent two-floor result explicitly names test mode and R/N only")
	test.key(KEY_E)
	test.check(returned.count == 0, "Independent result E does not fabricate a Museum target")
	test.capture("independent_complete_screen")
	screen.queue_free()
	await test.frames(3)
