extends RefCounted
## 五层生产配置，真实Door/弹丸/E/F/库存管理；不直接造Run结果或注入携货。
var test: SceneTree
var driver: RefCounted
var cargo_driver: RefCounted
var swaps: int = 0
func _init(context: SceneTree) -> void: test = context

func run() -> void:
	await play(5)
	for exit_floor in range(1, 5): await play(exit_floor)

func play(exit_floor: int) -> void:
	var flow := preload("res://scenes/main/game_flow.tscn").instantiate() as GameFlow
	flow.profile_store = MuseumProfileStore.in_memory()
	flow.campaign_seed_override = 52
	flow.forced_night_seed = 33
	test.root.add_child(flow)
	test.current_scene = flow
	await test.frames(3)
	test.check(flow.tomb.floors.size() == 5 and flow.museum_state.collection.all_items().is_empty(), "Production GameFlow starts empty museum and five floors")
	await preload("res://tests/phase_8a_flow_checks.gd").new(test, flow).night()
	var session := flow.dungeon
	var signatures: Array[String] = []
	for number in range(1, 6): signatures.append(session.floor_layout(number).signature())
	for number in range(1, exit_floor+1):
		driver = preload("res://tests/phase_5b_run_checks.gd").new(test)
		driver.shot_attempts = 128
		driver.avoid_optional_rooms = true
		driver.picked.assign(session.world.player.relics.inventory.ids())
		cargo_driver = preload("res://tests/phase_7b_run_driver.gd").new(test)
		cargo_driver.driver = driver
		if number in [2, 4]: await one_real_hit()
		await collect()
		var world := session.world
		test.check(world.combat_cache_count == 1 and world.antique_loot.selected_rooms.size() == 1, "Live Run33 uses one cache on every floor")
		await driver.visit(world.layout.terminal_id)
		if world.boss_definition is BossDefinition:
			if number == 2: await preload("res://tests/phase_6_floor_checks.gd").new(test).boss_fight()
			else: await preload("res://tests/beast_fight_driver.gd").new(test).run()
		test.check(world.current_room.room_state.status == RoomState.Status.CLEARED and session.cleared_floors.size() == number and session.bosses_defeated == (2 if number == 5 else (1 if number >= 2 else 0)), "True terminal combat updates separate floor/Boss counts")
		var rest := world.current_room.get_node_or_null("RestPoint") as RestPoint
		if number in [2, 4]:
			test.check(rest != null and rest.amount == (15 if number == 2 else 20), "Correct floor medical pack")
			world.player.position = rest.position + Vector2(24, 0)
			var before := world.player.health.current_hp
			var amount := rest.amount
			test.key(KEY_E)
			await test.frames(2)
			test.check(world.player.health.current_hp == minf(80, before+amount), "Real medical pack E heals through Health cap")
		else: test.check(rest == null, "No free healing on other floors")
		print("[9B live] floor=%d HP=%.2f bag=%d value=%d bosses=%d" % [number, world.player.health.current_hp, world.player.antiques.used_slots(), world.player.antiques.total_value(), session.bosses_defeated])
		test.capture("terminal_%d_exit_%d" % [number, exit_floor])
		if number == exit_floor:
			var exit := world.current_room.get_node("RunExit" if number == 5 else "ExpeditionExit") as Node2D
			world.player.position = exit.position + Vector2(24, 0)
			test.key(KEY_E if number == 5 else KEY_F)
			await test.frames(3)
			var result := session.complete_screen.result
			test.check(result.floor_reached == number and result.floors_cleared == number and result.bosses_defeated == (2 if number == 5 else (1 if number >= 2 else 0)) and result.outcome == (RunResult.Outcome.COMPLETED if number == 5 else RunResult.Outcome.EXTRACTED), "True E/F result correct for floor%d" % number)
			if number == 5: test.check(swaps > 0, "Full bag deep-floor E/Tab/Delete genuinely replaces cheaper cargo")
			var count := result.antique_ids.size()
			test.key(KEY_E)
			await test.frames(5)
			test.check(flow.dungeon == null and flow.current_day == 2 and flow.museum_state.collection.all_items().size() == count and count > 0, "Actual E museum return imports successful cargo exactly once")
			break
		var hp := world.player.health.current_hp
		var items := world.player.antiques.items()
		var relic_ids := world.player.relics.inventory.ids()
		var old_player: WeakRef = weakref(world.player)
		var exit := world.current_room.get_node("ExpeditionExit") as ExpeditionExit
		test.check(exit.next_floor_number == number+1 and exit.label.text.contains(str(number+1)), "Injected next-floor exit text")
		world.player.position = exit.position + Vector2(24, 0)
		test.key(KEY_E)
		await test.frames(5)
		test.check(session.floor_number == number+1 and old_player.get_ref() == null and session.world.player.health.current_hp == hp and session.world.player.antiques.items() == items and session.world.player.relics.inventory.ids() == relic_ids and session.world.player.antiques.capacity == 8, "Each real descent replaces World and preserves HP/cargo/Build")
		test.check(session.floor_layout(number+1).signature() == signatures[number], "Rest and cargo choices never alter subsequent floor map")
	flow.queue_free()
	await test.frames(4)

func collect() -> void:
	var session: DungeonSession = test.session
	var world := session.world
	var offers: Array[Dictionary] = []
	for id in world.antique_loot.selected_rooms:
		offers.append({"room": id, "source": &"combat_cache", "definition": world._pick_antique(id, &"combat_cache")})
	offers.append({"room": world.layout.antique_id, "source": &"antique_room", "definition": world._pick_antique(world.layout.antique_id, &"antique_room")})
	offers.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.definition.base_value < b.definition.base_value)
	for offer in offers:
		await driver.visit(offer.room)
		await cargo_driver.take_current(offer)
	swaps += cargo_driver.pressure_exchanges


func one_real_hit() -> void:
	# 主流程接受一次实际敌人攻击，以验证终点治疗不是只在满血空点。
	var world: RoomController = test.session.world
	var parents: Dictionary[StringName, StringName] = {world.current_id: &""}
	var queue: Array[StringName] = [world.current_id]
	var target: StringName = &""
	while not queue.is_empty():
		var id: StringName = queue.pop_front()
		if world.layout.rooms[id].room_type == RoomDefinition.Type.COMBAT:
			target = id
			break
		for neighbor in world.layout.rooms[id].neighbors.values():
			if not parents.has(neighbor):
				parents[neighbor] = id
				queue.append(neighbor)
	var path: Array[StringName] = []
	var cursor := target
	while cursor != world.current_id:
		path.push_front(cursor)
		cursor = parents[cursor]
	for id in path: await test.walk(world.layout.rooms[world.current_id].neighbors.find_key(id))
	var enemy := world.current_room.enemy_spawner.get_child(0) as Enemy
	var hp := world.player.health.current_hp
	for tick in range(360):
		if world.player.health.current_hp < hp: break
		world.player.position = enemy.position + Vector2(0, 34 if enemy is ScarabEnemy else 200)
		world.player.velocity = Vector2.ZERO
		await test.frames(1)
	test.check(world.player.health.current_hp < hp and not world.player.health.is_dead, "Actual live enemy attack precedes medical-pack recovery")
	await driver.fight()
