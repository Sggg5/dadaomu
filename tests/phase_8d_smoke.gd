extends "res://tests/phase_8c_smoke.gd"


func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args():
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://logs/phase_8d_%s.png" % name)


func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://logs")
	for suite in [preload("res://tests/phase_8d_market_checks.gd"),preload("res://tests/phase_8d_profile_checks.gd"),preload("res://tests/phase_8d_boundary_checks.gd"),preload("res://tests/phase_8d_isolation_checks.gd"),preload("res://tests/phase_8d_flow_checks.gd")]:
		var helper = suite.new(self)
		await helper.run()
	print("[Phase 8D] %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
