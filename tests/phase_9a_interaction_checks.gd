extends RefCounted
var test: SceneTree
func _init(context: SceneTree) -> void: test = context

func event_in(content: TombRiskContent, event: TombRiskEvent) -> TombRiskInteractable:
	for child in content.get_children():
		if child is TombRiskInteractable and child.event == event: return child
	return null

func fixture(kind: int, ambush_reward: bool = false) -> TombRiskContent:
	var session := preload("res://scenes/main/dungeon_test.tscn").instantiate() as DungeonSession
	session.tomb = preload("res://tests/fixtures/legacy_two_floor_tomb.tres")
	test.session = session
	test.root.add_child(session)
	await test.frames(3)
	var world := session.world
	world._switch_room(world.layout.antique_id, -1)
	# 单项边界夹具强制四种结果；完整主流程仅使用正式随机事件。
	var event := TombExplorationPlan.COFFIN.duplicate() as TombRiskEvent
	event.id = StringName("fixture_%d" % kind)
	event.weights = PackedInt32Array([0, 0, 0, 0])
	event.weights[kind] = 1
	event.ambush_reward = ambush_reward # 可选奖励生命周期夹具显式开启，不依赖生产默认。
	var content := TombRiskContent.new()
	content.room = world.current_room
	content.room_id = world.current_id
	content.service = world.risk_service
	content.events = [event]
	world.current_room.risk_content = content
	world.current_room.add_child(content)
	await test.frames(2)
	return content

func run() -> void:
	for kind in range(4):
		var content := await fixture(kind)
		var player := test.session.world.player as Player
		var interactable := event_in(content, content.events[0])
		var hp := player.health.current_hp
		player.position = interactable.position + Vector2(90, 0)
		test.key(KEY_E)
		test.check(not interactable.confirming and content.service.results.is_empty(), "Out of range E cannot resolve event%d" % kind)
		player.position = interactable.position + Vector2(24, 0)
		test.key(KEY_E)
		test.check(interactable.confirming and player.health.current_hp == hp, "First E only opens explicit risk confirmation%d" % kind)
		test.capture("confirm_%d" % kind)
		test.key(KEY_TAB)
		test.check(not interactable.confirming and player.controls_enabled and player.health.current_hp == hp and content.service.results.is_empty(), "Cancel does not pay/reserve outcome%d" % kind)
		test.key(KEY_E)
		test.key(KEY_E)
		var result := content.service.results[content.source(interactable.event)]
		test.check(result.outcome == kind and not content.resolve(interactable.event, interactable.position), "Interaction resolves once%d" % kind)
		if kind == TombRiskResult.Outcome.TRAP:
			test.check(player.health.current_hp == hp - 20 and result.damage_taken == 20, "Trap formally damages Health by20 once")
		elif kind == TombRiskResult.Outcome.EMPTY:
			test.check(player.health.current_hp == hp and result.antique_ids.is_empty() and content.message.text.contains("空棺"), "Empty coffin has no consolation loot")
		elif kind == TombRiskResult.Outcome.AMBUSH:
			test.check(content.remaining() == 2 and test.session.world.current_room.doors.values().all(func(door: Door) -> bool: return not door.is_open), "Ambush really spawns existing enemies and locks traversal")
			var old_clears: int = test.session.rewards.combat_clears
			# 单项生命周期以Health击杀加速，完整流程另用真实武器。
			for enemy in content.ambush.get_children(): enemy.take_damage(10000)
			await test.frames(3)
			test.check(result.wave_completed and content.remaining() == 0 and test.session.rewards.combat_clears == old_clears and test.session.world.current_room.doors.values().all(func(door: Door) -> bool: return door.is_open), "Ambush defeat opens doors without duplicate COMBAT/relic clear")
			test.check(result.antique_ids.is_empty() and content.get_node_or_null("RiskLoot_%s" % interactable.event.id) == null, "Official ambush gives no guaranteed antique or consolation reward")
		if not result.antique_ids.is_empty():
			var pickup := content.get_node("RiskLoot_%s" % interactable.event.id) as AntiquePedestal
			var before_stats := player.stats.duplicate()
			for index in range(8): player.antiques.add(TombRiskService.POOL.find_by_id(&"republic_silver_coin"))
			player.position = pickup.position + Vector2(24, 0)
			test.key(KEY_E)
			test.check(player.antiques.used_slots() == 8 and not pickup.is_queued_for_deletion() and pickup.label.text.contains("背包空间不足"), "Full8-slot bag leaves event reward present%d" % kind)
			test.key(KEY_TAB)
			await test.frames(1)
			while not player.antiques.can_add(pickup.definition):
				test.session.world.antique_panel.list.select(0)
				test.key(KEY_DELETE)
			test.key(KEY_TAB)
			test.key(KEY_E)
			test.check(player.antiques.items().has(pickup.definition) and pickup.room_state.is_loot_claimed(pickup.source_id) and not pickup.try_pickup(), "Real Tab/Delete/E makes room and claims exactly once%d" % kind)
			test.check(player.stats.max_hp == before_stats.max_hp and player.stats.attack_damage == before_stats.attack_damage and player.relics.inventory.ids().is_empty(), "Event antique has no combat stat/relic effect%d" % kind)
		test.session.queue_free()
		await test.frames(4)
	await altar_boundary()
	await trap_boundary()
	await hidden_distance()

