extends "res://tests/phase_8d_smoke.gd"
func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args():
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://logs/phase_9b2_%s.png" % name)
func run() -> void:
	for suite in [preload("res://tests/phase_9b2_data_checks.gd"),preload("res://tests/phase_9b2_build_checks.gd"),preload("res://tests/phase_9b2_ai_checks.gd"),preload("res://tests/phase_9b2_run_checks.gd")]:
		await suite.new(self).run()
	print("[Phase 9B.2] %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
