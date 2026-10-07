extends "res://tests/phase_6_smoke.gd"
const BEAST_CHECKS = preload("res://tests/phase_6_5_boss_checks.gd")
const RELIC_CHECKS = preload("res://tests/phase_6_5_relic_checks.gd")
const FINALE_CHECKS = preload("res://tests/phase_6_5_run_checks.gd")


func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args():
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://logs/phase_6_5_%s.png" % name)


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
	for suite in [BEAST_CHECKS,RELIC_CHECKS]:
		var helper = suite.new(self)
		await helper.run()
		check(helper.completed,"Beast/relic boundary suite completes")
	await reset()
	var finale = FINALE_CHECKS.new(self)
	await finale.run()
	check(finale.completed,"Full two-floor live Run suite completes")
	session.queue_free()
	await frames(3)
	print("[Phase 6.5] %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
