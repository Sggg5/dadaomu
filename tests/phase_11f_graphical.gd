extends "res://tests/phase_11a_smoke.gd"
func capture(label:String)->void:
	if DisplayServer.get_name()=="headless":return
	RenderingServer.force_draw();root.get_texture().get_image().save_png("res://logs/11f_%s.png"%label)
func select_staff(id:StringName)->void:
	var view:=flow.museum.office_panel.staff_view
	var index:=view.ids.find(id)
	await click(view.employees.get_global_rect().position+view.employees.get_item_rect(index).get_center())
	check(view.selected_id()==id,"Real personnel click selects "+str(id))
func run()->void:
	flow=preload("res://scenes/main/game_flow.tscn").instantiate();flow.profile_store=MuseumProfileStore.in_memory()
	var fixture:=preload("res://tests/fixtures/museum_management_fixture.gd").state_with_displays(100);fixture.cash=12000
	flow.profile_store._memory=flow.profile_store.encode(fixture)
	flow.museum_config=MuseumConfig.new();flow.museum_config.open_duration=25;flow.museum_config.visitor_speed=1000;flow.museum_config.view_duration=.1;flow.museum_config.staff_task_time_scale=.05
	root.add_child(flow);await frames(3)
	DisplayServer.window_set_title("大盗墓时代 · Phase11F 员工图形验证（隔离档）")
	var driver=preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
	await driver.walk_to(Vector2(230,450));await driver.walk_to(flow.museum.office_desk.position+Vector2(0,40));key(KEY_E);await frames(3)
	check(flow.museum.office_panel.panel.visible,"Actual E opens office")
	flow.museum.office_panel.tabs.current_tab=7;await frames(3)
	var view:=flow.museum.office_panel.staff_view
	capture("personnel_before")
	for id in [&"GUIDE_LIN",&"APPRAISER_SHEN",&"CONSERVATOR_SU"]:
		await select_staff(id);await click(view.hire.get_global_rect().get_center())
		check(flow.museum_state.staff.members.has(id),"Real hire button employs "+str(id))
	await select_staff(&"APPRAISER_SHEN")
	check(view.artifacts.item_count>0,"Actual owned unidentified items listed")
	await click(view.artifacts.get_global_rect().position+view.artifacts.get_item_rect(0).get_center())
	await click(view.submit.get_global_rect().get_center())
	await select_staff(&"CONSERVATOR_SU")
	await click(view.artifacts.get_global_rect().position+view.artifacts.get_item_rect(0).get_center())
	await click(view.submit.get_global_rect().get_center())
	check(flow.museum_state.staff.tasks.size()==2,"Mouse queues actual appraisal and repair")
	capture("queued_tasks")
	key(KEY_TAB);await frames(3)
	await driver.walk_to(Vector2(1080,540));key(KEY_E);await frames(550)
	check(flow.museum.business.workday.paid_ids.size()==3,"Real ticket opening pays and locks attendance")
	check(flow.museum.business.visits.staff_guides.get("GUIDE_LIN",0)>0,"Actual guide NPC serves real visitors")
	capture("guide_visitors")
	await driver.walk_to(Vector2(230,450));await driver.walk_to(flow.museum.office_desk.position+Vector2(0,40));key(KEY_E);await frames(3)
	flow.museum.office_panel.tabs.current_tab=7;await frames(3)
	check(view.hire.disabled and view.submit.disabled,"OPEN personnel page is read-only")
	capture("open_progress")
	flow.museum.business.close_now();await frames(240);flow.museum.office_panel.refresh()
	check(flow.museum_state.staff.tasks[0].status==&"COMPLETED" and flow.museum_state.staff.tasks[1].status==&"COMPLETED","Actual closure applies both staff jobs")
	capture("closed_results")
	flow.museum.office_panel.tabs.current_tab=2;await frames(3);capture("finance")
	key(KEY_TAB);await frames(3);flow.queue_free();flow=null;driver=null;await frames(5)
	print("[11F graphical] %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
