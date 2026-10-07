extends RefCounted
## 正式派生Seed/真实战斗跨日/死亡/退出/R/N/拍卖，与旧固定Run夹具分离。
var test: SceneTree
func _init(context: SceneTree) -> void: test = context

func run() -> void:
	test.check(MuseumState.new().campaign_seed == 0, "New museum campaign begins explicitly uninitialized")
	for campaign in [1, 52, 2147483647]:
		for day in range(1, 31):
			var value := ExpeditionSeedService.derive(campaign, day)
			test.check(value >= 1 and value <= 2147483647 and value == ExpeditionSeedService.derive(campaign, day), "Stable positive31-bit expedition campaign%d day%d" % [campaign, day])
	test.check(ExpeditionSeedService.derive(52, 2, &"OTHER_SITE") != ExpeditionSeedService.derive(52, 2), "Site identity participates in stable seed derivation")
	await preload("res://tests/phase_9a_seed_profile_checks.gd").new(test).run()
	await three_days()
	await auction_day()
	for mode in ["hub", "solo"]:
		var output: Array = []
		var args := PackedStringArray(["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", "res://tests/phase_9a_seed_cli.gd", "--", "--seed=52", "--mode=" + mode])
		var status := OS.execute(OS.get_executable_path(), args, output, true)
		test.check(status == 0 and str(output).contains("valid=true"), "Actual child-process CLI semantic test " + mode)
		for line in str(output[0]).split("\n"):
			if line.begins_with("[SeedCLI"): print(line.strip_edges())

func create(store: MuseumProfileStore) -> GameFlow:
	var flow := preload("res://scenes/main/game_flow.tscn").instantiate() as GameFlow
	flow.profile_store = store
	flow.campaign_seed_override = 52
	test.root.add_child(flow)
	test.current_scene = flow
	await test.frames(3)
	return flow

func night(flow: GameFlow) -> void:
	var navigation = preload("res://tests/phase_8b_progression_checks.gd").new(test)
	navigation.flow = flow
	navigation.daytime = preload("res://tests/phase_8a_flow_checks.gd").new(test, flow)
	await navigation.night()
	test.check(flow.dungeon.run_seed == ExpeditionSeedService.derive(flow.museum_state.campaign_seed, flow.current_day), "Real board E injects actual day expedition seed")

func three_days() -> void:
	var store := MuseumProfileStore.in_memory()
	var flow := await create(store)
	test.check(flow.forced_night_seed == 0 and flow.museum_state.campaign_seed == 52 and store.load_profile().campaign_seed == 52, "Formal default uses derivation and persists initialized Campaign52")
	await night(flow)
	var first := flow.dungeon.run_seed
	var first_map := flow.dungeon.world.layout.spatial_signature()
	var driver = preload("res://tests/phase_7b_run_driver.gd").new(test)
	driver.driver.shot_attempts = 128
	await driver.collect_floor()
	await driver.defeat_warlord()
	var exit := flow.dungeon.world.current_room.get_node("ExpeditionExit") as ExpeditionExit
	flow.dungeon.world.player.position = exit.position + Vector2(24, 0)
	test.key(KEY_F)
	await test.frames(2)
	test.check(flow.dungeon.complete_screen.result.outcome == RunResult.Outcome.EXTRACTED, "True derived-Day1 Boss/F extraction, no forged completed outcome")
	test.key(KEY_E)
	await test.frames(4)
	test.check(flow.current_day == 2 and flow.museum_state.campaign_seed == 52, "Real successful return advances only day, keeps campaign")
	var before := ExpeditionSeedService.derive(52, 2)
	var owned := flow.museum_state.collection.all_items()[0]
	flow.museum_state.identify(owned.instance_id)
	flow.museum_state.assign(&"CASE_1", owned.instance_id)
	# 修复/升级资金只在独立状态副本中构造，不给真实三日流程注入现金。
	var operations := store.decode(store.encode(flow.museum_state))
	operations.cash = 10000
	operations.repair(owned.instance_id)
	operations.upgrade(0)
	test.check(flow.museum_state.campaign_seed == 52 and ExpeditionSeedService.derive(operations.campaign_seed, operations.day_number) == before, "Appraisal/repair/level/cash changes do not reseed same-day expedition")
	await night(flow)
	var second := flow.dungeon.run_seed
	var second_map := flow.dungeon.world.layout.spatial_signature()
	driver = preload("res://tests/phase_7b_run_driver.gd").new(test)
	driver.driver.shot_attempts = 128
	await driver.die_to_enemy()
	await test.frames(2)
	test.key(KEY_E)
	await test.frames(4)
	test.check(flow.current_day == 3 and flow.museum_state.campaign_seed == 52, "Actual hostile death/return advances to Day3 without changing campaign")
	await night(flow)
	var third := flow.dungeon.run_seed
	var third_map := flow.dungeon.world.layout.spatial_signature()
	test.check(first != second and second != third and first_map != second_map and second_map != third_map, "Campaign52 real Day1/2/3 have distinct Seeds and spatial maps")
	test.check(flow.dungeon.world.hud.get_node("Root/Seed").text.contains(str(third)), "HUD shows actual expedition rather than campaign")
	print("[Campaign days] Campaign=52 Day1=%d Day2=%d Day3=%d maps=different" % [first, second, third])
	test.key(KEY_R)
	await test.frames(4)
	test.check(flow.dungeon.run_seed == third and flow.dungeon.world.layout.spatial_signature() == third_map, "R repeats current actual expedition")
	var saves := store.save_count
	flow.dungeon._seed_rng.seed = 20261007
	test.key(KEY_N)
	await test.frames(4)
	test.check(flow.dungeon.run_seed != third and store.save_count == saves and store.load_profile().campaign_seed == 52 and store.load_profile().day_number == 3, "N is a temporary dev Run and never rewrites Campaign/day profile")
	flow.queue_free() # 不结算：实际退出当前临时Night。
	await test.frames(4)
	flow = await create(store)
	test.check(flow.current_day == 3 and flow.current_phase == MuseumState.Phase.MORNING, "Mid-Night quit restores preceding Day3 safe ground")
	await night(flow)
	test.check(flow.dungeon.run_seed == third and flow.dungeon.world.layout.spatial_signature() == third_map, "Reload/down again restores exact formal Day3 seed/map despite N override")
	flow.queue_free()
	await test.frames(4)

func auction_day() -> void:
	var store := MuseumProfileStore.in_memory()
	var state := MuseumState.new()
	state.campaign_seed = 52
	var item := state.collection.add(&"tang_sancai_horse", 0, 76, true)
	state.consign(item.instance_id, 0)
	store.save_profile(state)
	var flow := await create(store)
	test.check(flow.start_auction(), "Prepared Day1 auction starts real AuctionSession")
	await test.frames(4)
	for round_index in range(100):
		if flow.auction.bidding.finished: break
		test.key(KEY_E)
		await test.frames(1)
	test.check(flow.auction.bidding.finished and flow.dungeon == null, "Real auction E bidding consumes exclusive night without Dungeon")
	test.key(KEY_E)
	await test.frames(4)
	test.check(flow.current_day == 2 and flow.museum_state.campaign_seed == 52, "Auction return advances calendar while preserving campaign")
	await night(flow)
	test.check(flow.dungeon.run_seed == ExpeditionSeedService.derive(52, 2), "Post-auction Dungeon uses Day2, not a separate expedition counter")
	flow.queue_free()
	await test.frames(4)
