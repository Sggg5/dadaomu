extends "res://tests/phase_9b33_smoke.gd"
func run()->void:
	await preload("res://tests/phase_player_baseline_checks.gd").new(self).run()
	await preload("res://tests/phase_boss_scale_checks.gd").new(self).run()
	await preload("res://tests/phase_9b33_benchmark_checks.gd").new(self).run()
	await preload("res://tests/phase_9b3_run_checks.gd").new(self).run()
	print("[Player/Boss baseline] %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
