extends RefCounted
## 正式GameFlow→真门/武器/E事件/满包丢弃/Boss/F→回馆，另跑真实敌人贪心死亡。
var test: SceneTree
var flow: GameFlow
var driver: RefCounted
var discarded: int = 0
var selected_seed: int
func _init(context: SceneTree) -> void: test = context

func choose_seed() -> int:
	for candidate in range(1000):
		var plan := TombExplorationPlan.build(DungeonGenerator.generate(candidate, DungeonSession.DEFAULT_CONFIG), candidate, 1)
		if plan.secret_id == &"" or plan.fork.is_empty() or not plan.events.has(&"RISK_PATH"): continue
		var service := TombRiskService.new(candidate, 1)
		if service.preview(&"RISK_PATH", TombExplorationPlan.COFFIN).outcome == TombRiskResult.Outcome.ANTIQUE and service.preview(plan.secret_id, TombExplorationPlan.COFFIN).outcome == TombRiskResult.Outcome.ANTIQUE: return candidate
	assert(false, "Bounded scan requires a reproducible full exploration fixture")
	return 0

func take(pickup: AntiquePedestal) -> void:
	var world := test.session.world as RoomController
	var item := pickup.definition
	world.player.position = pickup.global_position + Vector2(24, 0)
	world.player.velocity = Vector2.ZERO
	await test.frames(1)
	if not world.player.antiques.can_add(item):
		test.key(KEY_E)
		test.check(not pickup.is_queued_for_deletion() and pickup.label.text.contains("背包空间不足"), "Real exploration full bag refuses E and keeps visible treasure")
		await test.frames(1)
		test.capture("full_bag")
		test.key(KEY_TAB)
		await test.frames(1)
		while not world.player.antiques.can_add(item):
			var items := world.player.antiques.items()
			var cheapest := 0
			for index in range(items.size()):
				if items[index].base_value < items[cheapest].base_value: cheapest = index
			world.antique_panel.list.select(cheapest)
			test.key(KEY_DELETE)
			discarded += 1
		test.key(KEY_TAB)
	var before := world.player.antiques.items().size()
	test.key(KEY_E)
	test.check(world.player.antiques.items().size() == before + 1 and pickup.room_state.is_loot_claimed(pickup.source_id), "Real E receives exploration loot through8-slot AntiqueInventory")
	await test.frames(3)

func interact(content: TombRiskContent, event: TombRiskEvent) -> void:
	var actor: TombRiskInteractable
	for child in content.get_children():
		if child is TombRiskInteractable and child.event == event: actor = child
	var player := test.session.world.player as Player
	player.position = actor.global_position + Vector2(24, 0)
	player.velocity = Vector2.ZERO
	test.key(KEY_E)
	await test.frames(1)
	test.check(actor.confirming, "Real nearby E shows exploration risk before committing")
	test.capture("risk_confirmation")
	test.key(KEY_E)
	await test.frames(2)
	test.check(content.service.results.has(content.source(event)), "Second real E resolves one official event")
	var pickup := content.get_node_or_null("RiskLoot_%s" % event.id) as AntiquePedestal
	if pickup != null: await take(pickup)

func secret() -> void:
	var world := test.session.world as RoomController
	var plan := world.exploration
	await driver.driver.visit(plan.secret_parent)
	var true_mark: WallMark
	for child in world.current_room.get_children():
		if child is WallMark and child.definition.is_secret: true_mark = child
	test.check(true_mark != null and not plan.secret_discovered and not world.hud.get_node("Root/Minimap")._layout.rooms.has(plan.secret_id), "Hidden room is absent from minimap before investigation")
	world.player.position = true_mark.position + (Room.ROOM_RECT.get_center() - true_mark.position).normalized() * 24
	world.player.velocity = Vector2.ZERO
	test.key(KEY_E)
	await test.frames(1)
	test.check(plan.secret_inspected and world.current_id == plan.secret_parent and not world.hud.minimap._layout.rooms.has(plan.secret_id), "First E hears hollow wall without entering/revealing map")
	test.capture("wall_crack")
	test.key(KEY_E)
	await test.frames(5)
	test.check(world.current_id == plan.secret_id and plan.secret_discovered and world.current_room.remaining_count() == 0 and world.player.get_instance_id() == test.session.world.player.get_instance_id(), "Second E actually enters optional safe secret with same Player")
	var content := world.current_room.risk_content
	await interact(content, TombExplorationPlan.HIDDEN_REWARD)
	await interact(content, TombExplorationPlan.COFFIN)
	test.capture("secret_offerings")
	var entrance: HiddenRoomEntrance
	for child in world.current_room.get_children():
		if child is HiddenRoomEntrance: entrance = child
	world.player.position = entrance.position + (Room.ROOM_RECT.get_center() - entrance.position).normalized() * 24
	test.key(KEY_E)
	await test.frames(5)
	test.check(world.current_id == plan.secret_parent, "Actual E returns secret to original cleared room")

