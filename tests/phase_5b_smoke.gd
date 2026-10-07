extends SceneTree
const SESSION: PackedScene = preload("res://scenes/main/dungeon_test.tscn")
const DATA_CHECKS = preload("res://tests/phase_5b_data_checks.gd")
const HIT_CHECKS = preload("res://tests/phase_5b_hit_checks.gd")
const RUN_CHECKS = preload("res://tests/phase_5b_run_checks.gd")
const BALANCE_CHECKS = preload("res://tests/encounter_balance_checks.gd")
var session: DungeonSession
var contexts: Array[RoomClearContext] = []
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("[PASS] " + message)
	else:
		failures += 1
		push_error("[FAIL] " + message)


func frames(count: int) -> void:
	for frame in range(count):
		await physics_frame
		Input.action_release("attack")
	await process_frame


func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args():
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://logs/phase_5b_%s.png" % name)


func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event)


func watch(node: Node) -> void:
	if node is RoomController:
		node.room_cleared.connect(func(context: RoomClearContext) -> void: contexts.append(context))


func walk(side: int) -> void:
	var world := session.world
	var destination: StringName = world.layout.rooms[world.current_id].neighbors[side]
	world.player.position = world.current_room.get_entry_position(side)
	world.player.velocity = Vector2.ZERO
	await frames(2)
	var moves: Array[StringName] = [&"move_up", &"move_right", &"move_down", &"move_left"]
	Input.action_press(moves[side])
	await frames(28)
	Input.action_release(moves[side])
	await frames(12)
	check(world.current_id == destination, "Real Door reaches " + str(destination))


func reset(code: Key = KEY_R) -> void:
	key(code)
	await frames(5)


func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://logs")
	session = SESSION.instantiate() as DungeonSession
	session.progressive_relics = false
	session.tomb = preload("res://tests/fixtures/legacy_two_floor_tomb.tres")
	# 历史回归使用原主图夹具；Phase9A单独覆盖正式探索入口。
	session.exploration_enabled = false
	session.seed_value = 192034
	session.child_entered_tree.connect(watch)
	root.add_child(session)
	current_scene = session
	await frames(3)
	var balance = BALANCE_CHECKS.new(self)
	await balance.run()
	check(balance.completed, "Encounter balance suite completes")
	var data = DATA_CHECKS.new(self)
	await data.run()
	check(data.completed, "Data/attack suite completes")
	var hits = HIT_CHECKS.new(self)
	await hits.run()
	check(hits.completed, "Projectile/synergy suite completes")
	await reset()
	var runs = RUN_CHECKS.new(self)
	await runs.run()
	check(runs.completed, "Full normal reward run completes")
	session.queue_free()
	await frames(3)
	print("[Phase 5B] %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
