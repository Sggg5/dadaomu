extends "res://tests/phase_6_5_smoke.gd"
const ANTIQUE_DATA = preload("res://tests/phase_7a_data_checks.gd")
const ANTIQUE_RUN = preload("res://tests/phase_7a_run_checks.gd")


func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args():
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://logs/phase_7a_%s.png" % name)


func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://logs")
	session = SESSION.instantiate() as DungeonSession
	# 历史回归使用原主图夹具；Phase9A单独覆盖正式探索入口。
	session.exploration_enabled = false
	session.seed_value = 192034
	session.child_entered_tree.connect(watch)
	root.add_child(session)
	current_scene = session
	await frames(3)
	var data = ANTIQUE_DATA.new(self)
	await data.run()
	check(data.completed,"Antique data/boundary suite completes")
	session._schedule_new_run(DungeonGenerator.generate(192034,session.config))
	await frames(5)
	var runs = ANTIQUE_RUN.new(self)
	await runs.run()
	check(runs.completed,"Actual two-floor antique loot/Run suite completes")
	session.queue_free()
	await frames(3)
	print("[Phase 7A] %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
