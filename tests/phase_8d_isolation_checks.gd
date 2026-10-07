extends "res://tests/phase_8b_isolation_checks.gd"


func run() -> void:
	var baseline: Dictionary
	for variant in range(3):
		var flow := preload("res://scenes/main/game_flow.tscn").instantiate() as GameFlow
		flow.progressive_relics = false
		flow.tomb = preload("res://tests/fixtures/legacy_two_floor_tomb.tres")
		# 旧功能固定Run夹具；正式派生Seed由9A专项另外覆盖。
		flow.forced_night_seed = 192034
		flow.campaign_seed_override = 52
		flow.profile_store = MuseumProfileStore.in_memory()
		var state := MuseumState.new()
		state.campaign_seed = 52 # 明确的有效v4存档夹具。
		var item := state.collection.add(&"tang_sancai_horse",1,76,true)
		if variant == 1: state.consign(item.instance_id,2)
		if variant == 2:
			state.sell_to_dealer(item.instance_id)
			var second := state.collection.add(&"gold_thread_jade",1,100,true)
			state.consign(second.instance_id,0)
			var bidding := AuctionBidding.new()
			bidding.configure(second,MuseumState.POOL.find_by_id(second.definition_id),1,192034,0)
			for rounds in range(100):
				if bidding.finished: break
				bidding.next_round()
			state.phase = MuseumState.Phase.NIGHT
			state.settle_auction(bidding.result)
			state.phase = MuseumState.Phase.MORNING
		flow.profile_store.save_profile(state)
		test.root.add_child(flow)
		await test.frames(3)
		flow.start_night()
		await test.frames(5)
		var actual := snapshot(flow.dungeon)
		if variant == 0: baseline = actual
		test.check(actual == baseline and actual.actual_player_hp == 80 and actual.inventory_capacity == 8 and flow.auction == null,"Dealer/pending/auction revenue keep all Dungeon data/Seed/drops/weapon/enemies/Boss/relics unchanged variant%d" % variant)
		flow.queue_free()
		await test.frames(3)
