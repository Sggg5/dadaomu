extends "res://tests/phase_11a_smoke.gd"
## Explicit isolated collection/funds. No formal profile is ever accessed.
func run()->void:
	flow=preload("res://scenes/main/game_flow.tscn").instantiate()
	flow.profile_store=MuseumProfileStore.in_memory()
	var fixture:=preload("res://tests/fixtures/museum_management_fixture.gd").state_with_displays(100)
	fixture.cash=12000
	flow.profile_store._memory=flow.profile_store.encode(fixture)
	root.add_child(flow);await frames(3)
	var driver=preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
	await driver.walk_to(Vector2(340,450));await driver.walk_to(Vector2(340,230));await driver.walk_to(flow.museum.construction.position+Vector2(0,40))
	DisplayServer.window_set_title("大盗墓时代 · Phase11E 设施建设试玩（隔离档 / 资金12000）")
	flow.museum.message.text="隔离建设试玩：100件测试馆藏，资金12000。建设牌E→设施建设；办公室也可进入。正式档不读不写。"
