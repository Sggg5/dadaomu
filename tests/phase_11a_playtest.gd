extends "res://tests/phase_11a_smoke.gd"
## Isolated human acceptance: real formal GameFlow, no gifts, no production save writes.
func run()->void:
	flow=preload("res://scenes/main/game_flow.tscn").instantiate()
	flow.profile_store=MuseumProfileStore.in_memory()
	flow.campaign_seed_override=52
	root.add_child(flow)
	await frames(3)
	var driver=preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
	await driver.walk_to(Vector2(940,450))
	await driver.walk_to(Vector2(940,210))
	await driver.walk_to(flow.museum.board.position+Vector2(-40,20))
	key(KEY_E)
	await frames(3)
	DisplayServer.window_set_title("大盗墓时代 · Phase11A 远征地图试玩（隔离档 / Campaign52）")
	capture("manual_ready")
