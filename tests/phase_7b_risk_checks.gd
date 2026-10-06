extends RefCounted
var test: SceneTree
var seed_value: int
var completed: bool = false


func _init(context: SceneTree, selected_seed: int) -> void:
	test = context
	seed_value = selected_seed


func run() -> void:
	var run = preload("res://tests/phase_7b_run_driver.gd").new(test)
	await run.reset(seed_value)
	await run.collect_floor()
	test.check(run.cache_pickups > 0 and test.session.world.player.antiques.items().size() >= 2, "Conservative path earns multiple antiques including real Combat Cache")
	await run.defeat_warlord()
	var world: RoomController = test.session.world
	var exit := world.current_room.get_node("ExpeditionExit") as ExpeditionExit
	var expected := world.player.antiques.total_value()
	var names: Array[String] = []
	for item in world.player.antiques.items(): names.append(item.display_name)
	world.player.position = exit.position+Vector2(24,0)
	await test.frames(1)
	test.check(exit.label.text.contains(AntiqueDefinition.money(expected)) and exit.label.text.contains("撤离可保住"), "Actual Boss choice explains current safe extraction value")
	test.capture("extract_choice")
	test.key(KEY_F)
	await test.frames(3)
	var result: RunResult = test.session.complete_screen.result
	test.check(result.outcome == RunResult.Outcome.EXTRACTED and result.antique_value == expected and result.antique_names == names and test.session.floor_number == 1 and result.bosses_defeated == 1, "Real cache/Weapon Boss/F extraction safely returns exact held cargo without floor2")
	test.capture("extracted")
	print("[Conservative extracted] Seed=%d cargo=%d value=%d" % [seed_value,names.size(),expected])
	# 贪心路径：真实E深层、更高rarity拾取，然后真实敌人致死，不注入HP。
	await run.reset(seed_value)
	await run.collect_floor()
	await run.defeat_warlord()
	await run.descend()
	world = test.session.world
	var offers := preload("res://tests/phase_7b_plan_checks.gd").offers(seed_value,2,world.layout)
	offers.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return world.layout.rooms[a.room].distance_from_start < world.layout.rooms[b.room].distance_from_start)
	var offer: Dictionary = offers[0]
	await run.driver.visit(offer.room)
	await run.take_current(offer)
	test.check(offer.definition.rarity >= AntiqueDefinition.Rarity.UNCOMMON and world.current_room.room_state.is_loot_claimed(offer.source), "Greedy floor2 actually picks UNCOMMON+ official cargo")
	expected = world.player.antiques.total_value()
	names.clear()
	for item in world.player.antiques.items(): names.append(item.display_name)
	await run.die_to_enemy()
	await test.frames(3)
	result = test.session.complete_screen.result
	test.check(result.outcome == RunResult.Outcome.DEAD and result.antique_value == expected and result.antique_names == names and world.player.antiques.items().is_empty() and test.session.complete_screen.label.text.contains("全部遗失"), "Real deep enemy fatal damage snapshots all lost cargo then clears bag")
	test.capture("greedy_dead")
	print("[Greedy dead] Seed=%d lost=%d, HP=%f" % [seed_value,expected,world.player.health.current_hp])
	# 完整成功/压力路线：正式8机会，真实Tab/Delete换入高价值，仍击杀两Boss。
	await run.reset(seed_value)
	await run.collect_floor()
	await run.defeat_warlord()
	await run.descend()
	await run.collect_floor()
	test.check(run.pressure_exchanges > 0 and test.session.world.player.antiques.used_slots() <= 8, "Official eight-source Run really performs E-fail/Tab/Delete/E higher-value exchange")
	world = test.session.world
	await run.driver.visit(world.layout.boss_id)
	var beast = preload("res://tests/beast_fight_driver.gd").new(test)
	await beast.run()
	var final_exit := world.current_room.get_node("RunExit") as RunExit
	test.check(not world.current_room.has_node("ExpeditionExit") and not world.current_room.has_node("FloorExit"), "Final Boss offers RunExit only, no third layer")
	expected = world.player.antiques.total_value()
	world.player.position = final_exit.position+Vector2(24,0)
	test.key(KEY_E)
	await test.frames(3)
	result = test.session.complete_screen.result
	test.check(result.outcome == RunResult.Outcome.COMPLETED and result.floors_cleared == 2 and result.bosses_defeated == 2 and result.antique_value == expected and test.session.complete_screen.label.text.contains("安全带回"), "Two real Weapon Boss kills/RunExit produce COMPLETED with safe exact cargo")
	test.capture("completed")
	print("[Completed pressure] Seed=%d exchanges=%d cargo=%d slots=%d value=%d" % [seed_value,run.pressure_exchanges,result.antique_names.size(),world.player.antiques.used_slots(),expected])
	var guards = preload("res://tests/phase_7b_outcome_checks.gd").new(test)
	guards.finished_checks()
	var signature := world.antique_loot.selected_rooms.duplicate()
	await test.reset(KEY_R)
	test.check(test.session.run_seed == seed_value and test.session.floor_number == 1 and test.session.world.player.antiques.items().is_empty(), "R after full pressure Run returns same Seed floor1/empty cargo")
	test.session._seed_rng.seed = 20261006
	await test.reset(KEY_N)
	test.check(test.session.run_seed != seed_value and test.session.floor_number == 1 and test.session.world.player.antiques.items().is_empty(), "N after success creates new Run and empty cargo")
	completed = true
