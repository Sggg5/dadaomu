extends "res://tests/phase_7b_smoke.gd"
const FLOW_SCENE: PackedScene = preload("res://scenes/main/game_flow.tscn")
var flow: GameFlow


func capture(name: String) -> void:
	if DisplayServer.get_name() != "headless" and "--capture" in OS.get_cmdline_user_args():
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://logs/phase_8a_%s.png" % name)


func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://logs")
	var data = preload("res://tests/phase_8a_data_checks.gd").new(self)
	await data.run()
	var hub = preload("res://tests/phase_8a_hub_checks.gd").new(self)
	await hub.run()
	var first_exhibit = preload("res://tests/phase_8a_first_exhibit_checks.gd").new(self)
	await first_exhibit.run()
	flow = FLOW_SCENE.instantiate() as GameFlow
	# 旧功能固定Run夹具；正式派生Seed由9A专项另外覆盖。
	flow.forced_night_seed = 192034
	flow.campaign_seed_override = 52
	# 历史回归使用原主图夹具；Phase9A单独覆盖正式探索入口。
	flow.tomb_exploration_enabled = false
	flow.profile_store = MuseumProfileStore.in_memory()
	# 真实布展流程的测试夹具，不能依赖正式入口赠送馆藏。
	flow.initial_test_collection = true
	var config := MuseumConfig.new()
	config.open_duration = 5
	config.visitor_speed = 1200
	config.view_duration = 2
	flow.museum_config = config
	root.add_child(flow)
	current_scene = flow
	await frames(3)
	var helper = preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
	await helper.run()
	flow.queue_free()
	await frames(3)
	print("[Phase 8A] %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
