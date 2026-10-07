extends RefCounted
var test: SceneTree


func _init(context: SceneTree) -> void: test = context


func run() -> void:
	var store := MuseumProfileStore.new()
	store.save_path = "user://tests/phase_8d/%d_profile.json" % OS.get_process_id()
	var state := MuseumState.new()
	state.campaign_seed = 52 # 明确的有效v4存档夹具。
	state.day_number = 5
	state.cash = 1234
	state.museum_level = 1
	var item := state.collection.add(&"tang_sancai_horse",3,76,true)
	var shown := state.collection.add(&"gold_thread_jade",4,88,true)
	var unknown := state.collection.add(&"blue_white_jar",4,70)
	state.assign(&"CASE_4",shown.instance_id)
	var v2 := store.encode(state)
	v2.version = 2
	v2.erase("auction_lot_instance_id")
	v2.erase("auction_reserve_mode")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(store.save_path).get_base_dir())
	var file := FileAccess.open(store.save_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(v2))
	file.close()
	var flow := preload("res://scenes/main/game_flow.tscn").instantiate() as GameFlow
	flow.progressive_relics = false
	flow.tomb = preload("res://tests/fixtures/legacy_two_floor_tomb.tres")
	# 旧功能固定Run夹具；正式派生Seed由9A专项另外覆盖。
	flow.forced_night_seed = 192034
	flow.campaign_seed_override = 52
	flow.profile_store = store
	test.root.add_child(flow)
	await test.frames(3)
	var migrated := flow.museum_state
	test.check(migrated.auction_lot_instance_id == &"" and migrated.cash == 1234 and migrated.museum_level == 1 and migrated.day_number == 5 and migrated.collection.find(item.instance_id).condition == 76 and migrated.collection.find(item.instance_id).identified and migrated.display_assignments == state.display_assignments,"Actual v2 migration keeps complete old museum state and starts without pending lot")
	test.check(JSON.parse_string(FileAccess.get_file_as_string(store.save_path)).version == MuseumProfileStore.VERSION and migrated.collection.next_id() == state.collection.next_id(),"Startup writes current schema with unchanged next antique ID")
	flow.queue_free()
	await test.frames(3)
	state.consign(item.instance_id,2)
	test.check(store.save_profile(state) and store.encode(store.load_profile()) == store.encode(state) and store.load_profile().is_auction_locked(item.instance_id),"v3 real disk pending ID/reserve HIGH roundtrip preserves locking")
	for invalid in ["A999999",str(unknown.instance_id),str(shown.instance_id),123]:
		var payload := store.encode(state)
		payload.auction_lot_instance_id = invalid
		var restored := store.decode(payload)
		test.check(restored.auction_lot_instance_id == &"" and restored.display_assignments == state.display_assignments and restored.cash == state.cash,"Invalid pending safely clears, existing display takes priority: "+str(invalid))
	for invalid in [-1,3,"bad",null]:
		var payload := store.encode(state)
		payload.auction_reserve_mode = invalid
		test.check(store.decode(payload).auction_lot_instance_id == &"","Malformed reserve clears pending rather than crashing")
