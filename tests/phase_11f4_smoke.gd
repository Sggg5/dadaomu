extends "res://tests/phase_5b_smoke.gd"
func run()->void:
	var state:=preload("res://tests/fixtures/museum_management_fixture.gd").state_with_displays(100)
	state.cash=20000
	for id in [&"GUIDE_LIN",&"APPRAISER_SHEN",&"CONSERVATOR_SU"]:MuseumStaffService.hire(state,id)
	var unknown:=state.collection.add(&"ly_attendant",1,70,false)
	var broken:=state.collection.add(&"gz_floral_mirror",1,60,true)
	MuseumStaffTasks.enqueue(state,&"APPRAISER_SHEN",unknown.instance_id)
	MuseumStaffTasks.enqueue(state,&"CONSERVATOR_SU",broken.instance_id)
	var hire:=20000-state.cash
	var museum:=Museum.new();museum.state=state;museum.config=MuseumConfig.new()
	museum.config.open_duration=4;museum.config.visitor_speed=1800;museum.config.view_duration=.03;museum.config.staff_task_time_scale=.02
	root.add_child(museum);await frames(3)
	var gross:=0;var wages:=0;var fees:=0
	for day in range(1,31):
		state.day_number=day;state.phase=MuseumState.Phase.MORNING
		check(museum.business.start(),"Start actual staffed day "+str(day))
		await frames(600)
		check(state.daily_reports.has(day),"Real close stores daily report")
		var r:Dictionary=state.daily_reports[day]
		check(r.staff_wages_paid==42 and r.operating_net_income==r.ticket_income-r.maintenance_paid-42,"Locked wages and operating net reconcile")
		gross+=r.ticket_income;wages+=r.staff_wages_paid;fees+=r.staff_repair_fees
		var cash:=state.cash
		check(not MuseumStaffPayroll.begin(state).wages_paid and state.cash==cash,"Repeated opening payroll never pays twice")
	check(state.cash==20000-hire+gross-wages-fees,"30 real days reconcile separate recruitment repair and payroll")
	var stats:={"days":30,"gross":gross,"wages":wages,"hire":hire,"repair_fees":fees,"cash":state.cash}
	var f:=FileAccess.open("res://logs/11f_30days.json",FileAccess.WRITE);f.store_string(JSON.stringify(stats));f.close()
	var store:=MuseumProfileStore.new();store.save_path="res://logs/11f_v8_%d.json"%Time.get_ticks_usec()
	check(store.save_profile(state),"Isolated V8 profile writes")
	var loaded:=store.load_profile()
	check(not store.write_blocked and store.encode(state)==store.encode(loaded),"V8 disk preserves employees tasks IDs cash display reports")
	var legacy:=store.encode(state);legacy.version=7
	for key in legacy.keys():
		if str(key).begins_with("staff_"):legacy.erase(key)
	for report:Dictionary in legacy.daily_reports:
		for key in report.keys():
			if str(key).begins_with("staff_"):report.erase(key)
		report.operating_net_income=report.ticket_income-report.maintenance_paid
	var migration:=MuseumProfileStore.new();migration.save_path="res://logs/11f_v7_%d.json"%Time.get_ticks_usec()
	f=FileAccess.open(migration.save_path,FileAccess.WRITE);f.store_string(JSON.stringify(legacy));f.close()
	var sha:=FileAccess.get_sha256(migration.save_path)
	var old:=migration.load_profile()
	check(not migration.write_blocked and old.staff.members.is_empty() and old.cash==state.cash and old.display_assignments==state.display_assignments and old.collection.all_items().size()==state.collection.all_items().size(),"V7 migrates without inventing staff or losing assets")
	check(migration.save_profile(old) and FileAccess.get_sha256("%s.v7.%s.backup.json"%[migration.save_path,sha.substr(0,12)])==sha,"V8 first migration write backs up exact old bytes")
	var bad:=store.encode(state);bad.staff_members.append(bad.staff_members[0])
	store.decode(bad);check(store.write_blocked,"Duplicate employee blocks source overwrite")
	bad=store.encode(state);bad.staff_payroll_days["1"].wages_paid+=1
	store.decode(bad);check(store.write_blocked,"Conflicting payroll blocked")
	f=FileAccess.open(migration.save_path,FileAccess.WRITE);f.store_string("external edit");f.close()
	check(not migration.save_profile(old) and FileAccess.get_file_as_string(migration.save_path)=="external edit","External change protected")
	museum.queue_free();await frames(3)
	print("[11F4] %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
