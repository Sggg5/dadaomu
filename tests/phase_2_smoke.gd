extends SceneTree
## 使用真实弹丸击杀、物理门区域和 WASD 输入走完固定五房，不靠直接设置 CLEARED。
## godot --headless --path . --script res://tests/phase_2_smoke.gd
## 图形模式加 -- --capture 会保存各房间与清场/死亡截图。

const MAP_SCENE: PackedScene = preload("res://scenes/main/room_test.tscn")
const MOVE_ACTIONS: Array[StringName] = [&"move_up", &"move_right", &"move_down", &"move_left"]

var world: RoomController
var checks: int = 0
var failures: int = 0
var _state_changes: Dictionary[StringName, Array] = {}
var _clear_counts: Dictionary[StringName, int] = {}


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
	for index in range(count):
		await physics_frame
	await process_frame


func _capture(name: String) -> void:
	if DisplayServer.get_name() == "headless" or not "--capture" in OS.get_cmdline_user_args():
		return
	DirAccess.make_dir_recursive_absolute("res://logs")
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://logs/phase_2_%s.png" % name)


func _record_state(status: RoomState.Status, room_id: StringName) -> void:
	_state_changes[room_id].append(status)


func _record_clear(room_id: StringName) -> void:
	_clear_counts[room_id] += 1


func _all_doors_open(value: bool) -> bool:
	for door in world.current_room.doors.values():
		if door.is_open != value or door.blocker.disabled != value:
			return false
	return true


func _clear_current_room() -> void:
	var room_id := world.current_id
	var room := world.current_room
	_clear_counts[room_id] = 0
	room.cleared.connect(_record_clear.bind(room_id))
	_check(room.room_state.status == RoomState.Status.ACTIVE and _all_doors_open(false), "%s enters ACTIVE with all doors blocked" % room_id)
	_check(room.enemy_spawner.get_remaining() == room.definition.enemy_positions.size(), "%s spawns configured enemy count" % room_id)
	_capture(str(room_id) + "_active")
	var enemies := room.enemy_spawner.get_children()
	for index in range(enemies.size()):
		var enemy := enemies[index] as Dummy
		for shot in range(3):
			var fired := world.player.weapon.try_attack(enemy.global_position - Vector2(0, 48), Vector2.DOWN, world.player.stats)
			_check(fired, "%s weapon fires at target %d shot %d" % [room_id, index, shot])
			await _frames(14)
		_check(not is_instance_valid(enemy), "%s target %d dies from actual projectile hits" % [room_id, index])
		if index < enemies.size() - 1:
			_check(room.room_state.status == RoomState.Status.ACTIVE and _all_doors_open(false), "%s doors stay locked before last death" % room_id)
	_check(room.room_state.status == RoomState.Status.CLEARED and room.enemy_spawner.get_remaining() == 0, "%s last death clears room" % room_id)
	_check(_all_doors_open(true) and _clear_counts[room_id] == 1, "%s opens all doors and emits cleared once" % room_id)
	room.enter()
	await _frames(2)
	_check(room.enemy_spawner.get_child_count() == 0 and _clear_counts[room_id] == 1, "%s repeated enter does not respawn or clear twice" % room_id)
	_capture(str(room_id) + "_cleared")


func _walk_through(side: int, target_id: StringName, use_existing_position: bool = false) -> void:
	var previous_room := world.current_room
	var same_player := world.player
	var hp := same_player.health.current_hp
	if not use_existing_position:
		same_player.position = previous_room.get_entry_position(side)
		same_player.velocity = Vector2.ZERO
	await _frames(2)
	# 一个长寿弹丸随旧房间释放，不允许留在下一个房间。
	var request := AttackRequest.new()
	request.origin = Vector2(640, 550)
	request.direction = Vector2.RIGHT
	request.speed = 1.0
	request.damage = 20.0
	request.lifetime = 100.0
	world._spawn_projectile(request)
	var old_projectile := previous_room.projectiles.get_child(0)
	Input.action_press(MOVE_ACTIONS[side])
	await _frames(28)
	Input.action_release(MOVE_ACTIONS[side])
	await _frames(12)
	_check(world.current_id == target_id, "Physical door %d leads to %s" % [side, target_id])
	_check(world.player == same_player and world.player.health.current_hp == hp, "Room crossing preserves player and HP")
	_check(not is_instance_valid(previous_room) and not is_instance_valid(old_projectile), "Crossing releases previous room and projectile")
	_check(world.get_node("RoomHost").get_child_count() == 1 and world.current_room.projectiles.get_child_count() == 0, "One room and no stale projectiles after crossing")
	_check(not world.transitioning and world.player.controls_enabled, "Crossing resumes input without entry bounce")


func _validate_content() -> void:
	for definition in world.definitions:
		var valid: bool = true
		for position in definition.enemy_positions:
			var bounds := Rect2(position - Vector2(20, 20), Vector2(40, 40))
			valid = valid and Room.ROOM_RECT.encloses(bounds)
			for obstacle in definition.obstacles:
				valid = valid and not obstacle.intersects(bounds)
		for side in RoomController.CONNECTIONS[definition.room_id]:
			var entry := world.current_room.get_entry_position(side)
			var bounds := Rect2(entry - Vector2(16, 16), Vector2(32, 32))
			for obstacle in definition.obstacles:
				valid = valid and not obstacle.intersects(bounds)
		_check(valid, "%s has safe enemy and doorway spawn bounds" % definition.room_id)


