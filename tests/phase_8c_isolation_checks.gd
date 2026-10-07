extends "res://tests/phase_8b_isolation_checks.gd"


func run() -> void:
	var baseline: Dictionary
	for variant in range(3):
		var flow := preload("res://scenes/main/game_flow.tscn").instantiate() as GameFlow
		flow.tomb = preload("res://tests/fixtures/legacy_two_floor_tomb.tres")
		# 旧功能固定Run夹具；正式派生Seed由9A专项另外覆盖。
		flow.forced_night_seed = 192034
		flow.campaign_seed_override = 52
		flow.profile_store = MuseumProfileStore.in_memory()
		var state := MuseumState.new()
		state.campaign_seed = 52 # 明确的有效v4存档夹具。
		state.cash = 5000*variant
		state.museum_level = variant
		var item := state.collection.add(&"tang_sancai_horse",1,55)
		if variant > 0: state.identify(item.instance_id)
		if variant == 2: state.repair(item.instance_id)
		flow.profile_store.save_profile(state)
		test.root.add_child(flow)
		await test.frames(3)
		flow.start_night()
		await test.frames(5)
		var actual := snapshot(flow.dungeon)
		if variant == 0: baseline = actual
		test.check(actual == baseline and actual.actual_player_hp == 80 and actual.inventory_capacity == 8,"Unidentified/appraised/repaired museum + cash/levels leave all Night data/layout/drops/relics unchanged variant%d" % variant)
		flow.queue_free()
		await test.frames(3)
