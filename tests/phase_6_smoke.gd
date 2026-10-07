extends "res://tests/phase_5b_smoke.gd"
## 旧测试驾驶复用真实Door/Weapon/E；单项边界与完整实战分开。
const BOSS_CHECKS = preload("res://tests/phase_6_boss_checks.gd")
const FLOOR_CHECKS = preload("res://tests/phase_6_floor_checks.gd")


func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args():
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://logs/phase_6_%s.png" % name)


func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://logs")
	session = SESSION.instantiate() as DungeonSession
	session.tomb = preload("res://tests/fixtures/legacy_two_floor_tomb.tres")
	# 历史回归使用原主图夹具；Phase9A单独覆盖正式探索入口。
	session.exploration_enabled = false
	session.seed_value = 192034
	session.child_entered_tree.connect(watch)
	root.add_child(session)
	current_scene = session
	await frames(3)
	var bosses = BOSS_CHECKS.new(self)
	await bosses.run()
	check(bosses.completed, "Boss boundary suite completes")
	await reset()
	var floors = FLOOR_CHECKS.new(self)
	await floors.run()
	check(floors.completed, "Live Boss to floor-two suite completes")
	session.queue_free()
	await frames(3)
	print("[Phase 6] %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
