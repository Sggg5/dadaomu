extends "res://tests/phase_11a_smoke.gd"
func capture(label:String)->void:
	if DisplayServer.get_name()=="headless":return
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://logs/11e_%s.png"%label)
func select_facility(id:StringName)->void:
	var view:=flow.museum.facility_panel.view
	var index:=view.ids.find(id)
	check(index>=0,"Blueprint lists stable facility "+str(id))
	await click(view.list.get_global_rect().position+view.list.get_item_rect(index).get_center())
func buy_levels(id:StringName,count:int)->void:
	await select_facility(id)
	var view:=flow.museum.facility_panel.view
	check(view.request!=null and view.request.facility_id==id,"Actual clicked row binds expected facility "+str(id))
	for level in range(count):
		if level>0:await click(view.next_quote.get_global_rect().get_center())
		await click(view.buy.get_global_rect().get_center())
		await frames(3)
		check(flow.museum_state.facilities.level(id)==level+1,"Actual mouse facility upgrade "+str(id)+" / "+str(level+1))
func run()->void:
	flow=preload("res://scenes/main/game_flow.tscn").instantiate()
	flow.profile_store=MuseumProfileStore.in_memory()
	var fixture:=preload("res://tests/fixtures/museum_management_fixture.gd").state_with_displays(100)
	fixture.cash=12000
	flow.profile_store._memory=flow.profile_store.encode(fixture)
	flow.museum_config=MuseumConfig.new();flow.museum_config.open_duration=20;flow.museum_config.visitor_speed=1000;flow.museum_config.view_duration=.2
	root.add_child(flow);await frames(3)
	DisplayServer.window_set_title("大盗墓时代 · Phase11E 建设图形专项（隔离档）")
	var driver=preload("res://tests/phase_8a_flow_checks.gd").new(self,flow)
	await driver.walk_to(Vector2(640,450));await driver.walk_to(Vector2(640,390))
	capture("case_before")
	await driver.walk_to(Vector2(640,450));await driver.walk_to(Vector2(340,450));await driver.walk_to(Vector2(340,230));await driver.walk_to(flow.museum.construction.position+Vector2(0,40))
	key(KEY_E);await frames(3)
	await click((flow.museum.construction_panel.panel.get_child(1) as Button).get_global_rect().get_center())
	await frames(3)
	var view:=flow.museum.facility_panel.view
	view.hall_filter.select(1);view.hall_filter.item_selected.emit(1)
	await frames(4)
	await buy_levels(&"CASE_2:LIGHT",3)
	await buy_levels(&"CASE_2:BASE",3)
	await buy_levels(&"CASE_2:LABEL",3)
	await buy_levels(&"CASE_2:PROTECT",3)
	capture("blueprint_upgrade")
	await buy_levels(&"MAIN_GUIDE",1)
	await buy_levels(&"MAIN_RECEPTION",1)
	view.hall_filter.select(2);view.hall_filter.item_selected.emit(2)
	await frames(4)
	await buy_levels(&"EAST_REST",1)
	key(KEY_TAB);await frames(3)
	await driver.walk_to(Vector2(340,230));await driver.walk_to(Vector2(340,450));await driver.walk_to(Vector2(640,450));await driver.walk_to(Vector2(640,390))
	capture("case_after")
	flow.museum.switch_hall(&"EAST");await frames(3);capture("rest_area")
	flow.museum.switch_hall(&"MAIN");await frames(3);capture("public_main")
	await driver.walk_to(Vector2(1080,540));key(KEY_E);await frames(900)
	check(flow.museum.business.visits.services.size()==3,"Real upgraded guide rest and reception use all record")
	capture("services_in_use")
	flow.museum.business.close_now();await frames(220)
	var report:Dictionary=flow.museum_state.daily_reports[1]
	check(report.maintenance_paid>0 and report.operating_net_income==report.ticket_income-report.maintenance_paid,"Graphical business reports gross maintenance and net correctly")
	await driver.walk_to(Vector2(230,450));await driver.walk_to(flow.museum.office_desk.position+Vector2(0,40));key(KEY_E);await frames(3)
	flow.museum.office_panel.tabs.current_tab=6;await frames(3);capture("office_facilities")
	flow.museum.office_panel.tabs.current_tab=4;await frames(3);capture("operating_report")
	flow.museum.office_panel.tabs.current_tab=2;await frames(3);capture("finance")
	key(KEY_TAB);await frames(3)
	flow.queue_free();flow=null;driver=null;await frames(5)
	print("[11E graphical] %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