func run() -> void:
	selected_seed = choose_seed()
	flow = preload("res://scenes/main/game_flow.tscn").instantiate() as GameFlow
	flow.progressive_relics = false
	flow.tomb = preload("res://tests/fixtures/legacy_two_floor_tomb.tres")
	# 旧功能固定Run夹具；正式派生Seed由9A专项另外覆盖。
	flow.forced_night_seed = 192034
	flow.campaign_seed_override = 52
	flow.profile_store = MuseumProfileStore.in_memory()
	flow.forced_night_seed = selected_seed
	test.root.add_child(flow)
	test.current_scene = flow
	await test.frames(3)
	var daytime = preload("res://tests/phase_8a_flow_checks.gd").new(test, flow)
	await daytime.night()
	driver = preload("res://tests/phase_7b_run_driver.gd").new(test)
	driver.driver.shot_attempts = 128
	var world := test.session.world as RoomController
	test.check(flow.tomb_exploration_enabled and test.session.exploration_enabled and world.exploration != null and world.player.health.max_hp == 80 and world.player.antiques.capacity == 8, "Official museum Night enters production exploration with80HP/eight slots")
	await driver.collect_floor()
	test.check(world.player.antiques.used_slots() >= 5, "True ordinary clears/E put several antiques at risk before extra exploration")
	await driver.driver.visit(&"RISK_PATH")
	test.check(world.current_id == &"RISK_PATH", "Actual Door reaches intended risk detour before coffin")
	await interact(world.current_room.risk_content, TombExplorationPlan.COFFIN)
	await secret()
	await driver.driver.visit(&"RISK_REWARD")
	var hp := world.player.health.current_hp
	await interact(world.current_room.risk_content, TombExplorationPlan.ALTAR)
	test.check(is_equal_approx(world.player.health.current_hp, hp - 25), "Risk detour offering really charges25HP for its high-value reward")
	test.check(world.player.antiques.used_slots() >= 6 and discarded > 0, "Real risk/secret/altar cause near-full bag and actual value-versus-space discards")
	var ids_before := world.player.antiques.items()
	var event_results := world.risk_service.results.size()
	await driver.defeat_warlord()
	var exit := world.current_room.get_node("ExpeditionExit") as ExpeditionExit
	world.player.position = exit.position + Vector2(24, 0)
	test.key(KEY_F)
	await test.frames(3)
	var result := test.session.complete_screen.result as RunResult
	test.check(result.outcome == RunResult.Outcome.EXTRACTED and result.antique_ids.size() == ids_before.size() and result.antique_value > 0, "Real Boss/F extracts actual ordinary and event antiques")
	test.capture("extracted")
	test.key(KEY_E)
	await test.frames(5)
	test.check(flow.current_day == 2 and flow.museum_state.collection.all_items().size() == result.antique_ids.size() and flow.museum_state.cash == 0, "Return E imports cargo as OwnedAntique without immediate money or combat bonuses")
	for index in range(result.antique_ids.size()):
		var owned := flow.museum_state.collection.all_items()[index]
		test.check(owned.definition_id == result.antique_ids[index] and not owned.identified and owned.condition == result.antique_conditions[index], "Returned event/ordinary cargo keeps standard appraisal/condition pipeline%d" % index)
	print("[9A success] seed=%d events=%d discarded=%d cargo=%s value=%d Day2 collection=%d" % [selected_seed, event_results, discarded, result.antique_ids, result.antique_value, flow.museum_state.collection.all_items().size()])
	# 新一晚依旧真实拿货/探索；死亡由活跃敌人造成，保留上一晚安全馆藏。
	var saved_count := flow.museum_state.collection.all_items().size()
	daytime = preload("res://tests/phase_8a_flow_checks.gd").new(test, flow)
	await daytime.night()
	driver = preload("res://tests/phase_7b_run_driver.gd").new(test)
	driver.driver.shot_attempts = 128
	world = test.session.world
	await driver.driver.visit(&"RISK_PATH")
	test.check(world.current_id == &"RISK_PATH", "Second actual Run reaches risk detour before taking greedy loot")
	await interact(world.current_room.risk_content, TombExplorationPlan.COFFIN)
	await secret()
	await driver.driver.visit(&"RISK_REWARD")
	await interact(world.current_room.risk_content, TombExplorationPlan.ALTAR)
	var carried := world.player.antiques.total_value()
	test.check(carried >= 1200, "Greedy second real Run carries high-value exploration treasure")
	await driver.die_to_enemy()
	await test.frames(3)
	result = test.session.complete_screen.result
	test.check(result.outcome == RunResult.Outcome.DEAD and result.antique_value == carried and world.player.antiques.used_slots() == 0, "Real hostile death loses all Run antiques including altar/secret loot")
	test.capture("greedy_death")
	test.key(KEY_E)
	await test.frames(5)
	test.check(flow.current_day == 3 and flow.museum_state.collection.all_items().size() == saved_count and flow.museum_state.cash == 0, "Death return imports nothing and preserves earlier safe collection")
	print("[9A death] seed=%d lost=%d safe_collection=%d" % [selected_seed, carried, saved_count])
	flow.queue_free()
	await test.frames(4)
	# 旧隔离检查在探索开启时再跑：包含实际市场/拍卖交易，不只是空数据。
	await preload("res://tests/phase_8d_isolation_checks.gd").new(test).run()
