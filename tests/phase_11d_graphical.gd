extends "res://tests/phase_11a_smoke.gd"
func capture(label:String)->void:
	if DisplayServer.get_name()=="headless":return
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://logs/11d_%s.png"%label)
func run()->void:
	flow=preload("res://scenes/main/game_flow.tscn").instantiate()
	flow.profile_store=MuseumProfileStore.in_memory()
	flow.museum_config=MuseumConfig.new()
	flow.museum_config.visitor_speed=800
	flow.museum_config.open_duration=20
	flow.museum_config.view_duration=.5
	flow.profile_store._memory=flow.profile_store.encode(preload("res://tests/fixtures/museum_management_fixture.gd").state_with_displays(500))
	root.add_child(flow)
	await frames(3)
	DisplayServer.window_set_title("大盗墓时代 · Phase11D 图形专项（隔离档）")
	var daytime=preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
	await daytime.walk_to(Vector2(230,450))
	await daytime.walk_to(flow.museum.office_desk.position+Vector2(0,40))
	capture("office_desk")
	key(KEY_E)
	await frames(3)
	check(flow.museum.office_panel.panel.visible,"Real WASD and E open director office")
	capture("office_overview")
	for tab in range(6):
		var tab_bar:=flow.museum.office_panel.tabs.get_tab_bar()
		await click(tab_bar.get_global_rect().position+tab_bar.get_tab_rect(tab).get_center())
		await frames(3)
		check(flow.museum.office_panel.tabs.current_tab==tab,"Actual mouse selects office tab "+str(tab))
		capture("office_tab"+str(tab))
	var panel:=flow.museum.office_panel
	panel.tabs.current_tab=5
	panel.topic_hall.select(0)
	panel.topic_select.select(1)
	panel._refresh_topic()
	await click(panel.topic_start.get_global_rect().get_center())
	await frames(3)
	check(flow.museum_state.exhibition_plans[&"MAIN"]==&"TANG_SILK","Actual button replaces hall topic with displayed Tang objects")
	capture("tang_exhibition")
	key(KEY_TAB)
	await frames(3)
	await daytime.walk_to(Vector2(230,450))
	await daytime.walk_to(Vector2(1080,540))
	key(KEY_E)
	await frames(4)
	check(flow.current_phase==MuseumState.Phase.OPEN,"Actual ticket E starts themed museum")
	for frame in range(600):
		if flow.museum.business.visits.view_count>0:break
		await frames(1)
	check(flow.museum.business.visits.view_count>0,"Real visitors watch legal combination cabinets")
	capture("visitors_main")
	await daytime.walk_to(Vector2(230,450))
	await daytime.walk_to(flow.museum.office_desk.position+Vector2(0,40))
	key(KEY_E)
	await frames(3)
	panel.tabs.current_tab=5
	check(flow.current_phase==MuseumState.Phase.OPEN and panel.topic_start.disabled and panel.topic_stop.disabled,"Actual OPEN office permits read only and disables topic changes")
	capture("office_readonly")
	key(KEY_TAB)
	await frames(3)
	for frame in range(300):
		if flow.museum.business.visits.hall_visits.has("EAST"):break
		await frames(1)
	check(flow.museum.business.visits.hall_visits.has("EAST"),"Actual off-screen hall visits survive lazy facility loading")
	flow.museum.switch_hall(&"EAST")
	await frames(10)
	capture("visitors_east")
	flow.museum.switch_hall(&"MAIN")
	flow.museum.business.close_now()
	await frames(300)
	check(flow.museum_state.daily_reports.size()==1 and not flow.museum.business.running,"Real completed business creates one persisted report")
	var read:=flow.profile_store.load_profile()
	check(not flow.profile_store.write_blocked and read.daily_reports.size()==1,"GameFlow autosaves completed management data")
	await daytime.walk_to(Vector2(230,450))
	await daytime.walk_to(flow.museum.office_desk.position+Vector2(0,40))
	key(KEY_E)
	await frames(3)
	panel.tabs.current_tab=4
	await frames(3)
	capture("daily_report")
	panel.tabs.current_tab=3
	await frames(3)
	capture("visitor_feedback")
	panel.tabs.current_tab=2
	await frames(3)
	capture("finance_settled")
	key(KEY_TAB)
	await frames(3)
	flow.queue_free()
	flow=null
	daytime=null
	await frames(5)
	print("[11D graphical] %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
