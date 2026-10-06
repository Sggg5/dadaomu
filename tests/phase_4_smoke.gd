extends SceneTree
## 真实 AI、伤害/碰撞和随机地宫流程的入口；子模块按职责划分测试。
const ENEMY_CHECKS = preload("res://tests/phase_4_enemy_checks.gd")
const BULLET_CHECKS = preload("res://tests/phase_4_projectile_checks.gd")
const ROOM_CHECKS = preload("res://tests/phase_4_room_checks.gd")

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


func _capture(name: String) -> void:
	if DisplayServer.get_name() == "headless" or not "--capture" in OS.get_cmdline_user_args():
		return
	DirAccess.make_dir_recursive_absolute("res://logs")
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://logs/phase_4_%s.png" % name)


func _run() -> void:
	var arena = ENEMY_CHECKS.new(self, _check, _capture)
	await arena.setup()
	await arena.melee()
	var shooter: BanditShooter = await arena.ranged()
	await arena.player_damage_and_death(shooter)
	var bullets = BULLET_CHECKS.new(arena, _check)
	await bullets.run()
	arena.host.queue_free()
	await arena.frames(2)
	var rooms = ROOM_CHECKS.new(self, _check, _capture)
	await rooms.run()
	print("[Phase 4] %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
