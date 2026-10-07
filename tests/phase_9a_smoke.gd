extends "res://tests/phase_8d_smoke.gd"
## 正式探索默认开启；历史回归的主图夹具另外运行，绝不碰正式存档。
func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args():
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://logs/phase_9a_%s.png" % name)

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://logs")
	for suite in [preload("res://tests/phase_9a_data_checks.gd"), preload("res://tests/phase_9a_interaction_checks.gd"), preload("res://tests/phase_9a_wall_checks.gd"), preload("res://tests/phase_9a_lifecycle_checks.gd"), preload("res://tests/phase_9a_flow_checks.gd"), preload("res://tests/phase_9a_complete_flow_checks.gd"), preload("res://tests/phase_9a_seed_checks.gd")]:
		await suite.new(self).run()
	print("[Phase 9A] %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
