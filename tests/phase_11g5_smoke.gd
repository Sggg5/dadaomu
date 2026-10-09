extends "res://tests/phase_5b_smoke.gd"
func run()->void:
	for count in [50,100,500]:
		var state:=preload("res://tests/fixtures/museum_management_fixture.gd").state_with_displays(count);state.cash=20000
		var museum:=Museum.new();museum.state=state;museum.config=MuseumConfig.new();root.add_child(museum);await frames(3)
		museum.codex_panel.open()
		check(museum.codex_panel.list.item_count<=40 and museum.codex_panel.result_ids.size()==count,"Actual dossier panel paginates %d owned items"%count)
		check("来源未记录" in museum.codex_panel.detail.text,"Missing old provenance never fabricated in UI")
		museum.queue_free();await frames(3)
	var state:=preload("res://tests/fixtures/museum_management_fixture.gd").state_with_displays(50);state.cash=20000
	MuseumStaffService.hire(state,&"APPRAISER_SHEN");MuseumStaffService.hire(state,&"CONSERVATOR_SU")
	MuseumConstructionService.purchase(state,MuseumConstructionService.quote(state,&"CASE_2:PROTECT"))
	var investment:=MuseumConstructionService.capital_today(state);var hire:=260
	var research_ids:Array[StringName]=[]
	for id in [&"ly_attendant",&"ly_granary",&"ly_attendant"]:
		var item:=state.collection.add(id,1,80,true);research_ids.append(item.instance_id);MuseumResearchService.register(state,item.instance_id)
		MuseumStaffTasks.enqueue(state,&"APPRAISER_SHEN",item.instance_id,&"RESEARCH",2)
	var inspected:=state.collection.find(state.display_assignments[&"CASE_2"])
	MuseumStaffTasks.enqueue(state,&"CONSERVATOR_SU",inspected.instance_id,&"INSPECT")
	var museum:=Museum.new();museum.state=state;museum.config=MuseumConfig.new();museum.config.open_duration=4;museum.config.staff_task_time_scale=.02;museum.config.visitor_speed=1800;museum.config.view_duration=.02
	root.add_child(museum);await frames(3)
	var gross:=0;var maintenance:=0;var wages:=0;var repairs:=0
	for day in range(1,31):
		state.day_number=day;state.phase=MuseumState.Phase.MORNING
		if day==2:MuseumStaffTasks.enqueue(state,&"CONSERVATOR_SU",inspected.instance_id)
		if day==3:check(MuseumStaffTasks.enqueue(state,&"APPRAISER_SHEN",research_ids[0],&"RESEARCH",3)!=null,"Three real researched objects unlock topic queue")
		check(museum.business.start(),"Actual research business starts day %d"%day);await frames(600)
		var r:Dictionary=state.daily_reports[day]
		gross+=r.ticket_income;maintenance+=r.maintenance_paid;wages+=r.staff_wages_paid;repairs+=r.staff_repair_fees
		check(r.staff_wages_paid==32 and r.operating_net_income==r.ticket_income-r.maintenance_paid-32,"Research day locks original wages and operating net")
	check(state.cash==20000-hire-investment+gross-maintenance-wages-repairs,"Thirty day research finance exact reconciliation")
	check(state.collection.archives[research_ids[0]].level==3,"Real multi-day type and topic work completed")
	check(MuseumCollectionCare.due(state,inspected.instance_id),"Thirty business days produce advisory due state without damage")
	check(inspected.condition==100,"Inspection never causes passive deterioration")
	var stats:={"days":30,"gross":gross,"maintenance":maintenance,"wages":wages,"repairs":repairs,"hire":hire,"investment":investment,"cash":state.cash}
	var file:=FileAccess.open("res://logs/11g_30days.json",FileAccess.WRITE);file.store_string(JSON.stringify(stats));file.close()
	var store:=MuseumProfileStore.in_memory();check(store.save_profile(state),"Research payroll and history save after closure")
	var loaded:=store.load_profile();check(not store.write_blocked and store.encode(loaded)==store.encode(state),"Topic research inspection and repair disk-value roundtrip")
	state.withdraw_unit(&"CASE_2");var old_interval:int=MuseumCollectionCare.environment(state,inspected.instance_id).interval
	check(old_interval==3 and state.collection.archives[inspected.instance_id].events.size()>0,"Moving to storage updates environment but retains instance history")
	check(state.sell_to_dealer(inspected.instance_id) and "不再持有" in MuseumDossierText.format(state,inspected.instance_id),"Sold dossier clearly unowned and cannot participate")
	museum.queue_free();await frames(3)
	print("[11G5] %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)

