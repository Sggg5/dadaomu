extends "res://tests/phase_7a_smoke.gd"
const PLAN_CHECKS = preload("res://tests/phase_7b_plan_checks.gd")
const CACHE_CHECKS = preload("res://tests/phase_7b_cache_checks.gd")
const OUTCOME_CHECKS = preload("res://tests/phase_7b_outcome_checks.gd")
const RISK_CHECKS = preload("res://tests/phase_7b_risk_checks.gd")


func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args():
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://logs/phase_7b_%s.png" % name)


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
	var plan = PLAN_CHECKS.new(self)
	await plan.run()
	check(plan.completed,"Cache/Floor source plan suite completes")
	for suite in [CACHE_CHECKS,OUTCOME_CHECKS]:
		await reset()
		var helper = suite.new(self)
		await helper.run()
		check(helper.completed,"Cache/Outcome boundary suite completes")
	var risk = RISK_CHECKS.new(self,plan.pressure_seed)
	await risk.run()
	check(risk.completed,"Three real risk/success flows complete")
	session.queue_free()
	await frames(3)
	print("[Phase 7B] %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
