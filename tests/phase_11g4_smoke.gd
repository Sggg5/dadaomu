extends "res://tests/phase_5b_smoke.gd"
func run()->void:
	var state:=preload("res://tests/fixtures/museum_management_fixture.gd").state_with_displays(50);state.cash=10000
	var item:=state.collection.find(state.display_assignments[&"CASE_2"])
	check(MuseumCollectionCare.environment(state,item.instance_id).interval==3,"Unprotected inspection interval is 3 business days")
	for level in range(1,4):
		MuseumConstructionService.purchase(state,MuseumConstructionService.quote(state,&"CASE_2:PROTECT"))
		check(MuseumCollectionCare.environment(state,item.instance_id).interval==[3,5,7,10][level],"PROTECT updates real interval")
	var before:=item.condition;var cost:=state.restoration_cost(item.instance_id);var cash:=state.cash
	check(state.repair(item.instance_id) and state.cash==cash-cost,"Manual repair charges original cost once")
	check(state.collection.archives[item.instance_id].events[0].details.before==before and not state.repair(item.instance_id),"Repair history does not recharge or repeat")
	MuseumStaffService.hire(state,&"CONSERVATOR_SU")
	var task:=MuseumStaffTasks.enqueue(state,&"CONSERVATOR_SU",item.instance_id,&"INSPECT")
	var museum:=Museum.new();museum.state=state;museum.config=MuseumConfig.new();museum.config.open_duration=5;museum.config.staff_task_time_scale=.02
	root.add_child(museum);await frames(3);museum.business.start();await frames(50);museum.business.close_now();await frames(300)
	check(task.status==&"COMPLETED" and item.condition==100,"Real employee inspection does not change condition")
	var store:=MuseumProfileStore.new();store.save_path="res://logs/11g_v9_%d.json"%Time.get_ticks_usec()
	check(store.save_profile(state),"Isolated V9 writes")
	var loaded:=store.load_profile()
	check(not store.write_blocked and store.encode(loaded)==store.encode(state),"V9 exact employee facility archive roundtrip")
	var old:=store.encode(state);old.version=8;old.erase("collection_archives");old.erase("collection_research_version")
	# Historical v8 has only appraisal/restoration jobs, not the new inspection.
	old.staff_tasks=[];old.staff_next_task=1;old.daily_reports[0].staff_task_counts={}
	var migration:=MuseumProfileStore.new();migration.save_path="res://logs/11g_v8_%d.json"%Time.get_ticks_usec()
	var file:=FileAccess.open(migration.save_path,FileAccess.WRITE);file.store_string(JSON.stringify(old));file.close()
	var sha:=FileAccess.get_sha256(migration.save_path);var migrated:=migration.load_profile()
	check(not migration.write_blocked and migrated.cash==state.cash and migrated.display_assignments==state.display_assignments and migrated.staff.members.size()==1 and migrated.collection.archives[item.instance_id].source.is_empty(),"V8 keeps real assets staff and unknown discovery")
	check(migration.save_profile(migrated) and FileAccess.get_sha256("%s.v8.%s.backup.json"%[migration.save_path,sha.substr(0,12)])==sha,"V9 byte exact V8 backup")
	var bad:=store.encode(state);bad.collection_archives.append(bad.collection_archives[0]);store.decode(bad)
	check(store.write_blocked,"Duplicate dossier protects source")
	bad=store.encode(state);bad.collection_archives[0].references=["https://invented.example/"];store.decode(bad)
	check(store.write_blocked,"Unknown research citation protects source")
	museum.queue_free();await frames(3)
	print("[11G4] %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