func _run() -> void:
	var state := RoomState.new()
	_check(not state.clear() and state.status == RoomState.Status.UNVISITED, "UNVISITED cannot skip directly to CLEARED")
	_check(state.activate() and not state.activate(), "Activation is idempotent")
	_check(state.clear() and not state.clear() and not state.activate(), "Clearing is terminal and idempotent")
	world = MAP_SCENE.instantiate() as RoomController
	root.add_child(world)
	current_scene = world
	await _frames(3)
	_validate_content()
	_check(world.current_id == &"center" and world.current_room.doors.size() == 4, "Starts in center of fixed cross map")
	for room_id in world.states:
		_state_changes[room_id] = []
		world.states[room_id].changed.connect(_record_state.bind(room_id))
		if room_id != &"center":
			_check(world.states[room_id].status == RoomState.Status.UNVISITED, "%s begins UNVISITED" % room_id)
	world.current_room.enter()
	world.current_room.enter()
	await _frames(2)
	_check(world.current_room.enemy_spawner.get_child_count() == 3, "Repeated active entry never duplicates enemies")
	_check(not world.request_traversal(Door.Direction.NORTH), "Controller rejects leaving an active room")
	world.player.position = world.current_room.get_entry_position(Door.Direction.NORTH)
	Input.action_press(&"move_up")
	await _frames(30)
	Input.action_release(&"move_up")
	await _frames(12)
	_check(world.current_id == &"center" and world.player.position.y >= 167.9, "Closed door physically blocks player")
	_check(world.current_room.doors[Door.Direction.NORTH].trigger.get_overlapping_bodies().has(world.player), "Player can already overlap sensor while door is locked")
	world.apply_test_damage()
	await _frames(2)
	_check(world.player.health.current_hp == 75.0, "Test damage before room crossing")
	await _clear_current_room()
	_check(world.current_id == &"center", "Door opening alone does not teleport player standing nearby")
	await _walk_through(Door.Direction.NORTH, &"north", true)
	await _clear_current_room()
	_check(not world.request_traversal(Door.Direction.EAST), "Leaf room rejects non-adjacent direction")
	await _walk_through(Door.Direction.SOUTH, &"center")
	_check(world.current_room.room_state.status == RoomState.Status.CLEARED and not world.current_room.enemy_spawner.started and _all_doors_open(true), "Revisited center stays cleared without spawning")

	for side in [Door.Direction.WEST, Door.Direction.EAST, Door.Direction.SOUTH]:
		var destination: StringName = RoomController.CONNECTIONS[&"center"][side]
		await _walk_through(side, destination)
		_check(world.current_room.doors.size() == 1, "%s only has its connected return door" % destination)
		await _clear_current_room()
		await _walk_through(Door.opposite(side), &"center")
		_check(world.current_room.room_state.status == RoomState.Status.CLEARED and world.current_room.enemy_spawner.get_child_count() == 0, "Center revisits never repopulate")
	for room_id in world.states:
		_check(world.states[room_id].status == RoomState.Status.CLEARED and _clear_counts[room_id] == 1, "%s retains CLEARED exactly once" % room_id)
		var expected: Array = [RoomState.Status.CLEARED] if room_id == &"center" else [RoomState.Status.ACTIVE, RoomState.Status.CLEARED]
		_check(_state_changes[room_id] == expected, "%s has correct state transition sequence" % room_id)
	_capture("all_cleared")

	_check(world.request_traversal(Door.Direction.NORTH) and not world.request_traversal(Door.Direction.EAST), "Only first traversal request accepted during transition")
	await _frames(4)
	_check(world.current_id == &"north" and world.current_room.enemy_spawner.get_child_count() == 0, "Cleared leaf revisit does not respawn")
	await _walk_through(Door.Direction.SOUTH, &"center")

	var empty_data := world.definitions[0].duplicate() as RoomDefinition
	empty_data.enemy_positions = PackedVector2Array()
	var empty := RoomController.ROOM_SCENE.instantiate() as Room
	var empty_state := RoomState.new()
	empty.configure(empty_data, empty_state, [])
	empty.position = Vector2(2000, 2000)
	root.add_child(empty)
	empty.enter()
	await _frames(2)
	_check(empty_state.status == RoomState.Status.CLEARED, "Zero-enemy combat room clears without deadlock")
	_check(world.definitions[0].enemy_positions.size() == 3, "Runtime changes do not mutate shared definition")
	empty.queue_free()
	await _frames(2)

	world.player.health.take_damage(1000.0)
	await _frames(2)
	_check(world.player.health.is_dead and not world.request_traversal(Door.Direction.NORTH), "Death blocks room traversal")
	_capture("death")
	var previous_world := world
	world.hud.restart_requested.emit()
	await _frames(5)
	world = current_scene as RoomController
	_check(not is_instance_valid(previous_world) and world.player.health.current_hp == 100.0, "Restart releases map and restores HP")
	for room_id in world.states:
		var expected: RoomState.Status = RoomState.Status.ACTIVE if room_id == &"center" else RoomState.Status.UNVISITED
		_check(world.states[room_id].status == expected, "%s resets state on restart" % room_id)
	_check(world.current_room.enemy_spawner.get_remaining() == 3 and world.get_node("RoomHost").get_child_count() == 1, "Restart spawns one center room and three enemies")
	print("[Phase 2] %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
