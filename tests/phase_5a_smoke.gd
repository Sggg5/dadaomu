extends SceneTree
## 生产 Session、武器、弹丸与真实 Door 集成；不替换 Phase 1～4 回归。
const SESSION = preload("res://scenes/main/dungeon_test.tscn")
const ATTACK_CHECKS = preload("res://tests/phase_5a_attack_checks.gd")
const ROOM_CHECKS = preload("res://tests/phase_5a_room_checks.gd")
var checks: int = 0
var failures: int = 0
var session: DungeonSession


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
		# 图形自动验证不接受桌面鼠标额外连射；本测试从真实 Weapon 发出攻击。
		Input.action_release("attack")
	await process_frame


func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute("res://logs")
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://logs/phase_5a_%s.png" % name)


func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event)


func walk(side: int) -> void:
	var world := session.world
	world.player.position = world.current_room.get_entry_position(side)
	world.player.velocity = Vector2.ZERO
	await frames(2)
	var moves: Array[StringName] = [&"move_up", &"move_right", &"move_down", &"move_left"]
	Input.action_press(moves[side])
	await frames(28)
	Input.action_release(moves[side])
	await frames(12)


func run() -> void:
	session = SESSION.instantiate() as DungeonSession
	session.seed_value = 1
	root.add_child(session)
	current_scene = session
	await frames(3)
	var attacks = ATTACK_CHECKS.new(self)
	await attacks.run()
	check(attacks.completed, "Attack test suite reaches its final assertion")
	var rooms = ROOM_CHECKS.new(self)
	await rooms.run()
	check(rooms.completed, "Room lifecycle suite reaches its final assertion")
	session.queue_free()
	await frames(3)
	print("[Phase 5A] %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
