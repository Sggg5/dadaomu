extends SceneTree
## 在真实 Godot 场景树/物理帧中验证核心行为；失败以非零退出码结束。
## godot --headless --path . --script res://tests/phase_1_smoke.gd
## 图形模式可附加 -- --capture 保存初始场景截图到 logs/。

const ARENA: PackedScene = preload("res://scenes/main/combat_test.tscn")
var failures: int = 0
var checks: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("[FAIL] " + message)
	else:
		print("[PASS] " + message)


func _frames(count: int) -> void:
	for index in range(count):
		await physics_frame
	await process_frame


func _move_mouse(position: Vector2) -> void:
	# 经真实视口分发事件，验证输入采样，不依赖 Windows 前台焦点。
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	root.push_input(motion)


func _run() -> void:
	var arena := ARENA.instantiate() as CombatTest
	root.add_child(arena)
	current_scene = arena
	await _frames(3)
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		RenderingServer.force_draw()
		DirAccess.make_dir_recursive_absolute("res://logs")
		root.get_texture().get_image().save_png("res://logs/phase_1_initial.png")
	var player := arena.player
	_check(player.health.current_hp == 100.0 and arena.remaining_targets == 3, "Initial HP and three targets")
	_check(InputMap.action_get_events("test_damage")[0].physical_keycode == KEY_F1, "F1 binding")

	Input.action_press("move_right")
	await _frames(3)
	_check(player.velocity.x > 0.0 and player.velocity.x < player.stats.move_speed, "Movement accelerates")
	await _frames(12)
	var straight_speed := player.velocity.length()
	_check(is_equal_approx(straight_speed, player.stats.move_speed), "Movement reaches configured speed")
	Input.action_release("move_right")
	await _frames(12)
	_check(player.velocity.is_zero_approx(), "Movement decelerates to rest")
	Input.action_press("move_right")
	Input.action_press("move_down")
	await _frames(15)
	_check(is_equal_approx(player.velocity.length(), straight_speed), "Diagonal speed is normalized")
	Input.action_release("move_right")
	Input.action_release("move_down")
	await _frames(12)
	player.position = Vector2(90, 360)
	Input.action_press("move_left")
	await _frames(40)
	_check(player.position.x >= 79.9, "Player is blocked by room wall")
	Input.action_release("move_left")
	await _frames(12)
	player.position = Vector2(700, 240)
	await _frames(2)

	var first := arena.get_node("Actors/DummyA") as Dummy
	_check(player.weapon.try_attack(player.position, Vector2.RIGHT, player.stats), "Weapon fires first shot")
	_check(not player.weapon.try_attack(player.position, Vector2.RIGHT, player.stats), "Cooldown rejects immediate second shot")
	await _frames(20)
	_check(first.health.current_hp == 40.0, "One projectile applies damage exactly once")
	_check(arena.projectiles.get_child_count() == 0, "Projectile is removed after hit")
	for shot in range(2):
		player.weapon.try_attack(player.position, Vector2.RIGHT, player.stats)
		await _frames(20)
	_check(not is_instance_valid(first) and arena.remaining_targets == 2, "Third hit kills dummy and updates counter once")

	for target_name in ["DummyB", "DummyC"]:
		var target := arena.get_node("Actors/" + target_name) as Dummy
		player.position = target.position - Vector2(80, 0)
		for shot in range(3):
			player.weapon.try_attack(player.position, Vector2.RIGHT, player.stats)
			await _frames(20)
	_check(arena.remaining_targets == 0, "All three dummies can be killed")

	var wall_shot := AttackRequest.new()
	wall_shot.origin = Vector2(1180, 550)
	wall_shot.direction = Vector2.RIGHT
	wall_shot.damage = 20.0
	wall_shot.speed = 20000.0
	wall_shot.lifetime = 2.0
	arena._spawn_projectile(wall_shot)
	await _frames(3)
	_check(arena.projectiles.get_child_count() == 0, "High speed projectile is consumed by thin wall")
	wall_shot.origin = Vector2(600, 550)
	wall_shot.speed = 1.0
	wall_shot.lifetime = 0.02
	arena._spawn_projectile(wall_shot)
	await _frames(4)
	_check(arena.projectiles.get_child_count() == 0, "Projectile expires without hitting anything")

	_check(not player.take_damage(-5.0), "Negative damage is rejected")
	var death_count := [0]
	player.died.connect(func() -> void: death_count[0] += 1)
	# 经真实输入分发验证 F1，不直接绕过场景快捷键。
	var key := InputEventKey.new()
	key.physical_keycode = KEY_F1
	key.pressed = true
	root.push_input(key)
	await _frames(2)
	_check(player.health.current_hp == 75.0, "F1 dispatch applies configured test damage")
	_check(not player.take_damage(25.0), "Hurt invulnerability rejects repeated immediate damage")
	for hit in range(3):
		await _frames(25)
		arena.damage_button.pressed.emit()
	await _frames(2)
	_check(player.health.is_dead and player.health.current_hp == 0.0, "Four test hits cause death")
	_check(death_count[0] == 1 and not player.take_damage(25.0), "Death fires once and further damage is ignored")
	Input.action_press("move_right")
	Input.action_press("attack")
	var death_position := player.position
	await _frames(20)
	_check(player.position.is_equal_approx(death_position) and arena.projectiles.get_child_count() == 0, "Dead player cannot move or attack")
	Input.action_release("move_right")
	Input.action_release("attack")
	_check(arena.damage_button.disabled, "Test damage button disabled on death")
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://logs/phase_1_death.png")

	for iteration in range(2):
		arena.get_node("HUD/Root/RestartButton").pressed.emit()
		await _frames(5)
		var previous := arena
		arena = current_scene as CombatTest
		_check(not is_instance_valid(previous), "Restart releases old scene %d" % iteration)
		_check(arena.player.health.current_hp == 100.0 and arena.remaining_targets == 3
			and arena.projectiles.get_child_count() == 0 and arena.player.weapon.cooldown_remaining == 0.0,
			"Restart resets health, targets, projectiles and cooldown %d" % iteration)

	if DisplayServer.get_name() != "headless":
		var target := arena.get_node("Actors/DummyA") as Dummy
		_move_mouse(target.global_position)
		await _frames(4)
		var expected_aim := (target.global_position - arena.player.global_position).normalized()
		_check(arena.player.aim_direction.dot(expected_aim) > 0.999, "Mouse position controls attack direction")
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = target.global_position
		click.global_position = target.global_position
		click.pressed = true
		Input.parse_input_event(click)
		await _frames(3)
		click = click.duplicate() as InputEventMouseButton
		click.pressed = false
		Input.parse_input_event(click)
		await _frames(45)
		_check(target.health.current_hp == 40.0, "Left mouse input fires aimed projectile and hits target")
		_move_mouse(Vector2(700, 660))
		await _frames(3)
		click = InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = Vector2(700, 660)
		click.global_position = click.position
		click.pressed = true
		Input.parse_input_event(click)
		await _frames(3)
		click = click.duplicate() as InputEventMouseButton
		click.pressed = false
		Input.parse_input_event(click)
		await _frames(3)
		_check(arena.player.health.current_hp == 75.0 and arena.projectiles.get_child_count() == 0,
			"Clicking test damage UI applies damage without firing")

	var restart_key := InputEventKey.new()
	restart_key.physical_keycode = KEY_R
	restart_key.pressed = true
	root.push_input(restart_key)
	await _frames(5)
	_check(current_scene != arena and (current_scene as CombatTest).player.health.current_hp == 100.0,
		"R input restarts scene")

	print("[Phase 1] %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
