extends "res://tests/phase_5b_smoke.gd"
func run()->void:
	var state:=preload("res://tests/fixtures/museum_management_fixture.gd").state_with_displays(50)
	state.cash=10000
	for kind in [&"LIGHT",&"BASE",&"LABEL",&"PROTECT"]:
		for i in range(2):MuseumConstructionService.purchase(state,MuseumConstructionService.quote(state,StringName("CASE_2:"+str(kind))))
	for id in [&"MAIN_GUIDE",&"EAST_REST",&"MAIN_RECEPTION"]:MuseumConstructionService.purchase(state,MuseumConstructionService.quote(state,id))
	var investment:=MuseumConstructionService.capital_today(state)
	var museum:=Museum.new();museum.state=state;museum.config=MuseumConfig.new()
	museum.config.open_duration=4;museum.config.visitor_speed=1800;museum.config.view_duration=.05
	root.add_child(museum);await frames(3)
	var gross:=0;var maintenance:=0;var visitors:=0
	for day in range(1,31):
		state.day_number=day;state.phase=MuseumState.Phase.MORNING
		check(museum.business.start(),"Real upgraded museum starts day"+str(day))
		await frames(550)
		check(state.daily_reports.has(day) and not museum.business.running,"Actual visitor closure reports day"+str(day))
		var report:Dictionary=state.daily_reports[day]
		check(report.ticket_income==report.visitor_count*5 and report.operating_net_income==report.ticket_income-report.maintenance_paid and report.maintenance_due==report.maintenance_paid+report.maintenance_waived,"Gross maintenance and net remain distinct on day"+str(day))
		gross+=report.ticket_income;maintenance+=report.maintenance_paid;visitors+=report.visitor_count
		var before:=state.cash
		check(not MuseumOperatingFinance.settle(state,museum.business) and state.cash==before,"Repeated day settlement never deducts again")
	check(state.cash==10000-investment+gross-maintenance and state.daily_reports.size()==30,"Thirty days cash reconciles real tickets investment and maintenance")
	var stats:={"days":30,"visitors":visitors,"gross":gross,"investment":investment,"maintenance":maintenance,"net":gross-maintenance,"cash":state.cash}
	var file:=FileAccess.open("res://logs/11e_30days.json",FileAccess.WRITE);file.store_string(JSON.stringify(stats));file.close()
	state.phase=MuseumState.Phase.EVENING
	var store:=MuseumProfileStore.new();store.save_path="res://logs/11e_v7_%d.json"%Time.get_ticks_usec()
	check(store.save_profile(state),"V7 isolated full asset and expense snapshot writes")
	var loaded:=store.load_profile()
	check(not store.write_blocked and store.encode(loaded)==store.encode(state),"V7 disk roundtrip preserves exact IDs themes reports cash and ledger")
	var legacy:=store.encode(state);legacy.version=6
	for key in ["facility_config_version","facility_levels","facility_expenses","facility_next_transaction","facility_foundation_level"]:legacy.erase(key)
	# Real v6 history has gross ticket reports, no maintenance columns or invented expenses.
	for report:Dictionary in legacy.daily_reports:
		for key in ["maintenance_due","maintenance_paid","maintenance_waived","operating_net_income","construction_at_close","service_visits","view_limit"]:report.erase(key)
	var migration:=MuseumProfileStore.new();migration.save_path="res://logs/11e_v6_%d.json"%Time.get_ticks_usec()
	file=FileAccess.open(migration.save_path,FileAccess.WRITE);file.store_string(JSON.stringify(legacy));file.close()
	var sha:=FileAccess.get_sha256(migration.save_path)
	var migrated:=migration.load_profile()
	check(not migration.write_blocked and migrated.facilities.levels.is_empty() and migrated.daily_reports.size()==30 and migrated.exhibition_plans==state.exhibition_plans and migrated.display_assignments==state.display_assignments and migrated.cash==state.cash,"V6 migration preserves all actual assets and no fabricated maintenance")
	check(MuseumOperatingFinance.net_for_day(migrated,state.day_number)==int(migrated.daily_reports[state.day_number].ticket_income),"Legacy V6 reports show original gross as net without fictitious historic cost")
	check(migration.save_profile(migrated) and FileAccess.get_sha256("%s.v6.%s.backup.json"%[migration.save_path,sha.substr(0,12)])==sha,"First V7 write retains byte-exact V6 backup")
	var bad:=store.encode(state);bad.facility_levels["CASE_2:LIGHT"]=3
	store.decode(bad);check(store.write_blocked,"Level and paid upgrade chain conflict blocks writes")
	bad=store.encode(state);bad.daily_reports[0].maintenance_paid+=1
	store.decode(bad);check(store.write_blocked,"Corrupt financial equation blocks writes")
	file=FileAccess.open(migration.save_path,FileAccess.WRITE);file.store_string("external edit");file.close()
	check(not migration.save_profile(migrated) and FileAccess.get_file_as_string(migration.save_path)=="external edit","Externally edited legacy/new profile cannot be overwritten")
	museum.queue_free();await frames(3)
	var poor:=MuseumState.new();poor.cash=1000
	var item:=poor.collection.add(&"tang_sancai_horse",1,95,true);poor.assign(&"CASE_2",item.instance_id)
	for i in range(3):MuseumConstructionService.purchase(poor,MuseumConstructionService.quote(poor,&"CASE_2:PROTECT"))
	poor.cash=2
	var business:=MuseumBusiness.new();business.state=poor;business.config=MuseumConfig.new()
	root.add_child(business);business.start();business.close_now();business._physics_process(.01)
	check(poor.cash==0 and poor.daily_reports[1].maintenance_paid==2 and poor.daily_reports[1].maintenance_waived==1,"Insufficient maintenance cash is waived once with no debt")
	check(not MuseumOperatingFinance.settle(poor,business) and poor.cash==0,"No repeated shortfall deduction")
	business.queue_free();await frames(3)
	print("[11E4] %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
