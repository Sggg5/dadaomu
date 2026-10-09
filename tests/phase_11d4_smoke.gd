extends "res://tests/phase_5b_smoke.gd"
var thirty_stats:Dictionary={}
func run()->void:
	var state:=MuseumState.new()
	state.campaign_seed=52
	state.museum_level=2
	state.cash=1234
	var slots:=state.display_catalog.units[&"CASE_2"].slots()
	var i:=0
	for id in [&"ly_attendant",&"ly_wuzhu",&"ly_granary"]:
		var item:=state.collection.add(id,1,95,true)
		state.place(slots[i].id,item.instance_id)
		i+=1
	ExhibitionService.start(state,&"MAIN",&"HAN_WEI")
	var museum:=Museum.new()
	museum.state=state
	museum.config=MuseumConfig.new()
	museum.config.open_duration=4.0
	museum.config.visitor_speed=1800
	museum.config.view_duration=.05
	root.add_child(museum)
	await frames(3)
	var income:=0
	var visitors:=0
	for day in range(1,31):
		state.day_number=day
		state.phase=MuseumState.Phase.MORNING
		check(museum.business.start(),"Day%d actual business begins"%day)
		await frames(420)
		check(not museum.business.running and state.daily_reports.has(day),"Day%d closes with exactly one report"%day)
		var report:Dictionary=state.daily_reports[day]
		check(report.ticket_income==report.visitor_count*museum.config.ticket_price and report.visitor_count>0,"Day%d income equals actual paid visitors"%day)
		income+=report.ticket_income
		visitors+=report.visitor_count
		var before:=state.cash
		museum.business._physics_process(1.0)
		var duplicate:=MuseumDailyReport.new()
		duplicate.values=report.duplicate(true)
		check(not MuseumDailyReport.store(state,duplicate) and state.cash==before,"Day%d duplicate closure never adds report or cash"%day)
		state.phase=MuseumState.Phase.MORNING
		check(not museum.business.start(),"Day%d cannot reopen settled day"%day)
	check(state.cash==1234+income and MuseumDailyReport.totals(state).visitors==visitors and state.daily_reports.size()==30,"Thirty days cash matches every actual ticket and unique daily report")
	check(MuseumDailyReport.recent(state,5).size()==5 and MuseumDailyReport.recent(state,6).is_empty(),"Recent thirty days bounded five-row pagination")
	thirty_stats={"days":30,"visitors":visitors,"income":income,"cash":state.cash}
	var out:=FileAccess.open("res://logs/11d_30days.json",FileAccess.WRITE)
	out.store_string(JSON.stringify(thirty_stats));out.close()
	state.phase=MuseumState.Phase.EVENING
	var store:=MuseumProfileStore.in_memory()
	var payload:=store.encode(state)
	var restored:=store.decode(payload)
	check(not store.write_blocked and restored.daily_reports.size()==30 and restored.exhibition_plans==state.exhibition_plans,"V6 restores topics and thirty reports")
	check(restored.cash==state.cash and restored.display_assignments==state.display_assignments,"Reading reports never pays income again or moves displays")
	var legacy:=payload.duplicate(true)
	legacy.version=5
	legacy.erase("exhibition_plans");legacy.erase("daily_reports")
	var old:=store.decode(legacy)
	check(not store.write_blocked and old.cash==state.cash and old.collection.all_items().size()==3 and old.display_assignments==state.display_assignments,"V5 migrates all real IDs condition cash and slots without gifts")
	for version in range(1,6):
		var earlier:=legacy.duplicate(true)
		earlier.version=version
		if version<5:earlier.display_assignments={"CASE_2":str(state.display_assignments[&"CASE_2"])}
		var loaded:=store.decode(earlier)
		check(not store.write_blocked and loaded.collection.all_items().size()==3 and loaded.display_assignments.size()==earlier.display_assignments.size() and loaded.case_for(StringName(earlier.display_assignments.CASE_2))==&"CASE_2" and loaded.cash==state.cash,"Legacy v%d reads real collection and cash without management replay"%version)
	check(old.daily_reports.is_empty() and old.exhibition_plans.is_empty(),"Legacy has no fabricated history")
	var corrupt:=payload.duplicate(true)
	corrupt.daily_reports.append(corrupt.daily_reports[0].duplicate(true))
	store.decode(corrupt)
	check(store.write_blocked,"Conflicting repeated day blocks writes")
	var roundtrip:=MuseumProfileStore.new()
	roundtrip.save_path="res://logs/11d_v6_roundtrip_%d.json"%Time.get_ticks_usec()
	check(roundtrip.save_profile(state),"Thirty report V6 profile writes to isolated disk")
	check(roundtrip.encode(roundtrip.load_profile())==roundtrip.encode(state),"JSON numeric normalization preserves exact thirty-day profile")
	var inconsistent:=payload.duplicate(true)
	inconsistent.daily_reports[0].hall_visit_statistics={}
	store.decode(inconsistent)
	check(store.write_blocked,"Inconsistent view counters protect corrupt report")
	var disk:=MuseumProfileStore.new()
	disk.save_path="res://logs/11d_v5_%d.json"%Time.get_ticks_usec()
	var file:=FileAccess.open(disk.save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy));file.close()
	var sha:=FileAccess.get_sha256(disk.save_path)
	var migrated:=disk.load_profile()
	check(disk.save_profile(migrated),"V5 migration safe first V6 write")
	var backup:="%s.v5.%s.backup.json"%[disk.save_path,sha.substr(0,12)]
	check(FileAccess.file_exists(backup) and FileAccess.get_sha256(backup)==sha,"Exact V5 byte backup exists before replacement")
	file=FileAccess.open(disk.save_path,FileAccess.WRITE);file.store_string("external change");file.close()
	check(not disk.save_profile(migrated) and FileAccess.get_file_as_string(disk.save_path)=="external change","External mutation cannot be overwritten")
	var bad:=MuseumProfileStore.new()
	bad.save_path="res://logs/11d_bad_%d.json"%Time.get_ticks_usec()
	file=FileAccess.open(bad.save_path,FileAccess.WRITE);file.store_string("broken");file.close()
	var bad_state:=bad.load_profile()
	bad_state.campaign_seed=52
	check(not bad.save_profile(bad_state) and FileAccess.get_file_as_string(bad.save_path)=="broken","Bad profile original remains protected")
	museum.queue_free()
	await frames(3)
	print("[11D4] %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
