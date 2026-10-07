extends SceneTree
## 100 个连续 Seed 的独立图验证 + 真实房间/弹丸/门/重开集成。
## godot --headless --path . --script res://tests/phase_3_smoke.gd
## 图形模式可加 -- --capture；新 Seed 来源在测试中固定，保证测试自身确定性。

const SESSION_SCENE: PackedScene = preload("res://scenes/main/dungeon_test.tscn")
const CONFIG: DungeonConfig = preload("res://data/tombs/default_dungeon_config.tres")
const LAYOUT_CHECKS = preload("res://tests/phase_3_layout_checks.gd")
const MOVES: Array[StringName] = [&"move_up", &"move_right", &"move_down", &"move_left"]

var session: DungeonSession
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("[PASS] " + message)
	else:
		failures += 1
		push_error("[FAIL] " + message)


func _frames(count: int) -> void:
	for frame in range(count):
		await physics_frame
	await process_frame


func _capture(name: String) -> void:
	if DisplayServer.get_name() == "headless" or not "--capture" in OS.get_cmdline_user_args():
		return
	DirAccess.make_dir_recursive_absolute("res://logs")
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://logs/phase_3_%s.png" % name)


func _test_generator() -> void:
	var results: Dictionary[String, int] = {}
	var signatures: Dictionary[String, bool] = {}
	var repeat_count: int = 0
	var manifest: String = ""
	for seed_value in range(100):
		var first := DungeonGenerator.generate(seed_value, CONFIG)
		var second := DungeonGenerator.generate(seed_value, CONFIG)
		if first == null or second == null:
			_check(false, "Seed %d generated null" % seed_value)
			continue
		var report := LAYOUT_CHECKS.inspect(first, CONFIG)
		for rule in report:
			results[rule] = results.get(rule, 0) + int(report[rule])
			if not report[rule]:
				push_error("Seed %d violates %s" % [seed_value, rule])
		if first.signature() == second.signature() and first.seed_value == seed_value:
			repeat_count += 1
		signatures[first.spatial_signature()] = true
		manifest += first.signature() + "\n"
	for rule in results:
		_check(results[rule] == 100, "%s: %d / 100 Seeds" % [rule, results[rule]])
	_check(repeat_count == 100, "Same Seed: identical nodes, types, distances, links and templates 100 / 100")
	_check(signatures.size() >= 50, "Different topology signatures: %d / 100 Seeds" % signatures.size())
	var unchanged: bool = true
	for template in CONFIG.templates:
		unchanged = unchanged and template.room_type == RoomDefinition.Type.COMBAT
	_check(unchanged, "Special node types do not mutate shared combat templates")
	seed(81032)
	var expected_next := randi()
	seed(81032)
	DungeonGenerator.generate(42, CONFIG)
	_check(randi() == expected_next, "Generator leaves global RNG unchanged")
	for extreme in [8, 12]:
		var config := CONFIG.duplicate() as DungeonConfig
		config.min_rooms = extreme
		config.max_rooms = extreme
		config.min_boss_distance = extreme - 1
		config.min_antique_distance = extreme - 2
		var layout := DungeonGenerator.generate(-9223372036854775807, config)
		_check(layout != null and not LAYOUT_CHECKS.inspect(layout, config).values().has(false), "Boundary config %d rooms and deep spine" % extreme)
	var invalid := CONFIG.duplicate() as DungeonConfig
	invalid.min_rooms = 13
	_check(not invalid.validation_error().is_empty(), "Invalid config rejected before generation")
	# 配合无窗口/图形两次进程执行，比较完整 100 Seed 结果的摘要。
	DirAccess.make_dir_recursive_absolute("res://logs")
	var output := FileAccess.open("res://logs/phase_3_digest_%s.txt" % DisplayServer.get_name(), FileAccess.WRITE)
	if output:
		output.store_string(manifest.sha256_text())
		output.close()