func trap_boundary() -> void:
	var content := await fixture(TombRiskResult.Outcome.TRAP)
	var actor := event_in(content, content.events[0])
	var player := test.session.world.player as Player
	player.health.restore(20) # 独立致死边界，不用于正式主流程。
	player.position = actor.position + Vector2(24, 0)
	test.key(KEY_E)
	test.key(KEY_E)
	await test.frames(2)
	test.check(player.health.is_dead and test.session.run_ended and content.service.results[content.source(actor.event)].damage_taken == 20, "Official20HP coffin mechanism can kill via Health")
	test.session.queue_free()
	await test.frames(3)

func hidden_distance() -> void:
	var content := await fixture(TombRiskResult.Outcome.EMPTY)
	var entrance := WallMark.new()
	entrance.player = test.session.world.player
	entrance.definition = WallMarkDefinition.new()
	entrance.definition.id = &"distance_fixture"
	entrance.definition.side = 0
	entrance.definition.inspect_result = "只是年代久远造成的破损。"
	entrance.plan = test.session.world.exploration
	entrance.can_inspect = func() -> bool: return true
	entrance.reveal_callback = func() -> bool: return false
	entrance.position = Vector2(400, 520)
	content.room.add_child(entrance)
	for distance in [64, 40, 32]:
		entrance.player.position = entrance.position + Vector2(distance, 0)
		await test.frames(1)
		test.key(KEY_E)
		test.check(not entrance.in_range() and entrance.label.text.is_empty() and not entrance.plan.checked_wall_marks.has(entrance.definition.id), "Wall clue has no E hint/interaction at%dpx" % distance)
	entrance.player.position = entrance.position + Vector2(30, 0)
	await test.frames(1)
	test.check(entrance.in_range() and entrance.label.text == "[E] 检查墙面", "Neutral wall hint appears only within30px")
	test.key(KEY_E)
	test.check(entrance.plan.checked_wall_marks.has(entrance.definition.id), "Close-range E records wall inspection")
	test.session.queue_free()
	await test.frames(3)

func altar_boundary() -> void:
	var content := await fixture(TombRiskResult.Outcome.EMPTY)
	var event := TombExplorationPlan.ALTAR
	content.events = [event]
	var interactable := TombRiskInteractable.new()
	interactable.content = content
	interactable.event = event
	interactable.position = Vector2(950, 480)
	content.add_child(interactable)
	var player := test.session.world.player as Player
	player.health.restore(63) # 单项UI/致死边界；真实主流程不注入HP。
	player.invulnerability_remaining = 10
	var damage_events := {"count": 0}
	player.health.damaged.connect(func(_amount: float) -> void: damage_events.count += 1)
	player.position = interactable.position + Vector2(24, 0)
	test.key(KEY_E)
	test.check(interactable.confirmation_label.text.contains("63.0 → 38.0") and not interactable.confirmation_label.text.contains("这会导致死亡"), "Altar preview shows actual currentHP and25HP loss without false warning")
	await test.frames(1)
	test.capture("altar_safe_preview")
	test.key(KEY_TAB)
	test.check(player.health.current_hp == 63 and damage_events.count == 0, "Altar cancel leaves Health untouched")
	player.health.restore(20)
	test.key(KEY_E)
	test.check(interactable.confirmation_label.text.contains("20.0 → 0.0") and interactable.confirmation_label.text.contains("警告：这会导致死亡"), "Altar explicitly warns fatal payment and still allows confirmation")
	await test.frames(1)
	test.capture("altar_fatal_preview")
	test.key(KEY_E)
	test.key(KEY_E)
	await test.frames(3)
	var result := content.service.results[content.source(event)]
	test.check(player.health.is_dead and damage_events.count == 1 and result.damage_taken == 20 and result.antique_ids.size() == 1 and test.session.run_ended, "25HP altar cost formally kills20HP player once and produces only inaccessible offering")
	test.check(player.antiques.items().is_empty() and not content.resolve(event, interactable.position), "Death cannot collect/retrigger altar reward")
	test.session.queue_free()
	await test.frames(4)
