extends "res://tests/phase_9b3_smoke.gd"
func capture(label:String)->void:
	if DisplayServer.get_name()!="headless" and "--capture" in OS.get_cmdline_user_args():
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://logs/phase_9b32_%s.png"%label)
func run()->void:
	for suite in [preload("res://tests/phase_9b32_data_checks.gd"),preload("res://tests/phase_9b32_mechanic_checks.gd"),preload("res://tests/phase_9b32_benchmark_checks.gd"),preload("res://tests/phase_9b3_run_checks.gd")]:
		await suite.new(self).run()
	print("[Phase 9B.3.2] %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
