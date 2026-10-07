extends RefCounted
var test: SceneTree
func _init(context: SceneTree) -> void: test = context

func run() -> void:
	var store := MuseumProfileStore.new()
	store.save_path = "user://tests/phase_9a1/%d_campaign_migration.json" % OS.get_process_id()
	var state := MuseumState.new()
	state.campaign_seed = 52
	state.day_number = 5
	state.cash = 2468
	state.museum_level = 1
	state.phase = MuseumState.Phase.EVENING
	state.last_day_visitors = 17
	state.last_day_ticket_income = 85
	var display := state.collection.add(&"han_jade_disc", 2, 73, true)
	var pending := state.collection.add(&"tang_sancai_horse", 3, 88, true)
	state.assign(&"CASE_4", display.instance_id)
	state.consign(pending.instance_id, AntiqueMarketService.Reserve.HIGH)
	var legacy := store.encode(state)
	legacy.version = 3
	legacy.erase("campaign_seed")
	var migrated := store.decode(legacy)
	test.check(migrated.campaign_seed == 0 and migrated.cash == 2468 and migrated.day_number == 5 and migrated.museum_level == 1 and migrated.phase == MuseumState.Phase.EVENING, "Pure v3 decode preserves old ground values and leaves Campaign uninitialized")
	test.check(migrated.collection.next_id() == state.collection.next_id() and migrated.display_assignments == state.display_assignments and migrated.auction_lot_instance_id == pending.instance_id and migrated.auction_reserve_mode == 2 and migrated.collection.find(display.instance_id).condition == 73 and migrated.collection.find(pending.instance_id).identified, "v3 appraisal/condition/next ID/exhibition/pending auction preserved")
	for version in [1, 2]:
		var older := legacy.duplicate(true)
		older.version = version
		var decoded := store.decode(older)
		test.check(decoded.campaign_seed == 0 and decoded.cash == state.cash and decoded.collection.all_items().size() == 2 and decoded.display_assignments == state.display_assignments, "Legacyv%d migration remains pure and preserves collection/ground" % version)
	seed(641)
	var expected := randi()
	seed(641)
	store.decode(legacy)
	test.check(randi() == expected, "Profile decode never randomizes campaign or consumes global RNG")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(store.save_path).get_base_dir())
	var file := FileAccess.open(store.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	var flow := preload("res://scenes/main/game_flow.tscn").instantiate() as GameFlow
	flow.tomb = preload("res://tests/fixtures/legacy_two_floor_tomb.tres")
	flow.profile_store = store
	flow.campaign_seed_override = 777
	test.root.add_child(flow)
	await test.frames(3)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(store.save_path))
	test.check(MuseumProfileStore.VERSION == 4 and flow.museum_state.campaign_seed == 777 and data.version == 4 and data.campaign_seed == 777, "Actual GameFlow initializes migrated campaign exactly once and saves v4")
	var snapshot := store.encode(flow.museum_state)
	flow.queue_free()
	await test.frames(3)
	flow = preload("res://scenes/main/game_flow.tscn").instantiate() as GameFlow
	flow.tomb = preload("res://tests/fixtures/legacy_two_floor_tomb.tres")
	flow.profile_store = store
	flow.campaign_seed_override = 999
	test.root.add_child(flow)
	await test.frames(3)
	test.check(flow.museum_state.campaign_seed == 777 and store.encode(flow.museum_state) == snapshot, "Second startup preserves campaign and every old field despite a different init override")
	flow.queue_free()
	await test.frames(3)
	for invalid in [0, -1, 2147483648, 1.5, true, "52", null, INF, NAN]:
		var payload := store.encode(state)
		payload.campaign_seed = invalid
		var repaired := store.decode(payload)
		test.check(repaired.campaign_seed == 0 and repaired.cash == state.cash and repaired.collection.all_items().size() == 2 and repaired.auction_lot_instance_id == pending.instance_id and not store.last_error.is_empty(), "Malformed v4 Campaign safely requests initialization without losing old assets: " + str(invalid))
	var uninitialized := MuseumState.new()
	test.check(not store.save_profile(uninitialized), "Formal v4 saving rejects campaign0 instead of persisting an invalid seed")
	for boundary in [1, 2147483647]:
		state.campaign_seed = boundary
		test.check(store.save_profile(state) and store.load_profile().campaign_seed == boundary, "31-bit Campaign JSON disk roundtrip exact boundary%d" % boundary)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(store.save_path))