func _count_players(node: Node) -> int:
	var total: int = int(node is Player)
	for child in node.get_children():
		total += _count_players(child)
	return total


func _clear_with_projectiles() -> void:
	var world := session.world
	var room := world.current_room
	_check(room.room_state.status == RoomState.Status.ACTIVE, "Entered room is ACTIVE")
	_check(not world.request_traversal(room.doors.keys()[0]), "Combat prevents early traversal")
	# Phase 3 隔离房间生命周期，不对新增 AI 作手感断言；活跃 AI 由 Phase 4 覆盖。
	room.enemy_spawner.stop_all()
	for enemy in room.enemy_spawner.get_children():
		var health := enemy.get_node("Health") as Health
		for shot in range(int(ceil(health.current_hp / world.player.stats.attack_damage))):
			_check(world.player.weapon.try_attack(enemy.global_position - Vector2(0, 48), Vector2.DOWN, world.player.stats), "Player weapon issues real projectile")
			await _frames(int(ceil(world.player.weapon.cooldown_remaining*60))+2)
	await _frames(2)
	_check(room.room_state.status == RoomState.Status.CLEARED and room.enemy_spawner.get_remaining() == 0, "Actual projectile kills clear generated room")
	for door in room.doors.values():
		_check(door.is_open and door.blocker.disabled, "Clearing opens generated door")


func _walk(side: int) -> void:
	var world := session.world
	var previous := world.current_room
	var player_id := world.player.get_instance_id()
	var hp := world.player.health.current_hp
	var destination := world.layout.rooms[world.current_id].neighbors[side]
	world.player.position = previous.get_entry_position(side)
	world.player.velocity = Vector2.ZERO
	var request := AttackRequest.new()
	request.origin = Vector2(640, 550)
	request.direction = Vector2.RIGHT
	request.speed = 1.0
	request.damage = 20.0
	request.lifetime = 100.0
	world._spawn_projectile(request)
	var bullet := previous.projectiles.get_child(0)
	await _frames(2)
	Input.action_press(MOVES[side])
	await _frames(28)
	Input.action_release(MOVES[side])
	await _frames(12)
	_check(world.current_id == destination, "WASD + Door reaches layout neighbor")
	_check(world.player.get_instance_id() == player_id and world.player.health.current_hp == hp and _count_players(root) == 1, "Unique player and HP retained across generated rooms")
	_check(not is_instance_valid(previous) and not is_instance_valid(bullet) and world.current_room.projectiles.get_child_count() == 0, "Old Room and projectiles released")
	_check(world.get_node("RoomHost").get_child_count() == 1 and not world.transitioning, "One active Room after traversal")


func _visit(target_id: StringName) -> void:
	var layout := session.world.layout
	var origin := session.world.current_id
	var parents: Dictionary = {origin: []}
	var queue: Array[StringName] = [origin]
	var index: int = 0
	while index < queue.size():
		var room_id := queue[index]
		index += 1
		for direction in layout.rooms[room_id].neighbors:
			var next_id := layout.rooms[room_id].neighbors[direction]
			if not parents.has(next_id):
				parents[next_id] = [room_id, direction]
				queue.append(next_id)
	var route: Array[int] = []
	var cursor := target_id
	while cursor != origin:
		route.append(parents[cursor][1])
		cursor = parents[cursor][0]
	route.reverse()
	for direction in route:
		# 两间核心战斗已验证实际弹丸；远端占位检查通过 Health 接口加速清场。
		for enemy in session.world.current_room.enemy_spawner.get_children():
			enemy.take_damage(1000.0)
		await _frames(3)
		await _walk(direction)


func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event)


