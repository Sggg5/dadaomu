extends "res://tests/phase_11a_smoke.gd"
func capture(label:String)->void:
	if DisplayServer.get_name()=="headless":return
	RenderingServer.force_draw();root.get_texture().get_image().save_png("res://logs/11g_%s.png"%label)
func run()->void:
	flow=preload("res://scenes/main/game_flow.tscn").instantiate();flow.profile_store=MuseumProfileStore.in_memory()
	var fixture:=preload("res://tests/fixtures/museum_management_fixture.gd").state_with_displays(100);fixture.cash=20000
	MuseumStaffService.hire(fixture,&"APPRAISER_SHEN");MuseumStaffService.hire(fixture,&"CONSERVATOR_SU")
	MuseumConstructionService.purchase(fixture,MuseumConstructionService.quote(fixture,&"CASE_2:PROTECT"))
	flow.profile_store._memory=flow.profile_store.encode(fixture)
	flow.museum_config=MuseumConfig.new();flow.museum_config.open_duration=25;flow.museum_config.staff_task_time_scale=.02;flow.museum_config.visitor_speed=1200;flow.museum_config.view_duration=.05
	root.add_child(flow);await frames(3)
	DisplayServer.window_set_title("大盗墓时代 · Phase11G 研究档案图形专项（隔离档）")
	var driver=preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
	await driver.walk_to(Vector2(940,450));await driver.walk_to(Vector2(940,230));await driver.walk_to(flow.museum.research_desk.position+Vector2(0,40))
	capture("research_desk");key(KEY_E);await frames(3)
	var panel:=flow.museum.codex_panel
	check(panel.panel.visible and panel.dossier_id==&"A000001","Real research table E opens actual individual dossier")
	capture("independent_dossier")
	await click(panel.register_button.get_global_rect().get_center())
	check(flow.museum_state.collection.archives[&"A000001"].level==1,"Mouse manually registers first actual artifact")
	await click(panel.research_button.get_global_rect().get_center())
	check(flow.museum_state.staff.tasks.size()==1 and flow.museum_state.staff.tasks[0].action()==&"RESEARCH","Mouse queues real staff research")
	capture("research_task")
	key(KEY_TAB);await frames(3)
	await driver.walk_to(Vector2(1080,540));key(KEY_E);await frames(600)
	check(flow.museum.business.workday.prepared.size()==1 and flow.museum_state.collection.archives[&"A000001"].level==1,"Actual OPEN prepares research without early reward")
	flow.museum.business.close_now();await frames(240)
	check(flow.museum_state.collection.archives[&"A000001"].level==2,"Real closure unlocks type content")
	await driver.walk_to(Vector2(940,450));await driver.walk_to(Vector2(940,230));await driver.walk_to(flow.museum.research_desk.position+Vector2(0,40));key(KEY_E);await frames(3)
	capture("research_completed")
	panel.employee_choice.select(panel.employee_ids.find(&"CONSERVATOR_SU"));panel.employee_choice.item_selected.emit(panel.employee_choice.selected);await frames(3)
	await click(panel.inspection_button.get_global_rect().get_center())
	check(flow.museum_state.staff.tasks.size()==2 and flow.museum_state.staff.tasks[1].action()==&"INSPECT","Real selected conservator receives inspection")
	capture("inspection_queued");key(KEY_TAB);await frames(3)
	# Isolated simulation advances a real next business day without changing production time.
	flow.museum_state.day_number=2;flow.museum_state.phase=MuseumState.Phase.MORNING
	await driver.walk_to(Vector2(1080,540));key(KEY_E);await frames(600);flow.museum.business.close_now();await frames(240)
	check(flow.museum_state.collection.archives[&"A000001"].events[-1].kind=="INSPECTION","Actual second workday produces dated inspection")
	var before:=flow.museum_state.collection.find(&"A000001").condition
	var cost:=flow.museum_state.restoration_cost(&"A000001");var cash:=flow.museum_state.cash
	await driver.walk_to(Vector2(940,450));await driver.walk_to(Vector2(940,230));await driver.walk_to(Vector2(730,230));key(KEY_E);await frames(3)
	await click(flow.museum.restoration_panel.confirm_button.get_global_rect().get_center());await frames(3)
	key(KEY_TAB);await frames(3)
	check(flow.museum_state.collection.find(&"A000001").condition==100 and flow.museum_state.cash==cash-cost and before<100,"Actual repair table E charges once and logs real before state")
	await driver.walk_to(Vector2(940,450));await driver.walk_to(Vector2(940,230));await driver.walk_to(flow.museum.research_desk.position+Vector2(0,40));key(KEY_E);await frames(3)
	panel.detail.get_v_scroll_bar().value=panel.detail.get_v_scroll_bar().max_value*.35;await frames(3)
	capture("care_restoration_history")
	check("费用" in panel.detail.text and "保护检查" in panel.detail.text,"Individual dossier displays both real histories")
	key(KEY_TAB);await frames(3)
	await driver.walk_to(Vector2(640,450));await driver.walk_to(Vector2(640,350));key(KEY_E);await frames(3)
	var collection_panel:=flow.museum.collection_panel
	check(collection_panel.panel.visible and collection_panel.case_id==&"CASE_2","Real E opens expected combined unit")
	for button in collection_panel.panel.find_children("*","Button",true,false):
		if button.text=="研究说明牌":await click(button.get_global_rect().get_center())
	await frames(3)
	check("游戏原型" in collection_panel.research_text.text,"Actual display unit reveals researched label without price bonus")
	capture("display_research_label");key(KEY_TAB);await frames(3)
	await driver.walk_to(Vector2(940,450));await driver.walk_to(Vector2(940,230));await driver.walk_to(flow.museum.research_desk.position+Vector2(0,40));key(KEY_E);await frames(3)
	panel.set_mode(1);await frames(3);capture("global_readonly")
	check(not panel.dossier_actions.visible,"Global research cannot mutate ownership")
	key(KEY_TAB);await frames(3);flow.queue_free();flow=null;driver=null;await frames(5)
	print("[11G graphical] %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
