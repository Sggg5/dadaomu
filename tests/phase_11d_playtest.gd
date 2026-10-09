extends "res://tests/phase_11a_smoke.gd"
## Fixed in-memory test collection. Production profile is never read or written.
func run()->void:
	flow=preload("res://scenes/main/game_flow.tscn").instantiate()
	flow.profile_store=MuseumProfileStore.in_memory()
	flow.profile_store._memory=flow.profile_store.encode(preload("res://tests/fixtures/museum_management_fixture.gd").state_with_displays(500))
	root.add_child(flow)
	await frames(3)
	var daytime=preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
	await daytime.walk_to(Vector2(230,450))
	await daytime.walk_to(flow.museum.office_desk.position+Vector2(0,40))
	DisplayServer.window_set_title("大盗墓时代 · Phase11D 馆长办公室试玩（隔离档 / 500件）")
	flow.museum.message.text="隔离试玩：500件测试馆藏；两厅已布展。办公室E查看/策展/日报。正式玩家存档不读不写。"
