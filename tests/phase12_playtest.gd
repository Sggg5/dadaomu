extends "res://tests/phase_11a_smoke.gd"
## Opens real formal GameFlow via actual map UI, entirely memory-only.
func run() -> void:
	ArtRenderSettings.initialized = true
	ArtRenderSettings.mode = ArtRenderSettings.Mode.ENHANCED
	flow = preload("res://scenes/main/game_flow.tscn").instantiate()
	flow.profile_store = MuseumProfileStore.in_memory(); flow.campaign_seed_override = 52
	root.add_child(flow); await frames(5)
	var day = preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
	await day.walk_to(Vector2(940,450)); await day.walk_to(Vector2(940,210)); await day.walk_to(flow.museum.board.position+Vector2(-40,20))
	key(KEY_E); await frames(3); await choose_region(&"JINBEI"); await choose_row(0)
	await click(flow.museum.expedition_map.confirm_button.get_global_rect().get_center()); await frames(6)
	check(flow.dungeon != null,"Memory-only formal map enters Jinbei")
	DisplayServer.window_set_title("大盗墓时代 · Phase12美术草稿 · Seed522269330 · F6切换旧/基础/光影 · 隔离内存档")
