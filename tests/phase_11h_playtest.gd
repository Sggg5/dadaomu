extends "res://tests/phase_11a_smoke.gd"
## Explicit isolated fixture. No disk profile, no reading user://.
func run()->void:
	flow=preload("res://scenes/main/game_flow.tscn").instantiate();flow.profile_store=MuseumProfileStore.in_memory()
	var fixture:=preload("res://tests/fixtures/museum_management_fixture.gd").state_with_displays(100);fixture.cash=12000
	MuseumStaffService.hire(fixture,&"APPRAISER_SHEN")
	var id:=fixture.collection.all_items()[0].instance_id;MuseumResearchService.register(fixture,id);MuseumStaffTasks.enqueue(fixture,&"APPRAISER_SHEN",id,&"RESEARCH",2)
	flow.profile_store._memory=flow.profile_store.encode(fixture);root.add_child(flow);await frames(3)
	var driver=preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
	await driver.walk_to(Vector2(115,540));await driver.walk_to(Vector2(115,390))
	DisplayServer.window_set_title("大盗墓时代 · Phase11H 荣誉墙试玩（隔离馆藏与资金，不读写正式档）")
	flow.museum.message.text="荣誉墙隔离试玩：100件测试馆藏、实际专题与纪念荣誉。E查看图鉴/评级；研究任务可通过开馆完成。"
	await frames(3)
	if DisplayServer.get_name()!="headless":RenderingServer.force_draw();root.get_texture().get_image().save_png("res://logs/11h_isolated_window.png")
	print("[11H playtest ready] isolated artifacts=%d honors=%d"%[fixture.collection.all_items().size(),fixture.achievements.size()])
