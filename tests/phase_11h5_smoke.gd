extends "res://tests/phase_5b_smoke.gd"
func run()->void:
	var state:=preload("res://tests/fixtures/museum_management_fixture.gd").state_with_displays(50);state.cash=50000
	var initial:=state.cash
	for item in state.collection.all_items():
		if not item.identified:state.identify(item.instance_id)
		if item.condition<100:state.repair(item.instance_id)
	# Actual provenance fixture, separate from real regional GameFlow coverage in phase11b.
	for id in [&"ly_attendant",&"ly_wuzhu",&"ly_granary",&"ly_bronze_mirror",&"ly_jade_pendant"]:
		if MuseumState.POOL.find_by_id(id)==null:continue
		state.collection.add(id,1,100,true,{"site_id":"LUOYANG_EAST","region_id":"LUOYANG","run_seed":33,"expedition_day":1})
	# Resolve known formal local IDs from registry if fixture names differ.
	var local_ids:Array=SiteRegistry.load_default().loot_profiles[1].local_ids
	for id in local_ids.slice(0,5):state.collection.add(StringName(id),1,100,true,{"site_id":"LUOYANG_EAST","region_id":"LUOYANG","run_seed":33,"expedition_day":1})
	var ids:Array[StringName]=[]
	for item in state.collection.all_items():ids.append(item.instance_id)
	for unit in state.display_catalog.unit_ids(state.museum_level):state.fill_unit(unit,ids)
	for unit in state.display_catalog.unit_ids(state.museum_level):
		if not state.unit_items(unit).is_empty():MuseumConstructionService.purchase(state,MuseumConstructionService.quote(state,StringName(str(unit)+":PROTECT")))
	MuseumStaffService.hire(state,&"APPRAISER_SHEN");MuseumStaffService.hire(state,&"CONSERVATOR_SU")
	var unique:Dictionary={};var research_ids:Array[StringName]=[]
	for item in state.collection.all_items():
		if unique.has(item.definition_id):continue
		unique[item.definition_id]=true;MuseumResearchService.register(state,item.instance_id)
		if research_ids.size()<20:research_ids.append(item.instance_id);MuseumStaffTasks.enqueue(state,&"APPRAISER_SHEN",item.instance_id,&"RESEARCH",2)
	ExhibitionService.start(state,&"MAIN",&"HAN_WEI");ExhibitionService.start(state,&"EAST",&"COINS")
	var museum:=Museum.new();museum.state=state;museum.config=MuseumConfig.new();museum.config.open_duration=4;museum.config.staff_task_time_scale=.02;museum.config.visitor_speed=1800;museum.config.view_duration=.02;root.add_child(museum);await frames(3)
	var opening_cash:=state.cash;var gross:=0;var wages:=0;var maintenance:=0;var repairs:=0
	for day in range(1,31):
		state.day_number=day;state.phase=MuseumState.Phase.MORNING
		if day==12:
			check(MuseumStaffTasks.enqueue(state,&"APPRAISER_SHEN",research_ids[0],&"RESEARCH",3)!=null,"Actual related artifacts make topic research reachable")
		for item in state.collection.all_items():
			if state.case_for(item.instance_id)!=&"" and MuseumCollectionCare.environment(state,item.instance_id).protect_level>0 and MuseumCollectionCare.due(state,item.instance_id):
				MuseumStaffTasks.enqueue(state,&"CONSERVATOR_SU",item.instance_id,&"INSPECT")
		check(museum.business.start(),"Real business opens day %d"%day);await frames(600)
		var report:Dictionary=state.daily_reports[day];gross+=report.ticket_income;wages+=report.staff_wages_paid;maintenance+=report.maintenance_paid;repairs+=report.staff_repair_fees
		var visitors_before:int=MuseumDailyReport.totals(state).visitors;var snapshot:=state.achievements.duplicate(true)
		var duplicate:=MuseumDailyReport.new();duplicate.values=report.duplicate(true)
		check(not MuseumDailyReport.store(state,duplicate) and MuseumDailyReport.totals(state).visitors==visitors_before and state.achievements==snapshot,"Same dated report cannot repeat visitors or honors")
	check(state.cash==opening_cash+gross-wages-maintenance-repairs,"Thirty business days preserve exact original economics")
	check(initial>opening_cash and wages>0 and maintenance>0,"Legal acquisition/repair/construction/payroll costs remain separate")
	var m:=MuseumMilestoneService.metrics(state)
	for goal in MuseumMilestoneDefinition.goals():check(state.achievements.has(goal.id),"Actual workflow reaches goal: "+goal.id)
	var eval:=MuseumReputationService.evaluate(state)
	check(eval.rank==3 and eval.metrics.identified>=30 and eval.metrics.researched>=15,"High rating collection/research conditions are attainable")
	var store:=MuseumProfileStore.in_memory();check(store.save_profile(state),"Thirty day V10 saves after real closure")
	var loaded:=store.load_profile();check(not store.write_blocked and store.encode(loaded)==store.encode(state),"Thirty day achievements finance research exact roundtrip")
	var file:=FileAccess.open("res://logs/11h_30days.json",FileAccess.WRITE);file.store_string(JSON.stringify({"days":30,"opening_cash":opening_cash,"gross":gross,"wages":wages,"maintenance":maintenance,"repairs":repairs,"cash":state.cash,"rank":eval.rank,"score":eval.score,"metrics":m,"achievements":state.achievements}));file.close()
	museum.queue_free();await frames(3)
	print("[11H5] %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
