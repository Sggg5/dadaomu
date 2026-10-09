extends SceneTree
## Always memory-only. --midgame reads an earned automated QA snapshot, not a user save.
var flow:GameFlow
func _initialize()->void:call_deferred("start")
func start()->void:
	flow=preload("res://scenes/main/game_flow.tscn").instantiate()
	flow.profile_store=MuseumProfileStore.in_memory()
	flow.campaign_seed_override=52
	if "--midgame" in OS.get_cmdline_user_args():
		var source:=MuseumProfileStore.new();source.save_path="res://tests/fixtures/11i_earned_midgame.json"
		var state:=source.load_profile()
		if source.write_blocked:push_error("隔离中期快照不可用，拒绝换成空档");quit(1);return
		flow.profile_store._memory=source.encode(state)
	root.add_child(flow)
	DisplayServer.window_set_title("大盗墓时代 · Phase11I " + ("自动实际游玩所得中期档" if "--midgame" in OS.get_cmdline_user_args() else "Day1空新档") + "（内存隔离，不读写正式玩家档）")
