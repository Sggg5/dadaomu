extends RefCounted
var test: SceneTree


func _init(context: SceneTree) -> void: test = context


func run() -> void:
	var store := MuseumProfileStore.new()
	store.save_path = "user://tests/phase_8c/%d_profile.json" % OS.get_process_id()
	var state := MuseumState.new()
	state.day_number = 3
	state.cash = 777
	state.museum_level = 1
	var identified := state.collection.add(&"tang_sancai_horse",2,72,true)
	var waiting := state.collection.add(&"tang_sancai_horse",2,65,false)
	state.assign(&"CASE_4",identified.instance_id)
	test.check(store.save_profile(state) and store.encode(store.load_profile()) == store.encode(state),"v2 real disk exact identity/condition/assignments/next ID roundtrip")
	var v1 := store.encode(state)
	v1.version = 1
	for row in v1.collection:
		row.erase("condition")
		row.erase("identified")
	v1.display_assignments["CASE_5"] = str(waiting.instance_id)
	var file := FileAccess.open(store.save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(v1))
	file.close()
	var migrated := store.load_profile()
	test.check(migrated.collection.all_items().size() == 2 and migrated.collection.all_items().all(func(item: OwnedAntique) -> bool: return item.identified and item.condition == 100) and migrated.cash == 777 and migrated.museum_level == 1 and migrated.display_assignments.size() == 2,"Real v1 disk migration preserves existing exhibits/cash/level, all identified100")
	test.check(store.save_profile(migrated) and JSON.parse_string(FileAccess.get_file_as_string(store.save_path)).version == 2,"Next save upgrades same existing filename to version2")
	# 正式GameFlow初始化同样读v1并自动保存v2，而不是只有手动Store可迁移。
	file = FileAccess.open(store.save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(v1))
	file.close()
	var flow := preload("res://scenes/main/game_flow.tscn").instantiate() as GameFlow
	flow.profile_store = store
	test.root.add_child(flow)
	await test.frames(3)
	test.check(flow.museum_state.collection.all_items().size() == 2 and flow.museum_state.display_assignments.size() == 2 and JSON.parse_string(FileAccess.get_file_as_string(store.save_path)).version == 2,"Actual GameFlow startup migrates legacy profile and rewritesv2 without clearing exhibition")
	flow.queue_free()
	await test.frames(3)
	test.check(migrated.collection.add(&"republic_silver_coin",3).instance_id == &"A000003","Migrated next antique ID remains stable")
	for bad in [-10,500,"bad",55.5,null]:
		var invalid := store.encode(state)
		invalid.collection[0].condition = bad
		var loaded := store.decode(invalid)
		test.check(loaded.collection.all_items().size() == 1 and loaded.collection.find(waiting.instance_id) != null and loaded.display_assignments.is_empty(),"Invalid v2 condition safely skips only affected item: "+str(bad))
	for bad in ["true",1,null]:
		var invalid := store.encode(state)
		invalid.collection[0].identified = bad
		test.check(store.decode(invalid).collection.all_items().size() == 1,"identified requires actual bool "+str(bad))
	var invalid_assignment := store.encode(state)
	invalid_assignment.display_assignments["CASE_5"] = str(waiting.instance_id)
	test.check(store.decode(invalid_assignment).display_assignments.size() == 1,"v2 cannot restore illegal unidentified exhibition")
	for version in [0,3]:
		var unsupported := store.encode(state)
		unsupported.version = version
		test.check(store.decode(unsupported).collection.all_items().is_empty(),"Unsupported schema safely defaults version%d" % version)
