extends "res://tests/phase_9b33_smoke.gd"
func run()->void:
	await preload("res://tests/phase_softlock_checks.gd").new(self).run()
	print("[Softlock] %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
