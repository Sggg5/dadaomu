extends "res://tests/phase_11a_smoke.gd"
func capture(label:String)->void:
	if DisplayServer.get_name()=="headless":return
	RenderingServer.force_draw();root.get_texture().get_image().save_png("res://logs/11h_%s.png"%label)
func run()->void:
	flow=preload("res://scenes/main/game_flow.tscn").instantiate();flow.profile_store=MuseumProfileStore.in_memory()
	var fixture:=preload("res://tests/fixtures/museum_management_fixture.gd").state_with_displays(100);fixture.cash=20000
	MuseumStaffService.hire(fixture,&"APPRAISER_SHEN")
	var id:=fixture.collection.all_items()[0].instance_id;MuseumResearchService.register(fixture,id);MuseumStaffTasks.enqueue(fixture,&"APPRAISER_SHEN",id,&"RESEARCH",2)
	flow.profile_store._memory=flow.profile_store.encode(fixture)
	flow.museum_config=MuseumConfig.new();flow.museum_config.open_duration=5;flow.museum_config.staff_task_time_scale=.02;flow.museum_config.visitor_speed=1800;flow.museum_config.view_duration=.02
	root.add_child(flow);await frames(3)
	DisplayServer.window_set_title("大盗墓时代 · Phase11H 荣誉图鉴真实图形专项（隔离）")
	var driver=preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
	await driver.walk_to(Vector2(115,540));await driver.walk_to(Vector2(115,390));capture("honor_wall")
	key(KEY_E);await frames(3)
	var panel:=flow.museum.reputation_panel
	check(panel.panel.visible and panel.tabs.current_tab==2,"Real honor wall E opens earned honors/goals")
	var before:=flow.museum_state.achievements.duplicate(true);capture("milestones")
	await click(panel.tabs.get_tab_bar().global_position+panel.tabs.get_tab_bar().get_tab_rect(0).get_center());await frames(3);capture("rating")
	check(panel.tabs.current_tab==0 and MuseumReputationService.evaluate(flow.museum_state).title in panel.overview.text and "有据营业日：0" in panel.overview.text,"Mouse opens actual operating evaluation")
	await click(panel.tabs.get_tab_bar().global_position+panel.tabs.get_tab_bar().get_tab_rect(1).get_center());await frames(3);capture("collection_codex")
	check(panel.catalog_list.item_count<=20 and panel.rows.size()==50 and "50" in panel.heading.text,"Real fifty-object codex paginates")
	check(before==flow.museum_state.achievements,"Read-only mouse navigation never awards honors")
	await click(panel.dossier.get_global_rect().get_center());await frames(3)
	check(flow.museum.codex_panel.panel.visible and not panel.panel.visible,"Real codex opens held accession dossier")
	capture("accession_link");key(KEY_TAB);await frames(3)
	await driver.walk_to(Vector2(115,230));await driver.walk_to(Vector2(230,230));key(KEY_E);await frames(3)
	check(flow.museum.office_panel.panel.visible,"Original office E remains functional")
	capture("office_groups")
	for b in flow.museum.office_panel.panel.find_children("*","Button",true,false):
		if b.text=="荣誉 / 收藏":await click(b.get_global_rect().get_center());break
	check(panel.panel.visible and not flow.museum.office_panel.panel.visible,"Office grouped honor shortcut opens same service-based ledger")
	key(KEY_TAB);await frames(3)
	check(flow.museum.player.controls_enabled,"Closing grouped ledger restores real movement")
	await driver.walk_to(Vector2(230,450));await driver.walk_to(Vector2(1080,540));key(KEY_E);await frames(700)
	check(flow.museum_state.daily_reports.size()==1 and flow.museum_state.achievements.has("FIRST_BUSINESS") and flow.museum_state.achievements.has("FIRST_RESEARCH"),"Real paid business closure awards unique business and staff research honors")
	await driver.walk_to(Vector2(115,540));await driver.walk_to(Vector2(115,390));key(KEY_E);await frames(3);capture("earned_honors")
	flow.queue_free();flow=null;driver=null;await frames(5)
	print("[11H graphical] %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