func _run() -> void:
	_test_generator()
	if failures > 0:
		quit(1)
		return
	session = SESSION_SCENE.instantiate() as DungeonSession
	session.progressive_relics = false
	session.tomb = preload("res://tests/fixtures/legacy_two_floor_tomb.tres")
	# 历史回归使用原主图夹具；Phase9A单独覆盖正式探索入口。
	session.exploration_enabled = false
	root.add_child(session)
	current_scene = session
	await _frames(3)
	session._seed_rng.seed = 20261006
	var signature := session.world.layout.signature()
	var topology := session.world.layout.spatial_signature()
	var original_seed := session.seed_value
	_capture("start")
	_check(session.world.current_id == &"START" and _count_players(root) == 1, "Session starts at START with one Player")
	_check(session.world.current_room.room_state.status == RoomState.Status.CLEARED and session.world.current_room.enemy_spawner.get_remaining() == 0 and not session.world.current_room.enemy_spawner.started and session.world.current_room.doors.values().all(func(door: Door) -> bool: return door.is_open), "START is safe and opens all actual connections immediately")
	_check(session.world.hud.get_node("Root/Seed").text.contains(str(original_seed)), "HUD shows actual Seed")
	session.world.apply_test_damage()
	# START 已自动清场；原有 ACTIVE/锁门/真实弹丸清场断言在下一 COMBAT 执行。
	var side: int = session.world.layout.rooms[&"START"].neighbors.keys()[0]
	await _walk(side)
	_check(session.world.layout.rooms[session.world.current_id].room_type == RoomDefinition.Type.COMBAT, "START leads to generated COMBAT room")
	_capture("combat")
	await _clear_with_projectiles()
	await _walk(Door.opposite(side))
	_check(session.world.current_room.room_state.status == RoomState.Status.CLEARED and not session.world.current_room.enemy_spawner.started, "Revisit CLEARED keeps room empty and doors open")
	await _visit(session.world.layout.antique_id)
	_check(session.world.current_room.room_type == RoomDefinition.Type.ANTIQUE and session.world.current_room.room_state.status == RoomState.Status.CLEARED and session.world.current_room.enemy_spawner.get_remaining() == 0, "ANTIQUE placeholder auto clears without implementing inventory")
	_capture("antique")
	await _visit(session.world.layout.boss_id)
	_check(session.world.current_room.room_type == RoomDefinition.Type.BOSS and not session.world.current_room.enemy_spawner.started and is_instance_valid(session.world.current_room.boss_encounter.boss), "First-floor BOSS replaces ordinary spawns with one formal encounter")
	_capture("boss")
	session.world.player.health.take_damage(1000.0)
	await _frames(2)
	_check(not session.world.request_traversal(session.world.current_room.doors.keys()[0]), "Death prevents dungeon traversal")
	_capture("death")
	var old_world := session.world
	_key(KEY_R)
	await _frames(5)
	_check(not is_instance_valid(old_world) and session.seed_value == original_seed and session.world.layout.signature() == signature, "R reproduces same full layout and releases old controller")
	_check(session.world.player.health.current_hp == 80.0 and _count_players(root) == 1, "R restores HP and keeps only one Player")
	var states_reset: bool = true
	for room_id in session.world.states:
		states_reset = states_reset and session.world.states[room_id].status == (RoomState.Status.CLEARED if room_id == &"START" else RoomState.Status.UNVISITED)
	_check(states_reset, "R resets every room state")
	old_world = session.world
	_key(KEY_N)
	await _frames(5)
	_check(session.seed_value != original_seed and session.world.layout.spatial_signature() != topology, "N selects a new Seed and different topology")
	_check(not is_instance_valid(old_world) and _count_players(root) == 1 and session.world.player.health.current_hp == 80.0, "New Seed rebuilds without stale Player")
	_check(not LAYOUT_CHECKS.inspect(session.world.layout, CONFIG).values().has(false), "New Seed restart still satisfies every layout constraint")
	var new_signature := session.world.layout.signature()
	_key(KEY_R)
	await _frames(5)
	_check(session.world.layout.signature() == new_signature, "R after N repeats the newly selected Seed")
	_capture("new_seed")
	print("[Phase 3] %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
