extends "res://tests/phase_11a_smoke.gd"
## Explicit QA state. Never reads user:// or writes a real player profile.
func run()->void:
	flow=preload("res://scenes/main/game_flow.tscn").instantiate();flow.profile_store=MuseumProfileStore.in_memory()
	var fixture:=preload("res://tests/fixtures/museum_management_fixture.gd").state_with_displays(100);fixture.cash=12000
	for id in [&"GUIDE_LIN",&"APPRAISER_SHEN",&"CONSERVATOR_SU"]:MuseumStaffService.hire(fixture,id)
	MuseumResearchService.register(fixture,&"A000001")
	MuseumStaffTasks.enqueue(fixture,&"APPRAISER_SHEN",&"A000001",&"RESEARCH",2)
	MuseumStaffTasks.enqueue(fixture,&"CONSERVATOR_SU",&"A000002",&"INSPECT")
	flow.profile_store._memory=flow.profile_store.encode(fixture)
	root.add_child(flow);await frames(3)
	var driver=preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
	await driver.walk_to(Vector2(940,450));await driver.walk_to(Vector2(940,230));await driver.walk_to(flow.museum.research_desk.position+Vector2(0,40));key(KEY_E);await frames(3)
	DisplayServer.window_set_title("大盗墓时代 · Phase11G 馆藏研究试玩（隔离馆藏与资金，不读写正式档）")
	flow.museum.message.text="研究隔离试玩：100件测试馆藏，3名员工，研究与检查任务。Tab合档，售票台E开馆；任务闭馆生效。"

	await frames(3)
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw();root.get_texture().get_image().save_png("res://logs/11g_isolated_window.png")
	print("[11G playtest ready] isolated staff=%d tasks=%d cash=%d"%[flow.museum_state.staff.active_count(),flow.museum_state.staff.tasks.size(),flow.museum_state.cash])
