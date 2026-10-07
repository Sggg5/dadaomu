extends RefCounted
## 生命周期边界单项与上方真实五层主流程分开；允许注入HP/终点状态。
var test: SceneTree
func _init(context: SceneTree) -> void: test = context
func run() -> void:
	var session := preload("res://scenes/main/dungeon_test.tscn").instantiate() as DungeonSession
	session.seed_value = 33
	test.root.add_child(session)
	test.current_scene = session
	await test.frames(3)
	var signatures: Array[String] = []
	var rewards := session.rewards.sequence.duplicate()
	for number in range(1, 6): signatures.append(session.floor_layout(number).signature())
	var pool: AntiquePool = preload("res://data/antiques/formal_pool.tres")
	var profile := session.tomb.floor_at(4).antique_reward_profile
	var offer := pool.pick_profiled(33, 4, &"ROOM", &"antique_room", profile)
	var service := TombRiskService.new(33, 1)
	service.reward_profile = session.tomb.floor_at(1).antique_reward_profile
	service.resolve(&"ROOM", preload("res://data/dungeon/events/stone_coffin.tres"))
	for number in range(1, 6): test.check(session.floor_layout(number).signature() == signatures[number-1], "Risk RNG cannot change future map")
	test.check(pool.pick_profiled(33, 4, &"ROOM", &"antique_room", profile) == offer and session.rewards.sequence == rewards, "Risk opening leaves ordinary profile result and relic sequence unchanged")
	# Instantiate actual cleared Floor2 terminal, revisit and consume official RestPoint.
	var small := TombDefinition.new()
	small.id = &"SMALL_THREE"
	small.floors.assign(session.tomb.floors.slice(0, 3))
	test.check(small.validation_error().is_empty() and TombFloorGenerator.generate(33, 3, small) != null and TombFloorGenerator.generate(33, 4, small) == null, "Three-floor data needs no Session hardcoding")
	var carry := RunCarryState.capture(session.world.player)
	session._enter_next_floor(session.floor_layout(2), carry)
	await test.frames(3)
	var world := session.world
	var terminal := world.layout.terminal_id
	world.states[terminal].activate()
	world.states[terminal].clear()
	world._switch_room(terminal, -1)
	await test.frames(2)
	var rest := world.current_room.get_node("RestPoint") as RestPoint
	var initial_pos := rest.position
	test.check(initial_pos.distance_to(world.current_room.get_node("ExpeditionExit").position) >= 170, "Medical pack and exit interaction regions separated")
	world._switch_room(world.layout.start_id, -1)
	world.player.health.restore(34)
	world._switch_room(terminal, -1)
	rest = world.current_room.get_node("RestPoint") as RestPoint
	world.player.position = rest.position+Vector2(24, 0)
	test.key(KEY_E)
	await test.frames(2)
	test.check(world.player.health.current_hp == 49 and world.states[terminal].is_loot_claimed(&"rest_point"), "Leave cleared terminal, return hurt and actual E heals15")
	world._switch_room(world.layout.start_id, -1)
	world._switch_room(terminal, -1)
	test.check(world.current_room.get_node_or_null("RestPoint") == null, "Used medical pack does not respawn on revisit")
	# 未用治疗不随Carry进入下一层。
	world.states[terminal].claimed_loot_sources.erase(&"rest_point")
	world._switch_room(world.layout.start_id, -1)
	world._switch_room(terminal, -1)
	var unused_rest: WeakRef = weakref(world.current_room.get_node("RestPoint"))
	# Fourth-floor death retains three cleared terminals but only one real Boss.
	carry = RunCarryState.capture(world.player)
	session._enter_next_floor(session.floor_layout(3), carry)
	await test.frames(2)
	test.check(unused_rest.get_ref() == null and session.world.current_room.get_node_or_null("RestPoint") == null, "Unused previous-floor treatment expires with World")
	carry = RunCarryState.capture(session.world.player)
	session._enter_next_floor(session.floor_layout(4), carry)
	await test.frames(2)
	for number in range(1, 4): session.cleared_floors[number] = true
	session.bosses_defeated = 1
	session.world.player.health.take_damage(1000)
	var result := session.complete_screen.result
	test.check(result.outcome == RunResult.Outcome.DEAD and result.floor_reached == 4 and result.floors_cleared == 3 and result.bosses_defeated == 1, "Fourth-floor death reports reached4/cleared3/Boss1")
	test.key(KEY_R)
	await test.frames(5)
	for number in range(1, 6): test.check(session.floor_layout(number).signature() == signatures[number-1], "R recreates all five identical maps")
	test.check(session.floor_number == 1 and session.cleared_floors.is_empty() and session.bosses_defeated == 0 and session.world.player.health.current_hp == 80 and session.world.player.antiques.items().is_empty(), "R resets HP, cargo and separate terminal statistics")
	session._seed_rng.seed = 20261007
	test.key(KEY_N)
	await test.frames(5)
	test.check(session.run_seed != 33 and session.floor_layout(1).signature() != signatures[0] and session.floor_number == 1 and session.world.player.antiques.capacity == 8, "N new Run rebuilds tomb with same capacity")
	for number in range(1, 6):
		var data := session.tomb.floor_at(number)
		test.check(data.rest_amount == ([0,15,0,20,0][number-1]) and EncounterDifficulty.from_depth(100+number).tier == 3, "No economy-based treatment or Tier4+ scaling")
	test.check(service.reward(&"ROOM", preload("res://data/dungeon/events/risk_altar.tres")).rarity >= AntiqueDefinition.Rarity.RARE, "High-value altar ignores ordinary profile")
	session.queue_free()
	await test.frames(4)

	# 一层普通终点墓也通过同一生产生命周期完成。
	session = preload("res://scenes/main/dungeon_test.tscn").instantiate() as DungeonSession
	var one := TombDefinition.new()
	one.id = &"ONE_FLOOR"
	one.floors.assign([preload("res://data/tombs/default_tomb.tres").floor_at(1)])
	session.tomb = one
	session.seed_value = 33
	session.exploration_enabled = false
	test.session = session
	test.root.add_child(session)
	test.current_scene = session
	await test.frames(3)
	var driver = preload("res://tests/phase_5b_run_checks.gd").new(test)
	driver.shot_attempts = 128
	await driver.visit(session.world.layout.terminal_id)
	var final_exit := session.world.current_room.get_node("RunExit") as RunExit
	session.world.player.position = final_exit.position+Vector2(24, 0)
	test.key(KEY_E)
	await test.frames(2)
	test.check(session.run_ended and session.complete_screen.result.floors_cleared == 1 and session.complete_screen.result.bosses_defeated == 0 and session.complete_screen.result.outcome == RunResult.Outcome.COMPLETED, "One-floor combat terminal really completes via RunExit with zero Bosses")
	session.queue_free()
	await test.frames(3)
