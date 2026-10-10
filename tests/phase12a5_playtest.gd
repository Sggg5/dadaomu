extends "res://tests/phase12a4_playtest.gd"
## Same memory-only selector; A gets the explicitly attached DRAFT art sample.
func show_layout(index: int) -> void:
	await super.show_layout(index)
	if index==1 and "--old-a" not in OS.get_cmdline_user_args():
		preload("res://tests/support/phase12a5_binding.gd").install(session.world)
		notice.text="12A.5 DRAFT · A主棺高品质样板"
	DisplayServer.window_set_title("大盗墓时代 · 12A.5 A主棺样板 · Seed522269330 · 隔离内存档")
func run() -> void:
	root.mode=Window.MODE_WINDOWED
	root.size=Vector2i(1280,720)
	root.content_scale_size=Vector2i(1280,720)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_factor=1.0
	await super.run()
	await show_layout(1)
